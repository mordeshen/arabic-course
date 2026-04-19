import { getCurrentUser, getAdminSupabase } from "../lib/supabase.js";

// Map a lesson number to a course part (1/2/3) or 'free'
// Free: lessons 1-2
// Part 1: lessons 3-6
// Part 2: lessons 7-12
// Part 3: lessons 13-18
export function getLessonPart(lessonNum) {
  if (lessonNum >= 1 && lessonNum <= 2) return "free";
  if (lessonNum >= 3 && lessonNum <= 6) return 1;
  if (lessonNum >= 7 && lessonNum <= 12) return 2;
  if (lessonNum >= 13 && lessonNum <= 18) return 3;
  if (lessonNum >= 100) return "free"; // special lessons (reading, etc.)
  return null; // unknown
}

// Extract lesson number from a path like "/lessons/lesson_05.html"
export function getLessonNumFromPath(path) {
  const m = path.match(/lesson_(\d+)\.html/i);
  return m ? parseInt(m[1], 10) : null;
}

// Returns true if a user can access a given lesson
// Uses the DB function user_has_lesson_access for consistency
export async function canUserAccessLesson(userId, lessonNum) {
  if (!lessonNum) return false;
  const part = getLessonPart(lessonNum);
  if (part === "free") return true;
  if (!userId) return false;

  try {
    const admin = getAdminSupabase();
    const { data, error } = await admin.rpc("user_has_lesson_access", {
      p_user_id: userId,
      p_lesson_num: lessonNum,
    });
    if (error) {
      console.error("[canUserAccessLesson] DB error:", error.message);
      return false;
    }
    return data === true;
  } catch (e) {
    console.error("[canUserAccessLesson]", e.message);
    return false;
  }
}

// Express middleware: check access before serving lesson HTML
// Free lessons (1-2), nawwitni, reading_arabic, reading_practice — open
// Lessons 3+: must be logged in AND have a valid plan covering that part
export async function lessonAccessMiddleware(req, res, next) {
  const path = req.path;

  // Skip non-lesson files (e.g. assets, JSON)
  if (!path.match(/lesson_\d+\.html$/i)) {
    return next();
  }

  const lessonNum = getLessonNumFromPath(path);
  const part = getLessonPart(lessonNum);

  // Free lessons — let through
  if (part === "free") {
    return next();
  }

  // Need to check user
  const user = await getCurrentUser(req, res);
  const allowed = await canUserAccessLesson(user?.id, lessonNum);

  if (!allowed) {
    // If browser request — redirect to pricing page with intent
    if (req.headers.accept?.includes("text/html")) {
      return res.redirect(`/pricing.html?wanted=${lessonNum}`);
    }
    return res.status(403).json({
      error: "forbidden",
      message: "אין לך גישה לשיעור הזה. רכוש את החלק המתאים כדי להמשיך.",
      lesson: lessonNum,
      required_part: part,
    });
  }

  next();
}

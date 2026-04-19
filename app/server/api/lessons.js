// ──────────────────────────────────────────────────────────────
// GET /api/lessons/:num
// Returns a lesson + all its slides as JSON.
// Enforces access control + per-route rate limit + audit log.
// This is the ONLY way the client gets lesson content — never via static files.
// ──────────────────────────────────────────────────────────────

import { Router } from "express";
import rateLimit from "express-rate-limit";
import { getCurrentUser, getAdminSupabase } from "../lib/supabase.js";
import {
  canUserAccessLesson,
  getLessonPart,
} from "../middleware/lessonAccess.js";

const router = Router();

// Stricter rate limit on lesson content — to make scraping painful.
// 20 lesson fetches/min per IP is plenty for any human reader.
const lessonLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 20,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: "too_many_lesson_requests" },
});

router.get("/:num", lessonLimiter, async (req, res) => {
  const num = parseInt(req.params.num, 10);
  if (!Number.isInteger(num) || num < 0 || num > 200) {
    return res.status(400).json({ error: "invalid_lesson_number" });
  }

  const part = getLessonPart(num);
  if (part === null) {
    return res.status(404).json({ error: "lesson_not_found" });
  }

  const user = await getCurrentUser(req, res);
  const allowed = await canUserAccessLesson(user?.id, num);

  if (!allowed) {
    return res.status(403).json({
      error: "forbidden",
      message: "אין לך גישה לשיעור הזה. רכוש את החלק המתאים כדי להמשיך.",
      lesson: num,
      required_part: part,
    });
  }

  // Fetch via admin (RPC is SECURITY DEFINER and reads only active rows)
  let lessonPayload = null;
  try {
    const admin = getAdminSupabase();
    const { data, error } = await admin.rpc("get_lesson", {
      p_lesson_num: num,
    });
    if (error) {
      console.error("[/api/lessons] get_lesson:", error.message);
      return res.status(500).json({ error: "lesson_fetch_failed" });
    }
    lessonPayload = data;
  } catch (e) {
    console.error("[/api/lessons]", e.message);
    return res.status(500).json({ error: "lesson_fetch_failed" });
  }

  if (!lessonPayload || !lessonPayload.lesson) {
    return res.status(404).json({ error: "lesson_not_found" });
  }

  // Audit log — fire-and-forget; never block the response on logging
  if (user?.id) {
    queueMicrotask(async () => {
      try {
        const admin = getAdminSupabase();
        await admin.from("purchase_log").insert({
          user_id: user.id,
          plan_id: null,
          amount: 0,
          type: "lesson_view",
          description: `lesson ${num} fetched`,
          metadata: {
            lesson: num,
            part,
            ip: req.ip,
            ua: req.headers["user-agent"]?.slice(0, 200) || null,
          },
        });
      } catch (e) {
        console.error("[/api/lessons] audit log:", e.message);
      }
    });
  }

  // Tell browsers + intermediaries not to cache lesson content
  res.setHeader("Cache-Control", "no-store, max-age=0");
  res.json(lessonPayload);
});

export default router;

// ──────────────────────────────────────────────────────────────
// letter-confusion-map.js
// Maps visually similar Arabic letter pairs with Hebrew feedback.
// Used by letter_drag_game for smart corrective hints.
// Designed to grow as later lessons introduce more letters.
// ──────────────────────────────────────────────────────────────

// Each entry: [letter_a, letter_b] → Hebrew explanation of difference
// Keys are sorted alphabetically so lookup is order-independent.
const CONFUSION_PAIRS = {
  "ب|ت":  "ب ו-ت נראות אותו דבר! ההבדל: ب = נקודה אחת למטה, ت = שתי נקודות למעלה.",
  "ب|ث":  "ב ות׳ — אותה צורה! ب = נקודה אחת למטה, ث = שלוש נקודות למעלה.",
  "ت|ث":  "ת ות׳ — כמעט זהות! ت = שתי נקודות, ث = שלוש נקודות למעלה.",
  "ب|ن":  "ب ו-ن — צורת ״קערה״ דומה. ب = נקודה למטה + בטן ארוכה, ن = נקודה למעלה + קערה קצרה.",
  "ب|ي":  "ب ו-ي — אותה צורה בסיסית. ب = נקודה אחת למטה, ي = שתי נקודות למטה.",
  "ج|ح|خ": "ג׳, ח, ח׳ — אותה צורה! ج = נקודה למטה, ح = בלי נקודה, خ = נקודה למעלה.",
  "ج|ح":  "ג׳ ו-ח — אותו דבר, רק ج = יש נקודה בפנים, ح = בלי נקודה.",
  "ج|خ":  "ג׳ ו-ח׳ — ج = נקודה למטה בפנים, خ = נקודה למעלה.",
  "ح|خ":  "ח ו-ח׳ — ح = חלק (בלי נקודה), خ = עם נקודה למעלה. הנקודה הופכת את הצליל ל-kh.",
  "د|ذ":  "ד ו-ד׳ — ד = بلי نقطة, ד׳ = عם נקודה למעלה. הנקודה הופכת d ל-th (כמו that).",
  "ر|ز":  "ר ו-ז — אותה צורה! ر = בלי נקודה (ר), ز = עם נקודה למעלה (ז).",
  "س|ش":  "ס ו-ש — س = שלושה שיניים בלי נקודות, ش = שלושה שיניים + שלוש נקודות למעלה.",
  "ص|ض":  "סֿ ו-דֿ — ص = בלי נקודה (ס כועסת), ض = עם נקודה למעלה (ד כועסת).",
  "ط|ظ":  "ט ו-זֿ — ط = בלי נקודה (ט/ת כועסת), ظ = עם נקודה למעלה (ז כועסת).",
  "ع|غ":  "ע ו-ע׳ — ع = בלי נקודה (עין), غ = עם נקודה למעלה (ע׳ין = gh).",
  "ف|ق":  "פ ו-ק — ف = נקודה אחת למעלה, ق = שתי נקודות למעלה. בפלסטינית ק הופך ל-אַ (עצירה גרונית).",
  "ه|ة":  "ה ו-תאא מרבוטה — ه = הא (h), ة = תאא מרבוטה (ת/ה בסוף מילה). הנקודות למעלה הופכות אותה ל-ת.",
  "ا|ل":  "אַלֵף ו-לאם — שתיהן קווים אנכיים. ا = קצרה ועצמאית, ل = עם ״זנב״ שמחבר לאות הבאה.",
  "ك|ل":  "כ ו-ל — דומות באמצע מילה. ك = עם קו קטן בפנים (כּ), ل = חלקה ופשוטה.",
};

// Lookup: given two Arabic letters, return the feedback string or null
export function getConfusionFeedback(letterA, letterB) {
  // Try both orderings
  const keyAB = `${letterA}|${letterB}`;
  const keyBA = `${letterB}|${letterA}`;
  if (CONFUSION_PAIRS[keyAB]) return CONFUSION_PAIRS[keyAB];
  if (CONFUSION_PAIRS[keyBA]) return CONFUSION_PAIRS[keyBA];

  // Also check 3-way keys that contain both letters
  for (const [key, val] of Object.entries(CONFUSION_PAIRS)) {
    const letters = key.split("|");
    if (letters.includes(letterA) && letters.includes(letterB)) return val;
  }
  return null;
}

// Generic fallback when no specific pair is mapped
export function getGenericFeedback(expectedName, gotName) {
  return `לא בדיוק — זו ${gotName}, לא ${expectedName}. נסו שוב!`;
}

"""
הבחנה בין ערבית ספרותית (فصحى / MSA) לבין ערבית פלסטינית מדוברת (عامية).

סימנים לזיהוי MSA (לסינון החוצה):
- שימוש בתנועות קצרות (حركات/نِقاط) — נדיר בטקסט עממי
- מילות קישור פורמליות: إنّ، لكنّ، حيث، إذ، بيد أنّ
- צורות פועל ספרותיות: يُعَدّ، يُشير، أفاد
- ביטויים חדשותיים: "وفي السياق ذاته"، "على صعيد آخر"

סימנים לזיהוי ערבית פלסטינית:
- "هاد/هادي" במקום "هذا/هذه"
- "إشي" = דבר
- "بدي" = אני רוצה (במקום "أريد")
- "هلّق/هلأ" = עכשיו
- "مشان/عشان" = בשביל
- "كتير" = הרבה
- שלילה ב-"مش" במקום "ليس"
- "وين" = איפה (במקום "أين")
- "ليش" = למה (במקום "لماذا")
- "هيك" = ככה
"""

# רשימת מילות מפתח של ערבית פלסטינית
PALESTINIAN_MARKERS = [
    "بدي", "بدك", "بدو", "بدها", "بدنا", "بدكم", "بدهم",  # רוצה
    "هاد", "هادي", "هدول",  # זה/זאת/אלה
    "إشي", "اشي",  # דבר
    "هلق", "هلأ", "هلقيت",  # עכשיו
    "مشان", "عشان", "لإنو",  # בשביל/כי
    "كتير", "كثير",  # הרבה
    "مش", "مو",  # לא
    "وين",  # איפה
    "ليش",  # למה
    "هيك", "هيكي",  # ככה
    "طيب",  # אוקיי
    "يلا", "يللا",  # יאללה
    "شو",  # מה
    "كيفك",  # מה שלומך
    "منيح", "منيحة",  # טוב/ה
    "هون",  # כאן
]

MSA_MARKERS = [
    "إنّ", "لكنّ", "حيث", "إذ", "بيد",
    "يُعَدّ", "يُشير", "أفاد", "أوضح",
    "على صعيد", "في السياق", "من جهة أخرى",
    "المذكور", "المشار إليه", "سالف الذكر",
]


def compute_dialect_score(text: str) -> float:
    """
    מחשב ציון דיאלקט: 0.0 = فصحى טהורה, 1.0 = عامية טהורה.
    ציון מעל 0.3 = כנראה עממית.
    """
    words = text.split()
    if not words:
        return 0.5

    pal_count = sum(1 for w in words if any(m in w for m in PALESTINIAN_MARKERS))
    msa_count = sum(1 for w in words if any(m in w for m in MSA_MARKERS))

    total_markers = pal_count + msa_count
    if total_markers == 0:
        return 0.5  # לא ניתן לקבוע

    return pal_count / total_markers


def is_palestinian(text: str, threshold: float = 0.3) -> bool:
    """בודק אם טקסט הוא כנראה ערבית פלסטינית מדוברת."""
    return compute_dialect_score(text) >= threshold


def filter_msa(segments: list[dict], threshold: float = 0.3) -> list[dict]:
    """מסנן ומחזיר רק segments שהם כנראה ערבית מדוברת (לא MSA)."""
    filtered = []
    for seg in segments:
        score = compute_dialect_score(seg["text"])
        seg["dialect_score"] = score
        if score >= threshold:
            filtered.append(seg)
    return filtered

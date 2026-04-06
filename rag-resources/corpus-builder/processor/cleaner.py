"""
ניקוי כתוביות גולמיות:
1. הסר timestamps ותגיות HTML/VTT
2. הסר שורות כפולות (כתוביות אוטומטיות חוזרות על עצמן)
3. מזג שורות קצרות למשפטים שלמים
4. נרמל רווחים וסימני פיסוק
5. הסר תווים לא-ערביים מיותרים (אמוג'י, סימנים מיוחדים)
"""

import re


def clean_subtitle_text(raw: str) -> str:
    """מנקה טקסט כתוביות גולמי."""
    # הסר תגיות HTML
    text = re.sub(r"<[^>]+>", "", raw)
    # הסר timestamps בפורמט VTT/SRT
    text = re.sub(
        r"\d{2}:\d{2}:\d{2}[.,]\d{3}\s*-->\s*\d{2}:\d{2}:\d{2}[.,]\d{3}", "", text
    )
    # הסר מספרי שורות SRT
    text = re.sub(r"^\d+$", "", text, flags=re.MULTILINE)
    # הסר תווים לא-ערביים מיותרים (שמור על ערבית, עברית, רווחים, סימני פיסוק בסיסיים)
    text = re.sub(r"[^\u0600-\u06FF\u0750-\u077F\uFB50-\uFDFF\uFE70-\uFEFF\s.,!?؟،؛\-]", "", text)
    # נרמל רווחים
    text = re.sub(r"\s+", " ", text).strip()
    return text


def deduplicate_segments(segments: list[dict]) -> list[dict]:
    """כתוביות אוטומטיות חוזרות — הסר כפילויות."""
    seen = set()
    deduped = []
    for seg in segments:
        normalized = seg["text"].strip()
        if normalized and normalized not in seen:
            seen.add(normalized)
            deduped.append(seg)
    return deduped


def merge_short_segments(segments: list[dict], min_words: int = 3) -> list[dict]:
    """מאחד segments קצרים מדי למשפטים שלמים."""
    if not segments:
        return []

    merged = []
    buffer = None

    for seg in segments:
        words = seg["text"].split()

        if buffer is None:
            buffer = seg.copy()
            continue

        buffer_words = buffer["text"].split()
        if len(buffer_words) < min_words:
            # מאחד עם ה-segment הנוכחי
            buffer["text"] = buffer["text"] + " " + seg["text"]
            buffer["end"] = seg.get("end", buffer.get("end"))
        else:
            merged.append(buffer)
            buffer = seg.copy()

    if buffer:
        merged.append(buffer)

    return merged


def clean_segments(segments: list[dict], min_words: int = 3) -> list[dict]:
    """צינור ניקוי מלא: ניקוי טקסט → הסרת כפילויות → איחוד קצרים."""
    # ניקוי טקסט
    for seg in segments:
        seg["text"] = clean_subtitle_text(seg["text"])

    # הסר segments ריקים
    segments = [seg for seg in segments if seg["text"].strip()]

    # הסר כפילויות
    segments = deduplicate_segments(segments)

    # אחד segments קצרים
    segments = merge_short_segments(segments, min_words)

    return segments

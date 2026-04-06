"""פילוח טקסט למשפטים ו-utterances."""

import re


def segment_text(text: str) -> list[str]:
    """
    מפלח טקסט ערבי למשפטים.
    משתמש בסימני פיסוק ערביים ולטיניים כנקודות חיתוך.
    """
    # פיצול לפי סימני פיסוק ערביים ולטיניים
    sentences = re.split(r"[.!?؟،؛\n]+", text)
    # ניקוי רווחים ושורות ריקות
    sentences = [s.strip() for s in sentences if s.strip()]
    return sentences


def segment_segments(segments: list[dict], min_words: int = 3) -> list[dict]:
    """
    מפלח segments ארוכים למשפטים נפרדים.
    שומר על timestamps מקוריים (start/end של ה-segment המקורי).
    """
    result = []
    for seg in segments:
        sentences = segment_text(seg["text"])
        for sentence in sentences:
            words = sentence.split()
            if len(words) >= min_words:
                result.append(
                    {
                        "text": sentence,
                        "start": seg.get("start"),
                        "end": seg.get("end"),
                    }
                )
    return result

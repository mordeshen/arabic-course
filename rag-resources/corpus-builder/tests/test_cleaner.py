"""בדיקות יחידה לניקוי כתוביות."""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent))

from processor.cleaner import clean_subtitle_text, deduplicate_segments, merge_short_segments, clean_segments


def test_clean_html_tags():
    """בדיקה שתגיות HTML מוסרות."""
    raw = "<b>مرحبا</b> <i>كيفك</i>"
    result = clean_subtitle_text(raw)
    assert "<" not in result
    assert "مرحبا" in result
    assert "كيفك" in result


def test_clean_timestamps():
    """בדיקה שtimestamps מוסרים."""
    raw = "00:01:23,456 --> 00:01:25,789 مرحبا"
    result = clean_subtitle_text(raw)
    assert "-->" not in result
    assert "مرحبا" in result


def test_clean_non_arabic():
    """בדיקה שתווים לא-ערביים מוסרים."""
    raw = "مرحبا 😊 hello 123"
    result = clean_subtitle_text(raw)
    assert "😊" not in result
    assert "hello" not in result
    assert "مرحبا" in result


def test_deduplicate_segments():
    """בדיקה שכפילויות מוסרות."""
    segments = [
        {"text": "مرحبا", "start": 0, "end": 1},
        {"text": "مرحبا", "start": 1, "end": 2},
        {"text": "كيفك", "start": 2, "end": 3},
    ]
    result = deduplicate_segments(segments)
    assert len(result) == 2


def test_merge_short_segments():
    """בדיקה שsegments קצרים מתאחדים."""
    segments = [
        {"text": "شو", "start": 0, "end": 1},
        {"text": "بدك تاكل اليوم", "start": 1, "end": 3},
    ]
    result = merge_short_segments(segments, min_words=3)
    assert len(result) == 1
    assert "شو" in result[0]["text"]
    assert "بدك" in result[0]["text"]


def test_clean_segments_pipeline():
    """בדיקת צינור ניקוי מלא."""
    segments = [
        {"text": "<b>مرحبا</b>", "start": 0, "end": 1},
        {"text": "مرحبا", "start": 1, "end": 2},
        {"text": "كيف الحال اليوم عندكم", "start": 2, "end": 4},
    ]
    result = clean_segments(segments, min_words=2)
    # כפילות צריכה להיות מוסרת
    texts = [seg["text"] for seg in result]
    assert len(set(texts)) == len(texts)

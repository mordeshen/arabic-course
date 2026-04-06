"""בדיקות יחידה לפילוח טקסט."""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent))

from processor.segmenter import segment_text, segment_segments


def test_segment_by_period():
    """פילוח לפי נקודה."""
    text = "مرحبا كيفك. شو أخبارك. كل شي تمام"
    result = segment_text(text)
    assert len(result) == 3


def test_segment_by_question_mark():
    """פילוח לפי סימן שאלה ערבי."""
    text = "شو بدك؟ وين رايح؟ ليش"
    result = segment_text(text)
    assert len(result) == 3


def test_segment_segments_min_words():
    """segments קצרים מדי צריכים להיות מסוננים."""
    segments = [
        {"text": "هلأ. شو بدك تعمل اليوم", "start": 0, "end": 5},
    ]
    result = segment_segments(segments, min_words=3)
    # "هلأ" (מילה אחת) צריך להיות מסונן
    assert all(len(seg["text"].split()) >= 3 for seg in result)

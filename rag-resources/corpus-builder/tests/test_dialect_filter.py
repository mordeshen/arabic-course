"""בדיקות יחידה לסינון דיאלקט."""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent))

from processor.dialect_filter import compute_dialect_score, is_palestinian, filter_msa


def test_palestinian_text_high_score():
    """טקסט פלסטיני צריך לקבל ציון גבוה."""
    text = "شو بدك تاكل هلأ كتير جوعان"
    score = compute_dialect_score(text)
    assert score > 0.5


def test_msa_text_low_score():
    """טקסט ספרותי צריך לקבל ציון נמוך."""
    text = "إنّ المشار إليه أفاد بأنّ على صعيد آخر"
    score = compute_dialect_score(text)
    assert score < 0.4


def test_neutral_text():
    """טקסט ניטרלי צריך לקבל 0.5."""
    text = "الطقس جميل اليوم"
    score = compute_dialect_score(text)
    assert score == 0.5


def test_empty_text():
    """טקסט ריק צריך לקבל 0.5."""
    assert compute_dialect_score("") == 0.5


def test_is_palestinian():
    """בדיקת פונקציית is_palestinian."""
    assert is_palestinian("شو بدك يا زلمة")
    assert not is_palestinian("إنّ المؤتمر أفاد")


def test_filter_msa():
    """בדיקת סינון MSA."""
    segments = [
        {"text": "شو بدك تاكل هلأ"},
        {"text": "إنّ المشار إليه أفاد"},
        {"text": "الطقس جميل"},
    ]
    result = filter_msa(segments, threshold=0.3)
    # רק הפלסטיני + הניטרלי צריכים לעבור
    assert any("بدك" in seg["text"] for seg in result)

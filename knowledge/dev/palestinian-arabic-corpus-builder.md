# Palestinian Arabic Corpus Builder — Claude Code Instructions

## מטרה

בנה כלי CLI בפייתון שמחלץ כתוביות מסרטוני יוטיוב בערבית פלסטינית מדוברת, מנקה ומעבד אותן, ובונה בסיס ידע מובנה. הכלי מיועד ליצירת קורפוס של ערבית פלסטינית מדוברת (عامية فلسطينية) — לא ערבית ספרותית (فصحى).

## ארכיטקטורה

```
palestinian-corpus/
├── cli.py                  # Entry point — typer CLI
├── scraper/
│   ├── __init__.py
│   ├── channel.py          # Channel/playlist discovery via yt-dlp
│   ├── subtitles.py        # Subtitle extraction (CC + auto-generated)
│   └── transcriber.py      # Whisper fallback for no-subtitle videos
├── processor/
│   ├── __init__.py
│   ├── cleaner.py          # Strip timestamps, formatting, duplicates
│   ├── dialect_filter.py   # Filter out فصحى (MSA) content
│   └── segmenter.py        # Split into sentences/utterances
├── storage/
│   ├── __init__.py
│   ├── models.py           # SQLModel/Pydantic models
│   └── db.py               # SQLite via SQLModel
├── export/
│   ├── __init__.py
│   └── exporter.py         # Export to JSON, CSV, JSONL, Anki
├── config.py               # Settings via pydantic-settings
├── requirements.txt
└── README.md
```

## תלויות

```txt
yt-dlp>=2024.0
youtube-transcript-api>=0.6.0
openai-whisper>=20231117      # fallback transcription
typer>=0.9.0
rich>=13.0
sqlmodel>=0.0.14
pydantic-settings>=2.0
langdetect>=1.0.9
```

## CLI Commands

### 1. `fetch` — חילוץ כתוביות

```bash
# מערוץ שלם
python cli.py fetch channel "https://www.youtube.com/@Makan33"

# מפלייליסט
python cli.py fetch playlist "https://www.youtube.com/playlist?list=PLxxxxx"

# מסרטון בודד
python cli.py fetch video "https://www.youtube.com/watch?v=xxxxx"

# עם תמלול Whisper כ-fallback
python cli.py fetch channel "URL" --whisper-fallback --whisper-model medium
```

### 2. `process` — ניקוי ועיבוד

```bash
# ניקוי + סינון דיאלקט + פילוח למשפטים
python cli.py process --filter-msa --min-length 3
```

### 3. `export` — ייצוא

```bash
python cli.py export jsonl --output corpus.jsonl
python cli.py export csv --output corpus.csv
python cli.py export anki --output anki_deck.txt
```

### 4. `stats` — סטטיסטיקות

```bash
python cli.py stats  # כמה סרטונים, משפטים, מילים ייחודיות, וכו'
```

---

## מודל נתונים — `models.py`

```python
from sqlmodel import SQLModel, Field
from datetime import datetime
from typing import Optional

class Video(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    youtube_id: str = Field(unique=True, index=True)
    title: str
    channel: str
    url: str
    duration_seconds: int
    subtitle_source: str  # "cc", "auto", "whisper"
    language_code: str    # "ar", "ar-PL" etc.
    fetched_at: datetime = Field(default_factory=datetime.utcnow)
    is_msa: Optional[bool] = None  # True = فصحى, False = عامية

class Utterance(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    video_id: int = Field(foreign_key="video.id", index=True)
    text: str                          # הטקסט בערבית
    start_time: Optional[float] = None # שנייה בסרטון
    end_time: Optional[float] = None
    speaker: Optional[str] = None      # אם ניתן לזהות
    hebrew_translation: Optional[str] = None
    english_translation: Optional[str] = None
    notes: Optional[str] = None        # הערות ידניות
    dialect_score: Optional[float] = None  # 0=فصحى, 1=عامية
```

---

## לוגיקת חילוץ — `subtitles.py`

```python
"""
סדר עדיפויות לחילוץ כתוביות:
1. כתוביות ידניות בערבית (ar)
2. כתוביות אוטומטיות בערבית (ar auto-generated)
3. כתוביות ידניות בעברית (he) — כגיבוי לתרגום
4. Whisper transcription — רק אם --whisper-fallback מופעל

שימוש ב-yt-dlp כמנוע ראשי כי:
- youtube-transcript-api נשבר לעתים קרובות (תלוי ב-API לא רשמי)
- yt-dlp יציב יותר ותומך גם בפורמטים אחרים
"""

import subprocess
import json
import os
from pathlib import Path

def get_subtitles_ytdlp(video_url: str, output_dir: Path) -> dict:
    """
    חלץ כתוביות עם yt-dlp.
    מחזיר dict עם {language: filepath} של קבצי כתוביות שהורדו.
    """
    cmd = [
        "yt-dlp",
        "--write-subs",
        "--write-auto-subs",
        "--sub-langs", "ar,he",
        "--sub-format", "json3",  # פורמט מובנה עם timestamps
        "--skip-download",        # לא מוריד את הווידאו
        "--output", str(output_dir / "%(id)s.%(ext)s"),
        video_url
    ]
    subprocess.run(cmd, check=True, capture_output=True)
    # ... parse downloaded subtitle files

def get_subtitles_api(video_id: str) -> list[dict]:
    """
    Fallback via youtube-transcript-api.
    """
    from youtube_transcript_api import YouTubeTranscriptApi
    try:
        # נסה כתוביות ידניות קודם
        transcript = YouTubeTranscriptApi.get_transcript(video_id, languages=['ar'])
    except:
        # נסה אוטומטיות
        transcript = YouTubeTranscriptApi.get_transcript(
            video_id, languages=['ar'], 
            preserve_formatting=False
        )
    return transcript  # [{"text": "...", "start": 0.0, "duration": 2.5}, ...]
```

---

## סינון דיאלקט — `dialect_filter.py`

```python
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
- "كيف الحال" → "كيفك" / "شلونك"
- "بدي" = אני רוצה (במקום "أريد")
- "هلّق/هلأ" = עכשיו
- "مشان/عشان" = בשביל
- "كتير" = הרבה
- שלילה ב-"مش" במקום "ليس"
- "وين" = איפה (במקום "أين")
- "ليش" = למה (במקום "لماذا")
- "هيك" = ככה
"""

# רשימת מילות מפתח של ערבית פלסטינית (ניתן להרחיב)
PALESTINIAN_MARKERS = [
    "بدي", "بدك", "بدو", "بدها", "بدنا", "بدكم", "بدهم",  # רוצה
    "هاد", "هادي", "هدول",                                    # זה/זאת/אלה
    "إشي", "اشي",                                              # דבר
    "هلق", "هلأ", "هلقيت",                                     # עכשיו
    "مشان", "عشان", "لإنو",                                    # בשביל/כי
    "كتير", "كثير",                                             # הרבה
    "مش", "مو",                                                 # לא
    "وين",                                                      # איפה
    "ليش",                                                      # למה
    "هيك", "هيكي",                                              # ככה
    "طيب",                                                      # אוקיי
    "يلا", "يللا",                                              # יאללה
    "شو",                                                       # מה
    "كيفك",                                                     # מה שלומך
    "منيح", "منيحة",                                            # טוב/ה
    "هون",                                                      # כאן
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
```

---

## Whisper Fallback — `transcriber.py`

```python
"""
כשאין כתוביות כלל — תמלול באמצעות Whisper.
- מודל medium מספיק לרוב — מודל large מדויק יותר אבל כבד
- Whisper תומך בערבית אבל לא תמיד מבחין בדיאלקט
- שמור את האודיו כ-opus/mp3 (קטן) ולא wav
"""

def transcribe_video(video_url: str, model_size: str = "medium") -> list[dict]:
    import whisper
    import tempfile
    
    # הורד רק את האודיו
    with tempfile.TemporaryDirectory() as tmpdir:
        audio_path = f"{tmpdir}/audio.mp3"
        subprocess.run([
            "yt-dlp",
            "-x", "--audio-format", "mp3",
            "--audio-quality", "5",  # איכות סבירה, קובץ קטן
            "-o", audio_path,
            video_url
        ], check=True)
        
        model = whisper.load_model(model_size)
        result = model.transcribe(
            audio_path, 
            language="ar",
            task="transcribe",
            word_timestamps=True
        )
    
    return [
        {
            "text": seg["text"].strip(),
            "start": seg["start"],
            "end": seg["end"]
        }
        for seg in result["segments"]
    ]
```

---

## ניקוי — `cleaner.py`

```python
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
    # הסר תגיות HTML
    text = re.sub(r'<[^>]+>', '', raw)
    # הסר timestamps בפורמט VTT/SRT
    text = re.sub(r'\d{2}:\d{2}:\d{2}[.,]\d{3}\s*-->\s*\d{2}:\d{2}:\d{2}[.,]\d{3}', '', text)
    # הסר מספרי שורות SRT
    text = re.sub(r'^\d+$', '', text, flags=re.MULTILINE)
    # נרמל רווחים
    text = re.sub(r'\s+', ' ', text).strip()
    # הסר שורות ריקות כפולות
    text = re.sub(r'\n{3,}', '\n\n', text)
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
```

---

## ייצוא — `exporter.py`

```python
"""
פורמטי ייצוא:
- JSONL: שורה אחת = utterance אחד. מצוין ל-fine-tuning / RAG
- CSV: לעבודה באקסל
- Anki: לכרטיסיות לימוד (ערבית → עברית)
"""

def export_jsonl(utterances, output_path):
    """
    כל שורה:
    {"text": "شو بدك تاكل؟", "translation_he": "מה אתה רוצה לאכול?", 
     "source_video": "...", "timestamp": 42.5, "dialect_score": 0.85}
    """
    ...

def export_anki(utterances, output_path):
    """
    פורמט TSV לייבוא ל-Anki:
    front (ערבית) \t back (עברית + הקשר)
    """
    ...
```

---

## ערוצי יוטיוב מומלצים לקורפוס

```python
# ערוצים עם תוכן בערבית פלסטינית מדוברת:
RECOMMENDED_CHANNELS = {
    "makan33": "https://www.youtube.com/@Makan33",           # מכאן 33 — תוכניות מגוונות
    "musawa": "https://www.youtube.com/@Musawa.channel",     # מוסאוואה — חדשות וריאיונות
    "alhurra_palestine": "https://www.youtube.com/@AlHurra", # חדשות (יותר MSA, סנן!)
    "wattan_tv": "https://www.youtube.com/@WattanTV",        # ואטן — תוכן פלסטיני
    "roya_news": "https://www.youtube.com/@RoyaNews",        # רויא — ירדני/פלסטיני
    # פודקאסטים ותוכן שיחתי (עדיף — הכי קרוב לשפה מדוברת):
    "nas_daily_arabic": "https://www.youtube.com/@NasDaily",
    # סדרות רשת פלסטיניות — מצוין לדיאלוגים:
    "watan_ala_watar": "https://www.youtube.com/@watanalawatar",
}
```

---

## Config — `config.py`

```python
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    db_path: str = "corpus.db"
    whisper_model: str = "medium"
    min_utterance_length: int = 3       # מינימום מילים ב-utterance
    dialect_threshold: float = 0.3      # מעל = عامية
    batch_size: int = 50                # סרטונים לעיבוד בכל ריצה
    subtitle_cache_dir: str = ".cache/subs"
    audio_cache_dir: str = ".cache/audio"
    
    class Config:
        env_prefix = "PAL_CORPUS_"      # PAL_CORPUS_DB_PATH=... etc.
```

---

## הוראות מיוחדות ל-Claude Code

1. **תעשה אל תסביר** — אל תשאל שאלות מיותרות. תממש.
2. **קוד באנגלית, הערות בעברית** — docstrings ו-comments בעברית, שמות משתנים באנגלית.
3. **טיפול בשגיאות** — סרטונים ייכשלו. השתמש ב-try/except ולוג ברור עם `rich.console`.
4. **Rate limiting** — יוטיוב חוסם. הוסף `--delay` בין בקשות (ברירת מחדל 2 שניות).
5. **Progress bars** — השתמש ב-`rich.progress` לכל פעולה ארוכה.
6. **Idempotent** — אם סרטון כבר ב-DB, דלג עליו (לפי youtube_id).
7. **Tests** — כתוב pytest בסיסי עם mock ל-yt-dlp ו-youtube-transcript-api.
8. **README** — בעברית, עם דוגמאות שימוש מלאות.

## התקנה מהירה

```bash
pip install -r requirements.txt
# Whisper דורש גם ffmpeg:
sudo apt install ffmpeg
```

## שימוש ראשון

```bash
# חלץ כתוביות מערוץ מכאן 33
python cli.py fetch channel "https://www.youtube.com/@Makan33" --delay 3

# נקה וסנן — השאר רק ערבית מדוברת
python cli.py process --filter-msa --min-length 3

# ייצא ל-JSONL לשימוש ב-RAG
python cli.py export jsonl --output palestinian_corpus.jsonl

# סטטיסטיקות
python cli.py stats
```

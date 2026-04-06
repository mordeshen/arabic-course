# Palestinian Arabic Corpus Builder

כלי CLI לבניית קורפוס של ערבית פלסטינית מדוברת (عامية فلسطينية) מתוך כתוביות של סרטוני יוטיוב.

## מה הכלי עושה?

1. **מחלץ כתוביות** מסרטוני יוטיוב — ידניות, אוטומטיות, או תמלול Whisper
2. **מנקה ומעבד** — מסיר כפילויות, תגיות, ותווים מיותרים
3. **מסנן דיאלקט** — מבדיל בין ערבית ספרותית (فصحى) לערבית פלסטינית מדוברת (عامية)
4. **מייצא** — ל-JSONL, CSV, או כרטיסיות Anki

## התקנה

```bash
pip install -r requirements.txt

# Whisper דורש גם ffmpeg:
brew install ffmpeg  # macOS
# או
sudo apt install ffmpeg  # Linux
```

## שימוש

### חילוץ כתוביות

```bash
# מערוץ שלם
python cli.py fetch channel "https://www.youtube.com/@Makan33" --delay 3

# מפלייליסט
python cli.py fetch playlist "https://www.youtube.com/playlist?list=PLxxxxx"

# מסרטון בודד
python cli.py fetch video "https://www.youtube.com/watch?v=xxxxx"

# עם תמלול Whisper כ-fallback
python cli.py fetch channel "URL" --whisper-fallback --whisper-model medium
```

### ניקוי ועיבוד

```bash
# ניקוי + סינון דיאלקט + פילוח למשפטים
python cli.py process --filter-msa --min-length 3
```

### ייצוא

```bash
python cli.py export jsonl --output corpus.jsonl
python cli.py export csv --output corpus.csv
python cli.py export anki --output anki_deck.txt
```

### סטטיסטיקות

```bash
python cli.py stats
```

## הגדרות

ניתן לשנות הגדרות דרך משתני סביבה עם הקידומת `PAL_CORPUS_`:

| משתנה | ברירת מחדל | תיאור |
|---|---|---|
| `PAL_CORPUS_DB_PATH` | `corpus.db` | נתיב בסיס הנתונים |
| `PAL_CORPUS_WHISPER_MODEL` | `medium` | גודל מודל Whisper |
| `PAL_CORPUS_MIN_UTTERANCE_LENGTH` | `3` | מינימום מילים |
| `PAL_CORPUS_DIALECT_THRESHOLD` | `0.3` | סף ציון דיאלקט |
| `PAL_CORPUS_BATCH_SIZE` | `50` | סרטונים לעיבוד בריצה |
| `PAL_CORPUS_DEFAULT_DELAY` | `2.0` | השהיה בין בקשות (שניות) |

## ערוצים מומלצים

- [מכאן 33](https://www.youtube.com/@Makan33) — תוכניות מגוונות
- [מוסאוואה](https://www.youtube.com/@Musawa.channel) — חדשות וריאיונות
- [ואטן TV](https://www.youtube.com/@WattanTV) — תוכן פלסטיני
- [וטן ע אלוותר](https://www.youtube.com/@watanalawatar) — סדרות רשת

## מבנה הפרויקט

```
palestinian-corpus/
├── cli.py                  # Entry point — typer CLI
├── scraper/
│   ├── channel.py          # גילוי סרטונים מערוץ/פלייליסט
│   ├── subtitles.py        # חילוץ כתוביות
│   └── transcriber.py      # Whisper fallback
├── processor/
│   ├── cleaner.py          # ניקוי טקסט
│   ├── dialect_filter.py   # סינון ערבית ספרותית
│   └── segmenter.py        # פילוח למשפטים
├── storage/
│   ├── models.py           # מודלי נתונים
│   └── db.py               # SQLite
├── export/
│   └── exporter.py         # ייצוא JSONL/CSV/Anki
├── config.py               # הגדרות
└── requirements.txt
```

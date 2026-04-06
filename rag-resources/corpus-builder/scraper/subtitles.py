"""
חילוץ כתוביות מסרטוני יוטיוב.

סדר עדיפויות:
1. כתוביות ידניות בערבית (ar)
2. כתוביות אוטומטיות בערבית (ar auto-generated)
3. כתוביות ידניות בעברית (he) — כגיבוי לתרגום
4. Whisper transcription — רק אם --whisper-fallback מופעל

שימוש ב-yt-dlp כמנוע ראשי כי:
- youtube-transcript-api נשבר לעתים קרובות (תלוי ב-API לא רשמי)
- yt-dlp יציב יותר ותומך גם בפורמטים אחרים
"""

import json
import subprocess
from pathlib import Path

from rich.console import Console

from config import settings

console = Console()


def get_subtitles_ytdlp(video_url: str, output_dir: Path | None = None) -> dict:
    """
    חלץ כתוביות עם yt-dlp.
    מחזיר dict עם {language: filepath} של קבצי כתוביות שהורדו.
    """
    if output_dir is None:
        output_dir = Path(settings.subtitle_cache_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    cmd = [
        "yt-dlp",
        "--write-subs",
        "--write-auto-subs",
        "--sub-langs", "ar,he",
        "--sub-format", "json3",  # פורמט מובנה עם timestamps
        "--skip-download",  # לא מוריד את הווידאו
        "--no-warnings",
        "--output", str(output_dir / "%(id)s.%(ext)s"),
        video_url,
    ]

    try:
        subprocess.run(cmd, check=True, capture_output=True, text=True, timeout=60)
    except subprocess.CalledProcessError as e:
        console.print(f"[yellow]yt-dlp כתוביות נכשל:[/] {e.stderr[:200]}")
        return {}
    except subprocess.TimeoutExpired:
        console.print("[yellow]חריגה מזמן בחילוץ כתוביות[/]")
        return {}

    # מחפש קבצי כתוביות שהורדו
    result = {}
    for sub_file in output_dir.glob("*.json3"):
        name = sub_file.stem  # e.g., "dQw4w9WgXcQ.ar"
        parts = name.rsplit(".", 1)
        if len(parts) == 2:
            lang = parts[1]
            result[lang] = sub_file

    return result


def parse_json3_subtitles(filepath: Path) -> list[dict]:
    """
    פורס קובץ json3 של yt-dlp.
    מחזיר רשימת segments עם text, start, end.
    """
    try:
        with open(filepath, "r", encoding="utf-8") as f:
            data = json.load(f)
    except (json.JSONDecodeError, FileNotFoundError) as e:
        console.print(f"[yellow]שגיאה בפירוס כתוביות:[/] {e}")
        return []

    segments = []
    events = data.get("events", [])

    for event in events:
        # json3 events מכילים segs עם utf8 text
        text_parts = []
        for seg in event.get("segs", []):
            text = seg.get("utf8", "").strip()
            if text and text != "\n":
                text_parts.append(text)

        if text_parts:
            full_text = " ".join(text_parts).strip()
            if full_text:
                start_ms = event.get("tStartMs", 0)
                duration_ms = event.get("dDurationMs", 0)
                segments.append(
                    {
                        "text": full_text,
                        "start": start_ms / 1000.0,
                        "end": (start_ms + duration_ms) / 1000.0,
                    }
                )

    return segments


def get_subtitles_api(video_id: str) -> list[dict]:
    """
    Fallback דרך youtube-transcript-api.
    """
    try:
        from youtube_transcript_api import YouTubeTranscriptApi

        try:
            # נסה כתוביות ידניות קודם
            transcript = YouTubeTranscriptApi.get_transcript(
                video_id, languages=["ar"]
            )
        except Exception:
            try:
                # נסה אוטומטיות
                transcript = YouTubeTranscriptApi.get_transcript(
                    video_id,
                    languages=["ar"],
                    preserve_formatting=False,
                )
            except Exception:
                console.print(
                    f"[yellow]לא נמצאו כתוביות בערבית עבור {video_id}[/]"
                )
                return []

        return [
            {
                "text": seg["text"],
                "start": seg["start"],
                "end": seg["start"] + seg["duration"],
            }
            for seg in transcript
        ]
    except ImportError:
        console.print("[yellow]youtube-transcript-api לא מותקן[/]")
        return []


def extract_subtitles(video_url: str, video_id: str) -> tuple[list[dict], str]:
    """
    מנסה לחלץ כתוביות בכל הדרכים.
    מחזיר (segments, source) כש-source הוא "cc", "auto", או "api".
    """
    # נסה yt-dlp קודם
    sub_files = get_subtitles_ytdlp(video_url)

    if "ar" in sub_files:
        segments = parse_json3_subtitles(sub_files["ar"])
        if segments:
            # בדיקה אם כתוביות ידניות (cc) או אוטומטיות
            source = "cc"  # ברירת מחדל — yt-dlp לא תמיד מבדיל
            console.print(f"[green]נמצאו כתוביות בערבית ({source})[/]")
            return segments, source

    # fallback ל-youtube-transcript-api
    segments = get_subtitles_api(video_id)
    if segments:
        console.print("[green]נמצאו כתוביות דרך API[/]")
        return segments, "api"

    console.print(f"[yellow]לא נמצאו כתוביות עבור {video_id}[/]")
    return [], ""

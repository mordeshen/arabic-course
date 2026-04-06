"""
ייצוא הקורפוס לפורמטים שונים:
- JSONL: שורה אחת = utterance אחד. מצוין ל-fine-tuning / RAG
- CSV: לעבודה באקסל
- Anki: לכרטיסיות לימוד (ערבית → עברית)
"""

import csv
import json
from pathlib import Path

from rich.console import Console

from storage.db import get_all_utterances, get_all_videos, get_session
from storage.models import Utterance, Video
from sqlmodel import select

console = Console()


def export_jsonl(output_path: str, min_dialect_score: float | None = None):
    """
    ייצוא ל-JSONL.
    כל שורה: {"text": "...", "translation_he": "...", "source_video": "...", ...}
    """
    output = Path(output_path)
    count = 0

    with get_session() as session:
        stmt = select(Utterance, Video).join(Video, Utterance.video_id == Video.id)
        if min_dialect_score is not None:
            stmt = stmt.where(Utterance.dialect_score >= min_dialect_score)
        results = session.exec(stmt).all()

        with open(output, "w", encoding="utf-8") as f:
            for utterance, video in results:
                record = {
                    "text": utterance.text,
                    "translation_he": utterance.hebrew_translation,
                    "translation_en": utterance.english_translation,
                    "source_video": video.title,
                    "source_url": video.url,
                    "channel": video.channel,
                    "timestamp": utterance.start_time,
                    "dialect_score": utterance.dialect_score,
                }
                f.write(json.dumps(record, ensure_ascii=False) + "\n")
                count += 1

    console.print(f"[green]יוצאו {count} utterances ל-[/] {output}")


def export_csv(output_path: str, min_dialect_score: float | None = None):
    """ייצוא ל-CSV."""
    output = Path(output_path)
    count = 0

    with get_session() as session:
        stmt = select(Utterance, Video).join(Video, Utterance.video_id == Video.id)
        if min_dialect_score is not None:
            stmt = stmt.where(Utterance.dialect_score >= min_dialect_score)
        results = session.exec(stmt).all()

        with open(output, "w", encoding="utf-8", newline="") as f:
            writer = csv.writer(f)
            writer.writerow([
                "text", "translation_he", "translation_en",
                "source_video", "channel", "timestamp", "dialect_score",
            ])
            for utterance, video in results:
                writer.writerow([
                    utterance.text,
                    utterance.hebrew_translation or "",
                    utterance.english_translation or "",
                    video.title,
                    video.channel,
                    utterance.start_time,
                    utterance.dialect_score,
                ])
                count += 1

    console.print(f"[green]יוצאו {count} utterances ל-[/] {output}")


def export_anki(output_path: str, min_dialect_score: float | None = None):
    """
    ייצוא בפורמט TSV לייבוא ל-Anki.
    front (ערבית) \t back (עברית + הקשר)
    """
    output = Path(output_path)
    count = 0

    with get_session() as session:
        stmt = select(Utterance, Video).join(Video, Utterance.video_id == Video.id)
        if min_dialect_score is not None:
            stmt = stmt.where(Utterance.dialect_score >= min_dialect_score)
        results = session.exec(stmt).all()

        with open(output, "w", encoding="utf-8") as f:
            for utterance, video in results:
                front = utterance.text
                back_parts = []
                if utterance.hebrew_translation:
                    back_parts.append(utterance.hebrew_translation)
                if utterance.english_translation:
                    back_parts.append(utterance.english_translation)
                back_parts.append(f"מקור: {video.title}")
                back = " | ".join(back_parts)
                f.write(f"{front}\t{back}\n")
                count += 1

    console.print(f"[green]יוצאו {count} כרטיסיות Anki ל-[/] {output}")

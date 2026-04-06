"""
Palestinian Arabic Corpus Builder — כלי CLI לבניית קורפוס ערבית פלסטינית מדוברת.

שימוש:
    python cli.py fetch channel "URL"
    python cli.py fetch video "URL"
    python cli.py process --filter-msa
    python cli.py export jsonl --output corpus.jsonl
    python cli.py stats
"""

import time
from typing import Optional

import typer
from rich.console import Console
from rich.progress import Progress, SpinnerColumn, TextColumn, BarColumn
from rich.table import Table

from config import settings
from processor.cleaner import clean_segments
from processor.dialect_filter import compute_dialect_score, filter_msa
from processor.segmenter import segment_segments
from scraper.channel import get_single_video_info, get_video_list
from scraper.subtitles import extract_subtitles
from storage.db import (
    delete_utterance,
    get_all_utterances,
    get_all_videos,
    get_unprocessed_utterances,
    init_db,
    save_utterances,
    save_video,
    update_utterance,
    video_exists,
)
from storage.models import Utterance, Video

app = typer.Typer(help="כלי לבניית קורפוס ערבית פלסטינית מדוברת מיוטיוב")
console = Console()

# ——— פקודת fetch ———

fetch_app = typer.Typer(help="חילוץ כתוביות מיוטיוב")
app.add_typer(fetch_app, name="fetch")


def _process_video(
    video_info: dict,
    whisper_fallback: bool = False,
    whisper_model: str = "medium",
) -> bool:
    """מעבד סרטון בודד: חילוץ כתוביות ושמירה ל-DB. מחזיר True אם הצליח."""
    video_id = video_info["id"]

    if video_exists(video_id):
        console.print(f"[dim]דילוג — {video_id} כבר קיים ב-DB[/]")
        return False

    # חילוץ כתוביות
    segments, source = extract_subtitles(video_info["url"], video_id)

    # Whisper fallback
    if not segments and whisper_fallback:
        console.print(f"[blue]מנסה תמלול Whisper עבור {video_id}...[/]")
        from scraper.transcriber import transcribe_video

        segments = transcribe_video(video_info["url"], whisper_model)
        source = "whisper"

    if not segments:
        console.print(f"[yellow]אין כתוביות עבור {video_info['title']}[/]")
        return False

    # ניקוי בסיסי
    segments = clean_segments(segments)

    # שמירה ל-DB
    video = Video(
        youtube_id=video_id,
        title=video_info["title"],
        channel=video_info.get("channel", ""),
        url=video_info["url"],
        duration_seconds=video_info.get("duration", 0),
        subtitle_source=source,
        language_code="ar",
    )
    video = save_video(video)

    utterances = [
        Utterance(
            video_id=video.id,
            text=seg["text"],
            start_time=seg.get("start"),
            end_time=seg.get("end"),
        )
        for seg in segments
    ]
    save_utterances(utterances)

    console.print(
        f"[green]✓ {video_info['title']} — {len(utterances)} utterances[/]"
    )
    return True


@fetch_app.command("channel")
def fetch_channel(
    url: str = typer.Argument(..., help="כתובת ערוץ יוטיוב"),
    delay: float = typer.Option(2.0, help="השהיה בשניות בין סרטונים"),
    whisper_fallback: bool = typer.Option(False, "--whisper-fallback", help="תמלול Whisper כשאין כתוביות"),
    whisper_model: str = typer.Option("medium", "--whisper-model", help="גודל מודל Whisper"),
    batch_size: int = typer.Option(50, "--batch-size", help="מספר סרטונים מקסימלי"),
):
    """חילוץ כתוביות מערוץ יוטיוב שלם."""
    init_db()
    videos = get_video_list(url, batch_size=batch_size, delay=delay)

    if not videos:
        console.print("[red]לא נמצאו סרטונים[/]")
        raise typer.Exit(1)

    success_count = 0
    with Progress(
        SpinnerColumn(),
        TextColumn("[progress.description]{task.description}"),
        BarColumn(),
        TextColumn("[progress.percentage]{task.percentage:>3.0f}%"),
        console=console,
    ) as progress:
        task = progress.add_task("מעבד סרטונים...", total=len(videos))

        for video_info in videos:
            progress.update(task, description=f"[blue]{video_info['title'][:40]}...[/]")
            try:
                if _process_video(video_info, whisper_fallback, whisper_model):
                    success_count += 1
            except Exception as e:
                console.print(f"[red]שגיאה ב-{video_info['id']}:[/] {e}")
            progress.advance(task)
            time.sleep(delay)

    console.print(f"\n[bold green]סיום — {success_count}/{len(videos)} סרטונים עובדו בהצלחה[/]")


@fetch_app.command("playlist")
def fetch_playlist(
    url: str = typer.Argument(..., help="כתובת פלייליסט"),
    delay: float = typer.Option(2.0, help="השהיה בשניות בין סרטונים"),
    whisper_fallback: bool = typer.Option(False, "--whisper-fallback"),
    whisper_model: str = typer.Option("medium", "--whisper-model"),
    batch_size: int = typer.Option(50, "--batch-size"),
):
    """חילוץ כתוביות מפלייליסט."""
    # אותה לוגיקה כמו ערוץ — yt-dlp מטפל בשניהם
    init_db()
    videos = get_video_list(url, batch_size=batch_size, delay=delay)

    if not videos:
        console.print("[red]לא נמצאו סרטונים[/]")
        raise typer.Exit(1)

    success_count = 0
    with Progress(
        SpinnerColumn(),
        TextColumn("[progress.description]{task.description}"),
        BarColumn(),
        TextColumn("[progress.percentage]{task.percentage:>3.0f}%"),
        console=console,
    ) as progress:
        task = progress.add_task("מעבד סרטונים...", total=len(videos))

        for video_info in videos:
            progress.update(task, description=f"[blue]{video_info['title'][:40]}...[/]")
            try:
                if _process_video(video_info, whisper_fallback, whisper_model):
                    success_count += 1
            except Exception as e:
                console.print(f"[red]שגיאה ב-{video_info['id']}:[/] {e}")
            progress.advance(task)
            time.sleep(delay)

    console.print(f"\n[bold green]סיום — {success_count}/{len(videos)} סרטונים עובדו בהצלחה[/]")


@fetch_app.command("video")
def fetch_video(
    url: str = typer.Argument(..., help="כתובת סרטון"),
    whisper_fallback: bool = typer.Option(False, "--whisper-fallback"),
    whisper_model: str = typer.Option("medium", "--whisper-model"),
):
    """חילוץ כתוביות מסרטון בודד."""
    init_db()
    video_info = get_single_video_info(url)

    if not video_info:
        console.print("[red]לא ניתן לחלץ מידע על הסרטון[/]")
        raise typer.Exit(1)

    _process_video(video_info, whisper_fallback, whisper_model)


# ——— פקודת process ———

@app.command("process")
def process(
    filter_msa_flag: bool = typer.Option(False, "--filter-msa", help="סנן ערבית ספרותית"),
    min_length: int = typer.Option(3, "--min-length", help="מינימום מילים ב-utterance"),
    threshold: float = typer.Option(0.3, "--threshold", help="סף ציון דיאלקט"),
):
    """ניקוי, סינון דיאלקט ופילוח ה-utterances בבסיס הנתונים."""
    init_db()
    utterances = get_unprocessed_utterances()

    if not utterances:
        console.print("[yellow]אין utterances חדשים לעיבוד[/]")
        return

    console.print(f"[blue]מעבד {len(utterances)} utterances...[/]")

    processed = 0
    filtered_out = 0

    with Progress(
        SpinnerColumn(),
        TextColumn("[progress.description]{task.description}"),
        BarColumn(),
        console=console,
    ) as progress:
        task = progress.add_task("מעבד...", total=len(utterances))

        for utterance in utterances:
            # חישוב ציון דיאלקט
            score = compute_dialect_score(utterance.text)
            utterance.dialect_score = score

            # בדיקת אורך מינימלי
            word_count = len(utterance.text.split())

            if word_count < min_length:
                delete_utterance(utterance.id)
                filtered_out += 1
            elif filter_msa_flag and score < threshold:
                delete_utterance(utterance.id)
                filtered_out += 1
            else:
                update_utterance(utterance)
                processed += 1

            progress.advance(task)

    console.print(
        f"[green]עובדו {processed} utterances, סוננו {filtered_out}[/]"
    )


# ——— פקודת export ———

export_app = typer.Typer(help="ייצוא הקורפוס")
app.add_typer(export_app, name="export")


@export_app.command("jsonl")
def export_jsonl_cmd(
    output: str = typer.Option("corpus.jsonl", "--output", "-o"),
    min_score: Optional[float] = typer.Option(None, "--min-score"),
):
    """ייצוא ל-JSONL."""
    init_db()
    from export.exporter import export_jsonl
    export_jsonl(output, min_score)


@export_app.command("csv")
def export_csv_cmd(
    output: str = typer.Option("corpus.csv", "--output", "-o"),
    min_score: Optional[float] = typer.Option(None, "--min-score"),
):
    """ייצוא ל-CSV."""
    init_db()
    from export.exporter import export_csv
    export_csv(output, min_score)


@export_app.command("anki")
def export_anki_cmd(
    output: str = typer.Option("anki_deck.txt", "--output", "-o"),
    min_score: Optional[float] = typer.Option(None, "--min-score"),
):
    """ייצוא לפורמט Anki."""
    init_db()
    from export.exporter import export_anki
    export_anki(output, min_score)


# ——— פקודת stats ———

@app.command("stats")
def stats():
    """הצגת סטטיסטיקות הקורפוס."""
    init_db()
    videos = get_all_videos()
    utterances = get_all_utterances()

    if not videos and not utterances:
        console.print("[yellow]בסיס הנתונים ריק[/]")
        return

    # מילים ייחודיות
    all_words = set()
    total_words = 0
    dialect_counts = {"عامية": 0, "فصحى": 0, "לא ידוע": 0}

    for u in utterances:
        words = u.text.split()
        total_words += len(words)
        all_words.update(words)

        if u.dialect_score is None:
            dialect_counts["לא ידוע"] += 1
        elif u.dialect_score >= 0.3:
            dialect_counts["عامية"] += 1
        else:
            dialect_counts["فصحى"] += 1

    # מקורות כתוביות
    source_counts = {}
    for v in videos:
        source_counts[v.subtitle_source] = source_counts.get(v.subtitle_source, 0) + 1

    # ערוצים
    channel_counts = {}
    for v in videos:
        channel_counts[v.channel] = channel_counts.get(v.channel, 0) + 1

    # טבלת סטטיסטיקות
    table = Table(title="סטטיסטיקות קורפוס", show_header=True)
    table.add_column("מדד", style="bold")
    table.add_column("ערך", justify="right")

    table.add_row("סרטונים", str(len(videos)))
    table.add_row("משפטים (utterances)", str(len(utterances)))
    table.add_row("מילים (סה\"כ)", f"{total_words:,}")
    table.add_row("מילים ייחודיות", f"{len(all_words):,}")
    table.add_row("", "")
    table.add_row("[bold]דיאלקט[/]", "")
    table.add_row("  عامية (מדוברת)", str(dialect_counts["عامية"]))
    table.add_row("  فصحى (ספרותית)", str(dialect_counts["فصحى"]))
    table.add_row("  לא מסווג", str(dialect_counts["לא ידוע"]))
    table.add_row("", "")
    table.add_row("[bold]מקורות כתוביות[/]", "")
    for source, count in source_counts.items():
        table.add_row(f"  {source}", str(count))
    table.add_row("", "")
    table.add_row("[bold]ערוצים[/]", "")
    for channel, count in sorted(channel_counts.items(), key=lambda x: -x[1])[:10]:
        table.add_row(f"  {channel}", str(count))

    console.print(table)


if __name__ == "__main__":
    app()

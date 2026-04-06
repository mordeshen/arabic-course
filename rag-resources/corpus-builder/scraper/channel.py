"""גילוי סרטונים מערוץ או פלייליסט ביוטיוב באמצעות yt-dlp."""

import json
import subprocess
import time

from rich.console import Console
from rich.progress import Progress

console = Console()


def get_video_list(url: str, batch_size: int = 50, delay: float = 2.0) -> list[dict]:
    """
    מחלץ רשימת סרטונים מערוץ או פלייליסט.
    מחזיר רשימת dicts עם: id, title, url, duration, channel.
    """
    console.print(f"[bold blue]מחלץ רשימת סרטונים מ-[/] {url}")

    cmd = [
        "yt-dlp",
        "--flat-playlist",
        "--dump-json",
        "--no-warnings",
        "--playlist-end", str(batch_size),
        url,
    ]

    try:
        result = subprocess.run(
            cmd, capture_output=True, text=True, check=True, timeout=120
        )
    except subprocess.CalledProcessError as e:
        console.print(f"[bold red]שגיאה בחילוץ רשימת סרטונים:[/] {e.stderr}")
        return []
    except subprocess.TimeoutExpired:
        console.print("[bold red]חריגה מזמן — yt-dlp לא הגיב תוך 2 דקות[/]")
        return []

    videos = []
    for line in result.stdout.strip().split("\n"):
        if not line.strip():
            continue
        try:
            data = json.loads(line)
            videos.append(
                {
                    "id": data.get("id", ""),
                    "title": data.get("title", "ללא כותרת"),
                    "url": f"https://www.youtube.com/watch?v={data.get('id', '')}",
                    "duration": data.get("duration") or 0,
                    "channel": data.get("channel", data.get("uploader", "")),
                }
            )
        except json.JSONDecodeError:
            continue

    console.print(f"[green]נמצאו {len(videos)} סרטונים[/]")
    return videos


def get_single_video_info(url: str) -> dict | None:
    """מחלץ מידע על סרטון בודד."""
    cmd = [
        "yt-dlp",
        "--dump-json",
        "--no-warnings",
        "--skip-download",
        url,
    ]

    try:
        result = subprocess.run(
            cmd, capture_output=True, text=True, check=True, timeout=60
        )
        data = json.loads(result.stdout)
        return {
            "id": data.get("id", ""),
            "title": data.get("title", "ללא כותרת"),
            "url": url,
            "duration": data.get("duration") or 0,
            "channel": data.get("channel", data.get("uploader", "")),
        }
    except (subprocess.CalledProcessError, json.JSONDecodeError, subprocess.TimeoutExpired) as e:
        console.print(f"[bold red]שגיאה בחילוץ מידע על סרטון:[/] {e}")
        return None

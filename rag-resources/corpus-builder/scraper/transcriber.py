"""
תמלול באמצעות Whisper — fallback כשאין כתוביות כלל.
- מודל medium מספיק לרוב — מודל large מדויק יותר אבל כבד
- Whisper תומך בערבית אבל לא תמיד מבחין בדיאלקט
- שמור את האודיו כ-mp3 (קטן) ולא wav
"""

import subprocess
import tempfile

from rich.console import Console

console = Console()


def transcribe_video(
    video_url: str, model_size: str = "medium"
) -> list[dict]:
    """
    מוריד אודיו מסרטון ומתמלל עם Whisper.
    מחזיר רשימת segments עם text, start, end.
    """
    try:
        import whisper
    except ImportError:
        console.print(
            "[bold red]openai-whisper לא מותקן. התקן עם: pip install openai-whisper[/]"
        )
        return []

    with tempfile.TemporaryDirectory() as tmpdir:
        audio_path = f"{tmpdir}/audio.mp3"
        console.print(f"[blue]מוריד אודיו מ-[/] {video_url}")

        try:
            subprocess.run(
                [
                    "yt-dlp",
                    "-x",
                    "--audio-format", "mp3",
                    "--audio-quality", "5",  # איכות סבירה, קובץ קטן
                    "-o", audio_path,
                    video_url,
                ],
                check=True,
                capture_output=True,
                text=True,
                timeout=300,
            )
        except subprocess.CalledProcessError as e:
            console.print(f"[bold red]שגיאה בהורדת אודיו:[/] {e.stderr[:200]}")
            return []
        except subprocess.TimeoutExpired:
            console.print("[bold red]חריגה מזמן בהורדת אודיו[/]")
            return []

        console.print(f"[blue]מתמלל עם Whisper ({model_size})...[/]")
        model = whisper.load_model(model_size)
        result = model.transcribe(
            audio_path,
            language="ar",
            task="transcribe",
            word_timestamps=True,
        )

    return [
        {
            "text": seg["text"].strip(),
            "start": seg["start"],
            "end": seg["end"],
        }
        for seg in result["segments"]
        if seg["text"].strip()
    ]

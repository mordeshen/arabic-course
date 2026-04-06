"""מודלים של בסיס הנתונים — טבלאות Video ו-Utterance."""

from datetime import datetime
from typing import Optional

from sqlmodel import Field, SQLModel


class Video(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    youtube_id: str = Field(unique=True, index=True)
    title: str
    channel: str
    url: str
    duration_seconds: int
    subtitle_source: str  # "cc", "auto", "whisper"
    language_code: str  # "ar", "ar-PL" etc.
    fetched_at: datetime = Field(default_factory=datetime.utcnow)
    is_msa: Optional[bool] = None  # True = فصحى, False = عامية


class Utterance(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    video_id: int = Field(foreign_key="video.id", index=True)
    text: str  # הטקסט בערבית
    start_time: Optional[float] = None  # שנייה בסרטון
    end_time: Optional[float] = None
    speaker: Optional[str] = None  # אם ניתן לזהות
    hebrew_translation: Optional[str] = None
    english_translation: Optional[str] = None
    notes: Optional[str] = None  # הערות ידניות
    dialect_score: Optional[float] = None  # 0=فصحى, 1=عامية

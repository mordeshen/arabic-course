"""הגדרות הפרויקט — ניתנות לשינוי דרך משתני סביבה."""

from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    db_path: str = "corpus.db"
    whisper_model: str = "medium"
    min_utterance_length: int = 3  # מינימום מילים ב-utterance
    dialect_threshold: float = 0.3  # מעל = عامية
    batch_size: int = 50  # סרטונים לעיבוד בכל ריצה
    subtitle_cache_dir: str = ".cache/subs"
    audio_cache_dir: str = ".cache/audio"
    default_delay: float = 2.0  # שניות בין בקשות ליוטיוב

    class Config:
        env_prefix = "PAL_CORPUS_"  # PAL_CORPUS_DB_PATH=... etc.


settings = Settings()

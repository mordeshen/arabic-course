"""חיבור ל-SQLite וניהול בסיס הנתונים."""

from sqlmodel import Session, SQLModel, create_engine, select

from config import settings
from storage.models import Utterance, Video

engine = create_engine(f"sqlite:///{settings.db_path}", echo=False)


def init_db():
    """יצירת טבלאות אם לא קיימות."""
    SQLModel.metadata.create_all(engine)


def get_session() -> Session:
    """מחזיר session חדש."""
    return Session(engine)


def video_exists(youtube_id: str) -> bool:
    """בודק אם סרטון כבר קיים ב-DB — לשמירה על idempotency."""
    with get_session() as session:
        stmt = select(Video).where(Video.youtube_id == youtube_id)
        return session.exec(stmt).first() is not None


def save_video(video: Video) -> Video:
    """שומר סרטון חדש ומחזיר עם ID."""
    with get_session() as session:
        session.add(video)
        session.commit()
        session.refresh(video)
        return video


def save_utterances(utterances: list[Utterance]):
    """שומר רשימת utterances."""
    with get_session() as session:
        for u in utterances:
            session.add(u)
        session.commit()


def get_all_utterances(min_dialect_score: float | None = None) -> list[Utterance]:
    """מחזיר את כל ה-utterances, עם סינון אופציונלי לפי ציון דיאלקט."""
    with get_session() as session:
        stmt = select(Utterance)
        if min_dialect_score is not None:
            stmt = stmt.where(Utterance.dialect_score >= min_dialect_score)
        return session.exec(stmt).all()


def get_all_videos() -> list[Video]:
    """מחזיר את כל הסרטונים."""
    with get_session() as session:
        return session.exec(select(Video)).all()


def get_unprocessed_utterances() -> list[Utterance]:
    """מחזיר utterances שעדיין לא עברו סינון דיאלקט."""
    with get_session() as session:
        stmt = select(Utterance).where(Utterance.dialect_score == None)  # noqa: E711
        return session.exec(stmt).all()


def update_utterance(utterance: Utterance):
    """מעדכן utterance קיים."""
    with get_session() as session:
        session.add(utterance)
        session.commit()


def delete_utterance(utterance_id: int):
    """מוחק utterance לפי ID."""
    with get_session() as session:
        stmt = select(Utterance).where(Utterance.id == utterance_id)
        utterance = session.exec(stmt).first()
        if utterance:
            session.delete(utterance)
            session.commit()

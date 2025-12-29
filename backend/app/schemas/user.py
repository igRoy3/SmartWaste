from pydantic import BaseModel, ConfigDict
from datetime import datetime


class UserRead(BaseModel):
    id: int
    uid: str
    email: str | None
    name: str | None

    model_config = ConfigDict(from_attributes=True)


class PracticeSessionRead(BaseModel):
    id: int
    user_id: int | None
    transcription: str
    corrected_text: str | None
    feedback: str | None
    score: int | None
    created_at: datetime | None

    model_config = ConfigDict(from_attributes=True)


class UserStatsRead(BaseModel):
    total_sessions: int
    average_score: int
    best_score: int
    first_session: datetime | None
    last_session: datetime | None

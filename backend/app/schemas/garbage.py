from pydantic import BaseModel, ConfigDict, Field
from datetime import datetime
from typing import Literal


class GarbageReportCreate(BaseModel):
    location_lat: float = Field(..., ge=-90, le=90, description="Latitude of garbage location")
    location_lng: float = Field(..., ge=-180, le=180, description="Longitude of garbage location")
    address: str | None = None
    description: str | None = None


class GarbageReportRead(BaseModel):
    id: int
    citizen_id: int
    collector_id: int | None
    photo_url: str
    location_lat: float
    location_lng: float
    address: str | None
    description: str | None
    status: Literal["pending", "assigned", "in_progress", "completed", "rejected"]
    created_at: datetime
    updated_at: datetime
    assigned_at: datetime | None
    completed_at: datetime | None

    model_config = ConfigDict(from_attributes=True)


class GarbageReportUpdate(BaseModel):
    status: Literal["pending", "assigned", "in_progress", "completed", "rejected"] | None = None
    collector_id: int | None = None


class GarbageReportAssign(BaseModel):
    collector_id: int


class TaskRead(BaseModel):
    id: int
    citizen_id: int
    citizen_name: str | None
    photo_url: str
    location_lat: float
    location_lng: float
    address: str | None
    description: str | None
    status: Literal["pending", "assigned", "in_progress", "completed", "rejected"]
    created_at: datetime
    assigned_at: datetime | None

    model_config = ConfigDict(from_attributes=True)


class AdminStatsRead(BaseModel):
    total_reports: int
    pending_reports: int
    assigned_reports: int
    in_progress_reports: int
    completed_reports: int
    total_collectors: int
    total_citizens: int

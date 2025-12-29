from sqlalchemy import Column, Integer, String, DateTime, Text, ForeignKey, Float, Enum
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.db.session import Base
import enum


class UserRole(str, enum.Enum):
    CITIZEN = "citizen"
    ADMIN = "admin"
    COLLECTOR = "collector"


class ReportStatus(str, enum.Enum):
    PENDING = "pending"
    ASSIGNED = "assigned"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"
    REJECTED = "rejected"


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    uid = Column(String, unique=True, index=True, nullable=False)
    email = Column(String, unique=True, index=True, nullable=True)
    name = Column(String, nullable=True)
    role = Column(Enum(UserRole), default=UserRole.CITIZEN, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Relationships
    practice_sessions = relationship("PracticeSession", back_populates="user")
    garbage_reports = relationship("GarbageReport", foreign_keys="GarbageReport.citizen_id", back_populates="citizen")
    assigned_tasks = relationship("GarbageReport", foreign_keys="GarbageReport.collector_id", back_populates="collector")


class PracticeSession(Base):
    __tablename__ = "practice_sessions"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    transcription = Column(Text, nullable=False)
    corrected_text = Column(Text, nullable=True)
    feedback = Column(Text, nullable=True)
    score = Column(Integer, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Relationships
    user = relationship("User", back_populates="practice_sessions")


class GarbageReport(Base):
    __tablename__ = "garbage_reports"

    id = Column(Integer, primary_key=True, index=True)
    citizen_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    collector_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    photo_url = Column(String, nullable=False)
    location_lat = Column(Float, nullable=False)
    location_lng = Column(Float, nullable=False)
    address = Column(String, nullable=True)
    description = Column(Text, nullable=True)
    status = Column(Enum(ReportStatus), default=ReportStatus.PENDING, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    assigned_at = Column(DateTime(timezone=True), nullable=True)
    completed_at = Column(DateTime(timezone=True), nullable=True)
    
    # Relationships
    citizen = relationship("User", foreign_keys=[citizen_id], back_populates="garbage_reports")
    collector = relationship("User", foreign_keys=[collector_id], back_populates="assigned_tasks")

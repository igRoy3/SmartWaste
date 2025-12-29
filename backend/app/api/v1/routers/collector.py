"""Collector endpoints for managing assigned tasks."""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from datetime import datetime, timezone

from app.db.session import get_db
from app.db.models import User, GarbageReport, ReportStatus
from app.core.security import get_current_collector
from app.schemas.garbage import TaskRead, GarbageReportRead


router = APIRouter()


@router.get("/tasks", response_model=List[GarbageReportRead])
async def get_assigned_tasks(
    current_user: User = Depends(get_current_collector),
    db: Session = Depends(get_db),
    skip: int = 0,
    limit: int = 100
):
    """Get all tasks assigned to current collector."""
    tasks = db.query(GarbageReport).filter(
        GarbageReport.collector_id == current_user.id,
        GarbageReport.status.in_([ReportStatus.ASSIGNED, ReportStatus.IN_PROGRESS])
    ).order_by(GarbageReport.assigned_at.desc()).offset(skip).limit(limit).all()
    
    return tasks


@router.get("/tasks/{task_id}", response_model=GarbageReportRead)
async def get_task_detail(
    task_id: int,
    current_user: User = Depends(get_current_collector),
    db: Session = Depends(get_db)
):
    """Get specific task details with location."""
    task = db.query(GarbageReport).filter(GarbageReport.id == task_id).first()
    
    if not task:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Task not found"
        )
    
    # Collectors can only view their assigned tasks
    if task.collector_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to view this task"
        )
    
    return task


@router.put("/tasks/{task_id}/start", response_model=GarbageReportRead)
async def start_task(
    task_id: int,
    current_user: User = Depends(get_current_collector),
    db: Session = Depends(get_db)
):
    """Mark task as in progress."""
    task = db.query(GarbageReport).filter(GarbageReport.id == task_id).first()
    
    if not task:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Task not found"
        )
    
    if task.collector_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to modify this task"
        )
    
    if task.status != ReportStatus.ASSIGNED:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Task must be in assigned status to start"
        )
    
    task.status = ReportStatus.IN_PROGRESS
    db.commit()
    db.refresh(task)
    
    return task


@router.put("/tasks/{task_id}/complete", response_model=GarbageReportRead)
async def complete_task(
    task_id: int,
    current_user: User = Depends(get_current_collector),
    db: Session = Depends(get_db)
):
    """Mark task as completed."""
    task = db.query(GarbageReport).filter(GarbageReport.id == task_id).first()
    
    if not task:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Task not found"
        )
    
    if task.collector_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to modify this task"
        )
    
    if task.status not in [ReportStatus.ASSIGNED, ReportStatus.IN_PROGRESS]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Task must be assigned or in progress to complete"
        )
    
    task.status = ReportStatus.COMPLETED
    task.completed_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(task)
    
    return task


@router.get("/history", response_model=List[GarbageReportRead])
async def get_completed_tasks(
    current_user: User = Depends(get_current_collector),
    db: Session = Depends(get_db),
    skip: int = 0,
    limit: int = 100
):
    """Get all completed tasks by current collector."""
    tasks = db.query(GarbageReport).filter(
        GarbageReport.collector_id == current_user.id,
        GarbageReport.status == ReportStatus.COMPLETED
    ).order_by(GarbageReport.completed_at.desc()).offset(skip).limit(limit).all()
    
    return tasks

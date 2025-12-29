"""Admin endpoints for managing garbage reports."""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import List
from datetime import datetime, timezone

from app.db.session import get_db
from app.db.models import User, GarbageReport, ReportStatus, UserRole
from app.core.security import get_current_admin
from app.schemas.garbage import (
    GarbageReportRead,
    GarbageReportAssign,
    AdminStatsRead
)


router = APIRouter()


@router.get("/reports", response_model=List[GarbageReportRead])
async def get_all_reports(
    current_user: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
    status_filter: str | None = None,
    skip: int = 0,
    limit: int = 100
):
    """Get all garbage reports with optional status filter."""
    query = db.query(GarbageReport)
    
    if status_filter:
        try:
            status_enum = ReportStatus(status_filter)
            query = query.filter(GarbageReport.status == status_enum)
        except ValueError:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Invalid status: {status_filter}"
            )
    
    reports = query.order_by(GarbageReport.created_at.desc()).offset(skip).limit(limit).all()
    return reports


@router.get("/reports/{report_id}", response_model=GarbageReportRead)
async def get_report_detail(
    report_id: int,
    current_user: User = Depends(get_current_admin),
    db: Session = Depends(get_db)
):
    """Get specific report details."""
    report = db.query(GarbageReport).filter(GarbageReport.id == report_id).first()
    
    if not report:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Report not found"
        )
    
    return report


@router.put("/reports/{report_id}/assign", response_model=GarbageReportRead)
async def assign_report(
    report_id: int,
    assignment: GarbageReportAssign,
    current_user: User = Depends(get_current_admin),
    db: Session = Depends(get_db)
):
    """Assign a report to a collector."""
    report = db.query(GarbageReport).filter(GarbageReport.id == report_id).first()
    
    if not report:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Report not found"
        )
    
    # Verify collector exists and has collector role
    collector = db.query(User).filter(User.id == assignment.collector_id).first()
    if not collector:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Collector not found"
        )
    
    if collector.role not in [UserRole.COLLECTOR, UserRole.ADMIN]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User is not a collector"
        )
    
    # Update report
    report.collector_id = assignment.collector_id
    report.status = ReportStatus.ASSIGNED
    report.assigned_at = datetime.now(timezone.utc)
    
    db.commit()
    db.refresh(report)
    
    return report


@router.get("/collectors", response_model=List[dict])
async def get_collectors(
    current_user: User = Depends(get_current_admin),
    db: Session = Depends(get_db)
):
    """Get all collectors."""
    collectors = db.query(User).filter(
        User.role.in_([UserRole.COLLECTOR, UserRole.ADMIN])
    ).all()
    
    return [
        {
            "id": collector.id,
            "name": collector.name,
            "email": collector.email,
            "role": collector.role.value
        }
        for collector in collectors
    ]


@router.get("/stats", response_model=AdminStatsRead)
async def get_stats(
    current_user: User = Depends(get_current_admin),
    db: Session = Depends(get_db)
):
    """Get admin statistics."""
    total_reports = db.query(func.count(GarbageReport.id)).scalar()
    pending_reports = db.query(func.count(GarbageReport.id)).filter(
        GarbageReport.status == ReportStatus.PENDING
    ).scalar()
    assigned_reports = db.query(func.count(GarbageReport.id)).filter(
        GarbageReport.status == ReportStatus.ASSIGNED
    ).scalar()
    in_progress_reports = db.query(func.count(GarbageReport.id)).filter(
        GarbageReport.status == ReportStatus.IN_PROGRESS
    ).scalar()
    completed_reports = db.query(func.count(GarbageReport.id)).filter(
        GarbageReport.status == ReportStatus.COMPLETED
    ).scalar()
    total_collectors = db.query(func.count(User.id)).filter(
        User.role == UserRole.COLLECTOR
    ).scalar()
    total_citizens = db.query(func.count(User.id)).filter(
        User.role == UserRole.CITIZEN
    ).scalar()
    
    return AdminStatsRead(
        total_reports=total_reports or 0,
        pending_reports=pending_reports or 0,
        assigned_reports=assigned_reports or 0,
        in_progress_reports=in_progress_reports or 0,
        completed_reports=completed_reports or 0,
        total_collectors=total_collectors or 0,
        total_citizens=total_citizens or 0
    )

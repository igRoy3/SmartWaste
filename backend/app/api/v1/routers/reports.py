"""Garbage report endpoints for citizens."""
from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File, Form
from sqlalchemy.orm import Session
from typing import List
import os
import uuid
from pathlib import Path

from app.db.session import get_db
from app.db.models import User, GarbageReport, ReportStatus
from app.core.security import get_current_citizen
from app.schemas.garbage import GarbageReportCreate, GarbageReportRead


router = APIRouter()

# Configure upload directory
UPLOAD_DIR = Path("uploads/garbage_photos")
UPLOAD_DIR.mkdir(parents=True, exist_ok=True)


@router.post("", response_model=GarbageReportRead, status_code=status.HTTP_201_CREATED)
async def create_report(
    location_lat: float = Form(...),
    location_lng: float = Form(...),
    address: str = Form(None),
    description: str = Form(None),
    photo: UploadFile = File(...),
    current_user: User = Depends(get_current_citizen),
    db: Session = Depends(get_db)
):
    """Create a new garbage report with photo."""
    # Validate file type
    if not photo.content_type.startswith("image/"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="File must be an image"
        )
    
    # Generate unique filename
    file_extension = os.path.splitext(photo.filename)[1]
    unique_filename = f"{uuid.uuid4()}{file_extension}"
    file_path = UPLOAD_DIR / unique_filename
    
    # Save file
    with open(file_path, "wb") as buffer:
        content = await photo.read()
        buffer.write(content)
    
    # Create report
    report = GarbageReport(
        citizen_id=current_user.id,
        photo_url=f"/uploads/garbage_photos/{unique_filename}",
        location_lat=location_lat,
        location_lng=location_lng,
        address=address,
        description=description,
        status=ReportStatus.PENDING
    )
    
    db.add(report)
    db.commit()
    db.refresh(report)
    
    return report


@router.get("", response_model=List[GarbageReportRead])
async def get_my_reports(
    current_user: User = Depends(get_current_citizen),
    db: Session = Depends(get_db),
    skip: int = 0,
    limit: int = 100
):
    """Get all reports created by current citizen."""
    reports = db.query(GarbageReport).filter(
        GarbageReport.citizen_id == current_user.id
    ).order_by(GarbageReport.created_at.desc()).offset(skip).limit(limit).all()
    
    return reports


@router.get("/{report_id}", response_model=GarbageReportRead)
async def get_report(
    report_id: int,
    current_user: User = Depends(get_current_citizen),
    db: Session = Depends(get_db)
):
    """Get specific report details."""
    report = db.query(GarbageReport).filter(GarbageReport.id == report_id).first()
    
    if not report:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Report not found"
        )
    
    # Citizens can only view their own reports
    if report.citizen_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to view this report"
        )
    
    return report

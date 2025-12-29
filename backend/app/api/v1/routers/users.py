from fastapi import APIRouter, Depends, Header, HTTPException, status, Query
from firebase_admin import auth as firebase_auth
from sqlalchemy.orm import Session
from sqlalchemy import func

from app.db.session import get_db
from app.db import models
from app.schemas.user import UserRead, PracticeSessionRead, UserStatsRead

router = APIRouter()


def get_current_user_from_token(
    authorization: str | None = Header(None), 
    db: Session = Depends(get_db)
) -> models.User:
    """Dependency to extract and validate the current user from Firebase token."""
    if not authorization:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Missing Authorization header")

    parts = authorization.split()
    if len(parts) != 2 or parts[0].lower() != "bearer":
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid Authorization header format")

    token = parts[1]
    try:
        decoded = firebase_auth.verify_id_token(token)
    except Exception:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token")

    uid = decoded.get("uid")
    email = decoded.get("email")
    name = decoded.get("name") or decoded.get("display_name")

    user = db.query(models.User).filter(models.User.uid == uid).first()
    if not user:
        user = models.User(uid=uid, email=email, name=name)
        db.add(user)
        db.commit()
        db.refresh(user)

    return user


@router.get("/me", response_model=UserRead)
async def get_current_user(user: models.User = Depends(get_current_user_from_token)):
    """Get the current authenticated user's profile."""
    return user


@router.get("/me/sessions", response_model=list[PracticeSessionRead])
async def get_user_sessions(
    user: models.User = Depends(get_current_user_from_token),
    db: Session = Depends(get_db),
    limit: int = Query(default=20, le=100),
    offset: int = Query(default=0, ge=0),
):
    """Get the current user's practice session history."""
    sessions = (
        db.query(models.PracticeSession)
        .filter(models.PracticeSession.user_id == user.id)
        .order_by(models.PracticeSession.created_at.desc())
        .offset(offset)
        .limit(limit)
        .all()
    )
    return sessions


@router.get("/me/stats", response_model=UserStatsRead)
async def get_user_stats(
    user: models.User = Depends(get_current_user_from_token),
    db: Session = Depends(get_db),
):
    """Get aggregated statistics for the current user's practice sessions."""
    stats = db.query(
        func.count(models.PracticeSession.id).label("total_sessions"),
        func.avg(models.PracticeSession.score).label("average_score"),
        func.max(models.PracticeSession.score).label("best_score"),
        func.min(models.PracticeSession.created_at).label("first_session"),
        func.max(models.PracticeSession.created_at).label("last_session"),
    ).filter(models.PracticeSession.user_id == user.id).first()
    
    return UserStatsRead(
        total_sessions=stats.total_sessions or 0,
        average_score=round(stats.average_score or 0),
        best_score=stats.best_score or 0,
        first_session=stats.first_session,
        last_session=stats.last_session,
    )

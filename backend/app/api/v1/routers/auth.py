"""Authentication endpoints."""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from pydantic import BaseModel, EmailStr

from app.db.session import get_db
from app.db.models import User, UserRole
from app.core.security import create_access_token
from app.schemas.user import UserRead


router = APIRouter()


class RegisterRequest(BaseModel):
    uid: str
    email: EmailStr | None = None
    name: str | None = None
    role: str = "citizen"


class LoginRequest(BaseModel):
    uid: str


class AuthResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserRead


@router.post("/register", response_model=AuthResponse)
async def register(
    request: RegisterRequest,
    db: Session = Depends(get_db)
):
    """Register a new user."""
    # Check if user already exists
    existing_user = db.query(User).filter(User.uid == request.uid).first()
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User already exists"
        )
    
    # Validate role
    if request.role not in ["citizen", "admin", "collector"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid role"
        )
    
    # Create new user
    user = User(
        uid=request.uid,
        email=request.email,
        name=request.name,
        role=UserRole(request.role)
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    
    # Create access token
    access_token = create_access_token(user.id, user.uid, user.role.value)
    
    return AuthResponse(
        access_token=access_token,
        user=UserRead.model_validate(user)
    )


@router.post("/login", response_model=AuthResponse)
async def login(
    request: LoginRequest,
    db: Session = Depends(get_db)
):
    """Login existing user."""
    user = db.query(User).filter(User.uid == request.uid).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    # Create access token
    access_token = create_access_token(user.id, user.uid, user.role.value)
    
    return AuthResponse(
        access_token=access_token,
        user=UserRead.model_validate(user)
    )

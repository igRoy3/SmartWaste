from fastapi import APIRouter

from .routers import speech, users

api_router = APIRouter()

api_router.include_router(speech.router, prefix="/speech", tags=["speech"])
api_router.include_router(users.router, prefix="/users", tags=["users"])

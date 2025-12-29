from fastapi import APIRouter

from .routers import speech, users, auth, reports, admin, collector

api_router = APIRouter()

api_router.include_router(speech.router, prefix="/speech", tags=["speech"])
api_router.include_router(users.router, prefix="/users", tags=["users"])
api_router.include_router(auth.router, prefix="/auth", tags=["auth"])
api_router.include_router(reports.router, prefix="/reports", tags=["reports"])
api_router.include_router(admin.router, prefix="/admin", tags=["admin"])
api_router.include_router(collector.router, prefix="/collector", tags=["collector"])

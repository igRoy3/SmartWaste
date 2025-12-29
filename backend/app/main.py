from contextlib import asynccontextmanager
import logging

from fastapi import FastAPI, Request, Response
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from slowapi import _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded

from app.api.v1 import api_router
from app.db.session import engine, Base
from app.core.config import settings
from app.core.logging import setup_logging, get_logger
from app.core.security import limiter, SECURITY_HEADERS

# Initialize Sentry for error tracking (production)
if settings.sentry_dsn:
    import sentry_sdk
    sentry_sdk.init(
        dsn=settings.sentry_dsn,
        environment=settings.environment,
        traces_sample_rate=0.1 if settings.is_production else 1.0,
        profiles_sample_rate=0.1 if settings.is_production else 1.0,
    )

# Setup logging
setup_logging()
logger = get_logger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    logger.info(f"Starting FluentMind API in {settings.environment} mode")
    Base.metadata.create_all(bind=engine)
    logger.info("Database tables initialized")
    yield
    # Shutdown
    logger.info("Shutting down FluentMind API")


app = FastAPI(
    title="FluentMind Backend",
    description="AI-powered language learning API",
    version="1.0.0",
    lifespan=lifespan,
    docs_url="/docs" if not settings.is_production else None,  # Disable docs in prod
    redoc_url="/redoc" if not settings.is_production else None,
)

# Rate limiting
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.middleware("http")
async def add_security_headers(request: Request, call_next):
    """Add security headers to all responses."""
    response: Response = await call_next(request)
    
    # Add security headers in production
    if settings.is_production:
        for header, value in SECURITY_HEADERS.items():
            response.headers[header] = value
    
    return response


@app.middleware("http")
async def log_requests(request: Request, call_next):
    """Log all incoming requests."""
    import time
    start_time = time.time()
    
    response = await call_next(request)
    
    process_time = time.time() - start_time
    logger.info(
        f"{request.method} {request.url.path}",
        extra={
            "method": request.method,
            "path": request.url.path,
            "status_code": response.status_code,
            "process_time_ms": round(process_time * 1000, 2),
            "client_ip": request.client.host if request.client else "unknown",
        }
    )
    
    return response


@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    """Global exception handler to catch unhandled errors."""
    logger.exception(f"Unhandled exception: {exc}")
    
    # Don't expose internal errors in production
    if settings.is_production:
        return JSONResponse(
            status_code=500,
            content={"detail": "An internal error occurred. Please try again later."}
        )
    
    return JSONResponse(
        status_code=500,
        content={"detail": str(exc)}
    )


# Include API routes
app.include_router(api_router, prefix="/api/v1")


@app.get("/")
async def root():
    return {
        "status": "ok",
        "service": "fluentmind-backend",
        "version": "1.0.0",
        "environment": settings.environment,
    }


@app.get("/health")
async def health():
    """Health check endpoint for load balancers and monitoring."""
    return {
        "status": "healthy",
        "environment": settings.environment,
    }

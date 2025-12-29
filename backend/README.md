# SmartWaste — Backend

Production-ready FastAPI backend for SmartWaste garbage management system.

## Features

- 🗑️ **Garbage Reporting** — Citizens report garbage with photo & location
- 👨‍💼 **Admin Dashboard** — View all reports, assign to collectors, track stats
- 🚛 **Collector Tasks** — View assigned tasks, navigate to location, complete tasks
- 🔐 **JWT Auth** — Secure token-based authentication
- 👥 **Role-Based Access** — Citizen, Admin, Collector roles
- 📊 **Statistics** — Real-time metrics and reporting
- 🚀 **Production-Ready** — Rate limiting, CORS, logging, Sentry

## Quick Start

### Development

```bash
# Setup
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Configure
cp .env.example .env
# Edit .env and set JWT_SECRET_KEY

# Run
uvicorn app.main:app --reload
```

### Docker (with PostgreSQL)

```bash
docker-compose up -d
```

## API Endpoints

### Authentication
| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/v1/auth/register` | POST | Register new user |
| `/api/v1/auth/login` | POST | Login user |

### Citizen Endpoints
| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/v1/reports` | POST | Create garbage report |
| `/api/v1/reports` | GET | Get my reports |
| `/api/v1/reports/{id}` | GET | Get report details |

### Admin Endpoints
| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/v1/admin/reports` | GET | Get all reports |
| `/api/v1/admin/reports/{id}/assign` | PUT | Assign to collector |
| `/api/v1/admin/collectors` | GET | Get all collectors |
| `/api/v1/admin/stats` | GET | Get statistics |

### Collector Endpoints
| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/v1/collector/tasks` | GET | Get assigned tasks |
| `/api/v1/collector/tasks/{id}` | GET | Get task details |
| `/api/v1/collector/tasks/{id}/start` | PUT | Mark task as in progress |
| `/api/v1/collector/tasks/{id}/complete` | PUT | Mark as completed |
| `/api/v1/collector/history` | GET | Get completed tasks |

## Environment Variables

See `.env.example` for all options. Key variables:

| Variable | Description | Required |
|----------|-------------|----------|
| `DATABASE_URL` | Database connection string | ✅ |
| `JWT_SECRET_KEY` | Secret key for JWT tokens | ✅ |
| `ENVIRONMENT` | development / production | ❌ |
| `SENTRY_DSN` | Sentry error tracking | ❌ |

## Database Models

### User
- Supports 3 roles: citizen, admin, collector
- Firebase UID authentication
- Links to garbage reports and tasks

### GarbageReport
- Photo upload with location (lat/lng)
- Status: pending, assigned, in_progress, completed, rejected
- Timestamps for created, updated, assigned, completed

## Database Migrations

```bash
# Create a new migration
alembic revision --autogenerate -m "description"

# Apply migrations
alembic upgrade head
```

## Production Deployment

```bash
# Build and run production containers
docker-compose -f docker-compose.prod.yml up -d

# Or deploy to Railway/Render with the Dockerfile
```

## Testing

```bash
pytest tests/ -v
```

## Security Features

- JWT token-based authentication
- Role-based access control
- Rate limiting
- CORS configuration
- File upload validation
- Security headers
- Sentry error tracking

# FluentMind — Backend

Production-ready FastAPI backend for FluentMind language learning app.

## Features

- 🎙️ **Speech-to-Text** — Whisper API transcription
- 🤖 **AI Feedback** — GPT-powered language coaching
- 🔐 **Firebase Auth** — Secure user authentication
- 📊 **Progress Tracking** — Practice sessions & statistics
- 🚀 **Production-Ready** — Rate limiting, CORS, logging, Sentry

## Quick Start

### Development

```bash
# Setup
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

# Configure
cp .env.example .env
# Edit .env and add your OPENAI_API_KEY

# Run
uvicorn app.main:app --reload
```

### Docker (with PostgreSQL)

```bash
docker-compose up -d
```

## API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/v1/speech/transcribe` | POST | Transcribe audio file |
| `/api/v1/speech/feedback` | POST | Get AI language feedback |
| `/api/v1/speech/practice` | POST | Combined transcribe + feedback |
| `/api/v1/users/me` | GET | Get current user profile |
| `/api/v1/users/me/sessions` | GET | Get practice history |
| `/api/v1/users/me/stats` | GET | Get aggregated stats |

## Environment Variables

See `.env.example` for all options. Key variables:

| Variable | Description | Required |
|----------|-------------|----------|
| `OPENAI_API_KEY` | OpenAI API key | ✅ |
| `DATABASE_URL` | Database connection string | ✅ |
| `FIREBASE_CREDENTIALS_PATH` | Path to Firebase JSON | ✅ |
| `ENVIRONMENT` | development / production | ❌ |
| `SENTRY_DSN` | Sentry error tracking | ❌ |

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

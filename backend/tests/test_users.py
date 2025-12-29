"""Tests for user endpoints and authentication."""
import pytest
from unittest.mock import patch, MagicMock
from datetime import datetime

from app.db import models


def test_get_current_user_no_auth_header(client):
    """Test /users/me without authorization header."""
    response = client.get("/api/v1/users/me")
    assert response.status_code == 401
    assert "Missing Authorization header" in response.json()["detail"]


def test_get_current_user_invalid_header_format(client):
    """Test /users/me with invalid authorization header format."""
    response = client.get(
        "/api/v1/users/me",
        headers={"Authorization": "InvalidFormat"}
    )
    assert response.status_code == 401
    assert "Invalid Authorization header format" in response.json()["detail"]


@patch("app.api.v1.routers.users.firebase_auth")
def test_get_current_user_invalid_token(mock_firebase_auth, client):
    """Test /users/me with invalid Firebase token."""
    mock_firebase_auth.verify_id_token.side_effect = Exception("Invalid token")
    
    response = client.get(
        "/api/v1/users/me",
        headers={"Authorization": "Bearer invalid-token"}
    )
    assert response.status_code == 401
    assert "Invalid token" in response.json()["detail"]


@patch("app.api.v1.routers.users.firebase_auth")
def test_get_current_user_creates_new_user(mock_firebase_auth, client, db):
    """Test /users/me creates a new user if not exists."""
    mock_firebase_auth.verify_id_token.return_value = {
        "uid": "test-uid-123",
        "email": "test@example.com",
        "name": "Test User"
    }
    
    response = client.get(
        "/api/v1/users/me",
        headers={"Authorization": "Bearer valid-token"}
    )
    
    assert response.status_code == 200
    data = response.json()
    assert data["uid"] == "test-uid-123"
    assert data["email"] == "test@example.com"
    assert data["name"] == "Test User"


@patch("app.api.v1.routers.users.firebase_auth")
def test_get_user_sessions_empty(mock_firebase_auth, client, db):
    """Test /users/me/sessions returns empty list for new user."""
    mock_firebase_auth.verify_id_token.return_value = {
        "uid": "test-uid-sessions",
        "email": "sessions@example.com",
        "name": "Sessions User"
    }
    
    response = client.get(
        "/api/v1/users/me/sessions",
        headers={"Authorization": "Bearer valid-token"}
    )
    
    assert response.status_code == 200
    assert response.json() == []


@patch("app.api.v1.routers.users.firebase_auth")
def test_get_user_sessions_with_data(mock_firebase_auth, client, db):
    """Test /users/me/sessions returns user's practice sessions."""
    # Create a user
    user = models.User(uid="test-uid-with-sessions", email="withsessions@example.com", name="With Sessions")
    db.add(user)
    db.commit()
    db.refresh(user)
    
    # Create practice sessions for this user
    session1 = models.PracticeSession(
        user_id=user.id,
        transcription="Hello world",
        corrected_text="Hello, world!",
        feedback="Good job!",
        score=85
    )
    session2 = models.PracticeSession(
        user_id=user.id,
        transcription="How are you",
        corrected_text="How are you?",
        feedback="Nice!",
        score=90
    )
    db.add_all([session1, session2])
    db.commit()
    
    mock_firebase_auth.verify_id_token.return_value = {
        "uid": "test-uid-with-sessions",
        "email": "withsessions@example.com",
        "name": "With Sessions"
    }
    
    response = client.get(
        "/api/v1/users/me/sessions",
        headers={"Authorization": "Bearer valid-token"}
    )
    
    assert response.status_code == 200
    sessions = response.json()
    assert len(sessions) == 2
    # Verify both sessions are returned (order may vary without explicit timestamps)
    scores = [s["score"] for s in sessions]
    assert 85 in scores
    assert 90 in scores


@patch("app.api.v1.routers.users.firebase_auth")
def test_get_user_stats_empty(mock_firebase_auth, client, db):
    """Test /users/me/stats returns zeros for new user."""
    mock_firebase_auth.verify_id_token.return_value = {
        "uid": "test-uid-stats-empty",
        "email": "statsempty@example.com",
        "name": "Stats Empty"
    }
    
    response = client.get(
        "/api/v1/users/me/stats",
        headers={"Authorization": "Bearer valid-token"}
    )
    
    assert response.status_code == 200
    stats = response.json()
    assert stats["total_sessions"] == 0
    assert stats["average_score"] == 0
    assert stats["best_score"] == 0


@patch("app.api.v1.routers.users.firebase_auth")
def test_get_user_stats_with_data(mock_firebase_auth, client, db):
    """Test /users/me/stats returns correct aggregated stats."""
    # Create a user
    user = models.User(uid="test-uid-with-stats", email="withstats@example.com", name="With Stats")
    db.add(user)
    db.commit()
    db.refresh(user)
    
    # Create practice sessions
    sessions = [
        models.PracticeSession(user_id=user.id, transcription="Test 1", score=80),
        models.PracticeSession(user_id=user.id, transcription="Test 2", score=90),
        models.PracticeSession(user_id=user.id, transcription="Test 3", score=100),
    ]
    db.add_all(sessions)
    db.commit()
    
    mock_firebase_auth.verify_id_token.return_value = {
        "uid": "test-uid-with-stats",
        "email": "withstats@example.com",
        "name": "With Stats"
    }
    
    response = client.get(
        "/api/v1/users/me/stats",
        headers={"Authorization": "Bearer valid-token"}
    )
    
    assert response.status_code == 200
    stats = response.json()
    assert stats["total_sessions"] == 3
    assert stats["average_score"] == 90  # (80 + 90 + 100) / 3 = 90
    assert stats["best_score"] == 100

"""Tests for speech endpoints."""
import pytest
from unittest.mock import Mock, patch, MagicMock
from io import BytesIO


def test_transcribe_no_file(client):
    """Test transcribe endpoint rejects empty requests."""
    response = client.post("/api/v1/speech/transcribe")
    # Returns 422 (validation error) or 500 (no API key) depending on config
    assert response.status_code in [422, 500]


def test_transcribe_without_api_key(client):
    """Test transcribe fails gracefully without API key configured."""
    # Create a mock audio file
    audio_content = b"fake audio content"
    files = {"file": ("test.mp3", BytesIO(audio_content), "audio/mpeg")}
    
    with patch("app.core.config.settings.openai_api_key", None):
        response = client.post("/api/v1/speech/transcribe", files=files)
        assert response.status_code == 500
        assert "OpenAI API key not configured" in response.json()["detail"]


def test_feedback_without_api_key(client):
    """Test feedback endpoint fails gracefully without API key."""
    with patch("app.core.config.settings.openai_api_key", None):
        response = client.post(
            "/api/v1/speech/feedback",
            json={"text": "Hello, how are you?", "target_language": "en"}
        )
        assert response.status_code == 500
        assert "OpenAI API key not configured" in response.json()["detail"]


@patch("app.api.v1.routers.speech.OpenAI")
def test_feedback_success(mock_openai_class, client):
    """Test feedback endpoint with mocked OpenAI response."""
    # Setup mock
    mock_client = MagicMock()
    mock_openai_class.return_value = mock_client
    
    mock_response = MagicMock()
    mock_response.choices = [MagicMock()]
    mock_response.choices[0].message.content = '''{
        "corrected_text": "Hello, how are you?",
        "feedback": "Great job! Your sentence is grammatically correct.",
        "pronunciation_tips": ["Focus on the 'h' sound in 'hello'"],
        "grammar_notes": [],
        "score": 95
    }'''
    mock_client.chat.completions.create.return_value = mock_response
    
    with patch("app.core.config.settings.openai_api_key", "test-key"):
        response = client.post(
            "/api/v1/speech/feedback",
            json={"text": "Hello, how are you?", "target_language": "en"}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["original_text"] == "Hello, how are you?"
        assert data["score"] == 95
        assert len(data["pronunciation_tips"]) > 0

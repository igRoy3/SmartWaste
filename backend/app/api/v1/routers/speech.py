from fastapi import APIRouter, UploadFile, File, HTTPException, Depends, Header
from pydantic import BaseModel
from openai import OpenAI
from sqlalchemy.orm import Session
from typing import Optional

from app.core.config import settings
from app.db.session import get_db
from app.db import models

router = APIRouter()


class TranscriptionResponse(BaseModel):
    text: str
    language: str | None = None
    duration: float | None = None


class FeedbackRequest(BaseModel):
    text: str
    target_language: str = "en"
    context: str | None = None  # e.g., "casual conversation", "business meeting"


class FeedbackResponse(BaseModel):
    original_text: str
    corrected_text: str
    feedback: str
    pronunciation_tips: list[str]
    grammar_notes: list[str]
    score: int  # 1-100


class PracticeResponse(BaseModel):
    session_id: int
    transcription: str
    corrected_text: str | None
    feedback: str | None
    pronunciation_tips: list[str]
    grammar_notes: list[str]
    score: int


def get_openai_client() -> OpenAI:
    if not settings.openai_api_key:
        raise HTTPException(status_code=500, detail="OpenAI API key not configured")
    return OpenAI(api_key=settings.openai_api_key)


def get_optional_user(
    authorization: str | None = Header(None),
    db: Session = Depends(get_db),
) -> Optional[models.User]:
    """Optionally extract user from token. Returns None if no valid auth."""
    if not authorization:
        return None
    
    parts = authorization.split()
    if len(parts) != 2 or parts[0].lower() != "bearer":
        return None
    
    token = parts[1]
    try:
        from firebase_admin import auth as firebase_auth
        decoded = firebase_auth.verify_id_token(token)
        uid = decoded.get("uid")
        user = db.query(models.User).filter(models.User.uid == uid).first()
        return user
    except Exception:
        return None


@router.post("/transcribe", response_model=TranscriptionResponse)
async def transcribe_audio(
    file: UploadFile = File(...),
    client: OpenAI = Depends(get_openai_client),
):
    """Transcribe audio using OpenAI Whisper API."""
    if not file.filename:
        raise HTTPException(status_code=400, detail="No file uploaded")
    
    # Validate file type
    allowed_types = ["audio/mpeg", "audio/wav", "audio/webm", "audio/mp4", "audio/m4a", "audio/ogg"]
    if file.content_type and file.content_type not in allowed_types:
        raise HTTPException(
            status_code=400, 
            detail=f"Unsupported audio format. Allowed: mp3, wav, webm, mp4, m4a, ogg"
        )
    
    try:
        contents = await file.read()
        
        # Create a file-like object for the API
        transcription = client.audio.transcriptions.create(
            model=settings.whisper_model,
            file=(file.filename, contents),
            response_format="verbose_json"
        )
        
        return TranscriptionResponse(
            text=transcription.text,
            language=getattr(transcription, 'language', None),
            duration=getattr(transcription, 'duration', None)
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Transcription failed: {str(e)}")


@router.post("/feedback", response_model=FeedbackResponse)
async def get_speech_feedback(
    request: FeedbackRequest,
    client: OpenAI = Depends(get_openai_client),
):
    """Analyze speech/text and provide language learning feedback."""
    
    system_prompt = f"""You are an expert language tutor for {request.target_language}. 
Analyze the following text from a language learner and provide constructive feedback.

Respond in JSON format with these fields:
- corrected_text: The grammatically correct version
- feedback: A friendly, encouraging summary of their performance (2-3 sentences)
- pronunciation_tips: List of specific pronunciation advice (max 3 items)
- grammar_notes: List of grammar corrections with explanations (max 3 items)  
- score: An overall score from 1-100

Context: {request.context or 'general conversation'}
Be encouraging and focus on the most impactful improvements."""

    try:
        response = client.chat.completions.create(
            model=settings.gpt_model,
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": request.text}
            ],
            response_format={"type": "json_object"}
        )
        
        import json
        result = json.loads(response.choices[0].message.content)
        
        return FeedbackResponse(
            original_text=request.text,
            corrected_text=result.get("corrected_text", request.text),
            feedback=result.get("feedback", ""),
            pronunciation_tips=result.get("pronunciation_tips", []),
            grammar_notes=result.get("grammar_notes", []),
            score=result.get("score", 50)
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Feedback generation failed: {str(e)}")


@router.post("/practice", response_model=PracticeResponse)
async def create_practice_session(
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    client: OpenAI = Depends(get_openai_client),
    user: Optional[models.User] = Depends(get_optional_user),
):
    """Complete practice flow: transcribe audio and get feedback in one call.
    
    If authenticated, the session is linked to the user's account.
    """
    
    # First transcribe
    if not file.filename:
        raise HTTPException(status_code=400, detail="No file uploaded")
    
    try:
        contents = await file.read()
        transcription = client.audio.transcriptions.create(
            model=settings.whisper_model,
            file=(file.filename, contents),
            response_format="verbose_json"
        )
        
        transcribed_text = transcription.text
        
        # Then get feedback
        system_prompt = f"""You are an expert language tutor for {settings.target_language}. 
Analyze the following transcribed speech from a language learner.

Respond in JSON format with:
- corrected_text: The grammatically correct version
- feedback: Encouraging summary (2-3 sentences)
- pronunciation_tips: List of advice (max 3)
- grammar_notes: List of corrections (max 3)
- score: Score from 1-100"""

        response = client.chat.completions.create(
            model=settings.gpt_model,
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": transcribed_text}
            ],
            response_format={"type": "json_object"}
        )
        
        import json
        feedback_result = json.loads(response.choices[0].message.content)
        
        # Save practice session to database (linked to user if authenticated)
        session = models.PracticeSession(
            user_id=user.id if user else None,
            transcription=transcribed_text,
            corrected_text=feedback_result.get("corrected_text", transcribed_text),
            feedback=feedback_result.get("feedback", ""),
            score=feedback_result.get("score", 50),
        )
        db.add(session)
        db.commit()
        db.refresh(session)
        
        return PracticeResponse(
            session_id=session.id,
            transcription=transcribed_text,
            corrected_text=feedback_result.get("corrected_text"),
            feedback=feedback_result.get("feedback"),
            pronunciation_tips=feedback_result.get("pronunciation_tips", []),
            grammar_notes=feedback_result.get("grammar_notes", []),
            score=feedback_result.get("score", 50)
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Practice session failed: {str(e)}")

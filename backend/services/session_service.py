"""
Session service — manages per-student session tokens stored in
Firestore.  Only one active session per student at a time.
"""

from __future__ import annotations

import secrets
from datetime import datetime, timezone

from firebase_client import get_document, update_document
from models.student import COLLECTION as STUDENTS_COLLECTION


async def create_session(uid: str) -> str:
    """
    Generate a fresh session token for *uid*, store it in the student
    document, and return the token.
    """
    session_token = secrets.token_hex(32)
    await update_document(
        STUDENTS_COLLECTION,
        uid,
        {
            "active_session_token": session_token,
            "session_created_at": datetime.now(timezone.utc),
        },
    )
    return session_token


async def invalidate_all_sessions(uid: str) -> None:
    """
    Wipe the active session for *uid* so any previously issued token
    is no longer valid.
    """
    await update_document(
        STUDENTS_COLLECTION,
        uid,
        {
            "active_session_token": None,
            "session_created_at": None,
        },
    )


async def validate_session(uid: str, token: str) -> bool:
    """
    Return True only if the stored session token matches *token*.
    """
    student = await get_document(STUDENTS_COLLECTION, uid)
    if student is None:
        return False
    return student.get("active_session_token") == token

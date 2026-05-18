"""
Firestore-backed rate limiter (no Redis required).

Each student has a document in /rate_limits/{student_uid} that tracks
how many attendance attempts they have made within a sliding window.
"""

from datetime import datetime, timezone

from fastapi import HTTPException, status

from firebase_client import get_document, set_document, update_document
from config import RATE_LIMIT_MAX_ATTEMPTS, RATE_LIMIT_WINDOW_SECONDS

COLLECTION = "rate_limits"


async def check_rate_limit(student_uid: str) -> bool:
    """
    Returns True if the student is within the allowed rate limit.

    Raises HTTP 429 if the limit is exceeded.
    """
    now = datetime.now(timezone.utc)
    doc = await get_document(COLLECTION, student_uid)

    if doc is None:
        # First attempt ever — create the tracking document.
        await set_document(
            COLLECTION,
            student_uid,
            {
                "attempt_count": 1,
                "window_start": now,
            },
        )
        return True

    window_start = doc["window_start"]
    # Firestore timestamps come back as datetime-aware objects.
    if hasattr(window_start, "timestamp"):
        pass  # already a datetime
    else:
        window_start = datetime.fromisoformat(str(window_start))

    elapsed = (now - window_start).total_seconds()

    if elapsed > RATE_LIMIT_WINDOW_SECONDS:
        # Window expired — reset.
        await update_document(
            COLLECTION,
            student_uid,
            {"attempt_count": 1, "window_start": now},
        )
        return True

    if doc["attempt_count"] >= RATE_LIMIT_MAX_ATTEMPTS:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail=(
                f"Rate limit exceeded. Maximum {RATE_LIMIT_MAX_ATTEMPTS} "
                f"attempts per {RATE_LIMIT_WINDOW_SECONDS} seconds."
            ),
        )

    # Increment
    await update_document(
        COLLECTION,
        student_uid,
        {"attempt_count": doc["attempt_count"] + 1},
    )
    return True

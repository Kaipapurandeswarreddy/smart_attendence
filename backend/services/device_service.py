"""
Device service — register and validate student devices to prevent
account sharing and multi-device abuse.
"""

from __future__ import annotations

from fastapi import HTTPException, status

from firebase_client import get_document, update_document, query_collection
from models.student import COLLECTION as STUDENTS_COLLECTION


async def register_device(
    uid: str,
    uuid: str,
    fingerprint_hash: str,
    model: str,
    os_version: str,
) -> bool:
    """
    Bind a device to a student account.

    Raises HTTP 409 if the fingerprint is already registered to a
    *different* account.
    """
    # Check whether another account already owns this fingerprint.
    existing = await query_collection(
        STUDENTS_COLLECTION,
        "device_fingerprint_hash",
        "==",
        fingerprint_hash,
    )
    for doc in existing:
        if doc.get("uid") != uid:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Device already registered to another account.",
            )

    # Update the student document with device details.
    await update_document(
        STUDENTS_COLLECTION,
        uid,
        {
            "uuid": uuid,
            "device_fingerprint_hash": fingerprint_hash,
            "registered_device_model": model,
            "registered_os": os_version,
            "is_device_locked": True,
        },
    )
    return True


async def validate_device(
    uid: str,
    uuid: str,
    fingerprint_hash: str,
) -> bool:
    """
    Verify that the device presenting credentials matches the one on
    file for this student.
    """
    student = await get_document(STUDENTS_COLLECTION, uid)
    if student is None:
        return False

    if student.get("uuid") != uuid:
        return False

    if student.get("device_fingerprint_hash") != fingerprint_hash:
        return False

    return True

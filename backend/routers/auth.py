"""
Auth router — student registration and login with Firebase ID-token
verification and device binding.
"""

from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, status

from firebase_client import get_document, set_document, query_collection, update_document
from models.student import COLLECTION as STUDENTS_COLLECTION
from schemas.student import (
    StudentLoginRequest,
    StudentRegisterRequest,
    StudentResponse,
)
from security.firebase_auth_handler import get_current_user
from services import device_service, session_service

router = APIRouter(prefix="/auth", tags=["auth"])


async def _ensure_device_available_for_uid(uid: str, fingerprint_hash: str) -> None:
    existing_devices = await query_collection(
        STUDENTS_COLLECTION,
        "device_fingerprint_hash",
        "==",
        fingerprint_hash,
    )
    for doc in existing_devices:
        if doc.get("uid") != uid:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Device already registered to another account.",
            )


@router.post("/register", response_model=StudentResponse)
async def register(
    body: StudentRegisterRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Register a new student.  Firebase Auth must already have the
    account (created client-side); this endpoint binds the device.
    """
    uid = current_user["uid"]
    email = current_user.get("email", "")

    await _ensure_device_available_for_uid(uid, body.device_fingerprint_hash)

    # Check if student already registered
    existing = await get_document(STUDENTS_COLLECTION, uid)
    if existing is not None:
        existing_uuid = existing.get("uuid")
        existing_fingerprint = existing.get("device_fingerprint_hash")
        is_device_locked = existing.get("is_device_locked", False)
        if (
            is_device_locked
            and existing_uuid
            and existing_fingerprint
            and (
                existing_uuid != body.uuid
                or existing_fingerprint != body.device_fingerprint_hash
            )
        ):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="This account is registered to a different device.",
            )

        print(f"DEBUG: Updating existing student {uid} with name {body.name}", flush=True)
        # Update name and roll ID just in case they were auto-recovered with email prefix
        await update_document(
            STUDENTS_COLLECTION,
            uid,
            {
                "name": body.name,
                "student_roll_id": body.student_roll_id,
                "uuid": body.uuid,
                "device_fingerprint_hash": body.device_fingerprint_hash,
                "registered_device_model": body.device_model,
                "registered_os": body.os_version,
                "is_device_locked": True,
            }
        )
        print(f"DEBUG: Updated document successfully", flush=True)
        return StudentResponse(
            uid=uid,
            name=body.name,
            email=email,
            student_roll_id=body.student_roll_id,
            created_at=existing.get("created_at", datetime.now(timezone.utc)),
        )

    now = datetime.now(timezone.utc)

    student_doc = {
        "uid": uid,
        "name": body.name,
        "email": email,
        "student_roll_id": body.student_roll_id,
        "uuid": body.uuid,
        "device_fingerprint_hash": body.device_fingerprint_hash,
        "registered_device_model": body.device_model,
        "registered_os": body.os_version,
        "active_session_token": None,
        "session_created_at": None,
        "is_device_locked": True,
        "is_active": True,
        "created_at": now,
    }

    # Create the student document first
    await set_document(STUDENTS_COLLECTION, uid, student_doc)

    return StudentResponse(
        uid=uid,
        name=body.name,
        email=email,
        student_roll_id=body.student_roll_id,
        created_at=now,
    )


@router.post("/login")
async def login(
    body: StudentLoginRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Validate the device, rotate sessions, and return a fresh session
    token.  Email/password is handled by Firebase client-side.

    If the student document is missing (partial registration), it is
    auto-created using the device info from this request.
    """
    uid = current_user["uid"]
    email = current_user.get("email", "")

    student = await get_document(STUDENTS_COLLECTION, uid)

    if student is None:
        await _ensure_device_available_for_uid(uid, body.device_fingerprint_hash)

        # Auto-create student document for accounts that exist in
        # Firebase Auth but are missing in Firestore (partial reg).
        now = datetime.now(timezone.utc)
        student = {
            "uid": uid,
            "name": current_user.get("name") or email.split("@")[0],
            "email": email,
            "student_roll_id": "",
            "uuid": body.uuid,
            "device_fingerprint_hash": body.device_fingerprint_hash,
            "registered_device_model": "auto-recovered",
            "registered_os": "auto-recovered",
            "active_session_token": None,
            "session_created_at": None,
            "is_device_locked": True,
            "is_active": True,
            "created_at": now,
        }
        await set_document(STUDENTS_COLLECTION, uid, student)

    # Device validation
    is_valid = await device_service.validate_device(
        uid, body.uuid, body.device_fingerprint_hash
    )
    if not is_valid:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Device not recognized. This account is registered to a different device.",
        )

    # Rotate session
    await session_service.invalidate_all_sessions(uid)
    session_token = await session_service.create_session(uid)

    return {
        "message": "Login successful",
        "session_token": session_token,
        "uid": uid,
        "name": student.get("name"),
    }

"""
Attendance router — the attendance marking pipeline using static QR codes.
"""

from __future__ import annotations

from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, status

from config import REPLAY_WINDOW_SECONDS
from firebase_client import get_document
from models.student import COLLECTION as STUDENTS_COLLECTION
from schemas.attendance import AttendanceRequest, AttendanceResponse
from security.firebase_auth_handler import get_current_user
from security.payload_verifier import verify_attendance_payload
from security.rate_limiter import check_rate_limit
from services import attendance_service, device_service, gps_service, session_service, time_service
from services.qr_service import verify_qr_signature

router = APIRouter(prefix="/attendance", tags=["attendance"])


@router.post("/mark", response_model=AttendanceResponse)
async def mark_attendance(
    payload: AttendanceRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Execute the attendance verification pipeline:
      0. Time window check (10:00, 1:30, 5:00)
      1. UID from Firebase token
      2. Rate limit
      3. Replay window check
      4. Fetch student record
      5. Device validation
      6. Client payload signature check
      7. QR HMAC signature check (static)
      8. Fetch classroom
      9. GPS radius check
     10. Duplicate-per-day check
     11. Record attendance
    """
    uid = current_user["uid"]

    # ── Step 0: Time window check ─────────────────────────────────
    time_service.verify_attendance_time_window()

    # ── Step 1: UID extracted (already done by dependency) ────────

    # ── Step 2: Rate limit ────────────────────────────────────────
    await check_rate_limit(uid)

    # ── Step 3: Replay window ─────────────────────────────────────
    server_time = int(datetime.now(timezone.utc).timestamp())
    if abs(server_time - payload.payload_timestamp) > REPLAY_WINDOW_SECONDS:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Request expired. Timestamp outside acceptable window.",
        )

    # ── Step 4: Fetch student ─────────────────────────────────────
    student = await get_document(STUDENTS_COLLECTION, uid)
    if student is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Student record not found.",
        )

    # ── Step 5: Device validation ─────────────────────────────────
    session_ok = await session_service.validate_session(uid, payload.session_token)
    if not session_ok:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Login session expired. Please sign in again.",
        )

    device_ok = await device_service.validate_device(
        uid, payload.device_uuid, payload.device_fingerprint_hash
    )
    if not device_ok:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Device mismatch. Attendance rejected.",
        )

    # ── Step 6: Client payload signature ──────────────────────────
    sig_ok = verify_attendance_payload(payload, student["uuid"])
    if not sig_ok:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Invalid payload signature.",
        )

    # ── Step 7: QR HMAC signature (static) ────────────────────────
    qr_ok = verify_qr_signature(payload.classroom_id, payload.hmac_signature)
    if not qr_ok:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid QR code.",
        )

    # ── Step 8: Fetch classroom ───────────────────────────────────
    if not payload.classroom_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid QR code: missing classroom ID.",
        )
        
    classroom = await get_document("classrooms", payload.classroom_id)
    if classroom is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Classroom not found.",
        )

    # ── Step 9: GPS radius check ──────────────────────────────────
    radius = classroom.get("allowed_radius_meters", 50)
    loc = classroom.get("location")
    if loc and hasattr(loc, "latitude"):
        class_lat = loc.latitude
        class_lng = loc.longitude
    else:
        class_lat = classroom.get("gps_lat", 0)
        class_lng = classroom.get("gps_lng", 0)

    within = gps_service.is_within_radius(
        student_lat=payload.gps_lat,
        student_lng=payload.gps_lng,
        class_lat=class_lat,
        class_lng=class_lng,
        radius_meters=radius,
        accuracy_meters=payload.gps_accuracy_meters,
    )
    if not within:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Outside classroom radius. Attendance rejected.",
        )

    # ── Step 10-11: Duplicate check + Record ──────────────────────
    record = await attendance_service.record_attendance(
        student_uid=uid,
        request=payload,
        classroom=classroom,
    )

    return AttendanceResponse(
        attendance_id=record["attendance_id"],
        status="present",
        timestamp=record["timestamp"],
        message="Attendance marked successfully.",
    )

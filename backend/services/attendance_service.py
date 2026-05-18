"""
Attendance service — writes attendance records with per-day duplicate
prevention.
"""

from __future__ import annotations

from datetime import datetime, timezone

from fastapi import HTTPException, status

from firebase_client import add_document, query_collection
from schemas.attendance import AttendanceRequest
from models.attendance import COLLECTION as RECORDS_COLLECTION


async def record_attendance(
    student_uid: str,
    request: AttendanceRequest,
    classroom: dict,
) -> dict:
    """
    Create an attendance record after all upstream validations pass.

    Raises HTTP 409 if the student has already been marked present for
    this classroom *today*.
    """
    now = datetime.now(timezone.utc)
    today_str = now.strftime("%Y-%m-%d")

    # Duplicate check — one mark per classroom per day
    existing = await query_collection(
        RECORDS_COLLECTION,
        "student_uid",
        "==",
        student_uid,
    )
    for rec in existing:
        if rec.get("classroom_id") != request.classroom_id:
            continue
        ts = rec.get("timestamp")
        if ts and hasattr(ts, "strftime"):
            if ts.strftime("%Y-%m-%d") == today_str:
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail="Already marked attendance for this classroom today.",
                )

    record = {
        "student_uid": student_uid,
        "classroom_id": request.classroom_id,
        "timestamp": now,
        "gps_lat": request.gps_lat,
        "gps_lng": request.gps_lng,
        "gps_accuracy_meters": request.gps_accuracy_meters,
        "device_uuid": request.device_uuid,
        "device_fingerprint_hash": request.device_fingerprint_hash,
        "payload_signature": request.payload_signature,
        "attendance_status": "present",
        "is_flagged": False,
        "flag_reason": None,
    }

    doc_id = await add_document(RECORDS_COLLECTION, record)
    record["attendance_id"] = doc_id

    return record

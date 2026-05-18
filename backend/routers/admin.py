"""
Admin router — device release, attendance reports, and admin claim
management.
"""

from __future__ import annotations

from datetime import datetime, timezone
from typing import Optional

from fastapi import APIRouter, Depends, Header, HTTPException, status
from pydantic import BaseModel

from config import ADMIN_SECRET
from firebase_client import auth, get_document, query_collection, update_document
from models.student import COLLECTION as STUDENTS_COLLECTION
from models.attendance import COLLECTION as RECORDS_COLLECTION
from security.firebase_auth_handler import get_admin_user
from services.session_service import invalidate_all_sessions

router = APIRouter(prefix="/admin", tags=["admin"])


# ── Request bodies ────────────────────────────────────────────────

class ReleaseDeviceRequest(BaseModel):
    student_uid: str
    reason: str


class SetAdminRequest(BaseModel):
    uid: str


class GrantAdminRequest(BaseModel):
    uid: Optional[str] = None
    email: Optional[str] = None


class CreateClassroomRequest(BaseModel):
    id: str
    name: str
    gps_lat: float
    gps_lng: float
    allowed_radius_meters: int = 50


# ── Endpoints ─────────────────────────────────────────────────────

@router.post("/release-device")
async def release_device(
    body: ReleaseDeviceRequest,
    _admin: dict = Depends(get_admin_user),
):
    """
    Unbind a student's device so they can re-register from a new one.
    """
    student = await get_document(STUDENTS_COLLECTION, body.student_uid)
    if student is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Student not found.",
        )

    await update_document(
        STUDENTS_COLLECTION,
        body.student_uid,
        {
            "uuid": None,
            "device_fingerprint_hash": None,
            "is_device_locked": False,
        },
    )
    await invalidate_all_sessions(body.student_uid)

    return {
        "message": f"Device released for student {body.student_uid}.",
        "reason": body.reason,
    }


@router.get("/attendance-report")
async def attendance_report(
    classroom_id: str,
    date: str,  # YYYY-MM-DD
    _admin: dict = Depends(get_admin_user),
):
    """
    Fetch attendance records for a given classroom and date.
    """
    try:
        target = datetime.strptime(date, "%Y-%m-%d").replace(tzinfo=timezone.utc)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid date format. Use YYYY-MM-DD.",
        )

    start_of_day = target.replace(hour=0, minute=0, second=0, microsecond=0)
    end_of_day = target.replace(hour=23, minute=59, second=59, microsecond=999999)

    records = await query_collection(
        RECORDS_COLLECTION,
        "classroom_id",
        "==",
        classroom_id,
    )

    # Filter by date range in-memory (Firestore compound queries
    # require a composite index; this is fine for moderate data).
    filtered = []
    for rec in records:
        ts = rec.get("timestamp")
        if ts is None:
            continue
        if hasattr(ts, "timestamp"):
            # Firestore datetime
            if start_of_day <= ts <= end_of_day:
                filtered.append(rec)
        else:
            try:
                parsed = datetime.fromisoformat(str(ts))
                if start_of_day <= parsed <= end_of_day:
                    filtered.append(rec)
            except (ValueError, TypeError):
                continue

    return {"classroom_id": classroom_id, "date": date, "records": filtered}


@router.post("/set-admin-claim")
async def set_admin_claim(
    body: SetAdminRequest,
    x_admin_secret: str = Header(..., alias="X-Admin-Secret"),
):
    """
    Grant the ``admin`` custom claim to a Firebase user.

    Protected by the ADMIN_SECRET header (not by Firebase auth) so
    the very first admin can be bootstrapped.
    """
    if x_admin_secret != ADMIN_SECRET:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Invalid admin secret.",
        )

    try:
        auth.set_custom_user_claims(body.uid, {"admin": True})
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to set admin claim: {exc}",
        )

    return {"message": f"Admin claim set for user {body.uid}."}


@router.post("/grant-admin")
async def grant_admin(
    body: GrantAdminRequest,
    _admin: dict = Depends(get_admin_user),
):
    """
    Grant admin access from the admin dashboard.
    Accepts either a Firebase UID or an email address.
    """
    uid = body.uid
    if not uid and body.email:
        try:
            user = auth.get_user_by_email(body.email)
            uid = user.uid
        except Exception:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User with this email was not found.",
            )

    if not uid:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Enter a Firebase UID or email address.",
        )

    try:
        auth.set_custom_user_claims(uid, {"admin": True})
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to grant admin access: {exc}",
        )

    return {"message": f"Admin access granted for user {uid}."}


# ── List all students ─────────────────────────────────────────────

@router.get("/students")
async def list_students(
    _admin: dict = Depends(get_admin_user),
):
    """Return all registered students."""
    from firebase_client import db

    students = []
    async for doc in db.collection(STUDENTS_COLLECTION).stream():
        data = doc.to_dict()
        data["uid"] = data.get("uid") or doc.id
        # Serialise datetime fields for JSON
        for key in ("created_at", "session_created_at"):
            val = data.get(key)
            if val and hasattr(val, "isoformat"):
                data[key] = val.isoformat()
        students.append(data)

    return {"students": students}


# ── List all classrooms ───────────────────────────────────────────

@router.get("/classrooms")
async def list_classrooms(
    _admin: dict = Depends(get_admin_user),
):
    """Return all configured classrooms."""
    from firebase_client import db

    classrooms = []
    async for doc in db.collection("classrooms").stream():
        data = doc.to_dict()
        for key in ("created_at",):
            val = data.get(key)
            if val and hasattr(val, "isoformat"):
                data[key] = val.isoformat()
        # Convert GeoPoint to lat/lng dict
        loc = data.get("location")
        if loc and hasattr(loc, "latitude"):
            data["location"] = {
                "latitude": loc.latitude,
                "longitude": loc.longitude,
            }
        # Explicitly inject the document ID as classroom_id
        data["classroom_id"] = doc.id
        classrooms.append(data)

    return {"classrooms": classrooms}

@router.post("/classrooms")
async def create_classroom(
    body: CreateClassroomRequest,
    _admin: dict = Depends(get_admin_user),
):
    """Create a new classroom from the admin dashboard."""
    from firebase_client import db
    from google.cloud.firestore import GeoPoint
    from datetime import datetime, timezone
    
    doc_ref = db.collection("classrooms").document(body.id)
    doc = await doc_ref.get()
    if doc.exists:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Classroom with ID '{body.id}' already exists."
        )
        
    data = {
        "classroom_id": body.id,  # Add this field to the document itself
        "name": body.name,
        "location": GeoPoint(body.gps_lat, body.gps_lng),
        "allowed_radius_meters": body.allowed_radius_meters,
        "created_at": datetime.now(timezone.utc)
    }
    
    await doc_ref.set(data)
    
    # Return serializable format
    data["created_at"] = data["created_at"].isoformat()
    data["location"] = {"latitude": body.gps_lat, "longitude": body.gps_lng}
    
    return data

# ── Analytics summary ─────────────────────────────────────────────

@router.get("/analytics")
async def analytics(
    _admin: dict = Depends(get_admin_user),
):
    """
    Return attendance analytics:
      - total_students
      - total_records
      - records_by_classroom  (dict)
      - records_by_date       (dict, last 30 days)
    """
    from firebase_client import db
    from collections import defaultdict

    # Count students
    total_students = 0
    async for _ in db.collection(STUDENTS_COLLECTION).stream():
        total_students += 1

    # Aggregate attendance records
    total_records = 0
    by_classroom: dict[str, int] = defaultdict(int)
    by_date: dict[str, int] = defaultdict(int)
    by_session: dict[str, int] = defaultdict(int)
    
    # Nested dict for detailed records: { "YYYY-MM-DD": { "Morning": [...], "Afternoon": [...], "Evening": [...] } }
    detailed_records: dict[str, dict[str, list[str]]] = defaultdict(lambda: {
        "Morning (10:00 AM)": [],
        "Afternoon (1:30 PM)": [],
        "Evening (5:00 PM)": []
    })

    # IST timezone
    import pytz
    ist = pytz.timezone('Asia/Kolkata')
    
    # Pre-fetch students to map uid -> name
    student_map = {}
    async for s_doc in db.collection(STUDENTS_COLLECTION).stream():
        s_data = s_doc.to_dict()
        name = s_data.get("name", "Unknown")
        student_map[s_doc.id] = name

    async for doc in db.collection(RECORDS_COLLECTION).stream():
        total_records += 1
        data = doc.to_dict()
        cid = data.get("classroom_id", "unknown")
        student_uid = data.get("student_uid", "")
        student_display = student_map.get(student_uid, "Unknown Student")
        by_classroom[cid] += 1

        ts = data.get("timestamp")
        if ts and hasattr(ts, "astimezone"):
            # Convert to IST
            ts_ist = ts.astimezone(ist)
            date_str = ts_ist.strftime("%Y-%m-%d")
            by_date[date_str] += 1
            
            # Determine session
            hour = ts_ist.hour
            if hour < 12:
                session_key = "Morning (10:00 AM)"
            elif hour < 16:
                session_key = "Afternoon (1:30 PM)"
            else:
                session_key = "Evening (5:00 PM)"
                
            by_session[session_key] += 1
            detailed_records[date_str][session_key].append(student_display)

    return {
        "total_students": total_students,
        "total_records": total_records,
        "records_by_classroom": dict(by_classroom),
        "records_by_date": dict(sorted(by_date.items())),
        "records_by_session": dict(by_session),
        "detailed_records": dict(sorted(detailed_records.items(), reverse=True)),
    }

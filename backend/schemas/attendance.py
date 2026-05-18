"""
Pydantic v2 schemas for attendance marking requests and responses.
"""

from datetime import datetime

from pydantic import BaseModel


class AttendanceRequest(BaseModel):
    classroom_id: str
    hmac_signature: str          # from the static QR code
    gps_lat: float
    gps_lng: float
    gps_accuracy_meters: float
    device_uuid: str
    device_fingerprint_hash: str
    session_token: str
    payload_timestamp: int
    payload_signature: str       # client-side HMAC (device integrity)


class AttendanceResponse(BaseModel):
    attendance_id: str
    status: str
    timestamp: datetime
    message: str

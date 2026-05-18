"""
Payload verifier — recomputes HMAC-SHA256 over attendance payload
fields and compares with the client-supplied signature.
"""

import hmac
import hashlib

from schemas.attendance import AttendanceRequest


def verify_attendance_payload(
    payload: AttendanceRequest,
    student_uuid: str,
) -> bool:
    """
    Recompute the HMAC-SHA256 signature and compare with the one
    the client sent.

    Key   = student_uuid (UTF-8 bytes)
    Msg   = f"{classroom_id}{payload_timestamp}"

    Returns True if signatures match.
    """
    key = student_uuid.encode("utf-8")
    message = (
        f"{payload.classroom_id}"
        f"{payload.payload_timestamp}"
    ).encode("utf-8")

    expected = hmac.new(key, message, hashlib.sha256).hexdigest()
    return hmac.compare_digest(expected, payload.payload_signature)

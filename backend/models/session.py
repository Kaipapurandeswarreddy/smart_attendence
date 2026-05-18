"""
Attendance session Firestore document model — collection name & field constants.
"""

COLLECTION = "attendance_sessions"

SESSION_ID = "session_id"
CLASSROOM_ID = "classroom_id"
SESSION_NONCE = "session_nonce"
QR_HMAC_SIGNATURE = "qr_hmac_signature"
CREATED_AT = "created_at"
EXPIRES_AT = "expires_at"
IS_ACTIVE = "is_active"
USED_NONCES = "used_nonces"

# Nonce tracking
NONCES_COLLECTION = "used_nonces"
NONCE = "nonce"
USED_AT = "used_at"

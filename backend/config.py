"""
Configuration module — loads all settings from environment variables.
"""

import os
from dotenv import load_dotenv

load_dotenv()

# Firebase
FIREBASE_CREDENTIALS_PATH: str = os.getenv(
    "FIREBASE_CREDENTIALS_PATH", "serviceAccountKey.json"
)

# QR / HMAC
QR_HMAC_SECRET: str = os.getenv("QR_HMAC_SECRET", "change-me-in-production")
QR_EXPIRY_SECONDS: int = int(os.getenv("QR_EXPIRY_SECONDS", "90"))

# GPS
GPS_DEFAULT_RADIUS_METERS: float = float(
    os.getenv("GPS_DEFAULT_RADIUS_METERS", "50")
)

# Replay protection
REPLAY_WINDOW_SECONDS: int = int(os.getenv("REPLAY_WINDOW_SECONDS", "30"))

# Rate limiting
RATE_LIMIT_MAX_ATTEMPTS: int = int(os.getenv("RATE_LIMIT_MAX_ATTEMPTS", "3"))
RATE_LIMIT_WINDOW_SECONDS: int = int(
    os.getenv("RATE_LIMIT_WINDOW_SECONDS", "300")
)

# Admin
ADMIN_SECRET: str = os.getenv("ADMIN_SECRET", "super-secret-admin-key")

# Attendance Time Windows
ATTENDANCE_TIME_WINDOWS_ENFORCED: bool = (
    os.getenv("ATTENDANCE_TIME_WINDOWS_ENFORCED", "True").lower() == "true"
)
ATTENDANCE_SLOT_DURATION_MINUTES: int = int(
    os.getenv("ATTENDANCE_SLOT_DURATION_MINUTES", "10")
)

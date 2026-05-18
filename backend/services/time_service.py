"""
Time-based services for attendance windows and limits.
"""

from datetime import datetime
from zoneinfo import ZoneInfo
from fastapi import HTTPException, status

from config import ATTENDANCE_TIME_WINDOWS_ENFORCED, ATTENDANCE_SLOT_DURATION_MINUTES

def verify_attendance_time_window():
    """
    Verifies if the current time in IST is within the allowed attendance windows.
    Allowed windows are:
      - 10:00 AM
      - 1:30 PM (13:30)
      - 5:00 PM (17:00)
    Each window lasts for exactly 10 minutes (configurable via ATTENDANCE_SLOT_DURATION_MINUTES).
    Raises HTTP 403 if outside the allowed windows.
    """
    if not ATTENDANCE_TIME_WINDOWS_ENFORCED:
        return

    # User is in India (+05:30)
    tz = ZoneInfo("Asia/Kolkata")
    now = datetime.now(tz)
    
    current_minutes = now.hour * 60 + now.minute
    
    # Windows defined as (hour, minute)
    # 10:00 AM, 1:30 PM, 5:00 PM
    allowed_windows = [
        (10, 0),
        (13, 30),
        (17, 0)
    ]
    
    for start_h, start_m in allowed_windows:
        start_mins = start_h * 60 + start_m
        end_mins = start_mins + ATTENDANCE_SLOT_DURATION_MINUTES
        
        if start_mins <= current_minutes <= end_mins:
            # We are within a valid window!
            return
            
    # If we reach here, we are not in any valid window.
    # Build a friendly error message showing the upcoming windows
    error_msg = (
        "Attendance marking is currently closed. "
        "You can only mark attendance during these specific 10-minute slots: "
        "10:00 AM, 1:30 PM, and 5:00 PM."
    )
    
    raise HTTPException(
        status_code=status.HTTP_403_FORBIDDEN,
        detail=error_msg
    )

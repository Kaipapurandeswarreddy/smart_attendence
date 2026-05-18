"""
GPS service — Haversine distance calculation and radius check.
"""

import math


def _haversine(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    """
    Calculate the great-circle distance (in metres) between two GPS
    coordinates using the Haversine formula.
    """
    R = 6_371_000  # Earth radius in metres

    phi1 = math.radians(lat1)
    phi2 = math.radians(lat2)
    delta_phi = math.radians(lat2 - lat1)
    delta_lambda = math.radians(lng2 - lng1)

    a = (
        math.sin(delta_phi / 2) ** 2
        + math.cos(phi1) * math.cos(phi2) * math.sin(delta_lambda / 2) ** 2
    )
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))

    return R * c


def is_within_radius(
    student_lat: float,
    student_lng: float,
    class_lat: float,
    class_lng: float,
    radius_meters: float,
    accuracy_meters: float,
) -> bool:
    """
    Returns True only if:
      1. The reported GPS accuracy is ≤ 50 m (rejects mock / coarse fixes).
      2. The Haversine distance between student and classroom is within
         the allowed radius.
    """
    if accuracy_meters > 50:
        return False

    distance = _haversine(student_lat, student_lng, class_lat, class_lng)
    return distance <= radius_meters

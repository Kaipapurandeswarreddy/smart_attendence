"""
Pydantic v2 schemas for student-related requests and responses.
"""

from datetime import datetime

from pydantic import BaseModel, EmailStr


class StudentRegisterRequest(BaseModel):
    name: str
    student_roll_id: str
    uuid: str
    device_fingerprint_hash: str
    device_model: str
    os_version: str


class StudentLoginRequest(BaseModel):
    uuid: str
    device_fingerprint_hash: str


class StudentResponse(BaseModel):
    uid: str
    name: str
    email: str
    student_roll_id: str
    created_at: datetime

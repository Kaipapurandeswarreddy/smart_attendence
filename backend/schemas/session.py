"""
Pydantic v2 schemas for QR generation and responses.
"""

from pydantic import BaseModel


class QRGenerateRequest(BaseModel):
    classroom_id: str


class QRStaticResponse(BaseModel):
    qr_data: str  # JSON string to encode into QR image
    classroom_id: str

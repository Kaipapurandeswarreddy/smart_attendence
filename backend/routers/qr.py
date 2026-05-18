"""
QR router — generate static QR codes (admin only).
"""

from fastapi import APIRouter, Depends

from schemas.session import QRGenerateRequest, QRStaticResponse
from security.firebase_auth_handler import get_admin_user
from services.qr_service import generate_static_qr

router = APIRouter(prefix="/qr", tags=["qr"])


@router.post("/generate", response_model=QRStaticResponse)
async def generate(
    body: QRGenerateRequest,
    _admin: dict = Depends(get_admin_user),
):
    """
    Generate a static QR code for a classroom.
    The QR never expires — it can be printed, displayed, or shared.
    Requires the Firebase user to have the ``admin`` custom claim.
    """
    result = generate_static_qr(body.classroom_id)
    return QRStaticResponse(
        qr_data=result["qr_data"],
        classroom_id=result["classroom_id"],
    )

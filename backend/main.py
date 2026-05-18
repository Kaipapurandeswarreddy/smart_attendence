"""
Smart Attendance System — FastAPI application entry-point.
"""

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from starlette.middleware.base import BaseHTTPMiddleware
import sys

from routers import auth, attendance, qr, admin


class LoggingMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        auth_header = request.headers.get("authorization", "")
        token_preview = auth_header[:50] + "..." if len(auth_header) > 50 else auth_header
        print(f"[REQ] {request.method} {request.url.path} | Auth: {token_preview}", flush=True)
        try:
            response = await call_next(request)
            print(f"[RES] {request.url.path} -> {response.status_code}", flush=True)
            return response
        except Exception as e:
            import traceback
            error_details = traceback.format_exc()
            with open("error.log", "a") as f:
                f.write(f"Exception during request {request.method} {request.url}: {str(e)}\n")
                f.write(error_details)
                f.write("\n" + "="*50 + "\n")
            raise e

app = FastAPI(
    title="Smart Attendance System API",
    description="Secure attendance backend with Firebase Auth, HMAC-signed QR codes, GPS geofencing, and device binding.",
    version="1.0.0",
)

# ── CORS ──────────────────────────────────────────────────────────
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # tighten in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Logging (debug) ──────────────────────────────────────────────
app.add_middleware(LoggingMiddleware)

# ── Routers ───────────────────────────────────────────────────────
app.include_router(auth.router)
app.include_router(attendance.router)
app.include_router(qr.router)
app.include_router(admin.router)


# ── Health check ──────────────────────────────────────────────────
@app.get("/health", tags=["health"])
async def health():
    return {"status": "ok"}

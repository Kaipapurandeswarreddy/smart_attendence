"""
Firebase Auth dependency — verifies Firebase ID tokens on every
protected route and returns the decoded token dict.
"""

from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer

from firebase_client import auth

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login")


def verify_firebase_token(id_token: str) -> dict:
    """
    Verify a Firebase ID token and return the decoded claims.

    Raises
    ------
    HTTPException 401
        If the token is invalid, expired, or revoked.
    """
    try:
        decoded = auth.verify_id_token(
            id_token, check_revoked=False, clock_skew_seconds=5
        )
        return decoded
    except auth.ExpiredIdTokenError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Firebase ID token has expired. Please re-authenticate.",
        )
    except auth.RevokedIdTokenError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Firebase ID token has been revoked.",
        )
    except auth.InvalidIdTokenError as e:
        print(f"[AUTH] InvalidIdTokenError: {e}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid Firebase ID token.",
        )
    except Exception as e:
        print(f"[AUTH] Unexpected auth error: {type(e).__name__}: {e}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Could not validate credentials: {type(e).__name__}",
        )


async def get_current_user(
    token: str = Depends(oauth2_scheme),
) -> dict:
    """FastAPI dependency that extracts and validates the Firebase user."""
    return verify_firebase_token(token)


async def get_admin_user(
    current_user: dict = Depends(get_current_user),
) -> dict:
    """FastAPI dependency that ensures the user has the 'admin' custom claim."""
    if not current_user.get("admin"):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin privileges required.",
        )
    return current_user

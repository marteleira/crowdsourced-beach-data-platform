import hashlib
import random
import secrets
from datetime import datetime, timedelta, timezone
from typing import Optional
from uuid import UUID

import bcrypt as _bcrypt
from jose import JWTError, jwt

from app.core.config import settings


def hash_password(password: str) -> str:
    return _bcrypt.hashpw(password.encode(), _bcrypt.gensalt()).decode()


def verify_password(plain: str, hashed: str) -> bool:
    return _bcrypt.checkpw(plain.encode(), hashed.encode())


def create_access_token(
    user_id: UUID, reputation: int, is_anonymous: bool, is_email_verified: bool = False
) -> str:
    expire = datetime.now(timezone.utc) + timedelta(minutes=settings.JWT_ACCESS_EXPIRE_MINUTES)
    payload = {
        "sub": str(user_id),
        "rep": reputation,
        "anon": is_anonymous,
        "email_verified": is_email_verified,
        "exp": expire,
    }
    return jwt.encode(payload, settings.JWT_SECRET, algorithm="HS256")


def decode_access_token(token: str) -> Optional[dict]:
    try:
        return jwt.decode(token, settings.JWT_SECRET, algorithms=["HS256"])
    except JWTError:
        return None


def generate_refresh_token() -> tuple[str, str]:
    """Return (raw_token, sha256_hash). Store only the hash."""
    raw = secrets.token_urlsafe(48)
    hashed = hashlib.sha256(raw.encode()).hexdigest()
    return raw, hashed


def hash_refresh_token(raw: str) -> str:
    return hashlib.sha256(raw.encode()).hexdigest()


def generate_verification_code() -> tuple[str, str]:
    """Return (plain_code, sha256_hash). Store only the hash."""
    code = f"{random.randint(0, 999_999):06d}"
    hashed = hashlib.sha256(code.encode()).hexdigest()
    return code, hashed


def hash_verification_code(code: str) -> str:
    return hashlib.sha256(code.encode()).hexdigest()


async def verify_google_id_token(id_token: str) -> dict:
    """Verify a Google id_token and return the decoded payload."""
    from google.oauth2 import id_token as google_id_token
    from google.auth.transport import requests as google_requests
    import asyncio

    if not settings.GOOGLE_CLIENT_ID:
        raise ValueError("GOOGLE_CLIENT_ID not configured")

    loop = asyncio.get_event_loop()
    payload = await loop.run_in_executor(
        None,
        lambda: google_id_token.verify_oauth2_token(
            id_token,
            google_requests.Request(),
            settings.GOOGLE_CLIENT_ID,
        ),
    )
    return payload

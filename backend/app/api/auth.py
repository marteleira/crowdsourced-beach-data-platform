import logging
from datetime import datetime, timedelta, timezone
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.deps import require_user
from app.core.security import (
    hash_password, verify_password, create_access_token,
    generate_refresh_token, hash_refresh_token, verify_google_id_token,
)
from app.core.config import settings
from app.models.user import User, RefreshToken
from app.schemas.auth import (
    RegisterRequest, LoginRequest, GoogleRequest, GuestRequest,
    RefreshRequest, LogoutRequest, PromoteRequest, TokenResponse,
)

router = APIRouter(prefix="/auth", tags=["auth"])
logger = logging.getLogger(__name__)


async def _issue_tokens(user: User, db: AsyncSession) -> TokenResponse:
    access = create_access_token(user.id, user.reputation, user.is_anonymous)
    raw_refresh, token_hash = generate_refresh_token()

    expires = datetime.now(timezone.utc) + timedelta(days=settings.JWT_REFRESH_EXPIRE_DAYS)
    db.add(RefreshToken(user_id=user.id, token_hash=token_hash, expires_at=expires))
    await db.commit()

    return TokenResponse(
        access_token=access,
        refresh_token=raw_refresh,
        expires_in=settings.JWT_ACCESS_EXPIRE_MINUTES * 60,
        is_anonymous=user.is_anonymous,
    )


@router.post("/guest", response_model=TokenResponse)
async def create_guest(body: GuestRequest, db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(User).where(User.device_id == body.device_id, User.is_anonymous == True)
    )
    user = result.scalar_one_or_none()

    if not user:
        user = User(device_id=body.device_id, is_anonymous=True)
        db.add(user)
        await db.flush()

    return await _issue_tokens(user, db)


@router.post("/register", response_model=TokenResponse, status_code=201)
async def register(body: RegisterRequest, db: AsyncSession = Depends(get_db)):
    existing = await db.execute(select(User).where(User.email == body.email))
    if existing.scalar_one_or_none():
        raise HTTPException(409, "Email já registado")

    user = User(
        email=body.email,
        display_name=body.display_name,
        password_hash=hash_password(body.password),
        is_anonymous=False,
    )
    db.add(user)
    await db.flush()

    return await _issue_tokens(user, db)


@router.post("/login", response_model=TokenResponse)
async def login(body: LoginRequest, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(User).where(User.email == body.email))
    user = result.scalar_one_or_none()

    if not user or not user.password_hash or not verify_password(body.password, user.password_hash):
        raise HTTPException(401, "Credenciais inválidas")

    if user.is_banned:
        raise HTTPException(403, "Conta suspensa")

    return await _issue_tokens(user, db)


@router.post("/google", response_model=TokenResponse)
async def google_login(body: GoogleRequest, db: AsyncSession = Depends(get_db)):
    try:
        payload = await verify_google_id_token(body.id_token)
    except Exception as e:
        logger.error("Google token error: %s: %s", type(e).__name__, e)
        raise HTTPException(401, "Token Google inválido")

    google_sub = payload["sub"]
    email = payload.get("email", "")
    name = payload.get("name", "")

    result = await db.execute(select(User).where(User.google_sub == google_sub))
    user = result.scalar_one_or_none()

    if not user:
        # Check if email already exists (link accounts)
        if email:
            result = await db.execute(select(User).where(User.email == email))
            user = result.scalar_one_or_none()

        if user:
            user.google_sub = google_sub
        else:
            user = User(
                email=email or None,
                display_name=name,
                google_sub=google_sub,
                is_anonymous=False,
            )
            db.add(user)
            await db.flush()

    await db.commit()
    return await _issue_tokens(user, db)


@router.post("/refresh", response_model=TokenResponse)
async def refresh_token(body: RefreshRequest, db: AsyncSession = Depends(get_db)):
    token_hash = hash_refresh_token(body.refresh_token)

    result = await db.execute(
        select(RefreshToken).where(RefreshToken.token_hash == token_hash)
    )
    record = result.scalar_one_or_none()

    now = datetime.now(timezone.utc)
    if not record or record.revoked_at or record.expires_at.replace(tzinfo=timezone.utc) < now:
        raise HTTPException(401, "Refresh token inválido ou expirado")

    # Rotate: revoke old, issue new
    await db.execute(
        update(RefreshToken)
        .where(RefreshToken.id == record.id)
        .values(revoked_at=now)
    )

    result = await db.execute(select(User).where(User.id == record.user_id))
    user = result.scalar_one_or_none()
    if not user or user.is_banned:
        raise HTTPException(401, "Utilizador não encontrado")

    return await _issue_tokens(user, db)


@router.post("/logout")
async def logout(body: LogoutRequest, db: AsyncSession = Depends(get_db)):
    token_hash = hash_refresh_token(body.refresh_token)
    await db.execute(
        update(RefreshToken)
        .where(RefreshToken.token_hash == token_hash)
        .values(revoked_at=datetime.now(timezone.utc))
    )
    await db.commit()
    return {"status": "ok"}


@router.post("/promote", response_model=TokenResponse)
async def promote_guest(
    body: PromoteRequest,
    user: User = Depends(require_user),
    db: AsyncSession = Depends(get_db),
):
    if not user.is_anonymous:
        raise HTTPException(400, "Utilizador já registado")

    existing = await db.execute(select(User).where(User.email == body.email))
    if existing.scalar_one_or_none():
        raise HTTPException(409, "Email já registado")

    user.email = body.email
    user.display_name = body.display_name
    user.password_hash = hash_password(body.password)
    user.is_anonymous = False

    await db.commit()
    await db.refresh(user)

    return await _issue_tokens(user, db)

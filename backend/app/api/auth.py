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
    generate_verification_code, hash_verification_code,
)
from app.core.config import settings
from app.models.user import User, RefreshToken
from app.schemas.auth import (
    RegisterRequest, LoginRequest, GoogleRequest, GuestRequest,
    RefreshRequest, LogoutRequest, PromoteRequest, TokenResponse,
    VerifyEmailRequest, ForgotPasswordRequest, ResetPasswordRequest,
)
from app.services.email import send_verification_email, send_password_reset_email

router = APIRouter(prefix="/auth", tags=["auth"])
logger = logging.getLogger(__name__)


async def _issue_tokens(user: User, db: AsyncSession) -> TokenResponse:
    access = create_access_token(
        user.id, user.reputation, user.is_anonymous,
        is_email_verified=bool(user.is_email_verified),
    )
    raw_refresh, token_hash = generate_refresh_token()

    expires = datetime.now(timezone.utc) + timedelta(days=settings.JWT_REFRESH_EXPIRE_DAYS)
    db.add(RefreshToken(user_id=user.id, token_hash=token_hash, expires_at=expires))
    await db.commit()

    return TokenResponse(
        access_token=access,
        refresh_token=raw_refresh,
        expires_in=settings.JWT_ACCESS_EXPIRE_MINUTES * 60,
        is_anonymous=user.is_anonymous,
        is_email_verified=bool(user.is_email_verified),
    )


async def _send_verification(user: User, db: AsyncSession) -> None:
    code, code_hash = generate_verification_code()
    user.email_verification_code_hash = code_hash
    user.email_verification_expires_at = (
        datetime.now(timezone.utc)
        + timedelta(minutes=settings.EMAIL_VERIFICATION_EXPIRE_MINUTES)
    )
    await db.commit()
    await send_verification_email(user.email, code)


@router.post("/guest", response_model=TokenResponse)
async def create_guest(body: GuestRequest, db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(User).where(User.device_id == body.device_id, User.is_anonymous == True)
    )
    user = result.scalar_one_or_none()

    if not user:
        user = User(device_id=body.device_id, is_anonymous=True, is_email_verified=False)
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
        is_email_verified=False,
    )
    db.add(user)
    await db.flush()
    await db.refresh(user)

    await _send_verification(user, db)
    return await _issue_tokens(user, db)


@router.post("/login", response_model=TokenResponse)
async def login(body: LoginRequest, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(User).where(User.email == body.email))
    user = result.scalar_one_or_none()

    if not user or not user.password_hash or not verify_password(body.password, user.password_hash):
        raise HTTPException(401, "Credenciais inválidas")

    if user.is_banned:
        raise HTTPException(403, detail={
            "code": "account_banned",
            "ban_reason": user.ban_reason,
            "message": "Conta permanentemente banida.",
        })

    now = datetime.now(timezone.utc)
    if user.suspended_until and user.suspended_until > now:
        raise HTTPException(403, detail={
            "code": "account_suspended",
            "suspended_until": user.suspended_until.isoformat(),
            "message": "Conta suspensa temporariamente.",
        })

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

    if not user.is_email_verified:
        user.is_email_verified = True

    await db.commit()

    if user.is_banned:
        raise HTTPException(403, detail={
            "code": "account_banned",
            "ban_reason": user.ban_reason,
            "message": "Conta permanentemente banida.",
        })

    now = datetime.now(timezone.utc)
    if user.suspended_until and user.suspended_until > now:
        raise HTTPException(403, detail={
            "code": "account_suspended",
            "suspended_until": user.suspended_until.isoformat(),
            "message": "Conta suspensa temporariamente.",
        })

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

    await db.execute(
        update(RefreshToken)
        .where(RefreshToken.id == record.id)
        .values(revoked_at=now)
    )

    result = await db.execute(select(User).where(User.id == record.user_id))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(401, "Utilizador não encontrado")

    if user.is_banned:
        raise HTTPException(403, detail={
            "code": "account_banned",
            "ban_reason": user.ban_reason,
            "message": "Conta permanentemente banida.",
        })

    now = datetime.now(timezone.utc)
    if user.suspended_until and user.suspended_until > now:
        raise HTTPException(403, detail={
            "code": "account_suspended",
            "suspended_until": user.suspended_until.isoformat(),
            "message": "Conta suspensa temporariamente.",
        })

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
    user.is_email_verified = False

    await db.commit()
    await db.refresh(user)

    await _send_verification(user, db)
    return await _issue_tokens(user, db)


@router.post("/verify-email")
async def verify_email(
    body: VerifyEmailRequest,
    user: User = Depends(require_user),
    db: AsyncSession = Depends(get_db),
):
    if user.is_email_verified:
        return {"status": "already_verified"}

    if not user.email_verification_code_hash or not user.email_verification_expires_at:
        raise HTTPException(400, "Nenhum código de verificação pendente")

    now = datetime.now(timezone.utc)
    expires = user.email_verification_expires_at
    if expires.tzinfo is None:
        expires = expires.replace(tzinfo=timezone.utc)
    if expires < now:
        raise HTTPException(400, "Código expirado. Solicita um novo.")

    if hash_verification_code(body.code) != user.email_verification_code_hash:
        raise HTTPException(400, "Código inválido")

    user.is_email_verified = True
    user.email_verification_code_hash = None
    user.email_verification_expires_at = None
    await db.commit()

    return {"status": "verified"}


@router.post("/resend-verification")
async def resend_verification(
    user: User = Depends(require_user),
    db: AsyncSession = Depends(get_db),
):
    if user.is_email_verified:
        raise HTTPException(400, "Email já verificado")

    if not user.email:
        raise HTTPException(400, "Utilizador sem email associado")

    await _send_verification(user, db)
    return {"status": "sent"}


@router.post("/forgot-password")
async def forgot_password(body: ForgotPasswordRequest, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(User).where(User.email == body.email))
    user = result.scalar_one_or_none()

    # Only send for email/password accounts; always return same response to avoid enumeration
    if user and user.password_hash:
        code, code_hash = generate_verification_code()
        user.password_reset_code_hash = code_hash
        user.password_reset_expires_at = (
            datetime.now(timezone.utc)
            + timedelta(minutes=settings.EMAIL_VERIFICATION_EXPIRE_MINUTES)
        )
        await db.commit()
        await send_password_reset_email(user.email, code)

    return {"status": "sent"}


@router.post("/reset-password")
async def reset_password(body: ResetPasswordRequest, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(User).where(User.email == body.email))
    user = result.scalar_one_or_none()

    if not user or not user.password_reset_code_hash or not user.password_reset_expires_at:
        raise HTTPException(400, "Pedido de recuperação inválido ou expirado")

    now = datetime.now(timezone.utc)
    expires = user.password_reset_expires_at
    if expires.tzinfo is None:
        expires = expires.replace(tzinfo=timezone.utc)
    if expires < now:
        raise HTTPException(400, "Código expirado. Solicita um novo.")

    if hash_verification_code(body.code) != user.password_reset_code_hash:
        raise HTTPException(400, "Código inválido")

    user.password_hash = hash_password(body.new_password)
    user.password_reset_code_hash = None
    user.password_reset_expires_at = None

    # Revoke all active refresh tokens so existing sessions are invalidated
    await db.execute(
        update(RefreshToken)
        .where(RefreshToken.user_id == user.id, RefreshToken.revoked_at.is_(None))
        .values(revoked_at=now)
    )
    await db.commit()

    return {"status": "ok"}

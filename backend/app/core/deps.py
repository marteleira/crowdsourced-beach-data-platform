from datetime import datetime, timedelta, timezone
from typing import Optional
from uuid import UUID

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.security import decode_access_token
from app.models.beach import Beach
from app.models.beach_status import OccupancyHeartbeat
from app.models.user import User

bearer_scheme = HTTPBearer(auto_error=False)


def raise_if_account_locked(user: "User") -> None:
    """Raise HTTPException 403 if the user is banned or currently suspended.

    Called during token issuance (login / google / refresh) where the normal
    dependency chain hasn't run yet and we must block proactively.
    """
    if user.is_banned:
        raise HTTPException(
            status_code=403,
            detail={
                "code": "account_banned",
                "ban_reason": user.ban_reason,
                "message": "Conta permanentemente banida.",
            },
        )
    now = datetime.now(timezone.utc)
    if user.suspended_until and user.suspended_until > now:
        raise HTTPException(
            status_code=403,
            detail={
                "code": "account_suspended",
                "suspended_until": user.suspended_until.isoformat(),
                "message": "Conta suspensa temporariamente.",
            },
        )


async def get_current_user(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(bearer_scheme),
    db: AsyncSession = Depends(get_db),
) -> Optional[User]:
    if not credentials:
        return None

    payload = decode_access_token(credentials.credentials)
    if not payload:
        raise HTTPException(status_code=401, detail="Token inválido ou expirado")

    user_id = UUID(payload["sub"])
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()

    if not user:
        raise HTTPException(status_code=401, detail="Utilizador não encontrado")

    raise_if_account_locked(user)
    return user


async def require_user(
    user: Optional[User] = Depends(get_current_user),
) -> User:
    if user is None:
        raise HTTPException(status_code=401, detail="Autenticação necessária")

    if user.scheduled_deletion_at:
        raise HTTPException(
            status_code=403,
            detail={
                "code": "account_pending_deletion",
                "scheduled_deletion_at": user.scheduled_deletion_at.isoformat(),
                "message": "Conta agendada para eliminação. Cancela em /users/me/cancel-deletion.",
            },
        )

    now = datetime.now(timezone.utc)
    if user.suspended_until and user.suspended_until > now:
        raise HTTPException(
            status_code=403,
            detail={
                "code": "account_suspended",
                "suspended_until": user.suspended_until.isoformat(),
                "message": "Conta suspensa temporariamente.",
            },
        )

    return user


async def require_registered_user(
    user: User = Depends(require_user),
) -> User:
    """Like require_user but also rejects anonymous/guest accounts."""
    if user.is_anonymous:
        raise HTTPException(
            status_code=403,
            detail={
                "code": "guest_not_allowed",
                "message": "Cria uma conta para realizar esta ação.",
            },
        )
    return user


async def require_user_or_pending(
    user: Optional[User] = Depends(get_current_user),
) -> User:
    """Like require_user but allows accounts with scheduled_deletion_at set.
    Use only for endpoints that let the user cancel their own deletion."""
    if user is None:
        raise HTTPException(status_code=401, detail="Autenticação necessária")
    return user


async def get_beach_or_404(slug: str, db: AsyncSession) -> Beach:
    result = await db.execute(select(Beach).where(Beach.slug == slug))
    beach = result.scalar_one_or_none()
    if not beach:
        raise HTTPException(404, f"Praia '{slug}' não encontrada")
    return beach


async def was_recently_present(
    db: AsyncSession, user_id, beach_id: int, *, window: timedelta
) -> bool:
    cutoff = datetime.now(timezone.utc) - window
    result = await db.execute(
        select(OccupancyHeartbeat.id)
        .where(
            OccupancyHeartbeat.user_id == user_id,
            OccupancyHeartbeat.beach_id == beach_id,
            OccupancyHeartbeat.created_at > cutoff,
        )
        .limit(1)
    )
    return result.scalar_one_or_none() is not None


def require_reputation(min_rep: int):
    async def check(user: User = Depends(require_user)) -> User:
        if user.reputation < min_rep:
            raise HTTPException(
                status_code=403,
                detail=f"Reputação mínima necessária: {min_rep}",
            )
        return user
    return check

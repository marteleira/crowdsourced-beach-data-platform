from datetime import timedelta
from typing import Optional
from uuid import UUID

from fastapi import Depends, Header, HTTPException
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.constants import AUTO_BAN_REPUTATION_THRESHOLD
from app.core.database import get_db
from app.core.errors import api_error
from app.core.i18n import t
from app.core.language import DEFAULT_LANGUAGE, resolve_language
from app.core.utils import now_utc
from app.core.security import decode_access_token
from app.models.beach import Beach
from app.models.beach_status import OccupancyHeartbeat
from app.models.user import User

bearer_scheme = HTTPBearer(auto_error=False)


async def get_language(accept_language: Optional[str] = Header(None)) -> str:
    return resolve_language(accept_language)


def raise_if_account_locked(user: "User", lang: str) -> None:
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
                "message": t("account_banned", lang),
                "ban_reason_message": (
                    t(user.ban_reason, lang, threshold=AUTO_BAN_REPUTATION_THRESHOLD)
                    if user.ban_reason else None
                ),
            },
        )
    now = now_utc()
    if user.suspended_until and user.suspended_until > now:
        raise api_error(
            403, "account_suspended", lang,
            extra={"suspended_until": user.suspended_until.isoformat()},
        )


async def get_current_user(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(bearer_scheme),
    db: AsyncSession = Depends(get_db),
    accept_language: Optional[str] = Header(None),
) -> Optional[User]:
    lang = resolve_language(accept_language)

    if not credentials:
        return None

    payload = decode_access_token(credentials.credentials)
    if not payload:
        raise api_error(401, "token_invalid", lang)

    user_id = UUID(payload["sub"])
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()

    if not user:
        raise api_error(401, "user_not_found", lang)

    if user.language != lang:
        user.language = lang
        db.add(user)
        await db.commit()

    raise_if_account_locked(user, lang)
    return user


async def require_user(
    user: Optional[User] = Depends(get_current_user),
    accept_language: Optional[str] = Header(None),
) -> User:
    if user is None:
        raise api_error(401, "auth_required", resolve_language(accept_language))

    if user.scheduled_deletion_at:
        raise api_error(
            403, "account_pending_deletion", user.language,
            extra={"scheduled_deletion_at": user.scheduled_deletion_at.isoformat()},
        )

    now = now_utc()
    if user.suspended_until and user.suspended_until > now:
        raise api_error(
            403, "account_suspended", user.language,
            extra={"suspended_until": user.suspended_until.isoformat()},
        )

    return user


async def require_registered_user(
    user: User = Depends(require_user),
) -> User:
    """Like require_user but also rejects anonymous/guest accounts."""
    if user.is_anonymous:
        raise api_error(403, "guest_not_allowed", user.language)
    return user


async def require_user_or_pending(
    user: Optional[User] = Depends(get_current_user),
    accept_language: Optional[str] = Header(None),
) -> User:
    """Like require_user but allows accounts with scheduled_deletion_at set.
    Use only for endpoints that let the user cancel their own deletion."""
    if user is None:
        raise api_error(401, "auth_required", resolve_language(accept_language))
    return user


async def get_beach_or_404(slug: str, db: AsyncSession, lang: str = DEFAULT_LANGUAGE) -> Beach:
    result = await db.execute(select(Beach).where(Beach.slug == slug))
    beach = result.scalar_one_or_none()
    if not beach:
        raise api_error(404, "beach_slug_not_found", lang, slug=slug)
    return beach


async def was_recently_present(
    db: AsyncSession, user_id, beach_id: int, *, window: timedelta
) -> bool:
    cutoff = now_utc() - window
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
    async def check(user: User = Depends(require_registered_user)) -> User:
        if user.reputation < min_rep:
            raise api_error(403, "insufficient_reputation", user.language, min_rep=min_rep)
        return user
    return check


def require_presence(window: timedelta, code: str):
    """Returns the Beach so callers don't need to fetch it again."""
    async def check(
        slug: str,
        db: AsyncSession = Depends(get_db),
        user: User = Depends(require_user),
    ) -> Beach:
        beach = await get_beach_or_404(slug, db, user.language)
        present = await was_recently_present(db, user.id, beach.id, window=window)
        if not present:
            raise api_error(403, code, user.language)
        return beach
    return check

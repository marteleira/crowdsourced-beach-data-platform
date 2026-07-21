"""
Push notification dispatch service

Sends push notifications to users currently at a beach (active heartbeat within
CHECKIN_WINDOW_MINUTES) and users who have the beach in favourites,
respects each user's notification settings and quiet hours.

FCM/APNs sending is stubbed, integrate with firebase-admin SDK when credentials
are available
"""
import logging
from datetime import datetime, timedelta, timezone
from typing import Optional
from zoneinfo import ZoneInfo

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.constants import CHECKIN_WINDOW_MINUTES, REPORT_TYPE_EMOJIS, FLAG_COLOR_EMOJIS, SEVERITY_LABELS
from app.models.beach_status import OccupancyHeartbeat
from app.models.user import User
from app.models.user_extended import PushToken, UserFavourite, effective_notification_settings

logger = logging.getLogger(__name__)

# quiet_hours_start/end are entered by users as local (Portugal) time
LOCAL_TZ = ZoneInfo("Europe/Lisbon")


def _in_quiet_hours(settings: dict) -> bool:
    if not settings.get("quiet_hours_enabled"):
        return False
    now_time = datetime.now(LOCAL_TZ).strftime("%H:%M")
    start = settings.get("quiet_hours_start", "22:00")
    end = settings.get("quiet_hours_end", "07:00")
    if start <= end:
        return start <= now_time <= end
    return now_time >= start or now_time <= end


def _alert_type_allowed(settings: dict, alert_type: str) -> bool:
    types = settings.get("alert_types", {})
    return types.get(alert_type, True)


def _severity_allowed(settings: dict, severity: int) -> bool:
    return severity >= settings.get("min_severity", 1)


async def _get_tokens(db: AsyncSession, user_id) -> list[str]:
    r = await db.execute(select(PushToken.token).where(PushToken.user_id == user_id))
    return [row[0] for row in r.all()]


async def _fetch_eligible_user(db: AsyncSession, user_id) -> tuple["User | None", dict]:
    """Load a candidate user and their notification settings.
    Returns (None, {}) if the user is missing, banned, or has global notifications off."""
    user_r = await db.execute(select(User).where(User.id == user_id))
    user = user_r.scalar_one_or_none()
    if not user or user.is_banned:
        return None, {}
    settings = effective_notification_settings(user)
    if not settings.get("global_enabled"):
        return None, {}
    return user, settings


async def _checkin_and_fav_candidates(
    db: AsyncSession,
    beach_id: int,
    exclude_user_id=None,
) -> tuple[set, set]:
    """Returns (checkin_users, fav_users), optionally excluding one user id."""
    cutoff = datetime.now(timezone.utc) - timedelta(minutes=CHECKIN_WINDOW_MINUTES)

    checkin_r = await db.execute(
        select(OccupancyHeartbeat.user_id)
        .where(
            OccupancyHeartbeat.beach_id == beach_id,
            OccupancyHeartbeat.created_at > cutoff,
            OccupancyHeartbeat.user_id.isnot(None),
        )
        .distinct()
    )
    checkin_users = {row[0] for row in checkin_r.all()}

    fav_r = await db.execute(
        select(UserFavourite.user_id).where(UserFavourite.beach_id == beach_id)
    )
    fav_users = {row[0] for row in fav_r.all()}

    if exclude_user_id is not None:
        checkin_users.discard(exclude_user_id)
        fav_users.discard(exclude_user_id)

    return checkin_users, fav_users


async def dispatch_report_notification(
    db: AsyncSession,
    beach_id: int,
    alert_type: str,
    severity: int,
    beach_name: str,
    note: Optional[str],
    exclude_user_id=None,
) -> int:
    """
    Notify users at the beach (or with it in favourites) about a new report.
    exclude_user_id skips the report author.
    Returns the number of users notified.
    """
    checkin_users, fav_users = await _checkin_and_fav_candidates(
        db, beach_id, exclude_user_id=exclude_user_id
    )
    candidate_ids = checkin_users | fav_users
    notified = 0

    emoji = REPORT_TYPE_EMOJIS.get(alert_type, "⚠️")
    title = f"{emoji} {alert_type.replace('_', ' ').title()} · {beach_name}"
    body = note or f"Aviso reportado. Severidade: {SEVERITY_LABELS.get(severity, str(severity))}."

    for user_id in candidate_ids:
        user, settings = await _fetch_eligible_user(db, user_id)
        if user is None:
            continue

        is_checkin = user_id in checkin_users
        is_favourite = user_id in fav_users

        if is_checkin and not settings.get("checkin_alerts"):
            if not (is_favourite and settings.get("favourite_alerts_enabled")):
                continue
        if is_favourite and not is_checkin:
            if not settings.get("favourite_alerts_enabled"):
                continue
            per_beach = settings.get("favourite_alerts_per_beach", {})
            if not per_beach.get(str(beach_id), True):
                continue

        if not _alert_type_allowed(settings, alert_type):
            continue
        if not _severity_allowed(settings, severity):
            continue

        # Quiet hours — severity 3 (alto) always goes through
        if severity < 3 and _in_quiet_hours(settings):
            continue

        tokens = await _get_tokens(db, user_id)
        if not tokens:
            continue

        for token in tokens:
            await _send_push(token, title, body, beach_id=beach_id)
        notified += 1

    return notified


async def dispatch_flag_notification(
    db: AsyncSession,
    beach_id: int,
    old_color: str,
    new_color: str,
    beach_name: str,
) -> int:
    """
    Notify users at the beach (or with it in favourites) about a flag color change,
    Returns the number of users notified.
    """
    checkin_users, fav_users = await _checkin_and_fav_candidates(db, beach_id)
    candidate_ids = checkin_users | fav_users
    notified = 0

    emoji = FLAG_COLOR_EMOJIS.get(new_color, "🏖️")
    title = f"{emoji} Bandeira alterada · {beach_name}"
    body = f"A bandeira mudou de {old_color} para {new_color}."

    for user_id in candidate_ids:
        user, settings = await _fetch_eligible_user(db, user_id)
        if user is None:
            continue
        if not settings.get("flag_change_alerts", True):
            continue

        is_checkin = user_id in checkin_users
        is_favourite = user_id in fav_users

        if is_checkin and not settings.get("checkin_alerts"):
            if not (is_favourite and settings.get("favourite_alerts_enabled")):
                continue
        if is_favourite and not is_checkin:
            if not settings.get("favourite_alerts_enabled"):
                continue
            per_beach = settings.get("favourite_alerts_per_beach", {})
            if not per_beach.get(str(beach_id), True):
                continue

        if _in_quiet_hours(settings):
            continue

        tokens = await _get_tokens(db, user_id)
        if not tokens:
            continue

        for token in tokens:
            await _send_push(token, title, body, beach_id=beach_id)
        notified += 1

    return notified


async def _send_push(token: str, title: str, body: str, beach_id: int) -> None:
    from app.core.firebase import is_firebase_ready
    if not is_firebase_ready():
        logger.info("PUSH [stub] -> %s | %s: %s", token[:12] + "...", title, body)
        return

    from firebase_admin import messaging
    import asyncio

    message = messaging.Message(
        notification=messaging.Notification(title=title, body=body),
        data={"beach_id": str(beach_id), "route": f"/beach/{beach_id}/alerts"},
        token=token,
    )
    try:
        # messaging.send is synchronous — run in thread pool to avoid blocking event loop
        result = await asyncio.get_event_loop().run_in_executor(None, messaging.send, message)
        logger.info("PUSH sent -> %s | message_id=%s", token[:12] + "...", result)
    except messaging.UnregisteredError:
        logger.warning("PUSH token unregistered, should be removed: %s", token[:12] + "...")
    except Exception as exc:
        logger.error("PUSH failed for token %s: %s", token[:12] + "...", exc)

"""
Push notification dispatch service.

Determines which users should receive a notification when a report is validated
or a flag changes. Respects each user's notification settings and quiet hours.

FCM/APNs sending is stubbed — integrate with firebase-admin SDK when credentials
are available. The targeting logic is complete and production-ready.
"""
import logging
from datetime import datetime, timezone
from typing import Optional

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.beach_status import OccupancyHeartbeat
from app.models.user import User
from app.models.user_extended import PushToken, UserFavourite, effective_notification_settings
from datetime import timedelta

logger = logging.getLogger(__name__)

CHECKIN_WINDOW_MINUTES = 180   # 3h active check-in session
PROXIMITY_WINDOW_MINUTES = 20  # GPS within radius


def _in_quiet_hours(settings: dict) -> bool:
    if not settings.get("quiet_hours_enabled"):
        return False
    now_time = datetime.now(timezone.utc).strftime("%H:%M")
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


async def dispatch_report_notification(
    db: AsyncSession,
    beach_id: int,
    alert_type: str,
    severity: int,
    beach_name: str,
    note: Optional[str],
) -> int:
    """
    Send push notifications to all users who should receive this alert.
    Returns the number of users notified.
    """
    cutoff_checkin = datetime.now(timezone.utc) - timedelta(minutes=CHECKIN_WINDOW_MINUTES)
    cutoff_proximity = datetime.now(timezone.utc) - timedelta(minutes=PROXIMITY_WINDOW_MINUTES)

    # 1. Users in check-in (heartbeat within 3h)
    checkin_r = await db.execute(
        select(OccupancyHeartbeat.user_id)
        .where(
            OccupancyHeartbeat.beach_id == beach_id,
            OccupancyHeartbeat.created_at > cutoff_checkin,
            OccupancyHeartbeat.user_id != None,
        )
        .distinct()
    )
    checkin_users = {row[0] for row in checkin_r.all()}

    # 2. Users with beach in favourites
    fav_r = await db.execute(
        select(UserFavourite.user_id).where(UserFavourite.beach_id == beach_id)
    )
    fav_users = {row[0] for row in fav_r.all()}

    candidate_ids = checkin_users | fav_users
    notified = 0

    for user_id in candidate_ids:
        user_r = await db.execute(select(User).where(User.id == user_id))
        user = user_r.scalar_one_or_none()
        if not user or user.is_banned:
            continue

        settings = effective_notification_settings(user)

        if not settings.get("global_enabled"):
            continue

        # Determine why this user is a candidate and check corresponding toggle
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

        # Quiet hours — severity 3 always goes through
        if severity < 3 and _in_quiet_hours(settings):
            continue

        tokens = await _get_tokens(db, user_id)
        if not tokens:
            continue

        severity_labels = {1: "Mild", 2: "Moderate", 3: "Severe"}
        type_emojis = {
            "jellyfish": "🪼", "strong_current": "⚡",
            "pollution": "🗑️", "rough_sea": "🌊", "other_alert": "⚠️",
        }
        emoji = type_emojis.get(alert_type, "⚠️")
        title = f"{emoji} {alert_type.replace('_', ' ').title()} · {beach_name}"
        body = note or f"Reported condition. Severity: {severity_labels.get(severity, str(severity))}."

        for token in tokens:
            await _send_push(token, title, body, beach_id=beach_id)

        notified += 1

    return notified


async def _send_push(token: str, title: str, body: str, beach_id: int) -> None:
    """
    Stub — replace with actual FCM call once firebase-admin is configured.

    Example FCM call:
        message = messaging.Message(
            notification=messaging.Notification(title=title, body=body),
            data={"beach_id": str(beach_id), "route": f"/beach/{beach_id}/alerts"},
            token=token,
        )
        messaging.send(message)
    """
    logger.info("PUSH [stub] → %s | %s: %s", token[:12] + "...", title, body)

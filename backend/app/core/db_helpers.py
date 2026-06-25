"""
Shared async database query helpers.
These patterns appear in multiple routers and are extracted here to avoid duplication.
"""
from datetime import datetime, timedelta
from typing import Optional, TYPE_CHECKING

from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.constants import (
    OCCUPANCY_WINDOW_MINUTES,
    OCCUPANCY_LOW_RATIO, OCCUPANCY_MEDIUM_RATIO,
    OCCUPANCY_LOW_THRESHOLD, OCCUPANCY_MEDIUM_THRESHOLD,
)
from app.core.utils import now_utc
from app.models.beach import Beach
from app.models.beach_status import BeachStatus, OccupancyHeartbeat
from app.models.report import Report
from app.schemas.beach import BeachSummary, OccupancyData
from app.services.activity import get_activity_level, get_params


async def get_beach_flag_status(db: AsyncSession, beach_id: int) -> tuple[str, float]:
    """Return (flag_color, flag_confidence) for a beach, defaulting to unknown/0.0."""
    result = await db.execute(select(BeachStatus).where(BeachStatus.beach_id == beach_id))
    status = result.scalar_one_or_none()
    return (status.flag_color, status.flag_confidence) if status else ("unknown", 0.0)


async def count_active_alerts(db: AsyncSession, beach_id: int, now: datetime) -> int:
    """Count non-expired active reports for a beach."""
    result = await db.execute(
        select(func.count(Report.id)).where(
            Report.beach_id == beach_id,
            Report.is_expired.is_(False),
            Report.expires_at > now,
        )
    )
    return result.scalar_one() or 0


async def compute_occupancy(db: AsyncSession, beach: Beach) -> OccupancyData:
    """Compute real-time occupancy for a beach from recent heartbeats."""
    cutoff = now_utc() - timedelta(minutes=OCCUPANCY_WINDOW_MINUTES)
    stmt = (
        select(func.count(func.distinct(OccupancyHeartbeat.user_id)))
        .where(
            OccupancyHeartbeat.beach_id == beach.id,
            OccupancyHeartbeat.created_at > cutoff,
        )
    )
    result = await db.execute(stmt)
    count = result.scalar_one() or 0

    if beach.max_capacity:
        ratio = count / beach.max_capacity
        level = "low" if ratio < OCCUPANCY_LOW_RATIO else "medium" if ratio < OCCUPANCY_MEDIUM_RATIO else "high"
    else:
        level = "low" if count < OCCUPANCY_LOW_THRESHOLD else "medium" if count < OCCUPANCY_MEDIUM_THRESHOLD else "high"

    if count == 0 and not beach.has_capacity_data:
        level = "unknown"

    return OccupancyData(
        level=level,
        user_count=count,
        is_estimate=True,
        last_updated=now_utc(),
    )


async def build_beach_summary(
    db: AsyncSession,
    beach: Beach,
    now: datetime,
    *,
    distance_km: Optional[float] = None,
    recommendation_score: Optional[float] = None,
) -> BeachSummary:
    """Assemble a BeachSummary for a single beach (used by list and favourites endpoints)."""
    activity_level = await get_activity_level(db, beach.id)
    flag_color, flag_confidence = await get_beach_flag_status(db, beach.id)
    alerts_count = await count_active_alerts(db, beach.id, now)
    occupancy = await compute_occupancy(db, beach)
    params = get_params(activity_level)

    return BeachSummary(
        id=beach.id,
        slug=beach.slug,
        name=beach.name,
        lat=beach.lat,
        lon=beach.lon,
        flag_color=flag_color,
        flag_confidence=flag_confidence,
        occupancy_level=occupancy.level,
        active_alerts_count=alerts_count,
        activity_level=activity_level,
        activity_label=params["label"],
        distance_km=round(distance_km, 1) if distance_km is not None else None,
        recommendation_score=round(recommendation_score, 3) if recommendation_score is not None else None,
        cover_photo_url=beach.cover_photo_url,
        municipality=beach.municipality,
    )

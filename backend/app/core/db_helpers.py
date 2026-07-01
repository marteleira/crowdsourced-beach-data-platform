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
    OCCUPANCY_REPORT_EXPIRE_MINUTES, OCCUPANCY_REPORT_CONFIDENCE_THRESHOLD,
)
from app.core.utils import now_utc
from app.models.beach import Beach
from app.models.beach_status import BeachStatus, OccupancyHeartbeat, OccupancyReport
from app.models.report import Report
from app.models.user import User
from app.schemas.beach import BeachSummary, OccupancyData
from app.services.activity import get_activity_level, get_params


# Occupancy helpers 

def _reputation_weight(reputation: int) -> float:
    """Map user reputation to a report weight multiplier."""
    if reputation < 0:
        return 0.1
    if reputation < 10:
        return 0.5   #novo
    if reputation < 50:
        return 1.0   # regular
    if reputation < 150:
        return 1.5   # contribuidor
    return 2.0       # veterano


def _level_from_report_score(score: float) -> str:
    """Map weighted average report level (1–5) to low/medium/high."""
    if score <= 2.0:
        return "low"
    if score <= 3.5:
        return "medium"
    return "high"


def _level_to_int(level: str) -> int:
    return {"low": 1, "medium": 2, "high": 3}.get(level, 0)


def _int_to_level(value: float) -> str:
    if value < 1.5:
        return "low"
    if value < 2.5:
        return "medium"
    return "high"


def _blend_levels(heartbeat_level: str, report_level: str, report_confidence: float) -> str:
    """Linearly interpolate between heartbeat and report level signals."""
    hb = _level_to_int(heartbeat_level)
    rp = _level_to_int(report_level)
    if hb == 0:
        return report_level
    blended = hb * (1.0 - report_confidence) + rp * report_confidence
    return _int_to_level(blended)


def _heartbeat_level(beach: Beach, count: int) -> str:
    """Derive low/medium/high from heartbeat count alone."""
    if beach.max_capacity:
        ratio = count / beach.max_capacity
        return "low" if ratio < OCCUPANCY_LOW_RATIO else "medium" if ratio < OCCUPANCY_MEDIUM_RATIO else "high"
    return "low" if count < OCCUPANCY_LOW_THRESHOLD else "medium" if count < OCCUPANCY_MEDIUM_THRESHOLD else "high"


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
    """Compute real-time occupancy blending heartbeat count with crowdsourced reports."""
    now = now_utc()

    #  Heartbeat signal 
    hb_cutoff = now - timedelta(minutes=OCCUPANCY_WINDOW_MINUTES)
    hb_count = await db.scalar(
        select(func.count(func.distinct(OccupancyHeartbeat.user_id)))
        .where(OccupancyHeartbeat.beach_id == beach.id, OccupancyHeartbeat.created_at > hb_cutoff)
    ) or 0
    hb_level = _heartbeat_level(beach, hb_count)

    #  Report signal 
    rpt_cutoff = now - timedelta(minutes=OCCUPANCY_REPORT_EXPIRE_MINUTES)
    rows = await db.execute(
        select(OccupancyReport.level, OccupancyReport.created_at, User.reputation)
        .join(User, OccupancyReport.user_id == User.id)
        .where(OccupancyReport.beach_id == beach.id, OccupancyReport.created_at > rpt_cutoff)
    )
    reports = rows.all()

    total_weight = 0.0
    weighted_sum = 0.0
    for rpt_level, created_at, reputation in reports:
        age_minutes = (now - created_at).total_seconds() / 60
        time_decay = max(0.0, 1.0 - age_minutes / OCCUPANCY_REPORT_EXPIRE_MINUTES)
        w = _reputation_weight(reputation) * time_decay
        total_weight += w
        weighted_sum += rpt_level * w

    report_count = len(reports)
    report_confidence = min(1.0, total_weight / OCCUPANCY_REPORT_CONFIDENCE_THRESHOLD)

    #  Blend 
    if report_confidence >= 0.8:
        level = _level_from_report_score(weighted_sum / total_weight)
    elif report_confidence >= 0.2:
        report_level = _level_from_report_score(weighted_sum / total_weight)
        level = _blend_levels(hb_level, report_level, report_confidence)
    else:
        level = hb_level

    if hb_count == 0 and report_confidence < 0.2 and not beach.has_capacity_data:
        level = "unknown"

    return OccupancyData(
        level=level,
        user_count=hb_count,
        report_count=report_count,
        report_confidence=round(report_confidence, 2),
        is_estimate=True,
        last_updated=now,
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

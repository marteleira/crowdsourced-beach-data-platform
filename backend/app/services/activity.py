"""
Beach activity level helpers.
Determines whether a beach is in low/normal/high activity mode,
which adjusts TTLs, confirmation thresholds, and confidence decay.
"""
from dataclasses import dataclass
from datetime import timedelta
from typing import Optional

from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.utils import now_utc
from app.models.beach_status import OccupancyHeartbeat


@dataclass(frozen=True)
class ActivityParams:
    level: str
    ttl_multiplier: float
    contradiction_threshold: dict[str, int]
    flag_confirmation_min: int
    confidence_decay_per_minute: float
    label: Optional[str]

ACTIVITY_PARAMS = {
    "high": {
        "ttl_multiplier": 1.0,
        "contradiction_threshold": {"jellyfish": 3, "strong_current": 3, "other_alert": 5, "pollution": 4, "rough_sea": 3},
        "flag_confirmation_min": 5,
        "confidence_decay_per_minute": 0.008,
        "label": None,
    },
    "normal": {
        "ttl_multiplier": 1.5,
        "contradiction_threshold": {"jellyfish": 3, "strong_current": 3, "other_alert": 4, "pollution": 3, "rough_sea": 3},
        "flag_confirmation_min": 3,
        "confidence_decay_per_minute": 0.004,
        "label": None,
    },
    "low": {
        "ttl_multiplier": 3.0,
        "contradiction_threshold": {"jellyfish": 2, "strong_current": 2, "other_alert": 3, "pollution": 2, "rough_sea": 2},
        "flag_confirmation_min": 1,
        "confidence_decay_per_minute": 0.001,
        "label": "unverified",
    },
}

BASE_TTL_MINUTES = {
    "jellyfish": 180,
    "strong_current": 120,
    "pollution": 240,
    "rough_sea": 120,
    "other_alert": 60,
}


async def get_activity_level(db: AsyncSession, beach_id: int) -> str:
    cutoff = now_utc() - timedelta(hours=1)
    stmt = (
        select(func.count(func.distinct(OccupancyHeartbeat.user_id)))
        .where(
            OccupancyHeartbeat.beach_id == beach_id,
            OccupancyHeartbeat.created_at > cutoff,
        )
    )
    result = await db.execute(stmt)
    count = result.scalar_one() or 0

    if count >= 10:
        return "high"
    if count >= 3:
        return "normal"
    return "low"


def get_params(level: str) -> dict:
    return ACTIVITY_PARAMS.get(level, ACTIVITY_PARAMS["low"])


async def get_activity_params(db: AsyncSession, beach_id: int) -> ActivityParams:
    """Single call: fetch activity level + return typed params — avoids double-lookup."""
    level = await get_activity_level(db, beach_id)
    p = get_params(level)
    return ActivityParams(
        level=level,
        ttl_multiplier=p["ttl_multiplier"],
        contradiction_threshold=p["contradiction_threshold"],
        flag_confirmation_min=p["flag_confirmation_min"],
        confidence_decay_per_minute=p["confidence_decay_per_minute"],
        label=p["label"],
    )


def report_ttl_minutes(report_type: str, level: str) -> int:
    base = BASE_TTL_MINUTES.get(report_type, 60)
    multiplier = get_params(level)["ttl_multiplier"]
    return int(base * multiplier)

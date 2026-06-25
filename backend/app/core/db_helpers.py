"""
Shared async database query helpers.
These patterns appear in multiple routers and are extracted here to avoid duplication.
"""
from datetime import datetime

from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.beach_status import BeachStatus
from app.models.report import Report


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

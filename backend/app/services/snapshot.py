"""
Snapshot helpers — fetch from external API with automatic fallback to DB cache.
Every successful fetch is saved to api_snapshots. On failure, the latest
snapshot is returned along with its age so the response can be flagged.
"""
import logging
from datetime import datetime
from typing import Optional, Callable, Awaitable, Any

from sqlalchemy import select, desc
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.snapshot import ApiSnapshot

logger = logging.getLogger(__name__)


async def save_snapshot(
    db: AsyncSession,
    source: str,
    data: dict,
    beach_id: Optional[int] = None,
) -> ApiSnapshot:
    snap = ApiSnapshot(source=source, beach_id=beach_id, data=data)
    db.add(snap)
    await db.commit()
    return snap


async def get_latest_snapshot(
    db: AsyncSession,
    source: str,
    beach_id: Optional[int] = None,
) -> Optional[ApiSnapshot]:
    stmt = (
        select(ApiSnapshot)
        .where(
            ApiSnapshot.source == source,
            ApiSnapshot.beach_id == beach_id,
        )
        .order_by(desc(ApiSnapshot.fetched_at))
        .limit(1)
    )
    result = await db.execute(stmt)
    return result.scalar_one_or_none()


async def fetch_with_fallback(
    db: AsyncSession,
    source: str,
    fetcher: Callable[[], Awaitable[Any]],
    beach_id: Optional[int] = None,
) -> tuple[Any, str, Optional[datetime]]:
    """
    Call `fetcher()`. On success, save snapshot and return (data, "live", None).
    On failure, load latest snapshot and return (data, "snapshot", fetched_at).
    Raises HTTPException 503 if no snapshot exists.
    """
    from fastapi import HTTPException

    try:
        data = await fetcher()
        if data is not None:
            await save_snapshot(db, source, data, beach_id)
            return data, "live", None
    except Exception as e:
        logger.warning("Live fetch failed for %s (beach_id=%s), falling back to cache: %s", source, beach_id, e)

    snap = await get_latest_snapshot(db, source, beach_id)
    if snap is None:
        raise HTTPException(503, f"Dados de '{source}' indisponíveis e sem cache")

    return snap.data, "snapshot", snap.fetched_at

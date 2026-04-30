from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select, update, delete, func
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List

from app.core.database import get_db
from app.core.deps import require_user
from app.models.beach import Beach
from app.models.beach_status import BeachStatus, OccupancyHeartbeat
from app.models.report import Report
from app.models.user import User
from app.models.user_extended import UserFavourite
from app.schemas.beach import BeachSummary
from app.services.activity import get_activity_level, get_params
from datetime import datetime, timedelta, timezone
from pydantic import BaseModel

router = APIRouter(prefix="/users/me/favourites", tags=["favourites"])


class FavouriteOrderRequest(BaseModel):
    ordered_slugs: List[str]


async def _beach_summary(db: AsyncSession, beach: Beach) -> BeachSummary:
    activity_level = await get_activity_level(db, beach.id)
    status_r = await db.execute(select(BeachStatus).where(BeachStatus.beach_id == beach.id))
    status = status_r.scalar_one_or_none()
    now = datetime.now(timezone.utc)
    count_r = await db.execute(
        select(func.count(Report.id)).where(
            Report.beach_id == beach.id,
            Report.is_expired == False,
            Report.expires_at > now,
        )
    )
    cutoff = now - timedelta(minutes=20)
    occ_r = await db.execute(
        select(func.count(func.distinct(OccupancyHeartbeat.user_id))).where(
            OccupancyHeartbeat.beach_id == beach.id,
            OccupancyHeartbeat.created_at > cutoff,
        )
    )
    count = occ_r.scalar_one() or 0
    if beach.max_capacity:
        ratio = count / beach.max_capacity
        occ_level = "low" if ratio < 0.4 else "medium" if ratio < 0.75 else "high"
    else:
        occ_level = "low" if count < 10 else "medium" if count < 40 else "high"
    if count == 0 and not beach.has_capacity_data:
        occ_level = "unknown"

    return BeachSummary(
        id=beach.id,
        slug=beach.slug,
        name=beach.name,
        lat=beach.lat,
        lon=beach.lon,
        flag_color=status.flag_color if status else "unknown",
        flag_confidence=status.flag_confidence if status else 0.0,
        occupancy_level=occ_level,
        active_alerts_count=count_r.scalar_one() or 0,
        activity_level=activity_level,
        activity_label=get_params(activity_level)["label"],
    )


@router.get("", response_model=List[BeachSummary])
async def list_favourites(
    user: User = Depends(require_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(UserFavourite)
        .where(UserFavourite.user_id == user.id)
        .order_by(UserFavourite.position)
    )
    favs = result.scalars().all()
    summaries = []
    for fav in favs:
        beach_r = await db.execute(select(Beach).where(Beach.id == fav.beach_id))
        beach = beach_r.scalar_one_or_none()
        if beach:
            summaries.append(await _beach_summary(db, beach))
    return summaries


@router.post("/{beach_slug}", status_code=201)
async def add_favourite(
    beach_slug: str,
    user: User = Depends(require_user),
    db: AsyncSession = Depends(get_db),
):
    beach_r = await db.execute(select(Beach).where(Beach.slug == beach_slug))
    beach = beach_r.scalar_one_or_none()
    if not beach:
        raise HTTPException(404, "Praia não encontrada")

    existing = await db.execute(
        select(UserFavourite).where(
            UserFavourite.user_id == user.id,
            UserFavourite.beach_id == beach.id,
        )
    )
    if existing.scalar_one_or_none():
        raise HTTPException(409, "Praia já está nos favoritos")

    # Assign next position
    count_r = await db.execute(
        select(func.count(UserFavourite.id)).where(UserFavourite.user_id == user.id)
    )
    position = count_r.scalar_one() or 0

    db.add(UserFavourite(user_id=user.id, beach_id=beach.id, position=position))
    await db.commit()
    return {"status": "added", "beach_slug": beach_slug}


@router.delete("/{beach_slug}", status_code=204)
async def remove_favourite(
    beach_slug: str,
    user: User = Depends(require_user),
    db: AsyncSession = Depends(get_db),
):
    beach_r = await db.execute(select(Beach).where(Beach.slug == beach_slug))
    beach = beach_r.scalar_one_or_none()
    if not beach:
        raise HTTPException(404, "Praia não encontrada")

    result = await db.execute(
        delete(UserFavourite).where(
            UserFavourite.user_id == user.id,
            UserFavourite.beach_id == beach.id,
        )
    )
    if result.rowcount == 0:
        raise HTTPException(404, "Praia não está nos favoritos")
    await db.commit()


@router.patch("/order")
async def reorder_favourites(
    body: FavouriteOrderRequest,
    user: User = Depends(require_user),
    db: AsyncSession = Depends(get_db),
):
    for pos, slug in enumerate(body.ordered_slugs):
        beach_r = await db.execute(select(Beach).where(Beach.slug == slug))
        beach = beach_r.scalar_one_or_none()
        if not beach:
            continue
        await db.execute(
            update(UserFavourite)
            .where(UserFavourite.user_id == user.id, UserFavourite.beach_id == beach.id)
            .values(position=pos)
        )
    await db.commit()
    return {"status": "reordered"}

from datetime import datetime, timezone
from typing import List

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy import select, update, delete, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.beaches import _compute_occupancy
from app.core.database import get_db
from app.core.db_helpers import get_beach_flag_status, count_active_alerts
from app.core.deps import require_user
from app.models.beach import Beach
from app.models.user import User
from app.models.user_extended import UserFavourite
from app.schemas.beach import BeachSummary
from app.services.activity import get_activity_level, get_params

router = APIRouter(prefix="/users/me/favourites", tags=["favourites"])


class FavouriteOrderRequest(BaseModel):
    ordered_slugs: List[str]


async def _beach_summary(db: AsyncSession, beach: Beach) -> BeachSummary:
    activity_level = await get_activity_level(db, beach.id)
    flag_color, flag_confidence = await get_beach_flag_status(db, beach.id)
    now = datetime.now(timezone.utc)
    alerts_count = await count_active_alerts(db, beach.id, now)
    occupancy = await _compute_occupancy(db, beach)

    return BeachSummary(
        id=beach.id,
        slug=beach.slug,
        name=beach.name,
        lat=beach.lat,
        lon=beach.lon,
        cover_photo_url=beach.cover_photo_url,
        flag_color=flag_color,
        flag_confidence=flag_confidence,
        occupancy_level=occupancy.level,
        active_alerts_count=alerts_count,
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
    if result.rowcount == 0:  # type: ignore[attr-defined]
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

"""
Map endpoint — returns active user counts per beach, plus the names/avatars
of those who opted in to being listed.

Privacy rules (per user's privacy_settings):
  share_presence = False (default) → user not included in the visible list at all
                                       (still counted in user_count)
  name_public = False              → display_name replaced with "Anonymous"

No per-user coordinates are returned — the app only shows aggregate counts
and a "who's here" name list, never individual positions on a map.
"""
from datetime import timedelta
from typing import List, Optional

from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.constants import MAP_PRESENCE_WINDOW_MINUTES
from app.core.database import get_db
from app.core.deps import get_current_user
from app.core.utils import now_utc
from app.models.beach import Beach
from app.models.beach_status import OccupancyHeartbeat
from app.models.user import User
from app.models.user_extended import effective_privacy_settings

router = APIRouter(prefix="/map", tags=["map"])


class MapUser(BaseModel):
    display_name: Optional[str] = None   # None = "Anonymous"
    avatar_id: Optional[str] = None
    beach_id: int


class MapBeachPresence(BaseModel):
    beach_id: int
    beach_slug: str
    beach_name: str
    lat: float
    lon: float
    user_count: int
    users: List[MapUser]


@router.get("/users", response_model=List[MapBeachPresence])
async def get_map_users(
    db: AsyncSession = Depends(get_db),
    _caller: Optional[User] = Depends(get_current_user),
):
    """
    Returns active users (heartbeat in last 20 min) grouped by beach.
    Each user is listed by name/avatar only if their privacy settings allow it.
    """
    cutoff = now_utc() - timedelta(minutes=MAP_PRESENCE_WINDOW_MINUTES)

    # Load all beaches
    beaches_r = await db.execute(select(Beach))
    beaches = {b.id: b for b in beaches_r.scalars().all()}

    # Load recent heartbeats with user data
    hb_r = await db.execute(
        select(OccupancyHeartbeat)
        .where(OccupancyHeartbeat.created_at > cutoff)
        .order_by(OccupancyHeartbeat.beach_id, OccupancyHeartbeat.created_at.desc())
    )
    heartbeats = hb_r.scalars().all()

    # Deduplicate: one entry per user per beach (most recent)
    seen: set[tuple] = set()
    unique_hbs = []
    for hb in heartbeats:
        key = (hb.user_id, hb.beach_id)
        if key not in seen:
            seen.add(key)
            unique_hbs.append(hb)

    # Total count per beach — includes ALL users regardless of privacy settings
    total_count: dict[int, int] = {}
    for hb in unique_hbs:
        if hb.beach_id in beaches:
            total_count[hb.beach_id] = total_count.get(hb.beach_id, 0) + 1

    # Visible users per beach — filtered by individual privacy settings
    beach_map: dict[int, list[MapUser]] = {}
    for hb in unique_hbs:
        if hb.beach_id not in beaches:
            continue

        if hb.user_id:
            user_r = await db.execute(select(User).where(User.id == hb.user_id))
            user = user_r.scalar_one_or_none()
        else:
            user = None

        if user:
            priv = effective_privacy_settings(user)
            if not priv["share_presence"]:
                continue  # excluded from the visible list, but still counted above
            name = user.display_name if priv["name_public"] else None
            avatar = user.avatar_id if priv.get("avatar_public", True) else None
        else:
            # Anonymous heartbeat — always show, no name
            name = None
            avatar = None

        if hb.beach_id not in beach_map:
            beach_map[hb.beach_id] = []
        beach_map[hb.beach_id].append(MapUser(display_name=name, avatar_id=avatar, beach_id=hb.beach_id))

    # Include beaches that have active users even if all chose maximum privacy
    result = []
    for beach_id, count in total_count.items():
        beach = beaches[beach_id]
        result.append(MapBeachPresence(
            beach_id=beach_id,
            beach_slug=beach.slug,
            beach_name=beach.name,
            lat=beach.lat,
            lon=beach.lon,
            user_count=count,           # total including private users
            users=beach_map.get(beach_id, []),  # only those who opted in
        ))

    return result

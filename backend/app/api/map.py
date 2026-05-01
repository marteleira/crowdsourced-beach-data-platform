"""
Map endpoint — returns active users per beach for the map overlay.

Privacy rules (per user's privacy_settings):
  share_presence = False  → user not included at all
  location_accuracy = "none"      → not included
  location_accuracy = "approximate" → position jittered ±~300m
  location_accuracy = "exact"     → exact heartbeat position
  name_public = False             → display_name replaced with "Anonymous"
"""
import random
import math
from datetime import datetime, timedelta, timezone
from typing import List, Optional
from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from pydantic import BaseModel

from app.core.database import get_db
from app.core.deps import get_current_user
from app.models.beach import Beach
from app.models.beach_status import OccupancyHeartbeat
from app.models.user import User
from app.models.user_extended import DEFAULT_PRIVACY_SETTINGS

router = APIRouter(prefix="/map", tags=["map"])

PRESENCE_WINDOW_MINUTES = 20
JITTER_DEGREES = 0.003   # ~300m at Arrábida latitude


class MapUser(BaseModel):
    display_name: Optional[str] = None   # None = "Anonymous"
    lat: float
    lon: float
    beach_id: int


class MapBeachPresence(BaseModel):
    beach_id: int
    beach_slug: str
    beach_name: str
    lat: float
    lon: float
    user_count: int
    users: List[MapUser]


def _jitter(coord: float) -> float:
    return coord + random.uniform(-JITTER_DEGREES, JITTER_DEGREES)


def _privacy(user: User) -> dict:
    base = dict(DEFAULT_PRIVACY_SETTINGS)
    if user.privacy_settings:
        base.update(user.privacy_settings)
    return base


@router.get("/users", response_model=List[MapBeachPresence])
async def get_map_users(
    db: AsyncSession = Depends(get_db),
    _caller: Optional[User] = Depends(get_current_user),
):
    """
    Returns active users (heartbeat in last 20 min) grouped by beach.
    Each user is shown only if their privacy settings allow it.
    Position is jittered or omitted based on location_accuracy.
    """
    cutoff = datetime.now(timezone.utc) - timedelta(minutes=PRESENCE_WINDOW_MINUTES)

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

    # Group by beach
    beach_map: dict[int, list[MapUser]] = {}
    for hb in unique_hbs:
        if hb.beach_id not in beaches:
            continue

        # Load user privacy settings
        if hb.user_id:
            user_r = await db.execute(select(User).where(User.id == hb.user_id))
            user = user_r.scalar_one_or_none()
        else:
            user = None

        if user:
            priv = _privacy(user)
            if not priv["share_presence"] or priv["location_accuracy"] == "none":
                continue
            name = user.display_name if priv["name_public"] else None
            accuracy = priv["location_accuracy"]
        else:
            # Anonymous heartbeat — always show, no name
            name = None
            accuracy = "approximate"

        # Resolve position from geometry (stored as WKB; fall back to beach coords)
        beach = beaches[hb.beach_id]
        base_lat, base_lon = beach.lat, beach.lon

        if accuracy == "exact":
            lat, lon = base_lat, base_lon
        else:
            lat, lon = _jitter(base_lat), _jitter(base_lon)

        if hb.beach_id not in beach_map:
            beach_map[hb.beach_id] = []
        beach_map[hb.beach_id].append(MapUser(display_name=name, lat=lat, lon=lon, beach_id=hb.beach_id))

    result = []
    for beach_id, users in beach_map.items():
        beach = beaches[beach_id]
        result.append(MapBeachPresence(
            beach_id=beach_id,
            beach_slug=beach.slug,
            beach_name=beach.name,
            lat=beach.lat,
            lon=beach.lon,
            user_count=len(users),
            users=users,
        ))

    return result

from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.deps import require_user
from app.models.beach import Beach
from app.models.beach_status import OccupancyHeartbeat
from app.models.user import User
from app.schemas.user import HeartbeatRequest, HeartbeatResponse

router = APIRouter(prefix="/beaches/{slug}/occupancy", tags=["occupancy"])


async def _get_beach_or_404(slug: str, db: AsyncSession) -> Beach:
    result = await db.execute(select(Beach).where(Beach.slug == slug))
    beach = result.scalar_one_or_none()
    if not beach:
        raise HTTPException(404, f"Praia '{slug}' não encontrada")
    return beach


@router.post("/heartbeat", response_model=HeartbeatResponse)
async def send_heartbeat(
    slug: str,
    body: HeartbeatRequest,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(require_user),
):
    beach = await _get_beach_or_404(slug, db)

    geom = f"SRID=4326;POINT({body.lon} {body.lat})"
    heartbeat = OccupancyHeartbeat(
        beach_id=beach.id,
        user_id=user.id,
        geom=geom,
    )
    db.add(heartbeat)
    await db.commit()

    # Return current occupancy estimate
    cutoff = datetime.now(timezone.utc) - timedelta(minutes=20)
    result = await db.execute(
        select(func.count(func.distinct(OccupancyHeartbeat.user_id))).where(
            OccupancyHeartbeat.beach_id == beach.id,
            OccupancyHeartbeat.created_at > cutoff,
        )
    )
    count = result.scalar_one() or 0

    if beach.max_capacity:
        ratio = count / beach.max_capacity
        level = "low" if ratio < 0.4 else "medium" if ratio < 0.75 else "high"
    else:
        level = "low" if count < 10 else "medium" if count < 40 else "high"

    return HeartbeatResponse(
        status="ok",
        beach_id=beach.id,
        occupancy_level=level,
        user_count=count,
    )

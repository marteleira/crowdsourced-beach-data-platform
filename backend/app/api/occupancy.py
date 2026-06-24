from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends
from sqlalchemy import delete
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.beaches import _compute_occupancy
from app.core.constants import OCCUPANCY_WINDOW_MINUTES
from app.core.database import get_db
from app.core.deps import require_user, get_beach_or_404
from app.models.beach_status import OccupancyHeartbeat
from app.models.user import User
from app.schemas.user import HeartbeatRequest, HeartbeatResponse
from app.services.achievements import update_streak

router = APIRouter(prefix="/beaches/{slug}/occupancy", tags=["occupancy"])


@router.post("/heartbeat", response_model=HeartbeatResponse)
async def send_heartbeat(
    slug: str,
    body: HeartbeatRequest,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(require_user),
):
    beach = await get_beach_or_404(slug, db)

    # invalidate heartbeats from this user at other beaches
    cutoff = datetime.now(timezone.utc) - timedelta(minutes=OCCUPANCY_WINDOW_MINUTES)
    await db.execute(
        delete(OccupancyHeartbeat).where(
            OccupancyHeartbeat.user_id == user.id,
            OccupancyHeartbeat.beach_id != beach.id,
            OccupancyHeartbeat.created_at > cutoff,
        )
    )

    geom = f"SRID=4326;POINT({body.lon} {body.lat})"
    db.add(OccupancyHeartbeat(beach_id=beach.id, user_id=user.id, geom=geom))
    await db.commit()
    await update_streak(db, user)

    occupancy = await _compute_occupancy(db, beach)
    return HeartbeatResponse(
        status="ok",
        beach_id=beach.id,
        occupancy_level=occupancy.level,
        user_count=occupancy.user_count,
    )

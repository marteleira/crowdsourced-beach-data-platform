from datetime import timedelta

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import delete, select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.constants import (
    OCCUPANCY_WINDOW_MINUTES,
    OCCUPANCY_REPORT_RATE_LIMIT_MINUTES,
    REPORT_PRESENCE_WINDOW_HOURS,
)
from app.core.database import get_db
from app.core.db_helpers import compute_occupancy
from app.core.deps import require_user, get_beach_or_404, was_recently_present
from app.core.utils import now_utc
from app.models.beach_status import OccupancyHeartbeat, OccupancyReport
from app.models.user import User
from app.schemas.user import (
    HeartbeatRequest, HeartbeatResponse,
    OccupancyReportRequest, OccupancyReportResponse,
)
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

    cutoff = now_utc() - timedelta(minutes=OCCUPANCY_WINDOW_MINUTES)
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

    occupancy = await compute_occupancy(db, beach)
    return HeartbeatResponse(
        status="ok",
        beach_id=beach.id,
        occupancy_level=occupancy.level,
        user_count=occupancy.user_count,
    )


@router.post("/report", response_model=OccupancyReportResponse)
async def submit_occupancy_report(
    slug: str,
    body: OccupancyReportRequest,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(require_user),
):
    beach = await get_beach_or_404(slug, db)

    # Must have been at the beach recently (heartbeat within REPORT_PRESENCE_WINDOW_HOURS)
    present = await was_recently_present(
        db, user.id, beach.id,
        window=timedelta(hours=REPORT_PRESENCE_WINDOW_HOURS),
    )
    if not present:
        raise HTTPException(
            status_code=403,
            detail={"code": "not_present", "message": "Deves estar (ou ter estado) na praia para reportar a ocupação."},
        )

    # Rate limit: one report per user per beach per window
    rate_cutoff = now_utc() - timedelta(minutes=OCCUPANCY_REPORT_RATE_LIMIT_MINUTES)
    existing = await db.scalar(
        select(func.count(OccupancyReport.id)).where(
            OccupancyReport.user_id == user.id,
            OccupancyReport.beach_id == beach.id,
            OccupancyReport.created_at > rate_cutoff,
        )
    )
    if existing:
        raise HTTPException(
            status_code=429,
            detail={"code": "already_reported", "message": "Já reportaste a ocupação desta praia recentemente."},
        )

    db.add(OccupancyReport(beach_id=beach.id, user_id=user.id, level=body.level))
    await db.commit()

    occupancy = await compute_occupancy(db, beach)
    return OccupancyReportResponse(
        status="ok",
        occupancy_level=occupancy.level,
        report_count=occupancy.report_count,
        report_confidence=occupancy.report_confidence,
    )

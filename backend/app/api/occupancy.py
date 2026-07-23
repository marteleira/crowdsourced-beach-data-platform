from datetime import timedelta

from fastapi import APIRouter, Depends
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.constants import (
    OCCUPANCY_REPORT_RATE_LIMIT_MINUTES,
    REPORT_PRESENCE_WINDOW_HOURS,
)
from app.core.database import get_db
from app.core.db_helpers import (
    compute_occupancy,
    point_within_beach_radius,
    find_nearest_beach,
    record_heartbeat_and_get_occupancy,
)
from app.core.deps import require_registered_user, get_beach_or_404, require_presence
from app.core.errors import api_error
from app.core.utils import now_utc
from app.models.beach import Beach
from app.models.beach_status import OccupancyReport
from app.models.user import User
from app.schemas.user import (
    HeartbeatRequest, HeartbeatResponse, HeartbeatByLocationResponse,
    OccupancyReportRequest, OccupancyReportResponse,
)

router = APIRouter(prefix="/beaches/{slug}/occupancy", tags=["occupancy"])
location_router = APIRouter(prefix="/occupancy", tags=["occupancy"])


@router.post("/heartbeat", response_model=HeartbeatResponse)
async def send_heartbeat(
    slug: str,
    body: HeartbeatRequest,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(require_registered_user),
):
    beach = await get_beach_or_404(slug, db, user.language)

    if not await point_within_beach_radius(db, beach, body.lat, body.lon):
        raise api_error(403, "too_far_from_beach", user.language)

    occupancy = await record_heartbeat_and_get_occupancy(db, beach, user, body.lat, body.lon)
    return HeartbeatResponse(
        status="ok",
        beach_id=beach.id,
        occupancy_level=occupancy.level,
        user_count=occupancy.user_count,
    )


@location_router.post("/heartbeat", response_model=HeartbeatByLocationResponse)
async def send_heartbeat_by_location(
    body: HeartbeatRequest,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(require_registered_user),
):
    match = await find_nearest_beach(db, body.lat, body.lon)
    if match is None:
        return HeartbeatByLocationResponse(status="no_beach_nearby")

    beach, _distance_m = match
    occupancy = await record_heartbeat_and_get_occupancy(db, beach, user, body.lat, body.lon)
    return HeartbeatByLocationResponse(
        status="ok",
        beach_id=beach.id,
        beach_slug=beach.slug,
        occupancy_level=occupancy.level,
        user_count=occupancy.user_count,
    )


@router.post("/report", response_model=OccupancyReportResponse)
async def submit_occupancy_report(
    slug: str,
    body: OccupancyReportRequest,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(require_registered_user),
    beach: Beach = Depends(
        require_presence(
            timedelta(hours=REPORT_PRESENCE_WINDOW_HOURS),
            "occupancy_must_be_at_beach",
        )
    ),
):
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
        raise api_error(429, "occupancy_already_reported", user.language)

    db.add(OccupancyReport(beach_id=beach.id, user_id=user.id, level=body.level))
    await db.commit()

    occupancy = await compute_occupancy(db, beach)
    return OccupancyReportResponse(
        status="ok",
        occupancy_level=occupancy.level,
        report_count=occupancy.report_count,
        report_confidence=occupancy.report_confidence,
    )

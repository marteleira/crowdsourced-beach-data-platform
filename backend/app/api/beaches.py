import asyncio
from datetime import datetime, timedelta, timezone
from typing import List, Optional

from fastapi import APIRouter, Depends, Query
from sqlalchemy import select, func, literal
from sqlalchemy.ext.asyncio import AsyncSession
from geoalchemy2.functions import ST_Distance, ST_GeogFromText

from app.api.transport import _group_by_direction
from app.core.database import get_db
from app.core.deps import get_beach_or_404, get_current_user
from app.models.beach import Beach
from app.models.beach_status import BeachStatus, OccupancyHeartbeat
from app.models.report import Report
from app.models.user import User
from app.schemas.beach import BeachSummary, BeachFullResponse, BeachStatusResponse, OccupancyData
from app.services.activity import get_activity_level, get_params
from app.services.snapshot import fetch_with_fallback
from app.services import ipma, hidrografico, eea, carris, open_meteo
from app.api.weather import _open_meteo_overrides

router = APIRouter(prefix="/beaches", tags=["beaches"])

FLAG_SCORE     = {"green": 1.0, "yellow": 0.6, "unknown": 0.4, "red": 0.1, "purple": 0.1}
OCCUPANCY_SCORE = {"low": 1.0, "medium": 0.6, "high": 0.2, "unknown": 0.5}


def _recommendation_score(distance_km: float, flag_color: str,
                           occupancy_level: str, alerts_count: int) -> float:
    proximity     = max(0.0, 1.0 - distance_km / 50.0)
    flag          = FLAG_SCORE.get(flag_color, 0.4)
    occupancy     = OCCUPANCY_SCORE.get(occupancy_level, 0.5)
    alert_penalty = min(1.0, alerts_count / 5.0)
    return (
        0.40 * proximity
        + 0.30 * flag
        + 0.20 * occupancy
        + 0.10 * (1.0 - alert_penalty)
    )


async def _compute_occupancy(db: AsyncSession, beach: Beach) -> OccupancyData:
    cutoff = datetime.now(timezone.utc) - timedelta(minutes=20)
    stmt = (
        select(func.count(func.distinct(OccupancyHeartbeat.user_id)))
        .where(
            OccupancyHeartbeat.beach_id == beach.id,
            OccupancyHeartbeat.created_at > cutoff,
        )
    )
    result = await db.execute(stmt)
    count = result.scalar_one() or 0

    if beach.max_capacity:
        ratio = count / beach.max_capacity
        level = "low" if ratio < 0.4 else "medium" if ratio < 0.75 else "high"
    else:
        level = "low" if count < 10 else "medium" if count < 40 else "high"

    if count == 0 and not beach.has_capacity_data:
        level = "unknown"

    return OccupancyData(
        level=level,
        user_count=count,
        is_estimate=True,
        last_updated=datetime.now(timezone.utc),
    )


async def _get_active_alerts(db: AsyncSession, beach_id: int, activity_level: str):
    now = datetime.now(timezone.utc)
    stmt = (
        select(Report)
        .where(
            Report.beach_id == beach_id,
            Report.is_expired == False,
            Report.expires_at > now,
        )
        .order_by(Report.created_at.desc())
    )
    result = await db.execute(stmt)
    reports = result.scalars().all()

    label = get_params(activity_level)["label"]
    alerts = []
    for r in reports:
        alerts.append({
            "id": r.id,
            "type": r.type,
            "severity": r.severity,
            "upvotes": r.upvotes,
            "downvotes": r.downvotes,
            "created_at": r.created_at,
            "expires_at": r.expires_at,
            "note": r.note,
            "verified": (r.upvotes - r.downvotes) >= 3,
            "activity_label": label,
        })
    return alerts


@router.get("", response_model=List[BeachSummary])
async def list_beaches(
    lat: Optional[float] = Query(None, description="User latitude for proximity ranking"),
    lon: Optional[float] = Query(None, description="User longitude for proximity ranking"),
    db: AsyncSession = Depends(get_db),
):
    # When coordinates are provided, PostGIS calculates the distance in the same
    # query and orders by it — no Python-side math, no N+1 for distance.
    if lat is not None and lon is not None:
        user_point = f"SRID=4326;POINT({lon} {lat})"
        dist_col = (
            ST_Distance(Beach.geom, ST_GeogFromText(user_point)) / 1000.0
        ).label("distance_km")
        stmt = (
            select(Beach, dist_col)
            .order_by(dist_col)
        )
    else:
        stmt = select(Beach, literal(None).label("distance_km")).order_by(Beach.name)

    rows = (await db.execute(stmt)).all()

    summaries = []
    now = datetime.now(timezone.utc)

    for row in rows:
        beach: Beach = row[0]
        distance_km: Optional[float] = row[1]

        activity_level = await get_activity_level(db, beach.id)

        status_result = await db.execute(
            select(BeachStatus).where(BeachStatus.beach_id == beach.id)
        )
        status = status_result.scalar_one_or_none()
        flag_color      = status.flag_color      if status else "unknown"
        flag_confidence = status.flag_confidence if status else 0.0

        alerts_count = (await db.execute(
            select(func.count(Report.id)).where(
                Report.beach_id == beach.id,
                Report.is_expired == False,
                Report.expires_at > now,
            )
        )).scalar_one() or 0

        occupancy = await _compute_occupancy(db, beach)
        params    = get_params(activity_level)

        score = (
            _recommendation_score(distance_km, flag_color, occupancy.level, alerts_count)
            if distance_km is not None
            else None
        )

        summaries.append(BeachSummary(
            id=beach.id,
            slug=beach.slug,
            name=beach.name,
            lat=beach.lat,
            lon=beach.lon,
            flag_color=flag_color,
            flag_confidence=flag_confidence,
            occupancy_level=occupancy.level,
            active_alerts_count=alerts_count,
            activity_level=activity_level,
            activity_label=params["label"],
            distance_km=round(distance_km, 1) if distance_km is not None else None,
            recommendation_score=round(score, 3) if score is not None else None,
            cover_photo_url=beach.cover_photo_url,
            municipality=beach.municipality,
        ))

    if lat is not None and lon is not None:
        summaries.sort(key=lambda s: s.recommendation_score or 0, reverse=True)

    return summaries


@router.get("/{slug}", response_model=BeachFullResponse)
async def get_beach(
    slug: str,
    db: AsyncSession = Depends(get_db),
    _user: Optional[User] = Depends(get_current_user),
):
    beach = await get_beach_or_404(slug, db)
    activity_level = await get_activity_level(db, beach.id)
    params = get_params(activity_level)

    # Status
    status_result = await db.execute(select(BeachStatus).where(BeachStatus.beach_id == beach.id))
    status = status_result.scalar_one_or_none()
    flag_color = status.flag_color if status else "unknown"
    flag_confidence = status.flag_confidence if status else 0.0

    occupancy = await _compute_occupancy(db, beach)
    alerts = await _get_active_alerts(db, beach.id, activity_level)

    # External data — weather
    weather = sea = tides = water_quality = transport = None

    if beach.ipma_global_id:
        try:
            ipma_result, om_result = await asyncio.gather(
                fetch_with_fallback(
                    db, "ipma_weather",
                    lambda: ipma.fetch_weather_forecast(beach.ipma_global_id),
                    beach_id=beach.id,
                ),
                open_meteo.fetch_weather(beach.lat, beach.lon),
                return_exceptions=True,
            )
            if isinstance(ipma_result, BaseException):
                raise ipma_result
            raw, source, snap_at = ipma_result
            today_overrides = _open_meteo_overrides(
                om_result if not isinstance(om_result, BaseException) else None
            )
            weather = []
            for i, f in enumerate(raw.get("forecasts", [])):
                extra = today_overrides if i == 0 else {}
                weather.append({**f, **extra, "data_source": source, "snapshot_at": snap_at})
        except Exception:
            pass

    if beach.ipma_sea_global_id:
        try:
            raw, source, snap_at = await fetch_with_fallback(
                db, "ipma_sea",
                lambda: ipma.fetch_sea_forecast(beach.ipma_sea_global_id),
                beach_id=beach.id,
            )
            sea = [
                {**f, "data_source": source, "snapshot_at": snap_at}
                for f in raw.get("forecasts", [])
            ]
        except Exception:
            pass

    if beach.tide_station_id:
        try:
            raw, source, snap_at = await fetch_with_fallback(
                db, "tides",
                lambda: hidrografico.fetch_tides_for_station(beach.tide_station_id),
                beach_id=beach.id,
            )
            tides = {**raw, "data_source": source, "snapshot_at": snap_at}
        except Exception:
            pass

    if beach.eea_station_id:
        try:
            raw, source, snap_at = await fetch_with_fallback(
                db, "water_quality",
                lambda: eea.fetch_water_quality(beach.eea_station_id),
                beach_id=beach.id,
            )
            water_quality = {**raw, "data_source": source, "snapshot_at": snap_at}
        except Exception:
            pass

    if beach.nearby_stop_ids:
        try:
            raw, source, snap_at = await fetch_with_fallback(
                db, "carris_stops",
                lambda: carris.fetch_multiple_stops_departures(beach.nearby_stop_ids),
                beach_id=beach.id,
            )
            stops_info = []
            for sid in beach.nearby_stop_ids:
                info = await carris.fetch_stop(sid)
                if info:
                    stops_info.append(info)
            trips = raw if isinstance(raw, list) else []
            transport = {
                "stops": stops_info,
                "directions": [d.model_dump() for d in _group_by_direction(trips)],
                "data_source": source,
                "snapshot_at": snap_at,
            }
        except Exception:
            pass

    beach_detail = {
        "id": beach.id,
        "slug": beach.slug,
        "name": beach.name,
        "lat": beach.lat,
        "lon": beach.lon,
        "has_capacity_data": beach.has_capacity_data,
        "max_capacity": beach.max_capacity,
        "flags_available": beach.flags_available,
        "nearby_stop_ids": beach.nearby_stop_ids or [],
        "cover_photo_url": beach.cover_photo_url,
        "municipality": beach.municipality,
    }

    return BeachFullResponse(
        beach=beach_detail,
        status=BeachStatusResponse(
            flag_color=flag_color,
            flag_confidence=flag_confidence,
            activity_level=activity_level,
            activity_label=params["label"],
            occupancy=occupancy,
        ),
        active_alerts=alerts,
        weather=weather,
        sea=sea,
        tides=tides,
        water_quality=water_quality,
        transport=transport,
    )

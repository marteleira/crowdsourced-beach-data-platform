from collections import defaultdict

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.models.beach import Beach
from app.schemas.beach import TransportResponse, TransportDirection, TransportTrip
from app.services.snapshot import fetch_with_fallback
from app.services import carris

router = APIRouter(prefix="/beaches/{slug}", tags=["transport"])


async def _get_beach_or_404(slug: str, db: AsyncSession) -> Beach:
    result = await db.execute(select(Beach).where(Beach.slug == slug))
    beach = result.scalar_one_or_none()
    if not beach:
        raise HTTPException(404, f"Praia '{slug}' não encontrada")
    return beach


def _group_by_direction(trips: list) -> list[TransportDirection]:
    """Group a flat list of trips by headsign (destination), sorted by departure time."""
    by_headsign: dict[str, list] = defaultdict(list)
    for t in trips:
        headsign = t.get("trip_headsign") or t.get("route_short_name") or "?"
        by_headsign[headsign].append(TransportTrip(
            route_id=t.get("route_id", ""),
            route_short_name=t.get("route_short_name", ""),
            trip_headsign=headsign,
            stop_id=t.get("stop_id", ""),
            departure_time=t.get("departure_time", ""),
            is_realtime=t.get("is_realtime", False),
        ))
    return [
        TransportDirection(headsign=headsign, departures=sorted(deps, key=lambda d: d.departure_time))
        for headsign, deps in sorted(by_headsign.items())
    ]


@router.get("/transport", response_model=TransportResponse)
async def get_transport(slug: str, db: AsyncSession = Depends(get_db)):
    beach = await _get_beach_or_404(slug, db)
    if not beach.nearby_stop_ids:
        raise HTTPException(404, "Sem paragens de autocarro para esta praia")

    departures_raw, source, snap_at = await fetch_with_fallback(
        db, "carris_stops",
        lambda: carris.fetch_multiple_stops_departures(beach.nearby_stop_ids),
        beach_id=beach.id,
    )

    stops_info = []
    for sid in beach.nearby_stop_ids:
        info = await carris.fetch_stop(sid)
        if info:
            stops_info.append(info)

    trips = departures_raw if isinstance(departures_raw, list) else []

    return TransportResponse(
        stops=stops_info,
        directions=_group_by_direction(trips),
        data_source=source,
        snapshot_at=snap_at,
    )

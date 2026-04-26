from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.models.beach import Beach
from app.schemas.beach import TransportResponse
from app.services.snapshot import fetch_with_fallback
from app.services import carris

router = APIRouter(prefix="/beaches/{slug}", tags=["transport"])


async def _get_beach_or_404(slug: str, db: AsyncSession) -> Beach:
    result = await db.execute(select(Beach).where(Beach.slug == slug))
    beach = result.scalar_one_or_none()
    if not beach:
        raise HTTPException(404, f"Praia '{slug}' não encontrada")
    return beach


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

    return TransportResponse(
        stops=stops_info,
        next_departures=departures_raw if isinstance(departures_raw, list) else [],
        data_source=source,
        snapshot_at=snap_at,
    )

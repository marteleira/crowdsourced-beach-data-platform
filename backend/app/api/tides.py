from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.models.beach import Beach
from app.schemas.beach import TidesResponse
from app.services.snapshot import fetch_with_fallback
from app.services import hidrografico

router = APIRouter(prefix="/beaches/{slug}", tags=["tides"])


async def _get_beach_or_404(slug: str, db: AsyncSession) -> Beach:
    result = await db.execute(select(Beach).where(Beach.slug == slug))
    beach = result.scalar_one_or_none()
    if not beach:
        raise HTTPException(404, f"Praia '{slug}' não encontrada")
    return beach


@router.get("/tides", response_model=TidesResponse)
async def get_tides(slug: str, db: AsyncSession = Depends(get_db)):
    beach = await _get_beach_or_404(slug, db)
    if not beach.tide_station_id:
        raise HTTPException(404, "Sem dados de marés para esta praia")

    raw, source, snap_at = await fetch_with_fallback(
        db, "tides",
        lambda: hidrografico.fetch_tides_for_station(beach.tide_station_id),
        beach_id=beach.id,
    )
    return TidesResponse(**raw, data_source=source, snapshot_at=snap_at)

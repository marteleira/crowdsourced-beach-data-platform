from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.models.beach import Beach
from app.schemas.beach import WaterQualityResponse
from app.services.snapshot import fetch_with_fallback
from app.services import apa

router = APIRouter(prefix="/beaches/{slug}", tags=["water-quality"])


async def _get_beach_or_404(slug: str, db: AsyncSession) -> Beach:
    result = await db.execute(select(Beach).where(Beach.slug == slug))
    beach = result.scalar_one_or_none()
    if not beach:
        raise HTTPException(404, f"Praia '{slug}' não encontrada")
    return beach


@router.get("/water-quality", response_model=WaterQualityResponse)
async def get_water_quality(slug: str, db: AsyncSession = Depends(get_db)):
    beach = await _get_beach_or_404(slug, db)
    if not beach.apa_station_id:
        raise HTTPException(404, "Sem dados de qualidade da água para esta praia")

    raw, source, snap_at = await fetch_with_fallback(
        db, "water_quality",
        lambda: apa.fetch_water_quality(beach.apa_station_id),
        beach_id=beach.id,
    )
    return WaterQualityResponse(**raw, data_source=source, snapshot_at=snap_at)

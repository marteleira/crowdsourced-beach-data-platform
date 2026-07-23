from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.deps import get_beach_or_404, get_language
from app.core.errors import api_error
from app.schemas.beach import WaterQualityResponse
from app.services.snapshot import fetch_with_fallback
from app.services import eea

router = APIRouter(prefix="/beaches/{slug}", tags=["water-quality"])


@router.get("/water-quality", response_model=WaterQualityResponse)
async def get_water_quality(slug: str, db: AsyncSession = Depends(get_db), lang: str = Depends(get_language)):
    beach = await get_beach_or_404(slug, db, lang)
    if not beach.eea_station_id:
        raise api_error(404, "no_water_quality_data", lang)

    try:
        raw, source, snap_at = await fetch_with_fallback(
            db, "water_quality",
            lambda: eea.fetch_water_quality(beach.eea_station_id),
            beach_id=beach.id,
        )
        return WaterQualityResponse(**raw, data_source=source, snapshot_at=snap_at)
    except HTTPException:
        # API unavailable and no cached snapshot — return unknown instead of 503
        return WaterQualityResponse(
            station_id=beach.eea_station_id,
            quality_code=None,
            sampled_at=None,
            parameters=None,
            data_source="unavailable",
            snapshot_at=None,
        )

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.deps import get_beach_or_404, get_language
from app.core.errors import api_error
from app.schemas.beach import TidesResponse
from app.services.snapshot import fetch_with_fallback
from app.services import hidrografico

router = APIRouter(prefix="/beaches/{slug}", tags=["tides"])


@router.get("/tides", response_model=TidesResponse)
async def get_tides(slug: str, db: AsyncSession = Depends(get_db), lang: str = Depends(get_language)):
    beach = await get_beach_or_404(slug, db, lang)
    if not beach.tide_station_id:
        raise api_error(404, "no_tide_data", lang)

    raw, source, snap_at = await fetch_with_fallback(
        db, "tides",
        lambda: hidrografico.fetch_current_tide(beach.tide_station_id),
        beach_id=beach.id,
    )
    return TidesResponse(**raw, data_source=source, snapshot_at=snap_at)

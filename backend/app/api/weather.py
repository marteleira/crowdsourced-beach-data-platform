from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List

from app.core.database import get_db
from app.models.beach import Beach
from app.schemas.beach import WeatherForecast, SeaForecast
from app.services.snapshot import fetch_with_fallback
from app.services import ipma

router = APIRouter(prefix="/beaches/{slug}", tags=["weather"])


async def _get_beach_or_404(slug: str, db: AsyncSession) -> Beach:
    result = await db.execute(select(Beach).where(Beach.slug == slug))
    beach = result.scalar_one_or_none()
    if not beach:
        raise HTTPException(404, f"Praia '{slug}' não encontrada")
    return beach


@router.get("/weather", response_model=List[WeatherForecast])
async def get_weather(slug: str, db: AsyncSession = Depends(get_db)):
    beach = await _get_beach_or_404(slug, db)
    if not beach.ipma_global_id:
        raise HTTPException(404, "Sem dados meteorológicos para esta praia")

    raw, source, snap_at = await fetch_with_fallback(
        db, "ipma_weather",
        lambda: ipma.fetch_weather_forecast(beach.ipma_global_id),
        beach_id=beach.id,
    )
    return [
        WeatherForecast(**f, data_source=source, snapshot_at=snap_at)
        for f in raw.get("forecasts", [])
    ]


@router.get("/sea", response_model=List[SeaForecast])
async def get_sea(slug: str, db: AsyncSession = Depends(get_db)):
    beach = await _get_beach_or_404(slug, db)
    if not beach.ipma_sea_global_id:
        raise HTTPException(404, "Sem dados do estado do mar para esta praia")

    raw, source, snap_at = await fetch_with_fallback(
        db, "ipma_sea",
        lambda: ipma.fetch_sea_forecast(beach.ipma_sea_global_id),
        beach_id=beach.id,
    )
    return [
        SeaForecast(**f, data_source=source, snapshot_at=snap_at)
        for f in raw.get("forecasts", [])
    ]

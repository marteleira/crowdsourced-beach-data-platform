import asyncio
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List, Optional

from app.core.database import get_db
from app.core.deps import get_beach_or_404, get_language
from app.core.errors import api_error
from app.schemas.beach import WeatherForecast, SeaForecast
from app.services.snapshot import fetch_with_fallback
from app.services import ipma
from app.services import open_meteo

router = APIRouter(prefix="/beaches/{slug}", tags=["weather"])


def _open_meteo_overrides(om: Optional[dict]) -> dict:
    """
    Extract fields from Open-Meteo result to overlay onto today IPMA forecast
    Open-Meteo is more accurate for current conditions and actual wind values
    """
    if not isinstance(om, dict):
        return {}
    current = om.get("current", {})
    daily = om.get("daily", {})
    overrides: dict = {}
    if (v := current.get("temperature_2m")) is not None:
        overrides["current_temp"] = v
    if (v := current.get("apparent_temperature")) is not None:
        overrides["apparent_temp"] = v
    if (v := current.get("relative_humidity_2m")) is not None:
        overrides["humidity"] = float(v)
    if (v := current.get("uv_index")) is not None:
        overrides["uv_index"] = v
    if (v := current.get("wind_speed_10m")) is not None:
        overrides["wind_speed"] = v
    if (v := current.get("wind_direction_cardinal")) is not None:
        overrides["wind_direction_code"] = v
    if (v := current.get("wind_direction_10m")) is not None:
        overrides["wind_direction_deg"] = float(v)
    if (v := current.get("wind_gusts_10m")) is not None:
        overrides["wind_gusts"] = v
    if (v := current.get("weather_code_wmo")) is not None:
        overrides["weather_code_wmo"] = v
    if (v := daily.get("temperature_2m_max")) is not None:
        overrides["max_temp"] = v
    if (v := daily.get("temperature_2m_min")) is not None:
        overrides["min_temp"] = v
    if (v := daily.get("precipitation_probability_max")) is not None:
        overrides["precipitation_prob"] = float(v)
    return overrides


@router.get("/weather", response_model=List[WeatherForecast])
async def get_weather(slug: str, db: AsyncSession = Depends(get_db), lang: str = Depends(get_language)):
    beach = await get_beach_or_404(slug, db, lang)
    if not beach.ipma_global_id:
        raise api_error(404, "no_weather_data", lang)

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

    today_overrides = _open_meteo_overrides(om_result if not isinstance(om_result, BaseException) else None)

    result = []
    for i, f in enumerate(raw.get("forecasts", [])):
        extra = today_overrides if i == 0 else {}
        merged = {**f, "data_source": source, "snapshot_at": snap_at, **extra}
        result.append(WeatherForecast(**merged))
    return result


@router.get("/sea", response_model=List[SeaForecast])
async def get_sea(slug: str, db: AsyncSession = Depends(get_db), lang: str = Depends(get_language)):
    beach = await get_beach_or_404(slug, db, lang)
    if not beach.ipma_sea_global_id:
        raise api_error(404, "no_sea_data", lang)

    raw, source, snap_at = await fetch_with_fallback(
        db, "ipma_sea",
        lambda: ipma.fetch_sea_forecast(beach.ipma_sea_global_id),
        beach_id=beach.id,
    )
    return [
        SeaForecast(**f, data_source=source, snapshot_at=snap_at)
        for f in raw.get("forecasts", [])
    ]

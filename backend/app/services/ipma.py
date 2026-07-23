"""
IPMA API client — https://api.ipma.pt/
Weather forecast and sea state data.
No authentication required. Updates ~2x/day.

The API serves global forecast files per day index (0=today, 1=tomorrow…).
Each file contains all locations; we filter by globalIdLocal.
"""
import logging
import httpx
from typing import Optional

logger = logging.getLogger(__name__)

IPMA_BASE = "https://api.ipma.pt/open-data"

# IPMA already reports wind direction as the canonical 8-point English code
# (N/NE/E/SE/S/SW/W/NW), so it passes through unchanged as wind_direction_code.
# weather_type_id (IPMA's own 1-29 code) is returned as-is; the client resolves
# display text from it via its own l10n, same as weather_code_wmo (Open-Meteo).


async def fetch_weather_forecast(global_id_local: int) -> Optional[dict]:
    """
    Fetch 5-day weather forecast for a location by filtering the global daily files.
    """
    days = []
    async with httpx.AsyncClient(timeout=10.0) as client:
        for day_idx in range(5):
            url = f"{IPMA_BASE}/forecast/meteorology/cities/daily/hp-daily-forecast-day{day_idx}.json"
            try:
                resp = await client.get(url)
                resp.raise_for_status()
                data = resp.json()
                for item in data.get("data", []):
                    if item.get("globalIdLocal") == global_id_local:
                        days.append({
                            "date": data.get("forecastDate", ""),
                            "min_temp": _num(item.get("tMin")),
                            "max_temp": _num(item.get("tMax")),
                            "precipitation_prob": _num(item.get("precipitaProb")),
                            "wind_speed": _num(item.get("classWindSpeed")),
                            "wind_direction_code": item.get("predWindDir") or None,
                            "weather_type_id": item.get("idWeatherType"),
                        })
                        break
            except Exception as e:
                logger.warning("IPMA weather fetch failed for day %d (global_id_local=%d): %s",
                               day_idx, global_id_local, e)
                continue

    if not days:
        return None
    return {"forecasts": days, "global_id_local": global_id_local}


async def fetch_sea_forecast(global_id_local: int) -> Optional[dict]:
    """
    Fetch sea/ocean forecast for a location by filtering the global daily sea files.
    """
    days = []
    async with httpx.AsyncClient(timeout=10.0) as client:
        for day_idx in range(4):
            url = f"{IPMA_BASE}/forecast/oceanography/daily/hp-daily-sea-forecast-day{day_idx}.json"
            try:
                resp = await client.get(url)
                resp.raise_for_status()
                data = resp.json()
                for item in data.get("data", []):
                    if item.get("globalIdLocal") == global_id_local:
                        days.append({
                            "date": data.get("forecastDate", ""),
                            "wave_height_max": _num(item.get("waveHighMax")),
                            "wave_height_min": _num(item.get("waveHighMin")),
                            "wave_period_max": _num(item.get("wavePeriodMax")),
                            "sea_surface_temp": _num(item.get("sstMax")),
                        })
                        break
            except Exception as e:
                logger.warning("IPMA sea fetch failed for day %d (global_id_local=%d): %s",
                               day_idx, global_id_local, e)
                continue

    if not days:
        return None
    return {"forecasts": days, "global_id_local": global_id_local}


async def fetch_warnings() -> Optional[list]:
    """Fetch active IPMA weather warnings (national)."""
    url = f"{IPMA_BASE}/forecast/warnings/warnings_www.json"
    async with httpx.AsyncClient(timeout=8.0) as client:
        resp = await client.get(url)
        resp.raise_for_status()
        return resp.json()


def _num(v) -> Optional[float]:
    """Safely convert IPMA string/number values to float."""
    if v is None:
        return None
    try:
        return float(v)
    except (ValueError, TypeError):
        return None

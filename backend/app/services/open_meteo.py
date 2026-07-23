"""
Open-Meteo API client - https://open-meteo.com
Current weather + today daily forecast by lat/lon
Free, no auth required and updates every 15 min (current) / hourly (forecast)
"""
import httpx
from typing import Optional

OPEN_METEO_BASE = "https://api.open-meteo.com/v1/forecast"

# Canonical 8-point English code space - matches the codes IPMA already uses
# for predWindDir, so wind_direction_code is consistent regardless of provider.
_CARDINALS = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]


def degrees_to_cardinal(deg: float) -> str:
    idx = round(deg / 45) % 8
    return _CARDINALS[idx]


async def fetch_weather(lat: float, lon: float) -> Optional[dict]:
    """
    Returns a dict with 'current' and 'daily' (today only) sub-dicts, or None on failure

    current keys: temperature_2m, apparent_temperature, relative_humidity_2m,
                  wind_speed_10m, wind_direction_10m, wind_direction_cardinal,
                  wind_gusts_10m, uv_index, weather_code

    daily keys: temperature_2m_max, temperature_2m_min, precipitation_probability_max
    """
    params = {
        "latitude": lat,
        "longitude": lon,
        "current": (
            "temperature_2m,apparent_temperature,relative_humidity_2m,"
            "wind_speed_10m,wind_direction_10m,wind_gusts_10m,"
            "uv_index,weather_code"
        ),
        "daily": "temperature_2m_max,temperature_2m_min,precipitation_probability_max",
        "forecast_days": 1,
        "timezone": "auto",
        "wind_speed_unit": "kmh",
    }
    async with httpx.AsyncClient(timeout=8) as client:
        resp = await client.get(OPEN_METEO_BASE, params=params)  # type: ignore[arg-type]
        resp.raise_for_status()
        data = resp.json()

    current = data.get("current", {})
    daily = data.get("daily", {})

    wind_deg = current.get("wind_direction_10m")
    current["wind_direction_cardinal"] = degrees_to_cardinal(wind_deg) if wind_deg is not None else None

    current["weather_code_wmo"] = current.get("weather_code")

    today_daily = {
        "temperature_2m_max": (daily.get("temperature_2m_max") or [None])[0],
        "temperature_2m_min": (daily.get("temperature_2m_min") or [None])[0],
        "precipitation_probability_max": (daily.get("precipitation_probability_max") or [None])[0],
    }

    return {"current": current, "daily": today_daily}

"""
Open-Meteo API client - https://open-meteo.com
Current weather + today daily forecast by lat/lon
Free, no auth required and updates every 15 min (current) / hourly (forecast)
"""
import httpx
from typing import Optional

OPEN_METEO_BASE = "https://api.open-meteo.com/v1/forecast"

_CARDINALS = ["N", "NE", "E", "SE", "S", "SO", "O", "NO"]

_WMO_PT = {
    0: "Céu limpo",
    1: "Poucas nuvens", 2: "Parcialmente nublado", 3: "Céu nublado",
    45: "Nevoeiro", 48: "Nevoeiro gelado",
    51: "Chuviscos fracos", 53: "Chuviscos moderados", 55: "Chuviscos fortes",
    61: "Chuva fraca", 63: "Chuva moderada", 65: "Chuva forte",
    71: "Neve fraca", 73: "Neve moderada", 75: "Neve forte",
    77: "Grãos de neve",
    80: "Aguaceiros fracos", 81: "Aguaceiros moderados", 82: "Aguaceiros fortes",
    85: "Aguaceiros de neve fracos", 86: "Aguaceiros de neve fortes",
    95: "Trovoada", 96: "Trovoada com granizo", 99: "Trovoada com granizo forte",
}


def degrees_to_cardinal(deg: float) -> str:
    idx = round(deg / 45) % 8
    return _CARDINALS[idx]


def wmo_to_desc(code: int) -> str:
    return _WMO_PT.get(code, f"Código {code}")


async def fetch_weather(lat: float, lon: float) -> Optional[dict]:
    """
    Returns a dict with 'current' and 'daily' (today only) sub-dicts, or None on failure

    current keys: temperature_2m, apparent_temperature, relative_humidity_2m,
                  wind_speed_10m, wind_direction_10m, wind_direction_cardinal,
                  wind_gusts_10m, uv_index, weather_code, weather_desc

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
        resp = await client.get(OPEN_METEO_BASE, params=params)
        resp.raise_for_status()
        data = resp.json()

    current = data.get("current", {})
    daily = data.get("daily", {})

    wind_deg = current.get("wind_direction_10m")
    current["wind_direction_cardinal"] = degrees_to_cardinal(wind_deg) if wind_deg is not None else None

    code = current.get("weather_code")
    current["weather_desc"] = wmo_to_desc(code) if code is not None else None

    today_daily = {
        "temperature_2m_max": (daily.get("temperature_2m_max") or [None])[0],
        "temperature_2m_min": (daily.get("temperature_2m_min") or [None])[0],
        "precipitation_probability_max": (daily.get("precipitation_probability_max") or [None])[0],
    }

    return {"current": current, "daily": today_daily}

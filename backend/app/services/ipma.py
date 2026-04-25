"""
IPMA API client — https://api.ipma.pt/
Weather forecast and sea state data.
No authentication required. Updates ~2x/day.

The API serves global forecast files per day index (0=today, 1=tomorrow…).
Each file contains all locations; we filter by globalIdLocal.
"""
import httpx
from typing import Optional

IPMA_BASE = "https://api.ipma.pt/open-data"

WEATHER_TYPES = {
    1: "Céu limpo", 2: "Poucas nuvens", 3: "Céu parcialmente nublado",
    4: "Céu muito nublado", 5: "Céu nublado", 6: "Aguaceiros fracos",
    7: "Aguaceiros", 8: "Aguaceiros fortes", 9: "Chuva fraca",
    10: "Chuva moderada", 11: "Chuva forte", 12: "Chuva fraca ou aguaceiros fracos",
    13: "Chuva ou aguaceiros", 14: "Chuva forte ou aguaceiros fortes",
    15: "Trovoada com chuva fraca", 16: "Trovoada com chuva moderada ou forte",
    17: "Granizo", 18: "Neve fraca", 19: "Neve moderada a forte",
    20: "Nevoeiro ou nuvens baixas", 21: "Neblina",
    22: "Aguaceiros e neve fraca", 23: "Chuva fraca e neve",
    24: "Chuva e neve", 25: "Neve e chuva fraca",
    26: "Chuva fraca ou aguaceiros fracos (probabilidade)",
    27: "Aguaceiros de granizo", 28: "Vento forte, aguaceiros fracos",
    29: "Trovoada com aguaceiros",
}

WIND_DIRECTIONS = {
    "N": "Norte", "NE": "Nordeste", "E": "Este", "SE": "Sudeste",
    "S": "Sul", "SW": "Sudoeste", "W": "Oeste", "NW": "Noroeste",
}


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
                            "wind_direction": WIND_DIRECTIONS.get(
                                item.get("predWindDir", ""), item.get("predWindDir")
                            ),
                            "weather_type_id": item.get("idWeatherType"),
                            "weather_type_desc": WEATHER_TYPES.get(
                                item.get("idWeatherType", 0), ""
                            ),
                        })
                        break
            except Exception:
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
            except Exception:
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

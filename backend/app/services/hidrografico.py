"""
Instituto Hidrográfico OGC API Features client.
https://api-features.hidrografico.pt/openapi

Tide prediction data. Updates rarely (astronomical, predictable).
"""
import httpx
from typing import Optional
from datetime import date, timedelta

IH_BASE = "https://api-features.hidrografico.pt"


async def fetch_collections() -> Optional[list]:
    """List available feature collections (for discovery)."""
    url = f"{IH_BASE}/collections"
    async with httpx.AsyncClient(timeout=10.0) as client:
        resp = await client.get(url, params={"f": "json"})
        resp.raise_for_status()
        data = resp.json()
        return data.get("collections", [])


async def fetch_tide_stations() -> Optional[list]:
    """Return all tide gauge stations."""
    url = f"{IH_BASE}/collections/PortosEstacoes/items"
    async with httpx.AsyncClient(timeout=10.0) as client:
        resp = await client.get(url, params={"f": "json", "limit": 200})
        resp.raise_for_status()
        data = resp.json()
        stations = []
        for feat in data.get("features", []):
            props = feat.get("properties", {})
            coords = feat.get("geometry", {}).get("coordinates", [])
            stations.append({
                "station_id": props.get("idLocal") or props.get("id"),
                "name": props.get("nome") or props.get("name"),
                "lat": coords[1] if len(coords) >= 2 else None,
                "lon": coords[0] if len(coords) >= 2 else None,
            })
        return stations


async def fetch_tides_for_station(station_id: str, target_date: Optional[date] = None) -> Optional[dict]:
    """
    Fetch tide predictions for a station for a given date (default: today).
    Returns a dict with date and list of tide entries.
    """
    if target_date is None:
        target_date = date.today()

    date_str = target_date.isoformat()
    next_day = (target_date + timedelta(days=1)).isoformat()

    url = f"{IH_BASE}/collections/PredMaresLocal/items"
    params = {
        "f": "json",
        "limit": 100,
        "idLocal": station_id,
        "datetime": f"{date_str}T00:00:00Z/{next_day}T00:00:00Z",
    }

    async with httpx.AsyncClient(timeout=10.0) as client:
        resp = await client.get(url, params=params)
        resp.raise_for_status()
        data = resp.json()

        entries = []
        for feat in data.get("features", []):
            props = feat.get("properties", {})
            entries.append({
                "time": props.get("data") or props.get("datetime") or props.get("time"),
                "height": props.get("altura") or props.get("height") or 0.0,
                "type": _classify_tide(props),
            })

        return {
            "station_id": station_id,
            "date": date_str,
            "entries": entries,
        }


def _classify_tide(props: dict) -> Optional[str]:
    tide_type = props.get("tipo") or props.get("type") or ""
    if "PM" in str(tide_type).upper() or "high" in str(tide_type).lower():
        return "high"
    if "BM" in str(tide_type).upper() or "low" in str(tide_type).lower():
        return "low"
    return None

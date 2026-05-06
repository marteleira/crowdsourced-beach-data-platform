"""
Carris Metropolitana API client.
https://github.com/carrismetropolitana/api

Provides stop info, routes, and real-time departures.
"""
import httpx
from typing import Optional, List

CARRIS_BASE = "https://api.carrismetropolitana.pt"


async def fetch_stop(stop_id: str) -> Optional[dict]:
    """Fetch metadata for a single stop."""
    url = f"{CARRIS_BASE}/stops/{stop_id}"
    async with httpx.AsyncClient(timeout=8.0) as client:
        try:
            resp = await client.get(url)
            resp.raise_for_status()
            data = resp.json()
            lat = data.get("lat")
            lon = data.get("lon")
            return {
                "stop_id": data.get("id") or data.get("stop_id"),
                "stop_name": data.get("name"),
                "lat": float(lat) if lat is not None else None,
                "lon": float(lon) if lon is not None else None,
            }
        except Exception:
            return None


async def fetch_stops_nearby(lat: float, lon: float, radius_m: int = 1000) -> Optional[List[dict]]:
    """Fetch stops within radius_m metres of (lat, lon)."""
    url = f"{CARRIS_BASE}/stops"
    params = {"lat": lat, "lon": lon, "radius": radius_m}
    async with httpx.AsyncClient(timeout=10.0) as client:
        try:
            resp = await client.get(url, params=params)
            resp.raise_for_status()
            stops = resp.json()
            return [
                {
                    "stop_id": s.get("id"),
                    "stop_name": s.get("name"),
                    "lat": s.get("lat"),
                    "lon": s.get("lon"),
                }
                for s in (stops if isinstance(stops, list) else [])
            ]
        except Exception:
            return None


async def fetch_stop_departures(stop_id: str) -> Optional[List[dict]]:
    """
    Fetch upcoming real-time departures for a stop from Carris Metropolitana.
    API response uses: line_id, headsign, estimated_arrival, scheduled_arrival.
    """
    url = f"{CARRIS_BASE}/stops/{stop_id}/realtime"
    async with httpx.AsyncClient(timeout=8.0) as client:
        try:
            resp = await client.get(url)
            resp.raise_for_status()
            data = resp.json()
            trips = []
            for item in data if isinstance(data, list) else []:
                trips.append({
                    "route_id": item.get("route_id") or item.get("line_id", ""),
                    "route_short_name": item.get("line_id", ""),
                    "trip_headsign": item.get("headsign", ""),
                    "stop_id": stop_id,
                    "departure_time": (
                        item.get("estimated_arrival")
                        or item.get("scheduled_arrival")
                        or ""
                    ),
                })
            return trips[:10]
        except Exception:
            return None


async def fetch_multiple_stops_departures(stop_ids: List[str]) -> List[dict]:
    """Aggregate departures for all stops near a beach."""
    import asyncio
    results = await asyncio.gather(
        *[fetch_stop_departures(sid) for sid in stop_ids],
        return_exceptions=True,
    )
    trips = []
    for res in results:
        if isinstance(res, list):
            trips.extend(res)
    # Sort by departure_time ascending
    return sorted(trips, key=lambda x: x.get("departure_time", ""))


async def fetch_routes() -> Optional[List[dict]]:
    """Fetch all Carris routes (for GTFS-like mapping)."""
    url = f"{CARRIS_BASE}/routes"
    async with httpx.AsyncClient(timeout=15.0) as client:
        try:
            resp = await client.get(url)
            resp.raise_for_status()
            return resp.json()
        except Exception:
            return None

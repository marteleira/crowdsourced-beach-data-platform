"""
Carris Metropolitana API client.
https://github.com/carrismetropolitana/api

Provides stop info, routes, and real-time departures.
"""
import logging
import httpx
from typing import Optional, List

logger = logging.getLogger(__name__)

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
        except Exception as e:
            logger.warning("Could not fetch Carris stop %s: %s", stop_id, e)
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
        except Exception as e:
            logger.warning("Could not fetch Carris stops near (%s, %s): %s",
                           lat, lon, e)
            return None


async def fetch_stop_departures(stop_id: str) -> Optional[List[dict]]:
    """
    Fetch upcoming real-time departures for a stop, filtered to now onwards.
    Uses scheduled_arrival_unix for precise time comparison.
    """
    import time as _time
    now_unix = int(_time.time())

    url = f"{CARRIS_BASE}/stops/{stop_id}/realtime"
    async with httpx.AsyncClient(timeout=8.0) as client:
        try:
            resp = await client.get(url)
            resp.raise_for_status()
            data = resp.json()
            trips = []
            for item in data if isinstance(data, list) else []:
                # Use the unix timestamp to filter out past trips accurately
                trip_unix = (
                    item.get("estimated_arrival_unix")
                    or item.get("scheduled_arrival_unix")
                    or 0
                )
                if trip_unix and trip_unix < now_unix:
                    continue

                # Prefer estimated over scheduled for the display time
                departure_time = (
                    item.get("estimated_arrival")
                    or item.get("scheduled_arrival")
                    or ""
                )

                trips.append({
                    "route_id": item.get("route_id") or item.get("line_id", ""),
                    "route_short_name": item.get("line_id", ""),
                    "trip_headsign": item.get("headsign", ""),
                    "stop_id": stop_id,
                    "departure_time": departure_time,
                    "departure_unix": trip_unix,
                    "is_realtime": item.get("estimated_arrival_unix") is not None,
                })
            return trips
        except Exception as e:
            logger.warning("Could not fetch Carris departures for stop %s: %s",
                           stop_id, e)
            return None


async def fetch_multiple_stops_departures(stop_ids: List[str]) -> List[dict]:
    """
    Aggregate departures for all stops near a beach, grouped by direction (headsign).
    Returns a flat list sorted by departure time; callers group by headsign if needed.
    """
    import asyncio
    results = await asyncio.gather(
        *[fetch_stop_departures(sid) for sid in stop_ids],
        return_exceptions=True,
    )
    seen: set[tuple] = set()
    trips = []
    for res in results:
        if isinstance(res, list):
            for t in res:
                # Deduplicate: same trip can appear for multiple nearby stops
                key = (t.get("trip_headsign", ""), t.get("departure_unix", 0))
                if key not in seen:
                    seen.add(key)
                    trips.append(t)

    return sorted(trips, key=lambda x: x.get("departure_unix") or 0)


async def fetch_routes() -> Optional[List[dict]]:
    """Fetch all Carris routes (for GTFS-like mapping)."""
    url = f"{CARRIS_BASE}/routes"
    async with httpx.AsyncClient(timeout=15.0) as client:
        try:
            resp = await client.get(url)
            resp.raise_for_status()
            return resp.json()
        except Exception as e:
            logger.warning("Could not fetch Carris routes: %s", e)
            return None

"""
APA InfoÁgua client — bathing water quality data.
https://sniamb.apambiente.pt/infobathing (web UI)
The public REST endpoint is underdocumented; we query the known JSON endpoint.
Updates daily (lab analysis results).
"""
import httpx
from typing import Optional

# APA SNIAmb InfoBathing API base
APA_BASE = "https://sniamb.apambiente.pt/api"

# Quality classification mapping (APA standard)
QUALITY_LABELS = {
    "E": "Excelente",
    "B": "Boa",
    "S": "Suficiente",
    "I": "Insuficiente",
    "P": "Má",
}


async def fetch_bathing_sites() -> Optional[list]:
    """List all registered bathing water sites in Portugal."""
    url = f"{APA_BASE}/bathing/sites"
    async with httpx.AsyncClient(timeout=12.0) as client:
        try:
            resp = await client.get(url)
            resp.raise_for_status()
            return resp.json()
        except Exception:
            return None


async def fetch_water_quality(station_id: str) -> Optional[dict]:
    """
    Fetch the latest water quality result for a given APA station.
    Returns normalised dict or None on failure.
    """
    url = f"{APA_BASE}/bathing/sites/{station_id}/quality"
    async with httpx.AsyncClient(timeout=10.0) as client:
        try:
            resp = await client.get(url)
            resp.raise_for_status()
            raw = resp.json()
            return _normalise(station_id, raw)
        except Exception:
            # APA API is underdocumented — try alternate endpoint
            return await _fetch_quality_fallback(station_id)


async def _fetch_quality_fallback(station_id: str) -> Optional[dict]:
    """
    Fallback: query APA's public GeoServer WFS endpoint.
    Used when the REST API is unavailable or changes structure.
    """
    url = "https://geo.snirh.apambiente.pt/geoserver/wfs"
    params = {
        "service": "WFS",
        "version": "2.0.0",
        "request": "GetFeature",
        "typeNames": "snirh:InfoBathing_PraiasBalnear",
        "outputFormat": "application/json",
        "CQL_FILTER": f"LOCAL_ID='{station_id}'",
        "count": "1",
    }
    async with httpx.AsyncClient(timeout=12.0) as client:
        try:
            resp = await client.get(url, params=params)
            resp.raise_for_status()
            data = resp.json()
            features = data.get("features", [])
            if not features:
                return None
            props = features[0].get("properties", {})
            return {
                "station_id": station_id,
                "classification": QUALITY_LABELS.get(
                    props.get("CLASS_ATUAL", ""), props.get("CLASS_ATUAL")
                ),
                "sampled_at": props.get("DATA_COLHEITA") or props.get("SEASON_YEAR"),
                "parameters": {
                    k: v for k, v in props.items()
                    if k not in ("LOCAL_ID", "NOME", "CLASS_ATUAL", "DATA_COLHEITA")
                },
            }
        except Exception:
            return None


def _normalise(station_id: str, raw: dict) -> dict:
    return {
        "station_id": station_id,
        "classification": QUALITY_LABELS.get(
            raw.get("classification", ""), raw.get("classification")
        ),
        "sampled_at": raw.get("sampled_at") or raw.get("date"),
        "parameters": raw.get("parameters") or {},
    }

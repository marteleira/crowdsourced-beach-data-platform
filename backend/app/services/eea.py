"""
EEA WISE Bathing Water Directive client — water quality data

Data source: European Environment Agency DiscoData (WISE_BWD database)
  https://discodata.eea.europa.eu/

Classification is updated once per year, at the end of each bathing season
The `apa_station_id` field on each Beach must hold the EEA
`bathingWaterIdentifier` for the corresponding site (e.g. "PTCQ8P")

Finding the correct identifier for a beach:
  1. Open https://snirh.apambiente.pt/?idMain=1&idItem=2.1 in a browser
  2. Select the ARH region and municipality (Setúbal beaches → ARH Tejo)
  3. Click the beach — the URL will contain code_cee=PTXXXX
  OR
  1. Open https://www.eea.europa.eu/en/analysis/maps-and-charts/state-of-bathing-waters
  2. Search for the beach by name and note the identifier in the popup
"""
import re
import logging
import httpx
from typing import Optional

logger = logging.getLogger(__name__)

DISCODATA_URL = "https://discodata.eea.europa.eu/sql"

# Valid EEA bathingWaterIdentifier: 2-letter country code + 4 alphanumeric chars
_VALID_ID = re.compile(r'^[A-Z]{2}[A-Z0-9]{4,10}$')


async def fetch_water_quality(station_id: str) -> Optional[dict]:
    """
    Fetch the most recent annual classification for an EEA bathing water site.
    `station_id` must be the EEA bathingWaterIdentifier (e.g. "PTCQ8P").
    Returns a normalised dict or None on failure / site not found.
    """
    if not _VALID_ID.match(station_id):
        return None

    # Parameterised-style embedding is not supported by DiscoData; we validate
    # the ID above so the format is safe to interpolate directly.
    query = (
        "SELECT TOP 1 bathingWaterIdentifier, quality, season "
        "FROM [WISE_BWD].[latest].[assessment_BathingWaterStatus] "
        f"WHERE bathingWaterIdentifier='{station_id}' "
        "ORDER BY season DESC"
    )
    params = {"query": query, "p": "1", "nrOfHits": "1"}

    async with httpx.AsyncClient(timeout=15.0) as client:
        try:
            resp = await client.get(DISCODATA_URL, params=params)
            resp.raise_for_status()
            data = resp.json()
            results = data.get("results", [])
            if not results:
                return None
            return _normalise(station_id, results[0])
        except Exception as e:
            logger.warning("Could not fetch water quality for %s: %s",
                           station_id, e)
            return None


def _normalise(station_id: str, row: dict) -> dict:
    raw_quality = (row.get("quality") or "").strip()
    # EEA quality string format: "1 - Excellent", "2 - Good", etc.
    code = raw_quality.split(" - ")[0]
    quality_code = int(code) if code.isdigit() else None
    season = row.get("season")
    return {
        "station_id": station_id,
        "quality_code": quality_code,
        "sampled_at": str(season) if season else None,
        "parameters": {"eea_quality_raw": raw_quality, "season": season},
    }

"""
Populate tide_observations with historical IH data

Paginates through the IH real-time API (tide_obs_data_nrt_l1_min) using
eu_lau_code filter + ascending sort + offset stepping, each page covers
~1 minute of data, we step by ~470 records to sample every ~14 minutes,
targeting ~500 observations per station.

Rate: 0.5 s between requests
Typical runtime: ~13 minutes for both stations.
"""
import asyncio
import sys
import os
from datetime import datetime, timezone

import httpx

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from app.services.hidrografico import store_observation as _store  # noqa
from app.core.database import AsyncSessionLocal
from app.models.tide_model import TideObservation
from sqlalchemy import select
from sqlalchemy.dialects.postgresql import insert as pg_insert

IH_BASE = "https://api-features.hidrografico.pt"

# eu_lau_code → primary sensor codp (used to filter the right sensor client-side)
STATIONS = {
    "PT_150505_2": 20.0,   # Setúbal - Tróia (primary sensor)
    "PT_151101_1": 28.0,   # Sesimbra (primary sensor)
}

# Empirically: ~32.9 records/minute in the eu_lau_code-filtered stream.
# Step 470 ≈ one sample every 14 minutes.
OFFSET_STEP = 470
TARGET_OBS  = 500        # stop after this many obs per station
DELAY_S     = 0.5        # seconds between requests


async def _get_total(station_id: str, client: httpx.AsyncClient) -> int:
    r = await client.get(
        f"{IH_BASE}/collections/tide_obs_data_nrt_l1_min/items",
        params={"f": "json", "limit": 1, "eu_lau_code": station_id, "sortby": "date_time"},
    )
    r.raise_for_status()
    return r.json().get("numberMatched", 0)


async def _fetch_page(station_id: str, offset: int, client: httpx.AsyncClient) -> list[dict]:
    r = await client.get(
        f"{IH_BASE}/collections/tide_obs_data_nrt_l1_min/items",
        params={
            "f": "json", "limit": 31,
            "eu_lau_code": station_id,
            "sortby": "date_time",
            "offset": offset,
        },
        timeout=12.0,
    )
    r.raise_for_status()
    return r.json().get("features", [])


async def _save_observation(station_id: str, height: float, observed_at: datetime) -> bool:
    async with AsyncSessionLocal() as db:
        stmt = (
            pg_insert(TideObservation)
            .values(station_id=station_id, height=height, observed_at=observed_at)
            .on_conflict_do_nothing(constraint="uq_tide_obs_station_time")
        )
        result = await db.execute(stmt)
        await db.commit()
        return result.rowcount > 0


async def populate_station(station_id: str, primary_codp: float) -> int:
    print(f"\n{'='*55}")
    print(f"Station: {station_id}  (codp={primary_codp:.0f})")
    print(f"{'='*55}")

    async with httpx.AsyncClient(timeout=15) as client:
        total = await _get_total(station_id, client)
        print(f"Total records in API: {total:,}")
        if total == 0:
            print("No data found.")
            return 0

        stored = skipped = errors = 0
        offset = 0

        while offset <= total and stored < TARGET_OBS:
            try:
                features = await _fetch_page(station_id, offset, client)
            except Exception as e:
                errors += 1
                if errors > 10:
                    print(f"  Too many errors, stopping.")
                    break
                offset += OFFSET_STEP
                await asyncio.sleep(DELAY_S)
                continue

            # Filter: primary sensor only, QC=0
            valid = [
                f for f in features
                if f.get("properties", {}).get("codp") == primary_codp
                and f.get("properties", {}).get("sea_surface_height_qc", 1) == 0
                and f.get("properties", {}).get("sea_surface_height") is not None
            ]

            for feat in valid[:1]:   # one observation per 14-minute window
                props = feat["properties"]
                h = round(float(props["sea_surface_height"]), 3)
                try:
                    t = datetime.fromisoformat(props["date_time"])
                    if t.tzinfo is None:
                        t = t.replace(tzinfo=timezone.utc)
                except (ValueError, TypeError):
                    continue

                inserted = await _save_observation(station_id, h, t)
                if inserted:
                    stored += 1
                else:
                    skipped += 1

            # Progress every 50 stored
            if stored % 50 == 0 and stored > 0:
                print(f"  stored={stored:>4}  offset={offset:>7}  skipped={skipped}")

            offset += OFFSET_STEP
            await asyncio.sleep(DELAY_S)

        print(f"\nDone — stored={stored}, skipped={skipped}, errors={errors}")
        return stored


async def main():
    print("OndaCerta — historical tide observation importer")
    print(f"Target: {TARGET_OBS} observations/station  |  Delay: {DELAY_S}s/request")

    total_stored = 0
    for station_id, codp in STATIONS.items():
        n = await populate_station(station_id, codp)
        total_stored += n

    print(f"\n{'='*55}")
    print(f"Total stored across all stations: {total_stored}")
    print("Run the scheduler or wait for weekly fit to build the model.")
    print("Minimum needed for model fit:", 360, "observations/station")


if __name__ == "__main__":
    asyncio.run(main())

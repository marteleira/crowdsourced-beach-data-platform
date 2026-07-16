"""
Populate tide_observations with historical IH data - span-aware version.

Strategy
--------
The harmonic fit needs ≥ MIN_SPAN_DAYS (15) of coverage to separate M2 from
S2 — the *time span* matters, not the row count.  This script therefore:

  1. PROBES the archive at runtime: numberMatched + first/last timestamps
     give the exact available span and record density (no hard-coded
     "32.9 records/minute" assumptions, which break on data gaps).
  2. Detects whether the server honours the standard OGC `datetime`
     parameter (pygeoapi supports it when the provider has a time field).
     If yes, samples deterministic time windows thats immune to gaps.
     If not, falls back to offset stepping computed from measured density.
  3. Spreads TARGET_OBS samples evenly over the MOST RECENT
     TARGET_SPAN_DAYS of the archive (sampling from the newest end, not the
     oldest — recent data also feeds the live MSL estimator).
  4. Additionally backfills the last RECENT_TAIL_HOURS densely
     (RECENT_TAIL_STEP_MIN cadence) so _estimate_msl_from_recent_obs has
     data immediately after import.
  5. Uses the L2 collection (5min, quality-controlled) by default, falling
     back to L1 (1-min raw) if L2 has no data for the station.

QC convention (IOC/OceanSITES): 0 = no QC performed, 1 = good, 2 = probably
good, 3 = suspect, 4 = bad.  We accept {0, 1} — the previous `qc == 0`
filter would have REJECTED all quality-controlled good data on L2 (where the
flag arrives as the string 1).

Rate: DELAY_S between requests.  Typical runtime: a few minutes per station.
After a successful import this script triggers the harmonic fit directly.
"""
import asyncio
import sys
import os
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from typing import Optional

import httpx

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

IH_BASE = "https://api-features.hidrografico.pt"

# Collections, in order of preference.  L2 = 5-min QC'd product (≈5× fewer
# records per unit time than the raw 1-min L1 stream, and quality-flagged).
COLLECTIONS = ["tide_obs_data_nrt_l2", "tide_obs_data_nrt_l1_min"]

# eu_lau_code → primary sensor codp (None = auto-detect the modal codp)
STATIONS: dict[str, Optional[float]] = {
    "PT_150505_2": 20.0,   # Setúbal - Tróia
    "PT_151101_1": 28.0,   # Sesimbra
}

MIN_SPAN_DAYS = 15.0        # hard floor for a usable M2/S2 fit
TARGET_SPAN_DAYS = 30.0     # aim for the 10-min accuracy tier
TARGET_OBS = 600            # sparse samples spread over the span
RECENT_TAIL_HOURS = 25.0    # dense recent window for the MSL estimator
RECENT_TAIL_STEP_MIN = 15
DELAY_S = 0.5
PAGE_LIMIT = 40             # wide enough to contain ≥1 primary-sensor record
ACCEPTED_QC = {0, 1}        # no-QCyet or good

# Keep imports of app.* lazy so the fetch/planning logic is testable
# without the application package installed.

def _qc_ok(value) -> bool:
    try:
        return int(float(value)) in ACCEPTED_QC
    except (TypeError, ValueError):
        return False


def _parse_time(s) -> Optional[datetime]:
    try:
        t = datetime.fromisoformat(s)
        return t.replace(tzinfo=timezone.utc) if t.tzinfo is None else t
    except (ValueError, TypeError):
        return None


@dataclass
class ArchiveProbe:
    collection: str
    total: int
    t_first: datetime
    t_last: datetime
    datetime_filter: bool
    primary_codp: Optional[float]

    @property
    def span_days(self) -> float:
        return (self.t_last - self.t_first).total_seconds() / 86400.0

    @property
    def records_per_minute(self) -> float:
        mins = max(1.0, (self.t_last - self.t_first).total_seconds() / 60.0)
        return self.total / mins


class IHClient:
    def __init__(self, client: httpx.AsyncClient):
        self.c = client

    async def items(self, collection: str, station_id: str, **params) -> dict:
        base = {"f": "json", "eu_lau_code": station_id, "sortby": "date_time"}
        base.update(params)
        r = await self.c.get(
            f"{IH_BASE}/collections/{collection}/items",
            params=base, timeout=15.0,
        )
        r.raise_for_status()
        return r.json()

    async def probe(self, station_id: str,
                    preferred_codp: Optional[float]) -> Optional[ArchiveProbe]:
        """Measure the archive: collection, total, span, density,
        datetime-filter support, and primary sensor codp."""
        for collection in COLLECTIONS:
            head = await self.items(collection, station_id, limit=PAGE_LIMIT)
            total = head.get("numberMatched", 0)
            feats = head.get("features", [])
            if total == 0 or not feats:
                continue

            t_first = _parse_time(feats[0]["properties"].get("date_time"))
            await asyncio.sleep(DELAY_S)
            tail = await self.items(collection, station_id, limit=PAGE_LIMIT,
                                    offset=max(0, total - PAGE_LIMIT))
            tail_feats = tail.get("features", [])
            t_last = None
            for f in reversed(tail_feats):
                t_last = _parse_time(f["properties"].get("date_time"))
                if t_last:
                    break
            if not (t_first and t_last and t_last > t_first):
                continue

            # Auto-detect primary codp when not configured: modal codp
            # among QC-accepted records in the head page.
            codp = preferred_codp
            if codp is None:
                counts: dict[float, int] = {}
                for f in feats:
                    p = f.get("properties", {})
                    if _qc_ok(p.get("sea_surface_height_qc", 0)):
                        c = p.get("codp")
                        if c is not None:
                            counts[c] = counts.get(c, 0) + 1
                codp = max(counts, key=counts.get) if counts else None

            # Probe OGC datetime support: a 1-hour window in the middle of
            # the archive must match far fewer records than the whole set.
            mid = t_first + (t_last - t_first) / 2
            await asyncio.sleep(DELAY_S)
            dt_supported = False
            try:
                win = await self.items(
                    collection, station_id, limit=1,
                    datetime=f"{mid.isoformat()}/{(mid + timedelta(hours=1)).isoformat()}",
                )
                nm = win.get("numberMatched", total)
                dt_supported = 0 < nm < max(2, total // 10)
            except httpx.HTTPStatusError:
                dt_supported = False

            return ArchiveProbe(collection=collection, total=total,
                                t_first=t_first, t_last=t_last,
                                datetime_filter=dt_supported,
                                primary_codp=codp)
        return None


def build_sample_times(probe: ArchiveProbe) -> list[datetime]:
    """Sample instants: sparse grid over the most recent TARGET_SPAN_DAYS
    (or whatever the archive holds) + dense recent tail.  Deduplicated and
    ascending."""
    span_days = min(TARGET_SPAN_DAYS, probe.span_days)
    t_end = probe.t_last
    t_start = t_end - timedelta(days=span_days)

    step = timedelta(days=span_days) / max(1, TARGET_OBS - 1)
    times = [t_start + i * step for i in range(TARGET_OBS)]

    tail_start = t_end - timedelta(hours=RECENT_TAIL_HOURS)
    t = tail_start
    while t <= t_end:
        times.append(t)
        t += timedelta(minutes=RECENT_TAIL_STEP_MIN)

    # Deduplicate to one sample per 5-min bucket (L2 native cadence).
    seen: set[int] = set()
    out: list[datetime] = []
    for t in sorted(times):
        key = int(t.timestamp() // 300)
        if key not in seen:
            seen.add(key)
            out.append(t)
    return out


def _pick_valid(features: list[dict], codp: Optional[float]) -> Optional[tuple[float, datetime]]:
    for f in features:
        p = f.get("properties", {})
        if codp is not None and p.get("codp") != codp:
            continue
        if not _qc_ok(p.get("sea_surface_height_qc", 0)):
            continue
        h = p.get("sea_surface_height")
        t = _parse_time(p.get("date_time"))
        if h is None or t is None:
            continue
        return round(float(h), 3), t
    return None


async def collect_station(ih: IHClient, station_id: str,
                          probe: ArchiveProbe) -> list[tuple[float, datetime]]:
    """Fetch one valid observation per planned sample instant."""
    sample_times = build_sample_times(probe)
    print(f"  plan: {len(sample_times)} samples over "
          f"{min(TARGET_SPAN_DAYS, probe.span_days):.1f} days "
          f"({'datetime windows' if probe.datetime_filter else 'offset stepping'})")

    window = timedelta(minutes=max(10, RECENT_TAIL_STEP_MIN))
    density = probe.records_per_minute  # only needed for the offset path
    collected: list[tuple[float, datetime]] = []
    errors = 0
    last_progress = 0

    for i, t in enumerate(sample_times):
        try:
            if probe.datetime_filter:
                page = await ih.items(
                    probe.collection, station_id, limit=PAGE_LIMIT,
                    datetime=f"{t.isoformat()}/{(t + window).isoformat()}",
                )
            else:
                # offset - records elapsed since archive start at time t
                offset = int((t - probe.t_first).total_seconds() / 60.0
                             * density)
                offset = min(max(0, offset), max(0, probe.total - 1))
                page = await ih.items(probe.collection, station_id,
                                      limit=PAGE_LIMIT, offset=offset)
            hit = _pick_valid(page.get("features", []), probe.primary_codp)
            if hit:
                collected.append(hit)
        except Exception as e:
            errors += 1
            if errors > 15:
                print(f"  too many errors ({e!r}); stopping early.")
                break
        if len(collected) >= last_progress + 100:
            last_progress = len(collected)
            print(f"  collected={len(collected):>4}  "
                  f"({i + 1}/{len(sample_times)} windows)")
        await asyncio.sleep(DELAY_S)

    # Dedupe on the exact timestamp (windows can overlap at the tail).
    uniq = {t: h for h, t in collected}
    return sorted(((h, t) for t, h in uniq.items()), key=lambda x: x[1])


async def save_batch(station_id: str,
                     obs: list[tuple[float, datetime]]) -> int:
    """Insert all observations in one session; returns rows inserted."""
    from app.core.database import AsyncSessionLocal
    from app.models.tide_model import TideObservation
    from sqlalchemy.dialects.postgresql import insert as pg_insert

    if not obs:
        return 0
    inserted = 0
    async with AsyncSessionLocal() as db:
        for height, observed_at in obs:
            stmt = (
                pg_insert(TideObservation)
                .values(station_id=station_id, height=height,
                        observed_at=observed_at)
                .on_conflict_do_nothing(constraint="uq_tide_obs_station_time")
            )
            result = await db.execute(stmt)
            inserted += result.rowcount or 0
        await db.commit()
    return inserted


async def populate_station(ih: IHClient, station_id: str,
                           preferred_codp: Optional[float]) -> int:
    print(f"\n{'=' * 55}\nStation: {station_id}\n{'=' * 55}")
    probe = await ih.probe(station_id, preferred_codp)
    if probe is None:
        print("No data found in any collection.")
        return 0

    print(f"  collection: {probe.collection}")
    print(f"  archive: {probe.total:,} records, "
          f"{probe.t_first:%Y-%m-%d} → {probe.t_last:%Y-%m-%d} "
          f"({probe.span_days:.1f} days, {probe.records_per_minute:.2f} rec/min)")
    print(f"  primary codp: {probe.primary_codp}")

    if probe.span_days < MIN_SPAN_DAYS:
        print(f"  WARNING: archive holds only {probe.span_days:.1f} days "
              f"(< {MIN_SPAN_DAYS:.0f} needed for M2/S2 separation).\n"
              f"  Importing what exists — keep the scheduler storing live\n"
              f"  observations and the fit will engage once the span "
              f"reaches {MIN_SPAN_DAYS:.0f} days.")

    obs = await collect_station(ih, station_id, probe)
    if not obs:
        print("  nothing collected.")
        return 0

    span = (obs[-1][1] - obs[0][1]).total_seconds() / 86400.0
    inserted = await save_batch(station_id, obs)
    print(f"\n  Done — collected={len(obs)}, inserted={inserted}, "
          f"span={span:.1f} days")
    return inserted


async def main():
    print("OndaCerta — historical tide observation importer (span-aware)")
    print(f"Target: ≥{MIN_SPAN_DAYS:.0f} days (ideal {TARGET_SPAN_DAYS:.0f}) "
          f"× ~{TARGET_OBS} obs/station | delay {DELAY_S}s/request")

    total_inserted = 0
    async with httpx.AsyncClient(timeout=15) as client:
        ih = IHClient(client)
        for station_id, codp in STATIONS.items():
            total_inserted += await populate_station(ih, station_id, codp)

    print(f"\n{'=' * 55}")
    print(f"Total inserted across all stations: {total_inserted}")

    if total_inserted:
        print("Triggering harmonic fit now (no need to wait for the "
              "weekly job)…")
        from app.services.hidrografico import fit_model_from_observations
        for station_id in STATIONS:
            n = await fit_model_from_observations(station_id)
            print(f"  {station_id}: "
                  + (f"fitted with {n} observations"
                     if n else "not fitted (insufficient span/count — "
                               "will retry on the weekly schedule)"))


if __name__ == "__main__":
    asyncio.run(main())
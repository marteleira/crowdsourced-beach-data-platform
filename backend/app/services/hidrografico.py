"""
Instituto Hidrográfico OGC API Features client.
https://api-features.hidrografico.pt

Tide prediction strategy (self-improving over time):

  Phase 1 — bootstrap (insufficient observations in DB):
    Use published IH harmonic constants for Setúbal (M2+S2+N2+K1+O1) as a
    starting model, the MSL is estimated from the mean residual of the last
    ~25 h of stored observations when available (robust to surge/noise),
    falling back to anchoring on the single live observation.
    Accuracy: ±15–25 min.

  Phase 2 — data-driven (≥ MIN_OBS_FOR_FIT observations spanning ≥ MIN_SPAN_DAYS_FOR_FIT days):
    Run utide.solve on the accumulated real observations to fit a full
    harmonic model directly to this station's data,the  fitted coefficients
    are cached in tide_model_coef and refitted weekly by the scheduler.
    The constituent set grows automatically with record length (shallow-water
    M4/MS4 from the start; P1/K2/Q1 after +-6 months, SA/SSA after ~13 months).
    Accuracy improves with data: ≥30 days -> ±10 min, ≥90 days then ±5 min.

  Both phases apply a persistence correction: the instantaneous residual
  (observation − model) is added to the forecast with an exponential decay
  (t = RESIDUAL_DECAY_HOURS), which absorbs meteorological surge in the
  first hours of the tide table

  NOTE: run the populate_tide_observations.py script to backfill historical
  data and trigger the first fit.

Station IDs (eu_lau_code):
  PT_150505_2  Setúbal - Tróia   (Arrábida beaches)
  PT_151101_1  Sesimbra
"""
import copy
import asyncio
import logging
import warnings
from typing import Optional, Sequence
from datetime import datetime, timedelta, timezone
from zoneinfo import ZoneInfo

import httpx
import numpy as np

logger = logging.getLogger(__name__)

IH_BASE = "https://api-features.hidrografico.pt"

# Times shown to users are converted to this zone (handles WET/WEST DST)
LOCAL_TZ = ZoneInfo("Europe/Lisbon")

# Minimum observations AND minimum time span required to switch from
# published constants to the fitted model, the span check matters: 360 rows
# at 10-min cadence is only 2.5 days and thts far too short to separate M2 from S2,
# which needs ~15 days (one synodic month / 2).
MIN_OBS_FOR_FIT = 360
MIN_SPAN_DAYS_FOR_FIT = 15.0

# Constituent tiers by record length (Rayleigh criterion, conservative).
_CONSTIT_15D = ["M2", "S2", "N2", "K1", "O1", "M4", "MS4"]
_CONSTIT_6MO = _CONSTIT_15D + ["P1", "K2", "Q1"]          # ≥ ~183 days
_CONSTIT_13MO = _CONSTIT_6MO + ["SA", "SSA"]              # ≥ ~400 days

# e-folding time of the persistence (surge) correction, and the maximum
# magnitude it may take, the meteorological surge on the Portuguese coast rarely
# exceeds ~0.6 m, so a larger residual indicates bad data or gross model
# misalignment and must not be propagated into the forecast.
RESIDUAL_DECAY_HOURS = 6.0
RESIDUAL_MAX = 0.8

# |dh|, over 10 min below which the tide is reported as "steady" (≈ 5 cm/h).
_STEADY_THRESHOLD_M_PER_10MIN = 0.008

# Published fallback constants (IH Tabelas de Marés, Setúbal 07/05/2026
# means low accuracy, bootstrap only)
SETUBAL_CONSTITUENTS = {
    "M2": {"A": 1.475, "g": 332.0},
    "S2": {"A": 0.530, "g":   4.0},
    "N2": {"A": 0.259, "g": 305.0},
    "K1": {"A": 0.075, "g":  64.0},
    "O1": {"A": 0.059, "g":  41.0},
}

STATION_LAT = 38.49

# Approximate MSL above the hydrographic zero (ZH) at Setúbal-Tróia.
# Source: IH, ZH is 2.00 m below the adopted mean level, plus ~+0.10 m of
# systematic sealevel rise since that datum was fixed, used ONLY as a
# sanity anchor: if a single-observation MSL estimate lands outside
# DEFAULT_MSL ± MSL_SANITY_BAND, the observation is contaminated by surge or
# phase misalignment, so we keep DEFAULT_MSL and let the decaying residual
# correction absorb the difference instead of shifting the whole tide table.
DEFAULT_MSL = 2.10
MSL_SANITY_BAND = 0.60

#  Template / bootstrap coef caches (per-process) 
# the templates are utide coef structures (with the full `aux` machinery needed by
# utide.reconstruct) built once per constituent set from synthetic data
# They are NEVER handed out directly, the callers always receive a deepcopy, so
# patching amplitudes/phases cannot corrupt the cache (this was a bug in the
# previous version).
_TEMPLATE_CACHE: dict[tuple, dict] = {}
_BOOTSTRAP_COEF: Optional[dict] = None


def _to_dt64(times: Sequence[datetime]) -> np.ndarray:
    """Convert (possibly tz-aware) datetimes to a naive-UTC datetime64 array

    Passing tz-aware datetimes straight into np.array(dtype='datetime64')
    is deprecated in numpy and loses/garbles the offset; normalising to
    naive UTC is explicit and warning-free.
    """
    out = []
    for t in times:
        if t.tzinfo is not None:
            t = t.astimezone(timezone.utc).replace(tzinfo=None)
        out.append(t)
    return np.array(out, dtype="datetime64[s]")


def _template_coef(constituents: Sequence[str]) -> dict:
    """Return a deepcopy of a full utide coef structure for `constituents`.

    Built by running utide.solve on synthetic data — this is the only
    supported way to obtain a coef with a valid `aux` block (frequencies,
    nodal machinery, reference time) for utide.reconstruct.  Amplitudes and
    phases in the returned copy are meaningless until patched by the caller.
    """
    key = tuple(sorted(constituents))
    if key not in _TEMPLATE_CACHE:
        import utide
        # Long-period constituents (SA/SSA) need a long synthetic record to
        # be resolvable; everything else is fine with ~1 month of hourly data.
        long_period = any(c in ("SA", "SSA") for c in key)
        step_h, n = (3, 4000) if long_period else (1, 800)
        t0 = datetime(2024, 1, 1)
        t = _to_dt64([t0 + timedelta(hours=i * step_h) for i in range(n)])
        rng = np.arange(n) * step_h
        h = (1.5 * np.cos(2 * np.pi * rng / 12.42)
             + 0.5 * np.cos(2 * np.pi * rng / 12.0))
        with warnings.catch_warnings():
            warnings.simplefilter("ignore")
            coef = utide.solve(t, h, lat=STATION_LAT, constit=list(key),
                               method="ols", conf_int="linear",
                               trend=False, verbose=False)
        coef["mean"] = 0.0
        coef["slope"] = 0.0
        _TEMPLATE_CACHE[key] = coef
    return copy.deepcopy(_TEMPLATE_CACHE[key])


def _bootstrap_coef() -> dict:
    """Deepcopy of the published-constants bootstrap model for Setúbal."""
    global _BOOTSTRAP_COEF
    if _BOOTSTRAP_COEF is None:
        coef = _template_coef(list(SETUBAL_CONSTITUENTS.keys()))
        for i, name in enumerate(coef["name"]):
            if name in SETUBAL_CONSTITUENTS:
                coef["A"][i] = SETUBAL_CONSTITUENTS[name]["A"]
                coef["g"][i] = SETUBAL_CONSTITUENTS[name]["g"]
        _BOOTSTRAP_COEF = coef
    return copy.deepcopy(_BOOTSTRAP_COEF)


# Serialise / deserialise utide coef

def coef_to_dict(coef) -> dict:
    """Serialise the utide coef Bunch to a plain dict (for JSONB storage)."""
    return {
        "name": [str(n) for n in coef["name"]],
        "A":    [float(a) for a in coef["A"]],
        "g":    [float(g) for g in coef["g"]],
        "mean": float(coef.get("mean", 0.0)),
    }


def coef_from_dict(d: dict):
    """Rebuild a utide coef Bunch from a stored dict

    The reconstruction template is built from the *stored* constituent list,
    so every fitted constituent (including shallow-water M4/MS4 and any
    long-record additions) survives the round trip, the previous version
    silently dropped anything outside the 5 bootstrap constituents.
    """
    names_stored: list[str] = list(d["name"])
    coef = _template_coef(names_stored)
    lookup = {n: i for i, n in enumerate(names_stored)}
    for i, name in enumerate(coef["name"]):
        j = lookup.get(str(name))
        if j is not None:
            coef["A"][i] = d["A"][j]
            coef["g"][i] = d["g"][j]
    coef["mean"] = d.get("mean", 0.0)
    coef["slope"] = 0.0
    return coef


# Core prediction engine (pure/synchronous — call via _predict_async)
def _predict_harmonic(coef, t_start: datetime, hours: float = 36,
                      step_min: int = 5) -> np.ndarray:
    """Return the harmonic component (MSL excluded) for a time range."""
    import utide
    n = int(hours * 60 / step_min) + 1
    t_arr = _to_dt64([t_start + timedelta(minutes=i * step_min)
                      for i in range(n)])
    with warnings.catch_warnings():
        warnings.simplefilter("ignore")
        result = utide.reconstruct(t_arr, coef, verbose=False,
                                   min_SNR=0, min_PE=0)
    return result.h


async def _predict_async(coef, t_start: datetime, hours: float = 36,
                         step_min: int = 5) -> np.ndarray:
    """Run the (CPU-bound) harmonic reconstruction off the event loop."""
    return await asyncio.to_thread(_predict_harmonic, coef, t_start,
                                   hours, step_min)


def _residual_decay(t_start: datetime, n: int, step_min: int,
                    offset: float, obs_time: datetime,
                    tau_hours: float = RESIDUAL_DECAY_HOURS) -> np.ndarray:
    """Persistence correction: full offset at obs_time, decaying with e-folding
    time `tau_hours`.  Before obs_time (hindcast part of the grid) the full
    offset applies — it is our best estimate of the recent non-tidal signal."""
    if abs(offset) < 1e-9:
        return np.zeros(n)
    dt_h = (np.arange(n) * step_min
            - (obs_time - t_start).total_seconds() / 60.0) / 60.0
    dt_h = np.clip(dt_h, 0.0, None)
    return offset * np.exp(-dt_h / tau_hours)


def _find_next_extrema(
    t_start: datetime,
    h: np.ndarray,
    after: datetime,
    step_min: int = 5,
    n: int = 4,
) -> list[dict]:
    """Locate the next `n` tide extrema after `after` in the height series.

    Extrema instants are refined with a parabolic fit through the three
    samples around each grid extremum, giving ~1-min precision instead of
    quantising to the 5-min grid.  Times are reported in LOCAL_TZ.
    """
    extrema: list[dict] = []
    after_idx = max(1, int((after - t_start).total_seconds() / 60 / step_min))
    for i in range(after_idx, len(h) - 1):
        is_high = h[i] > h[i - 1] and h[i] >= h[i + 1]
        is_low = h[i] < h[i - 1] and h[i] <= h[i + 1]
        if not (is_high or is_low):
            continue
        # Parabolic refinement: vertex of parabola through (i-1, i, i+1).
        denom = h[i - 1] - 2.0 * h[i] + h[i + 1]
        if abs(denom) > 1e-12:
            delta = 0.5 * (h[i - 1] - h[i + 1]) / denom
            delta = float(np.clip(delta, -1.0, 1.0))
        else:
            delta = 0.0
        t_ext = t_start + timedelta(minutes=(i + delta) * step_min)
        if t_ext <= after:
            continue
        h_ext = float(h[i] - 0.25 * (h[i - 1] - h[i + 1]) * delta)
        t_local = t_ext.astimezone(LOCAL_TZ)
        extrema.append({
            "time": t_local.strftime("%H:%M"),
            "time_iso": t_local.isoformat(timespec="minutes"),
            "height": round(h_ext, 2),
            "type": "high" if is_high else "low",
        })
        if len(extrema) == n:
            break
    return extrema


# DB helpers 

async def _load_fitted_coef(station_id: str):
    """Load the data-driven fitted coef from the DB (None if not available)."""
    try:
        from app.core.database import AsyncSessionLocal
        from app.models.tide_model import TideModelCoef
        from sqlalchemy import select
        async with AsyncSessionLocal() as db:
            r = await db.execute(
                select(TideModelCoef).where(TideModelCoef.station_id == station_id)
            )
            row = r.scalar_one_or_none()
            if row is None or row.n_observations < MIN_OBS_FOR_FIT:
                return None, None
            return coef_from_dict(row.coef_json), float(row.msl)
    except Exception as e:
        logger.warning("Could not load fitted coef for %s: %s", station_id, e)
        return None, None


async def _estimate_msl_from_recent_obs(station_id: str, coef,
                                        now: datetime,
                                        window_hours: float = 25.0
                                        ) -> Optional[float]:
    """Bootstrap MSL estimate: mean(observation − harmonic) over the last
    ~25 h of stored observations (covers two full M2 cycles plus the diurnal
    inequality, so tidal signal averages out).  Far more robust than anchoring
    on a single reading, which folds surge/seiche/sensor noise straight into
    the MSL and shifts the whole 36 h tide table.  Returns None when there is
    not enough data (falls back to single-point anchoring)."""
    try:
        from app.core.database import AsyncSessionLocal
        from app.models.tide_model import TideObservation
        from sqlalchemy import select
        cutoff = now - timedelta(hours=window_hours)
        async with AsyncSessionLocal() as db:
            r = await db.execute(
                select(TideObservation.observed_at, TideObservation.height)
                .where(TideObservation.station_id == station_id,
                       TideObservation.observed_at >= cutoff)
                .order_by(TideObservation.observed_at)
            )
            rows = r.all()
        if len(rows) < 12:
            return None
        times = []
        heights = []
        for observed_at, height in rows:
            if observed_at.tzinfo is None:
                observed_at = observed_at.replace(tzinfo=timezone.utc)
            times.append(observed_at)
            heights.append(float(height))
        t_arr = _to_dt64(times)
        import utide
        with warnings.catch_warnings():
            warnings.simplefilter("ignore")
            harm = await asyncio.to_thread(
                utide.reconstruct, t_arr, coef, verbose=False,
                min_SNR=0, min_PE=0)
        return float(np.mean(np.asarray(heights) - harm.h))
    except Exception as e:
        logger.debug("MSL-from-recent-obs unavailable for %s: %s", station_id, e)
        return None


#IH real-time API 

async def fetch_current_observation(station_id: str) -> Optional[tuple[float, str]]:
    """Return (height_m, observed_at_iso) from the IH real-time API."""
    url = f"{IH_BASE}/collections/tide_obs_stations_nrt/items"
    async with httpx.AsyncClient(timeout=10.0) as client:
        resp = await client.get(url, params={"f": "json", "limit": 100,
                                             "eu_lau_code": station_id})
        resp.raise_for_status()
        features = resp.json().get("features", [])
        if not features:
            return None
        props = features[0].get("properties", {})
        h = props.get("last_obs")
        t = props.get("last_data")
        if h is None:
            return None
        return round(float(h), 3), t


def _parse_obs_time(last_data_str: Optional[str]) -> datetime:
    try:
        obs_time = datetime.fromisoformat(last_data_str)
        if obs_time.tzinfo is None:
            obs_time = obs_time.replace(tzinfo=timezone.utc)
        return obs_time
    except (ValueError, TypeError):
        return datetime.now(timezone.utc)


async def fetch_current_tide(station_id: str) -> Optional[dict]:
    """
    Return current tide observation + predicted tide table.

    Uses the data-driven fitted model when enough observations have been
    accumulated, falling back to published harmonic constants.  In both modes
    the forecast is nudged by the decaying instantaneous residual (surge
    correction) so the first hours of the table track reality closely.
    """
    obs = await fetch_current_observation(station_id)
    if obs is None:
        return None
    current_height, last_data_str = obs
    obs_time = _parse_obs_time(last_data_str)

    #  Choose model 
    fitted_coef, fitted_msl = await _load_fitted_coef(station_id)

    if fitted_coef is not None:
        coef = fitted_coef
        msl = fitted_msl
        model_source = "fitted"
    else:
        coef = _bootstrap_coef()
        model_source = "bootstrap"
        msl = await _estimate_msl_from_recent_obs(station_id, coef, obs_time)
        if msl is None:
            # Last resort: anchor MSL to the single live observation — but
            # clamp it to a physically plausible band around the published
            # mean level.  An out-of-band anchor means the reading is
            # dominated by surge/phase mismatch; keeping DEFAULT_MSL yields a
            # sane table and the residual correction below still makes the
            # near-term forecast track the observation.
            h_at_obs = await _predict_async(coef, obs_time, hours=0.1,
                                            step_min=1)
            msl = current_height - float(h_at_obs[0])
            if abs(msl - DEFAULT_MSL) > MSL_SANITY_BAND:
                logger.warning(
                    "Anchored MSL %.2f m for %s outside sanity band "
                    "(%.2f ± %.2f m); using default MSL.",
                    msl, station_id, DEFAULT_MSL, MSL_SANITY_BAND)
                msl = DEFAULT_MSL

    #  Instantaneous residual (surge correction) 
    h_now = await _predict_async(coef, obs_time, hours=0.1, step_min=1)
    residual = current_height - (msl + float(h_now[0]))
    if abs(residual) > RESIDUAL_MAX:
        logger.warning("Residual %.2f m for %s exceeds plausible surge "
                       "(±%.1f m); clipping.", residual, station_id,
                       RESIDUAL_MAX)
        residual = float(np.clip(residual, -RESIDUAL_MAX, RESIDUAL_MAX))

    #  Direction (from model slope around obs_time, incl, residual has no effect on the derivative sign at t=obs) 
    h_slope = await _predict_async(coef, obs_time - timedelta(minutes=5),
                                   hours=10 / 60, step_min=5)
    dh = float(h_slope[2]) - float(h_slope[0])   # change over 10 minutes
    if dh > _STEADY_THRESHOLD_M_PER_10MIN:
        direction = "rising"
    elif dh < -_STEADY_THRESHOLD_M_PER_10MIN:
        direction = "falling"
    else:
        direction = "steady"

    #  Tide table (36 h, 5-min grid, parabolic-refined extrema) 
    t_start = obs_time.replace(minute=0, second=0, microsecond=0)
    step_min = 5
    h_harm = await _predict_async(coef, t_start, hours=36, step_min=step_min)
    h_total = (msl + h_harm
               + _residual_decay(t_start, len(h_harm), step_min,
                                 residual, obs_time))
    entries = _find_next_extrema(t_start, h_total, after=obs_time,
                                 step_min=step_min)

    return {
        "station_id": station_id,
        "station_name": "",   # filled by caller
        "current_height": current_height,
        "direction": direction,
        "observed_at": last_data_str,
        "entries": entries,
        "timezone": str(LOCAL_TZ),
        "model": model_source,
        "residual_offset": round(residual, 3),
    }


#Scheduler helpers (called from jobs.py) 

async def store_observation(station_id: str) -> bool:
    """
    Fetch the current IH observation and store it in tide_observations.
    Returns True if a new row was inserted, False if already exists or error.
    """
    from app.core.database import AsyncSessionLocal
    from app.models.tide_model import TideObservation
    from sqlalchemy.dialects.postgresql import insert as pg_insert

    obs = await fetch_current_observation(station_id)
    if obs is None:
        return False
    height, observed_at_str = obs

    try:
        observed_at = datetime.fromisoformat(observed_at_str)
        if observed_at.tzinfo is None:
            observed_at = observed_at.replace(tzinfo=timezone.utc)
    except (ValueError, TypeError):
        return False

    async with AsyncSessionLocal() as db:
        stmt = (
            pg_insert(TideObservation)
            .values(station_id=station_id, height=height, observed_at=observed_at)
            .on_conflict_do_nothing(constraint="uq_tide_obs_station_time")
        )
        result = await db.execute(stmt)
        await db.commit()
        return result.rowcount > 0  # type: ignore[attr-defined]


def _constituents_for_span(span_days: float) -> list[str]:
    if span_days >= 400:
        return _CONSTIT_13MO
    if span_days >= 183:
        return _CONSTIT_6MO
    return _CONSTIT_15D


async def fit_model_from_observations(station_id: str) -> Optional[int]:
    """
    Pull all stored observations for station_id, fit a harmonic model with
    utide.solve, and persist the result in tide_model_coef.
    Returns the number of observations used, or None on failure.

    Requires BOTH ≥ MIN_OBS_FOR_FIT rows and a time span of
    ≥ MIN_SPAN_DAYS_FOR_FIT days (row count alone says nothing about
    frequency resolution when the sampling cadence varies).  The constituent
    set grows automatically with the record length.
    """
    import utide
    from app.core.database import AsyncSessionLocal
    from app.models.tide_model import TideObservation, TideModelCoef
    from sqlalchemy import select
    from sqlalchemy.dialects.postgresql import insert as pg_insert

    async with AsyncSessionLocal() as db:
        result = await db.execute(
            select(TideObservation)
            .where(TideObservation.station_id == station_id)
            .order_by(TideObservation.observed_at)
        )
        rows = result.scalars().all()

    if len(rows) < MIN_OBS_FOR_FIT:
        logger.info("Not enough tide observations for %s: %d / %d",
                    station_id, len(rows), MIN_OBS_FOR_FIT)
        return None

    times = []
    for r in rows:
        t = r.observed_at
        if t.tzinfo is None:
            t = t.replace(tzinfo=timezone.utc)
        times.append(t)

    span_days = (times[-1] - times[0]).total_seconds() / 86400.0
    if span_days < MIN_SPAN_DAYS_FOR_FIT:
        logger.info("Tide record for %s too short to fit: %.1f / %.1f days "
                    "(%d rows)", station_id, span_days,
                    MIN_SPAN_DAYS_FOR_FIT, len(rows))
        return None

    t_arr = _to_dt64(times)
    h_arr = np.array([float(r.height) for r in rows], dtype=float)
    constituents = _constituents_for_span(span_days)

    def _solve():
        with warnings.catch_warnings():
            warnings.simplefilter("ignore")
            return utide.solve(
                t_arr, h_arr,
                lat=STATION_LAT,
                constit=constituents,
                method="ols",
                conf_int="linear",
                trend=False,   # sub-annual records: trend term only fits noise
                verbose=False,
            )

    try:
        coef = await asyncio.to_thread(_solve)
    except Exception as e:
        logger.error("utide.solve failed for %s: %s", station_id, e)
        return None

    msl = float(coef.get("mean", 0.0))
    coef["mean"] = 0.0   # MSL lives in its own column, not in the coef

    stored = coef_to_dict(coef)

    async with AsyncSessionLocal() as db:
        stmt = (
            pg_insert(TideModelCoef)
            .values(
                station_id=station_id,
                coef_json=stored,
                msl=msl,
                n_observations=len(rows),
            )
            .on_conflict_do_update(
                index_elements=["station_id"],
                set_=dict(coef_json=stored, msl=msl,
                          n_observations=len(rows),
                          fitted_at=datetime.now(timezone.utc)),
            )
        )
        await db.execute(stmt)
        await db.commit()

    logger.info("Fitted tide model for %s: %d observations over %.1f days, "
                "%d constituents", station_id, len(rows), span_days,
                len(constituents))
    return len(rows)


async def fetch_tide_stations() -> Optional[list]:
    """Return all active tide gauge stations."""
    url = f"{IH_BASE}/collections/tide_obs_stations_nrt/items"
    async with httpx.AsyncClient(timeout=10.0) as client:
        resp = await client.get(url, params={"f": "json", "limit": 200})
        resp.raise_for_status()
        data = resp.json()
        return [
            {"station_id": p.get("eu_lau_code"), "name": p.get("title"),
             "lat": p.get("lat"), "lon": p.get("lon"),
             "last_obs": p.get("last_obs"), "last_data": p.get("last_data")}
            for feat in data.get("features", [])
            for p in [feat.get("properties", {})]
        ]

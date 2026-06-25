"""
Instituto Hidrográfico OGC API Features client.
https://api-features.hidrografico.pt

Tide prediction strategy (self-improving over time):

  Phase 1 — bootstrap (< MIN_OBS observations in DB):
    Use published IH harmonic constants for Setúbal (M2+S2+N2+K1+O1) as a
    starting model, calibrated each request by anchoring the MSL to the live
    real-time observation.  Accuracy: ±15–25 min.

  Phase 2 — data-driven (≥ MIN_OBS observations in DB):
    Run utide.solve on the accumulated real observations to fit a full
    harmonic model directly to this station's data.  The fitted coefficients
    are cached in tide_model_coef and re-fitted weekly by the scheduler.
    Accuracy improves with data: ≥30 days → ±10 min, ≥90 days → ±5 min.
    NOTE: you should run the populate_tide_observations.py script to backfill historical data and trigger

Station IDs (eu_lau_code):
  PT_150505_2  Setúbal - Tróia   (Arrábida beaches)
  PT_151101_1  Sesimbra
"""
import logging
import warnings
from typing import Optional
from datetime import datetime, timedelta, timezone

import httpx
import numpy as np

warnings.filterwarnings("ignore", category=UserWarning)
logger = logging.getLogger(__name__)

IH_BASE = "https://api-features.hidrografico.pt"

# Minimum observations required to switch from published constants to fitted model.
# 360 hours = 15 days of hourly data — enough for stable M2+S2 separation.
MIN_OBS_FOR_FIT = 360

# ── Published fallback constants (IH Tabelas de Marés, Setúbal 07/05/2026 (very low accuracy))
SETUBAL_CONSTITUENTS = {
    "M2": {"A": 1.475, "g": 332.0},
    "S2": {"A": 0.530, "g":   4.0},
    "N2": {"A": 0.259, "g": 305.0},
    "K1": {"A": 0.075, "g":  64.0},
    "O1": {"A": 0.059, "g":  41.0},
}

# Cache the bootstrapped coef in memory (rebuilt once per process, ~1 s)
_BOOTSTRAP_COEF: Optional[dict] = None


def _bootstrap_coef() -> dict:
    global _BOOTSTRAP_COEF
    if _BOOTSTRAP_COEF is not None:
        return _BOOTSTRAP_COEF
    import utide
    t0 = datetime(2024, 1, 1, tzinfo=timezone.utc)
    t_fake = np.array([t0 + timedelta(hours=i) for i in range(500)], dtype="datetime64")
    h_fake = (1.5 * np.cos(2 * np.pi * np.arange(500) / 12.42)
              + 0.5 * np.cos(2 * np.pi * np.arange(500) / 12.0))
    coef = utide.solve(t_fake, h_fake, lat=38.49,
                       constit=list(SETUBAL_CONSTITUENTS.keys()), verbose=False)
    coef["mean"] = 0.0
    coef["slope"] = 0.0
    for i, name in enumerate(coef["name"]):
        if name in SETUBAL_CONSTITUENTS:
            coef["A"][i] = SETUBAL_CONSTITUENTS[name]["A"]
            coef["g"][i] = SETUBAL_CONSTITUENTS[name]["g"]
    _BOOTSTRAP_COEF = coef
    return coef


# Serialise / deserialise utide coef

def coef_to_dict(coef) -> dict:
    """Serialise the utide coef Bunch to a plain dict (for JSONB storage)."""
    return {
        "name": coef["name"].tolist(),
        "A":    coef["A"].tolist(),
        "g":    coef["g"].tolist(),
        "mean": float(coef.get("mean", 0.0)),
    }


def coef_from_dict(d: dict):
    """Deserialise and rebuild a minimal utide coef Bunch from stored dict."""
    coef = _bootstrap_coef()          # get the full structure
    names_stored = d["name"]
    for i, name in enumerate(coef["name"]):
        if name in names_stored:
            idx = names_stored.index(name)
            coef["A"][i] = d["A"][idx]
            coef["g"][i] = d["g"][idx]
    coef["mean"] = d.get("mean", 0.0)
    coef["slope"] = 0.0
    return coef


# Core prediction engine

def _predict_harmonic(coef, t_start: datetime, hours: int = 36, step_min: int = 5) -> np.ndarray:
    """Return the harmonic component (MSL excluded) for a time range."""
    import utide
    n = int(hours * 60 / step_min) + 1
    t_arr = np.array([t_start + timedelta(minutes=i * step_min) for i in range(n)],
                     dtype="datetime64")
    result = utide.reconstruct(t_arr, coef, verbose=False, min_SNR=0, min_PE=0)
    return result.h


def _find_next_extrema(
    t_start: datetime,
    h_harmonic: np.ndarray,
    msl: float,
    after: datetime,
    step_min: int = 5,
    n: int = 4,
) -> list[dict]:
    h = msl + h_harmonic
    after_idx = max(0, int((after - t_start).total_seconds() / 60 / step_min))
    extrema = []
    for i in range(max(1, after_idx), len(h) - 1):
        t_ext = t_start + timedelta(minutes=i * step_min)
        if t_ext <= after:
            continue
        if h[i] > h[i - 1] and h[i] > h[i + 1]:
            extrema.append({"time": t_ext.strftime("%H:%M"),
                             "height": round(float(h[i]), 2), "type": "high"})
        elif h[i] < h[i - 1] and h[i] < h[i + 1]:
            extrema.append({"time": t_ext.strftime("%H:%M"),
                             "height": round(float(h[i]), 2), "type": "low"})
        if len(extrema) == n:
            break
    return extrema


async def _load_fitted_coef(station_id: str):
    """Load the data-driven fitted coef from the DB (None if not yet available)."""
    from app.core.database import AsyncSessionLocal
    from app.models.tide_model import TideModelCoef
    from sqlalchemy import select
    try:
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


# IH real-time API

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


async def fetch_current_tide(station_id: str) -> Optional[dict]:
    """
    Return current tide observation + predicted tide table.

    Uses the data-driven fitted model when enough observations have been
    accumulated (≥ MIN_OBS_FOR_FIT), falling back to published harmonic
    constants calibrated to the live observation.
    """
    obs = await fetch_current_observation(station_id)
    if obs is None:
        return None
    current_height, last_data_str = obs

    try:
        obs_time = datetime.fromisoformat(last_data_str)
        if obs_time.tzinfo is None:
            obs_time = obs_time.replace(tzinfo=timezone.utc)
    except (ValueError, TypeError):
        obs_time = datetime.now(timezone.utc)

    # Choose model
    fitted_coef, fitted_msl = await _load_fitted_coef(station_id)

    if fitted_coef is not None:
        coef = fitted_coef
        msl = fitted_msl
        model_source = "fitted"
    else:
        coef = _bootstrap_coef()
        # Calibrate MSL to match current observation
        h_at_obs = _predict_harmonic(coef, obs_time, hours=1, step_min=1)
        msl = current_height - float(h_at_obs[0])
        model_source = "bootstrap"

    # Direction
    h_5min = _predict_harmonic(coef, obs_time - timedelta(minutes=5), hours=1, step_min=5)
    dh = float(h_5min[1]) - float(h_5min[0])
    direction = "rising" if dh > 0.004 else "falling" if dh < -0.004 else "steady"

    # Tide table
    t_start = obs_time.replace(minute=0, second=0, microsecond=0)
    h_harm = _predict_harmonic(coef, t_start, hours=36, step_min=5)
    entries = _find_next_extrema(t_start, h_harm, msl, after=obs_time)

    return {
        "station_id": station_id,
        "station_name": "",   # filled by caller
        "current_height": current_height,
        "direction": direction,
        "observed_at": last_data_str,
        "entries": entries,
        "model": model_source,
    }


# Scheduler helpers (called from jobs.py)

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


async def fit_model_from_observations(station_id: str) -> Optional[int]:
    """
    Pull all stored observations for station_id, fit a harmonic model with
    utide.solve, and persist the result in tide_model_coef.
    Returns the number of observations used, or None on failure.
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

    t_arr = np.array([r.observed_at for r in rows], dtype="datetime64")
    h_arr = np.array([r.height for r in rows], dtype=float)

    try:
        coef = utide.solve(
            t_arr, h_arr,
            lat=38.49,
            constit=["M2", "S2", "N2", "K1", "O1", "M4", "MS4"],
            method="ols",
            conf_int="MC",
            verbose=False,
        )
    except Exception as e:
        logger.error("utide.solve failed for %s: %s", station_id, e)
        return None

    msl = float(coef.get("mean", 0.0))
    coef["mean"] = 0.0   # bake MSL into separate field, not the coef

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

    logger.info("Fitted tide model for %s using %d observations", station_id, len(rows))
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

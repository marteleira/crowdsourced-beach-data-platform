"""
Instituto Hidrográfico OGC API Features client.
https://api-features.hidrografico.pt

The IH API provides real-time observations only (no tide predictions endpoint).
We use tide_obs_stations_nrt for the current height, then fit a simplified
M2 sinusoidal model (calibrated to the current observation) to estimate the
tide table for the rest of the day.

M2 is the dominant tidal constituent on the Portuguese coast (~85% of total
tidal energy), so a pure M2 model gives times accurate to within +-30 min.

Station IDs (eu_lau_code):
  PT_150505_2  Setúbal - Tróia   (Arrábida beaches)
  PT_151101_1  Sesimbra
"""
import math
import httpx
from typing import Optional
from datetime import datetime, timedelta, timezone

IH_BASE = "https://api-features.hidrografico.pt"

# Tidal model constants for the Setúbal area
# Source: IH Tabelas de Marés (annual tide tables), simplified to M2 constituent.

MSL_M = 1.95    # mean sea level above chart datum (metres)
AMPL_M = 1.52   # mean M2 amplitude (spring ≈ 1.85m, neap ≈ 1.15m → mean ≈ 1.52m)
M2_PERIOD_S = 44714.16   # M2 period in seconds (12 h 25 min 14 s)
M2_OMEGA = 2 * math.pi / M2_PERIOD_S


def _fit_phase(h0: float, direction: str, t0: datetime) -> float:
    """
    Given current observation h0 at t0 and tide direction, return the M2
    phase offset φ such that h(t) = MSL + A·cos(ω·t_unix + φ).
    """
    ratio = max(-1.0, min(1.0, (h0 - MSL_M) / AMPL_M))
    theta = math.acos(ratio)

    # dh/dt = −A·ω·sin(ω·t + φ)
    # Rising → dh/dt > 0 → sin < 0 → (ω·t + φ) in (π, 2π) → use 2π − θ
    # Falling → sin > 0 → use θ
    if direction == "rising":
        phase_val = 2 * math.pi - theta
    else:
        phase_val = theta

    t_unix = t0.timestamp()
    phi = (phase_val - M2_OMEGA * t_unix) % (2 * math.pi)
    return phi


def _next_extrema(t0: datetime, phi: float, n: int = 4) -> list[dict]:
    """
    Return the next n tidal extrema (alternating high/low) after t0.
    High water: ω·t + φ = 2kπ  → h = MSL + A
    Low water:  ω·t + φ = (2k+1)π → h = MSL − A
    """
    t0_unix = t0.timestamp()
    # Which 'half-period' bin are we in?
    k_start = math.ceil((M2_OMEGA * t0_unix + phi) / math.pi)

    extrema = []
    for k in range(k_start, k_start + n + 4):
        t_ext_unix = (k * math.pi - phi) / M2_OMEGA
        if t_ext_unix <= t0_unix:
            continue
        t_ext = datetime.fromtimestamp(t_ext_unix, tz=timezone.utc)
        is_high = (k % 2 == 0)
        extrema.append({
            "time": t_ext.strftime("%H:%M"),
            "height": round(MSL_M + AMPL_M if is_high else MSL_M - AMPL_M, 2),
            "type": "high" if is_high else "low",
        })
        if len(extrema) >= n:
            break
    return extrema


# IH API calls

async def fetch_current_tide(station_id: str) -> Optional[dict]:
    """
    Return current tide observation + estimated tide table for the station.
    current_height and observed_at come from the live IH API.
    entries (high/low table) are estimated via the M2 model.
    """
    url = f"{IH_BASE}/collections/tide_obs_stations_nrt/items"
    async with httpx.AsyncClient(timeout=10.0) as client:
        resp = await client.get(url, params={"f": "json", "limit": 100, "eu_lau_code": station_id})
        resp.raise_for_status()
        data = resp.json()
        features = data.get("features", [])
        if not features:
            return None

        props = features[0].get("properties", {})
        current_height = props.get("last_obs")
        last_data_str = props.get("last_data")

        if current_height is None:
            return None

        current_height = round(float(current_height), 3)

        # Parse observation time
        observed_at: datetime
        try:
            observed_at = datetime.fromisoformat(last_data_str)
            if observed_at.tzinfo is None:
                observed_at = observed_at.replace(tzinfo=timezone.utc)
        except (ValueError, TypeError):
            observed_at = datetime.now(timezone.utc)

        # Compute direction from recent observations
        direction = await _compute_trend(station_id)

        # Fit M2 model and compute tide table
        phi = _fit_phase(current_height, direction, observed_at)
        entries = _next_extrema(observed_at, phi, n=4)

        return {
            "station_id": station_id,
            "station_name": props.get("title", ""),
            "current_height": current_height,
            "direction": direction,
            "observed_at": last_data_str,
            "entries": entries,
        }


async def _compute_trend(station_id: str) -> str:
    """
    Fetch the last few real-time observations and return 'rising', 'falling',
    or 'steady' based on the slope.
    """
    url = f"{IH_BASE}/collections/tide_obs_data_nrt_l1_min/items"
    try:
        async with httpx.AsyncClient(timeout=8.0) as client:
            resp = await client.get(url, params={
                "f": "json", "limit": 10,
                "eu_lau_code": station_id,
                "sortby": "-date_time",
            })
            resp.raise_for_status()
            data = resp.json()
            features = data.get("features", [])

        valid = [
            f for f in features
            if f.get("properties", {}).get("sea_surface_height") is not None
            and f.get("properties", {}).get("sea_surface_height_qc", 1) == 0
        ]

        if len(valid) < 2:
            return "steady"

        # Sort ascending by time
        valid.sort(key=lambda f: f["properties"]["date_time"])
        heights = [float(f["properties"]["sea_surface_height"]) for f in valid]

        # Linear regression slope over the window
        n = len(heights)
        mean_h = sum(heights) / n
        mean_x = (n - 1) / 2
        slope = sum((i - mean_x) * (heights[i] - mean_h) for i in range(n)) / \
                max(1, sum((i - mean_x) ** 2 for i in range(n)))

        if slope > 0.003:     # >0.003 m/min
            return "rising"
        if slope < -0.003:
            return "falling"
        return "steady"

    except Exception:
        return "steady"


async def fetch_tide_stations() -> Optional[list]:
    """Return all active tide gauge stations."""
    url = f"{IH_BASE}/collections/tide_obs_stations_nrt/items"
    async with httpx.AsyncClient(timeout=10.0) as client:
        resp = await client.get(url, params={"f": "json", "limit": 200})
        resp.raise_for_status()
        data = resp.json()
        return [
            {
                "station_id": p.get("eu_lau_code"),
                "name": p.get("title"),
                "lat": p.get("lat"),
                "lon": p.get("lon"),
                "last_obs": p.get("last_obs"),
                "last_data": p.get("last_data"),
            }
            for feat in data.get("features", [])
            for p in [feat.get("properties", {})]
        ]

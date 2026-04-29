from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime


class BeachSummary(BaseModel):
    id: int
    slug: str
    name: str
    lat: float
    lon: float
    flag_color: str
    flag_confidence: float
    occupancy_level: str              # low | medium | high | unknown
    active_alerts_count: int
    activity_level: str               # low | normal | high
    activity_label: Optional[str] = None
    distance_km: Optional[float] = None         # only when lat/lon provided
    recommendation_score: Optional[float] = None

    model_config = {"from_attributes": True}


class BeachDetail(BaseModel):
    id: int
    slug: str
    name: str
    lat: float
    lon: float
    has_capacity_data: bool
    max_capacity: Optional[int] = None
    flags_available: bool
    nearby_stop_ids: List[str] = []

    model_config = {"from_attributes": True}


class WeatherForecast(BaseModel):
    date: str
    min_temp: Optional[float] = None
    max_temp: Optional[float] = None
    precipitation_prob: Optional[float] = None
    wind_speed: Optional[float] = None
    wind_direction: Optional[str] = None
    weather_type_id: Optional[int] = None
    weather_type_desc: Optional[str] = None
    data_source: str = "live"
    snapshot_at: Optional[datetime] = None


class SeaForecast(BaseModel):
    date: str
    wave_height_max: Optional[float] = None
    wave_height_min: Optional[float] = None
    wave_period_max: Optional[float] = None
    sea_surface_temp: Optional[float] = None
    data_source: str = "live"
    snapshot_at: Optional[datetime] = None


class TideEntry(BaseModel):
    time: str
    height: float
    type: Optional[str] = None   # high | low


class TidesResponse(BaseModel):
    station_id: Optional[str] = None
    date: str
    entries: List[TideEntry] = []
    data_source: str = "live"
    snapshot_at: Optional[datetime] = None


class WaterQualityResponse(BaseModel):
    station_id: Optional[str] = None
    classification: Optional[str] = None   # Excelente | Boa | Suficiente | Má
    sampled_at: Optional[str] = None
    parameters: Optional[dict] = None
    data_source: str = "live"
    snapshot_at: Optional[datetime] = None


class TransportStop(BaseModel):
    stop_id: str
    stop_name: str
    lat: Optional[float] = None
    lon: Optional[float] = None


class TransportTrip(BaseModel):
    route_id: str
    route_short_name: str
    trip_headsign: Optional[str] = None
    stop_id: str
    departure_time: str


class TransportResponse(BaseModel):
    stops: List[TransportStop] = []
    next_departures: List[TransportTrip] = []
    data_source: str = "live"
    snapshot_at: Optional[datetime] = None


class OccupancyData(BaseModel):
    level: str                    # low | medium | high | unknown
    user_count: int
    is_estimate: bool = True
    last_updated: datetime


class ActiveAlert(BaseModel):
    id: int
    type: str
    severity: Optional[int] = None
    upvotes: int
    downvotes: int
    created_at: datetime
    expires_at: datetime
    note: Optional[str] = None
    verified: bool                # net upvotes >= 3
    activity_label: Optional[str] = None


class BeachStatusResponse(BaseModel):
    flag_color: str
    flag_confidence: float
    activity_level: str
    activity_label: Optional[str] = None
    occupancy: OccupancyData


class BeachFullResponse(BaseModel):
    beach: BeachDetail
    status: BeachStatusResponse
    active_alerts: List[ActiveAlert] = []
    weather: Optional[List[WeatherForecast]] = None
    sea: Optional[List[SeaForecast]] = None
    tides: Optional[TidesResponse] = None
    water_quality: Optional[WaterQualityResponse] = None
    transport: Optional[TransportResponse] = None

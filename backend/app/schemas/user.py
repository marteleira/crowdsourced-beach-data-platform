from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime


class ReputationEventOut(BaseModel):
    event: str
    delta: int
    reason: Optional[str] = None
    created_at: datetime


class UserProfile(BaseModel):
    id: str
    display_name: Optional[str] = None
    reputation: int
    level: str         # novo | regular | contribuidor | veterano
    is_anonymous: bool
    streak: int = 0
    achievements: List[dict] = []
    stats: dict        # total_reports, confirmed_reports, false_reports, accuracy_rate
    recent_events: List[ReputationEventOut] = []

    model_config = {"from_attributes": True}


class HeartbeatRequest(BaseModel):
    lat: float
    lon: float


class HeartbeatResponse(BaseModel):
    status: str
    beach_id: int
    occupancy_level: str
    user_count: int

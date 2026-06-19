from pydantic import BaseModel, EmailStr, field_validator
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
    email: Optional[str] = None
    has_password: bool = False
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


class UpdateProfileRequest(BaseModel):
    display_name: Optional[str] = None
    email: Optional[EmailStr] = None
    current_password: Optional[str] = None  # required when changing email

    @field_validator("display_name")
    @classmethod
    def name_not_empty(cls, v: Optional[str]) -> Optional[str]:
        if v is not None:
            v = v.strip()
            if not (1 <= len(v) <= 50):
                raise ValueError("Nome deve ter entre 1 e 50 caracteres")
        return v


class ChangePasswordRequest(BaseModel):
    current_password: str
    new_password: str

    @field_validator("new_password")
    @classmethod
    def password_min_length(cls, v: str) -> str:
        if len(v) < 8:
            raise ValueError("A password deve ter pelo menos 8 caracteres")
        return v

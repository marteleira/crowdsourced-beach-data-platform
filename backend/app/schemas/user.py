from datetime import datetime
from typing import List, Optional

from pydantic import BaseModel, EmailStr, field_validator


class ReputationEventOut(BaseModel):
    event: str
    delta: int
    params: Optional[dict] = None  # structured params for frontend l10n formatting
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
    avatar_id: Optional[str] = None
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


_VALID_AVATAR_IDS = {
    "wave", "surfer", "shell", "anchor", "dolphin",
    "crab", "sailboat", "compass", "fish", "shark",
    "lighthouse", "star",
}

class UpdateProfileRequest(BaseModel):
    display_name: Optional[str] = None
    email: Optional[EmailStr] = None
    current_password: Optional[str] = None  # required when changing email
    avatar_id: Optional[str] = None         # None = keep current; "default" = clear

    @field_validator("display_name")
    @classmethod
    def name_not_empty(cls, v: Optional[str]) -> Optional[str]:
        if v is not None:
            v = v.strip()
            if not (1 <= len(v) <= 50):
                raise ValueError("Nome deve ter entre 1 e 50 caracteres")
        return v

    @field_validator("avatar_id")
    @classmethod
    def avatar_valid(cls, v: Optional[str]) -> Optional[str]:
        if v is not None and v != "default" and v not in _VALID_AVATAR_IDS:
            raise ValueError(f"Avatar inválido: {v}")
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

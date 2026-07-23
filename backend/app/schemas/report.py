from pydantic import BaseModel, field_validator
from typing import Optional, List, Literal
from datetime import datetime

from app.schemas.errors import CodedValueError

VALID_REPORT_TYPES = ("jellyfish", "strong_current", "pollution", "rough_sea", "other_alert")


class ReportCreate(BaseModel):
    type: str
    severity: int = 2
    note: Optional[str] = None
    lat: Optional[float] = None
    lon: Optional[float] = None

    @field_validator("type")
    @classmethod
    def type_must_be_valid(cls, v: str) -> str:
        if v not in VALID_REPORT_TYPES:
            raise CodedValueError("invalid_report_type", valid_types=", ".join(VALID_REPORT_TYPES))
        return v

    @field_validator("severity")
    @classmethod
    def severity_range(cls, v: int) -> int:
        if not 1 <= v <= 3:
            raise CodedValueError("invalid_severity")
        return v


class ReportResponse(BaseModel):
    id: int
    beach_id: int
    type: str
    severity: Optional[int] = None
    note: Optional[str] = None
    upvotes: int
    downvotes: int
    created_at: datetime
    expires_at: datetime
    is_expired: bool
    verified: bool
    my_vote: Optional[int] = None    # 1 | -1 | None (caller's vote if authenticated)
    activity_label: Optional[str] = None

    model_config = {"from_attributes": True}


class VoteRequest(BaseModel):
    vote: Literal["up", "down"]


class ReportListResponse(BaseModel):
    reports: List[ReportResponse]
    total: int

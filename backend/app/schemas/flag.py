from pydantic import BaseModel
from typing import Optional, Literal
from datetime import datetime

VALID_FLAG_COLORS = ("green", "yellow", "red", "purple", "unknown")


class FlagProposalRequest(BaseModel):
    color: Literal["green", "yellow", "red", "purple"]


class FlagProposalResponse(BaseModel):
    proposal_id: int
    status: str
    code: str
    message: str


class FlagConfirmRequest(BaseModel):
    response: Literal["yes", "no", "unsure"]


class FlagConfirmResponse(BaseModel):
    status: str
    beach_id: int
    new_confidence: float


class BeachFlagStatus(BaseModel):
    flag_color: str
    flag_confidence: float
    flag_source: str
    updated_at: datetime
    activity_label: Optional[str] = None

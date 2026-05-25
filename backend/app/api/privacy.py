import json
from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy import select, delete, update
from sqlalchemy.ext.asyncio import AsyncSession
from typing import Optional, Literal

from app.core.database import get_db
from app.core.deps import require_user
from app.models.user import User, ReputationEvent
from app.models.report import Report
from app.models.user_extended import effective_privacy_settings

router = APIRouter(prefix="/users/me", tags=["privacy"])


class PrivacySettingsPatch(BaseModel):
    location_accuracy: Optional[Literal["exact", "approximate", "none"]] = None
    name_public: Optional[bool] = None
    avatar_public: Optional[bool] = None
    share_usage_data: Optional[bool] = None
    share_presence: Optional[bool] = None


class DeleteAccountRequest(BaseModel):
    confirmation: str   # must equal "APAGAR"


@router.get("/privacy-settings")
async def get_privacy_settings(
    user: User = Depends(require_user),
    db: AsyncSession = Depends(get_db),
):
    return effective_privacy_settings(user)


@router.patch("/privacy-settings")
async def update_privacy_settings(
    body: PrivacySettingsPatch,
    user: User = Depends(require_user),
    db: AsyncSession = Depends(get_db),
):
    current = effective_privacy_settings(user)
    current.update(body.model_dump(exclude_none=True))
    user.privacy_settings = current
    db.add(user)
    await db.commit()
    return current


@router.get("/data-export")
async def export_data(
    user: User = Depends(require_user),
    db: AsyncSession = Depends(get_db),
):
    """Return a JSON export of all data owned by the user."""
    reports_r = await db.execute(select(Report).where(Report.user_id == user.id))
    reports = reports_r.scalars().all()

    events_r = await db.execute(
        select(ReputationEvent).where(ReputationEvent.user_id == user.id)
    )
    events = events_r.scalars().all()

    return {
        "exported_at": datetime.now(timezone.utc).isoformat(),
        "user": {
            "id": str(user.id),
            "email": user.email,
            "display_name": user.display_name,
            "reputation": user.reputation,
            "created_at": user.created_at.isoformat() if user.created_at else None,
        },
        "reports": [
            {
                "id": r.id,
                "beach_id": r.beach_id,
                "type": r.type,
                "severity": r.severity,
                "note": r.note,
                "upvotes": r.upvotes,
                "downvotes": r.downvotes,
                "created_at": r.created_at.isoformat() if r.created_at else None,
            }
            for r in reports
        ],
        "reputation_events": [
            {
                "event": e.event,
                "delta": e.delta,
                "reason": e.reason,
                "created_at": e.created_at.isoformat() if e.created_at else None,
            }
            for e in events
        ],
    }


@router.delete("/reports", status_code=204)
async def delete_all_reports(
    user: User = Depends(require_user),
    db: AsyncSession = Depends(get_db),
):
    """Soft-delete all reports by this user."""
    await db.execute(
        update(Report)
        .where(Report.user_id == user.id)
        .values(is_expired=True)
    )
    await db.execute(
        update(User)
        .where(User.id == user.id)
        .values(total_reports=0, confirmed_reports=0, false_reports=0)
    )
    await db.commit()


@router.delete("", status_code=204)
async def delete_account(
    body: DeleteAccountRequest,
    user: User = Depends(require_user),
    db: AsyncSession = Depends(get_db),
):
    if body.confirmation != "APAGAR":
        raise HTTPException(400, "Confirmação inválida — escreve 'APAGAR' para confirmar")

    # Soft-delete reports first, then hard-delete the user (cascades handle the rest)
    await db.execute(
        update(Report).where(Report.user_id == user.id).values(is_expired=True)
    )
    await db.delete(user)
    await db.commit()

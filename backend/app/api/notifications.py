from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select, delete
from sqlalchemy.ext.asyncio import AsyncSession
from pydantic import BaseModel
from typing import Optional, Literal
from app.core.database import get_db
from app.core.deps import require_user
from app.models.user import User
from app.core.messages import Msg
from app.models.user_extended import PushToken, effective_notification_settings

router = APIRouter(tags=["notifications"])


class NotificationSettingsPatch(BaseModel):
    global_enabled: Optional[bool] = None
    checkin_alerts: Optional[bool] = None
    proximity_alerts: Optional[bool] = None
    proximity_radius_meters: Optional[int] = None
    favourite_alerts_enabled: Optional[bool] = None
    favourite_alerts_per_beach: Optional[dict] = None
    alert_types: Optional[dict] = None
    min_severity: Optional[Literal[1, 2, 3]] = None
    flag_change_alerts: Optional[bool] = None
    tide_alerts: Optional[bool] = None
    report_confirmed: Optional[bool] = None
    report_rejected: Optional[bool] = None
    quiet_hours_enabled: Optional[bool] = None
    quiet_hours_start: Optional[str] = None
    quiet_hours_end: Optional[str] = None


class PushTokenRequest(BaseModel):
    token: str
    platform: Literal["ios", "android"]


@router.get("/users/me/notification-settings")
async def get_notification_settings(
    user: User = Depends(require_user),
    db: AsyncSession = Depends(get_db),
):
    return effective_notification_settings(user)


@router.patch("/users/me/notification-settings")
async def update_notification_settings(
    body: NotificationSettingsPatch,
    user: User = Depends(require_user),
    db: AsyncSession = Depends(get_db),
):
    current = effective_notification_settings(user)
    patch = body.model_dump(exclude_none=True)
    current.update(patch)

    user.notification_settings = current
    db.add(user)
    await db.commit()
    return current


@router.post("/notifications/register-token", status_code=201)
async def register_push_token(
    body: PushTokenRequest,
    user: User = Depends(require_user),
    db: AsyncSession = Depends(get_db),
):
    existing = await db.execute(select(PushToken).where(PushToken.token == body.token))
    token_row = existing.scalar_one_or_none()

    if token_row:
        # Re-assign to current user (device may have been signed out and back in)
        token_row.user_id = user.id
        token_row.platform = body.platform
    else:
        db.add(PushToken(user_id=user.id, token=body.token, platform=body.platform))

    await db.commit()
    return {"status": "registered"}


@router.delete("/notifications/token/{token}", status_code=204)
async def remove_push_token(
    token: str,
    user: User = Depends(require_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        delete(PushToken).where(PushToken.token == token, PushToken.user_id == user.id)
    )
    if result.rowcount == 0:  # type: ignore[attr-defined]
        raise HTTPException(404, Msg.TOKEN_NOT_FOUND)
    await db.commit()

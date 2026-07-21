from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.deps import require_user
from app.core.messages import Msg
from app.core.security import (
    generate_verification_code,
    hash_password,
    verify_password,
)
from app.core.utils import now_utc
from app.models.user import RefreshToken, ReputationEvent, User
from app.models.user_extended import UserAchievement
from app.schemas.user import (
    ChangePasswordRequest,
    ReputationEventOut,
    UpdateProfileRequest,
    UserProfile,
)
from app.services.achievements import get_all_achievements_status
from app.services.email import send_verification_email
from app.services.reputation import reputation_level

router = APIRouter(prefix="/users", tags=["users"])


# Profile builder (shared by GET and PATCH)

async def _build_profile(user: User, db: AsyncSession) -> UserProfile:
    result = await db.execute(
        select(ReputationEvent)
        .where(ReputationEvent.user_id == user.id)
        .order_by(ReputationEvent.created_at.desc())
        .limit(10)
    )
    recent_events = result.scalars().all()

    ach_r = await db.execute(
        select(UserAchievement.achievement_id).where(UserAchievement.user_id == user.id)
    )
    earned_ids = {row[0] for row in ach_r.all()}

    total = user.total_reports
    accuracy = round((total - user.false_reports) / total, 2) if total > 0 else 0.0

    return UserProfile(
        id=str(user.id),
        display_name=user.display_name,
        email=user.email,
        has_password=bool(user.password_hash),
        reputation=user.reputation,
        level=reputation_level(user.reputation),
        is_anonymous=user.is_anonymous,
        streak=user.streak or 0,
        avatar_id=user.avatar_id,
        achievements=get_all_achievements_status(user, earned_ids),
        stats={
            "total_reports": total,
            "confirmed_reports": user.confirmed_reports,
            "false_reports": user.false_reports,
            "accuracy_rate": accuracy,
        },
        recent_events=[
            ReputationEventOut(
                event=e.event,
                delta=e.delta,
                params=e.params,
                created_at=e.created_at,
            )
            for e in recent_events
        ],
    )


async def _send_new_verification(user: User, db: AsyncSession) -> None:
    code, code_hash = generate_verification_code()
    from datetime import timedelta

    from app.core.config import settings
    user.email_verification_code_hash = code_hash
    user.email_verification_expires_at = (
        now_utc()
        + timedelta(minutes=settings.EMAIL_VERIFICATION_EXPIRE_MINUTES)
    )
    await db.flush()
    await send_verification_email(user.email, code)


#  Endpoints

@router.get("/me", response_model=UserProfile)
async def get_profile(
    user: User = Depends(require_user),
    db: AsyncSession = Depends(get_db),
):
    return await _build_profile(user, db)


@router.patch("/me", response_model=UserProfile)
async def update_profile(
    body: UpdateProfileRequest,
    user: User = Depends(require_user),
    db: AsyncSession = Depends(get_db),
):
    if user.is_anonymous:
        raise HTTPException(403, {"code": "guest_cannot_edit_profile", "message": Msg.GUESTS_CANNOT_EDIT_PROFILE})

    if body.display_name is None and body.email is None and body.avatar_id is None:
        raise HTTPException(400, Msg.NO_CHANGES_PROVIDED)

    if body.display_name is not None:
        user.display_name = body.display_name

    if body.avatar_id is not None:
        user.avatar_id = None if body.avatar_id == "default" else body.avatar_id

    if body.email is not None and body.email != user.email:
        # Google-only accounts cannot change email
        if not user.password_hash:
            raise HTTPException(400, Msg.GOOGLE_CANNOT_CHANGE_EMAIL)

        if not body.current_password:
            raise HTTPException(400, Msg.PASSWORD_REQUIRED_FOR_EMAIL_CHANGE)

        if not verify_password(body.current_password, user.password_hash):
            raise HTTPException(401, Msg.PASSWORD_INCORRECT)

        conflict = await db.execute(
            select(User).where(User.email == body.email, User.id != user.id)
        )
        if conflict.scalar_one_or_none():
            raise HTTPException(409, {"code": "email_in_use", "message": Msg.EMAIL_IN_USE})

        user.email = body.email
        user.is_email_verified = False
        await _send_new_verification(user, db)

    await db.commit()
    await db.refresh(user)
    return await _build_profile(user, db)


@router.post("/me/change-password")
async def change_password(
    body: ChangePasswordRequest,
    user: User = Depends(require_user),
    db: AsyncSession = Depends(get_db),
):
    if user.is_anonymous:
        raise HTTPException(403, {"code": "guest_cannot_change_password", "message": Msg.GUESTS_CANNOT_CHANGE_PASSWORD})

    if not user.password_hash:
        raise HTTPException(400, Msg.GOOGLE_NO_PASSWORD)

    if not verify_password(body.current_password, user.password_hash):
        raise HTTPException(401, Msg.PASSWORD_INCORRECT)

    if body.new_password == body.current_password:
        raise HTTPException(400, Msg.PASSWORD_SAME_AS_CURRENT)

    user.password_hash = hash_password(body.new_password)

    # Revoke all active refresh tokens → forces re-login on every device
    now = now_utc()
    await db.execute(
        update(RefreshToken)
        .where(RefreshToken.user_id == user.id, RefreshToken.revoked_at.is_(None))
        .values(revoked_at=now)
    )
    await db.commit()
    return {"status": "ok"}


@router.get("/me/reputation-history")
async def get_reputation_history(
    limit: int = 20,
    offset: int = 0,
    user: User = Depends(require_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(ReputationEvent)
        .where(ReputationEvent.user_id == user.id)
        .order_by(ReputationEvent.created_at.desc())
        .limit(limit)
        .offset(offset)
    )
    events = result.scalars().all()
    return [
        ReputationEventOut(
            event=e.event,
            delta=e.delta,
            params=e.params,
            created_at=e.created_at,
        )
        for e in events
    ]

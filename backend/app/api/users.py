from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.deps import require_user
from app.models.user import User, ReputationEvent
from app.models.user_extended import UserAchievement
from app.schemas.user import UserProfile, ReputationEventOut
from app.services.reputation import reputation_level
from app.services.achievements import ALL_ACHIEVEMENTS, get_all_achievements_status

router = APIRouter(prefix="/users", tags=["users"])


@router.get("/me", response_model=UserProfile)
async def get_profile(
    user: User = Depends(require_user),
    db: AsyncSession = Depends(get_db),
):
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
    accuracy = round((total - user.false_reports) / total) if total > 0.0 else 0.0

    return UserProfile(
        id=str(user.id),
        display_name=user.display_name,
        reputation=user.reputation,
        level=reputation_level(user.reputation),
        is_anonymous=user.is_anonymous,
        streak=user.streak or 0,
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
                reason=e.reason,
                created_at=e.created_at,
            )
            for e in recent_events
        ],
    )


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
            reason=e.reason,
            created_at=e.created_at,
        )
        for e in events
    ]

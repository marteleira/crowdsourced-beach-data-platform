"""
Achievement definitions and unlock logic.

Achievements are checked when reputation events are processed.
Each definition has: id, emoji, label, and a predicate that receives the User.
"""
from datetime import date, timedelta
from typing import List
from dataclasses import dataclass

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.user import User
from app.models.user_extended import UserAchievement


@dataclass
class AchievementDef:
    id: str
    emoji: str
    label: str

    def earned(self, user: User) -> bool:
        raise NotImplementedError


class _ThresholdAchievement(AchievementDef):
    def __init__(self, id, emoji, label, field: str, threshold: int):
        super().__init__(id, emoji, label)
        self._field = field
        self._threshold = threshold

    def earned(self, user: User) -> bool:
        return (getattr(user, self._field, 0) or 0) >= self._threshold


ALL_ACHIEVEMENTS: List[AchievementDef] = [
    _ThresholdAchievement("first_report",  "🌊", "First Wave",    "total_reports",     1),
    _ThresholdAchievement("tide_watcher",  "🔭", "Tide Watcher",  "total_reports",     3),
    _ThresholdAchievement("10_reports",    "📋", "10 Reports",    "total_reports",     10),
    _ThresholdAchievement("accurate",      "🎯", "Accurate",      "confirmed_reports", 5),
    _ThresholdAchievement("streak_10",     "🔥", "10-day Streak", "streak",            10),
    _ThresholdAchievement("regular",       "🐚", "Regular",       "reputation",        10),
    _ThresholdAchievement("contributor",   "🤝", "Contributor",   "reputation",        50),
    _ThresholdAchievement("veteran",       "🏄", "Veteran",       "reputation",        150),
]


async def unlock_new_achievements(db: AsyncSession, user: User) -> List[str]:
    """Check all achievement definitions and unlock any newly earned ones. Returns new IDs."""
    existing_r = await db.execute(
        select(UserAchievement.achievement_id).where(UserAchievement.user_id == user.id)
    )
    already_earned = {row[0] for row in existing_r.all()}

    newly_unlocked = []
    for ach in ALL_ACHIEVEMENTS:
        if ach.id in already_earned:
            continue
        if ach.earned(user):
            db.add(UserAchievement(user_id=user.id, achievement_id=ach.id))
            newly_unlocked.append(ach.id)

    if newly_unlocked:
        await db.commit()

    return newly_unlocked


def get_all_achievements_status(user: User, earned_ids: set) -> List[dict]:
    return [
        {
            "id": a.id,
            "emoji": a.emoji,
            "label": a.label,
            "earned": a.earned(user) or a.id in earned_ids,
        }
        for a in ALL_ACHIEVEMENTS
    ]


async def update_streak(db: AsyncSession, user: User) -> None:
    """Increment streak if last contribution was yesterday, reset if more than 1 day ago."""
    today = date.today()
    last = user.last_contribution_date

    if last == today:
        return

    if last is None or last < today - timedelta(days=1):
        user.streak = 1
    else:
        user.streak = (user.streak or 0) + 1

    user.last_contribution_date = today
    db.add(user)
    await db.commit()

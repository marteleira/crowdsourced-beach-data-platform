"""
Additional user-related models:
  UserFavourite   — ordered list of favourite beaches per user
  PushToken       — FCM/APNs device tokens for push notifications
  UserAchievement — unlocked achievements
"""
from datetime import datetime
import uuid
from sqlalchemy import Integer, Text, TIMESTAMP, ForeignKey, UniqueConstraint, Index
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.sql import func
from app.core.database import Base

# ── Default settings blobs ────────────────────────────────────────────────────

DEFAULT_NOTIFICATION_SETTINGS = {
    "global_enabled": True,
    "checkin_alerts": True,
    "proximity_alerts": True,
    "proximity_radius_meters": 500,
    "favourite_alerts_enabled": True,
    "favourite_alerts_per_beach": {},
    "alert_types": {
        "jellyfish": True,
        "strong_current": True,
        "pollution": True,
        "rough_sea": True,
    },
    "min_severity": 1,
    "flag_change_alerts": True,
    "tide_alerts": True,
    "report_confirmed": True,
    "report_rejected": True,
    "quiet_hours_enabled": False,
    "quiet_hours_start": "22:00",
    "quiet_hours_end": "07:00",
}

DEFAULT_PRIVACY_SETTINGS = {
    "name_public": True,
    "avatar_public": True,
    "share_usage_data": True, #This settings does nothing yet
    "share_presence": False,              # show on map (opt-in, not opt-out)
}


def effective_notification_settings(user) -> dict:
    base = dict(DEFAULT_NOTIFICATION_SETTINGS)
    if user.notification_settings:
        base.update(user.notification_settings)
    return base


def effective_privacy_settings(user) -> dict:
    base = dict(DEFAULT_PRIVACY_SETTINGS)
    if user.privacy_settings:
        base.update(user.privacy_settings)
    return base


class UserFavourite(Base):
    __tablename__ = "user_favourites"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    user_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    beach_id: Mapped[int] = mapped_column(Integer, ForeignKey("beaches.id", ondelete="CASCADE"), nullable=False)
    position: Mapped[int] = mapped_column(Integer, default=0)  # ordering index
    created_at: Mapped[datetime] = mapped_column(TIMESTAMP(timezone=True), server_default=func.now())

    __table_args__ = (
        UniqueConstraint("user_id", "beach_id", name="uq_user_favourite_beach"),
        Index("ix_user_favourites_user", "user_id", "position"),
    )


class PushToken(Base):
    __tablename__ = "push_tokens"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    user_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    token: Mapped[str] = mapped_column(Text, nullable=False, unique=True)
    platform: Mapped[str] = mapped_column(Text, nullable=False)  # ios | android
    created_at: Mapped[datetime] = mapped_column(TIMESTAMP(timezone=True), server_default=func.now())

    __table_args__ = (
        Index("ix_push_tokens_user", "user_id"),
    )


class UserAchievement(Base):
    __tablename__ = "user_achievements"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    user_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    achievement_id: Mapped[str] = mapped_column(Text, nullable=False)
    earned_at: Mapped[datetime] = mapped_column(TIMESTAMP(timezone=True), server_default=func.now())

    __table_args__ = (
        UniqueConstraint("user_id", "achievement_id", name="uq_user_achievement"),
        Index("ix_user_achievements_user", "user_id"),
    )

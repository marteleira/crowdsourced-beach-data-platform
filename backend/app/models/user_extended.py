"""
Additional user-related models:
  UserFavourite   — ordered list of favourite beaches per user
  PushToken       — FCM/APNs device tokens for push notifications
  UserAchievement — unlocked achievements
"""
from sqlalchemy import (
    Column, Integer, Text, Boolean, TIMESTAMP, ForeignKey,
    UniqueConstraint, Index, Date,
)
from sqlalchemy.dialects.postgresql import UUID, JSONB
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
    "location_accuracy": "approximate",   # exact | approximate | none
    "name_public": True,
    "avatar_public": True,
    "share_usage_data": True, #This settings does nothing yet
    "share_presence": True,               # show on map
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

    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    beach_id = Column(Integer, ForeignKey("beaches.id", ondelete="CASCADE"), nullable=False)
    position = Column(Integer, default=0)  # ordering index
    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now())

    __table_args__ = (
        UniqueConstraint("user_id", "beach_id", name="uq_user_favourite_beach"),
        Index("ix_user_favourites_user", "user_id", "position"),
    )


class PushToken(Base):
    __tablename__ = "push_tokens"

    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    token = Column(Text, nullable=False, unique=True)
    platform = Column(Text, nullable=False)   # ios | android
    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now())

    __table_args__ = (
        Index("ix_push_tokens_user", "user_id"),
    )


class UserAchievement(Base):
    __tablename__ = "user_achievements"

    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    achievement_id = Column(Text, nullable=False)
    earned_at = Column(TIMESTAMP(timezone=True), server_default=func.now())

    __table_args__ = (
        UniqueConstraint("user_id", "achievement_id", name="uq_user_achievement"),
        Index("ix_user_achievements_user", "user_id"),
    )

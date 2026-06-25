from datetime import datetime, date
from typing import Any
import uuid
from sqlalchemy import Text, Boolean, Integer, TIMESTAMP, Index, Date
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.sql import func
from app.core.database import Base


class User(Base):
    __tablename__ = "users"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    email: Mapped[str | None] = mapped_column(Text, unique=True, nullable=True)
    display_name: Mapped[str | None] = mapped_column(Text, nullable=True)

    password_hash: Mapped[str | None] = mapped_column(Text, nullable=True)   # NULL if Google-only
    google_sub: Mapped[str | None] = mapped_column(Text, unique=True, nullable=True)  # NULL if email-only

    is_anonymous: Mapped[bool] = mapped_column(Boolean, default=False)
    device_id: Mapped[str | None] = mapped_column(Text, nullable=True)  # used for anonymous/guest users

    reputation: Mapped[int] = mapped_column(Integer, default=0)
    is_banned: Mapped[bool] = mapped_column(Boolean, default=False)
    ban_reason: Mapped[str | None] = mapped_column(Text, nullable=True)
    suspended_until: Mapped[datetime | None] = mapped_column(TIMESTAMP(timezone=True), nullable=True)

    # Denormalised counters for fast reads
    total_reports: Mapped[int] = mapped_column(Integer, default=0)
    confirmed_reports: Mapped[int] = mapped_column(Integer, default=0)
    false_reports: Mapped[int] = mapped_column(Integer, default=0)
    streak: Mapped[int] = mapped_column(Integer, default=0)
    last_contribution_date: Mapped[date | None] = mapped_column(Date, nullable=True)

    # Settings stored as JSONB (defaults applied at read time if NULL)
    notification_settings: Mapped[Any] = mapped_column(JSONB, nullable=True)
    privacy_settings: Mapped[Any] = mapped_column(JSONB, nullable=True)

    is_email_verified: Mapped[bool] = mapped_column(Boolean, default=False)
    email_verification_code_hash: Mapped[str | None] = mapped_column(Text, nullable=True)
    email_verification_expires_at: Mapped[datetime | None] = mapped_column(TIMESTAMP(timezone=True), nullable=True)

    password_reset_code_hash: Mapped[str | None] = mapped_column(Text, nullable=True)
    password_reset_expires_at: Mapped[datetime | None] = mapped_column(TIMESTAMP(timezone=True), nullable=True)

    avatar_id: Mapped[str | None] = mapped_column(Text, nullable=True)

    created_at: Mapped[datetime] = mapped_column(TIMESTAMP(timezone=True), server_default=func.now())
    scheduled_deletion_at: Mapped[datetime | None] = mapped_column(TIMESTAMP(timezone=True), nullable=True)


class RefreshToken(Base):
    __tablename__ = "refresh_tokens"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), nullable=False)
    token_hash: Mapped[str] = mapped_column(Text, nullable=False, unique=True)
    device_info: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(TIMESTAMP(timezone=True), server_default=func.now())
    expires_at: Mapped[datetime] = mapped_column(TIMESTAMP(timezone=True), nullable=False)
    revoked_at: Mapped[datetime | None] = mapped_column(TIMESTAMP(timezone=True), nullable=True)

    __table_args__ = (
        Index("ix_refresh_tokens_user_revoked", "user_id", "revoked_at"),
    )


class ReputationEvent(Base):
    __tablename__ = "reputation_events"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    user_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), nullable=False)
    event: Mapped[str] = mapped_column(Text, nullable=False)  # report_confirmed | report_contradicted | ...
    delta: Mapped[int] = mapped_column(Integer, nullable=False)
    reason: Mapped[str | None] = mapped_column(Text, nullable=True)
    ref_id: Mapped[int | None] = mapped_column(Integer, nullable=True)  # ID of associated report/flag
    created_at: Mapped[datetime] = mapped_column(TIMESTAMP(timezone=True), server_default=func.now())

from sqlalchemy import (
    Column, Text, Boolean, Integer, TIMESTAMP, Index,
    CheckConstraint, SmallInteger,
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func
import uuid
from app.core.database import Base


class User(Base):
    __tablename__ = "users"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    email = Column(Text, unique=True)
    display_name = Column(Text)

    password_hash = Column(Text)           # NULL if Google-only
    google_sub = Column(Text, unique=True) # NULL if email-only

    is_anonymous = Column(Boolean, default=False)
    device_id = Column(Text)               # used for anonymous/guest users

    reputation = Column(Integer, default=0)
    is_banned = Column(Boolean, default=False)
    ban_reason = Column(Text)

    # Denormalised counters for fast reads
    total_reports = Column(Integer, default=0)
    confirmed_reports = Column(Integer, default=0)
    false_reports = Column(Integer, default=0)

    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now())


class RefreshToken(Base):
    __tablename__ = "refresh_tokens"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), nullable=False)
    token_hash = Column(Text, nullable=False, unique=True)
    device_info = Column(Text)
    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now())
    expires_at = Column(TIMESTAMP(timezone=True), nullable=False)
    revoked_at = Column(TIMESTAMP(timezone=True))

    __table_args__ = (
        Index("ix_refresh_tokens_user_revoked", "user_id", "revoked_at"),
    )


class ReputationEvent(Base):
    __tablename__ = "reputation_events"

    id = Column(Integer, primary_key=True)
    user_id = Column(UUID(as_uuid=True), nullable=False)
    event = Column(Text, nullable=False)   # report_confirmed | report_contradicted | ...
    delta = Column(Integer, nullable=False)
    reason = Column(Text)
    ref_id = Column(Integer)               # ID of associated report/flag
    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now())

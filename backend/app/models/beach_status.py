from datetime import datetime
from typing import Any
import uuid
from sqlalchemy import Integer, Text, Float, TIMESTAMP, ForeignKey, BigInteger, CheckConstraint, Index
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.sql import func
from geoalchemy2 import Geography
from app.core.database import Base

FLAG_COLORS = ("green", "yellow", "red", "purple", "unknown")


class BeachStatus(Base):
    __tablename__ = "beach_status"

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    beach_id: Mapped[int] = mapped_column(Integer, ForeignKey("beaches.id"), nullable=False, unique=True)
    flag_color: Mapped[str] = mapped_column(Text, default="unknown")
    flag_source: Mapped[str] = mapped_column(Text, default="community")  # "community" | "official"
    flag_confidence: Mapped[float] = mapped_column(Float, default=0.0)
    # No onupdate: this marks when the CURRENT flag instance was (re)set, not
    # last-write time — every write must set it explicitly and only on
    # instance changes (see app/api/flags.py, app/scheduler/jobs.py).
    updated_at: Mapped[datetime] = mapped_column(TIMESTAMP(timezone=True), server_default=func.now())

    __table_args__ = (
        CheckConstraint(f"flag_color IN {tuple(FLAG_COLORS)}", name="ck_flag_color"),
    )


class FlagProposal(Base):
    __tablename__ = "flag_proposals"

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    beach_id: Mapped[int] = mapped_column(Integer, ForeignKey("beaches.id"), nullable=False)
    user_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    proposed_color: Mapped[str] = mapped_column(Text, nullable=False)
    initial_weight: Mapped[float] = mapped_column(Float, default=1.0)
    status: Mapped[str] = mapped_column(Text, default="pending")  # pending | applied | rejected
    created_at: Mapped[datetime] = mapped_column(TIMESTAMP(timezone=True), server_default=func.now())


class FlagConfirmation(Base):
    __tablename__ = "flag_confirmations"

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    beach_id: Mapped[int] = mapped_column(Integer, ForeignKey("beaches.id"), nullable=False)
    user_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    response: Mapped[str] = mapped_column(Text, nullable=False)   # yes | no | unsure
    flag_color: Mapped[str] = mapped_column(Text, nullable=False)
    created_at: Mapped[datetime] = mapped_column(TIMESTAMP(timezone=True), server_default=func.now())

    __table_args__ = (
        CheckConstraint("response IN ('yes', 'no', 'unsure')", name="ck_confirmation_response"),
        Index(
            "ix_flag_confirm_user_beach_hour",
            "user_id", "beach_id",
        ),
    )


class OccupancyHeartbeat(Base):
    __tablename__ = "occupancy_heartbeats"

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    beach_id: Mapped[int] = mapped_column(Integer, ForeignKey("beaches.id"), nullable=False)
    user_id: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=True)
    geom: Mapped[Any] = mapped_column(Geography("Point", srid=4326), nullable=True)
    created_at: Mapped[datetime] = mapped_column(TIMESTAMP(timezone=True), server_default=func.now())

    __table_args__ = (
        Index("ix_heartbeats_beach_created", "beach_id", "created_at"),
    )


class OccupancyReport(Base):
    """Crowdsourced occupancy perception (1=vazia … 5=cheia), one per user per beach per 2h."""
    __tablename__ = "occupancy_reports"

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    beach_id: Mapped[int] = mapped_column(Integer, ForeignKey("beaches.id"), nullable=False)
    user_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    level: Mapped[int] = mapped_column(Integer, nullable=False)   # 1–5
    created_at: Mapped[datetime] = mapped_column(TIMESTAMP(timezone=True), server_default=func.now())

    __table_args__ = (
        CheckConstraint("level BETWEEN 1 AND 5", name="ck_occupancy_report_level"),
        Index("ix_occupancy_reports_beach_created", "beach_id", "created_at"),
        Index("ix_occupancy_reports_user_beach", "user_id", "beach_id"),
    )

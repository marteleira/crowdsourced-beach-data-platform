from sqlalchemy import (
    Column, Integer, Text, Float, TIMESTAMP, ForeignKey,
    BigInteger, CheckConstraint, Index, UniqueConstraint,
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func
from geoalchemy2 import Geography
from app.core.database import Base

FLAG_COLORS = ("green", "yellow", "red", "purple", "unknown")


class BeachStatus(Base):
    __tablename__ = "beach_status"

    id = Column(BigInteger, primary_key=True, autoincrement=True)
    beach_id = Column(Integer, ForeignKey("beaches.id"), nullable=False, unique=True)
    flag_color = Column(Text, default="unknown")
    flag_source = Column(Text, default="community")  # "community" | "official"
    flag_confidence = Column(Float, default=0.0)
    updated_at = Column(TIMESTAMP(timezone=True), server_default=func.now(), onupdate=func.now())

    __table_args__ = (
        CheckConstraint(f"flag_color IN {tuple(FLAG_COLORS)}", name="ck_flag_color"),
    )


class FlagProposal(Base):
    __tablename__ = "flag_proposals"

    id = Column(BigInteger, primary_key=True, autoincrement=True)
    beach_id = Column(Integer, ForeignKey("beaches.id"), nullable=False)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    proposed_color = Column(Text, nullable=False)
    initial_weight = Column(Float, default=1.0)
    status = Column(Text, default="pending")  # pending | applied | rejected
    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now())


class FlagConfirmation(Base):
    __tablename__ = "flag_confirmations"

    id = Column(BigInteger, primary_key=True, autoincrement=True)
    beach_id = Column(Integer, ForeignKey("beaches.id"), nullable=False)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    response = Column(Text, nullable=False)   # yes | no | unsure
    flag_color = Column(Text, nullable=False)
    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now())

    __table_args__ = (
        CheckConstraint("response IN ('yes', 'no', 'unsure')", name="ck_confirmation_response"),
        # One vote per user per beach per hour
        Index(
            "ix_flag_confirm_user_beach_hour",
            "user_id", "beach_id",
        ),
    )


class OccupancyHeartbeat(Base):
    __tablename__ = "occupancy_heartbeats"

    id = Column(BigInteger, primary_key=True, autoincrement=True)
    beach_id = Column(Integer, ForeignKey("beaches.id"), nullable=False)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"))
    geom = Column(Geography("Point", srid=4326))
    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now())

    __table_args__ = (
        Index("ix_heartbeats_beach_created", "beach_id", "created_at"),
    )

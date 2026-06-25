from datetime import datetime
from typing import Any
import uuid
from sqlalchemy import Integer, Text, SmallInteger, Boolean, TIMESTAMP, ForeignKey, CheckConstraint, Index, BigInteger
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.sql import func
from geoalchemy2 import Geography
from app.core.database import Base
from app.core.constants import REPORT_VERIFIED_NET_VOTES

REPORT_TYPES = (
    "jellyfish",
    "strong_current",
    "pollution",
    "rough_sea",
    "other_alert",
)


class Report(Base):
    __tablename__ = "reports"

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    beach_id: Mapped[int] = mapped_column(Integer, ForeignKey("beaches.id"), nullable=False)
    user_id: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=True)  # NULL = anonymous

    type: Mapped[str] = mapped_column(Text, nullable=False)
    severity: Mapped[int | None] = mapped_column(SmallInteger, nullable=True)  # 1–3
    note: Mapped[str | None] = mapped_column(Text, nullable=True)
    geom: Mapped[Any] = mapped_column(Geography("Point", srid=4326), nullable=True)

    upvotes: Mapped[int] = mapped_column(Integer, default=0)
    downvotes: Mapped[int] = mapped_column(Integer, default=0)

    created_at: Mapped[datetime] = mapped_column(TIMESTAMP(timezone=True), server_default=func.now())
    expires_at: Mapped[datetime] = mapped_column(TIMESTAMP(timezone=True), nullable=False)
    is_expired: Mapped[bool] = mapped_column(Boolean, default=False)

    __table_args__ = (
        CheckConstraint(f"type IN {tuple(REPORT_TYPES)}", name="ck_report_type"),
        CheckConstraint("severity BETWEEN 1 AND 3", name="ck_report_severity"),
        Index("ix_reports_beach_active", "beach_id", "is_expired", "expires_at"),
    )

    @property
    def is_verified(self) -> bool:
        return (self.upvotes - self.downvotes) >= REPORT_VERIFIED_NET_VOTES


class ReportVote(Base):
    __tablename__ = "report_votes"

    report_id: Mapped[int] = mapped_column(BigInteger, ForeignKey("reports.id"), primary_key=True)
    user_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id"), primary_key=True)
    vote: Mapped[int] = mapped_column(SmallInteger, nullable=False)  # 1 or -1

    __table_args__ = (
        CheckConstraint("vote IN (1, -1)", name="ck_vote_value"),
    )

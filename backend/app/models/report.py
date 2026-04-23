from sqlalchemy import (
    Column, Integer, Text, SmallInteger, Boolean, TIMESTAMP,
    ForeignKey, CheckConstraint, Index, BigInteger,
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func
from geoalchemy2 import Geography
from app.core.database import Base

REPORT_TYPES = (
    "jellyfish",
    "strong_current",
    "pollution",
    "rough_sea",
    "other_alert",
)


class Report(Base):
    __tablename__ = "reports"

    id = Column(BigInteger, primary_key=True, autoincrement=True)
    beach_id = Column(Integer, ForeignKey("beaches.id"), nullable=False)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"))  # NULL = anonymous

    type = Column(Text, nullable=False)
    severity = Column(SmallInteger)  # 1–3
    note = Column(Text)
    geom = Column(Geography("Point", srid=4326))

    upvotes = Column(Integer, default=0)
    downvotes = Column(Integer, default=0)

    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now())
    expires_at = Column(TIMESTAMP(timezone=True), nullable=False)
    # is_active is derived: expires_at > now() AND not manually expired
    is_expired = Column(Boolean, default=False)

    __table_args__ = (
        CheckConstraint(f"type IN {tuple(REPORT_TYPES)}", name="ck_report_type"),
        CheckConstraint("severity BETWEEN 1 AND 3", name="ck_report_severity"),
        Index("ix_reports_beach_active", "beach_id", "is_expired", "expires_at"),
    )


class ReportVote(Base):
    __tablename__ = "report_votes"

    report_id = Column(BigInteger, ForeignKey("reports.id"), primary_key=True)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), primary_key=True)
    vote = Column(SmallInteger, nullable=False)  # 1 or -1

    __table_args__ = (
        CheckConstraint("vote IN (1, -1)", name="ck_vote_value"),
    )

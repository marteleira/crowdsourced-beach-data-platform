from datetime import datetime
from typing import Any
from sqlalchemy import Integer, Text, TIMESTAMP, Index
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.sql import func
from app.core.database import Base

SNAPSHOT_SOURCES = (
    "ipma_weather",
    "ipma_sea",
    "tides",
    "water_quality",
    "carris_stops",
    "carris_routes",
    "gtfs",
)


class ApiSnapshot(Base):
    __tablename__ = "api_snapshots"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    source: Mapped[str] = mapped_column(Text, nullable=False)   # one of SNAPSHOT_SOURCES
    beach_id: Mapped[int | None] = mapped_column(Integer, nullable=True)  # NULL for global data (e.g. IPMA alerts)
    data: Mapped[Any] = mapped_column(JSONB, nullable=False)
    fetched_at: Mapped[datetime] = mapped_column(TIMESTAMP(timezone=True), server_default=func.now())

    __table_args__ = (
        Index("ix_snapshots_source_beach_fetched", "source", "beach_id", "fetched_at"),
    )

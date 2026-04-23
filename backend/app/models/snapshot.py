from sqlalchemy import Column, Integer, Text, TIMESTAMP, Index
from sqlalchemy.dialects.postgresql import JSONB
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

    id = Column(Integer, primary_key=True)
    source = Column(Text, nullable=False)   # one of SNAPSHOT_SOURCES
    beach_id = Column(Integer)              # NULL for global data (e.g. IPMA alerts)
    data = Column(JSONB, nullable=False)
    fetched_at = Column(TIMESTAMP(timezone=True), server_default=func.now())

    __table_args__ = (
        Index("ix_snapshots_source_beach_fetched", "source", "beach_id", "fetched_at"),
    )

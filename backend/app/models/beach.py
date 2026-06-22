from sqlalchemy import (
    Column, Integer, String, Boolean, Float, Text,
    ARRAY, TIMESTAMP, ForeignKey, SmallInteger, BigInteger,
    UniqueConstraint, Index, Computed,
)
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.sql import func
from geoalchemy2 import Geography
from app.core.database import Base


class Beach(Base):
    __tablename__ = "beaches"

    id = Column(Integer, primary_key=True)
    slug = Column(Text, unique=True, nullable=False)
    name = Column(Text, nullable=False)
    lat = Column(Float, nullable=False)
    lon = Column(Float, nullable=False)
    geom = Column(Geography("Point", srid=4326))

    # External API identifiers (nullable – not all APIs cover every beach)
    ipma_global_id = Column(Integer)
    ipma_sea_global_id = Column(Integer)
    eea_station_id = Column(Text)
    tide_station_id = Column(Text)

    # Capacity
    has_capacity_data = Column(Boolean, default=False)
    max_capacity = Column(Integer)

    # Carris stop IDs near this beach
    nearby_stop_ids = Column(ARRAY(Text), default=[])

    # Feature flags
    flags_available = Column(Boolean, default=True)

    cover_photo_url = Column(Text, nullable=True)

    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now())

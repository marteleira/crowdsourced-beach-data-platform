from datetime import datetime
from typing import Any
from sqlalchemy import Integer, Boolean, Float, Text, ARRAY, TIMESTAMP
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.sql import func
from geoalchemy2 import Geography
from app.core.database import Base


class Beach(Base):
    __tablename__ = "beaches"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    slug: Mapped[str] = mapped_column(Text, unique=True, nullable=False)
    name: Mapped[str] = mapped_column(Text, nullable=False)
    lat: Mapped[float] = mapped_column(Float, nullable=False)
    lon: Mapped[float] = mapped_column(Float, nullable=False)
    geom: Mapped[Any] = mapped_column(Geography("Point", srid=4326), nullable=True)

    # External API identifiers (nullable – not all APIs cover every beach)
    ipma_global_id: Mapped[int | None] = mapped_column(Integer, nullable=True)
    ipma_sea_global_id: Mapped[int | None] = mapped_column(Integer, nullable=True)
    eea_station_id: Mapped[str | None] = mapped_column(Text, nullable=True)
    tide_station_id: Mapped[str | None] = mapped_column(Text, nullable=True)

    # Capacity
    has_capacity_data: Mapped[bool] = mapped_column(Boolean, default=False)
    max_capacity: Mapped[int | None] = mapped_column(Integer, nullable=True)

    # Carris stop IDs near this beach
    nearby_stop_ids: Mapped[list[str] | None] = mapped_column(ARRAY(Text), default=[], nullable=True)

    # Feature flags
    flags_available: Mapped[bool] = mapped_column(Boolean, default=True)

    cover_photo_url: Mapped[str | None] = mapped_column(Text, nullable=True)
    municipality: Mapped[str | None] = mapped_column(Text, nullable=True)

    created_at: Mapped[datetime] = mapped_column(TIMESTAMP(timezone=True), server_default=func.now())

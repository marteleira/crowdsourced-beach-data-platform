from datetime import datetime
from typing import Any
from sqlalchemy import BigInteger, Integer, Text, Float, TIMESTAMP, UniqueConstraint, Index
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.sql import func
from app.core.database import Base


class TideObservation(Base):
    __tablename__ = "tide_observations"

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    station_id: Mapped[str] = mapped_column(Text, nullable=False)
    height: Mapped[float] = mapped_column(Float, nullable=False)
    observed_at: Mapped[datetime] = mapped_column(TIMESTAMP(timezone=True), nullable=False)

    __table_args__ = (
        UniqueConstraint("station_id", "observed_at", name="uq_tide_obs_station_time"),
        Index("ix_tide_obs_station_time", "station_id", "observed_at"),
    )


class TideModelCoef(Base):
    __tablename__ = "tide_model_coef"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    station_id: Mapped[str] = mapped_column(Text, nullable=False, unique=True)
    coef_json: Mapped[Any] = mapped_column(JSONB, nullable=False)
    msl: Mapped[float] = mapped_column(Float, nullable=False)
    n_observations: Mapped[int] = mapped_column(Integer, nullable=False)
    fitted_at: Mapped[datetime] = mapped_column(TIMESTAMP(timezone=True), server_default=func.now())

from sqlalchemy import Column, BigInteger, Integer, Text, Float, TIMESTAMP, UniqueConstraint, Index
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.sql import func
from app.core.database import Base


class TideObservation(Base):
    __tablename__ = "tide_observations"

    id = Column(BigInteger, primary_key=True, autoincrement=True)
    station_id = Column(Text, nullable=False)
    height = Column(Float, nullable=False)
    observed_at = Column(TIMESTAMP(timezone=True), nullable=False)

    __table_args__ = (
        UniqueConstraint("station_id", "observed_at", name="uq_tide_obs_station_time"),
        Index("ix_tide_obs_station_time", "station_id", "observed_at"),
    )


class TideModelCoef(Base):
    __tablename__ = "tide_model_coef"

    id = Column(Integer, primary_key=True, autoincrement=True)
    station_id = Column(Text, nullable=False, unique=True)
    coef_json = Column(JSONB, nullable=False)   # serialised utide coef (A, g, name arrays)
    msl = Column(Float, nullable=False)          # calibrated mean sea level
    n_observations = Column(Integer, nullable=False)
    fitted_at = Column(TIMESTAMP(timezone=True), server_default=func.now())

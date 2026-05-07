"""Add tide observations and fitted model coefficient tables

Revision ID: 0003
Revises: 0002
Create Date: 2025-01-01 00:00:00.000000
"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision: str = "0003"
down_revision: Union[str, None] = "0002"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Raw observations collected by the scheduler
    op.create_table(
        "tide_observations",
        sa.Column("id", sa.BigInteger(), autoincrement=True, nullable=False),
        sa.Column("station_id", sa.Text(), nullable=False),
        sa.Column("height", sa.Float(), nullable=False),
        sa.Column("observed_at", sa.TIMESTAMP(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("station_id", "observed_at", name="uq_tide_obs_station_time"),
    )
    op.create_index("ix_tide_obs_station_time", "tide_observations", ["station_id", "observed_at"])

    # Fitted harmonic model coefficients (updated weekly once enough data exists)
    op.create_table(
        "tide_model_coef",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("station_id", sa.Text(), nullable=False, unique=True),
        sa.Column("coef_json", postgresql.JSONB(), nullable=False),
        sa.Column("msl", sa.Float(), nullable=False),
        sa.Column("n_observations", sa.Integer(), nullable=False),
        sa.Column("fitted_at", sa.TIMESTAMP(timezone=True), server_default=sa.text("now()"), nullable=True),
        sa.PrimaryKeyConstraint("id"),
    )


def downgrade() -> None:
    op.drop_table("tide_model_coef")
    op.drop_table("tide_observations")

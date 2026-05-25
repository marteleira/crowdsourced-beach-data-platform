"""Rename beaches.apa_station_id to eea_station_id

The column holds EEA bathingWaterIdentifiers (e.g. "PTCW2P"), not APA codes.
The service backing this field was already migrated to the EEA DiscoData API.

Revision ID: 0004
Revises: 0003
Create Date: 2026-05-25 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op

revision: str = "0004"
down_revision: Union[str, None] = "0003"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.alter_column("beaches", "apa_station_id", new_column_name="eea_station_id")


def downgrade() -> None:
    op.alter_column("beaches", "eea_station_id", new_column_name="apa_station_id")

"""Add cover_photo_url to beaches

Revision ID: 0010
Revises: 0009
Create Date: 2026-06-22 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "0010"
down_revision: Union[str, None] = "0009"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("beaches", sa.Column("cover_photo_url", sa.Text(), nullable=True))


def downgrade() -> None:
    op.drop_column("beaches", "cover_photo_url")

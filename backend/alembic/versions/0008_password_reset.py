"""Add password reset fields to users

Revision ID: 0008
Revises: 0007
Create Date: 2026-06-18 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "0008"
down_revision: Union[str, None] = "0007"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("users", sa.Column("password_reset_code_hash", sa.Text(), nullable=True))
    op.add_column("users", sa.Column("password_reset_expires_at", sa.TIMESTAMP(timezone=True), nullable=True))


def downgrade() -> None:
    op.drop_column("users", "password_reset_expires_at")
    op.drop_column("users", "password_reset_code_hash")

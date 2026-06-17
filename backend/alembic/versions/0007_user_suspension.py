"""Add suspended_until to users

Revision ID: 0007
Revises: 0006
Create Date: 2026-06-17 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "0007"
down_revision: Union[str, None] = "0006"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "users",
        sa.Column("suspended_until", sa.TIMESTAMP(timezone=True), nullable=True),
    )
    op.create_index(
        "ix_users_suspended_until",
        "users",
        ["suspended_until"],
        postgresql_where=sa.text("suspended_until IS NOT NULL"),
    )


def downgrade() -> None:
    op.drop_index("ix_users_suspended_until", table_name="users")
    op.drop_column("users", "suspended_until")

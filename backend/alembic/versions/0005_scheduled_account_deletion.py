"""Add scheduled_deletion_at to users for deferred account purge

Revision ID: 0005
Revises: 0004
Create Date: 2026-06-01 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "0005"
down_revision: Union[str, None] = "0004"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "users",
        sa.Column("scheduled_deletion_at", sa.TIMESTAMP(timezone=True), nullable=True),
    )
    op.create_index(
        "ix_users_scheduled_deletion_at",
        "users",
        ["scheduled_deletion_at"],
        postgresql_where=sa.text("scheduled_deletion_at IS NOT NULL"),
    )


def downgrade() -> None:
    op.drop_index("ix_users_scheduled_deletion_at", table_name="users")
    op.drop_column("users", "scheduled_deletion_at")

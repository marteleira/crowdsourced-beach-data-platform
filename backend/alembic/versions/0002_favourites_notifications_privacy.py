"""Add favourites, push tokens, achievements and user settings

Revision ID: 0002
Revises: 0001
Create Date: 2025-01-01 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision: str = "0002"
down_revision: Union[str, None] = "0001"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # New columns on users
    op.add_column("users", sa.Column("streak", sa.Integer(), nullable=True, server_default="0"))
    op.add_column("users", sa.Column("last_contribution_date", sa.Date(), nullable=True))
    op.add_column("users", sa.Column("notification_settings", postgresql.JSONB(), nullable=True))
    op.add_column("users", sa.Column("privacy_settings", postgresql.JSONB(), nullable=True))

    # user_favourites
    op.create_table(
        "user_favourites",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("beach_id", sa.Integer(), nullable=False),
        sa.Column("position", sa.Integer(), nullable=True, server_default="0"),
        sa.Column("created_at", sa.TIMESTAMP(timezone=True), server_default=sa.text("now()"), nullable=True),
        sa.ForeignKeyConstraint(["beach_id"], ["beaches.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("user_id", "beach_id", name="uq_user_favourite_beach"),
    )
    op.create_index("ix_user_favourites_user", "user_favourites", ["user_id", "position"])

    # push_tokens
    op.create_table(
        "push_tokens",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("token", sa.Text(), nullable=False),
        sa.Column("platform", sa.Text(), nullable=False),
        sa.Column("created_at", sa.TIMESTAMP(timezone=True), server_default=sa.text("now()"), nullable=True),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("token"),
    )
    op.create_index("ix_push_tokens_user", "push_tokens", ["user_id"])

    # user_achievements
    op.create_table(
        "user_achievements",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("achievement_id", sa.Text(), nullable=False),
        sa.Column("earned_at", sa.TIMESTAMP(timezone=True), server_default=sa.text("now()"), nullable=True),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("user_id", "achievement_id", name="uq_user_achievement"),
    )
    op.create_index("ix_user_achievements_user", "user_achievements", ["user_id"])


def downgrade() -> None:
    op.drop_table("user_achievements")
    op.drop_table("push_tokens")
    op.drop_table("user_favourites")
    op.drop_column("users", "privacy_settings")
    op.drop_column("users", "notification_settings")
    op.drop_column("users", "last_contribution_date")
    op.drop_column("users", "streak")

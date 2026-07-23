"""Add users.language

Push notifications and emails are composed outside the recipient's own
request context (e.g. user A submits a report, user B receives the push),
so the recipient's Accept-Language header isn't available at dispatch
time - it has to already be persisted. Defaults to "en"; app/core/deps.py
keeps it in sync with each authenticated request's Accept-Language header.

Revision ID: 0015
Revises: 0014
Create Date: 2026-07-23
"""
from alembic import op
import sqlalchemy as sa

revision = '0015'
down_revision = '0014'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column("users", sa.Column("language", sa.Text(), nullable=False, server_default="en"))
    # Pre-existing ban_reason values were rendered Portuguese prose (e.g. "Reputação
    # abaixo de 10"); normalise them to the new stable code so t() resolves them
    # correctly regardless of the banned user's language.
    op.execute(
        "UPDATE users SET ban_reason = 'reputation_below_threshold' "
        "WHERE ban_reason LIKE 'Reputação abaixo de%'"
    )


def downgrade() -> None:
    op.drop_column("users", "language")

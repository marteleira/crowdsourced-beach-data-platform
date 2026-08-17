"""Add flag_proposals.applied_at

Flag membership for a reapplied cycle used to be guessed using a
60-minute window around beach_status.updated_at, which could wrongly pin
a quick decay-then-reapply cycle on the previous cycle's authors.
Now applied_at gets the exact same timestamp as beach_status.updated_at
when applied, so we just do an exact match instead.

Revision ID: 0016
Revises: 0015
Create Date: 2026-08-18
"""
from alembic import op
import sqlalchemy as sa

revision = '0016'
down_revision = '0015'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column("flag_proposals", sa.Column("applied_at", sa.TIMESTAMP(timezone=True), nullable=True))


def downgrade() -> None:
    op.drop_column("flag_proposals", "applied_at")

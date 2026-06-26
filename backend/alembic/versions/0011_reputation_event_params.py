"""Add params JSONB column to reputation_events, remove reason

Revision ID: 0011
Revises: 0010
Create Date: 2026-06-26
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import JSONB

revision = '0011'
down_revision = 'c09bd4e870f6'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        'reputation_events',
        sa.Column('params', JSONB, nullable=True),
    )
    # Drop reason — frontend now formats using event + params via l10n
    op.drop_column('reputation_events', 'reason')


def downgrade() -> None:
    op.add_column(
        'reputation_events',
        sa.Column('reason', sa.Text, nullable=True),
    )
    op.drop_column('reputation_events', 'params')

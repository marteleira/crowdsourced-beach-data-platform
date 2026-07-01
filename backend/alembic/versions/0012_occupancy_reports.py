"""Add occupancy_reports table for crowdsourced occupancy perception

Revision ID: 0012
Revises: 0011
Create Date: 2026-07-01
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import UUID

revision = '0012'
down_revision = '0011'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        'occupancy_reports',
        sa.Column('id', sa.BigInteger, primary_key=True, autoincrement=True),
        sa.Column('beach_id', sa.Integer, sa.ForeignKey('beaches.id'), nullable=False),
        sa.Column('user_id', UUID(as_uuid=True), sa.ForeignKey('users.id'), nullable=False),
        sa.Column('level', sa.Integer, nullable=False),
        sa.Column('created_at', sa.TIMESTAMP(timezone=True), server_default=sa.func.now()),
        sa.CheckConstraint('level BETWEEN 1 AND 5', name='ck_occupancy_report_level'),
    )
    op.create_index('ix_occupancy_reports_beach_created', 'occupancy_reports', ['beach_id', 'created_at'])
    op.create_index('ix_occupancy_reports_user_beach', 'occupancy_reports', ['user_id', 'beach_id'])


def downgrade() -> None:
    op.drop_index('ix_occupancy_reports_user_beach', table_name='occupancy_reports')
    op.drop_index('ix_occupancy_reports_beach_created', table_name='occupancy_reports')
    op.drop_table('occupancy_reports')

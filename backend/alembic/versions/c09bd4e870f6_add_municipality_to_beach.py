"""add municipality to beach

Revision ID: c09bd4e870f6
Revises: 0010
Create Date: 2026-06-23 14:53:22.218438

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
import geoalchemy2


# revision identifiers, used by Alembic.
revision: str = 'c09bd4e870f6'
down_revision: Union[str, None] = '0010'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column('beaches', sa.Column('municipality', sa.Text(), nullable=True))


def downgrade() -> None:
    op.drop_column('beaches', 'municipality')

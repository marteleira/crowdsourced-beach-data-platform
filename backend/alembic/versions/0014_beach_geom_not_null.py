"""Make beaches.geom NOT NULL

geom is fully derived from lat/lon (which are already NOT NULL) and every
write path (scripts/seed_beaches.py) sets it alongside them, so a NULL geom
can only be a data bug, but presence matching (point_within_beach_radius,
find_nearest_beach in app/core/db_helpers.py) relies on PostGIS ST_DWithin
against beach.geom, which evaluates to NULL/false for such a beach
instead of raising. That beach then simply never registers anyone as
present, with no error anywhere, enforce the invariant at the schema level
instead of trusting every future write path to remember it.

Revision ID: 0014
Revises: 0013
Create Date: 2026-07-21
"""
from alembic import op

revision = '0014'
down_revision = '0013'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.execute(
        "UPDATE beaches SET geom = ST_SetSRID(ST_MakePoint(lon, lat), 4326)::geography "
        "WHERE geom IS NULL"
    )
    op.alter_column("beaches", "geom", nullable=False)


def downgrade() -> None:
    op.alter_column("beaches", "geom", nullable=True)

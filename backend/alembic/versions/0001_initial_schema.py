"""Initial schema

Revision ID: 0001
Revises:
Create Date: 2025-01-01 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql
import geoalchemy2

revision: str = "0001"
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Enable PostGIS extension
    op.execute("CREATE EXTENSION IF NOT EXISTS postgis")
    op.execute("CREATE EXTENSION IF NOT EXISTS pgcrypto")

    # beaches
    op.create_table(
        "beaches",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("slug", sa.Text(), nullable=False),
        sa.Column("name", sa.Text(), nullable=False),
        sa.Column("lat", sa.Float(), nullable=False),
        sa.Column("lon", sa.Float(), nullable=False),
        sa.Column("geom", geoalchemy2.types.Geography(geometry_type="POINT", srid=4326), nullable=True),
        sa.Column("ipma_global_id", sa.Integer(), nullable=True),
        sa.Column("ipma_sea_global_id", sa.Integer(), nullable=True),
        sa.Column("apa_station_id", sa.Text(), nullable=True),
        sa.Column("tide_station_id", sa.Text(), nullable=True),
        sa.Column("has_capacity_data", sa.Boolean(), nullable=True, server_default="false"),
        sa.Column("max_capacity", sa.Integer(), nullable=True),
        sa.Column("nearby_stop_ids", sa.ARRAY(sa.Text()), nullable=True),
        sa.Column("flags_available", sa.Boolean(), nullable=True, server_default="true"),
        sa.Column("created_at", sa.TIMESTAMP(timezone=True), server_default=sa.text("now()"), nullable=True),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("slug"),
    )

    # users
    op.create_table(
        "users",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False, server_default=sa.text("gen_random_uuid()")),
        sa.Column("email", sa.Text(), nullable=True),
        sa.Column("display_name", sa.Text(), nullable=True),
        sa.Column("password_hash", sa.Text(), nullable=True),
        sa.Column("google_sub", sa.Text(), nullable=True),
        sa.Column("is_anonymous", sa.Boolean(), nullable=True, server_default="false"),
        sa.Column("device_id", sa.Text(), nullable=True),
        sa.Column("reputation", sa.Integer(), nullable=True, server_default="0"),
        sa.Column("is_banned", sa.Boolean(), nullable=True, server_default="false"),
        sa.Column("ban_reason", sa.Text(), nullable=True),
        sa.Column("total_reports", sa.Integer(), nullable=True, server_default="0"),
        sa.Column("confirmed_reports", sa.Integer(), nullable=True, server_default="0"),
        sa.Column("false_reports", sa.Integer(), nullable=True, server_default="0"),
        sa.Column("created_at", sa.TIMESTAMP(timezone=True), server_default=sa.text("now()"), nullable=True),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("email"),
        sa.UniqueConstraint("google_sub"),
    )

    # refresh_tokens
    op.create_table(
        "refresh_tokens",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False, server_default=sa.text("gen_random_uuid()")),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("token_hash", sa.Text(), nullable=False),
        sa.Column("device_info", sa.Text(), nullable=True),
        sa.Column("created_at", sa.TIMESTAMP(timezone=True), server_default=sa.text("now()"), nullable=True),
        sa.Column("expires_at", sa.TIMESTAMP(timezone=True), nullable=False),
        sa.Column("revoked_at", sa.TIMESTAMP(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("token_hash"),
    )
    op.create_index("ix_refresh_tokens_user_revoked", "refresh_tokens", ["user_id", "revoked_at"])

    # reputation_events
    op.create_table(
        "reputation_events",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("event", sa.Text(), nullable=False),
        sa.Column("delta", sa.Integer(), nullable=False),
        sa.Column("reason", sa.Text(), nullable=True),
        sa.Column("ref_id", sa.Integer(), nullable=True),
        sa.Column("created_at", sa.TIMESTAMP(timezone=True), server_default=sa.text("now()"), nullable=True),
        sa.PrimaryKeyConstraint("id"),
    )

    # reports
    op.create_table(
        "reports",
        sa.Column("id", sa.BigInteger(), autoincrement=True, nullable=False),
        sa.Column("beach_id", sa.Integer(), nullable=False),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column("type", sa.Text(), nullable=False),
        sa.Column("severity", sa.SmallInteger(), nullable=True),
        sa.Column("note", sa.Text(), nullable=True),
        sa.Column("geom", geoalchemy2.types.Geography(geometry_type="POINT", srid=4326), nullable=True),
        sa.Column("upvotes", sa.Integer(), nullable=True, server_default="0"),
        sa.Column("downvotes", sa.Integer(), nullable=True, server_default="0"),
        sa.Column("created_at", sa.TIMESTAMP(timezone=True), server_default=sa.text("now()"), nullable=True),
        sa.Column("expires_at", sa.TIMESTAMP(timezone=True), nullable=False),
        sa.Column("is_expired", sa.Boolean(), nullable=True, server_default="false"),
        sa.CheckConstraint("type IN ('jellyfish','strong_current','pollution','rough_sea','other_alert')", name="ck_report_type"),
        sa.CheckConstraint("severity BETWEEN 1 AND 3", name="ck_report_severity"),
        sa.ForeignKeyConstraint(["beach_id"], ["beaches.id"]),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_reports_beach_active", "reports", ["beach_id", "is_expired", "expires_at"])

    # report_votes
    op.create_table(
        "report_votes",
        sa.Column("report_id", sa.BigInteger(), nullable=False),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("vote", sa.SmallInteger(), nullable=False),
        sa.CheckConstraint("vote IN (1, -1)", name="ck_vote_value"),
        sa.ForeignKeyConstraint(["report_id"], ["reports.id"]),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"]),
        sa.PrimaryKeyConstraint("report_id", "user_id"),
    )

    # beach_status
    op.create_table(
        "beach_status",
        sa.Column("id", sa.BigInteger(), autoincrement=True, nullable=False),
        sa.Column("beach_id", sa.Integer(), nullable=False),
        sa.Column("flag_color", sa.Text(), nullable=True, server_default="'unknown'"),
        sa.Column("flag_source", sa.Text(), nullable=True, server_default="'community'"),
        sa.Column("flag_confidence", sa.Float(), nullable=True, server_default="0.0"),
        sa.Column("updated_at", sa.TIMESTAMP(timezone=True), server_default=sa.text("now()"), nullable=True),
        sa.CheckConstraint("flag_color IN ('green','yellow','red','purple','unknown')", name="ck_flag_color"),
        sa.ForeignKeyConstraint(["beach_id"], ["beaches.id"]),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("beach_id"),
    )

    # flag_proposals
    op.create_table(
        "flag_proposals",
        sa.Column("id", sa.BigInteger(), autoincrement=True, nullable=False),
        sa.Column("beach_id", sa.Integer(), nullable=False),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("proposed_color", sa.Text(), nullable=False),
        sa.Column("initial_weight", sa.Float(), nullable=True, server_default="1.0"),
        sa.Column("status", sa.Text(), nullable=True, server_default="'pending'"),
        sa.Column("created_at", sa.TIMESTAMP(timezone=True), server_default=sa.text("now()"), nullable=True),
        sa.ForeignKeyConstraint(["beach_id"], ["beaches.id"]),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"]),
        sa.PrimaryKeyConstraint("id"),
    )

    # flag_confirmations
    op.create_table(
        "flag_confirmations",
        sa.Column("id", sa.BigInteger(), autoincrement=True, nullable=False),
        sa.Column("beach_id", sa.Integer(), nullable=False),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("response", sa.Text(), nullable=False),
        sa.Column("flag_color", sa.Text(), nullable=False),
        sa.Column("created_at", sa.TIMESTAMP(timezone=True), server_default=sa.text("now()"), nullable=True),
        sa.CheckConstraint("response IN ('yes', 'no', 'unsure')", name="ck_confirmation_response"),
        sa.ForeignKeyConstraint(["beach_id"], ["beaches.id"]),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_flag_confirm_user_beach_hour", "flag_confirmations", ["user_id", "beach_id"])

    # occupancy_heartbeats
    op.create_table(
        "occupancy_heartbeats",
        sa.Column("id", sa.BigInteger(), autoincrement=True, nullable=False),
        sa.Column("beach_id", sa.Integer(), nullable=False),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column("geom", geoalchemy2.types.Geography(geometry_type="POINT", srid=4326), nullable=True),
        sa.Column("created_at", sa.TIMESTAMP(timezone=True), server_default=sa.text("now()"), nullable=True),
        sa.ForeignKeyConstraint(["beach_id"], ["beaches.id"]),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_heartbeats_beach_created", "occupancy_heartbeats", ["beach_id", "created_at"])

    # api_snapshots
    op.create_table(
        "api_snapshots",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("source", sa.Text(), nullable=False),
        sa.Column("beach_id", sa.Integer(), nullable=True),
        sa.Column("data", postgresql.JSONB(), nullable=False),
        sa.Column("fetched_at", sa.TIMESTAMP(timezone=True), server_default=sa.text("now()"), nullable=True),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_snapshots_source_beach_fetched", "api_snapshots", ["source", "beach_id", "fetched_at"])


def downgrade() -> None:
    op.drop_table("api_snapshots")
    op.drop_table("occupancy_heartbeats")
    op.drop_table("flag_confirmations")
    op.drop_table("flag_proposals")
    op.drop_table("beach_status")
    op.drop_table("report_votes")
    op.drop_table("reports")
    op.drop_table("reputation_events")
    op.drop_table("refresh_tokens")
    op.drop_table("users")
    op.drop_table("beaches")

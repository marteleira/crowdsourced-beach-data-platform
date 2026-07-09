"""Add ON DELETE behavior to user_id foreign keys referencing users.id

Without this, purge_scheduled_deletions() (which hard-deletes User rows once
the 30-day grace period elapses) raises a foreign key violation for any user
who ever submitted a report, voted, proposed/confirmed a flag, sent a
heartbeat, or submitted an occupancy perception report -- which is most
active users. That breaks the account-deletion / GDPR right-to-erasure flow.

- reports, occupancy_heartbeats: SET NULL. These rows carry standalone
  informational content (hazard description, presence ping) that stays
  useful to the community/statistics once detached from the deleted user.
- report_votes, flag_proposals, flag_confirmations, occupancy_reports:
  CASCADE. These are per-user signals (a vote, a proposed flag colour, a
  confirmation, a crowd-level rating) with no standalone meaning once the
  submitting user is gone, so they are deleted along with the account.

Revision ID: 0013
Revises: 0012
Create Date: 2026-07-09
"""
from alembic import op

revision = '0013'
down_revision = '0012'
branch_labels = None
depends_on = None

_SET_NULL = [
    ("reports", "reports_user_id_fkey"),
    ("occupancy_heartbeats", "occupancy_heartbeats_user_id_fkey"),
]
_CASCADE = [
    ("report_votes", "report_votes_user_id_fkey"),
    ("flag_proposals", "flag_proposals_user_id_fkey"),
    ("flag_confirmations", "flag_confirmations_user_id_fkey"),
    ("occupancy_reports", "occupancy_reports_user_id_fkey"),
]


def upgrade() -> None:
    for table, constraint in _SET_NULL:
        op.drop_constraint(constraint, table, type_='foreignkey')
        op.create_foreign_key(constraint, table, 'users', ['user_id'], ['id'], ondelete='SET NULL')
    for table, constraint in _CASCADE:
        op.drop_constraint(constraint, table, type_='foreignkey')
        op.create_foreign_key(constraint, table, 'users', ['user_id'], ['id'], ondelete='CASCADE')


def downgrade() -> None:
    for table, constraint in _SET_NULL + _CASCADE:
        op.drop_constraint(constraint, table, type_='foreignkey')
        op.create_foreign_key(constraint, table, 'users', ['user_id'], ['id'])

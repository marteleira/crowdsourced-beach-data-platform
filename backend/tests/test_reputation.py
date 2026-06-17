"""Reputation economy and account status tests."""
from datetime import datetime, timedelta, timezone

import pytest
from httpx import AsyncClient
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import create_access_token, hash_password
from app.models.beach import Beach
from app.models.beach_status import FlagProposal, OccupancyHeartbeat
from app.models.report import Report
from app.models.user import User, ReputationEvent
from app.services.reputation import (
    AUTO_BAN_THRESHOLD,
    DELTA_FIRST_REPORT_BONUS,
    DELTA_FLAG_CONTRADICTED,
    DELTA_REPORT_CONFIRMED,
    DELTA_REPORT_CONTRADICTED,
    DELTA_REPORT_SUBMITTED,
    SUSPENSION_THRESHOLD,
    apply_delta,
    lift_expired_suspensions,
    process_flag_outcomes,
    process_report_outcomes,
    sync_account_status,
)


# ── Helpers ────────────────────────────────────────────────────────────────────

async def _fresh_user(db: AsyncSession, user_id) -> User:
    result = await db.execute(select(User).where(User.id == user_id))
    return result.scalar_one()


async def _rep_events(db: AsyncSession, user_id, event: str) -> list[ReputationEvent]:
    result = await db.execute(
        select(ReputationEvent).where(
            ReputationEvent.user_id == user_id,
            ReputationEvent.event == event,
        )
    )
    return result.scalars().all()


async def _make_user(db: AsyncSession, *, reputation: int = 0, email: str = "u@test.com") -> User:
    u = User(
        email=email,
        display_name="Test",
        password_hash=hash_password("pw"),
        is_anonymous=False,
        reputation=reputation,
        is_email_verified=True,
    )
    db.add(u)
    await db.commit()
    await db.refresh(u)
    return u


async def _add_presence(db: AsyncSession, beach: Beach, user: User) -> None:
    db.add(OccupancyHeartbeat(
        beach_id=beach.id,
        user_id=user.id,
        geom="SRID=4326;POINT(-8.9821 38.4839)",
    ))
    await db.commit()


# ── apply_delta ────────────────────────────────────────────────────────────────

class TestApplyDelta:
    async def test_awards_points(self, db: AsyncSession, user: User):
        await apply_delta(db, user.id, 10, "test_event", "test")
        u = await _fresh_user(db, user.id)
        assert u.reputation == 10

    async def test_deducts_points(self, db: AsyncSession, user: User):
        await apply_delta(db, user.id, -15, "test_event", "test")
        u = await _fresh_user(db, user.id)
        assert u.reputation == -15

    async def test_creates_reputation_event(self, db: AsyncSession, user: User):
        await apply_delta(db, user.id, 10, "report_confirmed", "confirmado", ref_id=42)
        events = await _rep_events(db, user.id, "report_confirmed")
        assert len(events) == 1
        assert events[0].delta == 10
        assert events[0].ref_id == 42

    async def test_triggers_suspension_at_threshold(self, db: AsyncSession):
        u = await _make_user(db, reputation=SUSPENSION_THRESHOLD + 1, email="sus@test.com")
        await apply_delta(db, u.id, -2, "test_event", "test")
        u = await _fresh_user(db, u.id)
        assert u.suspended_until is not None
        assert u.suspended_until > datetime.now(timezone.utc)
        assert u.is_banned is False

    async def test_triggers_ban_at_threshold(self, db: AsyncSession):
        u = await _make_user(db, reputation=AUTO_BAN_THRESHOLD + 1, email="ban@test.com")
        await apply_delta(db, u.id, -2, "test_event", "test")
        u = await _fresh_user(db, u.id)
        assert u.is_banned is True

    async def test_no_suspension_above_threshold(self, db: AsyncSession, user: User):
        await apply_delta(db, user.id, -5, "test_event", "test")
        u = await _fresh_user(db, user.id)
        assert u.suspended_until is None
        assert u.is_banned is False


# ── sync_account_status ────────────────────────────────────────────────────────

class TestSyncAccountStatus:
    async def test_suspends_users_below_threshold(self, db: AsyncSession):
        u = await _make_user(db, reputation=-35, email="s1@test.com")
        assert u.suspended_until is None

        await sync_account_status(db)

        u = await _fresh_user(db, u.id)
        assert u.suspended_until is not None
        assert u.is_banned is False

    async def test_bans_users_below_ban_threshold(self, db: AsyncSession):
        u = await _make_user(db, reputation=-55, email="b1@test.com")
        assert u.is_banned is False

        await sync_account_status(db)

        u = await _fresh_user(db, u.id)
        assert u.is_banned is True

    async def test_does_not_overwrite_existing_suspension(self, db: AsyncSession):
        future = datetime.now(timezone.utc) + timedelta(hours=10)
        u = await _make_user(db, reputation=-35, email="s2@test.com")
        u.suspended_until = future
        await db.commit()

        await sync_account_status(db)

        u = await _fresh_user(db, u.id)
        # suspended_until should not be reset to a new 48h window
        assert abs((u.suspended_until - future).total_seconds()) < 5

    async def test_does_not_touch_healthy_users(self, db: AsyncSession, user: User):
        await sync_account_status(db)
        u = await _fresh_user(db, user.id)
        assert u.suspended_until is None
        assert u.is_banned is False


# ── lift_expired_suspensions ───────────────────────────────────────────────────

class TestLiftExpiredSuspensions:
    async def test_clears_expired_suspension(self, db: AsyncSession):
        u = await _make_user(db, reputation=-35, email="exp@test.com")
        u.suspended_until = datetime.now(timezone.utc) - timedelta(seconds=1)
        await db.commit()

        await lift_expired_suspensions(db)

        u = await _fresh_user(db, u.id)
        assert u.suspended_until is None

    async def test_does_not_clear_active_suspension(self, db: AsyncSession):
        u = await _make_user(db, reputation=-35, email="act@test.com")
        future = datetime.now(timezone.utc) + timedelta(hours=24)
        u.suspended_until = future
        await db.commit()

        await lift_expired_suspensions(db)

        u = await _fresh_user(db, u.id)
        assert u.suspended_until is not None


# ── process_report_outcomes ────────────────────────────────────────────────────

class TestProcessReportOutcomes:
    async def _make_report(self, db: AsyncSession, beach: Beach, user: User, upvotes=0, downvotes=0) -> Report:
        r = Report(
            beach_id=beach.id,
            user_id=user.id,
            type="jellyfish",
            severity=1,
            upvotes=upvotes,
            downvotes=downvotes,
            expires_at=datetime.now(timezone.utc) + timedelta(hours=2),
        )
        db.add(r)
        await db.commit()
        await db.refresh(r)
        return r

    async def test_awards_delta_for_confirmed_report(self, db: AsyncSession, beach: Beach, user: User):
        await self._make_report(db, beach, user, upvotes=3, downvotes=0)
        await process_report_outcomes(db)
        u = await _fresh_user(db, user.id)
        assert u.reputation == DELTA_REPORT_CONFIRMED
        assert u.confirmed_reports == 1

    async def test_deducts_delta_for_contradicted_report(self, db: AsyncSession, beach: Beach, user: User):
        await self._make_report(db, beach, user, upvotes=0, downvotes=4)
        await process_report_outcomes(db)
        u = await _fresh_user(db, user.id)
        assert u.reputation == DELTA_REPORT_CONTRADICTED
        assert u.false_reports == 1

    async def test_no_delta_for_borderline_report(self, db: AsyncSession, beach: Beach, user: User):
        await self._make_report(db, beach, user, upvotes=1, downvotes=1)
        await process_report_outcomes(db)
        u = await _fresh_user(db, user.id)
        assert u.reputation == 0

    async def test_no_double_scoring(self, db: AsyncSession, beach: Beach, user: User):
        await self._make_report(db, beach, user, upvotes=3)
        await process_report_outcomes(db)
        await process_report_outcomes(db)
        events = await _rep_events(db, user.id, "report_confirmed")
        assert len(events) == 1

    async def test_expires_contradicted_report(self, db: AsyncSession, beach: Beach, user: User):
        report = await self._make_report(db, beach, user, upvotes=0, downvotes=4)
        await process_report_outcomes(db)
        result = await db.execute(select(Report).where(Report.id == report.id))
        assert result.scalar_one().is_expired is True


# ── process_flag_outcomes ──────────────────────────────────────────────────────

class TestProcessFlagOutcomes:
    async def test_deducts_delta_for_rejected_proposal(self, db: AsyncSession, beach: Beach, user: User):
        proposal = FlagProposal(
            beach_id=beach.id,
            user_id=user.id,
            proposed_color="yellow",
            initial_weight=1.5,
            status="rejected",
        )
        db.add(proposal)
        await db.commit()

        await process_flag_outcomes(db)

        u = await _fresh_user(db, user.id)
        assert u.reputation == DELTA_FLAG_CONTRADICTED

    async def test_no_delta_for_pending_proposal(self, db: AsyncSession, beach: Beach, user: User):
        proposal = FlagProposal(
            beach_id=beach.id,
            user_id=user.id,
            proposed_color="yellow",
            initial_weight=1.5,
            status="pending",
        )
        db.add(proposal)
        await db.commit()

        await process_flag_outcomes(db)

        u = await _fresh_user(db, user.id)
        assert u.reputation == 0

    async def test_no_double_scoring_rejected_proposal(self, db: AsyncSession, beach: Beach, user: User):
        proposal = FlagProposal(
            beach_id=beach.id,
            user_id=user.id,
            proposed_color="yellow",
            initial_weight=1.5,
            status="rejected",
        )
        db.add(proposal)
        await db.commit()

        await process_flag_outcomes(db)
        await process_flag_outcomes(db)

        events = await _rep_events(db, user.id, "flag_contradicted")
        assert len(events) == 1


# ── Report submission bonuses ──────────────────────────────────────────────────

class TestReportSubmissionBonuses:
    async def test_first_report_bonus(
        self, client: AsyncClient, beach: Beach, db: AsyncSession, user: User, auth_headers: dict
    ):
        await _add_presence(db, beach, user)
        await client.post(
            "/api/v1/beaches/portinho-da-arrabida/reports",
            json={"type": "jellyfish", "severity": 1},
            headers=auth_headers,
        )
        events = await _rep_events(db, user.id, "first_report_bonus")
        assert len(events) == 1
        assert events[0].delta == DELTA_FIRST_REPORT_BONUS

    async def test_first_report_bonus_only_once(
        self, client: AsyncClient, beach: Beach, db: AsyncSession, user: User, auth_headers: dict
    ):
        await _add_presence(db, beach, user)
        for _ in range(2):
            await client.post(
                "/api/v1/beaches/portinho-da-arrabida/reports",
                json={"type": "jellyfish", "severity": 1},
                headers=auth_headers,
            )
        events = await _rep_events(db, user.id, "first_report_bonus")
        assert len(events) == 1

    async def test_report_submitted_bonus(
        self, client: AsyncClient, beach: Beach, db: AsyncSession, user: User, auth_headers: dict
    ):
        await _add_presence(db, beach, user)
        await client.post(
            "/api/v1/beaches/portinho-da-arrabida/reports",
            json={"type": "jellyfish", "severity": 1},
            headers=auth_headers,
        )
        events = await _rep_events(db, user.id, "report_submitted")
        assert len(events) == 1
        assert events[0].delta == DELTA_REPORT_SUBMITTED

    async def test_report_submitted_bonus_capped_at_3_per_day(
        self, client: AsyncClient, beach: Beach, db: AsyncSession, user: User, auth_headers: dict
    ):
        await _add_presence(db, beach, user)
        for _ in range(4):
            await client.post(
                "/api/v1/beaches/portinho-da-arrabida/reports",
                json={"type": "jellyfish", "severity": 1},
                headers=auth_headers,
            )
        events = await _rep_events(db, user.id, "report_submitted")
        assert len(events) == 3


# ── Account status enforcement (API) ──────────────────────────────────────────

class TestAccountStatusEnforcement:
    async def test_banned_user_cannot_access_protected_endpoint(
        self, client: AsyncClient, beach: Beach, db: AsyncSession
    ):
        u = await _make_user(db, email="banned@test.com")
        u.is_banned = True
        u.ban_reason = "Test ban"
        await db.commit()

        token = create_access_token(u.id, u.reputation, u.is_anonymous)
        headers = {"Authorization": f"Bearer {token}"}

        r = await client.get("/api/v1/beaches/portinho-da-arrabida/reports", headers=headers)
        assert r.status_code == 403
        assert r.json()["detail"]["code"] == "account_banned"

    async def test_suspended_user_cannot_access_protected_endpoint(
        self, client: AsyncClient, beach: Beach, db: AsyncSession
    ):
        u = await _make_user(db, email="susp@test.com")
        u.suspended_until = datetime.now(timezone.utc) + timedelta(hours=24)
        await db.commit()

        token = create_access_token(u.id, u.reputation, u.is_anonymous)
        headers = {"Authorization": f"Bearer {token}"}

        r = await client.get("/api/v1/beaches/portinho-da-arrabida/reports", headers=headers)
        assert r.status_code == 403
        body = r.json()["detail"]
        assert body["code"] == "account_suspended"
        assert "suspended_until" in body

    async def test_user_with_expired_suspension_can_access(
        self, client: AsyncClient, beach: Beach, db: AsyncSession
    ):
        u = await _make_user(db, email="unsusp@test.com")
        u.suspended_until = datetime.now(timezone.utc) - timedelta(seconds=1)
        await db.commit()

        token = create_access_token(u.id, u.reputation, u.is_anonymous)
        headers = {"Authorization": f"Bearer {token}"}

        r = await client.get("/api/v1/beaches/portinho-da-arrabida/reports", headers=headers)
        assert r.status_code == 200

    async def test_banned_user_cannot_login(
        self, client: AsyncClient, db: AsyncSession
    ):
        u = await _make_user(db, email="banned2@test.com")
        u.is_banned = True
        u.ban_reason = "Test"
        await db.commit()

        r = await client.post(
            "/api/v1/auth/login",
            json={"email": "banned2@test.com", "password": "pw"},
        )
        assert r.status_code == 403
        assert r.json()["detail"]["code"] == "account_banned"

    async def test_suspended_user_cannot_login(
        self, client: AsyncClient, db: AsyncSession
    ):
        u = await _make_user(db, email="susp2@test.com")
        u.suspended_until = datetime.now(timezone.utc) + timedelta(hours=24)
        await db.commit()

        r = await client.post(
            "/api/v1/auth/login",
            json={"email": "susp2@test.com", "password": "pw"},
        )
        assert r.status_code == 403
        assert r.json()["detail"]["code"] == "account_suspended"

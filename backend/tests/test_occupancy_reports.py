"""Tests for crowdsourced occupancy reports and blend logic."""
import pytest
from datetime import timedelta
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.beach import Beach
from app.models.beach_status import OccupancyHeartbeat, OccupancyReport
from app.models.user import User
from app.core.security import create_access_token
from app.core.utils import now_utc
from app.core.db_helpers import compute_occupancy, _reputation_weight, _level_from_report_score, _blend_levels


#  Unit tests: pure blend helpers 

class TestBlendHelpers:
    def test_reputation_weight_tiers(self):
        assert _reputation_weight(-10) == 0.1   # banned/problematic
        assert _reputation_weight(0) == 0.5     # novo
        assert _reputation_weight(9) == 0.5     # still novo
        assert _reputation_weight(10) == 1.0    # regular
        assert _reputation_weight(49) == 1.0    # still regular
        assert _reputation_weight(50) == 1.5    # contribuidor
        assert _reputation_weight(150) == 2.0   # veterano

    def test_level_from_report_score(self):
        assert _level_from_report_score(1.0) == "low"
        assert _level_from_report_score(2.0) == "low"
        assert _level_from_report_score(2.5) == "medium"
        assert _level_from_report_score(3.5) == "medium"
        assert _level_from_report_score(3.6) == "high"
        assert _level_from_report_score(5.0) == "high"

    def test_blend_levels_full_confidence_uses_report(self):
        # At confidence=1.0 the blend is entirely the report level
        result = _blend_levels("low", "high", 1.0)
        assert result == "high"

    def test_blend_levels_zero_confidence_uses_heartbeat(self):
        result = _blend_levels("high", "low", 0.0)
        assert result == "high"

    def test_blend_levels_medium_confidence_interpolates(self):
        # low(1) + high(3) at 50% confidence → 2.0 → "medium"
        result = _blend_levels("low", "high", 0.5)
        assert result == "medium"

    def test_blend_levels_unknown_heartbeat_falls_through(self):
        result = _blend_levels("unknown", "low", 0.5)
        assert result == "low"


#  Integration: compute_occupancy with reports 

class TestComputeOccupancyBlend:
    async def test_no_data_returns_unknown(self, db: AsyncSession, beach: Beach):
        data = await compute_occupancy(db, beach)
        assert data.level == "unknown"
        assert data.user_count == 0
        assert data.report_count == 0
        assert data.report_confidence == 0.0

    async def test_heartbeat_only_no_reports(self, db: AsyncSession, beach: Beach):
        user = User(email="hb@test.com", is_anonymous=False, reputation=10)
        db.add(user)
        await db.flush()
        db.add(OccupancyHeartbeat(beach_id=beach.id, user_id=user.id))
        await db.commit()

        data = await compute_occupancy(db, beach)
        assert data.level == "low"
        assert data.user_count == 1
        assert data.report_count == 0

    async def test_single_high_report_boosts_level(self, db: AsyncSession, beach: Beach):
        # Create enough users to reach high confidence with one "cheia" (5) report
        # Need total_weight >= 0.8 * CONFIDENCE_THRESHOLD (3.0) = 2.4
        # A veterano user (rep=150) → weight=2.0, decay~1.0 → confidence = 2.0/3.0 = 0.67
        # That's between 0.2 and 0.8 → blend. With 3+ veteranos we get full confidence.
        users = []
        for i in range(3):
            u = User(email=f"vet{i}@test.com", is_anonymous=False, reputation=150)
            db.add(u)
            users.append(u)
        await db.flush()

        for u in users:
            db.add(OccupancyReport(beach_id=beach.id, user_id=u.id, level=5))
        await db.commit()

        data = await compute_occupancy(db, beach)
        assert data.level == "high"
        assert data.report_count == 3
        assert data.report_confidence == 1.0

    async def test_low_reports_override_heartbeat_signal(self, db: AsyncSession, beach: Beach):
        # 3 regular users report "vazia" (1) with heartbeat showing some users
        users = []
        for i in range(3):
            u = User(email=f"low{i}@test.com", is_anonymous=False, reputation=50)
            db.add(u)
            users.append(u)
        hb_user = User(email="hb_extra@test.com", is_anonymous=False, reputation=10)
        db.add(hb_user)
        await db.flush()

        # Heartbeat signal: 1 user → "low" anyway
        db.add(OccupancyHeartbeat(beach_id=beach.id, user_id=hb_user.id))
        for u in users:
            db.add(OccupancyReport(beach_id=beach.id, user_id=u.id, level=1))
        await db.commit()

        data = await compute_occupancy(db, beach)
        assert data.level == "low"
        assert data.report_count == 3

    async def test_expired_reports_not_counted(self, db: AsyncSession, beach: Beach):
        u = User(email="old@test.com", is_anonymous=False, reputation=150)
        db.add(u)
        await db.flush()

        # Insert a report with old created_at (3 hours ago)
        old_report = OccupancyReport(beach_id=beach.id, user_id=u.id, level=5)
        db.add(old_report)
        await db.commit()
        await db.refresh(old_report)

        # Manually age it
        from sqlalchemy import update
        await db.execute(
            update(OccupancyReport)
            .where(OccupancyReport.id == old_report.id)
            .values(created_at=now_utc() - timedelta(hours=3))
        )
        await db.commit()

        data = await compute_occupancy(db, beach)
        assert data.report_count == 0
        assert data.report_confidence == 0.0

    async def test_reputation_weighing_low_rep_has_less_impact(self, db: AsyncSession, beach: Beach):
        # 1 veterano reporting "high" vs 5 novos reporting "low"
        vet = User(email="vet@test.com", is_anonymous=False, reputation=150)
        db.add(vet)
        novos = []
        for i in range(5):
            u = User(email=f"novo{i}@test.com", is_anonymous=False, reputation=5)
            db.add(u)
            novos.append(u)
        await db.flush()

        db.add(OccupancyReport(beach_id=beach.id, user_id=vet.id, level=5))
        for u in novos:
            db.add(OccupancyReport(beach_id=beach.id, user_id=u.id, level=1))
        await db.commit()

        # veterano weight=2.0, novos weight=5*0.5=2.5 each at level=1
        # weighted_sum = 2.0*5 + 2.5*1 = 10 + 2.5 = 12.5
        # total_weight = 2.0 + 2.5 = 4.5 → confidence = min(1, 4.5/3) = 1.0
        # avg = 12.5/4.5 ≈ 2.78 → "medium"
        data = await compute_occupancy(db, beach)
        assert data.report_count == 6
        assert data.level == "medium"


#  API endpoint tests 

class TestOccupancyReportEndpoint:
    async def test_requires_auth(self, client: AsyncClient, beach: Beach):
        r = await client.post(
            "/api/v1/beaches/portinho-da-arrabida/occupancy/report",
            json={"level": 3},
        )
        assert r.status_code == 401

    async def test_requires_presence(
        self, client: AsyncClient, beach: Beach, auth_headers: dict
    ):
        # No heartbeat → 403 not_present
        r = await client.post(
            "/api/v1/beaches/portinho-da-arrabida/occupancy/report",
            json={"level": 3},
            headers=auth_headers,
        )
        assert r.status_code == 403
        assert r.json()["detail"]["code"] == "occupancy_must_be_at_beach"

    async def test_rejects_invalid_level(
        self, client: AsyncClient, beach: Beach, auth_headers: dict, db: AsyncSession, user: User
    ):
        db.add(OccupancyHeartbeat(beach_id=beach.id, user_id=user.id))
        await db.commit()

        for bad_level in [0, 6, -1]:
            r = await client.post(
                "/api/v1/beaches/portinho-da-arrabida/occupancy/report",
                json={"level": bad_level},
                headers=auth_headers,
            )
            assert r.status_code == 422, f"Expected 422 for level={bad_level}"

    async def test_valid_report_returns_occupancy(
        self, client: AsyncClient, beach: Beach, auth_headers: dict, db: AsyncSession, user: User
    ):
        db.add(OccupancyHeartbeat(beach_id=beach.id, user_id=user.id))
        await db.commit()

        r = await client.post(
            "/api/v1/beaches/portinho-da-arrabida/occupancy/report",
            json={"level": 4},
            headers=auth_headers,
        )
        assert r.status_code == 200
        body = r.json()
        assert body["status"] == "ok"
        assert body["occupancy_level"] in ("low", "medium", "high", "unknown")
        assert body["report_count"] >= 1
        assert 0.0 <= body["report_confidence"] <= 1.0

    async def test_rate_limit_blocks_second_report(
        self, client: AsyncClient, beach: Beach, auth_headers: dict, db: AsyncSession, user: User
    ):
        db.add(OccupancyHeartbeat(beach_id=beach.id, user_id=user.id))
        await db.commit()

        r1 = await client.post(
            "/api/v1/beaches/portinho-da-arrabida/occupancy/report",
            json={"level": 3},
            headers=auth_headers,
        )
        assert r1.status_code == 200

        r2 = await client.post(
            "/api/v1/beaches/portinho-da-arrabida/occupancy/report",
            json={"level": 5},
            headers=auth_headers,
        )
        assert r2.status_code == 429
        assert r2.json()["detail"]["code"] == "occupancy_already_reported"

    async def test_different_users_can_report_same_beach(
        self, client: AsyncClient, beach: Beach,
        auth_headers: dict, trusted_headers: dict,
        db: AsyncSession, user: User, user_with_rep: User,
    ):
        db.add(OccupancyHeartbeat(beach_id=beach.id, user_id=user.id))
        db.add(OccupancyHeartbeat(beach_id=beach.id, user_id=user_with_rep.id))
        await db.commit()

        r1 = await client.post(
            "/api/v1/beaches/portinho-da-arrabida/occupancy/report",
            json={"level": 5},
            headers=auth_headers,
        )
        r2 = await client.post(
            "/api/v1/beaches/portinho-da-arrabida/occupancy/report",
            json={"level": 5},
            headers=trusted_headers,
        )
        assert r1.status_code == 200
        assert r2.status_code == 200
        assert r2.json()["report_count"] == 2

    async def test_nonexistent_beach_returns_404(
        self, client: AsyncClient, auth_headers: dict
    ):
        r = await client.post(
            "/api/v1/beaches/praia-inventada/occupancy/report",
            json={"level": 3},
            headers=auth_headers,
        )
        assert r.status_code == 404

    async def test_all_valid_levels_accepted(
        self, client: AsyncClient, beach: Beach, db: AsyncSession
    ):
        for level in range(1, 6):
            u = User(email=f"lvl{level}@test.com", is_anonymous=False, reputation=10)
            db.add(u)
            await db.flush()
            db.add(OccupancyHeartbeat(beach_id=beach.id, user_id=u.id))
            await db.commit()

            token = create_access_token(u.id, u.reputation, u.is_anonymous)
            r = await client.post(
                "/api/v1/beaches/portinho-da-arrabida/occupancy/report",
                json={"level": level},
                headers={"Authorization": f"Bearer {token}"},
            )
            assert r.status_code == 200, f"level={level} rejected: {r.json()}"

    async def test_report_confidence_increases_with_more_reports(
        self, client: AsyncClient, beach: Beach, db: AsyncSession
    ):
        confidences = []
        for i in range(4):
            u = User(email=f"conf{i}@test.com", is_anonymous=False, reputation=10)
            db.add(u)
            await db.flush()
            db.add(OccupancyHeartbeat(beach_id=beach.id, user_id=u.id))
            await db.commit()

            token = create_access_token(u.id, u.reputation, u.is_anonymous)
            r = await client.post(
                "/api/v1/beaches/portinho-da-arrabida/occupancy/report",
                json={"level": 3},
                headers={"Authorization": f"Bearer {token}"},
            )
            assert r.status_code == 200
            confidences.append(r.json()["report_confidence"])

        # Confidence should grow monotonically (more reports = more signal)
        assert all(confidences[i] <= confidences[i + 1] for i in range(len(confidences) - 1))
        # After enough reports it should cap at 1.0
        assert confidences[-1] == 1.0

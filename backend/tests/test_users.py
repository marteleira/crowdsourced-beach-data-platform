"""User profile and reputation endpoint tests."""
import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.user import User, ReputationEvent


class TestUserProfile:
    async def test_profile_requires_auth(self, client: AsyncClient):
        r = await client.get("/api/v1/users/me")
        assert r.status_code == 401

    async def test_profile_returns_correct_data(
        self, client: AsyncClient, auth_headers: dict, user: User
    ):
        r = await client.get("/api/v1/users/me", headers=auth_headers)
        assert r.status_code == 200
        body = r.json()
        assert body["id"] == str(user.id)
        assert body["display_name"] == "Test User"
        assert body["reputation"] == 0
        assert body["level"] == "novo"
        assert body["is_anonymous"] is False

    async def test_profile_stats_present(self, client: AsyncClient, auth_headers: dict):
        r = await client.get("/api/v1/users/me", headers=auth_headers)
        stats = r.json()["stats"]
        for key in ("total_reports", "confirmed_reports", "false_reports", "accuracy_rate"):
            assert key in stats

    async def test_profile_level_thresholds(self, client: AsyncClient, db: AsyncSession):
        from app.core.security import create_access_token

        levels = [
            (0, "novo"),
            (10, "regular"),
            (50, "contribuidor"),
            (150, "veterano"),
        ]
        for rep, expected_level in levels:
            u = User(email=f"level{rep}@test.com", is_anonymous=False, reputation=rep)
            db.add(u)
            await db.commit()   # commit so the client's independent session can find the user
            await db.refresh(u)
            token = create_access_token(u.id, rep, False)
            r = await client.get("/api/v1/users/me", headers={"Authorization": f"Bearer {token}"})
            assert r.json()["level"] == expected_level, f"rep={rep} expected {expected_level}"

        await db.commit()

    async def test_profile_includes_recent_events(
        self, client: AsyncClient, auth_headers: dict, user: User, db: AsyncSession
    ):
        evt = ReputationEvent(
            user_id=user.id,
            event="report_confirmed",
            delta=10,
            reason="Test event",
        )
        db.add(evt)
        await db.commit()

        r = await client.get("/api/v1/users/me", headers=auth_headers)
        events = r.json()["recent_events"]
        assert len(events) == 1
        assert events[0]["delta"] == 10
        assert events[0]["event"] == "report_confirmed"


class TestReputationHistory:
    async def test_history_requires_auth(self, client: AsyncClient):
        r = await client.get("/api/v1/users/me/reputation-history")
        assert r.status_code == 401

    async def test_history_empty_by_default(self, client: AsyncClient, auth_headers: dict):
        r = await client.get("/api/v1/users/me/reputation-history", headers=auth_headers)
        assert r.status_code == 200
        assert r.json() == []

    async def test_history_returns_events_in_order(
        self, client: AsyncClient, auth_headers: dict, user: User, db: AsyncSession
    ):
        for i, delta in enumerate([10, -5, 15]):
            db.add(ReputationEvent(
                user_id=user.id, event="report_confirmed", delta=delta, reason=f"event {i}"
            ))
        await db.commit()

        r = await client.get("/api/v1/users/me/reputation-history", headers=auth_headers)
        events = r.json()
        assert len(events) == 3
        assert {e["delta"] for e in events} == {10, -5, 15}

    async def test_history_pagination(
        self, client: AsyncClient, auth_headers: dict, user: User, db: AsyncSession
    ):
        for i in range(25):
            db.add(ReputationEvent(
                user_id=user.id, event="report_confirmed", delta=1, reason=f"evt {i}"
            ))
        await db.commit()

        r = await client.get(
            "/api/v1/users/me/reputation-history?limit=10&offset=0", headers=auth_headers
        )
        assert len(r.json()) == 10

        r2 = await client.get(
            "/api/v1/users/me/reputation-history?limit=10&offset=10", headers=auth_headers
        )
        assert len(r2.json()) == 10

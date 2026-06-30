"""Flag system tests."""
from datetime import datetime, timedelta, timezone

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.beach import Beach
from app.models.beach_status import BeachStatus, FlagConfirmation, OccupancyHeartbeat
from app.models.user import User


async def _add_heartbeat(db: AsyncSession, beach: Beach, user: User):
    hb = OccupancyHeartbeat(
        beach_id=beach.id,
        user_id=user.id,
        geom="SRID=4326;POINT(-8.9821 38.4839)",
    )
    db.add(hb)
    await db.commit()


class TestGetFlag:
    async def test_get_flag_unknown_when_no_status(self, client: AsyncClient, beach: Beach):
        r = await client.get("/api/v1/beaches/portinho-da-arrabida/flag")
        assert r.status_code == 200
        assert r.json()["flag_color"] == "unknown"

    async def test_get_flag_reflects_current_status(
        self, client: AsyncClient, beach: Beach, beach_status: BeachStatus
    ):
        r = await client.get("/api/v1/beaches/portinho-da-arrabida/flag")
        assert r.status_code == 200
        body = r.json()
        assert body["flag_color"] == "green"
        assert body["flag_confidence"] == pytest.approx(0.8)

    async def test_get_flag_nonexistent_beach(self, client: AsyncClient):
        r = await client.get("/api/v1/beaches/praia-fake/flag")
        assert r.status_code == 404


class TestProposeFlag:
    async def test_propose_requires_auth(self, client: AsyncClient, beach: Beach):
        r = await client.post(
            "/api/v1/beaches/portinho-da-arrabida/flag/propose",
            json={"color": "yellow"},
        )
        assert r.status_code == 401

    async def test_propose_requires_minimum_reputation(
        self, client: AsyncClient, beach: Beach, auth_headers: dict, db: AsyncSession, user: User
    ):
        await _add_heartbeat(db, beach, user)
        r = await client.post(
            "/api/v1/beaches/portinho-da-arrabida/flag/propose",
            json={"color": "yellow"},
            headers=auth_headers,
        )
        assert r.status_code == 403

    async def test_propose_requires_presence(
        self, client: AsyncClient, beach: Beach, trusted_headers: dict
    ):
        r = await client.post(
            "/api/v1/beaches/portinho-da-arrabida/flag/propose",
            json={"color": "yellow"},
            headers=trusted_headers,
        )
        assert r.status_code == 403

    async def test_propose_succeeds_with_rep_and_presence(
        self, client: AsyncClient, beach: Beach, db: AsyncSession,
        trusted_headers: dict, user_with_rep: User
    ):
        await _add_heartbeat(db, beach, user_with_rep)
        r = await client.post(
            "/api/v1/beaches/portinho-da-arrabida/flag/propose",
            json={"color": "yellow"},
            headers=trusted_headers,
        )
        assert r.status_code == 201
        assert r.json()["status"] in ("pending", "applied")

    async def test_propose_invalid_color(
        self, client: AsyncClient, beach: Beach, db: AsyncSession,
        trusted_headers: dict, user_with_rep: User
    ):
        await _add_heartbeat(db, beach, user_with_rep)
        r = await client.post(
            "/api/v1/beaches/portinho-da-arrabida/flag/propose",
            json={"color": "blue"},
            headers=trusted_headers,
        )
        assert r.status_code == 422


class TestConfirmFlag:
    async def test_confirm_requires_auth(self, client: AsyncClient, beach: Beach, beach_status: BeachStatus):
        r = await client.post(
            "/api/v1/beaches/portinho-da-arrabida/flag/confirm",
            json={"response": "yes"},
        )
        assert r.status_code == 401

    async def test_confirm_requires_presence(
        self, client: AsyncClient, beach: Beach, beach_status: BeachStatus, auth_headers: dict
    ):
        r = await client.post(
            "/api/v1/beaches/portinho-da-arrabida/flag/confirm",
            json={"response": "yes"},
            headers=auth_headers,
        )
        assert r.status_code == 403

    async def test_confirm_flag_yes(
        self, client: AsyncClient, beach: Beach, beach_status: BeachStatus,
        db: AsyncSession, auth_headers: dict, user: User
    ):
        await _add_heartbeat(db, beach, user)
        r = await client.post(
            "/api/v1/beaches/portinho-da-arrabida/flag/confirm",
            json={"response": "yes"},
            headers=auth_headers,
        )
        assert r.status_code == 201
        assert "new_confidence" in r.json()

    async def test_confirm_flag_all_responses_valid(
        self, client: AsyncClient, beach: Beach, beach_status: BeachStatus,
        db: AsyncSession
    ):
        # Three different users confirming with different responses
        from app.core.security import create_access_token
        import uuid

        for i, response in enumerate(("yes", "no", "unsure")):
            u = User(email=f"u{i}@test.com", is_anonymous=False, reputation=0)
            db.add(u)
            await db.commit()   # commit so the client's session can find the user
            await db.refresh(u)
            await _add_heartbeat(db, beach, u)
            token = create_access_token(u.id, 0, False)
            r = await client.post(
                "/api/v1/beaches/portinho-da-arrabida/flag/confirm",
                json={"response": response},
                headers={"Authorization": f"Bearer {token}"},
            )
            assert r.status_code == 201

        await db.commit()

    async def test_confirm_rate_limited_per_hour(
        self, client: AsyncClient, beach: Beach, beach_status: BeachStatus,
        db: AsyncSession, auth_headers: dict, user: User
    ):
        await _add_heartbeat(db, beach, user)
        await client.post(
            "/api/v1/beaches/portinho-da-arrabida/flag/confirm",
            json={"response": "yes"}, headers=auth_headers,
        )
        r = await client.post(
            "/api/v1/beaches/portinho-da-arrabida/flag/confirm",
            json={"response": "yes"}, headers=auth_headers,
        )
        assert r.status_code == 429

    async def test_confirm_unknown_flag_returns_400(
        self, client: AsyncClient, beach: Beach, db: AsyncSession,
        auth_headers: dict, user: User
    ):
        await _add_heartbeat(db, beach, user)
        r = await client.post(
            "/api/v1/beaches/portinho-da-arrabida/flag/confirm",
            json={"response": "yes"}, headers=auth_headers,
        )
        assert r.status_code == 400

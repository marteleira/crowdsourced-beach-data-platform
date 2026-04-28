"""Occupancy heartbeat tests."""
import pytest
from httpx import AsyncClient
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.beach import Beach
from app.models.beach_status import OccupancyHeartbeat
from app.models.user import User


class TestHeartbeat:
    async def test_heartbeat_requires_auth(self, client: AsyncClient, beach: Beach):
        r = await client.post(
            "/api/v1/beaches/portinho-da-arrabida/occupancy/heartbeat",
            json={"lat": 38.4839, "lon": -8.9821},
        )
        assert r.status_code == 401

    async def test_heartbeat_creates_record(
        self, client: AsyncClient, beach: Beach, auth_headers: dict, db: AsyncSession
    ):
        r = await client.post(
            "/api/v1/beaches/portinho-da-arrabida/occupancy/heartbeat",
            json={"lat": 38.4839, "lon": -8.9821},
            headers=auth_headers,
        )
        assert r.status_code == 200

        count = await db.execute(
            select(func.count(OccupancyHeartbeat.id)).where(
                OccupancyHeartbeat.beach_id == beach.id
            )
        )
        assert count.scalar_one() == 1

    async def test_heartbeat_returns_occupancy_level(
        self, client: AsyncClient, beach: Beach, auth_headers: dict
    ):
        r = await client.post(
            "/api/v1/beaches/portinho-da-arrabida/occupancy/heartbeat",
            json={"lat": 38.4839, "lon": -8.9821},
            headers=auth_headers,
        )
        body = r.json()
        assert body["status"] == "ok"
        assert body["beach_id"] == beach.id
        assert body["occupancy_level"] in ("low", "medium", "high", "unknown")
        assert isinstance(body["user_count"], int)

    async def test_heartbeat_low_with_few_users(
        self, client: AsyncClient, beach: Beach, auth_headers: dict
    ):
        r = await client.post(
            "/api/v1/beaches/portinho-da-arrabida/occupancy/heartbeat",
            json={"lat": 38.4839, "lon": -8.9821},
            headers=auth_headers,
        )
        assert r.json()["occupancy_level"] == "low"

    async def test_heartbeat_nonexistent_beach(self, client: AsyncClient, auth_headers: dict):
        r = await client.post(
            "/api/v1/beaches/praia-fake/occupancy/heartbeat",
            json={"lat": 38.0, "lon": -9.0},
            headers=auth_headers,
        )
        assert r.status_code == 404

    async def test_multiple_users_increase_count(
        self, client: AsyncClient, beach: Beach, db: AsyncSession
    ):
        from app.core.security import create_access_token

        tokens = []
        for i in range(5):
            u = User(email=f"beach{i}@test.com", is_anonymous=False, reputation=0)
            db.add(u)
            await db.flush()
            tokens.append(create_access_token(u.id, 0, False))
        await db.commit()

        for token in tokens:
            await client.post(
                "/api/v1/beaches/portinho-da-arrabida/occupancy/heartbeat",
                json={"lat": 38.4839, "lon": -8.9821},
                headers={"Authorization": f"Bearer {token}"},
            )

        r = await client.post(
            "/api/v1/beaches/portinho-da-arrabida/occupancy/heartbeat",
            json={"lat": 38.4839, "lon": -8.9821},
            headers={"Authorization": f"Bearer {tokens[0]}"},
        )
        assert r.json()["user_count"] >= 5

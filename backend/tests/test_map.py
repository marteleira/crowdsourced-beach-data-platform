"""Map users endpoint tests."""
import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.beach import Beach
from app.models.beach_status import OccupancyHeartbeat
from app.models.user import User


async def _add_heartbeat(db: AsyncSession, beach: Beach, user: User):
    hb = OccupancyHeartbeat(
        beach_id=beach.id, user_id=user.id,
        geom="SRID=4326;POINT(-8.9821 38.4839)",
    )
    db.add(hb)
    await db.commit()


class TestMapUsers:
    async def test_empty_when_no_heartbeats(self, client: AsyncClient, beach: Beach):
        r = await client.get("/api/v1/map/users")
        assert r.status_code == 200
        assert r.json() == []

    async def test_shows_beach_with_active_user(
        self, client: AsyncClient, beach: Beach, db: AsyncSession, user: User
    ):
        await _add_heartbeat(db, beach, user)
        r = await client.get("/api/v1/map/users")
        assert r.status_code == 200
        data = r.json()
        assert len(data) == 1
        assert data[0]["beach_slug"] == beach.slug
        assert data[0]["user_count"] == 1

    async def test_user_with_share_presence_false_hidden(
        self, client: AsyncClient, beach: Beach, db: AsyncSession, user: User
    ):
        user.privacy_settings = {"share_presence": False, "location_accuracy": "approximate",
                                  "name_public": True, "avatar_public": True, "share_usage_data": True}
        db.add(user)
        await db.commit()
        await _add_heartbeat(db, beach, user)

        r = await client.get("/api/v1/map/users")
        assert r.status_code == 200
        assert r.json() == []

    async def test_anonymous_user_has_no_name(
        self, client: AsyncClient, beach: Beach, db: AsyncSession, user: User
    ):
        user.privacy_settings = {"share_presence": True, "location_accuracy": "approximate",
                                  "name_public": False, "avatar_public": True, "share_usage_data": True}
        db.add(user)
        await db.commit()
        await _add_heartbeat(db, beach, user)

        r = await client.get("/api/v1/map/users")
        assert r.status_code == 200
        beach_data = r.json()[0]
        for u in beach_data["users"]:
            assert u["display_name"] is None

    async def test_endpoint_accessible_without_auth(self, client: AsyncClient, beach: Beach):
        r = await client.get("/api/v1/map/users")
        assert r.status_code == 200

    async def test_response_has_required_fields(
        self, client: AsyncClient, beach: Beach, db: AsyncSession, user: User
    ):
        await _add_heartbeat(db, beach, user)
        r = await client.get("/api/v1/map/users")
        item = r.json()[0]
        for field in ("beach_id", "beach_slug", "beach_name", "lat", "lon", "user_count", "users"):
            assert field in item, f"missing field: {field}"

"""Favourites endpoints tests."""
import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.beach import Beach
from app.models.user import User
from app.models.user_extended import UserFavourite


class TestFavourites:
    async def test_list_empty_by_default(self, client: AsyncClient, auth_headers: dict):
        r = await client.get("/api/v1/users/me/favourites", headers=auth_headers)
        assert r.status_code == 200
        assert r.json() == []

    async def test_requires_auth(self, client: AsyncClient):
        r = await client.get("/api/v1/users/me/favourites")
        assert r.status_code == 401

    async def test_add_favourite(self, client: AsyncClient, beach: Beach, auth_headers: dict):
        r = await client.post(
            f"/api/v1/users/me/favourites/{beach.slug}", headers=auth_headers
        )
        assert r.status_code == 201
        assert r.json()["beach_slug"] == beach.slug

    async def test_add_duplicate_returns_409(
        self, client: AsyncClient, beach: Beach, auth_headers: dict
    ):
        await client.post(f"/api/v1/users/me/favourites/{beach.slug}", headers=auth_headers)
        r = await client.post(f"/api/v1/users/me/favourites/{beach.slug}", headers=auth_headers)
        assert r.status_code == 409

    async def test_add_nonexistent_beach(self, client: AsyncClient, auth_headers: dict):
        r = await client.post("/api/v1/users/me/favourites/praia-fake", headers=auth_headers)
        assert r.status_code == 404

    async def test_list_returns_added_beach(
        self, client: AsyncClient, beach: Beach, auth_headers: dict
    ):
        await client.post(f"/api/v1/users/me/favourites/{beach.slug}", headers=auth_headers)
        r = await client.get("/api/v1/users/me/favourites", headers=auth_headers)
        assert r.status_code == 200
        slugs = [b["slug"] for b in r.json()]
        assert beach.slug in slugs

    async def test_remove_favourite(self, client: AsyncClient, beach: Beach, auth_headers: dict):
        await client.post(f"/api/v1/users/me/favourites/{beach.slug}", headers=auth_headers)
        r = await client.delete(f"/api/v1/users/me/favourites/{beach.slug}", headers=auth_headers)
        assert r.status_code == 204

        r2 = await client.get("/api/v1/users/me/favourites", headers=auth_headers)
        assert r2.json() == []

    async def test_remove_not_in_favourites_returns_404(
        self, client: AsyncClient, beach: Beach, auth_headers: dict
    ):
        r = await client.delete(f"/api/v1/users/me/favourites/{beach.slug}", headers=auth_headers)
        assert r.status_code == 404

    async def test_reorder_favourites(
        self, client: AsyncClient, db: AsyncSession, auth_headers: dict, user: User
    ):
        # Add two beaches
        b1 = Beach(slug="b1", name="B1", lat=38.48, lon=-8.98,
                   geom="SRID=4326;POINT(-8.98 38.48)", flags_available=True)
        b2 = Beach(slug="b2", name="B2", lat=38.49, lon=-8.99,
                   geom="SRID=4326;POINT(-8.99 38.49)", flags_available=True)
        db.add(b1); db.add(b2)
        await db.commit()
        await db.refresh(b1); await db.refresh(b2)

        await client.post("/api/v1/users/me/favourites/b1", headers=auth_headers)
        await client.post("/api/v1/users/me/favourites/b2", headers=auth_headers)

        r = await client.patch(
            "/api/v1/users/me/favourites/order",
            json={"ordered_slugs": ["b2", "b1"]},
            headers=auth_headers,
        )
        assert r.status_code == 200

        r2 = await client.get("/api/v1/users/me/favourites", headers=auth_headers)
        slugs = [b["slug"] for b in r2.json()]
        assert slugs[0] == "b2"

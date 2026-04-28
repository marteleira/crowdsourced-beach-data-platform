"""Authentication endpoint tests."""
from unittest.mock import patch

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.user import User


class TestGuestAuth:
    async def test_create_guest_returns_tokens(self, client: AsyncClient):
        r = await client.post("/api/v1/auth/guest", json={"device_id": "device-abc"})
        assert r.status_code == 200
        body = r.json()
        assert "access_token" in body
        assert "refresh_token" in body
        assert body["is_anonymous"] is True

    async def test_same_device_id_reuses_user(self, client: AsyncClient, db: AsyncSession):
        await client.post("/api/v1/auth/guest", json={"device_id": "device-xyz"})
        await client.post("/api/v1/auth/guest", json={"device_id": "device-xyz"})

        from sqlalchemy import select, func
        result = await db.execute(
            select(func.count(User.id)).where(User.device_id == "device-xyz")
        )
        assert result.scalar_one() == 1


class TestRegister:
    async def test_register_success(self, client: AsyncClient):
        r = await client.post("/api/v1/auth/register", json={
            "email": "new@example.com",
            "password": "strongpass",
            "display_name": "New User",
        })
        assert r.status_code == 201
        assert r.json()["is_anonymous"] is False

    async def test_register_duplicate_email(self, client: AsyncClient, user: User):
        r = await client.post("/api/v1/auth/register", json={
            "email": "test@example.com",
            "password": "strongpass",
            "display_name": "Dup",
        })
        assert r.status_code == 409

    async def test_register_short_password(self, client: AsyncClient):
        r = await client.post("/api/v1/auth/register", json={
            "email": "short@example.com",
            "password": "123",
            "display_name": "Short",
        })
        assert r.status_code == 422


class TestLogin:
    async def test_login_success(self, client: AsyncClient, user: User):
        r = await client.post("/api/v1/auth/login", json={
            "email": "test@example.com",
            "password": "password123",
        })
        assert r.status_code == 200
        assert "access_token" in r.json()

    async def test_login_wrong_password(self, client: AsyncClient, user: User):
        r = await client.post("/api/v1/auth/login", json={
            "email": "test@example.com",
            "password": "wrongpass",
        })
        assert r.status_code == 401

    async def test_login_unknown_email(self, client: AsyncClient):
        r = await client.post("/api/v1/auth/login", json={
            "email": "nobody@example.com",
            "password": "password123",
        })
        assert r.status_code == 401


class TestGoogleLogin:
    async def test_google_login_creates_user(self, client: AsyncClient):
        fake_payload = {"sub": "google-uid-123", "email": "google@example.com", "name": "Google User"}
        with patch("app.api.auth.verify_google_id_token", return_value=fake_payload):
            r = await client.post("/api/v1/auth/google", json={"id_token": "fake-token"})
        assert r.status_code == 200
        assert r.json()["is_anonymous"] is False

    async def test_google_login_links_existing_email(self, client: AsyncClient, user: User):
        fake_payload = {"sub": "google-uid-456", "email": "test@example.com", "name": "Test User"}
        with patch("app.api.auth.verify_google_id_token", return_value=fake_payload):
            r = await client.post("/api/v1/auth/google", json={"id_token": "fake-token"})
        assert r.status_code == 200

    async def test_google_login_invalid_token(self, client: AsyncClient):
        with patch("app.api.auth.verify_google_id_token", side_effect=ValueError("bad token")):
            r = await client.post("/api/v1/auth/google", json={"id_token": "bad"})
        assert r.status_code == 401


class TestRefreshAndLogout:
    async def test_refresh_returns_new_tokens(self, client: AsyncClient, user: User):
        login = await client.post("/api/v1/auth/login", json={
            "email": "test@example.com", "password": "password123"
        })
        old_refresh = login.json()["refresh_token"]

        r = await client.post("/api/v1/auth/refresh", json={"refresh_token": old_refresh})
        assert r.status_code == 200
        # A new refresh token is always issued (token rotation)
        assert r.json()["refresh_token"] != old_refresh

    async def test_refresh_token_can_only_be_used_once(self, client: AsyncClient, user: User):
        login = await client.post("/api/v1/auth/login", json={
            "email": "test@example.com", "password": "password123"
        })
        refresh_token = login.json()["refresh_token"]

        await client.post("/api/v1/auth/refresh", json={"refresh_token": refresh_token})
        r = await client.post("/api/v1/auth/refresh", json={"refresh_token": refresh_token})
        assert r.status_code == 401

    async def test_logout_invalidates_refresh_token(self, client: AsyncClient, user: User):
        login = await client.post("/api/v1/auth/login", json={
            "email": "test@example.com", "password": "password123"
        })
        refresh_token = login.json()["refresh_token"]

        await client.post("/api/v1/auth/logout", json={"refresh_token": refresh_token})
        r = await client.post("/api/v1/auth/refresh", json={"refresh_token": refresh_token})
        assert r.status_code == 401

    async def test_refresh_invalid_token(self, client: AsyncClient):
        r = await client.post("/api/v1/auth/refresh", json={"refresh_token": "notavalidtoken"})
        assert r.status_code == 401


class TestPromote:
    async def test_promote_guest_to_full_account(self, client: AsyncClient, db: AsyncSession):
        guest = await client.post("/api/v1/auth/guest", json={"device_id": "promo-device"})
        token = guest.json()["access_token"]

        r = await client.post(
            "/api/v1/auth/promote",
            json={"email": "promoted@example.com", "password": "password123", "display_name": "Promoted"},
            headers={"Authorization": f"Bearer {token}"},
        )
        assert r.status_code == 200
        assert r.json()["is_anonymous"] is False

    async def test_promote_fails_for_registered_user(self, client: AsyncClient, auth_headers: dict):
        r = await client.post(
            "/api/v1/auth/promote",
            json={"email": "other@example.com", "password": "password123", "display_name": "X"},
            headers=auth_headers,
        )
        assert r.status_code == 400

    async def test_promote_fails_duplicate_email(self, client: AsyncClient, db: AsyncSession, user: User):
        guest = await client.post("/api/v1/auth/guest", json={"device_id": "promo-device-2"})
        token = guest.json()["access_token"]

        r = await client.post(
            "/api/v1/auth/promote",
            json={"email": "test@example.com", "password": "password123", "display_name": "X"},
            headers={"Authorization": f"Bearer {token}"},
        )
        assert r.status_code == 409

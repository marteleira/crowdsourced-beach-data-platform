"""Authentication endpoint tests."""
from unittest.mock import AsyncMock, patch

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import hash_verification_code
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
        with patch("app.api.auth.send_verification_email", new_callable=AsyncMock):
            r = await client.post("/api/v1/auth/register", json={
                "email": "new@example.com",
                "password": "strongpass",
                "display_name": "New User",
            })
        assert r.status_code == 201
        body = r.json()
        assert body["is_anonymous"] is False
        assert body["is_email_verified"] is False

    async def test_register_duplicate_email(self, client: AsyncClient, user: User):
        with patch("app.api.auth.send_verification_email", new_callable=AsyncMock):
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

        with patch("app.api.auth.send_verification_email", new_callable=AsyncMock):
            r = await client.post(
                "/api/v1/auth/promote",
                json={"email": "promoted@example.com", "password": "password123", "display_name": "Promoted"},
                headers={"Authorization": f"Bearer {token}"},
            )
        assert r.status_code == 200
        body = r.json()
        assert body["is_anonymous"] is False
        assert body["is_email_verified"] is False

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

        with patch("app.api.auth.send_verification_email", new_callable=AsyncMock):
            r = await client.post(
                "/api/v1/auth/promote",
                json={"email": "test@example.com", "password": "password123", "display_name": "X"},
                headers={"Authorization": f"Bearer {token}"},
            )
        assert r.status_code == 409


class TestEmailVerification:
    async def _register_unverified(self, client: AsyncClient) -> tuple[str, str]:
        """Register a new user and return (access_token, captured_code)."""
        mock_send = AsyncMock()
        with patch("app.api.auth.send_verification_email", mock_send):
            r = await client.post("/api/v1/auth/register", json={
                "email": "verify@example.com",
                "password": "password123",
                "display_name": "Verify Me",
            })
        assert r.status_code == 201
        token = r.json()["access_token"]
        # code is the second positional arg of send_verification_email(email, code)
        code = mock_send.call_args.args[1]
        return token, code

    async def test_register_email_not_verified_by_default(self, client: AsyncClient):
        with patch("app.api.auth.send_verification_email", new_callable=AsyncMock):
            r = await client.post("/api/v1/auth/register", json={
                "email": "verify@example.com",
                "password": "password123",
                "display_name": "Verify Me",
            })
        assert r.json()["is_email_verified"] is False

    async def test_verify_email_correct_code(self, client: AsyncClient):
        token, code = await self._register_unverified(client)
        r = await client.post(
            "/api/v1/auth/verify-email",
            json={"code": code},
            headers={"Authorization": f"Bearer {token}"},
        )
        assert r.status_code == 200
        assert r.json()["status"] == "verified"

    async def test_verify_email_wrong_code(self, client: AsyncClient):
        token, _ = await self._register_unverified(client)
        r = await client.post(
            "/api/v1/auth/verify-email",
            json={"code": "000000"},
            headers={"Authorization": f"Bearer {token}"},
        )
        assert r.status_code == 400

    async def test_verify_email_already_verified(self, client: AsyncClient, user: User, auth_headers: dict):
        r = await client.post(
            "/api/v1/auth/verify-email",
            json={"code": "123456"},
            headers=auth_headers,
        )
        assert r.status_code == 200
        assert r.json()["status"] == "already_verified"

    async def test_verify_email_no_pending_code(self, client: AsyncClient, db: AsyncSession):
        from app.models.user import User as UserModel
        from app.core.security import hash_password as hp
        u = UserModel(
            email="nopending@example.com",
            display_name="NoPending",
            password_hash=hp("password123"),
            is_anonymous=False,
            is_email_verified=False,
        )
        db.add(u)
        await db.commit()
        await db.refresh(u)

        login = await client.post("/api/v1/auth/login", json={
            "email": "nopending@example.com", "password": "password123"
        })
        token = login.json()["access_token"]

        r = await client.post(
            "/api/v1/auth/verify-email",
            json={"code": "123456"},
            headers={"Authorization": f"Bearer {token}"},
        )
        assert r.status_code == 400

    async def test_resend_verification_sends_new_code(self, client: AsyncClient):
        token, old_code = await self._register_unverified(client)

        mock_send = AsyncMock()
        with patch("app.api.auth.send_verification_email", mock_send):
            r = await client.post(
                "/api/v1/auth/resend-verification",
                headers={"Authorization": f"Bearer {token}"},
            )
        assert r.status_code == 200
        new_code = mock_send.call_args.args[1]

        # old code no longer works
        r = await client.post(
            "/api/v1/auth/verify-email",
            json={"code": old_code},
            headers={"Authorization": f"Bearer {token}"},
        )
        assert r.status_code == 400

        # new code works
        r = await client.post(
            "/api/v1/auth/verify-email",
            json={"code": new_code},
            headers={"Authorization": f"Bearer {token}"},
        )
        assert r.status_code == 200

    async def test_resend_verification_fails_if_already_verified(
        self, client: AsyncClient, auth_headers: dict
    ):
        r = await client.post(
            "/api/v1/auth/resend-verification",
            headers=auth_headers,
        )
        assert r.status_code == 400

    async def test_google_user_is_always_verified(self, client: AsyncClient):
        fake_payload = {"sub": "google-uid-999", "email": "gverify@example.com", "name": "GUser"}
        with patch("app.api.auth.verify_google_id_token", return_value=fake_payload):
            r = await client.post("/api/v1/auth/google", json={"id_token": "fake"})
        assert r.status_code == 200
        assert r.json()["is_email_verified"] is True

    async def test_login_token_reflects_verification_state(self, client: AsyncClient):
        token, code = await self._register_unverified(client)

        login = await client.post("/api/v1/auth/login", json={
            "email": "verify@example.com", "password": "password123"
        })
        assert login.json()["is_email_verified"] is False

        await client.post(
            "/api/v1/auth/verify-email",
            json={"code": code},
            headers={"Authorization": f"Bearer {token}"},
        )

        login2 = await client.post("/api/v1/auth/login", json={
            "email": "verify@example.com", "password": "password123"
        })
        assert login2.json()["is_email_verified"] is True

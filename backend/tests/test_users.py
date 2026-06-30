"""User profile and reputation endpoint tests."""
from unittest.mock import AsyncMock, patch

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import hash_password, create_access_token
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
        assert body["email"] == "test@example.com"
        assert body["has_password"] is True
        assert body["reputation"] == 0
        assert body["level"] == "novo"
        assert body["is_anonymous"] is False

    async def test_profile_stats_present(self, client: AsyncClient, auth_headers: dict):
        r = await client.get("/api/v1/users/me", headers=auth_headers)
        stats = r.json()["stats"]
        for key in ("total_reports", "confirmed_reports", "false_reports", "accuracy_rate"):
            assert key in stats

    async def test_profile_level_thresholds(self, client: AsyncClient, db: AsyncSession):
        levels = [
            (0, "novo"),
            (10, "regular"),
            (50, "contribuidor"),
            (150, "veterano"),
        ]
        for rep, expected_level in levels:
            u = User(email=f"level{rep}@test.com", is_anonymous=False, reputation=rep)
            db.add(u)
            await db.commit()
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
            params={"reason": "Test event"},
        )
        db.add(evt)
        await db.commit()

        r = await client.get("/api/v1/users/me", headers=auth_headers)
        events = r.json()["recent_events"]
        assert len(events) == 1
        assert events[0]["delta"] == 10
        assert events[0]["event"] == "report_confirmed"


class TestUpdateProfile:
    async def test_update_requires_auth(self, client: AsyncClient):
        r = await client.patch("/api/v1/users/me", json={"display_name": "New"})
        assert r.status_code == 401

    async def test_update_display_name(
        self, client: AsyncClient, auth_headers: dict, user: User, db: AsyncSession
    ):
        r = await client.patch(
            "/api/v1/users/me",
            json={"display_name": "Updated Name"},
            headers=auth_headers,
        )
        assert r.status_code == 200
        assert r.json()["display_name"] == "Updated Name"

    async def test_display_name_too_long(self, client: AsyncClient, auth_headers: dict):
        r = await client.patch(
            "/api/v1/users/me",
            json={"display_name": "A" * 51},
            headers=auth_headers,
        )
        assert r.status_code == 422

    async def test_update_email_requires_current_password(
        self, client: AsyncClient, auth_headers: dict
    ):
        r = await client.patch(
            "/api/v1/users/me",
            json={"email": "newemail@example.com"},
            headers=auth_headers,
        )
        assert r.status_code == 400

    async def test_update_email_wrong_password(
        self, client: AsyncClient, auth_headers: dict
    ):
        r = await client.patch(
            "/api/v1/users/me",
            json={"email": "newemail@example.com", "current_password": "wrongpass"},
            headers=auth_headers,
        )
        assert r.status_code == 401

    async def test_update_email_success(
        self, client: AsyncClient, auth_headers: dict, user: User
    ):
        with patch("app.api.users.send_verification_email", new_callable=AsyncMock):
            r = await client.patch(
                "/api/v1/users/me",
                json={"email": "newemail@example.com", "current_password": "password123"},
                headers=auth_headers,
            )
        assert r.status_code == 200
        body = r.json()
        assert body["email"] == "newemail@example.com"

    async def test_update_email_conflict(
        self, client: AsyncClient, auth_headers: dict, db: AsyncSession
    ):
        other = User(email="taken@example.com", is_anonymous=False)
        db.add(other)
        await db.commit()

        with patch("app.api.users.send_verification_email", new_callable=AsyncMock):
            r = await client.patch(
                "/api/v1/users/me",
                json={"email": "taken@example.com", "current_password": "password123"},
                headers=auth_headers,
            )
        assert r.status_code == 409

    async def test_update_email_google_account_forbidden(
        self, client: AsyncClient, db: AsyncSession
    ):
        google_user = User(
            email="google@example.com",
            google_sub="sub123",
            is_anonymous=False,
            is_email_verified=True,
        )
        db.add(google_user)
        await db.commit()
        await db.refresh(google_user)
        token = create_access_token(google_user.id, 0, False, is_email_verified=True)

        r = await client.patch(
            "/api/v1/users/me",
            json={"email": "another@example.com", "current_password": "anything"},
            headers={"Authorization": f"Bearer {token}"},
        )
        assert r.status_code == 400
        assert "Google" in r.json()["detail"]

    async def test_update_guest_forbidden(self, client: AsyncClient, db: AsyncSession):
        guest = User(device_id="dev-abc", is_anonymous=True)
        db.add(guest)
        await db.commit()
        await db.refresh(guest)
        token = create_access_token(guest.id, 0, True)

        r = await client.patch(
            "/api/v1/users/me",
            json={"display_name": "Guest"},
            headers={"Authorization": f"Bearer {token}"},
        )
        assert r.status_code == 403

    async def test_update_no_fields(self, client: AsyncClient, auth_headers: dict):
        r = await client.patch("/api/v1/users/me", json={}, headers=auth_headers)
        assert r.status_code == 400


class TestChangePassword:
    async def test_change_password_requires_auth(self, client: AsyncClient):
        r = await client.post(
            "/api/v1/users/me/change-password",
            json={"current_password": "old", "new_password": "newpassword1"},
        )
        assert r.status_code == 401

    async def test_change_password_success(
        self, client: AsyncClient, auth_headers: dict
    ):
        r = await client.post(
            "/api/v1/users/me/change-password",
            json={"current_password": "password123", "new_password": "NewStr0ng!"},
            headers=auth_headers,
        )
        assert r.status_code == 200
        assert r.json()["status"] == "ok"

    async def test_change_password_wrong_current(
        self, client: AsyncClient, auth_headers: dict
    ):
        r = await client.post(
            "/api/v1/users/me/change-password",
            json={"current_password": "wrongpass", "new_password": "NewStr0ng!"},
            headers=auth_headers,
        )
        assert r.status_code == 401

    async def test_change_password_same_as_current(
        self, client: AsyncClient, auth_headers: dict
    ):
        r = await client.post(
            "/api/v1/users/me/change-password",
            json={"current_password": "password123", "new_password": "password123"},
            headers=auth_headers,
        )
        assert r.status_code == 400

    async def test_change_password_too_short(
        self, client: AsyncClient, auth_headers: dict
    ):
        r = await client.post(
            "/api/v1/users/me/change-password",
            json={"current_password": "password123", "new_password": "short"},
            headers=auth_headers,
        )
        assert r.status_code == 422

    async def test_change_password_revokes_tokens(
        self, client: AsyncClient, auth_headers: dict, user: User, db: AsyncSession
    ):
        # Create a session first
        login_r = await client.post(
            "/api/v1/auth/login",
            json={"email": "test@example.com", "password": "password123"},
        )
        refresh_token = login_r.json()["refresh_token"]

        # Change password
        r = await client.post(
            "/api/v1/users/me/change-password",
            json={"current_password": "password123", "new_password": "NewStr0ng!"},
            headers=auth_headers,
        )
        assert r.status_code == 200

        # Old refresh token should now be invalid
        r2 = await client.post(
            "/api/v1/auth/refresh",
            json={"refresh_token": refresh_token},
        )
        assert r2.status_code == 401

    async def test_change_password_google_account_forbidden(
        self, client: AsyncClient, db: AsyncSession
    ):
        google_user = User(
            email="google2@example.com",
            google_sub="sub456",
            is_anonymous=False,
            is_email_verified=True,
        )
        db.add(google_user)
        await db.commit()
        await db.refresh(google_user)
        token = create_access_token(google_user.id, 0, False, is_email_verified=True)

        r = await client.post(
            "/api/v1/users/me/change-password",
            json={"current_password": "anything", "new_password": "NewStr0ng!"},
            headers={"Authorization": f"Bearer {token}"},
        )
        assert r.status_code == 400
        assert "Google" in r.json()["detail"]

    async def test_change_password_guest_forbidden(
        self, client: AsyncClient, db: AsyncSession
    ):
        guest = User(device_id="dev-xyz", is_anonymous=True)
        db.add(guest)
        await db.commit()
        await db.refresh(guest)
        token = create_access_token(guest.id, 0, True)

        r = await client.post(
            "/api/v1/users/me/change-password",
            json={"current_password": "anything", "new_password": "NewStr0ng!"},
            headers={"Authorization": f"Bearer {token}"},
        )
        assert r.status_code == 403


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
                user_id=user.id, event="report_confirmed", delta=delta, params={"reason": f"event {i}"}
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
                user_id=user.id, event="report_confirmed", delta=1, params={"reason": f"evt {i}"}
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

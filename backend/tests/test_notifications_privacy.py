"""Notification settings, privacy settings, push tokens and account management tests."""
import pytest
from httpx import AsyncClient
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.user import User
from app.models.report import Report
from app.models.user_extended import PushToken
from datetime import datetime, timedelta, timezone


class TestNotificationSettings:
    async def test_get_returns_defaults(self, client: AsyncClient, auth_headers: dict):
        r = await client.get("/api/v1/users/me/notification-settings", headers=auth_headers)
        assert r.status_code == 200
        body = r.json()
        assert body["global_enabled"] is True
        assert body["checkin_alerts"] is True
        assert body["min_severity"] == 1

    async def test_patch_updates_field(self, client: AsyncClient, auth_headers: dict):
        r = await client.patch(
            "/api/v1/users/me/notification-settings",
            json={"global_enabled": False, "min_severity": 2},
            headers=auth_headers,
        )
        assert r.status_code == 200
        assert r.json()["global_enabled"] is False
        assert r.json()["min_severity"] == 2

    async def test_patch_persists_across_requests(self, client: AsyncClient, auth_headers: dict):
        await client.patch(
            "/api/v1/users/me/notification-settings",
            json={"tide_alerts": False},
            headers=auth_headers,
        )
        r = await client.get("/api/v1/users/me/notification-settings", headers=auth_headers)
        assert r.json()["tide_alerts"] is False

    async def test_requires_auth(self, client: AsyncClient):
        r = await client.get("/api/v1/users/me/notification-settings")
        assert r.status_code == 401


class TestPushTokens:
    async def test_register_token(self, client: AsyncClient, auth_headers: dict):
        r = await client.post(
            "/api/v1/notifications/register-token",
            json={"token": "fcm-token-abc123", "platform": "android"},
            headers=auth_headers,
        )
        assert r.status_code == 201
        assert r.json()["status"] == "registered"

    async def test_register_token_idempotent(self, client: AsyncClient, auth_headers: dict):
        await client.post(
            "/api/v1/notifications/register-token",
            json={"token": "fcm-token-xyz", "platform": "ios"},
            headers=auth_headers,
        )
        r = await client.post(
            "/api/v1/notifications/register-token",
            json={"token": "fcm-token-xyz", "platform": "ios"},
            headers=auth_headers,
        )
        assert r.status_code == 201

    async def test_remove_token(
        self, client: AsyncClient, auth_headers: dict, db: AsyncSession, user: User
    ):
        token_str = "fcm-delete-me"
        db.add(PushToken(user_id=user.id, token=token_str, platform="android"))
        await db.commit()

        r = await client.delete(
            f"/api/v1/notifications/token/{token_str}", headers=auth_headers
        )
        assert r.status_code == 204

    async def test_remove_nonexistent_token(self, client: AsyncClient, auth_headers: dict):
        r = await client.delete("/api/v1/notifications/token/ghost-token", headers=auth_headers)
        assert r.status_code == 404

    async def test_invalid_platform_rejected(self, client: AsyncClient, auth_headers: dict):
        r = await client.post(
            "/api/v1/notifications/register-token",
            json={"token": "tok", "platform": "windows"},
            headers=auth_headers,
        )
        assert r.status_code == 422


class TestPrivacySettings:
    async def test_get_returns_defaults(self, client: AsyncClient, auth_headers: dict):
        r = await client.get("/api/v1/users/me/privacy-settings", headers=auth_headers)
        assert r.status_code == 200
        body = r.json()
        assert body["share_presence"] is True
        assert body["location_accuracy"] == "approximate"
        assert body["name_public"] is True

    async def test_patch_updates_fields(self, client: AsyncClient, auth_headers: dict):
        r = await client.patch(
            "/api/v1/users/me/privacy-settings",
            json={"share_presence": False, "name_public": False},
            headers=auth_headers,
        )
        assert r.status_code == 200
        assert r.json()["share_presence"] is False

    async def test_patch_persists(self, client: AsyncClient, auth_headers: dict):
        await client.patch(
            "/api/v1/users/me/privacy-settings",
            json={"location_accuracy": "exact"},
            headers=auth_headers,
        )
        r = await client.get("/api/v1/users/me/privacy-settings", headers=auth_headers)
        assert r.json()["location_accuracy"] == "exact"

    async def test_requires_auth(self, client: AsyncClient):
        r = await client.get("/api/v1/users/me/privacy-settings")
        assert r.status_code == 401


class TestDataExport:
    async def test_export_returns_user_data(self, client: AsyncClient, auth_headers: dict, user: User):
        r = await client.get("/api/v1/users/me/data-export", headers=auth_headers)
        assert r.status_code == 200
        body = r.json()
        assert body["user"]["id"] == str(user.id)
        assert "reports" in body
        assert "reputation_events" in body
        assert "exported_at" in body

    async def test_requires_auth(self, client: AsyncClient):
        r = await client.get("/api/v1/users/me/data-export")
        assert r.status_code == 401


class TestDeleteReports:
    async def test_delete_all_reports(
        self, client: AsyncClient, auth_headers: dict, db: AsyncSession,
        beach, user: User
    ):
        from app.models.beach_status import OccupancyHeartbeat
        hb = OccupancyHeartbeat(beach_id=beach.id, user_id=user.id,
                                geom="SRID=4326;POINT(-8.9821 38.4839)")
        db.add(hb)
        report = Report(
            beach_id=beach.id, user_id=user.id, type="jellyfish", severity=1,
            expires_at=datetime.now(timezone.utc) + timedelta(hours=3),
        )
        db.add(report)
        await db.commit()

        r = await client.delete("/api/v1/users/me/reports", headers=auth_headers)
        assert r.status_code == 204

        r2 = await client.get("/api/v1/beaches/portinho-da-arrabida/reports")
        assert r2.json()["total"] == 0

    async def test_requires_auth(self, client: AsyncClient):
        r = await client.delete("/api/v1/users/me/reports")
        assert r.status_code == 401


class TestDeleteAccount:
    async def test_delete_requires_correct_confirmation(
        self, client: AsyncClient, auth_headers: dict
    ):
        r = await client.request(
            "DELETE", "/api/v1/users/me",
            json={"confirmation": "wrong"},
            headers=auth_headers,
        )
        assert r.status_code == 400

    async def test_delete_account(self, client: AsyncClient, db: AsyncSession):
        r = await client.post("/api/v1/auth/register", json={
            "email": "todelete@example.com",
            "password": "password123",
            "display_name": "ToDelete",
        })
        token = r.json()["access_token"]

        r2 = await client.request(
            "DELETE", "/api/v1/users/me",
            json={"confirmation": "APAGAR"},
            headers={"Authorization": f"Bearer {token}"},
        )
        assert r2.status_code == 204

        r3 = await client.get(
            "/api/v1/users/me",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert r3.status_code == 401

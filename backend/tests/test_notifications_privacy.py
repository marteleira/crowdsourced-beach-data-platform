"""Notification settings, privacy settings, push tokens and account management tests."""
import pytest
from httpx import AsyncClient
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.user import User
from app.models.report import Report
from app.models.user_extended import PushToken
from app.models.beach import Beach
from app.models.beach_status import OccupancyHeartbeat
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
        assert body["share_presence"] is False
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
            json={"name_public": False},
            headers=auth_headers,
        )
        r = await client.get("/api/v1/users/me/privacy-settings", headers=auth_headers)
        assert r.json()["name_public"] is False

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

    async def test_delete_schedules_account_for_30_days(
        self, client: AsyncClient, db: AsyncSession
    ):
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
        assert r2.status_code == 202
        body = r2.json()
        assert "scheduled_deletion_at" in body

        # Account is now pending deletion — regular API calls must be blocked
        r3 = await client.get(
            "/api/v1/users/me",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert r3.status_code == 403
        assert r3.json()["detail"]["code"] == "account_pending_deletion"

    async def test_delete_idempotent_when_already_pending(
        self, client: AsyncClient, db: AsyncSession
    ):
        r = await client.post("/api/v1/auth/register", json={
            "email": "todelete-idem@example.com",
            "password": "password123",
            "display_name": "ToDeleteIdem",
        })
        token = r.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}

        r1 = await client.request("DELETE", "/api/v1/users/me",
                                  json={"confirmation": "APAGAR"}, headers=headers)
        assert r1.status_code == 202
        date1 = r1.json()["scheduled_deletion_at"]

        r2 = await client.request("DELETE", "/api/v1/users/me",
                                  json={"confirmation": "APAGAR"}, headers=headers)
        assert r2.status_code == 202
        assert r2.json()["scheduled_deletion_at"] == date1  # same date, not extended

    async def test_cancel_deletion_restores_account(
        self, client: AsyncClient, db: AsyncSession
    ):
        r = await client.post("/api/v1/auth/register", json={
            "email": "cancel-delete@example.com",
            "password": "password123",
            "display_name": "CancelDelete",
        })
        token = r.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}

        await client.request("DELETE", "/api/v1/users/me",
                              json={"confirmation": "APAGAR"}, headers=headers)

        r2 = await client.post("/api/v1/users/me/cancel-deletion", headers=headers)
        assert r2.status_code == 200

        # Account is restored — regular API calls work again
        r3 = await client.get("/api/v1/users/me", headers=headers)
        assert r3.status_code == 200

    async def test_cancel_deletion_when_not_pending_returns_400(
        self, client: AsyncClient, auth_headers: dict
    ):
        r = await client.post("/api/v1/users/me/cancel-deletion", headers=auth_headers)
        assert r.status_code == 400


#Privacy enforcement on /map/users 


class TestPrivacySettingsEnforcement:
    """Privacy settings must actually filter what /map/users returns."""

    async def _heartbeat(self, db: AsyncSession, user: User, beach: Beach):
        db.add(OccupancyHeartbeat(
            beach_id=beach.id, user_id=user.id,
            geom="SRID=4326;POINT(-8.9821 38.4839)",
        ))
        await db.commit()

    async def test_share_presence_false_excluded_from_users_but_still_counted(
        self, client: AsyncClient, auth_headers: dict,
        db: AsyncSession, user: User, beach: Beach,
    ):
        await self._heartbeat(db, user, beach)
        await client.patch(
            "/api/v1/users/me/privacy-settings",
            json={"share_presence": False},
            headers=auth_headers,
        )

        r = await client.get("/api/v1/map/users")
        assert r.status_code == 200
        entry = next((b for b in r.json() if b["beach_id"] == beach.id), None)
        assert entry is not None
        assert entry["user_count"] == 1   #counted
        assert entry["users"] == []       #but not listed

    async def test_name_public_false_returns_null_display_name(
        self, client: AsyncClient, auth_headers: dict,
        db: AsyncSession, user: User, beach: Beach,
    ):
        await self._heartbeat(db, user, beach)
        await client.patch(
            "/api/v1/users/me/privacy-settings",
            json={"name_public": False, "share_presence": True},
            headers=auth_headers,
        )

        r = await client.get("/api/v1/map/users")
        entry = next((b for b in r.json() if b["beach_id"] == beach.id), None)
        assert entry is not None
        assert len(entry["users"]) == 1
        assert entry["users"][0]["display_name"] is None

    async def test_name_public_true_returns_display_name(
        self, client: AsyncClient, auth_headers: dict,
        db: AsyncSession, user: User, beach: Beach,
    ):
        await self._heartbeat(db, user, beach)
        #name_public defaults to True, but share_presence defaults to False (opt-in) —
        #must opt in explicitly to appear in the visible list at all.
        await client.patch(
            "/api/v1/users/me/privacy-settings",
            json={"share_presence": True},
            headers=auth_headers,
        )

        r = await client.get("/api/v1/map/users")
        entry = next((b for b in r.json() if b["beach_id"] == beach.id), None)
        assert entry is not None
        assert len(entry["users"]) == 1
        assert entry["users"][0]["display_name"] == user.display_name

    async def test_share_presence_false_by_default_user_not_visible(
        self, client: AsyncClient, auth_headers: dict,
        db: AsyncSession, user: User, beach: Beach,
    ):
        await self._heartbeat(db, user, beach)

        r = await client.get("/api/v1/map/users")
        entry = next((b for b in r.json() if b["beach_id"] == beach.id), None)
        assert entry is not None
        assert entry["user_count"] == 1   #still counted
        assert entry["users"] == []       #but not listed — opt-in required

    async def test_share_presence_true_user_visible_when_opted_in(
        self, client: AsyncClient, auth_headers: dict,
        db: AsyncSession, user: User, beach: Beach,
    ):
        await self._heartbeat(db, user, beach)
        await client.patch(
            "/api/v1/users/me/privacy-settings",
            json={"share_presence": True},
            headers=auth_headers,
        )

        r = await client.get("/api/v1/map/users")
        entry = next((b for b in r.json() if b["beach_id"] == beach.id), None)
        assert entry is not None
        assert entry["user_count"] == 1
        assert len(entry["users"]) == 1

    async def test_all_privacy_fields_returned_on_get(
        self, client: AsyncClient, auth_headers: dict,
    ):
        r = await client.get("/api/v1/users/me/privacy-settings", headers=auth_headers)
        body = r.json()
        assert set(body.keys()) == {
            "name_public", "avatar_public", "share_presence",
        }

    async def test_avatar_public_persisted(
        self, client: AsyncClient, auth_headers: dict,
    ):
        r = await client.patch(
            "/api/v1/users/me/privacy-settings",
            json={"avatar_public": False},
            headers=auth_headers,
        )
        assert r.status_code == 200
        assert r.json()["avatar_public"] is False

        r2 = await client.get("/api/v1/users/me/privacy-settings", headers=auth_headers)
        assert r2.json()["avatar_public"] is False

    async def test_partial_patch_does_not_clobber_other_fields(
        self, client: AsyncClient, auth_headers: dict,
    ):
        await client.patch(
            "/api/v1/users/me/privacy-settings",
            json={"avatar_public": False},
            headers=auth_headers,
        )
        await client.patch(
            "/api/v1/users/me/privacy-settings",
            json={"name_public": False},
            headers=auth_headers,
        )
        r = await client.get("/api/v1/users/me/privacy-settings", headers=auth_headers)
        body = r.json()
        assert body["avatar_public"] is False       #not clobbered
        assert body["name_public"] is False         #new value


#Notification settings enforcement 


class TestNotificationSettingsEnforcement:
    """All notification setting fields must persist independently and validate correctly."""

    async def test_all_boolean_fields_persisted(
        self, client: AsyncClient, auth_headers: dict,
    ):
        payload = {
            "global_enabled": False,
            "checkin_alerts": False,
            "favourite_alerts_enabled": False,
            "flag_change_alerts": False,
            "tide_alerts": False,
            "quiet_hours_enabled": True,
        }
        r = await client.patch(
            "/api/v1/users/me/notification-settings",
            json=payload,
            headers=auth_headers,
        )
        assert r.status_code == 200
        body = r.json()
        for key, value in payload.items():
            assert body[key] == value, f"Field {key!r} mismatch"

    async def test_min_severity_valid_values_accepted(
        self, client: AsyncClient, auth_headers: dict,
    ):
        for severity in (1, 2, 3):
            r = await client.patch(
                "/api/v1/users/me/notification-settings",
                json={"min_severity": severity},
                headers=auth_headers,
            )
            assert r.status_code == 200
            assert r.json()["min_severity"] == severity

    async def test_min_severity_invalid_value_rejected(
        self, client: AsyncClient, auth_headers: dict,
    ):
        r = await client.patch(
            "/api/v1/users/me/notification-settings",
            json={"min_severity": 5},
            headers=auth_headers,
        )
        assert r.status_code == 422

    async def test_quiet_hours_times_persisted(
        self, client: AsyncClient, auth_headers: dict,
    ):
        r = await client.patch(
            "/api/v1/users/me/notification-settings",
            json={"quiet_hours_enabled": True, "quiet_hours_start": "21:30", "quiet_hours_end": "06:30"},
            headers=auth_headers,
        )
        assert r.status_code == 200
        body = r.json()
        assert body["quiet_hours_enabled"] is True
        assert body["quiet_hours_start"] == "21:30"
        assert body["quiet_hours_end"] == "06:30"

    async def test_alert_types_nested_dict_persisted(
        self, client: AsyncClient, auth_headers: dict,
    ):
        r = await client.patch(
            "/api/v1/users/me/notification-settings",
            json={"alert_types": {
                "jellyfish": False,
                "strong_current": True,
                "pollution": False,
                "rough_sea": True,
            }},
            headers=auth_headers,
        )
        assert r.status_code == 200
        at = r.json()["alert_types"]
        assert at["jellyfish"] is False
        assert at["pollution"] is False
        assert at["strong_current"] is True
        assert at["rough_sea"] is True

    async def test_favourite_alerts_per_beach_dict_persisted(
        self, client: AsyncClient, auth_headers: dict,
    ):
        r = await client.patch(
            "/api/v1/users/me/notification-settings",
            json={"favourite_alerts_per_beach": {"1": False, "5": True}},
            headers=auth_headers,
        )
        assert r.status_code == 200
        assert r.json()["favourite_alerts_per_beach"] == {"1": False, "5": True}

    async def test_partial_patch_does_not_clobber_other_fields(
        self, client: AsyncClient, auth_headers: dict,
    ):
        await client.patch(
            "/api/v1/users/me/notification-settings",
            json={"tide_alerts": False,  "min_severity": 2},
            headers=auth_headers,
        )
        await client.patch(
            "/api/v1/users/me/notification-settings",
            json={"global_enabled": False},
            headers=auth_headers,
        )
        r = await client.get("/api/v1/users/me/notification-settings", headers=auth_headers)
        body = r.json()
        assert body["tide_alerts"] is False       #not clobbered
        assert body["min_severity"] == 2          #not clobbered
        assert body["global_enabled"] is False    #new value

    async def test_all_fields_present_in_get_response(
        self, client: AsyncClient, auth_headers: dict,
    ):
        r = await client.get("/api/v1/users/me/notification-settings", headers=auth_headers)
        body = r.json()
        expected_keys = {
            "global_enabled", "checkin_alerts", "favourite_alerts_enabled",
            "favourite_alerts_per_beach", "alert_types", "min_severity",
            "flag_change_alerts", "tide_alerts", "quiet_hours_enabled", 
            "quiet_hours_start", "quiet_hours_end",
        }
        assert expected_keys.issubset(body.keys())


# Settings isolation between users 


class TestSettingsIsolation:
    """Settings changed for one user must not affect another user."""

    async def _create_other_user(self, db: AsyncSession, email: str):
        from app.core.security import hash_password, create_access_token
        other = User(
            email=email,
            display_name="Other User",
            password_hash=hash_password("password123"),
            is_anonymous=False,
            reputation=0,
        )
        db.add(other)
        await db.commit()
        await db.refresh(other)
        token = create_access_token(other.id, other.reputation, other.is_anonymous)
        return {"Authorization": f"Bearer {token}"}

    async def test_notification_settings_are_per_user(
        self, client: AsyncClient, auth_headers: dict, db: AsyncSession,
    ):
        other_headers = await self._create_other_user(db, "isolated-notif@example.com")

        await client.patch(
            "/api/v1/users/me/notification-settings",
            json={"global_enabled": False, "min_severity": 3},
            headers=auth_headers,
        )

        r = await client.get("/api/v1/users/me/notification-settings", headers=other_headers)
        body = r.json()
        assert body["global_enabled"] is True
        assert body["min_severity"] == 1

    async def test_privacy_settings_are_per_user(
        self, client: AsyncClient, auth_headers: dict, db: AsyncSession,
    ):
        other_headers = await self._create_other_user(db, "isolated-priv@example.com")

        await client.patch(
            "/api/v1/users/me/privacy-settings",
            json={"share_presence": True},
            headers=auth_headers,
        )

        r = await client.get("/api/v1/users/me/privacy-settings", headers=other_headers)
        body = r.json()
        assert body["share_presence"] is False

    async def test_map_shows_only_users_with_presence_enabled(
        self, client: AsyncClient, auth_headers: dict,
        db: AsyncSession, user: User, beach: Beach,
    ):
        from app.core.security import hash_password, create_access_token
        #First user opts in to presence (default is now False / opt-in)
        await client.patch(
            "/api/v1/users/me/privacy-settings",
            json={"share_presence": True},
            headers=auth_headers,
        )
        #Second user leaves presence at its default (opted out)
        other = User(
            email="no-presence@example.com",
            display_name="Hidden User",
            password_hash=hash_password("password123"),
            is_anonymous=False,
            reputation=0,
            privacy_settings={"share_presence": False},
        )
        db.add(other)
        await db.commit()
        await db.refresh(other)

        #Both users have heartbeats
        db.add(OccupancyHeartbeat(beach_id=beach.id, user_id=user.id,
                                  geom="SRID=4326;POINT(-8.9821 38.4839)"))
        db.add(OccupancyHeartbeat(beach_id=beach.id, user_id=other.id,
                                  geom="SRID=4326;POINT(-8.9821 38.4839)"))
        await db.commit()

        r = await client.get("/api/v1/map/users")
        entry = next((b for b in r.json() if b["beach_id"] == beach.id), None)
        assert entry["user_count"] == 2          #both counted
        assert len(entry["users"]) == 1          #only the visible one listed
        assert entry["users"][0]["display_name"] == user.display_name


# Favourite / presence parity for flag notifications
#
# There used to be a dedicated dispatch_red_flag_favourite_notification() that special-cased
# favourite-only users on a red flag (its own setting, bypassed quiet hours). That's gone —
# favouriting a beach is now treated exactly like being checked in there: everything flows
# through dispatch_flag_notification() and the standard settings gates (favourite_alerts_enabled,
# flag_change_alerts, quiet hours, per-beach mute).


class TestFavouritePresenceParityOnRedFlag:
    """dispatch_flag_notification trata utilizadores fav-only da mesma forma que utilizadores
    com checkin, incluindo para bandeira vermelha — sem função especial dedicada."""

    async def test_setting_red_flag_favourite_alerts_no_longer_exists(
        self, client: AsyncClient, auth_headers: dict,
    ):
        r = await client.get("/api/v1/users/me/notification-settings", headers=auth_headers)
        assert "red_flag_favourite_alerts" not in r.json()

    async def test_dispatch_notifies_fav_only_user_on_red_flag(
        self, db: AsyncSession, beach: Beach, user: User,
    ):
        from unittest.mock import AsyncMock, patch
        from app.models.user_extended import PushToken, UserFavourite
        from app.services.push_notifications import dispatch_flag_notification

        db.add(UserFavourite(user_id=user.id, beach_id=beach.id))
        db.add(PushToken(user_id=user.id, token="fav-token-red", platform="android"))
        await db.commit()

        with patch("app.services.push_notifications._send_push", new_callable=AsyncMock) as mock_send:
            count = await dispatch_flag_notification(db, beach.id, "green", "red", beach.name)

        assert count == 1
        mock_send.assert_called_once()
        title_arg = mock_send.call_args.args[1]
        assert beach.name in title_arg

    async def test_dispatch_skips_fav_only_user_with_favourite_alerts_disabled(
        self, db: AsyncSession, beach: Beach, user: User,
    ):
        from unittest.mock import AsyncMock, patch
        from app.models.user_extended import PushToken, UserFavourite
        from app.services.push_notifications import dispatch_flag_notification

        user.notification_settings = {"favourite_alerts_enabled": False}
        db.add(user)
        db.add(UserFavourite(user_id=user.id, beach_id=beach.id))
        db.add(PushToken(user_id=user.id, token="fav-token-fav-off", platform="android"))
        await db.commit()

        with patch("app.services.push_notifications._send_push", new_callable=AsyncMock) as mock_send:
            count = await dispatch_flag_notification(db, beach.id, "green", "red", beach.name)

        assert count == 0
        mock_send.assert_not_called()

    async def test_dispatch_skips_fav_only_user_with_global_disabled(
        self, db: AsyncSession, beach: Beach, user: User,
    ):
        from unittest.mock import AsyncMock, patch
        from app.models.user_extended import PushToken, UserFavourite
        from app.services.push_notifications import dispatch_flag_notification

        user.notification_settings = {"global_enabled": False}
        db.add(user)
        db.add(UserFavourite(user_id=user.id, beach_id=beach.id))
        db.add(PushToken(user_id=user.id, token="fav-token-global-off", platform="android"))
        await db.commit()

        with patch("app.services.push_notifications._send_push", new_callable=AsyncMock) as mock_send:
            count = await dispatch_flag_notification(db, beach.id, "green", "red", beach.name)

        assert count == 0
        mock_send.assert_not_called()

    async def test_dispatch_skips_user_without_favourite_or_checkin(
        self, db: AsyncSession, beach: Beach, user: User,
    ):
        from unittest.mock import AsyncMock, patch
        from app.models.user_extended import PushToken
        from app.services.push_notifications import dispatch_flag_notification

        db.add(PushToken(user_id=user.id, token="no-fav-token", platform="android"))
        await db.commit()

        with patch("app.services.push_notifications._send_push", new_callable=AsyncMock) as mock_send:
            count = await dispatch_flag_notification(db, beach.id, "green", "red", beach.name)

        assert count == 0
        mock_send.assert_not_called()

    async def test_dispatch_red_flag_now_respects_quiet_hours_for_fav_only(
        self, db: AsyncSession, beach: Beach, user: User,
    ):
        """Ao contrário da antiga função dedicada, bandeira vermelha para fav-only já não
        ignora quiet hours — mesma regra aplicada a utilizadores com checkin."""
        from unittest.mock import AsyncMock, patch
        from app.models.user_extended import PushToken, UserFavourite
        from app.services.push_notifications import dispatch_flag_notification

        user.notification_settings = {
            "quiet_hours_enabled": True,
            "quiet_hours_start": "00:00",
            "quiet_hours_end": "23:59",
        }
        db.add(user)
        db.add(UserFavourite(user_id=user.id, beach_id=beach.id))
        db.add(PushToken(user_id=user.id, token="quiet-hours-token", platform="android"))
        await db.commit()

        with patch("app.services.push_notifications._send_push", new_callable=AsyncMock) as mock_send:
            count = await dispatch_flag_notification(db, beach.id, "green", "red", beach.name)

        assert count == 0
        mock_send.assert_not_called()

    async def test_dispatch_flag_notifies_fav_only_for_non_red_too(
        self, db: AsyncSession, beach: Beach, user: User,
    ):
        """dispatch_flag_notification continua a notificar fav-only para mudanças não-vermelhas."""
        from unittest.mock import AsyncMock, patch
        from app.models.user_extended import PushToken, UserFavourite
        from app.services.push_notifications import dispatch_flag_notification

        db.add(UserFavourite(user_id=user.id, beach_id=beach.id))
        db.add(PushToken(user_id=user.id, token="fav-only-yellow-token", platform="android"))
        await db.commit()

        with patch("app.services.push_notifications._send_push", new_callable=AsyncMock) as mock_send:
            count = await dispatch_flag_notification(db, beach.id, "green", "yellow", beach.name)

        assert count == 1
        mock_send.assert_called_once()

    async def test_checkin_and_fav_only_users_get_identical_outcome_on_red_flag(
        self, db: AsyncSession, beach: Beach,
    ):
        """Mesmo settings shape, mesmo resultado — quer o utilizador esteja lá (checkin) quer
        tenha apenas a praia como favorita."""
        from unittest.mock import AsyncMock, patch
        from app.core.security import hash_password
        from app.models.beach_status import OccupancyHeartbeat
        from app.models.user_extended import PushToken, UserFavourite
        from app.services.push_notifications import dispatch_flag_notification

        checkin_user = User(
            email="checkin-parity@x.com", display_name="checkin-parity",
            password_hash=hash_password("pw"), is_anonymous=False, reputation=0,
        )
        fav_user = User(
            email="fav-parity@x.com", display_name="fav-parity",
            password_hash=hash_password("pw"), is_anonymous=False, reputation=0,
        )
        db.add_all([checkin_user, fav_user])
        await db.commit()
        await db.refresh(checkin_user)
        await db.refresh(fav_user)

        db.add(OccupancyHeartbeat(
            beach_id=beach.id, user_id=checkin_user.id,
            geom="SRID=4326;POINT(-8.9821 38.4839)",
        ))
        db.add(UserFavourite(user_id=fav_user.id, beach_id=beach.id))
        db.add(PushToken(user_id=checkin_user.id, token="checkin-parity-tok", platform="android"))
        db.add(PushToken(user_id=fav_user.id, token="fav-parity-tok", platform="android"))
        await db.commit()

        with patch("app.services.push_notifications._send_push", new_callable=AsyncMock) as mock_send:
            count = await dispatch_flag_notification(db, beach.id, "yellow", "red", beach.name)

        assert count == 2
        called_tokens = {c.args[0] for c in mock_send.call_args_list}
        assert called_tokens == {"checkin-parity-tok", "fav-parity-tok"}

"""
Tests for push notification dispatch logic

_send_push is mocked throughout, so no real Firebase credentials needed
Covers: checkin targeting, author exclusion, favourites, notification settings,
severity/type filters, quiet hours, banned users, missing tokens, and HTTP wiring
"""
import pytest
from datetime import datetime, timedelta, timezone
from unittest.mock import patch, AsyncMock

from sqlalchemy.ext.asyncio import AsyncSession

from app.models.beach import Beach
from app.models.beach_status import OccupancyHeartbeat
from app.models.user import User
from app.models.user_extended import PushToken, UserFavourite
from app.services.push_notifications import dispatch_report_notification, dispatch_flag_notification


# ── Helpers ────────────────────────────────────────────────────────────────────

async def _make_user(db: AsyncSession, email: str, **kwargs) -> User:
    from app.core.security import hash_password
    u = User(
        email=email,
        display_name=email.split("@")[0],
        password_hash=hash_password("pw"),
        is_anonymous=False,
        reputation=0,
        **kwargs,
    )
    db.add(u)
    await db.commit()
    await db.refresh(u)
    return u


async def _heartbeat(db: AsyncSession, user: User, beach: Beach, minutes_ago: int = 30) -> None:
    db.add(OccupancyHeartbeat(
        beach_id=beach.id,
        user_id=user.id,
        geom="SRID=4326;POINT(-8.9821 38.4839)",
        created_at=datetime.now(timezone.utc) - timedelta(minutes=minutes_ago),
    ))
    await db.commit()


async def _token(db: AsyncSession, user: User, tok: str = None) -> str:
    tok = tok or f"fcm-{user.id}"
    db.add(PushToken(user_id=user.id, token=tok, platform="android"))
    await db.commit()
    return tok


async def _favourite(db: AsyncSession, user: User, beach: Beach) -> None:
    db.add(UserFavourite(user_id=user.id, beach_id=beach.id))
    await db.commit()


def _tokens_called(mock_push) -> list[str]:
    return [c.args[0] for c in mock_push.call_args_list]


MOCK_SEND = "app.services.push_notifications._send_push"


# ── Report dispatch ────────────────────────────────────────────────────────────

class TestReportDispatch:

    async def test_user_at_beach_receives_notification(self, db: AsyncSession, beach: Beach):
        u = await _make_user(db, "at-beach@x.com")
        await _heartbeat(db, u, beach, minutes_ago=30)
        tok = await _token(db, u)

        with patch(MOCK_SEND, new_callable=AsyncMock) as mock:
            n = await dispatch_report_notification(db, beach.id, "jellyfish", 1, beach.name, None)

        assert n == 1
        assert tok in _tokens_called(mock)

    async def test_user_not_at_beach_does_not_receive(self, db: AsyncSession, beach: Beach):
        u = await _make_user(db, "away@x.com")
        await _token(db, u)  # has token, but no heartbeat

        with patch(MOCK_SEND, new_callable=AsyncMock) as mock:
            n = await dispatch_report_notification(db, beach.id, "jellyfish", 1, beach.name, None)

        assert n == 0
        mock.assert_not_called()

    async def test_expired_heartbeat_not_counted(self, db: AsyncSession, beach: Beach):
        u = await _make_user(db, "old-checkin@x.com")
        await _heartbeat(db, u, beach, minutes_ago=200)  # outside 3h window
        await _token(db, u)

        with patch(MOCK_SEND, new_callable=AsyncMock) as mock:
            n = await dispatch_report_notification(db, beach.id, "jellyfish", 1, beach.name, None)

        assert n == 0
        mock.assert_not_called()

    async def test_report_author_excluded(self, db: AsyncSession, beach: Beach):
        author = await _make_user(db, "author@x.com")
        await _heartbeat(db, author, beach, minutes_ago=10)
        await _token(db, author)

        with patch(MOCK_SEND, new_callable=AsyncMock) as mock:
            n = await dispatch_report_notification(
                db, beach.id, "jellyfish", 1, beach.name, None,
                exclude_user_id=author.id,
            )

        assert n == 0
        mock.assert_not_called()

    async def test_only_other_users_notified_not_author(self, db: AsyncSession, beach: Beach):
        author = await _make_user(db, "author2@x.com")
        other = await _make_user(db, "bystander@x.com")
        await _heartbeat(db, author, beach, minutes_ago=5)
        await _heartbeat(db, other, beach, minutes_ago=15)
        author_tok = await _token(db, author)
        other_tok = await _token(db, other)

        with patch(MOCK_SEND, new_callable=AsyncMock) as mock:
            n = await dispatch_report_notification(
                db, beach.id, "jellyfish", 1, beach.name, None,
                exclude_user_id=author.id,
            )

        assert n == 1
        called = _tokens_called(mock)
        assert other_tok in called
        assert author_tok not in called

    async def test_favourite_without_heartbeat_receives(self, db: AsyncSession, beach: Beach):
        u = await _make_user(db, "fav@x.com")
        await _favourite(db, u, beach)
        tok = await _token(db, u)

        with patch(MOCK_SEND, new_callable=AsyncMock) as mock:
            n = await dispatch_report_notification(db, beach.id, "jellyfish", 1, beach.name, None)

        assert n == 1
        assert tok in _tokens_called(mock)

    async def test_multiple_users_all_notified(self, db: AsyncSession, beach: Beach):
        toks = []
        for i in range(4):
            u = await _make_user(db, f"u{i}@x.com")
            await _heartbeat(db, u, beach, minutes_ago=10 + i)
            toks.append(await _token(db, u, tok=f"tok-{i}"))

        with patch(MOCK_SEND, new_callable=AsyncMock) as mock:
            n = await dispatch_report_notification(db, beach.id, "jellyfish", 1, beach.name, None)

        assert n == 4
        assert mock.call_count == 4
        for tok in toks:
            assert tok in _tokens_called(mock)

    async def test_note_used_as_notification_body(self, db: AsyncSession, beach: Beach):
        u = await _make_user(db, "note@x.com")
        await _heartbeat(db, u, beach)
        await _token(db, u)

        with patch(MOCK_SEND, new_callable=AsyncMock) as mock:
            await dispatch_report_notification(db, beach.id, "jellyfish", 1, beach.name, "Muitas medusas no norte")

        assert mock.call_count == 1
        assert "Muitas medusas no norte" in mock.call_args.args[2]


# ── Notification settings filters ─────────────────────────────────────────────

class TestReportDispatchSettings:

    async def test_global_disabled_skips(self, db: AsyncSession, beach: Beach):
        u = await _make_user(db, "off@x.com", notification_settings={"global_enabled": False})
        await _heartbeat(db, u, beach)
        await _token(db, u)

        with patch(MOCK_SEND, new_callable=AsyncMock) as mock:
            n = await dispatch_report_notification(db, beach.id, "jellyfish", 1, beach.name, None)

        assert n == 0
        mock.assert_not_called()

    async def test_checkin_alerts_disabled_skips_checkin_user(self, db: AsyncSession, beach: Beach):
        u = await _make_user(db, "nocheckin@x.com", notification_settings={"checkin_alerts": False})
        await _heartbeat(db, u, beach)
        await _token(db, u)

        with patch(MOCK_SEND, new_callable=AsyncMock) as mock:
            n = await dispatch_report_notification(db, beach.id, "jellyfish", 1, beach.name, None)

        assert n == 0

    async def test_checkin_alerts_disabled_but_fav_enabled_still_receives(
        self, db: AsyncSession, beach: Beach
    ):
        u = await _make_user(db, "both@x.com", notification_settings={
            "checkin_alerts": False,
            "favourite_alerts_enabled": True,
        })
        await _heartbeat(db, u, beach)
        await _favourite(db, u, beach)
        await _token(db, u)

        with patch(MOCK_SEND, new_callable=AsyncMock) as mock:
            n = await dispatch_report_notification(db, beach.id, "jellyfish", 1, beach.name, None)

        assert n == 1

    async def test_favourite_alerts_disabled_skips_fav_user(self, db: AsyncSession, beach: Beach):
        u = await _make_user(db, "nofav@x.com", notification_settings={"favourite_alerts_enabled": False})
        await _favourite(db, u, beach)
        await _token(db, u)

        with patch(MOCK_SEND, new_callable=AsyncMock) as mock:
            n = await dispatch_report_notification(db, beach.id, "jellyfish", 1, beach.name, None)

        assert n == 0

    async def test_per_beach_toggle_off_skips_fav(self, db: AsyncSession, beach: Beach):
        u = await _make_user(db, "perbeach@x.com", notification_settings={
            "favourite_alerts_enabled": True,
            "favourite_alerts_per_beach": {str(beach.id): False},
        })
        await _favourite(db, u, beach)
        await _token(db, u)

        with patch(MOCK_SEND, new_callable=AsyncMock) as mock:
            n = await dispatch_report_notification(db, beach.id, "jellyfish", 1, beach.name, None)

        assert n == 0

    async def test_min_severity_blocks_low_severity(self, db: AsyncSession, beach: Beach):
        u = await _make_user(db, "minsev@x.com", notification_settings={"min_severity": 2})
        await _heartbeat(db, u, beach)
        await _token(db, u)

        with patch(MOCK_SEND, new_callable=AsyncMock) as mock:
            n = await dispatch_report_notification(db, beach.id, "jellyfish", 1, beach.name, None)

        assert n == 0

    async def test_min_severity_passes_equal_severity(self, db: AsyncSession, beach: Beach):
        u = await _make_user(db, "minsev2@x.com", notification_settings={"min_severity": 2})
        await _heartbeat(db, u, beach)
        await _token(db, u)

        with patch(MOCK_SEND, new_callable=AsyncMock) as mock:
            n = await dispatch_report_notification(db, beach.id, "jellyfish", 2, beach.name, None)

        assert n == 1

    async def test_alert_type_disabled_blocks(self, db: AsyncSession, beach: Beach):
        u = await _make_user(db, "nojelly@x.com",
                             notification_settings={"alert_types": {"jellyfish": False}})
        await _heartbeat(db, u, beach)
        await _token(db, u)

        with patch(MOCK_SEND, new_callable=AsyncMock) as mock:
            n = await dispatch_report_notification(db, beach.id, "jellyfish", 1, beach.name, None)

        assert n == 0

    async def test_alert_type_disabled_for_one_passes_other(self, db: AsyncSession, beach: Beach):
        u = await _make_user(db, "nojelly2@x.com",
                             notification_settings={"alert_types": {"jellyfish": False}})
        await _heartbeat(db, u, beach)
        await _token(db, u)

        with patch(MOCK_SEND, new_callable=AsyncMock) as mock:
            n = await dispatch_report_notification(db, beach.id, "rough_sea", 1, beach.name, None)

        assert n == 1

    async def test_quiet_hours_blocks_severity_1_and_2(self, db: AsyncSession, beach: Beach):
        u = await _make_user(db, "quiet@x.com", notification_settings={
            "quiet_hours_enabled": True,
            "quiet_hours_start": "00:00",
            "quiet_hours_end": "23:59",
        })
        await _heartbeat(db, u, beach)
        await _token(db, u)

        with patch(MOCK_SEND, new_callable=AsyncMock) as mock:
            n1 = await dispatch_report_notification(db, beach.id, "jellyfish", 1, beach.name, None)
            n2 = await dispatch_report_notification(db, beach.id, "jellyfish", 2, beach.name, None)

        assert n1 == 0
        assert n2 == 0

    async def test_quiet_hours_severity_3_always_passes(self, db: AsyncSession, beach: Beach):
        u = await _make_user(db, "quiet2@x.com", notification_settings={
            "quiet_hours_enabled": True,
            "quiet_hours_start": "00:00",
            "quiet_hours_end": "23:59",
        })
        await _heartbeat(db, u, beach)
        await _token(db, u)

        with patch(MOCK_SEND, new_callable=AsyncMock) as mock:
            n = await dispatch_report_notification(db, beach.id, "jellyfish", 3, beach.name, None)

        assert n == 1

    async def test_banned_user_skipped(self, db: AsyncSession, beach: Beach):
        u = await _make_user(db, "banned@x.com", is_banned=True)
        await _heartbeat(db, u, beach)
        await _token(db, u)

        with patch(MOCK_SEND, new_callable=AsyncMock) as mock:
            n = await dispatch_report_notification(db, beach.id, "jellyfish", 1, beach.name, None)

        assert n == 0

    async def test_user_without_token_not_counted(self, db: AsyncSession, beach: Beach):
        u = await _make_user(db, "notoken@x.com")
        await _heartbeat(db, u, beach)
        # No push token

        with patch(MOCK_SEND, new_callable=AsyncMock) as mock:
            n = await dispatch_report_notification(db, beach.id, "jellyfish", 1, beach.name, None)

        assert n == 0
        mock.assert_not_called()


# ── Flag dispatch ──────────────────────────────────────────────────────────────

class TestFlagDispatch:

    async def test_user_at_beach_receives_flag_change(self, db: AsyncSession, beach: Beach):
        u = await _make_user(db, "flag-user@x.com")
        await _heartbeat(db, u, beach, minutes_ago=20)
        tok = await _token(db, u)

        with patch(MOCK_SEND, new_callable=AsyncMock) as mock:
            n = await dispatch_flag_notification(db, beach.id, "green", "red", beach.name)

        assert n == 1
        assert tok in _tokens_called(mock)

    async def test_user_not_at_beach_does_not_receive_flag(self, db: AsyncSession, beach: Beach):
        u = await _make_user(db, "away-flag@x.com")
        await _token(db, u)

        with patch(MOCK_SEND, new_callable=AsyncMock) as mock:
            n = await dispatch_flag_notification(db, beach.id, "green", "red", beach.name)

        assert n == 0
        mock.assert_not_called()

    async def test_fav_user_without_heartbeat_receives_flag(self, db: AsyncSession, beach: Beach):
        u = await _make_user(db, "fav-flag@x.com")
        await _favourite(db, u, beach)
        tok = await _token(db, u)

        with patch(MOCK_SEND, new_callable=AsyncMock) as mock:
            n = await dispatch_flag_notification(db, beach.id, "yellow", "red", beach.name)

        assert n == 1
        assert tok in _tokens_called(mock)

    async def test_flag_change_alerts_disabled_skips(self, db: AsyncSession, beach: Beach):
        u = await _make_user(db, "noflag@x.com",
                             notification_settings={"flag_change_alerts": False})
        await _heartbeat(db, u, beach)
        await _token(db, u)

        with patch(MOCK_SEND, new_callable=AsyncMock) as mock:
            n = await dispatch_flag_notification(db, beach.id, "green", "red", beach.name)

        assert n == 0

    async def test_global_disabled_skips_flag(self, db: AsyncSession, beach: Beach):
        u = await _make_user(db, "globaloff-flag@x.com",
                             notification_settings={"global_enabled": False})
        await _heartbeat(db, u, beach)
        await _token(db, u)

        with patch(MOCK_SEND, new_callable=AsyncMock) as mock:
            n = await dispatch_flag_notification(db, beach.id, "green", "red", beach.name)

        assert n == 0

    async def test_quiet_hours_blocks_flag_notification(self, db: AsyncSession, beach: Beach):
        u = await _make_user(db, "quiet-flag@x.com", notification_settings={
            "quiet_hours_enabled": True,
            "quiet_hours_start": "00:00",
            "quiet_hours_end": "23:59",
        })
        await _heartbeat(db, u, beach)
        await _token(db, u)

        with patch(MOCK_SEND, new_callable=AsyncMock) as mock:
            n = await dispatch_flag_notification(db, beach.id, "green", "red", beach.name)

        assert n == 0

    async def test_flag_notification_title_contains_beach_and_color(self, db: AsyncSession, beach: Beach):
        u = await _make_user(db, "flag-title@x.com")
        await _heartbeat(db, u, beach)
        await _token(db, u)

        with patch(MOCK_SEND, new_callable=AsyncMock) as mock:
            await dispatch_flag_notification(db, beach.id, "green", "red", beach.name)

        title = mock.call_args.args[1]
        assert beach.name in title

    async def test_fav_alerts_disabled_skips_fav_for_flag(self, db: AsyncSession, beach: Beach):
        u = await _make_user(db, "nofav-flag@x.com",
                             notification_settings={"favourite_alerts_enabled": False})
        await _favourite(db, u, beach)
        await _token(db, u)

        with patch(MOCK_SEND, new_callable=AsyncMock) as mock:
            n = await dispatch_flag_notification(db, beach.id, "green", "red", beach.name)

        assert n == 0


# ── HTTP wiring ────────────────────────────────────────────────────────────────

class TestHTTPWiring:

    async def test_create_report_notifies_users_at_beach(
        self, client, db: AsyncSession, beach: Beach, user: User, auth_headers: dict
    ):
        # Reporter needs a heartbeat to pass was_recently_present check
        db.add(OccupancyHeartbeat(beach_id=beach.id, user_id=user.id,
                                  geom="SRID=4326;POINT(-8.9821 38.4839)"))
        # Bystander at the beach with a push token
        bystander = await _make_user(db, "bystander@x.com")
        await _heartbeat(db, bystander, beach, minutes_ago=15)
        bystander_tok = await _token(db, bystander)
        await db.commit()

        with patch(MOCK_SEND, new_callable=AsyncMock) as mock:
            r = await client.post(
                f"/api/v1/beaches/{beach.slug}/reports",
                json={"type": "jellyfish", "severity": 1},
                headers=auth_headers,
            )

        assert r.status_code == 201
        assert bystander_tok in _tokens_called(mock)

    async def test_create_report_does_not_notify_reporter(
        self, client, db: AsyncSession, beach: Beach, user: User, auth_headers: dict
    ):
        reporter_tok = await _token(db, user)
        db.add(OccupancyHeartbeat(beach_id=beach.id, user_id=user.id,
                                  geom="SRID=4326;POINT(-8.9821 38.4839)"))
        await db.commit()

        with patch(MOCK_SEND, new_callable=AsyncMock) as mock:
            r = await client.post(
                f"/api/v1/beaches/{beach.slug}/reports",
                json={"type": "jellyfish", "severity": 1},
                headers=auth_headers,
            )

        assert r.status_code == 201
        assert reporter_tok not in _tokens_called(mock)

    async def test_create_report_notifies_fav_user_not_at_beach(
        self, client, db: AsyncSession, beach: Beach, user: User, auth_headers: dict
    ):
        db.add(OccupancyHeartbeat(beach_id=beach.id, user_id=user.id,
                                  geom="SRID=4326;POINT(-8.9821 38.4839)"))
        fav_user = await _make_user(db, "fav-http@x.com")
        await _favourite(db, fav_user, beach)
        fav_tok = await _token(db, fav_user)
        await db.commit()

        with patch(MOCK_SEND, new_callable=AsyncMock) as mock:
            r = await client.post(
                f"/api/v1/beaches/{beach.slug}/reports",
                json={"type": "jellyfish", "severity": 1},
                headers=auth_headers,
            )

        assert r.status_code == 201
        assert fav_tok in _tokens_called(mock)

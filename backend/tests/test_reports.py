"""Community reports and voting tests."""
from datetime import datetime, timedelta, timezone

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.beach import Beach
from app.models.beach_status import OccupancyHeartbeat
from app.models.report import Report
from app.models.user import User


VALID_REPORT = {"type": "jellyfish", "severity": 2, "note": "Muitas caravelas"}


async def _add_presence(db, beach: Beach, user: User):
    """Insert a heartbeat so the user counts as present at the beach."""
    hb = OccupancyHeartbeat(
        beach_id=beach.id,
        user_id=user.id,
        geom="SRID=4326;POINT(-8.9821 38.4839)",
    )
    db.add(hb)
    await db.commit()


async def _make_report(client, slug, headers, payload=None) -> dict:
    r = await client.post(f"/api/v1/beaches/{slug}/reports", json=payload or VALID_REPORT, headers=headers)
    assert r.status_code == 201, r.json()
    return r.json()


class TestCreateReport:
    async def test_create_requires_auth(self, client: AsyncClient, beach: Beach):
        r = await client.post("/api/v1/beaches/portinho-da-arrabida/reports", json=VALID_REPORT)
        assert r.status_code == 401

    async def test_create_requires_presence(
        self, client: AsyncClient, beach: Beach, auth_headers: dict
    ):
        r = await client.post(
            "/api/v1/beaches/portinho-da-arrabida/reports",
            json=VALID_REPORT,
            headers=auth_headers,
        )
        assert r.status_code == 403

    async def test_create_valid_report_with_presence(
        self, client: AsyncClient, beach: Beach, db, auth_headers: dict, user: User
    ):
        await _add_presence(db, beach, user)
        r = await client.post(
            "/api/v1/beaches/portinho-da-arrabida/reports",
            json=VALID_REPORT,
            headers=auth_headers,
        )
        assert r.status_code == 201
        body = r.json()
        assert body["type"] == "jellyfish"
        assert body["severity"] == 2
        assert body["upvotes"] == 0
        assert body["is_expired"] is False

    async def test_create_invalid_type(self, client: AsyncClient, beach: Beach, db, auth_headers: dict, user: User):
        await _add_presence(db, beach, user)
        r = await client.post(
            "/api/v1/beaches/portinho-da-arrabida/reports",
            json={"type": "sharks", "severity": 1},
            headers=auth_headers,
        )
        assert r.status_code == 422

    async def test_create_invalid_severity(self, client: AsyncClient, beach: Beach, db, auth_headers: dict, user: User):
        await _add_presence(db, beach, user)
        r = await client.post(
            "/api/v1/beaches/portinho-da-arrabida/reports",
            json={"type": "jellyfish", "severity": 5},
            headers=auth_headers,
        )
        assert r.status_code == 422

    async def test_create_on_nonexistent_beach(self, client: AsyncClient, auth_headers: dict):
        r = await client.post(
            "/api/v1/beaches/praia-fake/reports",
            json=VALID_REPORT,
            headers=auth_headers,
        )
        assert r.status_code == 404

    async def test_all_valid_types_accepted(
        self, client: AsyncClient, beach: Beach, db, auth_headers: dict, user: User
    ):
        await _add_presence(db, beach, user)
        for report_type in ("jellyfish", "strong_current", "pollution", "rough_sea", "other_alert"):
            r = await client.post(
                "/api/v1/beaches/portinho-da-arrabida/reports",
                json={"type": report_type, "severity": 1},
                headers=auth_headers,
            )
            assert r.status_code == 201, f"failed for type: {report_type}"


class TestListReports:
    async def test_list_active_reports(self, client: AsyncClient, beach: Beach, db, auth_headers: dict, user: User):
        await _add_presence(db, beach, user)
        await _make_report(client, "portinho-da-arrabida", auth_headers)
        r = await client.get("/api/v1/beaches/portinho-da-arrabida/reports")
        assert r.status_code == 200
        assert r.json()["total"] == 1

    async def test_list_shows_my_vote_when_authenticated(
        self, client: AsyncClient, beach: Beach, db, auth_headers: dict, user: User
    ):
        await _add_presence(db, beach, user)
        report = await _make_report(client, "portinho-da-arrabida", auth_headers)
        await client.post(
            f"/api/v1/beaches/portinho-da-arrabida/reports/{report['id']}/vote",
            json={"vote": "up"},
            headers=auth_headers,
        )
        r = await client.get("/api/v1/beaches/portinho-da-arrabida/reports", headers=auth_headers)
        assert r.json()["reports"][0]["my_vote"] == 1

    async def test_expired_reports_excluded_by_default(
        self, client: AsyncClient, beach: Beach, db: AsyncSession, user: User
    ):
        expired = Report(
            beach_id=beach.id,
            user_id=user.id,
            type="jellyfish",
            severity=1,
            expires_at=datetime.now(timezone.utc) - timedelta(hours=1),
            is_expired=True,
        )
        db.add(expired)
        await db.commit()

        r = await client.get("/api/v1/beaches/portinho-da-arrabida/reports")
        assert r.json()["total"] == 0

    async def test_expired_reports_included_with_param(
        self, client: AsyncClient, beach: Beach, db: AsyncSession, user: User
    ):
        expired = Report(
            beach_id=beach.id,
            user_id=user.id,
            type="jellyfish",
            severity=1,
            expires_at=datetime.now(timezone.utc) - timedelta(hours=1),
            is_expired=True,
        )
        db.add(expired)
        await db.commit()

        r = await client.get("/api/v1/beaches/portinho-da-arrabida/reports?include_expired=true")
        assert r.json()["total"] == 1


class TestVoting:
    async def test_upvote_increments_count(
        self, client: AsyncClient, beach: Beach, db, auth_headers: dict, user: User
    ):
        await _add_presence(db, beach, user)
        report = await _make_report(client, "portinho-da-arrabida", auth_headers)
        r = await client.post(
            f"/api/v1/beaches/portinho-da-arrabida/reports/{report['id']}/vote",
            json={"vote": "up"},
            headers=auth_headers,
        )
        assert r.status_code == 200
        assert r.json()["upvotes"] == 1

    async def test_voting_same_direction_toggles_off(
        self, client: AsyncClient, beach: Beach, db, auth_headers: dict, user: User
    ):
        await _add_presence(db, beach, user)
        report = await _make_report(client, "portinho-da-arrabida", auth_headers)
        rid = report["id"]
        await client.post(
            f"/api/v1/beaches/portinho-da-arrabida/reports/{rid}/vote",
            json={"vote": "up"}, headers=auth_headers,
        )
        r = await client.post(
            f"/api/v1/beaches/portinho-da-arrabida/reports/{rid}/vote",
            json={"vote": "up"}, headers=auth_headers,
        )
        assert r.json()["upvotes"] == 0

    async def test_vote_requires_presence(
        self, client: AsyncClient, beach: Beach, db, auth_headers: dict, user: User
    ):
        # Seed a report directly (bypass presence check) then try to vote without presence
        report = Report(
            beach_id=beach.id, user_id=user.id, type="jellyfish", severity=2,
            expires_at=datetime.now(timezone.utc) + timedelta(hours=3),
        )
        db.add(report)
        await db.commit()
        await db.refresh(report)

        r = await client.post(
            f"/api/v1/beaches/portinho-da-arrabida/reports/{report.id}/vote",
            json={"vote": "up"},
            headers=auth_headers,
        )
        assert r.status_code == 403

    async def test_vote_allowed_with_presence(
        self, client: AsyncClient, beach: Beach, db, auth_headers: dict, user: User
    ):
        await _add_presence(db, beach, user)
        report = await _make_report(client, "portinho-da-arrabida", auth_headers,
                                     payload={"type": "jellyfish", "severity": 2})
        r = await client.post(
            f"/api/v1/beaches/portinho-da-arrabida/reports/{report['id']}/vote",
            json={"vote": "up"},
            headers=auth_headers,
        )
        assert r.status_code == 200

    async def test_vote_requires_auth(self, client: AsyncClient, beach: Beach, db, auth_headers: dict, user: User):
        await _add_presence(db, beach, user)
        report = await _make_report(client, "portinho-da-arrabida", auth_headers)
        r = await client.post(
            f"/api/v1/beaches/portinho-da-arrabida/reports/{report['id']}/vote",
            json={"vote": "up"},
        )
        assert r.status_code == 401


class TestDeleteReport:
    async def test_delete_own_report(self, client: AsyncClient, beach: Beach, db, auth_headers: dict, user: User):
        await _add_presence(db, beach, user)
        report = await _make_report(client, "portinho-da-arrabida", auth_headers)
        r = await client.delete(
            f"/api/v1/beaches/portinho-da-arrabida/reports/{report['id']}",
            headers=auth_headers,
        )
        assert r.status_code == 204

    async def test_delete_other_users_report_forbidden(
        self, client: AsyncClient, beach: Beach, db,
        auth_headers: dict, user: User, user_with_rep: User
    ):
        await _add_presence(db, beach, user)
        report = await _make_report(client, "portinho-da-arrabida", auth_headers)

        from app.core.security import create_access_token
        other_token = create_access_token(user_with_rep.id, user_with_rep.reputation, user_with_rep.is_anonymous)
        r = await client.delete(
            f"/api/v1/beaches/portinho-da-arrabida/reports/{report['id']}",
            headers={"Authorization": f"Bearer {other_token}"},
        )
        assert r.status_code == 403

    async def test_delete_requires_auth(self, client: AsyncClient, beach: Beach, db, auth_headers: dict, user: User):
        await _add_presence(db, beach, user)
        report = await _make_report(client, "portinho-da-arrabida", auth_headers)
        r = await client.delete(f"/api/v1/beaches/portinho-da-arrabida/reports/{report['id']}")
        assert r.status_code == 401

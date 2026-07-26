"""Flag system tests."""
import asyncio
from datetime import datetime, timedelta, timezone

import pytest
from httpx import AsyncClient
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.beach import Beach
from app.models.beach_status import BeachStatus, FlagConfirmation, FlagProposal, OccupancyHeartbeat
from app.models.user import ReputationEvent, User
from app.core.constants import FLAG_PROPOSAL_AGGREGATION_WINDOW_MINUTES, MIN_REPUTATION_TO_PROPOSE
from app.core.security import create_access_token
from app.services.reputation import DELTA_FLAG_CONFIRMED


async def _add_heartbeat(db: AsyncSession, beach: Beach, user: User):
    hb = OccupancyHeartbeat(
        beach_id=beach.id,
        user_id=user.id,
        geom="SRID=4326;POINT(-8.9821 38.4839)",
    )
    db.add(hb)
    await db.commit()


class TestGetFlag:
    async def test_get_flag_unknown_when_no_status(self, client: AsyncClient, beach: Beach):
        r = await client.get("/api/v1/beaches/portinho-da-arrabida/flag")
        assert r.status_code == 200
        assert r.json()["flag_color"] == "unknown"

    async def test_get_flag_reflects_current_status(
        self, client: AsyncClient, beach: Beach, beach_status: BeachStatus
    ):
        r = await client.get("/api/v1/beaches/portinho-da-arrabida/flag")
        assert r.status_code == 200
        body = r.json()
        assert body["flag_color"] == "green"
        assert body["flag_confidence"] == pytest.approx(0.8)

    async def test_get_flag_nonexistent_beach(self, client: AsyncClient):
        r = await client.get("/api/v1/beaches/praia-fake/flag")
        assert r.status_code == 404


class TestProposeFlag:
    async def test_propose_requires_auth(self, client: AsyncClient, beach: Beach):
        r = await client.post(
            "/api/v1/beaches/portinho-da-arrabida/flag/propose",
            json={"color": "yellow"},
        )
        assert r.status_code == 401

    async def test_propose_requires_minimum_reputation(
        self, client: AsyncClient, beach: Beach, auth_headers: dict, db: AsyncSession, user: User
    ):
        if MIN_REPUTATION_TO_PROPOSE <= 0:
            pytest.skip("MIN_REPUTATION_TO_PROPOSE is 0, skipping test")


        await _add_heartbeat(db, beach, user)
        r = await client.post(
            "/api/v1/beaches/portinho-da-arrabida/flag/propose",
            json={"color": "yellow"},
            headers=auth_headers,
        )
        assert r.status_code == 403

    async def test_propose_requires_presence(
        self, client: AsyncClient, beach: Beach, trusted_headers: dict
    ):
        r = await client.post(
            "/api/v1/beaches/portinho-da-arrabida/flag/propose",
            json={"color": "yellow"},
            headers=trusted_headers,
        )
        assert r.status_code == 403

    async def test_propose_succeeds_with_rep_and_presence(
        self, client: AsyncClient, beach: Beach, db: AsyncSession,
        trusted_headers: dict, user_with_rep: User
    ):
        await _add_heartbeat(db, beach, user_with_rep)
        r = await client.post(
            "/api/v1/beaches/portinho-da-arrabida/flag/propose",
            json={"color": "yellow"},
            headers=trusted_headers,
        )
        assert r.status_code == 201
        assert r.json()["status"] in ("pending", "applied")

    async def test_propose_invalid_color(
        self, client: AsyncClient, beach: Beach, db: AsyncSession,
        trusted_headers: dict, user_with_rep: User
    ):
        await _add_heartbeat(db, beach, user_with_rep)
        r = await client.post(
            "/api/v1/beaches/portinho-da-arrabida/flag/propose",
            json={"color": "blue"},
            headers=trusted_headers,
        )
        assert r.status_code == 422

    async def test_propose_when_flag_already_set_returns_409(
        self, client: AsyncClient, beach: Beach, beach_status: BeachStatus, db: AsyncSession,
        trusted_headers: dict, user_with_rep: User
    ):
        await _add_heartbeat(db, beach, user_with_rep)
        r = await client.post(
            "/api/v1/beaches/portinho-da-arrabida/flag/propose",
            json={"color": "yellow"},
            headers=trusted_headers,
        )
        assert r.status_code == 409
        assert r.json()["detail"]["code"] == "flag_already_set"

    async def test_propose_aggregates_pending_weights_across_users(
        self, client: AsyncClient, beach: Beach, db: AsyncSession
    ):
        # Two heartbeat-only users, to push activity to "medium" (>= 3 distinct
        # active users) once the first proposer's heartbeat is added — "medium"
        # requires a confirmation weight of 3, more than either single proposer
        # (weight 1.5 at reputation 25) can supply alone.
        extra1 = User(email="extra_activity1@test.com", is_anonymous=False, reputation=0)
        extra2 = User(email="extra_activity2@test.com", is_anonymous=False, reputation=0)
        db.add_all([extra1, extra2])
        await db.commit()
        await db.refresh(extra1)
        await db.refresh(extra2)
        await _add_heartbeat(db, beach, extra1)
        await _add_heartbeat(db, beach, extra2)

        u1 = User(email="proposer1@test.com", is_anonymous=False, reputation=25)
        u2 = User(email="proposer2@test.com", is_anonymous=False, reputation=25)
        db.add_all([u1, u2])
        await db.commit()
        await db.refresh(u1)
        await db.refresh(u2)

        await _add_heartbeat(db, beach, u1)
        r1 = await client.post(
            "/api/v1/beaches/portinho-da-arrabida/flag/propose",
            json={"color": "yellow"},
            headers={"Authorization": f"Bearer {create_access_token(u1.id, u1.reputation, False)}"},
        )
        assert r1.status_code == 201
        assert r1.json()["status"] == "pending"

        await _add_heartbeat(db, beach, u2)
        r2 = await client.post(
            "/api/v1/beaches/portinho-da-arrabida/flag/propose",
            json={"color": "yellow"},
            headers={"Authorization": f"Bearer {create_access_token(u2.id, u2.reputation, False)}"},
        )
        assert r2.status_code == 201
        assert r2.json()["status"] == "applied"

        flag = await client.get("/api/v1/beaches/portinho-da-arrabida/flag")
        assert flag.json()["flag_color"] == "yellow"

        # Both contributors — not just the one whose proposal triggered the apply — get credited
        await db.refresh(u1)
        await db.refresh(u2)
        assert u1.reputation == 25 + DELTA_FLAG_CONFIRMED
        assert u2.reputation == 25 + DELTA_FLAG_CONFIRMED

    async def test_propose_twice_by_same_user_supersedes_instead_of_accumulating(
        self, client: AsyncClient, beach: Beach, db: AsyncSession,
        trusted_headers: dict, user_with_rep: User
    ):
        extra1 = User(email="extra1@test.com", is_anonymous=False, reputation=0)
        extra2 = User(email="extra2@test.com", is_anonymous=False, reputation=0)
        db.add_all([extra1, extra2])
        await db.commit()
        await db.refresh(extra1)
        await db.refresh(extra2)
        await _add_heartbeat(db, beach, extra1)
        await _add_heartbeat(db, beach, extra2)
        await _add_heartbeat(db, beach, user_with_rep)

        r1 = await client.post(
            "/api/v1/beaches/portinho-da-arrabida/flag/propose",
            json={"color": "yellow"},
            headers=trusted_headers,
        )
        assert r1.json()["status"] == "pending"
        first_proposal_id = r1.json()["proposal_id"]

        r2 = await client.post(
            "/api/v1/beaches/portinho-da-arrabida/flag/propose",
            json={"color": "yellow"},
            headers=trusted_headers,
        )
        # Same user's weight (1.5) must not double-count to 3.0 and auto-apply
        assert r2.json()["status"] == "pending"

        result = await db.execute(select(FlagProposal).where(FlagProposal.beach_id == beach.id))
        statuses = {p.id: p.status for p in result.scalars().all()}
        assert statuses[first_proposal_id] == "superseded"

    async def test_stale_pending_proposal_excluded_from_aggregation_and_expires(
        self, client: AsyncClient, beach: Beach, db: AsyncSession,
        trusted_headers: dict, user_with_rep: User
    ):
        from unittest.mock import patch as mock_patch

        from app.scheduler.jobs import expire_stale_flag_proposals
        from tests.conftest import TestSessionLocal

        extra1 = User(email="extra1b@test.com", is_anonymous=False, reputation=0)
        extra2 = User(email="extra2b@test.com", is_anonymous=False, reputation=0)
        db.add_all([extra1, extra2])
        await db.commit()
        await db.refresh(extra1)
        await db.refresh(extra2)
        await _add_heartbeat(db, beach, extra1)
        await _add_heartbeat(db, beach, extra2)

        stale_proposal = FlagProposal(
            beach_id=beach.id,
            user_id=extra1.id,
            proposed_color="yellow",
            initial_weight=1.5,
            status="pending",
            created_at=datetime.now(timezone.utc) - timedelta(minutes=FLAG_PROPOSAL_AGGREGATION_WINDOW_MINUTES + 30),
        )
        db.add(stale_proposal)
        await db.commit()

        await _add_heartbeat(db, beach, user_with_rep)
        r = await client.post(
            "/api/v1/beaches/portinho-da-arrabida/flag/propose",
            json={"color": "yellow"},
            headers=trusted_headers,
        )
        # 1.5 (new) + 1.5 (stale) would reach the quorum of 3.0 if the stale
        # proposal leaked in; the aggregation window must exclude it.
        assert r.json()["status"] == "pending"

        with mock_patch("app.scheduler.jobs.AsyncSessionLocal", TestSessionLocal):
            await expire_stale_flag_proposals()
        await db.refresh(stale_proposal)
        assert stale_proposal.status == "expired"

    async def test_concurrent_proposes_do_not_double_credit_shared_proposal(
        self, client: AsyncClient, beach: Beach, db: AsyncSession
    ):
        # A pre-existing pending proposal (weight 1.5) plus either of two
        # concurrent proposers (weight 1.5 each) reaches the medium-activity
        # quorum of 3.0 on its own. Without the SELECT ... FOR UPDATE lock,
        # both concurrent requests could read the same pre-commit pending
        # total, both decide to apply, and both credit the baseline proposer
        # +15 twice for the same proposal.
        extra1 = User(email="race_extra1@test.com", is_anonymous=False, reputation=0)
        extra2 = User(email="race_extra2@test.com", is_anonymous=False, reputation=0)
        db.add_all([extra1, extra2])
        await db.commit()
        await db.refresh(extra1)
        await db.refresh(extra2)
        await _add_heartbeat(db, beach, extra1)
        await _add_heartbeat(db, beach, extra2)

        # Pre-seed the status row so both requests take the SELECT ... FOR UPDATE
        # path below, isolating the aggregation race from the (separate, unrelated)
        # insert race that would otherwise fire if no row exists yet.
        db.add(BeachStatus(beach_id=beach.id, flag_color="unknown", flag_confidence=0.0))
        await db.commit()

        baseline_user = User(email="race_baseline@test.com", is_anonymous=False, reputation=25)
        db.add(baseline_user)
        await db.commit()
        await db.refresh(baseline_user)
        await _add_heartbeat(db, beach, baseline_user)

        baseline_proposal = FlagProposal(
            beach_id=beach.id, user_id=baseline_user.id, proposed_color="yellow",
            initial_weight=1.5, status="pending",
        )
        db.add(baseline_proposal)
        await db.commit()
        await db.refresh(baseline_proposal)

        u1 = User(email="race_u1@test.com", is_anonymous=False, reputation=25)
        u2 = User(email="race_u2@test.com", is_anonymous=False, reputation=25)
        db.add_all([u1, u2])
        await db.commit()
        await db.refresh(u1)
        await db.refresh(u2)
        await _add_heartbeat(db, beach, u1)
        await _add_heartbeat(db, beach, u2)

        headers1 = {"Authorization": f"Bearer {create_access_token(u1.id, u1.reputation, False)}"}
        headers2 = {"Authorization": f"Bearer {create_access_token(u2.id, u2.reputation, False)}"}

        r1, r2 = await asyncio.gather(
            client.post(
                "/api/v1/beaches/portinho-da-arrabida/flag/propose",
                json={"color": "yellow"}, headers=headers1,
            ),
            client.post(
                "/api/v1/beaches/portinho-da-arrabida/flag/propose",
                json={"color": "yellow"}, headers=headers2,
            ),
        )

        # The lock serializes the two requests: exactly one applies (the
        # first to acquire it), the other sees the flag already set and 409s.
        winner, loser = (r1, r2) if r1.status_code == 201 else (r2, r1)
        assert winner.status_code == 201
        assert winner.json()["status"] == "applied"
        assert loser.status_code == 409
        assert loser.json()["detail"]["code"] == "flag_already_set"

        result = await db.execute(
            select(ReputationEvent).where(
                ReputationEvent.event == "flag_confirmed",
                ReputationEvent.ref_id == baseline_proposal.id,
            )
        )
        assert len(result.scalars().all()) == 1


class TestConfirmFlag:
    async def test_confirm_requires_auth(self, client: AsyncClient, beach: Beach, beach_status: BeachStatus):
        r = await client.post(
            "/api/v1/beaches/portinho-da-arrabida/flag/confirm",
            json={"response": "yes"},
        )
        assert r.status_code == 401

    async def test_confirm_requires_presence(
        self, client: AsyncClient, beach: Beach, beach_status: BeachStatus, auth_headers: dict
    ):
        r = await client.post(
            "/api/v1/beaches/portinho-da-arrabida/flag/confirm",
            json={"response": "yes"},
            headers=auth_headers,
        )
        assert r.status_code == 403

    async def test_confirm_flag_yes(
        self, client: AsyncClient, beach: Beach, beach_status: BeachStatus,
        db: AsyncSession, auth_headers: dict, user: User
    ):
        await _add_heartbeat(db, beach, user)
        r = await client.post(
            "/api/v1/beaches/portinho-da-arrabida/flag/confirm",
            json={"response": "yes"},
            headers=auth_headers,
        )
        assert r.status_code == 201
        assert "new_confidence" in r.json()

    async def test_confirm_does_not_bump_updated_at_when_flag_color_unchanged(
        self, client: AsyncClient, beach: Beach, beach_status: BeachStatus,
        db: AsyncSession, auth_headers: dict, user: User
    ):
        original_updated_at = beach_status.updated_at

        await _add_heartbeat(db, beach, user)
        r = await client.post(
            "/api/v1/beaches/portinho-da-arrabida/flag/confirm",
            json={"response": "yes"},
            headers=auth_headers,
        )
        assert r.status_code == 201

        # A confidence-only write must not reset the "instance start" clock —
        # onupdate=func.now() used to bump this on every write, breaking both
        # the linear time-decay and the confirmation-window fix.
        await db.refresh(beach_status)
        assert beach_status.updated_at == original_updated_at

    async def test_confirm_flag_all_responses_valid(
        self, client: AsyncClient, beach: Beach, beach_status: BeachStatus,
        db: AsyncSession
    ):
        # Three different users confirming with different responses
        from app.core.security import create_access_token
        import uuid

        for i, response in enumerate(("yes", "no", "unsure")):
            u = User(email=f"u{i}@test.com", is_anonymous=False, reputation=0)
            db.add(u)
            await db.commit()   # commit so the client's session can find the user
            await db.refresh(u)
            await _add_heartbeat(db, beach, u)
            token = create_access_token(u.id, 0, False)
            r = await client.post(
                "/api/v1/beaches/portinho-da-arrabida/flag/confirm",
                json={"response": response},
                headers={"Authorization": f"Bearer {token}"},
            )
            assert r.status_code == 201

        await db.commit()

    async def test_confirm_rate_limited_per_hour(
        self, client: AsyncClient, beach: Beach, beach_status: BeachStatus,
        db: AsyncSession, auth_headers: dict, user: User
    ):
        await _add_heartbeat(db, beach, user)
        await client.post(
            "/api/v1/beaches/portinho-da-arrabida/flag/confirm",
            json={"response": "yes"}, headers=auth_headers,
        )
        r = await client.post(
            "/api/v1/beaches/portinho-da-arrabida/flag/confirm",
            json={"response": "yes"}, headers=auth_headers,
        )
        assert r.status_code == 429

    async def test_confirm_unknown_flag_returns_400(
        self, client: AsyncClient, beach: Beach, db: AsyncSession,
        auth_headers: dict, user: User
    ):
        await _add_heartbeat(db, beach, user)
        r = await client.post(
            "/api/v1/beaches/portinho-da-arrabida/flag/confirm",
            json={"response": "yes"}, headers=auth_headers,
        )
        assert r.status_code == 400

    async def test_confirm_ignores_confirmations_from_previous_flag_instance(
        self, client: AsyncClient, beach: Beach, db: AsyncSession
    ):
        # Contradicting vote cast two days ago, before the current flag instance existed
        status = BeachStatus(beach_id=beach.id, flag_color="green", flag_confidence=0.8)
        db.add(status)
        await db.commit()

        old_voter = User(email="old_voter@test.com", is_anonymous=False, reputation=0)
        db.add(old_voter)
        await db.commit()
        await db.refresh(old_voter)
        db.add(FlagConfirmation(
            beach_id=beach.id,
            user_id=old_voter.id,
            response="no",
            flag_color="green",
            created_at=datetime.now(timezone.utc) - timedelta(days=2),
        ))
        await db.commit()

        new_voter = User(email="new_voter@test.com", is_anonymous=False, reputation=0)
        db.add(new_voter)
        await db.commit()
        await db.refresh(new_voter)
        await _add_heartbeat(db, beach, new_voter)
        token = create_access_token(new_voter.id, new_voter.reputation, new_voter.is_anonymous)

        r = await client.post(
            "/api/v1/beaches/portinho-da-arrabida/flag/confirm",
            json={"response": "yes"},
            headers={"Authorization": f"Bearer {token}"},
        )
        assert r.status_code == 201
        # If the stale "no" leaked in, ratio would be 1/2 = 0.5; with the window
        # fix only this fresh "yes" vote counts, so confidence stays near 1.0.
        assert r.json()["new_confidence"] > 0.9


class TestFlagConfidenceJob:
    async def test_stale_flag_with_no_votes_decays_to_unknown(
        self, db: AsyncSession, beach: Beach
    ):
        from unittest.mock import patch as mock_patch

        from app.scheduler.jobs import recalculate_flag_confidences
        from tests.conftest import TestSessionLocal

        # Green flags decay to 0 confidence after 30min with no votes at all.
        # Before removing onupdate=func.now(), this instance would never reach
        # unknown: every job run that wrote flag_confidence also bumped
        # updated_at, resetting the age clock back to ~0.
        status = BeachStatus(
            beach_id=beach.id,
            flag_color="green",
            flag_confidence=0.9,
            updated_at=datetime.now(timezone.utc) - timedelta(minutes=40),
        )
        db.add(status)
        await db.commit()

        with mock_patch("app.scheduler.jobs.AsyncSessionLocal", TestSessionLocal):
            await recalculate_flag_confidences()

        await db.refresh(status)
        assert status.flag_color == "unknown"
        assert status.flag_confidence == 0.0

    async def test_contradiction_rejects_all_contributing_proposals(
        self, db: AsyncSession, beach: Beach
    ):
        from unittest.mock import patch as mock_patch

        from app.scheduler.jobs import recalculate_flag_confidences
        from tests.conftest import TestSessionLocal

        # Two proposals applied together via aggregation — both contributed,
        # so both must be rejected when the flag is later contradicted, not
        # just "the most recent" (that would only penalize one of two authors
        # who were both credited +15 when it was applied).
        u1 = User(email="contrib1@test.com", is_anonymous=False, reputation=0)
        u2 = User(email="contrib2@test.com", is_anonymous=False, reputation=0)
        db.add_all([u1, u2])
        await db.commit()
        await db.refresh(u1)
        await db.refresh(u2)

        now = datetime.now(timezone.utc)
        status = BeachStatus(beach_id=beach.id, flag_color="red", flag_confidence=1.0, updated_at=now)
        p1 = FlagProposal(
            beach_id=beach.id, user_id=u1.id, proposed_color="red",
            initial_weight=1.5, status="applied", created_at=now,
        )
        p2 = FlagProposal(
            beach_id=beach.id, user_id=u2.id, proposed_color="red",
            initial_weight=1.5, status="applied", created_at=now,
        )
        db.add_all([status, p1, p2])
        await db.commit()

        for i in range(3):
            objector = User(email=f"objector{i}@test.com", is_anonymous=False, reputation=0)
            db.add(objector)
            await db.commit()
            await db.refresh(objector)
            db.add(FlagConfirmation(
                beach_id=beach.id, user_id=objector.id, response="no",
                flag_color="red", created_at=now,
            ))
        await db.commit()

        with mock_patch("app.scheduler.jobs.AsyncSessionLocal", TestSessionLocal):
            await recalculate_flag_confidences()

        await db.refresh(p1)
        await db.refresh(p2)
        assert p1.status == "rejected"
        assert p2.status == "rejected"

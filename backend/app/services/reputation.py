"""
Reputation service — processes report/flag outcomes asynchronously.
Called by the scheduler, never inline in request handlers.
"""
from datetime import datetime, timedelta, timezone

from sqlalchemy import exists, func, select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.constants import (
    AUTO_BAN_REPUTATION_THRESHOLD as AUTO_BAN_THRESHOLD,
    SUSPENSION_DURATION_HOURS,
    SUSPENSION_REPUTATION_THRESHOLD as SUSPENSION_THRESHOLD,
)
from app.models.report import Report
from app.models.user import ReputationEvent, User

DELTA_REPORT_SUBMITTED = 1
DELTA_FIRST_REPORT_BONUS = 5
DELTA_REPORT_CONFIRMED = 10
DELTA_REPORT_CONTRADICTED = -15
DELTA_CONFIRMATION_ACCURATE = 2
DELTA_FLAG_CONFIRMED = 15
DELTA_FLAG_CONTRADICTED = -20
DELTA_SPAM_PENALTY = -5


def reputation_level(rep: int) -> str:
    if rep < 10:
        return "new"
    if rep < 50:
        return "regular"
    if rep < 150:
        return "contributor"
    return "veteran"


def proposal_weight(rep: int) -> float:
    return min(3.0, 1.0 + rep / 50)


async def apply_delta(
    db: AsyncSession,
    user_id,
    delta: int,
    event: str,
    params: dict = None,
    ref_id: int = None,
) -> None:
    evt = ReputationEvent(user_id=user_id, event=event, delta=delta, params=params, ref_id=ref_id)
    db.add(evt)

    result = await db.execute(
        update(User)
        .where(User.id == user_id)
        .values(reputation=User.reputation + delta)
        .returning(User.reputation)
    )
    rep = result.scalar_one_or_none() or 0

    # Check for auto-ban and suspension
    if rep <= AUTO_BAN_THRESHOLD:
        await db.execute(
            update(User)
            .where(User.id == user_id)
            .values(is_banned=True, ban_reason="reputation_below_threshold")
        )
    elif rep <= SUSPENSION_THRESHOLD:
        suspended_until = datetime.now(timezone.utc) + timedelta(hours=SUSPENSION_DURATION_HOURS)
        await db.execute(
            update(User)
            .where(User.id == user_id)
            .values(suspended_until=suspended_until)
        )


def _unscored_filter(event: str, ref_id_col):
    """WHERE clause excluding rows that already have a ReputationEvent of `event` for this ref id."""
    return ~exists(
        select(ReputationEvent.id).where(
            ReputationEvent.event == event,
            ReputationEvent.ref_id == ref_id_col,
        )
    )


async def process_report_outcomes(db: AsyncSession) -> None:
    """
    Check all active reports that haven't yet been scored and apply reputation
    deltas when net votes cross thresholds.
    """
    net_votes = Report.upvotes - Report.downvotes

    confirmed_result = await db.execute(
        select(Report).where(
            Report.is_expired.is_(False),
            Report.user_id.isnot(None),
            net_votes >= 3,
            _unscored_filter("report_confirmed", Report.id),
        )
    )
    for report in confirmed_result.scalars().all():
        await apply_delta(
            db, report.user_id,
            DELTA_REPORT_CONFIRMED,
            "report_confirmed",
            params={"alert_type": report.type},
            ref_id=report.id,
        )
        await db.execute(
            update(User)
            .where(User.id == report.user_id)
            .values(confirmed_reports=User.confirmed_reports + 1)
        )

    contradicted_result = await db.execute(
        select(Report).where(
            Report.is_expired.is_(False),
            Report.user_id.isnot(None),
            Report.downvotes >= 3,
            net_votes <= -2,
            _unscored_filter("report_contradicted", Report.id),
        )
    )
    for report in contradicted_result.scalars().all():
        await apply_delta(
            db, report.user_id,
            DELTA_REPORT_CONTRADICTED,
            "report_contradicted",
            params={"alert_type": report.type},
            ref_id=report.id,
        )
        await db.execute(
            update(User)
            .where(User.id == report.user_id)
            .values(false_reports=User.false_reports + 1)
        )
        # Expire the report early
        await db.execute(
            update(Report)
            .where(Report.id == report.id)
            .values(is_expired=True)
        )

    await db.commit()


async def process_flag_outcomes(db: AsyncSession) -> None:
    """
    Apply DELTA_FLAG_CONTRADICTED to authors of rejected flag proposals
    that haven't been scored yet.
    """
    from app.models.beach_status import FlagProposal

    stmt = select(FlagProposal).where(
        FlagProposal.status == "rejected",
        _unscored_filter("flag_contradicted", FlagProposal.id),
    )
    result = await db.execute(stmt)
    proposals = result.scalars().all()

    for proposal in proposals:
        await apply_delta(
            db, proposal.user_id,
            DELTA_FLAG_CONTRADICTED,
            "flag_contradicted",
            params={"color": proposal.proposed_color},
            ref_id=proposal.id,
        )

    await db.commit()


async def process_confirmation_accuracy(db: AsyncSession) -> None:
    """
    Award DELTA_CONFIRMATION_ACCURATE to users whose flag confirmation votes proved accurate:
    - "no" voters on proposals that were subsequently rejected
    - "yes" voters on proposals that remained applied for > 2 hours
    """
    from app.models.beach_status import FlagConfirmation, FlagProposal

    now = datetime.now(timezone.utc)

    # 1. Score "no" voters on rejected proposals
    rejected_result = await db.execute(
        select(FlagProposal).where(FlagProposal.status == "rejected")
    )
    for proposal in rejected_result.scalars().all():
        confs_result = await db.execute(
            select(FlagConfirmation).where(
                FlagConfirmation.beach_id == proposal.beach_id,
                FlagConfirmation.flag_color == proposal.proposed_color,
                FlagConfirmation.response == "no",
                FlagConfirmation.created_at >= proposal.created_at,
                _unscored_filter("confirmation_accurate", FlagConfirmation.id),
            )
        )
        for conf in confs_result.scalars().all():
            await apply_delta(
                db, conf.user_id,
                DELTA_CONFIRMATION_ACCURATE,
                "confirmation_accurate",
                params={"color": conf.flag_color, "outcome": "contradicted"},
                ref_id=conf.id,
            )

    # 2. Score "yes" voters on proposals still applied after 2 hours
    stable_cutoff = now - timedelta(hours=2)
    stable_result = await db.execute(
        select(FlagProposal).where(
            FlagProposal.status == "applied",
            FlagProposal.created_at <= stable_cutoff,
        )
    )
    for proposal in stable_result.scalars().all():
        confs_result = await db.execute(
            select(FlagConfirmation).where(
                FlagConfirmation.beach_id == proposal.beach_id,
                FlagConfirmation.flag_color == proposal.proposed_color,
                FlagConfirmation.response == "yes",
                FlagConfirmation.created_at >= proposal.created_at,
                _unscored_filter("confirmation_accurate", FlagConfirmation.id),
            )
        )
        for conf in confs_result.scalars().all():
            await apply_delta(
                db, conf.user_id,
                DELTA_CONFIRMATION_ACCURATE,
                "confirmation_accurate",
                params={"color": conf.flag_color, "outcome": "verified"},
                ref_id=conf.id,
            )

    await db.commit()


async def lift_expired_suspensions(db: AsyncSession) -> None:
    """Clear suspended_until for users whose suspension period has passed."""
    now = datetime.now(timezone.utc)
    await db.execute(
        update(User)
        .where(User.suspended_until.is_not(None), User.suspended_until <= now)
        .values(suspended_until=None)
    )
    await db.commit()


async def sync_account_status(db: AsyncSession) -> None:
    """
    Proactively ensures ban and suspension flags match current reputation.
    Catches users who were already below thresholds before the logic existed,
    or whose reputation was updated outside of apply_delta (e.g. direct DB edits).
    """
    now = datetime.now(timezone.utc)
    suspended_until = now + timedelta(hours=SUSPENSION_DURATION_HOURS)

    # Users below ban threshold who aren't banned yet
    await db.execute(
        update(User)
        .where(
            User.reputation <= AUTO_BAN_THRESHOLD,
            User.is_banned.is_(False),
        )
        .values(is_banned=True, ban_reason="reputation_below_threshold")
    )

    # Users between suspension and ban threshold who aren't suspended yet
    await db.execute(
        update(User)
        .where(
            User.reputation <= SUSPENSION_THRESHOLD,
            User.reputation > AUTO_BAN_THRESHOLD,
            User.is_banned.is_(False),
            User.suspended_until.is_(None),
        )
        .values(suspended_until=suspended_until)
    )

    await db.commit()


async def detect_spam(db: AsyncSession) -> None:
    """
    Apply DELTA_SPAM_PENALTY when a user submits >= 4 reports at the same beach
    in one hour AND >= 3 of those reports have net_votes <= -2 within 2 hours.
    """

    now = datetime.now(timezone.utc)
    one_hour_ago = now - timedelta(hours=1)
    two_hours_ago = now - timedelta(hours=2)

    # Find (user_id, beach_id) pairs with >= 4 reports in the last hour
    volume_stmt = (
        select(Report.user_id, Report.beach_id, func.count().label("cnt"))
        .where(
            Report.created_at >= one_hour_ago,
            Report.user_id.isnot(None),
        )
        .group_by(Report.user_id, Report.beach_id)
        .having(func.count() >= 4)
    )
    volume_result = await db.execute(volume_stmt)
    candidates = volume_result.all()

    for user_id, beach_id, _ in candidates:
        # Check if already penalised in this window
        already = await db.scalar(
            select(exists(
                select(ReputationEvent.id).where(
                    ReputationEvent.user_id == user_id,
                    ReputationEvent.event == "spam_penalty",
                    ReputationEvent.created_at >= one_hour_ago,
                )
            ))
        )
        if already:
            continue

        # Count reports with net_votes <= -2 in the last 2 hours
        bad_reports_stmt = (
            select(func.count())
            .select_from(Report)
            .where(
                Report.user_id == user_id,
                Report.beach_id == beach_id,
                Report.created_at >= two_hours_ago,
                (Report.upvotes - Report.downvotes) <= -2,
            )
        )
        bad_count = await db.scalar(bad_reports_stmt) or 0

        if bad_count >= 3:
            await apply_delta(
                db, user_id,
                DELTA_SPAM_PENALTY,
                "spam_penalty",
            )

    await db.commit()

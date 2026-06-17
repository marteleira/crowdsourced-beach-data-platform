"""
Reputation service — processes report/flag outcomes asynchronously.
Called by the scheduler, never inline in request handlers.
"""
from datetime import datetime, timedelta, timezone

from sqlalchemy import select, update, exists, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.user import User, ReputationEvent
from app.models.report import Report

DELTA_REPORT_SUBMITTED = 1
DELTA_FIRST_REPORT_BONUS = 5
DELTA_REPORT_CONFIRMED = 10
DELTA_REPORT_CONTRADICTED = -15
DELTA_CONFIRMATION_ACCURATE = 2
DELTA_FLAG_CONFIRMED = 15
DELTA_FLAG_CONTRADICTED = -20
DELTA_SPAM_PENALTY = -5

AUTO_BAN_THRESHOLD = -50


def reputation_level(rep: int) -> str:
    if rep < 10:
        return "novo"
    if rep < 50:
        return "regular"
    if rep < 150:
        return "contribuidor"
    return "veterano"


def proposal_weight(rep: int) -> float:
    return min(3.0, 1.0 + rep / 50)


async def apply_delta(
    db: AsyncSession,
    user_id,
    delta: int,
    event: str,
    reason: str,
    ref_id: int = None,
) -> None:
    evt = ReputationEvent(user_id=user_id, event=event, delta=delta, reason=reason, ref_id=ref_id)
    db.add(evt)

    await db.execute(
        update(User)
        .where(User.id == user_id)
        .values(reputation=User.reputation + delta)
    )

    # Check for auto-ban
    result = await db.execute(select(User.reputation).where(User.id == user_id))
    rep = result.scalar_one_or_none() or 0
    if rep <= AUTO_BAN_THRESHOLD:
        await db.execute(
            update(User)
            .where(User.id == user_id)
            .values(is_banned=True, ban_reason="Reputação abaixo de −50")
        )

    await db.commit()


def _already_scored(event_name: str, ref_id: int):
    """Returns a correlated-subquery expression for use in WHERE clauses."""
    return exists(
        select(ReputationEvent.id).where(
            ReputationEvent.event == event_name,
            ReputationEvent.ref_id == ref_id,
        )
    )


async def process_report_outcomes(db: AsyncSession) -> None:
    """
    Check all active reports that haven't yet been scored and apply reputation
    deltas when net votes cross thresholds.
    """
    stmt = select(Report).where(
        Report.is_expired == False,
        Report.user_id != None,
    )
    result = await db.execute(stmt)
    reports = result.scalars().all()

    for report in reports:
        net = report.upvotes - report.downvotes

        if net >= 3:
            already = await db.scalar(
                select(exists(
                    select(ReputationEvent.id).where(
                        ReputationEvent.event == "report_confirmed",
                        ReputationEvent.ref_id == report.id,
                    )
                ))
            )
            if already:
                continue
            await apply_delta(
                db, report.user_id,
                DELTA_REPORT_CONFIRMED,
                "report_confirmed",
                f"Aviso de '{report.type}' confirmado pela comunidade",
                ref_id=report.id,
            )
            await db.execute(
                update(User)
                .where(User.id == report.user_id)
                .values(confirmed_reports=User.confirmed_reports + 1)
            )
        elif report.downvotes >= 3 and net <= -2:
            already = await db.scalar(
                select(exists(
                    select(ReputationEvent.id).where(
                        ReputationEvent.event == "report_contradicted",
                        ReputationEvent.ref_id == report.id,
                    )
                ))
            )
            if already:
                continue
            await apply_delta(
                db, report.user_id,
                DELTA_REPORT_CONTRADICTED,
                "report_contradicted",
                f"Aviso de '{report.type}' rejeitado pela comunidade",
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
        ~exists(
            select(ReputationEvent.id).where(
                ReputationEvent.event == "flag_contradicted",
                ReputationEvent.ref_id == FlagProposal.id,
            )
        ),
    )
    result = await db.execute(stmt)
    proposals = result.scalars().all()

    for proposal in proposals:
        await apply_delta(
            db, proposal.user_id,
            DELTA_FLAG_CONTRADICTED,
            "flag_contradicted",
            f"Proposta de bandeira {proposal.proposed_color} rejeitada pela comunidade",
            ref_id=proposal.id,
        )

    await db.commit()


async def process_confirmation_accuracy(db: AsyncSession) -> None:
    """
    Award DELTA_CONFIRMATION_ACCURATE to users whose flag confirmation votes proved accurate:
    - "no" voters on proposals that were subsequently rejected
    - "yes" voters on proposals that remained applied for > 2 hours
    """
    from app.models.beach_status import FlagProposal, FlagConfirmation

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
                ~exists(
                    select(ReputationEvent.id).where(
                        ReputationEvent.event == "confirmation_accurate",
                        ReputationEvent.ref_id == FlagConfirmation.id,
                    )
                ),
            )
        )
        for conf in confs_result.scalars().all():
            await apply_delta(
                db, conf.user_id,
                DELTA_CONFIRMATION_ACCURATE,
                "confirmation_accurate",
                f"Confirmação precisa: bandeira {conf.flag_color} contradita",
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
                ~exists(
                    select(ReputationEvent.id).where(
                        ReputationEvent.event == "confirmation_accurate",
                        ReputationEvent.ref_id == FlagConfirmation.id,
                    )
                ),
            )
        )
        for conf in confs_result.scalars().all():
            await apply_delta(
                db, conf.user_id,
                DELTA_CONFIRMATION_ACCURATE,
                "confirmation_accurate",
                f"Confirmação precisa: bandeira {conf.flag_color} verificada",
                ref_id=conf.id,
            )

    await db.commit()


async def detect_spam(db: AsyncSession) -> None:
    """
    Apply DELTA_SPAM_PENALTY when a user submits >= 4 reports at the same beach
    in one hour AND >= 3 of those reports have net_votes <= -2 within 2 hours.
    """
    from sqlalchemy import and_

    now = datetime.now(timezone.utc)
    one_hour_ago = now - timedelta(hours=1)
    two_hours_ago = now - timedelta(hours=2)

    # Find (user_id, beach_id) pairs with >= 4 reports in the last hour
    volume_stmt = (
        select(Report.user_id, Report.beach_id, func.count().label("cnt"))
        .where(
            Report.created_at >= one_hour_ago,
            Report.user_id != None,
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
                "Múltiplos avisos rejeitados em pouco tempo",
            )

    await db.commit()

"""
Reputation service — processes report/flag outcomes asynchronously.
Called by the scheduler, never inline in request handlers.
"""
from datetime import timezone, datetime

from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.user import User, ReputationEvent
from app.models.report import Report

DELTA_REPORT_CONFIRMED = 10
DELTA_REPORT_CONTRADICTED = -15
DELTA_FLAG_CONFIRMED = 15
DELTA_FLAG_CONTRADICTED = -20
DELTA_CONFIRMATION_ACCURATE = 2
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


async def process_report_outcomes(db: AsyncSession) -> None:
    """
    Check all active reports that haven't yet been scored and apply reputation
    deltas when net votes cross thresholds.
    """
    from app.services.activity import ACTIVITY_PARAMS

    stmt = select(Report).where(
        Report.is_expired == False,
        Report.user_id != None,
    )
    result = await db.execute(stmt)
    reports = result.scalars().all()

    for report in reports:
        net = report.upvotes - report.downvotes

        if net >= 3:
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

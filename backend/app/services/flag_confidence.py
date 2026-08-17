"""
Flag confidence calculation.
Confidence decays over time without confirmations and is boosted by community responses.
"""
from datetime import datetime, timezone, timedelta


def calculate_confidence(
    confirmations: int,
    contradictions: int,
    abstentions: int,
    age_minutes: float,
    flag_color: str,
    activity_level: str = "medium",
) -> float:
    from app.services.activity import get_params

    params = get_params(activity_level)
    decay_per_minute = params["confidence_decay_per_minute"]

    total_votes = confirmations + contradictions
    if total_votes == 0:
        # No votes — pure time decay; high-risk flags decay slower
        base_decay_minutes = {"red": 120, "purple": 120, "yellow": 60, "green": 30}.get(flag_color, 60)
        return max(0.0, 1.0 - (age_minutes / base_decay_minutes))

    # Weighted ratio: abstentions count 10%
    weighted_confirm = confirmations + abstentions * 0.1
    ratio = weighted_confirm / (total_votes + abstentions * 0.1)

    # Age penalty, capped at 30%
    age_penalty = min(0.3, age_minutes * decay_per_minute)
    return max(0.0, round(ratio - age_penalty, 3))


async def recalculate_beach_confidence(db, beach_id: int, flag_color: str, updated_at: datetime, activity_level: str) -> float:
    from sqlalchemy import select, func
    from app.models.beach_status import FlagConfirmation

    now = datetime.now(timezone.utc)
    age_minutes = (now - updated_at.replace(tzinfo=timezone.utc)).total_seconds() / 60

    # Count votes for the CURRENT flag instance only — votes cast before this
    # color was (re)applied belong to a previous instance and must not leak in.
    result = await db.execute(
        select(FlagConfirmation.response, func.count().label("cnt"))
        .where(
            FlagConfirmation.beach_id == beach_id,
            FlagConfirmation.flag_color == flag_color,
            FlagConfirmation.created_at >= updated_at,
        )
        .group_by(FlagConfirmation.response)
    )
    rows = result.all()
    counts = {row.response: row.cnt for row in rows}

    return calculate_confidence(
        confirmations=counts.get("yes", 0),
        contradictions=counts.get("no", 0),
        abstentions=counts.get("unsure", 0),
        age_minutes=age_minutes,
        flag_color=flag_color,
        activity_level=activity_level,
    )


async def reset_flag_on_zero_confidence(db, status) -> None:
    """Reset the flag when confidence hits zero.

    If it was reset by downvotes rather than just expiring, mark the source 
    proposals as "rejected" so the authors take the rep hit. Make sure to run 
    this anywhere confidence can drop to zero (both the scheduled job and the 
    /confirm endpoint). Otherwise, flags that flip to "unknown" will get skipped by 
    the job's query and stay stuck in limbo forever.
    """
    from sqlalchemy import select, func
    from app.core.constants import FLAG_PROPOSAL_AGGREGATION_WINDOW_MINUTES
    from app.core.utils import now_utc
    from app.models.beach_status import FlagConfirmation, FlagProposal

    current_color = status.flag_color

    vote_result = await db.execute(
        select(FlagConfirmation.response, func.count().label("cnt"))
        .where(
            FlagConfirmation.beach_id == status.beach_id,
            FlagConfirmation.flag_color == current_color,
            FlagConfirmation.created_at >= status.updated_at,
        )
        .group_by(FlagConfirmation.response)
    )
    counts = {row.response: row.cnt for row in vote_result.all()}
    actively_contradicted = counts.get("no", 0) > counts.get("yes", 0)

    if actively_contradicted:
        instance_start = status.updated_at - timedelta(minutes=FLAG_PROPOSAL_AGGREGATION_WINDOW_MINUTES)
        proposal_result = await db.execute(
            select(FlagProposal)
            .where(
                FlagProposal.beach_id == status.beach_id,
                FlagProposal.proposed_color == current_color,
                FlagProposal.status == "applied",
                FlagProposal.created_at >= instance_start,
                FlagProposal.created_at <= status.updated_at,
            )
        )
        for proposal in proposal_result.scalars().all():
            proposal.status = "rejected"

    status.flag_color = "unknown"
    status.flag_confidence = 0.0
    status.updated_at = now_utc()

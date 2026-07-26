"""
Flag confidence calculation.
Confidence decays over time without confirmations and is boosted by community responses.
"""
from datetime import datetime, timezone


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

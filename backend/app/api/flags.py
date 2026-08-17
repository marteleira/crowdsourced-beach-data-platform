from datetime import timedelta

from fastapi import APIRouter, Depends
from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.constants import (
    FLAG_CONFIRM_WINDOW_HOURS,
    FLAG_PROPOSAL_AGGREGATION_WINDOW_MINUTES,
    FLAG_PROPOSAL_WINDOW_MINUTES,
    MIN_REPUTATION_TO_PROPOSE,
    VOTE_PRESENCE_WINDOW_HOURS,
)
from app.core.database import get_db
from app.core.deps import (
    get_beach_or_404,
    get_language,
    require_presence,
    require_registered_user,
    require_reputation,
)
from app.core.errors import api_error
from app.core.i18n import t
from app.core.utils import now_utc
from app.models.beach import Beach
from app.models.beach_status import BeachStatus, FlagConfirmation, FlagProposal
from app.models.user import User
from app.schemas.flag import (
    BeachFlagStatus,
    FlagConfirmRequest,
    FlagConfirmResponse,
    FlagProposalRequest,
    FlagProposalResponse,
)
from app.services.activity import get_activity_params
from app.services.flag_confidence import recalculate_beach_confidence, reset_flag_on_zero_confidence
from app.services.push_notifications import dispatch_flag_notification
from app.services.reputation import DELTA_FLAG_CONFIRMED, apply_delta, proposal_weight

router = APIRouter(prefix="/beaches/{slug}/flag", tags=["flags"])

async def _ensure_beach_status(db: AsyncSession, beach_id: int, for_update: bool = False) -> BeachStatus:
    stmt = select(BeachStatus).where(BeachStatus.beach_id == beach_id)
    if for_update:
        stmt = stmt.with_for_update()
    result = await db.execute(stmt)
    status = result.scalar_one_or_none()
    if not status:
        status = BeachStatus(beach_id=beach_id, flag_color="unknown", flag_confidence=0.0)
        db.add(status)
        await db.flush()
    return status


@router.get("", response_model=BeachFlagStatus)
async def get_flag_status(
    slug: str,
    db: AsyncSession = Depends(get_db),
    lang: str = Depends(get_language),
):
    beach = await get_beach_or_404(slug, db, lang)
    status = await _ensure_beach_status(db, beach.id)
    params = await get_activity_params(db, beach.id)
    return BeachFlagStatus(
        flag_color=status.flag_color,
        flag_confidence=status.flag_confidence,
        flag_source=status.flag_source,
        updated_at=status.updated_at,
        activity_label=params.label,
    )


@router.post("/propose", response_model=FlagProposalResponse, status_code=201)
async def propose_flag(
    slug: str,
    body: FlagProposalRequest,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(require_reputation(MIN_REPUTATION_TO_PROPOSE)),
    beach: Beach = Depends(
        require_presence(timedelta(minutes=FLAG_PROPOSAL_WINDOW_MINUTES), "must_be_at_beach_flag")
    ),
):
    if not beach.flags_available:
        raise api_error(400, "beach_no_flag_system", user.language)

    # Locks the row for the rest of this transaction: concurrent proposes for the
    # same beach serialize here, so the aggregation check below always reads the
    # latest committed pending-proposal set instead of racing on a stale total
    # (which could otherwise double-apply and double-credit a shared proposal).
    status = await _ensure_beach_status(db, beach.id, for_update=True)
    if status.flag_color != "unknown":
        raise api_error(409, "flag_already_set", user.language)

    # A user can only have one active pending proposal per beach — otherwise
    # they could inflate the aggregated weight by re-proposing repeatedly.
    await db.execute(
        update(FlagProposal)
        .where(
            FlagProposal.beach_id == beach.id,
            FlagProposal.user_id == user.id,
            FlagProposal.status == "pending",
        )
        .values(status="superseded")
    )

    weight = proposal_weight(user.reputation)
    proposal = FlagProposal(
        beach_id=beach.id,
        user_id=user.id,
        proposed_color=body.color,
        initial_weight=weight,
        status="pending",
    )
    db.add(proposal)
    await db.flush()

    # Aggregate this proposal's weight with other recent pending proposals for
    # the same color, so several lower-reputation users can reach quorum together.
    flag_params = await get_activity_params(db, beach.id)
    min_confirmations = flag_params.flag_confirmation_min

    window_start = now_utc() - timedelta(minutes=FLAG_PROPOSAL_AGGREGATION_WINDOW_MINUTES)
    pending_result = await db.execute(
        select(FlagProposal).where(
            FlagProposal.beach_id == beach.id,
            FlagProposal.proposed_color == body.color,
            FlagProposal.status == "pending",
            FlagProposal.created_at >= window_start,
        )
    )
    pending_proposals = pending_result.scalars().all()
    total_weight = sum(p.initial_weight for p in pending_proposals)

    if total_weight >= min_confirmations:
        await _apply_proposal(db, status, proposal, body.color, user.id)
        for other in pending_proposals:
            if other.id == proposal.id:
                continue
            other.status = "applied"
            await apply_delta(
                db, other.user_id, DELTA_FLAG_CONFIRMED,
                "flag_confirmed",
                params={"color": body.color},
                ref_id=other.id,
            )

        await db.commit()
        await dispatch_flag_notification(db, beach.id, "unknown", body.color, beach.name)

        return FlagProposalResponse(
            proposal_id=proposal.id,
            status="applied",
            code="flag_applied",
            message=t("flag_applied", user.language),
        )

    await db.commit()
    return FlagProposalResponse(
        proposal_id=proposal.id,
        status="pending",
        code="flag_pending",
        message=t("flag_pending", user.language),
    )


async def _apply_proposal(db: AsyncSession, status: BeachStatus, proposal: FlagProposal, color: str, user_id) -> None:
    status.flag_color = color
    status.flag_source = "community"
    status.flag_confidence = 1.0
    status.updated_at = now_utc()

    proposal.status = "applied"

    await apply_delta(
        db, user_id, DELTA_FLAG_CONFIRMED,
        "flag_confirmed",
        params={"color": color},
        ref_id=proposal.id,
    )


@router.post("/confirm", response_model=FlagConfirmResponse, status_code=201)
async def confirm_flag(
    slug: str,
    body: FlagConfirmRequest,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(require_registered_user),
    beach: Beach = Depends(
        require_presence(timedelta(hours=VOTE_PRESENCE_WINDOW_HOURS), "must_be_at_beach_vote")
    ),
):
    status = await _ensure_beach_status(db, beach.id)

    if status.flag_color == "unknown":
        raise api_error(400, "no_flag_to_confirm", user.language)

    # One confirmation vote per user per beach per FLAG_CONFIRM_WINDOW_HOURS
    one_hour_ago = now_utc() - timedelta(hours=FLAG_CONFIRM_WINDOW_HOURS)
    existing = await db.execute(
        select(FlagConfirmation).where(
            FlagConfirmation.user_id == user.id,
            FlagConfirmation.beach_id == beach.id,
            FlagConfirmation.created_at > one_hour_ago,
        ).limit(1)
    )
    if existing.scalar_one_or_none():
        raise api_error(429, "flag_already_confirmed", user.language)

    confirmation = FlagConfirmation(
        beach_id=beach.id,
        user_id=user.id,
        response=body.response,
        flag_color=status.flag_color,
    )
    db.add(confirmation)
    await db.flush()

    # Recalculate confidence
    confirm_params = await get_activity_params(db, beach.id)
    new_confidence = await recalculate_beach_confidence(
        db, beach.id, status.flag_color, status.updated_at, confirm_params.level
    )
    status.flag_confidence = new_confidence

    # If confidence drops to zero and reset the flag
    if new_confidence <= 0.05:
        await reset_flag_on_zero_confidence(db, status)

    await db.commit()
    return FlagConfirmResponse(status="confirmed", beach_id=beach.id, new_confidence=new_confidence)

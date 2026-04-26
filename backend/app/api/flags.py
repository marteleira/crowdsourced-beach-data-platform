from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select, update, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.deps import get_current_user, require_user
from app.models.beach import Beach
from app.models.beach_status import BeachStatus, FlagProposal, FlagConfirmation, OccupancyHeartbeat
from app.models.user import User
from app.schemas.flag import (
    FlagProposalRequest, FlagProposalResponse,
    FlagConfirmRequest, FlagConfirmResponse, BeachFlagStatus,
)
from app.services.activity import get_activity_level, get_params
from app.services.flag_confidence import recalculate_beach_confidence
from app.services.reputation import apply_delta, proposal_weight, DELTA_FLAG_CONFIRMED, DELTA_FLAG_CONTRADICTED

router = APIRouter(prefix="/beaches/{slug}/flag", tags=["flags"])

MIN_REPUTATION_TO_PROPOSE = 5


async def _get_beach_or_404(slug: str, db: AsyncSession) -> Beach:
    result = await db.execute(select(Beach).where(Beach.slug == slug))
    beach = result.scalar_one_or_none()
    if not beach:
        raise HTTPException(404, f"Praia '{slug}' não encontrada")
    return beach


async def _was_recently_present(db: AsyncSession, user_id, beach_id: int, minutes: int = 10) -> bool:
    cutoff = datetime.now(timezone.utc) - timedelta(minutes=minutes)
    result = await db.execute(
        select(OccupancyHeartbeat.id).where(
            OccupancyHeartbeat.user_id == user_id,
            OccupancyHeartbeat.beach_id == beach_id,
            OccupancyHeartbeat.created_at > cutoff,
        ).limit(1)
    )
    return result.scalar_one_or_none() is not None


async def _ensure_beach_status(db: AsyncSession, beach_id: int) -> BeachStatus:
    result = await db.execute(select(BeachStatus).where(BeachStatus.beach_id == beach_id))
    status = result.scalar_one_or_none()
    if not status:
        status = BeachStatus(beach_id=beach_id, flag_color="unknown", flag_confidence=0.0)
        db.add(status)
        await db.flush()
    return status


@router.get("", response_model=BeachFlagStatus)
async def get_flag_status(slug: str, db: AsyncSession = Depends(get_db)):
    beach = await _get_beach_or_404(slug, db)
    status = await _ensure_beach_status(db, beach.id)
    activity_level = await get_activity_level(db, beach.id)
    label = get_params(activity_level)["label"]
    return BeachFlagStatus(
        flag_color=status.flag_color,
        flag_confidence=status.flag_confidence,
        flag_source=status.flag_source,
        updated_at=status.updated_at,
        activity_label=label,
    )


@router.post("/propose", response_model=FlagProposalResponse, status_code=201)
async def propose_flag(
    slug: str,
    body: FlagProposalRequest,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(require_user),
):
    if user.reputation < MIN_REPUTATION_TO_PROPOSE:
        raise HTTPException(403, f"Reputação mínima necessária: {MIN_REPUTATION_TO_PROPOSE}")

    beach = await _get_beach_or_404(slug, db)
    if not beach.flags_available:
        raise HTTPException(400, "Esta praia não tem sistema de bandeiras")

    present = await _was_recently_present(db, user.id, beach.id, minutes=10)
    if not present:
        raise HTTPException(403, "Tens de estar na praia para propor uma bandeira")

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

    # Auto-apply if weight is high enough (reputation ≥ 100) or if it's the only proposal
    activity_level = await get_activity_level(db, beach.id)
    min_confirmations = get_params(activity_level)["flag_confirmation_min"]

    if weight >= min_confirmations:
        await _apply_proposal(db, proposal, beach.id, body.color, user.id)
        await db.commit()
        return FlagProposalResponse(
            proposal_id=proposal.id,
            status="applied",
            message="Bandeira atualizada automaticamente com base na tua reputação",
        )

    await db.commit()
    return FlagProposalResponse(
        proposal_id=proposal.id,
        status="pending",
        message="Proposta submetida. Aguarda confirmação da comunidade.",
    )


async def _apply_proposal(db: AsyncSession, proposal: FlagProposal, beach_id: int, color: str, user_id) -> None:
    status = await _ensure_beach_status(db, beach_id)
    old_color = status.flag_color

    status.flag_color = color
    status.flag_source = "community"
    status.flag_confidence = 1.0
    status.updated_at = datetime.now(timezone.utc)

    proposal.status = "applied"

    if old_color != color:
        await apply_delta(
            db, user_id, DELTA_FLAG_CONFIRMED,
            "flag_confirmed",
            f"Proposta de bandeira {color} aplicada",
            ref_id=proposal.id,
        )


@router.post("/confirm", response_model=FlagConfirmResponse, status_code=201)
async def confirm_flag(
    slug: str,
    body: FlagConfirmRequest,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(require_user),
):
    beach = await _get_beach_or_404(slug, db)
    status = await _ensure_beach_status(db, beach.id)

    if status.flag_color == "unknown":
        raise HTTPException(400, "Não há bandeira para confirmar nesta praia")

    # One vote per user per beach per hour
    one_hour_ago = datetime.now(timezone.utc) - timedelta(hours=1)
    existing = await db.execute(
        select(FlagConfirmation).where(
            FlagConfirmation.user_id == user.id,
            FlagConfirmation.beach_id == beach.id,
            FlagConfirmation.created_at > one_hour_ago,
        ).limit(1)
    )
    if existing.scalar_one_or_none():
        raise HTTPException(429, "Já confirmaste a bandeira desta praia na última hora")

    confirmation = FlagConfirmation(
        beach_id=beach.id,
        user_id=user.id,
        response=body.response,
        flag_color=status.flag_color,
    )
    db.add(confirmation)
    await db.flush()

    # Recalculate confidence
    activity_level = await get_activity_level(db, beach.id)
    new_confidence = await recalculate_beach_confidence(
        db, beach.id, status.flag_color, status.updated_at, activity_level
    )
    status.flag_confidence = new_confidence

    # If confidence drops to zero and contradictions dominate — reset flag
    if new_confidence <= 0.05:
        status.flag_color = "unknown"
        status.flag_confidence = 0.0

    await db.commit()
    return FlagConfirmResponse(status="confirmed", beach_id=beach.id, new_confidence=new_confidence)

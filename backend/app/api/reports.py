from datetime import timedelta
from typing import Optional

from fastapi import APIRouter, Depends
from sqlalchemy import func, select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.constants import REPORT_PRESENCE_WINDOW_HOURS, VOTE_PRESENCE_WINDOW_HOURS
from app.core.database import get_db
from app.core.deps import (
    get_beach_or_404,
    get_current_user,
    get_language,
    require_presence,
    require_registered_user,
    require_user,
)
from app.core.errors import api_error
from app.core.utils import now_utc
from app.models.beach import Beach
from app.models.report import Report, ReportVote
from app.models.user import ReputationEvent, User
from app.schemas.report import ReportCreate, ReportListResponse, ReportResponse, VoteRequest
from app.services.activity import get_activity_params, report_ttl_minutes
from app.services.push_notifications import dispatch_report_notification
from app.services.reputation import DELTA_FIRST_REPORT_BONUS, DELTA_REPORT_SUBMITTED, apply_delta

router = APIRouter(prefix="/beaches/{slug}/reports", tags=["reports"])


def _to_response(r: Report, my_vote: Optional[int], activity_label: Optional[str]) -> ReportResponse:
    return ReportResponse(
        id=r.id,
        beach_id=r.beach_id,
        type=r.type,
        severity=r.severity,
        note=r.note,
        upvotes=r.upvotes,
        downvotes=r.downvotes,
        created_at=r.created_at,
        expires_at=r.expires_at,
        is_expired=r.is_expired,
        verified=r.is_verified,
        my_vote=my_vote,
        activity_label=activity_label,
    )


@router.get("", response_model=ReportListResponse)
async def list_reports(
    slug: str,
    include_expired: bool = False,
    db: AsyncSession = Depends(get_db),
    user: Optional[User] = Depends(get_current_user),
    lang: str = Depends(get_language),
):
    beach = await get_beach_or_404(slug, db, user.language if user else lang)
    activity_params = await get_activity_params(db, beach.id)
    now = now_utc()

    stmt = select(Report).where(Report.beach_id == beach.id)
    if not include_expired:
        stmt = stmt.where(~Report.is_expired, Report.expires_at > now)
    stmt = stmt.order_by(Report.created_at.desc())

    result = await db.execute(stmt)
    reports = result.scalars().all()

    # Get caller's votes if authenticated
    my_votes: dict[int, int] = {}
    if user:
        vote_result = await db.execute(
            select(ReportVote).where(
                ReportVote.report_id.in_([r.id for r in reports]),
                ReportVote.user_id == user.id,
            )
        )
        for v in vote_result.scalars().all():
            my_votes[v.report_id] = v.vote

    items = [_to_response(r, my_votes.get(r.id), activity_params.label) for r in reports]
    return ReportListResponse(reports=items, total=len(items))


@router.post("", response_model=ReportResponse, status_code=201)
async def create_report(
    slug: str,
    body: ReportCreate,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(require_registered_user),
    beach: Beach = Depends(
        require_presence(timedelta(hours=REPORT_PRESENCE_WINDOW_HOURS), "must_be_at_beach_report")
    ),
):
    activity_params = await get_activity_params(db, beach.id)

    ttl = report_ttl_minutes(body.type, activity_params.level)
    expires = now_utc() + timedelta(minutes=ttl)

    geom = None
    if body.lat is not None and body.lon is not None:
        geom = f"SRID=4326;POINT({body.lon} {body.lat})"

    report = Report(
        beach_id=beach.id,
        user_id=user.id,
        type=body.type,
        severity=body.severity,
        note=body.note,
        geom=geom,
        expires_at=expires,
    )
    db.add(report)
    await db.flush()  # needed to get report.id before apply_delta

    # Bónus de primeiro report (uma vez só)
    if user.total_reports == 0:
        await apply_delta(
            db, user.id, DELTA_FIRST_REPORT_BONUS,
            "first_report_bonus",
            ref_id=report.id,
        )

    # +1 por report submetido (máx. 3 por dia)
    today_start = now_utc().replace(hour=0, minute=0, second=0, microsecond=0)
    count_today = await db.scalar(
        select(func.count()).select_from(ReputationEvent).where(
            ReputationEvent.user_id == user.id,
            ReputationEvent.event == "report_submitted",
            ReputationEvent.created_at >= today_start,
        )
    )
    if count_today < 3:
        await apply_delta(
            db, user.id, DELTA_REPORT_SUBMITTED,
            "report_submitted",
            params={"alert_type": body.type},
            ref_id=report.id,
        )

    # Increment total_reports counter
    await db.execute(
        update(User).where(User.id == user.id).values(total_reports=User.total_reports + 1)
    )

    await db.commit()
    await db.refresh(report)

    await dispatch_report_notification(
        db=db,
        beach_id=beach.id,
        alert_type=body.type,
        severity=body.severity,
        beach_name=beach.name,
        note=body.note,
        exclude_user_id=user.id,
    )

    return _to_response(report, None, activity_params.label)


@router.post("/{report_id}/vote", response_model=dict)
async def vote_report(
    slug: str,
    report_id: int,
    body: VoteRequest,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(require_registered_user),
    beach: Beach = Depends(
        require_presence(timedelta(hours=VOTE_PRESENCE_WINDOW_HOURS), "must_be_at_beach_vote")
    ),
):
    result = await db.execute(
        select(Report).where(Report.id == report_id, Report.beach_id == beach.id)
    )
    report = result.scalar_one_or_none()
    if not report or report.is_expired:
        raise api_error(404, "report_not_found_or_expired", user.language)

    vote_value = 1 if body.vote == "up" else -1

    # Upsert vote
    existing = await db.execute(
        select(ReportVote).where(
            ReportVote.report_id == report_id,
            ReportVote.user_id == user.id,
        )
    )
    existing_vote = existing.scalar_one_or_none()

    if existing_vote:
        old_value = existing_vote.vote
        if old_value == vote_value:
            # Toggle off
            await db.delete(existing_vote)
            if old_value == 1:
                report.upvotes = max(0, report.upvotes - 1)
            else:
                report.downvotes = max(0, report.downvotes - 1)
        else:
            existing_vote.vote = vote_value
            if vote_value == 1:
                report.upvotes += 1
                report.downvotes = max(0, report.downvotes - 1)
            else:
                report.downvotes += 1
                report.upvotes = max(0, report.upvotes - 1)
    else:
        db.add(ReportVote(report_id=report_id, user_id=user.id, vote=vote_value))
        if vote_value == 1:
            report.upvotes += 1
        else:
            report.downvotes += 1

    # Check for early expiry by downvotes
    vote_params = await get_activity_params(db, beach.id)
    thresholds = vote_params.contradiction_threshold
    threshold = thresholds.get(report.type, 5)
    if report.downvotes >= threshold and (report.downvotes - report.upvotes) >= 2:
        report.is_expired = True

    await db.commit()
    return {"status": "voted", "upvotes": report.upvotes, "downvotes": report.downvotes}


@router.delete("/{report_id}", status_code=204)
async def delete_report(
    slug: str,
    report_id: int,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(require_user),
):
    beach = await get_beach_or_404(slug, db, user.language)
    result = await db.execute(
        select(Report).where(Report.id == report_id, Report.beach_id == beach.id)
    )
    report = result.scalar_one_or_none()
    if not report:
        raise api_error(404, "report_not_found", user.language)
    if report.user_id != user.id:
        raise api_error(403, "report_not_yours", user.language)

    report.is_expired = True
    await db.commit()

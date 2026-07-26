"""
APScheduler jobs — periodic data fetching and lifecycle management.
All jobs are async and use a fresh DB session per execution.
"""
import logging
from collections.abc import Callable, Coroutine
from datetime import timedelta
from typing import Any, Optional

from sqlalchemy import select, update, delete, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.constants import FLAG_PROPOSAL_AGGREGATION_WINDOW_MINUTES, HEARTBEAT_CLEANUP_HOURS
from app.core.database import AsyncSessionLocal
from app.core.utils import now_utc
from app.models.beach import Beach
from app.models.beach_status import BeachStatus, FlagProposal, OccupancyHeartbeat
from app.models.report import Report
from app.models.snapshot import ApiSnapshot
from app.models.user import User
from app.services import ipma, hidrografico, eea, carris
from app.services.activity import get_activity_level
from app.services.reputation import (
    process_report_outcomes,
    process_flag_outcomes,
    process_confirmation_accuracy,
    detect_spam,
    sync_account_status,
    lift_expired_suspensions as _lift_expired_suspensions,
)
from app.services.flag_confidence import recalculate_beach_confidence

logger = logging.getLogger(__name__)


async def _all_beaches(db: AsyncSession) -> list[Beach]:
    result = await db.execute(select(Beach))
    return list(result.scalars().all())


async def _run_snapshot_job(
    source: str,
    condition: Callable[[Beach], Any],
    fetch_fn: Callable[[Beach], Coroutine],
    data_transform: Optional[Callable[[Any], Any]] = None,
) -> None:
    """Generic runner for the repeating fetch-and-snapshot pattern.

    Iterates all beaches, skips those where condition(beach) is falsy,
    calls fetch_fn(beach), and saves an ApiSnapshot. data_transform, if
    provided, wraps the returned data before storing (e.g. Carris departures).
    """
    async with AsyncSessionLocal() as db:
        beaches = await _all_beaches(db)
        for beach in beaches:
            if not condition(beach):
                continue
            try:
                data = await fetch_fn(beach)
                if data is not None:
                    payload = data_transform(data) if data_transform else data
                    db.add(ApiSnapshot(source=source, beach_id=beach.id, data=payload))
            except Exception as e:
                logger.warning("%s fetch failed for beach %d: %s", source, beach.id, e)
        await db.commit()
        logger.info("%s snapshots updated", source)


# ── External API fetch jobs ────────────────────────────────────────────────────

async def fetch_ipma_weather() -> None:
    await _run_snapshot_job(
        source="ipma_weather",
        condition=lambda b: b.ipma_global_id,
        fetch_fn=lambda b: ipma.fetch_weather_forecast(b.ipma_global_id),
    )


async def fetch_ipma_sea() -> None:
    await _run_snapshot_job(
        source="ipma_sea",
        condition=lambda b: b.ipma_sea_global_id,
        fetch_fn=lambda b: ipma.fetch_sea_forecast(b.ipma_sea_global_id),
    )


async def collect_tide_observations() -> None:
    """Store the current IH observation for all unique tide stations."""
    async with AsyncSessionLocal() as db:
        result = await db.execute(
            select(Beach.tide_station_id)
            .where(Beach.tide_station_id.isnot(None))
            .distinct()
        )
        station_ids = [row[0] for row in result.all()]

    for station_id in station_ids:
        try:
            inserted = await hidrografico.store_observation(station_id)
            if inserted:
                logger.debug("Stored tide observation for %s", station_id)
        except Exception as e:
            logger.warning("Failed to store tide observation for %s: %s", station_id, e)


async def fit_tide_models() -> None:
    """Re-fit harmonic tide models from accumulated observations (runs weekly)."""
    async with AsyncSessionLocal() as db:
        result = await db.execute(
            select(Beach.tide_station_id)
            .where(Beach.tide_station_id.isnot(None))
            .distinct()
        )
        station_ids = [row[0] for row in result.all()]

    for station_id in station_ids:
        try:
            n = await hidrografico.fit_model_from_observations(station_id)
            if n:
                logger.info("Tide model fitted for %s using %d obs", station_id, n)
        except Exception as e:
            logger.warning("Tide model fit failed for %s: %s", station_id, e)


async def fetch_tides() -> None:
    await _run_snapshot_job(
        source="tides",
        condition=lambda b: b.tide_station_id,
        fetch_fn=lambda b: hidrografico.fetch_current_tide(b.tide_station_id),
    )


async def fetch_water_quality() -> None:
    await _run_snapshot_job(
        source="water_quality",
        condition=lambda b: b.eea_station_id,
        fetch_fn=lambda b: eea.fetch_water_quality(b.eea_station_id),
    )


async def fetch_carris_stops() -> None:
    await _run_snapshot_job(
        source="carris_stops",
        condition=lambda b: b.nearby_stop_ids,
        fetch_fn=lambda b: carris.fetch_multiple_stops_departures(b.nearby_stop_ids),
        data_transform=lambda data: {"departures": data},
    )


# ── Lifecycle management jobs ──────────────────────────────────────────────────

async def expire_stale_reports() -> None:
    """Mark reports past their expires_at as expired."""
    async with AsyncSessionLocal() as db:
        now = now_utc()
        await db.execute(
            update(Report)
            .where(Report.is_expired.is_(False), Report.expires_at <= now)
            .values(is_expired=True)
        )
        await db.commit()


async def expire_stale_flag_proposals() -> None:
    """Expire pending proposals that fell outside the aggregation window without reaching quorum."""
    async with AsyncSessionLocal() as db:
        cutoff = now_utc() - timedelta(minutes=FLAG_PROPOSAL_AGGREGATION_WINDOW_MINUTES)
        await db.execute(
            update(FlagProposal)
            .where(FlagProposal.status == "pending", FlagProposal.created_at < cutoff)
            .values(status="expired")
        )
        await db.commit()


async def process_reputation() -> None:
    async with AsyncSessionLocal() as db:
        await process_report_outcomes(db)
        await process_flag_outcomes(db)
        await process_confirmation_accuracy(db)
        await detect_spam(db)
        await sync_account_status(db)


async def recalculate_flag_confidences() -> None:
    from app.models.beach_status import FlagConfirmation

    async with AsyncSessionLocal() as db:
        result = await db.execute(select(BeachStatus).where(BeachStatus.flag_color != "unknown"))
        statuses = result.scalars().all()
        for status in statuses:
            activity_level = await get_activity_level(db, status.beach_id)
            current_color = status.flag_color
            new_conf = await recalculate_beach_confidence(
                db, status.beach_id, current_color, status.updated_at, activity_level
            )
            status.flag_confidence = new_conf
            if new_conf <= 0.05:
                # Determine if the reset is due to active contradiction (not just time decay).
                # Only votes cast against the current flag instance count.
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
                    # Mark every proposal that contributed to THIS instance as rejected
                    # (aggregation can apply several at once, not just one). Bounded to
                    # the aggregation window before updated_at so an older, already
                    # resolved instance's applied proposals for the same color — left
                    # "applied" by a prior decay-only reset — aren't swept in too.
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
        await db.commit()
        logger.info("Flag confidences recalculated")


async def lift_expired_suspensions() -> None:
    """Clear suspended_until for users whose suspension period has passed."""
    async with AsyncSessionLocal() as db:
        await _lift_expired_suspensions(db)


async def cleanup_old_heartbeats() -> None:
    """Keep only the last HEARTBEAT_CLEANUP_HOURS of heartbeats."""
    async with AsyncSessionLocal() as db:
        cutoff = now_utc() - timedelta(hours=HEARTBEAT_CLEANUP_HOURS)
        await db.execute(
            delete(OccupancyHeartbeat).where(OccupancyHeartbeat.created_at < cutoff)
        )
        await db.commit()
        logger.info("Old heartbeats cleaned up")


async def purge_scheduled_deletions() -> None:
    """Hard-delete user accounts whose 30-day grace period has elapsed."""
    async with AsyncSessionLocal() as db:
        now = now_utc()
        result = await db.execute(
            select(User).where(
                User.scheduled_deletion_at.is_not(None),
                User.scheduled_deletion_at <= now,
            )
        )
        users = result.scalars().all()
        for user in users:
            await db.execute(
                update(Report).where(Report.user_id == user.id).values(is_expired=True)
            )
            await db.delete(user)
        await db.commit()
        if users:
            logger.info("Purged %d scheduled account deletion(s)", len(users))


async def cleanup_old_snapshots() -> None:
    """Keep only the latest 5 snapshots per (source, beach_id)."""
    async with AsyncSessionLocal() as db:
        # For each (source, beach_id) combination, delete all but the 5 newest
        result = await db.execute(
            select(ApiSnapshot.source, ApiSnapshot.beach_id).distinct()
        )
        pairs = result.all()
        for source, beach_id in pairs:
            subq = (
                select(ApiSnapshot.id)
                .where(ApiSnapshot.source == source, ApiSnapshot.beach_id == beach_id)
                .order_by(ApiSnapshot.fetched_at.desc())
                .limit(5)
                .subquery()
            )
            await db.execute(
                delete(ApiSnapshot).where(
                    ApiSnapshot.source == source,
                    ApiSnapshot.beach_id == beach_id,
                    ApiSnapshot.id.not_in(select(subq.c.id)),
                )
            )
        await db.commit()
        logger.info("Old snapshots cleaned up")

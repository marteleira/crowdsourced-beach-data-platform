"""
APScheduler jobs — periodic data fetching and lifecycle management.
All jobs are async and use a fresh DB session per execution.
"""
import logging
from datetime import datetime, timedelta, timezone

from sqlalchemy import select, update, delete, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import AsyncSessionLocal
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
    return result.scalars().all()


# ── External API fetch jobs ────────────────────────────────────────────────────

async def fetch_ipma_weather() -> None:
    async with AsyncSessionLocal() as db:
        beaches = await _all_beaches(db)
        for beach in beaches:
            if not beach.ipma_global_id:
                continue
            try:
                data = await ipma.fetch_weather_forecast(beach.ipma_global_id)
                if data:
                    snap = ApiSnapshot(source="ipma_weather", beach_id=beach.id, data=data)
                    db.add(snap)
            except Exception as e:
                logger.warning("IPMA weather fetch failed for beach %d: %s", beach.id, e)
        await db.commit()
        logger.info("IPMA weather snapshots updated")


async def fetch_ipma_sea() -> None:
    async with AsyncSessionLocal() as db:
        beaches = await _all_beaches(db)
        for beach in beaches:
            if not beach.ipma_sea_global_id:
                continue
            try:
                data = await ipma.fetch_sea_forecast(beach.ipma_sea_global_id)
                if data:
                    snap = ApiSnapshot(source="ipma_sea", beach_id=beach.id, data=data)
                    db.add(snap)
            except Exception as e:
                logger.warning("IPMA sea fetch failed for beach %d: %s", beach.id, e)
        await db.commit()
        logger.info("IPMA sea snapshots updated")


async def collect_tide_observations() -> None:
    """Store the current IH observation for all unique tide stations."""
    async with AsyncSessionLocal() as db:
        result = await db.execute(
            select(Beach.tide_station_id)
            .where(Beach.tide_station_id != None)
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
            .where(Beach.tide_station_id != None)
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
    async with AsyncSessionLocal() as db:
        beaches = await _all_beaches(db)
        for beach in beaches:
            if not beach.tide_station_id:
                continue
            try:
                data = await hidrografico.fetch_current_tide(beach.tide_station_id)
                if data:
                    snap = ApiSnapshot(source="tides", beach_id=beach.id, data=data)
                    db.add(snap)
            except Exception as e:
                logger.warning("Tides fetch failed for beach %d: %s", beach.id, e)
        await db.commit()
        logger.info("Tide snapshots updated")


async def fetch_water_quality() -> None:
    async with AsyncSessionLocal() as db:
        beaches = await _all_beaches(db)
        for beach in beaches:
            if not beach.eea_station_id:
                continue
            try:
                data = await eea.fetch_water_quality(beach.eea_station_id)
                if data:
                    snap = ApiSnapshot(source="water_quality", beach_id=beach.id, data=data)
                    db.add(snap)
            except Exception as e:
                logger.warning("EEA water quality fetch failed for beach %d: %s", beach.id, e)
        await db.commit()
        logger.info("Water quality snapshots updated")


async def fetch_carris_stops() -> None:
    async with AsyncSessionLocal() as db:
        beaches = await _all_beaches(db)
        for beach in beaches:
            if not beach.nearby_stop_ids:
                continue
            try:
                data = await carris.fetch_multiple_stops_departures(beach.nearby_stop_ids)
                if data is not None:
                    snap = ApiSnapshot(source="carris_stops", beach_id=beach.id, data={"departures": data})
                    db.add(snap)
            except Exception as e:
                logger.warning("Carris fetch failed for beach %d: %s", beach.id, e)
        await db.commit()
        logger.info("Carris snapshots updated")


# ── Lifecycle management jobs ──────────────────────────────────────────────────

async def expire_stale_reports() -> None:
    """Mark reports past their expires_at as expired."""
    async with AsyncSessionLocal() as db:
        now = datetime.now(timezone.utc)
        await db.execute(
            update(Report)
            .where(Report.is_expired == False, Report.expires_at <= now)
            .values(is_expired=True)
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
    from sqlalchemy import func
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
                # Determine if the reset is due to active contradiction (not just time decay)
                vote_result = await db.execute(
                    select(FlagConfirmation.response, func.count().label("cnt"))
                    .where(
                        FlagConfirmation.beach_id == status.beach_id,
                        FlagConfirmation.flag_color == current_color,
                    )
                    .group_by(FlagConfirmation.response)
                )
                counts = {row.response: row.cnt for row in vote_result.all()}
                actively_contradicted = counts.get("no", 0) > counts.get("yes", 0)

                if actively_contradicted:
                    # Mark the most recent applied proposal as rejected
                    proposal_result = await db.execute(
                        select(FlagProposal)
                        .where(
                            FlagProposal.beach_id == status.beach_id,
                            FlagProposal.proposed_color == current_color,
                            FlagProposal.status == "applied",
                        )
                        .order_by(FlagProposal.created_at.desc())
                        .limit(1)
                    )
                    proposal = proposal_result.scalar_one_or_none()
                    if proposal:
                        proposal.status = "rejected"

                status.flag_color = "unknown"
                status.flag_confidence = 0.0
        await db.commit()
        logger.info("Flag confidences recalculated")


async def lift_expired_suspensions() -> None:
    """Clear suspended_until for users whose suspension period has passed."""
    async with AsyncSessionLocal() as db:
        await _lift_expired_suspensions(db)


async def cleanup_old_heartbeats() -> None:
    """Keep only the last 2 hours of heartbeats."""
    async with AsyncSessionLocal() as db:
        cutoff = datetime.now(timezone.utc) - timedelta(hours=2)
        await db.execute(
            delete(OccupancyHeartbeat).where(OccupancyHeartbeat.created_at < cutoff)
        )
        await db.commit()
        logger.info("Old heartbeats cleaned up")


async def purge_scheduled_deletions() -> None:
    """Hard-delete user accounts whose 30-day grace period has elapsed."""
    async with AsyncSessionLocal() as db:
        now = datetime.now(timezone.utc)
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

from apscheduler.schedulers.asyncio import AsyncIOScheduler
from apscheduler.triggers.interval import IntervalTrigger

from app.scheduler import jobs


def create_scheduler() -> AsyncIOScheduler:
    scheduler = AsyncIOScheduler(timezone="Europe/Lisbon")

    # External API refreshes
    scheduler.add_job(jobs.fetch_ipma_weather,    IntervalTrigger(minutes=30),  id="ipma_weather",    replace_existing=True)
    scheduler.add_job(jobs.fetch_ipma_sea,        IntervalTrigger(minutes=30),  id="ipma_sea",        replace_existing=True)
    scheduler.add_job(jobs.fetch_tides,           IntervalTrigger(hours=6),     id="tides",           replace_existing=True)
    scheduler.add_job(jobs.fetch_water_quality,   IntervalTrigger(hours=24),    id="water_quality",   replace_existing=True)
    scheduler.add_job(jobs.fetch_carris_stops,    IntervalTrigger(minutes=10),  id="carris_stops",    replace_existing=True)

    # Lifecycle
    scheduler.add_job(jobs.expire_stale_reports,          IntervalTrigger(minutes=5),  id="expire_reports",       replace_existing=True)
    scheduler.add_job(jobs.process_reputation,            IntervalTrigger(minutes=2),  id="reputation",           replace_existing=True)
    scheduler.add_job(jobs.recalculate_flag_confidences,  IntervalTrigger(minutes=10), id="flag_confidence",      replace_existing=True)
    scheduler.add_job(jobs.cleanup_old_heartbeats,        IntervalTrigger(hours=1),    id="cleanup_heartbeats",   replace_existing=True)
    scheduler.add_job(jobs.cleanup_old_snapshots,         IntervalTrigger(hours=6),    id="cleanup_snapshots",    replace_existing=True)

    return scheduler

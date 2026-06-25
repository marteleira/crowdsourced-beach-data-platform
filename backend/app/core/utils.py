"""
Shared utility functions for the OndaCerta backend.
"""
from datetime import datetime, timezone


def now_utc() -> datetime:
    """Return the current UTC datetime (timezone-aware).
    Single source of truth — avoids datetime.now(timezone.utc) scattered everywhere."""
    return datetime.now(timezone.utc)


def ensure_utc(dt: datetime) -> datetime:
    """Return dt with UTC timezone attached if it lacks tzinfo."""
    return dt if dt.tzinfo is not None else dt.replace(tzinfo=timezone.utc)

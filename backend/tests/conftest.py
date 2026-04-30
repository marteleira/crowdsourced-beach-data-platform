"""
Shared test fixtures.

Uses a dedicated arrabida_test database. Tables are created once per session
and truncated after each test for isolation.

Two separate session concerns:
  - `db`     fixture → used by tests to seed data directly
  - `client` fixture → AsyncClient whose requests use their own DB sessions
"""
from typing import AsyncGenerator
from unittest.mock import patch

import pytest
from httpx import AsyncClient, ASGITransport
from sqlalchemy import text
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession
from sqlalchemy.pool import NullPool

from app.core.database import Base, get_db
from app.core.security import hash_password, create_access_token
from app.models.all_models import *  # noqa: F401,F403
from app.models.beach import Beach
from app.models.beach_status import BeachStatus
from app.models.user import User

TEST_DB_URL = "postgresql+asyncpg://postgres@localhost:5432/arrabida_test"

# NullPool: each session gets a fresh connection, closed immediately on release.
# This avoids "another operation in progress" errors between fixtures and requests.
test_engine = create_async_engine(TEST_DB_URL, echo=False, poolclass=NullPool)
TestSessionLocal = async_sessionmaker(test_engine, expire_on_commit=False)


# ── Schema setup (once per session) ───────────────────────────────────────────

@pytest.fixture(scope="session", autouse=True)
async def setup_schema():
    async with test_engine.begin() as conn:
        await conn.execute(text("CREATE EXTENSION IF NOT EXISTS postgis"))
        await conn.execute(text("CREATE EXTENSION IF NOT EXISTS pgcrypto"))
        await conn.run_sync(Base.metadata.drop_all)
        await conn.run_sync(Base.metadata.create_all)
    yield
    async with test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)


# ── Per-test cleanup ───────────────────────────────────────────────────────────

TRUNCATE_ORDER = [
    "report_votes", "reports",
    "flag_confirmations", "flag_proposals", "beach_status",
    "occupancy_heartbeats",
    "reputation_events", "refresh_tokens",
    "api_snapshots",
    "user_achievements", "user_favourites", "push_tokens",
    "users", "beaches",
]

@pytest.fixture(autouse=True)
async def clean_tables():
    yield
    async with TestSessionLocal() as session:
        for table in TRUNCATE_ORDER:
            await session.execute(text(f"TRUNCATE TABLE {table} RESTART IDENTITY CASCADE"))
        await session.commit()


# ── DB session (for test data setup) ──────────────────────────────────────────

@pytest.fixture
async def db() -> AsyncGenerator[AsyncSession, None]:
    async with TestSessionLocal() as session:
        yield session
        await session.commit()


# ── App client (uses its own sessions via override) ────────────────────────────

@pytest.fixture
async def client() -> AsyncGenerator[AsyncClient, None]:
    from app.main import app

    async def override_get_db():
        async with TestSessionLocal() as session:
            yield session

    app.dependency_overrides[get_db] = override_get_db

    with patch("app.scheduler.setup.create_scheduler") as mock_sched:
        mock_sched.return_value.start = lambda: None
        mock_sched.return_value.shutdown = lambda **kw: None
        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as c:
            yield c

    app.dependency_overrides.clear()


# ── Data fixtures ──────────────────────────────────────────────────────────────

@pytest.fixture
async def beach(db: AsyncSession) -> Beach:
    b = Beach(
        slug="portinho-da-arrabida",
        name="Portinho da Arrábida",
        lat=38.4839, lon=-8.9821,
        geom="SRID=4326;POINT(-8.9821 38.4839)",
        ipma_global_id=1151200,
        ipma_sea_global_id=1111026,
        apa_station_id="PT06ART0002",
        tide_station_id="setubal",
        has_capacity_data=False,
        max_capacity=800,
        nearby_stop_ids=[],
        flags_available=True,
    )
    db.add(b)
    await db.commit()
    await db.refresh(b)
    return b


@pytest.fixture
async def beach_status(db: AsyncSession, beach: Beach) -> BeachStatus:
    s = BeachStatus(beach_id=beach.id, flag_color="green", flag_confidence=0.8)
    db.add(s)
    await db.commit()
    await db.refresh(s)
    return s


@pytest.fixture
async def user(db: AsyncSession) -> User:
    u = User(
        email="test@example.com",
        display_name="Test User",
        password_hash=hash_password("password123"),
        is_anonymous=False,
        reputation=0,
    )
    db.add(u)
    await db.commit()
    await db.refresh(u)
    return u


@pytest.fixture
async def user_with_rep(db: AsyncSession) -> User:
    u = User(
        email="trusted@example.com",
        display_name="Trusted User",
        password_hash=hash_password("password123"),
        is_anonymous=False,
        reputation=20,
    )
    db.add(u)
    await db.commit()
    await db.refresh(u)
    return u


@pytest.fixture
def auth_headers(user: User) -> dict:
    token = create_access_token(user.id, user.reputation, user.is_anonymous)
    return {"Authorization": f"Bearer {token}"}


@pytest.fixture
def trusted_headers(user_with_rep: User) -> dict:
    token = create_access_token(user_with_rep.id, user_with_rep.reputation, user_with_rep.is_anonymous)
    return {"Authorization": f"Bearer {token}"}

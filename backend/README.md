# Arrábida Backend

REST API for the OndaCerta information and community platform. Aggregates official data from IPMA, Instituto Hidrográfico and Carris Metropolitana, provides a community layer for real-time beach conditions.

---

## Table of contents

- [Stack](#stack)
- [Prerequisites](#prerequisites)
- [Local setup](#local-setup)
- [Environment variables](#environment-variables)
- [Database](#database)
- [Running the server](#running-the-server)
- [Running tests](#running-tests)
- [Project structure](#project-structure)
- [API reference](#api-reference)
- [External APIs](#external-apis)
- [Key design decisions](#key-design-decisions)

---

## Stack

| Layer | Technology |
|---|---|
| Framework | FastAPI + Uvicorn |
| ORM | SQLAlchemy 2 (async) + asyncpg |
| Database | PostgreSQL 16 + PostGIS |
| Migrations | Alembic |
| Background jobs | APScheduler |
| Auth | JWT (python-jose) + bcrypt + Google Sign-In |
| HTTP client | httpx (async) |
| Tests | pytest + pytest-asyncio |

---

## Prerequisites

- Python 3.11+
- PostgreSQL 16 with the **PostGIS** extension
- `pip` or any Python package manager

Install PostGIS on Arch Linux (the best distro btw...):
```bash
sudo pacman -S postgis
```

---

## Local setup

```bash
# 1. Clone and enter the backend directory
cd backend

# 2. Create and activate a virtual environment
python -m venv .venv
source .venv/bin/activate

# 3. Install dependencies
pip install -r requirements.txt

# 4. Create the database and enable extensions
psql -U postgres -c "CREATE DATABASE arrabida;"
psql -U postgres -d arrabida -c "CREATE EXTENSION IF NOT EXISTS postgis;"
psql -U postgres -d arrabida -c "CREATE EXTENSION IF NOT EXISTS pgcrypto;"

# 5. Configure environment
cp .env.example .env
# Edit .env — at minimum set JWT_SECRET and GOOGLE_CLIENT_ID

# 6. Run migrations
alembic upgrade head

# 7. Seed beaches
python scripts/seed_beaches.py
```

---

## Environment variables

| Variable | Description | Default |
|---|---|---|
| `DATABASE_URL` | Async PostgreSQL connection string | `postgresql+asyncpg://postgres@localhost:5432/arrabida` |
| `JWT_SECRET` | Secret used to sign access tokens — **change in production** | `dev-secret-change-in-production` |
| `JWT_ACCESS_EXPIRE_MINUTES` | Access token lifetime in minutes | `15` |
| `JWT_REFRESH_EXPIRE_DAYS` | Refresh token lifetime in days | `30` |
| `GOOGLE_CLIENT_ID` | OAuth client ID from Google Cloud Console (required for Google login) | *(empty)* |
| `CORS_ORIGINS` | JSON array of allowed origins | `["http://localhost:3000"]` |
| `ENVIRONMENT` | `development` or `production` | `development` |

---

## Database

### Migrations

```bash
# Apply all pending migrations
alembic upgrade head

# Roll back one migration
alembic downgrade -1

# Generate a new migration after changing models
alembic revision --autogenerate -m "description"
```

### Seed data

The seed script inserts the 13 Arrábida beaches with their coordinates, IPMA forecast IDs, APA water quality station IDs, and Instituto Hidrográfico tide station IDs:

```bash
python scripts/seed_beaches.py
```

> **Note:** Carris Metropolitana stop IDs (`nearby_stop_ids`) and APA station IDs need to be verified against the live APIs before production use. They are placeholders in the seed script.

### Schema overview

| Table | Purpose |
|---|---|
| `beaches` | Master list of beaches with external API identifiers |
| `users` | Accounts (email/password, Google, anonymous guest) |
| `refresh_tokens` | Server-side refresh token store for revocation |
| `reputation_events` | Immutable audit log of reputation changes |
| `reports` | Community alerts (jellyfish, current, pollution, etc.) |
| `report_votes` | One vote per user per report |
| `beach_status` | Current flag color + confidence score per beach |
| `flag_proposals` | Proposed flag changes, pending community confirmation |
| `flag_confirmations` | yes/no/unsure responses to active flag prompts |
| `occupancy_heartbeats` | Presence pings sent by the Flutter app every ~5 min |
| `api_snapshots` | Cached payloads from external APIs, used as fallback |

---

## Running the server

```bash
source .venv/bin/activate
uvicorn app.main:app --reload
```

Interactive API docs: **http://localhost:8000/docs**

The server starts an APScheduler instance on startup that periodically fetches and caches data from all external APIs. This runs in-process — no separate worker needed.

---

## Running tests

Tests run against a dedicated `arrabida_test` database:

```bash
psql -U postgres -c "CREATE DATABASE arrabida_test;"
psql -U postgres -d arrabida_test -c "CREATE EXTENSION IF NOT EXISTS postgis;"
psql -U postgres -d arrabida_test -c "CREATE EXTENSION IF NOT EXISTS pgcrypto;"
```

Then:

```bash
source .venv/bin/activate
pytest tests/ -q
```

The test suite creates and tears down the schema automatically. External API calls are mocked — no internet connection required.

```bash
# Run a specific file
pytest tests/test_reports.py -v

# Run with coverage
pytest tests/ --cov=app --cov-report=term-missing
```

---

## Project structure

```
backend/
├── app/
│   ├── main.py                  # FastAPI app, lifespan, router registration
│   ├── api/
│   │   ├── auth.py              # POST /auth/* — register, login, Google, refresh, promote
│   │   ├── beaches.py           # GET /beaches, GET /beaches/{slug}
│   │   ├── weather.py           # GET /beaches/{slug}/weather  (IPMA)
│   │   ├── tides.py             # GET /beaches/{slug}/tides    (Instituto Hidrográfico)
│   │   ├── water_quality.py     # GET /beaches/{slug}/water-quality  (APA)
│   │   ├── transport.py         # GET /beaches/{slug}/transport  (Carris)
│   │   ├── reports.py           # Community alerts + voting
│   │   ├── flags.py             # Flag proposals + confirmation
│   │   ├── occupancy.py         # Presence heartbeats
│   │   └── users.py             # Profile + reputation history
│   ├── core/
│   │   ├── config.py            # Settings (pydantic-settings, .env)
│   │   ├── database.py          # Async engine + session factory
│   │   ├── deps.py              # FastAPI dependencies (auth guards)
│   │   └── security.py          # JWT, bcrypt, Google token verification
│   ├── models/                  # SQLAlchemy ORM models
│   ├── schemas/                 # Pydantic request/response models
│   ├── services/
│   │   ├── ipma.py              # IPMA weather + sea forecast client
│   │   ├── hidrografico.py      # Instituto Hidrográfico tides client
│   │   ├── apa.py               # APA water quality client
│   │   ├── carris.py            # Carris Metropolitana client
│   │   ├── snapshot.py          # fetch_with_fallback — live → cache
│   │   ├── activity.py          # Beach activity level + dynamic parameters
│   │   ├── reputation.py        # Reputation delta processing
│   │   └── flag_confidence.py   # Flag confidence decay calculation
│   └── scheduler/
│       ├── jobs.py              # All periodic job functions
│       └── setup.py             # APScheduler configuration
├── alembic/                     # Database migrations
│   └── versions/
│       └── 0001_initial_schema.py
├── tests/
│   ├── conftest.py              # Test DB, fixtures, client
│   ├── test_auth.py
│   ├── test_beaches.py
│   ├── test_reports.py
│   ├── test_flags.py
│   ├── test_occupancy.py
│   ├── test_users.py
│   └── test_external_data.py
├── scripts/
│   └── seed_beaches.py
├── alembic.ini
├── pytest.ini
├── requirements.txt
└── .env.example
```

---

## API reference

All endpoints are prefixed with `/api/v1`.

### Authentication

| Method | Path | Auth | Description |
|---|---|---|---|
| `POST` | `/auth/guest` | — | Create anonymous session |
| `POST` | `/auth/register` | — | Register with email + password |
| `POST` | `/auth/login` | — | Login with email + password |
| `POST` | `/auth/google` | — | Login with Google id_token |
| `POST` | `/auth/refresh` | — | Rotate refresh token |
| `POST` | `/auth/logout` | Bearer | Revoke refresh token |
| `POST` | `/auth/promote` | Bearer | Upgrade anonymous account to full account |

### Beaches

| Method | Path | Auth | Description |
|---|---|---|---|
| `GET` | `/beaches` | Optional | List all beaches. Pass `?lat=&lon=` for proximity-ranked results |
| `GET` | `/beaches/{slug}` | Optional | Full beach detail — conditions, alerts, weather, tides, transport |
| `GET` | `/beaches/{slug}/weather` | — | IPMA 5-day weather forecast |
| `GET` | `/beaches/{slug}/sea` | — | IPMA sea state forecast (wave height, period, SST) |
| `GET` | `/beaches/{slug}/tides` | — | Today's tide table (Instituto Hidrográfico) |
| `GET` | `/beaches/{slug}/water-quality` | — | APA bathing water classification |
| `GET` | `/beaches/{slug}/transport` | — | Next Carris bus departures from nearby stops |

### Community layer

| Method | Path | Auth | Description |
|---|---|---|---|
| `GET` | `/beaches/{slug}/reports` | Optional | Active community alerts. Pass `?include_expired=true` for full history |
| `POST` | `/beaches/{slug}/reports` | Bearer + **presence** | Submit an alert. User must have a heartbeat in the last hour |
| `POST` | `/beaches/{slug}/reports/{id}/vote` | Bearer + **presence** | Upvote or downvote a report. Presence required |
| `DELETE` | `/beaches/{slug}/reports/{id}` | Bearer (owner) | Soft-delete own report |
| `GET` | `/beaches/{slug}/flag` | — | Current flag status + confidence |
| `POST` | `/beaches/{slug}/flag/propose` | Bearer + **presence** + rep ≥ 5 | Propose a flag color change |
| `POST` | `/beaches/{slug}/flag/confirm` | Bearer | Confirm or contradict current flag (rate-limited: once per hour per beach) |
| `POST` | `/beaches/{slug}/occupancy/heartbeat` | Bearer | Send presence ping — used for occupancy counting and presence checks |

### Users

| Method | Path | Auth | Description |
|---|---|---|---|
| `GET` | `/users/me` | Bearer | Profile, reputation level, stats |
| `GET` | `/users/me/reputation-history` | Bearer | Paginated reputation event log |

### Health

| Method | Path | Description |
|---|---|---|
| `GET` | `/health` | Returns `{"status": "ok"}` |

---

## External APIs

### IPMA — weather and sea forecasts
- **Base URL:** `https://api.ipma.pt/open-data`
- **Auth:** None
- **Update frequency:** ~2× per day
- **Endpoints used:**
  - `forecast/meteorology/cities/daily/hp-daily-forecast-day{0-4}.json` — 5-day weather forecast (filter by `globalIdLocal`)
  - `forecast/oceanography/daily/hp-daily-sea-forecast-day{0-3}.json` — Sea state forecast
- **globalIdLocal for Arrábida:** `1151200` (weather, Setúbal), `1111026` (sea, Arrábida coast)

### Instituto Hidrográfico — tide predictions
- **Base URL:** `https://api-features.hidrografico.pt`
- **Auth:** None
- **Standard:** OGC API Features
- **Update frequency:** Daily (astronomical data)
- **Collection used:** `PredMaresLocal` filtered by station ID and date range

### APA InfoÁgua — bathing water quality
- **Base URL:** `https://sniamb.apambiente.pt/api`
- **Auth:** None
- **Update frequency:** Daily (lab analysis results)
- **Fallback:** GeoServer WFS endpoint at `geo.snirh.apambiente.pt`

### Carris Metropolitana — public transport
- **Base URL:** `https://api.carrismetropolitana.pt`
- **Auth:** None
- **Update frequency:** Real-time for departures, periodic for stop metadata
- **Endpoints used:** `/stops/{id}`, `/stops/{id}/realtime`, `/routes`

### Snapshot / fallback system

Every successful API response is saved to `api_snapshots`. When a live fetch fails (timeout, HTTP error, API down), the most recent snapshot is returned instead. The response includes a `data_source` field (`"live"` or `"snapshot"`) and, when serving a snapshot, a `snapshot_at` timestamp so the client can show a "data from Xh ago" warning.

---

## Key design decisions

**Beaches as the anchor entity.** Beaches are a fixed, curated list (~13). Each row holds the external API identifiers for all four data sources, so a single DB lookup is all that's needed to route any request.

**Presence as a trust signal.** Submitting reports and voting both require a recent heartbeat at the beach (occupancy ping in the last 1–2 hours). This prevents remote manipulation of community data and ties reputation to actual beach visits.

**Recommendation scoring.** `GET /beaches?lat=&lon=` ranks beaches by a composite score: 40% proximity, 30% flag safety, 20% occupancy level, 10% absence of active alerts.

**Activity-aware parameters.** Each beach has an activity level (low / normal / high) derived from the number of active users in the last hour. This level adjusts report TTLs, the number of downvotes required for early expiry, and flag confirmation thresholds (so the system behaves sensibly both in peak summer and off-season).

**Flag as state, not alert.** The beach flag (green / yellow / red / purple) is a persistent state with a decaying confidence score, not a one-shot community report. Confidence decays over time without confirmations and is recalculated every 10 minutes by the scheduler.

**Reputation system.** Users start at 0 and gain/lose points when their contributions are confirmed or contradicted by the community. The minimum threshold to propose a flag change is 5 (low enough for active users to participate quickly, but with real consequences (down to −50 triggers an auto-ban) for bad-faith contributions).

# Arrábida Backend

REST API for the OndaCerta platform. Pulls official data from IPMA, Instituto Hidrográfico, APA InfoÁgua and Carris Metropolitana, and exposes a community layer for real-time beach conditions — reports, flags, occupancy, reputation.

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
| Tide modelling | utide (harmonic analysis) |
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

# 8. (Optional but recommended) Populate historical tide observations
#    Downloads ~500 real observations per station from the IH API,
#    enough to immediately fit the data-driven tide model.
python scripts/populate_tide_observations.py
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

There are three migrations:
- `0001` — core schema (beaches, users, reports, flags, snapshots, etc.)
- `0002` — favourites, push tokens, achievements, notification/privacy settings
- `0003` — tide observations and fitted harmonic model coefficients

### Seed data

The seed script inserts the 13 Arrábida beaches with coordinates, IPMA forecast IDs, APA station IDs, Instituto Hidrográfico station IDs, and Carris Metropolitana stop IDs:

```bash
python scripts/seed_beaches.py
```

> **Note:** APA station IDs are provisional placeholders — verify against the live API before going to production.

### Schema overview

| Table | Purpose |
|---|---|
| `beaches` | Master list of beaches with external API identifiers |
| `users` | Accounts (email/password, Google, anonymous guest) |
| `refresh_tokens` | Server-side refresh token store for revocation |
| `reputation_events` | Immutable audit log of every reputation change |
| `reports` | Community alerts (jellyfish, current, pollution, etc.) |
| `report_votes` | One vote per user per report |
| `beach_status` | Current flag colour + confidence score per beach |
| `flag_proposals` | Proposed flag changes pending community confirmation |
| `flag_confirmations` | yes/no/unsure responses to flag confirmation prompts |
| `occupancy_heartbeats` | Presence pings from the Flutter app (~every 5 min) |
| `api_snapshots` | Cached external API responses used as fallback |
| `user_favourites` | Ordered list of favourite beaches per user |
| `push_tokens` | FCM/APNs device tokens for push notifications |
| `user_achievements` | Unlocked achievements per user |
| `tide_observations` | Real IH tide gauge observations collected hourly |
| `tide_model_coef` | Fitted harmonic model coefficients per station |

---

## Running the server

```bash
source .venv/bin/activate
uvicorn app.main:app --reload
```

Interactive API docs: **http://localhost:8000/docs**

On startup the server launches an APScheduler instance that handles all periodic work — fetching external APIs, collecting tide observations, expiring reports, recalculating flag confidence, and re-fitting the tide model weekly. No separate worker process needed.

---

## Running tests

Tests use a dedicated `arrabida_test` database. Create it once:

```bash
psql -U postgres -c "CREATE DATABASE arrabida_test;"
psql -U postgres -d arrabida_test -c "CREATE EXTENSION IF NOT EXISTS postgis;"
psql -U postgres -d arrabida_test -c "CREATE EXTENSION IF NOT EXISTS pgcrypto;"
```

Then run:

```bash
source .venv/bin/activate
pytest tests/ -q
```

The suite creates and tears down the schema automatically. All external API calls are mocked, so no internet connection is needed.

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
│   ├── main.py                     # FastAPI app, lifespan, router registration
│   ├── api/
│   │   ├── auth.py                 # /auth/* — register, login, Google, refresh, promote
│   │   ├── beaches.py              # GET /beaches, GET /beaches/{slug}
│   │   ├── weather.py              # GET /beaches/{slug}/weather  (IPMA)
│   │   ├── tides.py                # GET /beaches/{slug}/tides    (Instituto Hidrográfico)
│   │   ├── water_quality.py        # GET /beaches/{slug}/water-quality  (APA)
│   │   ├── transport.py            # GET /beaches/{slug}/transport  (Carris)
│   │   ├── reports.py              # Community alerts + voting
│   │   ├── flags.py                # Flag proposals + confirmation
│   │   ├── occupancy.py            # Presence heartbeats
│   │   ├── users.py                # Profile, reputation, achievements
│   │   ├── favourites.py           # /users/me/favourites
│   │   ├── notifications.py        # Notification settings + push token registration
│   │   ├── privacy.py              # Privacy settings, data export, account deletion
│   │   └── map.py                  # GET /map/users — active users for map overlay
│   ├── core/
│   │   ├── config.py               # Settings (pydantic-settings, .env)
│   │   ├── database.py             # Async engine + session factory
│   │   ├── deps.py                 # FastAPI dependencies (auth guards)
│   │   └── security.py             # JWT, bcrypt, Google token verification
│   ├── models/                     # SQLAlchemy ORM models
│   ├── schemas/                    # Pydantic request/response models
│   ├── services/
│   │   ├── ipma.py                 # IPMA weather + sea forecast client
│   │   ├── hidrografico.py         # IH tide observations + harmonic model
│   │   ├── apa.py                  # APA bathing water quality client
│   │   ├── carris.py               # Carris Metropolitana client
│   │   ├── snapshot.py             # fetch_with_fallback — live → cache
│   │   ├── activity.py             # Beach activity level + dynamic parameters
│   │   ├── reputation.py           # Reputation delta processing
│   │   ├── flag_confidence.py      # Flag confidence decay calculation
│   │   ├── achievements.py         # Achievement definitions + unlock logic
│   │   └── push_notifications.py   # Notification targeting + FCM dispatch stub
│   └── scheduler/
│       ├── jobs.py                 # All periodic job functions
│       └── setup.py                # APScheduler configuration
├── alembic/
│   └── versions/
│       ├── 0001_initial_schema.py
│       ├── 0002_favourites_notifications_privacy.py
│       └── 0003_tide_observations.py
├── tests/
│   ├── conftest.py
│   ├── test_auth.py
│   ├── test_beaches.py
│   ├── test_reports.py
│   ├── test_flags.py
│   ├── test_occupancy.py
│   ├── test_users.py
│   ├── test_external_data.py
│   ├── test_favourites.py
│   ├── test_notifications_privacy.py
│   └── test_map.py
├── scripts/
│   ├── seed_beaches.py             # Insert the 13 Arrábida beaches
│   └── populate_tide_observations.py  # Bootstrap IH historical tide data
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
| `POST` | `/auth/guest` | — | Create an anonymous session (device_id based) |
| `POST` | `/auth/register` | — | Register with email + password |
| `POST` | `/auth/login` | — | Login with email + password |
| `POST` | `/auth/google` | — | Login with Google id_token |
| `POST` | `/auth/refresh` | — | Rotate refresh token (old one is immediately revoked) |
| `POST` | `/auth/logout` | Bearer | Revoke refresh token |
| `POST` | `/auth/promote` | Bearer | Upgrade an anonymous account to a full account |

### Beaches

| Method | Path | Auth | Description |
|---|---|---|---|
| `GET` | `/beaches` | Optional | List all beaches. Pass `?lat=&lon=` for proximity-ranked results with scores |
| `GET` | `/beaches/{slug}` | Optional | Full beach detail — conditions, alerts, weather, tides, transport |
| `GET` | `/beaches/{slug}/weather` | — | IPMA 5-day weather forecast |
| `GET` | `/beaches/{slug}/sea` | — | IPMA sea state (wave height, period, sea temperature) |
| `GET` | `/beaches/{slug}/tides` | — | Tide table from the harmonic model (see below) |
| `GET` | `/beaches/{slug}/water-quality` | — | APA bathing water classification |
| `GET` | `/beaches/{slug}/transport` | — | Next Carris bus departures from nearby stops |

### Community layer

| Method | Path | Auth | Description |
|---|---|---|---|
| `GET` | `/beaches/{slug}/reports` | Optional | Active alerts. `?include_expired=true` for history |
| `POST` | `/beaches/{slug}/reports` | Bearer + **presence** | Submit an alert (heartbeat in last hour required) |
| `POST` | `/beaches/{slug}/reports/{id}/vote` | Bearer + **presence** | Vote on a report (presence required for all votes) |
| `DELETE` | `/beaches/{slug}/reports/{id}` | Bearer (owner) | Soft-delete own report |
| `GET` | `/beaches/{slug}/flag` | — | Current flag colour + confidence |
| `POST` | `/beaches/{slug}/flag/propose` | Bearer + **presence** + rep ≥ 5 | Propose a flag colour change |
| `POST` | `/beaches/{slug}/flag/confirm` | Bearer | Confirm or contradict current flag (once per hour per beach) |
| `POST` | `/beaches/{slug}/occupancy/heartbeat` | Bearer | Send presence ping — enables voting, reporting, and occupancy counting |

### Map

| Method | Path | Auth | Description |
|---|---|---|---|
| `GET` | `/map/users` | Optional | Active users grouped by beach. `user_count` includes everyone; `users` array respects privacy settings |

### Users & profile

| Method | Path | Auth | Description |
|---|---|---|---|
| `GET` | `/users/me` | Bearer | Profile, reputation level, streak, achievements, stats |
| `GET` | `/users/me/reputation-history` | Bearer | Paginated log of reputation events |
| `GET` | `/users/me/favourites` | Bearer | Ordered list of favourite beaches |
| `POST` | `/users/me/favourites/{slug}` | Bearer | Add a beach to favourites |
| `DELETE` | `/users/me/favourites/{slug}` | Bearer | Remove a beach from favourites |
| `PATCH` | `/users/me/favourites/order` | Bearer | Reorder favourites |
| `GET` | `/users/me/notification-settings` | Bearer | Current notification preferences |
| `PATCH` | `/users/me/notification-settings` | Bearer | Update notification preferences |
| `GET` | `/users/me/privacy-settings` | Bearer | Current privacy preferences |
| `PATCH` | `/users/me/privacy-settings` | Bearer | Update privacy preferences |
| `GET` | `/users/me/data-export` | Bearer | Full GDPR data export (JSON) |
| `DELETE` | `/users/me/reports` | Bearer | Soft-delete all own reports |
| `DELETE` | `/users/me` | Bearer | Permanently delete account (requires `{"confirmation": "APAGAR"}`) |

### Notifications

| Method | Path | Auth | Description |
|---|---|---|---|
| `POST` | `/notifications/register-token` | Bearer | Register FCM/APNs push token |
| `DELETE` | `/notifications/token/{token}` | Bearer | Remove a push token |

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
- **How it works:** IPMA serves global daily forecast files (not per-location). We fetch each day's file and filter by `globalIdLocal`.
  - `forecast/meteorology/cities/daily/hp-daily-forecast-day{0-4}.json` — 5-day weather
  - `forecast/oceanography/daily/hp-daily-sea-forecast-day{0-3}.json` — sea state
- **IDs for Arrábida:** `1151200` (weather, Setúbal), `1111026` (sea, Arrábida coast)

### Instituto Hidrográfico — tide observations and predictions
- **Base URL:** `https://api-features.hidrografico.pt`
- **Auth:** None
- **What the API actually provides:** Real-time gauge observations only — there is no predictions endpoint. The API follows the OGC API Features standard.
- **How we handle it:** We collect one observation per hour from `tide_obs_stations_nrt` and store it in `tide_observations`. Once 360+ observations are accumulated (~15 days), `utide.solve` fits a 5-constituent harmonic model (M2, S2, N2, K1, O1) directly to the real station data. The fitted model is cached in `tide_model_coef` and re-fitted weekly by the scheduler. Until enough data exists, a bootstrap model with published IH constants is used instead.
- **Result:** Tide predictions that get better over time as more observations accumulate. After ~30 days the accuracy is typically ±10 minutes.
- **Stations used:** `PT_150505_2` (Setúbal-Tróia), `PT_151101_1` (Sesimbra)

### APA InfoÁgua — bathing water quality
- **Base URL:** `https://sniamb.apambiente.pt/api`
- **Auth:** None
- **Update frequency:** Daily (lab analysis results)
- **Fallback:** GeoServer WFS endpoint at `geo.snirh.apambiente.pt` if the REST API is down

### Carris Metropolitana — public transport
- **Base URL:** `https://api.carrismetropolitana.pt`
- **Auth:** None
- **Update frequency:** Real-time for departures
- **Endpoints used:** `/stops/{id}`, `/stops/{id}/realtime`
- **Note:** Some Arrábida beach stops only have service during the bathing season (June–September).

### Snapshot / fallback system

Every successful response from an external API is saved to `api_snapshots`. If a live fetch fails (timeout, HTTP error, API down), the most recent snapshot is served instead. The response includes a `data_source` field (`"live"` or `"snapshot"`) and a `snapshot_at` timestamp so the Flutter client can show a "data from Xh ago" label when needed.

---

## Key design decisions

**Beaches as the anchor entity.** The 13 beaches are a fixed, curated list. Each row stores the identifiers for all four external data sources, so the API always knows exactly which IPMA ID, IH station, APA station, and Carris stops to use for a given beach — no geocoding or discovery at request time.

**Presence as a trust signal.** Submitting reports and voting both require a recent heartbeat at the beach (occupancy ping within the last 1–2 hours). This ties reputation to actual physical presence and makes remote manipulation of community data much harder.

**Recommendation scoring.** `GET /beaches?lat=&lon=` ranks beaches using a composite score: 40% proximity, 30% flag safety, 20% occupancy level, 10% absence of active alerts. Falls back to alphabetical when no coordinates are provided.

**Activity-aware parameters.** Each beach has an activity level (low / normal / high) based on how many users have sent heartbeats in the last hour. This controls report TTLs, contradiction thresholds, and flag confirmation minimums — so the system doesn't expire alerts too aggressively on a quiet Tuesday in February.

**Flag as state, not alert.** The beach flag (green / yellow / red / purple) is a persistent state with a decaying confidence score. Confidence drops over time without confirmations and is recalculated every 10 minutes. This is different from community reports, which are ephemeral events.

**Self-improving tide model.** The IH API only provides real-time observations — there's no predictions endpoint. We solve this by accumulating observations hourly and fitting a harmonic model with `utide` once enough data exists. The model improves as more data is collected and is re-fitted weekly. New installs can bootstrap quickly using `scripts/populate_tide_observations.py`, which downloads ~8 days of historical observations in about 13 minutes.

**Reputation system.** Users start at 0 and earn or lose points when the community confirms or contradicts their contributions. The threshold to propose a flag change is deliberately low (rep ≥ 5) so active users can participate quickly, but dropping below −50 triggers an automatic ban. All reputation changes are logged immutably in `reputation_events` for auditability.

**Push notifications (infrastructure ready).** Token registration and notification settings (per-context targeting, alert type filters, quiet hours) are fully implemented. The actual FCM/APNs dispatch is stubbed in `push_notifications.py` and ready to be wired up once Firebase credentials are configured.

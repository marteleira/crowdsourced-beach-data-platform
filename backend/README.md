# Backend

REST API for the OndaCerta platform. Pulls official data from IPMA, Open-Meteo, Instituto Hidrográfico, EEA DiscoData and Carris Metropolitana, and exposes a community layer for real-time beach conditions: reports, flags, occupancy, reputation. It also serves the public marketing site and the account/email side of things (verification, password reset, deletion).

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
- [Public website](#public-website)
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
| Push notifications | Firebase Admin SDK, falls back to stub logging if no credentials are configured |
| Email | aiosmtplib, falls back to logging the code instead of sending if SMTP isn't configured |
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
# Edit .env, at minimum set JWT_SECRET and GOOGLE_CLIENT_ID

# 6. Run migrations
alembic upgrade head

# 7. Seed beaches
python scripts/seed_beaches.py

# 8. (Optional but recommended) Populate historical tide observations
#    Downloads ~500 real observations per station from the IH API,
#    enough to immediately fit the data-driven tide model.
python scripts/populate_tide_observations.py
```

Email and push notifications work without any extra setup too. If `SMTP_HOST` is left empty the server just logs the verification/reset code instead of emailing it, and if `FIREBASE_CREDENTIALS_PATH` is left empty push notifications are stubbed out. Neither is required to run the app locally.

---

## Environment variables

| Variable | Description | Default |
|---|---|---|
| `DATABASE_URL` | Async PostgreSQL connection string | `postgresql+asyncpg://postgres@localhost:5432/arrabida` |
| `JWT_SECRET` | Secret used to sign access tokens, **change in production** | `dev-secret-change-in-production` |
| `JWT_ACCESS_EXPIRE_MINUTES` | Access token lifetime in minutes | `15` |
| `JWT_REFRESH_EXPIRE_DAYS` | Refresh token lifetime in days | `30` |
| `GOOGLE_CLIENT_ID` | OAuth client ID from Google Cloud Console, required for Google login | *(empty)* |
| `CORS_ORIGINS` | JSON array of allowed origins | `["http://localhost:3000"]` |
| `ENVIRONMENT` | `development` or `production` | `development` |
| `FIREBASE_CREDENTIALS_PATH` | Path to the Firebase service account JSON, needed for real push delivery | *(empty, stubbed)* |
| `SMTP_HOST` | SMTP server for verification/reset emails, leave empty to just log the code | *(empty, logs instead)* |
| `SMTP_PORT` | SMTP port | `587` |
| `SMTP_USER` / `SMTP_PASSWORD` | SMTP credentials | *(empty)* |
| `SMTP_TLS` | Whether to use STARTTLS | `true` |
| `EMAIL_FROM` | From address on outgoing emails | `noreply@ondacerta.app` |
| `EMAIL_VERIFICATION_EXPIRE_MINUTES` | How long a verification/reset code stays valid | `15` |

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

There are 14 migrations, applied in this order:
- `0001`: core schema (beaches, users, reports, flags, snapshots, etc.)
- `0002`: favourites, push tokens, achievements, notification/privacy settings
- `0003`: tide observations and fitted harmonic model coefficients
- `0004`: rename `apa_station_id` → `eea_station_id`
- `0005`: `scheduled_deletion_at` on users, for the account deletion grace period
- `0006`: email verification fields on users
- `0007`: `suspended_until` on users
- `0008`: password reset fields on users
- `0009`: `avatar_id` on users
- `0010`: `cover_photo_url` on beaches
- `c09bd4e870f6`: `municipality` on beaches
- `0011`: `params` JSONB column on reputation_events, drops the old `reason` column
- `0012`: `occupancy_reports` table, for the crowdsourced busyness rating
- `0013`: adds `ON DELETE` behaviour to the foreign keys that reference `users.id`

### Seed data

The seed script inserts the 21 Arrábida, Sesimbra and Tróia beaches with coordinates, IPMA forecast IDs, EEA bathing water identifiers, Instituto Hidrográfico station IDs and Carris Metropolitana stop IDs:

```bash
python scripts/seed_beaches.py
```

The script is idempotent, re-running it updates existing records instead of duplicating them.

If you need to update just the EEA identifiers for a set of beaches there's a ready-made SQL script for that:
```bash
psql -U postgres -d arrabida -f scripts/update_eea_station_ids.sql
```

Beach cover photos live as static files in `static/beaches/`. There's a small script to shrink and re-encode them if you add new ones:
```bash
python scripts/optimize_beach_images.py
```

### Schema overview

| Table | Purpose |
|---|---|
| `beaches` | Curated list of beaches with external API identifiers, municipality and cover photo |
| `users` | Accounts (email/password, Google, anonymous guest), including ban/suspension, avatar, email verification and password reset state |
| `refresh_tokens` | Server-side refresh token store for revocation |
| `reputation_events` | Immutable audit log of every reputation change |
| `reports` | Community alerts (jellyfish, strong current, pollution, etc.) |
| `report_votes` | One vote per user per report |
| `beach_status` | Current flag colour + confidence score per beach |
| `flag_proposals` | Proposed flag changes pending community confirmation |
| `flag_confirmations` | yes/no/unsure responses to flag confirmation prompts |
| `occupancy_heartbeats` | Presence pings from the Flutter app (~every 19 min) |
| `occupancy_reports` | Crowdsourced busyness rating (1 to 5), presence gated and rate limited |
| `api_snapshots` | Cached external API responses used as fallback |
| `user_favourites` | Ordered list of favourite beaches per user |
| `push_tokens` | FCM device tokens for push notifications |
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

On startup the server initializes Firebase (if configured) and launches an APScheduler instance that handles all periodic work. Fetching external APIs, collecting tide observations, expiring reports, recalculating flag confidence, and re-fitting the tide model weekly all happen there, so no separate worker process is needed.

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

The suite creates and tears down the schema automatically. All external API calls are mocked, so no internet connection is needed. It currently covers auth, beaches, external data, favourites, flags, map, notifications/privacy, occupancy (both heartbeats and the crowdsourced reports), reports, reputation, push dispatch and users, around 270 test cases across 15 files.

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
│   ├── main.py                     # FastAPI app, lifespan (Firebase init + scheduler), router registration
│   ├── api/
│   │   ├── auth.py                 # /auth/*: register, login, Google, guest, promote, verify/reset email flows
│   │   ├── beaches.py              # GET /beaches, GET /beaches/{slug}
│   │   ├── weather.py              # GET /beaches/{slug}/weather, /sea  (IPMA + Open-Meteo)
│   │   ├── tides.py                # GET /beaches/{slug}/tides    (Instituto Hidrográfico)
│   │   ├── water_quality.py        # GET /beaches/{slug}/water-quality  (EEA)
│   │   ├── transport.py            # GET /beaches/{slug}/transport  (Carris)
│   │   ├── reports.py              # Community alerts + voting
│   │   ├── flags.py                # Flag proposals + confirmation
│   │   ├── occupancy.py            # Presence heartbeats + crowdsourced busyness reports
│   │   ├── users.py                # Profile, reputation, account edits (username/email/password/avatar)
│   │   ├── favourites.py           # /users/me/favourites
│   │   ├── notifications.py        # Notification settings + push token registration
│   │   ├── privacy.py              # Privacy settings, data export, account deletion (scheduled + cancel)
│   │   └── map.py                  # GET /map/users: active users for map overlay
│   ├── core/
│   │   ├── config.py               # Settings (pydantic-settings, .env)
│   │   ├── constants.py            # Recommendation weights, thresholds, misc tuning constants
│   │   ├── database.py             # Async engine + session factory
│   │   ├── db_helpers.py           # Small shared query helpers
│   │   ├── deps.py                 # Auth guards, ban/suspension checks, get_beach_or_404, was_recently_present
│   │   ├── firebase.py             # Firebase Admin SDK init, falls back to a warning log if not configured
│   │   ├── messages.py             # Centralised error/message strings (Msg.*)
│   │   ├── security.py             # JWT, bcrypt, Google token verification
│   │   └── utils.py                # now_utc() and other small helpers
│   ├── models/                     # SQLAlchemy ORM models
│   ├── schemas/                    # Pydantic request/response models
│   ├── services/
│   │   ├── ipma.py                 # IPMA weather + sea forecast client
│   │   ├── open_meteo.py           # Open-Meteo client, real-time current conditions
│   │   ├── hidrografico.py         # IH tide observations + harmonic model
│   │   ├── eea.py                  # EEA DiscoData client, bathing water quality
│   │   ├── carris.py               # Carris Metropolitana client
│   │   ├── email.py                # Verification/reset emails via aiosmtplib
│   │   ├── snapshot.py             # fetch_with_fallback, live then cache
│   │   ├── activity.py             # Beach activity level + dynamic parameters
│   │   ├── reputation.py           # Reputation delta processing, auto-ban
│   │   ├── flag_confidence.py      # Flag confidence decay calculation
│   │   ├── achievements.py         # Achievement definitions + unlock logic
│   │   └── push_notifications.py   # Notification targeting + FCM dispatch
│   └── scheduler/
│       ├── jobs.py                 # All periodic job functions
│       └── setup.py                # APScheduler configuration
├── alembic/
│   └── versions/                   # 14 migrations, see Database section above
├── tests/
│   ├── conftest.py
│   ├── test_auth.py
│   ├── test_beaches.py
│   ├── test_reports.py
│   ├── test_flags.py
│   ├── test_occupancy.py
│   ├── test_occupancy_reports.py
│   ├── test_users.py
│   ├── test_external_data.py
│   ├── test_favourites.py
│   ├── test_notifications_privacy.py
│   ├── test_map.py
│   ├── test_reputation.py
│   └── test_push_dispatch.py
├── scripts/
│   ├── seed_beaches.py                # Insert the 21 beaches
│   ├── populate_tide_observations.py  # Bootstrap IH historical tide data
│   ├── update_eea_station_ids.sql     # Update EEA identifiers for existing beaches
│   ├── optimize_beach_images.py       # Resize/re-encode static/beaches/ cover photos
│   └── generate_er_diagram.py         # Generate ER diagram from the live schema
├── static/
│   ├── site/                       # Public landing page + terms.html + privacy.html
│   ├── beaches/                    # Beach cover photos, served as static files
│   └── downloads/                  # onda-certa.apk, direct download for now
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
| `POST` | `/auth/guest` | none | Create an anonymous session (device_id based) |
| `POST` | `/auth/register` | none | Register with email + password, sends a verification code |
| `POST` | `/auth/login` | none | Login with email + password |
| `POST` | `/auth/google` | none | Login with Google id_token |
| `POST` | `/auth/refresh` | none | Rotate refresh token (old one is immediately revoked) |
| `POST` | `/auth/logout` | Bearer | Revoke refresh token |
| `POST` | `/auth/promote` | Bearer | Upgrade an anonymous account to a full account |
| `POST` | `/auth/verify-email` | none | Confirm the code sent on registration |
| `POST` | `/auth/resend-verification` | none | Resend the verification code |
| `POST` | `/auth/forgot-password` | none | Send a password reset code |
| `POST` | `/auth/reset-password` | none | Reset password using the code |

### Beaches

| Method | Path | Auth | Description |
|---|---|---|---|
| `GET` | `/beaches` | Optional | List all beaches. Pass `?lat=&lon=` for proximity-ranked results with recommendation scores |
| `GET` | `/beaches/{slug}` | Optional | Full beach detail, conditions, alerts, weather, tides, transport |
| `GET` | `/beaches/{slug}/weather` | none | IPMA 5-day weather forecast, blended with Open-Meteo current conditions for today |
| `GET` | `/beaches/{slug}/sea` | none | IPMA sea state (wave height, period, sea temperature) |
| `GET` | `/beaches/{slug}/tides` | none | Tide table from the harmonic model (see below) |
| `GET` | `/beaches/{slug}/water-quality` | none | EEA bathing water classification |
| `GET` | `/beaches/{slug}/transport` | none | Next Carris bus departures from nearby stops |

### Community layer

| Method | Path | Auth | Description |
|---|---|---|---|
| `GET` | `/beaches/{slug}/reports` | Optional | Active alerts. `?include_expired=true` for history |
| `POST` | `/beaches/{slug}/reports` | Bearer + **presence** | Submit an alert (heartbeat in last hour required) |
| `POST` | `/beaches/{slug}/reports/{id}/vote` | Bearer + **presence** | Vote on a report (presence required for all votes) |
| `DELETE` | `/beaches/{slug}/reports/{id}` | Bearer (owner) | Soft-delete own report |
| `GET` | `/beaches/{slug}/flag` | none | Current flag colour + confidence |
| `POST` | `/beaches/{slug}/flag/propose` | Bearer + **presence** + rep ≥ 5 | Propose a flag colour change |
| `POST` | `/beaches/{slug}/flag/confirm` | Bearer | Confirm or contradict current flag (once per hour per beach) |
| `POST` | `/beaches/{slug}/occupancy/heartbeat` | Bearer | Send presence ping, enables voting, reporting and occupancy counting |
| `POST` | `/beaches/{slug}/occupancy/report` | Bearer + **presence** | Rate how busy the beach feels (1 to 5), rate limited per user per beach |

### Map

| Method | Path | Auth | Description |
|---|---|---|---|
| `GET` | `/map/users` | Optional | Active users grouped by beach. `user_count` includes everyone, the `users` array respects individual privacy settings |

### Users & profile

| Method | Path | Auth | Description |
|---|---|---|---|
| `GET` | `/users/me` | Bearer | Profile, reputation level, streak, achievements, stats |
| `PATCH` | `/users/me` | Bearer | Change display name, email or avatar (changing email re-triggers verification) |
| `POST` | `/users/me/change-password` | Bearer | Change password, revokes every other active session |
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
| `DELETE` | `/users/me` | Bearer | Schedule account deletion (requires `{"confirmation": "APAGAR"}`), 30-day grace period before it's final |
| `POST` | `/users/me/cancel-deletion` | Bearer | Cancel a pending scheduled deletion |

### Notifications

| Method | Path | Auth | Description |
|---|---|---|---|
| `POST` | `/notifications/register-token` | Bearer | Register FCM push token |
| `DELETE` | `/notifications/token/{token}` | Bearer | Remove a push token |

### Health

| Method | Path | Description |
|---|---|---|
| `GET` | `/health` | Returns `{"status": "ok"}` |

---

## External APIs

### IPMA: weather and sea forecasts
- **Base URL:** `https://api.ipma.pt/open-data`
- **Auth:** None
- **Update frequency:** ~2× per day
- **How it works:** IPMA serves global daily forecast files, not per-location. We fetch each day's file and filter by `globalIdLocal`.
  - `forecast/meteorology/cities/daily/hp-daily-forecast-day{0-4}.json`: 5-day weather
  - `forecast/oceanography/daily/hp-daily-sea-forecast-day{0-3}.json`: sea state
- **IDs for Arrábida:** `1151200` (weather, Setúbal), `1111026` (sea, Arrábida coast)

### Open-Meteo: real-time current weather
- **Base URL:** `https://api.open-meteo.com/v1/forecast`
- **Auth:** None
- **Update frequency:** current conditions every 15 min, hourly forecast
- **Why we added it:** IPMA's forecast only refreshes twice a day and doesn't carry an actual "right now" reading. Open-Meteo fills that gap with live temperature, wind, humidity, gusts, UV index and today's precipitation chance by lat/lon, no station lookup needed. Its values override IPMA's "today" entry in the weather response, IPMA still drives the rest of the 5-day forecast.

### Instituto Hidrográfico: tide observations and predictions
- **Base URL:** `https://api-features.hidrografico.pt`
- **Auth:** None
- **What the API actually provides:** Real-time gauge observations only, there is no predictions endpoint. The API follows the OGC API Features standard.
- **How we handle it:** We collect one observation per hour from `tide_obs_stations_nrt` and store it in `tide_observations`. Once 360+ observations are accumulated (~15 days), `utide.solve` fits a 5-constituent harmonic model (M2, S2, N2, K1, O1) directly to the real station data. The fitted model is cached in `tide_model_coef` and re-fitted weekly by the scheduler. Until enough data exists, a bootstrap model with published IH constants is used instead.
- **Result:** Tide predictions that get better over time as more observations accumulate. After ~30 days the accuracy is typically ±10 minutes.
- **Stations used:** `PT_150505_2` (Setúbal-Tróia), `PT_151101_1` (Sesimbra)

### EEA DiscoData: bathing water quality
- **Base URL:** `https://discodata.eea.europa.eu/sql`
- **Auth:** None
- **Data source:** European Environment Agency WISE Bathing Water Directive (WISE_BWD database)
- **Update frequency:** Once per year, at the end of each bathing season
- **How it works:** Parameterised SQL query against the `WISE_BWD` database for the most recent annual classification of a specific bathing site. Each beach stores an `eea_station_id`, the EEA `bathingWaterIdentifier` (e.g. `"PTCW2P"`).
- **Classifications:** Excellent / Good / Sufficient / Poor

### Carris Metropolitana: public transport
- **Base URL:** `https://api.carrismetropolitana.pt`
- **Auth:** None
- **Update frequency:** Real-time for departures
- **Endpoints used:** `/stops/{id}`, `/stops/{id}/realtime`
- **Note:** Some Arrábida beach stops only have service during the bathing season (June to September).

### Snapshot / fallback system

Every successful response from an external API is saved to `api_snapshots`. If a live fetch fails (timeout, HTTP error, API down), the most recent snapshot is served instead. The response includes a `data_source` field (`"live"` or `"snapshot"`) and a `snapshot_at` timestamp so the Flutter client can show a "data from Xh ago" label when needed.

Note that this section only covers what the backend itself calls out to. The Flutter client also talks directly to OpenStreetMap for map tiles and to the MyMemory Translation API to translate community report notes on demand. Both of those bypass the backend entirely and are documented in the Flutter app's own README.

---

## Public website

`static/site/` holds a small marketing landing page plus the Terms of Service and Privacy Policy, all served directly by FastAPI at `/`, `/terms` and `/privacy`. There's also a direct APK download at `/static/downloads/onda-certa.apk`, which is the current distribution channel while app store submission is still pending. The site content is in Portuguese since that's the target audience, unlike this README.

---

## Key design decisions

**Beaches as the anchor entity.** The 21 beaches are a fixed, curated list. Each row stores the identifiers for all the external data sources, so the API always knows exactly which IPMA ID, IH station, EEA identifier and Carris stops to use for a given beach, no geocoding or discovery at request time.

**Presence as a trust signal.** Submitting reports, voting and rating busyness all require a recent heartbeat at the beach (occupancy ping within the last hour or two). This ties reputation to actual physical presence and makes remote manipulation of community data much harder.

**Recommendation scoring.** `GET /beaches?lat=&lon=` ranks beaches using a composite score, 40% proximity, 30% flag safety, 20% occupancy level, 10% absence of active alerts. Falls back to alphabetical when no coordinates are provided.

**Activity-aware parameters.** Each beach has an activity level (low / normal / high) based on how many users have sent heartbeats in the last hour. This controls report TTLs, contradiction thresholds and flag confirmation minimums, so the system doesn't expire alerts too aggressively on a quiet Tuesday in February.

**Flag as state, not alert.** The beach flag (green / yellow / red / purple) is a persistent state with a decaying confidence score. Confidence drops over time without confirmations and is recalculated every 10 minutes. This is different from community reports, which are ephemeral events.

**Two ways to measure occupancy.** The objective headcount comes from heartbeats in the last 20 minutes. Alongside that, users can rate how busy a beach feels on a 1 to 5 scale, gated by presence and rate limited to one rating per user per beach per window. The two signals are shown together rather than merged, since "how many people" and "how busy it feels" aren't quite the same thing.

**Self-improving tide model.** The IH API only provides real-time observations, there's no predictions endpoint. We solve this by accumulating observations hourly and fitting a harmonic model with `utide` once enough data exists. The model improves as more data is collected and is re-fitted weekly. New installs can bootstrap quickly using `scripts/populate_tide_observations.py`, which downloads ~8 days of historical observations in about 13 minutes.

**Reputation system.** Users start at 0 and earn or lose points when the community confirms or contradicts their contributions. The threshold to propose a flag change is deliberately low (rep ≥ 5) so active users can participate quickly, but dropping below −50 triggers an automatic ban. All reputation changes are logged immutably in `reputation_events` for auditability.

**Account deletion is a grace period, not a switch.** `DELETE /users/me` doesn't wipe the account there and then. It schedules deletion 30 days out, revokes every active session, and can be cancelled any time before that date through `/users/me/cancel-deletion`. This gives people a way back if they change their mind, and gives support a window to catch mistakes.

**Push notifications.** Token registration, per-context targeting and notification settings (alert type filters, radius, minimum severity, quiet hours) are all implemented against a real Firebase project. If `FIREBASE_CREDENTIALS_PATH` isn't set, dispatch just logs what it would have sent instead of failing, which keeps local development working without needing real credentials.

<div align="center">

![OndaCerta](docs/assets/banner.png)

# OndaCerta

**Collaborative platform and real-time bathing data aggregator**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)](https://dart.dev)
[![FastAPI](https://img.shields.io/badge/Backend-FastAPI-009688?logo=fastapi)](https://fastapi.tiangolo.com)
[![PostgreSQL](https://img.shields.io/badge/DB-PostgreSQL-4169E1?logo=postgresql)](https://postgresql.org)
[![Tests](https://img.shields.io/badge/Tests-292%20passing-brightgreen)](#technical-documentation)
[![License](https://img.shields.io/badge/License-MIT-lightgrey)](#terms-of-use)

</div>

---

## Table of Contents

- [About the project](#about-the-project)
- [Features](#features)
- [Main screens](#main-screens)
- [Architecture](#architecture)
- [Technical documentation](#technical-documentation)
- [Roadmap](#roadmap)
- [Terms of use](#terms-of-use)

---

## About the project

Planning a beach day at Arrábida usually means having at least 3 or 4 tabs open at the same time, one for the weather, another for tides, a third for water quality, and then separately having to figure out the buses, since none of those sources were built to work together or with the average beachgoer in mind.

OndaCerta was built to address that. It aggregates all those data sources into a single app and on top of that adds a community layer, similar in concept to what Waze does for traffic. People physically present at the beach can report conditions, confirm what flag is currently flying and vote on other users' reports. Any write action requires physical presence, verified via GPS heartbeat, so the data stays reasonably accurate.

The platform has been running in production since July 2026, publicly reachable at [ondacerta.bitaxiom.net](https://ondacerta.bitaxiom.net). It currently covers 24 beaches across Arrábida Natural Park, Sesimbra and Tróia. The architecture was designed from the start to scale to other Portuguese beaches later on, which is part of why some parts of it ended up more complex than strictly necessary for a single region.

---

## Features

### Real-time data
- weather: IPMA 5-day forecast blended with Open-Meteo real-time current conditions (temperature, wind, humidity, precipitation)
- sea conditions (wave height, period, direction, sea temperature)
- tide chart with cosine interpolation, window always centred on the current time, driven by a self-improving harmonic model fitted to real tide-gauge data
- water quality from the EEA bathing water directive (Excellent / Good / Sufficient / Poor)
- next public transport departures grouped by destination, times updated via GPS
- occupancy: live headcount from GPS heartbeats plus a crowdsourced busyness rating (1 to 5)
- graceful degradation: when an external source is down, the last cached snapshot is served with a `data_source` / `snapshot_at` label instead of failing

### Community layer
- submit alerts with type, severity and a short description
- vote on other user reports (up/down, toggleable)
- confirm or contest the current flag colour (green, yellow, red, purple)
- propose a new flag while the state is unknown — proposals from several users aggregate their reputation-based weights within a 60-minute window until the beach's activity-based quorum is met, so no single low-reputation account can set a flag on a busy beach
- flag confidence decays over time (faster for green, slower for red/purple) and is rebuilt by community confirmations; below a minimum threshold the flag resets to unknown
- rate how busy a beach feels, rate-limited to one report per user per beach per window
- translate another user's report note into your language on demand (MyMemory API)
- any write action requires physical presence, verified via GPS heartbeat
- alerts expire automatically once they accumulate enough downvotes

### Profile and gamification
- reputation level and score built from contributions
- beach day streak tracked through the heartbeat, counts once per day
- achievements evaluated in real time
- activity log

### Personal settings
- favourite beaches synced across devices, with a quick-access carousel on the dashboard
- push notifications delivered via Firebase Cloud Messaging, plus an in-app notification centre with read/unread state
- notification preferences: alert types, radius, minimum severity and quiet hours
- privacy controls: location accuracy, profile visibility, anonymous sharing, full data export
- account deletion, confirmation required, cancellable during a 30-day retention window

### Onboarding and account
- guided first-run tour before login
- email/password, Google or guest sign-in, with email verification and a forgot-password flow (code-based)
- change username, email, password and pick a predefined avatar from the profile
- handles banned/suspended account states with a dedicated screen
- Terms of Service and Privacy Policy rendered natively in-app, reachable without logging in

---

## Main screens

### Authentication

<table><tr>

<td align="center" valign="top" width="33%">

<img src="docs/assets/screens/splash.png" width="220" alt="Splash">

**Splash**
wave animation while the session loads in the background.
</td>

<td align="center" valign="top" width="33%">

<img src="docs/assets/screens/login.png" width="220" alt="Login">

**Login**
google or email/password sign-in, guest access available without registration
</td>

<td align="center" valign="top" width="33%">

<img src="docs/assets/screens/email_login.png" width="220" alt="Email Login">

**Email Login**
email and password registration and login
</td>

</tr></table>

---

### Dashboard and Beaches

<table><tr>

<td align="center" valign="top" width="33%">

<img src="docs/assets/screens/home.png" width="220" alt="Dashboard">

**Dashboard**
closest beach at the top, flag, current conditions, tide chart and active alerts
</td>

<td align="center" valign="top" width="33%">

<img src="docs/assets/screens/beach_list.png" width="220" alt="Beach List">

**Beaches**
OpenStreetMap with a sliding panel, search and filter by flag colour
</td>

<td align="center" valign="top" width="33%">

<img src="docs/assets/screens/beach_detail.png" width="220" alt="Beach Detail">

**Beach Detail**
everything for one beach: weather, sea, tides, water quality and also transport and alerts.
</td>

</tr></table>

---

### Community and Flags

<table><tr>

<td align="center" valign="top" width="33%">

<img src="docs/assets/screens/community_alerts.png" width="220" alt="Community Alerts">

**Alerts**
alert feed with severity, voting and a button to report something new
</td>

<td align="center" valign="top" width="33%">

<img src="docs/assets/screens/flag_confirm.png" width="220" alt="Flag Confirm">

**Confirm Flag**
sheet with sonar animation, confidence score, confirm or contest
</td>

<td align="center" valign="top" width="33%">

<img src="docs/assets/screens/flag_proposal.png" width="220" alt="Flag Proposal">

**Propose Flag**
2x2 grid to pick a colour, shown while the flag state is unknown
</td>

</tr></table>

---

### Tides, Profile and Favourites

<table><tr>

<td align="center" valign="top" width="33%">

<img src="docs/assets/screens/tides.png" width="220" alt="Tides">

**Tides**
fullscreen tide view with an animated ocean background that changes with the time and weather
</td>

<td align="center" valign="top" width="33%">

<img src="docs/assets/screens/profile.png" width="220" alt="Profile">

**Profile**
reputation, streak, achievements, contribution stats and recent activity
</td>

<td align="center" valign="top" width="33%">

<img src="docs/assets/screens/favorites.png" width="220" alt="Favourites">

**Favourites**
saved beaches with pull-to-refresh, synced across devices
</td>

</tr></table>

---

### Settings

<table><tr>

<td align="center" valign="top" width="50%">

<img src="docs/assets/screens/privacy_settings.png" width="300" alt="Privacy Settings">

**Privacy**
location accuracy, visibility and data sharing settings and account deletion is down here too
</td>

<td align="center" valign="top" width="50%">

<img src="docs/assets/screens/notification_settings.png" width="300" alt="Notification Settings">

**Notifications**
configure which alerts to receive, proximity radius, minimum severity and quiet hours
</td>

</tr></table>

---

## Architecture

![Diagram](docs/assets/architecture.svg)

| Layer | Technology | Notes |
|---|---|---|
| Mobile app | Flutter 3.x / Dart 3 | iOS 16+ and Android 10 (API 29+) |
| State management | Riverpod 3.x | AsyncNotifier, optimistic updates |
| Navigation | GoRouter 17.x | Declarative routes, deep linking |
| HTTP | Dio + AuthInterceptor | Silent token renewal |
| Maps | flutter_map + OpenStreetMap tiles | No paid dependencies, no API key |
| Push notifications | Firebase Cloud Messaging | Delivery to device, in-app notification centre |
| Backend | FastAPI (Python) | REST API, background jobs via APScheduler, PostGIS |
| Database | PostgreSQL + PostGIS | Geospatial presence, favourites, achievements |
| Deployment | Self-hosted · Cloudflare Tunnel · systemd | No exposed ports, automatic HTTPS, works behind CGNAT |
| External data (backend) | IPMA, Open-Meteo, Instituto Hidrográfico, EEA, Carris Metropolitana | Weather, sea state, tides, water quality, transport |
| External data (client) | OpenStreetMap, MyMemory Translation API | Map tiles, on-demand translation of report notes |

---

## Technical documentation

Detailed docs for each part live in their respective directories:

| Component | README | Contents |
|---|---|---|
| 📱 **Flutter App** | [`onda_certa_app/README.md`](onda_certa_app/README.md) | Folder structure, dependencies, environment variables, how to run locally |
| ⚙️ **Backend API** | [`backend/README.md`](backend/README.md) | Setup, endpoints, authentication, background jobs, deployment |

---

## Roadmap

### ✅ Completed

**Infrastructure and authentication**
- [x] Feature-first architecture with Riverpod 3.x, no code generation
- [x] Google, email/password and guest sign-in, guest accounts can be promoted to full accounts later
- [x] Email verification and a code-based forgot-password flow, plus a live password-strength indicator on registration (length, case, digit/special)
- [x] Clear feedback for duplicate accounts (409 Conflict) and wrong credentials
- [x] Secure token storage (Keychain / Keystore) with silent refresh via a Dio interceptor
- [x] Native splash screen with wave animation, guided first-run onboarding tour
- [x] Transactional email delivery (SMTP) for verification and password reset
- [x] Automated backend test suite (292 pytest cases)
- [x] Production deployment: self-hosted behind CGNAT via Cloudflare Tunnel, two systemd units (API + tunnel), no ports exposed to the internet

**Screens**
- [x] HomeScreen -> dashboard with nearest beach, conditions, tides, alerts and a favourites carousel
- [x] BeachListScreen -> list + interactive OpenStreetMap with sliding panel, live user count per beach
- [x] BeachDetailScreen -> full detail, pull-to-refresh and auto-refresh on return (RouteAware)
- [x] TideScreen -> immersive full-screen view with adaptive oceanic animation
- [x] CommunityAlertsScreen -> alerts with optimistic voting and report submission
- [x] TransportScreen -> nearby stops and next departures
- [x] ProfileScreen -> reputation, streak, achievements and history
- [x] FavouritesScreen -> saved beaches with multi-device sync
- [x] NotificationsScreen -> in-app notification centre
- [x] NotificationSettingsScreen, PrivacySettingsScreen, AccountSettingsScreen
- [x] TermsScreen / PrivacyScreen -> legal content rendered natively, reachable without logging in
- [x] Full auth flow: Login, EmailLogin, EmailVerification, ForgotPassword, ResetPassword, AccountStatus (banned/suspended), PendingDeletion

**Community layer**
- [x] Alert submission and voting, both gated by a recent presence heartbeat
- [x] Optimistic updates with rollback on server error
- [x] Flag confirmation with sonar animation and animated confidence bar
- [x] Flag proposal with multi-user quorum: pending proposals for the same colour aggregate their weights within a 60-minute window; quorum scales with beach activity (1 / 3 / 5). Reputation threshold is configurable (currently 0 for launch)
- [x] Flag lifecycle hardening: proposing over an already-set flag returns 409, confidence votes are scoped to the current flag instance, concurrent proposals are serialised with a row lock, and stale pending proposals expire automatically
- [x] Per-colour confidence decay (green 30 min · yellow 60 · red/purple 120 without votes; capped age penalty once the community has voted)
- [x] Alerts expire automatically once they accumulate enough downvotes
- [x] Crowdsourced busyness reports (1 to 5), rate-limited per user per beach
- [x] A user can only have an active heartbeat at one beach at a time
- [x] Community write actions disabled for guest accounts
- [x] Opt-in list of other users currently at the beach, respecting each user's privacy settings

**Gamification and reputation**
- [x] Achievement system evaluated in real time
- [x] Presence streak via heartbeat, idempotent per day
- [x] Confirmation rate-limiting: 1 per hour per beach, enforced server-side
- [x] Reputation history log, automatic suspension and ban thresholds, all deltas recorded in an immutable event log

**Account and privacy**
- [x] Change password, email and username, plus a predefined avatar picker
- [x] Full personal data export (GDPR-style JSON via `/users/me/data-export`)
- [x] Account deletion: confirmation required, deletion date shown on next login, cancellable during the 30-day retention window

**Push notifications**
- [x] Backend: FCM dispatch targeted by alert type, radius, severity and quiet hours, plus red-flag alerts for favourite beaches
- [x] Client: token registration, delivery via Firebase Cloud Messaging, in-app notification history

**Design system**
- [x] Centralised AppColors, AppSpacing, AppTextStyles
- [x] Flag gradients and colour mappings all in AppColors
- [x] Shared widgets: AlertItem, TideChartPainter, MetricCell, EmptyState

**Localisation**
- [x] Full Portuguese and English translations via Flutter `gen-l10n`

**Public website and distribution**
- [x] Landing page, Terms of Service and Privacy Policy served directly by the backend, with a direct APK download link
- [x] Usability evaluation with real users: System Usability Scale score of 90.4 (n = 12), "Excellent" band

---

### 🔜 Future work
- [ ] Submit to app stores (direct APK download is already live on the website)
- [ ] Mock-location detection and device integrity checks (Play Integrity) to further harden presence verification
- [ ] Wire the guest-account promotion flow into the client (the `/auth/promote` endpoint is already live)
- [ ] Activate capacity-based occupancy normalisation (fields already in the schema)

### After that
- [ ] Expand to other Portuguese beaches
- [ ] iOS build and App Store submission

---

## Terms of use

This project is licensed under the [MIT License](LICENSE). The external data it aggregates or calls out to IPMA, Open-Meteo, Instituto Hidrográfico, EEA, Carris Metropolitana, OpenStreetMap and the MyMemory Translation API, remains subject to each provider's own terms.

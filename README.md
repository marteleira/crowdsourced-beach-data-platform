<div align="center">

![OndaCerta](docs/assets/banner.png)


# OndaCerta

**Collaborative platform and real-time bathing data aggregator**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)](https://dart.dev)
[![FastAPI](https://img.shields.io/badge/Backend-FastAPI-009688?logo=fastapi)](https://fastapi.tiangolo.com)
[![PostgreSQL](https://img.shields.io/badge/DB-PostgreSQL-4169E1?logo=postgresql)](https://postgresql.org)
[![License](https://img.shields.io/badge/License-MIT-lightgrey)](#terms-of-use)

*Final Year Project · Bachelor's Degree in Computer Engineering*
*Escola Superior de Tecnologia de Setúbal, IPS · 2026*

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

Planning a visit to a beach in Arrábida currently involves consulting at least four separate portals simultaneously: water quality (EEA or APA), weather forecast and sea state (IPMA), tides (Instituto Hidrográfico) and public transport (Carris Metropolitana). None of them was designed for the average beachgoer, and none of them communicate with each other

**OndaCerta** solves this problem by aggregating all these sources into a single native mobile application, adding a community participation layer inspired by the Waze model: users who are physically at the beach can report conditions, confirm the flag status and vote on other users' alerts — creating a collaborative information system verified by physical presence.

The initial geographic scope covers the beaches of Arrábida and Sesimbra, with an architecture designed for expansion to other bathing areas in the country

---

## Features

### Real-time data
- Updated weather conditions (temperature, wind, precipitation, humidity)
- Sea state (wave height, period, direction)
- Tide chart with cosine interpolation and dynamic window centred on the present
- Water quality according to EEA classification (Excellent / Good / Sufficient / Poor)
- Upcoming public transport departures grouped by destination, with real-time GPS-based times

### Community layer
- Alert submission with type, severity and descriptive note
- Voting on other users' alerts (upvote / downvote with toggle)
- Confirmation and proposal of flag status (green, yellow, red, purple)
- All write mechanisms require physical presence verification via GPS heartbeat
- Automatic expiration of alerts with sufficient downvotes

### Profile and gamification
- Reputation level and accumulated score from contributions
- Streak of consecutive beach visit days (calculated via heartbeat)
- Achievement system evaluated in real time
- Recent activity history

### Personal management
- Favourite beaches with multi-device synchronisation
- Granular push notification settings (types, radius, minimum severity, quiet hours)
- Privacy settings (location accuracy, visibility, anonymous sharing)
- Account deletion with explicit confirmation and 30-day data retention

---

## Main screens

### Authentication

<table><tr>

<td align="center" width="33%">

<!-- 🖼️ docs/assets/screens/splash.png -->
> **[ SPLASH — docs/assets/screens/splash.png ]**

**Splash**
Adaptive wave animation while the session is verified.
</td>

<td align="center" width="33%">

<!-- 🖼️ docs/assets/screens/login.png -->
> **[ LOGIN — docs/assets/screens/login.png ]**

**Login**
Google or email/password authentication. Guest access without registration.
</td>

<td align="center" width="33%">

<!-- 🖼️ docs/assets/screens/email_login.png -->
> **[ EMAIL LOGIN — docs/assets/screens/email_login.png ]**

**Email Login**
Registration and authentication with email and password.
</td>

</tr></table>

---

### Dashboard and Beaches

<table><tr>

<td align="center" width="33%">

<!-- 🖼️ docs/assets/screens/home.png -->
> **[ HOME — docs/assets/screens/home.png ]**

**Dashboard**
Nearest beach highlighted with flag, conditions, tides and active alerts.
</td>

<td align="center" width="33%">

<!-- 🖼️ docs/assets/screens/beach_list.png -->
> **[ BEACH LIST — docs/assets/screens/beach_list.png ]**

**Beaches**
Interactive map (OpenStreetMap) with sliding panel. Search and filters by flag.
</td>

<td align="center" width="33%">

<!-- 🖼️ docs/assets/screens/beach_detail.png -->
> **[ BEACH DETAIL — docs/assets/screens/beach_detail.png ]**

**Beach Detail**
Complete data: weather, sea, tides, water quality, transport and alerts.
</td>

</tr></table>

---

### Community and Flags

<table><tr>

<td align="center" width="33%">

<!-- 🖼️ docs/assets/screens/community_alerts.png -->
> **[ COMMUNITY ALERTS — docs/assets/screens/community_alerts.png ]**

**Alerts**
Alert list with severity indicator, voting and new report submission.
</td>

<td align="center" width="33%">

<!-- 🖼️ docs/assets/screens/flag_confirm.png -->
> **[ FLAG CONFIRM — docs/assets/screens/flag_confirm.png ]**

**Confirm Flag**
Sheet with sonar animation, confidence index and confirm/contest actions.
</td>

<td align="center" width="33%">

<!-- 🖼️ docs/assets/screens/flag_proposal.png -->
> **[ FLAG PROPOSAL — docs/assets/screens/flag_proposal.png ]**

**Propose Flag**
2×2 grid to select the proposed flag colour. Available to users with sufficient reputation.
</td>

</tr></table>

---

### Tides, Profile and Favourites

<table><tr>

<td align="center" width="33%">

<!-- 🖼️ docs/assets/screens/tides.png -->
> **[ TIDES — docs/assets/screens/tides.png ]**

**Tides**
Immersive visualisation with oceanic animation adaptive to the time and weather conditions.
</td>

<td align="center" width="33%">

<!-- 🖼️ docs/assets/screens/profile.png -->
> **[ PROFILE — docs/assets/screens/profile.png ]**

**Profile**
Reputation, streak, achievements, contribution statistics and activity history.
</td>

<td align="center" width="33%">

<!-- 🖼️ docs/assets/screens/favourites.png -->
> **[ FAVOURITES — docs/assets/screens/favourites.png ]**

**Favourites**
Favourite beaches list with pull-to-refresh and cross-device synchronisation.
</td>

</tr></table>

---

### Settings

<table><tr>

<td align="center" width="50%">

<!-- 🖼️ docs/assets/screens/privacy_settings.png -->
> **[ PRIVACY SETTINGS — docs/assets/screens/privacy_settings.png ]**

**Privacy**
Control over location accuracy, profile visibility and data sharing. Account deletion.
</td>

<td align="center" width="50%">

<!-- 🖼️ docs/assets/screens/notification_settings.png -->
> **[ NOTIFICATION SETTINGS — docs/assets/screens/notification_settings.png ]**

**Notifications**
Granular configuration: alert types, proximity radius, minimum severity and quiet hours.
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
| Maps | flutter_map + OSM | No paid dependencies |
| Backend | FastAPI (Python) | REST API, periodic jobs, PostGIS |
| Database | PostgreSQL + PostGIS | Geospatial presence, favourites, achievements |

---

## Technical documentation

Detailed documentation for each component is in their respective directories:

| Component | README | Contents |
|---|---|---|
| 📱 **Flutter App** | [`onda_certa_app/README.md`](onda_certa_app/README.md) | Folder structure, dependencies, environment variables, how to run locally |
| ⚙️ **Backend API** | [`backend/README.md`](backend/README.md) | Setup, endpoints, authentication, periodic jobs, deployment |

---

## Roadmap

### ✅ Completed

**Infrastructure and authentication**
- [x] Feature-first architecture with Riverpod 3.x
- [x] Google authentication (OAuth 2.0), email/password and guest mode
- [x] Secure token storage (Keychain / Keystore)
- [x] Silent token renewal with Dio interceptor
- [x] Native splash screen (Android 12+ and iOS) with wave animation

**Screens**
- [x] HomeScreen — dashboard with nearest beach, conditions, tides, alerts
- [x] BeachListScreen — list + interactive OpenStreetMap with sliding panel
- [x] BeachDetailScreen — full detail with pull-to-refresh and auto-refresh via RouteAware
- [x] TideScreen — immersive visualisation with adaptive oceanic animation
- [x] CommunityAlertsScreen — alerts with optimistic voting and report submission
- [x] ProfileScreen — reputation, streak, achievements, history
- [x] FavouritesScreen — favourites with multi-device synchronisation
- [x] PrivacySettingsScreen — granular control over location and visibility
- [x] NotificationSettingsScreen — 14 push notification configuration parameters

**Community layer**
- [x] Alert submission with presence verification via heartbeat
- [x] Optimistic voting with rollback on server error
- [x] Flag confirmation with sonar animation and animated confidence bar
- [x] Flag proposal (users with reputation ≥ 5)
- [x] Automatic alert expiration by downvotes

**Gamification and profile**
- [x] Achievement system with real-time evaluation
- [x] Presence streak calculated via heartbeat (idempotent per day)
- [x] Confirmation rate-limiting (1/hour/beach) on the server

**Design system**
- [x] Centralised AppColors, AppSpacing, AppTextStyles
- [x] Flag gradients and mappings unified in AppColors
- [x] Shared widgets: AlertItem, TideChartPainter, MetricCell, EmptyState

---

### 🚧 In development

- [ ] **TransportPlannerScreen** — dedicated screen for planning public transport to the beaches, with nearby stop search and trip planning

---

### 🔜 Planned

- [ ] Dark mode (consider)
- [ ] Push notifications
- [ ] Personal data export (`/users/me/data-export` endpoint already exists in the backend)
- [ ] Administration panel (backoffice) for beach management and moderation
- [ ] Geographic expansion to other Portuguese bathing areas
- [ ] Final legal pages (Terms of Service, Privacy Policy)
- [ ] E2e integration tests
- [ ] Terms and conditions
---

<div align="center">
Escola Superior de Tecnologia de Setúbal, IPS · 2026

</div>

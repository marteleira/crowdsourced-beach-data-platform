# OndaCerta - Flutter Client

Native mobile application for the OndaCerta project, built with Flutter 3.x / Dart 3

**Platforms:** iOS 16+ · Android 10 (API 29+)

---

## Table of Contents

- [Folder structure](#folder-structure)
- [Architecture](#architecture)
- [Screens and routes](#screens-and-routes)
- [Design system](#design-system)
- [Main dependencies](#main-dependencies)
- [Environment variables](#environment-variables)
- [Setup and running](#setup-and-running)
- [Assets and icons](#assets-and-icons)

---

## Folder structure

```
lib/
├── app.dart                        # GoRouter, routeObserver, OndaCertaApp
├── main.dart
│
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── auth_repository.dart
│   │   │   └── secure_storage.dart
│   │   ├── domain/auth_state.dart   # sealed class AuthState
│   │   └── presentation/
│   │       ├── splash_screen.dart
│   │       ├── login_screen.dart
│   │       └── email_login_screen.dart
│   │
│   ├── beaches/
│   │   ├── data/
│   │   │   ├── beach_repository.dart
│   │   │   └── beach_provider.dart  # FutureProviders + CommunityReportsNotifier
│   │   ├── domain/beach_models.dart
│   │   └── presentation/
│   │       ├── beach_list_screen.dart
│   │       └── beach_detail_screen.dart
│   │
│   ├── community/
│   │   └── presentation/
│   │       ├── community_alerts_screen.dart
│   │       ├── flag_confirmation_sheet.dart
│   │       ├── flag_proposal_sheet.dart
│   │       └── report_condition_sheet.dart
│   │
│   ├── favourites/
│   │   └── presentation/
│   │       └── favourites_screen.dart
│   │
│   ├── home/
│   │   └── presentation/
│   │       └── home_screen.dart     # scaffold with NavigationBar (4 tabs)
│   │
│   ├── profile/
│   │   └── presentation/
│   │       └── profile_screen.dart
│   │
│   ├── settings/
│   │   ├── data/
│   │   │   ├── settings_repository.dart
│   │   │   └── settings_provider.dart
│   │   ├── domain/settings_models.dart
│   │   └── presentation/
│   │       ├── privacy_settings_screen.dart
│   │       └── notification_settings_screen.dart
│   │
│   └── tides/
│       └── presentation/
│           └── tide_screen.dart
│
├── core/
│   ├── network/
│   │   ├── dio_client.dart          # Dio singleton instance
│   │   └── auth_interceptor.dart    # token injection + silent refresh
│   └── presence/
│       ├── heartbeat_service.dart   # periodic Timer (19 min), GPS, 4 km radius
│       └── heartbeat_provider.dart
│
└── shared/
    ├── theme/
    │   └── app_theme.dart           # AppColors · AppSpacing · AppTextStyles
    ├── utils/
    │   └── beach_helpers.dart       # flagLabel · flagInfo · occupancyLabel
    └── widgets/
        ├── alert_item.dart          # AlertItem + alertMeta() + timeAgo()
        ├── animated_waves.dart      # wave CustomPainter (Splash + TideScreen)
        ├── empty_state.dart         # generic empty state (icon + message + action)
        ├── metric_cell.dart         # MetricCell + metricRow()
        └── tide_chart.dart          # TideChartPainter + TideTimeCell
```

---

## Architecture

### General pattern

The app follows a **feature-first** structure with internal separation into `domain / data / presentation`, the state management uses **Riverpod 3.x** without code generation (the deliberate trade-off was to skip the `build_runner` step to keep development cycles faster).

### State management

All data providers are `FutureProvider` or `FutureProvider.family`, the providers that support mutation (votes, favourites, settings) are `AsyncNotifier` with optimistic updates and automatic rollback on server failure.

```dart
// Optimistic update pattern used in FavouritesNotifier, CommunityReportsNotifier,
// PrivacySettingsNotifier and NotificationSettingsNotifier
Future<void> toggle(BeachSummary beach) async {
  final snapshot = List<BeachSummary>.from(state.value ?? []);
  state = AsyncData(/* immediate local state */);
  try {
    await ref.read(beachRepositoryProvider).addFavourite(beach.slug);
  } catch (_) {
    state = AsyncData(snapshot); // revert
    rethrow;
  }
}
```

### Authentication

`AuthInterceptor` intercepts all 401 responses, attempts a silent refresh via `POST /auth/refresh` (with `extra: {'skipAuthInterceptor': true}` to avoid loops), and retries the original request. Tokens are stored in Keychain (iOS) / Keystore (Android) via `flutter_secure_storage`

### Presence and heartbeat

`HeartbeatService` is a plain Dart class (not a Notifier) with two cancellable Timers: a 5-second initial delay and a 19-minute periodic one, it sends a heartbeat only when GPS places the user within 4 km of a beach, if the GPS is unavailable, the heartbeat is silently skipped (the beach coordinates are never used as a fallback).

The presence streak is calculated on the backend and incremented on each heartbeat (idempotent within the same day via `last_contribution_date`).

### Cross-route navigation

The `HomeScreen` has 4 tabs managed by local state (`_tab`). To navigate to a tab from another route (e.g. the "Full view" button in beach detail that leads to TideScreen), the `selectedTabProvider` is used with `ref.listen` in `HomeScreen`:

```dart
ref.listen<int>(selectedTabProvider, (_, tab) => setState(() => _tab = tab));
```

`BeachDetailScreen` auto-refresh uses `WidgetsBindingObserver` (return from background) and `RouteAware` with `routeObserver` registered in GoRouter (return from sub-routes)

---

## Screens and routes

| Route | Screen | Access |
|---|---|---|
| `/` | `SplashScreen` | Public |
| `/login` | `LoginScreen` | Public |
| `/login/email` | `EmailLoginScreen` | Public |
| `/home` | `HomeScreen` (4 tabs) | Authenticated / Guest |
| `/beach/:slug` | `BeachDetailScreen` | Authenticated / Guest |
| `/beach/:slug/alerts` | `CommunityAlertsScreen` | Authenticated / Guest |
| `/favourites` | `FavouritesScreen` | Authenticated |
| `/settings/privacy` | `PrivacySettingsScreen` | Authenticated |
| `/settings/notifications` | `NotificationSettingsScreen` | Authenticated |

GoRouter has a global redirect that sends to `/login` when a protected route is accessed and the user is not authenticated. `BeachSummary` is passed via `state.extra` (already loaded from the list, avoiding an extra backend call).

### Modal sheets

| Sheet | Entry point |
|---|---|
| `FlagConfirmationSheet` | Tap on `_FlagCard` when `flagColor != 'unknown'` |
| `FlagProposalSheet` | Tap on `_FlagCard` when `flagColor == 'unknown'` |
| `ReportConditionSheet` | "Submit Report" button in `CommunityAlertsScreen` |

---

## Design system

Centralised in `lib/shared/theme/app_theme.dart`.

### AppColors

```dart
AppColors.primary        // dark navy
AppColors.teal           // primary action
AppColors.tealDark
AppColors.coral          // alerts / destructive
AppColors.sand           // alternative background
AppColors.amber          // streak / achievements
AppColors.background     // general background
AppColors.textSecondary
AppColors.textHint
AppColors.borderLight    // 0xFFE5E7EB
AppColors.borderMedium   // 0xFFD1D5DB
AppColors.backgroundLight // 0xFFF3F4F6

// Flags
AppColors.flagGreen · flagYellow · flagRed · flagPurple

// Utilities
AppColors.forFlag(String flag)      → Color
AppColors.beachGradient(String flag) → LinearGradient
```

### AppSpacing

4–8–12–16–20–24–32 scale (Tailwind / Material 3 base).

```dart
AppSpacing.xs   // 4
AppSpacing.sm   // 8
AppSpacing.md   // 12
AppSpacing.lg   // 16
AppSpacing.xl   // 20
AppSpacing.xxl  // 24
AppSpacing.xxxl // 32
```

### AppTextStyles

Pre-defined styles for common `fontSize` + `color` + `fontWeight` combinations. Examples: `AppTextStyles.secondary`, `AppTextStyles.titleMd`, `AppTextStyles.tealLabel`.

---

## Main dependencies

| Package | Version | Use |
|---|---|---|
| `flutter_riverpod` | ^3.3.1 | State management |
| `go_router` | ^17.x | Declarative navigation |
| `dio` | — | HTTP client |
| `flutter_secure_storage` | — | Tokens in Keychain/Keystore |
| `google_sign_in` | ^7.x | Google OAuth (new API: `GoogleSignIn.instance`) |
| `device_info_plus` | — | `device_id` for guest session |
| `geolocator` | — | GPS, proximity sorting, heartbeat |
| `flutter_map` | ^7.0.2 | Interactive map (OpenStreetMap, no API key) |
| `latlong2` | ^0.9.1 | `LatLng` type used by flutter_map |
| `flutter_native_splash` | — | Native splash (Android 12+ and iOS) |
| `flutter_launcher_icons` | — | Launcher icons |

> **Note on `google_sign_in` v7.x:** The API changed completely from v6, so the `GoogleSignIn()` constructor no longer exists, ----use instead: `GoogleSignIn.instance.initialize(serverClientId: ...)` and `GoogleSignIn.instance.authenticate()`. The Firebase plugin (`com.google.gms.google-services`) is not required; authentication is configured purely in code

---

## Environment variables

There is no `.env` file on the Flutter client — configuration is done in `lib/core/network/dio_client.dart` and in the platform-specific files.

| Parameter | File | Description |
|---|---|---|
| Backend `baseUrl` | `dio_client.dart` | API base URL (e.g. `http://10.0.2.2:8000/api/v1` for Android emulator) |
| Google `serverClientId` | `auth_repository.dart` | Google Cloud Console OAuth Client ID (type "Web application") |
| Android `google-services` | Not required | The Google Sign-In integration does not use the Firebase plugin |

---

## Setup and running

### Prerequisites

- Flutter SDK `>=3.0.0` with Dart `>=3.0.0`
- Android SDK with API 29+ (for Android emulator/device)
- Xcode 15+ (for iOS)
- Backend running (see [`backend/README.md`](../backend/README.md))

### Getting started

```bash
# From the Flutter project root
flutter pub get

# Generate launcher icons
dart run flutter_launcher_icons

# Generate native splash screen
dart run flutter_native_splash:create

# Run in debug mode (auto-selects device if only one is connected)
flutter run

# Run on a specific device
flutter run -d <device-id>

# Android release build
flutter build apk --release

# iOS release build
flutter build ios --release
```

### Local backend (Android emulator)

The Android emulator uses `10.0.2.2` to reach the host machine's `localhost`. Configure `baseUrl` in `dio_client.dart`:

```dart
static const _baseUrl = 'http://10.0.2.2:8000/api/v1';
```

For a physical device on the same network, use the machine's local IP (e.g. `http://192.168.1.x:8000/api/v1`).

---

## Assets and icons

```
assets/
├── icon/
│   ├── icon.png          # launcher icon (flutter_launcher_icons)
│   ├── icon_spl.png      # icon for native splash Android 12+ / iOS
│   └── icon_fullogo.png  # full logo for animated Flutter splash
└── ...
```

Screenshots and mockups are documented in the [main README](../README.md).

---

*Part of the [OndaCerta](../README.md) project — Escola Superior de Tecnologia de Setúbal, IPS · 2026*

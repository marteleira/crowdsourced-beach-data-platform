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
├── main.dart                       # Firebase init, Google Sign-In init, FCM startup
│
├── features/
│   ├── auth/
│   │   └── presentation/
│   │       ├── login_screen.dart
│   │       ├── email_login_screen.dart
│   │       ├── email_verification_screen.dart
│   │       ├── forgot_password_screen.dart
│   │       ├── reset_password_screen.dart
│   │       ├── pending_deletion_screen.dart
│   │       └── account_status_screen.dart   # AccountBannedScreen + AccountSuspendedScreen
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
│   │       ├── community_alerts_screen.dart  # includes on-demand translation of report notes
│   │       ├── flag_confirmation_sheet.dart
│   │       ├── flag_proposal_sheet.dart
│   │       └── report_condition_sheet.dart
│   │
│   ├── favourites/
│   │   └── presentation/favourites_screen.dart
│   │
│   ├── home/
│   │   └── presentation/home_screen.dart     # 4 tabs, holds the bottom NavigationBar
│   │
│   ├── legal/
│   │   └── presentation/
│   │       ├── legal_screen.dart    # shared layout consumed by the two screens below
│   │       ├── terms_screen.dart
│   │       └── privacy_screen.dart
│   │
│   ├── notifications/
│   │   └── presentation/notifications_screen.dart  # in-app notification history
│   │
│   ├── onboarding/
│   │   └── presentation/onboarding_screen.dart      # first-run PageView tour
│   │
│   ├── profile/
│   │   └── presentation/profile_screen.dart
│   │
│   ├── settings/
│   │   ├── data/
│   │   │   ├── settings_repository.dart
│   │   │   └── settings_provider.dart
│   │   ├── domain/settings_models.dart
│   │   └── presentation/
│   │       ├── account_settings_screen.dart
│   │       ├── privacy_settings_screen.dart
│   │       └── notification_settings_screen.dart
│   │
│   ├── splash/
│   │   └── presentation/splash_screen.dart
│   │
│   ├── tides/
│   │   └── presentation/tide_screen.dart     # used both as a Home tab and a routed beach detail view
│   │
│   └── transport/
│       └── presentation/transport_screen.dart
│
├── core/
│   ├── api/
│   │   ├── api_client.dart          # Dio singleton, base URL, Accept-Language header
│   │   └── auth_interceptor.dart    # token refresh + banned/suspended/pending-deletion handling
│   ├── auth/
│   │   ├── auth_provider.dart       # sealed AuthState, AuthNotifier
│   │   └── auth_repository.dart
│   ├── constants/
│   │   ├── app_config.dart          # Google OAuth client id, map defaults
│   │   ├── app_routes.dart          # every GoRoute path as a constant
│   │   └── app_strings.dart         # copy not yet moved into l10n
│   ├── l10n/l10n.dart               # context.l10n extension
│   ├── notifications/
│   │   ├── fcm_service.dart         # token registration, foreground + background push handling
│   │   ├── notification_model.dart
│   │   └── notification_provider.dart  # persists notification history to disk
│   ├── onboarding/onboarding_provider.dart  # has the user already seen the intro tour
│   ├── presence/
│   │   ├── heartbeat_service.dart   # periodic Timer (19 min), GPS, 4 km radius
│   │   └── heartbeat_provider.dart
│   └── storage/secure_storage.dart
│
└── shared/
    ├── theme/
    │   └── app_theme.dart           # AppColors · AppSpacing · AppTextStyles
    ├── utils/
    │   ├── beach_helpers.dart       # flagLabel · flagInfo · occupancyLabel
    │   ├── format_helpers.dart
    │   └── ui_helpers.dart
    └── widgets/
        ├── alert_item.dart          # AlertItem + alertMeta() + timeAgo()
        ├── animated_waves.dart      # wave CustomPainter (Splash + TideScreen)
        ├── app_error_state.dart
        ├── app_loading_spinner.dart
        ├── auth_code_input.dart     # 6-digit code entry, shared by verification/reset flows
        ├── auth_consent_footer.dart # terms/privacy links on the auth screens
        ├── auth_input_decoration.dart
        ├── beach_cover_image.dart   # cover photo with flag-colour gradient fallback
        ├── empty_state.dart         # generic empty state (icon + message + action)
        ├── metric_cell.dart         # MetricCell + metricRow()
        ├── overlay_icon_button.dart
        ├── password_strength_field.dart  # live strength indicator (length, case, digit/special)
        ├── section_header.dart
        ├── severity_dots.dart
        ├── tide_chart.dart          # TideChartPainter + TideTimeCell
        └── user_avatar.dart
```

---

## Architecture

### General pattern

The app follows a **feature-first** structure. Screens live under `features/`, cross-cutting stuff (auth, api client, notifications, presence, onboarding) lives under `core/`, and truly shared UI lives under `shared/`. State management is **Riverpod 3.x** without code generation, a deliberate trade-off to skip the `build_runner` step and keep development cycles faster.

### State management

All data providers are `FutureProvider` or `FutureProvider.family`. The providers that support mutation (votes, favourites, settings) are `AsyncNotifier` with optimistic updates and automatic rollback on server failure.

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

`AuthInterceptor` intercepts every response, not just the happy path. On a 401 it attempts a silent refresh via `POST /auth/refresh` (tagged with `extra: {'skipAuthInterceptor': true}` to stop it looping on itself), then retries the original request. On a 403 it also reads the backend's structured error codes and reacts globally, `account_pending_deletion` routes to the pending deletion screen, `account_banned` to the banned screen, `account_suspended` to the suspended screen, all without every screen having to check for this itself. Tokens are stored in Keychain (iOS) / Keystore (Android) via `flutter_secure_storage`.

### Presence and heartbeat

`HeartbeatService` is a plain Dart class (not a Notifier) with two cancellable Timers, a 5 second initial delay and a 19 minute periodic one. It sends a heartbeat only when GPS places the user within 4 km of a beach. If GPS is unavailable the heartbeat is silently skipped, beach coordinates are never used as a fallback.

The presence streak is calculated on the backend and incremented on each heartbeat, idempotent within the same day via `last_contribution_date`.

### Push notifications

`FcmService` is initialised once in `main.dart`, right after `Firebase.initializeApp()` and before the app widget is built. It registers the FCM token after every login (`registerToken()`), unregisters it on logout, shows a local notification when a push arrives while the app is in the foreground (FCM doesn't do that automatically on its own), and persists received notifications to disk through `notification_provider.dart` so `NotificationsScreen` has history to show even after the app restarts.

### Onboarding

A `FutureProvider` (`onboardingSeenProvider`) reads a flag from secure storage to decide whether to show the first-run tour. `OnboardingScreen` is a `PageView` of slides with a legal links row at the end, and the `/onboarding` route is only reachable through an explicit navigation extra, so it can't be deep-linked into by accident.

### Cross-route navigation

`HomeScreen` holds 4 tabs locally in an `IndexedStack` (Home dashboard, BeachListScreen, TideScreen, ProfileScreen), switched either through the bottom `NavigationBar` or by watching `selectedTabProvider`, so any other screen can jump straight to a specific Home tab:

```dart
ref.listen<int>(selectedTabProvider, (_, tab) => setState(() => _tab = tab));
```

Beach-specific deep dives don't reuse those tabs though. A beach's own tide chart, its transport page and its alerts are separate routes pushed with that `BeachSummary` as `extra`, for example `context.push(AppRoutes.beachTides(slug), extra: beach)`. `TideScreen` itself is the same widget in both cases, it just renders differently depending on whether a specific beach was passed in.

`BeachDetailScreen` auto-refresh uses `WidgetsBindingObserver` (return from background) and `RouteAware` with `routeObserver` registered in GoRouter (return from sub-routes).

---

## Screens and routes

| Route | Screen | Access |
|---|---|---|
| `/` | `SplashScreen` | Public |
| `/onboarding` | `OnboardingScreen` | Public, only reachable via an explicit navigation extra |
| `/login` | `LoginScreen` | Public |
| `/login/email` | `EmailLoginScreen` | Public |
| `/login/forgot-password` | `ForgotPasswordScreen` | Public |
| `/login/reset-password` | `ResetPasswordScreen` | Public, needs a code passed as extra |
| `/verify-email` | `EmailVerificationScreen` | Authenticated, unverified |
| `/pending-deletion` | `PendingDeletionScreen` | Account scheduled for deletion |
| `/account-banned` | `AccountBannedScreen` | Banned accounts |
| `/account-suspended` | `AccountSuspendedScreen` | Suspended accounts |
| `/home` | `HomeScreen` (4 tabs) | Authenticated / Guest |
| `/terms` | `TermsScreen` | Public, reachable without logging in |
| `/privacy` | `PrivacyScreen` | Public, reachable without logging in |
| `/settings/account` | `AccountSettingsScreen` | Authenticated |
| `/settings/privacy` | `PrivacySettingsScreen` | Authenticated |
| `/settings/notifications` | `NotificationSettingsScreen` | Authenticated |
| `/notifications` | `NotificationsScreen` | Authenticated / Guest |
| `/favourites` | `FavouritesScreen` | Authenticated |
| `/beach/:slug` | `BeachDetailScreen` | Authenticated / Guest |
| `/beach/:slug/alerts` | `CommunityAlertsScreen` | Authenticated / Guest |
| `/beach/:slug/transport` | `TransportScreen` | Authenticated / Guest |
| `/beach/:slug/tides` | `TideScreen` | Authenticated / Guest |

GoRouter has a global redirect that sends to `/login` when a protected route is accessed and the user is not authenticated, and to the relevant status screen if the account is banned, suspended or pending deletion. `BeachSummary` is passed via `state.extra` on every `/beach/:slug*` route (already loaded from the list, avoiding an extra backend call).

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

4-8-12-16-20-24-32 scale (Tailwind / Material 3 base).

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
| `go_router` | ^17.2.3 | Declarative navigation |
| `dio` | ^5.9.2 | HTTP client |
| `flutter_secure_storage` | ^10.0.0 | Tokens in Keychain/Keystore |
| `google_sign_in` | ^7.2.0 | Google OAuth (new API, `GoogleSignIn.instance`) |
| `device_info_plus` | ^12.4.0 | `device_id` for guest session |
| `geolocator` | ^14.0.2 | GPS, proximity sorting, heartbeat |
| `flutter_map` | ^7.0.2 | Interactive map (OpenStreetMap tiles, no API key) |
| `latlong2` | ^0.9.1 | `LatLng` type used by flutter_map |
| `firebase_core` | ^3.6.0 | Firebase bootstrap |
| `firebase_messaging` | ^15.1.3 | Push notification delivery |
| `flutter_local_notifications` | ^18.0.1 | Shows a notification while the app is in the foreground |
| `path_provider` | ^2.1.5 | Local storage for notification history and data export files |
| `url_launcher` | ^6.3.1 | Opens Google Maps for directions |
| `google_fonts` | ^8.1.0 | Inter typeface |
| `intl` | ^0.20.2 | Locale handling, date formatting |
| `flutter_native_splash` | ^2.4.7 | Native splash (Android 12+ and iOS) |
| `flutter_launcher_icons` | ^0.14.4 | Launcher icons |

There's also a direct call from `community_alerts_screen.dart` to the MyMemory Translation API (`api.mymemory.translated.net`), used only to translate a community report's note on demand, no package for it, just a plain `Dio().get(...)` call at the point of use.

> **Note on `google_sign_in` v7.x:** The API changed completely from v6, the `GoogleSignIn()` constructor no longer exists. Use instead `GoogleSignIn.instance.initialize(serverClientId: ...)` and `GoogleSignIn.instance.authenticate()`. The Firebase plugin (`com.google.gms.google-services`) is not required for this, authentication is configured purely in code.

---

## Environment variables

There's still no `.env` file on the Flutter client. Configuration is a mix of compile-time defines and constants in code.

| Parameter | Where | Description |
|---|---|---|
| Backend host | `--dart-define=API_HOST=...` | Overrides the default `10.0.2.2` (Android emulator alias for the host machine). Use your machine's LAN IP for a physical device |
| Google `serverClientId` | `lib/core/constants/app_config.dart` | Google Cloud Console OAuth Client ID (type "Web application"), must match the backend's `GOOGLE_CLIENT_ID` |
| Map defaults | `lib/core/constants/app_config.dart` | Default map centre and zoom (Arrábida peninsula) |
| Android `google-services` | Not required | The Google Sign-In integration doesn't use the Firebase plugin for auth, Firebase itself is still needed for push notifications |
| Firebase config files | `android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist` | Needed for `firebase_core` to initialise, download from the Firebase console |

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

# Point at a backend on your LAN instead of the Android emulator default
flutter run --dart-define=API_HOST=192.168.1.221

# Android release build
flutter build apk --release

# iOS release build
flutter build ios --release
```

### Local backend (Android emulator)

The Android emulator uses `10.0.2.2` to reach the host machine's `localhost`, and that's the default baked into `api_client.dart`, so no configuration is needed for the emulator.

For a physical device on the same network, pass the machine's LAN IP with `--dart-define=API_HOST=192.168.1.x` and run the backend with `--host 0.0.0.0` so it accepts connections from outside localhost. If you change the IP, also update `android/app/src/main/res/xml/network_security_config.xml`, it whitelists which cleartext HTTP hosts Android is allowed to talk to.

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

*Part of the [OndaCerta](../README.md) project, Escola Superior de Tecnologia de Setúbal, IPS · 2026*

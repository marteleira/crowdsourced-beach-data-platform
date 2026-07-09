import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'l10n/app_localizations.dart';
import 'core/auth/auth_provider.dart';
import 'core/constants/app_routes.dart';
import 'core/notifications/notification_provider.dart';
import 'core/presence/heartbeat_provider.dart';
import 'features/notifications/presentation/notifications_screen.dart';
import 'features/auth/presentation/email_login_screen.dart';
import 'features/auth/presentation/email_verification_screen.dart';
import 'features/auth/presentation/forgot_password_screen.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/pending_deletion_screen.dart';
import 'features/auth/presentation/account_status_screen.dart';
import 'features/auth/presentation/reset_password_screen.dart';
import 'features/beaches/domain/beach_models.dart';
import 'features/beaches/presentation/beach_detail_screen.dart';
import 'features/community/presentation/community_alerts_screen.dart';
import 'features/transport/presentation/transport_screen.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/legal/presentation/privacy_screen.dart';
import 'features/legal/presentation/terms_screen.dart';
import 'features/onboarding/presentation/onboarding_screen.dart';
import 'features/settings/presentation/account_settings_screen.dart';
import 'features/settings/presentation/notification_settings_screen.dart';
import 'features/settings/presentation/privacy_settings_screen.dart';
import 'features/favourites/presentation/favourites_screen.dart';
import 'features/splash/presentation/splash_screen.dart';
import 'features/tides/presentation/tide_screen.dart';
import 'shared/theme/app_theme.dart';

final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

/// Notifies GoRouter to re-run its redirect logic when auth/account state
/// changes, without recreating the GoRouter instance itself (which would
/// reset navigation back to '/' mid-transition).
class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    ref.listen(authProvider, (_, _) => notifyListeners());
    ref.listen(pendingDeletionProvider, (_, _) => notifyListeners());
    ref.listen(accountBannedProvider, (_, _) => notifyListeners());
    ref.listen(accountSuspendedProvider, (_, _) => notifyListeners());
  }
}

final _routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefreshNotifier(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/',
    observers: [routeObserver],
    refreshListenable: refresh,
    redirect: (context, state) {
      final loc = state.matchedLocation;

      // Account status overrides fire from any location, including login/splash.
      // Return null (not a redirect) when already on the target screen so we
      // don't loop through the unauthenticated guard below.
      if (ref.read(accountBannedProvider) != null) {
        return loc == AppRoutes.accountBanned ? null : AppRoutes.accountBanned;
      }
      if (ref.read(accountSuspendedProvider) != null) {
        return loc == AppRoutes.accountSuspended ? null : AppRoutes.accountSuspended;
      }

      // Splash, onboarding, auth, and public legal routes manage their own navigation
      if (loc == '/' ||
          loc == AppRoutes.onboarding ||
          loc.startsWith(AppRoutes.login) ||
          loc == AppRoutes.terms ||
          loc == AppRoutes.privacy) {
        return null;
      }

      // Protect app routes
      final authState = ref.read(authProvider).value;
      if (authState is! AuthAuthenticated) return AppRoutes.login;

      // Redirect to pending-deletion screen for any app route when account is flagged
      final pendingDeletion = ref.read(pendingDeletionProvider);
      if (pendingDeletion != null && loc != AppRoutes.pendingDeletion) {
        return AppRoutes.pendingDeletion;
      }

      // Force email verification for registered (non-guest) accounts
      if (!authState.isAnonymous &&
          !authState.isEmailVerified &&
          loc != AppRoutes.verifyEmail) {
        return AppRoutes.verifyEmail;
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, _) => const SplashScreen()),
      GoRoute(
        path: AppRoutes.onboarding,
        redirect: (_, state) => state.extra is! String ? AppRoutes.login : null,
        builder: (_, state) => OnboardingScreen(destination: state.extra! as String),
      ),
      GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginScreen()),
      GoRoute(path: AppRoutes.loginEmail, builder: (_, _) => const EmailLoginScreen()),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (_, state) => ForgotPasswordScreen(
          prefillEmail: state.extra as String?,
        ),
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        redirect: (_, state) => state.extra is! String ? AppRoutes.login : null,
        builder: (_, state) => ResetPasswordScreen(
          email: state.extra! as String,
        ),
      ),
      GoRoute(path: AppRoutes.pendingDeletion, builder: (_, _) => const PendingDeletionScreen()),
      GoRoute(path: AppRoutes.accountBanned, builder: (_, _) => const AccountBannedScreen()),
      GoRoute(path: AppRoutes.accountSuspended, builder: (_, _) => const AccountSuspendedScreen()),
      GoRoute(path: AppRoutes.verifyEmail, builder: (_, _) => const EmailVerificationScreen()),
      GoRoute(path: AppRoutes.home, builder: (_, _) => const HomeScreen()),
      GoRoute(path: AppRoutes.terms, builder: (_, _) => const TermsScreen()),
      GoRoute(path: AppRoutes.privacy, builder: (_, _) => const PrivacyScreen()),
      GoRoute(path: AppRoutes.settingsAccount, builder: (_, _) => const AccountSettingsScreen()),
      GoRoute(path: AppRoutes.settingsPrivacy, builder: (_, _) => const PrivacySettingsScreen()),
      GoRoute(path: AppRoutes.settingsNotifications, builder: (_, _) => const NotificationSettingsScreen()),
      GoRoute(
        path: '/beach/:slug',
        redirect: (_, state) => state.extra is! BeachSummary ? AppRoutes.home : null,
        builder: (_, state) => BeachDetailScreen(beach: state.extra! as BeachSummary),
      ),
      GoRoute(
        path: '/beach/:slug/alerts',
        redirect: (_, state) => state.extra is! BeachSummary ? AppRoutes.home : null,
        builder: (_, state) => CommunityAlertsScreen(beach: state.extra! as BeachSummary),
      ),
      GoRoute(path: AppRoutes.favourites, builder: (_, _) => const FavouritesScreen()),
      GoRoute(
        path: '/beach/:slug/transport',
        redirect: (_, state) => state.extra is! BeachSummary ? AppRoutes.home : null,
        builder: (_, state) => TransportScreen(beach: state.extra! as BeachSummary),
      ),
      GoRoute(
        path: '/beach/:slug/tides',
        redirect: (_, state) => state.extra is! BeachSummary ? AppRoutes.home : null,
        builder: (_, state) => TideScreen(beach: state.extra! as BeachSummary),
      ),
      GoRoute(path: AppRoutes.notifications, builder: (_, _) => const NotificationsScreen()),
    ],
  );
});

class OndaCertaApp extends ConsumerWidget {
  const OndaCertaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(heartbeatProvider);
    ref.watch(notificationsProvider);
    final router = ref.watch(_routerProvider);
    return MaterialApp.router(
      title: 'OndaCerta',
      theme: AppTheme.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/auth/auth_provider.dart';
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
import 'features/settings/presentation/account_settings_screen.dart';
import 'features/settings/presentation/notification_settings_screen.dart';
import 'features/settings/presentation/privacy_settings_screen.dart';
import 'features/favourites/presentation/favourites_screen.dart';
import 'features/splash/presentation/splash_screen.dart';
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
        return loc == '/account-banned' ? null : '/account-banned';
      }
      if (ref.read(accountSuspendedProvider) != null) {
        return loc == '/account-suspended' ? null : '/account-suspended';
      }

      // Splash and auth routes manage their own navigation
      if (loc == '/' || loc.startsWith('/login')) return null;

      // Protect app routes
      final authState = ref.read(authProvider).value;
      if (authState is! AuthAuthenticated) return '/login';

      // Redirect to pending-deletion screen for any app route when account is flagged
      final pendingDeletion = ref.read(pendingDeletionProvider);
      if (pendingDeletion != null && loc != '/pending-deletion') {
        return '/pending-deletion';
      }

      // Force email verification for registered (non-guest) accounts
      if (!authState.isAnonymous &&
          !authState.isEmailVerified &&
          loc != '/verify-email') {
        return '/verify-email';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/login/email', builder: (_, _) => const EmailLoginScreen()),
      GoRoute(
        path: '/login/forgot-password',
        builder: (_, state) => ForgotPasswordScreen(
          prefillEmail: state.extra as String?,
        ),
      ),
      GoRoute(
        path: '/login/reset-password',
        builder: (_, state) => ResetPasswordScreen(
          email: state.extra as String,
        ),
      ),
      GoRoute(path: '/pending-deletion', builder: (_, _) => const PendingDeletionScreen()),
      GoRoute(path: '/account-banned', builder: (_, _) => const AccountBannedScreen()),
      GoRoute(path: '/account-suspended', builder: (_, _) => const AccountSuspendedScreen()),
      GoRoute(path: '/verify-email', builder: (_, _) => const EmailVerificationScreen()),
      GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
      GoRoute(path: '/terms', builder: (_, _) => const TermsScreen()),
      GoRoute(path: '/privacy', builder: (_, _) => const PrivacyScreen()),
      GoRoute(path: '/settings/account', builder: (_, _) => const AccountSettingsScreen()),
      GoRoute(path: '/settings/privacy', builder: (_, _) => const PrivacySettingsScreen()),
      GoRoute(path: '/settings/notifications', builder: (_, _) => const NotificationSettingsScreen()),
      GoRoute(
        path: '/beach/:slug',
        builder: (_, state) => BeachDetailScreen(beach: state.extra as BeachSummary),
      ),
      GoRoute(
        path: '/beach/:slug/alerts',
        builder: (_, state) => CommunityAlertsScreen(beach: state.extra as BeachSummary),
      ),
      GoRoute(path: '/favourites', builder: (_, _) => const FavouritesScreen()),
      GoRoute(
        path: '/beach/:slug/transport',
        builder: (_, state) => TransportScreen(beach: state.extra as BeachSummary),
      ),
      GoRoute(path: '/notifications', builder: (_, _) => const NotificationsScreen()),
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
    );
  }
}

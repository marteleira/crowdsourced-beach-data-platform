import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/auth/auth_provider.dart';
import 'core/presence/heartbeat_provider.dart';
import 'features/auth/presentation/email_login_screen.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/beaches/domain/beach_models.dart';
import 'features/beaches/presentation/beach_detail_screen.dart';
import 'features/community/presentation/community_alerts_screen.dart';
import 'features/transport/presentation/transport_screen.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/legal/presentation/privacy_screen.dart';
import 'features/legal/presentation/terms_screen.dart';
import 'features/settings/presentation/notification_settings_screen.dart';
import 'features/settings/presentation/privacy_settings_screen.dart';
import 'features/favourites/presentation/favourites_screen.dart';
import 'features/splash/presentation/splash_screen.dart';
import 'shared/theme/app_theme.dart';

final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

final _routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    observers: [routeObserver],
    redirect: (context, state) {
      final loc = state.matchedLocation;
      // Splash and auth routes manage their own navigation
      if (loc == '/' || loc.startsWith('/login')) return null;
      // Protect app routes
      final authed = authState.value is AuthAuthenticated;
      if (!authed && loc != '/') return '/login';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/login/email', builder: (_, _) => const EmailLoginScreen()),
      GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
      GoRoute(path: '/terms', builder: (_, _) => const TermsScreen()),
      GoRoute(path: '/privacy', builder: (_, _) => const PrivacyScreen()),
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
    ],
  );
});

class OndaCertaApp extends ConsumerWidget {
  const OndaCertaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(heartbeatProvider);
    final router = ref.watch(_routerProvider);
    return MaterialApp.router(
      title: 'OndaCerta',
      theme: AppTheme.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

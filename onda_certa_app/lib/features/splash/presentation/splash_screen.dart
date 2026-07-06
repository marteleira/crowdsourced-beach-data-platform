import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/onboarding/onboarding_provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/animated_waves.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entryCtrl;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;

  bool _animDone = false;
  bool _authReady = false;
  bool _onboardingReady = false;
  AuthState? _pendingState;
  bool _onboardingSeen = true;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _logoScale = Tween<double>(begin: 0.65, end: 1.0).animate(
      CurvedAnimation(parent: _entryCtrl, curve: const Interval(0.0, 0.65, curve: Curves.easeOutBack)),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryCtrl, curve: const Interval(0.0, 0.45, curve: Curves.easeIn)),
    );
    _entryCtrl.forward().then((_) {
      _animDone = true;
      _maybeNavigate();
    });
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  void _maybeNavigate() {
    if (!_animDone || !_authReady || !_onboardingReady || !mounted || _pendingState == null) {
      return;
    }
    final destination = _pendingState is AuthAuthenticated ? AppRoutes.home : AppRoutes.login;
    if (!_onboardingSeen) {
      context.go(AppRoutes.onboarding, extra: destination);
    } else {
      context.go(destination);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<AuthState>>(authProvider, (_, next) {
      if (next.isLoading) return;
      _authReady = true;
      _pendingState = next.value ?? const AuthUnauthenticated();
      _maybeNavigate();
    });

    final current = ref.read(authProvider);
    if (!current.isLoading && !_authReady) {
      _authReady = true;
      _pendingState = current.value ?? const AuthUnauthenticated();
    }

    ref.listen<AsyncValue<bool>>(onboardingSeenProvider, (_, next) {
      if (next.isLoading) return;
      _onboardingReady = true;
      _onboardingSeen = next.value ?? true;
      _maybeNavigate();
    });

    final currentOnboarding = ref.read(onboardingSeenProvider);
    if (!currentOnboarding.isLoading && !_onboardingReady) {
      _onboardingReady = true;
      _onboardingSeen = currentOnboarding.value ?? true;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const AnimatedWaves(heightFraction: 0.38),
          Center( child:
                AnimatedBuilder(
                  animation: _entryCtrl,
                  builder: (_, _) => Opacity(
                    opacity: _logoOpacity.value,
                    child: Transform.scale(
                      scale: _logoScale.value,
                        child: Image.asset('assets/icon/icon_fullogo.png', width: MediaQuery.of(context).size.width * 0.5),
                    ),
                  ),
                ),
          ),
        ],
      ),
    );
  }
}

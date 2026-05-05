import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../shared/theme/app_theme.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _waveCtrl;
  late final AnimationController _entryCtrl;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _textOpacity;

  bool _animDone = false;
  bool _authReady = false;
  AuthState? _pendingState;

  @override
  void initState() {
    super.initState();

    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _logoScale = Tween<double>(begin: 0.65, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOutBack),
      ),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.0, 0.45, curve: Curves.easeIn),
      ),
    );
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.45, 0.9, curve: Curves.easeIn),
      ),
    );

    _entryCtrl.forward().then((_) {
      _animDone = true;
      _maybeNavigate();
    });
  }

  @override
  void dispose() {
    _waveCtrl.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  void _maybeNavigate() {
    if (!_animDone || !_authReady || !mounted || _pendingState == null) return;
    if (_pendingState is AuthAuthenticated) {
      context.go('/home');
    } else {
      context.go('/login');
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

    // Trigger immediately if already resolved (e.g. hot restart)
    final current = ref.read(authProvider);
    if (!current.isLoading && !_authReady) {
      _authReady = true;
      _pendingState = current.value ?? const AuthUnauthenticated();
    }

    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Animated waves
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: size.height * 0.38,
            child: AnimatedBuilder(
              animation: _waveCtrl,
              builder: (_, _) => CustomPaint(
                painter: _WavesPainter(_waveCtrl.value),
                size: Size(size.width, size.height * 0.38),
              ),
            ),
          ),
          //  Logo + text
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _entryCtrl,
                  builder: (_, _) => Opacity(
                    opacity: _logoOpacity.value,
                    child: Transform.scale(
                      scale: _logoScale.value,
                      child: Image.asset(
                        'assets/icon/icon.png',
                        width: 104,
                        height: 104,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                AnimatedBuilder(
                  animation: _entryCtrl,
                  builder: (_, _) => Opacity(
                    opacity: _textOpacity.value,
                    child: Column(
                      children: [
                        Text(
                          'OndaCerta',
                          style: Theme.of(context)
                              .textTheme
                              .headlineLarge
                              ?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 36,
                                letterSpacing: -0.5,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Real beaches. Real conditions.',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Wave painter

class _WavesPainter extends CustomPainter {
  const _WavesPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    _wave(canvas, size,
        amplitude: 22, speedMult: 0.8, phaseOffset: 0.0, yFrac: 0.20, alpha: 0.12);
    _wave(canvas, size,
        amplitude: 16, speedMult: 1.2, phaseOffset: 0.33, yFrac: 0.45, alpha: 0.22);
    _wave(canvas, size,
        amplitude: 11, speedMult: 1.7, phaseOffset: 0.66, yFrac: 0.68, alpha: 0.38);
  }

  void _wave(
    Canvas canvas,
    Size size, {
    required double amplitude,
    required double speedMult,
    required double phaseOffset,
    required double yFrac,
    required double alpha,
  }) {
    final paint = Paint()
      ..color = AppColors.teal.withValues(alpha: alpha)
      ..style = PaintingStyle.fill;

    final path = Path();
    final baseY = size.height * yFrac;
    final phase = (t * speedMult + phaseOffset) * 2 * pi;

    path.moveTo(0, size.height);
    for (double x = 0; x <= size.width; x += 1) {
      final y = baseY + amplitude * sin((x / size.width) * 4 * pi + phase);
      path.lineTo(x, y);
    }
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WavesPainter old) => old.t != t;
}

import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Animated wave background. Manages its own AnimationController.
/// Use [heightFraction] to control how much of the parent it covers.
class AnimatedWaves extends StatefulWidget {
  const AnimatedWaves({super.key, this.heightFraction = 0.38});
  final double heightFraction;

  @override
  State<AnimatedWaves> createState() => _AnimatedWavesState();
}

class _AnimatedWavesState extends State<AnimatedWaves>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      height: size.height * widget.heightFraction,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, _) => CustomPaint(
          painter: WavesPainter(_ctrl.value),
        ),
      ),
    );
  }
}

class WavesPainter extends CustomPainter {
  const WavesPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    _wave(canvas, size, amp: 22, speed: 0.8, phase: 0.00, yFrac: 0.20, alpha: 0.12);
    _wave(canvas, size, amp: 16, speed: 1.2, phase: 0.33, yFrac: 0.45, alpha: 0.22);
    _wave(canvas, size, amp: 11, speed: 1.7, phase: 0.66, yFrac: 0.68, alpha: 0.38);
  }

  void _wave(
    Canvas canvas,
    Size size, {
    required double amp,
    required double speed,
    required double phase,
    required double yFrac,
    required double alpha,
  }) {
    final paint = Paint()
      ..color = AppColors.teal.withValues(alpha: alpha)
      ..style = PaintingStyle.fill;
    final path = Path();
    final baseY = size.height * yFrac;
    final ph = (t * speed + phase) * 2 * pi;
    path.moveTo(0, size.height);
    for (double x = 0; x <= size.width; x++) {
      path.lineTo(x, baseY + amp * sin((x / size.width) * 4 * pi + ph));
    }
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(WavesPainter old) => old.t != t;
}

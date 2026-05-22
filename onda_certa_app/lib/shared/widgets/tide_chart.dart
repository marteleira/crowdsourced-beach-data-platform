import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../../features/beaches/domain/beach_models.dart';

/// Shared tide chart painter — used by HomeScreen and BeachDetailScreen.
class TideChartPainter extends CustomPainter {
  const TideChartPainter({
    required this.tides,
    this.currentHeight,
    this.accentColor = AppColors.teal,
  });

  final List<TideEntry> tides;
  final double? currentHeight;
  final Color accentColor;

  static int _toMins(String time) {
    final p = time.split(':');
    if (p.length != 2) return 0;
    return (int.tryParse(p[0]) ?? 0) * 60 + (int.tryParse(p[1]) ?? 0);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (tides.isEmpty) return;

    // 1. Unwrap tide extremes across midnight
    final extremaMins = <double>[];
    for (int i = 0; i < tides.length; i++) {
      double m = _toMins(tides[i].time).toDouble();
      if (i > 0 && m < extremaMins.last - 200) m += 1440;
      extremaMins.add(m);
    }
    final heights = tides.map((t) => t.height).toList();

    // 2. Normalise nowMins to within ±12h of the first extreme
    final now = DateTime.now();
    double nowMins = now.hour * 60.0 + now.minute + now.second / 60.0;
    while (nowMins < extremaMins.first - 720) { nowMins += 1440; }
    while (nowMins > extremaMins.first + 720) { nowMins -= 1440; }

    // 3. Dynamic window
    final windowStart = min(nowMins, extremaMins.first) - 30.0;
    final windowEnd   = extremaMins.last + 30.0;

    // 4. Cosine-interpolate current height so the dot sits exactly on the curve
    final h0 = currentHeight ?? _cosineInterp(extremaMins, heights, nowMins);

    // 5. Scale helpers
    final allH = [...heights, h0];
    final minH = allH.reduce(min);
    final maxH = allH.reduce(max);
    final range = (maxH - minH).clamp(0.5, double.infinity);
    const vPad = 0.10;
    double toX(double m) => (m - windowStart) / (windowEnd - windowStart) * size.width;
    double toY(double h) =>
        size.height * vPad + (1 - (h - minH) / range) * size.height * (1 - vPad * 2);

    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // 6. Draw curve through extremes + current position
    final curvePoints = <(double, double)>[
      for (int i = 0; i < extremaMins.length; i++) (extremaMins[i], heights[i]),
    ];
    curvePoints.add((nowMins, h0));
    curvePoints.sort((a, b) => a.$1.compareTo(b.$1));

    final linePaint = Paint()
      ..color = accentColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(toX(curvePoints.first.$1), toY(curvePoints.first.$2));
    for (int i = 1; i < curvePoints.length; i++) {
      final cpX = (toX(curvePoints[i - 1].$1) + toX(curvePoints[i].$1)) / 2;
      path.cubicTo(
        cpX, toY(curvePoints[i - 1].$2),
        cpX, toY(curvePoints[i].$2),
        toX(curvePoints[i].$1), toY(curvePoints[i].$2),
      );
    }
    canvas.drawPath(path, linePaint);

    // 7. Dot at the interpolated position — always on the curve
    const dotR = 5.0;
    final dotX = toX(nowMins).clamp(dotR + 1, size.width - dotR - 1);
    final dotY = toY(h0).clamp(dotR + 1, size.height - dotR - 1);
    canvas.drawCircle(Offset(dotX, dotY), dotR + 1, Paint()..color = AppColors.primary);
    canvas.drawCircle(Offset(dotX, dotY), dotR - 0.5, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(dotX, dotY), dotR - 2.5, Paint()..color = accentColor);
  }

  double _cosineInterp(List<double> times, List<double> hs, double t) {
    if (t <= times.first) return hs.first;
    if (t >= times.last) return hs.last;
    for (int i = 1; i < times.length; i++) {
      if (t <= times[i]) {
        final p = (t - times[i - 1]) / (times[i] - times[i - 1]);
        final cosT = (1 - cos(p * pi)) / 2;
        return hs[i - 1] + (hs[i] - hs[i - 1]) * cosT;
      }
    }
    return hs.last;
  }

  @override
  bool shouldRepaint(TideChartPainter old) =>
      old.tides != tides ||
      old.currentHeight != currentHeight ||
      old.accentColor != accentColor;
}

class TideTimeCell extends StatelessWidget {
  const TideTimeCell({super.key, required this.entry});
  final TideEntry entry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(
            color: entry.type == 'alta' ? AppColors.teal : const Color(0xFFE8C98A),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(entry.time, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
        Text('${entry.height.toStringAsFixed(1)}m', style: AppTextStyles.secondarySm),
        Text(entry.type, style: AppTextStyles.secondaryXs),
      ],
    );
  }
}

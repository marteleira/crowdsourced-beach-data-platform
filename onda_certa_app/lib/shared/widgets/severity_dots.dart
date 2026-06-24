import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Row of [total] filled/empty circle dots — used for severity and vote indicators.
///
/// [filled] dots are rendered in [color]; the rest use [AppColors.borderLight].
class SeverityDotsIndicator extends StatelessWidget {
  const SeverityDotsIndicator({
    super.key,
    required this.filled,
    required this.color,
    this.total = 3,
    this.dotSize = 7.0,
    this.spacing = 3.0,
  });

  final int filled;
  final Color color;
  final int total;
  final double dotSize;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(total, (i) => Container(
        width: dotSize,
        height: dotSize,
        margin: EdgeInsets.only(right: spacing),
        decoration: BoxDecoration(
          color: i < filled ? color : AppColors.borderLight,
          shape: BoxShape.circle,
        ),
      )),
    );
  }
}

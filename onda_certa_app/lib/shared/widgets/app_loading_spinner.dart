import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Centered teal circular progress indicator — the standard loading state across the app.
class AppLoadingSpinner extends StatelessWidget {
  const AppLoadingSpinner({super.key, this.strokeWidth = 2.5});
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(
        color: AppColors.teal,
        strokeWidth: strokeWidth,
      ),
    );
  }
}

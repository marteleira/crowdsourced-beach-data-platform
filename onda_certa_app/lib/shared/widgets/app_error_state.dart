import 'package:flutter/material.dart';
import '../../core/constants/app_strings.dart';
import 'empty_state.dart';

/// Standard error state with optional retry button.
/// Wraps [EmptyState] so callers only need to supply a message.
class AppErrorState extends StatelessWidget {
  const AppErrorState({
    super.key,
    required this.message,
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.cloud_off_rounded,
      message: message,
      actionLabel: onRetry != null ? AppStrings.tryAgain : null,
      onAction: onRetry,
    );
  }
}

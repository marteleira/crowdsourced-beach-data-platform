import 'package:flutter/material.dart';
import '../../core/l10n/l10n.dart';
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
      actionLabel: onRetry != null ? context.l10n.tryAgain : null,
      onAction: onRetry,
    );
  }
}

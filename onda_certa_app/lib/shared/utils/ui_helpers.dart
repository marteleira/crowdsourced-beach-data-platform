library;

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Show a floating snackbar informing the user they must create an account.
void showGuestSnackbar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: AppColors.primary,
      behavior: SnackBarBehavior.floating,
    ),
  );
}

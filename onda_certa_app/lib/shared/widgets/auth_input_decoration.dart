import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

InputDecoration authInputDecoration({
  required String label,
  required String hint,
  required IconData icon,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
    suffixIcon: suffixIcon,
    labelStyle: const TextStyle(color: AppColors.textSecondary),
    hintStyle: const TextStyle(color: AppColors.textHint),
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: AppRadii.cardButton,
      borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.15)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: AppRadii.cardButton,
      borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.15)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: AppRadii.cardButton,
      borderSide: const BorderSide(color: AppColors.teal, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: AppRadii.cardButton,
      borderSide: const BorderSide(color: AppColors.coral),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: AppRadii.cardButton,
      borderSide: const BorderSide(color: AppColors.coral, width: 1.5),
    ),
  );
}

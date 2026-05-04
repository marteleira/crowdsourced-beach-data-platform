import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const primary = Color(0xFF0D2137);
  static const background = Color(0xFFF7F4EF);
  static const teal = Color(0xFF3ECFCF);
  static const tealDark = Color(0xFF1A8A8A);
  static const sand = Color(0xFFE8C98A);
  static const coral = Color(0xFFE86C50);

  static const flagGreen = Color(0xFF2ECC71);
  static const flagYellow = Color(0xFFF1C40F);
  static const flagRed = Color(0xFFE74C3C);
  static const flagPurple = Color(0xFF8B5CF6);

  static const textPrimary = Color(0xFF0D2137);
  static const textSecondary = Color(0xFF6B7280);
  static const textHint = Color(0xFF9CA3AF);
}

class AppTheme {
  static ThemeData get light {
    final base = GoogleFonts.interTextTheme();
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        surface: AppColors.background,
      ).copyWith(
        primary: AppColors.primary,
        surface: AppColors.background,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: base,
    );
  }
}

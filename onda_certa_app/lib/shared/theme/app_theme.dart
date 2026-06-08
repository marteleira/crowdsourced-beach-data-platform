import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const primary = Color(0xFF0D2137);
  static const primaryDark = Color(0xFF081C2E);
  static const background = Color(0xFFF7F4EF);
  static const teal = Color(0xFF3ECFCF);
  static const tealDark = Color(0xFF1A8A8A);
  static const sand = Color(0xFFE8C98A);
  static const coral = Color(0xFFE86C50);
  static const amber = Color(0xFFF59E0B);

  static const flagGreen = Color(0xFF2ECC71);
  static const flagYellow = Color(0xFFF1C40F);
  static const flagRed = Color(0xFFE74C3C);
  static const flagPurple = Color(0xFF8B5CF6);

  static const borderLight = Color(0xFFE5E7EB);
  static const borderMedium = Color(0xFFD1D5DB);
  static const backgroundLight = Color(0xFFF3F4F6);

  static const textPrimary = Color(0xFF0D2137);
  static const textSecondary = Color(0xFF6B7280);
  static const textHint = Color(0xFF9CA3AF);

  static Color forFlag(String flag) => switch (flag) {
    'green'  => flagGreen,
    'yellow' => flagYellow,
    'red'    => flagRed,
    'purple' => flagPurple,
    _        => textSecondary,
  };

  static LinearGradient beachGradient(String flag) => switch (flag) {
    'green'  => const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1A8A8A), Color(0xFF0D2137)]),
    'yellow' => const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF3ECFCF), Color(0xFF0D4A5A)]),
    'red'    => const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF8B1A1A), Color(0xFF0D2137)]),
    _        => const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1A5A8A), Color(0xFF0D2137)]),
  };
}

class AppTextStyles {
  // Secondary (gray) — subtitles, captions
  static const secondaryXs = TextStyle(fontSize: 10, color: AppColors.textSecondary);
  static const secondarySm = TextStyle(fontSize: 11, color: AppColors.textSecondary);
  static const secondary   = TextStyle(fontSize: 12, color: AppColors.textSecondary);
  static const secondaryMd = TextStyle(fontSize: 13, color: AppColors.textSecondary);
  static const secondaryLg = TextStyle(fontSize: 15, color: AppColors.textSecondary);

  // Hint (lighter gray) — placeholders, less important info
  static const hintXs = TextStyle(fontSize: 10, color: AppColors.textHint);
  static const hintSm = TextStyle(fontSize: 11, color: AppColors.textHint);
  static const hint   = TextStyle(fontSize: 12, color: AppColors.textHint);

  // Primary bold titles
  static const titleSm = TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primary);
  static const titleMd = TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary);
  static const titleLg = TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary);
  static const titleXl = TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.primary);

  // Primary non-bold
  static const primaryMd = TextStyle(fontSize: 15, color: AppColors.primary);
  static const subtitle   = TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.primary);

  // Teal accent
  static const tealLabel = TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.tealDark);

  // White small label
  static const whiteLabel = TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white);
}

class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
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

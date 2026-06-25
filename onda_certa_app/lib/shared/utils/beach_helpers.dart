import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../../core/constants/app_strings.dart';
import '../../features/beaches/domain/beach_models.dart';

// Short label for a flag color - used in pills, list items,...
String flagLabel(String flag) => switch (flag) {
  'green'  => AppStrings.flagLabelGreen,
  'yellow' => AppStrings.flagLabelYellow,
  'red'    => AppStrings.flagLabelRed,
  'purple' => AppStrings.flagLabelPurple,
  _        => AppStrings.flagLabelUnknown,
};

// Color + longer description for a flag - used in detail cards,...
(Color, String) flagInfo(String flag) => switch (flag) {
  'green'  => (AppColors.flagGreen,     AppStrings.flagDescGreen),
  'yellow' => (AppColors.flagYellow,    AppStrings.flagDescYellow),
  'red'    => (AppColors.flagRed,       AppStrings.flagDescRed),
  'purple' => (AppColors.flagPurple,    AppStrings.flagDescPurple),
  _        => (AppColors.textSecondary, AppStrings.flagDescUnknown),
};

// Short occupancy label, handles both 'medium' and 'normal' which different
// API endpoints use for the same mid-level state
String occupancyLabel(String level) => switch (level) {
  'low'                  => AppStrings.occupancyLow,
  'medium' || 'normal'   => AppStrings.occupancyMedium,
  'high'                 => AppStrings.occupancyHigh,
  _                      => '',
};

// Occupancy percentage + label + color for progress indicators.
// When maxCapacity is provided, uses real ratio, otherwise falls back to level enum
(double, String, Color) occupancyInfo(String level, int userCount, {int? maxCapacity}) {
  if (maxCapacity != null && maxCapacity > 0) {
    final pct = (userCount / maxCapacity).clamp(0.0, 1.0);
    final label = pct < 0.35 ? AppStrings.occupancyLow : pct < 0.70 ? AppStrings.occupancyAnimated : AppStrings.occupancyFull;
    final color = pct < 0.35 ? AppColors.flagGreen : pct < 0.70 ? AppColors.sand : AppColors.coral;
    return (pct, label, color);
  }
  return switch (level) {
    'low'                => (0.22, AppStrings.occupancyLow,      AppColors.flagGreen),
    'medium' || 'normal' => (0.55, AppStrings.occupancyAnimated, AppColors.sand),
    'high'               => (0.85, AppStrings.occupancyFull,     AppColors.coral),
    _                    => (0.0,  AppStrings.occupancyUnknown,  AppColors.textHint),
  };
}

// Water quality classification string (EN or PT from EEA) - color + PT label
(Color, String) waterQualityInfo(String? raw) => switch ((raw ?? '').toLowerCase()) {
  'excelente' || 'excellent'    => (AppColors.flagGreen,     AppStrings.qualityExcellent),
  'boa'       || 'good'         => (AppColors.teal,          AppStrings.qualityGood),
  'suficiente' || 'sufficient'  => (AppColors.flagYellow,    AppStrings.qualitySufficient),
  'má'        || 'poor'         => (AppColors.flagRed,       AppStrings.qualityPoor),
  _                              => (AppColors.textSecondary, AppStrings.qualityUnknown),
};

// Find the next upcoming tide extremum (first entry with time > now).
// Falls back to the last entry when all are in the past.
TideEntry? findNextTide(List<TideEntry> tides) {
  final nowMins = DateTime.now().hour * 60 + DateTime.now().minute;
  for (final t in tides) {
    final p = t.time.split(':');
    if (p.length == 2) {
      final tMins = (int.tryParse(p[0]) ?? 0) * 60 + (int.tryParse(p[1]) ?? 0);
      if (tMins > nowMins) return t;
    }
  }
  return tides.isNotEmpty ? tides.last : null;
}

// Tide type label for display. Default: 'alta'/'baixa'.
// capitalize: 'Alta'/'Baixa'. prefix: 'maré alta'/'maré baixa'.
String tideTypeLabel(String type, {bool capitalize = false, bool prefix = false}) {
  final String text;
  if (prefix) {
    text = type == 'alta' ? AppStrings.tidePrefixHigh : AppStrings.tidePrefixLow;
  } else {
    text = type == 'alta' ? AppStrings.tideHigh : AppStrings.tideLow;
  }
  return capitalize ? '${text[0].toUpperCase()}${text.substring(1)}' : text;
}

// Recommendation quality label based on flag + score - used in home screen cards
String beachQualityLabel(String flag, double? score) {
  if (flag == 'green' && (score ?? 0) > 0.7) return AppStrings.beachQualityExcellent;
  if (flag == 'green') return AppStrings.beachQualityGood;
  if (flag == 'yellow') return AppStrings.beachQualityFair;
  return AppStrings.beachQualityPoor;
}

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../../core/l10n/l10n.dart';
import '../../features/beaches/domain/beach_models.dart';

// Short label for a flag color - used in pills, list items,...
String flagLabel(AppLocalizations l10n, String flag) => switch (flag) {
  'green'  => l10n.flagLabelGreen,
  'yellow' => l10n.flagLabelYellow,
  'red'    => l10n.flagLabelRed,
  'purple' => l10n.flagLabelPurple,
  _        => l10n.flagLabelUnknown,
};

// Color + longer description for a flag - used in detail cards,...
(Color, String) flagInfo(AppLocalizations l10n, String flag) => switch (flag) {
  'green'  => (AppColors.flagGreen,     l10n.flagDescGreen),
  'yellow' => (AppColors.flagYellow,    l10n.flagDescYellow),
  'red'    => (AppColors.flagRed,       l10n.flagDescRed),
  'purple' => (AppColors.flagPurple,    l10n.flagDescPurple),
  _        => (AppColors.textSecondary, l10n.flagDescUnknown),
};

// Short occupancy label, handles both 'medium' and 'normal' which different
// API endpoints use for the same mid-level state
String occupancyLabel(AppLocalizations l10n, String level) => switch (level) {
  'low'                  => l10n.occupancyLow,
  'medium' || 'normal'   => l10n.occupancyMedium,
  'high'                 => l10n.occupancyHigh,
  _                      => '',
};

// Occupancy percentage + label + color for progress indicators.
// When maxCapacity is provided, uses real ratio, otherwise falls back to level enum
(double, String, Color) occupancyInfo(AppLocalizations l10n, String level, int userCount, {int? maxCapacity}) {
  if (maxCapacity != null && maxCapacity > 0) {
    final pct = (userCount / maxCapacity).clamp(0.0, 1.0);
    final label = pct < 0.35 ? l10n.occupancyLow : pct < 0.70 ? l10n.occupancyAnimated : l10n.occupancyFull;
    final color = pct < 0.35 ? AppColors.flagGreen : pct < 0.70 ? AppColors.sand : AppColors.coral;
    return (pct, label, color);
  }
  return switch (level) {
    'low'                => (0.22, l10n.occupancyLow,      AppColors.flagGreen),
    'medium' || 'normal' => (0.55, l10n.occupancyAnimated, AppColors.sand),
    'high'               => (0.85, l10n.occupancyFull,     AppColors.coral),
    _                    => (0.0,  l10n.occupancyUnknown,  AppColors.textHint),
  };
}

// Water quality classification string (EN or PT from EEA) - color + PT label
(Color, String) waterQualityInfo(AppLocalizations l10n, String? raw) => switch ((raw ?? '').toLowerCase()) {
  'excelente' || 'excellent'    => (AppColors.flagGreen,     l10n.qualityExcellent),
  'boa'       || 'good'         => (AppColors.teal,          l10n.qualityGood),
  'suficiente' || 'sufficient'  => (AppColors.flagYellow,    l10n.qualitySufficient),
  'má'        || 'poor'         => (AppColors.flagRed,       l10n.qualityPoor),
  _                              => (AppColors.textSecondary, l10n.qualityUnknown),
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
String tideTypeLabel(AppLocalizations l10n, String type, {bool capitalize = false, bool prefix = false}) {
  final String text;
  if (prefix) {
    text = type == 'alta' ? l10n.tidePrefixHigh : l10n.tidePrefixLow;
  } else {
    text = type == 'alta' ? l10n.tideHigh : l10n.tideLow;
  }
  return capitalize ? '${text[0].toUpperCase()}${text.substring(1)}' : text;
}

// Translate an activity_label key from the backend (e.g. "unverified") to a localized string.
// Returns null if the key is not recognized, so callers can skip display.
String? activityLabelText(AppLocalizations l10n, String? key) => switch (key) {
  'unverified' => l10n.activityLabelUnverified,
  _ => null,
};

// Recommendation quality label based on flag + score - used in home screen cards
String beachQualityLabel(AppLocalizations l10n, String flag, double? score) {
  if (flag == 'green' && (score ?? 0) > 0.7) return l10n.beachQualityExcellent;
  if (flag == 'green') return l10n.beachQualityGood;
  if (flag == 'yellow') return l10n.beachQualityFair;
  return l10n.beachQualityPoor;
}

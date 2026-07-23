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

// Short occupancy label - used in pills, list items,...
String occupancyLabel(AppLocalizations l10n, String level) => switch (level) {
  'low'    => l10n.occupancyLow,
  'medium' => l10n.occupancyMedium,
  'high'   => l10n.occupancyHigh,
  _        => '',
};

// EEA water quality code (1=excellent .. 4=poor) - color + localized label
(Color, String) waterQualityInfo(AppLocalizations l10n, int? code) => switch (code) {
  1 => (AppColors.flagGreen,     l10n.qualityExcellent),
  2 => (AppColors.teal,          l10n.qualityGood),
  3 => (AppColors.flagYellow,    l10n.qualitySufficient),
  4 => (AppColors.flagRed,       l10n.qualityPoor),
  _ => (AppColors.textSecondary, l10n.qualityUnknown),
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

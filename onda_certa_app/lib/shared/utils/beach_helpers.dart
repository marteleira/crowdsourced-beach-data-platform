import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// Short label for a flag color - used in pills, list items,...
String flagLabel(String flag) => switch (flag) {
  'green'  => 'Segura',
  'yellow' => 'Cuidado',
  'red'    => 'Perigo',
  'purple' => 'Fechada',
  _        => 'Desconhecida',
};

// Color + longer description for a flag - used in detail cards,...
(Color, String) flagInfo(String flag) => switch (flag) {
  'green'  => (AppColors.flagGreen,     'Segura para nadar'),
  'yellow' => (AppColors.flagYellow,    'Cuidado ao nadar'),
  'red'    => (AppColors.flagRed,       'Condições perigosas'),
  'purple' => (AppColors.flagPurple,    'Praia fechada'),
  _        => (AppColors.textSecondary, 'Estado desconhecido'),
};

// Short occupancy label, ithandles both 'medium' and 'normal' which different
// API endpoints use for the same mid-level state
String occupancyLabel(String level) => switch (level) {
  'low'                  => 'Tranquila',
  'medium' || 'normal'   => 'Moderada',
  'high'                 => 'Lotada',
  _                      => '',
};

// Occupancy percentage + label + color for progress indicators.
// When maxCapacity is provided, uses real ratio, otherwise falls back to level enum
(double, String, Color) occupancyInfo(String level, int userCount, {int? maxCapacity}) {
  if (maxCapacity != null && maxCapacity > 0) {
    final pct = (userCount / maxCapacity).clamp(0.0, 1.0);
    final label = pct < 0.35 ? 'Tranquila' : pct < 0.70 ? 'Animada' : 'Cheia';
    final color = pct < 0.35 ? AppColors.flagGreen : pct < 0.70 ? AppColors.sand : AppColors.coral;
    return (pct, label, color);
  }
  return switch (level) {
    'low'                => (0.22, 'Tranquila',    AppColors.flagGreen),
    'medium' || 'normal' => (0.55, 'Animada',      AppColors.sand),
    'high'               => (0.85, 'Cheia',         AppColors.coral),
    _                    => (0.0,  'Desconhecida',  AppColors.textHint),
  };
}

// Water quality classification string (EN or PT from EEA) - color + PT label
(Color, String) waterQualityInfo(String? raw) => switch ((raw ?? '').toLowerCase()) {
  'excelente' || 'excellent'    => (AppColors.flagGreen,     'Excelente'),
  'boa'       || 'good'         => (AppColors.teal,          'Boa'),
  'suficiente' || 'sufficient'  => (AppColors.flagYellow,    'Suficiente'),
  'má'        || 'poor'         => (AppColors.flagRed,       'Má'),
  _                              => (AppColors.textSecondary, 'Desconhecida'),
};

// Recommendation quality label based on flag + score - used in home screen cards
String beachQualityLabel(String flag, double? score) {
  if (flag == 'green' && (score ?? 0) > 0.7) return 'Excellent';
  if (flag == 'green') return 'Good';
  if (flag == 'yellow') return 'Fair';
  return 'Poor';
}

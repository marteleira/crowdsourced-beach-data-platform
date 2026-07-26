import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../../core/l10n/l10n.dart';

// Consolidates what used to be four separate switch statements (label, icon,
// color, progress-bar thresholds) in profile_screen.dart, all keyed on the
// same reputation level code (new | regular | contributor | veteran, per
// app.services.reputation.reputation_level()) - one switch, one place to
// keep in sync with the backend instead of four.
({String label, IconData icon, Color color, String? next, int min, int max, int range})
    reputationLevelMeta(AppLocalizations l10n, String level) => switch (level) {
  'new' => (
    label: l10n.levelNew, icon: Icons.water_outlined, color: AppColors.textHint,
    next: l10n.levelRegular, min: 0, max: 10, range: 10,
  ),
  'regular' => (
    label: l10n.levelRegular, icon: Icons.beach_access, color: AppColors.teal,
    next: l10n.levelContributor, min: 10, max: 50, range: 40,
  ),
  'contributor' => (
    label: l10n.levelContributor, icon: Icons.waves, color: AppColors.sand,
    next: l10n.levelVeteran, min: 50, max: 150, range: 100,
  ),
  'veteran' => (
    label: l10n.levelVeteran, icon: Icons.surfing, color: AppColors.amber,
    next: null, min: 150, max: 150, range: 0,
  ),
  _ => (
    label: l10n.levelNew, icon: Icons.water_outlined, color: AppColors.textHint,
    next: l10n.levelRegular, min: 0, max: 10, range: 10,
  ),
};

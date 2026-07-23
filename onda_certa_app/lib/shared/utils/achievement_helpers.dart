import '../../core/l10n/l10n.dart';

// id is the only source of truth from the backend (app/services/achievements.py
// ALL_ACHIEVEMENTS) - ARB text is the only source of truth for display. Keep
// this in sync when a new achievement id is added on the backend.
String achievementLabel(AppLocalizations l10n, String id) => switch (id) {
  'first_report' => l10n.achievementFirstReport,
  'tide_watcher' => l10n.achievementTideWatcher,
  '10_reports'   => l10n.achievement10Reports,
  'accurate'     => l10n.achievementAccurate,
  'streak_10'    => l10n.achievementStreak10,
  'regular'      => l10n.achievementRegular,
  'contributor'  => l10n.achievementContributor,
  'veteran'      => l10n.achievementVeteran,
  _ => id,
};

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/format_helpers.dart';
import '../widgets/severity_dots.dart';
import '../../core/l10n/l10n.dart';
import '../../features/beaches/domain/beach_models.dart';

(IconData, Color, String) alertMeta(AppLocalizations l10n, String type) {
  switch (type) {
    case 'jellyfish':       return (Icons.bubble_chart,   AppColors.waterIcon, l10n.alertTypeJellyfish);
    case 'strong_current':  return (Icons.electric_bolt,  AppColors.uvIcon,    l10n.alertTypeStrongCurrent);
    case 'pollution':       return (Icons.delete_outline,  const Color(0xFF10B981), l10n.alertTypePollution);
    case 'rough_sea':       return (Icons.waves,           AppColors.teal,          l10n.alertTypeRoughSea);
    default:                return (Icons.warning_amber,   AppColors.textSecondary, l10n.alertTypeDefault);
  }
}

(Color, String) severityMeta(AppLocalizations l10n, int? severity) => switch (severity) {
  1 => (AppColors.flagGreen,  l10n.severityLow),
  2 => (AppColors.flagYellow, l10n.severityModerate),
  3 => (AppColors.flagRed,    l10n.severityHigh),
  _ => (AppColors.textHint,   ''),
};

/// Reusable alert row — default trailing is the coral ··· icon.
/// Pass a custom [trailing] widget to override (e.g. vote dots on detail screen).
class AlertItem extends StatelessWidget {
  const AlertItem({super.key, required this.report, this.trailing});
  final BeachReport report;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (icon, typeColor, label) = alertMeta(l10n, report.type);
    final (sevColor, sevLabel) = severityMeta(l10n, report.severity);
    final ago = timeAgoFromString(l10n, report.createdAt);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadii.cardMd,
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: ClipRRect(
        borderRadius: AppRadii.cardMd,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Severity accent bar on the left
              Container(width: 4, color: sevColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                  child: Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: typeColor.withValues(alpha: 0.12),
                          borderRadius: AppRadii.cardMd,
                        ),
                        child: Icon(icon, color: typeColor, size: 20),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(label,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: AppColors.primary)),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                SeverityDotsIndicator(
                                  filled: report.severity ?? 0,
                                  color: sevColor,
                                  dotSize: 6,
                                  spacing: 2,
                                ),
                                if (sevLabel.isNotEmpty) ...[
                                  const SizedBox(width: AppSpacing.xs),
                                  Text(sevLabel,
                                      style: TextStyle(
                                          color: sevColor,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(width: 6),
                                  const Text('·',
                                      style: TextStyle(
                                          color: AppColors.textHint, fontSize: 11)),
                                  const SizedBox(width: 6),
                                ],
                                Expanded(
                                  child: Text(
                                    '${report.beachName != null ? "em ${report.beachName}" : ""} · $ago',
                                    style: const TextStyle(
                                        color: AppColors.textSecondary, fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      trailing ??
                          Icon(Icons.more_horiz,
                              color: AppColors.coral.withValues(alpha: 0.7)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

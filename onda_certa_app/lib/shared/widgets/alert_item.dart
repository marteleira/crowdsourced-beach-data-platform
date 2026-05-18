import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../../features/beaches/domain/beach_models.dart';

(IconData, Color, String) alertMeta(String type) {
  switch (type) {
    case 'jellyfish':       return (Icons.bubble_chart,   const Color(0xFF3B82F6), 'Medusas');
    case 'strong_current':  return (Icons.electric_bolt,  const Color(0xFFF59E0B), 'Corrente Forte');
    case 'pollution':       return (Icons.delete_outline,  const Color(0xFF10B981), 'Poluição');
    case 'rough_sea':       return (Icons.waves,           AppColors.teal,          'Mar Agitado');
    default:                return (Icons.warning_amber,   AppColors.textSecondary, 'Alerta');
  }
}

(Color, String) severityMeta(int? severity) => switch (severity) {
  1 => (AppColors.flagGreen,  'Baixo'),
  2 => (AppColors.flagYellow, 'Moderado'),
  3 => (AppColors.flagRed,    'Grave'),
  _ => (AppColors.textHint,   ''),
};

String timeAgo(String createdAt) {
  try {
    final dt = DateTime.parse(createdAt);
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24)   return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  } catch (_) {
    return '';
  }
}

/// Reusable alert row — default trailing is the coral ··· icon.
/// Pass a custom [trailing] widget to override (e.g. vote dots on detail screen).
class AlertItem extends StatelessWidget {
  const AlertItem({super.key, required this.report, this.trailing});
  final BeachReport report;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final (icon, typeColor, label) = alertMeta(report.type);
    final (sevColor, sevLabel) = severityMeta(report.severity);
    final ago = timeAgo(report.createdAt);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
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
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: typeColor, size: 20),
                      ),
                      const SizedBox(width: 12),
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
                                // Severity dots
                                ...List.generate(3, (i) => Container(
                                  width: 6, height: 6,
                                  margin: const EdgeInsets.only(right: 2),
                                  decoration: BoxDecoration(
                                    color: i < (report.severity ?? 0)
                                        ? sevColor
                                        : const Color(0xFFE5E7EB),
                                    shape: BoxShape.circle,
                                  ),
                                )),
                                if (sevLabel.isNotEmpty) ...[
                                  const SizedBox(width: 4),
                                  Text(sevLabel,
                                      style: TextStyle(
                                          color: sevColor,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(width: 6),
                                  Text('·',
                                      style: const TextStyle(
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
                      const SizedBox(width: 8),
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

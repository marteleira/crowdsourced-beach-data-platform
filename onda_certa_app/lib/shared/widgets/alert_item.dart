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
    final (icon, color, label) = alertMeta(report.type);
    final ago = timeAgo(report.createdAt);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.primary)),
                Text(
                  '${report.beachName != null ? "em ${report.beachName}" : ""} · $ago',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          trailing ?? Icon(Icons.more_horiz, color: AppColors.coral.withValues(alpha: 0.7)),
        ],
      ),
    );
  }
}

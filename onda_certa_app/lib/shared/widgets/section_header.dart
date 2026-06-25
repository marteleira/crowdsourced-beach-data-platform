import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Section header row: icon + ALL-CAPS label + optional badge count + optional trailing link.
///
/// Used for "FAVORITAS", "ALERTAS ACTIVOS", "MARÉS · BEACH", etc.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.label,
    this.icon,
    this.iconColor,
    this.badgeCount,
    this.badgeColor,
    this.trailingLabel,
    this.onTrailingTap,
  });

  final String label;
  final IconData? icon;
  final Color? iconColor;
  /// If non-null, shows a small coloured count chip next to the label.
  final int? badgeCount;
  final Color? badgeColor;
  /// Label for the trailing tappable link (e.g. "Ver tudo →").
  final String? trailingLabel;
  final VoidCallback? onTrailingTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, color: iconColor ?? AppColors.textSecondary, size: 16),
          const SizedBox(width: 6),
        ],
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 0.8,
          ),
        ),
        if (badgeCount != null && badgeCount! > 0) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: badgeColor ?? AppColors.coral,
              borderRadius: AppRadii.cardChip,
            ),
            child: Text('$badgeCount', style: AppTextStyles.whiteLabel),
          ),
        ],
        const Spacer(),
        if (trailingLabel != null && onTrailingTap != null)
          GestureDetector(
            onTap: onTrailingTap,
            child: Text(trailingLabel!, style: AppTextStyles.tealLabel),
          ),
      ],
    );
  }
}

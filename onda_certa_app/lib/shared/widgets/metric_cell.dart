import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MetricCell extends StatelessWidget {
  const MetricCell({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.iconColor,
    this.subLabel,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color iconColor;
  final String? subLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(height: 6),
        Text(value, style: AppTextStyles.titleMd),
        if (subLabel != null)
          Text(subLabel!, style: AppTextStyles.secondarySm.copyWith(fontSize: 10)),
        Text(label, style: AppTextStyles.secondarySm),
      ],
    );
  }
}

// Lays out MetricCells horizontally with a thin divider between each.
Widget metricRow(List<Widget> cells) {
  final items = <Widget>[];
  for (int i = 0; i < cells.length; i++) {
    if (i > 0) items.add(Container(width: 1, height: 40, color: AppColors.borderLight));
    items.add(Expanded(child: Center(child: cells[i])));
  }
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 14),
    decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
    child: Row(children: items),
  );
}

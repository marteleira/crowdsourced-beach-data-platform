import 'package:flutter/material.dart';

/// Circular dark-tinted icon button used over hero images (beach detail app bar).
class OverlayIconButton extends StatelessWidget {
  const OverlayIconButton({
    super.key,
    this.onTap,
    required this.icon,
    this.iconColor = Colors.white,
    this.iconSize = 20.0,
    this.size = 36.0,
  });

  final VoidCallback? onTap;
  final IconData icon;
  final Color iconColor;
  final double iconSize;
  final double size;

  @override
  Widget build(BuildContext context) {
    final inner = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: iconColor, size: iconSize),
    );
    if (onTap == null) return inner;
    return GestureDetector(onTap: onTap, child: inner);
  }
}

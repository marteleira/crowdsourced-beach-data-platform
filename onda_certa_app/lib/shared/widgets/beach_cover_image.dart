import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Renders the beach cover photo when a URL is available, otherwise falls back
/// to the flag-coloured gradient that was used before photos were introduced.
class BeachCoverImage extends StatelessWidget {
  const BeachCoverImage({
    super.key,
    required this.flagColor,
    this.photoUrl,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.dimOpacity = 0.30,
    this.child,
  });

  final String flagColor;
  final String? photoUrl;
  final double? height;
  final double? width;
  final BoxFit fit;

  /// Dark overlay applied on top of photos to improve text legibility.
  /// Set to 0.0 to disable. Has no effect when showing the gradient fallback.
  final double dimOpacity;

  /// Optional overlay content (scrim + text) rendered on top of everything.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: width ?? double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _background(),
          if (photoUrl != null && dimOpacity > 0)
            ColoredBox(color: Colors.black.withValues(alpha: dimOpacity)),
          ?child,
        ],
      ),
    );
  }

  Widget _background() {
    if (photoUrl != null) {
      return Image.network(
        photoUrl!,
        fit: fit,
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return _gradientFallback();
        },
        errorBuilder: (_, _, _) => _gradientFallback(),
      );
    }
    return _gradientFallback();
  }

  Widget _gradientFallback() => Container(
    decoration: BoxDecoration(gradient: AppColors.beachGradient(flagColor)),
  );
}

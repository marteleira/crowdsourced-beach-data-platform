import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/l10n/l10n.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/animated_waves.dart';

class _OnboardingSlide {
  const _OnboardingSlide({
    required this.icon,
    required this.title,
    required this.body,
  });
  final IconData icon;
  final String title;
  final String body;
}

/// Shown once, right after the splash screen, before the first login/home.
/// [destination] is where to go once the user finishes or skips (home if
/// already authenticated, login otherwise).
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key, required this.destination});
  final String destination;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<_OnboardingSlide> _slides(BuildContext context) {
    final l10n = context.l10n;
    return [
      _OnboardingSlide(
        icon: Icons.waves_rounded,
        title: l10n.onboardingTitle1,
        body: l10n.onboardingBody1,
      ),
      _OnboardingSlide(
        icon: Icons.campaign_rounded,
        title: l10n.onboardingTitle2,
        body: l10n.onboardingBody2,
      ),
      _OnboardingSlide(
        icon: Icons.favorite_rounded,
        title: l10n.onboardingTitle3,
        body: l10n.onboardingBody3,
      ),
    ];
  }

  Future<void> _finish() async {
    await ref.read(secureStorageProvider).setOnboardingSeen();
    if (!mounted) return;
    context.go(widget.destination);
  }

  void _next(int slideCount) {
    if (_page == slideCount - 1) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: AppDurations.medium,
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final slides = _slides(context);
    final isLast = _page == slides.length - 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            const AnimatedWaves(heightFraction: 0.32),
            Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.sm,
                    ),
                    child: Opacity(
                      opacity: isLast ? 0 : 1,
                      child: TextButton(
                        onPressed: isLast ? null : _finish,
                        child: Text(
                          context.l10n.onboardingSkip,
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: slides.length,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemBuilder: (context, i) => _SlideView(slide: slides[i]),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xxl,
                    vertical: AppSpacing.lg,
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          slides.length,
                          (i) => AnimatedContainer(
                            duration: AppDurations.medium,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: i == _page ? 22 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: i == _page ? AppColors.tealDark : AppColors.borderMedium,
                              borderRadius: AppRadii.cardChip,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _next(slides.length),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: AppRadii.cardButton),
                          ),
                          child: Text(
                            isLast ? context.l10n.onboardingStart : context.l10n.onboardingNext,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const _LegalLinksRow(),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});
  final _OnboardingSlide slide;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.tealDark.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(slide.icon, size: 56, color: AppColors.tealDark),
          ),
          const SizedBox(height: AppSpacing.xxxl),
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: AppTextStyles.titleXl.copyWith(fontSize: 24),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            slide.body,
            textAlign: TextAlign.center,
            style: AppTextStyles.secondaryLg.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _LegalLinksRow extends StatelessWidget {
  const _LegalLinksRow();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final style = TextStyle(fontSize: 12, color: AppColors.textHint);
    return Center(
      child: Text.rich(
        TextSpan(
          style: style,
          children: [
            TextSpan(
              text: l10n.termsOfService,
              recognizer: TapGestureRecognizer()
                ..onTap = () => context.push(AppRoutes.terms),
            ),
            TextSpan(text: l10n.legalLinksSeparator),
            TextSpan(
              text: l10n.privacyPolicy,
              recognizer: TapGestureRecognizer()
                ..onTap = () => context.push(AppRoutes.privacy),
            ),
          ],
        ),
      ),
    );
  }
}

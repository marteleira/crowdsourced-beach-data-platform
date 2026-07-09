import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_routes.dart';
import '../../core/l10n/l10n.dart';
import '../theme/app_theme.dart';

/// "By continuing, you accept our Terms of Service and Privacy Policy" —
/// shown wherever a user can create/authenticate an account (Google, guest,
/// or email registration) so consent is always in view before that happens.
class AuthConsentFooter extends StatelessWidget {
  const AuthConsentFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.textSecondary,
        );
    final linkStyle = style?.copyWith(
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    );

    final l10n = context.l10n;
    return Text.rich(
      TextSpan(
        text: l10n.authConsentPrefix,
        style: style,
        children: [
          TextSpan(
            text: l10n.termsOfService,
            style: linkStyle,
            recognizer: TapGestureRecognizer()
              ..onTap = () => context.push(AppRoutes.terms),
          ),
          TextSpan(text: l10n.authConsentJoiner),
          TextSpan(
            text: l10n.privacyPolicy,
            style: linkStyle,
            recognizer: TapGestureRecognizer()
              ..onTap = () => context.push(AppRoutes.privacy),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

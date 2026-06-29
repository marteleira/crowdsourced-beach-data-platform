import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/l10n/l10n.dart';
import '../../../shared/theme/app_theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _googleLoading = false;
  bool _guestLoading = false;

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<AuthState>>(authProvider, (_, next) {
      if (next case AsyncData(value: AuthAuthenticated())) {
        context.go(AppRoutes.home);
      }
      if (next case AsyncError(:final error)) {
        if (error is DioException && error.type == DioExceptionType.cancel) return;
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorSignIn)),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 3),
              _AppIcon(),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'OndaCerta',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 36,
                      letterSpacing: -0.5,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                context.l10n.appTagline,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w400,
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                context.l10n.appLocation,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const Spacer(flex: 4),
              _GoogleButton(
                loading: _googleLoading,
                onTap: _handleGoogleSignIn,
              ),
              const SizedBox(height: AppSpacing.md),
              _EmailButton(
                onTap: () => context.push(AppRoutes.loginEmail),
              ),
              const SizedBox(height: AppSpacing.xl),
              GestureDetector(
                onTap: _guestLoading ? null : _handleGuestSignIn,
                child: Center(
                  child: _guestLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          context.l10n.continueAsGuest,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                ),
              ),
              const Spacer(flex: 1),
              _Footer(),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _googleLoading = true);
    try {
      await GoogleSignIn.instance.signOut();
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.errorGoogleToken)),
          );
        }
        return;
      }
      await ref.read(authProvider.notifier).loginWithGoogle(idToken);
    } on GoogleSignInException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.description ?? context.l10n.errorGoogleSignIn)),
        );
      }
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  Future<void> _handleGuestSignIn() async {
    setState(() => _guestLoading = true);
    try {
      final deviceId = await _getDeviceId();
      await ref.read(authProvider.notifier).loginAsGuest(deviceId);
    } finally {
      if (mounted) setState(() => _guestLoading = false);
    }
  }

  Future<String> _getDeviceId() async {
    final info = DeviceInfoPlugin();
    try {
      final android = await info.androidInfo;
      return android.id;
    } catch (_) {
      try {
        final ios = await info.iosInfo;
        return ios.identifierForVendor ?? 'unknown';
      } catch (_) {
        return 'unknown-${DateTime.now().millisecondsSinceEpoch}';
      }
    }
  }
}

class _AppIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 120,
        height: 120,
        clipBehavior: Clip.antiAlias,
        decoration: const BoxDecoration(
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.all(Radius.circular(18))
        ),
        child: Image.asset(
          'assets/icon/icon.png',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.loading, required this.onTap});

  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.7),
          shape: const StadiumBorder(),
          elevation: 0,
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _GoogleGLogo(),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    context.l10n.signInGoogle,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _GoogleGLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Icon(Icons.g_mobiledata, size: 28);
  }
}

class _EmailButton extends StatelessWidget {
  const _EmailButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
          shape: const StadiumBorder(),
        ),
        child: Text(
          context.l10n.signInEmail,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
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
          const TextSpan(text: ' e\n'),
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

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_error.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/l10n/l10n.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/auth_consent_footer.dart';
import '../../../shared/widgets/auth_input_decoration.dart';
import '../../../shared/widgets/password_strength_field.dart';

class EmailLoginScreen extends ConsumerStatefulWidget {
  const EmailLoginScreen({super.key});

  @override
  ConsumerState<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends ConsumerState<EmailLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  bool _isRegister = false;
  bool _loading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    ref.listen<AsyncValue<AuthState>>(authProvider, (_, next) {
      if (next case AsyncData(value: AuthAuthenticated())) {
        context.go(AppRoutes.home);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.lg),
                Text(
                  _isRegister ? l10n.createAccount : l10n.signIn,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _isRegister ? l10n.registerSubtitle : l10n.loginWelcomeBack,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: AppSpacing.xxxl),
                if (_isRegister) ...[
                  TextFormField(
                    controller: _nameCtrl,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? l10n.emailNameEmpty : null,
                    style: const TextStyle(color: AppColors.primary),
                    decoration: authInputDecoration(
                      label: l10n.fieldName,
                      hint: l10n.fieldNameHint,
                      icon: Icons.person_outline,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return l10n.emailEmpty;
                    if (!v.contains('@')) return l10n.emailInvalidSimple;
                    return null;
                  },
                  style: const TextStyle(color: AppColors.primary),
                  decoration: authInputDecoration(
                    label: l10n.fieldEmail,
                    hint: l10n.fieldEmailHint,
                    icon: Icons.email_outlined,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                PasswordStrengthField(
                  controller: _passwordCtrl,
                  requireStrength: _isRegister,
                ),
                if (!_isRegister) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => context.push(
                        AppRoutes.forgotPassword,
                        extra: _emailCtrl.text.trim(),
                      ),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        l10n.forgotPassword,
                        style: const TextStyle(
                          color: AppColors.tealDark,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
                if (_errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _ErrorBanner(message: _errorMessage!),
                ],
                if (_isRegister) ...[
                  const SizedBox(height: AppSpacing.lg),
                  const AuthConsentFooter(),
                ],
                const SizedBox(height: 28),
                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          AppColors.primary.withValues(alpha: 0.7),
                      shape: const StadiumBorder(),
                      elevation: 0,
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            _isRegister ? l10n.createAccount : l10n.signIn,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                GestureDetector(
                  onTap: () => setState(() {
                    _isRegister = !_isRegister;
                    _errorMessage = null;
                  }),
                  child: Center(
                    child: Text.rich(
                      TextSpan(
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                        children: [
                          TextSpan(
                            text: _isRegister
                                ? l10n.emailAlreadyHaveAccount
                                : l10n.emailNoAccountYet,
                          ),
                          TextSpan(
                            text: _isRegister ? l10n.signIn : l10n.createAccount,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    final isRegister = _isRegister;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final repo = ref.read(authRepositoryProvider);
      final tokens = isRegister
          ? await repo.registerWithEmail(
              _emailCtrl.text.trim(),
              _passwordCtrl.text,
              _nameCtrl.text.trim(),
            )
          : await repo.loginWithEmail(
              _emailCtrl.text.trim(),
              _passwordCtrl.text,
            );
      await ref.read(authProvider.notifier).completeEmailAuth(tokens);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) return;
      if (!mounted) return;
      final status = e.response?.statusCode;
      final detail = e.response?.data?['detail'];

      if (status == 403 && detail is Map) {
        final code = detail['code'] as String?;
        if (code == 'account_banned') {
          ref.read(accountBannedProvider.notifier).set(detail['ban_reason'] as String?);
          return;
        }
        if (code == 'account_suspended') {
          final raw = detail['suspended_until'] as String?;
          if (raw != null) {
            ref.read(accountSuspendedProvider.notifier).set(DateTime.parse(raw));
          }
          return;
        }
      }

      final msg = parseApiError(e)?.message;

      if (status == 409) {
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.emailAlreadyRegisteredTitle),
            content: Text(msg ?? l10n.emailAlreadyRegisteredBody),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  setState(() => _isRegister = false);
                },
                child: Text(l10n.signIn),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l10n.close),
              ),
            ],
          ),
        );
      } else {
        setState(() => _errorMessage = msg ??
            (isRegister ? l10n.emailRegisterError : l10n.emailLoginError));
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = l10n.connectionError);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.coral.withValues(alpha: 0.1),
        borderRadius: AppRadii.cardMd,
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.coral, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.coral),
            ),
          ),
        ],
      ),
    );
  }
}

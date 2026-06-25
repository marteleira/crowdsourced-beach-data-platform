import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/constants/app_routes.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/auth_code_input.dart';
import '../../../shared/widgets/auth_input_decoration.dart';
import '../../../shared/widgets/password_strength_field.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, required this.email});

  final String email;

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  static const _resendCooldown = 30;

  // Step 0 = code entry, step 1 = new password, step 2 = success
  int _step = 0;
  String _code = '';

  final _codeKey = GlobalKey<AuthCodeInputState>();
  bool _codeComplete = false;

  final _formKey = GlobalKey<FormState>();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _loading = false;
  bool _resending = false;
  String? _errorMessage;
  int _cooldown = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _cooldown = _resendCooldown);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldown <= 1) {
        timer.cancel();
        setState(() => _cooldown = 0);
      } else {
        setState(() => _cooldown--);
      }
    });
  }

  Future<void> _resend() async {
    setState(() => _resending = true);
    try {
      await ref.read(authRepositoryProvider).forgotPassword(widget.email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Novo código enviado para o teu email.')),
        );
        _startCooldown();
      }
    } on DioException catch (e) {
      final detail = e.response?.data?['detail'];
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  detail is String ? detail : 'Erro ao reenviar o código.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro de ligação. Tenta novamente.')),
        );
      }
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  void _advanceToPassword() {
    setState(() {
      _code = _codeKey.currentState!.code;
      _step = 1;
      _errorMessage = null;
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      await ref.read(authRepositoryProvider).resetPassword(
            widget.email,
            _code,
            _passwordCtrl.text,
          );
      if (mounted) setState(() => _step = 2);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) return;
      final detail = e.response?.data?['detail'];
      final msg = detail is String ? detail : 'Erro ao alterar a password. Tenta novamente.';

      // Code-related errors → force back to step 0
      if (detail is String &&
          (detail.contains('Código') || detail.contains('expirado'))) {
        _codeKey.currentState?.clear();
        setState(() {
          _code = '';
          _codeComplete = false;
          _step = 0;
          _errorMessage = msg;
        });
      } else {
        setState(() => _errorMessage = msg);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Erro de ligação. Tenta novamente.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Handles Android back + AppBar back: step 1 → step 0 instead of exiting
  bool _onPop() {
    if (_step == 1) {
      setState(() {
        _step = 0;
        _errorMessage = null;
      });
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step != 1,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onPop();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: _step == 2
            ? null
            : AppBar(
                backgroundColor: AppColors.background,
                elevation: 0,
                scrolledUnderElevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.primary),
                  onPressed: () {
                    if (_step == 1) {
                      setState(() {
                        _step = 0;
                        _errorMessage = null;
                      });
                    } else {
                      context.pop();
                    }
                  },
                ),
              ),
        body: SafeArea(
          child: AnimatedSwitcher(
            duration: AppDurations.slow,
            transitionBuilder: (child, animation) {
              final offset = Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));
              return SlideTransition(position: offset, child: child);
            },
            child: switch (_step) {
              0 => _codeStep(key: const ValueKey(0)),
              1 => _passwordStep(key: const ValueKey(1)),
              _ => _successStep(key: const ValueKey(2)),
            },
          ),
        ),
      ),
    );
  }

  // code entry

  Widget _codeStep({required Key key}) {
    return SingleChildScrollView(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.lg),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.teal.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.mark_email_read_outlined,
              size: 36,
              color: AppColors.tealDark,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            'Verifica o teu email',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Enviámos um código de 6 dígitos para ${widget.email}.',
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: AppSpacing.xxxl),
          AuthCodeInput(
            key: _codeKey,
            enabled: !_loading,
            onChanged: (code) {
              setState(() {
                _codeComplete = code.length == 6;
                if (_errorMessage != null && code.isNotEmpty) _errorMessage = null;
              });
            },
          ),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: (_cooldown > 0 || _resending) ? null : _resend,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: _resending
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.textSecondary,
                      ),
                    )
                  : Text(
                      _cooldown > 0
                          ? 'Reenviar (${_cooldown}s)'
                          : 'Reenviar código',
                      style: TextStyle(
                        fontSize: 13,
                        color: _cooldown > 0 ? AppColors.textHint : AppColors.tealDark,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: AppSpacing.lg),
            _ErrorBanner(message: _errorMessage!),
          ],
          const SizedBox(height: 28),
          SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: _codeComplete ? _advanceToPassword : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
                shape: const StadiumBorder(),
                elevation: 0,
              ),
              child: const Text(
                'Continuar',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxxl),
        ],
      ),
    );
  }

  //  new password 

  Widget _passwordStep({required Key key}) {
    return SingleChildScrollView(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Nova password',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Escolhe uma nova password para a tua conta.',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
            const SizedBox(height: AppSpacing.xxxl),
            PasswordStrengthField(
              controller: _passwordCtrl,
              label: 'Nova password',
              requireStrength: true,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _confirmCtrl,
              obscureText: true,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Confirma a nova password';
                if (v != _passwordCtrl.text) return 'As passwords não coincidem';
                return null;
              },
              style: const TextStyle(color: AppColors.primary),
              decoration: authInputDecoration(
                label: 'Confirmar password',
                hint: '••••••••',
                icon: Icons.lock_outline,
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: AppSpacing.lg),
              _ErrorBanner(message: _errorMessage!),
            ],
            const SizedBox(height: 28),
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.7),
                  shape: const StadiumBorder(),
                  elevation: 0,
                ),
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Alterar password',
                        style:
                            TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),
    );
  }

  //  Step 2: success 

  Widget _successStep({required Key key}) {
    return Padding(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.flagGreen.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline,
                size: 44,
                color: AppColors.flagGreen,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            'Password alterada!',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'A tua password foi actualizada com sucesso.\nPodes entrar com a nova password.',
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xxxl),
          SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: () => context.go(AppRoutes.loginEmail),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                elevation: 0,
              ),
              child: const Text(
                'Entrar',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
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

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/auth_code_input.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen> {
  static const _resendCooldown = 30;

  final _codeKey = GlobalKey<AuthCodeInputState>();
  bool _codeComplete = false;
  bool _verifying = false;
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

  Future<void> _verify(String code) async {
    if (code.length != 6 || _verifying) return;
    setState(() {
      _verifying = true;
      _errorMessage = null;
    });
    try {
      await ref.read(authProvider.notifier).verifyEmail(code);
      if (mounted) context.go('/home');
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) return;
      final detail = e.response?.data?['detail'];
      _codeKey.currentState?.clear();
      setState(() {
        _codeComplete = false;
        _errorMessage = detail is String ? detail : 'Código inválido. Tenta de novo.';
      });
    } catch (_) {
      setState(() => _errorMessage = 'Erro de ligação. Tenta novamente.');
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _resend() async {
    setState(() => _resending = true);
    try {
      await ref.read(authProvider.notifier).resendVerification();
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
              content:
                  Text(detail is String ? detail : 'Erro ao reenviar o código.')),
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

  Future<void> _logout() async {
    await ref.read(authProvider.notifier).logout();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_read_outlined,
                  size: 40,
                  color: AppColors.tealDark,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'Confirma o teu email',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Enviámos um código de 6 dígitos para o teu email.\nIntroduz o código abaixo para continuares.',
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxxl),
              AuthCodeInput(
                key: _codeKey,
                enabled: !_verifying,
                onChanged: (code) {
                  setState(() {
                    _codeComplete = code.length == 6;
                    if (_errorMessage != null) _errorMessage = null;
                  });
                  if (code.length == 6) _verify(code);
                },
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: AppSpacing.lg),
                _errorBanner(context, _errorMessage!),
              ],
              const SizedBox(height: AppSpacing.xxl),
              SizedBox(
                height: 54,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_verifying || !_codeComplete)
                      ? null
                      : () => _verify(_codeKey.currentState!.code),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        AppColors.primary.withValues(alpha: 0.4),
                    shape: const StadiumBorder(),
                    elevation: 0,
                  ),
                  child: _verifying
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Verificar',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              TextButton(
                onPressed: (_cooldown > 0 || _resending) ? null : _resend,
                child: _resending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.textSecondary,
                        ),
                      )
                    : Text(
                        _cooldown > 0
                            ? 'Reenviar código (${_cooldown}s)'
                            : 'Reenviar código',
                        style: TextStyle(
                          color: _cooldown > 0
                              ? AppColors.textHint
                              : AppColors.tealDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
              const Spacer(flex: 2),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _verifying ? null : _logout,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    foregroundColor: AppColors.textSecondary,
                    side: BorderSide(
                      color: AppColors.textSecondary.withValues(alpha: 0.3),
                    ),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child:
                      const Text('Terminar sessão', style: TextStyle(fontSize: 15)),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _errorBanner(BuildContext context, String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.coral.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
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

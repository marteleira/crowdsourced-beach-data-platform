import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../shared/theme/app_theme.dart';

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
  bool _obscurePassword = true;
  bool _loading = false;
  String? _errorMessage;

  bool _pwHasLength = false;
  bool _pwHasUpper = false;
  bool _pwHasLower = false;
  bool _pwHasDigitOrSpecial = false;
  int get _pwScore =>
      [_pwHasLength, _pwHasUpper, _pwHasLower, _pwHasDigitOrSpecial]
          .where((b) => b)
          .length;

  @override
  void initState() {
    super.initState();
    _passwordCtrl.addListener(_updatePasswordStrength);
  }

  void _updatePasswordStrength() {
    final v = _passwordCtrl.text;
    setState(() {
      _pwHasLength = v.length >= 8;
      _pwHasUpper = v.contains(RegExp(r'[A-Z]'));
      _pwHasLower = v.contains(RegExp(r'[a-z]'));
      _pwHasDigitOrSpecial =
          v.contains(RegExp(r'[0-9]')) || v.contains(RegExp(r'[^A-Za-z0-9]'));
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<AuthState>>(authProvider, (_, next) {
      if (next case AsyncData(value: AuthAuthenticated())) {
        context.go('/home');
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
                  _isRegister ? 'Criar conta' : 'Entrar',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _isRegister
                      ? 'Regista-te para contribuíres com a comunidade'
                      : 'Bem-vindo de volta',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: AppSpacing.xxxl),
                if (_isRegister) ...[
                  _buildField(
                    controller: _nameCtrl,
                    label: 'Nome',
                    hint: 'O teu nome',
                    icon: Icons.person_outline,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Introduz o teu nome' : null,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                _buildField(
                  controller: _emailCtrl,
                  label: 'Email',
                  hint: 'o.teu@email.com',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Introduz o email';
                    if (!v.contains('@')) return 'Email inválido';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                _buildPasswordField(),
                if (_isRegister && _passwordCtrl.text.isNotEmpty)
                  _buildPasswordStrengthIndicator(),
                if (_errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.coral.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppColors.coral, size: 18),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.coral,
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),
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
                            _isRegister ? 'Criar conta' : 'Entrar',
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
                                ? 'Já tens conta? '
                                : 'Ainda não tens conta? ',
                          ),
                          TextSpan(
                            text: _isRegister ? 'Entrar' : 'Criar conta',
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

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: AppColors.primary),
      decoration: _inputDecoration(label: label, hint: hint, icon: icon),
    );
  }

  Widget _buildPasswordStrengthIndicator() {
    final score = _pwScore;
    final (label, barColor) = switch (score) {
      0 || 1 => ('Fraca', AppColors.coral),
      2 => ('Razoável', AppColors.amber),
      3 => ('Boa', AppColors.teal),
      _ => ('Forte', AppColors.flagGreen),
    };

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      child: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(end: score / 4),
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                      builder: (_, value, _) => LinearProgressIndicator(
                        value: value,
                        minHeight: 5,
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.08),
                        valueColor: AlwaysStoppedAnimation(barColor),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    label,
                    key: ValueKey(label),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: barColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _pwRequirement('8+ caracteres', _pwHasLength),
            _pwRequirement('Letra maiúscula (A–Z)', _pwHasUpper),
            _pwRequirement('Letra minúscula (a–z)', _pwHasLower),
            _pwRequirement('Número ou caractere especial', _pwHasDigitOrSpecial),
          ],
        ),
      ),
    );
  }

  Widget _pwRequirement(String label, bool met) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              met ? Icons.check_circle_outline : Icons.radio_button_unchecked,
              key: ValueKey(met),
              size: 14,
              color: met ? AppColors.teal : AppColors.textHint,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: met ? AppColors.teal : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordCtrl,
      obscureText: _obscurePassword,
      validator: (v) {
        if (v == null || v.isEmpty) return 'Introduz a password';
        if (_isRegister) {
          if (!_pwHasLength) return 'Mínimo 8 caracteres';
          if (!_pwHasUpper) return 'Precisa de uma letra maiúscula';
          if (!_pwHasLower) return 'Precisa de uma letra minúscula';
          if (!_pwHasDigitOrSpecial) return 'Precisa de um número ou caractere especial';
        }
        return null;
      },
      style: const TextStyle(color: AppColors.primary),
      decoration: _inputDecoration(
        label: 'Password',
        hint: '••••••••',
        icon: Icons.lock_outline,
      ).copyWith(
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: AppColors.textSecondary,
            size: 20,
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      hintStyle: const TextStyle(color: AppColors.textHint),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.teal, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.coral),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.coral, width: 1.5),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final repo = ref.read(authRepositoryProvider);
      final tokens = _isRegister
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
          if (raw != null) ref.read(accountSuspendedProvider.notifier).set(DateTime.parse(raw));
          return;
        }
      }

      final msg = detail is String ? detail : null;

      if (status == 409) {
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Email já registado'),
            content: Text(msg ?? 'Este email já tem uma conta. Entra com a tua password.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  setState(() => _isRegister = false);
                },
                child: const Text('Entrar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Fechar'),
              ),
            ],
          ),
        );
      } else {
        setState(() => _errorMessage = msg ??
            (_isRegister
                ? 'Erro ao criar conta. Verifica os dados.'
                : 'Email ou password incorrectos.'));
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Erro de ligação. Tenta novamente.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

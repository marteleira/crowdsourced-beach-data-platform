import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_provider.dart';
import '../../../features/beaches/data/beach_provider.dart';
import '../../../features/beaches/data/beach_repository.dart';
import '../../../features/beaches/domain/beach_models.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/auth_input_decoration.dart';
import '../../../shared/widgets/password_strength_field.dart';

class AccountSettingsScreen extends ConsumerWidget {
  const AccountSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: const Text('Conta', style: AppTextStyles.subtitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.primary),
          onPressed: () => context.pop(),
        ),
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.teal)),
        error: (_, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Não foi possível carregar o perfil',
                  style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: () => ref.invalidate(userProfileProvider),
                style: FilledButton.styleFrom(backgroundColor: AppColors.teal),
                child: const Text('Tentar de novo'),
              ),
            ],
          ),
        ),
        data: (profile) {
          if (profile == null) {
            return Center(
              child: FilledButton(
                onPressed: () => ref.invalidate(userProfileProvider),
                style: FilledButton.styleFrom(backgroundColor: AppColors.teal),
                child: const Text('Tentar de novo'),
              ),
            );
          }
          return _AccountForm(profile: profile);
        },
      ),
    );
  }
}

class _AccountForm extends ConsumerStatefulWidget {
  const _AccountForm({required this.profile});
  final UserProfile profile;

  @override
  ConsumerState<_AccountForm> createState() => _AccountFormState();
}

class _AccountFormState extends ConsumerState<_AccountForm> {
  final _nameKey = GlobalKey<FormState>();
  final _emailKey = GlobalKey<FormState>();
  final _passwordKey = GlobalKey<FormState>();

  late final _nameCtrl = TextEditingController(text: widget.profile.displayName ?? '');
  late final _emailCtrl = TextEditingController(text: widget.profile.email ?? '');
  final _emailPasswordCtrl = TextEditingController();
  final _currentPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  bool _nameBusy = false;
  bool _emailBusy = false;
  bool _passwordBusy = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _emailPasswordCtrl.dispose();
    _currentPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  BeachRepository get _repo => ref.read(beachRepositoryProvider);

  String? _extractError(Object e) {
    if (e is DioException) {
      final detail = e.response?.data;
      if (detail is Map) return detail['detail'] as String?;
      if (detail is String) return detail;
    }
    return 'Ocorreu um erro inesperado';
  }

  Future<void> _saveIdentity() async {
    if (!(_nameKey.currentState?.validate() ?? false)) return;
    final name = _nameCtrl.text.trim();

    if (name == (widget.profile.displayName ?? '')) {
      _showInfo('Nenhuma alteração para guardar');
      return;
    }

    setState(() => _nameBusy = true);
    try {
      await _repo.updateProfile(displayName: name);
      ref.invalidate(userProfileProvider);
      _showSuccess('Perfil atualizado com sucesso');
    } catch (e) {
      _showError(_extractError(e) ?? 'Não foi possível atualizar o perfil');
    } finally {
      if (mounted) setState(() => _nameBusy = false);
    }
  }

  Future<void> _saveEmail() async {
    if (!(_emailKey.currentState?.validate() ?? false)) return;
    final newEmail = _emailCtrl.text.trim();
    if (newEmail == widget.profile.email) {
      _showInfo('O email não foi alterado');
      return;
    }

    setState(() => _emailBusy = true);
    try {
      await _repo.updateProfile(
        email: newEmail,
        currentPassword: _emailPasswordCtrl.text,
      );
      // Refresh JWT so is_email_verified=false triggers /verify-email redirect
      await ref.read(authProvider.notifier).refreshSession();
      ref.invalidate(userProfileProvider);
      // Router redirect to /verify-email happens automatically via authProvider
    } catch (e) {
      if (mounted) _showError(_extractError(e) ?? 'Não foi possível alterar o email');
    } finally {
      if (mounted) setState(() => _emailBusy = false);
    }
  }

  Future<void> _savePassword() async {
    if (!(_passwordKey.currentState?.validate() ?? false)) return;

    setState(() => _passwordBusy = true);
    try {
      await _repo.changePassword(
        currentPassword: _currentPasswordCtrl.text,
        newPassword: _newPasswordCtrl.text,
      );
      _currentPasswordCtrl.clear();
      _newPasswordCtrl.clear();
      _confirmPasswordCtrl.clear();
      _showSuccess('Password alterada. Inicia sessão novamente nos outros dispositivos.');
    } catch (e) {
      _showError(_extractError(e) ?? 'Não foi possível alterar a password');
    } finally {
      if (mounted) setState(() => _passwordBusy = false);
    }
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.flagGreen,
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.coral,
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _showInfo(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final canChangeEmail = profile.hasPassword && !profile.isAnonymous;
    final canChangePassword = profile.hasPassword && !profile.isAnonymous;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
      children: [
        // Informação pessoal
        _SectionHeader(title: 'Informação Pessoal', icon: Icons.person_outline_rounded),
        _Card(
          child: Form(
            key: _nameKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  style: const TextStyle(color: AppColors.primary),
                  validator: (v) {
                    final s = (v ?? '').trim();
                    if (s.isEmpty) return 'O nome não pode estar vazio';
                    if (s.length > 50) return 'Máximo 50 caracteres';
                    return null;
                  },
                  decoration: authInputDecoration(
                    label: 'Nome',
                    hint: 'O teu nome',
                    icon: Icons.badge_outlined,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _SaveButton(
                  label: 'Guardar nome',
                  busy: _nameBusy,
                  onPressed: _saveIdentity,
                ),
              ],
            ),
          ),
        ),

        // Email
        _SectionHeader(title: 'Email', icon: Icons.email_outlined),
        if (!canChangeEmail)
          _InfoBanner(
            message: profile.isAnonymous
                ? 'Os convidados não têm email associado.'
                : 'A tua conta Google não permite alterar o email aqui.',
          )
        else
          _Card(
            child: Form(
              key: _emailKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _emailCtrl,
                    style: const TextStyle(color: AppColors.primary),
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    validator: (v) {
                      if ((v ?? '').trim().isEmpty) return 'Introduz um email';
                      final re = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                      if (!re.hasMatch(v!.trim())) return 'Email inválido';
                      return null;
                    },
                    decoration: authInputDecoration(
                      label: 'Novo email',
                      hint: 'novo@exemplo.com',
                      icon: Icons.email_outlined,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'A verificação será enviada para o novo email.',
                    style: AppTextStyles.secondary,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _ObscuredField(
                    controller: _emailPasswordCtrl,
                    label: 'Password atual (confirmação)',
                    hint: '••••••••',
                    icon: Icons.lock_outline_rounded,
                    validator: (v) =>
                        (v ?? '').isEmpty ? 'Introduz a password atual' : null,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _SaveButton(
                    label: 'Alterar email',
                    busy: _emailBusy,
                    onPressed: _saveEmail,
                  ),
                ],
              ),
            ),
          ),

        // Password
        _SectionHeader(title: 'Password', icon: Icons.lock_outline_rounded),
        if (!canChangePassword)
          _InfoBanner(
            message: profile.isAnonymous
                ? 'Os convidados não têm password.'
                : 'A tua conta Google não usa password.',
          )
        else
          _Card(
            child: Form(
              key: _passwordKey,
              child: Column(
                children: [
                  _ObscuredField(
                    controller: _currentPasswordCtrl,
                    label: 'Password atual',
                    hint: '••••••••',
                    icon: Icons.lock_outline_rounded,
                    validator: (v) =>
                        (v ?? '').isEmpty ? 'Introduz a password atual' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  PasswordStrengthField(
                    controller: _newPasswordCtrl,
                    label: 'Nova password',
                    hint: '••••••••',
                    requireStrength: true,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _ObscuredField(
                    controller: _confirmPasswordCtrl,
                    label: 'Confirmar nova password',
                    hint: '••••••••',
                    icon: Icons.lock_outline_rounded,
                    validator: (v) {
                      if ((v ?? '').isEmpty) return 'Confirma a nova password';
                      if (v != _newPasswordCtrl.text) return 'As passwords não coincidem';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _SaveButton(
                    label: 'Alterar password',
                    busy: _passwordBusy,
                    onPressed: _savePassword,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// Small private widgets

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: AppTextStyles.secondary),
          ),
        ],
      ),
    );
  }
}

class _ObscuredField extends StatefulWidget {
  const _ObscuredField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.validator,
  });
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final FormFieldValidator<String>? validator;

  @override
  State<_ObscuredField> createState() => _ObscuredFieldState();
}

class _ObscuredFieldState extends State<_ObscuredField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscure,
      validator: widget.validator,
      style: const TextStyle(color: AppColors.primary),
      decoration: authInputDecoration(
        label: widget.label,
        hint: widget.hint,
        icon: widget.icon,
        suffixIcon: IconButton(
          icon: Icon(
            _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: AppColors.textSecondary,
            size: 20,
          ),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.label, required this.busy, required this.onPressed});
  final String label;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: busy ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.teal,
          disabledBackgroundColor: AppColors.teal.withValues(alpha: 0.5),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: busy
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
      ),
    );
  }
}

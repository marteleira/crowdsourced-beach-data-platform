import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_error.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../features/beaches/data/beach_provider.dart';
import '../../../features/beaches/data/beach_repository.dart';
import '../../../features/beaches/domain/beach_models.dart';
import '../../../core/l10n/l10n.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/auth_input_decoration.dart';
import '../../../shared/widgets/password_strength_field.dart';
import '../../../shared/widgets/user_avatar.dart';

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
        title: Text(context.l10n.accountTitle, style: AppTextStyles.subtitle),
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
              Text(context.l10n.errorLoadProfile,
                  style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: () => ref.invalidate(userProfileProvider),
                style: FilledButton.styleFrom(backgroundColor: AppColors.teal),
                child: Text(context.l10n.tryAgain),
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
                child: Text(context.l10n.tryAgain),
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
  bool _avatarBusy = false;

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

  String _initials(String name) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (parts.isNotEmpty && parts[0].isNotEmpty) return parts[0][0].toUpperCase();
    return '?';
  }

  Future<void> _showAvatarPicker(BuildContext context, String? currentId) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AvatarPickerSheet(
        currentId: currentId,
        onSelect: (id) async {
          if (context.mounted) Navigator.pop(context);
          await _saveAvatar(id);
        },
      ),
    );
  }

  String? _extractDioError(Object e) {
    if (e is! DioException) return null;
    final apiError = parseApiError(e);
    return displayMessage(context.l10n, apiError) ?? apiError?.message;
  }

  Future<void> _saveAvatar(String? id) async {
    final l10n = context.l10n;
    final successMsg = l10n.accountAvatarUpdated;
    final errorMsg = l10n.accountAvatarUpdateError;
    setState(() => _avatarBusy = true);
    try {
      await _repo.updateProfile(avatarId: id ?? 'default');
      ref.invalidate(userProfileProvider);
      _showSuccess(successMsg);
    } catch (e) {
      _showError(_extractDioError(e) ?? errorMsg);
    } finally {
      if (mounted) setState(() => _avatarBusy = false);
    }
  }

  Future<void> _saveIdentity() async {
    final l10n = context.l10n;
    if (!(_nameKey.currentState?.validate() ?? false)) return;
    final name = _nameCtrl.text.trim();
    if (name == (widget.profile.displayName ?? '')) {
      _showInfo(l10n.accountNoChanges);
      return;
    }
    final successMsg = l10n.accountProfileUpdated;
    final errorMsg = l10n.accountProfileUpdateError;
    setState(() => _nameBusy = true);
    try {
      await _repo.updateProfile(displayName: name);
      ref.invalidate(userProfileProvider);
      _showSuccess(successMsg);
    } catch (e) {
      _showError(_extractDioError(e) ?? errorMsg);
    } finally {
      if (mounted) setState(() => _nameBusy = false);
    }
  }

  Future<void> _saveEmail() async {
    final l10n = context.l10n;
    if (!(_emailKey.currentState?.validate() ?? false)) return;
    final newEmail = _emailCtrl.text.trim();
    if (newEmail == widget.profile.email) {
      _showInfo(l10n.accountEmailUnchanged);
      return;
    }
    final errorMsg = l10n.accountProfileUpdateError;
    setState(() => _emailBusy = true);
    try {
      await _repo.updateProfile(
        email: newEmail,
        currentPassword: _emailPasswordCtrl.text,
      );
      await ref.read(authProvider.notifier).refreshSession();
      ref.invalidate(userProfileProvider);
    } catch (e) {
      if (mounted) _showError(_extractDioError(e) ?? errorMsg);
    } finally {
      if (mounted) setState(() => _emailBusy = false);
    }
  }

  Future<void> _savePassword() async {
    final l10n = context.l10n;
    if (!(_passwordKey.currentState?.validate() ?? false)) return;
    final successMsg = l10n.accountPasswordChanged;
    final errorMsg = l10n.accountPasswordChangeError;
    setState(() => _passwordBusy = true);
    try {
      await _repo.changePassword(
        currentPassword: _currentPasswordCtrl.text,
        newPassword: _newPasswordCtrl.text,
      );
      _currentPasswordCtrl.clear();
      _newPasswordCtrl.clear();
      _confirmPasswordCtrl.clear();
      _showSuccess(successMsg);
    } catch (e) {
      _showError(_extractDioError(e) ?? errorMsg);
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
    final currentAvatarId = widget.profile.avatarId;

    final l10n = context.l10n;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
      children: [
        _SectionHeader(title: l10n.accountAvatarSection, icon: Icons.face_outlined),
        _Card(
          child: Column(
            children: [
              UserAvatarWidget(
                size: 80,
                avatarId: currentAvatarId,
                initials: _initials(profile.displayName ?? '?'),
                showGlow: true,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                currentAvatarId == null
                    ? l10n.accountAvatarDefault
                    : (avatarById(currentAvatarId)?.label ?? currentAvatarId),
                style: AppTextStyles.secondary,
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _avatarBusy ? null : () => _showAvatarPicker(context, currentAvatarId),
                  icon: const Icon(Icons.grid_view_rounded, size: 18),
                  label: Text(l10n.accountAvatarChoose),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.teal,
                    side: BorderSide(color: AppColors.teal.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: AppRadii.cardMd),
                  ),
                ),
              ),
            ],
          ),
        ),

        _SectionHeader(title: l10n.accountPersonalSection, icon: Icons.person_outline_rounded),
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
                    if (s.isEmpty) return l10n.accountNameEmpty;
                    if (s.length > 50) return l10n.accountNameTooLong;
                    return null;
                  },
                  decoration: authInputDecoration(
                    label: l10n.fieldName,
                    hint: l10n.fieldNameHint,
                    icon: Icons.badge_outlined,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _SaveButton(
                  label: l10n.accountSaveName,
                  busy: _nameBusy,
                  onPressed: _saveIdentity,
                ),
              ],
            ),
          ),
        ),

        _SectionHeader(title: l10n.accountEmailSection, icon: Icons.email_outlined),
        if (!canChangeEmail)
          _InfoBanner(
            message: profile.isAnonymous
                ? l10n.accountEmailNoGuest
                : l10n.accountEmailNoGoogle,
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
                      if ((v ?? '').trim().isEmpty) return l10n.accountEmailEmpty;
                      final re = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                      if (!re.hasMatch(v!.trim())) return l10n.accountEmailInvalid;
                      return null;
                    },
                    decoration: authInputDecoration(
                      label: l10n.accountNewEmail,
                      hint: l10n.accountNewEmailHint,
                      icon: Icons.email_outlined,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(l10n.accountEmailVerificationNote, style: AppTextStyles.secondary),
                  const SizedBox(height: AppSpacing.md),
                  _ObscuredField(
                    controller: _emailPasswordCtrl,
                    label: l10n.accountCurrentPasswordConfirm,
                    hint: l10n.accountPasswordHint,
                    icon: Icons.lock_outline_rounded,
                    validator: (v) =>
                        (v ?? '').isEmpty ? l10n.accountCurrentPasswordEmpty : null,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _SaveButton(
                    label: l10n.accountChangeEmail,
                    busy: _emailBusy,
                    onPressed: _saveEmail,
                  ),
                ],
              ),
            ),
          ),

        _SectionHeader(title: l10n.accountPasswordSection, icon: Icons.lock_outline_rounded),
        if (!canChangePassword)
          _InfoBanner(
            message: profile.isAnonymous
                ? l10n.accountPasswordNoGuest
                : l10n.accountPasswordNoGoogle,
          )
        else
          _Card(
            child: Form(
              key: _passwordKey,
              child: Column(
                children: [
                  _ObscuredField(
                    controller: _currentPasswordCtrl,
                    label: l10n.accountCurrentPassword,
                    hint: l10n.accountPasswordHint,
                    icon: Icons.lock_outline_rounded,
                    validator: (v) =>
                        (v ?? '').isEmpty ? l10n.accountCurrentPasswordEmpty : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  PasswordStrengthField(
                    controller: _newPasswordCtrl,
                    label: l10n.accountNewPassword,
                    hint: l10n.accountPasswordHint,
                    requireStrength: true,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _ObscuredField(
                    controller: _confirmPasswordCtrl,
                    label: l10n.accountConfirmPassword,
                    hint: l10n.accountPasswordHint,
                    icon: Icons.lock_outline_rounded,
                    validator: (v) {
                      if ((v ?? '').isEmpty) return l10n.accountConfirmPasswordEmpty;
                      if (v != _newPasswordCtrl.text) return l10n.accountPasswordMismatch;
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _SaveButton(
                    label: l10n.accountChangePassword,
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
        borderRadius: AppRadii.cardLg,
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
        borderRadius: AppRadii.cardButton,
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

class _AvatarPickerSheet extends StatelessWidget {
  const _AvatarPickerSheet({required this.currentId, required this.onSelect});
  final String? currentId;
  final void Function(String? id) onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xxl)),
      ),
      padding: EdgeInsets.fromLTRB(
        24, 16, 24, MediaQuery.paddingOf(context).bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Builder(builder: (ctx) => Text(
            ctx.l10n.accountAvatarPickerTitle,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          )),
          const SizedBox(height: 6),
          Builder(builder: (ctx) => Text(
            ctx.l10n.accountAvatarPickerSub,
            style: AppTextStyles.secondary,
          )),
          const SizedBox(height: 20),
          // Default initials option
          _DefaultAvatarTile(
            selected: currentId == null,
            onTap: () => onSelect(null),
          ),
          const SizedBox(height: 16),
          // Grid of predefined avatars
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
            ),
            itemCount: kPredefinedAvatars.length,
            itemBuilder: (context, i) {
              final def = kPredefinedAvatars[i];
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AvatarPickerTile(
                    def: def,
                    selected: currentId == def.id,
                    onTap: () => onSelect(def.id),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    def.label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DefaultAvatarTile extends StatelessWidget {
  const _DefaultAvatarTile({required this.selected, required this.onTap});
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.teal.withValues(alpha: 0.08)
              : Colors.white,
          borderRadius: AppRadii.cardButton,
          border: Border.all(
            color: selected
                ? AppColors.teal
                : AppColors.borderLight,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.teal,
              ),
              child: const Center(
                child: Text(
                  'AB',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Builder(builder: (ctx) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ctx.l10n.accountAvatarDefaultLabel,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    ctx.l10n.accountAvatarDefaultSub,
                    style: AppTextStyles.secondary,
                  ),
                ],
              )),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.teal, size: 22),
          ],
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
          shape: RoundedRectangleBorder(borderRadius: AppRadii.cardMd),
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

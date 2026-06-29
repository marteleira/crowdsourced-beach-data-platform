import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../../core/l10n/l10n.dart';
import 'auth_input_decoration.dart';

/// Password field that optionally shows a live strength indicator.
///
/// When [requireStrength] is true the built-in validator enforces all four
/// rules (length, uppercase, lowercase, digit/special).  When false it only
/// checks that the field is not empty — useful for login mode.
class PasswordStrengthField extends StatefulWidget {
  const PasswordStrengthField({
    super.key,
    required this.controller,
    this.label = 'Password',
    this.hint = '••••••••',
    this.requireStrength = true,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final bool requireStrength;

  @override
  State<PasswordStrengthField> createState() => _PasswordStrengthFieldState();
}

class _PasswordStrengthFieldState extends State<PasswordStrengthField> {
  bool _obscure = true;
  bool _hasLength = false;
  bool _hasUpper = false;
  bool _hasLower = false;
  bool _hasDigitOrSpecial = false;

  int get _score =>
      [_hasLength, _hasUpper, _hasLower, _hasDigitOrSpecial].where((b) => b).length;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_update);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_update);
    super.dispose();
  }

  void _update() {
    final v = widget.controller.text;
    setState(() {
      _hasLength = v.length >= 8;
      _hasUpper = v.contains(RegExp(r'[A-Z]'));
      _hasLower = v.contains(RegExp(r'[a-z]'));
      _hasDigitOrSpecial =
          v.contains(RegExp(r'[0-9]')) || v.contains(RegExp(r'[^A-Za-z0-9]'));
    });
  }

  String? _validate(String? v) {
    final l10n = context.l10n;
    if (v == null || v.isEmpty) return l10n.passwordEmpty;
    if (!widget.requireStrength) return null;
    if (!_hasLength) return l10n.passwordMinLength;
    if (!_hasUpper) return l10n.passwordNeedsUppercase;
    if (!_hasLower) return l10n.passwordNeedsLowercase;
    if (!_hasDigitOrSpecial) return l10n.passwordNeedsDigitOrSpecial;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final showIndicator =
        widget.requireStrength && widget.controller.text.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.controller,
          obscureText: _obscure,
          validator: _validate,
          style: const TextStyle(color: AppColors.primary),
          decoration: authInputDecoration(
            label: widget.label,
            hint: widget.hint,
            icon: Icons.lock_outline,
            suffixIcon: IconButton(
              icon: Icon(
                _obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.textSecondary,
                size: 20,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
        ),
        if (showIndicator) _buildIndicator(),
      ],
    );
  }

  Widget _buildIndicator() {
    final score = _score;
    final l10n = context.l10n;
    final (label, color) = switch (score) {
      0 || 1 => (l10n.passwordStrengthWeak, AppColors.coral),
      2 => (l10n.passwordStrengthFair, AppColors.amber),
      3 => (l10n.passwordStrengthGood, AppColors.teal),
      _ => (l10n.passwordStrengthStrong, AppColors.flagGreen),
    };

    return AnimatedSize(
      duration: AppDurations.medium,
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
                        backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                        valueColor: AlwaysStoppedAnimation(color),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                AnimatedSwitcher(
                  duration: AppDurations.medium,
                  child: Text(
                    label,
                    key: ValueKey(label),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _requirement(l10n.passwordReq8Chars, _hasLength),
            _requirement(l10n.passwordReqUppercase, _hasUpper),
            _requirement(l10n.passwordReqLowercase, _hasLower),
            _requirement(l10n.passwordReqDigitOrSpecial, _hasDigitOrSpecial),
          ],
        ),
      ),
    );
  }

  Widget _requirement(String label, bool met) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: AppDurations.medium,
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
}

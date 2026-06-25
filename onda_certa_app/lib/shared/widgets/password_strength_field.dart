import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
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
    if (v == null || v.isEmpty) return 'Introduz a password';
    if (!widget.requireStrength) return null;
    if (!_hasLength) return 'Mínimo 8 caracteres';
    if (!_hasUpper) return 'Precisa de uma letra maiúscula';
    if (!_hasLower) return 'Precisa de uma letra minúscula';
    if (!_hasDigitOrSpecial) return 'Precisa de um número ou caractere especial';
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
    final (label, color) = switch (score) {
      0 || 1 => ('Fraca', AppColors.coral),
      2 => ('Razoável', AppColors.amber),
      3 => ('Boa', AppColors.teal),
      _ => ('Forte', AppColors.flagGreen),
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
            _requirement('8+ caracteres', _hasLength),
            _requirement('Letra maiúscula (A–Z)', _hasUpper),
            _requirement('Letra minúscula (a–z)', _hasLower),
            _requirement('Número ou caractere especial', _hasDigitOrSpecial),
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

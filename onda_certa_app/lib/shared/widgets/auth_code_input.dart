import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class AuthCodeInput extends StatefulWidget {
  const AuthCodeInput({
    super.key,
    this.onChanged,
    this.enabled = true,
  });

  /// Called on every change with the current code string.
  /// When [code].length == 6 the user has filled all digits.
  final void Function(String code)? onChanged;
  final bool enabled;

  @override
  State<AuthCodeInput> createState() => AuthCodeInputState();
}

class AuthCodeInputState extends State<AuthCodeInput> {
  static const _length = 6;

  final _controllers = List.generate(_length, (_) => TextEditingController());
  late final List<FocusNode> _nodes;

  String get code => _controllers.map((c) => c.text).join();

  @override
  void initState() {
    super.initState();
    _nodes = List.generate(
      _length,
      (i) => FocusNode(
        onKeyEvent: (_, event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace &&
              _controllers[i].text.isEmpty &&
              i > 0) {
            _controllers[i - 1].clear();
            _nodes[i - 1].requestFocus();
            setState(() {});
            widget.onChanged?.call(code);
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
      ),
    );
  }

  @override
  void dispose() {
    for (final c in _controllers) { c.dispose(); }
    for (final n in _nodes) { n.dispose(); }
    super.dispose();
  }

  void clear() {
    for (final c in _controllers) { c.clear(); }
    setState(() {});
    _nodes[0].requestFocus();
  }

  void _onChanged(int index, String value) {
    // Paste: full code pasted into a single field
    if (value.length == _length) {
      for (var i = 0; i < _length; i++) {
        _controllers[i].text = value[i];
      }
      _nodes.last.unfocus();
      setState(() {});
      widget.onChanged?.call(code);
      return;
    }

    if (value.isNotEmpty && index < _length - 1) {
      _nodes[index + 1].requestFocus();
    } else if (value.isNotEmpty) {
      _nodes[index].unfocus();
    }
    setState(() {});
    widget.onChanged?.call(code);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(_length, _buildDigit),
    );
  }

  Widget _buildDigit(int index) {
    return SizedBox(
      width: 46,
      height: 56,
      child: TextField(
        controller: _controllers[index],
        focusNode: _nodes[index],
        enabled: widget.enabled,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: AppRadii.cardButton,
            borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.15)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: AppRadii.cardButton,
            borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.15)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: AppRadii.cardButton,
            borderSide: const BorderSide(color: AppColors.teal, width: 1.5),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: AppRadii.cardButton,
            borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.08)),
          ),
        ),
        onChanged: (v) => _onChanged(index, v),
      ),
    );
  }
}

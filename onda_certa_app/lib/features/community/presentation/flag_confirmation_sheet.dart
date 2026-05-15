import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/beaches/data/beach_provider.dart';
import '../../../features/beaches/domain/beach_models.dart';
import '../../../shared/theme/app_theme.dart';

void showFlagConfirmationSheet(
  BuildContext context,
  BeachSummary beach, {
  required String flagColor,
  required double flagConfidence,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => FlagConfirmationSheet(
      beach: beach,
      flagColor: flagColor,
      flagConfidence: flagConfidence,
    ),
  );
}

enum _ConfirmState { idle, loading, success, rateLimited, error }

class FlagConfirmationSheet extends ConsumerStatefulWidget {
  const FlagConfirmationSheet({
    super.key,
    required this.beach,
    required this.flagColor,
    required this.flagConfidence,
  });
  final BeachSummary beach;
  final String flagColor;
  final double flagConfidence;

  @override
  ConsumerState<FlagConfirmationSheet> createState() => _FlagConfirmationSheetState();
}

class _FlagConfirmationSheetState extends ConsumerState<FlagConfirmationSheet>
    with SingleTickerProviderStateMixin {
  _ConfirmState _state = _ConfirmState.idle;
  double? _newConfidence;
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Color get _color => AppColors.forFlag(widget.flagColor);

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.96,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 12),
                // Handle
                Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1D5DB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: SingleChildScrollView(
                    controller: controller,
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                    child: _state == _ConfirmState.success
                        ? _buildSuccess()
                        : _buildMain(),
                  ),
                ),
              ],
            ),
            // Close button
            Positioned(
              top: 14, right: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 18, color: AppColors.primary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMain() {
    final color = _color;
    final confidence = widget.flagConfidence;

    return Column(
      children: [
        const SizedBox(height: 20),

        // Pulsing animated flag circle
        _PulsingFlagCircle(color: color, controller: _pulseCtrl),

        const SizedBox(height: 28),

        // Flag name chip
        _FlagChip(color: color, label: _flagName(widget.flagColor)),

        const SizedBox(height: 14),

        // Safety label
        Text(
          _flagSafety(widget.flagColor),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),

        const SizedBox(height: 4),

        // Beach name
        Text(
          widget.beach.name,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),

        const SizedBox(height: 24),

        // Animated confidence bar
        _AnimatedConfidenceBar(color: color, confidence: confidence),

        const SizedBox(height: 30),

        Container(height: 1, color: const Color(0xFFE5E7EB)),

        const SizedBox(height: 30),

        // Question with highlighted color word
        _buildQuestion(),

        const SizedBox(height: 28),

        // Action buttons
        _buildButtons(),

        // Error / rate limit feedback
        if (_state == _ConfirmState.rateLimited) ...[
          const SizedBox(height: 16),
          _InfoBanner(
            icon: Icons.hourglass_top_rounded,
            text: 'Já confirmaste a bandeira desta praia na última hora.',
            color: AppColors.sand,
            textColor: AppColors.primary,
          ),
        ] else if (_state == _ConfirmState.error) ...[
          const SizedBox(height: 16),
          _InfoBanner(
            icon: Icons.error_outline_rounded,
            text: 'Algo correu mal. Tenta de novo.',
            color: AppColors.coral.withValues(alpha: 0.12),
            textColor: AppColors.coral,
          ),
        ],
      ],
    );
  }

  Widget _buildQuestion() {
    final colorWord = _flagColorWord(widget.flagColor);
    final color = _color;

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
          height: 1.25,
          fontFamily: 'Inter',
        ),
        children: [
          const TextSpan(text: 'A bandeira ainda está '),
          TextSpan(
            text: colorWord,
            style: TextStyle(color: color),
          ),
          const TextSpan(text: '?'),
        ],
      ),
    );
  }

  Widget _buildButtons() {
    final color = _color;
    final isLoading = _state == _ConfirmState.loading;
    final colorWord = _flagName(widget.flagColor)
        .toLowerCase()
        .replaceFirst('bandeira ', '');

    return Column(
      children: [
        _ConfirmButton(
          onTap: isLoading ? null : () => _confirm('yes'),
          backgroundColor: color,
          child: isLoading
              ? const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      'Sim, ainda $colorWord',
                      style: const TextStyle(
                        color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
        ),

        const SizedBox(height: 10),

        _ConfirmButton(
          onTap: isLoading ? null : () => _confirm('no'),
          backgroundColor: AppColors.coral,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cancel_outlined,
                color: Colors.white.withValues(alpha: isLoading ? 0.45 : 1.0),
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                'Não, mudou',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: isLoading ? 0.45 : 1.0),
                  fontSize: 16, fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        _ConfirmButton(
          onTap: isLoading ? null : () => _confirm('unsure'),
          backgroundColor: Colors.white,
          hasBorder: true,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.help_outline_rounded,
                color: AppColors.textSecondary.withValues(alpha: isLoading ? 0.45 : 1.0),
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                'Não tenho a certeza',
                style: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: isLoading ? 0.45 : 1.0),
                  fontSize: 16, fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuccess() {
    final confidence = _newConfidence ?? widget.flagConfidence;
    final color = _color;

    return Column(
      children: [
        const SizedBox(height: 40),

        Container(
          width: 96, height: 96,
          decoration: BoxDecoration(
            color: AppColors.flagGreen.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle_outline_rounded, color: AppColors.flagGreen, size: 50),
        ),

        const SizedBox(height: 22),

        const Text(
          'Obrigado!',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.primary),
        ),

        const SizedBox(height: 10),

        const Text(
          'A tua confirmação ajuda a comunidade\na estar sempre bem informada.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.5),
        ),

        const SizedBox(height: 32),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            children: [
              const Text(
                'Confiança da comunidade',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),
              _AnimatedConfidenceBar(color: color, confidence: confidence),
              const SizedBox(height: 10),
              Text(
                '${(confidence * 100).round()}% de confiança',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: color),
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => Navigator.pop(context),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text(
              'Fechar',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirm(String response) async {
    setState(() => _state = _ConfirmState.loading);
    try {
      final newConf = await ref
          .read(beachRepositoryProvider)
          .confirmFlag(widget.beach.slug, response);
      if (!mounted) return;
      _newConfidence = newConf;
      ref.invalidate(beachFullDetailProvider(widget.beach.slug));
      setState(() => _state = _ConfirmState.success);
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _state = e.response?.statusCode == 429
          ? _ConfirmState.rateLimited
          : _ConfirmState.error);
    } catch (_) {
      if (mounted) setState(() => _state = _ConfirmState.error);
    }
  }
}

class _PulsingFlagCircle extends StatelessWidget {
  const _PulsingFlagCircle({required this.color, required this.controller});
  final Color color;
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, _) {
        final t1 = controller.value;
        final t2 = (controller.value + 0.5) % 1.0;
        return SizedBox(
          width: 204, height: 204,
          child: Stack(
            alignment: Alignment.center,
            children: [
              _pingRing(t1),
              _pingRing(t2),
              // Soft inner halo
              Container(
                width: 124, height: 124,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.18),
                ),
              ),
              // Core
              Container(
                width: 92, height: 92,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.5),
                      blurRadius: 30,
                      spreadRadius: 6,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _pingRing(double t) {
    final eased = Curves.easeOut.transform(t);
    final size = 92.0 + (108.0 * eased);
    final opacity = ((1.0 - t) * 0.32).clamp(0.0, 1.0);
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: opacity)),
    );
  }
}

class _AnimatedConfidenceBar extends StatelessWidget {
  const _AnimatedConfidenceBar({required this.color, required this.confidence});
  final Color color;
  final double confidence;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: confidence),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOut,
      builder: (_, value, _) => Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Confiança da comunidade',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              Text(
                '${(value * 100).round()}% confiança',
                style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}

class _FlagChip extends StatelessWidget {
  const _FlagChip({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              color: color, fontSize: 13, fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmButton extends StatelessWidget {
  const _ConfirmButton({
    required this.child,
    required this.backgroundColor,
    this.onTap,
    this.hasBorder = false,
  });
  final Widget child;
  final Color backgroundColor;
  final VoidCallback? onTap;
  final bool hasBorder;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: disabled
              ? backgroundColor.withValues(alpha: 0.45)
              : backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: hasBorder ? Border.all(color: const Color(0xFFD1D5DB)) : null,
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
    required this.icon,
    required this.text,
    required this.color,
    required this.textColor,
  });
  final IconData icon;
  final String text;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

String _flagName(String c) => switch (c) {
  'green'  => 'Bandeira Verde',
  'yellow' => 'Bandeira Amarela',
  'red'    => 'Bandeira Vermelha',
  'purple' => 'Bandeira Roxa',
  _        => 'Estado Desconhecido',
};

String _flagSafety(String c) => switch (c) {
  'green'  => 'Seguro para nadar',
  'yellow' => 'Nadar com precaução',
  'red'    => 'Proibido nadar',
  'purple' => 'Animais marinhos presentes',
  _        => 'Estado desconhecido',
};

String _flagColorWord(String c) => switch (c) {
  'green'  => 'verde',
  'yellow' => 'amarela',
  'red'    => 'vermelha',
  'purple' => 'roxa',
  _        => 'a mesma',
};

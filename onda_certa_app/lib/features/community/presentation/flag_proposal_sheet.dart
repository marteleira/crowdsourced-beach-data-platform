import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/beaches/data/beach_provider.dart';
import '../../../features/beaches/domain/beach_models.dart';
import '../../../shared/theme/app_theme.dart';

void showFlagProposalSheet(BuildContext context, BeachSummary beach) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => FlagProposalSheet(beach: beach),
  );
}

const _kFlags = [
  (value: 'green',  name: 'Verde',    desc: 'Seguro para nadar',          color: AppColors.flagGreen),
  (value: 'yellow', name: 'Amarela',  desc: 'Nadar com precaução',        color: AppColors.flagYellow),
  (value: 'red',    name: 'Vermelha', desc: 'Proibido nadar',             color: AppColors.flagRed),
  (value: 'purple', name: 'Roxa',     desc: 'Animais marinhos presentes', color: AppColors.flagPurple),
];

enum _ProposeState { idle, loading, successPending, successApplied, noRep, notPresent, unavailable, error }

class FlagProposalSheet extends ConsumerStatefulWidget {
  const FlagProposalSheet({super.key, required this.beach});
  final BeachSummary beach;

  @override
  ConsumerState<FlagProposalSheet> createState() => _FlagProposalSheetState();
}

class _FlagProposalSheetState extends ConsumerState<FlagProposalSheet> {
  _ProposeState _state = _ProposeState.idle;
  String? _selectedColor;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.88,
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
                    child: _isSuccess ? _buildSuccess() : _buildMain(),
                  ),
                ),
              ],
            ),
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

  bool get _isSuccess =>
      _state == _ProposeState.successPending || _state == _ProposeState.successApplied;

  Widget _buildMain() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),

        // Header
        const Text(
          'Propor Bandeira',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primary),
        ),
        const SizedBox(height: 4),
        Text(
          widget.beach.name,
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),

        const SizedBox(height: 16),

        // Info banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.teal.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.teal.withValues(alpha: 0.2)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: AppColors.teal, size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Tens de estar na praia e ter reputação ≥ 5 para propor.',
                  style: TextStyle(fontSize: 13, color: AppColors.tealDark, height: 1.4),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        const Text(
          'Qual é a bandeira actual?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary),
        ),

        const SizedBox(height: 14),

        // 2x2 flag grid
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.1,
          children: _kFlags
              .map((f) => _FlagOptionCard(
                    flagValue: f.value,
                    name: f.name,
                    desc: f.desc,
                    color: f.color,
                    isSelected: _selectedColor == f.value,
                    onTap: () => setState(() => _selectedColor = f.value),
                  ))
              .toList(),
        ),

        // Error banners
        if (_state == _ProposeState.noRep) ...[
          const SizedBox(height: 20),
          _ErrorBanner(
            icon: Icons.star_outline_rounded,
            text: 'Ainda não tens reputação suficiente (mínimo: 5). Continua a contribuir com alertas e confirmações!',
          ),
        ] else if (_state == _ProposeState.notPresent) ...[
          const SizedBox(height: 20),
          _ErrorBanner(
            icon: Icons.location_off_outlined,
            text: 'Tens de estar na praia (nos últimos 10 min) para propor uma bandeira.',
          ),
        ] else if (_state == _ProposeState.unavailable) ...[
          const SizedBox(height: 20),
          _ErrorBanner(
            icon: Icons.flag_outlined,
            text: 'Esta praia não tem sistema de bandeiras físicas.',
          ),
        ] else if (_state == _ProposeState.error) ...[
          const SizedBox(height: 20),
          _ErrorBanner(
            icon: Icons.error_outline_rounded,
            text: 'Algo correu mal. Tenta de novo.',
          ),
        ],

        // Submit button (visible after selection)
        if (_selectedColor != null) ...[
          const SizedBox(height: 28),
          _buildSubmitButton(),
        ],
      ],
    );
  }

  Widget _buildSubmitButton() {
    final selected = _kFlags.firstWhere((f) => f.value == _selectedColor);
    final isLoading = _state == _ProposeState.loading;

    return SizedBox(
      width: double.infinity,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isLoading
              ? selected.color.withValues(alpha: 0.5)
              : selected.color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: selected.color.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: isLoading ? null : _submit,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 17),
              child: Center(
                child: isLoading
                    ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 10, height: 10,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Propor bandeira ${selected.name.toLowerCase()}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccess() {
    final applied = _state == _ProposeState.successApplied;
    final selected = _kFlags.firstWhere((f) => f.value == _selectedColor);

    return Column(
      children: [
        const SizedBox(height: 40),

        Container(
          width: 96, height: 96,
          decoration: BoxDecoration(
            color: selected.color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            applied ? Icons.flag_rounded : Icons.schedule_rounded,
            color: selected.color,
            size: 50,
          ),
        ),

        const SizedBox(height: 22),

        Text(
          applied ? 'Bandeira atualizada!' : 'Proposta submetida!',
          style: const TextStyle(
            fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.primary,
          ),
        ),

        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: selected.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected.color.withValues(alpha: 0.28)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(color: selected.color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 7),
              Text(
                'Bandeira ${selected.name}',
                style: TextStyle(
                  color: selected.color, fontSize: 13, fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        Text(
          applied
              ? 'A tua reputação deu-te autoridade para aplicar a bandeira directamente.'
              : 'A comunidade irá confirmar a tua proposta em breve.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.5),
        ),

        const SizedBox(height: 36),

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

  Future<void> _submit() async {
    if (_selectedColor == null) return;
    setState(() => _state = _ProposeState.loading);
    try {
      final result = await ref
          .read(beachRepositoryProvider)
          .proposeFlag(widget.beach.slug, _selectedColor!);
      if (!mounted) return;
      ref.invalidate(beachFullDetailProvider(widget.beach.slug));
      setState(() => _state = result.status == 'applied'
          ? _ProposeState.successApplied
          : _ProposeState.successPending);
    } on DioException catch (e) {
      if (!mounted) return;
      final code = e.response?.statusCode;
      final detail = e.response?.data?['detail'] as String? ?? '';
      setState(() {
        if (code == 400) {
          _state = _ProposeState.unavailable;
        } else if (code == 403 && detail.contains('reputação')) {
          _state = _ProposeState.noRep;
        } else if (code == 403) {
          _state = _ProposeState.notPresent;
        } else {
          _state = _ProposeState.error;
        }
      });
    } catch (_) {
      if (mounted) setState(() => _state = _ProposeState.error);
    }
  }
}

class _FlagOptionCard extends StatelessWidget {
  const _FlagOptionCard({
    required this.flagValue,
    required this.name,
    required this.desc,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });
  final String flagValue;
  final String name;
  final String desc;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFE5E7EB),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: color.withValues(alpha: 0.18), blurRadius: 12, offset: const Offset(0, 4))]
              : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: isSelected ? 0.55 : 0.3),
                    blurRadius: isSelected ? 18 : 10,
                    spreadRadius: isSelected ? 3 : 1,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              name,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: isSelected ? color : AppColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              desc,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.coral.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.coral.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.coral, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13, color: AppColors.coral, height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

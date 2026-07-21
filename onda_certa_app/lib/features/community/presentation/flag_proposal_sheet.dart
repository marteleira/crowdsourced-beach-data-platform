import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_error.dart';
import '../../../core/l10n/l10n.dart';
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

List<({String value, String name, String desc, Color color})> _flagOptions(AppLocalizations l10n) => [
  (value: 'green',  name: l10n.flagColorGreenCap,  desc: l10n.flagProposeDescGreen,  color: AppColors.flagGreen),
  (value: 'yellow', name: l10n.flagColorYellowCap, desc: l10n.flagProposeDescYellow, color: AppColors.flagYellow),
  (value: 'red',    name: l10n.flagColorRedCap,    desc: l10n.flagProposeDescRed,    color: AppColors.flagRed),
  (value: 'purple', name: l10n.flagColorPurpleCap, desc: l10n.flagProposeDescPurple, color: AppColors.flagPurple),
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
    final l10n = context.l10n;
    final flags = _flagOptions(l10n);

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
                const SizedBox(height: AppSpacing.md),
                Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderMedium,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Expanded(
                  child: SingleChildScrollView(
                    controller: controller,
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                    child: _isSuccess ? _buildSuccess(l10n, flags) : _buildMain(l10n, flags),
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

  Widget _buildMain(AppLocalizations l10n, List<({String value, String name, String desc, Color color})> flags) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.sm),

        Text(
          l10n.flagProposeTitle,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primary),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          widget.beach.name,
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),

        const SizedBox(height: AppSpacing.lg),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.teal.withValues(alpha: 0.08),
            borderRadius: AppRadii.cardMd,
            border: Border.all(color: AppColors.teal.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: AppColors.teal, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.flagProposeRequirement,
                  style: const TextStyle(fontSize: 13, color: AppColors.tealDark, height: 1.4),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        Text(
          l10n.flagProposeQuestion,
          style: AppTextStyles.titleMd,
        ),

        const SizedBox(height: 14),

        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.1,
          children: flags
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

        if (_state == _ProposeState.noRep) ...[
          const SizedBox(height: AppSpacing.xl),
          _ErrorBanner(icon: Icons.star_outline_rounded, text: l10n.flagProposeNoRep),
        ] else if (_state == _ProposeState.notPresent) ...[
          const SizedBox(height: AppSpacing.xl),
          _ErrorBanner(icon: Icons.location_off_outlined, text: l10n.flagProposeNotPresent),
        ] else if (_state == _ProposeState.unavailable) ...[
          const SizedBox(height: AppSpacing.xl),
          _ErrorBanner(icon: Icons.flag_outlined, text: l10n.flagProposeUnavailable),
        ] else if (_state == _ProposeState.error) ...[
          const SizedBox(height: AppSpacing.xl),
          _ErrorBanner(icon: Icons.error_outline_rounded, text: l10n.flagProposeGenericError),
        ],

        if (_selectedColor != null) ...[
          const SizedBox(height: 28),
          _buildSubmitButton(l10n, flags),
        ],
      ],
    );
  }

  Widget _buildSubmitButton(AppLocalizations l10n, List<({String value, String name, String desc, Color color})> flags) {
    final selected = flags.firstWhere((f) => f.value == _selectedColor);
    final isLoading = _state == _ProposeState.loading;

    return SizedBox(
      width: double.infinity,
      child: AnimatedContainer(
        duration: AppDurations.medium,
        decoration: BoxDecoration(
          color: isLoading ? selected.color.withValues(alpha: 0.5) : selected.color,
          borderRadius: AppRadii.cardLg,
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
          borderRadius: AppRadii.cardLg,
          child: InkWell(
            onTap: isLoading ? null : _submit,
            borderRadius: AppRadii.cardLg,
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
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            l10n.flagProposeSubmit(selected.name.toLowerCase()),
                            style: const TextStyle(
                              color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700,
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

  Widget _buildSuccess(AppLocalizations l10n, List<({String value, String name, String desc, Color color})> flags) {
    final applied = _state == _ProposeState.successApplied;
    final selected = flags.firstWhere((f) => f.value == _selectedColor);

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
          applied ? l10n.flagProposeSuccessApplied : l10n.flagProposeSuccessPending,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.primary),
        ),

        const SizedBox(height: AppSpacing.md),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: selected.color.withValues(alpha: 0.1),
            borderRadius: AppRadii.cardXl,
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
                l10n.flagProposeFlagLabel(selected.name),
                style: TextStyle(color: selected.color, fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        Text(
          applied ? l10n.flagProposeSuccessBodyApplied : l10n.flagProposeSuccessBodyPending,
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
              shape: RoundedRectangleBorder(borderRadius: AppRadii.cardButton),
            ),
            child: Text(
              l10n.close,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
      if (e.type == DioExceptionType.cancel) return;
      if (!mounted) return;
      final code = e.response?.statusCode;
      final apiError = parseApiError(e);
      setState(() {
        if (code == 400) {
          _state = _ProposeState.unavailable;
        } else if (code == 403 && apiError?.code == 'insufficient_reputation') {
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
        duration: AppDurations.fast,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? color : AppColors.borderLight,
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
            const SizedBox(height: AppSpacing.md),
            Text(
              name,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: isSelected ? color : AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
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
        borderRadius: AppRadii.cardMd,
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
              style: const TextStyle(fontSize: 13, color: AppColors.coral, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

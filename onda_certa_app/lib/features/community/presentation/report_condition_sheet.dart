import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/l10n.dart';
import '../../../features/beaches/data/beach_provider.dart';
import '../../../features/beaches/domain/beach_models.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/alert_item.dart';

class ReportConditionSheet extends ConsumerStatefulWidget {
  const ReportConditionSheet({super.key, required this.beach});
  final BeachSummary beach;

  @override
  ConsumerState<ReportConditionSheet> createState() => _ReportConditionSheetState();
}

class _ReportConditionSheetState extends ConsumerState<ReportConditionSheet> {
  String? _selectedType;
  int _severity = 1;
  final _noteController = TextEditingController();
  bool _submitting = false;
  String? _errorMessage;
  ScrollController? _scrollController;

  List<(String, String, IconData)> _types(AppLocalizations l10n) => [
    ('jellyfish',      l10n.alertTypeJellyfish,      Icons.bubble_chart),
    ('strong_current', l10n.alertTypeStrongCurrent,  Icons.electric_bolt),
    ('pollution',      l10n.alertTypePollution,       Icons.delete_outline),
    ('rough_sea',      l10n.alertTypeRoughSea,        Icons.waves),
    ('other_alert',    l10n.alertTypeOther,           Icons.warning_amber_outlined),
  ];

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.96,
      builder: (_, controller) {
        _scrollController = controller;
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xxl)),
          ),
          child: Column(
            children: [
              // Handle
              const SizedBox(height: 10),
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.reportSheetTitle,
                            style: AppTextStyles.titleLg,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.beach.name,
                            style: AppTextStyles.secondaryMd,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 22),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),

              Container(height: 1, margin: const EdgeInsets.only(top: 16), color: AppColors.backgroundLight),

              // Scrollable form
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
                  children: [
                    _buildTypeSection(l10n),
                    if (_selectedType != null) ...[
                      const SizedBox(height: AppSpacing.xxl),
                      _buildSeveritySection(l10n),
                      const SizedBox(height: AppSpacing.xxl),
                      _buildNoteSection(l10n),
                      const SizedBox(height: 14),
                      _buildLocationNote(l10n),
                      const SizedBox(height: AppSpacing.xxl),
                      _buildSubmitButton(l10n),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        _buildErrorBanner(_errorMessage!),
                      ],
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _scrollToError() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = _scrollController;
      if (controller == null || !controller.hasClients) return;
      controller.animateTo(
        controller.position.maxScrollExtent,
        duration: AppDurations.medium,
        curve: Curves.easeOut,
      );
    });
  }

  Widget _buildTypeSection(AppLocalizations l10n) {
    final types = _types(l10n);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.reportTypeSection,
          style: AppTextStyles.titleSm,
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: types.map((t) {
            final (type, label, icon) = t;
            final isSelected = _selectedType == type;
            final (_, typeColor, _) = alertMeta(l10n, type);
            return GestureDetector(
              onTap: () => setState(() => _selectedType = type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? typeColor.withValues(alpha: 0.1) : Colors.white,
                  borderRadius: AppRadii.cardMd,
                  border: Border.all(
                    color: isSelected ? typeColor : AppColors.borderLight,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 16, color: isSelected ? typeColor : AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? typeColor : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSeveritySection(AppLocalizations l10n) {
    final severities = [
      (1, l10n.severityLow,      l10n.reportSeverityLowSub,      AppColors.flagGreen),
      (2, l10n.severityModerate, l10n.reportSeverityModerateSub,  AppColors.flagYellow),
      (3, l10n.severityHigh,     l10n.reportSeverityHighSub,      AppColors.flagRed),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.reportSeveritySection,
          style: AppTextStyles.titleSm,
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: severities.asMap().entries.map((entry) {
            final idx = entry.key;
            final (level, label, sub, color) = entry.value;
            final isSelected = _severity == level;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _severity = level),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  margin: EdgeInsets.only(right: idx < 2 ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? color : Colors.white,
                    borderRadius: AppRadii.cardMd,
                    border: Border.all(
                      color: isSelected ? color : AppColors.borderLight,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (i) => Container(
                          width: 8, height: 8,
                          margin: const EdgeInsets.only(right: 2),
                          decoration: BoxDecoration(
                            color: i < level
                                ? (isSelected ? Colors.white : color)
                                : (isSelected ? Colors.white.withValues(alpha: 0.35) : AppColors.borderLight),
                            shape: BoxShape.circle,
                          ),
                        )),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : AppColors.primary,
                        ),
                      ),
                      Text(
                        sub,
                        style: TextStyle(
                          fontSize: 10,
                          color: isSelected ? Colors.white.withValues(alpha: 0.8) : AppColors.textHint,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildNoteSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              l10n.reportNoteSection,
              style: AppTextStyles.titleSm,
            ),
            const SizedBox(width: 5),
            Text(l10n.reportNoteOptional, style: AppTextStyles.secondaryMd),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _noteController,
          maxLength: 200,
          maxLines: 3,
          onChanged: (_) => setState(() {}),
          style: const TextStyle(fontSize: 14, color: AppColors.primary),
          decoration: InputDecoration(
            hintText: l10n.reportNoteHint,
            hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 13),
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: AppRadii.cardMd,
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(14),
            counterStyle: AppTextStyles.hintSm,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationNote(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: AppRadii.cardChip,
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on_outlined, color: AppColors.textHint, size: 16),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              l10n.reportLocationNote,
              style: AppTextStyles.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.coral.withValues(alpha: 0.12),
        borderRadius: AppRadii.cardChip,
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.coral, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.coral, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(AppLocalizations l10n) {
    final canSubmit = _selectedType != null && !_submitting;

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: canSubmit ? _submit : null,
        icon: _submitting
            ? const SizedBox(
                width: 16, height: 16,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : const Icon(Icons.send_outlined, size: 18),
        label: Text(l10n.reportSubmit, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.teal,
          disabledBackgroundColor: AppColors.borderLight,
          disabledForegroundColor: AppColors.textHint,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: AppRadii.cardButton),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_selectedType == null) return;
    final l10n = context.l10n;
    final pos = ref.read(locationProvider).value;

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    try {
      await ref.read(communityReportsProvider(widget.beach.slug).notifier).submitReport(
        type: _selectedType!,
        severity: _severity,
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        lat: pos?.latitude,
        lon: pos?.longitude,
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.reportSuccess),
          backgroundColor: AppColors.flagGreen,
        ),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      final msg = e.response?.statusCode == 403
          ? l10n.reportMustBeAtBeach
          : l10n.reportError;
      setState(() => _errorMessage = msg);
      _scrollToError();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

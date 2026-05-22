import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../features/beaches/data/beach_provider.dart';
import '../../../features/beaches/domain/beach_models.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/alert_item.dart';

class CommunityAlertsScreen extends ConsumerStatefulWidget {
  const CommunityAlertsScreen({super.key, required this.beach});
  final BeachSummary beach;

  @override
  ConsumerState<CommunityAlertsScreen> createState() => _CommunityAlertsScreenState();
}

class _CommunityAlertsScreenState extends ConsumerState<CommunityAlertsScreen> {
  @override
  Widget build(BuildContext context) {
    final reports = ref.watch(communityReportsProvider(widget.beach.slug));
    final activeCount = reports.value?.where((r) => !r.isExpired).length
        ?? widget.beach.activeAlertsCount;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(activeCount),
      body: switch (reports) {
        AsyncLoading() when reports.value == null =>
          const Center(child: CircularProgressIndicator(color: AppColors.teal, strokeWidth: 2.5)),
        AsyncError(:final error) =>
          _ErrorView(error: error.toString(), onRetry: () => ref.invalidate(communityReportsProvider(widget.beach.slug))),
        _ => _buildBody(reports.value ?? []),
      },
      floatingActionButton: FloatingActionButton(
        onPressed: _openReportSheet,
        backgroundColor: AppColors.coral,
        elevation: 3,
        child: const Icon(Icons.add, color: Colors.white, size: 26),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(int activeCount) {
    return AppBar(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.white),
        onPressed: () => context.pop(),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Alertas da Comunidade',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          Text(
            widget.beach.name,
            style: const TextStyle(fontSize: 12, color: AppColors.teal, fontWeight: FontWeight.w500),
          ),
        ],
      ),
      actions: [
        if (activeCount > 0)
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.coral,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$activeCount activos',
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: Colors.white.withValues(alpha: 0.08)),
      ),
    );
  }

  Widget _buildBody(List<BeachReport> reports) {
    if (reports.isEmpty) {
      return _EmptyState(onReport: _openReportSheet);
    }

    return RefreshIndicator(
      onRefresh: () => ref.refresh(communityReportsProvider(widget.beach.slug).future),
      color: AppColors.teal,
      backgroundColor: Colors.white,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: reports.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (_, i) => _ReportCard(
          report: reports[i],
          onVote: (vote) => _vote(reports[i].id, vote),
        ),
      ),
    );
  }

  Future<void> _vote(int reportId, String vote) async {
    try {
      await ref.read(communityReportsProvider(widget.beach.slug).notifier).vote(reportId, vote);
    } on DioException catch (e) {
      if (!mounted) return;
      final msg = e.response?.statusCode == 403
          ? 'Tens de estar na praia para votar'
          : 'Erro ao votar. Tenta de novo.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.coral),
      );
    }
  }

  void _openReportSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReportConditionSheet(beach: widget.beach),
    );
  }
}

// Report Card

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report, required this.onVote});
  final BeachReport report;
  final void Function(String) onVote;

  Color get _severityColor => switch (report.severity) {
    1 => AppColors.flagGreen,
    2 => AppColors.flagYellow,
    3 => AppColors.flagRed,
    _ => AppColors.textHint,
  };

  String get _severityLabel => switch (report.severity) {
    1 => 'Baixo',
    2 => 'Moderado',
    3 => 'Grave',
    _ => '',
  };

  @override
  Widget build(BuildContext context) {
    final (icon, typeColor, typeLabel) = alertMeta(report.type);
    final severityColor = _severityColor;
    final severityLabel = _severityLabel;
    final totalVotes = report.upvotes + report.downvotes;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Colored severity accent line at top
            Container(height: 4, color: severityColor),

            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: icon + type + severity + time
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: typeColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: typeColor, size: 22),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    typeLabel,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                if (report.verified)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.flagGreen.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.verified_outlined, size: 11, color: AppColors.flagGreen),
                                        SizedBox(width: 3),
                                        Text('Verificado', style: TextStyle(fontSize: 10, color: AppColors.flagGreen, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Row(
                              children: [
                                _SeverityDots(severity: report.severity ?? 0, color: severityColor),
                                const SizedBox(width: 6),
                                Text(
                                  severityLabel,
                                  style: TextStyle(
                                    color: severityColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  timeAgo(report.createdAt),
                                  style: const TextStyle(color: AppColors.textHint, fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Note
                  if (report.note != null && report.note!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '"${report.note!}"',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: AppSpacing.md),

                  // Vote row
                  Row(
                    children: [
                      _VoteButton(
                        icon: Icons.thumb_up_outlined,
                        activeIcon: Icons.thumb_up,
                        count: report.upvotes,
                        isActive: report.myVote == 1,
                        color: const Color(0xFF10B981),
                        onTap: () => onVote('up'),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _VoteButton(
                        icon: Icons.thumb_down_outlined,
                        activeIcon: Icons.thumb_down,
                        count: report.downvotes,
                        isActive: report.myVote == -1,
                        color: AppColors.flagRed,
                        onTap: () => onVote('down'),
                      ),
                      const Spacer(),
                      Text(
                        '$totalVotes ${totalVotes == 1 ? 'voto' : 'votos'}',
                        style: const TextStyle(color: AppColors.textHint, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SeverityDots extends StatelessWidget {
  const _SeverityDots({required this.severity, required this.color});
  final int severity;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) => Container(
        width: 7, height: 7,
        margin: const EdgeInsets.only(right: 3),
        decoration: BoxDecoration(
          color: i < severity ? color : AppColors.borderLight,
          shape: BoxShape.circle,
        ),
      )),
    );
  }
}

class _VoteButton extends StatelessWidget {
  const _VoteButton({
    required this.icon, required this.activeIcon,
    required this.count, required this.isActive,
    required this.color, required this.onTap,
  });
  final IconData icon;
  final IconData activeIcon;
  final int count;
  final bool isActive;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.12) : AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? color.withValues(alpha: 0.35) : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              size: 15,
              color: isActive ? color : AppColors.textSecondary,
            ),
            const SizedBox(width: 5),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isActive ? color : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Empty State

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onReport});
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: AppColors.flagGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_outline, color: AppColors.flagGreen, size: 40),
            ),
            const SizedBox(height: AppSpacing.xl),
            const Text(
              'Tudo calmo!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Sem alertas activos nesta praia.\nSe vires algo, reporta!',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: AppSpacing.xxl),
            OutlinedButton.icon(
              onPressed: onReport,
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: const Text('Reportar condição'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.teal,
                side: const BorderSide(color: AppColors.teal),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Error View

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});
  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off_outlined, color: AppColors.textHint, size: 48),
          const SizedBox(height: AppSpacing.lg),
          const Text('Erro ao carregar alertas', style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
          const SizedBox(height: AppSpacing.lg),
          TextButton(onPressed: onRetry, child: const Text('Tentar de novo')),
        ],
      ),
    );
  }
}

// Report Condition Sheet

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

  static const _types = [
    ('jellyfish',      'Medusas',        Icons.bubble_chart),
    ('strong_current', 'Corrente Forte', Icons.electric_bolt),
    ('pollution',      'Poluição',       Icons.delete_outline),
    ('rough_sea',      'Mar Agitado',    Icons.waves),
    ('other_alert',    'Outro',          Icons.warning_amber_outlined),
  ];

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider).value;
    final isAnonymous = profile?.isAnonymous ?? false;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.96,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                        const Text(
                          'Reportar Condição',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.beach.name,
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
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
                  _buildTypeSection(),
                  if (_selectedType != null) ...[
                    const SizedBox(height: AppSpacing.xxl),
                    _buildSeveritySection(),
                    const SizedBox(height: AppSpacing.xxl),
                    _buildNoteSection(),
                    const SizedBox(height: 14),
                    _buildLocationNote(),
                    if (isAnonymous) ...[
                      const SizedBox(height: 10),
                      _buildGuestNote(),
                    ],
                    const SizedBox(height: AppSpacing.xxl),
                    _buildSubmitButton(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tipo de condição',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.primary),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _types.map((t) {
            final (type, label, icon) = t;
            final isSelected = _selectedType == type;
            final (_, typeColor, _) = alertMeta(type);
            return GestureDetector(
              onTap: () => setState(() => _selectedType = type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? typeColor.withValues(alpha: 0.1) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
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

  Widget _buildSeveritySection() {
    const severities = [
      (1, 'Baixo',    'Preocupação menor', AppColors.flagGreen),
      (2, 'Moderado', 'Risco notável',     AppColors.flagYellow),
      (3, 'Grave',    'Perigoso',          AppColors.flagRed),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Qual a gravidade?',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.primary),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: severities.map((s) {
            final (level, label, sub, color) = s;
            final isSelected = _severity == level;
            final idx = severities.indexOf(s);
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _severity = level),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  margin: EdgeInsets.only(right: idx < 2 ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? color : Colors.white,
                    borderRadius: BorderRadius.circular(12),
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

  Widget _buildNoteSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Adicionar nota',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.primary),
            ),
            const SizedBox(width: 5),
            const Text('(opcional)', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
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
            hintText: 'Descreve o que observaste...',
            hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 13),
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(14),
            counterStyle: const TextStyle(color: AppColors.textHint, fontSize: 11),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationNote() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        children: [
          Icon(Icons.location_on_outlined, color: AppColors.textHint, size: 16),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'A tua localização aproximada será partilhada com este aviso.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestNote() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('🌿', style: TextStyle(fontSize: 15)),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Modo convidado: os avisos funcionam, mas criar uma conta dá-te reputação e ajuda a acompanhar a precisão.',
              style: TextStyle(color: Color(0xFF166534), fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
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
        label: const Text('Submeter Aviso', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.teal,
          disabledBackgroundColor: AppColors.borderLight,
          disabledForegroundColor: AppColors.textHint,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_selectedType == null) return;
    final pos = ref.read(locationProvider).value;

    setState(() => _submitting = true);
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
        const SnackBar(
          content: Text('Aviso submetido com sucesso!'),
          backgroundColor: AppColors.flagGreen,
        ),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      final msg = e.response?.statusCode == 403
          ? 'Tens de estar na praia para submeter um aviso'
          : 'Erro ao submeter. Tenta de novo.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.coral),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

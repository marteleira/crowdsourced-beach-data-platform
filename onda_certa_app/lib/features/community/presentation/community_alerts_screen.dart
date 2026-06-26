import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/l10n/l10n.dart';
import '../../../features/beaches/data/beach_provider.dart';
import '../../../features/beaches/domain/beach_models.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/format_helpers.dart';
import '../../../shared/utils/ui_helpers.dart';
import '../../../shared/widgets/alert_item.dart';
import '../../../shared/widgets/severity_dots.dart';
import 'report_condition_sheet.dart';

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
    final l10n = context.l10n;
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
          Text(
            l10n.alertsTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
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
              borderRadius: AppRadii.cardXl,
            ),
            child: Text(
              l10n.alertsActive(activeCount),
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

  bool get _isGuest => ref.read(authProvider).isGuest;

  Future<void> _vote(int reportId, String vote) async {
    final l10n = context.l10n;
    if (_isGuest) {
      showGuestSnackbar(context, l10n.guestVoteAlerts);
      return;
    }
    try {
      await ref.read(communityReportsProvider(widget.beach.slug).notifier).vote(reportId, vote);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) return;
      if (!mounted) return;
      final msg = e.response?.statusCode == 403
          ? l10n.mustBeAtBeachVote
          : l10n.errorVoting;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.coral),
      );
    }
  }

  void _openReportSheet() {
    if (_isGuest) {
      showGuestSnackbar(context, context.l10n.guestSubmitReport);
      return;
    }
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (icon, typeColor, typeLabel) = alertMeta(l10n, report.type);
    final (severityColor, severityLabel) = severityMeta(l10n, report.severity);
    final totalVotes = report.upvotes + report.downvotes;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadii.cardLg,
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: ClipRRect(
        borderRadius: AppRadii.cardLg,
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
                          borderRadius: AppRadii.cardMd,
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
                                      borderRadius: AppRadii.cardXs,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.verified_outlined, size: 11, color: AppColors.flagGreen),
                                        const SizedBox(width: 3),
                                        Text(l10n.reportVerified, style: const TextStyle(fontSize: 10, color: AppColors.flagGreen, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Row(
                              children: [
                                SeverityDotsIndicator(filled: report.severity ?? 0, color: severityColor),
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
                                  timeAgoFromString(l10n, report.createdAt),
                                  style: AppTextStyles.hint,
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
                        borderRadius: AppRadii.cardChip,
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
                        '$totalVotes ${totalVotes == 1 ? l10n.reportVoteSingular : l10n.reportVotePlural}',
                        style: AppTextStyles.hint,
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
        duration: AppDurations.fast,
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.12) : AppColors.backgroundLight,
          borderRadius: AppRadii.cardXl,
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
    final l10n = context.l10n;
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
            Text(
              l10n.communityAlertsEmptyTitle,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.communityAlertsEmptyBody,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: AppSpacing.xxl),
            OutlinedButton.icon(
              onPressed: onReport,
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: Text(l10n.communityAlertsReportBtn),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.teal,
                side: const BorderSide(color: AppColors.teal),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: AppRadii.cardMd),
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
    final l10n = context.l10n;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off_outlined, color: AppColors.textHint, size: 48),
          const SizedBox(height: AppSpacing.lg),
          Text(l10n.errorLoadAlerts, style: AppTextStyles.secondaryLg),
          const SizedBox(height: AppSpacing.lg),
          TextButton(onPressed: onRetry, child: Text(l10n.tryAgain)),
        ],
      ),
    );
  }
}

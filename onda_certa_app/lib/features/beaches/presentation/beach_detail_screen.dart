import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/presence/heartbeat_service.dart';
import '../data/beach_provider.dart';
import '../domain/beach_models.dart';
import '../../../features/community/presentation/flag_confirmation_sheet.dart';
import '../../../features/community/presentation/flag_proposal_sheet.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/beach_helpers.dart';
import '../../../shared/utils/format_helpers.dart';
import '../../../shared/utils/ui_helpers.dart';
import '../../../shared/utils/weather_helpers.dart';
import '../../../shared/widgets/beach_cover_image.dart';
import '../../../shared/widgets/overlay_icon_button.dart';
import '../../../shared/widgets/metric_cell.dart';
import '../../../shared/widgets/alert_item.dart';
import '../../../shared/widgets/severity_dots.dart';
import '../../../shared/widgets/tide_chart.dart';
import '../../../shared/widgets/app_error_state.dart';
import '../../../shared/widgets/user_avatar.dart';

class BeachDetailScreen extends ConsumerStatefulWidget {
  const BeachDetailScreen({super.key, required this.beach});
  final BeachSummary beach;

  @override
  ConsumerState<BeachDetailScreen> createState() => _BeachDetailScreenState();
}

class _BeachDetailScreenState extends ConsumerState<BeachDetailScreen>
    with WidgetsBindingObserver, RouteAware {
  bool _sendingHeartbeat = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  @override
  void didPopNext() => _refresh();

  bool get _isGuest => ref.read(authProvider).isGuest;

  Future<void> _refresh() async {
    final slug = widget.beach.slug;
    ref.invalidate(beachFullDetailProvider(slug));
    ref.invalidate(beachTransportProvider(slug));
    ref.invalidate(beachWaterQualityProvider(slug));
    ref.invalidate(mapUsersProvider);
    await ref.read(beachFullDetailProvider(slug).future).catchError((_) => null);
  }

  @override
  Widget build(BuildContext context) {
    final slug = widget.beach.slug;
    // Core data (status, occupancy, weather, sea, tides, alerts) — one combined call
    final detail = ref.watch(beachFullDetailProvider(slug));
    // Independent calls for sections that have dedicated endpoints
    final transport = ref.watch(beachTransportProvider(slug));
    final waterQuality = ref.watch(beachWaterQualityProvider(slug));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: RefreshIndicator(
          onRefresh: _refresh,
          color: AppColors.teal,
          child: CustomScrollView(
          slivers: [
            _HeroAppBar(
              beach: widget.beach,
              isFavourite: ref.watch(favouritesProvider).value?.any((b) => b.slug == widget.beach.slug) ?? false,
              onFavourite: () async {
                final messenger = ScaffoldMessenger.of(context);
                final l10n = context.l10n;
                try {
                  await ref.read(favouritesProvider.notifier).toggle(widget.beach);
                } catch (_) {
                  messenger.showSnackBar(
                    SnackBar(content: Text(l10n.errorFavourite), backgroundColor: Colors.red),
                  );
                }
              },
            ),
            if (detail.isLoading && detail.value == null)
              const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: AppColors.teal, strokeWidth: 2.5)))
            else if (detail.hasError && detail.value == null)
              SliverFillRemaining(
                child: AppErrorState(
                  message: context.l10n.connectionError,
                  onRetry: _refresh,
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(
                    _buildSections(detail.value, transport, waterQuality),
                  ),
                ),
              ),
          ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSections(
    BeachFullDetail? d,
    AsyncValue<BeachTransportInfo> transport,
    AsyncValue<WaterQuality?> waterQuality,
  ) {
    final flagColor = d?.status.flagColor ?? widget.beach.flagColor;
    final flagConfidence = d?.status.flagConfidence ?? widget.beach.flagConfidence;

    return [
      _FlagCard(
        flagColor: flagColor,
        flagConfidence: flagConfidence,
        onTap: flagColor != 'unknown'
            ? () {
                if (_isGuest) {
                  showGuestSnackbar(context, context.l10n.guestConfirmFlag);
                  return;
                }
                showFlagConfirmationSheet(
                  context,
                  widget.beach,
                  flagColor: flagColor,
                  flagConfidence: flagConfidence ?? 0.7,
                );
              }
            : () {
                if (_isGuest) {
                  showGuestSnackbar(context, context.l10n.guestProposeFlag);
                  return;
                }
                showFlagProposalSheet(context, widget.beach);
              },
      ),
      const SizedBox(height: AppSpacing.md),
      _OccupancyCard(
        slug: widget.beach.slug,
        occupancy: d?.status.occupancy,
        occupancyLevel: d?.status.occupancy.level ?? widget.beach.occupancyLevel,
        onImHere: _sendHeartbeat,
        sending: _sendingHeartbeat,
      ),
      const SizedBox(height: AppSpacing.md),
      _WeatherCard(weather: d?.weather),
      const SizedBox(height: AppSpacing.md),
      _SeaCard(sea: d?.sea),
      const SizedBox(height: AppSpacing.md),
      _TidesCard(tidesData: d?.tides ?? TidesData.empty, onViewAll: _goToTides),
      const SizedBox(height: AppSpacing.md),
      _WaterQualityCard(quality: waterQuality.value),
      const SizedBox(height: AppSpacing.md),
      _TransportCard(
        transport: transport.value ?? BeachTransportInfo.empty,
        isLoading: transport.isLoading,
      ),
      const SizedBox(height: AppSpacing.md),
      _PlanTripButton(beach: widget.beach),
      const SizedBox(height: AppSpacing.md),
      _CommunityAlertsCard(reports: d?.activeAlerts ?? [], beach: widget.beach),
      const SizedBox(height: AppSpacing.md),
      _PresenceSection(slug: widget.beach.slug),
    ];
  }

  void _goToTides() {
    context.push(AppRoutes.beachTides(widget.beach.slug), extra: widget.beach);
  }

  Future<void> _sendHeartbeat() async {
    if (_sendingHeartbeat) return;
    setState(() => _sendingHeartbeat = true);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    try {
      final slug = await sendHeartbeatForCurrentPosition(ref);
      if (slug == null) {
        if (mounted) {
          messenger.showSnackBar(SnackBar(
            content: Text(l10n.tooFarToCheckin),
            duration: const Duration(seconds: 2),
            backgroundColor: AppColors.coral,
          ));
        }
        return;
      }
      if (mounted) {
        messenger.showSnackBar(SnackBar(
          content: Text(l10n.presenceRegistered),
          duration: const Duration(seconds: 2),
          backgroundColor: AppColors.teal,
        ));
        ref.invalidate(beachFullDetailProvider(slug));
      }
    } catch (_) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(
          content: Text(l10n.connectionError),
          duration: const Duration(seconds: 2),
          backgroundColor: AppColors.coral,
        ));
      }
    } finally {
      if (mounted) setState(() => _sendingHeartbeat = false);
    }
  }
}

class _HeroAppBar extends StatelessWidget {
  const _HeroAppBar({required this.beach, required this.isFavourite, required this.onFavourite});
  final BeachSummary beach;
  final bool isFavourite;
  final VoidCallback onFavourite;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: AppColors.primary,
      automaticallyImplyLeading: false,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: OverlayIconButton(
          onTap: () => context.pop(),
          icon: Icons.arrow_back,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8, right: 12),
          child: OverlayIconButton(
            onTap: onFavourite,
            icon: isFavourite ? Icons.favorite : Icons.favorite_border,
            iconColor: isFavourite ? AppColors.coral : Colors.white,
            iconSize: 18,
          ),
        ),
      ],
      flexibleSpace: Builder(
        builder: (ctx) {
          final settings = ctx.dependOnInheritedWidgetOfExactType<FlexibleSpaceBarSettings>();
          final t = settings == null
              ? 0.0
              : (1.0 - ((settings.currentExtent - settings.minExtent) / (settings.maxExtent - settings.minExtent)))
                  .clamp(0.0, 1.0);
          final leftPadding = 16.0 + 56.0 * t;  // interpolates 16 → 72
          final rightPadding = 56.0 * t;         // interpolates 0 → 56 (clears 1 action button)

          return FlexibleSpaceBar(
            titlePadding: EdgeInsetsDirectional.only(start: leftPadding, end: rightPadding),
            title: SizedBox(
              height: kToolbarHeight,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    beach.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700,
                      shadows: [Shadow(blurRadius: 6, color: Colors.black45)],
                    ),
                  ),
                  Text(
                    beach.municipality ?? ctx.l10n.municipality,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12, fontWeight: FontWeight.w400),
                  ),
                ],
              ),
            ),
            background: BeachCoverImage(
              flagColor: beach.flagColor,
              photoUrl: beach.coverPhotoUrl,
              child: Positioned(
                left: 0, right: 0, bottom: 0,
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.72)],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: AppRadii.cardLg,
      border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
    ),
    child: child,
  );
}

class _CardHeader extends StatelessWidget {
  const _CardHeader({required this.title, this.isLive = false});
  final String title;
  final bool isLive;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: AppTextStyles.titleSm),
        const Spacer(),
        if (isLive) ...[
          Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.teal, shape: BoxShape.circle)),
          const SizedBox(width: AppSpacing.xs),
          Text(context.l10n.liveLabel, style: const TextStyle(color: AppColors.teal, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ],
    );
  }
}


class _FlagCard extends StatelessWidget {
  const _FlagCard({required this.flagColor, this.flagConfidence, this.onTap});
  final String flagColor;
  final double? flagConfidence;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (color, label) = flagInfo(l10n, flagColor);
    final confidence = flagConfidence ?? 0.7;

    return Material(
      color: Colors.transparent,
      borderRadius: AppRadii.cardLg,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.cardLg,
        child: _SectionCard(
          child: Row(
        children: [
          Container(width: 14, height: 14, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.titleMd),
                const SizedBox(height: 3),
                Row(
                  children: [
                    if (flagColor != 'unknown') ...[
                      Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.teal, shape: BoxShape.circle)),
                      const SizedBox(width: AppSpacing.xs),
                    ],
                    Text(
                      flagColor != 'unknown'
                          ? l10n.flagLiveTap
                          : l10n.flagProposeTap,
                      style: AppTextStyles.secondary,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SizedBox(
                width: 80,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: confidence,
                    backgroundColor: color.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(context.l10n.confidencePct((confidence * 100).round()), style: AppTextStyles.hintXs),
            ],
          ),
        ],
          ),
        ),
      ),
    );
  }

}

class _OccupancyCard extends ConsumerStatefulWidget {
  const _OccupancyCard({
    required this.slug,
    this.occupancy,
    required this.occupancyLevel,
    required this.onImHere,
    required this.sending,
  });
  final String slug;
  final OccupancyData? occupancy;
  final String occupancyLevel;
  final VoidCallback onImHere;
  final bool sending;

  @override
  ConsumerState<_OccupancyCard> createState() => _OccupancyCardState();
}

class _OccupancyCardState extends ConsumerState<_OccupancyCard> {
  int? _votedLevel;
  bool _submitting = false;

  Color _levelColor(String level) => switch (level) {
    'low'    => AppColors.flagGreen,
    'medium' => AppColors.sand,
    'high'   => AppColors.coral,
    _        => AppColors.textHint,
  };

  String _levelLabel(AppLocalizations l10n, String level) => switch (level) {
    'low'    => l10n.occupancyLow,
    'medium' => l10n.occupancyMedium,
    'high'   => l10n.occupancyHigh,
    _        => l10n.occupancyUnknown,
  };

  Future<void> _submitVote(int level) async {
    if (_submitting || _votedLevel != null) return;
    setState(() => _submitting = true);
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(beachRepositoryProvider).submitOccupancyReport(widget.slug, level);
      if (!mounted) return;
      setState(() { _votedLevel = level; _submitting = false; });
      messenger.showSnackBar(SnackBar(
        content: Text(l10n.occupancyVoted),
        backgroundColor: AppColors.teal,
        duration: const Duration(seconds: 2),
      ));
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      final code = (e.response?.data as Map?)?.cast<String, dynamic>()['detail']?['code'] as String?;
      final msg = switch (code) {
        'occupancy_already_reported' => l10n.occupancyAlreadyVoted,
        'occupancy_must_be_at_beach' => l10n.occupancyMustBePresent,
        _                            => l10n.connectionError,
      };
      if (code == 'occupancy_already_reported') setState(() => _votedLevel = -1);
      messenger.showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.coral,
        duration: const Duration(seconds: 3),
      ));
    } catch (_) {
      if (mounted) {
        setState(() => _submitting = false);
        messenger.showSnackBar(SnackBar(
          content: Text(context.l10n.connectionError),
          backgroundColor: AppColors.coral,
          duration: const Duration(seconds: 2),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final level = widget.occupancyLevel;
    final color = _levelColor(level);
    final label = _levelLabel(l10n, level);
    final userCount = widget.occupancy?.userCount ?? 0;
    final reportCount = widget.occupancy?.reportCount ?? 0;

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(title: l10n.labelOccupancy, isLive: true),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _OccupancyMeter(level: level, color: color),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppTextStyles.titleMd.copyWith(color: color)),
                    const SizedBox(height: 4),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
                        children: [
                          TextSpan(
                            text: userCount > 0 ? '${l10n.occupancyAppUsers(userCount)} ' : '${l10n.fewUsersNote} ',
                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                          ),
                          TextSpan(text: l10n.occupancyNote),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: widget.sending ? null : widget.onImHere,
                          icon: widget.sending
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                              : const Text('📍', style: TextStyle(fontSize: 14)),
                          label: Text(widget.sending ? l10n.updating : l10n.updatePresence),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                            shape: RoundedRectangleBorder(borderRadius: AppRadii.cardXl),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _VoteChip(
                          votedLevel: _votedLevel,
                          submitting: _submitting,
                          onTap: () => _showVoteSheet(context, l10n, reportCount),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  void _showVoteSheet(BuildContext context, AppLocalizations l10n, int reportCount) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(color: AppColors.borderLight, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text(l10n.occupancyVotePrompt, style: AppTextStyles.titleSm),
            if (reportCount > 0) ...[
              const SizedBox(height: 4),
              Text(l10n.occupancyReports(reportCount), style: AppTextStyles.secondarySm),
            ],
            const SizedBox(height: 16),
            _OccupancyVoteRow(
              votedLevel: _votedLevel,
              submitting: _submitting,
              onVote: (level) {
                Navigator.of(context).pop();
                _submitVote(level);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _VoteChip extends StatelessWidget {
  const _VoteChip({required this.votedLevel, required this.submitting, required this.onTap});
  final int? votedLevel;
  final bool submitting;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final voted = votedLevel != null;
    return GestureDetector(
      onTap: voted ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: voted ? AppColors.primary.withValues(alpha: 0.06) : Colors.transparent,
          borderRadius: AppRadii.cardXl,
          border: Border.all(
            color: voted ? AppColors.primary.withValues(alpha: 0.15) : AppColors.primary.withValues(alpha: 0.3),
          ),
        ),
        child: submitting
            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
            : Icon(
                voted ? Icons.check_rounded : Icons.how_to_vote_outlined,
                size: 16,
                color: voted ? AppColors.teal : AppColors.primary,
              ),
      ),
    );
  }
}

class _OccupancyMeter extends StatelessWidget {
  const _OccupancyMeter({required this.level, required this.color});
  final String level;
  final Color color;

  int get _filledCount => switch (level) {
    'low'    => 2,
    'medium' => 3,
    'high'   => 5,
    _        => 0,
  };

  @override
  Widget build(BuildContext context) {
    final filled = _filledCount;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) => Padding(
        padding: EdgeInsets.only(right: i < 4 ? 4 : 0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 10, height: 40,
          decoration: BoxDecoration(
            color: i < filled ? color : AppColors.borderLight,
            borderRadius: BorderRadius.circular(5),
          ),
        ),
      )),
    );
  }
}

class _OccupancyVoteRow extends StatelessWidget {
  const _OccupancyVoteRow({
    required this.votedLevel,
    required this.submitting,
    required this.onVote,
  });
  final int? votedLevel;
  final bool submitting;
  final void Function(int) onVote;

  static const _colors = [
    AppColors.flagGreen,
    AppColors.flagGreen,
    AppColors.sand,
    AppColors.coral,
    AppColors.flagRed,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final labels = [
      l10n.occupancyVote1, l10n.occupancyVote2, l10n.occupancyVote3,
      l10n.occupancyVote4, l10n.occupancyVote5,
    ];
    final alreadyVoted = votedLevel != null;

    return Row(
      children: List.generate(5, (i) {
        final level = i + 1;
        final isSelected = votedLevel == level;
        final color = _colors[i];

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < 4 ? 4 : 0),
            child: GestureDetector(
              onTap: alreadyVoted || submitting ? null : () => onVote(level),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius: AppRadii.cardMd,
                  border: Border.all(
                    color: isSelected ? color : AppColors.borderLight,
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (submitting && !alreadyVoted)
                      const SizedBox(
                        width: 12, height: 12,
                        child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.textHint),
                      )
                    else
                      Icon(
                        isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                        size: 14,
                        color: isSelected ? color : AppColors.textHint,
                      ),
                    const SizedBox(height: 4),
                    Text(
                      labels[i],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? color : alreadyVoted ? AppColors.textHint : AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _WeatherCard extends StatelessWidget {
  const _WeatherCard({this.weather});
  final WeatherPoint? weather;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(title: l10n.sectionWeather, isLive: true),
          const SizedBox(height: AppSpacing.md),
          metricRow([
            MetricCell(
              icon: Icons.thermostat_outlined,
              value: weather?.currentTemp != null
                  ? '${weather!.currentTemp!.round()}°C'
                  : weather?.maxTemp != null
                      ? '${weather!.minTemp!.round()}-${weather!.maxTemp!.round()}°C'
                      : '--',
              subLabel: weather?.currentTemp != null && weather?.maxTemp != null
                  ? '${weather!.minTemp!.round()}-${weather!.maxTemp!.round()}°C'
                  : null,
              label: l10n.labelTemperature, iconColor: AppColors.coral,
            ),
            _WindCell(
              speedKmh: weather?.windSpeed,
              dirDeg: weather?.windDirDeg,
              dirCardinal: weather?.windDirCode != null ? windDirectionLabel(l10n, weather!.windDirCode) : null,
              gusts: weather?.windGusts,
            ),
            MetricCell(
              icon: Icons.umbrella_outlined,
              value: weather?.precipitationProb != null ? '${weather!.precipitationProb!.round()}%' : '--',
              label: l10n.labelRain, iconColor: AppColors.waterIcon,
            ),
          ]),
          if (weather?.apparentTemp != null || weather?.humidity != null || weather?.uvIndex != null) ...[
            const SizedBox(height: AppSpacing.sm),
            metricRow([
              if (weather?.apparentTemp != null)
                MetricCell(
                  icon: Icons.thermostat,
                  value: '${weather!.apparentTemp!.round()}°C',
                  label: l10n.weatherFeelsLike, iconColor: AppColors.coral,
                ),
              if (weather?.humidity != null)
                MetricCell(
                  icon: Icons.water_drop_outlined,
                  value: '${weather!.humidity!.round()}%',
                  label: l10n.weatherHumidity, iconColor: AppColors.waterIcon,
                ),
              if (weather?.uvIndex != null)
                MetricCell(
                  icon: Icons.wb_sunny_outlined,
                  value: '${weather!.uvIndex!.round()}',
                  label: l10n.weatherUv, iconColor: AppColors.uvIcon,
                ),
            ]),
          ],
        ],
      ),
    );
  }
}

class _WindCell extends StatelessWidget {
  const _WindCell({this.speedKmh, this.dirDeg, this.dirCardinal, this.gusts});
  final double? speedKmh;
  final double? dirDeg;
  final String? dirCardinal;
  final double? gusts;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.air, color: AppColors.teal, size: 22),
        const SizedBox(height: 6),
        Text(
          speedKmh != null ? '${speedKmh!.round()} km/h' : '--',
          style: AppTextStyles.titleMd,
        ),
        if (dirCardinal != null)
          Text(dirCardinal!, style: AppTextStyles.secondarySm),
        if (gusts != null)
          Builder(builder: (ctx) => Text(ctx.l10n.windGusts(gusts!.round()), style: AppTextStyles.secondarySm.copyWith(fontSize: 10))),
        Builder(builder: (ctx) => Text(ctx.l10n.weatherWind, style: AppTextStyles.secondarySm)),
      ],
    );
  }
}


class _SeaCard extends StatelessWidget {
  const _SeaCard({this.sea});
  final SeaPoint? sea;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(title: l10n.seaConditionsTitle, isLive: true),
          const SizedBox(height: AppSpacing.md),
          metricRow([
            MetricCell(
              icon: Icons.waves,
              value: sea?.waveHeightMax != null ? '${sea!.waveHeightMax!.toStringAsFixed(1)}m' : '--',
              label: l10n.weatherWaves, iconColor: AppColors.teal,
            ),
            MetricCell(
              icon: Icons.schedule,
              value: sea?.wavePeriodMax != null ? '${sea!.wavePeriodMax!.round()}s' : '--',
              label: l10n.seaWavePeriod, iconColor: AppColors.primary,
            ),
            MetricCell(
              icon: Icons.thermostat_outlined,
              value: sea?.seaTemp != null ? '${sea!.seaTemp!.round()}°C' : '--',
              label: l10n.seaTempLabel, iconColor: AppColors.coral,
            ),
          ]),
        ],
      ),
    );
  }
}

class _TidesCard extends StatelessWidget {
  const _TidesCard({required this.tidesData, this.onViewAll});
  final TidesData tidesData;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    final tides = tidesData.entries;
    final l10n = context.l10n;
    final apiDirection = tidesData.direction ?? 'steady';
    final isRising = apiDirection == 'rising';
    final directionLabel = isRising ? l10n.tideDirRisingCap : apiDirection == 'falling' ? l10n.tideDirFallingCap : l10n.tideDirSteadyCap;

    final nextTide = findNextTide(tides);

    final currentH = tidesData.currentHeight;
    final displayH = currentH != null
        ? '${currentH.toStringAsFixed(2)}m'
        : (nextTide != null ? '${nextTide.height.toStringAsFixed(1)}m' : '--');
    final accentColor = (currentH ?? 0) > 1.95 ? AppColors.teal : const Color(0xFFE8C98A);

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.waves, color: AppColors.teal, size: 16),
              const SizedBox(width: 6),
              Text(l10n.tidesCardTitle, style: AppTextStyles.titleSm),
              const Spacer(),
              GestureDetector(
                onTap: onViewAll,
                child: Text(l10n.tidesViewFull, style: AppTextStyles.tealLabel),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(isRising ? Icons.arrow_upward : Icons.arrow_downward, color: accentColor, size: 14),
                    const SizedBox(width: 3),
                    Text(directionLabel, style: TextStyle(color: accentColor, fontSize: 12, fontWeight: FontWeight.w600)),
                  ]),
                  const SizedBox(height: 2),
                  Text(displayH, style: AppTextStyles.titleXl),
                  if (nextTide != null)
                    Text(
                      '${tideTypeLabel(context.l10n, nextTide.type)} ${context.l10n.atTimePrep} ${nextTide.time}',
                      style: AppTextStyles.secondary,
                    ),
                ],
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: SizedBox(
                  height: 70,
                  child: CustomPaint(
                    painter: TideChartPainter(tides: tides, currentHeight: currentH, accentColor: accentColor),
                  ),
                ),
              ),
            ],
          ),
          if (tides.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(height: 1, color: AppColors.borderLight),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: tides.take(4).map((t) => TideTimeCell(entry: t)).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _WaterQualityCard extends StatelessWidget {
  const _WaterQualityCard({this.quality});
  final WaterQuality? quality;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (color, label) = waterQualityInfo(l10n, quality?.qualityCode);
    final cacheStr = _cacheStr(l10n, quality);
    final eeaStr = _eeaStr(l10n, quality);

    return _SectionCard(
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: AppColors.teal.withValues(alpha: 0.12), borderRadius: AppRadii.cardMd),
            child: const Icon(Icons.water_drop_outlined, color: AppColors.teal, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.l10n.waterQualityTitle, style: AppTextStyles.titleSm),
                if (eeaStr != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(children: [
                      const Icon(Icons.calendar_today_outlined, size: 11, color: AppColors.textHint),
                      const SizedBox(width: 3),
                      Text(eeaStr, style: AppTextStyles.hintSm),
                    ]),
                  ),
                if (cacheStr != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Row(children: [
                      const Icon(Icons.access_time, size: 11, color: AppColors.textHint),
                      const SizedBox(width: 3),
                      Text(cacheStr, style: AppTextStyles.hintSm),
                    ]),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: AppRadii.cardXl,
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_outline, color: color, size: 14),
                const SizedBox(width: AppSpacing.xs),
                Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String? _eeaStr(AppLocalizations l10n, WaterQuality? q) {
    if (q == null || q.sampledAt == null) return null;
    return l10n.waterQualityLastSampled(q.sampledAt!);
  }

  String? _cacheStr(AppLocalizations l10n, WaterQuality? q) {
    if (q == null || q.dataSource == 'live') return null;
    if (q.snapshotAt == null) return l10n.waterQualityCached;
    try {
      final dt = DateTime.parse(q.snapshotAt!);
      final diff = DateTime.now().difference(dt);
      if (diff.inHours < 1)  return l10n.waterQualityCachedMins(diff.inMinutes);
      if (diff.inHours < 48) return l10n.waterQualityCachedHours(diff.inHours);
      return l10n.waterQualityCachedDays(diff.inDays);
    } catch (_) { return l10n.waterQualityCached; }
  }
}

class _TransportCard extends StatelessWidget {
  const _TransportCard({required this.transport, this.isLoading = false});
  final BeachTransportInfo transport;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(title: l10n.transportCardTitle, isLive: !isLoading),
          if (isLoading) ...[
            const SizedBox(height: AppSpacing.lg),
            const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppColors.teal, strokeWidth: 2))),
            const SizedBox(height: AppSpacing.lg),
          ] else if (transport.stops.isEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Center(child: Text(l10n.transportNoInfo, style: AppTextStyles.secondaryMd)),
          ] else if (!transport.hasDepartures) ...[
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.schedule, size: 14, color: AppColors.textHint),
              const SizedBox(width: 6),
              Text(l10n.transportNoDepartures, style: AppTextStyles.secondaryMd),
            ]),
            const SizedBox(height: AppSpacing.xs),
            Center(
              child: Text(
                transport.stops.length == 1
                    ? l10n.transportNearbyStop(1)
                    : l10n.transportNearbyStops(transport.stops.length),
                style: AppTextStyles.hintSm,
              ),
            ),
          ] else ...[
            const SizedBox(height: AppSpacing.md),
            ...transport.directions.where((d) => d.departures.isNotEmpty).map(
              (d) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _DirectionGroup(direction: d),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DirectionGroup extends StatelessWidget {
  const _DirectionGroup({required this.direction});
  final TransportDirection direction;

  @override
  Widget build(BuildContext context) {
    final departures = direction.departures.take(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Direction header
        Row(children: [
          const Icon(Icons.arrow_forward, size: 13, color: AppColors.teal),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              direction.headsign,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ]),
        const SizedBox(height: 6),
        // Departure chips
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: departures.map((dep) => _DepartureChip(dep: dep)).toList(),
        ),
      ],
    );
  }
}

class _DepartureChip extends StatelessWidget {
  const _DepartureChip({required this.dep});
  final TransportDeparture dep;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: dep.isRealtime ? AppColors.teal.withValues(alpha: 0.10) : AppColors.background,
        borderRadius: AppRadii.cardSm,
        border: Border.all(
          color: dep.isRealtime ? AppColors.teal.withValues(alpha: 0.35) : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Route badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(color: AppColors.coral, borderRadius: BorderRadius.circular(4)),
            child: Text(dep.routeShortName, style: AppTextStyles.whiteLabel),
          ),
          const SizedBox(width: 5),
          Text(dep.displayTime, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
          if (dep.isRealtime) ...[
            const SizedBox(width: AppSpacing.xs),
            Container(width: 5, height: 5, decoration: const BoxDecoration(color: AppColors.teal, shape: BoxShape.circle)),
          ],
        ],
      ),
    );
  }
}

class _PlanTripButton extends StatelessWidget {
  const _PlanTripButton({required this.beach});
  final BeachSummary beach;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => context.push(AppRoutes.beachTransport(beach.slug), extra: beach),
        icon: const Icon(Icons.directions_bus, size: 18),
        label: Text(context.l10n.transportViewSchedules),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: AppRadii.cardButton),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
    );
  }
}

class _CommunityAlertsCard extends StatelessWidget {
  const _CommunityAlertsCard({required this.reports, required this.beach});
  final List<BeachReport> reports;
  final BeachSummary beach;

  @override
  Widget build(BuildContext context) {
    final visible = reports.take(5).toList();

    return Column(
      children: [
        Row(
          children: [
            const Icon(Icons.warning_amber_outlined, color: AppColors.coral, size: 18),
            const SizedBox(width: 6),
            Text(context.l10n.communityAlertsSectionTitle, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.8)),
            const SizedBox(width: 6),
            if (reports.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(color: AppColors.coral, borderRadius: AppRadii.cardChip),
                child: Text('${reports.length}', style: AppTextStyles.whiteLabel),
              ),
            const Spacer(),
            GestureDetector(
              onTap: () => context.push(AppRoutes.beachAlerts(beach.slug), extra: beach),
              child: Text(context.l10n.viewAll, style: AppTextStyles.tealLabel),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (visible.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: AppRadii.cardMd, border: Border.all(color: Colors.black.withValues(alpha: 0.06))),
            child: Center(child: Text(context.l10n.noAlerts, style: AppTextStyles.secondaryMd)),
          )
        else
          ...visible.map((r) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AlertItem(
              report: r,
              trailing: SeverityDotsIndicator(
                filled: ((r.upvotes / (r.upvotes + r.downvotes).clamp(1, 999)) * 3).round().clamp(0, 3),
                color: AppColors.flagGreen,
              ),
            ),
          )),
      ],
    );
  }
}


// Presence section

class _PresenceSection extends ConsumerWidget {
  const _PresenceSection({required this.slug});
  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presence = ref.watch(beachPresenceProvider(slug)).value;
    if (presence == null || presence.userCount == 0) return const SizedBox.shrink();

    final shown = presence.users.take(5).toList();
    final overflow = presence.userCount - shown.length;
    final hasVisible = shown.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.people_alt_outlined, color: AppColors.teal, size: 18),
            const SizedBox(width: 6),
            Text(
              context.l10n.presenceSectionTitle,
              style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700,
                color: AppColors.textSecondary, letterSpacing: 0.8,
              ),
            ),
            const SizedBox(width: 8),
            Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.teal, shape: BoxShape.circle)),
            const SizedBox(width: 4),
            Text(context.l10n.liveLabel, style: const TextStyle(color: AppColors.teal, fontSize: 11, fontWeight: FontWeight.w600)),
            const Spacer(),
            GestureDetector(
              onTap: () => _showPresencePeople(context, presence),
              child: Text(context.l10n.presenceViewAll, style: AppTextStyles.tealLabel),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Material(
          color: Colors.transparent,
          borderRadius: AppRadii.cardLg,
          child: InkWell(
            onTap: () => _showPresencePeople(context, presence),
            borderRadius: AppRadii.cardLg,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppRadii.cardLg,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.07),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: hasVisible
                  ? _PresenceWithAvatars(shown: shown, overflow: overflow, total: presence.userCount)
                  : _PresenceAllPrivate(total: presence.userCount),
            ),
          ),
        ),
      ],
    );
  }
}

class _PresenceWithAvatars extends StatelessWidget {
  const _PresenceWithAvatars({
    required this.shown,
    required this.overflow,
    required this.total,
  });
  final List<PresenceUser> shown;
  final int overflow;
  final int total;

  @override
  Widget build(BuildContext context) {
    const avatarSize = 45.0;
    const step = 30.0; // overlap: each avatar starts 30px after the previous
    final itemCount = shown.length + (overflow > 0 ? 1 : 0);
    final stackWidth = itemCount <= 1
        ? avatarSize
        : (itemCount - 1) * step + avatarSize;

    final l10n = context.l10n;
    final countLabel = total == 1 ? l10n.presencePerson : l10n.presencePeople(total);
    final sharedLabel = shown.length == 1
        ? l10n.presenceSharedProfile1
        : l10n.presenceSharedProfiles(shown.length);
    final subtitle = overflow > 0
        ? '$countLabel · $sharedLabel'
        : (total == 1 ? l10n.presencePersonHere : l10n.presencePeopleHere(total));

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: stackWidth,
          height: avatarSize,
          child: Stack(
            children: [
              for (int i = 0; i < shown.length; i++)
                Positioned(
                  left: i * step,
                  child: _AvatarBubble(user: shown[i]),
                ),
              if (overflow > 0)
                Positioned(
                  left: shown.length * step,
                  child: _OverflowBubble(count: overflow),
                ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            subtitle,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _PresenceAllPrivate extends StatelessWidget {
  const _PresenceAllPrivate({required this.total});
  final int total;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final label = total == 1 ? l10n.presenceEmptyTitle1 : l10n.presenceEmptyTitleN(total);
    return Row(
      children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.06),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.lock_outline, color: AppColors.textSecondary, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary)),
              const SizedBox(height: 2),
              Text(
                l10n.presencePrivateNote,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AvatarBubble extends StatelessWidget {
  const _AvatarBubble({required this.user});
  final PresenceUser user;

  @override
  Widget build(BuildContext context) {
    final initials = getInitials(user.displayName);
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 45,
          height: 45,
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        ),
        UserAvatarWidget(
          size: 40,
          avatarId: user.avatarId,
          initials: initials.isNotEmpty ? initials : '?',
        ),
      ],
    );
  }
}

class _OverflowBubble extends StatelessWidget {
  const _OverflowBubble({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) => Stack(
    alignment: Alignment.center,
    children: [
      Container(
        width: 45,
        height: 45,
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      ),
      Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.09),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            '+$count',
            style: const TextStyle(
              color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    ],
  );
}


// Presence people sheet

void _showPresencePeople(BuildContext context, MapBeachPresence presence) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useRootNavigator: true,
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      snap: true,
      snapSizes: const [0.6, 0.92],
      builder: (_, scrollController) => _PresencePeopleSheet(
        presence: presence,
        scrollController: scrollController,
      ),
    ),
  );
}

class _PresencePeopleSheet extends StatelessWidget {
  const _PresencePeopleSheet({
    required this.presence,
    required this.scrollController,
  });
  final MapBeachPresence presence;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final privateCount = presence.userCount - presence.users.length;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xxl)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Row(
              children: [
                const Icon(Icons.people_alt_outlined, color: AppColors.teal, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.l10n.presenceSheetTitle, style: AppTextStyles.titleMd),
                      Text(presence.beachName, style: AppTextStyles.secondary),
                    ],
                  ),
                ),
                // Live count badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: 0.12),
                    borderRadius: AppRadii.cardXl,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6, height: 6,
                        decoration: const BoxDecoration(color: AppColors.teal, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        presence.userCount == 1 ? context.l10n.presencePerson : context.l10n.presencePeople(presence.userCount),
                        style: const TextStyle(
                          color: AppColors.teal, fontWeight: FontWeight.w700, fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.borderLight),
          Expanded(
            child: presence.users.isEmpty
                ? _PresenceSheetEmpty(total: presence.userCount)
                : ListView.separated(
                    controller: scrollController,
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).padding.bottom + 24,
                    ),
                    itemCount: presence.users.length + (privateCount > 0 ? 1 : 0),
                    separatorBuilder: (_, i) => i < presence.users.length - 1
                        ? const Divider(height: 1, indent: 72, color: AppColors.borderLight)
                        : const SizedBox.shrink(),
                    itemBuilder: (_, i) {
                      if (i < presence.users.length) {
                        return _PresencePersonTile(user: presence.users[i]);
                      }
                      return _PresencePrivateFooter(count: privateCount);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _PresencePersonTile extends StatelessWidget {
  const _PresencePersonTile({required this.user});
  final PresenceUser user;

  @override
  Widget build(BuildContext context) {
    final isNamed = user.displayName != null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
      child: Row(
        children: [
          _AvatarBubble(user: user),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              user.displayName ?? context.l10n.presenceAnonymousUser,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isNamed ? FontWeight.w500 : FontWeight.normal,
                color: isNamed ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ),
          if (!isNamed)
            const Icon(Icons.person_outline_rounded, size: 16, color: AppColors.textHint),
        ],
      ),
    );
  }
}

class _PresencePrivateFooter extends StatelessWidget {
  const _PresencePrivateFooter({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(20, 10, 20, 0),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: AppColors.primary.withValues(alpha: 0.05),
      borderRadius: AppRadii.cardMd,
    ),
    child: Row(
      children: [
        const Icon(Icons.lock_outline, size: 15, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Text(
          count == 1 ? context.l10n.presencePrivateFooter1(count) : context.l10n.presencePrivateFooterN(count),
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
      ],
    ),
  );
}

class _PresenceSheetEmpty extends StatelessWidget {
  const _PresenceSheetEmpty({required this.total});
  final int total;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_outline, size: 28, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          Text(
            total == 1 ? context.l10n.presenceEmptyTitle1 : context.l10n.presenceEmptyTitleN(total),
            style: AppTextStyles.titleSm,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.presenceEmptyPrivate,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

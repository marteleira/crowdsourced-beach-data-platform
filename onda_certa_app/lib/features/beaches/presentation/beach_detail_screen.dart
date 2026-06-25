import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/presence/heartbeat_service.dart';
import '../data/beach_provider.dart';
import '../domain/beach_models.dart';
import '../../../features/community/presentation/flag_confirmation_sheet.dart';
import '../../../features/community/presentation/flag_proposal_sheet.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/beach_helpers.dart';
import '../../../shared/utils/format_helpers.dart';
import '../../../shared/utils/ui_helpers.dart';
import '../../../shared/widgets/beach_cover_image.dart';
import '../../../shared/widgets/metric_cell.dart';
import '../../../shared/widgets/alert_item.dart';
import '../../../shared/widgets/severity_dots.dart';
import '../../../shared/widgets/tide_chart.dart';
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
                try {
                  await ref.read(favouritesProvider.notifier).toggle(widget.beach);
                } catch (_) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Erro ao actualizar favorito'), backgroundColor: Colors.red),
                  );
                }
              },
            ),
            if (detail.isLoading && detail.value == null)
              const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: AppColors.teal, strokeWidth: 2.5)))
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
                  showGuestSnackbar(context, AppStrings.guestConfirmFlag);
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
                  showGuestSnackbar(context, AppStrings.guestProposeFlag);
                  return;
                }
                showFlagProposalSheet(context, widget.beach);
              },
      ),
      const SizedBox(height: AppSpacing.md),
      _OccupancyCard(
        occupancy: d?.status.occupancy,
        occupancyLevel: d?.status.occupancy.level ?? widget.beach.occupancyLevel,
        maxCapacity: d?.detail.maxCapacity,
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
    ref.read(selectedTabProvider.notifier).set(2);
    context.pop();
  }

  Future<void> _sendHeartbeat() async {
    if (_sendingHeartbeat) return;
    setState(() => _sendingHeartbeat = true);
    try {
      final nearest = await sendHeartbeatForCurrentPosition(ref);
      if (nearest == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Estás demasiado longe de uma praia para registar presença.'),
            duration: Duration(seconds: 2),
            backgroundColor: AppColors.coral,
          ));
        }
        return;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Presença registada!'),
          duration: Duration(seconds: 2),
          backgroundColor: AppColors.teal,
        ));
        // Refresh detail to update occupancy count
        ref.invalidate(beachFullDetailProvider(nearest.slug));
      }
    } catch (_) {
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
        child: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.35), shape: BoxShape.circle),
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: GestureDetector(
            onTap: onFavourite,
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.35), shape: BoxShape.circle),
              child: Icon(
                isFavourite ? Icons.favorite : Icons.favorite_border,
                color: isFavourite ? AppColors.coral : Colors.white,
                size: 18,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8, right: 12),
          child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.35), shape: BoxShape.circle),
            child: const Icon(Icons.ios_share, color: Colors.white, size: 18),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              beach.name,
              style: const TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700,
                shadows: [Shadow(blurRadius: 6, color: Colors.black45)],
              ),
            ),
            Text(
              beach.municipality ?? 'Arrábida',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12, fontWeight: FontWeight.w400),
            ),
          ],
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
      borderRadius: BorderRadius.circular(16),
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
          const Text('live', style: TextStyle(color: AppColors.teal, fontSize: 11, fontWeight: FontWeight.w600)),
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
    final (color, label) = flagInfo(flagColor);
    final confidence = flagConfidence ?? 0.7;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
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
                          ? 'live · Toca para confirmar'
                          : 'Toca para propor a bandeira',
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
              Text('${(confidence * 100).round()}% conf.', style: AppTextStyles.hintXs),
            ],
          ),
        ],
          ),
        ),
      ),
    );
  }

}

class _OccupancyCard extends StatelessWidget {
  const _OccupancyCard({
    this.occupancy, required this.occupancyLevel, this.maxCapacity,
    required this.onImHere, required this.sending,
  });
  final OccupancyData? occupancy;
  final String occupancyLevel;
  final int? maxCapacity;
  final VoidCallback onImHere;
  final bool sending;

  @override
  Widget build(BuildContext context) {
    final userCount = occupancy?.userCount ?? 0;
    final (pct, levelLabel, color) = occupancyInfo(occupancyLevel, userCount, maxCapacity: maxCapacity);

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(title: 'Ocupação', isLive: true),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _DonutChart(percentage: pct, label: levelLabel, color: color),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
                        children: [
                          TextSpan(
                            text: userCount > 0 ? '$userCount pessoas ' : 'Poucos utilizadores ',
                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                          ),
                          const TextSpan(text: 'a usar a app nesta praia nos últimos 20 min. Estimativa aproximada.'),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    OutlinedButton.icon(
                      onPressed: sending ? null : onImHere,
                      icon: sending
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                          : const Text('📍', style: TextStyle(fontSize: 14)),
                      label: Text(sending ? 'A atualizar...' : 'Atualizar presença'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
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

}

class _DonutChart extends StatelessWidget {
  const _DonutChart({required this.percentage, required this.label, required this.color});
  final double percentage;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80, height: 80,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(size: const Size(80, 80), painter: _DonutPainter(percentage: percentage, color: color)),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${(percentage * 100).round()}%',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary)),
              Text(label,
                  style: AppTextStyles.secondaryXs,
                  textAlign: TextAlign.center),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({required this.percentage, required this.color});
  final double percentage;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const strokeW = 10.0;
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawArc(rect, -pi / 2, 2 * pi, false,
      Paint()..color = AppColors.borderLight..style = PaintingStyle.stroke..strokeWidth = strokeW..strokeCap = StrokeCap.round);
    if (percentage > 0) {
      canvas.drawArc(rect, -pi / 2, 2 * pi * percentage, false,
        Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = strokeW..strokeCap = StrokeCap.round);
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) => old.percentage != percentage || old.color != color;
}

class _WeatherCard extends StatelessWidget {
  const _WeatherCard({this.weather});
  final WeatherPoint? weather;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(title: 'Meteorologia', isLive: true),
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
              label: 'Temperatura', iconColor: AppColors.coral,
            ),
            _WindCell(
              speedKmh: weather?.windSpeed,
              dirDeg: weather?.windDirDeg,
              dirCardinal: weather?.windDir,
              gusts: weather?.windGusts,
            ),
            MetricCell(
              icon: Icons.umbrella_outlined,
              value: weather?.precipitationProb != null ? '${weather!.precipitationProb!.round()}%' : '--',
              label: 'Chuva', iconColor: AppColors.waterIcon,
            ),
          ]),
          if (weather?.apparentTemp != null || weather?.humidity != null || weather?.uvIndex != null) ...[
            const SizedBox(height: AppSpacing.sm),
            metricRow([
              if (weather?.apparentTemp != null)
                MetricCell(
                  icon: Icons.thermostat,
                  value: '${weather!.apparentTemp!.round()}°C',
                  label: 'Sensação', iconColor: AppColors.coral,
                ),
              if (weather?.humidity != null)
                MetricCell(
                  icon: Icons.water_drop_outlined,
                  value: '${weather!.humidity!.round()}%',
                  label: 'Humidade', iconColor: AppColors.waterIcon,
                ),
              if (weather?.uvIndex != null)
                MetricCell(
                  icon: Icons.wb_sunny_outlined,
                  value: '${weather!.uvIndex!.round()}',
                  label: 'UV', iconColor: AppColors.uvIcon,
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
          Text('raj. ${gusts!.round()} km/h', style: AppTextStyles.secondarySm.copyWith(fontSize: 10)),
        Text('Vento', style: AppTextStyles.secondarySm),
      ],
    );
  }
}


class _SeaCard extends StatelessWidget {
  const _SeaCard({this.sea});
  final SeaPoint? sea;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(title: 'Condições do Mar', isLive: true),
          const SizedBox(height: AppSpacing.md),
          metricRow([
            MetricCell(
              icon: Icons.waves,
              value: sea?.waveHeightMax != null ? '${sea!.waveHeightMax!.toStringAsFixed(1)}m' : '--',
              label: 'Ondas', iconColor: AppColors.teal,
            ),
            MetricCell(
              icon: Icons.schedule,
              value: sea?.wavePeriodMax != null ? '${sea!.wavePeriodMax!.round()}s' : '--',
              label: 'Período', iconColor: AppColors.primary,
            ),
            MetricCell(
              icon: Icons.thermostat_outlined,
              value: sea?.seaTemp != null ? '${sea!.seaTemp!.round()}°C' : '--',
              label: 'Temp. Mar', iconColor: AppColors.coral,
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
    final apiDirection = tidesData.direction ?? 'steady';
    final isRising = apiDirection == 'rising';
    final directionLabel = isRising ? 'Subindo' : apiDirection == 'falling' ? 'Descendo' : 'Estável';

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
              const Text('Marés Hoje', style: AppTextStyles.titleSm),
              const Spacer(),
              GestureDetector(
                onTap: onViewAll,
                child: const Text('Vista completa →', style: AppTextStyles.tealLabel),
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
                      '${tideTypeLabel(nextTide.type)} às ${nextTide.time}',
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
    final (color, label) = waterQualityInfo(quality?.classification);
    final cacheStr = _cacheStr(quality);
    final eeaStr = _eeaStr(quality);

    return _SectionCard(
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: AppColors.teal.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.water_drop_outlined, color: AppColors.teal, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Qualidade da Água', style: AppTextStyles.titleSm),
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
              borderRadius: BorderRadius.circular(20),
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

  String? _eeaStr(WaterQuality? q) {
    if (q == null || q.sampledAt == null) return null;
    return 'Ultima avaliação em ${q.sampledAt}';
  }

  String? _cacheStr(WaterQuality? q) {
    if (q == null || q.dataSource == 'live') return null;
    if (q.snapshotAt == null) return 'dados em cache';
    try {
      final dt = DateTime.parse(q.snapshotAt!);
      final diff = DateTime.now().difference(dt);
      if (diff.inHours < 1)  return 'cache ${diff.inMinutes} min atrás';
      if (diff.inHours < 48) return 'cache ${diff.inHours}h atrás';
      return 'cache ${diff.inDays}d atrás';
    } catch (_) { return 'dados em cache'; }
  }
}

class _TransportCard extends StatelessWidget {
  const _TransportCard({required this.transport, this.isLoading = false});
  final BeachTransportInfo transport;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(title: 'Próximas Partidas', isLive: !isLoading),
          if (isLoading) ...[
            const SizedBox(height: AppSpacing.lg),
            const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppColors.teal, strokeWidth: 2))),
            const SizedBox(height: AppSpacing.lg),
          ] else if (transport.stops.isEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            const Center(child: Text('Sem informação de transportes para esta praia', style: AppTextStyles.secondaryMd)),
          ] else if (!transport.hasDepartures) ...[
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.schedule, size: 14, color: AppColors.textHint),
              const SizedBox(width: 6),
              const Text('Sem partidas previstas', style: AppTextStyles.secondaryMd),
            ]),
            const SizedBox(height: AppSpacing.xs),
            Center(
              child: Text(
                '${transport.stops.length} paragem${transport.stops.length > 1 ? 's' : ''} próxima${transport.stops.length > 1 ? 's' : ''}',
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
        borderRadius: BorderRadius.circular(8),
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
        onPressed: () => context.push('/beach/${beach.slug}/transport', extra: beach),
        icon: const Icon(Icons.directions_bus, size: 18),
        label: const Text('Ver horários completos →'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
            const Text('ALERTAS DA COMUNIDADE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.8)),
            const SizedBox(width: 6),
            if (reports.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(color: AppColors.coral, borderRadius: BorderRadius.circular(10)),
                child: Text('${reports.length}', style: AppTextStyles.whiteLabel),
              ),
            const Spacer(),
            GestureDetector(
              onTap: () => context.push('/beach/${beach.slug}/alerts', extra: beach),
              child: const Text('Ver tudo →', style: AppTextStyles.tealLabel),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (visible.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black.withValues(alpha: 0.06))),
            child: const Center(child: Text('Sem alertas activos', style: AppTextStyles.secondaryMd)),
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
            const Text(
              'QUEM ESTÁ AQUI',
              style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700,
                color: AppColors.textSecondary, letterSpacing: 0.8,
              ),
            ),
            const SizedBox(width: 8),
            Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.teal, shape: BoxShape.circle)),
            const SizedBox(width: 4),
            const Text('live', style: TextStyle(color: AppColors.teal, fontSize: 11, fontWeight: FontWeight.w600)),
            const Spacer(),
            GestureDetector(
              onTap: () => _showPresencePeople(context, presence),
              child: const Text('Ver todos →', style: AppTextStyles.tealLabel),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () => _showPresencePeople(context, presence),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
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

    final countLabel = total == 1 ? '1 pessoa' : '$total pessoas';
    final sharedLabel = shown.length == 1
        ? '1 partilha o perfil'
        : '${shown.length} partilham o perfil';
    final subtitle = overflow > 0
        ? '$countLabel · $sharedLabel'
        : '$countLabel nesta praia agora';

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
    final label = total == 1 ? '1 pessoa está aqui' : '$total pessoas estão aqui';
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
              const Text(
                'Nenhuma pessoa decidiu partilhar a localização.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                      const Text('Quem está aqui', style: AppTextStyles.titleMd),
                      Text(presence.beachName, style: AppTextStyles.secondary),
                    ],
                  ),
                ),
                // Live count badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
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
                        '${presence.userCount} ${presence.userCount == 1 ? "pessoa" : "pessoas"}',
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
              user.displayName ?? 'Utilizador Anónimo',
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
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        const Icon(Icons.lock_outline, size: 15, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Text(
          '+$count ${count == 1 ? "pessoa em" : "pessoas em"} modo privado',
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
            '$total ${total == 1 ? "pessoa está" : "pessoas estão"} aqui',
            style: AppTextStyles.titleSm,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Nenhuma pessoa decidiu partilhar\na sua localização.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

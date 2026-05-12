import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../data/beach_provider.dart';
import '../domain/beach_models.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/alert_item.dart';
import '../../../shared/widgets/tide_chart.dart';

class BeachDetailScreen extends ConsumerStatefulWidget {
  const BeachDetailScreen({super.key, required this.beach});
  final BeachSummary beach;

  @override
  ConsumerState<BeachDetailScreen> createState() => _BeachDetailScreenState();
}

class _BeachDetailScreenState extends ConsumerState<BeachDetailScreen> {
  bool _isFavourite = false;
  bool _sendingHeartbeat = false;

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
        body: CustomScrollView(
          slivers: [
            _HeroAppBar(
              beach: widget.beach,
              isFavourite: _isFavourite,
              onFavourite: () => setState(() => _isFavourite = !_isFavourite),
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
      _FlagCard(flagColor: flagColor, flagConfidence: flagConfidence),
      const SizedBox(height: 12),
      _OccupancyCard(
        occupancy: d?.status.occupancy,
        occupancyLevel: d?.status.occupancy.level ?? widget.beach.occupancyLevel,
        maxCapacity: d?.detail.maxCapacity,
        onImHere: _sendHeartbeat,
        sending: _sendingHeartbeat,
      ),
      const SizedBox(height: 12),
      _WeatherCard(weather: d?.weather),
      const SizedBox(height: 12),
      _SeaCard(sea: d?.sea),
      const SizedBox(height: 12),
      _TidesCard(tidesData: d?.tides ?? TidesData.empty),
      const SizedBox(height: 12),
      _WaterQualityCard(quality: waterQuality.value),
      const SizedBox(height: 12),
      _TransportCard(
        transport: transport.value ?? BeachTransportInfo.empty,
        isLoading: transport.isLoading,
      ),
      const SizedBox(height: 12),
      _PlanTripButton(),
      const SizedBox(height: 12),
      _CommunityAlertsCard(reports: d?.activeAlerts ?? []),
    ];
  }

  Future<void> _sendHeartbeat() async {
    if (_sendingHeartbeat) return;
    setState(() => _sendingHeartbeat = true);
    try {
      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.low, timeLimit: Duration(seconds: 5)),
        );
      } catch (_) {
        pos = await Geolocator.getLastKnownPosition();
      }
      if (pos != null && mounted) {
        await ref.read(beachRepositoryProvider).sendHeartbeat(
          widget.beach.slug, lat: pos.latitude, lon: pos.longitude,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Presença registada!'),
            duration: Duration(seconds: 2),
            backgroundColor: AppColors.teal,
          ));
          // Refresh detail to update occupancy count
          ref.invalidate(beachFullDetailProvider(widget.beach.slug));
        }
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _sendingHeartbeat = false);
    }
  }
}

// ─── Hero SliverAppBar ────────────────────────────────────────────────────────

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
              'Parque Natural da Arrábida',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(decoration: BoxDecoration(gradient: _gradient(beach.flagColor))),
            Positioned(
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
          ],
        ),
      ),
    );
  }

  LinearGradient _gradient(String flag) {
    switch (flag) {
      case 'green':  return const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1A8A8A), Color(0xFF0D2137)]);
      case 'yellow': return const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF3ECFCF), Color(0xFF0D4A5A)]);
      case 'red':    return const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF8B1A1A), Color(0xFF0D2137)]);
      default:       return const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1A5A8A), Color(0xFF0D2137)]);
    }
  }
}

// ─── Shared card primitives ───────────────────────────────────────────────────

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
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.primary)),
        const Spacer(),
        if (isLive) ...[
          Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.teal, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          const Text('live', style: TextStyle(color: AppColors.teal, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ],
    );
  }
}

class _MetricCell extends StatelessWidget {
  const _MetricCell({required this.icon, required this.value, required this.label, required this.iconColor});
  final IconData icon;
  final String value;
  final String label;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.primary)),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}

Widget _metricRow(List<Widget> cells) {
  final items = <Widget>[];
  for (int i = 0; i < cells.length; i++) {
    if (i > 0) items.add(Container(width: 1, height: 40, color: const Color(0xFFE5E7EB)));
    items.add(Expanded(child: Center(child: cells[i])));
  }
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 14),
    decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
    child: Row(children: items),
  );
}

// ─── Flag card ────────────────────────────────────────────────────────────────

class _FlagCard extends StatelessWidget {
  const _FlagCard({required this.flagColor, this.flagConfidence});
  final String flagColor;
  final double? flagConfidence;

  @override
  Widget build(BuildContext context) {
    final (color, label) = _flagInfo(flagColor);
    final confidence = flagConfidence ?? 0.7;

    return _SectionCard(
      child: Row(
        children: [
          Container(width: 14, height: 14, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.primary)),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.teal, shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    const Text('live · Toca para confirmar', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
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
              const SizedBox(height: 4),
              Text('${(confidence * 100).round()}% conf.', style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
            ],
          ),
        ],
      ),
    );
  }

  (Color, String) _flagInfo(String flag) {
    switch (flag) {
      case 'green':  return (AppColors.flagGreen,    'Segura para nadar');
      case 'yellow': return (AppColors.flagYellow,   'Cuidado ao nadar');
      case 'red':    return (AppColors.flagRed,      'Condições perigosas');
      case 'purple': return (AppColors.flagPurple,   'Praia fechada');
      default:       return (AppColors.textSecondary, 'Estado desconhecido');
    }
  }
}

// ─── Occupancy card ───────────────────────────────────────────────────────────

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
    final (pct, levelLabel, color) = _occupancyInfo(occupancyLevel, userCount);

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
              const SizedBox(width: 16),
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
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: sending ? null : onImHere,
                      icon: sending
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                          : const Text('📍', style: TextStyle(fontSize: 14)),
                      label: Text(sending ? 'A registar...' : 'Estou aqui'),
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

  (double, String, Color) _occupancyInfo(String level, int userCount) {
    // Use real capacity data when available
    if (maxCapacity != null && maxCapacity! > 0) {
      final pct = (userCount / maxCapacity!).clamp(0.0, 1.0);
      final label = pct < 0.35 ? 'Tranquila' : pct < 0.70 ? 'Animada' : 'Cheia';
      final color = pct < 0.35 ? AppColors.flagGreen : pct < 0.70 ? AppColors.sand : AppColors.coral;
      return (pct, label, color);
    }
    switch (level) {
      case 'low':    return (0.22, 'Tranquila', AppColors.flagGreen);
      case 'normal': return (0.55, 'Animada',   AppColors.sand);
      case 'high':   return (0.85, 'Cheia',     AppColors.coral);
      default:       return (0.0,  'Desconhecida', AppColors.textHint);
    }
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
                  style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
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
      Paint()..color = const Color(0xFFE5E7EB)..style = PaintingStyle.stroke..strokeWidth = strokeW..strokeCap = StrokeCap.round);
    if (percentage > 0) {
      canvas.drawArc(rect, -pi / 2, 2 * pi * percentage, false,
        Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = strokeW..strokeCap = StrokeCap.round);
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) => old.percentage != percentage || old.color != color;
}

// ─── Weather card ─────────────────────────────────────────────────────────────

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
          const SizedBox(height: 12),
          _metricRow([
            _MetricCell(
              icon: Icons.thermostat_outlined,
              value: weather?.maxTemp != null ? '${weather!.maxTemp!.round()}°C' : '--',
              label: 'Temperatura', iconColor: AppColors.coral,
            ),
            _MetricCell(
              icon: Icons.air,
              value: weather?.windSpeed != null
                  ? '${weather!.windSpeed!.round()} km/h${weather!.windDir != null ? " ${weather!.windDir}" : ""}'
                  : '--',
              label: 'Vento', iconColor: AppColors.teal,
            ),
            _MetricCell(
              icon: Icons.umbrella_outlined,
              value: weather?.precipitationProb != null ? '${weather!.precipitationProb!.round()}%' : '--',
              label: 'Chuva', iconColor: const Color(0xFF3B82F6),
            ),
          ]),
        ],
      ),
    );
  }
}

// ─── Sea card ─────────────────────────────────────────────────────────────────

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
          const SizedBox(height: 12),
          _metricRow([
            _MetricCell(
              icon: Icons.waves,
              value: sea?.waveHeightMax != null ? '${sea!.waveHeightMax!.toStringAsFixed(1)}m' : '--',
              label: 'Ondas', iconColor: AppColors.teal,
            ),
            _MetricCell(
              icon: Icons.schedule,
              value: sea?.wavePeriodMax != null ? '${sea!.wavePeriodMax!.round()}s' : '--',
              label: 'Período', iconColor: AppColors.primary,
            ),
            _MetricCell(
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

// ─── Tides card ───────────────────────────────────────────────────────────────

class _TidesCard extends StatelessWidget {
  const _TidesCard({required this.tidesData});
  final TidesData tidesData;

  @override
  Widget build(BuildContext context) {
    final tides = tidesData.entries;
    final apiDirection = tidesData.direction ?? 'steady';
    final isRising = apiDirection == 'rising';
    final directionLabel = isRising ? 'Subindo' : apiDirection == 'falling' ? 'Descendo' : 'Estável';

    TideEntry? nextTide;
    final nowMins = DateTime.now().hour * 60 + DateTime.now().minute;
    for (final t in tides) {
      final p = t.time.split(':');
      if (p.length == 2) {
        final tMins = (int.tryParse(p[0]) ?? 0) * 60 + (int.tryParse(p[1]) ?? 0);
        if (tMins > nowMins) { nextTide = t; break; }
      }
    }
    nextTide ??= tides.isNotEmpty ? tides.last : null;

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
              const Text('Marés Hoje', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.primary)),
              const Spacer(),
              GestureDetector(
                onTap: () {},
                child: const Text('Vista completa →', style: TextStyle(color: AppColors.tealDark, fontSize: 12, fontWeight: FontWeight.w600)),
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
                  Text(displayH, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.primary)),
                  if (nextTide != null)
                    Text(
                      '${nextTide.type == 'alta' ? 'alta' : 'baixa'} às ${nextTide.time}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                ],
              ),
              const SizedBox(width: 12),
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
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
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

// ─── Water quality card ───────────────────────────────────────────────────────

class _WaterQualityCard extends StatelessWidget {
  const _WaterQualityCard({this.quality});
  final WaterQuality? quality;

  @override
  Widget build(BuildContext context) {
    final (color, label) = _qualityInfo(quality?.classification);
    final cacheStr = _cacheStr(quality);

    return _SectionCard(
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: AppColors.teal.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.water_drop_outlined, color: AppColors.teal, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Qualidade da Água', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.primary)),
                if (cacheStr != null)
                  Row(children: [
                    const Icon(Icons.access_time, size: 11, color: AppColors.textHint),
                    const SizedBox(width: 3),
                    Text(cacheStr, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                  ]),
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
                const SizedBox(width: 4),
                Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  (Color, String) _qualityInfo(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'excelente': case 'excellent': return (AppColors.flagGreen,    'Excelente');
      case 'boa':       case 'good':      return (AppColors.teal,         'Boa');
      case 'suficiente': case 'sufficient': return (AppColors.flagYellow, 'Suficiente');
      case 'má':        case 'poor':      return (AppColors.flagRed,      'Má');
      default:                             return (AppColors.textSecondary, 'Desconhecida');
    }
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

// ─── Transport card ───────────────────────────────────────────────────────────

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
            const SizedBox(height: 16),
            const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppColors.teal, strokeWidth: 2))),
            const SizedBox(height: 16),
          ] else if (transport.stops.isEmpty) ...[
            const SizedBox(height: 12),
            const Center(child: Text('Sem informação de transportes para esta praia', style: TextStyle(color: AppColors.textSecondary, fontSize: 13))),
          ] else if (!transport.hasDepartures) ...[
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.schedule, size: 14, color: AppColors.textHint),
              const SizedBox(width: 6),
              const Text('Sem partidas previstas', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ]),
            const SizedBox(height: 4),
            Center(
              child: Text(
                '${transport.stops.length} paragem${transport.stops.length > 1 ? 's' : ''} próxima${transport.stops.length > 1 ? 's' : ''}',
                style: const TextStyle(color: AppColors.textHint, fontSize: 11),
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
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
            child: Text(dep.routeShortName, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 5),
          Text(dep.displayTime, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
          if (dep.isRealtime) ...[
            const SizedBox(width: 4),
            Container(width: 5, height: 5, decoration: const BoxDecoration(color: AppColors.teal, shape: BoxShape.circle)),
          ],
        ],
      ),
    );
  }
}

// ─── Plan trip button ─────────────────────────────────────────────────────────

class _PlanTripButton extends StatelessWidget {
  // ignore: prefer_const_constructors_in_immutables
  _PlanTripButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.directions_bus, size: 18),
        label: const Text('Planear viagem  →'),
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

// ─── Community alerts card ────────────────────────────────────────────────────

class _CommunityAlertsCard extends StatelessWidget {
  const _CommunityAlertsCard({required this.reports});
  final List<BeachReport> reports;

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
                child: Text('${reports.length}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
              ),
            const Spacer(),
            GestureDetector(
              onTap: () {},
              child: const Text('Ver tudo →', style: TextStyle(color: AppColors.tealDark, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (visible.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black.withValues(alpha: 0.06))),
            child: const Center(child: Text('Sem alertas activos', style: TextStyle(color: AppColors.textSecondary, fontSize: 13))),
          )
        else
          ...visible.map((r) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AlertItem(
              report: r,
              trailing: _VoteDots(upvotes: r.upvotes, downvotes: r.downvotes),
            ),
          )),
      ],
    );
  }
}

class _VoteDots extends StatelessWidget {
  const _VoteDots({required this.upvotes, required this.downvotes});
  final int upvotes;
  final int downvotes;

  @override
  Widget build(BuildContext context) {
    final total = (upvotes + downvotes).clamp(1, 999);
    final filled = ((upvotes / total) * 3).round().clamp(0, 3);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) => Container(
        width: 7, height: 7,
        margin: const EdgeInsets.only(left: 3),
        decoration: BoxDecoration(
          color: i < filled ? AppColors.flagGreen : const Color(0xFFE5E7EB),
          shape: BoxShape.circle,
        ),
      )),
    );
  }
}

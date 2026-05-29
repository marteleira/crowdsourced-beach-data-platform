import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../features/beaches/data/beach_provider.dart';
import '../../../features/beaches/domain/beach_models.dart';
import '../../../shared/theme/app_theme.dart';

class TransportScreen extends ConsumerStatefulWidget {
  const TransportScreen({super.key, required this.beach});
  final BeachSummary beach;

  @override
  ConsumerState<TransportScreen> createState() => _TransportScreenState();
}

class _TransportScreenState extends ConsumerState<TransportScreen> {
  Future<void> _refresh() async {
    ref.invalidate(beachTransportProvider(widget.beach.slug));
    ref.invalidate(beachFullDetailProvider(widget.beach.slug));
    await Future.wait([
      ref.read(beachTransportProvider(widget.beach.slug).future)
          .catchError((_) => BeachTransportInfo.empty),
      ref.read(beachFullDetailProvider(widget.beach.slug).future)
          .catchError((_) => null as BeachFullDetail?),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final transport = ref.watch(beachTransportProvider(widget.beach.slug));
    final detail = ref.watch(beachFullDetailProvider(widget.beach.slug));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(context),
        body: switch (transport) {
          AsyncLoading() when transport.value == null =>
            const Center(child: CircularProgressIndicator(color: AppColors.teal, strokeWidth: 2.5)),
          AsyncError(:final error) => _ErrorView(
              error: error.toString(),
              onRetry: () => ref.invalidate(beachTransportProvider(widget.beach.slug)),
            ),
          _ => _buildBody(transport.value ?? BeachTransportInfo.empty, detail.value),
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
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
            'Transportes',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          Text(
            widget.beach.name,
            style: const TextStyle(fontSize: 12, color: AppColors.teal, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BeachTransportInfo transport, BeachFullDetail? detail) {
    final flagColor = detail?.status.flagColor ?? widget.beach.flagColor;
    final activeDirections =
        transport.directions.where((d) => d.departures.isNotEmpty).toList();

    return RefreshIndicator(
      onRefresh: _refresh,
      color: AppColors.teal,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          _StatusStrip(
            flagColor: flagColor,
            weather: detail?.weather,
            sea: detail?.sea,
          ),
          const SizedBox(height: 16),
          if (transport.stops.isEmpty)
            const _EmptyTransport()
          else ...[
            ...activeDirections.asMap().entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _DirectionCard(
                  direction: e.value,
                  stops: transport.stops,
                  beach: widget.beach,
                  initiallyExpanded: e.key == 0,
                ),
              ),
            ),
            const SizedBox(height: 4),
            _WalkButton(beach: widget.beach, stops: transport.stops),
            const SizedBox(height: 20),
            _FooterDisclaimer(dataSource: transport.dataSource),
          ],
        ],
      ),
    );
  }
}

//Status strip 

class _StatusStrip extends StatelessWidget {
  const _StatusStrip({required this.flagColor, this.weather, this.sea});
  final String flagColor;
  final WeatherPoint? weather;
  final SeaPoint? sea;

  @override
  Widget build(BuildContext context) {
    final label = switch (flagColor) {
      'green'  => 'Segura',
      'yellow' => 'Cuidado',
      'red'    => 'Perigo',
      'purple' => 'Proibida',
      _        => 'Sem info',
    };
    final color = AppColors.forFlag(flagColor);
    final waves = sea?.waveHeightMax;
    final temp = weather?.maxTemp ?? sea?.seaTemp;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color),
          ),
          if (waves != null) ...[
            const _StripDivider(),
            const Icon(Icons.waves_rounded, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text('${waves.toStringAsFixed(1)}m ondas', style: AppTextStyles.secondaryMd),
          ],
          if (temp != null) ...[
            const _StripDivider(),
            const Icon(Icons.thermostat, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 2),
            Text('${temp.round()}°C', style: AppTextStyles.secondaryMd),
          ],
        ],
      ),
    );
  }
}

class _StripDivider extends StatelessWidget {
  const _StripDivider();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Container(width: 1, height: 14, color: AppColors.borderLight),
      );
}

//Direction card (expandable) 

class _DirectionCard extends StatefulWidget {
  const _DirectionCard({
    required this.direction,
    required this.stops,
    required this.beach,
    required this.initiallyExpanded,
  });
  final TransportDirection direction;
  final List<TransportStop> stops;
  final BeachSummary beach;
  final bool initiallyExpanded;

  @override
  State<_DirectionCard> createState() => _DirectionCardState();
}

class _DirectionCardState extends State<_DirectionCard>
    with SingleTickerProviderStateMixin {
  late bool _expanded;
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      value: _expanded ? 1.0 : 0.0,
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    _expanded ? _ctrl.forward() : _ctrl.reverse();
  }

  TransportStop? get _stop {
    final stopId = widget.direction.departures.firstOrNull?.stopId;
    if (stopId != null) {
      try {
        return widget.stops.firstWhere((s) => s.stopId == stopId);
      } catch (_) {}
    }
    return widget.stops.firstOrNull;
  }

  int? get _walkMins {
    final stop = _stop;
    if (stop?.lat == null || stop?.lon == null) return null;
    final dist = _haversine(
      widget.beach.lat, widget.beach.lon,
      stop!.lat!, stop.lon!,
    );
    return (dist / 83.0).ceil();
  }

  static double _haversine(
    double lat1, double lon1, double lat2, double lon2,
  ) {
    const R = 6371000.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) * cos(lat2 * pi / 180) *
            sin(dLon / 2) * sin(dLon / 2);
    return R * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  @override
  Widget build(BuildContext context) {
    final firstDep = widget.direction.departures.firstOrNull;
    final routeNum = firstDep?.routeShortName ?? '';
    final stop = _stop;
    final walkMins = _walkMins;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          //Header — always visible
          InkWell(
            onTap: _toggle,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  //Bus icon
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.coral.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.directions_bus_rounded,
                      size: 20, color: AppColors.coral,
                    ),
                  ),
                  const SizedBox(width: 12),
                  //Route badge + headsign + stop name
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.coral,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                routeNum,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.direction.headsign,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (stop != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.place_outlined,
                                  size: 12, color: AppColors.textHint),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  walkMins != null
                                      ? '${stop.stopName} · $walkMins min a pé'
                                      : stop.stopName,
                                  style: AppTextStyles.secondarySm,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  //Next time + chevron
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (firstDep != null)
                        Text(
                          'Próxima: ${firstDep.displayTime}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.tealDark,
                          ),
                        ),
                      const SizedBox(height: 4),
                      AnimatedRotation(
                        turns: _expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: const Icon(
                          Icons.keyboard_arrow_down,
                          size: 20, color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          //Animated departures section
          SizeTransition(
            sizeFactor: _anim,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Divider(height: 1, color: AppColors.borderLight),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PRÓXIMAS PARTIDAS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textHint,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Divider(color: AppColors.borderLight, height: 1),
                      const SizedBox(height: 10),
                      ...widget.direction.departures.take(6).map(
                        (dep) => _DepartureRow(
                          dep: dep,
                          headsign: widget.direction.headsign,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Departure row 

class _DepartureRow extends StatelessWidget {
  const _DepartureRow({required this.dep, required this.headsign});
  final TransportDeparture dep;
  final String headsign;

  bool get _isArrivingSoon {
    final now = DateTime.now();
    final parts = dep.departureTime.split(':');
    if (parts.length < 2) return false;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    final depMins = h * 60 + m;
    final nowMins = now.hour * 60 + now.minute;
    return depMins >= nowMins && depMins - nowMins <= 20;
  }

  @override
  Widget build(BuildContext context) {
    final soon = _isArrivingSoon;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(
            Icons.schedule,
            size: 14,
            color: soon ? AppColors.tealDark : AppColors.textHint,
          ),
          const SizedBox(width: 8),
          Text(
            dep.displayTime,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: soon ? AppColors.tealDark : AppColors.primary,
            ),
          ),
          if (soon) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.teal.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.teal.withValues(alpha: 0.30),
                ),
              ),
              child: const Text(
                'A chegar',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.tealDark,
                ),
              ),
            ),
          ],
          const Spacer(),
          const Icon(Icons.arrow_forward, size: 11, color: AppColors.textHint),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              headsign,
              style: AppTextStyles.secondarySm,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

// Walk-to-beach button 

class _WalkButton extends StatelessWidget {
  const _WalkButton({required this.beach, required this.stops});
  final BeachSummary beach;
  final List<TransportStop> stops;

  int? get _nearestWalkMins {
    double? minDist;
    for (final stop in stops) {
      if (stop.lat == null || stop.lon == null) continue;
      final d = _haversine(beach.lat, beach.lon, stop.lat!, stop.lon!);
      if (minDist == null || d < minDist) minDist = d;
    }
    return minDist != null ? (minDist / 83.0).ceil() : null;
  }

  static double _haversine(
    double lat1, double lon1, double lat2, double lon2,
  ) {
    const R = 6371000.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) * cos(lat2 * pi / 180) *
            sin(dLon / 2) * sin(dLon / 2);
    return R * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  Future<void> _launch() async {
    final geoUri = Uri.parse(
      'geo:${beach.lat},${beach.lon}'
      '?q=${beach.lat},${beach.lon}'
      '(${Uri.encodeComponent(beach.name)})',
    );
    if (await canLaunchUrl(geoUri)) {
      await launchUrl(geoUri);
    } else {
      final webUri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1'
        '&destination=${beach.lat},${beach.lon}'
        '&travelmode=walking',
      );
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mins = _nearestWalkMins;
    final label = mins != null
        ? 'Ir a pé para ${beach.name} ($mins min)'
        : 'Ir a pé para ${beach.name}';

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _launch,
        icon: const Icon(Icons.directions_walk, size: 18),
        label: Text(label, overflow: TextOverflow.ellipsis, maxLines: 1),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle:
              const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
    );
  }
}

// Footer disclaimer 

class _FooterDisclaimer extends StatelessWidget {
  const _FooterDisclaimer({required this.dataSource});
  final String dataSource;

  @override
  Widget build(BuildContext context) {
    return Text(
      dataSource == 'live'
          ? 'Horários Carris Metropolitana. Dados em tempo real quando disponível — verificar nas paragens.'
          : 'Horários Carris Metropolitana. Dados em cache — verificar nas paragens.',
      style: AppTextStyles.hint,
      textAlign: TextAlign.center,
    );
  }
}

//Empty state 

class _EmptyTransport extends StatelessWidget {
  const _EmptyTransport();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 60),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.directions_bus_outlined, size: 48, color: AppColors.textHint),
          SizedBox(height: 12),
          Text(
            'Sem transportes disponíveis\npara esta praia',
            style: AppTextStyles.secondaryMd,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

//Error view 

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});
  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.textHint),
            const SizedBox(height: 12),
            const Text(
              'Não foi possível carregar os transportes',
              style: AppTextStyles.secondaryMd,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: onRetry,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

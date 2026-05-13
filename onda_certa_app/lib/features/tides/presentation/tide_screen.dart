import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../beaches/data/beach_provider.dart';
import '../../beaches/domain/beach_models.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/tide_chart.dart';

const _kDeep   = Color(0xFF081C2E);
const _kMid    = Color(0xFF0E3D55);
const _kWater1 = Color(0xFF0F5F78);
const _kWater2 = Color(0xFF18879E);
const _kWater3 = Color(0xFF22A8BE);

class TideScreen extends ConsumerStatefulWidget {
  const TideScreen({super.key});

  @override
  ConsumerState<TideScreen> createState() => _TideScreenState();
}

class _TideScreenState extends ConsumerState<TideScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _waveCtrl;

  @override
  void initState() {
    super.initState();
    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _waveCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tidesAsync = ref.watch(tidesProvider);
    final seaAsync   = ref.watch(seaProvider);
    final beachAsync = ref.watch(bestBeachProvider);

    final tides   = tidesAsync.value ?? TidesData.empty;
    final sea     = seaAsync.value;
    final beach   = beachAsync.value;
    final loading = tidesAsync.isLoading && tides.entries.isEmpty;

    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedBuilder(
          animation: _waveCtrl,
          builder: (_, _) => CustomPaint(
            painter: _OceanPainter(
              phase: _waveCtrl.value,
              fillFraction: _computeFill(tides),
              isRising: tides.direction == 'rising',
            ),
          ),
        ),
        _HeroContent(tidesData: tides, beachName: beach?.name),
        DraggableScrollableSheet(
          initialChildSize: 0.22,
          minChildSize: 0.14,
          maxChildSize: 0.72,
          snap: true,
          snapSizes: const [0.22, 0.72],
          builder: (_, sc) => _DetailSheet(
            scrollController: sc,
            tidesData: tides,
            sea: sea,
            isLoading: loading,
          ),
        ),
      ],
    );
  }

  static double _computeFill(TidesData t) {
    final h = t.currentHeight;
    if (h == null || t.entries.isEmpty) return 0.36;
    final lo = t.entries.map((e) => e.height).reduce(min);
    final hi = t.entries.map((e) => e.height).reduce(max);
    return 0.20 + ((h - lo) / (hi - lo).clamp(0.5, 99.0)) * 0.30;
  }
}

// Ocean background 

class _OceanPainter extends CustomPainter {
  const _OceanPainter({
    required this.phase,
    required this.fillFraction,
    required this.isRising,
  });
  final double phase;
  final double fillFraction;
  final bool isRising;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_kDeep, _kMid],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    final waterTop = size.height * (1.0 - fillFraction);

    _wave(canvas, size,
      baseY: waterTop + 8, amp: 9, freq: 1.5,
      offset: phase * 2 * pi + 2.1,
      color: _kWater1.withValues(alpha: 0.80),
    );
    _wave(canvas, size,
      baseY: waterTop, amp: 12, freq: 1.2,
      offset: phase * 2 * pi,
      color: _kWater2.withValues(alpha: 0.90),
    );
    _wave(canvas, size,
      baseY: waterTop - 4, amp: 6, freq: 2.1,
      offset: phase * 2 * pi * 1.3 + pi,
      color: _kWater3.withValues(alpha: 0.50),
    );
  }

  void _wave(Canvas canvas, Size size, {
    required double baseY,
    required double amp,
    required double freq,
    required double offset,
    required Color color,
  }) {
    final path = Path();
    for (double x = 0; x <= size.width; x++) {
      final y = baseY + sin(x / size.width * freq * 2 * pi + offset) * amp;
      x == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_OceanPainter o) =>
      o.phase != phase || o.fillFraction != fillFraction || o.isRising != isRising;
}

// Hero text overlay

class _HeroContent extends StatelessWidget {
  const _HeroContent({required this.tidesData, this.beachName});
  final TidesData tidesData;
  final String? beachName;

  @override
  Widget build(BuildContext context) {
    final entries  = tidesData.entries;
    final isRising = tidesData.direction == 'rising';
    final currentH = tidesData.currentHeight;

    TideEntry? next;
    final nowMins = DateTime.now().hour * 60 + DateTime.now().minute;
    for (final t in entries) {
      final p = t.time.split(':');
      if (p.length == 2) {
        if ((int.tryParse(p[0]) ?? 0) * 60 + (int.tryParse(p[1]) ?? 0) > nowMins) {
          next = t;
          break;
        }
      }
    }
    next ??= entries.isNotEmpty ? entries.last : null;

    final displayH = currentH?.toStringAsFixed(2) ?? next?.height.toStringAsFixed(1) ?? '--';
    final dirLabel = isRising ? 'subindo' : tidesData.direction == 'falling' ? 'descendo' : 'estável';
    final nextStr  = next != null
        ? '${next.type == 'alta' ? 'maré alta' : 'maré baixa'} às ${next.time}'
        : '';
    final pillText = nextStr.isNotEmpty ? '$dirLabel · $nextStr' : dirLabel;
    final dotColor = isRising ? AppColors.teal : AppColors.sand;

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Text(
            beachName ?? 'Marés',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.60),
              fontSize: 13,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.8,
            ),
          ),
          const Spacer(flex: 1),
          Text.rich(
            TextSpan(children: [
              TextSpan(
                text: displayH,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 86,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                  letterSpacing: -3,
                ),
              ),
              TextSpan(
                text: 'm',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.70),
                  fontSize: 32,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.30),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 7, height: 7,
                decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                pillText,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ]),
          ),
          const Spacer(flex: 3),
        ],
      ),
    );
  }
}

// Slide-up detail sheet

class _DetailSheet extends StatelessWidget {
  const _DetailSheet({
    required this.scrollController,
    required this.tidesData,
    this.sea,
    required this.isLoading,
  });
  final ScrollController scrollController;
  final TidesData tidesData;
  final SeaPoint? sea;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 24, offset: Offset(0, -4))],
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 4),
          child: Column(children: [
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'MAIS DETALHES',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textHint, letterSpacing: 1.2),
            ),
            const SizedBox(height: 2),
            const Icon(Icons.keyboard_arrow_up, color: AppColors.textHint, size: 18),
          ]),
        ),
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.teal, strokeWidth: 2))
              : ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 48),
                  children: [
                    _TodayTidesSection(entries: tidesData.entries),
                    if (sea != null) ...[
                      const SizedBox(height: 16),
                      _SeaRow(sea: sea!),
                    ],
                    if (tidesData.entries.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _TideChartCard(tidesData: tidesData),
                    ],
                  ],
                ),
        ),
      ]),
    );
  }
}

// Today's tides list

class _TodayTidesSection extends StatelessWidget {
  const _TodayTidesSection({required this.entries});
  final List<TideEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        ),
        child: const Center(
          child: Text('Sem dados de marés disponíveis', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ),
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text(
        'MARÉS DE HOJE',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.9),
      ),
      const SizedBox(height: 10),
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        ),
        child: Column(children: [
          for (int i = 0; i < entries.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 40, color: Color(0xFFEEEEEE)),
            _TideRow(entry: entries[i]),
          ],
        ]),
      ),
    ]);
  }
}

class _TideRow extends StatelessWidget {
  const _TideRow({required this.entry});
  final TideEntry entry;

  @override
  Widget build(BuildContext context) {
    final isHigh = entry.type == 'alta';
    final color  = isHigh ? AppColors.teal : AppColors.sand;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      child: Row(children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 14),
        Text(entry.time, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary)),
        const Spacer(),
        Text.rich(TextSpan(children: [
          TextSpan(
            text: '${entry.height.toStringAsFixed(1)} m',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary),
          ),
          TextSpan(
            text: '  ${isHigh ? 'alta' : 'baixa'}',
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ])),
      ]),
    );
  }
}

// Sea conditions

class _SeaRow extends StatelessWidget {
  const _SeaRow({required this.sea});
  final SeaPoint sea;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: _SeaMini(
        icon: Icons.thermostat_outlined,
        iconColor: AppColors.coral,
        label: 'Temp. Mar',
        value: sea.seaTemp != null ? '${sea.seaTemp!.round()}°C' : '--',
      )),
      const SizedBox(width: 10),
      Expanded(child: _SeaMini(
        icon: Icons.waves,
        iconColor: AppColors.teal,
        label: 'Ondas',
        value: sea.waveHeightMax != null ? '${sea.waveHeightMax!.toStringAsFixed(1)} m' : '--',
      )),
    ]);
  }
}

class _SeaMini extends StatelessWidget {
  const _SeaMini({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Row(children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 6),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.primary)),
        ]),
      ]),
    );
  }
}

// Tide chart card

class _TideChartCard extends StatelessWidget {
  const _TideChartCard({required this.tidesData});
  final TidesData tidesData;

  @override
  Widget build(BuildContext context) {
    final accent = (tidesData.currentHeight ?? 0) > 1.95 ? AppColors.teal : AppColors.sand;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text(
        'CURVA DE MARÉ',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.9),
      ),
      const SizedBox(height: 10),
      Container(
        height: 110,
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        ),
        child: CustomPaint(
          size: Size.infinite,
          painter: TideChartPainter(
            tides: tidesData.entries,
            currentHeight: tidesData.currentHeight,
            accentColor: accent,
          ),
        ),
      ),
    ]);
  }
}

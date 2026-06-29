import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../beaches/data/beach_provider.dart';
import '../../beaches/domain/beach_models.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/beach_helpers.dart';
import '../../../core/l10n/l10n.dart';

// Scene configuration
// Derived from current time + weather data, Drives all visual decisions

class _Scene {
  _Scene({
    required this.hour,
    required this.minute,
    required this.weatherDesc,
    required this.precipProb,
    this.waveHeightMax,
  });

  final int hour;
  final int minute;
  final String weatherDesc;
  final double precipProb; // 0–100
  final double? waveHeightMax;

  bool get isNight => hour >= 20 || hour < 5;
  bool get isDawn  => hour >= 5  && hour < 7;
  bool get isDusk  => hour >= 18 && hour < 20;
  bool get isDay   => hour >= 7  && hour < 18;

  /// 0.0 = 06:00 (sunrise), 1.0 = 18:00 (sunset)
  double get dayProgress =>
      ((hour * 60 + minute - 360) / 720.0).clamp(0.0, 1.0);

  double get cloudCover {
    final d = weatherDesc.toLowerCase();
    if (d.contains('limpo')         || d.contains('clear'))     return 0.00;
    if (d.contains('pouco nublado') || d.contains('few'))       return 0.20;
    if (d.contains('parcialmente')  || d.contains('partly'))    return 0.50;
    if (d.contains('muito nublado') || d.contains('broken'))    return 0.80;
    if (d.contains('encoberto')     || d.contains('overcast'))  return 1.00;
    if (d.contains('chuv')          || d.contains('rain'))      return 0.90;
    if (d.contains('aguac')         || d.contains('shower'))    return 0.75;
    if (d.contains('trovoada')      || d.contains('thunder'))   return 1.00;
    if (d.contains('nevoeiro')      || d.contains('fog'))       return 0.85;
    return precipProb > 50 ? 0.80 : 0.35;
  }

  bool get isRaining =>
      precipProb > 40 ||
      weatherDesc.toLowerCase().contains('chuv') ||
      weatherDesc.toLowerCase().contains('aguac') ||
      weatherDesc.toLowerCase().contains('rain');

  double get rainIntensity =>
      isRaining ? ((precipProb / 100.0) * 0.8 + 0.2).clamp(0.2, 1.0) : 0.0;

  double get waveAmpMult {
    final h = waveHeightMax ?? 1.0;
    if (h < 0.5) return 0.50;
    if (h < 1.5) return 1.00;
    if (h < 3.0) return 1.75;
    return 2.40;
  }

  List<Color> get skyGradient {
    if (isRaining) return [const Color(0xFF1A2830), const Color(0xFF283848)];
    if (isNight)   return [const Color(0xFF030810), const Color(0xFF080F22)];
    if (isDawn)    return [const Color(0xFFC04000), const Color(0xFFFF7060), const Color(0xFF4028A0)];
    if (isDusk)    return [const Color(0xFFBB3800), const Color(0xFFAA2868), const Color(0xFF220E55)];
    final t = 1.0 - cloudCover * 0.65;
    return [
      Color.lerp(const Color(0xFF3A88BB), const Color(0xFF7EC8E8), t)!,
      Color.lerp(const Color(0xFF205898), const Color(0xFF58A8C8), t)!,
    ];
  }

  List<double> get skyStops =>
      skyGradient.length == 3 ? [0.0, 0.45, 1.0] : [0.0, 1.0];

  Color get waterDeep  => isNight ? const Color(0xFF06202E) : isRaining ? const Color(0xFF0A2C3C) : const Color(0xFF0F5F78);
  Color get waterMid   => isNight ? const Color(0xFF0C3555) : isRaining ? const Color(0xFF0C3C58) : const Color(0xFF18879E);
  Color get waterLight => isNight ? const Color(0xFF134560) : isRaining ? const Color(0xFF135068) : const Color(0xFF22A8BE);
}

// Widget

class TideScreen extends ConsumerStatefulWidget {
  const TideScreen({super.key, this.beach});

  /// When provided, shows tides for this specific beach instead of the
  /// nearest/"best" beach used by the bottom-nav Marés tab.
  final BeachSummary? beach;

  @override
  ConsumerState<TideScreen> createState() => _TideScreenState();
}

class _TideScreenState extends ConsumerState<TideScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _waveCtrl;
  late final DraggableScrollableController _sheetCtrl;
  bool _reloading = false;

  @override
  void initState() {
    super.initState();
    _waveCtrl  = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
    _sheetCtrl = DraggableScrollableController();
  }

  @override
  void dispose() { _waveCtrl.dispose(); _sheetCtrl.dispose(); super.dispose(); }

  Future<void> _reload() async {
    if (_reloading) return;
    setState(() => _reloading = true);
    try {
      final beach = widget.beach;
      if (beach != null) {
        ref.invalidate(beachTidesBySlugProvider(beach.slug));
        ref.invalidate(beachSeaBySlugProvider(beach.slug));
        ref.invalidate(beachWeatherBySlugProvider(beach.slug));
        await ref.read(beachTidesBySlugProvider(beach.slug).future);
      } else {
        await refreshHomeData(ref);
      }
    } finally {
      if (mounted) setState(() => _reloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final beach = widget.beach;

    final TidesData tides;
    final SeaPoint? sea;
    final WeatherPoint? weather;
    final String? beachName;
    final bool loading;

    if (beach != null) {
      final tidesAsync   = ref.watch(beachTidesBySlugProvider(beach.slug));
      final seaAsync     = ref.watch(beachSeaBySlugProvider(beach.slug));
      final weatherAsync = ref.watch(beachWeatherBySlugProvider(beach.slug));

      tides     = tidesAsync.value ?? TidesData.empty;
      sea       = seaAsync.value;
      weather   = weatherAsync.value;
      beachName = beach.name;
      loading   = tidesAsync.isLoading && tides.entries.isEmpty;
    } else {
      final tidesAsync   = ref.watch(tidesProvider);
      final seaAsync     = ref.watch(seaProvider);
      final beachAsync   = ref.watch(bestBeachProvider);
      final weatherAsync = ref.watch(weatherProvider);

      tides     = tidesAsync.value ?? TidesData.empty;
      sea       = seaAsync.value;
      weather   = weatherAsync.value;
      beachName = beachAsync.value?.name;
      loading   = tidesAsync.isLoading && tides.entries.isEmpty;
    }

    final now   = DateTime.now();
    final scene = _Scene(
      hour: now.hour, minute: now.minute,
      weatherDesc:  weather?.weatherDesc ?? '',
      precipProb:   weather?.precipitationProb ?? 0,
      waveHeightMax: sea?.waveHeightMax,
    );

    return Material(
      color: Colors.transparent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBuilder(
            animation: _waveCtrl,
            builder: (_, _) => CustomPaint(
              painter: _OceanPainter(
                phase: _waveCtrl.value,
                fillFraction: _computeFill(tides),
                scene: scene,
              ),
            ),
          ),
          _HeroContent(tidesData: tides, beachName: beachName),
          DraggableScrollableSheet(
            controller: _sheetCtrl,
            initialChildSize: 0.22, minChildSize: 0.14, maxChildSize: 0.72,
            snap: true, snapSizes: const [0.22, 0.72],
            builder: (_, sc) => _DetailSheet(
              scrollController: sc, sheetCtrl: _sheetCtrl,
              tidesData: tides, sea: sea, isLoading: loading,
            ),
          ),
          if (beach != null)
            Positioned(
              top: MediaQuery.paddingOf(context).top + 6,
              left: 12,
              child: GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Colors.black26,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                ),
              ),
            ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 6,
            right: 12,
            child: GestureDetector(
              onTap: _reload,
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Colors.black26,
                  shape: BoxShape.circle,
                ),
                child: _reloading
                    ? const Padding(
                        padding: EdgeInsets.all(9),
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.refresh, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
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

// Painter

class _OceanPainter extends CustomPainter {
  _OceanPainter({required this.phase, required this.fillFraction, required this.scene});
  final double phase;
  final double fillFraction;
  final _Scene scene;

  // Pre-computed (0–1) fractional positions — stable across frames
  static final _rainFracs = List.generate(70, (i) =>
    Offset((i * 0.785398 + 0.05) % 1.0, (i * 0.461793 + 0.12) % 1.0));
  static final _starFracs = List.generate(40, (i) =>
    Offset((i * 0.271828 + 0.08) % 0.95, (i * 0.183216 + 0.03) % 0.40));

  @override
  void paint(Canvas canvas, Size size) {
    _drawSky(canvas, size);
    final waterY = size.height * (1.0 - fillFraction);
    if (scene.isNight && !scene.isRaining) _drawStars(canvas, size, waterY);
    if (!scene.isRaining) {
      if (scene.isDay || scene.isDawn || scene.isDusk) _drawSun(canvas, size, waterY);
      if (scene.isNight) _drawMoon(canvas, size, waterY);
    }
    if (scene.cloudCover > 0.10) _drawClouds(canvas, size, waterY);
    _drawWaves(canvas, size, waterY);
    if (scene.isRaining) _drawRain(canvas, size);
  }

  // Sky

  void _drawSky(Canvas canvas, Size size) {
    final r = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(r, Paint()..shader = LinearGradient(
      begin: Alignment.topCenter, end: Alignment.bottomCenter,
      colors: scene.skyGradient, stops: scene.skyStops,
    ).createShader(r));
    // Dark vignette at top — keeps hero text readable in all conditions
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height * 0.40),
      Paint()..shader = const LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Color(0x55000000), Color(0x00000000)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.40)),
    );
  }

  // Stars

  void _drawStars(Canvas canvas, Size size, double waterY) {
    for (int i = 0; i < _starFracs.length; i++) {
      final pos = _starFracs[i];
      final y = pos.dy * waterY;
      if (y >= waterY) continue;
      final t = (sin(phase * 2 * pi * 1.5 + i * 0.83) + 1) / 2;
      canvas.drawCircle(
        Offset(pos.dx * size.width, y),
        0.6 + t * 1.1,
        Paint()..color = Colors.white.withValues(alpha: 0.30 + t * 0.65),
      );
    }
  }

  // Sun

  void _drawSun(Canvas canvas, Size size, double waterY) {
    final p    = scene.dayProgress;
    final skyH = waterY * 0.82;
    final sunX = size.width  * (0.08 + p * 0.84);
    final sunY = (waterY * 0.08 + skyH * (1.0 - sin(p * pi).clamp(0.0, 1.0) * 0.85))
        .clamp(size.height * 0.05, waterY - 28.0);
    final c = Offset(sunX, sunY);

    // Outer glow (blurred) — single expensive draw is fine for one element
    canvas.drawCircle(c, 34, Paint()
      ..color = const Color(0xFFFFD040).withValues(alpha: 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18));
    // Inner glow
    canvas.drawCircle(c, 20, Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    // Sun disc
    canvas.drawCircle(c, 13, Paint()..shader = RadialGradient(
      colors: [Colors.white, const Color(0xFFFFD040)],
    ).createShader(Rect.fromCircle(center: c, radius: 13)));
    // Rotating rays — only when not very cloudy
    if (scene.cloudCover < 0.65) {
      final rp = Paint()
        ..color = const Color(0xFFFFD040).withValues(alpha: 0.55)
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round;
      for (int i = 0; i < 8; i++) {
        final a = i * pi / 4 + phase * pi * 0.5;
        canvas.drawLine(
          c + Offset(cos(a) * 16, sin(a) * 16),
          c + Offset(cos(a) * 26, sin(a) * 26),
          rp,
        );
      }
    }
  }

  // Moon

  void _drawMoon(Canvas canvas, Size size, double waterY) {
    const r = 13.0;
    final c = Offset(size.width * 0.74, waterY * 0.22);
    // Soft halo
    canvas.drawCircle(c, r + 10, Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
    // Crescent via Path difference
    final full   = Path()..addOval(Rect.fromCircle(center: c, radius: r));
    final shadow = Path()..addOval(Rect.fromCircle(
      center: c.translate(r * 0.42, -r * 0.08), radius: r * 0.84));
    canvas.drawPath(
      Path.combine(PathOperation.difference, full, shadow),
      Paint()..color = const Color(0xFFE8E8D0).withValues(alpha: 0.90),
    );
  }

  // Clouds

  void _drawClouds(Canvas canvas, Size size, double waterY) {
    final a = (scene.cloudCover * 0.85).clamp(0.15, 0.92);
    final base = scene.isRaining
        ? Color.fromRGBO(38, 52, 62, a)
        : Color.fromRGBO(215, 222, 228, a);
    // Gentle horizontal sway using the wave phase at a much slower rate
    final sway = sin(phase * 2 * pi * 0.3) * 0.032;
    final defs = [
      (0.12 + sway,        waterY * 0.20, 72.0),
      (0.50 - sway * 0.6,  waterY * 0.30, 90.0),
      (0.78 + sway * 0.8,  waterY * 0.15, 60.0),
    ];
    // Extra bank when heavily overcast
    if (scene.cloudCover > 0.65) {
      _cloud(canvas, size.width * (0.30 + sway), waterY * 0.43, 98.0, base);
      _cloud(canvas, size.width * (0.65 - sway), waterY * 0.38, 80.0, base);
    }
    for (final (xf, y, w) in defs) {
      _cloud(canvas, size.width * xf, y, w, base);
    }
  }

  void _cloud(Canvas canvas, double cx, double cy, double w, Color color) {
    final p  = Paint()..color = color;
    final rx = w / 2;
    final ry = w / 4.2;
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: w, height: ry * 1.7), p);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx - rx * 0.37, cy + ry * 0.38), width: w * 0.68, height: ry * 1.45), p);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx + rx * 0.37, cy + ry * 0.38), width: w * 0.68, height: ry * 1.45), p);
  }

  // Waves

  void _drawWaves(Canvas canvas, Size size, double waterY) {
    final m = scene.waveAmpMult;
    _wave(canvas, size, baseY: waterY + 8,  amp: 9  * m, freq: 1.5, offset: phase * 2 * pi + 2.1,        color: scene.waterDeep.withValues(alpha: 0.80));
    _wave(canvas, size, baseY: waterY,       amp: 12 * m, freq: 1.2, offset: phase * 2 * pi,              color: scene.waterMid.withValues(alpha: 0.90));
    _wave(canvas, size, baseY: waterY - 4,   amp: 6  * m, freq: 2.1, offset: phase * 2 * pi * 1.3 + pi,  color: scene.waterLight.withValues(alpha: 0.50));
  }

  void _wave(Canvas canvas, Size size, {
    required double baseY, required double amp,
    required double freq,  required double offset, required Color color,
  }) {
    final path = Path();
    for (double x = 0; x <= size.width; x += 2) {
      final y = baseY + sin(x / size.width * freq * 2 * pi + offset) * amp;
      x == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  // Rain

  void _drawRain(Canvas canvas, Size size) {
    final intensity = scene.rainIntensity;
    final count     = (intensity * 70).round().clamp(10, 70);
    final paint     = Paint()
      ..color     = Colors.white.withValues(alpha: 0.20 + intensity * 0.22)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    final lenX = size.height * 0.015;
    final lenY = size.height * 0.040;
    for (int i = 0; i < count; i++) {
      final f  = _rainFracs[i];
      final ay = (f.dy + phase * 0.85) % 1.0;
      final x  = f.dx * size.width;
      final y  = ay  * size.height;
      canvas.drawLine(Offset(x, y), Offset(x + lenX, y + lenY), paint);
    }
  }

  @override
  bool shouldRepaint(_OceanPainter o) => o.phase != phase;
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

    final next = findNextTide(entries);

    final displayH = currentH?.toStringAsFixed(2) ?? next?.height.toStringAsFixed(1) ?? '--';
    final l10n = context.l10n;
    final dirLabel = isRising ? l10n.tideDirRising : tidesData.direction == 'falling' ? l10n.tideDirFalling : l10n.tideDirSteady;
    final nextStr  = next != null
        ? '${tideTypeLabel(l10n, next.type, prefix: true)} ${l10n.atTimePrep} ${next.time}'
        : '';
    final pillText = nextStr.isNotEmpty ? '$dirLabel · $nextStr' : dirLabel;
    final dotColor = isRising ? AppColors.teal : AppColors.sand;

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: AppSpacing.xl),
          Text(
            beachName ?? context.l10n.tidesPageTitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.70),
              fontSize: 13,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.8,
              shadows: const [Shadow(blurRadius: 8, color: Colors.black45)],
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
                  shadows: [Shadow(blurRadius: 16, color: Colors.black38)],
                ),
              ),
              TextSpan(
                text: 'm',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.70),
                  fontSize: 32,
                  fontWeight: FontWeight.w300,
                  shadows: const [Shadow(blurRadius: 8, color: Colors.black38)],
                ),
              ),
            ]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.30),
              borderRadius: AppRadii.cardXxl,
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 7, height: 7, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
              const SizedBox(width: AppSpacing.sm),
              Text(pillText, style: const TextStyle(
                color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500,
                shadows: [Shadow(blurRadius: 4, color: Colors.black45)],
              )),
            ]),
          ),
          const Spacer(flex: 3),
        ],
      ),
    );
  }
}

// Slideup detail sheet

class _DetailSheet extends StatelessWidget {
  const _DetailSheet({
    required this.scrollController,
    required this.sheetCtrl,
    required this.tidesData,
    this.sea,
    required this.isLoading,
  });
  final ScrollController scrollController;
  final DraggableScrollableController sheetCtrl;
  final TidesData tidesData;
  final SeaPoint? sea;
  final bool isLoading;

  void _onDragUpdate(DragUpdateDetails d, double screenH) {
    if (!sheetCtrl.isAttached) return;
    sheetCtrl.jumpTo((sheetCtrl.size - d.delta.dy / screenH).clamp(0.14, 0.72));
  }

  void _onDragEnd(DragEndDetails d) {
    if (!sheetCtrl.isAttached) return;
    final v = d.primaryVelocity ?? 0;
    final double target;
    if (v < -400) {
      target = 0.72;
    } else if (v > 400) {
      target = 0.22;
    } else {
      target = sheetCtrl.size > 0.46 ? 0.72 : 0.22;
    }
    sheetCtrl.animateTo(target,
      duration: AppDurations.slow,
      curve: Curves.easeOutCubic,
    );
  }

  void _onTap() {
    if (!sheetCtrl.isAttached) return;
    final target = sheetCtrl.size < 0.46 ? 0.72 : 0.22;
    sheetCtrl.animateTo(target,
      duration: AppDurations.slow,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 24, offset: Offset(0, -4))],
      ),
      child: Column(children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onVerticalDragUpdate: (d) => _onDragUpdate(d, screenH),
          onVerticalDragEnd: _onDragEnd,
          onTap: _onTap,
          child: Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 8),
            child: Column(children: [
              Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Builder(builder: (ctx) => Text(ctx.l10n.tidesMoreDetails, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textHint, letterSpacing: 1.2))),
              const SizedBox(height: 2),
              ListenableBuilder(
                listenable: sheetCtrl,
                builder: (_, _) => Icon(
                  sheetCtrl.isAttached && sheetCtrl.size > 0.46
                      ? Icons.keyboard_arrow_down
                      : Icons.keyboard_arrow_up,
                  color: AppColors.textHint,
                  size: 18,
                ),
              ),
            ]),
          ),
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
                      const SizedBox(height: AppSpacing.lg),
                      _SeaRow(sea: sea!),
                    ],
                    if (tidesData.entries.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.lg),
                      _TideChartCard(tidesData: tidesData),
                    ],
                  ],
                ),
        ),
      ]),
    );
  }
}

// Today's tides

class _TodayTidesSection extends StatelessWidget {
  const _TodayTidesSection({required this.entries});
  final List<TideEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Builder(
        builder: (ctx) => Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppRadii.cardLg,
            border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
          ),
          child: Center(child: Text(ctx.l10n.tidesNoData, style: AppTextStyles.secondaryMd)),
        ),
      );
    }
    return Builder(
      builder: (ctx) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(ctx.l10n.tidesTodaySection, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.9)),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppRadii.cardLg,
            border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
          ),
          child: Column(children: [
            for (int i = 0; i < entries.length; i++) ...[
              if (i > 0) const Divider(height: 1, indent: 40, color: Color(0xFFEEEEEE)),
              _TideRow(entry: entries[i]),
            ],
          ]),
        ),
      ]),
    );
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
        Text(entry.time, style: AppTextStyles.titleMd),
        const Spacer(),
        Text.rich(TextSpan(children: [
          TextSpan(
            text: '${entry.height.toStringAsFixed(1)} m',
            style: AppTextStyles.titleMd,
          ),
          TextSpan(
            text: '  ${tideTypeLabel(context.l10n, entry.type)}',
            style: AppTextStyles.secondaryMd,
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
    final l10n = context.l10n;
    return Row(children: [
      Expanded(child: _SeaMini(
        icon: Icons.thermostat_outlined, iconColor: AppColors.coral,
        label: l10n.seaTempLabel,
        value: sea.seaTemp != null ? '${sea.seaTemp!.round()}°C' : '--',
      )),
      const SizedBox(width: 10),
      Expanded(child: _SeaMini(
        icon: Icons.waves, iconColor: AppColors.teal,
        label: l10n.weatherWaves,
        value: sea.waveHeightMax != null ? '${sea.waveHeightMax!.toStringAsFixed(1)} m' : '--',
      )),
    ]);
  }
}

class _SeaMini extends StatelessWidget {
  const _SeaMini({required this.icon, required this.iconColor, required this.label, required this.value});
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
        borderRadius: AppRadii.cardLg,
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
        const SizedBox(height: AppSpacing.sm),
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
    return Builder(builder: (ctx) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(ctx.l10n.tidesChartSection, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.9)),
      const SizedBox(height: 10),
      Container(
        height: 210,
        padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppRadii.cardLg,
          border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        ),
        child: CustomPaint(
          size: Size.infinite,
          painter: _FullTideChartPainter(
            tides: tidesData.entries,
            currentHeight: tidesData.currentHeight,
            accentColor: accent,
            nowLabel: ctx.l10n.tidesNowLabel,
          ),
        ),
      ),
    ]));
  }
}

// Full tide chart painter

class _FullTideChartPainter extends CustomPainter {
  const _FullTideChartPainter({
    required this.tides,
    this.currentHeight,
    required this.accentColor,
    required this.nowLabel,
  });
  final List<TideEntry> tides;
  final double? currentHeight;
  final Color accentColor;
  final String nowLabel;

  // Internal layout constants (inside the painter's Size, after container padding)
  static const double _lPad = 36.0; // left — height axis labels
  static const double _rPad = 8.0;
  static const double _tPad = 18.0; // top — floating height labels above dots
  static const double _bPad = 26.0; // bottom — time axis labels

  static int _mins(String t) {
    final p = t.split(':');
    return p.length == 2 ? (int.tryParse(p[0]) ?? 0) * 60 + (int.tryParse(p[1]) ?? 0) : 0;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (tides.isEmpty) return;

    final cL = _lPad;
    final cT = _tPad;
    final cW = size.width  - _lPad - _rPad;
    final cH = size.height - _tPad - _bPad;

    // Unwrap extremes across midnight
    final eMins = <double>[];
    for (int i = 0; i < tides.length; i++) {
      double m = _mins(tides[i].time).toDouble();
      if (i > 0 && m < eMins.last - 200) m += 1440;
      eMins.add(m);
    }
    final eH = tides.map((t) => t.height).toList();

    // Normalise now into the same time-space as eMins
    final now = DateTime.now();
    double nowM = now.hour * 60.0 + now.minute + now.second / 60.0;
    while (nowM < eMins.first - 720) { nowM += 1440; }
    while (nowM > eMins.first + 720) { nowM -= 1440; }

    // Window
    final wS = min(nowM, eMins.first) - 30.0;
    final wE = eMins.last + 30.0;

    // Current height via cosine interpolation
    final h0 = currentHeight ?? _cosInterp(eMins, eH, nowM);

    // Height axis range, snapped to 0.5 m
    final allH = [...eH, h0];
    final hMin = (allH.reduce(min) / 0.5).floor() * 0.5;
    final hMax = (allH.reduce(max) / 0.5).ceil()  * 0.5;
    final hRng = (hMax - hMin).clamp(0.5, 99.0);

    // Mapping helpers
    double toX(double m) => cL + (m - wS) / (wE - wS) * cW;
    double toY(double h) => cT + (1 - (h - hMin) / hRng) * cH;

    // Grid lines + height labels
    for (double h = hMin; h <= hMax + 0.01; h += 0.5) {
      final y = toY(h);
      if (y < cT - 2 || y > cT + cH + 2) continue;
      canvas.drawLine(
        Offset(cL, y), Offset(cL + cW, y),
        Paint()
          ..color = Colors.black.withValues(alpha: h == hMin ? 0.12 : 0.07)
          ..strokeWidth = 1.0,
      );
      _label(canvas, '${h.toStringAsFixed(1)}m', Offset(cL - 5, y),
        const TextStyle(fontSize: 9, color: AppColors.textHint, fontWeight: FontWeight.w500),
        align: TextAlign.right,
      );
    }

    // Build ordered curve points (extremes + now)
    final pts = <(double, double)>[
      for (int i = 0; i < eMins.length; i++) (eMins[i], eH[i]),
      (nowM, h0),
    ]..sort((a, b) => a.$1.compareTo(b.$1));

    final curvePath = _buildCurve(pts, toX, toY);

    // Gradient fill (clipped to chart area)
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(cL, cT, cW, cH));
    final fill = Path.from(curvePath)
      ..lineTo(cL + cW, cT + cH)
      ..lineTo(cL, cT + cH)
      ..close();
    canvas.drawPath(fill, Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          accentColor.withValues(alpha: 0.30),
          accentColor.withValues(alpha: 0.04),
        ],
      ).createShader(Rect.fromLTWH(cL, cT, cW, cH)));

    // Curve line 
    canvas.drawPath(curvePath, Paint()
      ..color = accentColor
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round);
    canvas.restore();

    // Dashed "now" vertical line 
    final nowX = toX(nowM).clamp(cL, cL + cW);
    const dashH = 6.0; const gapH = 4.0;
    final dashPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.16)
      ..strokeWidth = 1.0;
    for (var dy = cT; dy < cT + cH; dy += dashH + gapH) {
      canvas.drawLine(Offset(nowX, dy), Offset(nowX, min(dy + dashH, cT + cH)), dashPaint);
    }
    _label(canvas, nowLabel, Offset(nowX, cT - 5),
      const TextStyle(fontSize: 8, color: AppColors.textHint, fontWeight: FontWeight.w700, letterSpacing: 0.5),
      align: TextAlign.center,
    );

    // Current position dot
    final nowY = toY(h0).clamp(cT, cT + cH);
    canvas.drawCircle(Offset(nowX, nowY), 7, Paint()..color = AppColors.primary.withValues(alpha: 0.15));
    canvas.drawCircle(Offset(nowX, nowY), 6, Paint()..color = AppColors.primary);
    canvas.drawCircle(Offset(nowX, nowY), 4.5, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(nowX, nowY), 2.8, Paint()..color = accentColor);

    // Current height label — left of dot if in right half, else right
    final labelX  = nowX > cL + cW / 2 ? nowX - 9 : nowX + 9;
    final labelAl = nowX > cL + cW / 2 ? TextAlign.right : TextAlign.left;
    _label(canvas, '${h0.toStringAsFixed(2)}m', Offset(labelX, nowY),
      TextStyle(fontSize: 9.5, color: accentColor, fontWeight: FontWeight.w700),
      align: labelAl,
    );

    // Extreme dots + labels 
    for (int i = 0; i < tides.length; i++) {
      final ex = toX(eMins[i]).clamp(cL, cL + cW);
      final ey = toY(eH[i]).clamp(cT, cT + cH);
      final dc = tides[i].type == 'alta' ? AppColors.teal : AppColors.sand;

      // Three-ring dot
      canvas.drawCircle(Offset(ex, ey), 6,   Paint()..color = dc.withValues(alpha: 0.20));
      canvas.drawCircle(Offset(ex, ey), 4.5, Paint()..color = Colors.white);
      canvas.drawCircle(Offset(ex, ey), 2.8, Paint()..color = dc);

      // Height label above dot
      _label(canvas, '${eH[i].toStringAsFixed(1)} m', Offset(ex, ey - 13),
        TextStyle(fontSize: 9, color: dc, fontWeight: FontWeight.w700),
        align: TextAlign.center,
      );

      // Time label below chart
      _label(canvas, tides[i].time, Offset(ex, cT + cH + 5),
        const TextStyle(fontSize: 9.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
        align: TextAlign.center,
      );
    }
  }

  // Helpers 

  Path _buildCurve(List<(double, double)> pts, double Function(double) toX, double Function(double) toY) {
    final path = Path()..moveTo(toX(pts.first.$1), toY(pts.first.$2));
    for (int i = 1; i < pts.length; i++) {
      final cpX = (toX(pts[i - 1].$1) + toX(pts[i].$1)) / 2;
      path.cubicTo(cpX, toY(pts[i - 1].$2), cpX, toY(pts[i].$2), toX(pts[i].$1), toY(pts[i].$2));
    }
    return path;
  }

  void _label(Canvas canvas, String s, Offset pos, TextStyle style, {TextAlign align = TextAlign.left}) {
    final tp = TextPainter(text: TextSpan(text: s, style: style), textDirection: TextDirection.ltr)..layout();
    double dx = pos.dx;
    if (align == TextAlign.center) dx -= tp.width / 2;
    if (align == TextAlign.right)  dx -= tp.width;
    tp.paint(canvas, Offset(dx, pos.dy - tp.height / 2));
  }

  double _cosInterp(List<double> ts, List<double> hs, double t) {
    if (t <= ts.first) return hs.first;
    if (t >= ts.last)  return hs.last;
    for (int i = 1; i < ts.length; i++) {
      if (t <= ts[i]) {
        final p = (t - ts[i - 1]) / (ts[i] - ts[i - 1]);
        return hs[i - 1] + (hs[i] - hs[i - 1]) * ((1 - cos(p * pi)) / 2);
      }
    }
    return hs.last;
  }

  @override
  bool shouldRepaint(_FullTideChartPainter o) =>
      o.tides != tides || o.currentHeight != currentHeight || o.accentColor != accentColor || o.nowLabel != nowLabel;
}

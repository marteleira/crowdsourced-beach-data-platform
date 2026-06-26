import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_config.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/presence/heartbeat_service.dart';
import '../data/beach_provider.dart';
import '../domain/beach_models.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/beach_helpers.dart';
import '../../../shared/utils/format_helpers.dart';
import '../../../shared/widgets/empty_state.dart';

class BeachListScreen extends ConsumerStatefulWidget {
  const BeachListScreen({super.key});

  @override
  ConsumerState<BeachListScreen> createState() => _BeachListScreenState();
}

class _BeachListScreenState extends ConsumerState<BeachListScreen> {
  final _searchController = TextEditingController();
  final _mapController = MapController();
  final _sheetCtrl = DraggableScrollableController();

  String _search = '';
  String _flagFilter = 'all';
  BeachSummary? _selectedBeach;
  bool _hasZoomedToUser = false;
  bool _reloading = false;

  static const _kMinSize = 0.08;
  static const _kMidSize = 0.30;
  static const _kMaxSize = 0.90;

  static const _kCenter = LatLng(AppConfig.mapCenterLat, AppConfig.mapCenterLon);
  static const _kInitialZoom = AppConfig.mapInitialZoom;

  List<(String, String, Color?)> _filters(AppLocalizations l10n) => [
    ('all', l10n.filterAll, null),
    ('green', l10n.filterSafe, AppColors.flagGreen),
    ('yellow', l10n.filterCaution, AppColors.flagYellow),
    ('red', l10n.filterDanger, AppColors.flagRed),
    ('unknown', l10n.filterNoData, AppColors.textHint),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _zoomToUser());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController.dispose();
    _sheetCtrl.dispose();
    super.dispose();
  }

  void _zoomToUser() {
    if (_hasZoomedToUser) return;
    final pos = ref.read(locationProvider).asData?.value;
    if (pos != null) {
      _hasZoomedToUser = true;
      _mapController.move(LatLng(pos.latitude, pos.longitude), 13);
    }
  }

  List<BeachSummary> _applyFilters(List<BeachSummary> beaches) {
    return beaches.where((b) {
      final matchesFlag = switch (_flagFilter) {
        'all' => true,
        'red' => b.flagColor == 'red' || b.flagColor == 'purple',
        'unknown' => b.flagColor == 'unknown',
        final f => b.flagColor == f,
      };
      final matchesSearch =
          _search.isEmpty || b.name.toLowerCase().contains(_search.toLowerCase());
      return matchesFlag && matchesSearch;
    }).toList();
  }

  Future<void> _refresh() async {
    ref.invalidate(locationProvider);
    ref.invalidate(beachListProvider);
    ref.invalidate(mapUsersProvider);
    await ref.read(beachListProvider.future);
  }

  Future<void> _reload() async {
    if (_reloading) return;
    setState(() => _reloading = true);
    try {
      // register presence at the nearest beach before reloading
      try {
        await sendHeartbeatForCurrentPosition(ref);
      } catch (_) {}
      await _refresh();
    } finally {
      if (mounted) setState(() => _reloading = false);
    }
  }

  void _selectOnMap(BeachSummary beach) {
    setState(() => _selectedBeach = beach);
    _mapController.move(LatLng(beach.lat, beach.lon), 14);
    if (_sheetCtrl.isAttached) {
      _sheetCtrl.animateTo(
        _kMidSize,
        duration: AppDurations.slow,
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _onDragUpdate(DragUpdateDetails d, double screenH) {
    if (!_sheetCtrl.isAttached) return;
    _sheetCtrl.jumpTo(
      (_sheetCtrl.size - d.delta.dy / screenH).clamp(_kMinSize, _kMaxSize),
    );
  }

  void _onDragEnd(DragEndDetails d) {
    if (!_sheetCtrl.isAttached) return;
    final v = d.primaryVelocity ?? 0;
    final double target;
    if (v < -500) {
      target = _sheetCtrl.size < _kMidSize ? _kMidSize : _kMaxSize;
    } else if (v > 500) {
      target = _sheetCtrl.size > _kMidSize ? _kMidSize : _kMinSize;
    } else {
      final s = _sheetCtrl.size;
      if (s < (_kMinSize + _kMidSize) / 2) {
        target = _kMinSize;
      } else if (s < (_kMidSize + _kMaxSize) / 2) {
        target = _kMidSize;
      } else {
        target = _kMaxSize;
      }
    }
    _sheetCtrl.animateTo(
      target,
      duration: AppDurations.slow,
      curve: Curves.easeOutCubic,
    );
  }

  void _onHandleTap() {
    if (!_sheetCtrl.isAttached) return;
    final s = _sheetCtrl.size;
    final double target;
    if (s < _kMidSize - 0.05) {
      target = _kMidSize;
    } else if (s < _kMaxSize - 0.05) {
      target = _kMaxSize;
    } else {
      target = _kMinSize;
    }
    _sheetCtrl.animateTo(
      target,
      duration: AppDurations.slow,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final filters = _filters(l10n);
    final top = MediaQuery.paddingOf(context).top;
    final screenH = MediaQuery.of(context).size.height;

    final beachesAsync = ref.watch(beachListProvider);
    final mapUsersAsync = ref.watch(mapUsersProvider);
    final locationAsync = ref.watch(locationProvider);

    ref.listen(locationProvider, (_, next) {
      if (!_hasZoomedToUser) {
        final pos = next.asData?.value;
        if (pos != null) {
          _hasZoomedToUser = true;
          _mapController.move(LatLng(pos.latitude, pos.longitude), 13);
        }
      }
    });

    final allBeaches = beachesAsync.asData?.value ?? [];
    final filteredSlugs = _applyFilters(allBeaches).map((b) => b.slug).toSet();
    final position = locationAsync.asData?.value;

    return Stack(
      fit: StackFit.expand,
      children: [
        // ── Full-screen map ──────────────────────────────────────────
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _kCenter,
            initialZoom: _kInitialZoom,
            onTap: (_, _) => setState(() => _selectedBeach = null),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.ondacerta.app',
            ),
            MarkerLayer(
              markers: [
                ...allBeaches.map((beach) {
                  final active = filteredSlugs.contains(beach.slug);
                  final color = AppColors.forFlag(beach.flagColor);
                  final dimmed = active ? color : color.withValues(alpha: 0.3);
                  final userCount = mapUsersAsync.asData?.value
                          .firstWhere(
                            (m) => m.beachSlug == beach.slug,
                            orElse: () => const MapBeachPresence(
                              beachId: 0,
                              beachSlug: '',
                              beachName: '',
                              userCount: 0,
                            ),
                          )
                          .userCount ??
                      0;
                  return Marker(
                    point: LatLng(beach.lat, beach.lon),
                    width: 46,
                    height: 56,
                    child: GestureDetector(
                      onTap: () => _selectOnMap(beach),
                      child: _BeachMarker(
                        color: dimmed,
                        userCount: userCount,
                        selected: _selectedBeach?.slug == beach.slug,
                      ),
                    ),
                  );
                }),
                if (position != null)
                  Marker(
                    point: LatLng(position.latitude, position.longitude),
                    width: 20,
                    height: 20,
                    child: const _UserLocationMarker(),
                  ),
              ],
            ),
          ],
        ),
        // ── Top gradient + title ─────────────────────────────────────
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: top + 56,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.40),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: top + 10,
          left: 16,
          child: Text(
            l10n.beachListTitle,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [Shadow(blurRadius: 6, color: Colors.black38)],
            ),
          ),
        ),
        Positioned(
          top: top + 6,
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
              child: (_reloading || beachesAsync.isLoading)
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
        // ── Draggable sheet ──────────────────────────────────────────
        DraggableScrollableSheet(
          controller: _sheetCtrl,
          initialChildSize: _kMidSize,
          minChildSize: _kMinSize,
          maxChildSize: _kMaxSize,
          snap: true,
          snapSizes: const [_kMinSize, _kMidSize, _kMaxSize],
          builder: (_, scrollController) {
            final filteredBeaches = _applyFilters(allBeaches);
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 24,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Handle
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onVerticalDragUpdate: (d) => _onDragUpdate(d, screenH),
                    onVerticalDragEnd: _onDragEnd,
                    onTap: _onHandleTap,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10, bottom: 8),
                      child: Column(
                        children: [
                          Container(
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 6),
                          ListenableBuilder(
                            listenable: _sheetCtrl,
                            builder: (_, _) => Icon(
                              _sheetCtrl.isAttached && _sheetCtrl.size > _kMaxSize - 0.05
                                  ? Icons.keyboard_arrow_down
                                  : Icons.keyboard_arrow_up,
                              color: AppColors.textHint,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Selected beach banner
                  if (_selectedBeach != null)
                    _SelectedBeachBanner(
                      beach: _selectedBeach!,
                      onNavigate: () => context.push(
                        AppRoutes.beach(_selectedBeach!.slug),
                        extra: _selectedBeach,
                      ),
                      onClose: () => setState(() => _selectedBeach = null),
                    ),
                  // Search bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: AppRadii.cardMd,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (q) => setState(() => _search = q),
                        style: const TextStyle(fontSize: 14, color: AppColors.primary),
                        decoration: InputDecoration(
                          hintText: l10n.searchHint,
                          hintStyle: const TextStyle(
                            color: AppColors.textHint,
                            fontSize: 14,
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: AppColors.textHint,
                            size: 20,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.clear,
                                    size: 18,
                                    color: AppColors.textHint,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _search = '');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  // Filter chips
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 32,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filters.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 6),
                      itemBuilder: (_, i) {
                        final (id, label, color) = filters[i];
                        final selected = _flagFilter == id;
                        return _FilterChip(
                          label: label,
                          color: color,
                          selected: selected,
                          onTap: () => setState(() => _flagFilter = id),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  // Beach list
                  Expanded(
                    child: beachesAsync.when(
                      loading: () => const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.teal,
                        ),
                      ),
                      error: (_, _) => EmptyState(
                        icon: Icons.cloud_off_rounded,
                        message: l10n.errorLoadBeaches,
                        actionLabel: l10n.tryAgain,
                        onAction: _refresh,
                      ),
                      data: (_) {
                        if (filteredBeaches.isEmpty) {
                          return EmptyState(
                            icon: Icons.search_off_rounded,
                            message: _search.isNotEmpty
                                ? l10n.noBeachesForSearch(_search)
                                : l10n.noBeachesForFilter,
                          );
                        }
                        return RefreshIndicator(
                          onRefresh: _refresh,
                          color: AppColors.teal,
                          child: ListView.separated(
                            controller: scrollController,
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            itemCount: filteredBeaches.length,
                            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                            itemBuilder: (_, i) => _BeachCard(
                              beach: filteredBeaches[i],
                              selected: _selectedBeach?.slug == filteredBeaches[i].slug,
                              onLocate: () => _selectOnMap(filteredBeaches[i]),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

// ── Map widgets ──────────────────────────────────────────────────────────────

class _BeachMarker extends StatelessWidget {
  const _BeachMarker({
    required this.color,
    required this.userCount,
    required this.selected,
  });
  final Color color;
  final int userCount;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: selected ? 1.2 : 1.0,
      duration: AppDurations.fast,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: selected ? 2.5 : 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: selected ? 0.5 : 0.3),
                      blurRadius: selected ? 10 : 6,
                      spreadRadius: selected ? 2 : 0,
                    ),
                  ],
                ),
                child: const Icon(Icons.waves_rounded, color: Colors.white, size: 16),
              ),
              if (userCount > 0)
                Positioned(
                  top: -3,
                  right: -6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: AppRadii.cardSm,
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                    child: Text(
                      '$userCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Container(width: 2, height: 6, color: color),
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }
}

class _UserLocationMarker extends StatelessWidget {
  const _UserLocationMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(color: Colors.blue.withValues(alpha: 0.4), blurRadius: 8),
        ],
      ),
    );
  }
}

// ── Selected beach banner (inside sheet) ─────────────────────────────────────

class _SelectedBeachBanner extends StatelessWidget {
  const _SelectedBeachBanner({
    required this.beach,
    required this.onNavigate,
    required this.onClose,
  });
  final BeachSummary beach;
  final VoidCallback onNavigate;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final flagColor = AppColors.forFlag(beach.flagColor);
    final flagLabelText = flagLabel(l10n, beach.flagColor);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadii.cardMd,
        border: Border(left: BorderSide(color: flagColor, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    beach.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: flagColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        flagLabelText,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: flagColor,
                        ),
                      ),
                      if (beach.occupancyLevel != 'unknown') ...[
                        const SizedBox(width: AppSpacing.sm),
                        const _Dot(),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          occupancyLabel(l10n, beach.occupancyLevel),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          TextButton(
            onPressed: onNavigate,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.teal,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              l10n.beachCardView,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            color: AppColors.textHint,
            onPressed: onClose,
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(8),
          ),
        ],
      ),
    );
  }

}

// ── List widgets ─────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final Color? color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? activeColor : Colors.white,
          borderRadius: AppRadii.cardXl,
          border: Border.all(
            color: selected ? activeColor : AppColors.borderLight,
          ),
          boxShadow: selected
              ? [BoxShadow(color: activeColor.withValues(alpha: 0.25), blurRadius: 6)]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (color != null && !selected) ...[
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BeachCard extends StatelessWidget {
  const _BeachCard({
    required this.beach,
    this.selected = false,
    required this.onLocate,
  });
  final BeachSummary beach;
  final bool selected;
  final VoidCallback onLocate;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final flagColor = AppColors.forFlag(beach.flagColor);

    return GestureDetector(
      onTap: () => context.push(AppRoutes.beach(beach.slug), extra: beach),
      child: AnimatedContainer(
        duration: AppDurations.medium,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppRadii.cardButton,
          border: selected ? Border.all(color: AppColors.teal, width: 1.5) : null,
          boxShadow: [
            BoxShadow(
              color: selected
                  ? AppColors.teal.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: selected ? 12 : 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: flagColor,
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 13, 8, 13),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              beach.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          if (beach.distanceKm != null) ...[
                            const SizedBox(width: AppSpacing.sm),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.teal.withValues(alpha: 0.08),
                                borderRadius: AppRadii.cardSm,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.near_me,
                                    size: 11,
                                    color: AppColors.tealDark,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    formatDistance(beach.distanceKm!),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.tealDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _StatusDot(color: flagColor),
                          const SizedBox(width: 5),
                          Text(
                            flagLabel(l10n, beach.flagColor),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: flagColor,
                            ),
                          ),
                          if (beach.occupancyLevel != 'unknown') ...[
                            const SizedBox(width: 10),
                            const _Dot(),
                            const SizedBox(width: 10),
                            Text(
                              occupancyLabel(l10n, beach.occupancyLevel),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                          if (activityLabelText(l10n, beach.activityLabel) case final actLabel?) ...[
                            const SizedBox(width: 10),
                            const _Dot(),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                actLabel,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (beach.activeAlertsCount > 0) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              size: 13,
                              color: AppColors.amber,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              '${beach.activeAlertsCount} ${beach.activeAlertsCount == 1 ? l10n.beachAlertSingular : l10n.beachAlertPlural}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.amber,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              GestureDetector(
                onTap: onLocate,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Icon(
                    Icons.location_on_outlined,
                    size: 20,
                    color: selected ? AppColors.teal : AppColors.textHint,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 7,
    height: 7,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) => Container(
    width: 3,
    height: 3,
    decoration: const BoxDecoration(color: AppColors.textHint, shape: BoxShape.circle),
  );
}


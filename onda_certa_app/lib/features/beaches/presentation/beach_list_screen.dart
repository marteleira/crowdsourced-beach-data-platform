import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../data/beach_provider.dart';
import '../domain/beach_models.dart';
import '../../../shared/theme/app_theme.dart';

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

  static const _kMinSize = 0.08;
  static const _kMidSize = 0.50;
  static const _kMaxSize = 0.90;

  static const _kCenter = LatLng(38.465, -8.94);
  static const _kInitialZoom = 11.0;

  static const _filters = [
    ('all', 'Todas', null),
    ('green', 'Seguras', AppColors.flagGreen),
    ('yellow', 'Cuidado', AppColors.flagYellow),
    ('red', 'Perigo', AppColors.flagRed),
    ('unknown', 'Sem dados', AppColors.textHint),
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

  void _selectOnMap(BeachSummary beach) {
    setState(() => _selectedBeach = beach);
    _mapController.move(LatLng(beach.lat, beach.lon), 14);
    if (_sheetCtrl.isAttached) {
      _sheetCtrl.animateTo(
        _kMidSize,
        duration: const Duration(milliseconds: 280),
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
      duration: const Duration(milliseconds: 280),
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
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
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
          child: const Text(
            'Praias',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [Shadow(blurRadius: 6, color: Colors.black38)],
            ),
          ),
        ),
        if (beachesAsync.isLoading)
          const Positioned(
            top: 60,
            right: 16,
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                color: AppColors.teal,
                strokeWidth: 2,
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
                        '/beach/${_selectedBeach!.slug}',
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
                        borderRadius: BorderRadius.circular(12),
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
                          hintText: 'Pesquisar praia...',
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
                      itemCount: _filters.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 6),
                      itemBuilder: (_, i) {
                        final (id, label, color) = _filters[i];
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
                  const SizedBox(height: 8),
                  // Beach list
                  Expanded(
                    child: beachesAsync.when(
                      loading: () => const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.teal,
                        ),
                      ),
                      error: (_, _) => _EmptyState(
                        icon: Icons.cloud_off_rounded,
                        message: 'Não foi possível carregar as praias',
                        actionLabel: 'Tentar de novo',
                        onAction: _refresh,
                      ),
                      data: (_) {
                        if (filteredBeaches.isEmpty) {
                          return _EmptyState(
                            icon: Icons.search_off_rounded,
                            message: _search.isNotEmpty
                                ? 'Nenhuma praia encontrada para "$_search"'
                                : 'Nenhuma praia com este filtro',
                          );
                        }
                        return RefreshIndicator(
                          onRefresh: _refresh,
                          color: AppColors.teal,
                          child: ListView.separated(
                            controller: scrollController,
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            itemCount: filteredBeaches.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 8),
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
      duration: const Duration(milliseconds: 180),
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
                      borderRadius: BorderRadius.circular(8),
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
    final flagColor = AppColors.forFlag(beach.flagColor);
    final flagLabel = switch (beach.flagColor) {
      'green' => 'Segura',
      'yellow' => 'Cuidado',
      'red' => 'Perigo',
      'purple' => 'Encerrada',
      _ => 'Sem dados',
    };

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          const SizedBox(width: 12),
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
                        flagLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: flagColor,
                        ),
                      ),
                      if (beach.occupancyLevel != 'unknown') ...[
                        const SizedBox(width: 8),
                        const _Dot(),
                        const SizedBox(width: 8),
                        Text(
                          _occupancyLabel(beach.occupancyLevel),
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
            child: const Text(
              'Ver →',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
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

  String _occupancyLabel(String level) => switch (level) {
    'low' => 'Tranquila',
    'medium' => 'Moderada',
    'high' => 'Lotada',
    _ => '',
  };
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
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? activeColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? activeColor : const Color(0xFFE5E7EB),
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
    final flagColor = AppColors.forFlag(beach.flagColor);

    return GestureDetector(
      onTap: () => context.push('/beach/${beach.slug}', extra: beach),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
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
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.teal.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
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
                                    _formatDist(beach.distanceKm!),
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
                            _flagLabel(beach.flagColor),
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
                              _occupancyLabel(beach.occupancyLevel),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                          if (beach.activityLabel != null) ...[
                            const SizedBox(width: 10),
                            const _Dot(),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                beach.activityLabel!,
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
                            const SizedBox(width: 4),
                            Text(
                              '${beach.activeAlertsCount} ${beach.activeAlertsCount == 1 ? 'alerta ativo' : 'alertas ativos'}',
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

  String _formatDist(double km) =>
      km < 1 ? '${(km * 1000).round()} m' : '${km.toStringAsFixed(1)} km';

  String _flagLabel(String color) => switch (color) {
    'green' => 'Segura',
    'yellow' => 'Cuidado',
    'red' => 'Perigo',
    'purple' => 'Encerrada',
    _ => 'Sem dados',
  };

  String _occupancyLabel(String level) => switch (level) {
    'low' => 'Tranquila',
    'medium' => 'Moderada',
    'high' => 'Lotada',
    _ => '',
  };
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(backgroundColor: AppColors.teal),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
  String _search = '';
  String _flagFilter = 'all';

  static const _filters = [
    ('all',     'Todas',     null),
    ('green',   'Seguras',   AppColors.flagGreen),
    ('yellow',  'Cuidado',   AppColors.flagYellow),
    ('red',     'Perigo',    AppColors.flagRed),
    ('unknown', 'Sem dados', AppColors.textHint),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<BeachSummary> _applyFilters(List<BeachSummary> beaches) {
    return beaches.where((b) {
      final matchesFlag = switch (_flagFilter) {
        'all'     => true,
        'red'     => b.flagColor == 'red' || b.flagColor == 'purple',
        'unknown' => b.flagColor == 'unknown',
        final f   => b.flagColor == f,
      };
      final matchesSearch = _search.isEmpty ||
          b.name.toLowerCase().contains(_search.toLowerCase());
      return matchesFlag && matchesSearch;
    }).toList();
  }

  Future<void> _refresh() async {
    ref.invalidate(locationProvider);
    ref.invalidate(beachListProvider);
    await ref.read(beachListProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final beachesAsync = ref.watch(beachListProvider);

    return Column(
      children: [
        _ListHeader(
          controller: _searchController,
          flagFilter: _flagFilter,
          filters: _filters,
          onSearchChanged: (q) => setState(() => _search = q),
          onFilterChanged: (f) => setState(() => _flagFilter = f),
        ),
        Expanded(
          child: beachesAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.teal),
            ),
            error: (_, _) => _EmptyState(
              icon: Icons.cloud_off_rounded,
              message: 'Não foi possível carregar as praias',
              actionLabel: 'Tentar de novo',
              onAction: _refresh,
            ),
            data: (beaches) {
              final list = _applyFilters(beaches);
              if (list.isEmpty) {
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
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _BeachCard(beach: list[i]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ListHeader extends StatelessWidget {
  const _ListHeader({
    required this.controller,
    required this.flagFilter,
    required this.filters,
    required this.onSearchChanged,
    required this.onFilterChanged,
  });
  final TextEditingController controller;
  final String flagFilter;
  final List<(String, String, Color?)> filters;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Container(
      color: AppColors.background,
      padding: EdgeInsets.fromLTRB(16, top + 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Praias',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          // Search bar
          Container(
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
              controller: controller,
              onChanged: onSearchChanged,
              style: const TextStyle(fontSize: 14, color: AppColors.primary),
              decoration: InputDecoration(
                hintText: 'Pesquisar praia...',
                hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: AppColors.textHint, size: 20),
                suffixIcon: controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18, color: AppColors.textHint),
                        onPressed: () {
                          controller.clear();
                          onSearchChanged('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Filter chips
          SizedBox(
            height: 32,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: filters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (_, i) {
                final (id, label, color) = filters[i];
                final selected = flagFilter == id;
                return _FilterChip(
                  label: label,
                  color: color,
                  selected: selected,
                  onTap: () => onFilterChanged(id),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

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
  const _BeachCard({required this.beach});
  final BeachSummary beach;

  @override
  Widget build(BuildContext context) {
    final flagColor = AppColors.forFlag(beach.flagColor);

    return GestureDetector(
      onTap: () => context.push('/beach/${beach.slug}', extra: beach),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Flag color accent
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: flagColor,
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
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
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.teal.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.near_me, size: 11, color: AppColors.tealDark),
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
                          const SizedBox(width: 10),
                          const _Dot(),
                          const SizedBox(width: 10),
                          Text(
                            _occupancyLabel(beach.occupancyLevel),
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          if (beach.activityLabel != null) ...[
                            const SizedBox(width: 10),
                            const _Dot(),
                            const SizedBox(width: 10),
                            Text(
                              beach.activityLabel!,
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ],
                      ),
                      if (beach.activeAlertsCount > 0) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, size: 13, color: AppColors.amber),
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
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(Icons.chevron_right_rounded, color: AppColors.textHint, size: 20),
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
    'green'   => 'Segura',
    'yellow'  => 'Cuidado',
    'red'     => 'Perigo',
    'purple'  => 'Encerrada',
    _         => 'Sem dados',
  };

  String _occupancyLabel(String level) => switch (level) {
    'low'    => 'Tranquila',
    'medium' => 'Moderada',
    'high'   => 'Lotada',
    _        => 'Ocupação desconhecida',
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

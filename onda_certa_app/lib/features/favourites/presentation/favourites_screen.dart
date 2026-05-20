import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../features/beaches/data/beach_provider.dart';
import '../../../features/beaches/domain/beach_models.dart';
import '../../../shared/theme/app_theme.dart';

class FavouritesScreen extends ConsumerWidget {
  const FavouritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favourites = ref.watch(favouritesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Praias Favoritas', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: favourites.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.teal, strokeWidth: 2.5)),
        error: (_, _) => _ErrorView(onRetry: () => ref.invalidate(favouritesProvider)),
        data: (beaches) {
          if (beaches.isEmpty) return const _EmptyView();
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(favouritesProvider),
            color: AppColors.teal,
            backgroundColor: Colors.white,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              itemCount: beaches.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _FavouriteCard(beach: beaches[i]),
            ),
          );
        },
      ),
    );
  }
}

class _FavouriteCard extends ConsumerWidget {
  const _FavouriteCard({required this.beach});
  final BeachSummary beach;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              beach.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(color: flagColor, shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  _flagLabel(beach.flagColor),
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                                if (beach.activeAlertsCount > 0) ...[
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: AppColors.coral.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${beach.activeAlertsCount} alertas',
                                      style: const TextStyle(fontSize: 11, color: AppColors.coral, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.favorite, color: AppColors.coral, size: 22),
                        tooltip: 'Remover favorito',
                        onPressed: () => _removeFavourite(context, ref),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _removeFavourite(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(favouritesProvider.notifier).toggle(beach);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao remover favorito'), backgroundColor: AppColors.coral),
        );
      }
    }
  }

  String _flagLabel(String flag) => switch (flag) {
    'green' => 'Segura',
    'yellow' => 'Cuidado',
    'red' => 'Perigo',
    'purple' => 'Fechada',
    _ => 'Desconhecida',
  };
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite_border, size: 64, color: AppColors.textHint),
          const SizedBox(height: 16),
          const Text(
            'Sem praias favoritas',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Abre uma praia e toca no coração\npara a guardar aqui.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 48, color: AppColors.textHint),
          const SizedBox(height: 12),
          const Text('Erro ao carregar favoritos', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('Tentar novamente')),
        ],
      ),
    );
  }
}

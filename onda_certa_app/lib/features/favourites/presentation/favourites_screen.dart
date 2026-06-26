import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_routes.dart';
import '../../../features/beaches/data/beach_provider.dart';
import '../../../features/beaches/domain/beach_models.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/beach_helpers.dart';
import '../../../shared/widgets/beach_cover_image.dart';
import '../../../core/l10n/l10n.dart';

class FavouritesScreen extends ConsumerWidget {
  const FavouritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favourites = ref.watch(favouritesProvider);
    final count = favourites.value?.length;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.l10n.favouritesScreenTitle, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
              if (count != null && count > 0)
                Text(
                  count == 1 ? context.l10n.favouritesSaved1 : context.l10n.favouritesSavedN(count),
                  style: const TextStyle(fontSize: 11, color: Colors.white54, fontWeight: FontWeight.w400),
                ),
            ],
          ),
        ),
        body: favourites.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.teal, strokeWidth: 2.5)),
          error: (_, _) => _ErrorView(onRetry: () => ref.invalidate(favouritesProvider)),
          data: (beaches) => RefreshIndicator(
            onRefresh: () async => ref.invalidate(favouritesProvider),
            color: AppColors.teal,
            backgroundColor: Colors.white,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                if (beaches.isEmpty)
                  const SliverFillRemaining(hasScrollBody: false, child: _EmptyView())
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                    sliver: SliverList.separated(
                      itemCount: beaches.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemBuilder: (_, i) => _BeachFavCard(beach: beaches[i]),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Beach card 

class _BeachFavCard extends ConsumerWidget {
  const _BeachFavCard({required this.beach});
  final BeachSummary beach;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final flagColor = AppColors.forFlag(beach.flagColor);
    //On dark card backgrounds, the gray "unknown" colour is invisible — use white instead.
    final pillColor = beach.flagColor == 'unknown' || beach.flagColor.isEmpty ? Colors.white : flagColor;

    return GestureDetector(
      onTap: () => context.push(AppRoutes.beach(beach.slug), extra: beach),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: AppRadii.cardXl,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.13),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: AppRadii.cardXl,
          child: SizedBox(
            height: 195,
            child: Stack(
              fit: StackFit.expand,
              children: [
                BeachCoverImage(
                  flagColor: beach.flagColor,
                  photoUrl: beach.coverPhotoUrl,
                  height: 195,
                  dimOpacity: 0,
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.38),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.68),
                      ],
                      stops: const [0.0, 0.38, 1.0],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: pillColor.withValues(alpha: 0.22),
                              borderRadius: AppRadii.cardXl,
                              border: Border.all(color: pillColor.withValues(alpha: 0.65), width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(width: 6, height: 6, decoration: BoxDecoration(color: pillColor, shape: BoxShape.circle)),
                                const SizedBox(width: 5),
                                Text(flagLabel(l10n, beach.flagColor), style: TextStyle(color: pillColor, fontSize: 11, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                          const Spacer(),
                          if (beach.activeAlertsCount > 0) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.coral.withValues(alpha: 0.9),
                                borderRadius: AppRadii.cardXl,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 11),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${beach.activeAlertsCount} ${beach.activeAlertsCount == 1 ? l10n.favouriteAlertSingular : l10n.favouriteAlertPlural}',
                                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          GestureDetector(
                            onTap: () => _confirmRemove(context, ref),
                            child: Container(
                              width: 34, height: 34,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                              ),
                              child: const Icon(Icons.favorite, color: AppColors.coral, size: 17),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        beach.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                          shadows: [Shadow(blurRadius: 8, color: Colors.black45)],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (beach.activityLabel != null) ...[
                            const Icon(Icons.people_outline, color: Colors.white70, size: 13),
                            const SizedBox(width: 4),
                            Text(beach.activityLabel!, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                            const SizedBox(width: 12),
                          ],
                          if (beach.distanceKm != null) ...[
                            const Icon(Icons.near_me_outlined, color: Colors.white60, size: 13),
                            const SizedBox(width: 4),
                            Text('${beach.distanceKm!.toStringAsFixed(1)} km', style: const TextStyle(color: Colors.white60, fontSize: 12)),
                          ],
                          const Spacer(),
                          const Icon(Icons.arrow_outward, color: Colors.white60, size: 15),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmRemove(BuildContext context, WidgetRef ref) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xxl))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(color: AppColors.borderMedium, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 24),
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(color: AppColors.coral.withValues(alpha: 0.10), shape: BoxShape.circle),
              child: const Icon(Icons.favorite_border, color: AppColors.coral, size: 28),
            ),
            const SizedBox(height: 14),
            Text(
              context.l10n.favouriteRemoveTitle(beach.name),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              context.l10n.favouriteRemoveBody,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.borderMedium),
                      shape: RoundedRectangleBorder(borderRadius: AppRadii.cardButton),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: Text(context.l10n.cancelLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.coral,
                      shape: RoundedRectangleBorder(borderRadius: AppRadii.cardButton),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: Text(context.l10n.removeLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref.read(favouritesProvider.notifier).toggle(beach);
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.errorRemoveFavourite), backgroundColor: AppColors.coral),
          );
        }
      }
    }
  }

}

// Empty 

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88, height: 88,
              decoration: BoxDecoration(color: AppColors.coral.withValues(alpha: 0.09), shape: BoxShape.circle),
              child: const Icon(Icons.favorite_border, size: 40, color: AppColors.coral),
            ),
            const SizedBox(height: 22),
            Text(context.l10n.favouritesEmptyTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary)),
            const SizedBox(height: 8),
            Text(
              context.l10n.favouritesEmptyHint,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

//  Error 

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
          const SizedBox(height: 16),
          Text(context.l10n.errorLoadFavourites, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onRetry,
            child: Text(context.l10n.retryAgain, style: const TextStyle(color: AppColors.tealDark, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

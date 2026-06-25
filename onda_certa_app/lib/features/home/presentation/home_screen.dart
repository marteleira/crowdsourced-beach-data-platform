import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/notifications/notification_provider.dart';
import '../../../core/presence/heartbeat_provider.dart';
import '../../../features/beaches/data/beach_provider.dart';
import '../../../features/beaches/domain/beach_models.dart';
import '../../../core/constants/app_strings.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/beach_helpers.dart';
import '../../../shared/widgets/alert_item.dart';
import '../../../shared/widgets/animated_waves.dart';
import '../../../shared/widgets/beach_cover_image.dart';
import '../../../shared/widgets/tide_chart.dart';
import '../../beaches/presentation/beach_list_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../tides/presentation/tide_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(selectedTabProvider, (_, tab) {
      setState(() => _tab = tab);
    });

    ref.listen<bool>(locationPermissionDeniedProvider, (_, denied) {
      final messenger = ScaffoldMessenger.of(context);
      if (denied) {
        messenger.showMaterialBanner(
          MaterialBanner(
            backgroundColor: AppColors.primary,
            content: const Text(
              AppStrings.noLocationBanner,
              style: TextStyle(color: Colors.white),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  messenger.clearMaterialBanners();
                  Geolocator.openAppSettings();
                },
                child: const Text(AppStrings.settings, style: TextStyle(color: AppColors.teal)),
              ),
              TextButton(
                onPressed: messenger.clearMaterialBanners,
                child: const Text(AppStrings.close, style: TextStyle(color: Colors.white54)),
              ),
            ],
          ),
        );
      } else {
        messenger.clearMaterialBanners();
      }
    });

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _tab == 2 ? AppColors.primaryDark : AppColors.background,
        body: switch (_tab) {
          0 => _HomeDashboard(onTabChange: (i) => setState(() => _tab = i)),
          1 => const BeachListScreen(),
          2 => const TideScreen(),
          3 => const ProfileScreen(),
          _ => _PlaceholderTab(tab: _tab),
        },
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (i) => setState(() => _tab = i),
          backgroundColor: Colors.white,
          indicatorColor: AppColors.teal.withValues(alpha: 0.15),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: AppStrings.navHome),
            NavigationDestination(icon: Icon(Icons.location_on_outlined), selectedIcon: Icon(Icons.location_on), label: AppStrings.navBeaches),
            NavigationDestination(icon: Icon(Icons.waves_outlined), selectedIcon: Icon(Icons.waves), label: AppStrings.navTides),
            NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: AppStrings.navProfile),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({required this.tab});
  final int tab;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(AppStrings.comingSoon, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.textSecondary)),
    );
  }
}

class _HomeDashboard extends ConsumerWidget {
  const _HomeDashboard({required this.onTabChange});
  final void Function(int) onTabChange;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final beaches = ref.watch(beachListProvider);
    final bestBeach = ref.watch(bestBeachProvider);
    final weather = ref.watch(weatherProvider);
    final sea = ref.watch(seaProvider);
    final tides = ref.watch(tidesProvider);
    final reports = ref.watch(reportsProvider);
    final mapUsers = ref.watch(mapUsersProvider);
    final profile = ref.watch(userProfileProvider);

    final totalActiveUsers = mapUsers.value?.fold<int>(0, (s, b) => s + b.userCount) ?? 0;
    final totalAlerts = beaches.value?.fold<int>(0, (s, b) => s + b.activeAlertsCount) ?? 0;
    final lastUpdated = ref.watch(lastUpdatedProvider);

    // Set timestamp when data finishes loading
    ref.listen(beachListProvider, (_, next) {
      if (next.hasValue) ref.read(lastUpdatedProvider.notifier).setNow();
    });

    // Show loading only on initial load (value == null), not during refresh
    if (beaches.isLoading && beaches.value == null) {
      return const _HomeLoadingView();
    }

    Future<void> onRefresh() => refreshHomeData(ref);

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.teal,
      backgroundColor: Colors.white,
      child: CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: _Header(
            beaches: beaches.value ?? [],
            bestBeach: bestBeach.value,
            weather: weather.value,
            sea: sea.value,
            profile: profile.value,
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _SectionLabelWithTime(label: AppStrings.bestBeachNow, updatedAt: lastUpdated),
              const SizedBox(height: 10),
              _BestBeachCard(beach: bestBeach.value, sea: sea.value),
              const SizedBox(height: AppSpacing.md),
              _StatsRow(
                seaTemp: sea.value?.seaTemp,
                activeUsers: totalActiveUsers,
                alertsCount: totalAlerts,
              ),
              const SizedBox(height: AppSpacing.xxl),
              _AlertsSection(reports: reports.value ?? [], beach: bestBeach.value),
              const SizedBox(height: AppSpacing.xxl),
              _TidesSection(beach: bestBeach.value, tidesData: tides.value ?? TidesData.empty, onViewAll: () => onTabChange(2)),
              const SizedBox(height: AppSpacing.xxl),
              _ExploreGrid(beachCount: beaches.value?.length ?? 0, onTabChange: onTabChange, bestBeach: bestBeach.value),
              const SizedBox(height: AppSpacing.xxl),
              const _FavouritesSection(),
              const SizedBox(height: AppSpacing.xxl),
              _CommunitySection(
                totalReports: totalAlerts,
                beachCount: beaches.value?.length ?? 0,
                activeUsers: totalActiveUsers,
              ),
            ]),
          ),
        ),
      ],
    ),
    );
  }
}

class _SectionLabelWithTime extends StatelessWidget {
  const _SectionLabelWithTime({required this.label, required this.updatedAt});
  final String label;
  final DateTime? updatedAt;

  @override
  Widget build(BuildContext context) {
    final timeStr = updatedAt != null
        ? '${updatedAt!.hour.toString().padLeft(2, '0')}:${updatedAt!.minute.toString().padLeft(2, '0')}'
        : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
          const Spacer(),
          if (timeStr != null)
            Text(
              'Actualizado às $timeStr',
              style: AppTextStyles.hintXs,
            ),
        ],
      ),
    );
  }
}

class _HomeLoadingView extends StatelessWidget {
  const _HomeLoadingView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const AnimatedWaves(heightFraction: 0.4),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: AppColors.teal, strokeWidth: 2.5),
                const SizedBox(height: AppSpacing.xl),
                Text(AppStrings.loading, style: AppTextStyles.secondaryMd),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _sectionLabel(String text) => Padding(
  padding: const EdgeInsets.only(bottom: 4),
  child: Text(
    text.toUpperCase(),
    style: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: AppColors.textSecondary,
      letterSpacing: 0.8,
    ),
  ),
);

// Header

class _Header extends ConsumerWidget {
  const _Header({required this.beaches, this.bestBeach, required this.weather, required this.sea, required this.profile});
  final List<BeachSummary> beaches;
  final BeachSummary? bestBeach;
  final WeatherPoint? weather;
  final SeaPoint? sea;
  final UserProfile? profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasUnread = ref.watch(hasUnreadProvider);
    final now = DateTime.now();
    final hour = now.hour;
    final greeting = hour < 5 ? AppStrings.greetingEvening : hour < 12 ? AppStrings.greetingMorning : hour < 18 ? AppStrings.greetingAfternoon : AppStrings.greetingEvening;
    final precip = weather?.precipitationProb ?? 0;
    final wind = weather?.windSpeed ?? 0;
    final minTemp = weather?.minTemp ?? 0;

    final String emoji;
    if(precip >= 40 && minTemp < 0) {
      emoji = '🌨️';
    }else if (precip >= 70 && wind >= 40) {
      emoji = '⛈️';
    } else if (precip >= 70) {
      emoji = '🌧️';
    } else if (precip >= 40) {
      emoji = '🌦️';
    } else if (hour < 5) {
      emoji = '🌙';
    } else if (hour < 7) {
      emoji = '🌅';
    } else if (hour < 19) {
      emoji = '☀️';
    } else if (hour < 21) {
      emoji = '🌇';
    } else {
      emoji = '🌙';
    }
    final name = profile?.displayName ?? 'explorador';
    const dayNames = AppStrings.dayNames;
    const monthNames = AppStrings.monthNames;
    final dateStr = '${dayNames[now.weekday - 1]}, ${now.day} ${monthNames[now.month - 1]}';

    final safe = beaches.where((b) => b.flagColor == 'green').length;
    final caution = beaches.where((b) => b.flagColor == 'yellow').length;
    final danger = beaches.where((b) => b.flagColor == 'red' || b.flagColor == 'purple').length;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(AppRadii.xxl),
          bottomRight: Radius.circular(AppRadii.xxl),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row
              Row(
                children: [
                  Image.asset("assets/icon/icon.png", width: 24,),
                  const SizedBox(width: AppSpacing.sm),
                  const Text(AppStrings.appName, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
                  const Spacer(),
                  Stack(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 18),
                          onPressed: () => context.push(AppRoutes.notifications),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                      if (hasUnread) Positioned(top: 2, right: 2, child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.coral, shape: BoxShape.circle))),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                bestBeach != null ? '$dateStr · ${bestBeach!.name}' : dateStr,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                '$emoji $greeting,\n$name.',
                style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700, height: 1.2),
              ),
              const SizedBox(height: AppSpacing.lg),
              // Weather strip
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _WeatherCell(icon: Icons.thermostat_outlined, value: weather?.currentTemp != null ? '${weather!.currentTemp!.round()}°C' : weather?.maxTemp != null ? '${weather!.minTemp!.round()}°-${weather!.maxTemp!.round()}°' : '--', label: AppStrings.weatherAir),
                  _WeatherCell(icon: Icons.air, value: weather?.windSpeed != null ? '${weather!.windSpeed!.round()}km/h' : '--', label: weather?.windDir ?? AppStrings.weatherWind),
                  _WeatherCell(icon: Icons.waves, value: sea?.waveHeightMax != null ? '${sea!.waveHeightMax!.toStringAsFixed(1)}m' : '--', label: AppStrings.weatherWaves),
                  _WeatherCell(icon: Icons.umbrella_outlined, value: weather?.precipitationProb != null ? '${weather!.precipitationProb!.round()}%' : '--', label: AppStrings.weatherRain),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              // Live + badge pills
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: AppRadii.cardXl,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.teal, shape: BoxShape.circle)),
                        const SizedBox(width: AppSpacing.xs),
                        const Text(AppStrings.liveLabel, style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  if (safe > 0) _StatusPill('$safe ${AppStrings.flagStatusSafe}', AppColors.flagGreen),
                  if (safe > 0) const SizedBox(width: 6),
                  if (caution > 0) _StatusPill('$caution ${AppStrings.flagStatusCaution}', AppColors.flagYellow),
                  if (caution > 0) const SizedBox(width: 6),
                  if (danger > 0) _StatusPill('$danger ${AppStrings.flagStatusDanger}', AppColors.flagRed),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeatherCell extends StatelessWidget {
  const _WeatherCell({required this.icon, required this.value, required this.label});
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(height: AppSpacing.xs),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill(this.label, this.color);
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: AppRadii.cardXl,
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: AppSpacing.xs),
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// Best beach card

class _BestBeachCard extends StatelessWidget {
  const _BestBeachCard({required this.beach, required this.sea});
  final BeachSummary? beach;
  final SeaPoint? sea;

  @override
  Widget build(BuildContext context) {
    if (beach == null) {
      return _cardShell(
        child: Container(height: 180, decoration: BoxDecoration(
          gradient: LinearGradient(colors: [AppColors.teal.withValues(alpha: 0.3), AppColors.primary.withValues(alpha: 0.3)]),
          borderRadius: AppRadii.cardLg,
        )),
      );
    }

    final flagColor = AppColors.forFlag(beach!.flagColor);
    final qualityLabel = beachQualityLabel(beach!.flagColor, beach!.recommendationScore);
    final qualityColor = beach!.recommendationScore != null && beach!.recommendationScore! > 0.7
        ? AppColors.teal : AppColors.sand;

    return GestureDetector(
      onTap: () => context.push(AppRoutes.beach(beach!.slug), extra: beach),
      child: Container(
      decoration: BoxDecoration(
        borderRadius: AppRadii.cardLg,
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          // Cover photo / gradient
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Stack(
              children: [
                BeachCoverImage(
                  flagColor: beach!.flagColor,
                  photoUrl: beach!.coverPhotoUrl,
                  height: 170,
                ),
                // Scrim
                Positioned(
                  left: 0, right: 0, bottom: 0,
                  child: Container(
                    height: 90,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.65)],
                      ),
                    ),
                  ),
                ),
                // Arrow
                Positioned(
                  top: 12, right: 12,
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: AppRadii.cardSm),
                    child: const Icon(Icons.arrow_outward, color: Colors.white, size: 16),
                  ),
                ),
                // Bottom content
                Positioned(
                  left: 14, bottom: 14, right: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: AppColors.sand, borderRadius: AppRadii.cardXl),
                        child: const Text('Recomendada', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(height: 6),
                      Text(beach!.name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700, shadows: [Shadow(blurRadius: 4, color: Colors.black38)])),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Info row
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                _InfoPill(
                  color: flagColor,
                  label: flagLabel(beach!.flagColor),
                  dot: true,
                ),
                const SizedBox(width: AppSpacing.sm),
                if (sea?.waveHeightMax != null)
                  _InfoPill(icon: Icons.waves, label: '${sea!.waveHeightMax!.toStringAsFixed(1)}m'),
                if (sea?.waveHeightMax != null) const SizedBox(width: AppSpacing.sm),
                if (sea?.seaTemp != null)
                  _InfoPill(icon: Icons.thermostat_outlined, label: '${sea!.seaTemp!.round()}°C'),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: qualityColor.withValues(alpha: 0.15),
                    borderRadius: AppRadii.cardXl,
                    border: Border.all(color: qualityColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(qualityLabel, style: TextStyle(color: qualityColor == AppColors.teal ? AppColors.tealDark : AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
  }

  Widget _cardShell({required Widget child}) => Container(
    decoration: BoxDecoration(borderRadius: AppRadii.cardLg, border: Border.all(color: Colors.black.withValues(alpha: 0.06))),
    child: ClipRRect(borderRadius: AppRadii.cardLg, child: child),
  );

}

class _InfoPill extends StatelessWidget {
  const _InfoPill({this.icon, this.color, required this.label, this.dot = false});
  final IconData? icon;
  final Color? color;
  final String label;
  final bool dot;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (dot && color != null)
          Container(width: 8, height: 8, margin: const EdgeInsets.only(right: 4), decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        if (icon != null)
          Icon(icon, size: 14, color: AppColors.textSecondary),
        if (icon != null) const SizedBox(width: 3),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

// Stats row

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.seaTemp, required this.activeUsers, required this.alertsCount});
  final double? seaTemp;
  final int activeUsers;
  final int alertsCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatCard(icon: Icons.thermostat_outlined, value: seaTemp != null ? '${seaTemp!.round()}°C' : '--', label: 'Temp. mar', iconColor: AppColors.teal)),
        const SizedBox(width: 10),
        Expanded(child: _StatCard(icon: Icons.people_outline, value: '$activeUsers', label: 'Activos agora', iconColor: AppColors.primary)),
        const SizedBox(width: 10),
        Expanded(child: _StatCard(icon: Icons.warning_amber_outlined, value: '$alertsCount', label: 'Alertas', iconColor: alertsCount > 0 ? AppColors.coral : AppColors.textSecondary)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.icon, required this.value, required this.label, required this.iconColor});
  final IconData icon;
  final String value;
  final String label;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadii.cardMd,
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 6),
          Text(value, style: AppTextStyles.titleLg),
          Text(label, style: AppTextStyles.secondaryXs, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// Favourites section

class _FavouritesSection extends ConsumerWidget {
  const _FavouritesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favAsync = ref.watch(favouritesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.favorite_border, color: AppColors.coral, size: 16),
            const SizedBox(width: 6),
            const Text(
              AppStrings.sectionFavourites,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.8),
            ),
            const SizedBox(width: 6),
            favAsync.maybeWhen(
              data: (beaches) => beaches.isNotEmpty
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(color: AppColors.coral, borderRadius: AppRadii.cardChip),
                      child: Text('${beaches.length}', style: AppTextStyles.whiteLabel),
                    )
                  : const SizedBox.shrink(),
              orElse: () => const SizedBox.shrink(),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => context.push(AppRoutes.favourites),
              child: const Text(AppStrings.viewBeaches, style: AppTextStyles.tealLabel),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 118,
          child: favAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.teal, strokeWidth: 2)),
            error: (_, _) => const SizedBox.shrink(),
            data: (beaches) => beaches.isEmpty
                ? const _FavouritesNudgeCard()
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.zero,
                    itemCount: beaches.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (context, i) {
                      if (i == beaches.length) return const _FavouritesViewAllCard();
                      return _FavouriteBeachCard(beach: beaches[i]);
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

class _FavouriteBeachCard extends StatelessWidget {
  const _FavouriteBeachCard({required this.beach});
  final BeachSummary beach;

  @override
  Widget build(BuildContext context) {
    final flagColor = AppColors.forFlag(beach.flagColor);

    return GestureDetector(
      onTap: () => context.push(AppRoutes.beach(beach.slug), extra: beach),
      child: ClipRRect(
        borderRadius: AppRadii.cardButton,
        child: SizedBox(
          width: 148,
          child: BeachCoverImage(
            flagColor: beach.flagColor,
            photoUrl: beach.coverPhotoUrl,
            height: 118,
            dimOpacity: beach.coverPhotoUrl != null ? 0.40 : 0.0,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: AppRadii.cardSm,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(width: 5, height: 5, decoration: BoxDecoration(color: flagColor, shape: BoxShape.circle)),
                            const SizedBox(width: 4),
                            Text(flagLabel(beach.flagColor), style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      const Spacer(),
                      if (beach.activeAlertsCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.coral, borderRadius: BorderRadius.circular(7)),
                          child: Text('${beach.activeAlertsCount}⚠', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                        ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    beach.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                      shadows: [Shadow(blurRadius: 4, color: Colors.black38)],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

}

class _FavouritesViewAllCard extends StatelessWidget {
  const _FavouritesViewAllCard();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.favourites),
      child: Container(
        width: 76,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppRadii.cardButton,
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: AppColors.teal.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: const Icon(Icons.arrow_forward, color: AppColors.teal, size: 17),
            ),
            const SizedBox(height: 7),
            const Text('Ver\ntodas', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.tealDark, height: 1.3)),
          ],
        ),
      ),
    );
  }
}

class _FavouritesNudgeCard extends StatelessWidget {
  const _FavouritesNudgeCard();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.favourites),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppRadii.cardButton,
          border: Border.all(color: AppColors.coral.withValues(alpha: 0.22), width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, color: AppColors.coral.withValues(alpha: 0.45), size: 30),
            const SizedBox(width: 14),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(AppStrings.noFavourites, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary)),
                const SizedBox(height: 3),
                const Text(
                  AppStrings.noFavouritesHint,
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.4),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Alerts section

class _AlertsSection extends StatelessWidget {
  const _AlertsSection({required this.reports, this.beach});
  final List<BeachReport> reports;
  final BeachSummary? beach;

  @override
  Widget build(BuildContext context) {
    final visible = reports.take(3).toList();
    return Column(
      children: [
        Row(
          children: [
            const Icon(Icons.warning_amber_outlined, color: AppColors.coral, size: 18),
            const SizedBox(width: 6),
            const Text(AppStrings.sectionAlerts, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.8)),
            const SizedBox(width: 6),
            if (reports.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(color: AppColors.coral, borderRadius: AppRadii.cardChip),
                child: Text('${reports.length}', style: AppTextStyles.whiteLabel),
              ),
            const Spacer(),
            if (beach != null)
              GestureDetector(
                onTap: () => context.push(AppRoutes.beachAlerts(beach!.slug), extra: beach),
                child: const Text(AppStrings.viewAll, style: AppTextStyles.tealLabel),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (visible.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: AppRadii.cardMd, border: Border.all(color: Colors.black.withValues(alpha: 0.06))),
            child: const Center(child: Text(AppStrings.noAlerts, style: AppTextStyles.secondaryMd)),
          )
        else
          ...visible.map((r) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AlertItem(report: r),
          )),
      ],
    );
  }
}

// Tides section

class _TidesSection extends StatelessWidget {
  const _TidesSection({required this.beach, required this.tidesData, required this.onViewAll});
  final BeachSummary? beach;
  final TidesData tidesData;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    if (beach == null) return const SizedBox.shrink();

    final tides = tidesData.entries;
    final beachShort = beach!.name.split(' ').last;

    // Determine direction label and next extremum from the API direction field
    final apiDirection = tidesData.direction ?? 'steady';
    final directionLabel = apiDirection == 'rising' ? 'Subindo' : apiDirection == 'falling' ? 'Descendo' : 'Estável';
    final isRising = apiDirection == 'rising';

    final nextTide = findNextTide(tides);

    // Current height: prefer live observation, fall back to next extremum height
    final currentH = tidesData.currentHeight;
    final displayHeight = currentH != null
        ? '${currentH.toStringAsFixed(2)}m'
        : (nextTide != null ? '${nextTide.height.toStringAsFixed(1)}m' : '--');

    // Tide is considered "high" when above mean sea level (~1.95m)
    const msl = 1.95;
    final isHighTide = (currentH ?? 0) > msl;
    final accentColor = isHighTide ? AppColors.teal : const Color(0xFFE8C98A);

    return Column(
      children: [
        Row(
          children: [
            const Icon(Icons.waves, color: AppColors.teal, size: 16),
            const SizedBox(width: 6),
            Text(AppStrings.tidesSection(beachShort), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.8)),
            const Spacer(),
            GestureDetector(
              onTap: onViewAll,
              child: const Text(AppStrings.viewDetails, style: AppTextStyles.tealLabel),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppRadii.cardLg,
            border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info row: height/direction on left, chart on right (wider than before)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Left: current height + direction + next tide
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(isRising ? Icons.arrow_upward : Icons.arrow_downward,
                              color: accentColor, size: 14),
                          const SizedBox(width: 3),
                          Text(directionLabel,
                              style: TextStyle(color: accentColor, fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(displayHeight,
                          style: AppTextStyles.titleXl),
                      if (nextTide != null)
                        Text(
                          '${tideTypeLabel(nextTide.type, capitalize: true)} às ${nextTide.time}',
                          style: AppTextStyles.secondary,
                        ),
                    ],
                  ),
                  const SizedBox(width: AppSpacing.md),
                  // Right: chart — Expanded so it fills remaining width
                  Expanded(
                    child: SizedBox(
                      height: 70,
                      child: CustomPaint(
                        painter: TideChartPainter(
                          tides: tides,
                          currentHeight: currentH,
                          accentColor: accentColor,
                        ),
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
        ),
      ],
    );
  }
}

// Explore grid

class _ExploreGrid extends StatelessWidget {
  const _ExploreGrid({required this.beachCount, required this.onTabChange, this.bestBeach});
  final int beachCount;
  final void Function(int tab) onTabChange;
  final BeachSummary? bestBeach;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(AppStrings.exploreTitle),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.3,
          children: [
            _ExploreCard(emoji: '🗺️', title: AppStrings.exploreMap, subtitle: AppStrings.exploreMapSub, onTap: () => onTabChange(1)),
            _ExploreCard(emoji: '🚌', title: AppStrings.exploreTransport, subtitle: AppStrings.exploreTransportSub, onTap: () => onTabChange(1)),
            _ExploreCard(emoji: '🌊', title: AppStrings.exploreBeaches, subtitle: '$beachCount praias da Arrábida', onTap: () => onTabChange(1)),
            _ExploreCard(
              emoji: '📋',
              title: AppStrings.exploreReport,
              subtitle: AppStrings.exploreReportSub,
              onTap: bestBeach != null
                  ? () => context.push(AppRoutes.beachAlerts(bestBeach!.slug), extra: bestBeach)
                  : () => onTabChange(1),
            ),
          ],
        ),
      ],
    );
  }
}

class _ExploreCard extends StatelessWidget {
  const _ExploreCard({required this.emoji, required this.title, required this.subtitle, required this.onTap});
  final String emoji;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppRadii.cardLg,
          border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const Spacer(),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.primary)),
            const SizedBox(height: 2),
            Text(subtitle, style: AppTextStyles.secondarySm),
          ],
        ),
      ),
    );
  }
}

// Community section 

class _CommunitySection extends StatelessWidget {
  const _CommunitySection({required this.totalReports, required this.beachCount, required this.activeUsers});
  final int totalReports;
  final int beachCount;
  final int activeUsers;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(AppStrings.communityTitle),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppRadii.cardLg,
            border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: AppColors.teal.withValues(alpha: 0.12), borderRadius: AppRadii.cardMd),
                    child: const Icon(Icons.waves, color: AppColors.teal, size: 20),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppStrings.communityReports(totalReports), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.primary)),
                      Text(AppStrings.communityFooter(beachCount, activeUsers), style: AppTextStyles.secondary),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
                    shape: RoundedRectangleBorder(borderRadius: AppRadii.cardMd),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(AppStrings.seeAllBeaches, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

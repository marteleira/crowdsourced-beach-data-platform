import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/auth/auth_provider.dart';
import '../domain/beach_models.dart';
import 'beach_repository.dart';

final beachRepositoryProvider = Provider<BeachRepository>((ref) {
  return BeachRepository(ref.read(dioProvider));
});

//Allow any to change to current homescreen tab
final selectedTabProvider = NotifierProvider<_SelectedTabNotifier, int>(_SelectedTabNotifier.new);

class _SelectedTabNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void set(int tab) => state = tab;
}

// Timestamp of the last successful data refresh
final lastUpdatedProvider =
    NotifierProvider<_LastUpdatedNotifier, DateTime?>(_LastUpdatedNotifier.new);

class _LastUpdatedNotifier extends Notifier<DateTime?> {
  @override
  DateTime? build() => null;
  void setNow() => state = DateTime.now();
}

// GPS location — always tries a fresh fix; falls back to last known on timeout.
final locationProvider = FutureProvider<Position?>((ref) async {
  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    return null;
  }

  try {
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.low,
        timeLimit: Duration(seconds: 10),
      ),
    );
  } catch (_) {
    // GPS unavailable or timed out — use cached position as fallback
    return Geolocator.getLastKnownPosition();
  }
});

// Beach list (sorted by proximity when GPS available)

final beachListProvider = FutureProvider<List<BeachSummary>>((ref) async {
  final pos = await ref.watch(locationProvider.future);
  return ref.read(beachRepositoryProvider).getBeaches(
    lat: pos?.latitude,
    lon: pos?.longitude,
  );
});

// Best beach = highest recommendation_score (already sorted by backend with GPS)
final bestBeachProvider = FutureProvider<BeachSummary?>((ref) async {
  final beaches = await ref.watch(beachListProvider.future);
  if (beaches.isEmpty) return null;
  return beaches.reduce(
    (a, b) => (b.recommendationScore ?? 0) > (a.recommendationScore ?? 0) ? b : a,
  );
});

// Best beach data

final weatherProvider = FutureProvider<WeatherPoint?>((ref) async {
  final best = await ref.watch(bestBeachProvider.future);
  if (best == null) return null;
  return ref.read(beachRepositoryProvider).getBeachWeather(best.slug);
});

final seaProvider = FutureProvider<SeaPoint?>((ref) async {
  final best = await ref.watch(bestBeachProvider.future);
  if (best == null) return null;
  return ref.read(beachRepositoryProvider).getBeachSea(best.slug);
});

final tidesProvider = FutureProvider<TidesData>((ref) async {
  final best = await ref.watch(bestBeachProvider.future);
  if (best == null) return TidesData.empty;
  return ref.read(beachRepositoryProvider).getBeachTides(best.slug);
});

final reportsProvider = FutureProvider<List<BeachReport>>((ref) async {
  final best = await ref.watch(bestBeachProvider.future);
  if (best == null) return [];
  final reports = await ref.read(beachRepositoryProvider).getBeachReports(best.slug);
  return reports
      .map((r) => BeachReport(
            id: r.id, type: r.type, severity: r.severity, note: r.note,
            upvotes: r.upvotes, downvotes: r.downvotes, createdAt: r.createdAt,
            isExpired: r.isExpired, verified: r.verified,
            beachName: best.name, beachSlug: best.slug,
          ))
      .toList();
});

final mapUsersProvider = FutureProvider<List<MapBeachPresence>>((ref) async {
  return ref.read(beachRepositoryProvider).getMapUsers();
});

final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final auth = ref.watch(authProvider);
  if (auth.value is! AuthAuthenticated) return null;
  return ref.read(beachRepositoryProvider).getUserProfile();
});

Future<void> refreshHomeData(WidgetRef ref) {
  ref.invalidate(locationProvider);
  ref.invalidate(beachListProvider);
  ref.invalidate(weatherProvider);
  ref.invalidate(seaProvider);
  ref.invalidate(tidesProvider);
  ref.invalidate(reportsProvider);
  ref.invalidate(mapUsersProvider);
  return ref.read(beachListProvider.future);
}

// Single combined call for BeachDetailScreen

final beachFullDetailProvider = FutureProvider.family<BeachFullDetail?, String>((ref, slug) async {
  return ref.read(beachRepositoryProvider).getBeachFullDetail(slug);
});

// Per-section family providers (keyed by slug)

final beachWeatherBySlugProvider = FutureProvider.family<WeatherPoint?, String>((ref, slug) async {
  return ref.read(beachRepositoryProvider).getBeachWeather(slug);
});

final beachSeaBySlugProvider = FutureProvider.family<SeaPoint?, String>((ref, slug) async {
  return ref.read(beachRepositoryProvider).getBeachSea(slug);
});

final beachTidesBySlugProvider = FutureProvider.family<TidesData, String>((ref, slug) async {
  return ref.read(beachRepositoryProvider).getBeachTides(slug);
});

final beachReportsBySlugProvider = FutureProvider.family<List<BeachReport>, String>((ref, slug) async {
  return ref.read(beachRepositoryProvider).getBeachReports(slug);
});

final beachWaterQualityProvider = FutureProvider.family<WaterQuality?, String>((ref, slug) async {
  return ref.read(beachRepositoryProvider).getBeachWaterQuality(slug);
});

final beachTransportProvider = FutureProvider.family<BeachTransportInfo, String>((ref, slug) async {
  return ref.read(beachRepositoryProvider).getBeachTransport(slug);
});

/// Mutable reports list for CommunityAlertsScreen — supports optimistic vote + submit.
final communityReportsProvider =
    AsyncNotifierProvider.family<CommunityReportsNotifier, List<BeachReport>, String>(
  (slug) => CommunityReportsNotifier(slug),
);

class CommunityReportsNotifier extends AsyncNotifier<List<BeachReport>> {
  CommunityReportsNotifier(this._slug);
  final String _slug;

  @override
  Future<List<BeachReport>> build() async {
    return ref.read(beachRepositoryProvider).getBeachReports(_slug);
  }

  Future<void> vote(int reportId, String vote) async {
    final before = List<BeachReport>.from(state.value ?? []);
    final voteVal = vote == 'up' ? 1 : -1;

    // Optimistic update
    state = AsyncData(before.map((r) {
      if (r.id != reportId) return r;
      final isToggle = r.myVote == voteVal;
      final wasOpposite = r.myVote != null && r.myVote != voteVal;
      return r.withVote(
        myVote: isToggle ? null : voteVal,
        upvotes: r.upvotes +
            (vote == 'up'
                ? (isToggle ? -1 : 1)
                : (wasOpposite ? -1 : 0)),
        downvotes: r.downvotes +
            (vote == 'down'
                ? (isToggle ? -1 : 1)
                : (wasOpposite ? -1 : 0)),
      );
    }).toList());

    try {
      final result = await ref.read(beachRepositoryProvider).voteReport(_slug, reportId, vote);
      state = AsyncData((state.value ?? []).map((r) {
        if (r.id != reportId) return r;
        final voteVal2 = vote == 'up' ? 1 : -1;
        final myVote = r.myVote == voteVal2 ? voteVal2 : null;
        return r.withVote(
          myVote: myVote,
          upvotes: result['upvotes']!,
          downvotes: result['downvotes']!,
        );
      }).toList());
    } catch (_) {
      state = AsyncData(before);
      rethrow;
    }
  }

  Future<BeachReport> submitReport({
    required String type,
    required int severity,
    String? note,
    double? lat,
    double? lon,
  }) async {
    final report = await ref.read(beachRepositoryProvider).createReport(
      _slug,
      type: type,
      severity: severity,
      note: note,
      lat: lat,
      lon: lon,
    );
    state = AsyncData([report, ...(state.value ?? [])]);
    return report;
  }
}

/// Favourites — supports optimistic toggle.
final favouritesProvider =
    AsyncNotifierProvider<FavouritesNotifier, List<BeachSummary>>(FavouritesNotifier.new);

class FavouritesNotifier extends AsyncNotifier<List<BeachSummary>> {
  @override
  Future<List<BeachSummary>> build() async {
    final auth = ref.watch(authProvider);
    if (auth.value is! AuthAuthenticated) return [];
    return ref.read(beachRepositoryProvider).getFavourites();
  }

  bool isFavourite(String slug) =>
      state.value?.any((b) => b.slug == slug) ?? false;

  Future<void> toggle(BeachSummary beach) async {
    final current = List<BeachSummary>.from(state.value ?? []);
    final alreadyFav = current.any((b) => b.slug == beach.slug);

    // Optimistic update
    state = AsyncData(alreadyFav
        ? current.where((b) => b.slug != beach.slug).toList()
        : [...current, beach]);

    try {
      if (alreadyFav) {
        await ref.read(beachRepositoryProvider).removeFavourite(beach.slug);
      } else {
        await ref.read(beachRepositoryProvider).addFavourite(beach.slug);
      }
    } catch (_) {
      state = AsyncData(current); // rollback
      rethrow;
    }
  }
}

/// Filters the already-loaded map presence data for a single beach.
final beachPresenceProvider = FutureProvider.family<MapBeachPresence?, String>((ref, slug) async {
  final users = await ref.watch(mapUsersProvider.future);
  try {
    return users.firstWhere((u) => u.beachSlug == slug);
  } catch (_) {
    return null;
  }
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/auth/auth_provider.dart';
import '../domain/beach_models.dart';
import 'beach_repository.dart';

final beachRepositoryProvider = Provider<BeachRepository>((ref) {
  return BeachRepository(ref.read(dioProvider));
});

// Timestamp of the last successful data refresh
final lastUpdatedProvider =
    NotifierProvider<_LastUpdatedNotifier, DateTime?>(_LastUpdatedNotifier.new);

class _LastUpdatedNotifier extends Notifier<DateTime?> {
  @override
  DateTime? build() => null;
  void setNow() => state = DateTime.now();
}

// GPS location:
// 1. lastKnownPosition — instant, available after first real use
// 2. getCurrentPosition — only if no cached position (first ever launch)
final locationProvider = FutureProvider<Position?>((ref) async {
  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    return null;
  }

  // Fast path: cached position is accurate enough for beach ranking
  final lastKnown = await Geolocator.getLastKnownPosition();
  if (lastKnown != null) return lastKnown;

  // Slow path: first ever launch — wait for a fresh fix
  try {
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.low,
        timeLimit: Duration(seconds: 10),
      ),
    );
  } catch (_) {
    return null;
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

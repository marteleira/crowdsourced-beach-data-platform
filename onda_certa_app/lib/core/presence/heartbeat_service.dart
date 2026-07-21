import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../features/beaches/data/beach_provider.dart';
import 'heartbeat_provider.dart';

const _kInterval = Duration(minutes: 19);

// gets the device current position, falling back to the last known one if
// a fresh fix cant be obtained quickly
Future<Position?> getCurrentOrLastPosition() async {
  try {
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.low, timeLimit: Duration(seconds: 5)),
    );
  } catch (_) {
    return await Geolocator.getLastKnownPosition();
  }
}

// Sends a heartbeat for the device's current position. The backend decides
// which beach (if any) it belongs to via a PostGIS spatial query.
// Returns the matched beach's slug, or null if no position or no beach nearby.
Future<String?> sendHeartbeatForCurrentPosition(WidgetRef ref) async {
  final pos = await getCurrentOrLastPosition();
  if (pos == null) return null;

  return ref.read(beachRepositoryProvider).sendHeartbeatByLocation(
    lat: pos.latitude, lon: pos.longitude,
  );
}

class HeartbeatService {
  Timer? _initialTimer;
  Timer? _timer;

  void start(Ref ref) {
    if (_timer != null) return;
    _initialTimer = Timer(const Duration(seconds: 5), () => _tick(ref));
    _timer = Timer.periodic(_kInterval, (_) => _tick(ref));
  }

  void stop() {
    _initialTimer?.cancel();
    _initialTimer = null;
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _tick(Ref ref) async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      ref.read(locationPermissionDeniedProvider.notifier).setDenied(true);
      return;
    }
    ref.read(locationPermissionDeniedProvider.notifier).setDenied(false);

    Position? pos;
    try {
      pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      pos = await Geolocator.getLastKnownPosition();
      if (pos == null) {
        return;
      }
    }

    try {
      await ref.read(beachRepositoryProvider).sendHeartbeatByLocation(
        lat: pos.latitude,
        lon: pos.longitude,
      );
    } catch (_) {}
  }
}

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../features/beaches/data/beach_provider.dart';
import '../../features/beaches/domain/beach_models.dart';
import 'heartbeat_provider.dart';

const _kRadius = 2000.0; // 2km (at this distance the user is on the beach)
const _kInterval = Duration(minutes: 19);

class HeartbeatService {
  Timer? _timer;

  void start(Ref ref) {
    if (_timer != null) {
      return;
    }
    _tick(ref);
    _timer = Timer.periodic(_kInterval, (_) => _tick(ref));
  }

  void stop() {
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

    List<BeachSummary> beaches;
    try {
      beaches = await ref.read(beachListProvider.future).timeout(
        const Duration(seconds: 15),
        onTimeout: () => [],
      );
    } catch (e) {
      return;
    }

    if (beaches.isEmpty) {
      return;
    }

    final nearest = _nearest(beaches, pos);
    if (nearest == null) {
      return;
    }

    try {
      await ref.read(beachRepositoryProvider).sendHeartbeat(
        nearest.slug,
        lat: pos.latitude,
        lon: pos.longitude,
      );
    } catch (_) {}
  }

  BeachSummary? _nearest(List<BeachSummary> beaches, Position pos) {
    BeachSummary? result;
    double minDist = double.infinity;
    for (final b in beaches) {
      final d = Geolocator.distanceBetween(
        pos.latitude, pos.longitude, b.lat, b.lon,
      );
      if (d < minDist) {
        minDist = d;
        result = b;
      }
    }
    return minDist <= _kRadius ? result : null;
  }
}

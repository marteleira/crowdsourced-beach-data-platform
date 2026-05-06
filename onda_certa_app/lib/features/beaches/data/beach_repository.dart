import 'package:dio/dio.dart';
import '../domain/beach_models.dart';

class BeachRepository {
  const BeachRepository(this._dio);
  final Dio _dio;

  Future<List<BeachSummary>> getBeaches({double? lat, double? lon}) async {
    final params = <String, dynamic>{};
    if (lat != null) params['lat'] = lat;
    if (lon != null) params['lon'] = lon;
    final res = await _dio.get('/beaches', queryParameters: params.isEmpty ? null : params);
    final list = res.data as List;
    return list.map((e) => BeachSummary.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<WeatherPoint?> getBeachWeather(String slug) async {
    try {
      final res = await _dio.get('/beaches/$slug/weather');
      final list = res.data as List;
      if (list.isEmpty) return null;
      return WeatherPoint.fromJson(list.first as Map<String, dynamic>);
    } catch (_) { return null; }
  }

  Future<SeaPoint?> getBeachSea(String slug) async {
    try {
      final res = await _dio.get('/beaches/$slug/sea');
      final list = res.data as List;
      if (list.isEmpty) return null;
      return SeaPoint.fromJson(list.first as Map<String, dynamic>);
    } catch (_) { return null; }
  }

  Future<TidesData> getBeachTides(String slug) async {
    try {
      final res = await _dio.get('/beaches/$slug/tides');
      return TidesData.fromJson(res.data as Map<String, dynamic>);
    } catch (_) { return TidesData.empty; }
  }

  Future<List<BeachReport>> getBeachReports(String slug) async {
    try {
      final res = await _dio.get('/beaches/$slug/reports');
      final data = res.data as Map<String, dynamic>;
      final list = data['reports'] as List? ?? [];
      return list.map((e) => BeachReport.fromJson(e as Map<String, dynamic>, beachSlug: slug)).toList();
    } catch (_) { return []; }
  }

  Future<List<MapBeachPresence>> getMapUsers() async {
    try {
      final res = await _dio.get('/map/users');
      final list = res.data as List;
      return list.map((e) => MapBeachPresence.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) { return []; }
  }

  Future<void> sendHeartbeat(String slug, {required double lat, required double lon}) async {
    await _dio.post(
      '/beaches/$slug/occupancy/heartbeat',
      data: {'lat': lat, 'lon': lon},
    );
  }

  Future<UserProfile?> getUserProfile() async {
    try {
      final res = await _dio.get('/users/me');
      return UserProfile.fromJson(res.data as Map<String, dynamic>);
    } catch (_) { return null; }
  }
}

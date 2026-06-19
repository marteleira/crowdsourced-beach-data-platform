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

  Future<BeachFullDetail?> getBeachFullDetail(String slug) async {
    try {
      final res = await _dio.get('/beaches/$slug');
      return BeachFullDetail.fromJson(res.data as Map<String, dynamic>);
    } catch (_) { return null; }
  }

  Future<WaterQuality?> getBeachWaterQuality(String slug) async {
    try {
      final res = await _dio.get('/beaches/$slug/water-quality');
      return WaterQuality.fromJson(res.data as Map<String, dynamic>);
    } catch (_) { return null; }
  }

  Future<BeachTransportInfo> getBeachTransport(String slug) async {
    try {
      final res = await _dio.get('/beaches/$slug/transport');
      return BeachTransportInfo.fromJson(res.data as Map<String, dynamic>);
    } catch (_) { return BeachTransportInfo.empty; }
  }

  Future<Map<String, int>> voteReport(String slug, int reportId, String vote) async {
    final res = await _dio.post(
      '/beaches/$slug/reports/$reportId/vote',
      data: {'vote': vote},
    );
    final data = res.data as Map<String, dynamic>;
    return {
      'upvotes': data['upvotes'] as int,
      'downvotes': data['downvotes'] as int,
    };
  }

  Future<BeachReport> createReport(
    String slug, {
    required String type,
    required int severity,
    String? note,
    double? lat,
    double? lon,
  }) async {
    final body = <String, dynamic>{
      'type': type,
      'severity': severity,
      if (note != null && note.isNotEmpty) 'note': note,
      'lat': ?lat,
      'lon': ?lon,
    };
    final res = await _dio.post('/beaches/$slug/reports', data: body);
    return BeachReport.fromJson(res.data as Map<String, dynamic>, beachSlug: slug);
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

  Future<UserProfile> updateProfile({
    String? displayName,
    String? email,
    String? currentPassword,
    String? avatarId,
  }) async {
    final body = <String, dynamic>{
      'display_name': ?displayName,
      'email': ?email,
      'current_password': ?currentPassword,
      'avatar_id': ?avatarId,
    };
    final res = await _dio.patch('/users/me', data: body);
    return UserProfile.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _dio.post('/users/me/change-password', data: {
      'current_password': currentPassword,
      'new_password': newPassword,
    });
  }

  Future<List<BeachSummary>> getFavourites() async {
    try {
      final res = await _dio.get('/users/me/favourites');
      final list = res.data as List;
      return list.map((e) => BeachSummary.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) { return []; }
  }

  Future<void> addFavourite(String slug) async {
    await _dio.post('/users/me/favourites/$slug');
  }

  Future<void> removeFavourite(String slug) async {
    await _dio.delete('/users/me/favourites/$slug');
  }

  Future<double> confirmFlag(String slug, String response) async {
    final res = await _dio.post(
      '/beaches/$slug/flag/confirm',
      data: {'response': response},
    );
    return (res.data['new_confidence'] as num).toDouble();
  }

  Future<({String status, String message})> proposeFlag(String slug, String color) async {
    final res = await _dio.post(
      '/beaches/$slug/flag/propose',
      data: {'color': color},
    );
    final data = res.data as Map<String, dynamic>;
    return (
      status: data['status'] as String,
      message: data['message'] as String,
    );
  }
}

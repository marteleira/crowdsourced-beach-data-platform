class BeachSummary {
  const BeachSummary({
    required this.id, required this.slug, required this.name,
    required this.lat, required this.lon, required this.flagColor,
    this.flagConfidence, required this.occupancyLevel,
    required this.activeAlertsCount, required this.activityLevel,
    this.activityLabel, this.distanceKm, this.recommendationScore,
  });
  final int id;
  final String slug;
  final String name;
  final double lat;
  final double lon;
  final String flagColor;
  final double? flagConfidence;
  final String occupancyLevel;
  final int activeAlertsCount;
  final String activityLevel;
  final String? activityLabel;
  final double? distanceKm;
  final double? recommendationScore;

  factory BeachSummary.fromJson(Map<String, dynamic> j) => BeachSummary(
    id: j['id'] as int,
    slug: j['slug'] as String,
    name: j['name'] as String,
    lat: (j['lat'] as num).toDouble(),
    lon: (j['lon'] as num).toDouble(),
    flagColor: j['flag_color'] as String? ?? 'unknown',
    flagConfidence: (j['flag_confidence'] as num?)?.toDouble(),
    occupancyLevel: j['occupancy_level'] as String? ?? 'unknown',
    activeAlertsCount: j['active_alerts_count'] as int? ?? 0,
    activityLevel: j['activity_level'] as String? ?? 'normal',
    activityLabel: j['activity_label'] as String?,
    distanceKm: (j['distance_km'] as num?)?.toDouble(),
    recommendationScore: (j['recommendation_score'] as num?)?.toDouble(),
  );
}

// Backend: WeatherForecast { date, min_temp, max_temp, precipitation_prob,
//                            wind_speed, wind_direction, weather_type_desc }
class WeatherPoint {
  const WeatherPoint({
    this.minTemp, this.maxTemp, this.windSpeed, this.windDir,
    this.precipitationProb, this.weatherDesc,
  });
  final double? minTemp;
  final double? maxTemp;
  final double? windSpeed;
  final String? windDir;
  final double? precipitationProb;
  final String? weatherDesc;

  factory WeatherPoint.fromJson(Map<String, dynamic> j) => WeatherPoint(
    minTemp: (j['min_temp'] as num?)?.toDouble(),
    maxTemp: (j['max_temp'] as num?)?.toDouble(),
    windSpeed: (j['wind_speed'] as num?)?.toDouble(),
    windDir: j['wind_direction'] as String?,
    precipitationProb: (j['precipitation_prob'] as num?)?.toDouble(),
    weatherDesc: j['weather_type_desc'] as String?,
  );
}

// Backend: SeaForecast { date, wave_height_max, wave_height_min,
//                        wave_period_max, sea_surface_temp }
class SeaPoint {
  const SeaPoint({this.waveHeightMax, this.waveHeightMin, this.wavePeriodMax, this.seaTemp});
  final double? waveHeightMax;
  final double? waveHeightMin;
  final double? wavePeriodMax;
  final double? seaTemp;

  factory SeaPoint.fromJson(Map<String, dynamic> j) => SeaPoint(
    waveHeightMax: (j['wave_height_max'] as num?)?.toDouble(),
    waveHeightMin: (j['wave_height_min'] as num?)?.toDouble(),
    wavePeriodMax: (j['wave_period_max'] as num?)?.toDouble(),
    seaTemp: (j['sea_surface_temp'] as num?)?.toDouble(),
  );
}

// Backend: TideEntry { time, height, type } — type is "high" | "low"
class TideEntry {
  const TideEntry({required this.time, required this.height, required this.type});
  final String time;
  final double height;
  final String type; // "alta" | "baixa"

  factory TideEntry.fromJson(Map<String, dynamic> j) => TideEntry(
    time: j['time'] as String,
    height: (j['height'] as num).toDouble(),
    type: switch (j['type'] as String? ?? 'low') {
      'high' => 'alta',
      'low'  => 'baixa',
      final v => v,
    },
  );
}

class TidesData {
  const TidesData({
    required this.entries,
    this.currentHeight,
    this.direction,
    this.observedAt,
  });

  final List<TideEntry> entries;
  final double? currentHeight;   // live observed height in metres
  final String? direction;       // "rising" | "falling" | "steady"
  final String? observedAt;

  static const empty = TidesData(entries: []);

  factory TidesData.fromJson(Map<String, dynamic> j) {
    final raw = j['entries'] as List? ?? [];
    return TidesData(
      entries: raw.map((e) => TideEntry.fromJson(e as Map<String, dynamic>)).toList(),
      currentHeight: (j['current_height'] as num?)?.toDouble(),
      direction: j['direction'] as String?,
      observedAt: j['observed_at'] as String?,
    );
  }
}

class BeachReport {
  const BeachReport({
    required this.id, required this.type, this.severity,
    this.note, required this.upvotes, required this.downvotes,
    required this.createdAt, required this.isExpired, required this.verified,
    this.beachName, this.beachSlug,
  });
  final int id;
  final String type;
  final int? severity;
  final String? note;
  final int upvotes;
  final int downvotes;
  final String createdAt;
  final bool isExpired;
  final bool verified;
  final String? beachName;
  final String? beachSlug;

  factory BeachReport.fromJson(Map<String, dynamic> j, {String? beachName, String? beachSlug}) =>
      BeachReport(
        id: j['id'] as int,
        type: j['type'] as String,
        severity: j['severity'] as int?,
        note: j['note'] as String?,
        upvotes: j['upvotes'] as int? ?? 0,
        downvotes: j['downvotes'] as int? ?? 0,
        createdAt: (j['created_at'] as String?) ?? DateTime.now().toIso8601String(),
        isExpired: j['is_expired'] as bool? ?? false,
        verified: j['verified'] as bool? ?? false,
        beachName: beachName,
        beachSlug: beachSlug,
      );
}

class MapBeachPresence {
  const MapBeachPresence({
    required this.beachId, required this.beachSlug,
    required this.beachName, required this.userCount,
  });
  final int beachId;
  final String beachSlug;
  final String beachName;
  final int userCount;

  factory MapBeachPresence.fromJson(Map<String, dynamic> j) => MapBeachPresence(
    beachId: j['beach_id'] as int,
    beachSlug: j['beach_slug'] as String,
    beachName: j['beach_name'] as String,
    userCount: j['user_count'] as int? ?? 0,
  );
}

// Backend: WaterQualityResponse { classification, sampled_at, data_source, snapshot_at }
class WaterQuality {
  const WaterQuality({this.classification, this.sampledAt, this.snapshotAt, this.dataSource = 'live'});
  final String? classification; // "Excelente" | "Boa" | "Suficiente" | "Má"
  final String? sampledAt;
  final String? snapshotAt;
  final String dataSource;

  factory WaterQuality.fromJson(Map<String, dynamic> j) => WaterQuality(
    classification: j['classification'] as String?,
    sampledAt: j['sampled_at'] as String?,
    snapshotAt: j['snapshot_at'] as String?,
    dataSource: j['data_source'] as String? ?? 'live',
  );
}

// Backend: TransportResponse { stops: [{ stop_id, stop_name }],
//                              next_departures: [{ route_id, route_short_name, trip_headsign, departure_time }] }
class TransportStop {
  const TransportStop({required this.stopId, required this.stopName});
  final String stopId;
  final String stopName;

  factory TransportStop.fromJson(Map<String, dynamic> j) => TransportStop(
    stopId: j['stop_id'] as String,
    stopName: j['stop_name'] as String,
  );
}

class TransportTrip {
  const TransportTrip({
    required this.routeId, required this.routeShortName,
    this.tripHeadsign, required this.departureTime,
  });
  final String routeId;
  final String routeShortName;
  final String? tripHeadsign;
  final String departureTime;

  factory TransportTrip.fromJson(Map<String, dynamic> j) => TransportTrip(
    routeId: j['route_id'] as String,
    routeShortName: j['route_short_name'] as String,
    tripHeadsign: j['trip_headsign'] as String?,
    departureTime: j['departure_time'] as String,
  );
}

class BeachTransportInfo {
  const BeachTransportInfo({required this.stops, required this.nextDepartures});
  final List<TransportStop> stops;
  final List<TransportTrip> nextDepartures;

  static const empty = BeachTransportInfo(stops: [], nextDepartures: []);

  factory BeachTransportInfo.fromJson(Map<String, dynamic> j) => BeachTransportInfo(
    stops: (j['stops'] as List? ?? []).map((e) => TransportStop.fromJson(e as Map<String, dynamic>)).toList(),
    nextDepartures: (j['next_departures'] as List? ?? []).map((e) => TransportTrip.fromJson(e as Map<String, dynamic>)).toList(),
  );

  /// Group trips by route for display purposes.
  Map<String, List<TransportTrip>> get byRoute {
    final map = <String, List<TransportTrip>>{};
    for (final t in nextDepartures) {
      map.putIfAbsent(t.routeShortName, () => []).add(t);
    }
    return map;
  }
}

class UserProfile {
  const UserProfile({
    required this.id, this.displayName, required this.reputation,
    required this.level, required this.isAnonymous,
  });
  final String id;
  final String? displayName;
  final int reputation;
  final String level;
  final bool isAnonymous;

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
    id: j['id'] as String,
    displayName: j['display_name'] as String?,
    reputation: j['reputation'] as int? ?? 0,
    level: j['level'] as String? ?? 'novo',
    isAnonymous: j['is_anonymous'] as bool? ?? false,
  );
}

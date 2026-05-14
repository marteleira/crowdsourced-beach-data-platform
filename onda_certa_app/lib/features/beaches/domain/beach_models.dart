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
    this.beachName, this.beachSlug, this.myVote,
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
  final int? myVote; // 1=upvote, -1=downvote, null=no vote

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
        myVote: j['my_vote'] as int?,
      );

  // myVote is always explicitly set (null = no vote)
  BeachReport withVote({required int? myVote, int? upvotes, int? downvotes}) => BeachReport(
    id: id, type: type, severity: severity, note: note,
    upvotes: upvotes ?? this.upvotes,
    downvotes: downvotes ?? this.downvotes,
    createdAt: createdAt, isExpired: isExpired, verified: verified,
    beachName: beachName, beachSlug: beachSlug,
    myVote: myVote,
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

// Backend: OccupancyData { level, user_count, is_estimate, last_updated }
class OccupancyData {
  const OccupancyData({required this.level, required this.userCount, this.isEstimate = true});
  final String level; // low | medium | high | unknown
  final int userCount;
  final bool isEstimate;

  factory OccupancyData.fromJson(Map<String, dynamic> j) => OccupancyData(
    level: j['level'] as String? ?? 'unknown',
    userCount: j['user_count'] as int? ?? 0,
    isEstimate: j['is_estimate'] as bool? ?? true,
  );
}

// Backend: BeachStatusResponse { flag_color, flag_confidence, activity_level, occupancy }
class BeachStatus {
  const BeachStatus({
    required this.flagColor, required this.flagConfidence,
    required this.activityLevel, this.activityLabel, required this.occupancy,
  });
  final String flagColor;
  final double flagConfidence;
  final String activityLevel;
  final String? activityLabel;
  final OccupancyData occupancy;

  factory BeachStatus.fromJson(Map<String, dynamic> j) => BeachStatus(
    flagColor: j['flag_color'] as String? ?? 'unknown',
    flagConfidence: (j['flag_confidence'] as num?)?.toDouble() ?? 0.0,
    activityLevel: j['activity_level'] as String? ?? 'normal',
    activityLabel: j['activity_label'] as String?,
    occupancy: OccupancyData.fromJson(j['occupancy'] as Map<String, dynamic>),
  );
}

// Backend: BeachDetail { id, slug, name, lat, lon, max_capacity, flags_available }
class BeachDetailInfo {
  const BeachDetailInfo({
    required this.id, required this.slug, required this.name,
    required this.lat, required this.lon,
    this.maxCapacity, required this.flagsAvailable,
  });
  final int id;
  final String slug;
  final String name;
  final double lat;
  final double lon;
  final int? maxCapacity;
  final bool flagsAvailable;

  factory BeachDetailInfo.fromJson(Map<String, dynamic> j) => BeachDetailInfo(
    id: j['id'] as int,
    slug: j['slug'] as String,
    name: j['name'] as String,
    lat: (j['lat'] as num).toDouble(),
    lon: (j['lon'] as num).toDouble(),
    maxCapacity: j['max_capacity'] as int?,
    flagsAvailable: j['flags_available'] as bool? ?? false,
  );
}

// Backend: BeachFullResponse — returned by GET /beaches/{slug}
class BeachFullDetail {
  const BeachFullDetail({
    required this.detail, required this.status, required this.activeAlerts,
    this.weather, this.sea, required this.tides,
    this.waterQuality, required this.transport,
  });
  final BeachDetailInfo detail;
  final BeachStatus status;
  final List<BeachReport> activeAlerts;
  final WeatherPoint? weather;
  final SeaPoint? sea;
  final TidesData tides;
  final WaterQuality? waterQuality;
  final BeachTransportInfo transport;

  factory BeachFullDetail.fromJson(Map<String, dynamic> j) {
    final beachJson = j['beach'] as Map<String, dynamic>;
    final alertsList = (j['active_alerts'] as List? ?? []);
    final weatherList = j['weather'] as List?;
    final seaList = j['sea'] as List?;
    final tidesJson = j['tides'] as Map<String, dynamic>?;
    final wqJson = j['water_quality'] as Map<String, dynamic>?;
    final transportJson = j['transport'] as Map<String, dynamic>?;

    return BeachFullDetail(
      detail: BeachDetailInfo.fromJson(beachJson),
      status: BeachStatus.fromJson(j['status'] as Map<String, dynamic>),
      activeAlerts: alertsList
          .map((e) => BeachReport.fromJson(
                e as Map<String, dynamic>,
                beachName: beachJson['name'] as String?,
                beachSlug: beachJson['slug'] as String?,
              ))
          .toList(),
      weather: weatherList != null && weatherList.isNotEmpty
          ? WeatherPoint.fromJson(weatherList.first as Map<String, dynamic>)
          : null,
      sea: seaList != null && seaList.isNotEmpty
          ? SeaPoint.fromJson(seaList.first as Map<String, dynamic>)
          : null,
      tides: tidesJson != null ? TidesData.fromJson(tidesJson) : TidesData.empty,
      waterQuality: wqJson != null ? WaterQuality.fromJson(wqJson) : null,
      transport: transportJson != null ? BeachTransportInfo.fromJson(transportJson) : BeachTransportInfo.empty,
    );
  }
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

// Single departure within a direction group
class TransportDeparture {
  const TransportDeparture({
    required this.departureTime, required this.routeShortName, this.isRealtime = false,
  });
  final String departureTime;  // "HH:MM:SS" from backend
  final String routeShortName;
  final bool isRealtime;

  String get displayTime {
    // "18:50:00" → "18:50"
    final parts = departureTime.split(':');
    return parts.length >= 2 ? '${parts[0]}:${parts[1]}' : departureTime;
  }

  factory TransportDeparture.fromJson(Map<String, dynamic> j) => TransportDeparture(
    departureTime: j['departure_time'] as String,
    routeShortName: j['route_short_name'] as String,
    isRealtime: j['is_realtime'] as bool? ?? false,
  );
}

// A destination group — all departures heading the same way
class TransportDirection {
  const TransportDirection({required this.headsign, required this.departures});
  final String headsign;
  final List<TransportDeparture> departures;

  factory TransportDirection.fromJson(Map<String, dynamic> j) => TransportDirection(
    headsign: j['headsign'] as String,
    departures: (j['departures'] as List? ?? [])
        .map((e) => TransportDeparture.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

class BeachTransportInfo {
  const BeachTransportInfo({required this.stops, required this.directions});
  final List<TransportStop> stops;
  final List<TransportDirection> directions;

  static const empty = BeachTransportInfo(stops: [], directions: []);

  bool get hasDepartures => directions.any((d) => d.departures.isNotEmpty);

  factory BeachTransportInfo.fromJson(Map<String, dynamic> j) => BeachTransportInfo(
    stops: (j['stops'] as List? ?? [])
        .map((e) => TransportStop.fromJson(e as Map<String, dynamic>))
        .toList(),
    directions: (j['directions'] as List? ?? [])
        .map((e) => TransportDirection.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
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

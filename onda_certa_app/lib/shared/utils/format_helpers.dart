/// Shared formatting helpers — measurements, time, strings.
library;

import '../../core/constants/app_strings.dart';

/// Relative time from a [DateTime]. Returns e.g. "há 5 min", "ontem".
String timeAgo(DateTime dt) {
  final diff = DateTime.now().toUtc().difference(dt.toUtc());
  if (diff.inMinutes < 1) return AppStrings.timeJustNow;
  if (diff.inMinutes < 60) return AppStrings.timeMinutes(diff.inMinutes);
  if (diff.inHours < 24) return AppStrings.timeHours(diff.inHours);
  if (diff.inDays == 1) return AppStrings.timeYesterday;
  if (diff.inDays < 7) return AppStrings.timeDays(diff.inDays);
  if (diff.inDays < 30) return AppStrings.timeWeeks((diff.inDays / 7).round());
  return AppStrings.timeMonths((diff.inDays / 30).round());
}

/// Relative time from an ISO 8601 string. Returns '' on parse failure.
String timeAgoFromString(String iso) {
  try {
    return timeAgo(DateTime.parse(iso));
  } catch (_) {
    return '';
  }
}

/// Up to two initials from a display name, upper-cased. Returns '' if empty.
String getInitials(String? name) {
  if (name == null || name.trim().isEmpty) return '';
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  return parts[0][0].toUpperCase();
}

/// Distance: sub-kilometre in metres, kilometre with one decimal.
String formatDistance(double km) =>
    km < 1 ? '${(km * 1000).round()} m' : '${km.toStringAsFixed(1)} km';

/// Sea/air temperature with degree symbol. Returns '--' if null.
String formatTemperature(double? t) => t != null ? '${t.round()}°C' : '--';

/// Wave height in metres with one decimal. Returns '--' if null.
String formatWaveHeight(double? h) => h != null ? '${h.toStringAsFixed(1)}m' : '--';

/// Tide height in metres with two decimals. Returns '--' if null.
String formatTideHeight(double? h) => h != null ? '${h.toStringAsFixed(2)}m' : '--';

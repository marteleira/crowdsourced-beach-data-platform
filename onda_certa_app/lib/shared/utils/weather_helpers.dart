import '../../core/l10n/l10n.dart';

// Wind direction: backend always sends the canonical 8-point English code
// (N/NE/E/SE/S/SW/W/NW), regardless of data source (IPMA or Open-Meteo).
String windDirectionLabel(AppLocalizations l10n, String? code) => switch (code) {
  'N'  => l10n.windDirN,
  'NE' => l10n.windDirNE,
  'E'  => l10n.windDirE,
  'SE' => l10n.windDirSE,
  'S'  => l10n.windDirS,
  'SW' => l10n.windDirSW,
  'W'  => l10n.windDirW,
  'NW' => l10n.windDirNW,
  _    => '',
};

// IPMA's own 1-29 weather type code - used for the 5-day baseline forecast.
String? weatherTypeIpmaLabel(AppLocalizations l10n, int? id) => switch (id) {
  1  => l10n.weatherDescClearSky,
  2  => l10n.weatherDescFewClouds,
  3  => l10n.weatherDescPartlyCloudy,
  4  => l10n.weatherDescVeryCloudy,
  5  => l10n.weatherDescCloudy,
  6  => l10n.weatherDescLightShowers,
  7  => l10n.weatherDescShowers,
  8  => l10n.weatherDescHeavyShowers,
  9  => l10n.weatherDescLightRain,
  10 => l10n.weatherDescModerateRain,
  11 => l10n.weatherDescHeavyRain,
  12 => l10n.weatherDescLightRainOrShowers,
  13 => l10n.weatherDescRainOrShowers,
  14 => l10n.weatherDescHeavyRainOrShowers,
  15 => l10n.weatherDescThunderLightRain,
  16 => l10n.weatherDescThunderModerateRain,
  17 => l10n.weatherDescHail,
  18 => l10n.weatherDescLightSnow,
  19 => l10n.weatherDescModerateToHeavySnow,
  20 => l10n.weatherDescFogLowClouds,
  21 => l10n.weatherDescMist,
  22 => l10n.weatherDescShowersAndLightSnow,
  23 => l10n.weatherDescLightRainAndSnow,
  24 => l10n.weatherDescRainAndSnow,
  25 => l10n.weatherDescSnowAndLightRain,
  26 => l10n.weatherDescLightRainOrShowersChance,
  27 => l10n.weatherDescHailShowers,
  28 => l10n.weatherDescStrongWindLightShowers,
  29 => l10n.weatherDescThunderShowers,
  _  => null,
};

// WMO weather code (0-99) - used for Open-Meteo's "today" override, more
// accurate/current than the IPMA baseline for the first forecast day.
String? weatherCodeWmoLabel(AppLocalizations l10n, int? code) => switch (code) {
  0  => l10n.weatherDescClearSky,
  1  => l10n.weatherDescFewClouds,
  2  => l10n.weatherDescPartlyCloudy,
  3  => l10n.weatherDescOvercast,
  45 => l10n.weatherDescFogLowClouds,
  48 => l10n.weatherDescFreezingFog,
  51 => l10n.weatherDescLightDrizzle,
  53 => l10n.weatherDescModerateDrizzle,
  55 => l10n.weatherDescHeavyDrizzle,
  61 => l10n.weatherDescLightRain,
  63 => l10n.weatherDescModerateRain,
  65 => l10n.weatherDescHeavyRain,
  71 => l10n.weatherDescLightSnow,
  73 => l10n.weatherDescModerateSnow,
  75 => l10n.weatherDescHeavySnow,
  77 => l10n.weatherDescSnowGrains,
  80 => l10n.weatherDescLightShowers,
  81 => l10n.weatherDescShowers,
  82 => l10n.weatherDescHeavyShowers,
  85 => l10n.weatherDescLightSnowShowers,
  86 => l10n.weatherDescHeavySnowShowers,
  95 => l10n.weatherDescThunderstorm,
  96 => l10n.weatherDescThunderstormHail,
  99 => l10n.weatherDescHeavyThunderstormHail,
  _  => null,
};

// Prefers the WMO code (Open-Meteo, only present for "today") over the IPMA
// type id (5-day baseline), mirroring the backend's own override precedence.
String weatherDescription(AppLocalizations l10n, {int? wmoCode, int? ipmaTypeId}) {
  return weatherCodeWmoLabel(l10n, wmoCode) ??
      weatherTypeIpmaLabel(l10n, ipmaTypeId) ??
      '';
}

// Cloud cover (0=clear..1=overcast) and whether it's actively precipitating,
// derived directly from the weather code. Drives the tide screen's animated
// background — previously done by keyword-matching the (possibly PT or EN)
// description text, which broke whenever the string arrived in a language
// the matcher didn't expect. Prefers the WMO code, same precedence as
// weatherDescription().
({double cloudCover, bool isRaining}) weatherSceneMeta({int? wmoCode, int? ipmaTypeId}) {
  if (wmoCode != null) return _wmoScene(wmoCode);
  if (ipmaTypeId != null) return _ipmaScene(ipmaTypeId);
  return (cloudCover: 0.35, isRaining: false);
}

({double cloudCover, bool isRaining}) _wmoScene(int code) => switch (code) {
  0 => (cloudCover: 0.00, isRaining: false),
  1 => (cloudCover: 0.20, isRaining: false),
  2 => (cloudCover: 0.50, isRaining: false),
  3 => (cloudCover: 1.00, isRaining: false),
  45 || 48 => (cloudCover: 0.85, isRaining: false),
  51 || 53 || 55 => (cloudCover: 0.90, isRaining: true),
  61 || 63 || 65 => (cloudCover: 0.90, isRaining: true),
  71 || 73 || 75 || 77 => (cloudCover: 0.85, isRaining: false),
  80 || 81 || 82 => (cloudCover: 0.75, isRaining: true),
  85 || 86 => (cloudCover: 0.75, isRaining: false),
  95 || 96 || 99 => (cloudCover: 1.00, isRaining: true),
  _ => (cloudCover: 0.35, isRaining: false),
};

({double cloudCover, bool isRaining}) _ipmaScene(int id) => switch (id) {
  1 => (cloudCover: 0.00, isRaining: false),
  2 => (cloudCover: 0.20, isRaining: false),
  3 => (cloudCover: 0.50, isRaining: false),
  4 => (cloudCover: 0.80, isRaining: false),
  5 => (cloudCover: 0.65, isRaining: false),
  6 || 7 || 8 => (cloudCover: 0.75, isRaining: true),
  9 || 10 || 11 => (cloudCover: 0.90, isRaining: true),
  12 || 13 || 14 => (cloudCover: 0.90, isRaining: true),
  15 || 16 || 17 => (cloudCover: 1.00, isRaining: true),
  18 || 19 => (cloudCover: 0.85, isRaining: false),
  20 => (cloudCover: 0.85, isRaining: false),
  21 => (cloudCover: 0.70, isRaining: false),
  22 || 23 || 24 || 25 || 26 || 27 => (cloudCover: 0.85, isRaining: true),
  28 => (cloudCover: 0.75, isRaining: true),
  29 => (cloudCover: 1.00, isRaining: true),
  _ => (cloudCover: 0.35, isRaining: false),
};

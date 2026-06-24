/// Application-level configuration constants.
///
/// OAuth credentials and environment-specific values live here
/// so they have a single source of truth.
library;

class AppConfig {
  /// Google OAuth server client ID — must match backend GOOGLE_CLIENT_ID.
  static const String googleServerClientId =
      '690249877915-a70cee3ioodj4tv4nqm8ge0mnrs4mmh0.apps.googleusercontent.com';

  /// Geographic centre of the Arrábida peninsula — used as the default map position.
  static const double mapCenterLat = 38.465;
  static const double mapCenterLon = -8.94;
  static const double mapInitialZoom = 11.0;
}

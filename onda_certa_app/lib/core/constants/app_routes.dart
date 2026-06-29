class AppRoutes {
  // Auth
  static const login         = '/login';
  static const loginEmail    = '/login/email';
  static const forgotPassword = '/login/forgot-password';
  static const resetPassword  = '/login/reset-password';
  static const verifyEmail    = '/verify-email';

  // Account status
  static const pendingDeletion  = '/pending-deletion';
  static const accountBanned    = '/account-banned';
  static const accountSuspended = '/account-suspended';

  // Main
  static const home          = '/home';
  static const notifications = '/notifications';
  static const favourites    = '/favourites';

  // Settings
  static const settingsAccount       = '/settings/account';
  static const settingsNotifications = '/settings/notifications';
  static const settingsPrivacy       = '/settings/privacy';

  // Legal
  static const terms   = '/terms';
  static const privacy = '/privacy';

  // Beach (parametric)
  static String beach(String slug)          => '/beach/$slug';
  static String beachAlerts(String slug)    => '/beach/$slug/alerts';
  static String beachTransport(String slug) => '/beach/$slug/transport';
  static String beachTides(String slug)     => '/beach/$slug/tides';
}

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'OndaCerta';

  @override
  String get appTagline => 'Real beaches. Real conditions.';

  @override
  String get appLocation => 'Arrábida Natural Park · Portugal';

  @override
  String get navHome => 'Home';

  @override
  String get navBeaches => 'Beaches';

  @override
  String get navTides => 'Tides';

  @override
  String get navProfile => 'Profile';

  @override
  String get continueAsGuest => 'Continue as guest';

  @override
  String get createAccount => 'Create account';

  @override
  String get signIn => 'Sign in';

  @override
  String get registerSubtitle => 'Register to contribute to the community';

  @override
  String get loginWelcomeBack => 'Welcome back';

  @override
  String get fieldName => 'Name';

  @override
  String get fieldNameHint => 'Your name';

  @override
  String get fieldEmail => 'Email';

  @override
  String get fieldEmailHint => 'your@email.com';

  @override
  String get forgotPassword => 'Forgot password';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get authConsentPrefix => 'By continuing, you accept our ';

  @override
  String get authConsentAnd => ' and our ';

  @override
  String get errorGoogleToken => 'Could not obtain Google token';

  @override
  String get errorGoogleSignIn => 'Failed to sign in with Google';

  @override
  String get loading => 'Loading data...';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get settings => 'Settings';

  @override
  String get close => 'Close';

  @override
  String get viewAll => 'View all →';

  @override
  String get viewDetails => 'View details →';

  @override
  String get viewBeaches => 'View all →';

  @override
  String get tryAgain => 'Try again';

  @override
  String get liveLabel => 'live';

  @override
  String get recommended => 'Recommended';

  @override
  String get updating => 'Updating...';

  @override
  String get updatePresence => 'Update presence';

  @override
  String get seeAllBeaches => 'See all beaches >';

  @override
  String get noLocationBanner =>
      'Without location access you cannot report conditions or vote.';

  @override
  String get sectionFavourites => 'FAVOURITES';

  @override
  String get sectionAlerts => 'ACTIVE ALERTS';

  @override
  String get noFavourites => 'No favourites yet';

  @override
  String get noFavouritesHint =>
      'Open a beach and save it\nfor quick access here.';

  @override
  String get noAlerts => 'No active alerts';

  @override
  String get bestBeachNow => 'Best Beach Now';

  @override
  String tidesSection(String beach) {
    return 'TIDES · $beach';
  }

  @override
  String get greetingMorning => 'Good morning';

  @override
  String get greetingAfternoon => 'Good afternoon';

  @override
  String get greetingEvening => 'Good evening';

  @override
  String get weatherAir => 'Air';

  @override
  String get weatherWind => 'Wind';

  @override
  String get weatherWaves => 'Waves';

  @override
  String get weatherRain => 'Rain';

  @override
  String get flagStatusSafe => 'Safe';

  @override
  String get flagStatusCaution => 'Caution';

  @override
  String get flagStatusDanger => 'Danger';

  @override
  String get exploreTitle => 'Explore';

  @override
  String get exploreMap => 'Beach map';

  @override
  String get exploreMapSub => 'View all on map';

  @override
  String get exploreTransport => 'Transport';

  @override
  String get exploreTransportSub => 'Carris Metropolitana';

  @override
  String get exploreBeaches => 'Beaches';

  @override
  String get exploreReport => 'Submit report';

  @override
  String get exploreReportSub => 'Help the community';

  @override
  String get communityTitle => 'Community';

  @override
  String communityReports(int count) {
    return '$count active reports';
  }

  @override
  String communityFooter(int beaches, int users) {
    return 'at $beaches beaches · $users users online';
  }

  @override
  String get beachListTitle => 'Beaches';

  @override
  String get searchHint => 'Search beach...';

  @override
  String get filterAll => 'All';

  @override
  String get filterSafe => 'Safe';

  @override
  String get filterCaution => 'Caution';

  @override
  String get filterDanger => 'Danger';

  @override
  String get filterNoData => 'No data';

  @override
  String get beachCardView => 'View →';

  @override
  String get errorLoadBeaches => 'Could not load beaches';

  @override
  String noBeachesForSearch(String query) {
    return 'No beach found for \"$query\"';
  }

  @override
  String get noBeachesForFilter => 'No beach with this filter';

  @override
  String get municipality => 'Arrábida';

  @override
  String get sectionWeather => 'Weather';

  @override
  String get labelTemperature => 'Temperature';

  @override
  String get labelRain => 'Rain';

  @override
  String get labelOccupancy => 'Occupancy';

  @override
  String get labelConfidence => '% conf.';

  @override
  String get flagLiveTap => 'live · Tap to confirm';

  @override
  String get flagProposeTap => 'Tap to propose a flag';

  @override
  String get errorFavourite => 'Could not update favourite';

  @override
  String get tooFarToCheckin =>
      'You are too far from a beach to register presence.';

  @override
  String get presenceRegistered => 'Presence registered!';

  @override
  String get fewUsersNote => 'Few users';

  @override
  String usersAtBeach(int count) {
    return '$count people';
  }

  @override
  String get occupancyNote =>
      'using the app at this beach in the last 20 min. Approximate estimate.';

  @override
  String get alertsTitle => 'Community Alerts';

  @override
  String alertsActive(int count) {
    return '$count active';
  }

  @override
  String get mustBeAtBeachVote => 'You must be at the beach to vote';

  @override
  String get errorVoting => 'Error voting. Try again.';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get errorLoadNotifications => 'Error loading notifications';

  @override
  String get notificationsEmpty => 'Beach notifications appear here.';

  @override
  String get settingsGeneral => 'General';

  @override
  String get settingsNotifsEnabled => 'Notifications enabled';

  @override
  String get settingsNotifsEnabledSub => 'Turn all notifications on or off';

  @override
  String get settingsCommunityAlerts => 'Community alerts';

  @override
  String get settingsCheckinAlerts => 'Check-in alerts';

  @override
  String get settingsCheckinAlertsSub =>
      'Notify when you arrive at a beach with alerts';

  @override
  String get settingsProximityAlerts => 'Proximity alerts';

  @override
  String get settingsProximityAlertsSub => 'Alerts when you are near a beach';

  @override
  String get settingsProximityRadius => 'Proximity radius';

  @override
  String get settingsAlertTypes => 'Alert types';

  @override
  String get settingsJellyfish => 'Jellyfish';

  @override
  String get settingsStrongCurrent => 'Strong current';

  @override
  String get settingsPollution => 'Pollution';

  @override
  String get settingsRoughSea => 'Rough sea';

  @override
  String get settingsMinSeverity => 'Minimum severity';

  @override
  String get errorLoadSettings => 'Could not load notifications';

  @override
  String proximityRadiusValue(int meters) {
    return '$meters m';
  }

  @override
  String get accountTitle => 'Account';

  @override
  String get errorLoadProfile => 'Could not load profile';

  @override
  String get guestUser => 'Guest';

  @override
  String get registeredUser => 'User';

  @override
  String get guestMode => 'Guest mode';

  @override
  String reputationPoints(int count) {
    return '$count reputation points';
  }

  @override
  String get flagLabelGreen => 'Safe';

  @override
  String get flagLabelYellow => 'Caution';

  @override
  String get flagLabelRed => 'Danger';

  @override
  String get flagLabelPurple => 'Closed';

  @override
  String get flagLabelUnknown => 'Unknown';

  @override
  String get flagDescGreen => 'Safe to swim';

  @override
  String get flagDescYellow => 'Swim with caution';

  @override
  String get flagDescRed => 'Dangerous conditions';

  @override
  String get flagDescPurple => 'Beach closed';

  @override
  String get flagDescUnknown => 'Unknown status';

  @override
  String get occupancyLow => 'Quiet';

  @override
  String get occupancyMedium => 'Moderate';

  @override
  String get occupancyHigh => 'Crowded';

  @override
  String get occupancyAnimated => 'Lively';

  @override
  String get occupancyFull => 'Full';

  @override
  String get occupancyUnknown => 'Unknown';

  @override
  String get qualityExcellent => 'Excellent';

  @override
  String get qualityGood => 'Good';

  @override
  String get qualitySufficient => 'Sufficient';

  @override
  String get qualityPoor => 'Poor';

  @override
  String get qualityUnknown => 'Unknown';

  @override
  String get beachQualityExcellent => 'Excellent';

  @override
  String get beachQualityGood => 'Good condition';

  @override
  String get beachQualityFair => 'Fair condition';

  @override
  String get beachQualityPoor => 'Poor condition';

  @override
  String get tideHigh => 'high';

  @override
  String get tideLow => 'low';

  @override
  String get tidePrefixHigh => 'high tide';

  @override
  String get tidePrefixLow => 'low tide';

  @override
  String get timeJustNow => 'just now';

  @override
  String get timeYesterday => 'yesterday';

  @override
  String timeMinutes(int minutes) {
    return '$minutes min ago';
  }

  @override
  String timeHours(int hours) {
    return '${hours}h ago';
  }

  @override
  String timeDays(int days) {
    return '$days days ago';
  }

  @override
  String timeWeeks(int weeks) {
    return '$weeks wk ago';
  }

  @override
  String timeMonths(int months) {
    return '$months months ago';
  }

  @override
  String get guestVoteAlerts => 'Create an account to vote on alerts';

  @override
  String get guestSubmitReport => 'Create an account to submit reports';

  @override
  String get guestConfirmFlag => 'Create an account to confirm flags';

  @override
  String get guestProposeFlag => 'Create an account to propose flags';

  @override
  String get guestSaveContribs =>
      'Create an account to save your contributions.';
}

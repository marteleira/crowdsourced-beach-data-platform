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
  String get signInGoogle => 'Sign in with Google';

  @override
  String get signInEmail => 'Sign in with email';

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
  String get errorSignIn => 'Error signing in. Please try again.';

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
  String get retryAgain => 'Try again';

  @override
  String get cancelLabel => 'Cancel';

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
  String get explorerName => 'explorer';

  @override
  String updatedAt(String time) {
    return 'Updated at $time';
  }

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
  String get homeSeaTemp => 'Sea temp.';

  @override
  String get homeActiveNow => 'Active now';

  @override
  String get homeAlerts => 'Alerts';

  @override
  String get homeFavViewAll => 'View\nall';

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
  String get weatherFeelsLike => 'Feels like';

  @override
  String get weatherHumidity => 'Humidity';

  @override
  String get weatherUv => 'UV';

  @override
  String windGusts(int gusts) {
    return 'gusts $gusts km/h';
  }

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
  String get beachAlertSingular => 'active alert';

  @override
  String get beachAlertPlural => 'active alerts';

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
  String get seaConditionsTitle => 'Sea Conditions';

  @override
  String get seaWavePeriod => 'Period';

  @override
  String get seaTempLabel => 'Sea Temp.';

  @override
  String get tideDirRising => 'rising';

  @override
  String get tideDirFalling => 'falling';

  @override
  String get tideDirSteady => 'steady';

  @override
  String get tideDirRisingCap => 'Rising';

  @override
  String get tideDirFallingCap => 'Falling';

  @override
  String get tideDirSteadyCap => 'Steady';

  @override
  String get tidesPageTitle => 'Tides';

  @override
  String get tidesMoreDetails => 'MORE DETAILS';

  @override
  String get tidesTodaySection => 'TODAY\'S TIDES';

  @override
  String get tidesNoData => 'No tide data available';

  @override
  String get tidesChartSection => 'TIDE CHART';

  @override
  String get tidesNowLabel => 'NOW';

  @override
  String get tidesCardTitle => 'Today\'s Tides';

  @override
  String get tidesViewFull => 'Full view →';

  @override
  String get waterQualityTitle => 'Water Quality';

  @override
  String waterQualityLastSampled(String date) {
    return 'Last sampled $date';
  }

  @override
  String waterQualityCachedMins(int minutes) {
    return 'cached $minutes min ago';
  }

  @override
  String waterQualityCachedHours(int hours) {
    return 'cached ${hours}h ago';
  }

  @override
  String waterQualityCachedDays(int days) {
    return 'cached ${days}d ago';
  }

  @override
  String get waterQualityCached => 'cached data';

  @override
  String get transportCardTitle => 'Next Departures';

  @override
  String get transportNoInfo => 'No transport information for this beach';

  @override
  String get transportNoDepartures => 'No scheduled departures';

  @override
  String transportNearbyStop(int count) {
    return '$count stop nearby';
  }

  @override
  String transportNearbyStops(int count) {
    return '$count stops nearby';
  }

  @override
  String get transportViewSchedules => 'View full schedule →';

  @override
  String get communityAlertsSectionTitle => 'COMMUNITY ALERTS';

  @override
  String get reportVerified => 'Verified';

  @override
  String get reportVoteSingular => 'vote';

  @override
  String get reportVotePlural => 'votes';

  @override
  String get communityAlertsEmptyTitle => 'All clear!';

  @override
  String get communityAlertsEmptyBody =>
      'No active alerts at this beach.\nIf you see something, report it!';

  @override
  String get communityAlertsReportBtn => 'Report condition';

  @override
  String get errorLoadAlerts => 'Error loading alerts';

  @override
  String get alertTypeJellyfish => 'Jellyfish';

  @override
  String get alertTypeStrongCurrent => 'Strong Current';

  @override
  String get alertTypePollution => 'Pollution';

  @override
  String get alertTypeRoughSea => 'Rough Sea';

  @override
  String get alertTypeOther => 'Other';

  @override
  String get alertTypeDefault => 'Alert';

  @override
  String get severityLow => 'Low';

  @override
  String get severityModerate => 'Moderate';

  @override
  String get severityHigh => 'Severe';

  @override
  String get reportSheetTitle => 'Report Condition';

  @override
  String get reportTypeSection => 'Condition type';

  @override
  String get reportSeveritySection => 'What is the severity?';

  @override
  String get reportSeverityLowSub => 'Minor concern';

  @override
  String get reportSeverityModerateSub => 'Notable risk';

  @override
  String get reportSeverityHighSub => 'Dangerous';

  @override
  String get reportNoteSection => 'Add note';

  @override
  String get reportNoteOptional => '(optional)';

  @override
  String get reportNoteHint => 'Describe what you observed...';

  @override
  String get reportLocationNote =>
      'Your approximate location will be shared with this report.';

  @override
  String get reportSubmit => 'Submit Report';

  @override
  String get reportSuccess => 'Report submitted successfully!';

  @override
  String get reportMustBeAtBeach =>
      'You must be at the beach to submit a report';

  @override
  String get reportError => 'Error submitting. Try again.';

  @override
  String get presenceSectionTitle => 'WHO\'S HERE';

  @override
  String get presenceViewAll => 'View all →';

  @override
  String get presencePerson => '1 person';

  @override
  String presencePeople(int count) {
    return '$count people';
  }

  @override
  String get presencePersonHere => '1 person at this beach now';

  @override
  String presencePeopleHere(int count) {
    return '$count people at this beach now';
  }

  @override
  String get presenceSharedProfile1 => '1 shares profile';

  @override
  String presenceSharedProfiles(int count) {
    return '$count share profile';
  }

  @override
  String get presencePrivateNote =>
      'No one has chosen to share their location.';

  @override
  String get presenceSheetTitle => 'Who\'s here';

  @override
  String get presenceAnonymousUser => 'Anonymous User';

  @override
  String presencePrivateFooter1(int count) {
    return '+$count person in private mode';
  }

  @override
  String presencePrivateFooterN(int count) {
    return '+$count people in private mode';
  }

  @override
  String get presenceEmptyTitle1 => '1 person is here';

  @override
  String presenceEmptyTitleN(int count) {
    return '$count people are here';
  }

  @override
  String get presenceEmptyPrivate =>
      'No one has chosen to share\ntheir location.';

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
  String get settingsFavBeaches => 'Favourite beaches';

  @override
  String get settingsFavAlertsEnabled => 'My beach alerts';

  @override
  String get settingsFavAlertsEnabledSub =>
      'Receive alerts for beaches you have saved';

  @override
  String get settingsBeachStatus => 'Beach status';

  @override
  String get settingsFlagChange => 'Flag change';

  @override
  String get settingsFlagChangeSub => 'Notify when the safety status changes';

  @override
  String get settingsTideAlerts => 'Tide alerts';

  @override
  String get settingsTideAlertsSub => 'Alert before high tide and low tide';

  @override
  String get settingsMyReports => 'My reports';

  @override
  String get settingsReportConfirmed => 'Report confirmed';

  @override
  String get settingsReportConfirmedSub =>
      'When the community confirms one of your reports';

  @override
  String get settingsReportRejected => 'Report rejected';

  @override
  String get settingsReportRejectedSub =>
      'When the community rejects one of your reports';

  @override
  String get settingsQuietHours => 'Quiet hours';

  @override
  String get settingsQuietHoursEnabled => 'Enable quiet hours';

  @override
  String get settingsQuietHoursEnabledSub =>
      'No notifications during the defined period';

  @override
  String get settingsQuietStart => 'Start';

  @override
  String get settingsQuietEnd => 'End';

  @override
  String get settingsSeverityLow => 'Low';

  @override
  String get settingsSeverityMedium => 'Medium';

  @override
  String get settingsSeverityHigh => 'High';

  @override
  String get privacyLocation => 'Location';

  @override
  String get privacyLocationAccuracy => 'Location accuracy';

  @override
  String get privacyLocationAccuracySub =>
      'Controls the precision shared with other users';

  @override
  String get privacyLocationExact => 'Exact';

  @override
  String get privacyLocationApprox => 'Approx.';

  @override
  String get privacyLocationNone => 'None';

  @override
  String get privacyPublicProfile => 'Public profile';

  @override
  String get privacyNameVisible => 'Name visible';

  @override
  String get privacyNameVisibleSub => 'Other users can see your name';

  @override
  String get privacyAvatarVisible => 'Avatar visible';

  @override
  String get privacyAvatarVisibleSub => 'Your initials appear on reports';

  @override
  String get privacyPresence => 'Presence & Activity';

  @override
  String get privacyShowOnMap => 'Show on map';

  @override
  String get privacyShowOnMapSub =>
      'Your presence counts towards beach occupancy';

  @override
  String get privacyShareUsage => 'Share usage data';

  @override
  String get privacyShareUsageSub => 'Help improve the app anonymously';

  @override
  String get privacyMyData => 'My data';

  @override
  String get privacyExportData => 'Export my data';

  @override
  String get privacyExportDataSub => 'Receive a copy of everything we store';

  @override
  String get privacyDeleteReports => 'Delete all reports';

  @override
  String get privacyDeleteReportsSub => 'Remove your reports from the platform';

  @override
  String get privacyDeleteAccount => 'Delete account';

  @override
  String get privacyDeleteAccountSub => 'Permanent and irreversible action';

  @override
  String get privacyExporting => 'Exporting data…';

  @override
  String privacyExportSaved(String filename) {
    return 'Saved: $filename';
  }

  @override
  String privacyExportError(String error) {
    return 'Error: $error';
  }

  @override
  String get privacyDeleteReportsConfirmTitle => 'Delete all reports?';

  @override
  String get privacyDeleteReportsConfirmBody =>
      'All your reports will be removed from the platform. Your reputation points will be kept.';

  @override
  String get privacyDeleteReportsSuccess => 'Reports deleted successfully';

  @override
  String get privacyDeleteReportsError => 'Error deleting reports';

  @override
  String get privacyDeleteAccountConfirmTitle => 'Delete account?';

  @override
  String get privacyDeleteAccountConfirmBody =>
      'This action is permanent. All your data will be deleted.\n\nType DELETE to confirm:';

  @override
  String get privacyDeleteAccountConfirmWord => 'DELETE';

  @override
  String get privacyDeleteAccountError => 'Error deleting account';

  @override
  String get privacyPendingTitle => 'Account scheduled for deletion';

  @override
  String privacyPendingBody(String date) {
    return 'Your account and all your data will be permanently deleted on $date.\n\nYou can cancel this action until that date.';
  }

  @override
  String get privacyPendingBodyNoDate =>
      'Your account is scheduled for deletion.\n\nYou can cancel this action before the scheduled date.';

  @override
  String get privacyCancelDeletion => 'Cancel account deletion';

  @override
  String get privacyCancelling => 'Cancelling…';

  @override
  String get privacyCancelError => 'Error cancelling deletion. Try again.';

  @override
  String get privacyDeleteLabel => 'Delete';

  @override
  String get privacyDeleteAccountConfirmBtn => 'Delete account';

  @override
  String get accountTitle => 'Account';

  @override
  String get errorLoadProfile => 'Could not load profile';

  @override
  String get accountAvatarSection => 'Avatar';

  @override
  String get accountAvatarDefault => 'Default avatar (initials)';

  @override
  String get accountAvatarChoose => 'Choose avatar';

  @override
  String get accountAvatarPickerTitle => 'Choose your avatar';

  @override
  String get accountAvatarPickerSub => 'Tap an avatar to select it.';

  @override
  String get accountAvatarDefaultLabel => 'Default (initials)';

  @override
  String get accountAvatarDefaultSub => 'Shows your name initials';

  @override
  String get accountPersonalSection => 'Personal Information';

  @override
  String get accountNameEmpty => 'Name cannot be empty';

  @override
  String get accountNameTooLong => 'Maximum 50 characters';

  @override
  String get accountSaveName => 'Save name';

  @override
  String get accountNoChanges => 'No changes to save';

  @override
  String get accountProfileUpdated => 'Profile updated successfully';

  @override
  String get accountProfileUpdateError => 'Could not update profile';

  @override
  String get accountAvatarUpdated => 'Avatar updated successfully';

  @override
  String get accountAvatarUpdateError => 'Could not update avatar';

  @override
  String get accountUnexpectedError => 'An unexpected error occurred';

  @override
  String get accountEmailSection => 'Email';

  @override
  String get accountEmailNoGuest => 'Guests do not have an associated email.';

  @override
  String get accountEmailNoGoogle =>
      'Your Google account does not allow changing email here.';

  @override
  String get accountNewEmail => 'New email';

  @override
  String get accountNewEmailHint => 'new@example.com';

  @override
  String get accountEmailVerificationNote =>
      'Verification will be sent to the new email.';

  @override
  String get accountCurrentPasswordConfirm => 'Current password (confirmation)';

  @override
  String get accountPasswordHint => '••••••••';

  @override
  String get accountEmailEmpty => 'Enter an email';

  @override
  String get accountEmailInvalid => 'Invalid email';

  @override
  String get accountEmailUnchanged => 'Email has not changed';

  @override
  String get accountCurrentPasswordEmpty => 'Enter current password';

  @override
  String get accountChangeEmail => 'Change email';

  @override
  String get accountPasswordSection => 'Password';

  @override
  String get accountPasswordNoGuest => 'Guests do not have a password.';

  @override
  String get accountPasswordNoGoogle =>
      'Your Google account does not use a password.';

  @override
  String get accountCurrentPassword => 'Current password';

  @override
  String get accountNewPassword => 'New password';

  @override
  String get accountConfirmPassword => 'Confirm new password';

  @override
  String get accountPasswordMismatch => 'Passwords do not match';

  @override
  String get accountConfirmPasswordEmpty => 'Confirm the new password';

  @override
  String get accountPasswordChanged =>
      'Password changed. Sign in again on other devices.';

  @override
  String get accountPasswordChangeError => 'Could not change password';

  @override
  String get accountChangePassword => 'Change password';

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
  String get levelNew => 'Beginner';

  @override
  String get levelRegular => 'Regular';

  @override
  String get levelContributor => 'Contributor';

  @override
  String get levelVeteran => 'Veteran';

  @override
  String get levelNextLabel => 'Next level';

  @override
  String levelPointsLeft(int count) {
    return '$count pts remaining';
  }

  @override
  String get levelMaxReached => '🏄 Max level!';

  @override
  String get statReports => 'Reports';

  @override
  String get statStreak => 'Streak';

  @override
  String get statAccuracy => 'Accuracy';

  @override
  String get guestBannerTitle => 'You are in guest mode';

  @override
  String get achievementsTitle => 'Achievements';

  @override
  String get achievementFirstReport => 'First Wave';

  @override
  String get achievementTideWatcher => 'Tide Guardian';

  @override
  String get achievement10Reports => '10 Reports';

  @override
  String get achievementAccurate => 'Accurate';

  @override
  String get achievementStreak10 => '10 Days';

  @override
  String get achievementRegular => 'Regular';

  @override
  String get achievementContributor => 'Contributor';

  @override
  String get achievementVeteran => 'Veteran';

  @override
  String get recentActivityTitle => 'Recent Activity';

  @override
  String get eventReportSubmitted => 'Report submitted';

  @override
  String get eventFirstReportBonus => 'First report!';

  @override
  String get eventReportConfirmed => 'Report confirmed by the community';

  @override
  String get eventReportContradicted => 'Report rejected by the community';

  @override
  String get eventFlagConfirmed => 'Flag proposal confirmed';

  @override
  String get eventFlagContradicted => 'Flag proposal rejected';

  @override
  String get eventConfirmationAccurate => 'Accurate confirmation';

  @override
  String eventConfirmationContradicted(String color) {
    return 'Accurate confirmation — $color flag contradicted';
  }

  @override
  String eventConfirmationVerified(String color) {
    return 'Accurate confirmation — $color flag verified';
  }

  @override
  String get eventSpamPenalty => 'Spam penalty';

  @override
  String get settingsAccountTitle => 'Account Settings';

  @override
  String get settingsFavouritesTitle => 'Favourite Beaches';

  @override
  String get settingsPrivacyTitle => 'Privacy & Data';

  @override
  String get settingsAboutTitle => 'About OndaCerta';

  @override
  String get signOut => 'Sign Out';

  @override
  String get signOutTitle => 'Sign out?';

  @override
  String get signOutBody =>
      'Are you sure you want to sign out of your account?';

  @override
  String get signOutCancel => 'Cancel';

  @override
  String get signOutConfirm => 'Sign out';

  @override
  String get favouritesScreenTitle => 'Favourite Beaches';

  @override
  String get favouritesSaved1 => '1 beach saved';

  @override
  String favouritesSavedN(int count) {
    return '$count beaches saved';
  }

  @override
  String get favouriteAlertSingular => 'alert';

  @override
  String get favouriteAlertPlural => 'alerts';

  @override
  String favouriteRemoveTitle(String name) {
    return 'Remove \"$name\"?';
  }

  @override
  String get favouriteRemoveBody =>
      'This beach will be removed from your favourites.';

  @override
  String get removeLabel => 'Remove';

  @override
  String get errorRemoveFavourite => 'Error removing favourite';

  @override
  String get favouritesEmptyTitle => 'No favourite beaches';

  @override
  String get favouritesEmptyHint =>
      'Open a beach and tap the heart\nto save it here.';

  @override
  String get errorLoadFavourites => 'Error loading favourites';

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
  String get activityLabelUnverified => 'Unverified';

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

  @override
  String get transportScreenTitle => 'Transport';

  @override
  String get transportFlagNoInfo => 'No info';

  @override
  String transportWavesLabel(String height) {
    return '${height}m waves';
  }

  @override
  String get transportArrivingSoon => 'Arriving';

  @override
  String get transportNextDeparturesSection => 'NEXT DEPARTURES';

  @override
  String transportWalkMins(int mins) {
    return '$mins min walk to beach';
  }

  @override
  String transportNextDep(String time) {
    return 'Next: $time';
  }

  @override
  String transportWalkTo(String beach) {
    return 'Walk to $beach';
  }

  @override
  String transportWalkToMins(String beach, int mins) {
    return 'Walk to $beach ($mins min)';
  }

  @override
  String transportWalkToMinsFromStop(String beach, int mins) {
    return 'Walk to $beach ($mins min from stop)';
  }

  @override
  String get transportDisclaimerLive =>
      'Carris Metropolitana schedules. Real-time data when available — check at stops.';

  @override
  String get transportDisclaimerCache =>
      'Carris Metropolitana schedules. Cached data — check at stops.';

  @override
  String get transportEmpty => 'No transport available\nfor this beach';

  @override
  String get transportLoadError => 'Could not load transport';

  @override
  String get emailNameEmpty => 'Enter your name';

  @override
  String get emailEmpty => 'Enter your email';

  @override
  String get emailInvalidSimple => 'Invalid email';

  @override
  String get emailAlreadyRegisteredTitle => 'Email already registered';

  @override
  String get emailAlreadyRegisteredBody =>
      'This email already has an account. Sign in with your password.';

  @override
  String get emailRegisterError => 'Error creating account. Check the details.';

  @override
  String get emailLoginError => 'Incorrect email or password.';

  @override
  String get connectionError => 'Connection error. Try again.';

  @override
  String get emailAlreadyHaveAccount => 'Already have an account? ';

  @override
  String get emailNoAccountYet => 'Don\'t have an account yet? ';

  @override
  String get flagColorGreen => 'green';

  @override
  String get flagColorYellow => 'yellow';

  @override
  String get flagColorRed => 'red';

  @override
  String get flagColorPurple => 'purple';

  @override
  String get flagColorGreenCap => 'Green';

  @override
  String get flagColorYellowCap => 'Yellow';

  @override
  String get flagColorRedCap => 'Red';

  @override
  String get flagColorPurpleCap => 'Purple';

  @override
  String get flagProposeTitle => 'Propose Flag';

  @override
  String get flagProposeRequirement =>
      'You must be at the beach and have reputation ≥ 25 to propose.';

  @override
  String get flagProposeQuestion => 'What is the current flag?';

  @override
  String get flagProposeDescGreen => 'Safe to swim';

  @override
  String get flagProposeDescYellow => 'Swim with caution';

  @override
  String get flagProposeDescRed => 'Swimming prohibited';

  @override
  String get flagProposeDescPurple => 'Marine animals present';

  @override
  String get flagProposeNoRep =>
      'You don\'t have enough reputation yet (minimum: 25). Keep contributing with alerts and confirmations!';

  @override
  String get flagProposeNotPresent =>
      'You must be at the beach (within the last 10 min) to propose a flag.';

  @override
  String get flagProposeUnavailable =>
      'This beach does not have a physical flag system.';

  @override
  String get flagProposeGenericError => 'Something went wrong. Try again.';

  @override
  String flagProposeSubmit(String color) {
    return 'Propose $color flag';
  }

  @override
  String get flagProposeSuccessApplied => 'Flag updated!';

  @override
  String get flagProposeSuccessPending => 'Proposal submitted!';

  @override
  String get flagProposeSuccessBodyApplied =>
      'Your reputation gave you authority to apply the flag directly.';

  @override
  String get flagProposeSuccessBodyPending =>
      'The community will confirm your proposal soon.';

  @override
  String flagProposeFlagLabel(String color) {
    return '$color flag';
  }

  @override
  String get flagConfirmQuestionPrefix => 'Is the flag still ';

  @override
  String get flagConfirmQuestionSuffix => '?';

  @override
  String get flagConfirmYesPrefix => 'Yes, still ';

  @override
  String get flagConfirmNo => 'No, it changed';

  @override
  String get flagConfirmUnsure => 'Not sure';

  @override
  String get flagConfirmRateLimited =>
      'You already confirmed this beach\'s flag in the last hour.';

  @override
  String get flagConfirmError => 'Something went wrong. Try again.';

  @override
  String get flagConfirmThankYou => 'Thank you!';

  @override
  String get flagConfirmSuccessBody =>
      'Your confirmation helps the community\nstay well informed.';

  @override
  String get communityConfidence => 'Community confidence';

  @override
  String confidencePercent(int pct) {
    return '$pct% confidence';
  }

  @override
  String confidencePercentShort(int pct) {
    return '$pct% confidence';
  }

  @override
  String get flagNameGreen => 'Green Flag';

  @override
  String get flagNameYellow => 'Yellow Flag';

  @override
  String get flagNameRed => 'Red Flag';

  @override
  String get flagNamePurple => 'Purple Flag';

  @override
  String get flagNameUnknown => 'Unknown Status';

  @override
  String get flagSafetyGreen => 'Safe to swim';

  @override
  String get flagSafetyYellow => 'Swim with caution';

  @override
  String get flagSafetyRed => 'Swimming prohibited';

  @override
  String get flagSafetyPurple => 'Marine animals present';

  @override
  String get flagSafetyUnknown => 'Unknown status';

  @override
  String confidencePct(int pct) {
    return '$pct% conf.';
  }

  @override
  String get atTimePrep => 'at';

  @override
  String get forgotPasswordTitle => 'Reset password';

  @override
  String get forgotPasswordBody =>
      'Enter your email. We\'ll send a 6-digit code so you can set a new password.';

  @override
  String get forgotPasswordSubmit => 'Send code';

  @override
  String get forgotPasswordSendError => 'Error sending the code. Try again.';

  @override
  String get emailVerifyTitle => 'Confirm your email';

  @override
  String get emailVerifyBody =>
      'We sent a 6-digit code to your email.\nEnter the code below to continue.';

  @override
  String get emailVerifyButton => 'Verify';

  @override
  String get emailVerifyCodeInvalid => 'Invalid code. Try again.';

  @override
  String get resetCodeTitle => 'Check your email';

  @override
  String resetCodeBody(String email) {
    return 'We sent a 6-digit code to $email.';
  }

  @override
  String get resetCodeContinue => 'Continue';

  @override
  String get resetNewPasswordTitle => 'New password';

  @override
  String get resetNewPasswordBody => 'Choose a new password for your account.';

  @override
  String get resetNewPasswordConfirmLabel => 'Confirm password';

  @override
  String get resetNewPasswordSubmit => 'Change password';

  @override
  String get resetPasswordSuccessTitle => 'Password changed!';

  @override
  String get resetPasswordSuccessBody =>
      'Your password has been updated successfully.\nYou can sign in with your new password.';

  @override
  String get resetPasswordError => 'Error changing password. Try again.';

  @override
  String get codeResend => 'Resend code';

  @override
  String codeResendCooldown(int secs) {
    return 'Resend code (${secs}s)';
  }

  @override
  String codeResendShortCooldown(int secs) {
    return 'Resend (${secs}s)';
  }

  @override
  String get codeSentSnack => 'New code sent to your email.';

  @override
  String get codeResendError => 'Error resending the code.';

  @override
  String get codeConfirmEmpty => 'Confirm the new password';

  @override
  String get accountBannedTitle => 'Account banned';

  @override
  String get accountBannedBody =>
      'Your account has been permanently banned for violating community rules.';

  @override
  String accountBannedBodyReason(String reason) {
    return 'Your account has been permanently banned for violating community rules.\n\nReason: $reason';
  }

  @override
  String get accountSuspendedTitle => 'Account suspended';

  @override
  String get accountSuspendedBody =>
      'Your account is temporarily suspended.\n\nYou can still view beaches.';

  @override
  String accountSuspendedBodyUntil(String date) {
    return 'Your account is temporarily suspended until $date.\n\nYou can still view beaches. You can contribute again after that period.';
  }

  @override
  String get passwordEmpty => 'Enter password';

  @override
  String get passwordMinLength => 'Minimum 8 characters';

  @override
  String get passwordNeedsUppercase => 'Needs an uppercase letter';

  @override
  String get passwordNeedsLowercase => 'Needs a lowercase letter';

  @override
  String get passwordNeedsDigitOrSpecial =>
      'Needs a digit or special character';

  @override
  String get passwordStrengthWeak => 'Weak';

  @override
  String get passwordStrengthFair => 'Fair';

  @override
  String get passwordStrengthGood => 'Good';

  @override
  String get passwordStrengthStrong => 'Strong';

  @override
  String get passwordReq8Chars => '8+ characters';

  @override
  String get passwordReqUppercase => 'Uppercase letter (A–Z)';

  @override
  String get passwordReqLowercase => 'Lowercase letter (a–z)';

  @override
  String get passwordReqDigitOrSpecial => 'Digit or special character';
}

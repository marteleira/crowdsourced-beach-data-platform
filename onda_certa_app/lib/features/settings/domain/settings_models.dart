class PrivacySettings {
  const PrivacySettings({
    this.namePublic = true,
    this.avatarPublic = true,
    this.sharePresence = false,
  });
  final bool namePublic;
  final bool avatarPublic;
  final bool sharePresence;

  factory PrivacySettings.fromJson(Map<String, dynamic> j) => PrivacySettings(
    namePublic: j['name_public'] as bool? ?? true,
    avatarPublic: j['avatar_public'] as bool? ?? true,
    sharePresence: j['share_presence'] as bool? ?? false,
  );

  PrivacySettings copyWith({
    bool? namePublic,
    bool? avatarPublic,
    bool? sharePresence,
  }) => PrivacySettings(
    namePublic: namePublic ?? this.namePublic,
    avatarPublic: avatarPublic ?? this.avatarPublic,
    sharePresence: sharePresence ?? this.sharePresence,
  );
}

class NotificationAlertTypes {
  const NotificationAlertTypes({
    this.jellyfish = true,
    this.strongCurrent = true,
    this.pollution = true,
    this.roughSea = true,
  });
  final bool jellyfish;
  final bool strongCurrent;
  final bool pollution;
  final bool roughSea;

  factory NotificationAlertTypes.fromJson(Map<String, dynamic> j) =>
      NotificationAlertTypes(
        jellyfish: j['jellyfish'] as bool? ?? true,
        strongCurrent: j['strong_current'] as bool? ?? true,
        pollution: j['pollution'] as bool? ?? true,
        roughSea: j['rough_sea'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
    'jellyfish': jellyfish,
    'strong_current': strongCurrent,
    'pollution': pollution,
    'rough_sea': roughSea,
  };

  NotificationAlertTypes copyWith({
    bool? jellyfish,
    bool? strongCurrent,
    bool? pollution,
    bool? roughSea,
  }) => NotificationAlertTypes(
    jellyfish: jellyfish ?? this.jellyfish,
    strongCurrent: strongCurrent ?? this.strongCurrent,
    pollution: pollution ?? this.pollution,
    roughSea: roughSea ?? this.roughSea,
  );
}

class NotificationSettings {
  const NotificationSettings({
    this.globalEnabled = true,
    this.checkinAlerts = true,
    this.favouriteAlertsEnabled = true,
    this.alertTypes = const NotificationAlertTypes(),
    this.minSeverity = 1,
    this.flagChangeAlerts = true,
    this.tideAlerts = true,
    this.quietHoursEnabled = false,
    this.quietHoursStart = '22:00',
    this.quietHoursEnd = '07:00',
  });
  final bool globalEnabled;
  final bool checkinAlerts;
  final bool favouriteAlertsEnabled;
  final NotificationAlertTypes alertTypes;
  final int minSeverity; // 1 | 2 | 3
  final bool flagChangeAlerts;
  final bool tideAlerts;
  final bool quietHoursEnabled;
  final String quietHoursStart;
  final String quietHoursEnd;

  factory NotificationSettings.fromJson(Map<String, dynamic> j) =>
      NotificationSettings(
        globalEnabled: j['global_enabled'] as bool? ?? true,
        checkinAlerts: j['checkin_alerts'] as bool? ?? true,
        favouriteAlertsEnabled: j['favourite_alerts_enabled'] as bool? ?? true,
        alertTypes: j['alert_types'] != null
            ? NotificationAlertTypes.fromJson(
                j['alert_types'] as Map<String, dynamic>)
            : const NotificationAlertTypes(),
        minSeverity: j['min_severity'] as int? ?? 1,
        flagChangeAlerts: j['flag_change_alerts'] as bool? ?? true,
        tideAlerts: j['tide_alerts'] as bool? ?? true,
        quietHoursEnabled: j['quiet_hours_enabled'] as bool? ?? false,
        quietHoursStart: j['quiet_hours_start'] as String? ?? '22:00',
        quietHoursEnd: j['quiet_hours_end'] as String? ?? '07:00',
      );

  NotificationSettings copyWith({
    bool? globalEnabled,
    bool? checkinAlerts,
    bool? favouriteAlertsEnabled,
    NotificationAlertTypes? alertTypes,
    int? minSeverity,
    bool? flagChangeAlerts,
    bool? tideAlerts,
    bool? quietHoursEnabled,
    String? quietHoursStart,
    String? quietHoursEnd,
  }) => NotificationSettings(
    globalEnabled: globalEnabled ?? this.globalEnabled,
    checkinAlerts: checkinAlerts ?? this.checkinAlerts,
    favouriteAlertsEnabled: favouriteAlertsEnabled ?? this.favouriteAlertsEnabled,
    alertTypes: alertTypes ?? this.alertTypes,
    minSeverity: minSeverity ?? this.minSeverity,
    flagChangeAlerts: flagChangeAlerts ?? this.flagChangeAlerts,
    tideAlerts: tideAlerts ?? this.tideAlerts,
    quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
    quietHoursStart: quietHoursStart ?? this.quietHoursStart,
    quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
  );
}

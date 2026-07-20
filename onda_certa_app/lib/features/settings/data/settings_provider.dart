import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/auth_provider.dart';
import '../domain/settings_models.dart';
import 'settings_repository.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref.read(dioProvider));
});

// Privacy

final privacySettingsProvider =
    AsyncNotifierProvider<PrivacySettingsNotifier, PrivacySettings>(
  PrivacySettingsNotifier.new,
);

class PrivacySettingsNotifier extends AsyncNotifier<PrivacySettings> {
  @override
  Future<PrivacySettings> build() =>
      ref.read(settingsRepositoryProvider).getPrivacySettings();

  Future<void> patch(Map<String, dynamic> changes) async {
    final previous = state.value;
    if (previous != null) {
      state = AsyncData(_apply(previous, changes));
    }
    try {
      final updated = await ref
          .read(settingsRepositoryProvider)
          .patchPrivacySettings(changes);
      state = AsyncData(updated);
    } catch (e, st) {
      if (previous != null) state = AsyncData(previous);
      state = AsyncError(e, st);
    }
  }

  PrivacySettings _apply(PrivacySettings p, Map<String, dynamic> c) =>
      p.copyWith(
        namePublic: c['name_public'] as bool?,
        avatarPublic: c['avatar_public'] as bool?,
        sharePresence: c['share_presence'] as bool?,
      );
}

// Notifications

final notificationSettingsProvider =
    AsyncNotifierProvider<NotificationSettingsNotifier, NotificationSettings>(
  NotificationSettingsNotifier.new,
);

class NotificationSettingsNotifier extends AsyncNotifier<NotificationSettings> {
  @override
  Future<NotificationSettings> build() =>
      ref.read(settingsRepositoryProvider).getNotificationSettings();

  Future<void> patch(Map<String, dynamic> changes) async {
    final previous = state.value;
    if (previous != null) {
      state = AsyncData(_apply(previous, changes));
    }
    try {
      final updated = await ref
          .read(settingsRepositoryProvider)
          .patchNotificationSettings(changes);
      state = AsyncData(updated);
    } catch (e, st) {
      if (previous != null) state = AsyncData(previous);
      state = AsyncError(e, st);
    }
  }

  NotificationSettings _apply(NotificationSettings s, Map<String, dynamic> c) {
    final types = c['alert_types'] as Map<String, dynamic>?;
    return s.copyWith(
      globalEnabled: c['global_enabled'] as bool?,
      checkinAlerts: c['checkin_alerts'] as bool?,
      favouriteAlertsEnabled: c['favourite_alerts_enabled'] as bool?,
      alertTypes: types != null
          ? NotificationAlertTypes.fromJson(types)
          : null,
      minSeverity: c['min_severity'] as int?,
      flagChangeAlerts: c['flag_change_alerts'] as bool?,
      tideAlerts: c['tide_alerts'] as bool?,
      quietHoursEnabled: c['quiet_hours_enabled'] as bool?,
      quietHoursStart: c['quiet_hours_start'] as String?,
      quietHoursEnd: c['quiet_hours_end'] as String?,
    );
  }
}

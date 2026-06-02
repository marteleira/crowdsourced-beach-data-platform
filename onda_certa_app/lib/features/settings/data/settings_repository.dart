import 'package:dio/dio.dart';
import '../domain/settings_models.dart';

class SettingsRepository {
  const SettingsRepository(this._dio);
  final Dio _dio;

  Future<PrivacySettings> getPrivacySettings() async {
    final res = await _dio.get('/users/me/privacy-settings');
    return PrivacySettings.fromJson(res.data as Map<String, dynamic>);
  }

  Future<PrivacySettings> patchPrivacySettings(Map<String, dynamic> patch) async {
    final res = await _dio.patch('/users/me/privacy-settings', data: patch);
    return PrivacySettings.fromJson(res.data as Map<String, dynamic>);
  }

  Future<NotificationSettings> getNotificationSettings() async {
    final res = await _dio.get('/users/me/notification-settings');
    return NotificationSettings.fromJson(res.data as Map<String, dynamic>);
  }

  Future<NotificationSettings> patchNotificationSettings(Map<String, dynamic> patch) async {
    final res = await _dio.patch('/users/me/notification-settings', data: patch);
    return NotificationSettings.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> deleteAllReports() async {
    await _dio.delete('/users/me/reports');
  }

  Future<DateTime> deleteAccount() async {
    final res = await _dio.delete('/users/me', data: {'confirmation': 'APAGAR'});
    final raw = res.data['scheduled_deletion_at'] as String;
    return DateTime.parse(raw);
  }

  Future<void> cancelDeletion() async {
    await _dio.post('/users/me/cancel-deletion');
  }
}

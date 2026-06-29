import 'dart:io';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Handles FCM token registration and incoming push notifications
///
/// Call [init] once at app startup (after Firebase.initializeApp)
/// Call [registerToken] after the user logs in.
/// Call [unregisterToken] on logout
class FcmService {
  FcmService(this._dio);

  final Dio _dio;
  final _messaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();

  String? _currentToken;

  Future<void> init() async {
    await _setupLocalNotifications();
    await _requestPermission();
    _setupForegroundHandler();

    try {
      _currentToken = await _messaging.getToken();
      _messaging.onTokenRefresh.listen((newToken) {
        _currentToken = newToken;
        _sendTokenToBackend(newToken);
      });
    } catch (e) {
      debugPrint('FCM unavailable: $e');
    }
  }


  /// Call after every successful login so the token is linked to the account
  Future<void> registerToken() async {
    try {
      final token = _currentToken ?? await _messaging.getToken();
      if (token != null) {
        _currentToken = token;
        await _sendTokenToBackend(token);
      }
    } catch (e) {
      debugPrint('FCM token registration failed: $e');
    }
  }

  /// Call on logout to unlink the token from the account
  Future<void> unregisterToken() async {
    final token = _currentToken;
    if (token == null) return;
    try {
      await _dio.delete('/notifications/token/$token');
    } catch (_) {}
  }

  Future<void> _sendTokenToBackend(String token) async {
    try {
      await _dio.post('/notifications/register-token', data: {
        'token': token,
        'platform': Platform.isIOS ? 'ios' : 'android',
      });
      
      debugPrint('FCM token registered with backend');
    } on DioException catch (e) {
      debugPrint('Failed to register FCM token: ${e.message}');
    }
  }

  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint('FCM permission: ${settings.authorizationStatus}');
  }

  void _setupForegroundHandler() {
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification == null) return;

      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'onda_certa_alerts',
            'Alertas de Praia',
            channelDescription: 'Avisos e mudanças de bandeira nas praias',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
      );
    });
  }

  Future<void> _setupLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iOS = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(android: android, iOS: iOS),
    );

    // Create the notification channel on Android
    const channel = AndroidNotificationChannel(
      'onda_certa_alerts',
      'Alertas de Praia',
      description: 'Avisos e mudanças de bandeira nas praias',
      importance: Importance.high,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }
}

import 'dart:io' show Platform;
import 'package:dio/dio.dart';
import 'package:intl/intl.dart' show Intl;
import '../storage/secure_storage.dart';
import 'auth_interceptor.dart';

// Override with: flutter run --dart-define=API_HOST=192.168.1.221
// Default 10.0.2.2 works on Android emulator (alias for the host machine)
// When changing the ip, don't forget to update android/app/src/main/res/xml/network_security_config.xml
// Note: when using real devices run the server with: --host 0.0.0.0 to allow incoming connections from the local network

const _kApiScheme = String.fromEnvironment('API_SCHEME', defaultValue: 'http');
const _kApiHost = String.fromEnvironment('API_HOST', defaultValue: '10.0.2.2');
const _kBaseUrl = '$_kApiScheme://$_kApiHost/api/v1';

/// Root of the server — use this to resolve root-relative paths like /static/...
const kServerBaseUrl = '$_kApiScheme://$_kApiHost';

/// Injects Accept-Language on every request so the backend can respond
/// (and send push notifications) in the user's current locale.
class _LanguageInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Intl.defaultLocale is set by Flutter's localization system at startup.
    // Falls back to the OS locale (e.g. "pt_PT" → "pt").
    final locale =
        (Intl.defaultLocale ?? Platform.localeName).split('_').first;
    options.headers['Accept-Language'] = locale;
    handler.next(options);
  }
}

Dio createDio(
  SecureStorage storage, {
  void Function(DateTime)? onPendingDeletion,
  void Function(String? banReason)? onBanned,
  void Function(DateTime suspendedUntil)? onSuspended,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: _kBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ),
  );
  dio.interceptors.addAll([
    _LanguageInterceptor(),
    AuthInterceptor(
      dio,
      storage,
      onPendingDeletion: onPendingDeletion,
      onBanned: onBanned,
      onSuspended: onSuspended,
    ),
  ]);
  return dio;
}

import 'package:dio/dio.dart';
import '../storage/secure_storage.dart';
import 'auth_interceptor.dart';

// Override with: flutter run --dart-define=API_HOST=192.168.1.221
// Default 10.0.2.2 works on Android emulator (alias for the host machine)
// When changing the ip, don't forget to update android/app/src/main/res/xml/network_security_config.xml
// Note: when using real devices run the server with: --host 0.0.0.0 to allow incoming connections from the local network
const _kApiHost = String.fromEnvironment('API_HOST', defaultValue: '10.0.2.2');
const _kBaseUrl = 'http://$_kApiHost:8000/api/v1';

Dio createDio(
  SecureStorage storage, {
  void Function(DateTime)? onPendingDeletion,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: _kBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ),
  );
  dio.interceptors.add(
    AuthInterceptor(dio, storage, onPendingDeletion: onPendingDeletion),
  );
  return dio;
}

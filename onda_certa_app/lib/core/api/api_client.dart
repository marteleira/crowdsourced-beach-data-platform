import 'package:dio/dio.dart';
import '../storage/secure_storage.dart';
import 'auth_interceptor.dart';

const _kBaseUrlDev = 'http://10.0.2.2:8000/api/v1';

Dio createDio(
  SecureStorage storage, {
  void Function(DateTime)? onPendingDeletion,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: _kBaseUrlDev,
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

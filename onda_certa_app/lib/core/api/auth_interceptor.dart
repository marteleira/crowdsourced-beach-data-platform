import 'package:dio/dio.dart';
import '../storage/secure_storage.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._dio, this._storage);

  final Dio _dio;
  final SecureStorage _storage;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Break the refresh loop: if this 401 came from the refresh call itself,
    // clear tokens and let the error propagate — no retry.
    if (err.requestOptions.extra['skipAuthInterceptor'] == true) {
      await _storage.clearTokens();
      return handler.next(err);
    }

    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    final refreshToken = await _storage.getRefreshToken();
    if (refreshToken == null) {
      await _storage.clearTokens();
      return handler.next(err);
    }

    try {
      final response = await _dio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
        options: Options(extra: {'skipAuthInterceptor': true}),
      );

      final newAccess = response.data['access_token'] as String;
      final newRefresh = response.data['refresh_token'] as String;
      final isAnon = response.data['is_anonymous'] as bool? ?? false;

      await _storage.saveTokens(
        accessToken: newAccess,
        refreshToken: newRefresh,
        isAnonymous: isAnon,
      );

      final retried = await _dio.fetch(
        err.requestOptions..headers['Authorization'] = 'Bearer $newAccess',
      );
      return handler.resolve(retried);
    } on DioException {
      await _storage.clearTokens();
      return handler.next(err);
    }
  }
}

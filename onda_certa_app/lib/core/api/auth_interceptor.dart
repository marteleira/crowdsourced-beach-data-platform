import 'package:dio/dio.dart';
import '../storage/secure_storage.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(
    this._dio,
    this._storage, {
    this.onPendingDeletion,
    this.onBanned,
    this.onSuspended,
  });

  final Dio _dio;
  final SecureStorage _storage;
  final void Function(DateTime scheduledAt)? onPendingDeletion;
  final void Function(String? banReason)? onBanned;
  final void Function(DateTime suspendedUntil)? onSuspended;

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

    if (err.response?.statusCode == 403) {
      final detail = err.response?.data?['detail'];
      if (detail is Map) {
        final code = detail['code'] as String?;
        if (code == 'account_pending_deletion') {
          final raw = detail['scheduled_deletion_at'] as String?;
          if (raw != null && onPendingDeletion != null) {
            onPendingDeletion!(DateTime.parse(raw));
          }
        } else if (code == 'account_banned') {
          await _storage.clearTokens();
          onBanned?.call(detail['ban_reason'] as String?);
        } else if (code == 'account_suspended') {
          final raw = detail['suspended_until'] as String?;
          if (raw != null) onSuspended?.call(DateTime.parse(raw));
        }
      }
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
      final isEmailVerified = response.data['is_email_verified'] as bool? ?? false;

      await _storage.saveTokens(
        accessToken: newAccess,
        refreshToken: newRefresh,
        isAnonymous: isAnon,
        isEmailVerified: isEmailVerified,
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

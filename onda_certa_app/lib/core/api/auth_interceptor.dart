import 'dart:async';
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

  // Prevents concurrent refresh calls: while one refresh is in flight,
  // subsequent 401s wait for its result instead of making their own call.
  Completer<String>? _refreshCompleter;

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
          // ban_reason is a stable code (e.g. "reputation_below_threshold"), not
          // display text - ban_reason_message is the backend's already-localized
          // rendering of it (see app.core.deps.raise_if_account_locked).
          onBanned?.call(detail['ban_reason_message'] as String?);
          // Swallow the error — router will redirect to ban screen
          return handler.reject(DioException(
            requestOptions: err.requestOptions,
            type: DioExceptionType.cancel,
          ));
        } else if (code == 'account_suspended') {
          final raw = detail['suspended_until'] as String?;
          if (raw != null) onSuspended?.call(DateTime.parse(raw));
          // Swallow the error — router will redirect to suspended screen
          return handler.reject(DioException(
            requestOptions: err.requestOptions,
            type: DioExceptionType.cancel,
          ));
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

    final String newToken;

    if (_refreshCompleter != null) {
      // Another refresh is already in flight — wait for its result.
      try {
        newToken = await _refreshCompleter!.future;
      } on DioException {
        return handler.next(err);
      }
    } else {
      _refreshCompleter = Completer<String>();
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

        _refreshCompleter!.complete(newAccess);
        newToken = newAccess;
      } on DioException catch (e) {
        _refreshCompleter!.completeError(e);
        await _storage.clearTokens();
        return handler.next(err);
      } finally {
        _refreshCompleter = null;
      }
    }

    try {
      final retried = await _dio.fetch(
        err.requestOptions..headers['Authorization'] = 'Bearer $newToken',
      );
      return handler.resolve(retried);
    } on DioException {
      // Refresh succeeded — tokens are valid, only this retry failed.
      return handler.next(err);
    }
  }
}

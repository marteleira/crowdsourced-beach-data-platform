import 'package:dio/dio.dart';
import '../l10n/l10n.dart';

/// Parsed shape of a backend error `detail`: always a structured
/// `{"code": ..., "message": ...}` envelope (app/core/errors.py::api_error).
/// `message` is the backend's own rendering in the user's language - a safe
/// fallback, but never as tailored as the app's own copy. Prefer
/// [displayMessage] over reading `.message` directly.
class ApiError {
  const ApiError({this.code, required this.message});

  final String? code;
  final String message;
}

ApiError? parseApiError(DioException e, {String? fallback}) {
  final data = e.response?.data;
  final detail = data is Map ? data['detail'] : null;
  if (detail is Map) {
    return ApiError(
      code: detail['code'] as String?,
      message: detail['message'] as String? ?? fallback ?? '',
    );
  }
  if (detail is String) {
    return ApiError(message: detail);
  }
  return fallback != null ? ApiError(message: fallback) : null;
}

/// Resolves display text purely from `error.code`, one case per backend code
/// the app has tailored copy for. Returns null for an unmapped code so the
/// caller can fall back to its own generic per-action message - `error.message`
/// (the backend's own rendering) should only ever be shown as a last resort,
/// since it's correct but generic, never as good as the app's own copy.
String? displayMessage(AppLocalizations l10n, ApiError? error) => switch (error?.code) {
  'email_taken' => l10n.emailAlreadyRegisteredBody,
  'invalid_credentials' => l10n.emailLoginError,
  _ => null,
};

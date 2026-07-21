import 'package:dio/dio.dart';

/// Parsed shape of a backend error `detail`, which is either a structured
/// `{"code": ..., "message": ...}` envelope or (for endpoints not yet
/// migrated) a plain PT message string.
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

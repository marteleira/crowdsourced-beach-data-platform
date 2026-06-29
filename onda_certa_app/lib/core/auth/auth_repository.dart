import 'package:dio/dio.dart';

class TokenResponse {
  const TokenResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
    required this.isAnonymous,
    required this.isEmailVerified,
  });

  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresIn;
  final bool isAnonymous;
  final bool isEmailVerified;

  factory TokenResponse.fromJson(Map<String, dynamic> json) => TokenResponse(
        accessToken: json['access_token'] as String,
        refreshToken: json['refresh_token'] as String,
        tokenType: json['token_type'] as String,
        expiresIn: json['expires_in'] as int,
        isAnonymous: json['is_anonymous'] as bool? ?? false,
        isEmailVerified: json['is_email_verified'] as bool? ?? false,
      );
}

class AuthRepository {
  const AuthRepository(this._dio);

  final Dio _dio;

  Future<TokenResponse> loginWithGoogle(String idToken) async {
    final res = await _dio.post(
      '/auth/google',
      data: {'id_token': idToken},
      options: Options(extra: {'skipAuthInterceptor': true}),
    );
    return TokenResponse.fromJson(res.data as Map<String, dynamic>);
  }

  Future<TokenResponse> registerWithEmail(
    String email,
    String password,
    String displayName,
  ) async {
    final res = await _dio.post(
      '/auth/register',
      data: {
        'email': email,
        'password': password,
        'display_name': displayName,
      },
      options: Options(extra: {'skipAuthInterceptor': true}),
    );
    return TokenResponse.fromJson(res.data as Map<String, dynamic>);
  }

  Future<TokenResponse> loginWithEmail(String email, String password) async {
    final res = await _dio.post(
      '/auth/login',
      data: {'email': email, 'password': password},
      options: Options(extra: {'skipAuthInterceptor': true}),
    );
    return TokenResponse.fromJson(res.data as Map<String, dynamic>);
  }

  Future<TokenResponse> loginAsGuest(String deviceId) async {
    final res = await _dio.post('/auth/guest', data: {'device_id': deviceId});
    return TokenResponse.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> logout(String refreshToken) async {
    await _dio.post('/auth/logout', data: {'refresh_token': refreshToken});
  }

  Future<TokenResponse> refresh(String refreshToken) async {
    final res = await _dio.post(
      '/auth/refresh',
      data: {'refresh_token': refreshToken},
      options: Options(extra: {'skipAuthInterceptor': true}),
    );
    return TokenResponse.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> verifyEmail(String code) async {
    await _dio.post('/auth/verify-email', data: {'code': code});
  }

  Future<void> resendVerification() async {
    await _dio.post('/auth/resend-verification');
  }

  Future<void> forgotPassword(String email) async {
    await _dio.post(
      '/auth/forgot-password',
      data: {'email': email},
      options: Options(extra: {'skipAuthInterceptor': true}),
    );
  }

  Future<void> resetPassword(String email, String code, String newPassword) async {
    await _dio.post(
      '/auth/reset-password',
      data: {'email': email, 'code': code, 'new_password': newPassword},
      options: Options(extra: {'skipAuthInterceptor': true}),
    );
  }
}

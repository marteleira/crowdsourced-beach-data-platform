import 'package:dio/dio.dart';

class TokenResponse {
  const TokenResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
    required this.isAnonymous,
  });

  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresIn;
  final bool isAnonymous;

  factory TokenResponse.fromJson(Map<String, dynamic> json) => TokenResponse(
        accessToken: json['access_token'] as String,
        refreshToken: json['refresh_token'] as String,
        tokenType: json['token_type'] as String,
        expiresIn: json['expires_in'] as int,
        isAnonymous: json['is_anonymous'] as bool? ?? false,
      );
}

class AuthRepository {
  const AuthRepository(this._dio);

  final Dio _dio;

  Future<TokenResponse> loginWithGoogle(String idToken) async {
    final res = await _dio.post('/auth/google', data: {'id_token': idToken});
    return TokenResponse.fromJson(res.data as Map<String, dynamic>);
  }

  Future<TokenResponse> loginWithEmail(String email, String password) async {
    final res = await _dio.post(
      '/auth/login',
      data: {'email': email, 'password': password},
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
}

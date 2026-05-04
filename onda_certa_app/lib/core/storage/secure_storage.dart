import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage();

  static const _kAccessToken = 'access_token';
  static const _kRefreshToken = 'refresh_token';
  static const _kIsAnonymous = 'is_anonymous';

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    bool isAnonymous = false,
  }) async {
    await Future.wait([
      _storage.write(key: _kAccessToken, value: accessToken),
      _storage.write(key: _kRefreshToken, value: refreshToken),
      _storage.write(key: _kIsAnonymous, value: isAnonymous.toString()),
    ]);
  }

  Future<String?> getAccessToken() => _storage.read(key: _kAccessToken);
  Future<String?> getRefreshToken() => _storage.read(key: _kRefreshToken);
  Future<bool> getIsAnonymous() async {
    final v = await _storage.read(key: _kIsAnonymous);
    return v == 'true';
  }

  Future<void> clearTokens() => _storage.deleteAll();
}

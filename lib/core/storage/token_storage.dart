import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 접근 토큰·갱신 토큰 보안 저장소.
class TokenStorage {
  const TokenStorage();

  static const _accessTokenKey = 'angela_access_token';
  static const _refreshTokenKey = 'angela_refresh_token';
  static const _storage = FlutterSecureStorage();

  Future<void> saveAccessToken(String token) =>
      _storage.write(key: _accessTokenKey, value: token);

  Future<String?> readAccessToken() => _storage.read(key: _accessTokenKey);

  Future<void> saveRefreshToken(String token) =>
      _storage.write(key: _refreshTokenKey, value: token);

  Future<String?> readRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    await saveAccessToken(accessToken);
    await saveRefreshToken(refreshToken);
  }

  Future<void> clear() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }
}

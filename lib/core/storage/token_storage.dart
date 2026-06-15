import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 액세스 토큰 보안 저장소.
class TokenStorage {
  const TokenStorage();

  static const _accessTokenKey = 'angela_access_token';
  static const _storage = FlutterSecureStorage();

  Future<void> saveAccessToken(String token) =>
      _storage.write(key: _accessTokenKey, value: token);

  Future<String?> readAccessToken() => _storage.read(key: _accessTokenKey);

  Future<void> clear() => _storage.delete(key: _accessTokenKey);
}

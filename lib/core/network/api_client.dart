import 'dart:convert';

import 'package:http/http.dart' as http;

import '../auth/auth_session.dart';
import '../config/app_config.dart';
import '../presidium/current_presidium.dart';

/// 서버가 돌려준 오류. [message] 는 화면에 그대로 보여줄 수 있는 문구다.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// 로그인 토큰을 붙여 AngelaCore API 를 호출한다. 응답 본문은 JSON 으로 해석해 돌려준다.
/// 접근 토큰이 만료됐거나 서버가 401 을 돌려주면 갱신 토큰으로 새로 받아 다시 보내고,
/// 갱신도 안 되면 세션을 끝내고 로그인 화면으로 보낸다.
class ApiClient {
  const ApiClient();

  static const _expiredMessage = '로그인이 만료되었습니다. 다시 로그인해 주세요.';
  static const _offlineMessage = '서버에 연결하지 못했습니다. 네트워크 연결을 확인해 주세요.';

  Future<dynamic> get(String path) => _send('GET', path);

  Future<dynamic> post(String path, [Map<String, dynamic>? body]) =>
      _send('POST', path, body);

  Future<dynamic> put(String path, Map<String, dynamic> body) => _send('PUT', path, body);

  Future<dynamic> delete(String path) => _send('DELETE', path);

  Future<dynamic> _send(String method, String path, [Map<String, dynamic>? body]) async {
    var token = await _token(AuthSession.accessToken);
    var response = await _request(method, path, token, body);
    if (response.statusCode == 401) {
      // 서버 기준으로 만료됐으면 한 번 갱신해서 다시 보낸다.
      token = await _token(AuthSession.renewAfterUnauthorized);
      response = await _request(method, path, token, body);
      if (response.statusCode == 401) {
        await AuthSession.expire();
        throw const ApiException(_expiredMessage, statusCode: 401);
      }
    }

    final decoded = response.body.isEmpty ? null : _tryDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }
    final message = decoded is Map<String, dynamic> ? decoded['message'] as String? : null;
    throw ApiException(message ?? '요청을 처리하지 못했습니다. (${response.statusCode})',
        statusCode: response.statusCode);
  }

  /// 접근 토큰을 받는다. 다시 로그인해야 하면 (로그인 화면으로 보낸 뒤) 만료 예외.
  static Future<String> _token(Future<String?> Function() obtain) async {
    try {
      final token = await obtain();
      if (token == null) throw const ApiException(_expiredMessage, statusCode: 401);
      return token;
    } on SessionOfflineException {
      throw const ApiException(_offlineMessage);
    }
  }

  static Future<http.Response> _request(
      String method, String path, String token, Map<String, dynamic>? body) async {
    final uri = Uri.parse('${AppConfig.baseUrl}$path');
    final presidiumId = CurrentPresidium.id.value;
    final headers = {
      'Authorization': 'Bearer $token',
      if (body != null) 'Content-Type': 'application/json',
      if (presidiumId != null) CurrentPresidium.header: '$presidiumId',
    };
    try {
      final encoded = body == null ? null : jsonEncode(body);
      return switch (method) {
        'GET' => await http.get(uri, headers: headers),
        'PUT' => await http.put(uri, headers: headers, body: encoded),
        'DELETE' => await http.delete(uri, headers: headers),
        _ => await http.post(uri, headers: headers, body: encoded),
      };
    } catch (_) {
      throw const ApiException(_offlineMessage);
    }
  }

  static dynamic _tryDecode(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }
}

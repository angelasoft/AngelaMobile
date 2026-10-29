import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../storage/token_storage.dart';

/// 서버가 돌려준 오류. [message] 는 화면에 그대로 보여줄 수 있는 문구다.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// 로그인 토큰을 붙여 AngelaCore API 를 호출한다. 응답 본문은 JSON 으로 해석해 돌려준다.
class ApiClient {
  const ApiClient({TokenStorage tokenStorage = const TokenStorage()})
      : _tokenStorage = tokenStorage;

  final TokenStorage _tokenStorage;

  Future<dynamic> get(String path) => _send('GET', path);

  Future<dynamic> post(String path, [Map<String, dynamic>? body]) =>
      _send('POST', path, body);

  Future<dynamic> put(String path, Map<String, dynamic> body) => _send('PUT', path, body);

  Future<dynamic> delete(String path) => _send('DELETE', path);

  Future<dynamic> _send(String method, String path, [Map<String, dynamic>? body]) async {
    final token = await _tokenStorage.readAccessToken();
    if (token == null) {
      throw const ApiException('로그인이 필요합니다. 다시 로그인해 주세요.', statusCode: 401);
    }

    final uri = Uri.parse('${AppConfig.baseUrl}$path');
    final headers = {
      'Authorization': 'Bearer $token',
      if (body != null) 'Content-Type': 'application/json',
    };

    final http.Response response;
    try {
      final encoded = body == null ? null : jsonEncode(body);
      response = switch (method) {
        'GET' => await http.get(uri, headers: headers),
        'PUT' => await http.put(uri, headers: headers, body: encoded),
        'DELETE' => await http.delete(uri, headers: headers),
        _ => await http.post(uri, headers: headers, body: encoded),
      };
    } catch (_) {
      throw const ApiException('서버에 연결하지 못했습니다. 네트워크 연결을 확인해 주세요.');
    }

    final decoded = response.body.isEmpty ? null : _tryDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }
    if (response.statusCode == 401) {
      throw const ApiException('로그인이 만료되었습니다. 다시 로그인해 주세요.', statusCode: 401);
    }
    final message = decoded is Map<String, dynamic> ? decoded['message'] as String? : null;
    throw ApiException(message ?? '요청을 처리하지 못했습니다. (${response.statusCode})',
        statusCode: response.statusCode);
  }

  static dynamic _tryDecode(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }
}

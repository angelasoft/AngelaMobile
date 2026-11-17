import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/auth/auth_session.dart';
import '../../core/config/app_config.dart';
import 'models/curia_item.dart';
import 'models/parish_summary.dart';
import 'models/presidium_info.dart';
import 'models/presidium_item.dart';

class PresidiumServiceException implements Exception {
  const PresidiumServiceException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// 본당·쁘레시디움 조회/생성/가입 API.
class PresidiumService {
  const PresidiumService();

  static const _expiredMessage = '로그인이 만료되었습니다. 다시 로그인해 주세요.';
  static const _offlineMessage = '서버에 연결하지 못했습니다. 네트워크 연결을 확인해 주세요.';

  /// 로그인이 필요한 요청. 접근 토큰이 만료됐거나 401 이면 갱신해 한 번 더 보내고,
  /// 다시 로그인해야 하면 (로그인 화면으로 보낸 뒤) 예외를 던진다.
  Future<http.Response> _authorized(Future<http.Response> Function(Map<String, String> headers) send) async {
    var response = await send(_headers(await _token(AuthSession.accessToken)));
    if (response.statusCode == 401) {
      response = await send(_headers(await _token(AuthSession.renewAfterUnauthorized)));
      if (response.statusCode == 401) {
        await AuthSession.expire();
        throw const PresidiumServiceException(_expiredMessage);
      }
    }
    return response;
  }

  static Future<String> _token(Future<String?> Function() obtain) async {
    try {
      final token = await obtain();
      if (token == null) throw const PresidiumServiceException(_expiredMessage);
      return token;
    } on SessionOfflineException {
      throw const PresidiumServiceException(_offlineMessage);
    }
  }

  static Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Future<List<ParishSummary>> searchParishes(String query) async {
    final q = query.trim();
    if (q.isEmpty) return const [];

    final uri = Uri.parse('${AppConfig.baseUrl}/app/regions/parishes/search')
        .replace(queryParameters: {'query': q});
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw const PresidiumServiceException('본당 검색에 실패했습니다.');
    }

    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => ParishSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<PresidiumItem>> listByParish(int parishId) async {
    final uri = Uri.parse('${AppConfig.baseUrl}/app/presidiums')
        .replace(queryParameters: {'parishId': parishId.toString()});
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw const PresidiumServiceException('쁘레시디움 목록을 불러오지 못했습니다.');
    }

    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => PresidiumItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<CuriaItem>> listCurias(int parishId) async {
    final uri = Uri.parse('${AppConfig.baseUrl}/app/presidiums/curias')
        .replace(queryParameters: {'parishId': parishId.toString()});
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw const PresidiumServiceException('큐리아 목록을 불러오지 못했습니다.');
    }

    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => CuriaItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 가입한 쁘레시디움 전체 (어른 쁘레시디움이 먼저). 미가입이면 빈 목록.
  /// 로그인이 만료됐으면 빈 목록(미가입)으로 착각하지 않게 예외를 던지고 로그인 화면으로 보낸다.
  Future<List<PresidiumInfo>> fetchMyPresidiums() async {
    final response = await _authorized(
      (headers) => http.get(Uri.parse('${AppConfig.baseUrl}/app/presidiums/mine'), headers: headers),
    );
    if (response.statusCode != 200) {
      throw const PresidiumServiceException('가입 정보를 불러오지 못했습니다.');
    }

    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => PresidiumInfo.fromMyPresidiumJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PresidiumInfo> joinPresidium(int presidiumId) async {
    final response = await _authorized(
      (headers) => http.post(Uri.parse('${AppConfig.baseUrl}/app/presidiums/$presidiumId/join'), headers: headers),
    );
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return PresidiumInfo.fromMyPresidiumJson(json);
    }

    String message = '쁘레시디움 가입에 실패했습니다.';
    try {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      message = decoded['message'] as String? ?? message;
    } catch (_) {}
    throw PresidiumServiceException(message);
  }

  /// 쁘레시디움을 만들고, 만든 사람이 단장으로 가입된 정보를 돌려준다.
  Future<PresidiumInfo> createPresidium({
    required int parishId,
    int? curiaId,
    String? curiaName,
    required String name,
    bool junior = false,
  }) async {
    final body = <String, dynamic>{
      'parishId': parishId,
      'name': name,
      'type': junior ? 'JUNIOR' : 'ADULT',
    };
    if (curiaId != null) body['curiaId'] = curiaId;
    if (curiaName != null && curiaName.trim().isNotEmpty) {
      body['curiaName'] = curiaName.trim();
    }

    final response = await _authorized(
      (headers) => http.post(
        Uri.parse('${AppConfig.baseUrl}/app/presidiums'),
        headers: headers,
        body: jsonEncode(body),
      ),
    );
    if (response.statusCode == 201) {
      return PresidiumInfo.fromMyPresidiumJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    String message = '쁘레시디움 생성에 실패했습니다.';
    try {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      message = decoded['message'] as String? ?? message;
    } catch (_) {}
    throw PresidiumServiceException(message);
  }
}

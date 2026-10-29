import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/app_config.dart';
import '../../core/storage/token_storage.dart';
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
  const PresidiumService({TokenStorage tokenStorage = const TokenStorage()})
      : _tokenStorage = tokenStorage;

  final TokenStorage _tokenStorage;

  Future<Map<String, String>> _authHeaders() async {
    final token = await _tokenStorage.readAccessToken();
    if (token == null) {
      throw const PresidiumServiceException('로그인이 필요합니다. 다시 로그인해 주세요.');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

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

  /// 내 가입 쁘레시디움. 미가입이면 null.
  Future<PresidiumInfo?> fetchMyPresidium() async {
    final token = await _tokenStorage.readAccessToken();
    if (token == null) return null;

    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/app/presidiums/me'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 401) return null;
    if (response.statusCode != 200) {
      throw const PresidiumServiceException('가입 정보를 불러오지 못했습니다.');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (json['joined'] != true) return null;
    return PresidiumInfo.fromMyPresidiumJson(json);
  }

  Future<PresidiumInfo> joinPresidium(int presidiumId) async {
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/app/presidiums/$presidiumId/join'),
      headers: await _authHeaders(),
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
  }) async {
    final body = <String, dynamic>{
      'parishId': parishId,
      'name': name,
    };
    if (curiaId != null) body['curiaId'] = curiaId;
    if (curiaName != null && curiaName.trim().isNotEmpty) {
      body['curiaName'] = curiaName.trim();
    }

    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/app/presidiums'),
      headers: await _authHeaders(),
      body: jsonEncode(body),
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

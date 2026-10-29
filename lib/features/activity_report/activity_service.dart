import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/widgets/korean_date.dart';
import 'models/activity_definition.dart';

class ActivityServiceException implements Exception {
  const ActivityServiceException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// 활동보고가 제출되면 값이 바뀐다. 쁘레시디움 탭의 통계 카드가 듣고 새로 고친다.
abstract final class ActivityReportEvents {
  static final submitted = ValueNotifier<int>(0);
}

/// 이번 주(월~일) 내 활동보고. 아직 제출하지 않았으면 [updatedAt] 이 null 이고 [counts] 가 비어 있다.
class WeeklyActivityReport {
  const WeeklyActivityReport({
    required this.weekStart,
    required this.weekEnd,
    required this.updatedAt,
    required this.counts,
  });

  factory WeeklyActivityReport.fromJson(Map<String, dynamic> json) {
    final updatedAt = json['updatedAt'] as String?;
    return WeeklyActivityReport(
      weekStart: parseIsoDate(json['weekStart'] as String),
      weekEnd: parseIsoDate(json['weekEnd'] as String),
      updatedAt: updatedAt == null ? null : DateTime.parse(updatedAt).toLocal(),
      counts: {
        for (final item in json['items'] as List<dynamic>? ?? const [])
          (item as Map<String, dynamic>)['activityId'] as int: item['count'] as int,
      },
    );
  }

  final DateTime weekStart;
  final DateTime weekEnd;
  final DateTime? updatedAt;
  final Map<int, int> counts;

  bool get isSubmitted => updatedAt != null;
}

/// 활동보고 API.
class ActivityService {
  const ActivityService({ApiClient client = const ApiClient()}) : _client = client;

  final ApiClient _client;

  Future<WeeklyActivityReport> fetchCurrentWeek() async {
    final json = await _client.get('/app/presidiums/me/activity-reports/current-week');
    return WeeklyActivityReport.fromJson(json as Map<String, dynamic>);
  }

  /// 이번 주 활동별 누적 횟수 전체를 보낸다. 서버는 이번 주 보고를 이 값으로 덮어쓰므로
  /// 여러 번 제출해도 통계에 중복으로 쌓이지 않는다. 모두 0 이면 이번 주 보고가 지워진다.
  Future<int> submitReport(Map<int, int> countsByActivityId) async {
    final json = await _client.post('/app/presidiums/me/activity-reports', {
      'items': [
        for (final e in countsByActivityId.entries) {'activityId': e.key, 'count': e.value},
      ],
    });
    ActivityReportEvents.submitted.value++;
    return (json as Map<String, dynamic>)['totalCount'] as int? ?? 0;
  }

  Future<List<ActivityDefinition>> fetchActivities() async {
    final response = await http.get(Uri.parse('${AppConfig.baseUrl}/app/activities'));
    if (response.statusCode != 200) {
      throw const ActivityServiceException('활동 목록을 불러오지 못했습니다.');
    }

    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => ActivityDefinition.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

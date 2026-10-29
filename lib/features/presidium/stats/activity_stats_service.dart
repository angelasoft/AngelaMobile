import '../../../core/network/api_client.dart';
import '../../../core/widgets/korean_date.dart';

class ActivityCount {
  const ActivityCount(this.activityId, this.name, this.count);

  final int activityId;
  final String name;
  final int count;
}

class MemberCount {
  const MemberCount(this.userId, this.displayName, this.count);

  final int userId;
  final String displayName;
  final int count;
}

/// 통계 기간: 한 주(월요일 [weekStart]) 또는 한 달.
class StatsPeriod {
  const StatsPeriod.week(DateTime monday)
      : weekStart = monday,
        year = 0,
        month = 0;

  const StatsPeriod.month(this.year, this.month) : weekStart = null;

  final DateTime? weekStart;
  final int year;
  final int month;

  bool get isWeek => weekStart != null;

  /// 주 통계는 월~토로 보여 준다 (일요일에 낸 보고도 그 주에 들어간다).
  DateTime? get weekSaturday => weekStart?.add(const Duration(days: 5));

  /// 연도별 추이를 볼 해.
  int get trendYear => weekStart?.year ?? year;
}

/// 한 달 또는 한 주 활동 통계. [userId] 가 있으면 그 단원 한 명의 통계.
class MonthlyActivityStats {
  const MonthlyActivityStats({
    required this.year,
    required this.month,
    this.weekStart,
    required this.userId,
    required this.totalCount,
    required this.activities,
    required this.members,
  });

  factory MonthlyActivityStats.fromJson(Map<String, dynamic> json) {
    final parts = (json['month'] as String).split('-');
    final weekStart = json['weekStart'] as String?;
    return MonthlyActivityStats(
      year: int.parse(parts[0]),
      month: int.parse(parts[1]),
      weekStart: weekStart == null ? null : parseIsoDate(weekStart),
      userId: json['userId'] as int?,
      totalCount: json['totalCount'] as int,
      activities: (json['activities'] as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .map((e) => ActivityCount(e['activityId'] as int, e['name'] as String, e['count'] as int))
          .toList(),
      members: (json['members'] as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .map((e) => MemberCount(e['userId'] as int, e['displayName'] as String, e['count'] as int))
          .toList(),
    );
  }

  final int year;
  final int month;

  /// 주 통계일 때 그 주 월요일.
  final DateTime? weekStart;
  final int? userId;
  final int totalCount;

  /// 많이 한 순.
  final List<ActivityCount> activities;

  /// 단원별 합계 (많이 한 순). 단원 한 명의 통계일 때는 비어 있다.
  final List<MemberCount> members;
}

/// 한 해 월별 합계 (1~12월).
class YearlyActivityTrend {
  const YearlyActivityTrend(this.year, this.monthCounts);

  factory YearlyActivityTrend.fromJson(Map<String, dynamic> json) {
    final counts = List<int>.filled(12, 0);
    for (final m in json['months'] as List<dynamic>) {
      final map = m as Map<String, dynamic>;
      counts[(map['month'] as int) - 1] = map['count'] as int;
    }
    return YearlyActivityTrend(json['year'] as int, counts);
  }

  final int year;
  final List<int> monthCounts;
}

class ActivityStatsService {
  const ActivityStatsService({ApiClient client = const ApiClient()}) : _client = client;

  final ApiClient _client;

  Future<MonthlyActivityStats> fetchMonthly({required int year, required int month, int? userId}) async {
    final m = '$year-${month.toString().padLeft(2, '0')}';
    final query = userId == null ? 'month=$m' : 'month=$m&userId=$userId';
    final json = await _client.get('/app/presidiums/me/activity-stats?$query');
    return MonthlyActivityStats.fromJson(json as Map<String, dynamic>);
  }

  Future<MonthlyActivityStats> fetchPeriod(StatsPeriod period, {int? userId}) async {
    final weekStart = period.weekStart;
    if (weekStart == null) {
      return fetchMonthly(year: period.year, month: period.month, userId: userId);
    }
    final query = 'week=${isoDate(weekStart)}${userId == null ? '' : '&userId=$userId'}';
    final json = await _client.get('/app/presidiums/me/activity-stats?$query');
    return MonthlyActivityStats.fromJson(json as Map<String, dynamic>);
  }

  Future<YearlyActivityTrend> fetchYearly({required int year, int? userId}) async {
    final query = userId == null ? 'year=$year' : 'year=$year&userId=$userId';
    final json = await _client.get('/app/presidiums/me/activity-stats/yearly?$query');
    return YearlyActivityTrend.fromJson(json as Map<String, dynamic>);
  }
}

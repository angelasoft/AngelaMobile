import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/widgets/korean_date.dart';

/// 서버 요일 코드 (java.time.DayOfWeek). 순서는 월~일.
const meetingDayCodes = ['MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY'];
const meetingDayLabels = ['월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'];

/// 주회합을 쉰 주.
class PresidiumRecess {
  const PresidiumRecess({required this.id, required this.weekStart, required this.weekEnd, this.reason});

  final int id;
  final DateTime weekStart;
  final DateTime weekEnd;
  final String? reason;

  /// "12/21(월) ~ 12/27(일)"
  String get weekLabel => '${koreanShortDate(weekStart)} ~ ${koreanShortDate(weekEnd)}';

  factory PresidiumRecess.fromJson(Map<String, dynamic> json) => PresidiumRecess(
        id: (json['id'] as num).toInt(),
        weekStart: parseIsoDate(json['weekStart'] as String),
        weekEnd: parseIsoDate(json['weekEnd'] as String),
        reason: json['reason'] as String?,
      );
}

/// 평의회 월례회의 주차: 1~4 와 5(마지막 주).
const councilWeekLabels = {1: '첫째 주', 2: '둘째 주', 3: '셋째 주', 4: '넷째 주', 5: '마지막 주'};

/// 평의회(Cu) 월례회의 일정. 같은 Cu 의 모든 쁘레시디움이 함께 쓴다.
class CouncilSchedule {
  const CouncilSchedule({
    this.curiaName,
    this.weekOfMonth,
    this.day,
    this.scheduleLabel,
    this.time,
    this.place,
    this.nextDate,
  });

  final String? curiaName;

  /// 1~4, 5 는 마지막 주.
  final int? weekOfMonth;

  /// MONDAY ~ SUNDAY
  final String? day;

  /// "셋째 주 일요일"
  final String? scheduleLabel;
  final TimeOfDay? time;
  final String? place;
  final DateTime? nextDate;

  bool get isSet => weekOfMonth != null && day != null;

  /// "매달 셋째 주 일요일 오후 2:00"
  String? get label {
    if (scheduleLabel == null) return null;
    return ['매달 $scheduleLabel', if (time != null) koreanTime(time!)].join(' ');
  }

  factory CouncilSchedule.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const CouncilSchedule();
    final time = json['time'] as String?;
    final next = json['nextDate'] as String?;
    return CouncilSchedule(
      curiaName: json['curiaName'] as String?,
      weekOfMonth: (json['weekOfMonth'] as num?)?.toInt(),
      day: json['day'] as String?,
      scheduleLabel: json['scheduleLabel'] as String?,
      time: time == null ? null : parseIsoTime(time),
      place: json['place'] as String?,
      nextDate: next == null ? null : parseIsoDate(next),
    );
  }
}

/// 쁘레시디움 정보: 설립일·승인일·주회합 요일/시간/장소, 휴회 주, 이번 주 주회합 차수, 평의회 월례회의 일정.
class PresidiumProfile {
  const PresidiumProfile({
    this.foundedDate,
    this.approvedDate,
    this.meetingDay,
    this.meetingTime,
    this.meetingPlace,
    this.meetingNumberOffset = 0,
    this.thisWeekMeetingDate,
    this.thisWeekMeetingNumber,
    this.thisWeekRecess = false,
    this.thisWeekRecessReason,
    this.nextMeetingNumber,
    this.recesses = const [],
    this.council = const CouncilSchedule(),
    this.canEdit = false,
  });

  final DateTime? foundedDate;
  final DateTime? approvedDate;

  /// MONDAY ~ SUNDAY
  final String? meetingDay;
  final TimeOfDay? meetingTime;
  final String? meetingPlace;

  /// 계산한 차수에 더하는 보정값.
  final int meetingNumberOffset;
  final DateTime? thisWeekMeetingDate;

  /// 승인일부터 휴회 주를 빼고 센 이번 주 주회합 차수. 휴회 주이거나 첫 회합 전이면 null.
  final int? thisWeekMeetingNumber;
  final bool thisWeekRecess;
  final String? thisWeekRecessReason;

  /// 이번 주가 휴회일 때 다음 회합 차수.
  final int? nextMeetingNumber;

  /// 최근 주가 먼저.
  final List<PresidiumRecess> recesses;
  final CouncilSchedule council;

  /// 4간부면 true.
  final bool canEdit;

  String? get meetingDayLabel {
    final index = meetingDayCodes.indexOf(meetingDay ?? '');
    return index < 0 ? null : meetingDayLabels[index];
  }

  bool get isEmpty =>
      foundedDate == null &&
      approvedDate == null &&
      meetingDay == null &&
      meetingTime == null &&
      (meetingPlace == null || meetingPlace!.isEmpty);

  /// "매주 수요일 오후 7:30"
  String? get meetingScheduleLabel {
    final parts = [
      if (meetingDayLabel != null) '매주 $meetingDayLabel',
      if (meetingTime != null) koreanTime(meetingTime!),
    ];
    return parts.isEmpty ? null : parts.join(' ');
  }

  /// 이번 주(휴회면 다음 회합) 실제 차수를 [actual] 로 맞추려면 필요한 보정값. 차수를 계산할 수 없으면 null.
  int? offsetToMatch(int actual) {
    final current = thisWeekRecess ? nextMeetingNumber : thisWeekMeetingNumber;
    if (current == null) return null;
    return meetingNumberOffset + (actual - current);
  }

  factory PresidiumProfile.fromJson(Map<String, dynamic> json) {
    DateTime? date(String key) {
      final value = json[key] as String?;
      return value == null || value.isEmpty ? null : parseIsoDate(value);
    }

    final time = json['meetingTime'] as String?;
    return PresidiumProfile(
      foundedDate: date('foundedDate'),
      approvedDate: date('approvedDate'),
      meetingDay: json['meetingDay'] as String?,
      meetingTime: time == null || time.isEmpty ? null : parseIsoTime(time),
      meetingPlace: json['meetingPlace'] as String?,
      meetingNumberOffset: (json['meetingNumberOffset'] as num?)?.toInt() ?? 0,
      thisWeekMeetingDate: date('thisWeekMeetingDate'),
      thisWeekMeetingNumber: (json['thisWeekMeetingNumber'] as num?)?.toInt(),
      thisWeekRecess: json['thisWeekRecess'] as bool? ?? false,
      thisWeekRecessReason: json['thisWeekRecessReason'] as String?,
      nextMeetingNumber: (json['nextMeetingNumber'] as num?)?.toInt(),
      recesses: ((json['recesses'] as List<dynamic>?) ?? const [])
          .map((e) => PresidiumRecess.fromJson(e as Map<String, dynamic>))
          .toList(),
      council: CouncilSchedule.fromJson(json['council'] as Map<String, dynamic>?),
      canEdit: json['canEdit'] as bool? ?? false,
    );
  }
}

/// 지금 고른 쁘레시디움의 정보 API. 수정·휴회 등록은 4간부만.
class PresidiumProfileService {
  const PresidiumProfileService({ApiClient client = const ApiClient()}) : _client = client;

  final ApiClient _client;

  static const _path = '/app/presidiums/me/profile';

  Future<PresidiumProfile> fetch() async {
    final json = await _client.get(_path);
    return PresidiumProfile.fromJson(json as Map<String, dynamic>);
  }

  /// 비운 값은 지워진다.
  Future<PresidiumProfile> save({
    DateTime? foundedDate,
    DateTime? approvedDate,
    String? meetingDay,
    TimeOfDay? meetingTime,
    String? meetingPlace,
    int meetingNumberOffset = 0,
  }) async {
    final json = await _client.put(_path, {
      'foundedDate': foundedDate == null ? null : isoDate(foundedDate),
      'approvedDate': approvedDate == null ? null : isoDate(approvedDate),
      'meetingDay': meetingDay,
      'meetingTime': meetingTime == null ? null : isoTime(meetingTime),
      'meetingPlace': meetingPlace,
      'meetingNumberOffset': meetingNumberOffset,
    });
    return PresidiumProfile.fromJson(json as Map<String, dynamic>);
  }

  /// 기존 정보는 그대로 두고 보정값만 바꾼다.
  Future<PresidiumProfile> saveOffset(PresidiumProfile profile, int offset) => save(
        foundedDate: profile.foundedDate,
        approvedDate: profile.approvedDate,
        meetingDay: profile.meetingDay,
        meetingTime: profile.meetingTime,
        meetingPlace: profile.meetingPlace,
        meetingNumberOffset: offset,
      );

  /// 평의회 월례회의 일정. [weekOfMonth] 1~4, 5 는 마지막 주. 주차·요일을 비우면 일정을 지운다.
  Future<PresidiumProfile> saveCouncil({int? weekOfMonth, String? day, TimeOfDay? time, String? place}) async {
    final json = await _client.put('$_path/council', {
      'weekOfMonth': weekOfMonth,
      'day': day,
      'time': time == null ? null : isoTime(time),
      'place': place,
    });
    return PresidiumProfile.fromJson(json as Map<String, dynamic>);
  }

  /// [date] 가 든 주(월~일)를 휴회로 등록한다.
  Future<PresidiumProfile> addRecess(DateTime date, {String? reason}) async {
    final json = await _client.post('$_path/recesses', {'date': isoDate(date), 'reason': reason});
    return PresidiumProfile.fromJson(json as Map<String, dynamic>);
  }

  Future<PresidiumProfile> removeRecess(int recessId) async {
    final json = await _client.delete('$_path/recesses/$recessId');
    return PresidiumProfile.fromJson(json as Map<String, dynamic>);
  }
}

import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/widgets/korean_date.dart';

/// 출석부 종류. 서버 값(code)과 화면 이름.
enum AttendanceKind {
  presidium('PRESIDIUM', '주회합 출석부', '주회합'),
  council('COUNCIL', '평의회 출석부', '평의회 월례회의');

  const AttendanceKind(this.code, this.title, this.meetingName);

  final String code;
  final String title;
  final String meetingName;
}

/// 출석부 명단의 단원 한 명. [present] 가 null 이면 아직 저장 전.
class AttendanceEntry {
  const AttendanceEntry({required this.userId, required this.displayName, this.officerLabel, this.present});

  final int userId;
  final String displayName;
  final String? officerLabel;
  final bool? present;

  factory AttendanceEntry.fromJson(Map<String, dynamic> json) => AttendanceEntry(
        userId: (json['userId'] as num).toInt(),
        displayName: json['displayName'] as String,
        officerLabel: json['officerLabel'] as String?,
        present: json['present'] as bool?,
      );
}

/// 이번 달 출석 집계. 월례보고서의 "출석: 간부 13/16, 단원 11/16".
class AttendanceMonth {
  const AttendanceMonth({
    required this.month,
    required this.meetings,
    required this.officerPresent,
    required this.officerTotal,
    required this.memberPresent,
    required this.memberTotal,
  });

  final int month;
  final int meetings;
  final int officerPresent;
  final int officerTotal;
  final int memberPresent;
  final int memberTotal;

  factory AttendanceMonth.fromJson(Map<String, dynamic> json) => AttendanceMonth(
        month: (json['month'] as num).toInt(),
        meetings: (json['meetings'] as num).toInt(),
        officerPresent: (json['officerPresent'] as num).toInt(),
        officerTotal: (json['officerTotal'] as num).toInt(),
        memberPresent: (json['memberPresent'] as num).toInt(),
        memberTotal: (json['memberTotal'] as num).toInt(),
      );
}

/// 지난 출석부 한 줄.
class AttendanceSessionSummary {
  const AttendanceSessionSummary({
    required this.id,
    required this.meetingDate,
    this.meetingNumber,
    required this.presentCount,
    required this.totalCount,
  });

  final int id;
  final DateTime meetingDate;
  final int? meetingNumber;
  final int presentCount;
  final int totalCount;

  factory AttendanceSessionSummary.fromJson(Map<String, dynamic> json) => AttendanceSessionSummary(
        id: (json['id'] as num).toInt(),
        meetingDate: parseIsoDate(json['meetingDate'] as String),
        meetingNumber: (json['meetingNumber'] as num?)?.toInt(),
        presentCount: (json['presentCount'] as num).toInt(),
        totalCount: (json['totalCount'] as num).toInt(),
      );
}

/// 출석부 화면 데이터.
class AttendanceOverview {
  const AttendanceOverview({
    required this.configured,
    required this.open,
    this.meetingDate,
    this.meetingTime,
    this.meetingPlace,
    this.meetingNumber,
    required this.canEdit,
    required this.recorded,
    required this.roster,
    required this.month,
    required this.history,
  });

  /// 회합 요일·시간이 입력돼 있는지.
  final bool configured;

  /// 지금 입력할 수 있는지 (회합 당일 회합 시간부터 자정 전까지).
  final bool open;

  /// 열려 있으면 오늘, 아니면 다음 회합 날짜.
  final DateTime? meetingDate;
  final TimeOfDay? meetingTime;
  final String? meetingPlace;
  final int? meetingNumber;
  final bool canEdit;

  /// 오늘 출석부를 저장했는지.
  final bool recorded;
  final List<AttendanceEntry> roster;
  final AttendanceMonth month;
  final List<AttendanceSessionSummary> history;

  /// "11/13(금) 오후 8:00"
  String? get meetingWhenLabel {
    if (meetingDate == null) return null;
    return [koreanShortDate(meetingDate!), if (meetingTime != null) koreanTime(meetingTime!)].join(' ');
  }

  factory AttendanceOverview.fromJson(Map<String, dynamic> json) {
    final date = json['meetingDate'] as String?;
    final time = json['meetingTime'] as String?;
    return AttendanceOverview(
      configured: json['configured'] as bool? ?? false,
      open: json['open'] as bool? ?? false,
      meetingDate: date == null ? null : parseIsoDate(date),
      meetingTime: time == null ? null : parseIsoTime(time),
      meetingPlace: json['meetingPlace'] as String?,
      meetingNumber: (json['meetingNumber'] as num?)?.toInt(),
      canEdit: json['canEdit'] as bool? ?? false,
      recorded: json['recorded'] as bool? ?? false,
      roster: ((json['roster'] as List<dynamic>?) ?? const [])
          .map((e) => AttendanceEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      month: AttendanceMonth.fromJson(json['month'] as Map<String, dynamic>),
      history: ((json['history'] as List<dynamic>?) ?? const [])
          .map((e) => AttendanceSessionSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// 주회합·평의회 출석부 API. 입력은 4간부만, 회합 당일 회합 시간부터.
class AttendanceService {
  const AttendanceService({ApiClient client = const ApiClient()}) : _client = client;

  final ApiClient _client;

  static const _base = '/app/presidiums/me/attendance';

  Future<AttendanceOverview> fetch(AttendanceKind kind) async {
    final json = await _client.get('$_base?kind=${kind.code}');
    return AttendanceOverview.fromJson(json as Map<String, dynamic>);
  }

  Future<AttendanceOverview> save(AttendanceKind kind, Set<int> presentUserIds) async {
    final json = await _client.put('$_base/today?kind=${kind.code}', {'presentUserIds': presentUserIds.toList()});
    return AttendanceOverview.fromJson(json as Map<String, dynamic>);
  }

  Future<List<AttendanceEntry>> fetchRecords(int sessionId) async {
    final json = await _client.get('$_base/$sessionId') as Map<String, dynamic>;
    return (json['records'] as List<dynamic>)
        .map((e) => AttendanceEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

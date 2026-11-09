import 'package:angelamobile/features/presidium/attendance/attendance_service.dart';
import 'package:angelamobile/features/presidium/governance/presidium_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('열린 주회합 출석부를 읽는다', () {
    final o = AttendanceOverview.fromJson({
      'kind': 'PRESIDIUM',
      'configured': true,
      'open': true,
      'meetingDate': '2026-11-13',
      'meetingTime': '20:00',
      'meetingPlace': '교육관 304호',
      'meetingNumber': 609,
      'canEdit': true,
      'recorded': false,
      'roster': [
        {'userId': 1, 'displayName': '이미희(수산나)', 'officerLabel': '단장', 'present': null},
        {'userId': 2, 'displayName': '박우석(유스티노)', 'officerLabel': null, 'present': true},
      ],
      'month': {
        'year': 2026,
        'month': 11,
        'meetings': 2,
        'officerPresent': 7,
        'officerTotal': 8,
        'memberPresent': 5,
        'memberTotal': 8,
      },
      'history': [
        {'id': 5, 'meetingDate': '2026-11-06', 'meetingNumber': 608, 'presentCount': 6, 'totalCount': 8},
      ],
    });

    expect(o.open, isTrue);
    expect(o.meetingTime, const TimeOfDay(hour: 20, minute: 0));
    expect(o.meetingWhenLabel, '11/13(금) 오후 8:00');
    expect(o.roster.first.present, isNull);
    expect(o.roster.last.present, isTrue);
    expect(o.month.officerPresent, 7);
    expect(o.history.single.meetingNumber, 608);
  });

  test('평의회 월례회의 일정을 읽는다', () {
    final council = CouncilSchedule.fromJson({
      'curiaName': '성모성심',
      'weekOfMonth': 3,
      'day': 'SUNDAY',
      'scheduleLabel': '셋째 주 일요일',
      'time': '14:00',
      'place': '본당 대성전',
      'nextDate': '2026-11-15',
    });

    expect(council.isSet, isTrue);
    expect(council.label, '매달 셋째 주 일요일 오후 2:00');
    expect(council.nextDate, DateTime(2026, 11, 15));
    expect(CouncilSchedule.fromJson(null).isSet, isFalse);
  });
}

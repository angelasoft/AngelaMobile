import 'package:flutter/material.dart';

const _weekdays = ['월', '화', '수', '목', '금', '토', '일'];

/// "목"
String koreanWeekday(DateTime date) => _weekdays[date.weekday - 1];

/// "10월 30일 (목)"
String koreanMonthDay(DateTime date) =>
    '${date.month}월 ${date.day}일 (${_weekdays[date.weekday - 1]})';

/// "10/26(월)"
String koreanShortDate(DateTime date) => '${date.month}/${date.day}(${koreanWeekday(date)})';

/// 날짜가 속한 주의 월요일 (서버와 같은 기준, 한 주는 월~일).
DateTime weekStartOf(DateTime date) =>
    DateTime(date.year, date.month, date.day - (date.weekday - 1));

/// "2026년 10월 30일 (목)"
String koreanFullDate(DateTime date) => '${date.year}년 ${koreanMonthDay(date)}';

/// "오후 2:00"
String koreanTime(TimeOfDay time) {
  final period = time.hour < 12 ? '오전' : '오후';
  final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
  return '$period $hour:${time.minute.toString().padLeft(2, '0')}';
}

/// 서버와 주고받는 형식: "2026-10-30"
String isoDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

/// 서버와 주고받는 형식: "14:00"
String isoTime(TimeOfDay time) =>
    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

TimeOfDay parseIsoTime(String value) {
  final parts = value.split(':');
  return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
}

/// 날짜만 있는 "2026-10-30" 을 현지 날짜로 읽는다 (시간대 변환 없음).
DateTime parseIsoDate(String value) {
  final parts = value.split('-').map(int.parse).toList();
  return DateTime(parts[0], parts[1], parts[2]);
}

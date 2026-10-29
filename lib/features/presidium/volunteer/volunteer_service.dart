import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/widgets/korean_date.dart';

/// 봉사 일정 한 건.
class VolunteerSchedule {
  const VolunteerSchedule({
    required this.id,
    required this.date,
    required this.time,
    required this.place,
    required this.content,
    required this.createdByName,
  });

  factory VolunteerSchedule.fromJson(Map<String, dynamic> json) {
    return VolunteerSchedule(
      id: json['id'] as int,
      date: parseIsoDate(json['serviceDate'] as String),
      time: parseIsoTime(json['serviceTime'] as String),
      place: json['place'] as String,
      content: json['content'] as String,
      createdByName: json['createdByName'] as String? ?? '',
    );
  }

  final int id;

  /// 날짜만 의미가 있다 (시각은 [time]).
  final DateTime date;
  final TimeOfDay time;
  final String place;
  final String content;
  final String createdByName;

  /// "10월 30일 (목) 오후 2:00"
  String get whenLabel => '${koreanMonthDay(date)} ${koreanTime(time)}';

  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }
}

/// 봉사 일정 등록·수정 입력값.
class VolunteerScheduleInput {
  const VolunteerScheduleInput({
    required this.date,
    required this.time,
    required this.place,
    required this.content,
  });

  final DateTime date;
  final TimeOfDay time;
  final String place;
  final String content;

  Map<String, dynamic> toJson() => {
        'serviceDate': isoDate(date),
        'serviceTime': isoTime(time),
        'place': place,
        'content': content,
      };
}

class VolunteerPage {
  const VolunteerPage(this.items, this.hasNext);

  final List<VolunteerSchedule> items;
  final bool hasNext;
}

class VolunteerService {
  const VolunteerService({ApiClient client = const ApiClient()}) : _client = client;

  final ApiClient _client;

  static const _base = '/app/presidiums/me/schedules';

  Future<List<VolunteerSchedule>> fetchUpcoming({int limit = 3}) async {
    final list = await _client.get('$_base/upcoming?limit=$limit') as List<dynamic>;
    return list.map((e) => VolunteerSchedule.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<VolunteerPage> fetchPast({required int page, int size = 20}) async {
    final json = await _client.get('$_base/past?page=$page&size=$size') as Map<String, dynamic>;
    final items = (json['items'] as List<dynamic>)
        .map((e) => VolunteerSchedule.fromJson(e as Map<String, dynamic>))
        .toList();
    return VolunteerPage(items, json['hasNext'] as bool? ?? false);
  }

  Future<VolunteerSchedule> fetch(int id) async {
    final json = await _client.get('$_base/$id');
    return VolunteerSchedule.fromJson(json as Map<String, dynamic>);
  }

  Future<VolunteerSchedule> create(VolunteerScheduleInput input) async {
    final json = await _client.post(_base, input.toJson());
    return VolunteerSchedule.fromJson(json as Map<String, dynamic>);
  }

  Future<VolunteerSchedule> update(int id, VolunteerScheduleInput input) async {
    final json = await _client.put('$_base/$id', input.toJson());
    return VolunteerSchedule.fromJson(json as Map<String, dynamic>);
  }

  Future<void> delete(int id) => _client.delete('$_base/$id');
}

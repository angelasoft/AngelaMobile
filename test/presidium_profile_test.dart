import 'package:angelamobile/features/presidium/governance/presidium_profile.dart';
import 'package:angelamobile/features/presidium/governance/presidium_profile_edit_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('쁘레시디움 정보와 이번 주 회합 차수를 읽는다', () {
    final profile = PresidiumProfile.fromJson({
      'foundedDate': '2025-12-01',
      'approvedDate': '2026-01-07',
      'meetingDay': 'WEDNESDAY',
      'meetingTime': '19:30',
      'meetingPlace': '본당 교육관 2층',
      'meetingNumberOffset': 0,
      'thisWeekMeetingDate': '2026-10-28',
      'thisWeekMeetingNumber': 43,
      'thisWeekRecess': false,
      'recesses': [
        {'id': 3, 'weekStart': '2026-04-06', 'weekEnd': '2026-04-12', 'reason': '부활 휴회'},
      ],
      'canEdit': true,
    });

    expect(profile.approvedDate, DateTime(2026, 1, 7));
    expect(profile.meetingDayLabel, '수요일');
    expect(profile.meetingScheduleLabel, '매주 수요일 오후 7:30');
    expect(profile.thisWeekMeetingNumber, 43);
    expect(profile.recesses.single.weekLabel, '4/6(월) ~ 4/12(일)');
    expect(profile.recesses.single.reason, '부활 휴회');
    expect(profile.isEmpty, isFalse);
    expect(PresidiumProfile.fromJson({'canEdit': false}).isEmpty, isTrue);
  });

  test('실제 차수로 맞추는 보정값을 계산한다', () {
    const meeting = PresidiumProfile(thisWeekMeetingNumber: 43, meetingNumberOffset: 5);
    expect(meeting.offsetToMatch(150), 112);
    expect(meeting.offsetToMatch(43), 5);

    // 휴회 주에는 다음 회합 차수를 기준으로 맞춘다.
    const recess = PresidiumProfile(thisWeekRecess: true, nextMeetingNumber: 10);
    expect(recess.offsetToMatch(12), 2);

    expect(const PresidiumProfile().offsetToMatch(3), isNull);
  });

  testWidgets('4간부 수정 화면에 입력값이 채워진다', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: PresidiumProfileEditPage(
        profile: PresidiumProfile.fromJson({
          'approvedDate': '2026-01-07',
          'meetingDay': 'WEDNESDAY',
          'meetingTime': '19:30',
          'meetingPlace': '본당 교육관 2층',
          'meetingNumberOffset': -3,
          'canEdit': true,
        }),
      ),
    ));

    expect(find.text('2026년 1월 7일 (수)'), findsOneWidget);
    expect(find.text('오후 7:30'), findsOneWidget);
    expect(find.text('본당 교육관 2층'), findsOneWidget);
    expect(find.text('-3'), findsOneWidget);
    final wednesday = tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '수'));
    expect(wednesday.selected, isTrue);
  });
}

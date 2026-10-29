import 'package:angelamobile/core/text_scale/text_scale_controller.dart';
import 'package:angelamobile/core/widgets/app_tab_header.dart';
import 'package:angelamobile/features/activity_report/models/activity_definition.dart';
import 'package:angelamobile/features/activity_report/models/activity_report_entry.dart';
import 'package:angelamobile/features/activity_report/widgets/activity_report_row.dart';
import 'package:angelamobile/features/main/main_page.dart';
import 'package:angelamobile/features/presidium/ledger/ledger_page.dart';
import 'package:angelamobile/features/presidium/ledger/ledger_service.dart';
import 'package:angelamobile/features/presidium/models/presidium_info.dart';
import 'package:angelamobile/features/presidium/notice/notice_service.dart';
import 'package:angelamobile/features/presidium/notice/notice_tile.dart';
import 'package:angelamobile/features/presidium/stats/horizontal_bar_chart.dart';
import 'package:angelamobile/features/presidium/volunteer/volunteer_schedule_tile.dart';
import 'package:angelamobile/features/presidium/volunteer/volunteer_service.dart';
import 'package:angelamobile/features/presidium/widgets/presidium_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 가장 큰 글자 크기에서도 좁은 화면에서 화면 배치가 넘치지 않는지 확인한다.
void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await TextScaleController.init();
  });

  final notice = Notice(
    id: 1,
    title: '11월 정기 회합 장소 변경 안내 — 본당 교육관 2층 소회의실로 변경됩니다',
    content: '이번 주 회합은 본당 교육관 2층 소회의실에서 진행합니다. 늦지 않게 와 주세요.',
    createdByName: '박우석(유스티노)',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
  final schedule = VolunteerSchedule(
    id: 1,
    date: DateTime.now(),
    time: const TimeOfDay(hour: 14, minute: 30),
    place: '효성동 성당 마당과 주차장 주변, 성모상 앞 화단',
    content: '본당 주변 환경 정리 봉사입니다. 장갑과 집게는 사무실에서 받아 가세요.',
    createdByName: '박우석(유스티노)',
  );
  final presidium = PresidiumInfo(id: 1, name: PresidiumInfo.displayName('황금궁전', '즐거움의샘'));
  final ledger = Ledger(
    exists: true,
    year: 2026,
    month: 10,
    canEdit: true,
    carryover: const LedgerAmounts(11344000, 11209000, 135000),
    entries: [
      LedgerEntry(
        id: 1,
        date: DateTime(2026, 10, 2),
        isIncome: false,
        category: ExpenseCategory.flower,
        description: '꽃 값',
        amount: 5000,
        balance: 130000,
      ),
      LedgerEntry(
        id: 2,
        date: DateTime(2026, 10, 28),
        isIncome: true,
        category: null,
        description: '제612차 비밀헌금 및 특별 헌금 모음',
        amount: 1232000,
        balance: 1362000,
      ),
    ],
    monthlyIncome: 1232000,
    monthlyExpense: 5000,
    cumulative: const LedgerAmounts(12576000, 11214000, 1362000),
    donation: 0,
    flower: 5000,
    other: 0,
    finalBalance: 1362000,
    previousCumulative: null,
    suggestedCarryover: null,
  );

  Widget pieces() => Scaffold(
        body: ListView(
          children: [
            PresidiumHeader(presidium: presidium, unreadCount: 12),
            const PresidiumHeader(),
            const AppTabHeader(title: '주요 기도문'),
            NoticeTile(notice: notice, showPreview: true),
            VolunteerScheduleTile(schedule: schedule),
            const HorizontalBarChart(entries: [
              BarEntry('가정성화(미사)', 120),
              BarEntry('교우환자방문', 37),
              BarEntry('성경읽고 묵상', 3),
            ]),
            ActivityReportRow(
              entry: ActivityReportEntry(
                definition: const ActivityDefinition(id: 1, name: '소년레지오돌봄'),
                count: 128,
                isFavorite: true,
              ),
              onFavoriteToggle: () {},
              onIncrement: () {},
              onDecrement: () {},
            ),
            LedgerTable(ledger: ledger),
            LedgerSummary(ledger: ledger),
          ],
        ),
      );

  for (final width in [320.0, 360.0]) {
    for (final scale in [1.0, 1.3, 1.6]) {
      testWidgets('화면 구성 요소: 폭 ${width.toInt()}dp, 글자 ${(scale * 100).round()}%', (tester) async {
        tester.view.physicalSize = Size(width * 3, 2000 * 3);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(width, 2000), textScaler: TextScaler.linear(scale)),
            child: pieces(),
          ),
        ));
        expect(tester.takeException(), isNull);
      });

      testWidgets('하단 탭 메뉴: 폭 ${width.toInt()}dp, 글자 ${(scale * 100).round()}%', (tester) async {
        tester.view.physicalSize = Size(width * 3, 760 * 3);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(width, 760), textScaler: TextScaler.linear(scale)),
            child: const MainPage(),
          ),
        ));
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull);
      });
    }
  }
}

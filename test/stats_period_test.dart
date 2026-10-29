import 'package:angelamobile/core/widgets/korean_date.dart';
import 'package:angelamobile/features/presidium/stats/activity_stats_service.dart';
import 'package:angelamobile/features/presidium/stats/stats_period_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('한 주는 월요일부터 시작한다', () {
    expect(weekStartOf(DateTime(2026, 10, 29)), DateTime(2026, 10, 26));
    expect(weekStartOf(DateTime(2026, 10, 26)), DateTime(2026, 10, 26));
    expect(weekStartOf(DateTime(2026, 11, 1)), DateTime(2026, 10, 26));
  });

  test('그 달과 월~토가 겹치는 주만 고른다', () {
    // 2026-10-01 은 목요일, 10-31 은 토요일.
    expect(weeksOfMonth(2026, 10), [
      DateTime(2026, 9, 28),
      DateTime(2026, 10, 5),
      DateTime(2026, 10, 12),
      DateTime(2026, 10, 19),
      DateTime(2026, 10, 26),
    ]);
    // 2026-11-01 은 일요일이라 10/26 주(월~토)는 11월과 겹치지 않는다.
    expect(weeksOfMonth(2026, 11).first, DateTime(2026, 11, 2));
  });

  for (final scale in [1.0, 1.6]) {
    testWidgets('기간 선택 창: 폭 320dp, 글자 ${(scale * 100).round()}%', (tester) async {
      tester.view.physicalSize = const Size(320 * 3, 700 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: const Size(320, 700), textScaler: TextScaler.linear(scale)),
          child: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => showStatsPeriodPicker(
                    context,
                    StatsPeriod.week(weekStartOf(DateTime.now())),
                  ),
                  child: const Text('열기'),
                ),
              ),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();

      expect(find.text('기간 선택'), findsOneWidget);
      expect(find.text('이번 주'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}

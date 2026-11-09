import 'package:angelamobile/core/text_scale/text_scale_controller.dart';
import 'package:angelamobile/features/rosary/rosary_data.dart';
import 'package:angelamobile/features/rosary/rosary_page.dart';
import 'package:angelamobile/features/rosary/rosary_prayer_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await TextScaleController.init();
  });

  test('묵주기도는 시작 5걸음 + 5단×11걸음 + 마침 1걸음', () {
    final steps = buildRosarySteps(RosaryMystery.joyful);
    expect(steps, hasLength(61));
    expect(steps.first.kind, BeadKind.cross);
    expect(steps.first.prayers.map((p) => p.title), ['성호경', '사도신경']);
    expect(steps[4].prayers.map((p) => p.title), ['성모송', '영광송', '구원을 비는 기도']);

    final decade1 = steps[5];
    expect(decade1.label, '1단');
    expect(decade1.meditation, '마리아께서 예수님을 잉태하심을 묵상합시다.');
    expect(steps[15].label, '1단 10번째 알');
    expect(steps[15].prayers.map((p) => p.title), ['성모송', '영광송', '구원을 비는 기도']);
    expect(steps[14].prayers.map((p) => p.title), ['성모송']);
    expect(steps.last.kind, BeadKind.end);
    expect(steps.last.prayers.first.title, '성모 찬송');
  });

  test('요일별 신비', () {
    expect(RosaryMystery.forDay(DateTime(2026, 11, 9)), RosaryMystery.joyful); // 월
    expect(RosaryMystery.forDay(DateTime(2026, 11, 10)), RosaryMystery.sorrowful); // 화
    expect(RosaryMystery.forDay(DateTime(2026, 11, 11)), RosaryMystery.glorious); // 수
    expect(RosaryMystery.forDay(DateTime(2026, 11, 12)), RosaryMystery.luminous); // 목
    expect(RosaryMystery.forDay(DateTime(2026, 11, 15)), RosaryMystery.glorious); // 일
  });

  for (final scale in [1.0, 1.6]) {
    testWidgets('묵주기도 화면: 폭 320dp, 글자 ${(scale * 100).round()}%', (tester) async {
      tester.view.physicalSize = const Size(320 * 3, 700 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      Widget wrap(Widget child) => MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(size: const Size(320, 700), textScaler: TextScaler.linear(scale)),
              child: child,
            ),
          );

      await tester.pumpWidget(wrap(const Scaffold(body: RosaryPage())));
      expect(find.text('오늘 바칠 묵주기도'), findsOneWidget);
      expect(find.text('★ 오늘'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(wrap(const RosaryPrayerPage(mystery: RosaryMystery.sorrowful)));
      await tester.pumpAndSettle();
      expect(find.text('1 / 61'), findsOneWidget);
      expect(find.text('사도신경'), findsOneWidget);

      for (var i = 0; i < 5; i++) {
        await tester.tap(find.text('다음'));
        await tester.pumpAndSettle();
      }
      expect(find.text('6 / 61'), findsOneWidget);
      expect(find.text('예수님께서 우리를 위하여 피땀 흘리심을 묵상합시다.'), findsOneWidget);

      await tester.tap(find.text('이전'));
      await tester.pumpAndSettle();
      expect(find.text('5 / 61'), findsOneWidget);
      expect(find.textContaining('3번째 알'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}

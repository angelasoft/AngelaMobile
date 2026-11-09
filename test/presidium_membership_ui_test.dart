import 'package:angelamobile/core/text_scale/text_scale_controller.dart';
import 'package:angelamobile/features/main/main_page.dart';
import 'package:angelamobile/features/presidium/governance/presidium_settings_page.dart';
import 'package:angelamobile/features/presidium/my_presidiums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await TextScaleController.init();
  });

  testWidgets('가입한 쁘레시디움이 없으면 쁘레시디움·활동보고 탭에 가입 안내가 나온다', (tester) async {
    // 테스트에는 로그인 토큰 저장소가 없어 서버 조회 대신 "가입 안 함"을 바로 넣는다.
    MyPresidiums.state.value = const MyPresidiumsState(loaded: true);
    await tester.pumpWidget(const MaterialApp(home: MainPage()));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('아직 가입한 쁘레시디움이 없어요', skipOffstage: false), findsNWidgets(2));
    expect(find.text('쁘레시디움 가입', skipOffstage: false), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('가입한 쁘레시디움이 없으면 설정에는 로그아웃만 보인다', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: PresidiumSettingsPage(presidium: null)));
    await tester.pump();

    expect(find.text('설정'), findsOneWidget);
    expect(find.text('로그아웃'), findsOneWidget);
    expect(find.text('간부 이동'), findsNothing);
    expect(find.text('퇴단 신청'), findsNothing);
  });
}

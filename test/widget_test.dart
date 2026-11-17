import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:angelamobile/app/angela_app.dart';
import 'package:angelamobile/core/text_scale/text_scale_controller.dart';
import 'package:angelamobile/features/auth/login_page.dart';
import 'package:angelamobile/features/splash/splash_page.dart';

void main() {
  testWidgets('앱이 빌드되고, 스플래시는 터치 없이 다음 화면으로 넘어간다', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    // 저장된 로그인 토큰이 없는 기기 (자동 로그인 안 됨).
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (call) async => null,
    );
    await TextScaleController.init();
    await tester.pumpWidget(const AngelaApp());
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(SplashPage), findsOneWidget);
    expect(find.text('화면을 터치하세요'), findsNothing);

    // 테스트 환경에는 광고 SDK 가 없어 광고 없이 최소 표시 시간 뒤 넘어간다.
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(LoginPage), findsOneWidget);
  });
}

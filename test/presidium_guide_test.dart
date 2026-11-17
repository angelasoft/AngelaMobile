import 'package:angelamobile/features/presidium/onboarding/presidium_guide_page.dart';
import 'package:angelamobile/features/presidium/widgets/join_presidium_prompt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('가이드를 끝까지 넘기면 가입하러 가기를 돌려준다', (tester) async {
    bool? result;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async => result = await PresidiumGuide.open(context),
          child: const Text('열기'),
        ),
      ),
    ));
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();

    expect(find.text('레지오마리애에 오신 걸 환영해요'), findsOneWidget);
    for (final title in ['소속 본당을 검색해요', '내 쁘레시디움을 눌러 가입해요', '새 쁘레시디움을 만들어요', '이렇게 시작해 보세요']) {
      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();
      expect(find.text(title), findsOneWidget);
    }
    await tester.tap(find.text('쁘레시디움 찾아 가입하기'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });

  testWidgets('처음 한 번만 자동으로 뜬다', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: JoinPresidiumPrompt())));
    await tester.pumpAndSettle();
    expect(find.text('레지오마리애에 오신 걸 환영해요'), findsOneWidget);

    await tester.tap(find.text('건너뛰기'));
    await tester.pumpAndSettle();
    expect(find.text('아직 가입한 쁘레시디움이 없어요'), findsOneWidget);

    // 다시 만들어져도 이미 봤으면 뜨지 않는다.
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox())));
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: JoinPresidiumPrompt())));
    await tester.pumpAndSettle();
    expect(find.text('레지오마리애에 오신 걸 환영해요'), findsNothing);
  });
}

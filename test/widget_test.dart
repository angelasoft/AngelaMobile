import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:angelamobile/app/angela_app.dart';
import 'package:angelamobile/core/text_scale/text_scale_controller.dart';

void main() {
  testWidgets('앱이 정상적으로 빌드된다', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await TextScaleController.init();
    await tester.pumpWidget(const AngelaApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:angelamobile/app/angela_app.dart';

void main() {
  testWidgets('앱이 정상적으로 빌드된다', (WidgetTester tester) async {
    await tester.pumpWidget(const AngelaApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}

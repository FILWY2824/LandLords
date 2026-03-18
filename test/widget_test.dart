import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:landlords/main.dart';

void main() {
  testWidgets('renders login page', (WidgetTester tester) async {
    await tester.pumpWidget(const LandlordsApp());

    expect(find.text('欢乐斗地主'), findsOneWidget);
    expect(find.text('进入大厅'), findsWidgets);
    expect(find.widgetWithText(FilledButton, '进入大厅'), findsOneWidget);
  });
}

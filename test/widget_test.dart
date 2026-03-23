import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:landlords/main.dart';
import 'package:landlords/src/services/local_demo_gateway.dart';

void main() {
  testWidgets('renders login page', (WidgetTester tester) async {
    await tester.pumpWidget(
      LandlordsApp(gateway: LocalDemoGateway()),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('欢乐斗地主'), findsOneWidget);
    expect(find.text('登录进入大厅'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '登录进入大厅'), findsOneWidget);
  });
}

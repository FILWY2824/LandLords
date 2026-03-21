import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:landlords/src/services/local_demo_gateway.dart';
import 'package:landlords/src/state/app_controller.dart';
import 'package:landlords/src/widgets/responsive_modal.dart';

void main() {
  testWidgets('desktop stage-relative dialog keeps button taps responsive', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    var tapped = false;
    const stageWidth = 1320.0;
    const stageHeight = 760.0;
    const screen = Size(1920, 1080);
    final stageScale = math.min(
      screen.width / stageWidth,
      screen.height / stageHeight,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StageRelativeDialogPanel(
            stageWidth: stageWidth,
            stageHeight: stageHeight,
            stageScale: stageScale,
            widthRatio: 0.45,
            heightRatio: 0.75,
            scrollable: false,
            child: Center(
              child: FilledButton(
                onPressed: () => tapped = true,
                child: const Text('desktop-tap'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('desktop-tap'));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('mobile stage-relative dialog keeps button taps responsive', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    var tapped = false;
    const stageWidth = 1320.0;
    const stageHeight = 760.0;
    const screen = Size(390, 844);
    final stageScale = math.min(
      screen.width / stageWidth,
      screen.height / stageHeight,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StageRelativeDialogPanel(
            stageWidth: stageWidth,
            stageHeight: stageHeight,
            stageScale: stageScale,
            widthRatio: 0.45,
            heightRatio: 0.75,
            scrollable: false,
            child: Center(
              child: FilledButton(
                onPressed: () => tapped = true,
                child: const Text('mobile-tap'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('mobile-tap'));
    await tester.pump();

    expect(tapped, isTrue);
  });

  test('controller can create a room after login', () async {
    final controller = AppController(gateway: LocalDemoGateway());
    addTearDown(controller.dispose);

    await controller.login('玩家1', 'player1');
    await controller.createRoom();

    expect(controller.stage, AppStage.game);
    expect(controller.roomSnapshot, isNotNull);
    expect(controller.errorText, isNull);
  });

  test('controller can send a room invitation without silent failure', () async {
    final controller = AppController(gateway: LocalDemoGateway());
    addTearDown(controller.dispose);

    await controller.register('friend1', '好友1', 'pass123');
    await controller.login('玩家1', 'player1');
    await controller.createRoom();
    await controller.invitePlayerToRoom(
      account: 'friend1',
      displayName: '好友1',
      seatIndex: 1,
    );
    await Future<void>.delayed(Duration.zero);

    expect(controller.errorText, isNull);
    expect(controller.activeInvitation, isNotNull);
    expect(controller.activePopupNotice?.title, '邀请已发送');
  });
}

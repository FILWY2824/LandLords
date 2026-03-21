import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:landlords/src/models/app_models.dart';
import 'package:landlords/src/services/socket_game_gateway.dart';
import 'package:landlords/src/services/websocket_game_gateway.dart';
import 'package:landlords/src/state/app_controller.dart';

void main() {
  test('mixed transports surface invitation reminders and feedback', () async {
    final owner = AppController(gateway: SocketGameGateway());
    final guest = AppController(
      gateway: WebSocketGameGateway(url: 'ws://127.0.0.1:23002/ws'),
    );
    addTearDown(owner.dispose);
    addTearDown(guest.dispose);

    final suffix = DateTime.now().microsecondsSinceEpoch.toString();
    final ownerAccount = 'own$suffix';
    final guestAccount = 'gst$suffix';
    final shortSuffix = suffix.substring(suffix.length - 2);
    const password = 'pass123';

    await owner.register(ownerAccount, '房主$shortSuffix', password);
    await guest.register(guestAccount, '来宾$shortSuffix', password);

    await owner.login(ownerAccount, password);
    await guest.login(guestAccount, password);

    await owner.addFriendByAccount(guestAccount);
    await owner.createRoom();
    await owner.invitePlayerToRoom(
      account: guestAccount,
      displayName: guestAccount,
      seatIndex: 1,
    );

    // Keep a direct assertion here so failures surface the controller state
    // before we wait on later invite feedback.
    expect(owner.errorText, isNull);

    final inviteNotice = await _waitForValue(
      'owner invite notice',
      () => owner.activePopupNotice,
    );
    expect(inviteNotice.title, '邀请已发送');

    final invitation = await _waitForValue(
      'guest invitation',
      () => guest.activeInvitation,
    );
    expect(invitation.inviterAccount, ownerAccount);

    final accepted = await guest.respondToInvitation(
      invitationId: invitation.invitationId,
      accept: true,
    );
    expect(accepted, isTrue);

    final feedback = await _waitForValue(
      'owner invitation feedback',
      () => owner.activeInvitationFeedback,
    );
    expect(feedback.status, InvitationFeedbackStatus.accepted);
    expect(guest.stage, AppStage.game);
  }, timeout: const Timeout(Duration(minutes: 2)));
}

Future<T> _waitForValue<T>(
  String label,
  T? Function() read, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    final value = read();
    if (value != null) {
      return value;
    }
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
  throw TimeoutException('timed out waiting for $label');
}

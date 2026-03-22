import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:landlords/src/models/app_models.dart';
import 'package:landlords/src/models/game_models.dart';
import 'package:landlords/src/services/socket_game_gateway.dart';
import 'package:landlords/src/services/websocket_game_gateway.dart';
import 'package:landlords/src/state/app_controller.dart';

void main() {
  test(
    'invited player can reject or accept while already seated in another pending room',
    () async {
      final host = Platform.environment['LANDLORDS_TEST_HOST'] ?? '127.0.0.1';
      final tcpPort =
          int.tryParse(Platform.environment['LANDLORDS_TEST_TCP_PORT'] ?? '') ??
              23001;
      final wsPort =
          int.tryParse(Platform.environment['LANDLORDS_TEST_WS_PORT'] ?? '') ??
              23002;
      final owner = AppController(
        gateway: SocketGameGateway(host: host, port: tcpPort),
      );
      final guest = AppController(
        gateway: WebSocketGameGateway(url: 'ws://$host:$wsPort/ws'),
      );
      final roommate = AppController(
        gateway: SocketGameGateway(host: host, port: tcpPort),
      );
      addTearDown(owner.dispose);
      addTearDown(guest.dispose);
      addTearDown(roommate.dispose);

      final suffix = DateTime.now().microsecondsSinceEpoch.toString();
      final ownerAccount = 'own$suffix';
      final guestAccount = 'gst$suffix';
      final roommateAccount = 'rmt$suffix';
      const password = 'pass123';

      await owner.register(ownerAccount, 'owner${suffix.substring(suffix.length - 2)}', password);
      await guest.register(guestAccount, 'guest${suffix.substring(suffix.length - 2)}', password);
      await roommate.register(
        roommateAccount,
        'mate${suffix.substring(suffix.length - 2)}',
        password,
      );

      await owner.login(ownerAccount, password);
      await guest.login(guestAccount, password);
      await roommate.login(roommateAccount, password);

      await guest.createRoom();
      final guestRoomId = guest.roomSnapshot!.roomId;
      final guestRoomCode = guest.roomSnapshot!.roomCode;

      await roommate.joinRoom(guestRoomCode);
      await _waitForCondition(
        'guest room to receive roommate snapshot',
        () => _occupiedCount(guest.roomSnapshot) == 2,
      );

      await owner.createRoom();
      final ownerRoomId = owner.roomSnapshot!.roomId;

      await owner.invitePlayerToRoom(
        account: guestAccount,
        displayName: guestAccount,
        seatIndex: 1,
      );
      expect(owner.errorText, isNull);

      final rejectInvitation = await _waitForValue(
        'guest invitation while seated elsewhere',
        () => guest.activeInvitation,
      );
      final rejected = await guest.respondToInvitation(
        invitationId: rejectInvitation.invitationId,
        accept: false,
      );
      expect(rejected, isTrue);
      expect(guest.errorText, isNull);

      final rejectFeedback = await _waitForValue(
        'owner reject feedback',
        () => owner.activeInvitationFeedback,
      );
      expect(rejectFeedback.status, InvitationFeedbackStatus.rejected);
      expect(guest.roomSnapshot?.roomId, guestRoomId);
      expect(guest.roomSnapshot?.ownerPlayerId, guest.profile?.userId);
      owner.dismissActiveInvitationFeedback();

      await owner.invitePlayerToRoom(
        account: guestAccount,
        displayName: guestAccount,
        seatIndex: 1,
      );
      expect(owner.errorText, isNull);

      final acceptInvitation = await _waitForValue(
        'guest second invitation',
        () => guest.activeInvitation,
      );
      final accepted = await guest.respondToInvitation(
        invitationId: acceptInvitation.invitationId,
        accept: true,
      );
      expect(accepted, isTrue);
      expect(guest.errorText, isNull);

      final acceptFeedback = await _waitForValue(
        'owner accept feedback',
        () => owner.activeInvitationFeedback,
      );
      expect(acceptFeedback.status, InvitationFeedbackStatus.accepted);

      await _waitForCondition(
        'guest switches into inviter room',
        () => guest.roomSnapshot?.roomId == ownerRoomId,
      );
      await _waitForCondition(
        'roommate becomes owner of the old room',
        () =>
            roommate.roomSnapshot?.roomId == guestRoomId &&
            roommate.roomSnapshot?.ownerPlayerId == roommate.profile?.userId &&
            _occupiedCount(roommate.roomSnapshot) == 1,
      );
      await _waitForCondition(
        'owner room shows both seated players',
        () => _occupiedCount(owner.roomSnapshot) == 2,
      );

      expect(guest.roomSnapshot?.roomId, ownerRoomId);
      expect(guest.roomSnapshot?.ownerPlayerId, owner.profile?.userId);
      expect(roommate.roomSnapshot?.roomId, guestRoomId);
      expect(roommate.roomSnapshot?.ownerPlayerId, roommate.profile?.userId);
      expect(_occupiedCount(owner.roomSnapshot), 2);
      expect(_occupiedCount(roommate.roomSnapshot), 1);
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}

int _occupiedCount(RoomSnapshot? snapshot) {
  if (snapshot == null) {
    return 0;
  }
  return snapshot.players.where((player) => player.occupied).length;
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

Future<void> _waitForCondition(
  String label,
  bool Function() predicate, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    if (predicate()) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
  throw TimeoutException('timed out waiting for $label');
}

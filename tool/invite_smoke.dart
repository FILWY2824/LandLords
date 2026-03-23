import 'dart:async';
import 'dart:io';

import 'package:landlords/src/models/app_models.dart';
import 'package:landlords/src/models/game_models.dart';
import 'package:landlords/src/services/game_gateway.dart';
import 'package:landlords/src/services/socket_game_gateway.dart';
import 'package:landlords/src/services/websocket_game_gateway.dart';

const _timeout = Duration(seconds: 10);

Future<void> main(List<String> args) async {
  final transport = args.isEmpty ? 'tcp' : args.first.toLowerCase();
  try {
    await runInviteSmoke(transport);
    stdout.writeln('[$transport] smoke test passed');
  } catch (error, stackTrace) {
    stderr.writeln('invite smoke failed: $error');
    stderr.writeln(stackTrace);
    exitCode = 1;
  }
}

Future<void> runInviteSmoke(String transport) async {
  final ownerGateway = _createGateway(transport);
  final guestGateway = _createGateway(transport);

  try {
    final suffix = DateTime.now().microsecondsSinceEpoch.toString();
    final ownerAccount = 'own$suffix';
    final guestAccount = 'gst$suffix';
    const password = 'pass123';

    stdout.writeln('[$transport] registering users');
    await ownerGateway.register(
      account: ownerAccount,
      nickname: '房主${suffix.substring(suffix.length - 2)}',
      password: password,
    );
    await guestGateway.register(
      account: guestAccount,
      nickname: '来宾${suffix.substring(suffix.length - 2)}',
      password: password,
    );

    stdout.writeln('[$transport] logging in');
    final ownerLogin = await ownerGateway.login(
      account: ownerAccount,
      password: password,
    );
    final guestLogin = await guestGateway.login(
      account: guestAccount,
      password: password,
    );

    stdout.writeln('[$transport] linking friends');
    await ownerGateway.sendFriendRequest(
      sessionToken: ownerLogin.sessionToken,
      account: guestAccount,
    );
    final friendCenter = await guestGateway.fetchFriendCenter(
      sessionToken: guestLogin.sessionToken,
    );
    await guestGateway.respondFriendRequest(
      sessionToken: guestLogin.sessionToken,
      requestId: friendCenter.pendingRequests.single.requestId,
      accept: true,
    );

    stdout.writeln('[$transport] creating room');
    final room = await ownerGateway.createRoom(
      sessionToken: ownerLogin.sessionToken,
    );
    if (room.roomId.isEmpty || room.roomCode.isEmpty) {
      throw StateError('createRoom returned an invalid snapshot');
    }

    stdout.writeln('[$transport] recovering owner connection');
    final recoveredSnapshot = _waitForRoomSnapshot(
      ownerGateway,
      room.roomId,
      minimumOccupied: 1,
    );
    await ownerGateway.recoverConnection();
    await recoveredSnapshot.timeout(_timeout);

    stdout.writeln('[$transport] sending invitation');
    final invitationFuture = _waitForInvitation(guestGateway.notifications);
    final feedbackFuture = _waitForFeedback(ownerGateway.notifications);
    final ownerRoomSnapshotFuture = _waitForRoomSnapshot(
      ownerGateway,
      room.roomId,
      minimumOccupied: 2,
    );
    await ownerGateway.invitePlayer(
      sessionToken: ownerLogin.sessionToken,
      roomId: room.roomId,
      targetAccount: guestAccount,
      seatIndex: 1,
    );

    final invitation = await invitationFuture.timeout(_timeout);
    if (invitation.roomId != room.roomId || invitation.roomCode != room.roomCode) {
      throw StateError('invitee received an unexpected room invitation');
    }

    stdout.writeln('[$transport] accepting invitation');
    final guestSnapshot = await guestGateway.respondInvitation(
      sessionToken: guestLogin.sessionToken,
      invitationId: invitation.invitationId,
      accept: true,
    );
    if (guestSnapshot == null || guestSnapshot.roomId != room.roomId) {
      throw StateError('invitee did not join the expected room');
    }

    final feedback = await feedbackFuture.timeout(_timeout);
    if (feedback.status != InvitationFeedbackStatus.accepted) {
      throw StateError('owner did not receive an accepted invitation result');
    }

    final ownerRoomSnapshot = await ownerRoomSnapshotFuture.timeout(_timeout);
    if (ownerRoomSnapshot.players.where((player) => player.occupied).length < 2) {
      throw StateError('owner snapshot was not updated after the invitee joined');
    }
  } finally {
    await ownerGateway.close();
    await guestGateway.close();
  }
}

GameGateway _createGateway(String transport) {
  final host = Platform.environment['LANDLORDS_TEST_HOST'] ?? '127.0.0.1';
  final tcpPort =
      int.tryParse(Platform.environment['LANDLORDS_TEST_TCP_PORT'] ?? '') ??
          23001;
  final wsPort =
      int.tryParse(Platform.environment['LANDLORDS_TEST_WS_PORT'] ?? '') ??
          23002;
  switch (transport) {
    case 'tcp':
      return SocketGameGateway(host: host, port: tcpPort);
    case 'ws':
    case 'websocket':
      return WebSocketGameGateway(url: 'ws://$host:$wsPort/ws');
    default:
      throw ArgumentError('unsupported transport: $transport');
  }
}

Future<RoomInvitation> _waitForInvitation(
  Stream<GatewayNotification> notifications,
) async {
  await for (final notification in notifications) {
    if (notification is RoomInvitationNotification) {
      return notification.invitation;
    }
  }
  throw StateError('notification stream ended before receiving an invitation');
}

Future<InvitationFeedback> _waitForFeedback(
  Stream<GatewayNotification> notifications,
) async {
  await for (final notification in notifications) {
    if (notification is InvitationFeedbackNotification) {
      return notification.feedback;
    }
  }
  throw StateError('notification stream ended before receiving invitation feedback');
}

Future<RoomSnapshot> _waitForRoomSnapshot(
  GameGateway gateway,
  String roomId, {
  required int minimumOccupied,
}) async {
  final current = gateway.currentSnapshot(roomId);
  if (current != null &&
      current.players.where((player) => player.occupied).length >=
          minimumOccupied) {
    return current;
  }
  await for (final snapshot in gateway.roomSnapshots) {
    if (snapshot.roomId != roomId) {
      continue;
    }
    final occupiedCount = snapshot.players.where((player) => player.occupied).length;
    if (occupiedCount >= minimumOccupied) {
      return snapshot;
    }
  }
  throw StateError('snapshot stream ended before room $roomId reached $minimumOccupied players');
}

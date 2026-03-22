import 'dart:io';

import 'package:landlords/src/models/app_models.dart';
import 'package:landlords/src/services/socket_game_gateway.dart';
import 'package:landlords/src/services/websocket_game_gateway.dart';

Future<void> main() async {
  try {
    await runFriendRequestSmoke();
    stdout.writeln('friend request smoke passed');
  } catch (error, stackTrace) {
    stderr.writeln('friend request smoke failed: $error');
    stderr.writeln(stackTrace);
    exitCode = 1;
  }
}

Future<void> runFriendRequestSmoke() async {
  final host = Platform.environment['LANDLORDS_TEST_HOST'] ?? '127.0.0.1';
  final tcpPort =
      int.tryParse(Platform.environment['LANDLORDS_TEST_TCP_PORT'] ?? '') ??
          23001;
  final wsPort =
      int.tryParse(Platform.environment['LANDLORDS_TEST_WS_PORT'] ?? '') ??
          23002;

  final owner = SocketGameGateway(host: host, port: tcpPort);
  final guest = WebSocketGameGateway(url: 'ws://$host:$wsPort/ws');

  try {
    final suffix = DateTime.now().microsecondsSinceEpoch.toString();
    final ownerAccount = 'smk$suffix';
    final guestAccount = 'smg$suffix';
    const password = 'pass123';

    await owner.register(
      account: ownerAccount,
      nickname: 'owner${suffix.substring(suffix.length - 2)}',
      password: password,
    );
    await guest.register(
      account: guestAccount,
      nickname: 'guest${suffix.substring(suffix.length - 2)}',
      password: password,
    );

    final ownerLogin = await owner.login(
      account: ownerAccount,
      password: password,
    );
    final guestLogin = await guest.login(
      account: guestAccount,
      password: password,
    );

    final ownerAfterSend = await owner.sendFriendRequest(
      sessionToken: ownerLogin.sessionToken,
      account: guestAccount,
    );
    if (ownerAfterSend.historyRequests.isEmpty ||
        ownerAfterSend.historyRequests.first.status !=
            FriendRequestStatus.pending) {
      throw StateError('owner history did not record pending outgoing request');
    }

    final guestPending = await guest.fetchFriendCenter(
      sessionToken: guestLogin.sessionToken,
    );
    if (guestPending.pendingRequests.isEmpty) {
      throw StateError('guest did not receive pending friend request');
    }

    await guest.respondFriendRequest(
      sessionToken: guestLogin.sessionToken,
      requestId: guestPending.pendingRequests.first.requestId,
      accept: true,
    );

    final ownerAfterAccept = await owner.fetchFriendCenter(
      sessionToken: ownerLogin.sessionToken,
    );
    if (ownerAfterAccept.friends.length != 1 ||
        ownerAfterAccept.friends.single.account != guestAccount ||
        !ownerAfterAccept.friends.single.online) {
      throw StateError('owner friend list did not update after acceptance');
    }

    final ownerAfterDelete = await owner.deleteFriend(
      sessionToken: ownerLogin.sessionToken,
      friendUserId: ownerAfterAccept.friends.single.userId,
    );
    if (ownerAfterDelete.friends.isNotEmpty) {
      throw StateError('friend delete did not remove the friend');
    }
    if (ownerAfterDelete.historyRequests.isEmpty ||
        ownerAfterDelete.historyRequests.first.status !=
            FriendRequestStatus.accepted) {
      throw StateError('friend history was not preserved after delete');
    }
  } finally {
    await owner.close();
    await guest.close();
  }
}

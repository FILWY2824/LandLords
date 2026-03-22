import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:landlords/src/models/app_models.dart';
import 'package:landlords/src/services/socket_game_gateway.dart';
import 'package:landlords/src/services/websocket_game_gateway.dart';

void main() {
  test(
    'friend requests keep pending/history state and survive delete operations',
    () async {
      final host = Platform.environment['LANDLORDS_TEST_HOST'] ?? '127.0.0.1';
      final tcpPort =
          int.tryParse(Platform.environment['LANDLORDS_TEST_TCP_PORT'] ?? '') ??
              23001;
      final wsPort =
          int.tryParse(Platform.environment['LANDLORDS_TEST_WS_PORT'] ?? '') ??
              23002;
      final owner = SocketGameGateway(host: host, port: tcpPort);
      final guest = WebSocketGameGateway(url: 'ws://$host:$wsPort/ws');
      addTearDown(owner.close);
      addTearDown(guest.close);

      final suffix = DateTime.now().microsecondsSinceEpoch.toString();
      final ownerAccount = 'fro$suffix';
      final guestAccount = 'frg$suffix';
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

      final ownerAfterFirstSend = await owner.sendFriendRequest(
        sessionToken: ownerLogin.sessionToken,
        account: guestAccount,
      );
      expect(ownerAfterFirstSend.pendingRequests, isEmpty);
      expect(ownerAfterFirstSend.historyRequests, hasLength(1));
      expect(
        ownerAfterFirstSend.historyRequests.single.status,
        FriendRequestStatus.pending,
      );

      final guestPending = await guest.fetchFriendCenter(
        sessionToken: guestLogin.sessionToken,
      );
      expect(guestPending.pendingRequests, hasLength(1));
      expect(guestPending.pendingRequests.single.requesterAccount, ownerAccount);

      final guestAfterReject = await guest.respondFriendRequest(
        sessionToken: guestLogin.sessionToken,
        requestId: guestPending.pendingRequests.single.requestId,
        accept: false,
      );
      expect(guestAfterReject.pendingRequests, isEmpty);
      expect(
        guestAfterReject.historyRequests.first.status,
        FriendRequestStatus.rejected,
      );

      final ownerAfterReject = await owner.fetchFriendCenter(
        sessionToken: ownerLogin.sessionToken,
      );
      expect(
        ownerAfterReject.historyRequests.first.status,
        FriendRequestStatus.rejected,
      );

      await owner.sendFriendRequest(
        sessionToken: ownerLogin.sessionToken,
        account: guestAccount,
      );
      final guestSecondPending = await guest.fetchFriendCenter(
        sessionToken: guestLogin.sessionToken,
      );
      expect(guestSecondPending.pendingRequests, hasLength(1));

      final guestAfterAccept = await guest.respondFriendRequest(
        sessionToken: guestLogin.sessionToken,
        requestId: guestSecondPending.pendingRequests.single.requestId,
        accept: true,
      );
      expect(guestAfterAccept.pendingRequests, isEmpty);
      expect(guestAfterAccept.friends, hasLength(1));
      expect(guestAfterAccept.friends.single.account, ownerAccount);

      final ownerAfterAccept = await owner.fetchFriendCenter(
        sessionToken: ownerLogin.sessionToken,
      );
      expect(ownerAfterAccept.friends, hasLength(1));
      expect(ownerAfterAccept.friends.single.account, guestAccount);
      expect(ownerAfterAccept.friends.single.online, isTrue);
      expect(
        ownerAfterAccept.historyRequests.first.status,
        FriendRequestStatus.accepted,
      );

      final ownerAfterDelete = await owner.deleteFriend(
        sessionToken: ownerLogin.sessionToken,
        friendUserId: ownerAfterAccept.friends.single.userId,
      );
      final guestAfterDelete = await guest.fetchFriendCenter(
        sessionToken: guestLogin.sessionToken,
      );

      expect(ownerAfterDelete.friends, isEmpty);
      expect(guestAfterDelete.friends, isEmpty);
      expect(
        ownerAfterDelete.historyRequests.first.status,
        FriendRequestStatus.accepted,
      );
      expect(
        guestAfterDelete.historyRequests.first.status,
        FriendRequestStatus.accepted,
      );
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}

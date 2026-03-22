import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:landlords/src/services/socket_game_gateway.dart';
import 'package:landlords/src/services/websocket_game_gateway.dart';

void main() {
  test(
    'friends report online when both users are logged in',
    () async {
      final host = Platform.environment['LANDLORDS_TEST_HOST'] ?? '127.0.0.1';
      final tcpPort =
          int.tryParse(Platform.environment['LANDLORDS_TEST_TCP_PORT'] ?? '') ??
              23001;
      final wsPort =
          int.tryParse(Platform.environment['LANDLORDS_TEST_WS_PORT'] ?? '') ??
              23002;
      final owner = SocketGameGateway(host: host, port: tcpPort);
      final friend = WebSocketGameGateway(url: 'ws://$host:$wsPort/ws');
      addTearDown(owner.close);
      addTearDown(friend.close);

      final suffix = DateTime.now().microsecondsSinceEpoch.toString();
      final ownerAccount = 'fol$suffix';
      final friendAccount = 'frd$suffix';
      const password = 'pass123';

      await owner.register(
        account: ownerAccount,
        nickname: 'owner${suffix.substring(suffix.length - 2)}',
        password: password,
      );
      await friend.register(
        account: friendAccount,
        nickname: 'friend${suffix.substring(suffix.length - 2)}',
        password: password,
      );

      final ownerLogin = await owner.login(
        account: ownerAccount,
        password: password,
      );
      final friendLogin = await friend.login(
        account: friendAccount,
        password: password,
      );

      await owner.sendFriendRequest(
        sessionToken: ownerLogin.sessionToken,
        account: friendAccount,
      );
      final pending = await friend.fetchFriendCenter(
        sessionToken: friendLogin.sessionToken,
      );
      await friend.respondFriendRequest(
        sessionToken: friendLogin.sessionToken,
        requestId: pending.pendingRequests.single.requestId,
        accept: true,
      );

      final ownerFriends = await owner.fetchFriendCenter(
        sessionToken: ownerLogin.sessionToken,
      );
      final friendFriends = await friend.fetchFriendCenter(
        sessionToken: friendLogin.sessionToken,
      );

      expect(ownerFriends.friends, hasLength(1));
      expect(friendFriends.friends, hasLength(1));
      expect(ownerFriends.friends.single.account, friendAccount);
      expect(friendFriends.friends.single.account, ownerAccount);
      expect(ownerFriends.friends.single.online, isTrue);
      expect(friendFriends.friends.single.online, isTrue);
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}

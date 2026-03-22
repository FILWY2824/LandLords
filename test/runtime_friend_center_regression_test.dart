import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:landlords/src/services/socket_game_gateway.dart';

void main() {
  test(
    'existing runtime accounts can login and fetch friend center without crashing server',
    () async {
      final host = Platform.environment['LANDLORDS_TEST_HOST'] ?? '127.0.0.1';
      final tcpPort =
          int.tryParse(Platform.environment['LANDLORDS_TEST_TCP_PORT'] ?? '') ??
              23001;
      final gateway = SocketGameGateway(host: host, port: tcpPort);
      addTearDown(gateway.close);

      const password = 'pass123';
      for (final account in const ['player1', 'admin']) {
        await gateway.resetPassword(account: account, newPassword: password);
        final login = await gateway.login(account: account, password: password);
        final snapshot = await gateway.fetchFriendCenter(
          sessionToken: login.sessionToken,
        );
        expect(snapshot.pendingRequestCount, greaterThanOrEqualTo(0));
      }
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}

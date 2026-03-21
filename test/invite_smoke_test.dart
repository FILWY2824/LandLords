import 'package:flutter_test/flutter_test.dart';

import '../tool/invite_smoke.dart' as smoke;

void main() {
  test(
    'invite flow works for tcp and websocket transports',
    () async {
      await smoke.runInviteSmoke('tcp');
      await smoke.runInviteSmoke('ws');
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}

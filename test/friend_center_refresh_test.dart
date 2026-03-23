import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:landlords/src/models/app_models.dart';
import 'package:landlords/src/models/game_models.dart';
import 'package:landlords/src/services/game_gateway.dart';
import 'package:landlords/src/state/app_controller.dart';
import 'package:landlords/src/widgets/friend_center_dialog.dart';

void main() {
  testWidgets('friend center keeps all major sections visible', (tester) async {
    final gateway = _PollingGateway();
    final controller = AppController(gateway: gateway);
    addTearDown(controller.dispose);

    await controller.login('player1', 'pass123');

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () {
                  showFriendCenterDialog(
                    context,
                    controller: controller,
                  );
                },
                child: const Text('open-friend-center'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open-friend-center'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('\u597d\u53cb\u8bf7\u6c42\u6d88\u606f'), findsOneWidget);
    expect(find.text('\u6dfb\u52a0\u597d\u53cb'), findsOneWidget);
    expect(find.text('\u597d\u53cb\u5217\u8868'), findsOneWidget);
    expect(find.text('\u5386\u53f2\u8bf7\u6c42\u6d88\u606f'), findsOneWidget);
    expect(find.textContaining('friendA'), findsOneWidget);
    expect(find.text('\u597d\u53cb\u4e59'), findsOneWidget);

    await tester.ensureVisible(find.text('\u5c55\u5f00\u5386\u53f2\u8bf7\u6c42'));
    await tester.tap(find.text('\u5c55\u5f00\u5386\u53f2\u8bf7\u6c42'));
    await tester.pump();

    expect(find.text('\u6536\u8d77\u5386\u53f2\u8bf7\u6c42'), findsOneWidget);
  });

  testWidgets('friend center refreshes friends automatically while open', (
    tester,
  ) async {
    final gateway = _PollingGateway();
    final controller = AppController(gateway: gateway);
    addTearDown(controller.dispose);

    await controller.login('player1', 'pass123');

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () {
                  showFriendCenterDialog(
                    context,
                    controller: controller,
                  );
                },
                child: const Text('open-friend-center'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open-friend-center'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('\u597d\u53cb\u8bf7\u6c42\u6d88\u606f'), findsOneWidget);
    expect(find.text('\u5386\u53f2\u8bf7\u6c42\u6d88\u606f'), findsOneWidget);
    expect(find.text('\u597d\u53cb\u5217\u8868'), findsOneWidget);
    expect(gateway.fetchFriendCenterCallCount, 2);
    expect(find.text('\u79bb\u7ebf'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(milliseconds: 200));

    expect(gateway.fetchFriendCenterCallCount, greaterThanOrEqualTo(3));
    expect(find.text('\u5728\u7ebf'), findsOneWidget);
  });

  testWidgets('friend center header scrolls together with the content', (
    tester,
  ) async {
    final gateway = _PollingGateway();
    final controller = AppController(gateway: gateway);
    addTearDown(controller.dispose);

    await controller.login('player1', 'pass123');

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () {
                  showFriendCenterDialog(
                    context,
                    controller: controller,
                  );
                },
                child: const Text('open-friend-center'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open-friend-center'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    final titleFinder = find.text('\u597d\u53cb\u4e2d\u5fc3');
    final initialTop = tester.getTopLeft(titleFinder).dy;

    await tester.drag(
      find.byType(SingleChildScrollView).last,
      const Offset(0, -220),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    final scrolledTop = tester.getTopLeft(titleFinder).dy;
    expect(scrolledTop, lessThan(initialTop));
  });

  testWidgets('seat invite dialog keeps DouZero actions above friend invites', (
    tester,
  ) async {
    final gateway = _PollingGateway();
    final controller = AppController(gateway: gateway);
    addTearDown(controller.dispose);

    await controller.login('player1', 'pass123');

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () {
                  showSeatInviteDialog(
                    context,
                    controller: controller,
                    snapshot: _inviteSnapshot(),
                    seatIndex: 1,
                  );
                },
                child: const Text('open-seat-invite'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open-seat-invite'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    final botSectionY =
        tester.getTopLeft(find.text('\u8865\u5165 DouZero')).dy;
    final friendSectionY =
        tester.getTopLeft(find.text('\u53ef\u9080\u8bf7\u597d\u53cb')).dy;

    expect(botSectionY, lessThan(friendSectionY));
  });
}

RoomSnapshot _inviteSnapshot() {
  return const RoomSnapshot(
    roomId: 'room-1',
    roomCode: '123456',
    ownerPlayerId: 'self',
    mode: MatchMode.online,
    phase: RoomPhase.preparing,
    players: [
      RoomPlayer(
        playerId: 'self',
        displayName: '玩家1',
        isBot: false,
        role: PlayerRole.farmer,
        cardsLeft: 0,
        roundScore: 0,
        seatIndex: 0,
        ready: false,
        occupied: true,
      ),
      RoomPlayer(
        playerId: '',
        displayName: '空位',
        isBot: false,
        role: PlayerRole.farmer,
        cardsLeft: 0,
        roundScore: 0,
        seatIndex: 1,
        ready: false,
        occupied: false,
      ),
      RoomPlayer(
        playerId: '',
        displayName: '空位',
        isBot: false,
        role: PlayerRole.farmer,
        cardsLeft: 0,
        roundScore: 0,
        seatIndex: 2,
        ready: false,
        occupied: false,
      ),
    ],
    selfCards: [],
    landlordCards: [],
    recentActions: [],
    currentTurnPlayerId: '',
    statusText: 'waiting_for_players',
    cardCounter: [],
    baseScore: 1,
    multiplier: 1,
    currentRoundScore: 0,
    springTriggered: false,
    turnSerial: 0,
  );
}

class _PollingGateway implements GameGateway {
  final StreamController<RoomSnapshot> _roomController =
      StreamController<RoomSnapshot>.broadcast();
  final StreamController<GatewayNotification> _notificationController =
      StreamController<GatewayNotification>.broadcast();

  int fetchFriendCenterCallCount = 0;

  @override
  Stream<RoomSnapshot> get roomSnapshots => _roomController.stream;

  @override
  Stream<GatewayNotification> get notifications =>
      _notificationController.stream;

  @override
  Future<LoginResult> login({
    required String account,
    required String password,
  }) async {
    return const LoginResult(
      profile: UserProfile(
        userId: 'self',
        account: 'player1',
        nickname: '玩家1',
        coins: 0,
      ),
      sessionToken: 'session-1',
    );
  }

  @override
  Future<FriendCenterSnapshot> fetchFriendCenter({
    required String sessionToken,
  }) async {
    fetchFriendCenterCallCount += 1;
    return FriendCenterSnapshot(
      friends: [
        OnlineUser(
          userId: 'friend-1',
          account: 'friend1',
          nickname: '好友乙',
          online: fetchFriendCenterCallCount > 2,
        ),
      ],
      pendingRequests: [
        FriendRequestEntry(
          requestId: 'request-1',
          requesterUserId: 'user-a',
          requesterAccount: 'friendA',
          requesterNickname: '好友甲',
          receiverUserId: 'self',
          receiverAccount: 'player1',
          receiverNickname: '玩家1',
          status: FriendRequestStatus.pending,
          createdAtMs: DateTime(2026, 3, 22, 10, 0).millisecondsSinceEpoch,
          updatedAtMs: DateTime(2026, 3, 22, 10, 0).millisecondsSinceEpoch,
        ),
      ],
      historyRequests: [
        FriendRequestEntry(
          requestId: 'request-2',
          requesterUserId: 'self',
          requesterAccount: 'player1',
          requesterNickname: '玩家1',
          receiverUserId: 'user-c',
          receiverAccount: 'friendC',
          receiverNickname: '好友丙',
          status: FriendRequestStatus.accepted,
          createdAtMs: DateTime(2026, 3, 21, 8, 0).millisecondsSinceEpoch,
          updatedAtMs: DateTime(2026, 3, 21, 8, 5).millisecondsSinceEpoch,
        ),
      ],
      pendingRequestCount: 1,
    );
  }

  @override
  Future<void> close() async {
    await _roomController.close();
    await _notificationController.close();
  }

  @override
  RoomSnapshot? currentSnapshot(String roomId) => null;

  @override
  void clearCurrentRoomCache() {}

  @override
  void forgetSession() {}

  @override
  Future<void> register({
    required String account,
    required String nickname,
    required String password,
  }) async {}

  @override
  Future<void> resetPassword({
    required String account,
    required String newPassword,
  }) async {}

  @override
  Future<void> changePassword({
    required String sessionToken,
    required String currentPassword,
    required String newPassword,
  }) async {}

  @override
  Future<UserProfile> updateNickname({
    required String sessionToken,
    required String nickname,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<SupportStats> fetchSupportStats() async {
    return const SupportStats(supportLikeCount: 9);
  }

  @override
  Future<SupportStats> submitSupportLike() async {
    return const SupportStats(supportLikeCount: 10);
  }

  @override
  Future<SupportRewardResult> claimSupportLikeReward({
    required String sessionToken,
  }) async {
    return const SupportRewardResult(
      profile: UserProfile(
        userId: 'user-player1',
        account: 'player1',
        nickname: '玩家1',
        coins: 50,
      ),
      stats: SupportStats(supportLikeCount: 10),
      rewardCoins: 50,
    );
  }

  @override
  Future<RoomSnapshot> startMatch({
    required String sessionToken,
    required UserProfile profile,
    required MatchMode mode,
    BotDifficulty botDifficulty = BotDifficulty.normal,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<RoomSnapshot> createRoom({
    required String sessionToken,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<RoomSnapshot> joinRoom({
    required String sessionToken,
    required String roomCode,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> leaveRoom({
    required String sessionToken,
    required String roomId,
  }) async {}

  @override
  Future<RoomSnapshot> setRoomReady({
    required String sessionToken,
    required String roomId,
    required bool ready,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<RoomSnapshot> addBot({
    required String sessionToken,
    required String roomId,
    required int seatIndex,
    BotDifficulty botDifficulty = BotDifficulty.normal,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<RoomSnapshot> removePlayer({
    required String sessionToken,
    required String roomId,
    required String playerId,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<FriendCenterSnapshot> sendFriendRequest({
    required String sessionToken,
    required String account,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<FriendCenterSnapshot> respondFriendRequest({
    required String sessionToken,
    required String requestId,
    required bool accept,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<FriendCenterSnapshot> deleteFriend({
    required String sessionToken,
    required String friendUserId,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> invitePlayer({
    required String sessionToken,
    required String roomId,
    required String targetAccount,
    required int seatIndex,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<RoomSnapshot?> respondInvitation({
    required String sessionToken,
    required String invitationId,
    required bool accept,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> cancelMatch({
    required String sessionToken,
  }) async {}

  @override
  Future<RoomSnapshot> playCards({
    required String sessionToken,
    required String roomId,
    required List<String> cardIds,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<RoomSnapshot> callScore({
    required String sessionToken,
    required String roomId,
    required int score,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<RoomSnapshot> setManaged({
    required String sessionToken,
    required String roomId,
    required bool managed,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<RoomSnapshot> pass({
    required String sessionToken,
    required String roomId,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<List<String>> requestSuggestion({
    required String sessionToken,
    required String roomId,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> acknowledgePresentation({
    required String sessionToken,
    required String roomId,
    required String actionId,
  }) async {}

  @override
  Future<void> recoverConnection() async {}

  @override
  Future<RoomSnapshot?> refreshCurrentRoom() async => null;
}

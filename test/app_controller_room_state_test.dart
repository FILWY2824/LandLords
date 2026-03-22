import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:landlords/src/models/app_models.dart';
import 'package:landlords/src/models/game_models.dart';
import 'package:landlords/src/services/game_gateway.dart';
import 'package:landlords/src/state/app_controller.dart';

void main() {
  test('leaving a vs bot game closes the room immediately', () async {
    final gateway = _RoomStateGateway(
      startMatchResult: _buildRoomSnapshot(
        roomId: 'bot-room',
        mode: MatchMode.vsBot,
        phase: RoomPhase.playing,
        turnSerial: 4,
      ),
    );
    final controller = AppController(gateway: gateway);
    addTearDown(controller.dispose);

    await controller.login('player1', 'pass123');
    await controller.startMatch(MatchMode.vsBot);
    await controller.backToLobby();

    expect(gateway.leaveRoomCalls, 1);
    expect(gateway.lastLeftRoomId, 'bot-room');
    expect(controller.stage, AppStage.lobby);
    expect(controller.roomSnapshot, isNull);
    expect(controller.hasResumeRoom, isFalse);
  });

  test('resuming an online game refreshes the latest room snapshot first', () async {
    final initialSnapshot = _buildRoomSnapshot(
      roomId: 'online-room',
      mode: MatchMode.online,
      phase: RoomPhase.playing,
      turnSerial: 3,
      currentRoundScore: 2,
    );
    final refreshedSnapshot = _buildRoomSnapshot(
      roomId: 'online-room',
      mode: MatchMode.online,
      phase: RoomPhase.playing,
      turnSerial: 9,
      currentRoundScore: 16,
    );
    final gateway = _RoomStateGateway(
      startMatchResult: initialSnapshot,
      refreshCurrentRoomResult: refreshedSnapshot,
    );
    final controller = AppController(gateway: gateway);
    addTearDown(controller.dispose);

    await controller.login('player1', 'pass123');
    await controller.startMatch(MatchMode.online);
    await controller.backToLobby();

    expect(controller.stage, AppStage.lobby);
    expect(controller.hasResumeRoom, isTrue);
    expect(controller.roomSnapshot?.turnSerial, 3);

    controller.resumeRoom();
    await _drainAsyncWork();

    expect(gateway.refreshCurrentRoomCalls, 1);
    expect(controller.stage, AppStage.game);
    expect(controller.roomSnapshot?.turnSerial, 9);
    expect(controller.roomSnapshot?.currentRoundScore, 16);
  });

  test('create room refuses unexpected active-room snapshots', () async {
    final gateway = _RoomStateGateway(
      createRoomResult: _buildRoomSnapshot(
        roomId: 'bad-room',
        mode: MatchMode.online,
        phase: RoomPhase.playing,
        turnSerial: 11,
      ),
    );
    final controller = AppController(gateway: gateway);
    addTearDown(controller.dispose);

    await controller.login('player1', 'pass123');
    await controller.createRoom();
    await _drainAsyncWork();

    expect(controller.stage, AppStage.lobby);
    expect(controller.roomSnapshot, isNull);
    expect(controller.activePopupNotice, isNotNull);
  });

  test('being removed from a pending room returns the player to the lobby', () async {
    final gateway = _RoomStateGateway(
      createRoomResult: _buildRoomSnapshot(
        roomId: 'pending-room',
        mode: MatchMode.online,
        phase: RoomPhase.preparing,
        turnSerial: 0,
      ).copyWithPlayers(const [
        RoomPlayer(
          playerId: 'user-player1',
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
      ]),
    );
    final controller = AppController(gateway: gateway);
    addTearDown(controller.dispose);

    await controller.login('player1', 'pass123');
    await controller.createRoom();

    gateway.emitRoomSnapshot(
      _buildRoomSnapshot(
        roomId: 'pending-room',
        mode: MatchMode.online,
        phase: RoomPhase.preparing,
        turnSerial: 0,
      ).copyWithPlayers(const [
        RoomPlayer(
          playerId: 'user-player2',
          displayName: '玩家2',
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
      ]),
    );
    await _drainAsyncWork();

    expect(controller.stage, AppStage.lobby);
    expect(controller.roomSnapshot, isNull);
    expect(
      controller.activePopupNotice?.message,
      contains('移出'),
    );
    expect(gateway.cacheCleared, isTrue);
  });

  test('change password uses the authenticated change-password gateway path', () async {
    final gateway = _RoomStateGateway();
    final controller = AppController(gateway: gateway);
    addTearDown(controller.dispose);

    await controller.login('player1', 'pass123');
    await controller.changePassword('pass123', 'pass456');

    expect(gateway.changePasswordCalls, 1);
    expect(gateway.lastChangePasswordSessionToken, 'session-1');
    expect(gateway.lastCurrentPassword, 'pass123');
    expect(gateway.lastNewPassword, 'pass456');
  });
}

Future<void> _drainAsyncWork() async {
  for (var index = 0; index < 6; index++) {
    await Future<void>.delayed(Duration.zero);
  }
}

RoomSnapshot _buildRoomSnapshot({
  required String roomId,
  required MatchMode mode,
  required RoomPhase phase,
  required int turnSerial,
  int currentRoundScore = 0,
}) {
  final isVsBot = mode == MatchMode.vsBot;
  return RoomSnapshot(
    roomId: roomId,
    roomCode: '123456',
    ownerPlayerId: 'user-player1',
    mode: mode,
    phase: phase,
    players: [
      const RoomPlayer(
        playerId: 'user-player1',
        displayName: '玩家1',
        isBot: false,
        role: PlayerRole.farmer,
        cardsLeft: 17,
        roundScore: 0,
        seatIndex: 0,
        ready: true,
        occupied: true,
      ),
      RoomPlayer(
        playerId: isVsBot ? 'bot-1' : 'user-player2',
        displayName: isVsBot ? '机器人甲' : '玩家2',
        isBot: isVsBot,
        role: PlayerRole.landlord,
        cardsLeft: 17,
        roundScore: 0,
        seatIndex: 1,
        ready: true,
        occupied: true,
      ),
      RoomPlayer(
        playerId: isVsBot ? 'bot-2' : 'user-player3',
        displayName: isVsBot ? '机器人乙' : '玩家3',
        isBot: isVsBot,
        role: PlayerRole.farmer,
        cardsLeft: 17,
        roundScore: 0,
        seatIndex: 2,
        ready: true,
        occupied: true,
      ),
    ],
    selfCards: const [],
    landlordCards: const [],
    recentActions: const [],
    currentTurnPlayerId: 'user-player1',
    statusText: phase == RoomPhase.preparing ? 'waiting_for_players' : 'playing',
    cardCounter: const [],
    baseScore: 1,
    multiplier: 1,
    currentRoundScore: currentRoundScore,
    springTriggered: false,
    turnSerial: turnSerial,
  );
}

class _RoomStateGateway implements GameGateway {
  _RoomStateGateway({
    this.startMatchResult,
    this.createRoomResult,
    this.refreshCurrentRoomResult,
  });

  final RoomSnapshot? startMatchResult;
  final RoomSnapshot? createRoomResult;
  final RoomSnapshot? refreshCurrentRoomResult;

  final StreamController<RoomSnapshot> _roomController =
      StreamController<RoomSnapshot>.broadcast();
  final StreamController<GatewayNotification> _notificationController =
      StreamController<GatewayNotification>.broadcast();

  int leaveRoomCalls = 0;
  int refreshCurrentRoomCalls = 0;
  int changePasswordCalls = 0;
  String? lastLeftRoomId;
  String? lastChangePasswordSessionToken;
  String? lastCurrentPassword;
  String? lastNewPassword;
  bool cacheCleared = false;

  @override
  Stream<RoomSnapshot> get roomSnapshots => _roomController.stream;

  @override
  Stream<GatewayNotification> get notifications => _notificationController.stream;

  @override
  Future<LoginResult> login({
    required String account,
    required String password,
  }) async {
    return const LoginResult(
      profile: UserProfile(
        userId: 'user-player1',
        account: 'player1',
        nickname: '玩家1',
        coins: 120,
      ),
      sessionToken: 'session-1',
    );
  }

  @override
  Future<RoomSnapshot> startMatch({
    required String sessionToken,
    required UserProfile profile,
    required MatchMode mode,
    BotDifficulty botDifficulty = BotDifficulty.normal,
  }) async {
    return startMatchResult ??
        _buildRoomSnapshot(
          roomId: 'default-room',
          mode: mode,
          phase: RoomPhase.playing,
          turnSerial: 1,
        );
  }

  @override
  Future<RoomSnapshot> createRoom({
    required String sessionToken,
  }) async {
    return createRoomResult ??
        _buildRoomSnapshot(
          roomId: 'created-room',
          mode: MatchMode.online,
          phase: RoomPhase.preparing,
          turnSerial: 0,
        ).copyWithPlayers(const [
          RoomPlayer(
            playerId: 'user-player1',
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
        ]);
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
  }) async {
    leaveRoomCalls += 1;
    lastLeftRoomId = roomId;
  }

  @override
  Future<RoomSnapshot?> refreshCurrentRoom() async {
    refreshCurrentRoomCalls += 1;
    return refreshCurrentRoomResult;
  }

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
  }) async {
    changePasswordCalls += 1;
    lastChangePasswordSessionToken = sessionToken;
    lastCurrentPassword = currentPassword;
    lastNewPassword = newPassword;
  }

  @override
  Future<UserProfile> updateNickname({
    required String sessionToken,
    required String nickname,
  }) async {
    throw UnimplementedError();
  }

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
  Future<FriendCenterSnapshot> fetchFriendCenter({
    required String sessionToken,
  }) async {
    return const FriendCenterSnapshot.empty();
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
  RoomSnapshot? currentSnapshot(String roomId) => null;

  @override
  void clearCurrentRoomCache() {
    cacheCleared = true;
  }

  @override
  Future<void> close() async {
    await _roomController.close();
    await _notificationController.close();
  }

  void emitRoomSnapshot(RoomSnapshot snapshot) {
    _roomController.add(snapshot);
  }
}

extension on RoomSnapshot {
  RoomSnapshot copyWithPlayers(List<RoomPlayer> players) {
    return RoomSnapshot(
      roomId: roomId,
      roomCode: roomCode,
      ownerPlayerId: ownerPlayerId,
      mode: mode,
      phase: phase,
      players: players,
      selfCards: selfCards,
      landlordCards: landlordCards,
      recentActions: recentActions,
      currentTurnPlayerId: currentTurnPlayerId,
      statusText: statusText,
      cardCounter: cardCounter,
      baseScore: baseScore,
      multiplier: multiplier,
      currentRoundScore: currentRoundScore,
      springTriggered: springTriggered,
      turnSerial: turnSerial,
    );
  }
}

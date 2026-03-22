import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:landlords/src/app.dart';
import 'package:landlords/src/models/app_models.dart';
import 'package:landlords/src/models/game_models.dart';
import 'package:landlords/src/services/game_gateway.dart';

const _loginButtonText = '\u767b\u5f55\u8fdb\u5165\u5927\u5385';
const _chooseModeText = '\u9009\u62e9\u65b9\u5f0f';
const _createRoomText = '\u521b\u5efa\u623f\u95f4';
const _arrangeSeatText = '\u5b89\u6392\u5ea7\u4f4d';
const _inviteSeatText = '\u9080\u8bf7\u5165\u5ea7';
const _inviteSentText = '\u9080\u8bf7\u5df2\u53d1\u9001';
const _inviteDialogTitle = '\u6536\u5230\u9080\u8bf7';
const _acceptText = '\u540c\u610f';
const _prepareText = '\u51c6\u5907';

void main() {
  testWidgets('desktop create room flow reaches the preparing room', (
    tester,
  ) async {
    final gateway = _ScriptedGateway();

    await _pumpApp(tester, gateway, const Size(1600, 900));
    await _loginIntoLobby(tester);

    await tester.tap(find.text(_chooseModeText));
    await _advanceUi(tester);

    await tester.tap(find.text(_createRoomText).last);
    await _advanceUi(tester);

    expect(gateway.createRoomCalls, 1);
    expect(find.text(_arrangeSeatText), findsWidgets);
  });

  testWidgets('mobile create room flow reaches the preparing room', (
    tester,
  ) async {
    final gateway = _ScriptedGateway();

    await _pumpApp(tester, gateway, const Size(844, 390));
    await _loginIntoLobby(tester);

    await tester.tap(find.text(_chooseModeText));
    await _advanceUi(tester);

    await tester.tap(find.text(_createRoomText).last);
    await _advanceUi(tester);

    expect(gateway.createRoomCalls, 1);
    expect(find.text(_arrangeSeatText), findsWidgets);
  });

  testWidgets('owner invite flow shows seat dialog and success notice', (
    tester,
  ) async {
    final gateway = _ScriptedGateway();

    await _pumpApp(tester, gateway, const Size(1600, 900));
    await _loginIntoLobby(tester);
    await tester.tap(find.text(_chooseModeText));
    await _advanceUi(tester);
    await tester.tap(find.text(_createRoomText).last);
    await _advanceUi(tester);

    await tester.tap(find.text(_arrangeSeatText).first);
    await _advanceUi(tester);

    expect(find.text(_arrangeSeatText), findsWidgets);

    final inviteButton = find.text(_inviteSeatText).first;
    await tester.ensureVisible(inviteButton);
    await _advanceUi(tester);
    await tester.tap(inviteButton);
    await _advanceUi(tester);

    expect(gateway.lastInvitedAccount, 'friend1');
    expect(gateway.lastInvitedSeatIndex, isNotNull);
    expect(find.text(_inviteSentText), findsOneWidget);

    await tester.tap(find.byType(FilledButton).last);
    await _advanceUi(tester);

    expect(find.text(_inviteSentText), findsNothing);
  });

  testWidgets('invitee sees invitation dialog and accepting enters room', (
    tester,
  ) async {
    final gateway = _ScriptedGateway();

    await _pumpApp(tester, gateway, const Size(1600, 900));
    await _loginIntoLobby(tester);

    gateway.emitInvitation();
    await tester.pump();
    await _advanceUi(tester);

    expect(find.text(_inviteDialogTitle), findsOneWidget);

    await tester.tap(find.text(_acceptText));
    await _advanceUi(tester);

    expect(gateway.acceptInvitationCalls, 1);
    expect(find.text(_prepareText), findsWidgets);
  });

  testWidgets('expired invitation closes the dialog and shows one timeout notice', (
    tester,
  ) async {
    final gateway = _ScriptedGateway()..expireInvitationOnResponse = true;

    await _pumpApp(tester, gateway, const Size(1600, 900));
    await _loginIntoLobby(tester);

    gateway.emitInvitation();
    await tester.pump();
    await _advanceUi(tester);

    expect(find.text(_inviteDialogTitle), findsOneWidget);

    await tester.tap(find.text(_acceptText));
    await _advanceUi(tester);

    expect(find.textContaining('超时'), findsOneWidget);
    expect(find.text(_inviteDialogTitle), findsNothing);

    await _advanceUi(tester);
    expect(find.textContaining('超时'), findsOneWidget);
  });
}

Future<void> _pumpApp(
  WidgetTester tester,
  _ScriptedGateway gateway,
  Size logicalSize,
) async {
  tester.view.physicalSize = logicalSize;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(LandlordsApp(gateway: gateway));
  await _advanceUi(tester);
}

Future<void> _loginIntoLobby(WidgetTester tester) async {
  await tester.tap(find.text(_loginButtonText));
  await _advanceUi(tester);
  expect(find.text(_chooseModeText), findsOneWidget);
}

Future<void> _advanceUi(WidgetTester tester) async {
  await tester.pump();
  for (var index = 0; index < 8; index++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}

class _ScriptedGateway implements GameGateway {
  _ScriptedGateway() {
    _usersByAccount['player1'] = const UserProfile(
      userId: 'user-player1',
      account: 'player1',
      nickname: '\u73a9\u5bb61',
      coins: 120,
      landlordWins: 5,
      landlordGames: 10,
      farmerWins: 7,
      farmerGames: 14,
    );
    _usersByAccount['friend1'] = const UserProfile(
      userId: 'user-friend1',
      account: 'friend1',
      nickname: '\u597d\u53cb1',
      coins: 88,
      landlordWins: 2,
      landlordGames: 4,
      farmerWins: 3,
      farmerGames: 6,
    );
  }

  final StreamController<RoomSnapshot> _snapshotController =
      StreamController<RoomSnapshot>.broadcast();
  final StreamController<GatewayNotification> _notificationController =
      StreamController<GatewayNotification>.broadcast();
  final Map<String, UserProfile> _usersByAccount = <String, UserProfile>{};
  final Map<String, String> _sessionToAccount = <String, String>{};

  RoomSnapshot? _currentSnapshot;
  RoomInvitation? _lastInvitation;
  int createRoomCalls = 0;
  int acceptInvitationCalls = 0;
  String? lastInvitedAccount;
  int? lastInvitedSeatIndex;
  bool expireInvitationOnResponse = false;
  int _idSeed = 0;

  @override
  Stream<RoomSnapshot> get roomSnapshots => _snapshotController.stream;

  @override
  Stream<GatewayNotification> get notifications => _notificationController.stream;

  @override
  void clearCurrentRoomCache() {
    _currentSnapshot = null;
  }

  @override
  void forgetSession() {}

  @override
  Future<void> register({
    required String account,
    required String nickname,
    required String password,
  }) async {
    _usersByAccount[account] = UserProfile(
      userId: 'user-$account',
      account: account,
      nickname: nickname,
      coins: 0,
    );
  }

  @override
  Future<LoginResult> login({
    required String account,
    required String password,
  }) async {
    final profile = _usersByAccount[account];
    if (profile == null) {
      throw Exception('invalid account or password');
    }
    final sessionToken = 'session-${_nextId()}';
    _sessionToAccount[sessionToken] = account;
    return LoginResult(profile: profile, sessionToken: sessionToken);
  }

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
    final account = _requireAccount(sessionToken);
    final updated = _usersByAccount[account]!.copyWith(nickname: nickname);
    _usersByAccount[account] = updated;
    return updated;
  }

  @override
  Future<RoomSnapshot> startMatch({
    required String sessionToken,
    required UserProfile profile,
    required MatchMode mode,
    BotDifficulty botDifficulty = BotDifficulty.normal,
  }) async {
    final snapshot = _buildPreparingRoom(owner: profile);
    _publishSnapshot(snapshot);
    return snapshot;
  }

  @override
  Future<RoomSnapshot> createRoom({
    required String sessionToken,
  }) async {
    createRoomCalls += 1;
    final owner = _usersByAccount[_requireAccount(sessionToken)]!;
    final snapshot = _buildPreparingRoom(owner: owner);
    _publishSnapshot(snapshot);
    return snapshot;
  }

  @override
  Future<RoomSnapshot> joinRoom({
    required String sessionToken,
    required String roomCode,
  }) async {
    final player = _usersByAccount[_requireAccount(sessionToken)]!;
    final snapshot = _buildJoinedRoom(invitee: player);
    _publishSnapshot(snapshot);
    return snapshot;
  }

  @override
  Future<void> leaveRoom({
    required String sessionToken,
    required String roomId,
  }) async {
    _currentSnapshot = null;
  }

  @override
  Future<RoomSnapshot> setRoomReady({
    required String sessionToken,
    required String roomId,
    required bool ready,
  }) async {
    final snapshot = _currentSnapshot;
    if (snapshot == null) {
      throw Exception('room not found');
    }
    final account = _requireAccount(sessionToken);
    final player = _usersByAccount[account]!;
    final updatedPlayers = snapshot.players
        .map(
          (item) => item.playerId == player.userId
              ? RoomPlayer(
                  playerId: item.playerId,
                  displayName: item.displayName,
                  isBot: item.isBot,
                  role: item.role,
                  cardsLeft: item.cardsLeft,
                  roundScore: item.roundScore,
                  seatIndex: item.seatIndex,
                  ready: ready,
                  occupied: item.occupied,
                )
              : item,
        )
        .toList(growable: false);
    final updated = RoomSnapshot(
      roomId: snapshot.roomId,
      roomCode: snapshot.roomCode,
      ownerPlayerId: snapshot.ownerPlayerId,
      mode: snapshot.mode,
      phase: snapshot.phase,
      players: updatedPlayers,
      selfCards: snapshot.selfCards,
      landlordCards: snapshot.landlordCards,
      recentActions: snapshot.recentActions,
      currentTurnPlayerId: snapshot.currentTurnPlayerId,
      statusText: snapshot.statusText,
      cardCounter: snapshot.cardCounter,
      baseScore: snapshot.baseScore,
      multiplier: snapshot.multiplier,
      currentRoundScore: snapshot.currentRoundScore,
      springTriggered: snapshot.springTriggered,
      turnSerial: snapshot.turnSerial,
    );
    _publishSnapshot(updated);
    return updated;
  }

  @override
  Future<RoomSnapshot> addBot({
    required String sessionToken,
    required String roomId,
    required int seatIndex,
    BotDifficulty botDifficulty = BotDifficulty.normal,
  }) async {
    final snapshot = _currentSnapshot;
    if (snapshot == null) {
      throw Exception('room not found');
    }
    final updatedPlayers = snapshot.players
        .map(
          (item) => item.seatIndex == seatIndex
              ? RoomPlayer(
                  playerId: 'bot-$seatIndex',
                  displayName: '\u673a\u5668\u4eba',
                  isBot: true,
                  role: PlayerRole.farmer,
                  cardsLeft: 17,
                  roundScore: 0,
                  seatIndex: seatIndex,
                  ready: false,
                  occupied: true,
                )
              : item,
        )
        .toList(growable: false);
    final updated = RoomSnapshot(
      roomId: snapshot.roomId,
      roomCode: snapshot.roomCode,
      ownerPlayerId: snapshot.ownerPlayerId,
      mode: snapshot.mode,
      phase: snapshot.phase,
      players: updatedPlayers,
      selfCards: snapshot.selfCards,
      landlordCards: snapshot.landlordCards,
      recentActions: snapshot.recentActions,
      currentTurnPlayerId: snapshot.currentTurnPlayerId,
      statusText: snapshot.statusText,
      cardCounter: snapshot.cardCounter,
      baseScore: snapshot.baseScore,
      multiplier: snapshot.multiplier,
      currentRoundScore: snapshot.currentRoundScore,
      springTriggered: snapshot.springTriggered,
      turnSerial: snapshot.turnSerial,
    );
    _publishSnapshot(updated);
    return updated;
  }

  @override
  Future<RoomSnapshot> removePlayer({
    required String sessionToken,
    required String roomId,
    required String playerId,
  }) async {
    final snapshot = _currentSnapshot;
    if (snapshot == null) {
      throw Exception('room not found');
    }
    final updatedPlayers = snapshot.players
        .map(
          (item) => item.playerId == playerId
              ? RoomPlayer(
                  playerId: '',
                  displayName: '',
                  isBot: false,
                  role: PlayerRole.farmer,
                  cardsLeft: 0,
                  roundScore: 0,
                  seatIndex: item.seatIndex,
                  ready: false,
                  occupied: false,
                )
              : item,
        )
        .toList(growable: false);
    final updated = RoomSnapshot(
      roomId: snapshot.roomId,
      roomCode: snapshot.roomCode,
      ownerPlayerId: snapshot.ownerPlayerId,
      mode: snapshot.mode,
      phase: snapshot.phase,
      players: updatedPlayers,
      selfCards: snapshot.selfCards,
      landlordCards: snapshot.landlordCards,
      recentActions: snapshot.recentActions,
      currentTurnPlayerId: snapshot.currentTurnPlayerId,
      statusText: snapshot.statusText,
      cardCounter: snapshot.cardCounter,
      baseScore: snapshot.baseScore,
      multiplier: snapshot.multiplier,
      currentRoundScore: snapshot.currentRoundScore,
      springTriggered: snapshot.springTriggered,
      turnSerial: snapshot.turnSerial,
    );
    _publishSnapshot(updated);
    return updated;
  }

  @override
  Future<FriendCenterSnapshot> fetchFriendCenter({
    required String sessionToken,
  }) async {
    return const FriendCenterSnapshot(
      friends: [
        OnlineUser(
          userId: 'user-friend1',
          account: 'friend1',
          nickname: '\u597d\u53cb1',
          online: true,
        ),
      ],
      pendingRequests: [],
      historyRequests: [],
      pendingRequestCount: 0,
    );
  }

  @override
  Future<FriendCenterSnapshot> sendFriendRequest({
    required String sessionToken,
    required String account,
  }) async {
    return fetchFriendCenter(sessionToken: sessionToken);
  }

  @override
  Future<FriendCenterSnapshot> respondFriendRequest({
    required String sessionToken,
    required String requestId,
    required bool accept,
  }) async {
    return fetchFriendCenter(sessionToken: sessionToken);
  }

  @override
  Future<FriendCenterSnapshot> deleteFriend({
    required String sessionToken,
    required String friendUserId,
  }) async {
    return fetchFriendCenter(sessionToken: sessionToken);
  }

  @override
  Future<void> invitePlayer({
    required String sessionToken,
    required String roomId,
    required String targetAccount,
    required int seatIndex,
  }) async {
    lastInvitedAccount = targetAccount;
    lastInvitedSeatIndex = seatIndex;
  }

  @override
  Future<RoomSnapshot?> respondInvitation({
    required String sessionToken,
    required String invitationId,
    required bool accept,
  }) async {
    if (expireInvitationOnResponse) {
      throw Exception('invitation timed out');
    }
    if (!accept) {
      return null;
    }
    acceptInvitationCalls += 1;
    final invitee = _usersByAccount[_requireAccount(sessionToken)]!;
    final snapshot = _buildJoinedRoom(invitee: invitee);
    _publishSnapshot(snapshot);
    return snapshot;
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
    if (_currentSnapshot == null) {
      throw Exception('room not found');
    }
    return _currentSnapshot!;
  }

  @override
  Future<RoomSnapshot> callScore({
    required String sessionToken,
    required String roomId,
    required int score,
  }) async {
    return playCards(
      sessionToken: sessionToken,
      roomId: roomId,
      cardIds: <String>['bid:$score'],
    );
  }

  @override
  Future<RoomSnapshot> setManaged({
    required String sessionToken,
    required String roomId,
    required bool managed,
  }) async {
    if (_currentSnapshot == null) {
      throw Exception('room not found');
    }
    return _currentSnapshot!;
  }

  @override
  Future<RoomSnapshot> pass({
    required String sessionToken,
    required String roomId,
  }) async {
    if (_currentSnapshot == null) {
      throw Exception('room not found');
    }
    return _currentSnapshot!;
  }

  @override
  Future<List<String>> requestSuggestion({
    required String sessionToken,
    required String roomId,
  }) async {
    return const <String>[];
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
  Future<RoomSnapshot?> refreshCurrentRoom() async => _currentSnapshot;

  @override
  RoomSnapshot? currentSnapshot(String roomId) =>
      _currentSnapshot?.roomId == roomId ? _currentSnapshot : null;

  @override
  Future<void> close() async {
    await _snapshotController.close();
    await _notificationController.close();
  }

  void emitInvitation() {
    final invitation = RoomInvitation(
      invitationId: 'invite-${_nextId()}',
      roomId: 'room-guest',
      roomCode: '654321',
      inviterUserId: 'user-friend1',
      inviterAccount: 'friend1',
      inviterNickname: '\u597d\u53cb1',
      seatIndex: 1,
    );
    _lastInvitation = invitation;
    _notificationController.add(RoomInvitationNotification(invitation));
  }

  RoomSnapshot _buildPreparingRoom({
    required UserProfile owner,
  }) {
    return RoomSnapshot(
      roomId: 'room-owner',
      roomCode: '123456',
      ownerPlayerId: owner.userId,
      mode: MatchMode.online,
      phase: RoomPhase.preparing,
      players: <RoomPlayer>[
        RoomPlayer(
          playerId: owner.userId,
          displayName: owner.displayName,
          isBot: false,
          role: PlayerRole.farmer,
          cardsLeft: 17,
          roundScore: 0,
          seatIndex: 0,
          ready: false,
          occupied: true,
        ),
        const RoomPlayer(
          playerId: '',
          displayName: '',
          isBot: false,
          role: PlayerRole.farmer,
          cardsLeft: 0,
          roundScore: 0,
          seatIndex: 1,
          ready: false,
          occupied: false,
        ),
        const RoomPlayer(
          playerId: '',
          displayName: '',
          isBot: false,
          role: PlayerRole.farmer,
          cardsLeft: 0,
          roundScore: 0,
          seatIndex: 2,
          ready: false,
          occupied: false,
        ),
      ],
      selfCards: const <PlayingCard>[],
      landlordCards: const <PlayingCard>[],
      recentActions: const <TableAction>[],
      currentTurnPlayerId: '',
      statusText: 'waiting_for_players',
      cardCounter: const <CardCounterEntry>[],
      baseScore: 1,
      multiplier: 1,
      currentRoundScore: 0,
      springTriggered: false,
      turnSerial: 0,
    );
  }

  RoomSnapshot _buildJoinedRoom({
    required UserProfile invitee,
  }) {
    return RoomSnapshot(
      roomId: _lastInvitation?.roomId ?? 'room-guest',
      roomCode: _lastInvitation?.roomCode ?? '654321',
      ownerPlayerId: 'user-friend1',
      mode: MatchMode.online,
      phase: RoomPhase.preparing,
      players: <RoomPlayer>[
        const RoomPlayer(
          playerId: 'user-friend1',
          displayName: '\u597d\u53cb1',
          isBot: false,
          role: PlayerRole.farmer,
          cardsLeft: 17,
          roundScore: 0,
          seatIndex: 0,
          ready: false,
          occupied: true,
        ),
        RoomPlayer(
          playerId: invitee.userId,
          displayName: invitee.displayName,
          isBot: false,
          role: PlayerRole.farmer,
          cardsLeft: 17,
          roundScore: 0,
          seatIndex: 1,
          ready: false,
          occupied: true,
        ),
        const RoomPlayer(
          playerId: '',
          displayName: '',
          isBot: false,
          role: PlayerRole.farmer,
          cardsLeft: 0,
          roundScore: 0,
          seatIndex: 2,
          ready: false,
          occupied: false,
        ),
      ],
      selfCards: const <PlayingCard>[],
      landlordCards: const <PlayingCard>[],
      recentActions: const <TableAction>[],
      currentTurnPlayerId: '',
      statusText: 'waiting_for_ready',
      cardCounter: const <CardCounterEntry>[],
      baseScore: 1,
      multiplier: 1,
      currentRoundScore: 0,
      springTriggered: false,
      turnSerial: 0,
    );
  }

  void _publishSnapshot(RoomSnapshot snapshot) {
    _currentSnapshot = snapshot;
    _snapshotController.add(snapshot);
  }

  String _requireAccount(String sessionToken) {
    final account = _sessionToAccount[sessionToken];
    if (account == null) {
      throw Exception('login required');
    }
    return account;
  }

  int _nextId() {
    _idSeed += 1;
    return _idSeed;
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';

import '../models/app_models.dart' as app;
import '../models/game_models.dart';
import '../proto/landlords.pb.dart' as pb;
import '../proto/landlords.pbenum.dart' as pbenum;
import 'game_gateway.dart';

class SocketGameGateway implements GameGateway {
  SocketGameGateway({
    this.host = '127.0.0.1',
    this.port = 23001,
  });

  final String host;
  final int port;

  static const String _suggestCommand = '__hint__';
  static const String _cancelMatchCommand = 'match:cancel';
  static const String _presentationAckPrefix = '__presented__:';
  static const Duration _requestTimeout = Duration(seconds: 45);

  final StreamController<RoomSnapshot> _snapshotController =
      StreamController<RoomSnapshot>.broadcast();
  final StreamController<GatewayNotification> _notificationController =
      StreamController<GatewayNotification>.broadcast();
  final Map<String, Completer<pb.ServerMessage>> _pending = {};
  final List<int> _buffer = <int>[];

  Socket? _socket;
  Future<void>? _connectFuture;
  StreamSubscription<List<int>>? _subscription;
  Timer? _heartbeatTimer;
  String? _sessionToken;
  String? _lastRoomId;
  RoomSnapshot? _latestSnapshot;

  @override
  Stream<RoomSnapshot> get roomSnapshots => _snapshotController.stream;

  @override
  Stream<GatewayNotification> get notifications =>
      _notificationController.stream;

  Future<void> _ensureConnected() async {
    if (_socket != null) {
      return;
    }
    if (_connectFuture != null) {
      return _connectFuture;
    }
    _connectFuture = _openConnection();
    try {
      await _connectFuture;
    } finally {
      _connectFuture = null;
    }
  }

  @override
  Future<void> register({
    required String account,
    required String nickname,
    required String password,
  }) async {
    await _ensureConnected();
    final response = await _send(
      (message) => message.registerRequest = pb.RegisterRequest(
        account: account,
        nickname: nickname,
        password: password,
      ),
    );
    if (!response.hasRegisterResponse() || !response.registerResponse.success) {
      throw Exception(
        response.hasRegisterResponse()
            ? response.registerResponse.message
            : response.errorResponse.message,
      );
    }
  }

  @override
  Future<LoginResult> login({
    required String account,
    required String password,
  }) async {
    await _ensureConnected();
    final response = await _send(
      (message) => message.loginRequest = pb.LoginRequest(
        account: account,
        password: password,
      ),
    );
    if (!response.hasLoginResponse() || !response.loginResponse.success) {
      throw Exception(
        response.hasLoginResponse()
            ? response.loginResponse.message
            : response.errorResponse.message,
      );
    }
    _sessionToken = response.loginResponse.sessionToken;
    return LoginResult(
      profile: _mapUserProfile(response.loginResponse.profile),
      sessionToken: response.loginResponse.sessionToken,
    );
  }

  @override
  Future<void> resetPassword({
    required String account,
    required String newPassword,
  }) async {
    await _ensureConnected();
    final response = await _send(
      (message) => message.resetPasswordRequest = pb.ResetPasswordRequest(
        account: account,
        newPassword: newPassword,
      ),
    );
    if (!response.hasResetPasswordResponse() ||
        !response.resetPasswordResponse.success) {
      throw Exception(
        response.hasResetPasswordResponse()
            ? response.resetPasswordResponse.message
            : response.errorResponse.message,
      );
    }
  }

  @override
  Future<RoomSnapshot> startMatch({
    required String sessionToken,
    required app.UserProfile profile,
    required app.MatchMode mode,
    app.BotDifficulty botDifficulty = app.BotDifficulty.normal,
  }) async {
    await _ensureConnected();
    _sessionToken = sessionToken;
    final previousSnapshot = _latestSnapshot;
    final snapshotFuture = roomSnapshots.firstWhere((snapshot) {
      if (previousSnapshot == null) {
        return true;
      }
      return snapshot.roomId != previousSnapshot.roomId ||
          snapshot.turnSerial != previousSnapshot.turnSerial ||
          snapshot.phase != previousSnapshot.phase ||
          snapshot.recentActions.length != previousSnapshot.recentActions.length;
    });
    final response = await _send(
      (message) => message.matchRequest = pb.MatchRequest(
        mode: mode == app.MatchMode.vsBot
            ? pbenum.MatchMode.MATCH_MODE_VS_BOT
            : pbenum.MatchMode.MATCH_MODE_PVP,
        botDifficulty: switch (botDifficulty) {
          app.BotDifficulty.easy => pbenum.BotDifficulty.BOT_DIFFICULTY_EASY,
          app.BotDifficulty.hard => pbenum.BotDifficulty.BOT_DIFFICULTY_HARD,
          app.BotDifficulty.normal => pbenum.BotDifficulty.BOT_DIFFICULTY_NORMAL,
        },
      ),
      sessionToken: sessionToken,
    );
    if (response.hasErrorResponse()) {
      throw Exception(response.errorResponse.message);
    }
    if (!response.hasMatchResponse() || !response.matchResponse.accepted) {
      throw Exception(
        response.hasMatchResponse()
            ? response.matchResponse.message
            : '匹配失败',
      );
    }
    final snapshot = await snapshotFuture.timeout(_requestTimeout);
    _lastRoomId = snapshot.roomId;
    return snapshot;
  }

  @override
  Future<RoomSnapshot> createRoom({
    required String sessionToken,
  }) async {
    await _ensureConnected();
    final response = await _send(
      (message) => message.createRoomRequest = pb.CreateRoomRequest(),
      sessionToken: sessionToken,
    );
    if (response.hasErrorResponse()) {
      throw Exception(response.errorResponse.message);
    }
    final snapshot = _mapSnapshot(response.operationResponse.snapshot);
    _publishSnapshot(snapshot);
    return snapshot;
  }

  @override
  Future<RoomSnapshot> joinRoom({
    required String sessionToken,
    required String roomCode,
  }) async {
    await _ensureConnected();
    final response = await _send(
      (message) =>
          message.joinRoomRequest = pb.JoinRoomRequest(roomCode: roomCode),
      sessionToken: sessionToken,
    );
    if (response.hasErrorResponse()) {
      throw Exception(response.errorResponse.message);
    }
    final snapshot = _mapSnapshot(response.operationResponse.snapshot);
    _publishSnapshot(snapshot);
    return snapshot;
  }

  @override
  Future<void> leaveRoom({
    required String sessionToken,
    required String roomId,
  }) async {
    await _ensureConnected();
    final response = await _send(
      (message) => message.leaveRoomRequest = pb.LeaveRoomRequest(roomId: roomId),
      sessionToken: sessionToken,
    );
    if (response.hasErrorResponse()) {
      throw Exception(response.errorResponse.message);
    }
  }

  @override
  Future<RoomSnapshot> setRoomReady({
    required String sessionToken,
    required String roomId,
    required bool ready,
  }) async {
    final response = await _send(
      (message) => message.roomReadyRequest = pb.RoomReadyRequest(
        roomId: roomId,
        ready: ready,
      ),
      sessionToken: sessionToken,
    );
    if (response.hasErrorResponse()) {
      throw Exception(response.errorResponse.message);
    }
    final snapshot = _mapSnapshot(response.operationResponse.snapshot);
    _publishSnapshot(snapshot);
    return snapshot;
  }

  @override
  Future<RoomSnapshot> addBot({
    required String sessionToken,
    required String roomId,
    required int seatIndex,
    app.BotDifficulty botDifficulty = app.BotDifficulty.normal,
  }) async {
    final response = await _send(
      (message) => message.addBotRequest = pb.AddBotRequest(
        roomId: roomId,
        seatIndex: seatIndex,
        botDifficulty: switch (botDifficulty) {
          app.BotDifficulty.easy => pbenum.BotDifficulty.BOT_DIFFICULTY_EASY,
          app.BotDifficulty.hard => pbenum.BotDifficulty.BOT_DIFFICULTY_HARD,
          app.BotDifficulty.normal => pbenum.BotDifficulty.BOT_DIFFICULTY_NORMAL,
        },
      ),
      sessionToken: sessionToken,
    );
    if (response.hasErrorResponse()) {
      throw Exception(response.errorResponse.message);
    }
    final snapshot = _mapSnapshot(response.operationResponse.snapshot);
    _publishSnapshot(snapshot);
    return snapshot;
  }

  @override
  Future<RoomSnapshot> removePlayer({
    required String sessionToken,
    required String roomId,
    required String playerId,
  }) async {
    final response = await _send(
      (message) => message.removePlayerRequest = pb.RemovePlayerRequest(
        roomId: roomId,
        playerId: playerId,
      ),
      sessionToken: sessionToken,
    );
    if (response.hasErrorResponse()) {
      throw Exception(response.errorResponse.message);
    }
    final snapshot = _mapSnapshot(response.operationResponse.snapshot);
    _publishSnapshot(snapshot);
    return snapshot;
  }

  @override
  Future<List<app.OnlineUser>> fetchFriends({
    required String sessionToken,
  }) async {
    final response = await _send(
      (message) => message.listFriendsRequest = pb.ListFriendsRequest(),
      sessionToken: sessionToken,
    );
    if (response.hasErrorResponse()) {
      throw Exception(response.errorResponse.message);
    }
    if (!response.hasListFriendsResponse()) {
      throw Exception('未收到好友列表');
    }
    return response.listFriendsResponse.users
        .map(_mapOnlineUser)
        .toList(growable: false);
  }

  @override
  Future<app.OnlineUser> addFriend({
    required String sessionToken,
    required String account,
  }) async {
    final response = await _send(
      (message) => message.addFriendRequest = pb.AddFriendRequest(
        account: account,
      ),
      sessionToken: sessionToken,
    );
    if (response.hasErrorResponse()) {
      throw Exception(response.errorResponse.message);
    }
    if (!response.hasAddFriendResponse() || !response.addFriendResponse.success) {
      throw Exception(
        response.hasAddFriendResponse()
            ? response.addFriendResponse.message
            : response.errorResponse.message,
      );
    }
    return _mapOnlineUser(response.addFriendResponse.user);
  }

  @override
  Future<void> invitePlayer({
    required String sessionToken,
    required String roomId,
    required String targetAccount,
    required int seatIndex,
  }) async {
    final response = await _send(
      (message) => message.invitePlayerRequest = pb.InvitePlayerRequest(
        roomId: roomId,
        inviteeAccount: targetAccount,
        seatIndex: seatIndex,
      ),
      sessionToken: sessionToken,
    );
    if (response.hasErrorResponse()) {
      throw Exception(response.errorResponse.message);
    }
    if (!response.hasInvitePlayerResponse()) {
      throw Exception('邀请请求没有返回结果');
    }
    if (!response.invitePlayerResponse.accepted) {
      throw Exception(response.invitePlayerResponse.message);
    }
  }

  @override
  Future<RoomSnapshot?> respondInvitation({
    required String sessionToken,
    required String invitationId,
    required bool accept,
  }) async {
    final response = await _send(
      (message) =>
          message.respondRoomInvitationRequest = pb.RespondRoomInvitationRequest(
        invitationId: invitationId,
        accept: accept,
      ),
      sessionToken: sessionToken,
    );
    if (response.hasErrorResponse()) {
      throw Exception(response.errorResponse.message);
    }
    if (!response.hasRespondRoomInvitationResponse()) {
      throw Exception('邀请响应没有返回结果');
    }
    if (!response.respondRoomInvitationResponse.success) {
      throw Exception(response.respondRoomInvitationResponse.message);
    }
    if (response.respondRoomInvitationResponse.hasSnapshot()) {
      final snapshot = _mapSnapshot(response.respondRoomInvitationResponse.snapshot);
      _publishSnapshot(snapshot);
      return snapshot;
    }
    return null;
  }

  @override
  Future<void> cancelMatch({
    required String sessionToken,
  }) async {
    final response = await _send(
      (message) => message.playCardsRequest = pb.PlayCardsRequest(
        roomId: '',
        cardIds: const [_cancelMatchCommand],
      ),
      sessionToken: sessionToken,
    );
    if (response.hasErrorResponse()) {
      throw Exception(response.errorResponse.message);
    }
  }

  @override
  Future<RoomSnapshot> playCards({
    required String sessionToken,
    required String roomId,
    required List<String> cardIds,
  }) async {
    final response = await _send(
      (message) => message.playCardsRequest = pb.PlayCardsRequest(
        roomId: roomId,
        cardIds: cardIds,
      ),
      sessionToken: sessionToken,
    );
    if (response.hasErrorResponse()) {
      throw Exception(response.errorResponse.message);
    }
    final snapshot = _mapSnapshot(response.operationResponse.snapshot);
    _publishSnapshot(snapshot);
    return snapshot;
  }

  @override
  Future<RoomSnapshot> callScore({
    required String sessionToken,
    required String roomId,
    required int score,
  }) {
    return playCards(
      sessionToken: sessionToken,
      roomId: roomId,
      cardIds: ['bid:$score'],
    );
  }

  @override
  Future<RoomSnapshot> setManaged({
    required String sessionToken,
    required String roomId,
    required bool managed,
  }) {
    return playCards(
      sessionToken: sessionToken,
      roomId: roomId,
      cardIds: [managed ? 'auto:on' : 'auto:off'],
    );
  }

  @override
  Future<RoomSnapshot> pass({
    required String sessionToken,
    required String roomId,
  }) async {
    final response = await _send(
      (message) => message.passRequest = pb.PassRequest(roomId: roomId),
      sessionToken: sessionToken,
    );
    if (response.hasErrorResponse()) {
      throw Exception(response.errorResponse.message);
    }
    final snapshot = _mapSnapshot(response.operationResponse.snapshot);
    _publishSnapshot(snapshot);
    return snapshot;
  }

  @override
  Future<List<String>> requestSuggestion({
    required String sessionToken,
    required String roomId,
  }) async {
    final response = await _send(
      (message) => message.playCardsRequest = pb.PlayCardsRequest(
        roomId: roomId,
        cardIds: const [_suggestCommand],
      ),
      sessionToken: sessionToken,
    );
    if (response.hasErrorResponse()) {
      throw Exception(response.errorResponse.message);
    }
    final snapshot = _mapSnapshot(response.operationResponse.snapshot);
    _publishSnapshot(snapshot);
    final message = response.operationResponse.message;
    if (!message.startsWith('suggest:')) {
      return const [];
    }
    final payload = message.substring('suggest:'.length);
    if (payload.isEmpty) {
      return const [];
    }
    return payload.split(',').where((item) => item.isNotEmpty).toList();
  }

  @override
  Future<void> acknowledgePresentation({
    required String sessionToken,
    required String roomId,
    required String actionId,
  }) async {
    final response = await _send(
      (message) => message.playCardsRequest = pb.PlayCardsRequest(
        roomId: roomId,
        cardIds: <String>['$_presentationAckPrefix$actionId'],
      ),
      sessionToken: sessionToken,
    );
    if (response.hasErrorResponse()) {
      throw Exception(response.errorResponse.message);
    }
    if (response.hasOperationResponse() &&
        response.operationResponse.hasSnapshot()) {
      _publishSnapshot(_mapSnapshot(response.operationResponse.snapshot));
    }
  }

  @override
  Future<RoomSnapshot?> refreshCurrentRoom() async {
    if (_sessionToken == null || _lastRoomId == null) {
      return null;
    }
    final response = await reconnect();
    if (!response.hasRoomSnapshot()) {
      return null;
    }
    final snapshot = _mapSnapshot(response.roomSnapshot);
    _publishSnapshot(snapshot);
    return snapshot;
  }

  @override
  RoomSnapshot? currentSnapshot(String roomId) =>
      _latestSnapshot?.roomId == roomId ? _latestSnapshot : null;

  Future<pb.ServerMessage> reconnect() async {
    if (_sessionToken == null || _lastRoomId == null) {
      throw Exception('没有可重连的房间');
    }
    await _ensureConnected();
    return _send(
      (message) =>
          message.reconnectRequest = pb.ReconnectRequest(roomId: _lastRoomId),
      sessionToken: _sessionToken,
    );
  }

  Future<pb.ServerMessage> _send(
    void Function(pb.ClientMessage message) build, {
    String? sessionToken,
  }) async {
    await _ensureConnected();
    final requestId = _id();
    final message = pb.ClientMessage(
      requestId: requestId,
      sessionToken: sessionToken ?? _sessionToken ?? '',
    );
    build(message);

    final payload = message.writeToBuffer();
    final header = ByteData(4)..setUint32(0, payload.length, Endian.big);
    final completer = Completer<pb.ServerMessage>();
    _pending[requestId] = completer;
    if (_socket == null) {
      _pending.remove(requestId);
      throw Exception('服务连接不可用');
    }
    _socket!.add(header.buffer.asUint8List());
    _socket!.add(payload);
    await _socket!.flush();
    return completer.future.timeout(_requestTimeout, onTimeout: () {
      _pending.remove(requestId);
      throw Exception('服务响应超时');
    });
  }

  void _onData(List<int> data) {
    _buffer.addAll(data);
    final bytes = Uint8List.fromList(_buffer);
    var offset = 0;
    while (bytes.length - offset >= 4) {
      final frameLength =
          ByteData.sublistView(Uint8List.fromList(bytes), offset, offset + 4)
              .getUint32(0, Endian.big);
      if (bytes.length - offset - 4 < frameLength) {
        break;
      }
      final frame = bytes.sublist(offset + 4, offset + 4 + frameLength);
      offset += 4 + frameLength;

      final message = pb.ServerMessage.fromBuffer(frame);
      if (message.hasRoomSnapshot()) {
        _publishSnapshot(_mapSnapshot(message.roomSnapshot));
      }
      if (message.hasRoomInvitationPush()) {
        _notificationController.add(
          RoomInvitationNotification(
            _mapInvitation(message.roomInvitationPush),
          ),
        );
      }
      if (message.hasRoomInvitationResultPush()) {
        _notificationController.add(
          InvitationFeedbackNotification(
            _mapInvitationFeedback(message.roomInvitationResultPush),
          ),
        );
      }
      if (message.requestId.isNotEmpty) {
        _pending.remove(message.requestId)?.complete(message);
      }
    }

    _buffer
      ..clear()
      ..addAll(bytes.sublist(offset));
  }

  Future<void> _openConnection() async {
    _socket = await Socket.connect(host, port, timeout: const Duration(seconds: 5));
    _subscription = _socket!.listen(
      _onData,
      onDone: _handleDisconnect,
      onError: (Object error, StackTrace stackTrace) => _handleDisconnect(error),
      cancelOnError: true,
    );
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (_sessionToken != null) {
        _send(
          (message) => message.heartbeatRequest = pb.HeartbeatRequest(
            clientTimeMs: Int64(DateTime.now().millisecondsSinceEpoch),
          ),
        ).ignore();
      }
    });
    if (_sessionToken != null && _lastRoomId != null) {
      unawaited(reconnect());
    }
  }

  void _handleDisconnect([Object? error]) {
    _socket?.destroy();
    _socket = null;
    _subscription?.cancel();
    _subscription = null;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _buffer.clear();
    final pending = Map<String, Completer<pb.ServerMessage>>.from(_pending);
    _pending.clear();
    final failure = error ?? Exception('连接已断开');
    for (final completer in pending.values) {
      if (!completer.isCompleted) {
        completer.completeError(failure);
      }
    }
  }

  void _publishSnapshot(RoomSnapshot snapshot) {
    _latestSnapshot = snapshot;
    _lastRoomId = snapshot.roomId;
    _snapshotController.add(snapshot);
  }

  app.UserProfile _mapUserProfile(pb.UserProfile profile) => app.UserProfile(
        userId: profile.userId,
        account: profile.account,
        nickname: profile.nickname,
        coins: profile.totalScore,
        landlordWins: profile.landlordWins,
        landlordGames: profile.landlordGames,
        farmerWins: profile.farmerWins,
        farmerGames: profile.farmerGames,
      );

  app.OnlineUser _mapOnlineUser(pb.OnlineUser user) => app.OnlineUser(
        userId: user.userId,
        account: user.account,
        nickname: user.nickname,
        online: user.online,
      );

  RoomSnapshot _mapSnapshot(pb.RoomSnapshot snapshot) {
    final players = snapshot.players
        .map(
          (player) => RoomPlayer(
            playerId: player.playerId,
            displayName: player.isBot ? '机器人' : player.displayName,
            isBot: player.isBot,
            role: player.role == pbenum.PlayerRole.PLAYER_ROLE_LANDLORD
                ? app.PlayerRole.landlord
                : app.PlayerRole.farmer,
            cardsLeft: player.cardsLeft,
            roundScore: player.roundScore,
            seatIndex: player.seatIndex,
            ready: player.ready,
            occupied: player.occupied,
          ),
        )
        .toList();
    final namesById = {
      for (final player in players) player.playerId: player.displayName,
    };
    return RoomSnapshot(
      roomId: snapshot.roomId,
      roomCode: snapshot.roomCode,
      ownerPlayerId: snapshot.ownerPlayerId,
      mode: snapshot.mode == pbenum.MatchMode.MATCH_MODE_VS_BOT
          ? app.MatchMode.vsBot
          : app.MatchMode.online,
      phase: switch (snapshot.phase) {
        pbenum.RoomPhase.ROOM_PHASE_PREPARING => app.RoomPhase.preparing,
        pbenum.RoomPhase.ROOM_PHASE_FINISHED => app.RoomPhase.finished,
        pbenum.RoomPhase.ROOM_PHASE_PLAYING => app.RoomPhase.playing,
        _ => app.RoomPhase.waiting,
      },
      players: players,
      selfCards: snapshot.selfCards.map(_mapCard).toList(),
      landlordCards: snapshot.landlordCards.map(_mapCard).toList(),
      recentActions: snapshot.recentActions
          .map(
            (action) => TableAction(
              actionId: action.actionId,
              playerId: action.playerId,
              playerName: namesById[action.playerId] ?? action.playerId,
              type: action.actionType == pbenum.ActionType.ACTION_TYPE_PASS
                  ? app.ActionType.pass
                  : app.ActionType.play,
              patternLabel: action.pattern,
              cards: action.cards.map(_mapCard).toList(),
              timestampMs: action.timestampMs.toInt(),
            ),
          )
          .toList(),
      currentTurnPlayerId: snapshot.currentTurnPlayerId,
      statusText: [
        snapshot.statusText,
        if (snapshot.springTriggered) '春天',
      ].join(snapshot.springTriggered ? ' · ' : ''),
      cardCounter: snapshot.cardCounter
          .map(
            (entry) =>
                CardCounterEntry(rank: entry.rank, remaining: entry.remaining),
          )
          .toList(),
      baseScore: snapshot.baseScore,
      multiplier: snapshot.multiplier,
      currentRoundScore: snapshot.currentRoundScore,
      springTriggered: snapshot.springTriggered,
      turnSerial: snapshot.turnSerial,
    );
  }

  PlayingCard _mapCard(pb.Card card) => PlayingCard(
        id: card.id,
        rank: card.rank,
        suit: card.suit,
        value: card.value,
      );

  app.RoomInvitation _mapInvitation(pb.RoomInvitationPush invitation) =>
      app.RoomInvitation(
        invitationId: invitation.invitationId,
        roomId: invitation.roomId,
        roomCode: invitation.roomCode,
        inviterUserId: invitation.inviterUserId,
        inviterAccount: invitation.inviterAccount,
        inviterNickname: invitation.inviterNickname,
        seatIndex: invitation.seatIndex,
      );

  app.InvitationFeedback _mapInvitationFeedback(
    pb.RoomInvitationResultPush feedback,
  ) =>
      app.InvitationFeedback(
        invitationId: feedback.invitationId,
        status: switch (feedback.result) {
          pbenum.InvitationResult.INVITATION_RESULT_ACCEPTED =>
            app.InvitationFeedbackStatus.accepted,
          pbenum.InvitationResult.INVITATION_RESULT_REJECTED =>
            app.InvitationFeedbackStatus.rejected,
          pbenum.InvitationResult.INVITATION_RESULT_EXPIRED =>
            app.InvitationFeedbackStatus.expired,
          _ => app.InvitationFeedbackStatus.failed,
        },
        targetUserId: feedback.inviteeUserId,
        targetAccount: feedback.inviteeAccount,
        targetNickname: feedback.inviteeNickname,
        detail: feedback.message,
      );

  String _id() => base64Url.encode(
        utf8.encode(
          '${DateTime.now().microsecondsSinceEpoch}-${DateTime.now().hashCode}',
        ),
      );
}

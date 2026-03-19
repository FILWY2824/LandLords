import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/app_models.dart' as app;
import '../models/game_models.dart';
import '../proto/landlords.pb.dart' as pb;
import '../proto/landlords.pbenum.dart' as pbenum;
import 'game_gateway.dart';

class WebSocketGameGateway implements GameGateway {
  WebSocketGameGateway({String? url}) : url = url ?? _resolveDefaultUrl();

  final String url;
  static const String _configuredUrl =
      String.fromEnvironment('LANDLORDS_WS_URL', defaultValue: '');
  static const String _suggestCommand = '__hint__';
  static const String _cancelMatchCommand = 'match:cancel';
  static const String _presentationAckPrefix = '__presented__:';

  final StreamController<RoomSnapshot> _snapshotController =
      StreamController<RoomSnapshot>.broadcast();
  final Map<String, Completer<pb.ServerMessage>> _pending = {};
  static const Duration _requestTimeout = Duration(seconds: 45);

  WebSocketChannel? _channel;
  Future<void>? _connectFuture;
  StreamSubscription<dynamic>? _subscription;
  Timer? _heartbeatTimer;
  String? _sessionToken;
  String? _lastRoomId;
  RoomSnapshot? _latestSnapshot;

  @override
  Stream<RoomSnapshot> get roomSnapshots => _snapshotController.stream;

  Future<void> _ensureConnected() async {
    if (_channel != null) {
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
    required String username,
    required String password,
  }) async {
    await _ensureConnected();
    final response = await _send(
      (message) => message.registerRequest = pb.RegisterRequest(
        username: username,
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
    required String username,
    required String password,
  }) async {
    await _ensureConnected();
    final response = await _send(
      (message) => message.loginRequest = pb.LoginRequest(
        username: username,
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
      profile: app.UserProfile(
        userId: response.loginResponse.profile.userId,
        username: response.loginResponse.profile.username,
        totalScore: response.loginResponse.profile.totalScore,
      ),
      sessionToken: response.loginResponse.sessionToken,
    );
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
        response.hasMatchResponse() ? response.matchResponse.message : '匹配失败',
      );
    }
    final snapshot = await snapshotFuture.timeout(_requestTimeout);
    _lastRoomId = snapshot.roomId;
    return snapshot;
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
      final snapshot = _mapSnapshot(response.operationResponse.snapshot);
      _publishSnapshot(snapshot);
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
      (message) => message.reconnectRequest = pb.ReconnectRequest(roomId: _lastRoomId),
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
    final completer = Completer<pb.ServerMessage>();
    _pending[requestId] = completer;
    if (_channel == null) {
      _pending.remove(requestId);
      throw Exception('服务器连接不可用');
    }
    _channel!.sink.add(Uint8List.fromList(message.writeToBuffer()));
    return completer.future.timeout(_requestTimeout, onTimeout: () {
      _pending.remove(requestId);
      throw Exception('服务器响应超时');
    });
  }

  void _onMessage(dynamic data) {
    final List<int> bytes;
    if (data is Uint8List) {
      bytes = data;
    } else if (data is List<int>) {
      bytes = data;
    } else if (data is ByteBuffer) {
      bytes = data.asUint8List();
    } else {
      throw Exception('WebSocket 返回了不支持的数据类型');
    }

    final message = pb.ServerMessage.fromBuffer(bytes);
    if (message.hasRoomSnapshot()) {
      final snapshot = _mapSnapshot(message.roomSnapshot);
      _publishSnapshot(snapshot);
    }
    if (message.requestId.isNotEmpty) {
      _pending.remove(message.requestId)?.complete(message);
    }
  }

  Future<void> _openConnection() async {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      await _channel!.ready;
      _subscription = _channel!.stream.listen(
        _onMessage,
        onError: (Object error, StackTrace stackTrace) => _handleDisconnect(error),
        onDone: _handleDisconnect,
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
    } catch (error) {
      _handleDisconnect(error);
      throw Exception('服务器连接失败，请检查地址或网络。');
    }
  }

  void _handleDisconnect([Object? error]) {
    _channel?.sink.close();
    _channel = null;
    _subscription?.cancel();
    _subscription = null;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
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

  RoomSnapshot _mapSnapshot(pb.RoomSnapshot snapshot) {
    final players = snapshot.players
        .map(
          (player) => RoomPlayer(
            playerId: player.playerId,
            displayName: player.displayName,
            isBot: player.isBot,
            role: player.role == pbenum.PlayerRole.PLAYER_ROLE_LANDLORD
                ? app.PlayerRole.landlord
                : app.PlayerRole.farmer,
            cardsLeft: player.cardsLeft,
            roundScore: player.roundScore,
          ),
        )
        .toList();
    final namesById = {
      for (final player in players) player.playerId: player.displayName,
    };
    return RoomSnapshot(
      roomId: snapshot.roomId,
      mode: snapshot.mode == pbenum.MatchMode.MATCH_MODE_VS_BOT
          ? app.MatchMode.vsBot
          : app.MatchMode.online,
      phase: switch (snapshot.phase) {
        pbenum.RoomPhase.ROOM_PHASE_FINISHED => app.RoomPhase.finished,
        pbenum.RoomPhase.ROOM_PHASE_PLAYING => app.RoomPhase.playing,
        _ => app.RoomPhase.waiting,
      },
      players: players,
      selfCards: snapshot.selfCards
          .map((card) => PlayingCard(id: card.id, rank: card.rank, suit: card.suit, value: card.value))
          .toList(),
      landlordCards: snapshot.landlordCards
          .map((card) => PlayingCard(id: card.id, rank: card.rank, suit: card.suit, value: card.value))
          .toList(),
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
              cards: action.cards
                  .map((card) => PlayingCard(id: card.id, rank: card.rank, suit: card.suit, value: card.value))
                  .toList(),
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
          .map((entry) => CardCounterEntry(rank: entry.rank, remaining: entry.remaining))
          .toList(),
      baseScore: snapshot.baseScore,
      multiplier: snapshot.multiplier,
      currentRoundScore: snapshot.currentRoundScore,
      springTriggered: snapshot.springTriggered,
      turnSerial: snapshot.turnSerial,
    );
  }

  String _id() => base64Url.encode(
        utf8.encode('${DateTime.now().microsecondsSinceEpoch}-${DateTime.now().hashCode}'),
      );

  static String _resolveDefaultUrl() {
    if (_configuredUrl.trim().isNotEmpty) {
      return _configuredUrl.trim();
    }
    final base = Uri.base;
    if (base.host.isEmpty) {
      return 'ws://127.0.0.1:23002/ws';
    }
    final scheme = base.scheme == 'https' ? 'wss' : 'ws';
    final port = _resolvedPort(base);
    final authority = port == null ? base.host : '${base.host}:$port';
    return '$scheme://$authority/ws';
  }

  static int? _resolvedPort(Uri base) {
    if (base.hasPort) {
      return base.port;
    }
    if (base.scheme == 'http' || base.scheme == 'ws') {
      return 80;
    }
    if (base.scheme == 'https' || base.scheme == 'wss') {
      return 443;
    }
    return null;
  }
}

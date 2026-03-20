import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../models/app_models.dart';
import '../models/game_models.dart';
import '../services/game_gateway.dart';
import '../utils/app_log.dart';

enum AppStage { login, lobby, matching, game }

class AppController extends ChangeNotifier {
  AppController({required GameGateway gateway}) : _gateway = gateway {
    _notificationSubscription = _gateway.notifications.listen(
      _handleGatewayNotification,
    );
  }

  static const int _matchingTimeoutSeconds = 20;

  final GameGateway _gateway;
  final Queue<RoomInvitation> _invitationQueue = Queue<RoomInvitation>();
  final Queue<InvitationFeedback> _feedbackQueue =
      Queue<InvitationFeedback>();

  StreamSubscription<RoomSnapshot>? _roomSubscription;
  StreamSubscription<GatewayNotification>? _notificationSubscription;
  Timer? _matchingTimer;

  AppStage _stage = AppStage.login;
  UserProfile? _profile;
  String? _sessionToken;
  RoomSnapshot? _roomSnapshot;
  String? _errorText;
  String? _busyText;
  String? _lobbyNotice;
  BotDifficulty _botDifficulty = BotDifficulty.normal;
  int _matchingElapsedSeconds = 0;
  int _matchEpoch = 0;
  String? _lastSettledRoomId;
  RoomInvitation? _activeInvitation;
  InvitationFeedback? _activeInvitationFeedback;

  AppStage get stage => _stage;
  UserProfile? get profile => _profile;
  RoomSnapshot? get roomSnapshot => _roomSnapshot;
  String? get errorText => _errorText;
  String? get busyText => _busyText;
  String? get lobbyNotice => _lobbyNotice;
  BotDifficulty get botDifficulty => _botDifficulty;
  RoomInvitation? get activeInvitation => _activeInvitation;
  InvitationFeedback? get activeInvitationFeedback => _activeInvitationFeedback;
  bool get isBusy => _busyText != null;
  bool get isMatching => _stage == AppStage.matching;
  int get matchingElapsedSeconds => _matchingElapsedSeconds;
  int get matchingTimeoutSeconds => _matchingTimeoutSeconds;
  bool get hasResumeRoom =>
      _roomSnapshot != null &&
      _roomSnapshot!.mode == MatchMode.online &&
      _roomSnapshot!.phase != RoomPhase.preparing &&
      _roomSnapshot!.phase != RoomPhase.finished;

  @override
  void dispose() {
    _matchingTimer?.cancel();
    _roomSubscription?.cancel();
    _notificationSubscription?.cancel();
    super.dispose();
  }

  Future<void> register(String account, String nickname, String password) async {
    await _guard('正在创建账号...', () {
      return _gateway.register(
        account: account,
        nickname: nickname,
        password: password,
      );
    });
  }

  Future<void> resetPassword(String account, String newPassword) async {
    await _guard('正在重置密码...', () {
      return _gateway.resetPassword(
        account: account,
        newPassword: newPassword,
      );
    });
  }

  Future<void> login(String account, String password) async {
    await _guard('正在进入大厅...', () async {
      final result = await _gateway.login(account: account, password: password);
      _profile = result.profile;
      _sessionToken = result.sessionToken;
      _lastSettledRoomId = null;
      _roomSnapshot = null;
      _lobbyNotice = null;
      _errorText = null;
      _invitationQueue.clear();
      _feedbackQueue.clear();
      _activeInvitation = null;
      _activeInvitationFeedback = null;
      _roomSubscription ??= _gateway.roomSnapshots.listen((snapshot) {
        _roomSnapshot = snapshot;
        _errorText = null;
        _lobbyNotice = null;
        _syncProfileFromSnapshot(snapshot);
        if (_stage == AppStage.matching || _stage == AppStage.game) {
          _stage = AppStage.game;
        }
        notifyListeners();
      });
      _stage = AppStage.lobby;
    });
  }

  Future<void> startMatch(
    MatchMode mode, {
    BotDifficulty botDifficulty = BotDifficulty.normal,
  }) async {
    if (_profile == null || _sessionToken == null) {
      return;
    }
    if (mode == MatchMode.online && hasResumeRoom) {
      _stage = AppStage.game;
      _errorText = null;
      _lobbyNotice = null;
      notifyListeners();
      return;
    }
    if (mode == MatchMode.vsBot) {
      _botDifficulty = botDifficulty;
    }

    _errorText = null;
    _lobbyNotice = null;

    if (mode == MatchMode.online) {
      final attempt = ++_matchEpoch;
      _busyText = null;
      _stage = AppStage.matching;
      _matchingElapsedSeconds = 0;
      _matchingTimer?.cancel();
      _matchingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_stage != AppStage.matching || attempt != _matchEpoch) {
          timer.cancel();
          return;
        }
        _matchingElapsedSeconds += 1;
        notifyListeners();
        if (_matchingElapsedSeconds >= _matchingTimeoutSeconds) {
          timer.cancel();
          unawaited(cancelMatching(timedOut: true));
        }
      });
      notifyListeners();

      try {
        _roomSnapshot = await _gateway.startMatch(
          sessionToken: _sessionToken!,
          profile: _profile!,
          mode: mode,
          botDifficulty: _botDifficulty,
        );
        _syncProfileFromSnapshot(_roomSnapshot!);
        if (attempt != _matchEpoch || _stage != AppStage.matching) {
          return;
        }
        _stage = AppStage.game;
        _lobbyNotice = null;
      } catch (error) {
        if (attempt != _matchEpoch) {
          return;
        }
        _stage = AppStage.lobby;
        _showLobbyNotice(_friendlyMatchMessage(error.toString()));
      } finally {
        if (attempt == _matchEpoch) {
          _matchingTimer?.cancel();
          _matchingTimer = null;
          _matchingElapsedSeconds = 0;
          notifyListeners();
        }
      }
      return;
    }

    await _guard('正在为你安排${_botDifficulty.hallTitle}...', () async {
      _roomSnapshot = await _gateway.startMatch(
        sessionToken: _sessionToken!,
        profile: _profile!,
        mode: mode,
        botDifficulty: _botDifficulty,
      );
      _syncProfileFromSnapshot(_roomSnapshot!);
      _stage = AppStage.game;
    });
  }

  Future<void> cancelMatching({bool timedOut = false}) async {
    if (_stage != AppStage.matching || _sessionToken == null) {
      return;
    }
    _matchEpoch += 1;
    _matchingTimer?.cancel();
    _matchingTimer = null;
    _matchingElapsedSeconds = 0;
    _stage = AppStage.lobby;
    notifyListeners();

    try {
      await _gateway.cancelMatch(sessionToken: _sessionToken!);
    } catch (_) {
      // The lobby already recovered. A late cancel failure should stay silent.
    }

    _showLobbyNotice(
      timedOut ? '暂时没有匹配到玩家，请稍后再试。' : '已退出当前匹配。',
    );
  }

  Future<void> createRoom() async {
    if (_sessionToken == null) {
      return;
    }
    await _guard('正在创建房间...', () async {
      _roomSnapshot = await _gateway.createRoom(sessionToken: _sessionToken!);
      _stage = AppStage.game;
      _lobbyNotice = null;
    });
  }

  Future<void> joinRoom(String roomCode) async {
    if (_sessionToken == null) {
      return;
    }
    await _guard('正在进入房间...', () async {
      _roomSnapshot = await _gateway.joinRoom(
        sessionToken: _sessionToken!,
        roomCode: roomCode,
      );
      _stage = AppStage.game;
      _lobbyNotice = null;
    });
  }

  Future<void> setRoomReady(bool ready) async {
    if (_sessionToken == null || _roomSnapshot == null) {
      return;
    }
    await _guard(ready ? '正在准备...' : '正在取消准备...', () async {
      _roomSnapshot = await _gateway.setRoomReady(
        sessionToken: _sessionToken!,
        roomId: _roomSnapshot!.roomId,
        ready: ready,
      );
    });
  }

  Future<void> addBotToRoom({
    required int seatIndex,
    BotDifficulty difficulty = BotDifficulty.normal,
  }) async {
    if (_sessionToken == null || _roomSnapshot == null) {
      return;
    }
    await _guard('正在补入 DouZero...', () async {
      _roomSnapshot = await _gateway.addBot(
        sessionToken: _sessionToken!,
        roomId: _roomSnapshot!.roomId,
        seatIndex: seatIndex,
        botDifficulty: difficulty,
      );
      if (_roomSnapshot != null) {
        _syncProfileFromSnapshot(_roomSnapshot!);
      }
    });
  }

  Future<void> removePlayerFromRoom(String playerId) async {
    if (_sessionToken == null || _roomSnapshot == null) {
      return;
    }
    await _guard('正在移除座位...', () async {
      _roomSnapshot = await _gateway.removePlayer(
        sessionToken: _sessionToken!,
        roomId: _roomSnapshot!.roomId,
        playerId: playerId,
      );
    });
  }

  Future<List<OnlineUser>> fetchFriends() async {
    if (_sessionToken == null) {
      return const [];
    }
    try {
      return await _gateway.fetchFriends(sessionToken: _sessionToken!);
    } catch (error) {
      _errorText = error.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return const [];
    }
  }

  Future<OnlineUser?> addFriendByAccount(String account) async {
    if (_sessionToken == null) {
      return null;
    }
    OnlineUser? added;
    await _guard('正在添加好友...', () async {
      added = await _gateway.addFriend(
        sessionToken: _sessionToken!,
        account: account,
      );
    });
    return added;
  }

  Future<void> invitePlayerToRoom({
    required String account,
    required int seatIndex,
  }) async {
    if (_sessionToken == null || _roomSnapshot == null) {
      return;
    }
    await _guard('正在发送邀请...', () async {
      await _gateway.invitePlayer(
        sessionToken: _sessionToken!,
        roomId: _roomSnapshot!.roomId,
        targetAccount: account,
        seatIndex: seatIndex,
      );
    });
  }

  Future<void> respondToInvitation({
    required String invitationId,
    required bool accept,
  }) async {
    if (_sessionToken == null) {
      return;
    }
    await _guard(
      accept ? '正在加入房间...' : '正在拒绝邀请...',
      () async {
        final snapshot = await _gateway.respondInvitation(
          sessionToken: _sessionToken!,
          invitationId: invitationId,
          accept: accept,
        );
        if (snapshot != null) {
          _roomSnapshot = snapshot;
          _stage = AppStage.game;
          _lobbyNotice = null;
        }
      },
    );
    dismissActiveInvitation();
  }

  void dismissActiveInvitation() {
    _activeInvitation = null;
    if (_invitationQueue.isNotEmpty) {
      _activeInvitation = _invitationQueue.removeFirst();
    }
    notifyListeners();
  }

  void dismissActiveInvitationFeedback() {
    _activeInvitationFeedback = null;
    if (_feedbackQueue.isNotEmpty) {
      _activeInvitationFeedback = _feedbackQueue.removeFirst();
    }
    notifyListeners();
  }

  Future<void> playCards(List<String> cardIds) async {
    if (_sessionToken == null || _roomSnapshot == null) {
      return;
    }
    await _guard('正在出牌...', () async {
      _roomSnapshot = await _gateway.playCards(
        sessionToken: _sessionToken!,
        roomId: _roomSnapshot!.roomId,
        cardIds: cardIds,
      );
    });
  }

  Future<void> callScore(int score) async {
    if (_sessionToken == null || _roomSnapshot == null) {
      return;
    }
    await _guard(score == 0 ? '正在选择不叫...' : '正在叫分...', () async {
      _roomSnapshot = await _gateway.callScore(
        sessionToken: _sessionToken!,
        roomId: _roomSnapshot!.roomId,
        score: score,
      );
    });
  }

  Future<void> setManaged(bool managed) async {
    if (_sessionToken == null || _roomSnapshot == null) {
      return;
    }
    await _guard(managed ? '正在开启托管...' : '正在取消托管...', () async {
      _roomSnapshot = await _gateway.setManaged(
        sessionToken: _sessionToken!,
        roomId: _roomSnapshot!.roomId,
        managed: managed,
      );
    });
  }

  Future<void> pass() async {
    if (_sessionToken == null || _roomSnapshot == null) {
      return;
    }
    await _guard('正在操作...', () async {
      _roomSnapshot = await _gateway.pass(
        sessionToken: _sessionToken!,
        roomId: _roomSnapshot!.roomId,
      );
    });
  }

  Future<List<String>> requestSuggestion() async {
    if (_sessionToken == null || _roomSnapshot == null) {
      return const [];
    }
    if (_busyText != null) {
      return const [];
    }
    _errorText = null;
    _busyText = '正在分析推荐牌...';
    notifyListeners();
    final watch = Stopwatch()..start();
    try {
      appLog(
        AppLogLevel.debug,
        'app_controller',
        'request suggestion room=${_roomSnapshot!.roomId}',
      );
      final suggestion = await _gateway.requestSuggestion(
        sessionToken: _sessionToken!,
        roomId: _roomSnapshot!.roomId,
      );
      appLog(
        AppLogLevel.info,
        'app_controller',
        'request suggestion room=${_roomSnapshot!.roomId} elapsed_ms=${watch.elapsedMilliseconds} cards=${suggestion.length}',
      );
      return suggestion;
    } catch (error) {
      appLog(
        AppLogLevel.warn,
        'app_controller',
        'request suggestion failed room=${_roomSnapshot!.roomId} elapsed_ms=${watch.elapsedMilliseconds} error=$error',
      );
      _errorText = error.toString().replaceFirst('Exception: ', '');
      return const [];
    } finally {
      _busyText = null;
      notifyListeners();
    }
  }

  Future<void> acknowledgePresentation(String roomId, String actionId) async {
    if (_sessionToken == null || actionId.isEmpty) {
      return;
    }
    try {
      appLog(
        AppLogLevel.debug,
        'app_controller',
        'send presentation ack room=$roomId action=$actionId',
      );
      await _gateway.acknowledgePresentation(
        sessionToken: _sessionToken!,
        roomId: roomId,
        actionId: actionId,
      );
    } catch (_) {
      appLog(
        AppLogLevel.warn,
        'app_controller',
        'presentation ack failed room=$roomId action=$actionId',
      );
    }
  }

  Future<void> refreshCurrentRoom() async {
    if (_sessionToken == null || _roomSnapshot == null) {
      return;
    }
    try {
      appLog(
        AppLogLevel.info,
        'app_controller',
        'refresh current room room=${_roomSnapshot!.roomId}',
      );
      final snapshot = await _gateway.refreshCurrentRoom();
      if (snapshot != null) {
        _roomSnapshot = snapshot;
        _syncProfileFromSnapshot(snapshot);
        _errorText = null;
        notifyListeners();
      }
    } catch (error) {
      appLog(
        AppLogLevel.warn,
        'app_controller',
        'refresh current room failed room=${_roomSnapshot?.roomId ?? '-'} error=$error',
      );
    }
  }

  Future<void> backToLobby() async {
    _matchingTimer?.cancel();
    _matchingTimer = null;
    _matchingElapsedSeconds = 0;
    final snapshot = _roomSnapshot;
    if (snapshot != null &&
        snapshot.mode == MatchMode.online &&
        snapshot.phase == RoomPhase.preparing &&
        _sessionToken != null) {
      try {
        await _gateway.leaveRoom(
          sessionToken: _sessionToken!,
          roomId: snapshot.roomId,
        );
      } catch (error) {
        _errorText = error.toString().replaceFirst('Exception: ', '');
      }
      _roomSnapshot = null;
    } else if (snapshot == null ||
        snapshot.mode == MatchMode.vsBot ||
        snapshot.phase == RoomPhase.finished) {
      _roomSnapshot = null;
    }
    _stage = AppStage.lobby;
    notifyListeners();
  }

  void logout() {
    _matchingTimer?.cancel();
    _matchingTimer = null;
    _matchingElapsedSeconds = 0;
    _matchEpoch += 1;
    _profile = null;
    _sessionToken = null;
    _roomSnapshot = null;
    _errorText = null;
    _busyText = null;
    _lobbyNotice = null;
    _lastSettledRoomId = null;
    _invitationQueue.clear();
    _feedbackQueue.clear();
    _activeInvitation = null;
    _activeInvitationFeedback = null;
    _stage = AppStage.login;
    notifyListeners();
  }

  void resumeRoom() {
    if (!hasResumeRoom) {
      return;
    }
    _stage = AppStage.game;
    _errorText = null;
    _lobbyNotice = null;
    notifyListeners();
  }

  void clearError() {
    if (_errorText == null) {
      return;
    }
    _errorText = null;
    notifyListeners();
  }

  void clearLobbyNotice() {
    if (_lobbyNotice == null) {
      return;
    }
    _lobbyNotice = null;
    notifyListeners();
  }

  void _showLobbyNotice(String text) {
    _lobbyNotice = text;
    notifyListeners();
  }

  void _handleGatewayNotification(GatewayNotification notification) {
    switch (notification) {
      case RoomInvitationNotification():
        final invitation = notification.invitation;
        if (_activeInvitation == null) {
          _activeInvitation = invitation;
        } else {
          _invitationQueue.addLast(invitation);
        }
        notifyListeners();
      case InvitationFeedbackNotification():
        final feedback = notification.feedback;
        if (_activeInvitationFeedback == null) {
          _activeInvitationFeedback = feedback;
        } else {
          _feedbackQueue.addLast(feedback);
        }
        notifyListeners();
    }
  }

  String _friendlyMatchMessage(String raw) {
    final text = raw.replaceFirst('Exception: ', '');
    if (text.contains('timeout')) {
      return '暂时没有匹配到玩家，请稍后再试。';
    }
    if (text.contains('already in room')) {
      return '你已经在牌桌里了，可以直接恢复牌桌。';
    }
    return '匹配暂时没有成功，请稍后再试。';
  }

  void _syncProfileFromSnapshot(RoomSnapshot snapshot) {
    final profile = _profile;
    if (profile == null ||
        snapshot.phase != RoomPhase.finished ||
        snapshot.roomId == _lastSettledRoomId) {
      return;
    }
    RoomPlayer? player;
    for (final item in snapshot.players) {
      if (item.playerId == profile.userId) {
        player = item;
        break;
      }
    }
    if (player == null) {
      return;
    }
    final won = player.roundScore > 0;
    _lastSettledRoomId = snapshot.roomId;
    _profile = profile.copyWith(
      coins: profile.coins + player.roundScore,
      landlordWins: profile.landlordWins + (player.isLandlord && won ? 1 : 0),
      landlordGames: profile.landlordGames + (player.isLandlord ? 1 : 0),
      farmerWins: profile.farmerWins + (!player.isLandlord && won ? 1 : 0),
      farmerGames: profile.farmerGames + (!player.isLandlord ? 1 : 0),
    );
  }

  Future<void> _guard(String busyText, Future<void> Function() action) async {
    if (_busyText != null) {
      return;
    }
    _errorText = null;
    _busyText = busyText;
    notifyListeners();
    try {
      await action();
    } catch (error) {
      _errorText = error.toString().replaceFirst('Exception: ', '');
    } finally {
      _busyText = null;
      notifyListeners();
    }
  }
}

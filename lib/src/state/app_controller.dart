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
  static const String _busyOperationError = 'operation in progress';

  final GameGateway _gateway;
  final Queue<RoomInvitation> _invitationQueue = Queue<RoomInvitation>();
  final Queue<InvitationFeedback> _feedbackQueue =
      Queue<InvitationFeedback>();
  final Queue<AppDialogNotice> _popupNoticeQueue = Queue<AppDialogNotice>();

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
  AppDialogNotice? _activePopupNotice;
  FriendCenterSnapshot _friendCenterSnapshot = const FriendCenterSnapshot.empty();

  AppStage get stage => _stage;
  UserProfile? get profile => _profile;
  RoomSnapshot? get roomSnapshot => _roomSnapshot;
  String? get errorText => _errorText;
  String? get busyText => _busyText;
  String? get lobbyNotice => _lobbyNotice;
  BotDifficulty get botDifficulty => _botDifficulty;
  RoomInvitation? get activeInvitation => _activeInvitation;
  InvitationFeedback? get activeInvitationFeedback => _activeInvitationFeedback;
  AppDialogNotice? get activePopupNotice => _activePopupNotice;
  FriendCenterSnapshot get friendCenterSnapshot => _friendCenterSnapshot;
  int get pendingFriendRequestCount => _friendCenterSnapshot.pendingRequestCount;
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
    unawaited(_gateway.close());
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

  Future<void> updateNickname(String nickname) async {
    if (_profile == null || _sessionToken == null) {
      return;
    }
    final normalizedNickname = nickname.trim();
    if (normalizedNickname.isEmpty) {
      return;
    }
    await _guard('姝ｅ湪鏇存柊鏄电О...', () async {
      _profile = await _gateway.updateNickname(
        sessionToken: _sessionToken!,
        nickname: normalizedNickname,
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
      _activePopupNotice = null;
      _popupNoticeQueue.clear();
      _friendCenterSnapshot = const FriendCenterSnapshot.empty();
      _roomSubscription ??= _gateway.roomSnapshots.listen((snapshot) {
        final profile = _profile;
        final wasRemovedFromPendingRoom =
            profile != null &&
            snapshot.mode == MatchMode.online &&
            snapshot.phase == RoomPhase.preparing &&
            snapshot.players.every((player) => player.playerId != profile.userId);
        if (wasRemovedFromPendingRoom) {
          _gateway.clearCurrentRoomCache();
          _roomSnapshot = null;
          _errorText = null;
          _lobbyNotice = null;
          _stage = AppStage.lobby;
          showDialogNotice(
            title: '已离开房间',
            message: '房主已将你移出当前房间。',
          );
          notifyListeners();
          return;
        }
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
    if (_sessionToken != null) {
      unawaited(refreshFriendCenter(silent: true));
    }
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
    if (mode != MatchMode.online && hasResumeRoom) {
      _showLobbyNotice('你有一局正在进行的对局，请先恢复对局。');
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
      final snapshot = await _gateway.createRoom(sessionToken: _sessionToken!);
      if (!_isValidCreatedRoomSnapshot(snapshot)) {
        throw Exception('invalid create room snapshot');
      }
      _roomSnapshot = snapshot;
      _stage = AppStage.game;
      _lobbyNotice = null;
    });
    await _recoverFromTransportFailure();
    if (_stage == AppStage.lobby && _errorText != null) {
      final msg = _friendlyRoomActionMessage(_errorText!);
      _errorText = null;
      showDialogNotice(message: msg, deduplicate: false);
    }
  }

  Future<void> joinRoom(String roomCode) async {
    if (_sessionToken == null) {
      return;
    }
    await _guard('正在进入房间...', () async {
      final snapshot = await _gateway.joinRoom(
        sessionToken: _sessionToken!,
        roomCode: roomCode,
      );
      if (!_isValidJoinedRoomSnapshot(snapshot)) {
        throw Exception('invalid join room snapshot');
      }
      _roomSnapshot = snapshot;
      _stage = AppStage.game;
      _lobbyNotice = null;
    });
    await _recoverFromTransportFailure();
    if (_stage == AppStage.lobby && _errorText != null) {
      final msg = _friendlyRoomActionMessage(_errorText!);
      _errorText = null;
      showDialogNotice(message: msg, deduplicate: false);
    }
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
    await _recoverFromTransportFailure();
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

  Future<FriendCenterSnapshot> refreshFriendCenter({bool silent = false}) async {
    if (_sessionToken == null) {
      return const FriendCenterSnapshot.empty();
    }
    try {
      final snapshot = await _gateway.fetchFriendCenter(
        sessionToken: _sessionToken!,
      );
      _friendCenterSnapshot = snapshot;
      if (!silent) {
        notifyListeners();
      }
      return snapshot;
    } catch (error) {
      if (!silent) {
        _errorText = error.toString().replaceFirst('Exception: ', '');
        notifyListeners();
      }
      return _friendCenterSnapshot;
    }
  }

  Future<FriendCenterSnapshot?> sendFriendRequestByAccount(String account) async {
    if (_sessionToken == null) {
      return null;
    }
    FriendCenterSnapshot? snapshot;
    await _guard('正在添加好友...', () async {
      snapshot = await _gateway.sendFriendRequest(
        sessionToken: _sessionToken!,
        account: account,
      );
      if (snapshot != null) {
        _friendCenterSnapshot = snapshot!;
      }
    });
    return snapshot;
  }

  Future<FriendCenterSnapshot?> respondFriendRequest({
    required String requestId,
    required bool accept,
  }) async {
    if (_sessionToken == null) {
      return null;
    }
    FriendCenterSnapshot? snapshot;
    await _guard(accept ? '姝ｅ湪鍚屾剰鐢宠...' : '姝ｅ湪鎷掔粷鐢宠...', () async {
      snapshot = await _gateway.respondFriendRequest(
        sessionToken: _sessionToken!,
        requestId: requestId,
        accept: accept,
      );
      if (snapshot != null) {
        _friendCenterSnapshot = snapshot!;
      }
    });
    return snapshot;
  }

  Future<FriendCenterSnapshot?> deleteFriend(String friendUserId) async {
    if (_sessionToken == null) {
      return null;
    }
    FriendCenterSnapshot? snapshot;
    await _guard('姝ｅ湪鍒犻櫎濂藉弸...', () async {
      snapshot = await _gateway.deleteFriend(
        sessionToken: _sessionToken!,
        friendUserId: friendUserId,
      );
      if (snapshot != null) {
        _friendCenterSnapshot = snapshot!;
      }
    });
    return snapshot;
  }

  Future<void> invitePlayerToRoom({
    required String account,
    String? displayName,
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
    await _recoverFromTransportFailure();
    if (_errorText == null) {
      final label = (displayName == null || displayName.trim().isEmpty)
          ? account
          : displayName.trim();
      showDialogNotice(
        title: '邀请已发送',
        message: '已向 $label 发送入座邀请，请等待对方确认。',
      );
    }
  }

  Future<bool> respondToInvitation({
    required String invitationId,
    required bool accept,
  }) async {
    if (_sessionToken == null) {
      return false;
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
    await _recoverFromTransportFailure();
    if (_errorText != null && _shouldDismissInvitationAfterError(_errorText!)) {
      final message = _friendlyRoomActionMessage(_errorText!);
      dismissActiveInvitation();
      showDialogNotice(title: '邀请已失效', message: message);
      return true;
    }
    if (_errorText != null) {
      final shouldDismiss = _shouldDismissInvitationAfterError(_errorText!);
      showDialogNotice(
        title: '邀请处理失败',
        message: _friendlyRoomActionMessage(_errorText!),
      );
      if (shouldDismiss) {
        dismissActiveInvitation();
      }
      return false;
    }
    dismissActiveInvitation();
    return true;
  }

  Future<void> recoverConnection() async {
    if (_sessionToken == null) {
      return;
    }
    try {
      await _gateway.recoverConnection();
      await refreshFriendCenter(silent: true);
      _errorText = null;
    } catch (error) {
      _errorText = error.toString().replaceFirst('Exception: ', '');
    }
    notifyListeners();
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

  void showDialogNotice({
    String title = '提示',
    required String message,
    String actionLabel = '知道了',
    bool deduplicate = true,
  }) {
    final notice = AppDialogNotice(
      title: title,
      message: message,
      actionLabel: actionLabel,
    );
    if (deduplicate &&
        (_noticeMatches(_activePopupNotice, notice) ||
            _popupNoticeQueue.any((item) => _noticeMatches(item, notice)))) {
      return;
    }
    if (_activePopupNotice == null) {
      _activePopupNotice = notice;
    } else {
      _popupNoticeQueue.addLast(notice);
    }
    notifyListeners();
  }

  void dismissActivePopupNotice() {
    if (_activePopupNotice == null) {
      return;
    }
    _activePopupNotice = null;
    if (_popupNoticeQueue.isNotEmpty) {
      _activePopupNotice = _popupNoticeQueue.removeFirst();
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
    final sessionToken = _sessionToken;
    final shouldCloseRoomOnLeave = snapshot != null &&
        sessionToken != null &&
        (snapshot.mode == MatchMode.vsBot ||
            (snapshot.mode == MatchMode.online &&
                snapshot.phase == RoomPhase.preparing));
    if (shouldCloseRoomOnLeave) {
      try {
        await _gateway.leaveRoom(
          sessionToken: sessionToken,
          roomId: snapshot.roomId,
        );
      } catch (error) {
        _errorText = error.toString().replaceFirst('Exception: ', '');
      }
      _roomSnapshot = null;
    } else if (snapshot == null || snapshot.phase == RoomPhase.finished) {
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
    _activePopupNotice = null;
    _popupNoticeQueue.clear();
    _friendCenterSnapshot = const FriendCenterSnapshot.empty();
    _stage = AppStage.login;
    notifyListeners();
  }

  void resumeRoom() {
    if (!hasResumeRoom || _busyText != null) {
      return;
    }
    unawaited(_resumeRoomInternal());
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
    _lobbyNotice = null;
    showDialogNotice(message: text);
  }

  bool _noticeMatches(AppDialogNotice? left, AppDialogNotice right) {
    return left != null &&
        left.title == right.title &&
        left.message == right.message &&
        left.actionLabel == right.actionLabel;
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
      case FriendCenterNotification():
        _friendCenterSnapshot = notification.snapshot;
        notifyListeners();
    }
  }

  String _friendlyMatchMessage(String raw) {
    final text = raw.replaceFirst('Exception: ', '');
    if (text.contains('invalid create room snapshot')) {
      return '鍒涘缓鎴块棿杩斿洖浜嗗紓甯哥姸鎬侊紝宸查樆姝㈣娆¤繘鍏ワ紝璇烽噸鏂板皾璇曘€?';
    }
    if (text.contains('invalid join room snapshot')) {
      return '杩涘叆鎴块棿杩斿洖浜嗗紓甯哥姸鎬侊紝璇烽噸鏂板皾璇曘€?';
    }
    if (text.contains('timeout')) {
      return '暂时没有匹配到玩家，请稍后再试。';
    }
    if (text.contains('already in room')) {
      return '你已经在牌桌里了，可以直接恢复对局。';
    }
    return '匹配暂时没有成功，请稍后再试。';
  }

String _friendlyRoomActionMessage(String raw) {
    final text = raw.replaceFirst('Exception: ', '');
    if (text.contains('only host can remove')) {
      return '只有房主可以移除房间内的其他玩家。';
    }
    if (text.contains('cannot remove yourself')) {
      return '不能移除自己，如需离开请使用退出房间。';
    }
    if (text.contains('player not found')) {
      return '没有找到这位玩家，房间状态可能已经变化。';
    }
    if (text.contains('invitation timed out')) {
      return '这条房间邀请已超时。';
    }
    if (text.contains('room seats changed')) {
      return '房间座位已变化，这条邀请已经失效。';
    }
    if (text.contains('room started')) {
      return '房间已经开局，这条邀请已经失效。';
    }
    if (text.contains('room closed')) {
      return '房间已经关闭，这条邀请已经失效。';
    }
    if (text.contains('invalid create room snapshot')) {
      return '鍒涘缓鎴块棿杩斿洖浜嗗紓甯哥姸鎬侊紝宸查樆姝㈣娆¤繘鍏ワ紝璇烽噸鏂板皾璇曘€?';
    }
    if (text.contains('invalid join room snapshot')) {
      return '杩涘叆鎴块棿杩斿洖浜嗗紓甯哥姸鎬侊紝璇烽噸鏂板皾璇曘€?';
    }
    if (text.contains('already in room')) {
      return '你当前已经在房间中，可以先退出当前房间后再重新创建或加入。';
    }
    if (text.contains('room not found')) {
      return '没有找到这个房间，请检查房间号是否正确。';
    }
    if (text.contains('room is no longer available')) {
      return '该房间已经不可用，无法处理这次邀请。';
    }
    if (text.contains('room is full')) {
      return '房间已经满员了，请换一个房间号再试。';
    }
    if (text.contains('invitation expired')) {
      return '这条房间邀请已经失效了。';
    }
    if (text.contains('player is currently in another room')) {
      return '你当前正在其他房间中，暂时无法加入该房间。';
    }
    if (text.contains('timeout')) {
      return '请求超时了，请检查网络后重新尝试。';
    }
    if (text.contains('login required')) {
      return '登录状态已失效，请重新登录后再试。';
    }
    if (_looksLikeTransportError(text)) {
      return '当前连接不稳定，已尝试自动重连，请稍后再试一次。';
    }
    if (text == _busyOperationError) {
      return '当前还有操作正在处理中，请稍候再试。';
    }
    return text;
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

  Future<void> _recoverFromTransportFailure() async {
    if (_sessionToken == null || !_looksLikeTransportError(_errorText)) {
      return;
    }
    try {
      await _gateway.recoverConnection();
    } catch (_) {
      // Keep the original action error visible to the user.
    }
  }

  bool _looksLikeTransportError(String? raw) {
    if (raw == null || raw.isEmpty) {
      return false;
    }
    final text = raw.replaceFirst('Exception: ', '').toLowerCase();
    return text.contains('timeout') ||
        text.contains('timed out') ||
        text.contains('socketexception') ||
        text.contains('websocket') ||
        text.contains('connection') ||
        text.contains('broken pipe') ||
        text.contains('service unavailable') ||
        text.contains('连接') ||
        text.contains('超时');
  }

  bool _shouldDismissInvitationAfterError(String raw) {
    final text = raw.replaceFirst('Exception: ', '').toLowerCase();
    return text.contains('invitation expired') ||
        text.contains('invitation timed out') ||
        text.contains('room is no longer available') ||
        text.contains('room not found') ||
        text.contains('room is full') ||
        text.contains('room seats changed') ||
        text.contains('room started') ||
        text.contains('room closed');
  }

  Future<void> _guard(String busyText, Future<void> Function() action) async {
    if (_busyText != null) {
      _errorText = _busyOperationError;
      appLog(
        AppLogLevel.warn,
        'app_controller',
        'guard blocked requested="$busyText" current="$_busyText"',
      );
      notifyListeners();
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

  Future<void> _resumeRoomInternal() async {
    _errorText = null;
    _lobbyNotice = null;
    _busyText = '姝ｅ湪鎭㈠瀵瑰眬...';
    notifyListeners();
    try {
      final snapshot = await _gateway.refreshCurrentRoom();
      if (snapshot != null) {
        _roomSnapshot = snapshot;
      }
      if (_roomSnapshot == null) {
        throw Exception('room not found');
      }
      _stage = AppStage.game;
    } catch (error) {
      final message = error.toString().replaceFirst('Exception: ', '');
      if (message.contains('room not found')) {
        _roomSnapshot = null;
        showDialogNotice(
          message: '褰撳墠瀵瑰眬宸叉棤娉曟仮澶嶏紝璇峰洖鍒板ぇ鍘呴噸鏂板紑濮嬨€?',
          deduplicate: false,
        );
      } else {
        _errorText = message;
        showDialogNotice(
          message: _friendlyRoomActionMessage(message),
          deduplicate: false,
        );
      }
    } finally {
      _busyText = null;
      notifyListeners();
    }
  }

  bool _isValidCreatedRoomSnapshot(RoomSnapshot snapshot) {
    final profile = _profile;
    if (!_isPreparingOnlineRoomSnapshot(snapshot) || profile == null) {
      return false;
    }
    final occupiedPlayers = snapshot.players
        .where((player) => player.occupied)
        .toList(growable: false);
    return snapshot.ownerPlayerId == profile.userId &&
        occupiedPlayers.length == 1 &&
        occupiedPlayers.first.playerId == profile.userId;
  }

  bool _isValidJoinedRoomSnapshot(RoomSnapshot snapshot) {
    return _isPreparingOnlineRoomSnapshot(snapshot);
  }

  bool _isPreparingOnlineRoomSnapshot(RoomSnapshot snapshot) {
    return snapshot.mode == MatchMode.online &&
        snapshot.phase == RoomPhase.preparing;
  }
}

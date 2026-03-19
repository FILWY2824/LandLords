import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/app_models.dart';
import '../models/game_models.dart';
import '../services/game_gateway.dart';
import '../utils/app_log.dart';

enum AppStage { login, lobby, matching, game }

class AppController extends ChangeNotifier {
  AppController({required GameGateway gateway}) : _gateway = gateway;

  static const int _matchingTimeoutSeconds = 20;

  final GameGateway _gateway;
  StreamSubscription<RoomSnapshot>? _roomSubscription;
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
  bool _expectingOnlineMatchSnapshot = false;

  AppStage get stage => _stage;
  UserProfile? get profile => _profile;
  RoomSnapshot? get roomSnapshot => _roomSnapshot;
  String? get errorText => _errorText;
  String? get busyText => _busyText;
  String? get lobbyNotice => _lobbyNotice;
  BotDifficulty get botDifficulty => _botDifficulty;
  bool get isBusy => _busyText != null;
  bool get isMatching => _stage == AppStage.matching;
  int get matchingElapsedSeconds => _matchingElapsedSeconds;
  int get matchingTimeoutSeconds => _matchingTimeoutSeconds;
  bool get hasResumeRoom =>
      _roomSnapshot != null &&
      _roomSnapshot!.mode == MatchMode.online &&
      _roomSnapshot!.phase != RoomPhase.finished;

  @override
  void dispose() {
    _matchingTimer?.cancel();
    _roomSubscription?.cancel();
    super.dispose();
  }

  Future<void> register(String username, String password) async {
    await _guard('正在创建账号...', () {
      return _gateway.register(username: username, password: password);
    });
  }

  Future<void> login(String username, String password) async {
    await _guard('正在进入大厅...', () async {
      final result = await _gateway.login(username: username, password: password);
      _profile = result.profile;
      _sessionToken = result.sessionToken;
      _roomSubscription ??= _gateway.roomSnapshots.listen((snapshot) {
        if (_stage == AppStage.lobby &&
            _roomSnapshot == null &&
            snapshot.mode == MatchMode.online &&
            !_expectingOnlineMatchSnapshot) {
          return;
        }
        _roomSnapshot = snapshot;
        _errorText = null;
        _lobbyNotice = null;
        if (snapshot.mode == MatchMode.online) {
          _expectingOnlineMatchSnapshot = false;
        }
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
      _expectingOnlineMatchSnapshot = true;
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

    await _guard('正在为你安排${_botDifficulty.gameChip}...', () async {
      _stage = AppStage.matching;
      notifyListeners();
      _roomSnapshot = await _gateway.startMatch(
        sessionToken: _sessionToken!,
        profile: _profile!,
        mode: mode,
        botDifficulty: _botDifficulty,
      );
      _stage = AppStage.game;
    });
    if (_roomSnapshot == null && _stage == AppStage.matching) {
      _stage = AppStage.lobby;
      notifyListeners();
    }
  }

  Future<void> cancelMatching({bool timedOut = false}) async {
    if (_stage != AppStage.matching || _sessionToken == null) {
      return;
    }
    _matchEpoch += 1;
    _matchingTimer?.cancel();
    _matchingTimer = null;
    _matchingElapsedSeconds = 0;
    _expectingOnlineMatchSnapshot = false;
    _stage = AppStage.lobby;
    notifyListeners();

    try {
      await _gateway.cancelMatch(sessionToken: _sessionToken!);
    } catch (_) {
      // The lobby already recovered. A late cancel failure should stay silent.
    }

    _showLobbyNotice(timedOut ? '暂未匹配到玩家，请稍后再试。' : '已退出匹配');
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
    _busyText = '正在思考推荐牌...';
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
      // Presentation ack is best-effort. The backend will fall back to timeout.
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

  void backToLobby() {
    _matchingTimer?.cancel();
    _matchingTimer = null;
    _matchingElapsedSeconds = 0;
    _expectingOnlineMatchSnapshot = false;
    final snapshot = _roomSnapshot;
    if (snapshot == null ||
        snapshot.mode == MatchMode.vsBot ||
        snapshot.phase == RoomPhase.finished) {
      _roomSnapshot = null;
    }
    _stage = AppStage.lobby;
    _errorText = null;
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

  String _friendlyMatchMessage(String raw) {
    final text = raw.replaceFirst('Exception: ', '');
    if (text.contains('timeout') || text.contains('超时')) {
      return '暂时没有匹配到玩家，请稍后再试。';
    }
    if (text.contains('already in room')) {
      return '你已经在牌桌里了，可以直接回到对局。';
    }
    return '匹配暂时没有成功，请稍后再试。';
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

import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../models/game_models.dart';
import '../services/voice_cue_service.dart';
import '../state/app_controller.dart';
import '../utils/app_log.dart';
import '../utils/current_trick_view.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key, required this.controller});

  final AppController controller;

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> with WidgetsBindingObserver {
  final _selectedIds = <String>{};
  final _suggestedIds = <String>{};
  final _voice = VoiceCueService();
  Timer? _countdownTimer;
  Timer? _bannerTimer;
  Timer? _errorTimer;
  String? _bannerText;
  String? _bannerActionId;
  String? _errorNotice;
  String? _lastGameErrorText;
  int? _turnSerial;
  int _secondsLeft = 25;
  bool _showCounter = true;
  bool _musicEnabled = true;
  final Set<String> _seenActionIds = <String>{};
  final Queue<String> _seenActionOrder = Queue<String>();
  final Set<String> _presentationAckedIds = <String>{};
  final Set<String> _stalePresentationIds = <String>{};
  final Queue<_PendingPresentation> _presentationQueue =
      Queue<_PendingPresentation>();
  bool _dragSelectionActive = false;
  bool _dragSelectionValue = true;
  int? _lastDragIndex;
  bool _processingPresentationQueue = false;
  String? _presentationRoomId;
  String? _activePresentationActionId;

  void _showBanner(String text, {int milliseconds = 1800}) {
    _bannerTimer?.cancel();
    setState(() => _bannerText = text);
    _bannerTimer = Timer(Duration(milliseconds: milliseconds), () {
      if (mounted) {
        setState(() => _bannerText = null);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_voice.startBackgroundMusic());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _countdownTimer?.cancel();
    _bannerTimer?.cancel();
    _errorTimer?.cancel();
    unawaited(_voice.dispose());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    appLog(
      AppLogLevel.info,
      'game_page',
      'lifecycle state=$state',
    );
  }

  bool _isManaged(RoomSnapshot snapshot, String playerId) {
    for (final action in snapshot.recentActions.reversed) {
      if (action.playerId != playerId) {
        continue;
      }
      if (action.patternLabel == 'managed_on') {
        return true;
      }
      if (action.patternLabel == 'managed_off') {
        return false;
      }
    }
    return false;
  }

  void _sync(RoomSnapshot snapshot) {
    if (_presentationRoomId != snapshot.roomId) {
      _presentationRoomId = snapshot.roomId;
      _presentationQueue.clear();
      _seenActionIds.clear();
      _seenActionOrder.clear();
      _presentationAckedIds.clear();
      _stalePresentationIds.clear();
      _activePresentationActionId = null;
      _voice.clearPending(clearRecentActionIds: true);
      appLog(
        AppLogLevel.info,
        'game_page',
        'switch room room=${snapshot.roomId}',
      );
    }

    if (_turnSerial != snapshot.turnSerial) {
      _turnSerial = snapshot.turnSerial;
      _secondsLeft = 25;
      _countdownTimer?.cancel();
      if (snapshot.phase != RoomPhase.finished &&
          snapshot.currentTurnPlayerId.isNotEmpty) {
        _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (!mounted) {
            timer.cancel();
            return;
          }
          if (_secondsLeft <= 0) {
            timer.cancel();
            return;
          }
          setState(() => _secondsLeft -= 1);
        });
      }
    }

    final unseenIndexes = <int>[];
    for (var index = 0; index < snapshot.recentActions.length; index++) {
      final action = snapshot.recentActions[index];
      if (_seenActionIds.contains(action.actionId)) {
        continue;
      }
      _seenActionIds.add(action.actionId);
      _seenActionOrder.add(action.actionId);
      while (_seenActionOrder.length > 96) {
        _seenActionIds.remove(_seenActionOrder.removeFirst());
      }
      unseenIndexes.add(index);
    }

    if (unseenIndexes.isNotEmpty) {
      final shouldCatchUp = unseenIndexes.length > 1 ||
          _processingPresentationQueue ||
          _presentationQueue.isNotEmpty;
      if (shouldCatchUp) {
        final latestIndex = unseenIndexes.last;
        final latestAction = snapshot.recentActions[latestIndex];
        if (_activePresentationActionId != null) {
          _stalePresentationIds.add(_activePresentationActionId!);
        }
        for (final pending in _presentationQueue) {
          _stalePresentationIds.add(pending.actionId);
        }
        _presentationQueue.clear();
        unawaited(_voice.interruptSpeech());
        _presentationQueue.add(
          _PendingPresentation(
            roomId: snapshot.roomId,
            actions: snapshot.recentActions,
            index: latestIndex,
            actionId: latestAction.actionId,
          ),
        );
        appLog(
          AppLogLevel.warn,
          'game_page',
          'presentation catch-up room=${snapshot.roomId} latest=${latestAction.actionId} '
          'unseen=${unseenIndexes.length}',
        );
      } else {
        for (final index in unseenIndexes) {
          final action = snapshot.recentActions[index];
          _presentationQueue.add(
            _PendingPresentation(
              roomId: snapshot.roomId,
              actions: snapshot.recentActions,
              index: index,
              actionId: action.actionId,
            ),
          );
          appLog(
            AppLogLevel.debug,
            'game_page',
            'queue presentation room=${snapshot.roomId} action=${action.actionId} '
            'label=${action.patternLabel} index=$index',
          );
        }
      }
      if (!_processingPresentationQueue) {
        unawaited(_drainPresentationQueue());
      }
    }

    final latest = unseenIndexes.isNotEmpty
        ? snapshot.recentActions[unseenIndexes.last]
        : null;
    if (latest != null && latest.actionId != _bannerActionId) {
      _bannerActionId = latest.actionId;
      _showBanner(_banner(latest));
    }

    if (snapshot.phase == RoomPhase.finished && _selectedIds.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _selectedIds.clear();
            _suggestedIds.clear();
          });
        }
      });
    }
  }

  Future<void> _presentAction(
    String roomId,
    List<TableAction> actions,
    int index,
  ) async {
    final action = actions[index];
    _activePresentationActionId = action.actionId;
    if (!mounted || widget.controller.roomSnapshot?.roomId != roomId) {
      if (_activePresentationActionId == action.actionId) {
        _activePresentationActionId = null;
      }
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 60));
    appLog(
      AppLogLevel.debug,
      'game_page',
      'present action start room=$roomId action=${action.actionId} '
      'label=${action.patternLabel}',
    );
    await _voice.enqueueActionAndWaitForStart(
      action.actionId,
      _voiceText(actions, index),
    );
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (_stalePresentationIds.remove(action.actionId)) {
      appLog(
        AppLogLevel.info,
        'game_page',
        'skip stale presentation room=$roomId action=${action.actionId}',
      );
      if (_activePresentationActionId == action.actionId) {
        _activePresentationActionId = null;
      }
      return;
    }
    if (!mounted || _presentationAckedIds.contains(action.actionId)) {
      if (_activePresentationActionId == action.actionId) {
        _activePresentationActionId = null;
      }
      return;
    }
    _presentationAckedIds.add(action.actionId);
    appLog(
      AppLogLevel.debug,
      'game_page',
      'ack presentation room=$roomId action=${action.actionId}',
    );
    await widget.controller.acknowledgePresentation(roomId, action.actionId);
    if (_activePresentationActionId == action.actionId) {
      _activePresentationActionId = null;
    }
  }

  Future<void> _drainPresentationQueue() async {
    _processingPresentationQueue = true;
    try {
      while (_presentationQueue.isNotEmpty) {
        final pending = _presentationQueue.removeFirst();
        if (!mounted || widget.controller.roomSnapshot?.roomId != pending.roomId) {
          continue;
        }
        await _presentAction(pending.roomId, pending.actions, pending.index);
      }
    } finally {
      _processingPresentationQueue = false;
    }
  }

  void _syncGameError() {
    final rawError = widget.controller.errorText;
    if (rawError == null) {
      _lastGameErrorText = null;
      return;
    }
    if (rawError == _lastGameErrorText) {
      return;
    }
    _lastGameErrorText = rawError;
    final notice = _friendlyGameError(rawError);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _errorTimer?.cancel();
      setState(() => _errorNotice = notice);
      _errorTimer = Timer(const Duration(milliseconds: 1900), () {
        if (mounted) {
          setState(() => _errorNotice = null);
        }
      });
      unawaited(_voice.playErrorCue(_friendlyGameErrorVoice(rawError)));
      widget.controller.clearError();
    });
  }

  bool _isSuggestedSelectionActive() =>
      _suggestedIds.isNotEmpty &&
      _selectedIds.length == _suggestedIds.length &&
      _selectedIds.containsAll(_suggestedIds);

  Future<void> _toggleSuggestedSelection() async {
    if (_isSuggestedSelectionActive()) {
      setState(() {
        _selectedIds.clear();
        _suggestedIds.clear();
      });
      return;
    }

    final suggested = await widget.controller.requestSuggestion();
    if (!mounted) {
      return;
    }
    if (suggested.isEmpty) {
      _showBanner('\u63a8\u8350\u4e0d\u51fa', milliseconds: 1500);
      unawaited(_voice.speakNow('\u63a8\u8350\u4e0d\u51fa'));
    }
    setState(() {
      _suggestedIds
        ..clear()
        ..addAll(suggested);
      _selectedIds
        ..clear()
        ..addAll(suggested);
    });
  }

  int? _handIndexAtPosition(
    List<PlayingCard> cards,
    double dx,
    double spacing,
    double width,
    double totalWidth,
  ) {
    if (cards.isEmpty || dx < 0 || dx > totalWidth) {
      return null;
    }
    if (dx >= totalWidth - width) {
      return cards.length - 1;
    }
    final index = (dx / spacing).floor();
    return index.clamp(0, cards.length - 1);
  }

  void _applyDragSelectionRange(
    List<PlayingCard> cards,
    int from,
    int to,
    bool select,
  ) {
    final start = math.min(from, to);
    final end = math.max(from, to);
    for (var index = start; index <= end; index++) {
      final cardId = cards[index].id;
      if (select) {
        _selectedIds.add(cardId);
      } else {
        _selectedIds.remove(cardId);
      }
    }
    _suggestedIds.clear();
  }

  void _endDragSelection() {
    _dragSelectionActive = false;
    _lastDragIndex = null;
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = widget.controller.roomSnapshot;
    final profile = widget.controller.profile;
    if (snapshot == null || profile == null) {
      return const Scaffold(body: SizedBox.shrink());
    }

    final me = snapshot.players.firstWhere(
      (player) => player.playerId == profile.userId,
    );
    final selfIndex = snapshot.players.indexOf(me);
    final leftPlayer =
        snapshot.players[(selfIndex + 2) % snapshot.players.length];
    final rightPlayer =
        snapshot.players[(selfIndex + 1) % snapshot.players.length];
    final currentTrickView = buildCurrentTrickView(snapshot.recentActions);
    final currentTrickActions = currentTrickView.actionsByPlayer;
    final myTurn = snapshot.currentTurnPlayerId == me.playerId;
    final managed = _isManaged(snapshot, me.playerId);
    final waitingMyBid = snapshot.phase == RoomPhase.waiting && myTurn;
    final selfCards = [...snapshot.selfCards]..sort(_compareSelfCards);

    _sync(snapshot);
    _syncGameError();

    return Scaffold(
      body: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) {
          if (_musicEnabled) {
            unawaited(_voice.startBackgroundMusic());
          }
        },
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFF8FCFF),
                Color(0xFFEAF6FF),
                Color(0xFFDCEEFF),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, viewport) {
                final mobileViewport =
                    viewport.maxWidth < 960 || viewport.maxHeight < 700;
                final narrowViewport =
                    viewport.maxWidth < 1320 || viewport.maxHeight < 860;
                final designWidth = mobileViewport
                    ? 1180.0
                    : narrowViewport
                        ? 1380.0
                        : 1540.0;
                final designHeight = mobileViewport
                    ? 760.0
                    : narrowViewport
                        ? 860.0
                        : 920.0;
                return Center(
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: SizedBox(
                      width: designWidth,
                      height: designHeight,
                      child: Stack(
                        children: [
                          Column(
                            children: [
                              _buildTopHud(snapshot, mobile: mobileViewport),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      final compact =
                                          mobileViewport || constraints.maxWidth < 1080;
                                      final seatWidth = mobileViewport
                                          ? 214.0
                                          : compact
                                              ? 228.0
                                              : 270.0;
                                      final playedWidth = mobileViewport
                                          ? 122.0
                                          : compact
                                              ? 118.0
                                              : 138.0;
                                      final sideTrayWidth = mobileViewport
                                          ? 372.0
                                          : compact
                                              ? 454.0
                                              : 520.0;
                                      final selfTrayWidth = mobileViewport
                                          ? 500.0
                                          : compact
                                              ? 580.0
                                              : 700.0;
                                      final trayLayouts = <_PlayedTrayLayout>[
                                        _PlayedTrayLayout(
                                          position: _PlayedTrayPosition.left,
                                          player: leftPlayer,
                                          active: snapshot.currentTurnPlayerId ==
                                              leftPlayer.playerId,
                                          towardCenter: true,
                                          centered: false,
                                          width: sideTrayWidth,
                                          displayAction:
                                              currentTrickActions[leftPlayer.playerId],
                                          isLeadingPlay:
                                              currentTrickView.leadingPlayerId ==
                                                  leftPlayer.playerId,
                                        ),
                                        _PlayedTrayLayout(
                                          position: _PlayedTrayPosition.right,
                                          player: rightPlayer,
                                          active: snapshot.currentTurnPlayerId ==
                                              rightPlayer.playerId,
                                          towardCenter: false,
                                          centered: false,
                                          width: sideTrayWidth,
                                          displayAction:
                                              currentTrickActions[rightPlayer.playerId],
                                          isLeadingPlay:
                                              currentTrickView.leadingPlayerId ==
                                                  rightPlayer.playerId,
                                        ),
                                        _PlayedTrayLayout(
                                          position: _PlayedTrayPosition.self,
                                          player: me,
                                          active: myTurn &&
                                              snapshot.phase != RoomPhase.finished,
                                          towardCenter: true,
                                          centered: true,
                                          width: selfTrayWidth,
                                          displayAction:
                                              currentTrickActions[me.playerId],
                                          isLeadingPlay:
                                              currentTrickView.leadingPlayerId ==
                                                  me.playerId,
                                        ),
                                      ]
                                        ..removeWhere(
                                          (layout) => layout.displayAction == null,
                                        )
                                        ..sort((left, right) {
                                          final leftPriority =
                                              left.displayAction!.emphasis ==
                                                      TrickActionEmphasis.primary
                                                  ? 1
                                                  : 0;
                                          final rightPriority =
                                              right.displayAction!.emphasis ==
                                                      TrickActionEmphasis.primary
                                                  ? 1
                                                  : 0;
                                          if (leftPriority != rightPriority) {
                                            return leftPriority.compareTo(
                                              rightPriority,
                                            );
                                          }
                                          return left.displayAction!.action
                                              .timestampMs
                                              .compareTo(
                                                right.displayAction!.action
                                                    .timestampMs,
                                              );
                                        });
                                      return Stack(
                                        children: [
                                          Positioned.fill(
                                            child: _buildTable(snapshot.mode),
                                          ),
                                          Positioned(
                                            left: compact ? 16 : 22,
                                            top: 18,
                                            child: _buildSeat(
                                              snapshot,
                                              leftPlayer,
                                              active:
                                                  snapshot.currentTurnPlayerId ==
                                                      leftPlayer.playerId,
                                              towardCenter: true,
                                              width: seatWidth,
                                            ),
                                          ),
                                          Positioned(
                                            right: compact ? 16 : 22,
                                            top: 18,
                                            child: _buildSeat(
                                              snapshot,
                                              rightPlayer,
                                              active:
                                                  snapshot.currentTurnPlayerId ==
                                                      rightPlayer.playerId,
                                              towardCenter: false,
                                              width: seatWidth,
                                            ),
                                          ),
                                          if (_bannerText != null)
                                            Positioned(
                                              left: 0,
                                              right: 0,
                                              top: compact ? 92 : 104,
                                              child: Center(
                                                child: _bannerPill(_bannerText!),
                                              ),
                                            ),
                                          if (snapshot.phase == RoomPhase.waiting)
                                            Positioned(
                                              left: 0,
                                              right: 0,
                                              top: compact ? 146 : 162,
                                              child: Center(
                                                child: _hintPill(
                                                  myTurn
                                                      ? '\u8f6e\u5230\u4f60\u53eb\u5206'
                                                      : '\u7b49\u5f85 ${_name(snapshot, snapshot.currentTurnPlayerId)} \u53eb\u5206',
                                                ),
                                              ),
                                            ),
                                          for (final layout in trayLayouts)
                                            Align(
                                              alignment: _trayAlignment(
                                                compact: compact,
                                                position: layout.position,
                                                emphasis:
                                                    layout.displayAction!.emphasis,
                                              ),
                                              child: SizedBox(
                                                width: layout.width,
                                                child: _buildPlayedTray(
                                                  player: layout.player,
                                                  action: layout.displayAction!.action,
                                                  emphasis:
                                                      layout.displayAction!.emphasis,
                                                  active: layout.active,
                                                  towardCenter:
                                                      layout.towardCenter,
                                                  centered: layout.centered,
                                                  cardWidth: layout.position ==
                                                          _PlayedTrayPosition.self
                                                      ? playedWidth + 12
                                                      : playedWidth,
                                                  maxWidth: layout.width,
                                                  showName: layout.position !=
                                                      _PlayedTrayPosition.self,
                                                  isLeadingPlay:
                                                      layout.isLeadingPlay,
                                                ),
                                              ),
                                            ),
                                          if (snapshot.phase != RoomPhase.finished &&
                                              myTurn &&
                                              !waitingMyBid)
                                            Positioned(
                                              left: 0,
                                              right: 0,
                                              bottom: compact ? 154 : 164,
                                              child: IgnorePointer(
                                                child: Center(
                                                  child: _turnPrompt(
                                                    waitingMyBid: false,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          if (waitingMyBid)
                                            Positioned(
                                              left: 0,
                                              right: 0,
                                              bottom: mobileViewport ? 12 : 18,
                                              child: Center(
                                                child: _buildBidChooser(),
                                              ),
                                            ),
                                          if (snapshot.phase == RoomPhase.finished)
                                            Positioned.fill(
                                              child: _buildResult(snapshot, me),
                                            ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ),
                              _buildBottomDock(
                                snapshot,
                                me,
                                selfCards: selfCards,
                                waitingMyBid: waitingMyBid,
                                myTurn: myTurn,
                                managed: managed,
                                mobile: mobileViewport,
                              ),
                            ],
                          ),
                          if (_errorNotice != null)
                            Positioned(
                              left: 0,
                              right: 0,
                              top: 92,
                              child: IgnorePointer(
                                child: Center(
                                  child: _buildErrorNotice(_errorNotice!),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopHud(RoomSnapshot snapshot, {required bool mobile}) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        mobile ? 12 : 16,
        mobile ? 10 : 14,
        mobile ? 12 : 16,
        0,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = mobile || constraints.maxWidth < 1260;
          final topInfoCluster = Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 12 : 16,
              vertical: compact ? 10 : 12,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: Colors.white.withValues(alpha: 0.90),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x143678A3),
                  blurRadius: 18,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 10 : 12,
                    vertical: compact ? 8 : 10,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: const Color(0xFFF6FAFF),
                    border: Border.all(color: const Color(0xFFD7EBFF)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '\u5e95\u724c',
                        style: TextStyle(
                          color: Color(0xFF245E90),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 8),
                      for (var index = 0; index < snapshot.landlordCards.length; index++) ...[
                        _miniCard(
                          snapshot.landlordCards[index].rankLabel,
                          snapshot.landlordCards[index].isRed,
                        ),
                        if (index != snapshot.landlordCards.length - 1)
                          const SizedBox(width: 4),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _hudButton(
                Icons.arrow_back_rounded,
                '\u5927\u5385',
                widget.controller.backToLobby,
                dense: true,
              ),
              SizedBox(width: mobile ? 8 : 12),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      flex: mobile ? 3 : 2,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: topInfoCluster,
                        ),
                      ),
                    ),
                    SizedBox(width: mobile ? 8 : 12),
                    if (_showCounter)
                      Expanded(
                        flex: mobile ? 6 : 7,
                        child: _buildCounter(
                          snapshot.cardCounter,
                          compact: !mobile,
                          singleLine: true,
                        ),
                      )
                    else
                      const Spacer(),
                    SizedBox(width: mobile ? 8 : 12),
                    _hudButton(
                      _musicEnabled
                          ? Icons.music_off_rounded
                          : Icons.music_note_rounded,
                      _musicEnabled
                          ? '\u5173\u95ed\u97f3\u4e50'
                          : '\u5f00\u542f\u97f3\u4e50',
                      () {
                        setState(() => _musicEnabled = !_musicEnabled);
                        if (_musicEnabled) {
                          unawaited(_voice.startBackgroundMusic());
                        } else {
                          unawaited(_voice.stopBackgroundMusic());
                        }
                      },
                      dense: true,
                    ),
                    SizedBox(width: mobile ? 6 : 8),
                    _hudButton(
                      _showCounter
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      _showCounter
                          ? '\u9690\u85cf\u724c\u51b5'
                          : '\u663e\u793a\u724c\u51b5',
                      () => setState(() => _showCounter = !_showCounter),
                      dense: true,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTable(MatchMode mode) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        gradient: const LinearGradient(
          colors: [Color(0xFFF7FCFF), Color(0xFFE6F4FF), Color(0xFFD0E9FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.95),
          width: 1.5,
        ),
      ),
      child: Stack(
        children: [
          Align(
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0x332B7FFF), width: 2),
              ),
            ),
          ),
          const Align(
            child: Text(
              '\u6b22\u4e50\u6597\u5730\u4e3b',
              style: TextStyle(
                color: Color(0x181D5687),
                fontSize: 52,
                fontWeight: FontWeight.w900,
                letterSpacing: 8,
              ),
            ),
          ),
          Positioned(
            left: 24,
            bottom: 18,
            child: Text(
              mode == MatchMode.online
                  ? '\u771f\u4eba\u724c\u684c'
                  : '\u4eba\u673a\u70ed\u8eab',
              style: const TextStyle(
                color: Color(0x7F54728E),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeat(
    RoomSnapshot snapshot,
    RoomPlayer player, {
    required bool active,
    required bool towardCenter,
    required double width,
  }) {
    final managed = _isManaged(snapshot, player.playerId);
    final roleText = player.isLandlord ? '\u5730\u4e3b' : '\u519c\u6c11';
    return AnimatedScale(
      duration: const Duration(milliseconds: 220),
      scale: active ? 1.02 : 1,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: width,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            colors: active
                ? [
                    Colors.white,
                    const Color(0xFFF4FAFF),
                    const Color(0xFFE6F3FF),
                  ]
                : [
                    Colors.white.withValues(alpha: 0.95),
                    Colors.white.withValues(alpha: 0.90),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: active ? const Color(0xFF2B7FFF) : const Color(0xFFD7EBFF),
            width: active ? 2.4 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: active ? const Color(0x2E2B7FFF) : const Color(0x123678A3),
              blurRadius: active ? 28 : 14,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              towardCenter ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: const Color(0xFF2B7FFF),
                  child: Text(
                    player.displayName.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 26,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player.displayName,
                        style: const TextStyle(
                          color: Color(0xFF173A59),
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$roleText / ${player.cardsLeft} \u5f20',
                        style: const TextStyle(
                          color: Color(0xFF5A7894),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                if (active) _turnDial(managed: managed),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _seatTag(roleText, player.isLandlord
                    ? const Color(0xFFF6B24B)
                    : const Color(0xFF6FAAFF)),
                if (player.isBot)
                  _seatTag('\u673a\u5668\u4eba', const Color(0xFF8BA4BE)),
                if (managed) _seatTag('\u6258\u7ba1\u4e2d', const Color(0xFF2B7FFF)),
                if (active) _seatTag('\u8f6e\u5230\u51fa\u724c', const Color(0xFF2B7FFF)),
              ],
            ),
            const SizedBox(height: 14),
            Align(
              alignment:
                  towardCenter ? Alignment.centerLeft : Alignment.centerRight,
              child: _backFan(player.cardsLeft, towardCenter: towardCenter),
            ),
          ],
        ),
      ),
    );
  }

  Widget _turnDial({required bool managed}) {
    final progress = (_secondsLeft / 25).clamp(0.0, 1.0);
    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 52,
            height: 52,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 4,
              backgroundColor: const Color(0xFFE1EEFF),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF2B7FFF)),
            ),
          ),
          Text(
            managed ? '\u6258' : '$_secondsLeft',
            style: const TextStyle(
              color: Color(0xFF173A59),
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomPlayerSummary(
    RoomSnapshot snapshot,
    RoomPlayer me, {
    required bool active,
    required bool managed,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withValues(alpha: 0.92),
        border: Border.all(
          color: active ? const Color(0xFF2B7FFF) : const Color(0xFFD7EBFF),
          width: active ? 2 : 1,
        ),
        boxShadow: active
            ? const [
                BoxShadow(
                  color: Color(0x1D2B7FFF),
                  blurRadius: 18,
                  offset: Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 17,
                    backgroundColor: const Color(0xFF2B7FFF),
                    child: Text(
                      me.displayName.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        me.displayName,
                        style: const TextStyle(
                          color: Color(0xFF173A59),
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${me.isLandlord ? '\u5730\u4e3b' : '\u519c\u6c11'} / ${managed ? '\u6258\u7ba1\u4e2d' : '\u4f60\u5728\u724c\u684c'}',
                        style: const TextStyle(
                          color: Color(0xFF5A7894),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _summaryChip(
                    snapshot.mode == MatchMode.online
                        ? '\u771f\u4eba\u5339\u914d'
                        : widget.controller.botDifficulty.gameChip,
                    filled: snapshot.mode != MatchMode.online,
                  ),
                  _summaryChip('\u5e95\u5206 ${snapshot.baseScore}'),
                  _summaryChip('\u500d\u6570 ${snapshot.multiplier}'),
                  _summaryChip('\u672c\u8f6e ${snapshot.currentRoundScore}'),
                  if (snapshot.springTriggered) _summaryChip('\u6625\u5929'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Alignment _trayAlignment({
    required bool compact,
    required _PlayedTrayPosition position,
    required TrickActionEmphasis emphasis,
  }) {
    final primary = emphasis == TrickActionEmphasis.primary;
    return switch (position) {
      _PlayedTrayPosition.left => compact
          ? Alignment(primary ? -0.20 : -0.57, primary ? -0.03 : -0.11)
          : Alignment(primary ? -0.18 : -0.52, primary ? -0.04 : -0.10),
      _PlayedTrayPosition.right => compact
          ? Alignment(primary ? 0.20 : 0.57, primary ? -0.03 : -0.11)
          : Alignment(primary ? 0.18 : 0.52, primary ? -0.04 : -0.10),
      _PlayedTrayPosition.self => compact
          ? Alignment(0, primary ? 0.18 : 0.24)
          : Alignment(0, primary ? 0.14 : 0.20),
    };
  }

  Widget _turnPrompt({required bool waitingMyBid}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: const LinearGradient(
            colors: [Color(0xFF8ACBFF), Color(0xFF2B7FFF)],
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x332B7FFF),
              blurRadius: 24,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.bolt_rounded,
              size: 18,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              waitingMyBid ? '\u5230\u4f60\u53eb\u5206' : '\u5230\u4f60\u51fa\u724c',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );

  Widget _buildBidChooser() => Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: Colors.white.withValues(alpha: 0.96),
          border: Border.all(color: const Color(0xFFD7EBFF)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x223678A3),
              blurRadius: 28,
              offset: Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '\u9009\u62e9\u672c\u8f6e\u53eb\u5206',
              style: TextStyle(
                color: Color(0xFF173A59),
                fontWeight: FontWeight.w900,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              '\u5730\u4e3b\u672a\u5b9a\uff0c\u8bf7\u5728\u8fd9\u91cc\u76f4\u63a5\u9009\u62e9\u53eb\u5206\u3002',
              style: TextStyle(
                color: Color(0xFF5A7894),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                _actionButton(
                  '\u4e0d\u53eb',
                  widget.controller.isBusy
                      ? null
                      : () => widget.controller.callScore(0),
                  primary: false,
                ),
                _actionButton(
                  '1 \u5206',
                  widget.controller.isBusy
                      ? null
                      : () => widget.controller.callScore(1),
                  primary: false,
                ),
                _actionButton(
                  '2 \u5206',
                  widget.controller.isBusy
                      ? null
                      : () => widget.controller.callScore(2),
                  primary: false,
                ),
                _actionButton(
                  '3 \u5206',
                  widget.controller.isBusy
                      ? null
                      : () => widget.controller.callScore(3),
                  primary: true,
                ),
              ],
            ),
          ],
        ),
      );

  Widget _buildPlayedTray({
    required RoomPlayer player,
    required TableAction? action,
    required TrickActionEmphasis emphasis,
    required bool active,
    required bool towardCenter,
    required double cardWidth,
    required double maxWidth,
    required bool isLeadingPlay,
    bool showName = true,
    bool centered = false,
  }) {
    if (action == null) {
      return const SizedBox.shrink();
    }
    final primary = emphasis == TrickActionEmphasis.primary;
    final label = _display(action);
    final hasCards = action.cards.isNotEmpty;
    final isPass = action.type == ActionType.pass;
    final toneColor = isLeadingPlay && primary
        ? const Color(0xFF1F69FF)
        : active && primary
            ? const Color(0xFF2B7FFF)
            : primary
                ? const Color(0xFF355A78)
                : const Color(0xFF6585A6);
    final displayCardWidth = primary
        ? cardWidth
        : centered
            ? cardWidth * 0.74
            : cardWidth * 0.62;
    final fanMaxWidth = primary
        ? maxWidth
        : math.min(maxWidth * (centered ? 0.60 : 0.48), 280.0);
    return AnimatedScale(
      duration: const Duration(milliseconds: 220),
      scale: primary && (active || isLeadingPlay) && hasCards ? 1.02 : 1,
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: centered
              ? CrossAxisAlignment.center
              : towardCenter
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment:
                  centered ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                if (showName)
                  Flexible(
                    child: Text(
                      player.displayName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF6A839A),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                if (active) ...[
                  if (showName) const SizedBox(width: 8),
                  if (primary) _turnStateChip(),
                ],
              ],
            ),
            SizedBox(height: primary ? 8 : 5),
            if (hasCards) ...[
              Align(
                alignment: centered
                    ? Alignment.center
                    : towardCenter
                        ? Alignment.centerLeft
                        : Alignment.centerRight,
                child: _playedFan(
                  action.cards,
                  towardCenter: towardCenter,
                  centered: centered,
                  width: displayCardWidth,
                  maxWidth: fanMaxWidth,
                ),
              ),
              SizedBox(height: primary ? 8 : 5),
              Text(
                label,
                textAlign: centered ? TextAlign.center : TextAlign.start,
                style: TextStyle(
                  color: toneColor,
                  fontWeight: FontWeight.w900,
                  fontSize: primary ? 20 : 15,
                  shadows: primary
                      ? [
                          Shadow(
                            color: toneColor.withValues(alpha: 0.18),
                            blurRadius: 10,
                          ),
                        ]
                      : null,
                ),
              ),
            ] else ...[
              Text(
                isPass ? label : player.displayName,
                textAlign: centered ? TextAlign.center : TextAlign.start,
                style: TextStyle(
                  color: isPass ? toneColor : const Color(0xFF5A7894),
                  fontWeight: FontWeight.w900,
                  fontSize: isPass
                      ? (primary ? 24 : 17)
                      : (primary ? 16 : 13),
                  letterSpacing: isPass ? 1.5 : 0,
                  shadows: isPass
                      ? primary
                          ? [
                              Shadow(
                                color: toneColor.withValues(alpha: 0.20),
                                blurRadius: 12,
                              ),
                            ]
                          : null
                      : null,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCounter(List<CardCounterEntry> entries,
      {bool compact = false, bool singleLine = false}) {
    final sorted = [...entries]
      ..sort((a, b) => _weight(b.rank).compareTo(_weight(a.rank)));
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        compact ? 10 : 14,
        compact ? 8 : 12,
        compact ? 10 : 14,
        compact ? 8 : 12,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white.withValues(alpha: 0.92),
        border: Border.all(color: const Color(0xFFD7EBFF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x143678A3),
            blurRadius: 14,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (singleLine)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: const Color(0xFFF2F8FF),
                      border: Border.all(color: const Color(0xFFD7EBFF)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.style_rounded,
                          size: 15,
                          color: Color(0xFF2B7FFF),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '\u5269\u4f59\u724c\u7edf\u8ba1',
                          style: TextStyle(
                            color: const Color(0xFF245E90),
                            fontWeight: FontWeight.w900,
                            fontSize: compact ? 12 : 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: compact ? 6 : 8),
                  for (var index = 0; index < sorted.length; index++) ...[
                    _counterPill(sorted[index], compact: compact, singleLine: true),
                    if (index != sorted.length - 1)
                      SizedBox(width: compact ? 3 : 4),
                  ],
                ],
              ),
            )
          else ...[
            Row(
              children: [
                const Icon(
                  Icons.style_rounded,
                  size: 18,
                  color: Color(0xFF2B7FFF),
                ),
                const SizedBox(width: 8),
                Text(
                  '\u5269\u4f59\u724c\u7edf\u8ba1',
                  style: TextStyle(
                    color: const Color(0xFF245E90),
                    fontWeight: FontWeight.w900,
                    fontSize: compact ? 13 : 14,
                  ),
                ),
              ],
            ),
            SizedBox(height: compact ? 8 : 10),
            Wrap(
              spacing: compact ? 6 : 8,
              runSpacing: compact ? 6 : 8,
              children: [
                for (final entry in sorted)
                  _counterPill(entry, compact: compact, singleLine: false),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _counterPill(CardCounterEntry entry,
      {required bool compact, required bool singleLine}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: singleLine
            ? (compact ? 6 : 8)
            : (compact ? 4 : 8),
        vertical: singleLine ? (compact ? 3 : 5) : (compact ? 4 : 7),
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFFF4FAFF),
        border: Border.all(color: const Color(0xFFD7EBFF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _counter(entry.rank),
            style: TextStyle(
              color: const Color(0xFF5A7894),
              fontWeight: FontWeight.w700,
              fontSize:
                  singleLine ? (compact ? 11 : 12) : (compact ? 10 : 12),
            ),
          ),
          SizedBox(width: singleLine ? 4 : 6),
          Text(
            '${entry.remaining}',
            style: TextStyle(
              color: const Color(0xFF173A59),
              fontWeight: FontWeight.w900,
              fontSize: singleLine ? (compact ? 12 : 13) : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomDock(
    RoomSnapshot snapshot,
    RoomPlayer me, {
    required List<PlayingCard> selfCards,
    required bool waitingMyBid,
    required bool myTurn,
    required bool managed,
    required bool mobile,
  }) {
    final statusText = widget.controller.busyText ??
        (waitingMyBid
            ? '\u8bf7\u9009\u62e9\u4f60\u8981\u53eb\u7684\u5206\u6570'
            : managed
                ? '\u5f53\u524d\u5df2\u8fdb\u5165\u6258\u7ba1\uff0c\u53ef\u968f\u65f6\u53d6\u6d88\u6258\u7ba1\u91cd\u65b0\u63a5\u624b\u3002'
                : myTurn
                    ? '\u8f6e\u5230\u4f60\u64cd\u4f5c\uff0c\u5148\u9009\u724c\u518d\u51fa\u724c\u3002'
                    : '\u7b49\u5f85\u5176\u4ed6\u73a9\u5bb6\u64cd\u4f5c\u3002');
    return Container(
      margin: EdgeInsets.fromLTRB(mobile ? 10 : 14, 0, mobile ? 10 : 14, 2),
      padding: EdgeInsets.fromLTRB(mobile ? 8 : 10, 3, mobile ? 8 : 10, 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          colors: myTurn && !managed
              ? const [Colors.white, Color(0xFFEFF7FF)]
              : const [Colors.white, Color(0xFFF4FAFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: myTurn && !managed
              ? const Color(0xFF8CC8FF)
              : const Color(0xFFD7EBFF),
          width: myTurn && !managed ? 1.4 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: myTurn && !managed
                ? const Color(0x222B7FFF)
                : const Color(0x143678A3),
            blurRadius: myTurn && !managed ? 28 : 22,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _bottomPlayerSummary(
                      snapshot,
                      me,
                      active: myTurn,
                      managed: managed,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '\u4f60\u7684\u624b\u724c / ${me.isLandlord ? '\u5730\u4e3b' : '\u519c\u6c11'}',
                                style: const TextStyle(
                                  color: Color(0xFF173A59),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 6),
                              if (snapshot.phase != RoomPhase.finished)
                                _chip(
                                  myTurn
                                      ? (waitingMyBid
                                          ? '\u8f6e\u5230\u4f60\u53eb\u5206'
                                          : '\u8f6e\u5230\u4f60\u51fa\u724c')
                                      : managed
                                          ? '\u6258\u7ba1\u4e2d'
                                          : '\u7b49\u5f85\u4e2d',
                                ),
                              if (myTurn && snapshot.phase != RoomPhase.finished) ...[
                                const SizedBox(width: 6),
                                _turnStateChip(compact: false),
                              ],
                            ],
                          ),
                          const SizedBox(height: 1),
                          Text(
                            statusText,
                            style: const TextStyle(
                              color: Color(0xFF5A7894),
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (snapshot.phase != RoomPhase.finished) ...[
                OutlinedButton(
                  onPressed:
                      _selectedIds.isEmpty ? null : () => setState(_selectedIds.clear),
                  child: const Text('\u6e05\u7a7a\u9009\u62e9'),
                ),
                const SizedBox(width: 6),
                OutlinedButton(
                  onPressed: snapshot.phase == RoomPhase.playing &&
                          myTurn &&
                          !managed &&
                          !widget.controller.isBusy
                      ? _toggleSuggestedSelection
                      : null,
                  child: Text(
                    _isSuggestedSelectionActive()
                        ? '\u53d6\u6d88\u63d0\u793a'
                        : '\u63d0\u793a',
                  ),
                ),
                const SizedBox(width: 6),
                FilledButton.tonal(
                  onPressed: widget.controller.isBusy
                      ? null
                      : () => widget.controller.setManaged(!managed),
                  child: Text(
                    managed ? '\u53d6\u6d88\u6258\u7ba1' : '\u6258\u7ba1',
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 2),
          _selfFan(selfCards, disabled: waitingMyBid || managed),
          const SizedBox(height: 2),
          if (snapshot.phase == RoomPhase.playing && snapshot.phase != RoomPhase.finished)
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                _actionButton(
                  '\u4e0d\u51fa',
                  snapshot.phase == RoomPhase.playing &&
                          myTurn &&
                          !managed &&
                          !widget.controller.isBusy
                      ? widget.controller.pass
                      : null,
                  primary: false,
                ),
                _actionButton(
                  '\u51fa\u724c',
                  snapshot.phase == RoomPhase.playing &&
                          myTurn &&
                          !managed &&
                          _selectedIds.isNotEmpty &&
                          !widget.controller.isBusy
                      ? () async {
                          await widget.controller.playCards(
                            _selectedIds.toList(),
                          );
                          if (mounted) {
                            setState(_selectedIds.clear);
                          }
                        }
                      : null,
                  primary: true,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _selfFan(List<PlayingCard> cards, {required bool disabled}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const width = 130.0;
        final minSpacing = width * 0.38;
        final maxSpacing = width * 0.54;
        final spacing = cards.length <= 1
            ? width
            : ((constraints.maxWidth - width) / (cards.length - 1))
                .clamp(minSpacing, maxSpacing);
        final totalWidth =
            cards.isEmpty ? width : width + (cards.length - 1) * spacing;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: disabled
                ? null
                : (event) {
                    final index = _handIndexAtPosition(
                      cards,
                      event.localPosition.dx,
                      spacing,
                      width,
                      totalWidth,
                    );
                    if (index == null) {
                      return;
                    }
                    setState(() {
                      _dragSelectionActive = true;
                      _dragSelectionValue =
                          !_selectedIds.contains(cards[index].id);
                      _lastDragIndex = index;
                      _applyDragSelectionRange(
                        cards,
                        index,
                        index,
                        _dragSelectionValue,
                      );
                    });
                  },
            onPointerMove: disabled
                ? null
                : (event) {
                    if (!_dragSelectionActive || _lastDragIndex == null) {
                      return;
                    }
                    final index = _handIndexAtPosition(
                      cards,
                      event.localPosition.dx,
                      spacing,
                      width,
                      totalWidth,
                    );
                    if (index == null || index == _lastDragIndex) {
                      return;
                    }
                    setState(() {
                      _applyDragSelectionRange(
                        cards,
                        _lastDragIndex!,
                        index,
                        _dragSelectionValue,
                      );
                      _lastDragIndex = index;
                    });
                  },
            onPointerUp: disabled ? null : (_) => _endDragSelection(),
            onPointerCancel: disabled ? null : (_) => _endDragSelection(),
            child: SizedBox(
              width: totalWidth,
              height: width * 1.48,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  for (var index = 0; index < cards.length; index++)
                    Positioned(
                      left: index * spacing,
                      top: _selectedIds.contains(cards[index].id) ? 0 : 7,
                      child: _cardFace(
                        cards[index],
                        width,
                        selected: _selectedIds.contains(cards[index].id),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _backFan(int count, {required bool towardCenter}) {
    const width = 38.0;
    final visible = math.min(count, 11);
    final spacing = width * 0.24;
    final totalWidth =
        visible == 0 ? width : width + (visible - 1) * spacing;
    return SizedBox(
      width: totalWidth,
      height: width * 1.56,
      child: Stack(
        children: [
          for (var index = 0; index < visible; index++)
            Positioned(
              left: towardCenter ? index * spacing : null,
              right: towardCenter ? null : index * spacing,
              child: Transform.rotate(
                angle: towardCenter ? -0.035 * index : 0.035 * index,
                child: _cardBack(width),
              ),
            ),
        ],
      ),
    );
  }

  Widget _playedFan(List<PlayingCard> cards,
      {required bool towardCenter,
      required bool centered,
      required double width,
      required double maxWidth}) {
    if (cards.isEmpty) {
      return const SizedBox.shrink();
    }
    var cardWidth = width;
    var spacing = cards.length <= 1
        ? cardWidth
        : cardWidth *
            (cards.length >= 8
                ? 0.76
                : cards.length >= 6
                    ? 0.80
                    : 0.84);
    var totalWidth =
        cards.length <= 1 ? cardWidth : cardWidth + (cards.length - 1) * spacing;
    if (cards.length > 1 && totalWidth > maxWidth) {
      final scale = (maxWidth / totalWidth).clamp(0.74, 1.0);
      cardWidth = cardWidth * scale;
      spacing = (maxWidth - cardWidth) / (cards.length - 1);
      totalWidth = maxWidth;
    }
    var paintOrder = List<int>.generate(cards.length, (value) => value);
    if (!centered && !towardCenter) {
      paintOrder = paintOrder.reversed.toList();
    }
    return SizedBox(
      width: totalWidth,
      height: cardWidth * 1.56,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (final index in paintOrder)
            Positioned(
              left: centered || towardCenter ? index * spacing : null,
              right: centered || towardCenter ? null : index * spacing,
              child: _cardFace(cards[index], cardWidth),
            ),
        ],
      ),
    );
  }

  Widget _cardFace(PlayingCard card, double width, {bool selected = false}) {
    final textColor =
        card.isRed ? const Color(0xFFC53C35) : const Color(0xFF1F2D40);
    final cornerLabel = card.rankLabel;
    final centerSuitSize = card.suit == 'C' || card.suit == 'S'
        ? width * 0.34
        : width * 0.38;
    return AnimatedScale(
      scale: selected ? 1.03 : 1,
      duration: const Duration(milliseconds: 140),
      child: Container(
        width: width,
        height: width * 1.42,
        padding: EdgeInsets.symmetric(
          horizontal: width * 0.12,
          vertical: width * 0.10,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(width * 0.18),
          gradient: const LinearGradient(
            colors: [Colors.white, Color(0xFFF8FBFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: selected ? const Color(0xFF2B7FFF) : const Color(0xFFD5E6F7),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              cornerLabel,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w900,
                fontSize: card.isJoker ? width * 0.17 : width * 0.24,
                height: 1,
              ),
            ),
            const Spacer(),
            Center(
              child: card.isJoker
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          card.rank == 'BJ'
                              ? Icons.workspace_premium_rounded
                              : Icons.auto_awesome_rounded,
                          color: textColor,
                          size: width * 0.34,
                        ),
                        SizedBox(height: width * 0.03),
                        Text(
                          card.rank == 'BJ'
                              ? '\u738b'
                              : '\u9b3c',
                          style: TextStyle(
                            color: textColor,
                            fontSize: width * 0.12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      card.suitSymbol,
                      style: TextStyle(
                        color: textColor,
                        fontSize: centerSuitSize,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
            ),
            const Spacer(),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                cornerLabel,
                style: TextStyle(
                  color: textColor,
                  fontSize: card.isJoker ? width * 0.15 : width * 0.18,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardBack(double width) => Container(
        width: width,
        height: width * 1.42,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(width * 0.18),
          gradient: const LinearGradient(
            colors: [Color(0xFF68AEFF), Color(0xFF2D73E9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.80)),
        ),
      );

  Widget _miniCard(String label, bool isRed) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.white,
          border: Border.all(color: const Color(0xFFD7EBFF)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isRed ? const Color(0xFFC53C35) : const Color(0xFF173A59),
            fontWeight: FontWeight.w900,
          ),
        ),
      );

  Widget _chip(String text, {bool filled = false}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: filled ? const Color(0xFF2B7FFF) : const Color(0x142B7FFF),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: filled ? Colors.white : const Color(0xFF2B7FFF),
            fontWeight: FontWeight.w800,
          ),
        ),
      );

  Widget _summaryChip(String text, {bool filled = false}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: filled ? const Color(0xFF2B7FFF) : const Color(0x142B7FFF),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: filled ? Colors.white : const Color(0xFF2B7FFF),
            fontWeight: FontWeight.w800,
            fontSize: 11,
          ),
        ),
      );

  Widget _seatTag(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: color.withValues(alpha: 0.12),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      );

  Widget _turnStateChip({bool compact = true}) => Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 12,
          vertical: compact ? 6 : 7,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: const LinearGradient(
            colors: [Color(0xFF9FD5FF), Color(0xFF2B7FFF)],
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.timelapse_rounded,
              size: 14,
              color: Colors.white,
            ),
            const SizedBox(width: 4),
            Text(
              '$_secondsLeft s',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: compact ? 12 : 13,
              ),
            ),
          ],
        ),
      );

  Widget _hudButton(IconData icon, String label, VoidCallback onTap,
          {bool dense = false}) =>
      InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          padding: EdgeInsets.symmetric(
            horizontal: dense ? 12 : 14,
            vertical: dense ? 10 : 12,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white.withValues(alpha: 0.88),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF245E90)),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF245E90),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _bannerPill(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: const LinearGradient(
            colors: [Color(0xFF7EC8FF), Color(0xFF2B7FFF)],
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
      );

  Widget _hintPill(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: Colors.white.withValues(alpha: 0.94),
          border: Border.all(color: const Color(0xFFD7EBFF)),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Color(0xFF2B7FFF),
            fontWeight: FontWeight.w900,
          ),
        ),
      );

  Widget _buildErrorNotice(String text) => AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [Color(0xFFFFFBF7), Color(0xFFFFF2EC)],
          ),
          border: Border.all(color: const Color(0xFFFFD6C7), width: 1.4),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22C55B3F),
              blurRadius: 24,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFFDE2D7),
              ),
              child: const Icon(
                Icons.priority_high_rounded,
                color: Color(0xFFC55B3F),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                text,
                style: const TextStyle(
                  color: Color(0xFF8C4736),
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _actionButton(String text, VoidCallback? onTap,
      {required bool primary}) {
    if (primary) {
      return FilledButton(onPressed: onTap, child: Text(text));
    }
    return OutlinedButton(onPressed: onTap, child: Text(text));
  }

  Widget _buildResult(RoomSnapshot snapshot, RoomPlayer me) {
    final win = me.roundScore > 0;
    return Container(
      color: Colors.white.withValues(alpha: 0.65),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: math.min(480, constraints.maxWidth - 24),
                maxHeight: constraints.maxHeight - 32,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(34),
                  color: Colors.white,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        win
                            ? '\u672c\u5c40\u83b7\u80dc'
                            : '\u4e0b\u5c40\u518d\u6765',
                        style: TextStyle(
                          color: win ? const Color(0xFF2B7FFF) : const Color(0xFF6E82A6),
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '\u4f60\u7684\u5f97\u5206 ${me.roundScore >= 0 ? '+' : ''}${me.roundScore}',
                        style: const TextStyle(
                          color: Color(0xFF173A59),
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 22),
                      for (final player in snapshot.players)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${player.displayName} / ${player.isLandlord ? '\u5730\u4e3b' : '\u519c\u6c11'}',
                                  style: const TextStyle(
                                    color: Color(0xFF5A7894),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Text(
                                '${player.roundScore >= 0 ? '+' : ''}${player.roundScore}',
                                style: TextStyle(
                                  color: player.roundScore >= 0
                                      ? const Color(0xFF2B7FFF)
                                      : const Color(0xFF7B8DAF),
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: widget.controller.backToLobby,
                        child: const Text('\u56de\u5230\u5927\u5385'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

String _name(RoomSnapshot snapshot, String playerId) {
  for (final player in snapshot.players) {
    if (player.playerId == playerId) {
      return player.displayName;
    }
  }
  return '\u724c\u624b';
}

String _counter(String rank) => switch (rank) {
      'BJ' => '\u5927\u738b',
      'SJ' => '\u5c0f\u738b',
      _ => rank,
    };

int _compareSelfCards(PlayingCard left, PlayingCard right) {
  final byWeight = _weight(left.rank).compareTo(_weight(right.rank));
  if (byWeight != 0) {
    return byWeight;
  }
  final bySuit = _suitOrder(left.suit).compareTo(_suitOrder(right.suit));
  if (bySuit != 0) {
    return bySuit;
  }
  return left.id.compareTo(right.id);
}

int _suitOrder(String suit) {
  const suitRanks = {
    'C': 0,
    'D': 1,
    'S': 2,
    'H': 3,
    '': 4,
  };
  return suitRanks[suit] ?? 5;
}

int _weight(String rank) {
  const map = {
    'BJ': 17,
    'SJ': 16,
    '2': 15,
    'A': 14,
    'K': 13,
    'Q': 12,
    'J': 11,
    '10': 10,
    '9': 9,
    '8': 8,
    '7': 7,
    '6': 6,
    '5': 5,
    '4': 4,
    '3': 3,
  };
  return map[rank] ?? 0;
}

String _display(TableAction action) {
  if (action.patternLabel == 'managed_on') return '\u6258\u7ba1\u4e2d';
  if (action.patternLabel == 'managed_off') return '\u53d6\u6d88\u6258\u7ba1';
  if (action.patternLabel == 'bid_pass') return '\u4e0d\u53eb';
  if (action.patternLabel.startsWith('bid_')) {
    return '${action.patternLabel.substring(4)} \u5206';
  }
  if (action.type == ActionType.pass) return '\u4e0d\u51fa';
  switch (action.patternLabel) {
    case 'single':
      return action.cards.isEmpty
          ? '\u5355\u724c'
          : '\u4e00\u5f20 ${action.cards.first.voiceLabel}';
    case 'pair':
      return action.cards.isEmpty
          ? '\u5bf9\u5b50'
          : '\u5bf9 ${action.cards.first.voiceLabel}';
    case 'triple':
      return action.cards.isEmpty
          ? '\u4e09\u5f20'
          : '\u4e09\u5f20 ${action.cards.first.voiceLabel}';
    case 'triple_with_single':
      return '\u4e09\u5e26\u4e00';
    case 'triple_with_pair':
      return '\u4e09\u5e26\u4e8c';
    case 'straight':
      return '\u987a\u5b50';
    case 'straight_pair':
      return '\u8fde\u5bf9';
    case 'airplane':
      return '\u98de\u673a';
    case 'airplane_with_single':
      return '\u98de\u673a\u5e26\u5355';
    case 'airplane_with_pair':
      return '\u98de\u673a\u5e26\u5bf9';
    case 'bomb':
      return '\u70b8\u5f39';
    case 'four_with_two_singles':
      return '\u56db\u5e26\u4e8c';
    case 'four_with_two_pairs':
      return '\u56db\u5e26\u4e24\u5bf9';
    case 'rocket':
      return '\u738b\u70b8';
    default:
      return action.patternLabel;
  }
}

String _banner(TableAction action) {
  if (action.patternLabel == 'managed_on') return '\u5df2\u5f00\u542f\u6258\u7ba1';
  if (action.patternLabel == 'managed_off') return '\u5df2\u53d6\u6d88\u6258\u7ba1';
  if (action.patternLabel == 'bid_pass') return '\u9009\u62e9\u4e86\u4e0d\u53eb';
  if (action.patternLabel.startsWith('bid_')) {
    return '\u53eb\u4e86 ${action.patternLabel.substring(4)} \u5206';
  }
  if (action.type == ActionType.pass) return '\u9009\u62e9\u4e86\u4e0d\u51fa';
  return '\u6253\u51fa ${_display(action)}';
}

String _voiceText(List<TableAction> actions, int index) {
  final action = actions[index];
  final previousPlay = _previousPlayableAction(actions, index);
  final samePatternBeat = previousPlay != null &&
      previousPlay.patternLabel == action.patternLabel;
  if (action.patternLabel == 'managed_on') return '\u6258\u7ba1';
  if (action.patternLabel == 'managed_off') return '\u53d6\u6d88\u6258\u7ba1';
  if (action.patternLabel == 'bid_pass') return '\u4e0d\u53eb';
  if (action.patternLabel.startsWith('bid_')) {
    return '\u53eb${_scoreText(action.patternLabel.substring(4))}\u5206';
  }
  if (action.type == ActionType.pass) {
    return previousPlay == null ? '\u4e0d\u51fa' : '\u8981\u4e0d\u8d77';
  }
  switch (action.patternLabel) {
    case 'single':
      return action.cards.isEmpty
          ? '\u5355\u724c'
          : '\u4e00\u5f20${action.cards.first.voiceLabel}';
    case 'pair':
      return action.cards.isEmpty
          ? '\u5bf9\u5b50'
          : '\u5bf9${action.cards.first.voiceLabel}';
    case 'triple':
      return action.cards.isEmpty
          ? '\u4e09\u5f20'
          : '\u4e09\u4e2a${action.cards.first.voiceLabel}';
    case 'triple_with_single':
      return samePatternBeat ? '\u538b\u4f60\uff0c\u4e09\u5e26\u4e00' : '\u4e09\u5e26\u4e00';
    case 'triple_with_pair':
      return samePatternBeat ? '\u538b\u4f60\uff0c\u4e09\u5e26\u4e8c' : '\u4e09\u5e26\u4e8c';
    case 'straight':
      return samePatternBeat ? '\u538b\u4f60\uff0c\u987a\u5b50' : '\u987a\u5b50';
    case 'straight_pair':
      return samePatternBeat ? '\u538b\u4f60\uff0c\u8fde\u5bf9' : '\u8fde\u5bf9';
    case 'airplane':
      return samePatternBeat ? '\u538b\u4f60\uff0c\u98de\u673a' : '\u98de\u673a';
    case 'airplane_with_single':
      return samePatternBeat ? '\u538b\u4f60\uff0c\u98de\u673a\u5e26\u5355' : '\u98de\u673a\u5e26\u5355';
    case 'airplane_with_pair':
      return samePatternBeat ? '\u538b\u4f60\uff0c\u98de\u673a\u5e26\u5bf9' : '\u98de\u673a\u5e26\u5bf9';
    case 'bomb':
      return '\u70b8\u5f39';
    case 'four_with_two_singles':
      return samePatternBeat ? '\u538b\u4f60\uff0c\u56db\u5e26\u4e8c' : '\u56db\u5e26\u4e8c';
    case 'four_with_two_pairs':
      return samePatternBeat ? '\u538b\u4f60\uff0c\u56db\u5e26\u4e24\u5bf9' : '\u56db\u5e26\u4e24\u5bf9';
    case 'rocket':
      return '\u738b\u70b8';
    default:
      return _display(action).replaceAll(' ', '');
  }
}

TableAction? _previousPlayableAction(List<TableAction> actions, int index) {
  var trailingPasses = 0;
  for (var cursor = index - 1; cursor >= 0; cursor--) {
    final action = actions[cursor];
    if (_isSystemAction(action)) {
      continue;
    }
    if (action.type == ActionType.pass) {
      trailingPasses += 1;
      continue;
    }
    if (action.type == ActionType.play && action.cards.isNotEmpty) {
      if (trailingPasses >= 2) {
        return null;
      }
      return action;
    }
  }
  return null;
}

bool _isSystemAction(TableAction action) {
  return action.patternLabel == 'managed_on' ||
      action.patternLabel == 'managed_off' ||
      action.patternLabel == 'bid_pass' ||
      action.patternLabel.startsWith('bid_');
}

String _scoreText(String score) => switch (score) {
      '0' => '\u96f6',
      '1' => '\u4e00',
      '2' => '\u4e8c',
      '3' => '\u4e09',
      _ => score,
    };

String _friendlyGameError(String rawError) => switch (rawError) {
      'cannot_beat_table' => '\u8fd9\u624b\u724c\u538b\u4e0d\u8fc7\u53bb',
      'invalid_pattern' => '\u8fd9\u624b\u724c\u724c\u578b\u4e0d\u5bf9',
      'invalid_cards' => '\u9009\u4e2d\u7684\u724c\u4e0d\u6b63\u786e',
      'not_your_turn' => '\u8fd8\u6ca1\u8f6e\u5230\u4f60',
      'lead_player_cannot_pass' => '\u4f60\u662f\u5148\u624b\uff0c\u4e0d\u80fd\u4e0d\u51fa',
      'room_not_playing' => '\u8fd9\u5c40\u5df2\u7ecf\u7ed3\u675f\u4e86',
      'hint_not_available' => '\u73b0\u5728\u8fd8\u4e0d\u80fd\u63d0\u793a',
      'not_your_bidding_turn' => '\u8fd8\u6ca1\u8f6e\u5230\u4f60\u53eb\u5206',
      'bid_lower_than_current' => '\u53eb\u5206\u4e0d\u80fd\u4f4e\u4e8e\u5f53\u524d\u5206\u6570',
      'invalid_bid_score' => '\u53eb\u5206\u4e0d\u5408\u89c4\u5219',
      'round_finished' => '\u672c\u5c40\u5df2\u7ed3\u675f',
      'round_finishing' => '\u8fd9\u624b\u724c\u5df2\u9501\u5b9a\uff0c\u9a6c\u4e0a\u7ed3\u7b97',
      _ => '\u8fd9\u6b21\u64cd\u4f5c\u6682\u65f6\u4e0d\u53ef\u7528',
    };

String _friendlyGameErrorVoice(String rawError) => switch (rawError) {
      'cannot_beat_table' => '\u538b\u4e0d\u8d77',
      'invalid_pattern' => '\u724c\u578b\u4e0d\u5bf9',
      'invalid_cards' => '\u8bf7\u91cd\u65b0\u9009\u724c',
      'not_your_turn' => '\u8fd8\u6ca1\u8f6e\u5230\u4f60',
      'lead_player_cannot_pass' => '\u5148\u624b\u4e0d\u80fd\u4e0d\u51fa',
      'room_not_playing' => '\u672c\u5c40\u5df2\u7ed3\u675f',
      'hint_not_available' => '\u73b0\u5728\u8fd8\u4e0d\u80fd\u63d0\u793a',
      'not_your_bidding_turn' => '\u8fd8\u6ca1\u8f6e\u5230\u4f60\u53eb\u5206',
      'bid_lower_than_current' => '\u53eb\u5206\u4e0d\u80fd\u66f4\u4f4e',
      'invalid_bid_score' => '\u53eb\u5206\u4e0d\u5408\u89c4\u5219',
      'round_finished' => '\u672c\u5c40\u5df2\u7ed3\u675f',
      'round_finishing' => '\u9a6c\u4e0a\u7ed3\u7b97',
      _ => '\u8fd9\u6b21\u64cd\u4f5c\u4e0d\u53ef\u4ee5',
    };

class _PendingPresentation {
  const _PendingPresentation({
    required this.roomId,
    required this.actions,
    required this.index,
    required this.actionId,
  });

  final String roomId;
  final List<TableAction> actions;
  final int index;
  final String actionId;
}

enum _PlayedTrayPosition { left, right, self }

class _PlayedTrayLayout {
  const _PlayedTrayLayout({
    required this.position,
    required this.player,
    required this.active,
    required this.towardCenter,
    required this.centered,
    required this.width,
    required this.displayAction,
    required this.isLeadingPlay,
  });

  final _PlayedTrayPosition position;
  final RoomPlayer player;
  final bool active;
  final bool towardCenter;
  final bool centered;
  final double width;
  final TrickDisplayAction? displayAction;
  final bool isLeadingPlay;
}

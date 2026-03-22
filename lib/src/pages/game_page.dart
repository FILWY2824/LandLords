import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/app_models.dart';
import '../models/game_models.dart';
import '../services/voice_cue_service.dart';
import '../state/app_controller.dart';
import '../utils/app_log.dart';
import '../utils/browser_background.dart';
import '../utils/current_trick_view.dart';
import '../widgets/friend_center_dialog.dart';
import '../widgets/fixed_stage.dart';
import '../widgets/seat_assignment_dialog.dart';

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
  final _browserBackground = createBrowserBackgroundBridge();
  final LayerLink _turnChooserAnchorLink = LayerLink();
  Timer? _countdownTimer;
  Timer? _bannerTimer;
  Timer? _errorTimer;
  StreamSubscription<bool>? _browserBackgroundSubscription;
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
  final Queue<_PendingPresentation> _presentationQueue =
      Queue<_PendingPresentation>();
  bool _dragSelectionActive = false;
  bool _dragSelectionValue = true;
  int? _lastDragIndex;
  bool _processingPresentationQueue = false;
  bool _browserBackgroundMode = false;
  String? _presentationRoomId;
  String? _activePresentationActionId;
  String? _bgmRoomId;
  bool _sortDescending = false;
  bool _lastManagedSelfState = false;

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
    if (_browserBackground.supported) {
      _browserBackgroundMode = _browserBackground.isBackgrounded;
      _browserBackgroundSubscription = _browserBackground.changes.listen(
        _handleBrowserBackgroundChanged,
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _countdownTimer?.cancel();
    _bannerTimer?.cancel();
    _errorTimer?.cancel();
    _browserBackgroundSubscription?.cancel();
    unawaited(_voice.dispose(releaseBackgroundMusic: true));
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    appLog(
      AppLogLevel.info,
      'game_page',
      'lifecycle state=$state (presentation queue preserved)',
    );
  }

  @override
  void didChangeViewFocus(ui.ViewFocusEvent event) {
    appLog(
      AppLogLevel.info,
      'game_page',
      'view focus=${event.state} (presentation queue preserved)',
    );
  }

  void _handleBrowserBackgroundChanged(bool backgrounded) {
    if (_browserBackgroundMode == backgrounded) {
      return;
    }
    _browserBackgroundMode = backgrounded;
    appLog(
      AppLogLevel.info,
      'game_page',
      'browser background mode=$backgrounded',
    );
    if (backgrounded) {
      _flushPresentationQueueForBrowserBackground();
      return;
    }
    unawaited(widget.controller.refreshCurrentRoom());
    _showBanner('\u5df2\u540c\u6b65\u5230\u6700\u65b0\u724c\u5c40', milliseconds: 1200);
  }

  void _flushPresentationQueueForBrowserBackground() {
    final roomId = widget.controller.roomSnapshot?.roomId;
    if (roomId == null) {
      return;
    }
    unawaited(_voice.interruptSpeech());
    for (final pending in _presentationQueue) {
      if (_presentationAckedIds.add(pending.actionId)) {
        unawaited(
          widget.controller.acknowledgePresentation(roomId, pending.actionId),
        );
      }
    }
    _presentationQueue.clear();
    final activeId = _activePresentationActionId;
    if (activeId != null && _presentationAckedIds.add(activeId)) {
      unawaited(widget.controller.acknowledgePresentation(roomId, activeId));
    }
    _activePresentationActionId = null;
    if (mounted) {
      setState(() => _bannerText = null);
    }
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
    _syncBackgroundMusic(snapshot);
    if (_presentationRoomId != snapshot.roomId) {
      _presentationRoomId = snapshot.roomId;
      _presentationQueue.clear();
      _seenActionIds.clear();
      _seenActionOrder.clear();
      _presentationAckedIds.clear();
      _activePresentationActionId = null;
      _voice.clearPending(clearRecentActionIds: true);
      _lastManagedSelfState = false;
      appLog(
        AppLogLevel.info,
        'game_page',
        'switch room room=${snapshot.roomId}',
      );
    }

    final selfUserId = widget.controller.profile?.userId;
    if (selfUserId != null && selfUserId.isNotEmpty) {
      final managedNow = _isManaged(snapshot, selfUserId);
      if (managedNow &&
          !_lastManagedSelfState &&
          (_selectedIds.isNotEmpty || _suggestedIds.isNotEmpty)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _selectedIds.clear();
              _suggestedIds.clear();
            });
          }
        });
      }
      _lastManagedSelfState = managedNow;
    } else {
      _lastManagedSelfState = false;
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
      if (_browserBackgroundMode) {
        appLog(
          AppLogLevel.info,
          'game_page',
          'browser background fast-sync room=${snapshot.roomId} actions=${unseenIndexes.length}',
        );
        for (final index in unseenIndexes) {
          final action = snapshot.recentActions[index];
          if (_presentationAckedIds.add(action.actionId)) {
            unawaited(
              widget.controller.acknowledgePresentation(
                snapshot.roomId,
                action.actionId,
              ),
            );
          }
        }
        return;
      }
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
          'label=${action.patternLabel} index=$index queue_size=${_presentationQueue.length}',
        );
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

  void _syncBackgroundMusic(RoomSnapshot snapshot) {
    if (!_musicEnabled || snapshot.phase == RoomPhase.finished) {
      if (_bgmRoomId != null) {
        _bgmRoomId = null;
        unawaited(_voice.stopBackgroundMusic());
      }
      return;
    }
    if (_bgmRoomId != snapshot.roomId) {
      _bgmRoomId = snapshot.roomId;
      unawaited(_voice.startBackgroundMusic());
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
    if (_browserBackgroundMode) {
      appLog(
        AppLogLevel.debug,
        'game_page',
        'ack immediately for browser background room=$roomId action=${action.actionId}',
      );
      if (_presentationAckedIds.add(action.actionId)) {
        await widget.controller.acknowledgePresentation(roomId, action.actionId);
      }
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
    await _voice.enqueueAction(
      action.actionId,
      _voiceText(actions, index),
    );
    await Future<void>.delayed(const Duration(milliseconds: 60));
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
    appLog(
      AppLogLevel.debug,
      'game_page',
      'drain presentation queue start room=$_presentationRoomId size=${_presentationQueue.length}',
    );
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
      appLog(
        AppLogLevel.debug,
        'game_page',
        'drain presentation queue end room=$_presentationRoomId size=${_presentationQueue.length}',
      );
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
      widget.controller.showDialogNotice(
        title: '操作提示',
        message: notice,
      );
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

  void _clearSelectedCards() {
    if (_selectedIds.isEmpty && _suggestedIds.isEmpty) {
      return;
    }
    setState(() {
      _selectedIds.clear();
      _suggestedIds.clear();
    });
  }

  void _toggleSortOrder() {
    setState(() => _sortDescending = !_sortDescending);
  }

  Future<void> _handleBackToLobby() async {
    await widget.controller.backToLobby();
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

    if (snapshot.phase == RoomPhase.preparing) {
      _sync(snapshot);
      _syncGameError();
      return _buildPreparingRoomView(snapshot, profile);
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
    final showTurnChooser = snapshot.phase != RoomPhase.finished &&
        myTurn &&
        !waitingMyBid &&
        !managed;
    final showActionChooser = showTurnChooser || waitingMyBid;
    final selfCards = [...snapshot.selfCards]
      ..sort((left, right) {
        final value = _compareSelfCards(left, right);
        return _sortDescending ? value : -value;
      });

    _sync(snapshot);
    _syncGameError();

    return Scaffold(
      body: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) {
          if (_musicEnabled && _bgmRoomId != null) {
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
                const designWidth = 1440.0;
                const designHeight = 860.0;
                return Center(
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: SizedBox(
                      width: designWidth,
                      height: designHeight,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Column(
                            children: [
                              _buildTopHudResponsive(snapshot),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      const seatWidth = 236.0;
                                      const playedWidth = 126.0;
                                      const sideTrayWidth = 332.0;
                                      const selfTrayWidth = 468.0;
                                      const sideSeatInset = 22.0;
                                      const sideSeatTop = 18.0;
                                      const sideTrayGap = 18.0;
                                      const sideTrayTop = 124.0;
                                      const selfTrayBottom = 18.0;
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
                                            left: sideSeatInset,
                                            top: sideSeatTop,
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
                                            right: sideSeatInset,
                                            top: sideSeatTop,
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
                                              top: 104,
                                              child: Center(
                                                child: _bannerPill(_bannerText!),
                                              ),
                                            ),
                                          if (snapshot.phase == RoomPhase.waiting)
                                            Positioned(
                                              left: 0,
                                              right: 0,
                                              top: 162,
                                              child: Center(
                                                child: _hintPill(
                                                  myTurn
                                                      ? '\u8f6e\u5230\u4f60\u53eb\u5206'
                                                      : '\u7b49\u5f85 ${_name(snapshot, snapshot.currentTurnPlayerId)} \u53eb\u5206',
                                                ),
                                              ),
                                            ),
                                          for (final layout in trayLayouts)
                                            Positioned(
                                              left: switch (layout.position) {
                                                _PlayedTrayPosition.left =>
                                                  sideSeatInset + seatWidth + sideTrayGap,
                                                _PlayedTrayPosition.self => 0,
                                                _PlayedTrayPosition.right => null,
                                              },
                                              right: switch (layout.position) {
                                                _PlayedTrayPosition.right =>
                                                  sideSeatInset + seatWidth + sideTrayGap,
                                                _PlayedTrayPosition.self => 0,
                                                _PlayedTrayPosition.left => null,
                                              },
                                              top: layout.position == _PlayedTrayPosition.self
                                                  ? null
                                                  : sideTrayTop,
                                              bottom: layout.position == _PlayedTrayPosition.self
                                                  ? selfTrayBottom
                                                  : null,
                                              child: layout.position ==
                                                      _PlayedTrayPosition.self
                                                  ? Center(
                                                      child: SizedBox(
                                                        width: layout.width,
                                                        child: _buildPlayedTray(
                                                          player: layout.player,
                                                          action: layout
                                                              .displayAction!
                                                              .action,
                                                          emphasis: layout
                                                              .displayAction!
                                                              .emphasis,
                                                          active: layout.active,
                                                          towardCenter:
                                                              layout.towardCenter,
                                                          centered:
                                                              layout.centered,
                                                          cardWidth: playedWidth,
                                                          maxWidth: layout.width,
                                                          isLeadingPlay:
                                                              layout.isLeadingPlay,
                                                        ),
                                                      ),
                                                    )
                                                  : SizedBox(
                                                      width: layout.width,
                                                      child: _buildPlayedTray(
                                                        player: layout.player,
                                                        action: layout
                                                            .displayAction!
                                                            .action,
                                                        emphasis: layout
                                                            .displayAction!
                                                            .emphasis,
                                                        active: layout.active,
                                                        towardCenter:
                                                            layout.towardCenter,
                                                        centered:
                                                            layout.centered,
                                                        cardWidth: playedWidth,
                                                        maxWidth: layout.width,
                                                        isLeadingPlay:
                                                            layout.isLeadingPlay,
                                                      ),
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
                              _buildResponsiveBottomDockFloating(
                                snapshot,
                                me,
                                selfCards: selfCards,
                                waitingMyBid: waitingMyBid,
                                myTurn: myTurn,
                                managed: managed,
                                showTurnChooser: showTurnChooser,
                              ),
                            ],
                          ),
                          if (showActionChooser)
                            Positioned(
                              left: 0,
                              top: 0,
                              child: CompositedTransformFollower(
                                link: _turnChooserAnchorLink,
                                showWhenUnlinked: false,
                                targetAnchor: Alignment.topCenter,
                                followerAnchor: Alignment.bottomCenter,
                                offset: const Offset(-120, -14),
                                child: Material(
                                  color: Colors.transparent,
                                  child: waitingMyBid
                                      ? _buildBidChooser(
                                          maxWidth: 430,
                                          showTimer: true,
                                        )
                                      : _buildTurnActionChooser(
                                          maxWidth: 360,
                                          showTimer: true,
                                        ),
                                ),
                              ),
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

  Future<void> _showInvitePlayerDialog(RoomSnapshot snapshot) async {
    final emptySeat = snapshot.players.cast<RoomPlayer?>().firstWhere(
      (player) => player != null && !player.occupied,
      orElse: () => null,
    );
    if (emptySeat == null) {
      _showBanner('\u5f53\u524d\u6ca1\u6709\u53ef\u4ee5\u9080\u8bf7\u7684\u7a7a\u4f4d', milliseconds: 1400);
      return;
    }
    await _showSeatAssignmentForSeat(snapshot, emptySeat.seatIndex);
    return;
    // ignore: dead_code
    final users = const <OnlineUser>[];
    if (!mounted) {
      return;
    }
    if (users.isEmpty) {
      _showBanner('当前没有可邀请的在线玩家', milliseconds: 1400);
      return;
    }
    final selected = await showDialog<OnlineUser>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: StagePanel(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            radius: 26,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        '邀请在线玩家',
                        style: TextStyle(
                          color: Color(0xFF173A59),
                          fontWeight: FontWeight.w900,
                          fontSize: 24,
                        ),
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  '选择一位在线玩家发送入桌邀请，对方确认后即可加入当前房间。',
                  style: TextStyle(
                    color: Color(0xFF587790),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 14),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 320),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        for (final user in users) ...[
                          InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () => Navigator.of(context).pop(user),
                            child: Ink(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                color: Colors.white.withValues(alpha: 0.92),
                                border: Border.all(color: const Color(0xFFD7EBFF)),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: const Color(0xFF2B7FFF),
                                    child: Text(
                                      (user.username.isEmpty
                                              ? 'P'
                                              : user.username.substring(0, 1))
                                          .toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      user.username,
                                      style: const TextStyle(
                                        color: Color(0xFF173A59),
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 16,
                                    color: Color(0xFF2B7FFF),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (user != users.last) const SizedBox(height: 8),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (!mounted || selected == null) {
      return;
    }
    await widget.controller.invitePlayerToRoom(
      account: selected.account,
      displayName: selected.username,
      seatIndex: snapshot.players.indexWhere((player) => !player.occupied),
    );
    if (!mounted || widget.controller.errorText != null) {
      return;
    }
    _showBanner('已向 ${selected.username} 发送邀请', milliseconds: 1400);
  }

  Future<void> _showSeatAssignmentForSeat(
    RoomSnapshot snapshot,
    int seatIndex,
  ) async {
    const designWidth = 1440.0;
    const designHeight = 860.0;
    final media = MediaQuery.sizeOf(context);
    final stageScale = math.min(
      media.width / designWidth,
      media.height / designHeight,
    );
    final result = await showSeatAssignmentDialog(
      context,
      controller: widget.controller,
      snapshot: snapshot,
      seatIndex: seatIndex,
      stageScale: stageScale,
      stageWidth: designWidth,
      stageHeight: designHeight,
    );
    if (!mounted || result == null) {
      return;
    }
    if (!result.message.contains('DouZero')) {
      return;
    }
    widget.controller.showDialogNotice(
      title: result.message.contains('邀请') ? '邀请已发送' : '操作已完成',
      message: result.message,
    );
  }

  Future<void> _showFriendCenter() async {
    const designWidth = 1440.0;
    const designHeight = 860.0;
    final media = MediaQuery.sizeOf(context);
    final stageScale = math.min(
      media.width / designWidth,
      media.height / designHeight,
    );
    await showFriendCenterDialog(
      context,
      controller: widget.controller,
      stageScale: stageScale,
      stageWidth: designWidth,
      stageHeight: designHeight,
    );
  }

  // ignore: unused_element
  Widget _buildPreparingRoom(RoomSnapshot snapshot, UserProfile profile) {
    final me = snapshot.players.firstWhere(
      (player) => player.playerId == profile.userId,
    );
    final isOwner = snapshot.ownerPlayerId == profile.userId;
    final occupiedCount =
        snapshot.players.where((player) => player.occupied).length;
    final readyCount = snapshot.players
        .where((player) => player.occupied && player.ready)
        .length;
    final hasEmptySeat = snapshot.players.any((player) => !player.occupied);

    return Scaffold(
      body: FixedStageBackdrop(
        child: FixedStage(
          width: 1360,
          height: 800,
          padding: const EdgeInsets.all(14),
          child: Stack(
            children: [
              Column(
                children: [
                  StagePanel(
                    padding: const EdgeInsets.fromLTRB(22, 18, 22, 16),
                    radius: 28,
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '房间准备',
                                style: TextStyle(
                                  color: Color(0xFF173A59),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 28,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _preparingStatusText(snapshot.statusText),
                                style: const TextStyle(
                                  color: Color(0xFF587790),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            color: const Color(0xFFEAF5FF),
                            border: Border.all(color: const Color(0xFFD1E9FF)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '房间号',
                                style: TextStyle(
                                  color: Color(0xFF587790),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                snapshot.roomCode.isEmpty
                                    ? snapshot.roomId
                                    : snapshot.roomCode,
                                style: const TextStyle(
                                  color: Color(0xFF173A59),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 22,
                                  letterSpacing: 1.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final code = snapshot.roomCode.isEmpty
                                ? snapshot.roomId
                                : snapshot.roomCode;
                            await Clipboard.setData(ClipboardData(text: code));
                            if (!mounted) {
                              return;
                            }
                            _showBanner('房间号已复制', milliseconds: 1100);
                          },
                          icon: const Icon(Icons.copy_rounded, size: 18),
                          label: const Text('复制'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          flex: 11,
                          child: StagePanel(
                            padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
                            radius: 30,
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    _buildPreparingSummaryChip(
                                      label: '入座人数',
                                      value: '$occupiedCount / 3',
                                    ),
                                    const SizedBox(width: 10),
                                    _buildPreparingSummaryChip(
                                      label: '准备人数',
                                      value: '$readyCount / 3',
                                    ),
                                    const Spacer(),
                                    const Text(
                                      '所有玩家准备后自动开局',
                                      style: TextStyle(
                                        color: Color(0xFF587790),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Expanded(
                                  child: Row(
                                    children: [
                                      for (var index = 0;
                                          index < snapshot.players.length;
                                          index++) ...[
                                        Expanded(
                                          child: _buildPreparingSeatCard(
                                            snapshot: snapshot,
                                            player: snapshot.players[index],
                                            seatLabel: switch (index) {
                                              0 => '一号位',
                                              1 => '二号位',
                                              _ => '三号位',
                                            },
                                            isOwner: isOwner,
                                            isSelf: snapshot.players[index].playerId ==
                                                profile.userId,
                                          ),
                                        ),
                                        if (index != snapshot.players.length - 1)
                                          const SizedBox(width: 14),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: 282,
                          child: StagePanel(
                            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                            radius: 28,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '本桌信息',
                                  style: TextStyle(
                                    color: Color(0xFF173A59),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 22,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  isOwner
                                      ? '你是房主，可以邀请在线玩家，也可以直接补入 DouZero。'
                                      : '等待房主安排座位，准备完成后即可进入正式对局。',
                                  style: const TextStyle(
                                    color: Color(0xFF587790),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    height: 1.45,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(24),
                                    color: const Color(0xFFF3F9FF),
                                    border: Border.all(color: const Color(0xFFD7EBFF)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isOwner ? '当前身份' : '当前状态',
                                        style: const TextStyle(
                                          color: Color(0xFF587790),
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        isOwner ? '房主' : (me.ready ? '已准备' : '等待准备'),
                                        style: const TextStyle(
                                          color: Color(0xFF173A59),
                                          fontWeight: FontWeight.w900,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Spacer(),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton(
                                    onPressed: widget.controller.isBusy
                                        ? null
                                        : () => widget.controller.setRoomReady(!me.ready),
                                    child: Text(me.ready ? '取消准备' : '准备'),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                if (isOwner && hasEmptySeat)
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: widget.controller.isBusy
                                          ? null
                                          : () => _showInvitePlayerDialog(snapshot),
                                      icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                                      label: const Text('邀请玩家'),
                                    ),
                                  ),
                                if (isOwner && hasEmptySeat) const SizedBox(height: 10),
                                if (isOwner && hasEmptySeat)
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: widget.controller.isBusy
                                          ? null
                                          : () => widget.controller.addBotToRoom(
                                                seatIndex: snapshot.players
                                                    .firstWhere(
                                                      (player) => !player.occupied,
                                                    )
                                                    .seatIndex,
                                              ),
                                      icon: const Icon(Icons.smart_toy_rounded, size: 18),
                                      label: const Text('加入 DouZero'),
                                    ),
                                  ),
                                if (isOwner && hasEmptySeat) const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.tonal(
                                    onPressed: widget.controller.isBusy
                                        ? null
                                        : widget.controller.backToLobby,
                                    child: const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.arrow_back_rounded, size: 18),
                                        SizedBox(width: 8),
                                        Text('返回大厅'),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (widget.controller.isBusy)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ),
                ),
              if (_bannerText != null)
                Positioned(
                  top: 18,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: Center(
                      child: _bannerPill(_bannerText!),
                    ),
                  ),
                ),
              if (_errorNotice != null)
                Positioned(
                  top: 92,
                  left: 0,
                  right: 0,
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
  }

  Widget _buildPreparingSeatCard({
    required RoomSnapshot snapshot,
    required RoomPlayer player,
    required String seatLabel,
    required bool isOwner,
    required bool isSelf,
  }) {
    final isEmpty = !player.occupied;
    final canRemoveOccupiedPlayer = isOwner && player.occupied && !isSelf;
    final accent = isSelf ? const Color(0xFF64B4FF) : const Color(0xFFD7EBFF);
    final title = isEmpty ? '空位' : player.displayName;
    final detail = isEmpty
        ? (isOwner
            ? '你可以邀请在线玩家，或者直接补入 DouZero。'
            : '等待房主安排玩家或 DouZero 入座。')
        : player.isBot
            ? 'DouZero 已接入这个座位，房主可以随时将其移除。'
            : isSelf
                ? '你可以先准备，等待其他玩家全部就位。'
                : '等待该玩家确认准备后即可开局。';
    final pillText = isEmpty
        ? '空位'
        : player.ready
            ? '已准备'
            : '待准备';
    final pillColor = isEmpty
        ? const Color(0xFF2B7FFF)
        : player.ready
            ? const Color(0xFF237A4B)
            : const Color(0xFFB56A18);
    final pillBackground = isEmpty
        ? const Color(0xFFEAF5FF)
        : player.ready
            ? const Color(0xFFE7F7EE)
            : const Color(0xFFFFF4E8);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: Colors.white.withValues(alpha: 0.92),
        border: Border.all(color: accent, width: isSelf ? 1.8 : 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14397BA8),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                seatLabel,
                style: const TextStyle(
                  color: Color(0xFF587790),
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              if (canRemoveOccupiedPlayer)
                IconButton(
                  tooltip: '移除机器人',
                  visualDensity: VisualDensity.compact,
                  onPressed: widget.controller.isBusy
                      ? null
                      : () => widget.controller.removePlayerFromRoom(player.playerId),
                  icon: const Icon(
                    Icons.person_remove_alt_1_rounded,
                    color: Color(0xFF2B7FFF),
                  ),
                ),
            ],
          ),
          const Spacer(),
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: isEmpty
                    ? [const Color(0xFFEAF5FF), const Color(0xFFD8EEFF)]
                    : [const Color(0xFF80D0FF), const Color(0xFF2B7FFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            alignment: Alignment.center,
            child: isEmpty
                ? const Icon(
                    Icons.add_rounded,
                    size: 42,
                    color: Color(0xFF2B7FFF),
                  )
                : Text(
                    title.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 30,
                    ),
                  ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF173A59),
              fontWeight: FontWeight.w900,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: pillBackground,
            ),
            child: Text(
              pillText,
              style: TextStyle(
                color: pillColor,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            detail,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF587790),
              fontWeight: FontWeight.w700,
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const Spacer(),
          if (isEmpty && isOwner)
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: widget.controller.isBusy
                        ? null
                        : () => _showInvitePlayerDialog(snapshot),
                    icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                    label: const Text('邀请玩家'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    onPressed: widget.controller.isBusy
                        ? null
                        : () => widget.controller.addBotToRoom(
                              seatIndex: player.seatIndex,
                            ),
                    icon: const Icon(Icons.smart_toy_rounded, size: 18),
                    label: const Text('加入 DouZero'),
                  ),
                ),
              ],
            )
          else
            const SizedBox(height: 82),
        ],
      ),
    );
  }

  Widget _buildPreparingRoomView(RoomSnapshot snapshot, UserProfile profile) {
    final me = snapshot.players.firstWhere(
      (player) => player.playerId == profile.userId,
    );
    final isOwner = snapshot.ownerPlayerId == profile.userId;
    final occupiedCount =
        snapshot.players.where((player) => player.occupied).length;
    final readyCount = snapshot.players
        .where((player) => player.occupied && player.ready)
        .length;
    final roomCode =
        snapshot.roomCode.isEmpty ? snapshot.roomId : snapshot.roomCode;

    return Scaffold(
      body: FixedStageBackdrop(
        child: FixedStage(
          width: 1240,
          height: 740,
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              StagePanel(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
                radius: 28,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '真人房间',
                            style: TextStyle(
                              color: Color(0xFF173A59),
                              fontWeight: FontWeight.w900,
                              fontSize: 30,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _preparingStatusTextView(snapshot.statusText),
                            style: const TextStyle(
                              color: Color(0xFF587790),
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        color: const Color(0xFFEAF5FF),
                        border: Border.all(color: const Color(0xFFD1E9FF)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '房间号',
                            style: TextStyle(
                              color: Color(0xFF587790),
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            roomCode,
                            style: const TextStyle(
                              color: Color(0xFF173A59),
                              fontWeight: FontWeight.w900,
                              fontSize: 28,
                              letterSpacing: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: roomCode));
                        if (!mounted) {
                          return;
                        }
                        _showBanner('房间号已复制', milliseconds: 1200);
                      },
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: const Text('复制房号'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(164, 66),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      flex: 10,
                      child: StagePanel(
                        padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
                        radius: 30,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                _buildPreparingSummaryChipView(
                                  label: '已入座',
                                  value: '$occupiedCount / 3',
                                ),
                                const SizedBox(width: 10),
                                _buildPreparingSummaryChipView(
                                  label: '已准备',
                                  value: '$readyCount / 3',
                                ),
                                const Spacer(),
                                const Text(
                                  '所有玩家准备后自动开局',
                                  style: TextStyle(
                                    color: Color(0xFF587790),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Expanded(
                              child: Row(
                                children: [
                                  for (var index = 0;
                                      index < snapshot.players.length;
                                      index++) ...[
                                    Expanded(
                                      child: _buildPreparingSeatCardView(
                                        snapshot: snapshot,
                                        player: snapshot.players[index],
                                        isOwner: isOwner,
                                        isSelf: snapshot.players[index].playerId ==
                                            profile.userId,
                                      ),
                                    ),
                                    if (index != snapshot.players.length - 1)
                                      const SizedBox(width: 14),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 304,
                      child: StagePanel(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                        radius: 28,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '房间操作',
                              style: TextStyle(
                                color: Color(0xFF173A59),
                                fontWeight: FontWeight.w900,
                                fontSize: 24,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              isOwner
                                  ? '点击空位即可安排好友或补入 DouZero，准备后等待其余玩家就绪。'
                                  : '等待房主安排座位。入座后点击准备，所有人准备后自动开始。',
                              style: const TextStyle(
                                color: Color(0xFF587790),
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: const Color(0xFFF4FAFF),
                                border: Border.all(color: const Color(0xFFD7EBFF)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '当前玩家：${me.displayName}',
                                    style: const TextStyle(
                                      color: Color(0xFF173A59),
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    me.ready ? '状态：已准备' : '状态：未准备',
                                    style: TextStyle(
                                      color: me.ready
                                          ? const Color(0xFF237A4B)
                                          : const Color(0xFFB56A18),
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: widget.controller.isBusy
                                    ? null
                                    : () => widget.controller.setRoomReady(
                                          !me.ready,
                                        ),
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(58),
                                ),
                                child: Text(me.ready ? '取消准备' : '准备'),
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: widget.controller.isBusy
                                    ? null
                                    : _showFriendCenter,
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(56),
                                ),
                                icon: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    const Icon(Icons.groups_rounded, size: 18),
                                    if (widget.controller.pendingFriendRequestCount > 0)
                                      const Positioned(
                                        right: -2,
                                        top: -2,
                                        child: CircleAvatar(
                                          radius: 4,
                                          backgroundColor: Color(0xFFE5534B),
                                        ),
                                      ),
                                  ],
                                ),
                                label: const Text('\u597d\u53cb\u4e2d\u5fc3'),
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: widget.controller.isBusy
                                    ? null
                                    : () => unawaited(_handleBackToLobby()),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(56),
                                ),
                                child: const Text('退出房间'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreparingSeatCardView({
    required RoomSnapshot snapshot,
    required RoomPlayer player,
    required bool isOwner,
    required bool isSelf,
  }) {
    final isEmpty = !player.occupied;
    final canRemoveOccupiedPlayer = isOwner && player.occupied && !isSelf;
    final accent = isSelf ? const Color(0xFF64B4FF) : const Color(0xFFD7EBFF);
    final title = isEmpty ? '空位' : player.displayName;
    final detail = isEmpty
        ? (isOwner ? '点击安排好友入座，或补入 DouZero。' : '等待房主安排座位。')
        : player.isBot
            ? 'DouZero 已接入该位置，可由房主移除。'
            : isSelf
                ? '你已经入座，准备后等待其余玩家。'
                : '等待这位玩家点击准备。';
    final pillText = isEmpty ? '空位' : (player.ready ? '已准备' : '待准备');
    final pillColor = isEmpty
        ? const Color(0xFF2B7FFF)
        : player.ready
            ? const Color(0xFF237A4B)
            : const Color(0xFFB56A18);
    final pillBackground = isEmpty
        ? const Color(0xFFEAF5FF)
        : player.ready
            ? const Color(0xFFE7F7EE)
            : const Color(0xFFFFF4E8);

    /*
    final statusText = waitingMyBid
        ? '请叫分'
        : managed
            ? '托管中'
            : myTurn
                ? '到你出牌'
                : '等待中';

    */
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: Colors.white.withValues(alpha: 0.92),
        border: Border.all(color: accent, width: isSelf ? 1.8 : 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14397BA8),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                _seatLabelForIndex(player.seatIndex),
                style: const TextStyle(
                  color: Color(0xFF587790),
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              if (canRemoveOccupiedPlayer)
                IconButton(
                  tooltip: '移除玩家',
                  onPressed: widget.controller.isBusy
                      ? null
                      : () => widget.controller.removePlayerFromRoom(
                            player.playerId,
                          ),
                  icon: const Icon(
                    Icons.person_remove_alt_1_rounded,
                    color: Color(0xFF2B7FFF),
                  ),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const Spacer(),
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: isEmpty
                    ? [const Color(0xFFEAF5FF), const Color(0xFFD8EEFF)]
                    : [const Color(0xFF80D0FF), const Color(0xFF2B7FFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            alignment: Alignment.center,
            child: isEmpty
                ? const Icon(
                    Icons.add_rounded,
                    size: 44,
                    color: Color(0xFF2B7FFF),
                  )
                : Text(
                    title.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 30,
                    ),
                  ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF173A59),
              fontWeight: FontWeight.w900,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: pillBackground,
            ),
            child: Text(
              pillText,
              style: TextStyle(
                color: pillColor,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            detail,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF587790),
              fontWeight: FontWeight.w700,
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const Spacer(),
          if (isEmpty && isOwner)
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: widget.controller.isBusy
                    ? null
                    : () => _showSeatAssignmentForSeat(
                          snapshot,
                          player.seatIndex,
                        ),
                icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                label: const Text('安排座位'),
              ),
            )
          else
            const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildPreparingSummaryChipView({
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: const Color(0xFFEAF5FF),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF587790),
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
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

  /*
  String _preparingStatusTextView(String status) {
    return switch (status) {
      'waiting_for_players' => '等待玩家加入房间，未坐满时可以继续补入席位。',
      'waiting_for_ready' => '玩家已到齐，等待所有玩家点击准备。',
      'ready_to_start' => '所有玩家均已准备，正在进入牌桌。',
      _ => '房间状态已更新，请继续完成本桌准备。',
    };
  }

  String _seatLabelForIndex(int seatIndex) => switch (seatIndex) {
        0 => '一号位',
        1 => '二号位',
        _ => '三号位',
      };

  */

  String _preparingStatusTextView(String status) {
    switch (status) {
      case 'waiting_for_players':
        return '\u7b49\u5f85\u73a9\u5bb6\u52a0\u5165\u623f\u95f4\uff0c\u672a\u5750\u6ee1\u65f6\u53ef\u4ee5\u7ee7\u7eed\u8865\u5165\u5e2d\u4f4d\u3002';
      case 'waiting_for_ready':
        return '\u73a9\u5bb6\u5df2\u5230\u9f50\uff0c\u7b49\u5f85\u6240\u6709\u73a9\u5bb6\u70b9\u51fb\u51c6\u5907\u3002';
      case 'ready_to_start':
        return '\u6240\u6709\u73a9\u5bb6\u5747\u5df2\u51c6\u5907\uff0c\u6b63\u5728\u8fdb\u5165\u724c\u684c\u3002';
      default:
        return '\u623f\u95f4\u72b6\u6001\u5df2\u66f4\u65b0\uff0c\u8bf7\u7ee7\u7eed\u5b8c\u6210\u672c\u5c40\u51c6\u5907\u3002';
    }
  }

  String _seatLabelForIndex(int seatIndex) {
    switch (seatIndex) {
      case 0:
        return '\u4e00\u53f7\u4f4d';
      case 1:
        return '\u4e8c\u53f7\u4f4d';
      default:
        return '\u4e09\u53f7\u4f4d';
    }
  }

  Widget _buildPreparingSummaryChip({
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: const Color(0xFFEAF5FF),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF587790),
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
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

  String _preparingStatusText(String status) {
    return switch (status) {
      'waiting_for_players' => '等待所有座位坐满，你可以邀请玩家或补入 DouZero。',
      'waiting_for_ready' => '玩家已到齐，请等待所有人点击准备。',
      'ready_to_start' => '所有人都已准备，牌桌即将开始。',
      _ => '房间状态已更新，请继续完成本桌准备。',
    };
  }

  // ignore: unused_element
  Widget _buildTopHudView(RoomSnapshot snapshot) {
    const tileHeight = 82.0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Row(
        children: [
          SizedBox(
            width: 112,
            height: tileHeight,
            child: OutlinedButton.icon(
              onPressed: () => unawaited(_handleBackToLobby()),
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text('大厅'),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 236,
            height: tileHeight,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              color: Colors.white.withValues(alpha: 0.92),
              border: Border.all(color: const Color(0xFFD7EBFF)),
            ),
            child: Row(
              children: [
                const Text(
                  '底牌',
                  style: TextStyle(
                    color: Color(0xFF245E90),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 10),
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
          const SizedBox(width: 8),
          Expanded(
            child: _showCounter
                ? _buildCounterStripView(snapshot.cardCounter)
                : _hudInfoTile('剩余牌统计已隐藏'),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 150,
            height: tileHeight,
            child: OutlinedButton.icon(
              onPressed: () => setState(() => _showCounter = !_showCounter),
              icon: Icon(
                _showCounter
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 18,
              ),
              label: Text(_showCounter ? '隐藏牌况' : '显示牌况'),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 150,
            height: tileHeight,
            child: OutlinedButton.icon(
              onPressed: () {
                setState(() => _musicEnabled = !_musicEnabled);
                if (_musicEnabled) {
                  unawaited(_voice.startBackgroundMusic());
                } else {
                  unawaited(_voice.stopBackgroundMusic());
                }
              },
              icon: Icon(
                _musicEnabled
                    ? Icons.music_off_rounded
                    : Icons.music_note_rounded,
                size: 18,
              ),
              label: Text(_musicEnabled ? '关闭音乐' : '开启音乐'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCounterStripView(List<CardCounterEntry> entries) {
    final sorted = [...entries]
      ..sort((a, b) => _weight(b.rank).compareTo(_weight(a.rank)));
    return Container(
      height: 82,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Colors.white.withValues(alpha: 0.92),
        border: Border.all(color: const Color(0xFFD7EBFF)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: const Color(0xFFF2F8FF),
              border: Border.all(color: const Color(0xFFD7EBFF)),
            ),
            child: const Text(
              '剩余牌统计',
              style: TextStyle(
                color: Color(0xFF245E90),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var index = 0; index < sorted.length; index++) ...[
                    _counterPill(
                      sorted[index],
                      compact: false,
                      singleLine: true,
                    ),
                    if (index != sorted.length - 1) const SizedBox(width: 4),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopHudResponsive(RoomSnapshot snapshot) {
    const tileHeight = 86.0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final landlordWidth = math.min(
            210.0,
            math.max(176.0, constraints.maxWidth * 0.135),
          );
          final actionWidth = math.min(
            104.0,
            math.max(88.0, constraints.maxWidth * 0.072),
          );
          return Row(
            children: [
              SizedBox(
                width: actionWidth,
                child: _buildTopControlTileResponsive(
                  icon: Icons.arrow_back_rounded,
                  label: '返回大厅',
                  active: false,
                  onTap: () => unawaited(_handleBackToLobby()),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: landlordWidth,
                child: _buildLandlordCardsTileResponsive(
                  snapshot,
                  height: tileHeight,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _showCounter
                    ? _buildCounterStripResponsive(
                        snapshot.cardCounter,
                        height: tileHeight,
                      )
                    : _buildHudInfoTileResponsive(
                        '剩余牌统计已隐藏',
                        height: tileHeight,
                      ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: actionWidth,
                child: _buildTopControlTileResponsive(
                  icon: _showCounter
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  label: _showCounter ? '隐藏牌况' : '显示牌况',
                  active: _showCounter,
                  onTap: () => setState(() => _showCounter = !_showCounter),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: actionWidth,
                child: _buildTopControlTileResponsive(
                  icon: _musicEnabled
                      ? Icons.music_off_rounded
                      : Icons.music_note_rounded,
                  label: _musicEnabled ? '关闭音乐' : '开启音乐',
                  active: _musicEnabled,
                  onTap: () {
                    setState(() => _musicEnabled = !_musicEnabled);
                    if (_musicEnabled) {
                      unawaited(_voice.startBackgroundMusic());
                    } else {
                      unawaited(_voice.stopBackgroundMusic());
                    }
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLandlordCardsTileResponsive(
    RoomSnapshot snapshot, {
    required double height,
  }) {
    return Container(
      height: height,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Colors.white.withValues(alpha: 0.92),
        border: Border.all(color: const Color(0xFFD7EBFF)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: const Color(0xFFF2F8FF),
              border: Border.all(color: const Color(0xFFD7EBFF)),
            ),
            child: const Text(
              '底牌',
              style: TextStyle(
                color: Color(0xFF245E90),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    for (var index = 0;
                        index < snapshot.landlordCards.length;
                        index++) ...[
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCounterStripResponsive(
    List<CardCounterEntry> entries, {
    required double height,
  }) {
    final sorted = [...entries]
      ..sort((a, b) => _weight(b.rank).compareTo(_weight(a.rank)));
    return Container(
      height: height,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Colors.white.withValues(alpha: 0.92),
        border: Border.all(color: const Color(0xFFD7EBFF)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: const Color(0xFFF2F8FF),
              border: Border.all(color: const Color(0xFFD7EBFF)),
            ),
            child: const Text(
              '剩余牌统计',
              style: TextStyle(
                color: Color(0xFF245E90),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  for (var index = 0; index < sorted.length; index++) ...[
                    _counterPill(
                      sorted[index],
                      compact: false,
                      singleLine: true,
                    ),
                    if (index != sorted.length - 1) const SizedBox(width: 4),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHudInfoTileResponsive(
    String label, {
    required double height,
  }) =>
      Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: Colors.white.withValues(alpha: 0.92),
          border: Border.all(color: const Color(0xFFD7EBFF)),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF5A7894),
            fontWeight: FontWeight.w800,
            fontSize: 15,
            height: 1.3,
          ),
        ),
      );

  Widget _buildTopControlTileResponsive({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Ink(
        height: 78,
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            colors: active
                ? const [Color(0xFFF7FBFF), Color(0xFFEEF7FF)]
                : const [Colors.white, Color(0xFFF7FBFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: active ? const Color(0xFF8CC8FF) : const Color(0xFFD7EBFF),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: active
                    ? const Color(0x1E2B7FFF)
                    : const Color(0xFFF2F8FF),
              ),
              child: Icon(
                icon,
                size: 16,
                color: const Color(0xFF245E90),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              maxLines: 2,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF245E90),
                fontWeight: FontWeight.w800,
                fontSize: 13,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildTopHud(RoomSnapshot snapshot) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 1260;
          final hudTileWidth = compact ? 176.0 : 208.0;
          final landlordCards = Container(
            width: double.infinity,
            height: compact ? 58 : 62,
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 10 : 12,
              vertical: compact ? 8 : 9,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              color: Colors.white.withValues(alpha: 0.92),
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
          );

          return Row(
            children: [
              _hudButton(
                Icons.arrow_back_rounded,
                '\u5927\u5385',
                widget.controller.backToLobby,
                width: compact ? 108 : 120,
              ),
              SizedBox(width: compact ? 6 : 8),
              SizedBox(width: hudTileWidth, child: landlordCards),
              SizedBox(width: compact ? 6 : 8),
              SizedBox(
                width: hudTileWidth,
                child: _showCounter
                    ? _buildCounter(
                        snapshot.cardCounter,
                        compact: compact,
                        singleLine: true,
                      )
                    : _hudInfoTile('\u5269\u4f59\u724c\u7edf\u8ba1\u5df2\u9690\u85cf'),
              ),
              SizedBox(width: compact ? 6 : 8),
              _hudButton(
                _showCounter
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                _showCounter ? '\u9690\u85cf\u724c\u51b5' : '\u663e\u793a\u724c\u51b5',
                () => setState(() => _showCounter = !_showCounter),
                width: hudTileWidth,
              ),
              SizedBox(width: compact ? 6 : 8),
              _hudButton(
                _musicEnabled
                    ? Icons.music_off_rounded
                    : Icons.music_note_rounded,
                _musicEnabled ? '\u5173\u95ed\u97f3\u4e50' : '\u5f00\u542f\u97f3\u4e50',
                () {
                  setState(() => _musicEnabled = !_musicEnabled);
                  if (_musicEnabled) {
                    unawaited(_voice.startBackgroundMusic());
                  } else {
                    unawaited(_voice.stopBackgroundMusic());
                  }
                },
                width: hudTileWidth,
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
          colors: [Color(0xFFF1F8FF), Color(0xFFD8EBFF), Color(0xFFBCD9F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.82),
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14397BA8),
            blurRadius: 26,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.42),
                    Colors.white.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.56, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            left: 90,
            top: 72,
            child: Transform.rotate(
              angle: -0.22,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
            ),
          ),
          Align(
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0x1F2B7FFF), width: 2),
              ),
            ),
          ),
          const Align(
            child: Text(
              '\u6b22\u4e50\u6597\u5730\u4e3b',
              style: TextStyle(
                color: Color(0x1F1D5687),
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
    return AnimatedContainer(
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

  // ignore: unused_element
  Alignment _trayAlignment({
    required bool compact,
    required _PlayedTrayPosition position,
    required TrickActionEmphasis emphasis,
  }) {
    final primary = emphasis == TrickActionEmphasis.primary;
    return switch (position) {
      _PlayedTrayPosition.left => compact
          ? Alignment(primary ? -0.22 : -0.64, primary ? -0.02 : -0.02)
          : Alignment(primary ? -0.22 : -0.66, primary ? -0.04 : -0.02),
      _PlayedTrayPosition.right => compact
          ? Alignment(primary ? 0.22 : 0.64, primary ? -0.02 : -0.02)
          : Alignment(primary ? 0.22 : 0.66, primary ? -0.04 : -0.02),
      _PlayedTrayPosition.self => compact
          ? Alignment(0, primary ? 0.12 : 0.42)
          : Alignment(0, primary ? 0.10 : 0.38),
    };
  }

  Widget _buildBidChooser({
    required double maxWidth,
    bool showTimer = false,
  }) => ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '\u8bf7\u53eb\u5206',
                    style: TextStyle(
                      color: Color(0xFF173A59),
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                  if (showTimer) ...[
                    const SizedBox(width: 8),
                    _turnStateChip(compact: true),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _actionButton(
                      '\u4e0d\u53eb',
                      widget.controller.isBusy
                          ? null
                          : () => widget.controller.callScore(0),
                      primary: false,
                      compact: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _actionButton(
                      '1 \u5206',
                      widget.controller.isBusy
                          ? null
                          : () => widget.controller.callScore(1),
                      primary: false,
                      compact: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _actionButton(
                      '2 \u5206',
                      widget.controller.isBusy
                          ? null
                          : () => widget.controller.callScore(2),
                      primary: false,
                      compact: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _actionButton(
                      '3 \u5206',
                      widget.controller.isBusy
                          ? null
                          : () => widget.controller.callScore(3),
                      primary: true,
                      compact: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _buildTurnActionChooser({
    required double maxWidth,
    bool showTimer = false,
  }) => ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '\u8f6e\u5230\u4f60',
                    style: TextStyle(
                      color: Color(0xFF173A59),
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                  if (showTimer) ...[
                    const SizedBox(width: 8),
                    _turnStateChip(compact: true),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _actionButton(
                      '\u4e0d\u51fa',
                      widget.controller.isBusy ? null : widget.controller.pass,
                      primary: false,
                      compact: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _actionButton(
                      '\u51fa\u724c',
                      _selectedIds.isNotEmpty && !widget.controller.isBusy
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
                      compact: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
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
    bool centered = false,
  }) {
    if (action == null) {
      return const SizedBox.shrink();
    }
    final primary = emphasis == TrickActionEmphasis.primary;
    final hasCards = action.cards.isNotEmpty;
    final isPass = action.type == ActionType.pass;
    final toneColor = isLeadingPlay && primary
        ? const Color(0xFF1F69FF)
        : active && primary
            ? const Color(0xFF2B7FFF)
            : primary
                ? const Color(0xFF355A78)
                : const Color(0xFF6585A6);
    final displayCardWidth = cardWidth;
    final fanMaxWidth = math.min(maxWidth, 332.0);
    return TweenAnimationBuilder<double>(
      key: ValueKey(action.actionId),
      tween: Tween<double>(begin: 0.94, end: 1),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 12),
            child: child,
          ),
        );
      },
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
            if (!centered) ...[
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: Colors.white.withValues(alpha: primary ? 0.96 : 0.88),
                  border: Border.all(
                    color: toneColor.withValues(alpha: primary ? 0.22 : 0.16),
                  ),
                ),
                child: Text(
                  player.displayName,
                  style: TextStyle(
                    color: toneColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            if (hasCards)
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
              )
            else if (isPass)
              _passBadge(
                '\u4e0d\u51fa',
                color: toneColor,
                primary: primary,
                centered: centered,
              ),
          ],
        ),
      ),
    );
  }

  Widget _passBadge(
    String text, {
    required Color color,
    required bool primary,
    required bool centered,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: primary ? 16 : 14,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: const Color(0xFFF7FBFF).withValues(alpha: primary ? 0.96 : 0.90),
        border: Border.all(
          color: color.withValues(alpha: primary ? 0.26 : 0.18),
        ),
      ),
      child: Text(
        text,
        textAlign: centered ? TextAlign.center : TextAlign.start,
        style: TextStyle(
          color: color.withValues(alpha: 0.78),
          fontWeight: FontWeight.w900,
          fontSize: primary ? 20 : 16,
          letterSpacing: 2,
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
          compact ? 8 : 12,
          compact ? 10 : 12,
          compact ? 8 : 12,
          compact ? 10 : 12,
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
                            fontSize: compact ? 15 : 17,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: compact ? 6 : 8),
                  for (var index = 0; index < sorted.length; index++) ...[
                    _counterPill(sorted[index], compact: compact, singleLine: true),
                    if (index != sorted.length - 1)
                      SizedBox(width: compact ? 2 : 3),
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
                    fontSize: compact ? 14 : 16,
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
      width: singleLine ? (compact ? 58 : 64) : null,
      padding: EdgeInsets.symmetric(
        horizontal: singleLine ? (compact ? 6 : 7) : (compact ? 5 : 8),
        vertical: singleLine ? (compact ? 7 : 8) : (compact ? 5 : 7),
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFFF4FAFF),
        border: Border.all(color: const Color(0xFFD7EBFF)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: const Color(0xFFEAF4FF),
              border: Border.all(color: const Color(0xFFD1E6FB)),
            ),
            child: Text(
              _counter(entry.rank),
              style: TextStyle(
                color: const Color(0xFF245E90),
                fontWeight: FontWeight.w800,
                fontSize:
                    singleLine ? (compact ? 13 : 14) : (compact ? 12 : 13),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${entry.remaining}',
            style: TextStyle(
              color: const Color(0xFF173A59),
              fontWeight: FontWeight.w900,
              fontSize: singleLine ? (compact ? 17 : 19) : 16,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildBottomDockView(
    RoomSnapshot snapshot,
    RoomPlayer me, {
    required List<PlayingCard> selfCards,
    required bool waitingMyBid,
    required bool myTurn,
    required bool managed,
    required bool showTurnChooser,
  }) {
    /*
        ? '请叫分'
        : managed
            ? '托管中'
            : myTurn
                ? '到你出牌'
                : '等待中';
    final showChooser = showTurnChooser || waitingMyBid;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showChooser)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
              child: Center(
                child: waitingMyBid
                    ? _buildBidChooser(maxWidth: 430)
                    : _buildTurnActionChooser(maxWidth: 360),
              ),
            ),
        Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 4),
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 168,
                child: Column(
                  children: [
                    _buildSelfIdentityCardView(me, active: myTurn),
                    const SizedBox(height: 8),
                    _buildMatchMetaCardView(snapshot),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          '你的手牌',
                          style: TextStyle(
                            color: Color(0xFF173A59),
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (snapshot.phase != RoomPhase.finished)
                          _chip(statusText, filled: myTurn || managed),
                        if (myTurn && snapshot.phase != RoomPhase.finished) ...[
                          const SizedBox(width: 8),
                          _turnStateChip(compact: false),
                        ],
                        const Spacer(),
                        OutlinedButton(
                          onPressed: widget.controller.isBusy
                              ? null
                              : _toggleSortOrder,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(92, 48),
                            textStyle: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          child: Text(_sortDescending ? '逆序' : '顺序'),
                        ),
                        const SizedBox(width: 6),
                        OutlinedButton(
                          onPressed: widget.controller.isBusy
                              ? null
                              : _clearSelectedCards,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(120, 48),
                            textStyle: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          child: const Text('取消选中'),
                        ),
                        const SizedBox(width: 6),
                        OutlinedButton(
                          onPressed: snapshot.phase == RoomPhase.playing &&
                                  myTurn &&
                                  !managed &&
                                  !widget.controller.isBusy
                              ? _toggleSuggestedSelection
                              : null,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(96, 48),
                            textStyle: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          child: Text(
                            _isSuggestedSelectionActive() ? '取消提示' : '提示',
                          ),
                        ),
                        const SizedBox(width: 6),
                        FilledButton.tonal(
                          onPressed: widget.controller.isBusy
                              ? null
                              : () {
                                  if (!managed) {
                                    _clearSelectedCards();
                                  }
                                  widget.controller.setManaged(!managed);
                                },
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(108, 48),
                            textStyle: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          child: Text(managed ? '取消托管' : '托管'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _selfFan(selfCards, disabled: waitingMyBid || managed),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ignore: unused_element
  Widget _buildResponsiveBottomDockView(
    RoomSnapshot snapshot,
    RoomPlayer me, {
    required List<PlayingCard> selfCards,
    required bool waitingMyBid,
    required bool myTurn,
    required bool managed,
    required bool showTurnChooser,
  }) {
    final statusText = waitingMyBid
        ? '\u8bf7\u53eb\u5206'
        : managed
            ? '\u6258\u7ba1\u4e2d'
            : myTurn
                ? '\u5230\u4f60\u51fa\u724c'
                : '\u7b49\u5f85\u4e2d';

    return Container(
    */
    final statusText = waitingMyBid
        ? '\u8bf7\u53eb\u5206'
        : managed
            ? '\u6258\u7ba1\u4e2d'
            : myTurn
                ? '\u5230\u4f60\u51fa\u724c'
                : '\u7b49\u5f85\u4e2d';
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 4),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 168,
            child: Column(
              children: [
                _buildSelfIdentityCardView(me, active: myTurn),
                const SizedBox(height: 8),
                _buildMatchMetaCardView(snapshot),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      '\u4f60\u7684\u624b\u724c',
                      style: TextStyle(
                        color: Color(0xFF173A59),
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (snapshot.phase != RoomPhase.finished)
                      _chip(statusText, filled: myTurn || managed),
                    if (myTurn && snapshot.phase != RoomPhase.finished) ...[
                      const SizedBox(width: 8),
                      _turnStateChip(compact: false),
                    ],
                    const Spacer(),
                    OutlinedButton(
                      onPressed: widget.controller.isBusy
                          ? null
                          : _toggleSortOrder,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(92, 48),
                        textStyle: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      child: Text(
                        _sortDescending ? '\u9006\u5e8f' : '\u987a\u5e8f',
                      ),
                    ),
                    const SizedBox(width: 6),
                    OutlinedButton(
                      onPressed: widget.controller.isBusy ||
                              (_selectedIds.isEmpty && _suggestedIds.isEmpty)
                          ? null
                          : _clearSelectedCards,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(120, 48),
                        textStyle: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      child: const Text('\u53d6\u6d88\u9009\u4e2d'),
                    ),
                    const SizedBox(width: 6),
                    OutlinedButton(
                      onPressed: snapshot.phase == RoomPhase.playing &&
                              myTurn &&
                              !managed &&
                              !widget.controller.isBusy
                          ? _toggleSuggestedSelection
                          : null,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(96, 48),
                        textStyle: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
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
                          : () {
                              if (!managed) {
                                _clearSelectedCards();
                              }
                              widget.controller.setManaged(!managed);
                            },
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(108, 48),
                        textStyle: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      child: Text(
                        managed ? '\u53d6\u6d88\u6258\u7ba1' : '\u6258\u7ba1',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _selfFan(selfCards, disabled: waitingMyBid || managed),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildResponsiveBottomDockOverlay(
    RoomSnapshot snapshot,
    RoomPlayer me, {
    required List<PlayingCard> selfCards,
    required bool waitingMyBid,
    required bool myTurn,
    required bool managed,
    required bool showTurnChooser,
  }) {
    final statusText = waitingMyBid
        ? '请叫分'
        : managed
            ? '托管中'
            : myTurn
                ? '到你出牌'
                : '等待中';
    final showChooser = showTurnChooser || waitingMyBid;

    final chooserTopPadding = showChooser ? 104.0 : 0.0;

    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.only(top: chooserTopPadding),
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 4),
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
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
            child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 168,
                child: Column(
                  children: [
                    _buildSelfIdentityCardView(me, active: myTurn),
                    const SizedBox(height: 8),
                    _buildMatchMetaCardView(snapshot),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          '你的手牌',
                          style: TextStyle(
                            color: Color(0xFF173A59),
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (snapshot.phase != RoomPhase.finished)
                          _chip(statusText, filled: myTurn || managed),
                        if (myTurn && snapshot.phase != RoomPhase.finished) ...[
                          const SizedBox(width: 8),
                          _turnStateChip(compact: false),
                        ],
                        const Spacer(),
                        OutlinedButton(
                          onPressed: widget.controller.isBusy
                              ? null
                              : _toggleSortOrder,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(92, 48),
                            textStyle: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          child: Text(_sortDescending ? '逆序' : '顺序'),
                        ),
                        const SizedBox(width: 6),
                        OutlinedButton(
                          onPressed: widget.controller.isBusy ||
                                  _selectedIds.isEmpty
                              ? null
                              : _clearSelectedCards,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(120, 48),
                            textStyle: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          child: const Text('取消选中'),
                        ),
                        const SizedBox(width: 6),
                        OutlinedButton(
                          onPressed: snapshot.phase == RoomPhase.playing &&
                                  myTurn &&
                                  !managed &&
                                  !widget.controller.isBusy
                              ? _toggleSuggestedSelection
                              : null,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(96, 48),
                            textStyle: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          child: Text(
                            _isSuggestedSelectionActive() ? '取消提示' : '提示',
                          ),
                        ),
                        const SizedBox(width: 6),
                        FilledButton.tonal(
                          onPressed: widget.controller.isBusy
                              ? null
                              : () {
                                  if (!managed) {
                                    _clearSelectedCards();
                                  }
                                  widget.controller.setManaged(!managed);
                                },
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(108, 48),
                            textStyle: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          child: Text(managed ? '取消托管' : '托管'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _selfFan(selfCards, disabled: waitingMyBid || managed),
                  ],
                ),
              ),
            ],
          ),
          ),
        ),
        if (showChooser)
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: Align(
              alignment: const Alignment(0.2, 0),
              child: waitingMyBid
                  ? _buildBidChooser(maxWidth: 410)
                  : _buildTurnActionChooser(maxWidth: 300),
            ),
          ),
      ],
    );
  }

  /*
  Widget _buildResponsiveBottomDockFloating(
    RoomSnapshot snapshot,
    RoomPlayer me, {
    required List<PlayingCard> selfCards,
    required bool waitingMyBid,
    required bool myTurn,
    required bool managed,
    required bool showTurnChooser,
  }) {
    final statusText = waitingMyBid
        ? '请叫分'
        : managed
            ? '托管中'
            : myTurn
                ? '到你出牌'
                : '等待中';
    /*
    final statusText = waitingMyBid
        ? '璇峰彨鍒?
        : managed
            ? '鎵樼涓?
            : myTurn
                ? '鍒颁綘鍑虹墝'
                : '绛夊緟涓?;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 4),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 168,
            child: Column(
              children: [
                _buildSelfIdentityCardView(me, active: myTurn),
                const SizedBox(height: 8),
                _buildMatchMetaCardView(snapshot),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: IgnorePointer(
                    child: Align(
                      alignment: const Alignment(0.12, 0),
                      child: CompositedTransformTarget(
                        link: _turnChooserAnchorLink,
                        child: const SizedBox(width: 1, height: 1),
                      ),
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          '浣犵殑鎵嬬墝',
                          style: TextStyle(
                            color: Color(0xFF173A59),
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (snapshot.phase != RoomPhase.finished)
                          _chip(statusText, filled: myTurn || managed),
                        if (myTurn && snapshot.phase != RoomPhase.finished) ...[
                          const SizedBox(width: 8),
                          _turnStateChip(compact: false),
                        ],
                        const Spacer(),
                        OutlinedButton(
                          onPressed: widget.controller.isBusy
                              ? null
                              : _toggleSortOrder,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(92, 48),
                            textStyle: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          child: Text(_sortDescending ? '閫嗗簭' : '椤哄簭'),
                        ),
                        const SizedBox(width: 6),
                        OutlinedButton(
                          onPressed: widget.controller.isBusy ||
                                  _selectedIds.isEmpty
                              ? null
                              : _clearSelectedCards,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(120, 48),
                            textStyle: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          child: const Text('鍙栨秷閫変腑'),
                        ),
                        const SizedBox(width: 6),
                        OutlinedButton(
                          onPressed: snapshot.phase == RoomPhase.playing &&
                                  myTurn &&
                                  !managed &&
                                  !widget.controller.isBusy
                              ? _toggleSuggestedSelection
                              : null,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(96, 48),
                            textStyle: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          child: Text(
                            _isSuggestedSelectionActive() ? '鍙栨秷鎻愮ず' : '鎻愮ず',
                          ),
                        ),
                        const SizedBox(width: 6),
                        FilledButton.tonal(
                          onPressed: widget.controller.isBusy
                              ? null
                              : () {
                                  if (!managed) {
                                    _clearSelectedCards();
                                  }
                                  widget.controller.setManaged(!managed);
                                },
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(108, 48),
                            textStyle: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          child: Text(managed ? '鍙栨秷鎵樼' : '鎵樼'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _selfFan(selfCards, disabled: waitingMyBid || managed),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  */
  */

  Widget _buildResponsiveBottomDockFloating(
    RoomSnapshot snapshot,
    RoomPlayer me, {
    required List<PlayingCard> selfCards,
    required bool waitingMyBid,
    required bool myTurn,
    required bool managed,
    required bool showTurnChooser,
  }) {
    final statusText = waitingMyBid
        ? '\u8bf7\u53eb\u5206'
        : managed
            ? '\u6258\u7ba1\u4e2d'
            : myTurn
                ? '\u5230\u4f60\u51fa\u724c'
                : '\u7b49\u5f85\u4e2d';
    final showChooser = showTurnChooser || waitingMyBid;
    const handSectionInset = 180.0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 4),
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 168,
                child: Column(
                  children: [
                    _buildSelfIdentityCardView(me, active: myTurn),
                    const SizedBox(height: 8),
                    _buildMatchMetaCardView(snapshot),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          '\u4f60\u7684\u624b\u724c',
                          style: TextStyle(
                            color: Color(0xFF173A59),
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (snapshot.phase != RoomPhase.finished && !showChooser)
                          _chip(statusText, filled: myTurn || managed),
                        if (myTurn &&
                            snapshot.phase != RoomPhase.finished &&
                            !showChooser) ...[
                          const SizedBox(width: 8),
                          _turnStateChip(compact: false),
                        ],
                        const Spacer(),
                        OutlinedButton(
                          onPressed: widget.controller.isBusy
                              ? null
                              : _toggleSortOrder,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(92, 48),
                            textStyle: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          child: Text(
                            _sortDescending
                                ? '\u9006\u5e8f'
                                : '\u987a\u5e8f',
                          ),
                        ),
                        const SizedBox(width: 6),
                        OutlinedButton(
                          onPressed: widget.controller.isBusy ||
                                  _selectedIds.isEmpty
                              ? null
                              : _clearSelectedCards,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(120, 48),
                            textStyle: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          child: const Text('\u53d6\u6d88\u9009\u4e2d'),
                        ),
                        const SizedBox(width: 6),
                        OutlinedButton(
                          onPressed: snapshot.phase == RoomPhase.playing &&
                                  myTurn &&
                                  !managed &&
                                  !widget.controller.isBusy
                              ? _toggleSuggestedSelection
                              : null,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(96, 48),
                            textStyle: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
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
                              : () {
                                  if (!managed) {
                                    _clearSelectedCards();
                                  }
                                  widget.controller.setManaged(!managed);
                                },
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(108, 48),
                            textStyle: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          child: Text(
                            managed
                                ? '\u53d6\u6d88\u6258\u7ba1'
                                : '\u6258\u7ba1',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _selfFan(selfCards, disabled: waitingMyBid || managed),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showChooser)
          Positioned(
            left: handSectionInset,
            right: 12,
            top: 0,
            child: Align(
              alignment: Alignment.topCenter,
              child: CompositedTransformTarget(
                link: _turnChooserAnchorLink,
                child: const SizedBox(width: 1, height: 1),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSelfIdentityCardView(
    RoomPlayer me, {
    required bool active,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Colors.white.withValues(alpha: 0.94),
        border: Border.all(
          color: active ? const Color(0xFF2B7FFF) : const Color(0xFFD7EBFF),
          width: active ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFF2B7FFF),
            child: Text(
              me.displayName.substring(0, 1).toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  me.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF173A59),
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  me.isLandlord ? '地主' : '农民',
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
    );
  }

  Widget _buildMatchMetaCardView(RoomSnapshot snapshot) {
    final modeText = snapshot.mode == MatchMode.online
        ? '真人对局'
        : widget.controller.botDifficulty.label;
    final rows = <MapEntry<String, String>>[
      MapEntry('模式', modeText),
      MapEntry('底分', '${snapshot.baseScore}'),
      MapEntry('倍数', '${snapshot.multiplier}'),
      MapEntry('本轮', '${snapshot.currentRoundScore}'),
      MapEntry('剩余牌数', '${snapshot.selfCards.length}'),
    ];
    if (snapshot.springTriggered) {
      rows.add(const MapEntry('春天', '已触发'));
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: const Color(0xFFF3F9FF),
        border: Border.all(color: const Color(0xFFD7EBFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < rows.length; index++) ...[
            Row(
              children: [
                SizedBox(
                  width: 70,
                  child: Text(
                    rows[index].key,
                    style: const TextStyle(
                      color: Color(0xFF5A7894),
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    rows[index].value,
                    style: const TextStyle(
                      color: Color(0xFF173A59),
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            if (index != rows.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildBottomDock(
    RoomSnapshot snapshot,
    RoomPlayer me, {
    required List<PlayingCard> selfCards,
    required bool waitingMyBid,
    required bool myTurn,
    required bool managed,
    required bool showTurnChooser,
  }) {
    final statusText = waitingMyBid
        ? '\u8bf7\u53eb\u5206'
        : managed
            ? '\u6258\u7ba1\u4e2d'
            : myTurn
                ? '\u5230\u4f60\u51fa\u724c'
                : '\u7b49\u5f85\u4e2d';
    const selfInfoWidth = 196.0;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 4),
          padding: EdgeInsets.fromLTRB(
            12,
            (showTurnChooser || waitingMyBid) ? 52 : 10,
            12,
            10,
          ),
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: selfInfoWidth,
                child: Column(
                  children: [
                    _buildSelfIdentityCard(
                      me,
                      active: myTurn,
                      managed: managed,
                    ),
                    const SizedBox(height: 10),
                    _buildMatchMetaCard(snapshot),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '\u4f60\u7684\u624b\u724c',
                          style: const TextStyle(
                            color: Color(0xFF173A59),
                            fontWeight: FontWeight.w900,
                            fontSize: 24,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (snapshot.phase != RoomPhase.finished)
                          _chip(statusText, filled: myTurn || managed),
                        if (myTurn && snapshot.phase != RoomPhase.finished) ...[
                          const SizedBox(width: 8),
                          _turnStateChip(compact: false),
                        ],
                        const Spacer(),
                        OutlinedButton(
                          onPressed: snapshot.phase == RoomPhase.playing &&
                                  myTurn &&
                                  !managed &&
                                  !widget.controller.isBusy
                              ? _toggleSuggestedSelection
                              : null,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(104, 52),
                            textStyle: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
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
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(118, 52),
                            textStyle: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          child: Text(
                            managed ? '\u53d6\u6d88\u6258\u7ba1' : '\u6258\u7ba1',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      me.isLandlord ? '\u5730\u4e3b' : '\u519c\u6c11',
                      style: const TextStyle(
                        color: Color(0xFF5A7894),
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _selfFan(selfCards, disabled: waitingMyBid || managed),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showTurnChooser || waitingMyBid)
          Positioned(
            top: -6,
            left: 0,
            right: 0,
              child: Center(
                child: waitingMyBid
                    ? _buildBidChooser(maxWidth: 430)
                    : _buildTurnActionChooser(maxWidth: 360),
              ),
            ),
      ],
    );
  }

  Widget _buildSelfIdentityCard(
    RoomPlayer me, {
    required bool active,
    required bool managed,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white.withValues(alpha: 0.94),
        border: Border.all(
          color: active ? const Color(0xFF2B7FFF) : const Color(0xFFD7EBFF),
          width: active ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFF2B7FFF),
            child: Text(
              me.displayName.substring(0, 1).toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  me.displayName,
                  style: const TextStyle(
                    color: Color(0xFF173A59),
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  me.isLandlord ? '\u5730\u4e3b' : '\u519c\u6c11',
                  style: const TextStyle(
                    color: Color(0xFF5A7894),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          if (managed)
            _seatTag('\u6258\u7ba1\u4e2d', const Color(0xFF2B7FFF)),
        ],
      ),
    );
  }

  Widget _buildMatchMetaCard(RoomSnapshot snapshot) {
    final modeText = snapshot.mode == MatchMode.online
        ? '真人模式'
        : '${widget.controller.botDifficulty.label}：${widget.controller.botDifficulty.modelFamily}';
    final coins = widget.controller.profile?.coins ?? 0;
    final rows = <MapEntry<String, String>>[
      MapEntry('模式', modeText),
      MapEntry('底分', '${snapshot.baseScore}'),
      MapEntry('倍数', '${snapshot.multiplier}'),
      MapEntry('本轮', '${snapshot.currentRoundScore}'),
      MapEntry('剩余牌数', '${snapshot.selfCards.length}'),
      MapEntry('本人金币', '$coins'),
    ];
    if (snapshot.springTriggered) {
      rows.add(const MapEntry('状态', '春天'));
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: const Color(0xFFF3F9FF),
        border: Border.all(color: const Color(0xFFD7EBFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < rows.length; index++) ...[
            Row(
              children: [
                SizedBox(
                  width: 76,
                  child: Text(
                    '${rows[index].key}：',
                    style: const TextStyle(
                      color: Color(0xFF5A7894),
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    rows[index].value,
                    style: const TextStyle(
                      color: Color(0xFF173A59),
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            if (index != rows.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _selfFan(List<PlayingCard> cards, {required bool disabled}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final overlapFactor = cards.length >= 20
            ? 0.34
            : cards.length >= 17
                ? 0.36
                : cards.length >= 14
                    ? 0.38
                    : cards.length >= 10
                        ? 0.40
                        : 0.44;
        var width = cards.isEmpty
            ? 132.0
            : (availableWidth /
                    (1 + overlapFactor * math.max(0, cards.length - 1)))
                .clamp(112.0, 168.0);
        var spacing = cards.length <= 1 ? width : width * overlapFactor;
        var totalWidth =
            cards.isEmpty ? width : width + (cards.length - 1) * spacing;
        if (cards.length > 1 && totalWidth > availableWidth) {
          spacing = (availableWidth - width) / (cards.length - 1);
          totalWidth = availableWidth;
        }
        final leftInset = math.max(0.0, (availableWidth - totalWidth) / 2);

        int? handIndexAt(double dx) {
          return _handIndexAtPosition(
            cards,
            dx - leftInset,
            spacing,
            width,
            totalWidth,
          );
        }

        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: disabled
              ? null
              : (event) {
                  final index = handIndexAt(event.localPosition.dx);
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
                  final index = handIndexAt(event.localPosition.dx);
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
            width: availableWidth,
            height: width * 1.42 + 8,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (var index = 0; index < cards.length; index++)
                  Positioned(
                    left: leftInset + index * spacing,
                    top: _selectedIds.contains(cards[index].id) ? 0 : 8,
                    child: _cardFace(
                      cards[index],
                      width,
                      selected: _selectedIds.contains(cards[index].id),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _backFan(int count, {required bool towardCenter}) {
    const width = 38.0;
    final visible = math.min(count, 11);
    final spacing = width * 0.16;
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

  Widget _miniCard(String label, bool isRed) {
    final isJoker = label == '大王' || label == '小王';
    final text = isJoker ? '${label[0]}\n${label[1]}' : label;
    final textColor = isRed ? const Color(0xFFC53C35) : const Color(0xFF173A59);
    final fontSize = isJoker
        ? 12.5
        : label.length >= 2
            ? 12.5
            : 14.5;
    return Container(
      width: 30,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFF6FAFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFFD7EBFF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x143678A3),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w900,
          fontSize: fontSize,
          height: 1.05,
        ),
      ),
    );
  }

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

  Widget _hudInfoTile(String label) => Container(
        height: 82,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white.withValues(alpha: 0.88),
          border: Border.all(color: const Color(0xFFD7EBFF)),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF5A7894),
            fontWeight: FontWeight.w800,
            fontSize: 15,
            height: 1.3,
          ),
        ),
      );

  Widget _hudButton(
        IconData icon,
        String label,
        VoidCallback onTap, {
        double? width,
      }) =>
      InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          width: width,
          height: 66,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white.withValues(alpha: 0.88),
            border: Border.all(color: const Color(0xFFD7EBFF)),
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
                  fontSize: 16,
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

  Widget _actionButton(
    String text,
    VoidCallback? onTap, {
    required bool primary,
    bool compact = false,
  }) {
    if (primary) {
      return FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          minimumSize: Size(0, compact ? 44 : 52),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 8 : 18,
            vertical: compact ? 8 : 12,
          ),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          textStyle: TextStyle(
            fontSize: compact ? 16 : 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        child: Text(text),
      );
    }
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: Size(0, compact ? 44 : 52),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 18,
          vertical: compact ? 8 : 12,
        ),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: TextStyle(
          fontSize: compact ? 16 : 18,
          fontWeight: FontWeight.w900,
        ),
      ),
      child: Text(text),
    );
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
                      FilledButton.icon(
                        onPressed: widget.controller.backToLobby,
                        icon: const Icon(Icons.arrow_back_rounded, size: 18),
                        label: const Text('\u56de\u5230\u5927\u5385'),
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
  if (action.patternLabel == 'managed_on') return '\u6258\u7ba1';
  if (action.patternLabel == 'managed_off') return '\u53d6\u6d88\u6258\u7ba1';
  if (action.patternLabel == 'bid_pass') return '\u4e0d\u53eb';
  if (action.patternLabel.startsWith('bid_')) {
    return '\u53eb${_scoreText(action.patternLabel.substring(4))}\u5206';
  }
  if (action.type == ActionType.pass) {
    return previousPlay == null ? '\u4e0d\u51fa' : '\u8981\u4e0d\u8d77';
  }
  if (action.cards.isNotEmpty) {
    return action.cards.map((card) => card.voiceLabel).join(' ');
  }
  return _display(action).replaceAll(' ', '');
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

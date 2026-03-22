import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'models/app_models.dart';
import 'pages/game_page.dart';
import 'pages/lobby_page.dart';
import 'pages/login_page.dart';
import 'services/gateway_factory.dart';
import 'services/game_gateway.dart';
import 'state/app_controller.dart';
import 'utils/app_log.dart';
import 'utils/render_dump.dart';
import 'widgets/responsive_modal.dart';

class LandlordsApp extends StatefulWidget {
  const LandlordsApp({
    super.key,
    this.gateway,
  });

  final GameGateway? gateway;

  @override
  State<LandlordsApp> createState() => _LandlordsAppState();
}

class _LandlordsAppState extends State<LandlordsApp>
    with WidgetsBindingObserver {
  late final AppController _controller;
  final GlobalKey _captureBoundaryKey = GlobalKey();
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  bool _capturedFirstFrame = false;
  AppStage? _lastCapturedStage;
  bool _showingInvitationDialog = false;
  bool _showingInvitationFeedbackDialog = false;
  bool _showingPopupNoticeDialog = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    appLog(AppLogLevel.info, 'app', 'initState');
    _controller = AppController(gateway: widget.gateway ?? createGateway());
    _controller.addListener(_handleControllerChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final media = MediaQuery.maybeOf(context);
      appLog(
        AppLogLevel.info,
        'app',
        'post-frame size=${media?.size.width ?? -1}x${media?.size.height ?? -1}',
      );
      unawaited(_captureFirstFrame());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    appLog(AppLogLevel.info, 'app', 'dispose');
    _controller.removeListener(_handleControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    appLog(AppLogLevel.info, 'app', 'lifecycle=${state.name}');
    if (state == AppLifecycleState.resumed) {
      unawaited(_handleAppResumed());
    }
  }

  @override
  Widget build(BuildContext context) {
    appLog(AppLogLevel.info, 'app', 'LandlordsApp build');
    const seed = Color(0xFF69B6FF);
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
      surface: const Color(0xFFF8FCFF),
      primary: const Color(0xFF2B7FFF),
      secondary: const Color(0xFF67C2FF),
    );

    return MaterialApp(
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      title: '欢乐斗地主',
      scrollBehavior: const _LandlordsScrollBehavior(),
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        fontFamilyFallback: const [
          'PingFang SC',
          'Microsoft YaHei',
          'Noto Sans SC',
          'Noto Sans CJK SC',
          'sans-serif',
        ],
        scaffoldBackgroundColor: const Color(0xFFF3F9FF),
        textTheme: ThemeData.light().textTheme.apply(
              bodyColor: const Color(0xFF14304B),
              displayColor: const Color(0xFF14304B),
            ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white.withValues(alpha: 0.88),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF2B7FFF),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            textStyle: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ),
      home: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          appLog(
            AppLogLevel.info,
            'app',
            'stage=${_controller.stage} snapshot=${_controller.roomSnapshot?.roomId ?? '-'} '
            'profile=${_controller.profile?.username ?? '-'}',
          );
          final child = switch (_controller.stage) {
            AppStage.login => LoginPage(controller: _controller),
            AppStage.lobby || AppStage.matching => LobbyPage(controller: _controller),
            AppStage.game => GamePage(controller: _controller),
          };
          WidgetsBinding.instance.addPostFrameCallback((_) {
            unawaited(_captureStageFrame(_controller.stage));
          });
          return RepaintBoundary(
            key: _captureBoundaryKey,
            child: _LandscapeGuard(child: child),
          );
        },
      ),
    );
  }

  void _handleControllerChanged() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }
      await _maybeShowInvitationDialog();
      await _maybeShowInvitationFeedbackDialog();
      await _maybeShowPopupNoticeDialog();
    });
  }

  Future<void> _handleAppResumed() async {
    await _controller.recoverConnection();
    if (!mounted) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }
      await _maybeShowInvitationDialog();
      await _maybeShowInvitationFeedbackDialog();
      await _maybeShowPopupNoticeDialog();
    });
  }

  Future<void> _maybeShowInvitationDialog() async {
    final invitation = _controller.activeInvitation;
    if (_showingInvitationDialog || invitation == null) {
      return;
    }
    final dialogContext = _navigatorKey.currentContext;
    if (dialogContext == null) {
      return;
    }
    _showingInvitationDialog = true;
    try {
      await showDialog<void>(
        context: dialogContext,
        useRootNavigator: true,
        barrierDismissible: false,
        builder: (context) => _InvitationDialog(
          invitation: invitation,
          onAccept: () async {
            return _controller.respondToInvitation(
              invitationId: invitation.invitationId,
              accept: true,
            );
          },
          onReject: () async {
            return _controller.respondToInvitation(
              invitationId: invitation.invitationId,
              accept: false,
            );
          },
        ),
      );
    } finally {
      _showingInvitationDialog = false;
    }
    if (_controller.activeInvitation?.invitationId == invitation.invitationId) {
      _controller.dismissActiveInvitation();
    }
    // After dismiss, check if there is another queued invitation to show.
    if (mounted) {
      await _maybeShowInvitationDialog();
    }
  }

  Future<void> _maybeShowInvitationFeedbackDialog() async {
    final feedback = _controller.activeInvitationFeedback;
    if (_showingInvitationFeedbackDialog || feedback == null) {
      return;
    }
    final dialogContext = _navigatorKey.currentContext;
    if (dialogContext == null) {
      return;
    }
    _showingInvitationFeedbackDialog = true;
    try {
      await showDialog<void>(
        context: dialogContext,
        useRootNavigator: true,
        builder: (context) => _InvitationFeedbackDialog(feedback: feedback),
      );
    } finally {
      _showingInvitationFeedbackDialog = false;
    }
    if (_controller.activeInvitationFeedback?.invitationId ==
        feedback.invitationId) {
      _controller.dismissActiveInvitationFeedback();
    }
    if (mounted) {
      await _maybeShowInvitationFeedbackDialog();
    }
  }

  Future<void> _maybeShowPopupNoticeDialog() async {
    final notice = _controller.activePopupNotice;
    if (_showingPopupNoticeDialog || notice == null) {
      return;
    }
    final dialogContext = _navigatorKey.currentContext;
    if (dialogContext == null) {
      return;
    }
    _showingPopupNoticeDialog = true;
    try {
      await showDialog<void>(
        context: dialogContext,
        useRootNavigator: true,
        barrierDismissible: false,
        builder: (context) => _PopupNoticeDialog(notice: notice),
      );
    } finally {
      _showingPopupNoticeDialog = false;
    }
    if (_controller.activePopupNotice?.title == notice.title &&
        _controller.activePopupNotice?.message == notice.message) {
      _controller.dismissActivePopupNotice();
    }
    if (mounted) {
      await _maybeShowPopupNoticeDialog();
    }
  }

  Future<void> _captureFirstFrame() async {
    final bindingName = WidgetsBinding.instance.runtimeType.toString();
    if (!kDebugMode ||
        _capturedFirstFrame ||
        !mounted ||
        bindingName.contains('TestWidgetsFlutterBinding')) {
      return;
    }
    _capturedFirstFrame = true;
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!mounted) {
      return;
    }
    final renderObject = _captureBoundaryKey.currentContext?.findRenderObject();
    if (renderObject is! RenderRepaintBoundary) {
      appLog(
        AppLogLevel.warn,
        'app',
        'first frame dump skipped boundary=${renderObject.runtimeType}',
      );
      return;
    }
    appLog(
      AppLogLevel.info,
      'app',
      'dump first frame boundary size=${renderObject.size.width}x${renderObject.size.height}',
    );
    try {
      await dumpRenderBoundaryToFile(renderObject, 'app_first_frame');
      appLog(AppLogLevel.info, 'app', 'first frame dump complete');
    } catch (error) {
      appLog(AppLogLevel.error, 'app', 'first frame dump failed: $error');
    }
  }

  Future<void> _captureStageFrame(AppStage stage) async {
    final bindingName = WidgetsBinding.instance.runtimeType.toString();
    if (!kDebugMode ||
        !mounted ||
        _lastCapturedStage == stage ||
        bindingName.contains('TestWidgetsFlutterBinding')) {
      return;
    }
    _lastCapturedStage = stage;
    await Future<void>.delayed(const Duration(milliseconds: 220));
    if (!mounted) {
      return;
    }
    final renderObject = _captureBoundaryKey.currentContext?.findRenderObject();
    if (renderObject is! RenderRepaintBoundary) {
      return;
    }
    try {
      await dumpRenderBoundaryToFile(renderObject, 'stage_${stage.name}');
      appLog(
        AppLogLevel.info,
        'app',
        'stage frame dump complete stage=${stage.name}',
      );
    } catch (error) {
      appLog(
        AppLogLevel.warn,
        'app',
        'stage frame dump failed stage=${stage.name}: $error',
      );
    }
  }
}

class _LandlordsScrollBehavior extends MaterialScrollBehavior {
  const _LandlordsScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.invertedStylus,
        PointerDeviceKind.unknown,
      };
}

class _LandscapeGuard extends StatelessWidget {
  const _LandscapeGuard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final portrait = media.size.height > media.size.width;
    final narrowScreen = media.size.shortestSide < 700;
    final shouldGuard = narrowScreen &&
        portrait &&
        (!kIsWeb ||
            defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
    appLog(
      AppLogLevel.debug,
      'landscape_guard',
      'size=${media.size.width}x${media.size.height} '
      'portrait=$portrait narrow=$narrowScreen guard=$shouldGuard '
      'platform=${defaultTargetPlatform.name} web=$kIsWeb',
    );
    if (!shouldGuard) {
      return child;
    }
    return DecoratedBox(
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
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x143678A3),
                  blurRadius: 28,
                  offset: Offset(0, 14),
                ),
              ],
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.screen_rotation_alt_rounded,
                  size: 54,
                  color: Color(0xFF2B7FFF),
                ),
                SizedBox(height: 16),
                Text(
                  '请横屏',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF173A59),
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  '横过来继续体验完整牌桌。',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF5A7894),
                    height: 1.4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}

class _InvitationDialog extends StatefulWidget {
  const _InvitationDialog({
    required this.invitation,
    required this.onAccept,
    required this.onReject,
  });

  final RoomInvitation invitation;
  final Future<bool> Function() onAccept;
  final Future<bool> Function() onReject;

  @override
  State<_InvitationDialog> createState() => _InvitationDialogState();
}

class _InvitationDialogState extends State<_InvitationDialog> {
  bool _submitting = false;

  Future<void> _handleAction(Future<bool> Function() action) async {
    if (_submitting) {
      return;
    }
    setState(() {
      _submitting = true;
    });
    try {
      final handled = await action();
      if (handled && mounted) {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final invitation = widget.invitation;
    final onAccept = widget.onAccept;
    final onReject = widget.onReject;
    return ResponsiveDialogPanel(
      maxWidth: 420,
      maxHeight: 420,
      widthFactor: 0.86,
      heightFactor: 0.56,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
      scrollable: false,
      child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '收到邀请',
                style: TextStyle(
                  color: Color(0xFF173A59),
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '${invitation.inviterName}（账号 ${invitation.inviterAccount}）邀请你加入房间 ${invitation.roomCode}。',
                style: const TextStyle(
                  color: Color(0xFF587790),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _submitting ? null : () => _handleAction(onReject),
                      child: const Text('拒绝'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: _submitting ? null : () => _handleAction(onAccept),
                      child: const Text('同意'),
                    ),
                  ),
                ],
              ),
            ],
          ),
    );
  }
}

class _InvitationFeedbackDialog extends StatelessWidget {
  const _InvitationFeedbackDialog({required this.feedback});

  final InvitationFeedback feedback;

  @override
  Widget build(BuildContext context) {
    final title = switch (feedback.status) {
      InvitationFeedbackStatus.accepted => '邀请已接受',
      InvitationFeedbackStatus.rejected => '邀请被拒绝',
      InvitationFeedbackStatus.expired => '邀请已失效',
      InvitationFeedbackStatus.failed => '邀请未成功',
    };
    final detail = _friendlyInvitationFeedbackDetail(feedback.detail);
    return ResponsiveDialogPanel(
      maxWidth: 400,
      maxHeight: 380,
      widthFactor: 0.84,
      heightFactor: 0.52,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
      scrollable: false,
      child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF173A59),
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '${feedback.targetName}：$detail',
                style: const TextStyle(
                  color: Color(0xFF587790),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('知道了'),
                ),
              ),
            ],
          ),
    );
  }
}

String _friendlyInvitationFeedbackDetail(String raw) {
  if (raw.contains('invitation timed out')) {
    return '这条房间邀请已超时。';
  }
  if (raw.contains('player joined the room')) {
    return '已加入你的房间。';
  }
  if (raw.contains('player rejected the invitation')) {
    return '拒绝了这次入座邀请。';
  }
  if (raw.contains('player is currently in another room')) {
    return '当前正在其他房间中，暂时无法加入。';
  }
  if (raw.contains('room is no longer available')) {
    return '目标房间已经不可用。';
  }
  if (raw.contains('room is full')) {
    return '目标房间已经满员。';
  }
  if (raw.contains('room seats changed')) {
    return '房间座位已变化，邀请已失效。';
  }
  if (raw.contains('room started')) {
    return '房间已经开局，邀请已失效。';
  }
  if (raw.contains('room closed')) {
    return '房间已经关闭，邀请已失效。';
  }
  return raw;
}

class _PopupNoticeDialog extends StatelessWidget {
  const _PopupNoticeDialog({required this.notice});

  final AppDialogNotice notice;

  @override
  Widget build(BuildContext context) {
    return ResponsiveDialogPanel(
      maxWidth: 420,
      maxHeight: 400,
      widthFactor: 0.86,
      heightFactor: 0.54,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
      scrollable: false,
      child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                notice.title,
                style: const TextStyle(
                  color: Color(0xFF173A59),
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                notice.message,
                style: const TextStyle(
                  color: Color(0xFF587790),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(notice.actionLabel),
                ),
              ),
            ],
          ),
    );
  }
}

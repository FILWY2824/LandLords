import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'pages/game_page.dart';
import 'pages/lobby_page.dart';
import 'pages/login_page.dart';
import 'services/gateway_factory.dart';
import 'state/app_controller.dart';
import 'utils/app_log.dart';
import 'utils/render_dump.dart';

class LandlordsApp extends StatefulWidget {
  const LandlordsApp({super.key});

  @override
  State<LandlordsApp> createState() => _LandlordsAppState();
}

class _LandlordsAppState extends State<LandlordsApp>
    with WidgetsBindingObserver {
  late final AppController _controller;
  final GlobalKey _captureBoundaryKey = GlobalKey();
  bool _capturedFirstFrame = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    appLog(AppLogLevel.info, 'app', 'initState');
    _controller = AppController(gateway: createGateway());
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
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    appLog(AppLogLevel.info, 'app', 'lifecycle=${state.name}');
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
      debugShowCheckedModeBanner: false,
      title: '欢乐斗地主',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: const Color(0xFFF3F9FF),
        fontFamily: 'LandlordsUiSubset',
        fontFamilyFallback: const [
          'Noto Sans SC',
          'Microsoft YaHei UI',
          'Microsoft YaHei',
          'PingFang SC',
          'Heiti SC',
          'WenQuanYi Micro Hei',
        ],
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
          return RepaintBoundary(
            key: _captureBoundaryKey,
            child: _LandscapeGuard(child: child),
          );
        },
      ),
    );
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
          constraints: const BoxConstraints(maxWidth: 420),
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
                  '请横屏体验牌桌',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF173A59),
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  '安卓原生应用会自动横屏。浏览器打开时，程序会尽量请求横屏；如果系统或浏览器拦截，请手动旋转设备后继续游戏。',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF5A7894),
                    height: 1.6,
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

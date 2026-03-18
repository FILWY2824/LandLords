import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'src/app.dart';
import 'src/utils/app_log.dart';

export 'src/app.dart';

Future<void> main() async {
  appLog(AppLogLevel.info, 'main', 'startup begin');
  WidgetsFlutterBinding.ensureInitialized();
  appLog(AppLogLevel.info, 'main', 'widgets binding ready');
  var timingLogCount = 0;
  WidgetsBinding.instance.addTimingsCallback((timings) {
    for (final timing in timings) {
      if (timingLogCount >= 5) {
        return;
      }
      timingLogCount += 1;
      appLog(
        AppLogLevel.debug,
        'main',
        'frame timing build=${timing.buildDuration.inMilliseconds}ms '
        'raster=${timing.rasterDuration.inMilliseconds}ms '
        'total=${timing.totalSpan.inMilliseconds}ms',
      );
    }
  });

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    appLog(
      AppLogLevel.error,
      'main',
      'flutter error: ${details.exceptionAsString()}',
    );
  };

  PlatformDispatcher.instance.onError = (error, stackTrace) {
    appLog(
      AppLogLevel.error,
      'main',
      'platform error: $error',
    );
    if (stackTrace.toString().isNotEmpty) {
      appLog(AppLogLevel.error, 'main', 'platform stack: $stackTrace');
    }
    return false;
  };
  appLog(AppLogLevel.info, 'main', 'error handlers installed');

  ErrorWidget.builder = (details) => _FatalErrorView(
        title: '页面加载失败',
        message: kDebugMode
            ? details.exceptionAsString()
            : '程序遇到异常，请重新启动后再试。',
      );

  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS)) {
    appLog(
      AppLogLevel.info,
      'main',
      'apply mobile landscape orientation preferences',
    );
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  try {
    appLog(AppLogLevel.info, 'main', 'font preload begin');
    final fontLoader = FontLoader('LandlordsUiSubset')
      ..addFont(rootBundle.load('assets/fonts/LandlordsUiSubset.ttf'));
    await fontLoader.load();
    appLog(AppLogLevel.info, 'main', 'ui font preload finished');
  } catch (error) {
    appLog(
      AppLogLevel.warn,
      'main',
      'ui font preload failed, continue with fallback fonts: $error',
    );
  }

  try {
    appLog(AppLogLevel.info, 'main', 'runApp begin');
    runApp(const LandlordsApp());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      appLog(
        AppLogLevel.info,
        'main',
        'first frame callback fired views=${PlatformDispatcher.instance.views.length}',
      );
    });
  } catch (error, stackTrace) {
    appLog(AppLogLevel.error, 'main', 'startup failed: $error');
    appLog(AppLogLevel.error, 'main', 'startup stack: $stackTrace');
    runApp(
      _FatalErrorApp(
        title: '启动失败',
        message: kDebugMode ? '$error' : '程序启动失败，请重新打开应用。',
      ),
    );
  }
}

class _FatalErrorApp extends StatelessWidget {
  const _FatalErrorApp({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: _FatalErrorView(
          title: title,
          message: message,
        ),
      ),
    );
  }
}

class _FatalErrorView extends StatelessWidget {
  const _FatalErrorView({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
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
          constraints: const BoxConstraints(maxWidth: 520),
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 28,
                      color: Color(0xFFBC5849),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Landlords',
                      style: TextStyle(
                        color: Color(0xFF173A59),
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF173A59),
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: const TextStyle(
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

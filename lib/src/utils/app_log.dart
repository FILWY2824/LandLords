import 'dart:async';

import 'package:flutter/foundation.dart';

import 'app_log_sink.dart';

enum AppLogLevel {
  debug,
  info,
  warn,
  error,
}

void appLog(
  AppLogLevel level,
  String tag,
  String message,
) {
  if (!kDebugMode) {
    return;
  }
  final now = DateTime.now();
  final timestamp =
      '${_two(now.hour)}:${_two(now.minute)}:${_two(now.second)}.${_three(now.millisecond)}';
  final line = '[$timestamp][${level.name.toUpperCase()}][$tag] $message';
  debugPrint(line);
  unawaited(writeAppLogLine(line));
}

String _two(int value) => value.toString().padLeft(2, '0');

String _three(int value) => value.toString().padLeft(3, '0');

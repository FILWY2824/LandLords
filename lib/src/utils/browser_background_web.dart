// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;

import 'browser_background.dart';

class _WebBrowserBackgroundBridge implements BrowserBackgroundBridge {
  static final StreamController<bool> _controller =
      StreamController<bool>.broadcast();
  static bool _listenersInstalled = false;
  static bool _windowFocused = true;
  static bool _lastKnownState = _computeBackgrounded();

  _WebBrowserBackgroundBridge() {
    _installListeners();
  }

  @override
  bool get supported => true;

  @override
  bool get isBackgrounded => _computeBackgrounded();

  @override
  Stream<bool> get changes => _controller.stream.distinct();

  static bool _computeBackgrounded() {
    final hidden = html.document.hidden ?? false;
    return hidden || !_windowFocused;
  }

  static void _installListeners() {
    if (_listenersInstalled) {
      return;
    }
    _listenersInstalled = true;

    void emitCurrent() {
      final current = _computeBackgrounded();
      if (current == _lastKnownState) {
        return;
      }
      _lastKnownState = current;
      _controller.add(current);
    }

    html.document.onVisibilityChange.listen((_) => emitCurrent());
    html.window.onFocus.listen((_) {
      _windowFocused = true;
      emitCurrent();
    });
    html.window.onBlur.listen((_) {
      _windowFocused = false;
      emitCurrent();
    });
  }
}

BrowserBackgroundBridge createPlatformBrowserBackgroundBridge() =>
    _WebBrowserBackgroundBridge();

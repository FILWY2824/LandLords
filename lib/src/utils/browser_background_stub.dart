import 'dart:async';

import 'browser_background.dart';

class _StubBrowserBackgroundBridge implements BrowserBackgroundBridge {
  @override
  bool get supported => false;

  @override
  bool get isBackgrounded => false;

  @override
  Stream<bool> get changes => const Stream<bool>.empty();
}

BrowserBackgroundBridge createPlatformBrowserBackgroundBridge() =>
    _StubBrowserBackgroundBridge();

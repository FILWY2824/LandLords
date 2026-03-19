import 'browser_background_stub.dart'
    if (dart.library.js_interop) 'browser_background_web.dart';

abstract class BrowserBackgroundBridge {
  bool get supported;
  bool get isBackgrounded;
  Stream<bool> get changes;
}

BrowserBackgroundBridge createBrowserBackgroundBridge() =>
    createPlatformBrowserBackgroundBridge();

import 'dart:async';
import 'dart:io';

Future<void> main(List<String> args) async {
  final options = _ServerOptions.parse(args);
  final webRoot = Directory(options.webRoot);
  if (!await webRoot.exists()) {
    stderr.writeln(
      '[${_timestamp()}][ERROR][web_public] web root not found: ${webRoot.path}',
    );
    exitCode = 1;
    return;
  }

  final server = await HttpServer.bind(options.host, options.port);
  stdout.writeln(
    '[${_timestamp()}][INFO][web_public] listening on http://${options.host}:${options.port}',
  );
  stdout.writeln(
    '[${_timestamp()}][INFO][web_public] web root=${webRoot.path}',
  );
  stdout.writeln(
    '[${_timestamp()}][INFO][web_public] proxy /ws -> ${options.backendWs}',
  );

  Future<void> closeServer() async {
    stdout.writeln('[${_timestamp()}][INFO][web_public] shutting down');
    await server.close(force: true);
  }

  _tryWatchSignal(ProcessSignal.sigint, closeServer);
  _tryWatchSignal(ProcessSignal.sigterm, closeServer);

  await for (final request in server) {
    unawaited(_handleRequest(request, options, webRoot));
  }
}

Future<void> _handleRequest(
  HttpRequest request,
  _ServerOptions options,
  Directory webRoot,
) async {
  try {
    if (request.uri.path == '/ws') {
      await _handleWebSocketProxy(request, options.backendWs);
      return;
    }
    if (request.method != 'GET' && request.method != 'HEAD') {
      _sendText(
        request.response,
        HttpStatus.methodNotAllowed,
        'Method Not Allowed',
      );
      _logAccess(request, HttpStatus.methodNotAllowed);
      return;
    }
    final file = await _resolveAssetFile(request.uri, webRoot);
    if (file == null) {
      _sendText(request.response, HttpStatus.forbidden, 'Forbidden');
      _logAccess(request, HttpStatus.forbidden);
      return;
    }
    final exists = await file.exists();
    final effectiveFile = exists
        ? file
        : File('${webRoot.path}${Platform.pathSeparator}index.html');
    if (!await effectiveFile.exists()) {
      _sendText(request.response, HttpStatus.notFound, 'Not Found');
      _logAccess(request, HttpStatus.notFound);
      return;
    }
    await _serveFile(request, effectiveFile);
    _logAccess(request, HttpStatus.ok);
  } catch (error, stackTrace) {
    stderr.writeln(
      '[${_timestamp()}][ERROR][web_public] request ${request.method} ${request.uri} failed: $error',
    );
    stderr.writeln(stackTrace);
    try {
      _sendText(
        request.response,
        HttpStatus.internalServerError,
        'Internal Server Error',
      );
    } catch (_) {
    }
    _logAccess(request, HttpStatus.internalServerError);
  }
}

Future<void> _handleWebSocketProxy(
  HttpRequest request,
  String backendWs,
) async {
  WebSocket? clientSocket;
  WebSocket? backendSocket;
  StreamSubscription<dynamic>? clientSub;
  StreamSubscription<dynamic>? backendSub;
  try {
    clientSocket = await WebSocketTransformer.upgrade(request);
    backendSocket = await WebSocket.connect(backendWs);
    stdout.writeln(
      '[${_timestamp()}][INFO][web_public] websocket connected client=${request.connectionInfo?.remoteAddress.address ?? "-"} target=$backendWs',
    );

    clientSub = clientSocket.listen(
      (data) {
        backendSocket?.add(data);
      },
      onDone: () {
        backendSocket?.close(clientSocket?.closeCode, clientSocket?.closeReason);
      },
      onError: (Object error, StackTrace stackTrace) {
        stderr.writeln(
          '[${_timestamp()}][WARN][web_public] client websocket error: $error',
        );
        stderr.writeln(stackTrace);
        backendSocket?.close(WebSocketStatus.internalServerError, 'client_error');
      },
      cancelOnError: true,
    );

    backendSub = backendSocket.listen(
      (data) {
        clientSocket?.add(data);
      },
      onDone: () {
        clientSocket?.close(
          backendSocket?.closeCode,
          backendSocket?.closeReason,
        );
      },
      onError: (Object error, StackTrace stackTrace) {
        stderr.writeln(
          '[${_timestamp()}][WARN][web_public] backend websocket error: $error',
        );
        stderr.writeln(stackTrace);
        clientSocket?.close(WebSocketStatus.internalServerError, 'backend_error');
      },
      cancelOnError: true,
    );

    await Future.any<void>([
      clientSub.asFuture<void>(),
      backendSub.asFuture<void>(),
    ]);
  } catch (error, stackTrace) {
    stderr.writeln(
      '[${_timestamp()}][ERROR][web_public] websocket proxy failed: $error',
    );
    stderr.writeln(stackTrace);
    if (clientSocket == null) {
      try {
        request.response.statusCode = HttpStatus.badGateway;
        request.response.write('WebSocket proxy unavailable');
        await request.response.close();
      } catch (_) {
      }
    } else {
      await clientSocket.close(WebSocketStatus.internalServerError, 'proxy_failed');
    }
  } finally {
    await clientSub?.cancel();
    await backendSub?.cancel();
    await clientSocket?.close();
    await backendSocket?.close();
  }
}

Future<File?> _resolveAssetFile(Uri uri, Directory webRoot) async {
  final segments = uri.pathSegments
      .where((segment) => segment.isNotEmpty)
      .toList(growable: false);
  if (segments.any((segment) => segment == '..')) {
    return null;
  }
  if (segments.isEmpty) {
    return File('${webRoot.path}${Platform.pathSeparator}index.html');
  }
  var path = webRoot.path;
  for (final segment in segments) {
    path = '$path${Platform.pathSeparator}$segment';
  }
  return File(path);
}

Future<void> _serveFile(HttpRequest request, File file) async {
  final response = request.response;
  final extension = file.path.split('.').last.toLowerCase();
  final contentType = _contentType(extension);
  if (contentType != null) {
    response.headers.contentType = contentType;
  }
  response.headers.set(HttpHeaders.cacheControlHeader, 'no-cache');
  response.headers.set('X-Content-Type-Options', 'nosniff');
  response.statusCode = HttpStatus.ok;
  if (request.method == 'HEAD') {
    await response.close();
    return;
  }
  await response.addStream(file.openRead());
  await response.close();
}

void _sendText(HttpResponse response, int statusCode, String body) {
  response.statusCode = statusCode;
  response.headers.contentType = ContentType.text;
  response.write(body);
  unawaited(response.close());
}

void _logAccess(HttpRequest request, int statusCode) {
  stdout.writeln(
    '[${_timestamp()}][INFO][web_public] ${request.method} ${request.uri.path}${request.uri.hasQuery ? "?${request.uri.query}" : ""} -> $statusCode',
  );
}

ContentType? _contentType(String extension) {
  switch (extension) {
    case 'html':
      return ContentType.html;
    case 'css':
      return ContentType('text', 'css', charset: 'utf-8');
    case 'js':
      return ContentType('application', 'javascript', charset: 'utf-8');
    case 'json':
      return ContentType.json;
    case 'wasm':
      return ContentType('application', 'wasm');
    case 'png':
      return ContentType('image', 'png');
    case 'jpg':
    case 'jpeg':
      return ContentType('image', 'jpeg');
    case 'svg':
      return ContentType('image', 'svg+xml');
    case 'ico':
      return ContentType('image', 'x-icon');
    case 'ttf':
      return ContentType('font', 'ttf');
    case 'woff':
      return ContentType('font', 'woff');
    case 'woff2':
      return ContentType('font', 'woff2');
    case 'mp3':
      return ContentType('audio', 'mpeg');
    default:
      return null;
  }
}

String _timestamp() {
  final now = DateTime.now();
  String two(int value) => value.toString().padLeft(2, '0');
  String three(int value) => value.toString().padLeft(3, '0');
  return '${two(now.hour)}:${two(now.minute)}:${two(now.second)}.${three(now.millisecond)}';
}

class _ServerOptions {
  _ServerOptions({
    required this.host,
    required this.port,
    required this.webRoot,
    required this.backendWs,
  });

  final String host;
  final int port;
  final String webRoot;
  final String backendWs;

  static _ServerOptions parse(List<String> args) {
    String host = '0.0.0.0';
    int port = 23000;
    String webRoot = 'build${Platform.pathSeparator}web';
    String backendWs = 'ws://127.0.0.1:23002/ws';

    for (var index = 0; index < args.length; index += 1) {
      final arg = args[index];
      if (arg == '--help' || arg == '-h') {
        stdout.writeln(
          'Usage: dart tool/web_public_server.dart [--host HOST] [--port PORT] [--web-root PATH] [--backend-ws URL]',
        );
        exit(0);
      }
      if (!arg.startsWith('--')) {
        continue;
      }
      final value = index + 1 < args.length ? args[index + 1] : '';
      switch (arg) {
        case '--host':
          host = value;
          index += 1;
        case '--port':
          port = int.tryParse(value) ?? port;
          index += 1;
        case '--web-root':
          webRoot = value;
          index += 1;
        case '--backend-ws':
          backendWs = value;
          index += 1;
      }
    }
    return _ServerOptions(
      host: host,
      port: port,
      webRoot: webRoot,
      backendWs: backendWs,
    );
  }
}

void _tryWatchSignal(ProcessSignal signal, Future<void> Function() onSignal) {
  if (Platform.isWindows) {
    return;
  }
  try {
    signal.watch().listen((_) {
      unawaited(onSignal());
    });
  } catch (_) {
  }
}

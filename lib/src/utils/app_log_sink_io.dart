import 'dart:io';

File? _appLogFile;
Future<void> _pendingWrite = Future<void>.value();

Directory _resolveRuntimeLogDirectory() {
  final executable = File(Platform.resolvedExecutable);
  final executableDir = executable.parent;
  return Directory(
    '${executableDir.path}${Platform.pathSeparator}runtime_logs',
  );
}

Future<void> writePlatformAppLogLine(String line) async {
  _pendingWrite = _pendingWrite.then((_) async {
    try {
      final file = await _resolveAppLogFile();
      await file.writeAsString('$line\n', mode: FileMode.append, flush: true);
    } catch (_) {
      // Avoid recursive failures when the logger itself cannot write.
    }
  });
  await _pendingWrite;
}

Future<File> _resolveAppLogFile() async {
  if (_appLogFile != null) {
    return _appLogFile!;
  }
  final directory = _resolveRuntimeLogDirectory();
  if (!await directory.exists()) {
    await directory.create(recursive: true);
  }
  final file = File('${directory.path}${Platform.pathSeparator}dart_ui.log');
  if (!await file.exists()) {
    await file.create(recursive: true);
  }
  _appLogFile = file;
  return file;
}

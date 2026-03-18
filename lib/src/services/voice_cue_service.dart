import 'dart:async';
import 'dart:collection';

import 'voice_backend.dart';

class VoiceCueService {
  VoiceCueService({VoiceBackend? backend}) : _backend = backend ?? createVoiceBackend();

  final VoiceBackend _backend;
  final Queue<_QueuedLine> _queue = Queue<_QueuedLine>();
  final Queue<String> _recentActionIds = Queue<String>();
  bool _processing = false;
  bool _bgmStarted = false;
  int _generation = 0;
  _QueuedLine? _activeItem;

  Future<void> enqueueAction(String actionId, String line) {
    return _enqueueLine(actionId, line).done.future;
  }

  Future<void> enqueueActionAndWaitForStart(String actionId, String line) {
    return _enqueueLine(actionId, line).started.future;
  }

  _QueuedLine _enqueueLine(String actionId, String line) {
    if (actionId.isEmpty || line.isEmpty || _recentActionIds.contains(actionId)) {
      final completed = _QueuedLine(
        line: line,
        started: Completer<void>()..complete(),
        done: Completer<void>()..complete(),
      );
      return completed;
    }
    _recentActionIds.add(actionId);
    while (_recentActionIds.length > 96) {
      _recentActionIds.removeFirst();
    }
    final item = _QueuedLine(
      line: line,
      started: Completer<void>(),
      done: Completer<void>(),
    );
    _queue.add(item);
    if (!_processing) {
      unawaited(_drainQueue());
    }
    return item;
  }

  Future<void> _drainQueue() async {
    _processing = true;
    try {
      while (_queue.isNotEmpty) {
        final item = _queue.removeFirst();
        final generation = _generation;
        _activeItem = item;
        await _backend.speak(item.line);
        if (!item.started.isCompleted) {
          item.started.complete();
        }
        await _waitForPresentationWindow(item.line, generation);
        if (!item.done.isCompleted) {
          item.done.complete();
        }
        _activeItem = null;
      }
    } finally {
      _processing = false;
      _activeItem = null;
      while (_queue.isNotEmpty) {
        final pending = _queue.removeFirst();
        if (!pending.started.isCompleted) {
          pending.started.complete();
        }
        if (!pending.done.isCompleted) {
          pending.done.complete();
        }
      }
    }
  }

  Future<void> playErrorCue(String line) async {
    await _backend.playErrorEffect();
    await speakNow(line);
  }

  Future<void> speakNow(String line) async {
    if (line.isEmpty) {
      return;
    }
    _generation += 1;
    while (_queue.isNotEmpty) {
      final pending = _queue.removeFirst();
      if (!pending.started.isCompleted) {
        pending.started.complete();
      }
      if (!pending.done.isCompleted) {
        pending.done.complete();
      }
    }
    if (_activeItem != null) {
      if (!_activeItem!.started.isCompleted) {
        _activeItem!.started.complete();
      }
      if (!_activeItem!.done.isCompleted) {
        _activeItem!.done.complete();
      }
    }
    await _backend.stopSpeech();
    await _backend.speak(line);
  }

  Future<void> startBackgroundMusic() async {
    _bgmStarted = true;
    await _backend.startBackgroundMusic();
  }

  Future<void> stopBackgroundMusic() async {
    if (!_bgmStarted) {
      return;
    }
    _bgmStarted = false;
    await _backend.stopBackgroundMusic();
  }

  void clearPending({bool clearRecentActionIds = false}) {
    _queue.clear();
    if (clearRecentActionIds) {
      _recentActionIds.clear();
    }
  }

  Future<void> interruptSpeech({bool clearRecentActionIds = false}) async {
    _generation += 1;
    while (_queue.isNotEmpty) {
      final pending = _queue.removeFirst();
      if (!pending.started.isCompleted) {
        pending.started.complete();
      }
      if (!pending.done.isCompleted) {
        pending.done.complete();
      }
    }
    if (_activeItem != null) {
      if (!_activeItem!.started.isCompleted) {
        _activeItem!.started.complete();
      }
      if (!_activeItem!.done.isCompleted) {
        _activeItem!.done.complete();
      }
    }
    if (clearRecentActionIds) {
      _recentActionIds.clear();
    }
    await _backend.stopSpeech();
  }

  Future<void> dispose() async {
    _queue.clear();
    await _backend.stopSpeech();
    await stopBackgroundMusic();
    await _backend.dispose();
  }

  Future<void> _waitForPresentationWindow(String line, int generation) async {
    final total = _estimatedSpeechDuration(line);
    var elapsed = Duration.zero;
    while (elapsed < total) {
      if (_generation != generation) {
        return;
      }
      const step = Duration(milliseconds: 40);
      final remaining = total - elapsed;
      final currentStep = remaining < step ? remaining : step;
      await Future<void>.delayed(currentStep);
      elapsed += currentStep;
    }
  }

  Duration _estimatedSpeechDuration(String line) {
    final visibleChars = line.replaceAll(RegExp(r'\s+'), '').runes.length;
    final estimatedMs = (180 + visibleChars * 55).clamp(220, 720);
    return Duration(milliseconds: estimatedMs);
  }
}

class _QueuedLine {
  const _QueuedLine({
    required this.line,
    required this.started,
    required this.done,
  });

  final String line;
  final Completer<void> started;
  final Completer<void> done;
}

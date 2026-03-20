// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:math' as math;
import 'dart:typed_data';

import '../utils/app_log.dart';
import 'voice_backend.dart';

class _WebVoiceBackend implements VoiceBackend {
  static final String _bgmAssetUrl =
      Uri.base.resolve('assets/assets/audio/background_music.mp3').toString();
  static html.AudioElement? _sharedBgm;
  static html.AudioElement? _sharedErrorAudio;
  static final List<StreamSubscription<html.Event>> _unlockSubscriptions = [];
  static bool _bgmRequested = false;
  static bool _unlockHooksInstalled = false;
  static bool _bgmDiagnosticsInstalled = false;
  static bool _bgmLoaded = false;
  static bool _speechPrimed = false;
  static Timer? _bgmDuckTimer;

  html.AudioElement? _bgm;
  html.AudioElement? _errorAudio;

  @override
  bool get reportsSpeechCompletion => true;

  @override
  Future<void> speak(String line) async {
    try {
      final synthesis = html.window.speechSynthesis;
      if (synthesis == null) {
        return;
      }
      await _primeSpeechSynthesis(withSilentUtterance: true);
      _duckBackgroundMusic();
      var completed = await _speakOnce(synthesis, line);
      if (!completed) {
        await Future<void>.delayed(const Duration(milliseconds: 120));
        await _primeSpeechSynthesis(withSilentUtterance: true);
        completed = await _speakOnce(synthesis, line);
      }
      if (!completed) {
        appLog(
          AppLogLevel.warn,
          'voice_web',
          'speech did not start, waiting for another user gesture',
        );
        _installUnlockHooks();
      }
    } catch (error) {
      appLog(AppLogLevel.warn, 'voice_web', 'speech failed: $error');
      _installUnlockHooks();
      // Ignore browser speech failures.
    } finally {
      _restoreBackgroundMusicVolume();
    }
  }

  @override
  Future<void> stopSpeech() async {
    try {
      html.window.speechSynthesis?.cancel();
      _restoreBackgroundMusicVolume();
    } catch (_) {
      // Ignore browser cleanup failures.
    }
  }

  @override
  Future<void> playErrorEffect() async {
    try {
      final audio =
          _errorAudio ??=
              _sharedErrorAudio ??=
                  html.AudioElement(_errorEffectDataUri())
                    ..preload = 'auto'
                    ..setAttribute('playsinline', 'true')
                    ..volume = 0.72;
      audio.pause();
      audio.currentTime = 0;
      await audio.play();
    } catch (error) {
      appLog(AppLogLevel.warn, 'voice_web', 'error effect blocked: $error');
      // Ignore browser audio failures.
    }
  }

  @override
  Future<void> startBackgroundMusic() async {
    _bgmRequested = true;
    final created = _sharedBgm == null;
    final audio =
        _bgm ??=
            _sharedBgm ??=
                html.AudioElement(_bgmAssetUrl)
                  ..loop = true
                  ..preload = 'auto'
                  ..setAttribute('playsinline', 'true')
                  ..volume = 0.30;
    await _primeSpeechSynthesis(withSilentUtterance: false);
    _installBgmDiagnostics(audio);
    if (created || !_bgmLoaded || audio.currentSrc.isEmpty) {
      audio.load();
      _bgmLoaded = true;
      appLog(
        AppLogLevel.info,
        'voice_web',
        'background music loaded src=${audio.src}',
      );
    }
    appLog(
      AppLogLevel.info,
      'voice_web',
      'startBackgroundMusic src=${audio.src} paused=${audio.paused} readyState=${audio.readyState}',
    );
    await _tryStartBackgroundMusic(audio);
  }

  @override
  Future<void> stopBackgroundMusic() async {
    _bgmRequested = false;
    _removeUnlockHooks();
    try {
      _sharedBgm?.pause();
      _sharedBgm?.currentTime = 0;
      _restoreBackgroundMusicVolume();
    } catch (error) {
      appLog(AppLogLevel.warn, 'voice_web', 'stop bgm failed: $error');
      // Ignore browser cleanup failures.
    }
  }

  @override
  Future<void> dispose() async {
    try {
      await stopSpeech();
      _removeUnlockHooks();
    } catch (_) {
      // Ignore browser cleanup failures.
    }
  }

  Future<void> _tryStartBackgroundMusic(html.AudioElement audio) async {
    if (!_bgmRequested) {
      return;
    }
    try {
      audio.muted = false;
      if (audio.paused) {
        await audio.play();
      } else {
        appLog(
          AppLogLevel.debug,
          'voice_web',
          'background music already playing currentTime=${audio.currentTime}',
        );
      }
      _removeUnlockHooks();
      appLog(AppLogLevel.info, 'voice_web', 'background music started');
    } catch (error) {
      appLog(
        AppLogLevel.info,
        'voice_web',
        'background music waiting for user gesture: $error',
      );
      try {
        audio
          ..muted = true
          ..volume = 0.30;
        if (audio.paused) {
          await audio.play();
        }
        audio.muted = false;
        _removeUnlockHooks();
        appLog(
          AppLogLevel.info,
          'voice_web',
          'background music started via muted bootstrap',
        );
        return;
      } catch (bootstrapError) {
        audio.muted = false;
        appLog(
          AppLogLevel.info,
          'voice_web',
          'background music bootstrap failed: $bootstrapError',
        );
      }
      _installUnlockHooks();
    }
  }

  void _installUnlockHooks() {
    if (_unlockHooksInstalled) {
      return;
    }
    _unlockHooksInstalled = true;
    void register(Stream<html.Event> stream) {
      _unlockSubscriptions.add(stream.listen((_) {
        unawaited(_primeSpeechSynthesis(withSilentUtterance: true));
        if (_bgmRequested && _bgm != null) {
          unawaited(_tryStartBackgroundMusic(_bgm!));
        }
      }));
    }

    register(html.document.onMouseDown);
    register(html.document.onClick);
    register(html.document.onTouchStart);
    register(html.document.onKeyDown);
    register(html.window.onFocus);
    register(html.document.onVisibilityChange);
  }

  void _removeUnlockHooks() {
    if (!_unlockHooksInstalled) {
      return;
    }
    for (final subscription in _unlockSubscriptions) {
      subscription.cancel();
    }
    _unlockSubscriptions.clear();
    _unlockHooksInstalled = false;
  }

  void _installBgmDiagnostics(html.AudioElement audio) {
    if (_bgmDiagnosticsInstalled) {
      return;
    }
    _bgmDiagnosticsInstalled = true;
    audio.onLoadedMetadata.listen((_) {
      appLog(
        AppLogLevel.info,
        'voice_web',
        'bgm metadata loaded duration=${audio.duration} readyState=${audio.readyState}',
      );
    });
    audio.onCanPlay.listen((_) {
      appLog(
        AppLogLevel.info,
        'voice_web',
        'bgm canplay readyState=${audio.readyState} networkState=${audio.networkState}',
      );
    });
    audio.onPlaying.listen((_) {
      appLog(
        AppLogLevel.info,
        'voice_web',
        'bgm playing currentTime=${audio.currentTime}',
      );
    });
    audio.onPause.listen((_) {
      appLog(
        AppLogLevel.info,
        'voice_web',
        'bgm paused currentTime=${audio.currentTime}',
      );
    });
    audio.onError.listen((_) {
      appLog(
        AppLogLevel.error,
        'voice_web',
        'bgm error code=${audio.error?.code} readyState=${audio.readyState} '
        'networkState=${audio.networkState} src=${audio.currentSrc}',
      );
    });
  }

  Future<void> _primeSpeechSynthesis({
    required bool withSilentUtterance,
  }) async {
    final synthesis = html.window.speechSynthesis;
    if (synthesis == null) {
      return;
    }
    try {
      synthesis.resume();
      if (_speechPrimed || !withSilentUtterance) {
        _speechPrimed = true;
        return;
      }
      final utterance = html.SpeechSynthesisUtterance('\u00A0')
        ..lang = 'zh-CN'
        ..volume = 0
        ..rate = 1
        ..pitch = 1;
      final completer = Completer<void>();
      utterance.onEnd.first.then((_) {
        if (!completer.isCompleted) {
          completer.complete();
        }
      });
      utterance.onError.first.then((_) {
        if (!completer.isCompleted) {
          completer.complete();
        }
      });
      synthesis.cancel();
      synthesis.speak(utterance);
      await completer.future.timeout(
        const Duration(milliseconds: 260),
        onTimeout: () {},
      );
      _speechPrimed = true;
      appLog(AppLogLevel.info, 'voice_web', 'speech synthesis primed');
    } catch (error) {
      appLog(AppLogLevel.warn, 'voice_web', 'speech prime failed: $error');
    }
  }

  html.SpeechSynthesisVoice? _pickPreferredVoice(
    html.SpeechSynthesis synthesis,
  ) {
    final voices = synthesis.getVoices();
    for (final voice in voices) {
      final lang = voice.lang ?? '';
      if (lang == 'zh-CN' || lang.startsWith('zh')) {
        return voice;
      }
    }
    return voices.isNotEmpty ? voices.first : null;
  }

  Future<bool> _speakOnce(
    html.SpeechSynthesis synthesis,
    String line,
  ) async {
    final utterance = html.SpeechSynthesisUtterance(line)
      ..lang = 'zh-CN'
      ..rate = 0.96
      ..pitch = 1.0
      ..volume = 1.0;
    final voice = _pickPreferredVoice(synthesis);
    if (voice != null) {
      utterance.voice = voice;
    }

    final started = Completer<void>();
    final completed = Completer<bool>();
    var didStart = false;
    utterance.onStart.first.then((_) {
      didStart = true;
      if (!started.isCompleted) {
        started.complete();
      }
    });
    utterance.onError.first.then((_) {
      if (!started.isCompleted) {
        started.complete();
      }
      if (!completed.isCompleted) {
        completed.complete(false);
      }
    });
    utterance.onEnd.first.then((_) {
      if (!started.isCompleted) {
        started.complete();
      }
      if (!completed.isCompleted) {
        completed.complete(true);
      }
    });

    synthesis.cancel();
    synthesis.resume();
    synthesis.speak(utterance);
    await started.future.timeout(
      const Duration(milliseconds: 420),
      onTimeout: () {},
    );
    return completed.future.timeout(
      _speechTimeout(line),
      onTimeout: () async {
        final deadline = DateTime.now().add(const Duration(seconds: 4));
        while ((synthesis.speaking ?? false) || (synthesis.pending ?? false)) {
          if (DateTime.now().isAfter(deadline)) {
            appLog(
              AppLogLevel.warn,
              'voice_web',
              'speech timed out while still speaking line=$line',
            );
            break;
          }
          await Future<void>.delayed(const Duration(milliseconds: 80));
        }
        return didStart;
      },
    );
  }

  Duration _speechTimeout(String line) {
    final visibleChars = line.replaceAll(RegExp(r'\s+'), '').runes.length;
    final estimatedMs = (900 + visibleChars * 260).clamp(1800, 6000);
    return Duration(milliseconds: estimatedMs);
  }

  void _duckBackgroundMusic() {
    final audio = _sharedBgm;
    if (audio == null || audio.paused) {
      return;
    }
    audio.volume = 0.12;
    _bgmDuckTimer?.cancel();
    _bgmDuckTimer = Timer(
      const Duration(milliseconds: 1200),
      _restoreBackgroundMusicVolume,
    );
  }

  void _restoreBackgroundMusicVolume() {
    _bgmDuckTimer?.cancel();
    _bgmDuckTimer = null;
    final audio = _sharedBgm;
    if (audio == null) {
      return;
    }
    audio.volume = 0.30;
  }
}

VoiceBackend createPlatformVoiceBackend() => _WebVoiceBackend();

String _errorEffectDataUri() {
  const sampleRate = 22050;
  const durationMs = 180;
  final sampleCount = sampleRate * durationMs ~/ 1000;
  final dataSize = sampleCount * 2;
  final bytes = ByteData(44 + dataSize);

  void writeString(int offset, String value) {
    for (var index = 0; index < value.length; index++) {
      bytes.setUint8(offset + index, value.codeUnitAt(index));
    }
  }

  writeString(0, 'RIFF');
  bytes.setUint32(4, 36 + dataSize, Endian.little);
  writeString(8, 'WAVE');
  writeString(12, 'fmt ');
  bytes.setUint32(16, 16, Endian.little);
  bytes.setUint16(20, 1, Endian.little);
  bytes.setUint16(22, 1, Endian.little);
  bytes.setUint32(24, sampleRate, Endian.little);
  bytes.setUint32(28, sampleRate * 2, Endian.little);
  bytes.setUint16(32, 2, Endian.little);
  bytes.setUint16(34, 16, Endian.little);
  writeString(36, 'data');
  bytes.setUint32(40, dataSize, Endian.little);

  for (var index = 0; index < sampleCount; index++) {
    final t = index / sampleRate;
    final attack = math.min(1.0, index / (sampleCount * 0.18));
    final release = math.max(
      0.0,
      (sampleCount - index) / (sampleCount * 0.82),
    );
    final envelope = math.min(attack, release);
    final sample = (math.sin(2 * math.pi * 520 * t) * envelope * 0.55 * 32767)
        .round()
        .clamp(-32767, 32767);
    bytes.setInt16(44 + index * 2, sample, Endian.little);
  }

  return 'data:audio/wav;base64,${base64Encode(bytes.buffer.asUint8List())}';
}

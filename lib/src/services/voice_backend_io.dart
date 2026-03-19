import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'voice_backend.dart';

class _ChannelVoiceBackend implements VoiceBackend {
  static const MethodChannel _channel = MethodChannel('landlords/voice');

  @override
  bool get reportsSpeechCompletion =>
      defaultTargetPlatform == TargetPlatform.android;

  @override
  Future<void> speak(String line) async {
    try {
      await _channel.invokeMethod<void>('speak', <String, Object?>{
        'text': line,
      });
    } catch (_) {
      // Keep gameplay responsive if native TTS is unavailable.
    }
  }

  @override
  Future<void> stopSpeech() async {
    try {
      await _channel.invokeMethod<void>('stop');
    } catch (_) {
      // Ignore stop failures.
    }
  }

  @override
  Future<void> playErrorEffect() async {
    try {
      await _channel.invokeMethod<void>('playErrorEffect');
    } catch (_) {
      // Keep gameplay responsive if native audio is unavailable.
    }
  }

  @override
  Future<void> startBackgroundMusic() async {
    try {
      await _channel.invokeMethod<void>('startBackgroundMusic');
    } catch (_) {
      // Keep gameplay responsive if native audio is unavailable.
    }
  }

  @override
  Future<void> stopBackgroundMusic() async {
    try {
      await _channel.invokeMethod<void>('stopBackgroundMusic');
    } catch (_) {
      // Ignore cleanup failures.
    }
  }

  @override
  Future<void> dispose() async {
    await stopSpeech();
    await stopBackgroundMusic();
  }
}

VoiceBackend createPlatformVoiceBackend() => _ChannelVoiceBackend();

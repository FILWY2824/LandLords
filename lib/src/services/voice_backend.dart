import 'voice_backend_stub.dart'
    if (dart.library.io) 'voice_backend_io.dart'
    if (dart.library.js_interop) 'voice_backend_web.dart';

abstract class VoiceBackend {
  Future<void> speak(String line);
  Future<void> stopSpeech();
  Future<void> playErrorEffect();
  Future<void> startBackgroundMusic();
  Future<void> stopBackgroundMusic();
  Future<void> dispose();
}

VoiceBackend createVoiceBackend() => createPlatformVoiceBackend();

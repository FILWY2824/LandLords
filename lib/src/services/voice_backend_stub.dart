import 'voice_backend.dart';

class _StubVoiceBackend implements VoiceBackend {
  @override
  Future<void> dispose() async {}

  @override
  Future<void> playErrorEffect() async {}

  @override
  Future<void> speak(String line) async {}

  @override
  Future<void> stopSpeech() async {}

  @override
  Future<void> startBackgroundMusic() async {}

  @override
  Future<void> stopBackgroundMusic() async {}
}

VoiceBackend createPlatformVoiceBackend() => _StubVoiceBackend();

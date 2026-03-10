/// Manages microphone audio capture and streams PCM frames to the DSP layer.
/// Full implementation in Phase 3.
abstract class AudioEngine {
  Stream<List<int>> get pcmStream;
  Future<void> start();
  Future<void> stop();
  void dispose();
}

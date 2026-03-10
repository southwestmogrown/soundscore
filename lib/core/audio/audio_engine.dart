import 'dart:async';
import 'dart:typed_data';

import 'package:record/record.dart';

/// Manages microphone audio capture and streams PCM frames to the DSP layer.
abstract class AudioEngine {
  Stream<Int16List> get pcmStream;
  Future<void> start();
  Future<void> stop();
  void dispose();
}

/// Concrete implementation using the `record` package.
///
/// Captures 44100 Hz mono 16-bit PCM from the device microphone and emits
/// non-overlapping [Int16List] chunks of [frameSize] samples via [pcmStream].
class RecordAudioEngine implements AudioEngine {
  static const int sampleRate = 44100;
  static const int frameSize  = 2048;

  final AudioRecorder _recorder = AudioRecorder();
  StreamController<Int16List>? _controller;
  StreamSubscription<Uint8List>? _rawSub;

  // Accumulate raw bytes until we have a full frame
  final _buffer = <int>[];

  @override
  Stream<Int16List> get pcmStream {
    _controller ??= StreamController<Int16List>.broadcast();
    return _controller!.stream;
  }

  @override
  Future<void> start() async {
    _controller ??= StreamController<Int16List>.broadcast();
    _buffer.clear();

    final rawStream = await _recorder.startStream(
      const RecordConfig(
        encoder:    AudioEncoder.pcm16bits,
        sampleRate: sampleRate,
        numChannels: 1,
      ),
    );

    _rawSub = rawStream.listen(_onBytes, onError: _controller!.addError);
  }

  void _onBytes(Uint8List bytes) {
    _buffer.addAll(bytes);

    // Each PCM16 sample is 2 bytes → frameSize samples = frameSize * 2 bytes
    const frameBytes = frameSize * 2;
    while (_buffer.length >= frameBytes) {
      final chunk = Uint8List.fromList(_buffer.sublist(0, frameBytes));
      _buffer.removeRange(0, frameBytes);

      // Reinterpret as Int16 (little-endian, as produced by the record pkg)
      final frame = chunk.buffer.asInt16List();
      _controller!.add(frame);
    }
  }

  @override
  Future<void> stop() async {
    await _rawSub?.cancel();
    _rawSub = null;
    await _recorder.stop();
    _buffer.clear();
  }

  @override
  void dispose() {
    _rawSub?.cancel();
    _controller?.close();
    _recorder.dispose();
  }
}

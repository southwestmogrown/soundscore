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

  late final AudioRecorder? _recorder;
  StreamController<Int16List>? _controller;
  StreamSubscription<Uint8List>? _rawSub;

  // Accumulate raw bytes until we have a full frame
  final _buffer = Uint8List(frameSize * 2);
  int _bufferHead = 0;

  @override
  Stream<Int16List> get pcmStream {
    _controller ??= StreamController<Int16List>.broadcast();
    return _controller!.stream;
  }

  @override
  Future<void> start() async {
    _controller ??= StreamController<Int16List>.broadcast();
    _bufferHead = 0;
    _recorder ??= AudioRecorder();

    final rawStream = await _recorder!.startStream(
      const RecordConfig(
        encoder:    AudioEncoder.pcm16bits,
        sampleRate: sampleRate,
        numChannels: 1,
      ),
    );

    _rawSub = rawStream.listen(_onBytes, onError: _controller!.addError);
  }

  void _onBytes(Uint8List bytes) {
    for (final b in bytes) {
      _buffer[_bufferHead] = b;
      _bufferHead++;

      if (_bufferHead == _buffer.length) {
        // Reinterpret as Int16 (little-endian, as produced by the record pkg)
        final frame = _buffer.buffer.asInt16List();
        _controller!.add(frame);
        _bufferHead = 0;
      }
    }
  }

  @override
  Future<void> stop() async {
    await _rawSub?.cancel();
    _rawSub = null;
    await _recorder?.stop();
    _bufferHead = 0;
    _controller?.close();
    _controller = null;
  }

  @override
  void dispose() {
    _rawSub?.cancel();
    _controller?.close();
    _recorder?.dispose();
  }
}

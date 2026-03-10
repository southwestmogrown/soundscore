import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import '../dsp/pitch_result.dart';

// ── Native struct layout ─────────────────────────────────────────────────────
// Must match SoundScorePitchResult in soundscore_dsp.h exactly.
final class _NativePitchResult extends Struct {
  @Float()
  external double frequency;

  @Int32()
  external int midiNote;

  @Float()
  external double confidence;

  @Int32()
  external int isOnset;
}

// ── Native function signatures ────────────────────────────────────────────────
typedef _CreateNative = Pointer<Void> Function(Int32 sampleRate, Int32 frameSize);
typedef _CreateDart   = Pointer<Void> Function(int sampleRate, int frameSize);

typedef _DestroyNative = Void Function(Pointer<Void> ctx);
typedef _DestroyDart   = void Function(Pointer<Void> ctx);

typedef _ProcessNative = _NativePitchResult Function(
    Pointer<Void> ctx, Pointer<Int16> samples, Int32 numSamples);
typedef _ProcessDart   = _NativePitchResult Function(
    Pointer<Void> ctx, Pointer<Int16> samples, int numSamples);

typedef _GetBpmNative = Float Function(Pointer<Void> ctx);
typedef _GetBpmDart   = double Function(Pointer<Void> ctx);

typedef _ResetNative = Void Function(Pointer<Void> ctx);
typedef _ResetDart   = void Function(Pointer<Void> ctx);

// ── Isolate message protocol ─────────────────────────────────────────────────
// Main → DSP isolate:
//   Int16List  → audio frame to process
//   'reset'    → reset the DSP context
//   SendPort   → handshake (first message)
//
// DSP isolate → Main:
//   List<dynamic> [freq, midiNote, confidence, isOnset, bpm, chordLabel]

class _IsolateInit {
  final SendPort replyPort;
  const _IsolateInit(this.replyPort);
}

/// Entry point for the DSP isolate. Runs entirely on a separate thread.
void _dspIsolateMain(SendPort mainSendPort) {
  final receivePort = ReceivePort();

  // Send our port back so main can talk to us
  mainSendPort.send(receivePort.sendPort);

  // Load the native library inside this isolate
  final lib = Platform.isAndroid
      ? DynamicLibrary.open('libsoundscore_dsp.so')
      : DynamicLibrary.process(); // iOS: linked statically

  final create  = lib.lookupFunction<_CreateNative,  _CreateDart>('soundscore_create');
  final destroy = lib.lookupFunction<_DestroyNative, _DestroyDart>('soundscore_destroy');
  final process = lib.lookupFunction<_ProcessNative, _ProcessDart>('soundscore_process_frame');
  final getBpm  = lib.lookupFunction<_GetBpmNative,  _GetBpmDart>('soundscore_get_bpm');
  final reset   = lib.lookupFunction<_ResetNative,   _ResetDart>('soundscore_reset');

  const sampleRate = 44100;
  const frameSize  = 2048;

  final ctx = create(sampleRate, frameSize);
  assert(ctx != nullptr, 'soundscore_create() returned null');

  // Allocate a reusable native buffer for PCM data (avoids per-frame alloc)
  final nativeSamples = calloc<Int16>(frameSize);

  receivePort.listen((message) {
    if (message == 'reset') {
      reset(ctx);
      return;
    }

    if (message == 'dispose') {
      destroy(ctx);
      calloc.free(nativeSamples);
      receivePort.close();
      return;
    }

    if (message is Int16List) {
      // Copy Dart-side audio chunk into native memory
      final len = message.length.clamp(0, frameSize);
      for (int i = 0; i < len; i++) nativeSamples[i] = message[i];

      final result = process(ctx, nativeSamples, len);
      final bpm    = getBpm(ctx);

      // Serialise to plain List for cross-isolate transfer
      mainSendPort.send(<dynamic>[
        result.frequency,
        result.midiNote,
        result.confidence,
        result.isOnset,
        bpm,
        '', // chordLabel — populated by ChordAnalyzer in Phase 3 integration
      ]);
    }
  });
}

/// Dart-side FFI bridge to the native soundscore_dsp C++ library.
///
/// Runs DSP processing in a dedicated [Isolate] so the UI thread is never
/// blocked. Exposes a [Stream<PitchResult>] for the rest of the app.
///
/// Usage:
/// ```dart
/// final bridge = DspFfiBridge();
/// await bridge.initialize();
/// bridge.results.listen((r) { ... });
/// bridge.processFrame(int16Data);
/// bridge.dispose();
/// ```
class DspFfiBridge {
  final _controller = StreamController<PitchResult>.broadcast();
  SendPort? _dspSendPort;
  Isolate?  _isolate;
  ReceivePort? _receivePort;
  bool _initialized = false;

  /// Stream of [PitchResult] values — one per processed audio frame.
  Stream<PitchResult> get results => _controller.stream;

  /// Start the DSP isolate. Must be called once before [processFrame].
  Future<void> initialize() async {
    if (_initialized) return;

    _receivePort = ReceivePort();

    // Spawn the DSP isolate
    _isolate = await Isolate.spawn(
      _dspIsolateMain,
      _receivePort!.sendPort,
      debugName: 'SoundScore-DSP',
    );

    // First message back is the isolate's own SendPort
    final completer = Completer<SendPort>();
    late StreamSubscription sub;
    sub = _receivePort!.listen((message) {
      if (!completer.isCompleted && message is SendPort) {
        completer.complete(message);
        sub.cancel();
      }
    });
    _dspSendPort = await completer.future;

    // All subsequent messages are List<dynamic> result payloads
    _receivePort!.listen((message) {
      if (message is List<dynamic> && !_controller.isClosed)
        _controller.add(PitchResult.fromIsolateMessage(message));
    });

    _initialized = true;
  }

  /// Send one frame of 16-bit PCM audio (mono, 44100 Hz) for processing.
  ///
  /// Results arrive asynchronously via [results].
  void processFrame(Int16List frame) {
    assert(_initialized, 'Call initialize() before processFrame()');
    _dspSendPort?.send(frame);
  }

  /// Reset the native DSP context (call when starting a new recording session).
  void resetSession() => _dspSendPort?.send('reset');

  /// Release all resources. The bridge cannot be used after this.
  void dispose() {
    _dspSendPort?.send('dispose');
    _isolate?.kill(priority: Isolate.immediate);
    _receivePort?.close();
    _controller.close();
    _initialized = false;
  }
}

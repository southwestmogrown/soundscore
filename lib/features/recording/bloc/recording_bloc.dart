import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:soundscore/core/audio/audio_engine.dart';
import 'package:soundscore/core/audio/ffi_bridge.dart';
import 'package:soundscore/core/dsp/pitch_result.dart';
import 'package:soundscore/core/permissions/permission_handler_service.dart';

import 'recording_event.dart';
import 'recording_state.dart';

class RecordingBloc extends Bloc<RecordingEvent, RecordingState> {
  RecordingBloc({
    required AudioEngine audioEngine,
    required DspFfiBridge bridge,
    required PermissionHandlerService permissions,
  })  : _engine      = audioEngine,
        _bridge      = bridge,
        _permissions = permissions,
        super(const RecordingState()) {
    on<RecordingStartRequested>(_onStartRequested);
    on<RecordingStopRequested>(_onStopRequested);
    on<RecordingResetRequested>(_onResetRequested);
    on<_PitchResultReceived>(_onPitchResult);
  }

  final AudioEngine              _engine;
  final DspFfiBridge             _bridge;
  final PermissionHandlerService _permissions;

  StreamSubscription? _pcmSub;
  StreamSubscription? _resultSub;

  // ── Event handlers ────────────────────────────────────────────────────────

  Future<void> _onStartRequested(
    RecordingStartRequested event,
    Emitter<RecordingState> emit,
  ) async {
    emit(state.copyWith(status: RecordingStatus.requestingPermission, clearError: true));

    final granted = await _permissions.requestMicrophone();
    if (!granted) {
      emit(state.copyWith(
        status:       RecordingStatus.permissionDenied,
        errorMessage: 'Microphone permission is required to detect notes.',
      ));
      return;
    }

    await _bridge.initialize();
    _bridge.resetSession();

    // Forward DSP results into the BLoC event stream
    _resultSub = _bridge.results.listen(
      (result) { if (!isClosed) add(_PitchResultReceived(result)); },
    );

    // Forward PCM frames from the microphone → FFI bridge
    _pcmSub = _engine.pcmStream.listen(_bridge.processFrame);

    await _engine.start();
    emit(state.copyWith(status: RecordingStatus.recording, clearError: true));
  }

  Future<void> _onStopRequested(
    RecordingStopRequested event,
    Emitter<RecordingState> emit,
  ) async {
    emit(state.copyWith(status: RecordingStatus.stopping));
    await _tearDownStreams();
    emit(state.copyWith(status: RecordingStatus.idle));
  }

  Future<void> _onResetRequested(
    RecordingResetRequested event,
    Emitter<RecordingState> emit,
  ) async {
    await _tearDownStreams();
    _bridge.resetSession();
    emit(const RecordingState());
  }

  void _onPitchResult(
    _PitchResultReceived event,
    Emitter<RecordingState> emit,
  ) {
    if (state.isRecording) {
      emit(state.copyWith(latest: event.result));
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Future<void> _tearDownStreams() async {
    await _pcmSub?.cancel();
    _pcmSub = null;
    await _resultSub?.cancel();
    _resultSub = null;
    await _engine.stop();
  }

  @override
  Future<void> close() async {
    await _tearDownStreams();
    _engine.dispose();
    _bridge.dispose();
    return super.close();
  }
}

// ── Internal event ─────────────────────────────────────────────────────────

class _PitchResultReceived extends RecordingEvent {
  const _PitchResultReceived(this.result);
  final PitchResult result;
  @override
  List<Object?> get props => [result];
}

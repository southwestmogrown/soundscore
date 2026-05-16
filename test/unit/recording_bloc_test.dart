import 'dart:async';
import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:soundscore/core/audio/audio_engine.dart';
import 'package:soundscore/core/audio/ffi_bridge.dart';
import 'package:soundscore/core/dsp/pitch_result.dart';
import 'package:soundscore/core/permissions/permission_handler_service.dart';
import 'package:soundscore/features/recording/bloc/recording_bloc.dart';
import 'package:soundscore/features/recording/bloc/recording_event.dart';
import 'package:soundscore/features/recording/bloc/recording_state.dart';

// ── Mocks ──────────────────────────────────────────────────────────────────────

class MockAudioEngine extends Mock implements AudioEngine {}

class MockDspFfiBridge extends Mock implements DspFfiBridge {}

class MockPermissionHandlerService extends Mock
    implements PermissionHandlerService {}

void main() {
  late MockAudioEngine mockEngine;
  late MockDspFfiBridge mockBridge;
  late MockPermissionHandlerService mockPermissions;
  late StreamController<Int16List> pcmController;
  late StreamController<PitchResult> resultController;

  setUp(() {
    mockEngine = MockAudioEngine();
    mockBridge = MockDspFfiBridge();
    mockPermissions = MockPermissionHandlerService();
    pcmController = StreamController<Int16List>.broadcast();
    resultController = StreamController<PitchResult>.broadcast();

    when(() => mockEngine.pcmStream).thenAnswer((_) => pcmController.stream);
    when(() => mockEngine.start()).thenAnswer((_) async {});
    when(() => mockEngine.stop()).thenAnswer((_) async {});
    when(() => mockEngine.dispose()).thenReturn(null);

    when(() => mockBridge.initialize()).thenAnswer((_) async {});
    when(() => mockBridge.resetSession()).thenReturn(null);
    when(() => mockBridge.results).thenAnswer((_) => resultController.stream);
    when(() => mockBridge.processFrame(any())).thenReturn(null);
    when(() => mockBridge.dispose()).thenReturn(null);
  });

  tearDown(() {
    pcmController.close();
    resultController.close();
  });

  RecordingBloc buildBloc() => RecordingBloc(
        audioEngine: mockEngine,
        bridge: mockBridge,
        permissions: mockPermissions,
      );

  group('RecordingBloc', () {
    test('initial state is idle', () {
      final bloc = buildBloc();
      expect(bloc.state.status, RecordingStatus.idle);
      expect(bloc.state.latest, pitchResultSilence);
      expect(bloc.state.errorMessage, isNull);
      bloc.close();
    });

    group('RecordingStartRequested', () {
      blocTest<RecordingBloc, RecordingState>(
        'emits permissionDenied when microphone permission is denied',
        build: () {
          when(() => mockPermissions.requestMicrophone())
              .thenAnswer((_) async => false);
          return buildBloc();
        },
        act: (bloc) => bloc.add(const RecordingStartRequested()),
        expect: () => [
          // First: requestingPermission
          isA<RecordingState>().having(
              (s) => s.status, 'status', RecordingStatus.requestingPermission),
          // Then: permissionDenied
          isA<RecordingState>()
              .having(
                  (s) => s.status, 'status', RecordingStatus.permissionDenied)
              .having((s) => s.errorMessage, 'errorMessage', isNotNull),
        ],
      );

      blocTest<RecordingBloc, RecordingState>(
        'emits recording when permission is granted',
        build: () {
          when(() => mockPermissions.requestMicrophone())
              .thenAnswer((_) async => true);
          return buildBloc();
        },
        act: (bloc) => bloc.add(const RecordingStartRequested()),
        expect: () => [
          isA<RecordingState>().having(
              (s) => s.status, 'status', RecordingStatus.requestingPermission),
          isA<RecordingState>()
              .having((s) => s.status, 'status', RecordingStatus.recording),
        ],
        verify: (_) {
          verify(() => mockBridge.initialize()).called(1);
          verify(() => mockBridge.resetSession()).called(1);
          verify(() => mockEngine.start()).called(1);
        },
      );
    });

    group('RecordingStopRequested', () {
      blocTest<RecordingBloc, RecordingState>(
        'transitions from recording → stopping → idle',
        build: () {
          when(() => mockPermissions.requestMicrophone())
              .thenAnswer((_) async => true);
          return buildBloc();
        },
        act: (bloc) async {
          bloc.add(const RecordingStartRequested());
          await Future<void>.delayed(const Duration(milliseconds: 50));
          bloc.add(const RecordingStopRequested());
        },
        expect: () => [
          // Start sequence
          isA<RecordingState>().having(
              (s) => s.status, 'status', RecordingStatus.requestingPermission),
          isA<RecordingState>()
              .having((s) => s.status, 'status', RecordingStatus.recording),
          // Stop sequence
          isA<RecordingState>()
              .having((s) => s.status, 'status', RecordingStatus.stopping),
          isA<RecordingState>()
              .having((s) => s.status, 'status', RecordingStatus.idle),
        ],
      );
    });

    group('RecordingResetRequested', () {
      blocTest<RecordingBloc, RecordingState>(
        'resets state to initial',
        build: () {
          when(() => mockPermissions.requestMicrophone())
              .thenAnswer((_) async => true);
          return buildBloc();
        },
        act: (bloc) async {
          bloc.add(const RecordingStartRequested());
          await Future<void>.delayed(const Duration(milliseconds: 50));
          bloc.add(const RecordingResetRequested());
        },
        expect: () => [
          isA<RecordingState>().having(
              (s) => s.status, 'status', RecordingStatus.requestingPermission),
          isA<RecordingState>()
              .having((s) => s.status, 'status', RecordingStatus.recording),
          const RecordingState(), // reset to initial
        ],
        verify: (_) {
          // resetSession called once for start, once for reset
          verify(() => mockBridge.resetSession()).called(2);
        },
      );
    });

    group('PitchResult streaming', () {
      blocTest<RecordingBloc, RecordingState>(
        'emits updated state when DSP results arrive during recording',
        build: () {
          when(() => mockPermissions.requestMicrophone())
              .thenAnswer((_) async => true);
          return buildBloc();
        },
        act: (bloc) async {
          bloc.add(const RecordingStartRequested());
          await Future<void>.delayed(const Duration(milliseconds: 50));
          resultController.add(const PitchResult(
            frequency: 440.0,
            midiNote: 69,
            confidence: 0.9,
            isOnset: true,
            bpm: 120.0,
            chordLabel: 'Am',
          ));
          await Future<void>.delayed(const Duration(milliseconds: 50));
        },
        expect: () => [
          isA<RecordingState>().having(
              (s) => s.status, 'status', RecordingStatus.requestingPermission),
          isA<RecordingState>()
              .having((s) => s.status, 'status', RecordingStatus.recording),
          isA<RecordingState>()
              .having((s) => s.latest.frequency, 'frequency', 440.0)
              .having((s) => s.latest.midiNote, 'midiNote', 69)
              .having((s) => s.latest.chordLabel, 'chordLabel', 'Am'),
        ],
      );
    });

    group('close / dispose', () {
      test('close disposes engine and bridge', () async {
        final bloc = buildBloc();
        await bloc.close();
        verify(() => mockEngine.dispose()).called(1);
        verify(() => mockBridge.dispose()).called(1);
      });
    });
  });
}

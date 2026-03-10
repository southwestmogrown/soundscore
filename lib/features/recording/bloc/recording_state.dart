import 'package:equatable/equatable.dart';
import 'package:soundscore/core/dsp/pitch_result.dart';

enum RecordingStatus {
  idle,
  requestingPermission,
  permissionDenied,
  recording,
  stopping,
}

class RecordingState extends Equatable {
  const RecordingState({
    this.status  = RecordingStatus.idle,
    this.latest  = PitchResult.silence,
    this.errorMessage,
  });

  final RecordingStatus status;

  /// Most recent DSP result from the native layer.
  final PitchResult latest;

  /// Non-null when [status] is [RecordingStatus.permissionDenied] or an error
  /// occurred.
  final String? errorMessage;

  bool get isRecording  => status == RecordingStatus.recording;
  bool get canRecord    => status == RecordingStatus.idle ||
                           status == RecordingStatus.permissionDenied;

  RecordingState copyWith({
    RecordingStatus? status,
    PitchResult?    latest,
    String?         errorMessage,
    bool            clearError = false,
  }) {
    return RecordingState(
      status:       status       ?? this.status,
      latest:       latest       ?? this.latest,
      errorMessage: clearError   ? null
                                 : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, latest, errorMessage];
}

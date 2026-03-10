import 'package:equatable/equatable.dart';

abstract class RecordingEvent extends Equatable {
  const RecordingEvent();
  @override
  List<Object?> get props => [];
}

/// User tapped the record button — request mic permission then start capture.
class RecordingStartRequested extends RecordingEvent {
  const RecordingStartRequested();
}

/// User tapped the stop button.
class RecordingStopRequested extends RecordingEvent {
  const RecordingStopRequested();
}

/// User tapped "reset" / "new session".
class RecordingResetRequested extends RecordingEvent {
  const RecordingResetRequested();
}

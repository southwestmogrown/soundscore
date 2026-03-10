import 'package:freezed_annotation/freezed_annotation.dart';

import 'note.dart';

part 'pitch_result.freezed.dart';

/// Result of processing one audio frame through the DSP pipeline.
@freezed
class PitchResult with _$PitchResult {
  const factory PitchResult({
    /// Detected fundamental frequency in Hz; 0.0 if no pitch detected.
    required double frequency,

    /// MIDI note number (0–127); -1 if no pitch detected.
    required int midiNote,

    /// Detection confidence: 0.0 (none) → 1.0 (high).
    required double confidence,

    /// True if a new note onset was detected in this frame.
    required bool isOnset,

    /// Current BPM estimate; 0.0 if not enough onsets accumulated yet.
    @Default(0.0) double bpm,

    /// Chord label ("Am", "G", "F#m", …); empty string if undetected.
    @Default('') String chordLabel,
  }) = _PitchResult;

  const PitchResult._();

  /// Returns the [Note] for this result, or null if no pitch was detected.
  Note? get note => midiNote >= 0 ? Note(midiNote) : null;

  /// True if this frame contains a valid pitch detection.
  bool get hasPitch => frequency > 0.0 && confidence > 0.1;

  /// True if a chord was detected in this frame.
  bool get hasChord => chordLabel.isNotEmpty;

  /// Silence / no pitch sentinel value.
  static const PitchResult silence = PitchResult(
    frequency: 0.0,
    midiNote: -1,
    confidence: 0.0,
    isOnset: false,
  );

  /// Deserialise from the list sent across Dart isolates:
  /// [frequency, midiNote, confidence, isOnset, bpm, chordConfidence, chordLabelEncoded]
  factory PitchResult.fromIsolateMessage(List<dynamic> msg) {
    return PitchResult(
      frequency:  (msg[0] as num).toDouble(),
      midiNote:   (msg[1] as num).toInt(),
      confidence: (msg[2] as num).toDouble(),
      isOnset:    (msg[3] as num) != 0,
      bpm:        (msg[4] as num).toDouble(),
      chordLabel: msg.length > 5 ? msg[5] as String : '',
    );
  }
}

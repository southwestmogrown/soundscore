import 'package:freezed_annotation/freezed_annotation.dart';

part 'chord_result.freezed.dart';

/// Chord quality classification.
enum ChordQuality { major, minor, unknown }

/// A detected chord.
@freezed
class ChordResult with _$ChordResult {
  const factory ChordResult({
    /// Chord label as returned by the C++ analyzer (e.g. "Am", "G", "F#m").
    /// Empty string means no chord was detected.
    required String label,

    /// Root note name ("C", "C#", …, "B"), or "" if undetected.
    required String root,

    /// Chord quality.
    required ChordQuality quality,

    /// Detection confidence: 0.0 (none) → 1.0 (high).
    required double confidence,
  }) = _ChordResult;

  const ChordResult._();

  /// Parse a chord label returned by the C++ chord analyzer into a [ChordResult].
  factory ChordResult.fromLabel(String label, double confidence) {
    if (label.isEmpty) return chordResultNone;

    final isMinor = label.endsWith('m');
    final root = isMinor ? label.substring(0, label.length - 1) : label;

    return ChordResult(
      label: label,
      root: root,
      quality: isMinor ? ChordQuality.minor : ChordQuality.major,
      confidence: confidence,
    );
  }

  bool get isDetected => label.isNotEmpty;
  
  @override
  // TODO: implement confidence
  double get confidence => throw UnimplementedError();
  
  @override
  // TODO: implement label
  String get label => throw UnimplementedError();
  
  @override
  // TODO: implement quality
  ChordQuality get quality => throw UnimplementedError();
  
  @override
  // TODO: implement root
  String get root => throw UnimplementedError();
}

const chordResultNone = ChordResult(
  label: '',
  root: '',
  quality: ChordQuality.unknown,
  confidence: 0.0,
);

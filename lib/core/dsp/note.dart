import 'dart:math' as math;

/// A musical note derived from a MIDI note number.
///
/// MIDI note 60 = Middle C (C4).
/// MIDI note 69 = A4 (440 Hz).
class Note {
  final int midiNote;

  const Note(this.midiNote);

  static const _names = [
    'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B',
  ];

  /// Pitch class name: "C", "C#", "D", … "B"
  String get name => _names[midiNote % 12];

  /// Scientific octave number (C4 = middle C, octave 4).
  int get octave => (midiNote ~/ 12) - 1;

  /// Full name with octave: "A4", "E2", "C#3", …
  String get fullName => '$name$octave';

  /// Theoretical frequency in Hz (equal temperament, A4 = 440 Hz).
  double get frequency => 440.0 * math.pow(2.0, (midiNote - 69) / 12.0);

  // ── Open string MIDI notes ────────────────────────────────────────────────

  /// Standard guitar tuning: strings 6→1: E2 A2 D3 G3 B3 E4
  static const List<int> guitarStandardTuning = [40, 45, 50, 55, 59, 64];

  /// Drop-D guitar tuning: string 6 → D2
  static const List<int> guitarDropDTuning = [38, 45, 50, 55, 59, 64];

  /// Standard 4-string bass tuning: strings 4→1: E1 A1 D2 G2
  static const List<int> bassStandardTuning = [28, 33, 38, 43];

  /// 5-string bass standard tuning: strings 5→1: B0 E1 A1 D2 G2
  static const List<int> bass5StringTuning = [23, 28, 33, 38, 43];

  @override
  bool operator ==(Object other) => other is Note && other.midiNote == midiNote;

  @override
  int get hashCode => midiNote.hashCode;

  @override
  String toString() => fullName;
}

/// A single detected note placed on the tablature staff.
class TabNote {
  /// MIDI note number.
  final int midiNote;

  /// String index (0 = lowest string, e.g. low-E on guitar).
  final int string;

  /// Fret number (0 = open string, 1–24 = fretted).
  final int fret;

  /// Detection confidence 0.0 – 1.0 from the DSP layer.
  final double confidence;

  const TabNote({
    required this.midiNote,
    required this.string,
    required this.fret,
    required this.confidence,
  });

  @override
  String toString() => 'TabNote(string=$string, fret=$fret, midi=$midiNote)';
}

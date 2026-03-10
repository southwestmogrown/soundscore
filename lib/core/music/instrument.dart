import '../dsp/note.dart';

enum InstrumentType { guitar, bass }

/// Defines the physical instrument being played — its string count and tuning.
///
/// [tuning] lists open-string MIDI notes from lowest string (index 0) to
/// highest string (index n-1). Matches the convention in [Note].
class Instrument {
  final InstrumentType type;
  final List<int> tuning;
  final String name;

  const Instrument({
    required this.type,
    required this.tuning,
    required this.name,
  });

  int get stringCount => tuning.length;

  /// Open-string note name for [stringIndex] (0 = lowest string).
  String openStringName(int stringIndex) => Note(tuning[stringIndex]).name;

  // ── Presets ───────────────────────────────────────────────────────────────

  static const Instrument guitarStandard = Instrument(
    type:   InstrumentType.guitar,
    tuning: Note.guitarStandardTuning, // E2 A2 D3 G3 B3 E4
    name:   'Guitar – Standard',
  );

  static const Instrument guitarDropD = Instrument(
    type:   InstrumentType.guitar,
    tuning: Note.guitarDropDTuning,    // D2 A2 D3 G3 B3 E4
    name:   'Guitar – Drop D',
  );

  static const Instrument bass4String = Instrument(
    type:   InstrumentType.bass,
    tuning: Note.bassStandardTuning,   // E1 A1 D2 G2
    name:   'Bass – 4-String',
  );

  static const Instrument bass5String = Instrument(
    type:   InstrumentType.bass,
    tuning: Note.bass5StringTuning,    // B0 E1 A1 D2 G2
    name:   'Bass – 5-String',
  );

  static const List<Instrument> presets = [
    guitarStandard,
    guitarDropD,
    bass4String,
    bass5String,
  ];

  @override
  bool operator ==(Object other) =>
      other is Instrument && other.name == name;

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => name;
}

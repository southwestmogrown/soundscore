import 'instrument.dart';
import 'tab_note.dart';

/// Maps a MIDI note number to the best (string, fret) position on the given
/// [Instrument], using a greedy scoring function that:
///
///  1. Prefers lower fret numbers (open-position playing).
///  2. Minimises string jumps from the previous note (voice-leading continuity).
///
/// Call [reset] when starting a new recording session so position history
/// is cleared.
class TabCalculator {
  TabCalculator(this.instrument);

  final Instrument instrument;
  _Position? _lastPosition;

  static const int _maxFret = 24;

  /// Returns a [TabNote] for [midiNote], or `null` if the note cannot be
  /// played on any string within the fret range.
  TabNote? noteToTabNote(int midiNote, {double confidence = 1.0}) {
    final candidates = <_Position>[];

    for (int s = 0; s < instrument.stringCount; s++) {
      final fret = midiNote - instrument.tuning[s];
      if (fret >= 0 && fret <= _maxFret) {
        candidates.add(_Position(string: s, fret: fret));
      }
    }

    if (candidates.isEmpty) return null;

    final best = candidates.reduce(
      (a, b) => _score(a) >= _score(b) ? a : b,
    );

    _lastPosition = best;
    return TabNote(
      midiNote:   midiNote,
      string:     best.string,
      fret:       best.fret,
      confidence: confidence,
    );
  }

  /// Clears position history — call at the start of each session.
  void reset() => _lastPosition = null;

  // ── Scoring ───────────────────────────────────────────────────────────────
  // Higher score = better choice.
  // • Lower frets are preferred (natural / first-position playing).
  // • String jumps from the previous note are penalised.

  double _score(_Position p) {
    var score = -p.fret * 0.5;
    if (_lastPosition != null) {
      score -= (p.string - _lastPosition!.string).abs() * 2.0;
    }
    return score;
  }
}

class _Position {
  final int string;
  final int fret;
  const _Position({required this.string, required this.fret});
}

import 'package:flutter_test/flutter_test.dart';
import 'package:soundscore/core/music/instrument.dart';
import 'package:soundscore/core/music/tab_calculator.dart';

void main() {
  group('TabCalculator – guitar standard', () {
    late TabCalculator calc;

    setUp(() {
      calc = TabCalculator(Instrument.guitarStandard);
    });

    test('open low-E (MIDI 40) → string 0, fret 0', () {
      final note = calc.noteToTabNote(40);
      expect(note, isNotNull);
      expect(note!.string, 0);
      expect(note.fret,   0);
    });

    test('A4 (MIDI 69) → fret 5 on string 5 (high-E string, fret 5) or similar', () {
      final note = calc.noteToTabNote(69);
      expect(note, isNotNull);
      // A4 = MIDI 69. High-E string open = 64, so fret = 5. That is the
      // highest-string option; low-fret preference should pick it.
      expect(note!.fret, lessThanOrEqualTo(10));
      // Verify the math: tuning[string] + fret == 69
      expect(Instrument.guitarStandard.tuning[note.string] + note.fret, 69);
    });

    test('out-of-range note (MIDI 20) → null', () {
      final note = calc.noteToTabNote(20); // below low E2
      expect(note, isNull);
    });

    test('fret 24 is the maximum (MIDI 88 on high-E = 64+24)', () {
      final note = calc.noteToTabNote(88);
      expect(note, isNotNull);
      expect(note!.fret, lessThanOrEqualTo(24));
      expect(Instrument.guitarStandard.tuning[note.string] + note.fret, 88);
    });

    test('position continuity: consecutive notes prefer same string region', () {
      // Play E2 (MIDI 40, string 0 fret 0), then F2 (MIDI 41).
      // F2 can be fret 1 on string 0 OR fret 6 on A string (45-4 = nope).
      // Best: string 0 fret 1 (same string, low fret).
      final e2 = calc.noteToTabNote(40);
      expect(e2!.string, 0);
      final f2 = calc.noteToTabNote(41);
      expect(f2!.string, 0); // should stay on same string
      expect(f2.fret, 1);
    });

    test('reset clears position history', () {
      calc.noteToTabNote(64); // high-E string
      calc.reset();
      // After reset, A4 should again prefer lower-fret option
      final note = calc.noteToTabNote(69);
      expect(note, isNotNull);
    });
  });

  group('TabCalculator – bass 4-string', () {
    late TabCalculator calc;

    setUp(() => calc = TabCalculator(Instrument.bass4String));

    test('open E1 (MIDI 28) → string 0, fret 0', () {
      final note = calc.noteToTabNote(28);
      expect(note, isNotNull);
      expect(note!.string, 0);
      expect(note.fret,   0);
    });

    test('G2 (MIDI 43) → open G string (string 3, fret 0)', () {
      final note = calc.noteToTabNote(43);
      expect(note, isNotNull);
      expect(note!.fret, 0); // prefer open string
    });

    test('note above bass range → null', () {
      // MIDI 80 is way above bass G string (43) + 24 frets = 67
      final note = calc.noteToTabNote(80);
      expect(note, isNull);
    });
  });

  group('Instrument', () {
    test('guitarStandard has 6 strings', () {
      expect(Instrument.guitarStandard.stringCount, 6);
    });

    test('bass4String has 4 strings', () {
      expect(Instrument.bass4String.stringCount, 4);
    });

    test('openStringName(0) on guitar returns low-E name', () {
      expect(Instrument.guitarStandard.openStringName(0), 'E'); // MIDI 40 = E
    });

    test('presets list contains 4 entries', () {
      expect(Instrument.presets.length, 4);
    });
  });
}

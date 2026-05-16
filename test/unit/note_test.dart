import 'package:flutter_test/flutter_test.dart';
import 'package:soundscore/core/dsp/note.dart';

void main() {
  group('Note', () {
    group('name and octave', () {
      test('A4 → name "A", octave 4', () {
        const n = Note(69);
        expect(n.name,     'A');
        expect(n.octave,   4);
        expect(n.fullName, 'A4');
      });

      test('Middle C (C4) → MIDI 60', () {
        const n = Note(60);
        expect(n.name,     'C');
        expect(n.octave,   4);
        expect(n.fullName, 'C4');
      });

      test('E2 (guitar low string) → MIDI 40', () {
        const n = Note(40);
        expect(n.name,     'E');
        expect(n.octave,   2);
        expect(n.fullName, 'E2');
      });

      test('E1 (bass low string) → MIDI 28', () {
        const n = Note(28);
        expect(n.name,     'E');
        expect(n.octave,   1);
        expect(n.fullName, 'E1');
      });

      test('G#3 → MIDI 56', () {
        const n = Note(56);
        expect(n.name,     'G#');
        expect(n.octave,   3);
        expect(n.fullName, 'G#3');
      });

      test('MIDI 0 → C-1', () {
        const n = Note(0);
        expect(n.name,     'C');
        expect(n.octave,   -1);
        expect(n.fullName, 'C-1');
      });
    });

    group('frequency', () {
      test('A4 = 440 Hz', () {
        expect(const Note(69).frequency, closeTo(440.0, 0.01));
      });

      test('A3 = 220 Hz (one octave below A4)', () {
        expect(const Note(57).frequency, closeTo(220.0, 0.01));
      });

      test('E2 ≈ 82.41 Hz', () {
        expect(const Note(40).frequency, closeTo(82.41, 0.1));
      });

      test('E1 ≈ 41.20 Hz', () {
        expect(const Note(28).frequency, closeTo(41.20, 0.1));
      });
    });

    group('open string tunings', () {
      test('guitar standard tuning has 6 strings', () {
        expect(Note.guitarStandardTuning.length, 6);
      });

      test('guitar standard: string 6 = E2 (MIDI 40)', () {
        expect(Note.guitarStandardTuning[0], 40);
        expect(Note(Note.guitarStandardTuning[0]).fullName, 'E2');
      });

      test('guitar standard: string 1 = E4 (MIDI 64)', () {
        expect(Note.guitarStandardTuning[5], 64);
        expect(Note(Note.guitarStandardTuning[5]).fullName, 'E4');
      });

      test('bass standard tuning has 4 strings', () {
        expect(Note.bassStandardTuning.length, 4);
      });

      test('bass standard: string 4 = E1 (MIDI 28)', () {
        expect(Note.bassStandardTuning[0], 28);
        expect(Note(Note.bassStandardTuning[0]).fullName, 'E1');
      });
    });

    group('equality', () {
      test('same MIDI note → equal', () {
        expect(const Note(69), equals(const Note(69)));
      });

      test('different MIDI notes → not equal', () {
        expect(const Note(69), isNot(equals(const Note(70))));
      });
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:soundscore/core/dsp/pitch_result.dart';
import 'package:soundscore/core/dsp/note.dart';

void main() {
  group('PitchResult', () {
    test('silence sentinel has no pitch', () {
      expect(PitchResult.silence.hasPitch, isFalse);
      expect(PitchResult.silence.note,     isNull);
      expect(PitchResult.silence.hasChord, isFalse);
    });

    test('result with valid pitch reports hasPitch = true', () {
      const r = PitchResult(
        frequency:  440.0,
        midiNote:   69,
        confidence: 0.9,
        isOnset:    true,
      );
      expect(r.hasPitch, isTrue);
      expect(r.note,     equals(Note(69)));
      expect(r.note!.fullName, 'A4');
    });

    test('result with midiNote -1 returns null note', () {
      const r = PitchResult(
        frequency:  0.0,
        midiNote:   -1,
        confidence: 0.0,
        isOnset:    false,
      );
      expect(r.note, isNull);
    });

    test('fromIsolateMessage deserialises correctly', () {
      final msg = <dynamic>[440.0, 69, 0.95, 1, 120.0, 'Am'];
      final r = PitchResult.fromIsolateMessage(msg);
      expect(r.frequency,  closeTo(440.0, 0.001));
      expect(r.midiNote,   69);
      expect(r.confidence, closeTo(0.95, 0.001));
      expect(r.isOnset,    isTrue);
      expect(r.bpm,        closeTo(120.0, 0.001));
      expect(r.chordLabel, 'Am');
      expect(r.hasChord,   isTrue);
    });

    test('fromIsolateMessage handles missing chordLabel', () {
      final msg = <dynamic>[82.4, 40, 0.8, 0, 0.0];
      final r = PitchResult.fromIsolateMessage(msg);
      expect(r.chordLabel, '');
      expect(r.hasChord,   isFalse);
    });

    test('low-confidence result does not report hasPitch', () {
      const r = PitchResult(
        frequency:  440.0,
        midiNote:   69,
        confidence: 0.05, // below 0.1 threshold
        isOnset:    false,
      );
      expect(r.hasPitch, isFalse);
    });
  });
}

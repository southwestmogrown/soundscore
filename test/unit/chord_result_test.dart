import 'package:flutter_test/flutter_test.dart';
import 'package:soundscore/core/dsp/chord_result.dart';

void main() {
  group('ChordResult', () {
    test('none sentinel is undetected', () {
      expect(ChordResult.none.isDetected, isFalse);
      expect(ChordResult.none.label, isEmpty);
    });

    group('fromLabel', () {
      test('major chord: "G"', () {
        final c = ChordResult.fromLabel('G', 0.8);
        expect(c.label,      'G');
        expect(c.root,       'G');
        expect(c.quality,    ChordQuality.major);
        expect(c.confidence, closeTo(0.8, 0.001));
        expect(c.isDetected, isTrue);
      });

      test('minor chord: "Am"', () {
        final c = ChordResult.fromLabel('Am', 0.75);
        expect(c.label,   'Am');
        expect(c.root,    'A');
        expect(c.quality, ChordQuality.minor);
      });

      test('sharp root: "F#m"', () {
        final c = ChordResult.fromLabel('F#m', 0.6);
        expect(c.root,    'F#');
        expect(c.quality, ChordQuality.minor);
      });

      test('empty label → none', () {
        final c = ChordResult.fromLabel('', 0.0);
        expect(c.isDetected, isFalse);
        expect(c.quality,    ChordQuality.unknown);
      });
    });
  });
}

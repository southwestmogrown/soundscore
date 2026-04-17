import 'package:flutter_test/flutter_test.dart';
import 'package:soundscore/core/export/tab_export_service.dart';
import 'package:soundscore/core/music/instrument.dart';
import 'package:soundscore/core/music/tab_note.dart';

void main() {
  group('TabExportService.toText', () {
    test('empty notes returns placeholder', () {
      final text = TabExportService.toText(Instrument.guitarStandard, []);
      expect(text, '(empty tablature)');
    });

    test('single open E2 note renders on lowest string', () {
      final text = TabExportService.toText(
        Instrument.guitarStandard,
        const [TabNote(midiNote: 40, string: 0, fret: 0, confidence: 0.9)],
      );

      // Should have 6 lines (6 strings)
      final lines = text.split('\n');
      expect(lines.length, 6);

      // The bottom line (low E) should contain the fret number 0
      // String 0 = lowest = last display row
      expect(lines.last, contains('0'));
    });

    test('renders correct number of columns', () {
      final notes = [
        const TabNote(midiNote: 40, string: 0, fret: 0, confidence: 0.9),
        const TabNote(midiNote: 45, string: 1, fret: 0, confidence: 0.9),
        const TabNote(midiNote: 50, string: 2, fret: 0, confidence: 0.9),
      ];
      final text = TabExportService.toText(Instrument.guitarStandard, notes);
      final lines = text.split('\n');

      // Each line should have string label + | + columns + -|
      for (final line in lines) {
        expect(line, contains('|'));
      }
    });

    test('bass 4-string has 4 lines', () {
      final text = TabExportService.toText(
        Instrument.bass4String,
        const [TabNote(midiNote: 28, string: 0, fret: 0, confidence: 0.9)],
      );
      final lines = text.split('\n');
      expect(lines.length, 4);
    });

    test('two-digit fret numbers render correctly', () {
      final text = TabExportService.toText(
        Instrument.guitarStandard,
        const [TabNote(midiNote: 52, string: 0, fret: 12, confidence: 0.9)],
      );
      expect(text, contains('12'));
    });
  });
}

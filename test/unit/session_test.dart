import 'package:flutter_test/flutter_test.dart';
import 'package:soundscore/core/music/instrument.dart';
import 'package:soundscore/core/music/tab_note.dart';
import 'package:soundscore/core/storage/session.dart';

void main() {
  group('Session', () {
    test('toMap and fromMap round-trip', () {
      final session = Session(
        name: 'Test Session',
        instrument: Instrument.guitarStandard,
        notes: const [
          TabNote(midiNote: 40, string: 0, fret: 0, confidence: 0.9),
          TabNote(midiNote: 45, string: 1, fret: 0, confidence: 0.85),
          TabNote(midiNote: 69, string: 5, fret: 5, confidence: 0.95),
        ],
        createdAt: DateTime(2026, 4, 17, 12, 0, 0),
      );

      final map = session.toMap();
      expect(map['name'], 'Test Session');
      expect(map['instrument_name'], 'Guitar – Standard');
      expect(map['notes_json'], isNotEmpty);
      expect(map['created_at'], '2026-04-17T12:00:00.000');

      // Simulate SQLite returning an id
      final mapWithId = {...map, 'id': 42};
      final restored = Session.fromMap(mapWithId);

      expect(restored.id, 42);
      expect(restored.name, 'Test Session');
      expect(restored.instrument, Instrument.guitarStandard);
      expect(restored.notes.length, 3);
      expect(restored.notes[0].midiNote, 40);
      expect(restored.notes[0].string, 0);
      expect(restored.notes[0].fret, 0);
      expect(restored.notes[0].confidence, closeTo(0.9, 0.001));
      expect(restored.notes[2].midiNote, 69);
      expect(restored.notes[2].fret, 5);
      expect(restored.createdAt, DateTime(2026, 4, 17, 12, 0, 0));
    });

    test('empty notes round-trip', () {
      final session = Session(
        name: 'Empty',
        instrument: Instrument.bass4String,
        notes: const [],
        createdAt: DateTime(2026, 1, 1),
      );

      final map = session.toMap();
      expect(map['notes_json'], '');

      final restored = Session.fromMap({...map, 'id': 1});
      expect(restored.notes, isEmpty);
      expect(restored.instrument, Instrument.bass4String);
    });

    test('unknown instrument name falls back to guitarStandard', () {
      final map = {
        'id': 1,
        'name': 'Test',
        'instrument_name': 'Unknown Instrument',
        'notes_json': '',
        'created_at': '2026-01-01T00:00:00.000',
      };

      final session = Session.fromMap(map);
      expect(session.instrument, Instrument.guitarStandard);
    });

    test('copyWith preserves fields', () {
      final original = Session(
        id: 1,
        name: 'Original',
        instrument: Instrument.guitarDropD,
        notes: const [
          TabNote(midiNote: 38, string: 0, fret: 0, confidence: 0.8),
        ],
        createdAt: DateTime(2026, 3, 15),
      );

      final copy = original.copyWith(name: 'Renamed');
      expect(copy.id, 1);
      expect(copy.name, 'Renamed');
      expect(copy.instrument, Instrument.guitarDropD);
      expect(copy.notes.length, 1);
    });
  });
}

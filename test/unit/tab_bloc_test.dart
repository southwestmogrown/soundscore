import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundscore/core/music/instrument.dart';
import 'package:soundscore/core/music/tab_note.dart';
import 'package:soundscore/features/tablature/bloc/tab_bloc.dart';
import 'package:soundscore/features/tablature/bloc/tab_event.dart';
import 'package:soundscore/features/tablature/bloc/tab_state.dart';

void main() {
  group('TabBloc', () {
    late TabBloc bloc;

    setUp(() {
      bloc = TabBloc();
    });

    tearDown(() => bloc.close());

    test('initial state is empty with guitarStandard', () {
      expect(bloc.state.instrument, Instrument.guitarStandard);
      expect(bloc.state.notes, isEmpty);
    });

    blocTest<TabBloc, TabState>(
      'TabNoteAdded adds a note to the list',
      build: TabBloc.new,
      act: (bloc) => bloc.add(
        const TabNoteAdded(midiNote: 40, confidence: 0.9),
      ),
      expect: () => [
        isA<TabState>()
            .having((s) => s.notes.length, 'notes.length', 1)
            .having((s) => s.notes.first.midiNote, 'midiNote', 40)
            .having((s) => s.notes.first.string, 'string', 0)
            .having((s) => s.notes.first.fret, 'fret', 0),
      ],
    );

    blocTest<TabBloc, TabState>(
      'TabNoteAdded ignores notes out of instrument range',
      build: TabBloc.new,
      act: (bloc) => bloc.add(
        const TabNoteAdded(midiNote: 20, confidence: 0.9), // below E2
      ),
      expect: () => <TabState>[], // no state change
    );

    blocTest<TabBloc, TabState>(
      'multiple TabNoteAdded events accumulate notes',
      build: TabBloc.new,
      act: (bloc) {
        bloc.add(const TabNoteAdded(midiNote: 40, confidence: 0.9));
        bloc.add(const TabNoteAdded(midiNote: 45, confidence: 0.8));
        bloc.add(const TabNoteAdded(midiNote: 50, confidence: 0.7));
      },
      expect: () => [
        isA<TabState>().having((s) => s.notes.length, 'notes.length', 1),
        isA<TabState>().having((s) => s.notes.length, 'notes.length', 2),
        isA<TabState>().having((s) => s.notes.length, 'notes.length', 3),
      ],
    );

    blocTest<TabBloc, TabState>(
      'TabInstrumentChanged changes instrument and clears notes',
      build: TabBloc.new,
      seed: () => TabState(
        instrument: Instrument.guitarStandard,
        notes: const [
          TabNote(midiNote: 40, string: 0, fret: 0, confidence: 0.9),
        ],
      ),
      act: (bloc) => bloc.add(
        const TabInstrumentChanged(Instrument.bass4String),
      ),
      expect: () => [
        isA<TabState>()
            .having((s) => s.instrument, 'instrument', Instrument.bass4String)
            .having((s) => s.notes, 'notes', isEmpty),
      ],
    );

    blocTest<TabBloc, TabState>(
      'TabCleared clears notes but keeps instrument',
      build: TabBloc.new,
      seed: () => TabState(
        instrument: Instrument.guitarDropD,
        notes: const [
          TabNote(midiNote: 38, string: 0, fret: 0, confidence: 0.9),
          TabNote(midiNote: 45, string: 1, fret: 0, confidence: 0.8),
        ],
      ),
      act: (bloc) => bloc.add(const TabCleared()),
      expect: () => [
        isA<TabState>()
            .having((s) => s.instrument, 'instrument', Instrument.guitarDropD)
            .having((s) => s.notes, 'notes', isEmpty),
      ],
    );

    blocTest<TabBloc, TabState>(
      'notes are correctly mapped with bass instrument',
      build: () {
        final b = TabBloc();
        b.add(const TabInstrumentChanged(Instrument.bass4String));
        return b;
      },
      act: (bloc) => bloc.add(
        const TabNoteAdded(midiNote: 28, confidence: 0.9), // open E1
      ),
      expect: () => [
        isA<TabState>()
            .having((s) => s.notes.last.midiNote, 'midiNote', 28)
            .having((s) => s.notes.last.fret, 'fret', 0),
      ],
      skip: 1, // skip the instrument change emission
    );
  });
}

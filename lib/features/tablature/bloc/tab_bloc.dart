import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:soundscore/core/music/tab_calculator.dart';

import 'tab_event.dart';
import 'tab_state.dart';

class TabBloc extends Bloc<TabEvent, TabState> {
  TabBloc() : super(const TabState()) {
    _calculator = TabCalculator(state.instrument);
    on<TabNoteAdded>(_onNoteAdded);
    on<TabInstrumentChanged>(_onInstrumentChanged);
    on<TabCleared>(_onCleared);
  }

  late TabCalculator _calculator;

  void _onNoteAdded(TabNoteAdded event, Emitter<TabState> emit) {
    final note = _calculator.noteToTabNote(
      event.midiNote,
      confidence: event.confidence,
    );
    if (note == null) return; // note out of instrument range — ignore
    emit(state.copyWith(notes: [...state.notes, note]));
  }

  void _onInstrumentChanged(TabInstrumentChanged event, Emitter<TabState> emit) {
    _calculator = TabCalculator(event.instrument);
    // Changing instrument clears notes — re-calculating old notes for a
    // different instrument tuning would produce meaningless results.
    emit(TabState(instrument: event.instrument));
  }

  void _onCleared(TabCleared event, Emitter<TabState> emit) {
    _calculator.reset();
    emit(TabState(instrument: state.instrument));
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:soundscore/core/music/tab_calculator.dart';
import 'package:soundscore/core/storage/session.dart';
import 'package:soundscore/core/storage/session_repository.dart';

import 'tab_event.dart';
import 'tab_state.dart';

class TabBloc extends Bloc<TabEvent, TabState> {
  TabBloc({SessionRepository? sessionRepository})
      : _sessionRepository = sessionRepository,
        super(const TabState()) {
    _calculator = TabCalculator(state.instrument);
    on<TabNoteAdded>(_onNoteAdded);
    on<TabInstrumentChanged>(_onInstrumentChanged);
    on<TabCleared>(_onCleared);
    on<TabSessionSaveRequested>(_onSessionSave);
    on<TabSessionLoadRequested>(_onSessionLoad);
    on<TabSessionListRequested>(_onSessionList);
    on<TabSessionDeleteRequested>(_onSessionDelete);
  }

  @override
  void onError(Object error, StackTrace stackTrace) {
    // TODO: route through crashlytics / error reporting
    FlutterError.presentError(
        FlutterErrorDetails(exception: 'TabBloc uncaught error: $error'));
  }

  late TabCalculator _calculator;
  final SessionRepository? _sessionRepository;

  void _onNoteAdded(TabNoteAdded event, Emitter<TabState> emit) {
    final note = _calculator.noteToTabNote(
      event.midiNote,
      confidence: event.confidence,
    );
    if (note == null) return; // note out of instrument range — ignore
    emit(state.copyWith(notes: [...state.notes, note]));
  }

  void _onInstrumentChanged(
      TabInstrumentChanged event, Emitter<TabState> emit) {
    _calculator = TabCalculator(event.instrument);
    // Changing instrument clears notes — re-calculating old notes for a
    // different instrument tuning would produce meaningless results.
    emit(TabState(
      instrument: event.instrument,
      savedSessions: state.savedSessions,
    ));
  }

  void _onCleared(TabCleared event, Emitter<TabState> emit) {
    _calculator.reset();
    emit(TabState(
      instrument: state.instrument,
      savedSessions: state.savedSessions,
    ));
  }

  Future<void> _onSessionSave(
    TabSessionSaveRequested event,
    Emitter<TabState> emit,
  ) async {
    final repo = _sessionRepository;
    if (repo == null) {
      emit(state.copyWith(errorMessage: 'Session storage unavailable'));
      return;
    }
    if (state.notes.isEmpty) return;

    final session = Session(
      name: event.name,
      instrument: state.instrument,
      notes: state.notes,
      createdAt: DateTime.now(),
    );

    final saved = await repo.insert(session);
    final sessions = await repo.getAll();
    emit(state.copyWith(
      savedSessions: sessions,
      currentSessionId: saved.id,
      clearError: true,
    ));
  }

  Future<void> _onSessionLoad(
    TabSessionLoadRequested event,
    Emitter<TabState> emit,
  ) async {
    final repo = _sessionRepository;
    if (repo == null) {
      emit(state.copyWith(errorMessage: 'Session storage unavailable'));
      return;
    }

    final session = await repo.getById(event.sessionId);
    if (session == null) {
      emit(state.copyWith(errorMessage: 'Session not found'));
      return;
    }

    _calculator = TabCalculator(session.instrument);
    _calculator.reset();
    emit(TabState(
      instrument: session.instrument,
      notes: session.notes,
      savedSessions: state.savedSessions,
      currentSessionId: session.id,
    ));
  }

  Future<void> _onSessionList(
    TabSessionListRequested event,
    Emitter<TabState> emit,
  ) async {
    final repo = _sessionRepository;
    if (repo == null) {
      emit(state.copyWith(errorMessage: 'Session storage unavailable'));
      return;
    }

    final sessions = await repo.getAll();
    emit(state.copyWith(savedSessions: sessions));
  }

  Future<void> _onSessionDelete(
    TabSessionDeleteRequested event,
    Emitter<TabState> emit,
  ) async {
    final repo = _sessionRepository;
    if (repo == null) {
      emit(state.copyWith(errorMessage: 'Session storage unavailable'));
      return;
    }

    await repo.delete(event.sessionId);
    final sessions = await repo.getAll();
    emit(state.copyWith(
      savedSessions: sessions,
      currentSessionId: state.currentSessionId == event.sessionId
          ? null
          : state.currentSessionId,
      clearSessionId: state.currentSessionId == event.sessionId,
    ));
  }
}

import 'package:equatable/equatable.dart';
import 'package:soundscore/core/music/instrument.dart';
import 'package:soundscore/core/music/tab_note.dart';
import 'package:soundscore/core/storage/session.dart';

class TabState extends Equatable {
  const TabState({
    this.instrument = Instrument.guitarStandard,
    this.notes      = const [],
    this.savedSessions = const [],
    this.currentSessionId,
  });

  final Instrument   instrument;
  final List<TabNote> notes;
  final List<Session> savedSessions;
  final int?         currentSessionId;

  bool get isEmpty => notes.isEmpty;

  TabState copyWith({
    Instrument? instrument,
    List<TabNote>? notes,
    List<Session>? savedSessions,
    int? currentSessionId,
    bool clearSessionId = false,
  }) {
    return TabState(
      instrument: instrument ?? this.instrument,
      notes:      notes      ?? this.notes,
      savedSessions: savedSessions ?? this.savedSessions,
      currentSessionId: clearSessionId ? null : (currentSessionId ?? this.currentSessionId),
    );
  }

  @override
  List<Object?> get props => [instrument, notes, savedSessions, currentSessionId];
}

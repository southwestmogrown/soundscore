import 'package:equatable/equatable.dart';
import 'package:soundscore/core/music/instrument.dart';
import 'package:soundscore/core/music/tab_note.dart';

class TabState extends Equatable {
  const TabState({
    this.instrument = Instrument.guitarStandard,
    this.notes      = const [],
  });

  final Instrument   instrument;
  final List<TabNote> notes;

  bool get isEmpty => notes.isEmpty;

  TabState copyWith({Instrument? instrument, List<TabNote>? notes}) {
    return TabState(
      instrument: instrument ?? this.instrument,
      notes:      notes      ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [instrument, notes];
}

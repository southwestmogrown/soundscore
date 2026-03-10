import 'package:equatable/equatable.dart';
import 'package:soundscore/core/music/instrument.dart';

abstract class TabEvent extends Equatable {
  const TabEvent();
  @override
  List<Object?> get props => [];
}

/// A new onset note was detected — add it to the tablature.
class TabNoteAdded extends TabEvent {
  const TabNoteAdded({required this.midiNote, required this.confidence});
  final int    midiNote;
  final double confidence;
  @override
  List<Object?> get props => [midiNote, confidence];
}

/// User changed the active instrument preset.
class TabInstrumentChanged extends TabEvent {
  const TabInstrumentChanged(this.instrument);
  final Instrument instrument;
  @override
  List<Object?> get props => [instrument];
}

/// User requested a fresh session.
class TabCleared extends TabEvent {
  const TabCleared();
}

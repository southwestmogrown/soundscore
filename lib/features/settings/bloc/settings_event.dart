import 'package:equatable/equatable.dart';
import 'package:soundscore/core/music/instrument.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();
  @override
  List<Object?> get props => [];
}

/// Load saved preferences on startup.
class SettingsLoadRequested extends SettingsEvent {
  const SettingsLoadRequested();
}

/// User changed the default instrument.
class SettingsInstrumentChanged extends SettingsEvent {
  const SettingsInstrumentChanged(this.instrument);
  final Instrument instrument;
  @override
  List<Object?> get props => [instrument];
}

/// User changed the theme mode ('system', 'light', 'dark').
class SettingsThemeModeChanged extends SettingsEvent {
  const SettingsThemeModeChanged(this.themeMode);
  final String themeMode;
  @override
  List<Object?> get props => [themeMode];
}

/// User changed the confidence threshold.
class SettingsConfidenceThresholdChanged extends SettingsEvent {
  const SettingsConfidenceThresholdChanged(this.threshold);
  final double threshold;
  @override
  List<Object?> get props => [threshold];
}

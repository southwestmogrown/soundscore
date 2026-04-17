import 'package:equatable/equatable.dart';
import 'package:soundscore/core/music/instrument.dart';

class SettingsState extends Equatable {
  const SettingsState({
    this.instrument = Instrument.guitarStandard,
    this.themeMode = 'system',
    this.confidenceThreshold = 0.1,
    this.isLoaded = false,
  });

  final Instrument instrument;
  final String themeMode;
  final double confidenceThreshold;
  final bool isLoaded;

  SettingsState copyWith({
    Instrument? instrument,
    String? themeMode,
    double? confidenceThreshold,
    bool? isLoaded,
  }) {
    return SettingsState(
      instrument: instrument ?? this.instrument,
      themeMode: themeMode ?? this.themeMode,
      confidenceThreshold: confidenceThreshold ?? this.confidenceThreshold,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }

  @override
  List<Object?> get props => [instrument, themeMode, confidenceThreshold, isLoaded];
}

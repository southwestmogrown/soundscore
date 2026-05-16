import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:soundscore/core/storage/preferences_service.dart';

import 'settings_event.dart';
import 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc({required PreferencesService preferencesService})
      : _prefs = preferencesService,
        super(const SettingsState()) {
    on<SettingsLoadRequested>(_onLoad);
    on<SettingsInstrumentChanged>(_onInstrumentChanged);
    on<SettingsThemeModeChanged>(_onThemeModeChanged);
    on<SettingsConfidenceThresholdChanged>(_onConfidenceThresholdChanged);
  }

  @override
  void onError(Object error, StackTrace stackTrace) {
    // TODO: route through crashlytics / error reporting
    FlutterError.presentError(
        FlutterErrorDetails(exception: 'SettingsBloc uncaught error: $error'));
  }

  final PreferencesService _prefs;

  Future<void> _onLoad(
    SettingsLoadRequested event,
    Emitter<SettingsState> emit,
  ) async {
    final instrument = await _prefs.getInstrument();
    final themeMode = await _prefs.getThemeMode();
    final threshold = await _prefs.getConfidenceThreshold();

    emit(state.copyWith(
      instrument: instrument,
      themeMode: themeMode,
      confidenceThreshold: threshold,
      isLoaded: true,
    ));
  }

  Future<void> _onInstrumentChanged(
    SettingsInstrumentChanged event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(instrument: event.instrument));
    await _prefs.setInstrument(event.instrument);
  }

  Future<void> _onThemeModeChanged(
    SettingsThemeModeChanged event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(themeMode: event.themeMode));
    await _prefs.setThemeMode(event.themeMode);
  }

  Future<void> _onConfidenceThresholdChanged(
    SettingsConfidenceThresholdChanged event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(confidenceThreshold: event.threshold));
    await _prefs.setConfidenceThreshold(event.threshold);
  }
}

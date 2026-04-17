import 'package:shared_preferences/shared_preferences.dart';
import 'package:soundscore/core/music/instrument.dart';

/// Persists user preferences to SharedPreferences.
class PreferencesService {
  static const _keyInstrument = 'pref_instrument';
  static const _keyThemeMode = 'pref_theme_mode';
  static const _keyConfidenceThreshold = 'pref_confidence_threshold';
  static const _keyOnboardingComplete = 'pref_onboarding_complete';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _instance async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // ── Instrument ─────────────────────────────────────────────────────────────

  Future<Instrument> getInstrument() async {
    final prefs = await _instance;
    final name = prefs.getString(_keyInstrument);
    if (name == null) return Instrument.guitarStandard;
    return Instrument.presets.firstWhere(
      (i) => i.name == name,
      orElse: () => Instrument.guitarStandard,
    );
  }

  Future<void> setInstrument(Instrument instrument) async {
    final prefs = await _instance;
    await prefs.setString(_keyInstrument, instrument.name);
  }

  // ── Theme ──────────────────────────────────────────────────────────────────

  /// Returns 'system', 'light', or 'dark'.
  Future<String> getThemeMode() async {
    final prefs = await _instance;
    return prefs.getString(_keyThemeMode) ?? 'system';
  }

  Future<void> setThemeMode(String mode) async {
    final prefs = await _instance;
    await prefs.setString(_keyThemeMode, mode);
  }

  // ── Confidence threshold ───────────────────────────────────────────────────

  Future<double> getConfidenceThreshold() async {
    final prefs = await _instance;
    return prefs.getDouble(_keyConfidenceThreshold) ?? 0.1;
  }

  Future<void> setConfidenceThreshold(double threshold) async {
    final prefs = await _instance;
    await prefs.setDouble(_keyConfidenceThreshold, threshold);
  }

  // ── Onboarding ─────────────────────────────────────────────────────────────

  Future<bool> isOnboardingComplete() async {
    final prefs = await _instance;
    return prefs.getBool(_keyOnboardingComplete) ?? false;
  }

  Future<void> setOnboardingComplete(bool complete) async {
    final prefs = await _instance;
    await prefs.setBool(_keyOnboardingComplete, complete);
  }
}

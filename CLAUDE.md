# CLAUDE.md — TabScribe

Project guidance for Claude Code. Read this before making any changes.

---

## Project Identity

- **Repo directory:** `tabscribe/`
- **Flutter package name:** `soundscore` (not `tabscribe`) — all imports use `package:soundscore/...`
- **App display name:** SoundScore (dev: "SoundScore Dev")
- **Platform targets:** iOS 12+, Android API 15+ (bump to 24 if adding `ffmpeg_kit_flutter`)

---

## Build & Run

```bash
# Install dependencies
flutter pub get

# Code generation — REQUIRED before building (Freezed, JSON serializers)
dart run build_runner build --delete-conflicting-outputs

# Run dev flavor
flutter run --flavor dev -t lib/main_dev.dart

# Run tests
flutter test test/unit/ --reporter expanded
```

Flavor entry points: `lib/main_dev.dart`, `lib/main_staging.dart`, `lib/main_prod.dart`.
Default `lib/main.dart` sets `AppConfig.dev`.

---

## Architecture

### State Management: BLoC

All features use `flutter_bloc`. Three app-level BLoCs are provisioned in `lib/app.dart`'s `MultiBlocProvider`:

| BLoC | Scope | File |
|---|---|---|
| `RecordingBloc` | Page-scoped (created per navigation) | `lib/features/recording/bloc/` |
| `TabBloc` | App-level (persists across navigation) | `lib/features/tablature/bloc/` |
| `SettingsBloc` | App-level | `lib/features/settings/bloc/` |

Rules:
- All events and states are immutable. New fields go through `Equatable` or `Freezed`.
- Page-scoped BLoCs are created in the page widget, not in `app.dart`.
- Never share a BLoC instance between features — use events to communicate across feature boundaries (e.g., `RecordingPage` fires `TabNoteAdded` into `TabBloc`).

### Navigation: GoRouter

All routes are defined in `lib/shared/router/app_router.dart`. Route path constants live in the `Routes` class in the same file.

To add a route:
1. Add a constant to `Routes`
2. Add a `GoRoute` entry in `AppRouter.router()`
3. Navigate with `context.push(Routes.foo)` or `context.go(Routes.foo)`

Current routes: `/onboarding`, `/` (recording), `/tablature`, `/sheet-music`, `/settings`, `/paywall`.

### Models: Freezed + JSON

DSP result types (`PitchResult`, `ChordResult`) and any new data models should use `@freezed`. Run `build_runner` after modifying annotated files.

Plain data classes (e.g., `TabNote`, `Session`) are handwritten — they are not Freezed. Adding fields to these requires manually updating JSON encode/decode in `Session._encodeNotes` / `_decodeNotes`.

### Audio Pipeline

```
Microphone (44.1kHz, 16-bit mono PCM, 2048-sample frames)
  → AudioEngine (lib/core/audio/audio_engine.dart)
  → DspFfiBridge isolate (lib/core/audio/ffi_bridge.dart)
  → C++ libsoundscore_dsp (native/)
  → PitchResult stream
  → RecordingBloc
  → TabNoteAdded event → TabBloc
```

- `AudioEngine` is an abstract class. `RecordAudioEngine` is the concrete mic implementation.
- The FFI bridge runs in a dedicated Dart `Isolate`. Do not call FFI functions from the main isolate.
- The C++ library emits `[frequency, midiNote, confidence, isOnset, bpm, chordLabel]` per frame.
- `RecordingBloc` filters on `isOnset == true` before firing `TabNoteAdded`. The tuner must not apply this filter.

### Storage

- **SQLite (`sqflite`):** Named sessions — `lib/core/storage/session_repository.dart`
- **SharedPreferences:** User settings — `lib/core/storage/preferences_service.dart`
- All storage is local-first. There is no backend or network API.

### Flavors & Config

`AppConfig` in `lib/core/config/app_config.dart` holds per-flavor API keys and feature flags. Access via `AppConfig.instance` anywhere in the app (set at startup in `main_*.dart`).

- `enableAnalytics` / `enableCrashlytics` are `false` in `dev`, `true` in `staging` and `prod`.
- AdMob App IDs must also appear in `AndroidManifest.xml` and `Info.plist` at build time.
- RevenueCat and AdMob keys in `AppConfig` are placeholder strings — replace before enabling monetization features.

---

## Code Conventions

- Feature code lives under `lib/features/<feature_name>/`. Each feature owns its pages, BLoC, and any feature-local widgets.
- Shared utilities (router, theme, common widgets) live under `lib/shared/`.
- Core services (audio, DSP, storage, permissions, export, music logic) live under `lib/core/`.
- Do not add `print()` statements — use `FlutterError.reportError` or `FirebaseCrashlytics` for error reporting.
- Do not import a feature from another feature. Cross-feature communication goes through app-level BLoC events.
- Prefer `const` constructors everywhere possible.
- New packages require justification — check `pubspec.yaml` before adding one; several capabilities (WebView, PDF, RevenueCat, AdMob) are already present but unused.

---

## Testing

Tests live in `test/unit/`. The pattern is:

```dart
blocTest<MyBloc, MyState>(
  'description',
  build: () => MyBloc(mockDep: MockDep()),
  act: (bloc) => bloc.add(MyEvent()),
  expect: () => [expectedState],
);
```

Use `mocktail` for mocking, `bloc_test` for BLoC tests. Do not mock the database in storage tests — use an in-memory `sqflite` instance.

Run before committing:
```bash
flutter analyze --no-fatal-infos
flutter test test/unit/
```

---

## CI

GitHub Actions runs on push and PR to `main`:
1. `flutter analyze` + `flutter test test/unit/`
2. CMake build of the native C++ DSP library

See `.github/workflows/ci.yml`.

---

## Planned Work

See [issues.md](issues.md) for the full feature backlog with architecture, file lists, and gotchas for each planned feature.

Recommended implementation order: Tuner → Per-note deletion → Landscape layout → Note quantization → Improved tab calculator → Sheet music (VexFlow) → Audio file input → RevenueCat/AdMob → Web/desktop.

---

## Known Placeholders

| Location | What's missing |
|---|---|
| `lib/features/sheet_music/sheet_music_page.dart` | VexFlow WebView — placeholder body |
| `lib/features/subscription/paywall_page.dart` | RevenueCat offerings UI — placeholder |
| `lib/core/monetization/subscription_service.dart` | Abstract only — no concrete impl |
| `lib/core/monetization/ad_service.dart` | Abstract only — no concrete impl |
| `AppConfig.prod` RevenueCat/AdMob keys | Placeholder strings — replace before release |
| `assets/html/` | Directory declared in pubspec; HTML assets not yet created |
| `assets/images/`, `assets/fonts/` | Declared in pubspec; Bravura font listed but verify presence |

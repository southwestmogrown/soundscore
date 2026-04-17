# TabScribe

> *Finding accurate tab online is a hassle. Writing it yourself is an even bigger one. TabScribe does it for you.*

TabScribe is a mobile app for musicians that listens to audio live from your microphone and generates guitar and bass tablature in real time. Hear a riff you want to learn? Play it. TabScribe transcribes it, displays it as standard ASCII tab, and lets you save or share it instantly.

Available on **iOS** and **Android**.

---

## What It Does

| Input | Output |
|---|---|
| Live microphone (real-time) | Guitar tablature (standard, drop-D) |
| | Bass tablature (4-string, 5-string) |
| | Chord detection with label + confidence |
| | BPM estimation |
| | PDF export |
| | Session save/load |

---

## Built For

- **Learners** — transcribe riffs and songs you want to play, instantly
- **Teachers** — generate readable tab to share with students
- **Songwriters** — capture melodic ideas before you forget them
- **Collaborators** — share ideas in a format any guitarist can read

---

## Platform

| Platform | Minimum Version |
|---|---|
| Android | API 15+ |
| iOS | iOS 12+ |

---

## Architecture & Tech Stack

TabScribe is a **Flutter** app built around a native C++ audio DSP library, a BLoC state management architecture, and a local-first data model.

### Audio Processing Pipeline

The core transcription pipeline runs entirely on-device:

1. **Microphone capture** — The `record` package streams 16-bit PCM audio at 44,100 Hz mono in 2048-sample frames.
2. **Native DSP (C++)** — A custom C++ library (`libsoundscore_dsp`) implements pitch detection, onset detection, BPM estimation, and chord recognition. It is loaded via Dart FFI.
3. **Isolate bridge** — The FFI calls run in a dedicated Dart isolate (`DspFfiBridge`) to avoid blocking the UI thread. Audio frames are sent via `SendPort`; results come back as `[frequency, midiNote, confidence, isOnset, bpm, chordLabel]`.
4. **Tab calculation** — Detected MIDI notes are mapped to string/fret positions by `TabCalculator` using a scoring function that prefers low frets and voice-leading continuity across the neck.

### State Management

The app uses the **BLoC pattern** (`flutter_bloc`) with three top-level BLoCs:

| BLoC | Scope | Responsibility |
|---|---|---|
| `RecordingBloc` | Page-scoped | Mic permissions, audio engine lifecycle, real-time pitch/chord/BPM streaming |
| `TabBloc` | App-level | Note accumulation, instrument selection, session CRUD |
| `SettingsBloc` | App-level | User preferences (instrument, theme, confidence threshold) |

All events and states are immutable, generated with **Freezed**.

### Key Libraries

| Category | Library | Version |
|---|---|---|
| Framework | Flutter SDK | 3.0+ |
| State management | flutter_bloc | 8.1.6 |
| Routing | go_router | 13.2.0 |
| Code generation | freezed + json_serializable | 2.5.7 / 6.8.0 |
| Native FFI | ffi | 2.1.3 |
| Audio capture | record | 5.1.2 |
| Local database | sqflite | 2.3.3 |
| Preferences | shared_preferences | 2.3.3 |
| PDF export | pdf | 3.11.1 |
| Sharing | share_plus | 12.0.1 |
| Permissions | permission_handler | 11.3.1 |
| Analytics | firebase_analytics | 11.3.3 |
| Crash reporting | firebase_crashlytics | 4.1.3 |
| Subscriptions | purchases_flutter (RevenueCat) | 6.29.1 |
| Ads | google_mobile_ads (AdMob) | 5.1.0 |
| Testing | bloc_test + mocktail | 9.1.7 / 1.0.4 |

### Navigation

Routes are managed by **go_router** with a redirect guard that enforces the onboarding flow on first launch:

```
/onboarding       OnboardingPage (3-page PageView)
/                 RecordingPage  (home — real-time detection)
/tablature        TabViewerPage  (ASCII tab display, export)
/sheet-music      SheetMusicPage (planned: VexFlow/OSMD via WebView)
/settings         SettingsPage
/paywall          PaywallPage    (planned: RevenueCat)
```

### Storage

All data is local-first. There is no backend.

- **SQLite** (`sqflite`) — Named sessions with instrument, note list (JSON), and timestamp.
- **SharedPreferences** — Instrument preference, theme mode, confidence threshold, onboarding state.

### Flavors

The app ships with three build flavors:

| Flavor | Entry point |
|---|---|
| `dev` | `lib/main_dev.dart` |
| `staging` | `lib/main_staging.dart` |
| `prod` | `lib/main_prod.dart` |

Each flavor has its own `AppConfig` with API keys, analytics toggles, and RevenueCat/AdMob IDs.

---

## Project Structure

```
lib/
├── app.dart                    # Root widget; MultiBlocProvider + router
├── bootstrap.dart              # Firebase init, orientation lock, crash hooks
├── main*.dart                  # Flavor entry points
├── core/
│   ├── audio/                  # AudioEngine (PCM capture), DspFfiBridge (FFI isolate)
│   ├── config/                 # AppConfig, flavor management
│   ├── dsp/                    # PitchResult, ChordResult, Note (MIDI/frequency utils)
│   ├── export/                 # TabExportService (text, PDF, share)
│   ├── monetization/           # AdService, SubscriptionService (stubs)
│   ├── music/                  # Instrument definitions, TabCalculator, TabNote
│   ├── permissions/            # PermissionHandlerService
│   └── storage/                # PreferencesService, SessionRepository, Session
├── features/
│   ├── onboarding/             # 3-page onboarding flow
│   ├── recording/              # RecordingPage + RecordingBloc
│   ├── settings/               # SettingsPage + SettingsBloc
│   ├── sheet_music/            # SheetMusicPage (WebView placeholder)
│   ├── subscription/           # PaywallPage (stub)
│   └── tablature/              # TabViewerPage, TabBloc, TabPainter
└── shared/
    ├── router/                 # AppRouter, Routes constants
    └── theme/                  # AppTheme (Material 3, deep green seed)
native/
└── soundscore_dsp/             # C++ DSP library (CMake)
test/
└── unit/                       # BLoC tests, model tests, calculator tests
```

---

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.0+
- **Android:** Android Studio with SDK (API 32+ build tools recommended)
- **iOS:** Xcode 14+ and CocoaPods

Verify your setup:

```bash
flutter doctor
```

### 1. Clone and install dependencies

```bash
git clone <your-repo-url>
cd tabscribe
flutter pub get
```

### 2. Generate code

Freezed models and JSON serializers are generated — this step is required before building:

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 3. Run

```bash
# Default (dev flavor) on connected device or emulator
flutter run

# With explicit flavor
flutter run --flavor dev -t lib/main_dev.dart
flutter run --flavor staging -t lib/main_staging.dart
flutter run --flavor prod -t lib/main_prod.dart

# Target a specific platform
flutter run -d android
flutter run -d ios
```

### 4. Run tests

```bash
flutter test test/unit/ --reporter expanded
```

### Firebase (optional)

Firebase Analytics and Crashlytics are initialized conditionally. If `google-services.json` (Android) or `GoogleService-Info.plist` (iOS) are absent, the app silently skips Firebase setup and runs normally. You only need Firebase credentials for analytics/crash reporting.

### Native DSP library (CI / advanced)

The C++ DSP library is built automatically as part of the Android and iOS native build process. For standalone compilation:

```bash
cd native
mkdir -p build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j$(nproc)
```

---

## CI/CD

GitHub Actions runs on every push and pull request to `main`:

| Job | Steps |
|---|---|
| Analyze & test | `flutter pub get` → `build_runner build` → `flutter analyze` → `flutter test` |
| Native DSP build | CMake configure → `make` → verify `libsoundscore_dsp.so` |

---

## Output Formats

**Guitar & Bass Tab** — Standard ASCII tablature rendered with a custom `TabPainter` canvas widget. Supports standard tuning, drop-D (guitar), and 4- or 5-string bass.

**PDF** — Exportable tab document generated with the `pdf` package, shareable via the system share sheet.

**Sessions** — Named transcription sessions saved locally to SQLite, available for reload and re-export at any time.

**Sheet Music** — Planned: standard notation via VexFlow or OpenSheetMusicDisplay in a WebView.

---

## Roadmap

- [ ] MusicXML, Guitar Pro (.gp) export
- [ ] Audio file input (play a recording, get tab)
- [ ] Sheet music rendering via VexFlow/OSMD
- [ ] Stem separation for multi-track transcription
- [ ] Multi-instrument detection
- [ ] Cloud sync and cross-device session access
- [ ] RevenueCat subscription + AdMob monetization (wired up, not yet active)

---

## Why This Exists

Finding accurate tablature for a song has always been a hassle — when it exists at all. Writing it yourself, even with a dedicated editor, is tedious enough that most musicians just don't bother. Good ideas get lost. Songs go untranscribed. Learning slows down.

TabScribe removes that friction. The goal is to make capturing and sharing musical ideas as easy as hitting record.

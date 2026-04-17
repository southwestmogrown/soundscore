# TabScribe — Implementation Plan

This document tracks planned features, their architecture, and implementation details.
Features are listed in recommended implementation order.

---

## Priority & Complexity Overview

| # | Feature | Complexity | New Dependencies |
|---|---|---|---|
| 1 | Tuner | M | None |
| 2 | Per-note deletion | S | None |
| 3 | Landscape / tablet layout | S | None |
| 4 | Note quantization | M | None |
| 5 | Improved tab calculator (capo, position lock) | M | None |
| 6 | Sheet music rendering (VexFlow) | L | None (`webview_flutter` already present) |
| 7 | Audio file input | M | `ffmpeg_kit_flutter`, `file_picker` |
| 8 | Activate RevenueCat + AdMob | L | None (already in pubspec) |
| 9 | Web / desktop build targets | XL | `sqflite_common_ffi` for desktop |

---

## Feature 1: Tuner

**Status:** Not started

### Approach

The C++ DSP already emits `PitchResult.frequency` and `PitchResult.midiNote` on every frame — the tuner needs continuous streaming, not just onset events. Cents deviation is pure math:

```
cents = 1200 * log2(detectedHz / (a4Hz * pow(2, (midiNote - 69) / 12)))
```

A dedicated `TunerBloc` provisions its own `RecordAudioEngine` + `DspFfiBridge` and emits on every frame (no onset filter). The A4 reference frequency (default 440 Hz) is persisted in `PreferencesService` and exposed in `SettingsPage`.

### UI Components

- Large center note name display (pitch class + octave)
- Cents readout with sign (`+12¢`, `−3¢`)
- Semicircular needle gauge (`CustomPainter`): green within ±5¢, amber ±5–15¢, red beyond ±15¢
- Guitar string reference row (E2 A2 D3 G3 B3 E4) — highlights when detected note matches a string's pitch class
- Configurable A4 reference (432, 440, 443 Hz, or custom)

### New Files

| File | Purpose |
|---|---|
| `lib/features/tuner/tuner_page.dart` | Full tuner UI |
| `lib/features/tuner/tuner_gauge_painter.dart` | `CustomPainter` needle gauge |
| `lib/features/tuner/bloc/tuner_bloc.dart` | Mic + DSP lifecycle; emits every frame |
| `lib/features/tuner/bloc/tuner_state.dart` | `frequency`, `midiNote`, `centsDeviation`, `isActive` |
| `lib/features/tuner/bloc/tuner_event.dart` | `TunerStarted`, `TunerStopped` |
| `lib/core/music/tuner_math.dart` | Pure `centsDeviation(detectedHz, midiNote, {a4 = 440.0})` |

### Modified Files

| File | Change |
|---|---|
| `lib/shared/router/app_router.dart` | Add `Routes.tuner = '/tuner'` and `GoRoute` |
| `lib/features/recording/recording_page.dart` | Tuning fork icon in `AppBar.actions` |
| `lib/core/storage/preferences_service.dart` | `getA4Reference()`, `setA4Reference(double hz)` |
| `lib/features/settings/settings_page.dart` | A4 reference selector |
| `lib/features/settings/bloc/settings_state.dart` | Add `a4Reference: double` |
| `lib/features/settings/bloc/settings_bloc.dart` | Handler for `SettingsA4ReferenceChanged` |

### Gotchas

- Two concurrent `RecordAudioEngine` instances conflict for the mic. Navigating to the tuner must stop any active recording — emit `RecordingStopRequested` on route push, or enforce in `TunerBloc._onStarted`.
- `TunerBloc` must not apply the onset filter (`listenWhen: next.isOnset`). It must process every `PitchResult` with a non-zero frequency.
- `Note.frequency` uses a hardcoded A4 = 440 Hz. `tuner_math.dart` must recompute using the user's reference: `a4Hz * pow(2, (midiNote - 69) / 12)`.

---

## Feature 2: Per-Note Deletion

**Status:** Not started

### Approach

Add tap detection to `TabPainter` via a `GestureDetector` wrapping the `CustomPaint`. Column index from tap position: `col = ((tap.dx - leftMargin) / colWidth).floor()`. Selected note is highlighted in the painter. A delete button appears in the `AppBar` actions when a note is selected.

The `_NoteList` `ListView` below the staff also gets per-item delete affordance (swipe-to-dismiss or long-press).

### Modified Files

| File | Change |
|---|---|
| `lib/features/tablature/bloc/tab_state.dart` | Add `selectedNoteIndex: int?` |
| `lib/features/tablature/bloc/tab_event.dart` | Add `TabNoteSelected(int? index)`, `TabNoteDeleted(int index)` |
| `lib/features/tablature/bloc/tab_bloc.dart` | Handle both events; clamp/clear selection after delete |
| `lib/features/tablature/tab_viewer_page.dart` | `GestureDetector` wrapping painter; conditional delete in `AppBar` |
| `lib/features/tablature/tab_painter.dart` | Add `selectedIndex: int?`; draw highlight rect at selected column |

### Gotchas

- The `GestureDetector` must wrap `CustomPaint` *inside* the `SingleChildScrollView` — not above it — so `localPosition` is in the painter's coordinate space after scroll translation.
- After deletion, `selectedNoteIndex` must be cleared or clamped to prevent an out-of-bounds index on the next render.

---

## Feature 3: Landscape / Tablet Layout

**Status:** Not started

### Approach

Remove the portrait-only lock in `bootstrap.dart`. Apply `OrientationBuilder` in `RecordingPage` to switch from `Column` to `Row` in landscape (metrics left, record button right). Expose `colWidth` as a `TabPainter` parameter so tablets fit more tab columns. Hide the `_NoteList` in landscape to give the staff full height.

Tablet detection: `MediaQuery.of(context).size.shortestSide > 600`.

### Modified Files

| File | Change |
|---|---|
| `lib/bootstrap.dart` | Remove or conditionally apply portrait lock (phones only via `shortestSide < 600`) |
| `lib/features/recording/recording_page.dart` | `OrientationBuilder` layout switch |
| `lib/features/tablature/tab_viewer_page.dart` | Hide `_NoteList` in landscape |
| `lib/features/tablature/tab_painter.dart` | Expose `colWidth` as constructor parameter |

### Gotchas

- The orientation lock in `bootstrap.dart` is a single global call. Test both phone and tablet form factors after removing it.

---

## Feature 4: Note Quantization

**Status:** Not started

### Approach

`TabNote` grows an optional `timestampMs` field, set from `DateTime.now().millisecondsSinceEpoch` at the moment `TabNoteAdded` is fired in `RecordingPage`. A `NoteQuantizer` class snaps each onset to the nearest rhythmic grid division (whole / half / quarter / 8th / 16th) given the detected BPM. Quantization is on-demand (a "Quantize" button in the tab viewer) rather than eager, since BPM detection needs time to stabilize.

Snapping algorithm: given BPM, compute beat duration in ms. For each onset offset from the first note, find the rhythmic subdivision with the smallest absolute error. Accept if error < 35% of the subdivision duration.

### New Files

| File | Purpose |
|---|---|
| `lib/core/music/note_quantizer.dart` | `quantize(double bpm, List<TabNote>) → List<QuantizedTabNote>` |
| `lib/core/music/rhythmic_value.dart` | Enum `{ whole, half, quarter, eighth, sixteenth }` with `durationInBeats` |

### Modified Files

| File | Change |
|---|---|
| `lib/core/music/tab_note.dart` | Add `final int? timestampMs` |
| `lib/core/storage/session.dart` | Persist `timestampMs` in JSON (nullable, backward-compatible) |
| `lib/features/recording/recording_page.dart` | Pass `DateTime.now().millisecondsSinceEpoch` in `TabNoteAdded` |
| `lib/features/tablature/bloc/tab_event.dart` | Add `timestampMs` to `TabNoteAdded` |
| `lib/features/tablature/bloc/tab_bloc.dart` | Forward timestamp when constructing `TabNote` |
| `lib/features/tablature/tab_viewer_page.dart` | Add "Quantize" action button |
| `lib/core/export/tab_export_service.dart` | Use rhythmic values for rest spacing in `toText()` |

### Gotchas

- Guard against `bpm == 0.0` (insufficient onsets accumulated). Skip quantization or use a user-supplied default BPM.
- Sessions saved before this ships have `timestampMs == null` on all notes and cannot be quantized — handle gracefully in the UI.
- `Session._decodeNotes` must use `map['ts'] as int?` with a null default, not throw on missing key.

---

## Feature 5: Improved Tab Calculator

**Status:** Not started

### Approach

Extend `TabCalculator` with three improvements:

**Capo awareness:** Add `int capo = 0`. Fret calculation becomes `fret = midiNote - tuning[s] - capo`. Display fret is the physical position above the capo.

**Position lock:** Add `int minFret = 0`, `int maxFret = 24`. Candidates where `fret < minFret || fret > maxFret` are excluded from scoring.

**Chord voicing:** Add `chordToTabNotes(List<int> midiNotes) → List<TabNote>`. Greedy algorithm: sort notes low to high, assign each to the lowest-numbered available string that can play it within the position window. Skip notes with no valid assignment.

New settings for capo, minFret, maxFret persisted in `PreferencesService` and exposed in `SettingsPage`.

### Modified Files

| File | Change |
|---|---|
| `lib/core/music/tab_calculator.dart` | Add capo, position lock params, `chordToTabNotes` method |
| `lib/core/storage/preferences_service.dart` | `getCapo`, `setCapo`, `getPositionLock`, `setPositionLock` |
| `lib/features/settings/settings_page.dart` | Capo slider (0–12), position lock range input |
| `lib/features/settings/bloc/settings_state.dart` | Add `capoFret`, `minFret`, `maxFret` |
| `lib/features/settings/bloc/settings_bloc.dart` | Event handlers for new settings fields |
| `lib/features/tablature/bloc/tab_event.dart` | Add `TabChordAdded(List<int> midiNotes)` |
| `lib/features/tablature/bloc/tab_bloc.dart` | `on<TabChordAdded>` calling `chordToTabNotes` |

### Gotchas

- Capo + position lock interact: with capo at fret 5 and a lock of 5–9, the physical fretboard range is 10–14 but displayed frets are 5–9. Be explicit about coordinate systems in code.
- Full chord voicing requires per-note MIDI detection from the DSP (simultaneous notes). The C++ layer currently returns a chord label string but not individual MIDI values per chord tone. A complete implementation requires either extending the native ABI or deriving chord tones from the label in Dart.

---

## Feature 6: Sheet Music Rendering (VexFlow)

**Status:** Placeholder exists (`SheetMusicPage` is a one-liner)

### Approach

Bundle `assets/html/sheet_music.html` with VexFlow JS as a local asset (not CDN — avoids cleartext/CORS issues on Android). Flutter passes note data via `WebViewController.runJavaScript('renderNotes([...])')`. A `BlocListener<TabBloc>` triggers re-render whenever `TabState.notes` changes.

VexFlow note format: `{"keys": ["c#/4"], "duration": "q"}`. A `VexflowBridge` utility class converts `List<TabNote>` to this JSON array. Duration is `"q"` (quarter note) by default, upgraded to the quantizer output once Feature 4 is implemented.

### New Files

| File | Purpose |
|---|---|
| `assets/html/sheet_music.html` | Bundled VexFlow page with `renderNotes(json)` JS entry point |
| `lib/features/sheet_music/vexflow_bridge.dart` | Serializes `List<TabNote>` → VexFlow JSON |

### Modified Files

| File | Change |
|---|---|
| `lib/features/sheet_music/sheet_music_page.dart` | Replace placeholder with `WebView` + `BlocListener<TabBloc>` |
| `lib/features/recording/recording_page.dart` | Sheet music nav button alongside "View Tab" FAB |

### Gotchas

- VexFlow pitch format (`"c#/4"`) uses slash-octave notation — `VexflowBridge` must insert the slash between pitch class and octave. The existing `Note` class uses `"C#4"` format.
- Sharps/flats belong in the `keys` element itself (`"c#/4"`), not as a separate accidental field.
- Bundle VexFlow JS as an asset rather than loading from CDN. CDN loading requires `allowsInlineMediaPlayback` quirks on iOS and cleartext network on Android.

---

## Feature 7: Audio File Input

**Status:** Not started (promised in README, not implemented)

### Approach

Add `FileAudioEngine implements AudioEngine`. Uses `ffmpeg_kit_flutter` to decode any audio format to a temp `.pcm` file with the command:

```
ffmpeg -i input.mp3 -ar 44100 -ac 1 -f s16le output.pcm
```

The output is streamed in 2048-sample `Int16List` chunks — matching the existing DSP pipeline exactly. File selection via `file_picker`. A new `RecordingFilePickRequested` event in `RecordingBloc` handles the full flow; mic permission is skipped for file mode.

### New Files

| File | Purpose |
|---|---|
| `lib/core/audio/file_audio_engine.dart` | `FileAudioEngine implements AudioEngine`; FFmpeg decode + chunk streaming |

### Modified Files

| File | Change |
|---|---|
| `lib/features/recording/bloc/recording_event.dart` | Add `RecordingFilePickRequested` |
| `lib/features/recording/bloc/recording_bloc.dart` | `on<RecordingFilePickRequested>`; skip mic permission for file mode |
| `lib/features/recording/recording_page.dart` | "Open File" button alongside mic record button |
| `pubspec.yaml` | Add `ffmpeg_kit_flutter: ^6.0.3`, `file_picker: ^8.1.2` |
| `android/app/build.gradle` | Bump `minSdkVersion` to 24 (required by ffmpeg_kit) |

### Gotchas

- `ffmpeg_kit_flutter` adds ~20 MB to the binary. Use `ffmpeg_kit_flutter_min` for a smaller footprint — covers MP3/AAC/WAV/M4A which is sufficient.
- Resampling is critical: if the source is not 44.1 kHz, `-ar 44100` in the FFmpeg command is mandatory. Omitting it produces silent DSP failures (garbage confidence values).
- The temp PCM file must be deleted in `FileAudioEngine.dispose()` to avoid storage leaks.
- The current `_onStartRequested` handler calls `_permissions.requestMicrophone()`. File mode must skip this branch.

---

## Feature 8: Activate RevenueCat + AdMob

**Status:** Stubs exist; no concrete implementations

### Approach

Both `AdService` and `SubscriptionService` are abstract classes with no implementations. `AppConfig` already has all API key fields. `purchases_flutter` and `google_mobile_ads` are already in `pubspec.yaml`.

**RevenueCat:** Implement `RevenueCatSubscriptionService`. Call `Purchases.configure(PurchasesConfiguration(apiKey))` in `initialize()`. Bridge `Purchases.addCustomerInfoUpdateListener` callback to a `StreamController<bool>` for `isPro`.

**AdMob:** Implement `AdMobAdService`. Call `MobileAds.instance.initialize()` in `initialize()`. Manage `InterstitialAd` lifecycle in `showInterstitial()`. Provide a `BannerAdWidget` for embedding in pages.

**Pro gating:** Add `SubscriptionCubit` to `app.dart`'s `MultiBlocProvider`. Gate:
- PDF export in `TabViewerPage` → check `isPro` before calling `sharePdf`
- Session count limit (e.g., 3 for free tier) in `TabBloc._onSessionSave`
- Banner ad visibility in `RecordingPage` → show only when `!isPro`

### New Files

| File | Purpose |
|---|---|
| `lib/core/monetization/revenue_cat_subscription_service.dart` | Concrete RevenueCat implementation |
| `lib/core/monetization/admob_ad_service.dart` | Concrete AdMob implementation |
| `lib/core/monetization/subscription_cubit.dart` | Exposes `isPro` stream to widget tree |
| `lib/shared/widgets/pro_gate.dart` | Utility widget; redirects to paywall if not Pro |

### Modified Files

| File | Change |
|---|---|
| `lib/app.dart` | Add `SubscriptionCubit` to `MultiBlocProvider`; call `initialize()` |
| `lib/bootstrap.dart` | Call `AdMobAdService().initialize()` during startup |
| `lib/features/subscription/paywall_page.dart` | Full RevenueCat offerings UI + restore purchases |
| `lib/features/tablature/tab_viewer_page.dart` | Gate PDF export behind `isPro` |
| `lib/features/recording/recording_page.dart` | Conditional `BannerAdWidget` |
| `android/app/src/main/AndroidManifest.xml` | Add AdMob App ID meta-data |
| `ios/Runner/Info.plist` | Add `GADApplicationIdentifier` |

### Gotchas

- AdMob App IDs must be in native manifests at **build time** — the app crashes on launch even if the Dart `initialize()` is never called. Use test IDs (already in `AppConfig.dev`) for non-prod builds.
- RevenueCat entitlements require App Store Connect / Google Play product setup before they resolve. Use StoreKit sandbox on iOS during development.
- `Purchases.addCustomerInfoUpdateListener` is callback-based; bridge to `StreamController<bool>` with an initial emit from `getCustomerInfo()`.
- Test purchases require a real device — iOS Simulator and Android Emulator have restrictions.

---

## Feature 9: Web / Desktop Build Targets

**Status:** Not started

### Approach

Platform-conditional code spans three layers. Best tackled after all mobile features are stable.

**Audio capture:** The `record` package does not support web. Create `WebAudioEngine implements AudioEngine` using `dart:js_interop` + an `AudioWorkletProcessor` JS worker. Float32 buffers downconverted to Int16List before being pushed into the Dart stream.

**FFI bridge:** `DspFfiBridge` uses `DynamicLibrary.open`. For macOS: `DynamicLibrary.open('libsoundscore_dsp.dylib')`. For web: compile C++ DSP to WASM via Emscripten, or implement a pure-Dart YIN pitch detector as fallback.

**Storage:** `sqflite` is mobile-only. Add `sqflite_common_ffi` for macOS/Linux/Windows. For web, use `drift` with a web worker backend.

**Conditional compilation:** `google_mobile_ads` and `purchases_flutter` have no web implementations — exclude via conditional imports or `kIsWeb` guards.

### New Files

| File | Purpose |
|---|---|
| `lib/core/audio/web_audio_engine.dart` | `WebAudioEngine implements AudioEngine` via `dart:js_interop` |
| `lib/core/audio/audio_engine_factory.dart` | Platform factory: returns correct `AudioEngine` impl per platform |
| `web/audio_worklet_processor.js` | JS AudioWorklet for PCM capture in browser |
| `lib/core/dsp/dart_pitch_detector.dart` | Pure-Dart YIN algorithm as web/WASM fallback |

### Modified Files

| File | Change |
|---|---|
| `lib/core/audio/ffi_bridge.dart` | `kIsWeb` guard; add macOS `dylib` path |
| `lib/features/recording/recording_page.dart` | Use `AudioEngineFactory.create()` instead of `RecordAudioEngine()` |
| `lib/bootstrap.dart` | Skip orientation lock on desktop/web |
| `pubspec.yaml` | Add `sqflite_common_ffi: ^2.3.3` |

### Gotchas

- Web Audio API requires a user gesture before `getUserMedia`. The existing record button satisfies this.
- WASM compilation of the C++ DSP requires the Emscripten toolchain and a separate build pipeline — this is a large standalone effort.
- `webview_flutter` web support loads assets via the browser's asset server, which differs from `loadFlutterAsset()` on mobile.
- This feature has the most risk and the most unknowns. Tackle it last.

---

## Dependency Changes Summary

| Package | Feature | Action |
|---|---|---|
| `ffmpeg_kit_flutter: ^6.0.3` | Feature 7 — file input | Add |
| `file_picker: ^8.1.2` | Feature 7 — file input | Add |
| `sqflite_common_ffi: ^2.3.3` | Feature 9 — desktop | Add |
| All others | Features 1–6, 8 | Already in `pubspec.yaml` |

---

## Critical Extension Points

These are the seams where most features plug in:

- `lib/core/audio/audio_engine.dart` — Abstract interface for Features 1 (file), 7 (file input), 9 (web engine)
- `lib/features/tablature/bloc/tab_bloc.dart` — Central coordinator for Features 3 (quantization), 4 (calculator), 5 (deletion)
- `lib/core/music/tab_calculator.dart` — Output `TabNote` flows into export, painter, and sheet music
- `lib/shared/router/app_router.dart` — Single registration point for all new routes (tuner, paywall)
- `lib/bootstrap.dart` — Startup sequence for orientation lock, AdMob init, platform-conditional setup

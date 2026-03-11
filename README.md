# 🎵 TabScribe

> *Finding accurate tab online is a hassle. Writing it yourself is an even bigger one. TabScribe does it for you.*

TabScribe is a mobile app for musicians that listens to audio — live from your microphone or from a file on your device — and generates accurate guitar tab, bass tab, sheet music, and chord charts automatically.

Hear a riff you want to learn? Play it or play the recording. TabScribe transcribes it. Share it, save it, build on it.

Available on **iOS** and **Android**.

---

## 🎸 What It Does

| Input | Output |
|---|---|
| 🎙️ Live microphone | 🎸 Guitar tablature |
| 📁 Audio file from device | 🎵 Bass tablature |
| | 📄 Sheet music / standard notation |
| | 🎼 Chord charts |

No more hunting through seventeen different tab sites hoping one of them is accurate. No more staring at a tab editor trying to remember which string is which. Just play it — or find the recording — and let the app do the rest.

---

## 🎯 Built For

- **Learners** — transcribe songs you want to learn, instantly
- **Teachers** — generate readable notation to share with students
- **Songwriters** — capture and notate ideas before you forget them
- **Collaborators** — share ideas in a format anyone can read and play

---

## 📱 Platform

| Platform | Minimum Version |
|---|---|
| Android | API 15+ |
| iOS | iOS 12+ |

Built with **Flutter** — a single codebase for both platforms.

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| Mobile Framework | Flutter (Dart) |
| Audio Input | Device microphone + file picker |
| Transcription | Audio ML pipeline |
| Output Formats | Tab, sheet music, chord charts |

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.0+)
- Android Studio or Xcode (depending on target platform)
- A physical device or emulator

### 1. Clone and Install

```bash
git clone <your-repo-url>
cd tabscribe
flutter pub get
```

### 2. Run

```bash
# Run on connected device or emulator
flutter run

# Run on specific platform
flutter run -d android
flutter run -d ios
```

---

## 🎼 Output Formats

**Guitar & Bass Tab** — Standard ASCII tablature, the format every guitarist already knows how to read.

**Sheet Music** — Standard notation for musicians who read music, and for sharing across instruments.

**Chord Charts** — Clean, readable chord diagrams for rhythm players and singers who just need the changes.

All outputs are shareable directly from the app.

---

## 💡 Why This Exists

Finding full, accurate tablature for a song has always been a hassle — when it exists at all. Writing it yourself, even with a dedicated editor, is tedious enough that most musicians just don't bother. Good ideas get lost. Songs go untranscribed. Learning slows down.

TabScribe removes that friction entirely. The goal is to make sharing musical ideas and learning from recordings as easy as hitting record.

---

## 🗺️ Roadmap

- [ ] Real-time transcription while playing
- [ ] Export to MusicXML, PDF, Guitar Pro
- [ ] Integration with Guitar Hub for stem-based transcription
- [ ] Multi-instrument detection

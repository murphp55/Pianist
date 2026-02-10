# Pianist Practice Lab

A Flutter-based piano practice companion that connects to MIDI keyboards, provides structured practice plans, evaluates note accuracy with metronome timing, and tracks progress.

![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue.svg)
![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20Android%20%7C%20Fire%20OS-green.svg)

## Features

✨ **Practice Plans** - Structured daily sessions and per-key exercises
🎹 **MIDI Integration** - Connect your keyboard for real-time practice
⏱️ **Metronome** - Visual + audio tempo guidance with timing validation
📊 **Progress Tracking** - Automatic saving of task completion and accuracy
🎯 **Real-time Feedback** - Instant note validation with visual indicators
🎨 **Modern UI** - Responsive design with accessibility features
📈 **Task Difficulty** - 1-3 star ratings based on tempo and complexity
💡 **Help System** - Built-in practice tips and guidance

## Screenshots

<kbd>Connection & Practice Interface</kbd>
- MIDI device selection with animated connection status
- Task list with difficulty indicators and status badges
- Real-time fingering diagram and progress tracking
- Metronome beat indicator for tempo-based exercises

## Quick Start

### Prerequisites
- Flutter 3.0 or higher
- Windows PC or Android device (including Fire tablets)

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/murphp55/Pianist.git
   cd Pianist
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run on Windows:**
   ```bash
   flutter run -d windows
   ```

4. **Run on Android/Fire Tablet:**
   - Enable USB debugging on your device
   - Connect via USB
   - Run:
     ```bash
     flutter run -d android
     ```

### Optional: Add Metronome Audio
Place an MP3 click sound at `assets/sounds/metronome_click.mp3` and uncomment the asset in `pubspec.yaml`. The app works in visual-only mode without audio.

## How to Use

1. **Connect MIDI Device** - Select your keyboard from the dropdown and click Connect (or use mock devices for testing)
2. **Choose Practice Plan** - Switch between Daily Session and Per-Key Extras
3. **Select a Task** - Click any task to view details and fingering diagram
4. **Start Practicing** - Click Start and play the notes shown in the diagram
5. **Track Progress** - Watch the animated progress bar and real-time feedback
6. **Complete Tasks** - Achieve perfect accuracy or manually mark as complete

## Practice Plans

### Daily Session
- **Warm-up** - Chromatic patterns and basic arpeggios
- **Scales** - C Major 1-2 octaves with metronome
- **Arpeggios** - Various C Major patterns
- **Chords** - Triads and chord progressions
- **Technique** - Finger independence exercises

### Per-Key Extras
- Advanced exercises for each key
- Supplementary patterns and sight-reading prep

## Technology

- **Framework:** Flutter/Dart
- **State Management:** Provider pattern
- **Audio:** just_audio (metronome clicks)
- **Logging:** logger package for error tracking
- **MIDI:** Platform channels (mock fallback for development)

## Project Structure

```
lib/
├── main.dart              # UI components and app shell
├── models/                # Data models (tasks, results, notes)
├── services/              # Business logic (MIDI, metronome, evaluation)
├── viewmodels/            # State management
├── helpers/               # Utilities
└── widgets/               # Custom widgets (diagrams, indicators)
```

## Development

### Run Tests
```bash
flutter analyze
```

### Build Release APK
```bash
flutter build apk --release
```

### Check Connected Devices
```bash
flutter devices
```

## Known Limitations

- Currently supports C Major only (multi-key support planned)
- MIDI uses mock devices (platform implementation pending)
- No practice session history/analytics yet
- Metronome tolerance (±20%) is not user-configurable

## Contributing

This is a personal practice tool, but suggestions and issues are welcome! Please open an issue on GitHub.

## Roadmap

- [ ] Real MIDI platform plugins for Windows/Android
- [ ] Multi-key support (all major and minor keys)
- [ ] Practice session history and analytics
- [ ] Pause/resume functionality
- [ ] Configurable metronome tolerance
- [ ] Export progress data
- [ ] Unit and integration tests

## License

This project is for personal use and educational purposes.

## Acknowledgments

Built with Flutter and inspired by the need for structured piano practice with real-time feedback.

---

**For Developers:** See [AI_CONTEXT.md](AI_CONTEXT.md) for comprehensive project documentation and architecture details.

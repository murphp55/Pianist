# Pianist (Flutter)

Pianist is a Flutter practice companion for piano. It connects to a MIDI input device, guides the user through a practice plan, evaluates note accuracy (with optional metronome timing), and tracks progress locally.

## Features (Current Scaffold)

- Practice plan with sections and tasks
- MIDI device list + connect/disconnect flow (platform channel placeholder + mock fallback)
- Note evaluation with basic metronome tolerance
- Local progress persistence in `progress.json`
- Fingering diagram overlay with expected notes

## Build And Run

Windows:

```powershell
flutter run -d windows
```

Android (including Fire OS):

```powershell
flutter run -d android
```

## Project Layout

- `lib/main.dart`: App shell and UI
- `lib/models/`: Practice tasks, results, and fingerings
- `lib/services/`: MIDI service abstraction, evaluator, progress store
- `lib/viewmodels/`: App state and bindings
- `lib/helpers/`: Note name helper
- `lib/widgets/`: Custom painters (fingering diagram)

## Next Steps

- Implement platform MIDI plugins for Windows and Android
- Replace mock devices with real device discovery
- Mirror MAUI evaluation edge cases and timing logic
- Add automated tests for evaluator logic

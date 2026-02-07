# PianistApp Agent Notes

## What This App Does
Pianist is a .NET MAUI practice companion for piano. It connects to a MIDI input device (USB or Bluetooth), guides the user through a built-in practice plan, and evaluates note accuracy and optional metronome timing. It shows lesson details, expected notes, live feedback on the last note played, and a simple fingering diagram overlay on a rendered keyboard. Progress is tracked per task and stored locally.

## Key Behaviors
- Loads a default practice plan and table of contents defined in `MainWindow.xaml.cs`.
- Connects to MIDI devices via NAudio and listens for `NoteOn` events.
- Evaluates practice tasks by checking expected note sequences and optional metronome timing.
- Records completions and verdicts (Pass/Needs work/Completed) in a local JSON file.
- Renders a fingering diagram based on per-task finger assignments.

## Local Data
- Progress is saved to `%AppData%\Pianist\progress.json` via `ProgressStore`.

## Build And Run
```powershell
dotnet build
dotnet run -f net10.0-windows10.0.19041.0
```

```powershell
dotnet build -f net10.0-android
```

## Project Layout
- `MainPage.xaml` and `MainPage.xaml.cs`: UI and primary orchestration.
- `Services/`: MIDI input, practice evaluation, and progress persistence.
- `Models/`: Practice tasks, results, and fingerings.
- `ViewModels/`: UI state and bindings.
- `Helpers/`: Note name conversion.
- `Converters/`: UI converters.
- `Drawables/`: MAUI drawing for the fingering diagram.

## Tests
No automated tests are present.

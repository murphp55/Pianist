# Pianist - AI Context & Project Overview

> **Purpose:** This file provides comprehensive context for AI assistants working on the Pianist project.
> **Last Updated:** 2026-02-10

## Project Summary

Pianist is a Flutter-based piano practice companion that connects to MIDI keyboards, provides structured practice plans per key signature, evaluates note accuracy with optional metronome timing, and tracks progress. The app guides users through daily practice sessions with real-time feedback and fingering diagrams.

## Technology Stack

### Core Framework
- **Flutter/Dart** - Cross-platform UI framework
- **Provider** (^6.1.2) - State management

### Key Dependencies
- **logger** (^2.5.0) - Structured logging for error handling
- **just_audio** (^0.9.40) - Audio playback for metronome clicks
- **Platform Channels** - Native MIDI device integration (mock fallback for development)

### Supported Platforms
- ✅ **Windows** - Primary development platform
- ✅ **Android** - Including Amazon Fire tablets (Fire OS)
- ⚠️ **iOS** - Not tested but should work
- ⚠️ **Web** - MIDI support limited

## Architecture Overview

### State Management
- **Provider pattern** with single `AppState` class
- Centralized state in `lib/viewmodels/app_state.dart` (241 lines)
- App state tracks selected key signature and rebuilds practice plans when the key changes
- Proper lifecycle management with dispose() methods to prevent memory leaks

### Key Services (lib/services/)

#### `midi_service.dart`
- **Purpose:** Abstraction layer for MIDI device communication
- **Implementation:** Platform channels with mock fallback
- **Components:**
  - `MidiServiceFactory` - Creates platform or mock service
  - `PlatformMidiService` - Real MIDI via method channels
  - `MockMidiService` - Simulated devices for development
- **Key Methods:** `listDevices()`, `connect()`, `disconnect()`, `noteStream`
- **Error Handling:** Comprehensive logging with PlatformException handling

#### `metronome_service.dart`
- **Purpose:** Audio + visual metronome for tempo-based practice
- **Implementation:**
  - `just_audio` for click playback
  - Timer-based beat generation (4/4 time signature)
  - Stream-based beat notifications
- **Features:**
  - Adjustable BPM
  - Graceful degradation without audio file
  - Visual-only mode support
- **Key Methods:** `start(bpm)`, `stop()`, `beatStream`, `dispose()`

#### `progress_store.dart`
- **Purpose:** Persist practice progress to local JSON file
- **Location:** `progress.json` in app support directory
- **Error Handling:** Specific exception handling for FileSystemException and FormatException
- **Returns:** bool from save() to indicate success/failure

#### `plan_factory.dart` (Refactored from AppState)
- **Purpose:** Build structured practice plans per key signature
- **Size:** 393 lines
- **Methods:**
  - `buildDailyPlan({key})` - Main practice session by key
  - `buildExtrasPlan({key})` - Per-key supplementary exercises
- **Contains:** All practice plan building logic including scales, arpeggios, chord progressions, and fingerings

#### `practice_evaluator.dart`
- **Purpose:** Evaluate played notes against expected sequence
- **Features:**
  - Note accuracy validation
  - Metronome timing tolerance (±20%)
  - Progress tracking with "needs work" detection
  - Timing penalty logic (reverts progress on poor timing)
  - Note name rendering uses key signature via `NoteNameHelper`

#### `app_logger.dart` (NEW)
- **Purpose:** Centralized structured logging
- **Implementation:** Uses `logger` package with PrettyPrinter
- **Methods:** `debug()`, `info()`, `warning()`, `error()`
- **Usage:** Throughout services for error tracking and debugging

### Models (lib/models/)
- **practice_task.dart** - Task/section definitions with metadata (tempo, metronome requirement)
- **practice_plan.dart** - Practice plan wrapper with section lookup
- **practice_result.dart** - Evaluation results and verdicts (pass, completed, needsWork)
- **task_progress.dart** - Progress map for practice results
- **fingered_note.dart** - MIDI note with fingering information
- **key_signature.dart** - Major key definitions, scale patterns, and fingerings

### Helpers (lib/helpers/)
- **note_name_helper.dart** - Note name rendering with sharps/flats and key signature support

### Widgets (lib/widgets/)
- **fingering_diagram.dart** - Custom painter for piano keyboard visualization with note names
- **metronome_indicator.dart** (NEW) - Visual 4-beat indicator with pulsing animations

### UI Structure (lib/main.dart)

**Main Components:**
- `AppShell` - Root scaffold with responsive layout and app bar status
- `_MidiDialog` - MIDI device selection and connection dialog
- `_SimplifiedPlanPanel` - Practice plan list with key selector
- `_DiagramFocusedPanel` - Large fingering diagram and compact feedback
- `_TaskTile` - Individual task with difficulty stars and status badge
- `_CompactFeedbackPanel` - Compact expected vs played note tiles
- `_HelpPanel` - Practice tips and keyboard shortcuts (expandable)
- `_DebugPanel` - Development tools (simulate notes)

**Responsive Breakpoints:**
- Wide (>800px): Side-by-side 2:5 ratio (plan list + diagram focus)
- Narrow (≤800px): Stacked vertical layout

## Recent Major Changes (2026-02-10)

### Key Updates:

1. **Multi-Key Major Support**
   - Added `KeySignature` model with 12 major keys and fingerings
   - Practice plans are generated per selected key
   - Note naming honors key signature (sharps/flats)

2. **Key Selection UI**
   - Key selector dropdown added to the plan panel
   - Plans rebuild when key changes
   - Fingering diagram displays key-accurate note names

3. **UI Layout Refresh**
   - New diagram-focused panel with larger fingering view
   - MIDI settings moved into a modal dialog
   - Compact feedback tiles for expected/played notes

## Known Issues & Limitations

### Platform-Specific:
- **Windows:** just_audio plugin may not work without additional setup (app runs in visual-only mode)
- **Fire Tablets:** Requires sideloading (no Google Play Services)
- **MIDI:** Platform channels exist; app falls back to mock devices when plugins/devices aren't available

### Feature Gaps:
- Only supports major keys (no minor keys yet)
- No practice session history/analytics
- No undo/redo functionality
- No export functionality for progress data
- No pause/resume (only reset)
- Metronome tolerance (±20%) not user-configurable

### Technical Debt:
- No unit tests
- No integration tests
- Timing penalty logic may be too harsh for beginners
- Many hardcoded values (colors, breakpoints, tolerances)
- No localization support

## Development Guidelines

### Code Style:
- Follow Flutter/Dart conventions
- Use meaningful variable names
- Keep widget methods under 100 lines
- Extract complex logic to separate methods
- Add comments for non-obvious logic only

### State Management:
- All state changes through AppState
- Use notifyListeners() after state mutations
- Properly dispose of StreamSubscriptions and controllers
- Avoid memory leaks

### Error Handling:
- Use AppLogger for all logging
- Catch specific exceptions (FileSystemException, PlatformException, etc.)
- Provide user-friendly error messages
- Graceful degradation for missing features

### UI Development:
- Responsive design (wide vs narrow breakpoint)
- Add tooltips to interactive elements
- Include semantic labels for accessibility
- Use consistent spacing (8px increments)
- Follow existing color scheme (Color(0xFF...))

### Testing Before Commit:
1. Run `flutter analyze` (should pass except metronome asset warning)
2. Test on target platform (Windows/Android)
3. Verify no memory leaks (check dispose() calls)
4. Test with and without MIDI devices

## File Structure

```
lib/
├── main.dart                    # App shell and UI (1800+ lines)
├── models/
│   ├── fingered_note.dart
│   ├── key_signature.dart
│   ├── practice_plan.dart
│   ├── practice_result.dart
│   ├── task_progress.dart
│   └── practice_task.dart
├── services/
│   ├── app_logger.dart          # NEW: Structured logging
│   ├── midi_service.dart        # MIDI abstraction
│   ├── metronome_service.dart   # NEW: Audio + visual metronome
│   ├── plan_factory.dart        # NEW: Practice plan builders
│   ├── practice_evaluator.dart  # Note validation
│   └── progress_store.dart      # JSON persistence
├── viewmodels/
│   └── app_state.dart           # Central state (241 lines)
├── helpers/
│   └── note_name_helper.dart
└── widgets/
    ├── fingering_diagram.dart
    └── metronome_indicator.dart  # NEW: Visual beat display

assets/
└── sounds/
    └── README.md                # Instructions for metronome click file

pubspec.yaml                     # Dependencies and config
```

## Practice Plan Structure

### Daily Plan (Per Selected Key):
1. **Scales** - 2-octave scales by key
2. **Arpeggios** - 2-octave arpeggios by key
3. **Chord Inversions** - I chord inversions by key

### Per-Key Extras:
- Additional exercises for each key
- Advanced patterns
- Sight-reading preparation

## Metronome System

### Audio:
- **File:** `assets/sounds/metronome_click.mp3` (currently missing, app works without)
- **Playback:** just_audio plugin
- **Fallback:** Visual-only mode if audio fails

### Visual:
- 4 pulsing circles (4/4 time)
- Downbeat (beat 0): Orange, larger size
- Other beats: Green, smaller size
- Active only during practice sessions

### Timing Tolerance:
- ±20% of beat interval (hardcoded)
- Wrong timing reverts progress (may be too harsh)

## MIDI Integration

### Current State:
- **Development:** Mock devices with simulate button
- **Production:** Platform channels ready, native plugins pending

### Mock Devices:
- "Mock MIDI Keyboard"
- "Bluetooth Piano (Mock)"
- Simulate button sends C4 (MIDI 60)

### Real MIDI (When Implemented):
- USB MIDI devices on Windows/Android
- Device discovery via platform channels
- NoteOn events with velocity

## Progress Tracking

### Storage:
- **Location:** `progress.json` in app support directory
- **Format:** JSON map of task ID → PracticeResult
- **Persistence:** Auto-save after each task completion

### Task Verdicts:
- **Pass** - Perfect accuracy achieved
- **Completed** - Manually marked done
- **Needs Work** - Attempted but accuracy < threshold
- **Not Attempted** - Never started

## Git Workflow

### Commit Style:
- Descriptive first line (50-70 chars)
- Blank line
- Detailed body with categories (Core Fixes, New Services, UI Enhancements, etc.)
- List specific files changed
- Include Co-Authored-By for AI assistance

### Branching:
- **main** - Production-ready code
- Feature branches as needed

## Quick Commands

### Development:
```bash
# Run on Windows
flutter run -d windows

# Run on Android (USB debugging)
flutter run -d android

# Build release APK
flutter build apk --release

# Analyze code
flutter analyze

# Check devices
flutter devices
```

### Git:
```bash
# Status and diff
git status
git diff

# Commit changes
git add <files>
git commit -m "message"
git push
```

## Future Enhancements (Planned)

### High Priority:
- Implement real MIDI platform plugins
- Add pause/resume functionality
- Make metronome tolerance configurable
- Add practice session history

### Medium Priority:
- Minor key support
- Export progress data
- Session timer
- Undo/redo functionality

### Low Priority:
- Dark mode
- Customizable color themes
- Onboarding flow
- Completion celebration animations
- Unit and integration tests

## Troubleshooting

### App won't build:
- Check `flutter doctor` for issues
- Ensure all dependencies in pubspec.yaml are compatible
- Run `flutter clean` then `flutter pub get`

### MIDI not working:
- Expected if the platform MIDI plugin isn't available or no devices are detected
- Use "Simulate Note" button for testing

### Metronome has no audio:
- Expected if `assets/sounds/metronome_click.mp3` is missing
- Visual metronome still works
- See `assets/sounds/README.md` for instructions

### Fire Tablet deployment issues:
- Enable USB debugging in Developer Options
- Allow apps from unknown sources
- Check USB connection mode (File Transfer, not charging only)

## Contact & Resources

- **Repository:** https://github.com/murphp55/Pianist
- **Flutter Docs:** https://docs.flutter.dev
- **MIDI Spec:** https://www.midi.org/specifications

---

**Note for AI Assistants:**
- Always run `flutter analyze` before committing
- Follow existing code patterns and naming conventions
- Test on target platform before major changes
- Document significant changes in commit messages

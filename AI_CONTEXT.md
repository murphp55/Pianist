# Pianist - AI Context & Project Overview

> **Purpose:** This file provides comprehensive context for AI assistants working on the Pianist project.
> **Last Updated:** 2026-02-09

## Project Summary

Pianist is a Flutter-based piano practice companion that connects to MIDI keyboards, provides structured practice plans, evaluates note accuracy with optional metronome timing, and tracks progress. The app guides users through daily practice sessions with real-time feedback.

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
- Centralized state in `lib/viewmodels/app_state.dart` (217 lines after refactoring)
- Proper lifecycle management with dispose() methods to prevent memory leaks

### Key Services (lib/services/)

#### `midi_service.dart`
- **Purpose:** Abstraction layer for MIDI device communication
- **Implementation:** Platform channels with mock fallback
- **Components:**
  - `MidiServiceFactory` - Creates platform or mock service
  - `PlatformMidiService` - Real MIDI via method channels
  - `MockMidiService` - Simulated devices for development
- **Key Methods:** `getDevices()`, `connect()`, `disconnect()`, `noteStream`
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
- **Location:** `progress.json` in app documents directory
- **Error Handling:** Specific exception handling for FileSystemException and FormatException
- **Returns:** bool from save() to indicate success/failure

#### `plan_factory.dart` (NEW - Refactored from AppState)
- **Purpose:** Build structured practice plans
- **Size:** 353 lines extracted from AppState
- **Methods:**
  - `buildDailyPlan()` - Main practice session
  - `buildExtrasPlan()` - Per-key supplementary exercises
- **Contains:** All practice plan building logic including scales, arpeggios, chord progressions

#### `practice_evaluator.dart`
- **Purpose:** Evaluate played notes against expected sequence
- **Features:**
  - Note accuracy validation
  - Metronome timing tolerance (±20%)
  - Progress tracking with "needs work" detection
  - Timing penalty logic (reverts progress on poor timing)

#### `app_logger.dart` (NEW)
- **Purpose:** Centralized structured logging
- **Implementation:** Uses `logger` package with PrettyPrinter
- **Methods:** `debug()`, `info()`, `warning()`, `error()`
- **Usage:** Throughout services for error tracking and debugging

### Models (lib/models/)
- **practice_task.dart** - Task/section definitions with metadata (tempo, metronome requirement)
- **practice_result.dart** - Evaluation results and verdicts (pass, completed, needsWork)
- **fingered_note.dart** - MIDI note with fingering information

### Widgets (lib/widgets/)
- **fingering_diagram.dart** - Custom painter for piano keyboard visualization
- **metronome_indicator.dart** (NEW) - Visual 4-beat indicator with pulsing animations

### UI Structure (lib/main.dart)

**Main Components:**
- `AppShell` - Root scaffold with responsive layout
- `_ConnectionStrip` - MIDI device selection and connection
- `_PlanPanel` - Practice plan task list with sections
- `_TaskPanel` - Active task details and controls
- `_TaskTile` - Individual task with difficulty stars and status badge
- `_ProgressPanel` - Animated progress visualization
- `_FeedbackPanel` - Real-time note feedback (expected vs played)
- `_HelpPanel` - Practice tips and keyboard shortcuts (expandable)
- `_DebugPanel` - Development tools (simulate notes)

**Responsive Breakpoints:**
- Large (>980px): Side-by-side 3:5 ratio
- Medium (600-980px): Side-by-side 2:3 ratio
- Small (<600px): Stacked vertical layout

## Recent Major Changes (2026-02-09)

### Fixed 4 High-Priority Issues:

1. **Memory Leak Fix**
   - Added dispose() to AppState, MidiServiceFactory, MockMidiService
   - Properly cancel StreamSubscriptions (_noteSubscription, _beatSubscription)
   - Dispose metronome and MIDI services

2. **Metronome Implementation**
   - Created MetronomeService with audio + visual support
   - Visual-only mode when audio unavailable
   - Integrated with practice evaluator for timing validation
   - Created MetronomeIndicator widget for beat display

3. **Error Handling**
   - Created AppLogger for structured logging
   - Added try-catch blocks throughout file I/O
   - Added PlatformException handling in MIDI service
   - Graceful degradation for missing features

4. **Architecture Refactoring**
   - Extracted PlanFactory (353 lines) from AppState
   - Reduced AppState from 571 to 217 lines (62% reduction)
   - Better separation of concerns (SRP compliance)

### UI Enhancements (19+ Improvements):

**High-Impact Features:**
- Task difficulty indicators (1-3 stars based on tempo/note count)
- Empty state guidance when no MIDI devices found
- Comprehensive tooltips on all interactive elements
- Enhanced action buttons with disabled states
- Task status badges with icons (Pass, Done, Review, New)

**Visual Design:**
- Animated progress bar with smooth transitions
- Icons throughout panels and feedback tiles
- Animated connection status with glow effect
- Enhanced metronome card with tempo badge
- Card elevation (2dp) for visual depth
- Visual section dividers with icons

**Accessibility:**
- Semantic labels for screen readers
- Color + icon feedback (not just color)
- Keyboard-friendly navigation

**User Guidance:**
- Expandable help panel with practice tips
- Keyboard shortcuts reference
- Getting started instructions
- Metronome timing guidance

## Known Issues & Limitations

### Platform-Specific:
- **Windows:** just_audio plugin may not work without additional setup (app runs in visual-only mode)
- **Fire Tablets:** Requires sideloading (no Google Play Services)
- **MIDI:** Currently using mock devices; platform implementation pending

### Feature Gaps:
- Only supports C Major (multi-key support planned)
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
- Responsive design (consider all 3 breakpoints)
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
├── main.dart                    # App shell and UI (760+ lines)
├── models/
│   ├── fingered_note.dart
│   ├── practice_result.dart
│   └── practice_task.dart
├── services/
│   ├── app_logger.dart          # NEW: Structured logging
│   ├── midi_service.dart        # MIDI abstraction
│   ├── metronome_service.dart   # NEW: Audio + visual metronome
│   ├── plan_factory.dart        # NEW: Practice plan builders
│   ├── practice_evaluator.dart  # Note validation
│   └── progress_store.dart      # JSON persistence
├── viewmodels/
│   └── app_state.dart           # Central state (217 lines)
├── helpers/
│   └── note_names.dart
└── widgets/
    ├── fingering_diagram.dart
    └── metronome_indicator.dart  # NEW: Visual beat display

assets/
└── sounds/
    └── README.md                # Instructions for metronome click file

pubspec.yaml                     # Dependencies and config
```

## Practice Plan Structure

### Daily Plan:
1. **Warm-up** - Chromatic scales, basic arpeggios
2. **Scales** - C Major 1-2 octaves with metronome
3. **Arpeggios** - C Major patterns
4. **Chords** - Triads and progressions
5. **Technique** - Finger independence exercises

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
- "Mock Piano A" (default)
- "Mock Piano B"
- "Mock Synth"
- Simulate button sends C4 (MIDI 60)

### Real MIDI (When Implemented):
- USB MIDI devices on Windows/Android
- Device discovery via platform channels
- NoteOn events with velocity

## Progress Tracking

### Storage:
- **Location:** `progress.json` in app documents directory
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
- Multi-key support (beyond C Major)
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
- Currently expected (mock devices only)
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
- Check memory.md in .claude/projects for additional context
- Follow existing code patterns and naming conventions
- Test on target platform before major changes
- Document significant changes in commit messages

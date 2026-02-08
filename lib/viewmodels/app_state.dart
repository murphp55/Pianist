import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../helpers/note_name_helper.dart';
import '../models/fingered_note.dart';
import '../models/practice_plan.dart';
import '../models/practice_result.dart';
import '../models/practice_task.dart';
import '../models/task_progress.dart';
import '../services/midi_service.dart';
import '../services/practice_evaluator.dart';
import '../services/progress_store.dart';

class AppState extends ChangeNotifier {
  AppState()
      : _plan = _buildDefaultPlan(),
        _progressStore = ProgressStore() {
    _selectedTask = _plan.sections.first.tasks.first;
    _evaluator = PracticeEvaluator(_selectedTask);
    _init();
  }

  final PracticePlan _plan;
  final ProgressStore _progressStore;
  final MidiServiceFactory _midiFactory = MidiServiceFactory();
  final Random _random = Random();

  TaskProgress _progress = TaskProgress(results: {});
  PracticeTask _selectedTask = const PracticeTask(
    id: 'placeholder',
    title: 'Loading',
    description: '',
    expectedNotes: [],
    metronomeRequired: false,
    tempoBpm: 80,
  );

  PracticeEvaluator _evaluator =
      PracticeEvaluator(const PracticeTask(
        id: 'placeholder',
        title: 'Loading',
        description: '',
        expectedNotes: [],
        metronomeRequired: false,
        tempoBpm: 80,
      ));

  String _lastNote = '-';
  String _expectedNote = '-';
  bool _lastWasCorrect = false;
  bool _isRunning = false;
  bool _isConnected = false;
  List<MidiDevice> _devices = const [];
  MidiDevice? _selectedDevice;
  StreamSubscription<NoteOnEvent>? _noteSubscription;

  PracticePlan get plan => _plan;
  PracticeTask get selectedTask => _selectedTask;
  TaskProgress get progress => _progress;
  String get lastNote => _lastNote;
  String get expectedNote => _expectedNote;
  bool get lastWasCorrect => _lastWasCorrect;
  bool get isRunning => _isRunning;
  bool get isConnected => _isConnected;
  List<MidiDevice> get devices => List.unmodifiable(_devices);
  MidiDevice? get selectedDevice => _selectedDevice;

  int get correctCount => _evaluator.correctCount;
  int get expectedIndex => _evaluator.expectedIndex;
  int get totalExpected => _selectedTask.expectedNotes.length;

  Future<void> _init() async {
    _progress = await _progressStore.load();
    await refreshDevices();
    notifyListeners();
  }

  Future<void> refreshDevices() async {
    _devices = await _midiFactory.listDevices();
    if (_devices.isNotEmpty && _selectedDevice == null) {
      _selectedDevice = _devices.first;
    }
    notifyListeners();
  }

  void selectDevice(MidiDevice device) {
    _selectedDevice = device;
    notifyListeners();
  }

  Future<void> connect() async {
    final device = _selectedDevice;
    if (device == null) return;
    final success = await _midiFactory.connect(device.id);
    _isConnected = success;
    _noteSubscription?.cancel();
    _noteSubscription = _midiFactory.service.noteStream.listen(_onNote);
    notifyListeners();
  }

  Future<void> disconnect() async {
    await _midiFactory.disconnect();
    _isConnected = false;
    await _noteSubscription?.cancel();
    _noteSubscription = null;
    notifyListeners();
  }

  void selectTask(PracticeTask task) {
    _selectedTask = task;
    _evaluator = PracticeEvaluator(task);
    _resetFeedback();
    notifyListeners();
  }

  void start() {
    _isRunning = true;
    _evaluator.reset();
    _resetFeedback();
    notifyListeners();
  }

  void reset() {
    _evaluator.reset();
    _resetFeedback();
    notifyListeners();
  }

  void complete() {
    _isRunning = false;
    _recordResult(TaskVerdict.completed);
    notifyListeners();
  }

  void simulateNote() {
    if (_selectedTask.expectedNotes.isEmpty) return;
    final expected = _selectedTask.expectedNotes[_evaluator.expectedIndex
        .clamp(0, _selectedTask.expectedNotes.length - 1) as int];
    final shouldHit = _random.nextBool();
    final midiNote = shouldHit ? expected.midiNote : expected.midiNote + 1;
    _midiFactory.service.simulateNote(midiNote);
  }

  void _onNote(NoteOnEvent event) {
    if (!_isRunning) return;
    final feedback = _evaluator.registerNote(event);
    _lastNote = feedback.playedNote;
    _expectedNote = feedback.expectedNote;
    _lastWasCorrect = feedback.isCorrect;

    if (_evaluator.isComplete) {
      _isRunning = false;
      final verdict =
          _evaluator.correctCount == _selectedTask.expectedNotes.length
              ? TaskVerdict.pass
              : TaskVerdict.needsWork;
      _recordResult(verdict);
    }

    notifyListeners();
  }

  void _recordResult(TaskVerdict verdict) {
    final result = PracticeResult(
      taskId: _selectedTask.id,
      verdict: verdict,
      completedAt: DateTime.now(),
      correctNotes: _evaluator.correctCount,
      totalNotes: _selectedTask.expectedNotes.length,
    );
    _progress.upsertResult(result);
    _progressStore.save(_progress);
  }

  void _resetFeedback() {
    _lastNote = '-';
    _expectedNote = _selectedTask.expectedNotes.isNotEmpty
        ? NoteNameHelper.toName(_selectedTask.expectedNotes.first.midiNote)
        : '-';
    _lastWasCorrect = false;
  }

  static PracticePlan _buildDefaultPlan() {
    return PracticePlan(sections: [
      PracticeSection(title: 'Warmup', tasks: [
        PracticeTask(
          id: 'warmup-5finger-c',
          title: 'C 5-Finger Pattern',
          description:
              'Play ascending C-D-E-F-G with steady tempo and fingering 1-2-3-4-5.',
          expectedNotes: const [
            FingeredNote(midiNote: 60, finger: 1),
            FingeredNote(midiNote: 62, finger: 2),
            FingeredNote(midiNote: 64, finger: 3),
            FingeredNote(midiNote: 65, finger: 4),
            FingeredNote(midiNote: 67, finger: 5),
          ],
          metronomeRequired: true,
          tempoBpm: 80,
        ),
        PracticeTask(
          id: 'warmup-5finger-g',
          title: 'G 5-Finger Pattern',
          description:
              'Play G-A-B-C-D with relaxed wrist and even tone.',
          expectedNotes: const [
            FingeredNote(midiNote: 67, finger: 1),
            FingeredNote(midiNote: 69, finger: 2),
            FingeredNote(midiNote: 71, finger: 3),
            FingeredNote(midiNote: 72, finger: 4),
            FingeredNote(midiNote: 74, finger: 5),
          ],
          metronomeRequired: true,
          tempoBpm: 84,
        ),
        PracticeTask(
          id: 'warmup-5finger-a-minor',
          title: 'A Minor 5-Finger',
          description:
              'Natural minor: A-B-C-D-E. Keep the hand rounded and light.',
          expectedNotes: const [
            FingeredNote(midiNote: 69, finger: 1),
            FingeredNote(midiNote: 71, finger: 2),
            FingeredNote(midiNote: 72, finger: 3),
            FingeredNote(midiNote: 74, finger: 4),
            FingeredNote(midiNote: 76, finger: 5),
          ],
          metronomeRequired: true,
          tempoBpm: 80,
        ),
        PracticeTask(
          id: 'warmup-contrary',
          title: 'Contrary Motion (C Major)',
          description:
              'Hands move outward then inward, staying even on each beat.',
          expectedNotes: const [
            FingeredNote(midiNote: 60, finger: 1),
            FingeredNote(midiNote: 62, finger: 2),
            FingeredNote(midiNote: 64, finger: 3),
            FingeredNote(midiNote: 65, finger: 4),
            FingeredNote(midiNote: 67, finger: 5),
            FingeredNote(midiNote: 65, finger: 4),
            FingeredNote(midiNote: 64, finger: 3),
            FingeredNote(midiNote: 62, finger: 2),
            FingeredNote(midiNote: 60, finger: 1),
          ],
          metronomeRequired: false,
          tempoBpm: 72,
        ),
      ]),
      PracticeSection(title: 'Technique', tasks: [
        PracticeTask(
          id: 'scale-c-major',
          title: 'C Major Scale (One Octave)',
          description: 'Hands separate, even tone, focus on smooth thumb pass.',
          expectedNotes: const [
            FingeredNote(midiNote: 60, finger: 1),
            FingeredNote(midiNote: 62, finger: 2),
            FingeredNote(midiNote: 64, finger: 3),
            FingeredNote(midiNote: 65, finger: 1),
            FingeredNote(midiNote: 67, finger: 2),
            FingeredNote(midiNote: 69, finger: 3),
            FingeredNote(midiNote: 71, finger: 4),
            FingeredNote(midiNote: 72, finger: 5),
          ],
          metronomeRequired: true,
          tempoBpm: 92,
        ),
        PracticeTask(
          id: 'scale-g-major',
          title: 'G Major Scale (One Octave)',
          description: 'One octave, focus on even tone and relaxed wrist.',
          expectedNotes: const [
            FingeredNote(midiNote: 67, finger: 1),
            FingeredNote(midiNote: 69, finger: 2),
            FingeredNote(midiNote: 71, finger: 3),
            FingeredNote(midiNote: 72, finger: 1),
            FingeredNote(midiNote: 74, finger: 2),
            FingeredNote(midiNote: 76, finger: 3),
            FingeredNote(midiNote: 78, finger: 4),
            FingeredNote(midiNote: 79, finger: 5),
          ],
          metronomeRequired: true,
          tempoBpm: 90,
        ),
        PracticeTask(
          id: 'scale-f-major',
          title: 'F Major Scale (One Octave)',
          description: 'Focus on even tone and clean Bb placement.',
          expectedNotes: const [
            FingeredNote(midiNote: 65, finger: 1),
            FingeredNote(midiNote: 67, finger: 2),
            FingeredNote(midiNote: 69, finger: 3),
            FingeredNote(midiNote: 70, finger: 4),
            FingeredNote(midiNote: 72, finger: 1),
            FingeredNote(midiNote: 74, finger: 2),
            FingeredNote(midiNote: 76, finger: 3),
            FingeredNote(midiNote: 77, finger: 4),
          ],
          metronomeRequired: true,
          tempoBpm: 86,
        ),
        PracticeTask(
          id: 'arpeggio-c',
          title: 'C Major Arpeggio',
          description: 'Play C-E-G-C with a relaxed hand shift.',
          expectedNotes: const [
            FingeredNote(midiNote: 60, finger: 1),
            FingeredNote(midiNote: 64, finger: 2),
            FingeredNote(midiNote: 67, finger: 3),
            FingeredNote(midiNote: 72, finger: 5),
          ],
          metronomeRequired: true,
          tempoBpm: 76,
        ),
        PracticeTask(
          id: 'hanon-fragment',
          title: 'Hanon Fragment',
          description: 'C-D-E-F-G-F-E-D. Light touch, even rhythm.',
          expectedNotes: const [
            FingeredNote(midiNote: 60, finger: 1),
            FingeredNote(midiNote: 62, finger: 2),
            FingeredNote(midiNote: 64, finger: 3),
            FingeredNote(midiNote: 65, finger: 4),
            FingeredNote(midiNote: 67, finger: 5),
            FingeredNote(midiNote: 65, finger: 4),
            FingeredNote(midiNote: 64, finger: 3),
            FingeredNote(midiNote: 62, finger: 2),
          ],
          metronomeRequired: true,
          tempoBpm: 96,
        ),
      ]),
      PracticeSection(title: 'Rhythm & Timing', tasks: [
        PracticeTask(
          id: 'rhythm-quarters',
          title: 'Steady Quarter Notes',
          description: 'Play repeated C with strict metronome alignment.',
          expectedNotes: const [
            FingeredNote(midiNote: 60, finger: 1),
            FingeredNote(midiNote: 60, finger: 1),
            FingeredNote(midiNote: 60, finger: 1),
            FingeredNote(midiNote: 60, finger: 1),
            FingeredNote(midiNote: 60, finger: 1),
            FingeredNote(midiNote: 60, finger: 1),
            FingeredNote(midiNote: 60, finger: 1),
            FingeredNote(midiNote: 60, finger: 1),
          ],
          metronomeRequired: true,
          tempoBpm: 72,
        ),
        PracticeTask(
          id: 'rhythm-alternate',
          title: 'Alternating Hands',
          description: 'Alternate C and G for steady timing awareness.',
          expectedNotes: const [
            FingeredNote(midiNote: 60, finger: 1),
            FingeredNote(midiNote: 67, finger: 5),
            FingeredNote(midiNote: 60, finger: 1),
            FingeredNote(midiNote: 67, finger: 5),
            FingeredNote(midiNote: 60, finger: 1),
            FingeredNote(midiNote: 67, finger: 5),
          ],
          metronomeRequired: true,
          tempoBpm: 78,
        ),
        PracticeTask(
          id: 'rhythm-accents',
          title: 'Accent Control',
          description: 'Play C-D-E-D with accents on beats 1 and 3.',
          expectedNotes: const [
            FingeredNote(midiNote: 60, finger: 1),
            FingeredNote(midiNote: 62, finger: 2),
            FingeredNote(midiNote: 64, finger: 3),
            FingeredNote(midiNote: 62, finger: 2),
          ],
          metronomeRequired: true,
          tempoBpm: 84,
        ),
      ]),
      PracticeSection(title: 'Repertoire', tasks: [
        PracticeTask(
          id: 'minuet-focus',
          title: 'Minuet Focus (Bars 1-4)',
          description:
              'Slow practice with clear articulation. Focus on bar transitions.',
          expectedNotes: const [
            FingeredNote(midiNote: 72, finger: 3),
            FingeredNote(midiNote: 71, finger: 2),
            FingeredNote(midiNote: 69, finger: 1),
            FingeredNote(midiNote: 67, finger: 2),
            FingeredNote(midiNote: 69, finger: 3),
            FingeredNote(midiNote: 71, finger: 4),
          ],
          metronomeRequired: false,
          tempoBpm: 76,
        ),
        PracticeTask(
          id: 'ode-joy',
          title: 'Ode to Joy (Theme)',
          description: 'Singable phrasing with even eighth notes.',
          expectedNotes: const [
            FingeredNote(midiNote: 64, finger: 3),
            FingeredNote(midiNote: 64, finger: 3),
            FingeredNote(midiNote: 65, finger: 4),
            FingeredNote(midiNote: 67, finger: 5),
            FingeredNote(midiNote: 67, finger: 5),
            FingeredNote(midiNote: 65, finger: 4),
            FingeredNote(midiNote: 64, finger: 3),
            FingeredNote(midiNote: 62, finger: 2),
          ],
          metronomeRequired: false,
          tempoBpm: 88,
        ),
        PracticeTask(
          id: 'cadence-focus',
          title: 'Cadence Focus',
          description: 'Resolve cleanly: G-F-E-D-C.',
          expectedNotes: const [
            FingeredNote(midiNote: 67, finger: 5),
            FingeredNote(midiNote: 65, finger: 4),
            FingeredNote(midiNote: 64, finger: 3),
            FingeredNote(midiNote: 62, finger: 2),
            FingeredNote(midiNote: 60, finger: 1),
          ],
          metronomeRequired: false,
          tempoBpm: 70,
        ),
      ]),
    ]);
  }
}

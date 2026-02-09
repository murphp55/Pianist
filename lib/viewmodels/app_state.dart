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
      : _dailyPlan = _buildDailyPlan(),
        _extrasPlan = _buildExtrasPlan(),
        _progressStore = ProgressStore() {
    _selectedTask = _dailyPlan.sections.first.tasks.first;
    _evaluator = PracticeEvaluator(_selectedTask);
    _init();
  }

  final PracticePlan _dailyPlan;
  final PracticePlan _extrasPlan;
  final ProgressStore _progressStore;
  final MidiServiceFactory _midiFactory = MidiServiceFactory();
  final Random _random = Random();

  int _selectedPlanIndex = 0;
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

  PracticePlan get currentPlan =>
      _selectedPlanIndex == 0 ? _dailyPlan : _extrasPlan;
  int get selectedPlanIndex => _selectedPlanIndex;
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

  void selectPlan(int index) {
    if (index == _selectedPlanIndex) return;
    _selectedPlanIndex = index;
    final plan = currentPlan;
    if (plan.sections.isNotEmpty && plan.sections.first.tasks.isNotEmpty) {
      selectTask(plan.sections.first.tasks.first);
    } else {
      _selectedTask = const PracticeTask(
        id: 'placeholder',
        title: 'No tasks yet',
        description: '',
        expectedNotes: [],
        metronomeRequired: false,
        tempoBpm: 80,
      );
      _evaluator = PracticeEvaluator(_selectedTask);
      _resetFeedback();
      notifyListeners();
    }
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

  static PracticePlan _buildDailyPlan() {
    const keyName = 'C Major';
    const repeatCount = 5;
    const rightHandRoot = 60; // C4
    const leftHandRoot = 48; // C3
    final keySlug = keyName.toLowerCase().replaceAll(' ', '-');

    final scaleSteps = _majorScaleTwoOctaves();
    final arpeggioSteps = _majorArpeggioTwoOctaves();
    final inversionStepsRight = _triadInversionsTwoOctaves();
    final inversionStepsLeft = _triadInversionsTwoOctaves();

    return PracticePlan(sections: [
      PracticeSection(title: 'Scales', tasks: [
        _buildTask(
          id: 'scale-rh-$keySlug',
          title: '$keyName Scale (Right Hand, 2 Octaves)',
          description:
              'Right hand only, ascending 2 octaves. Repeat $repeatCount times.',
          rootMidi: rightHandRoot,
          steps: scaleSteps,
          repeatCount: repeatCount,
          tempoBpm: 88,
        ),
        _buildTask(
          id: 'scale-lh-$keySlug',
          title: '$keyName Scale (Left Hand, 2 Octaves)',
          description:
              'Left hand only, ascending 2 octaves. Repeat $repeatCount times.',
          rootMidi: leftHandRoot,
          steps: scaleSteps,
          repeatCount: repeatCount,
          tempoBpm: 84,
        ),
        _buildTask(
          id: 'scale-ht-$keySlug',
          title: '$keyName Scale (Hands Together, 2 Octaves)',
          description:
              'Hands together, ascending 2 octaves. Repeat $repeatCount times.',
          rootMidi: rightHandRoot,
          steps: scaleSteps,
          repeatCount: repeatCount,
          tempoBpm: 80,
        ),
      ]),
      PracticeSection(title: 'Arpeggios', tasks: [
        _buildTask(
          id: 'arpeggio-rh-$keySlug',
          title: '$keyName Arpeggio (Right Hand, 2 Octaves)',
          description:
              'Right hand only, ascending 2 octaves. Repeat $repeatCount times.',
          rootMidi: rightHandRoot,
          steps: arpeggioSteps,
          repeatCount: repeatCount,
          tempoBpm: 80,
        ),
        _buildTask(
          id: 'arpeggio-lh-$keySlug',
          title: '$keyName Arpeggio (Left Hand, 2 Octaves)',
          description:
              'Left hand only, ascending 2 octaves. Repeat $repeatCount times.',
          rootMidi: leftHandRoot,
          steps: arpeggioSteps,
          repeatCount: repeatCount,
          tempoBpm: 76,
        ),
        _buildTask(
          id: 'arpeggio-ht-$keySlug',
          title: '$keyName Arpeggio (Hands Together, 2 Octaves)',
          description:
              'Hands together, ascending 2 octaves. Repeat $repeatCount times.',
          rootMidi: rightHandRoot,
          steps: arpeggioSteps,
          repeatCount: repeatCount,
          tempoBpm: 72,
        ),
      ]),
      PracticeSection(title: 'I Chord Inversions', tasks: [
        _buildTask(
          id: 'inversions-rh-$keySlug',
          title: '$keyName I Chord Inversions (Right Hand)',
          description:
              'Root, 1st, 2nd inversion sequentially up the keyboard. Repeat $repeatCount times.',
          rootMidi: rightHandRoot,
          steps: inversionStepsRight,
          repeatCount: repeatCount,
          tempoBpm: 72,
        ),
        _buildTask(
          id: 'inversions-lh-$keySlug',
          title: '$keyName I Chord Inversions (Left Hand)',
          description:
              'Root, 1st, 2nd inversion sequentially up the keyboard. Repeat $repeatCount times.',
          rootMidi: leftHandRoot,
          steps: inversionStepsLeft,
          repeatCount: repeatCount,
          tempoBpm: 68,
        ),
        _buildTask(
          id: 'inversions-ht-$keySlug',
          title: '$keyName I Chord Inversions (Hands Together)',
          description:
              'Root, 1st, 2nd inversion sequentially up the keyboard. Repeat $repeatCount times.',
          rootMidi: rightHandRoot,
          steps: inversionStepsRight,
          repeatCount: repeatCount,
          tempoBpm: 64,
        ),
      ]),
    ]);
  }

  static PracticePlan _buildExtrasPlan() {
    const keyName = 'C Major';
    const rightHandRoot = 60; // C4
    const leftHandRoot = 48; // C3
    final keySlug = keyName.toLowerCase().replaceAll(' ', '-');

    final scaleSteps = _majorScaleTwoOctaves();
    final arpeggioSteps = _majorArpeggioTwoOctaves();
    final inversionSteps = _triadInversionsTwoOctaves();

    return PracticePlan(sections: [
      PracticeSection(title: 'Technique', tasks: [
        _buildTask(
          id: 'contrary-scale-$keySlug',
          title: '$keyName Scale (Contrary Motion, 2 Octaves)',
          description:
              'Start both thumbs on middle C. Move outward to two octaves, then return inward. Count in 4/4 at 72 BPM. Keep wrists level and match touch between hands.',
          rootMidi: rightHandRoot,
          steps: scaleSteps,
          repeatCount: 3,
          tempoBpm: 72,
        ),
        _buildTask(
          id: 'thirds-scale-$keySlug',
          title: '$keyName Scale in Thirds (Hands Together)',
          description:
              'Play parallel thirds up two octaves and back. Use legato and even voicing between upper and lower notes. Aim for 60 BPM, 1 note per beat.',
          rootMidi: rightHandRoot,
          steps: scaleSteps,
          repeatCount: 2,
          tempoBpm: 60,
        ),
        _buildTask(
          id: 'sixths-scale-$keySlug',
          title: '$keyName Scale in Sixths (Hands Together)',
          description:
              'Play parallel sixths up two octaves and back. Keep the top voice singing, bottom voice soft. Start at 52 BPM, then increase to 64 BPM.',
          rootMidi: rightHandRoot,
          steps: scaleSteps,
          repeatCount: 2,
          tempoBpm: 52,
        ),
        _buildTask(
          id: 'arpeggio-inversions-$keySlug',
          title: '$keyName Arpeggios (Root + Inversions)',
          description:
              'Play root position, 1st inversion, and 2nd inversion arpeggios. Two octaves each, hands separate. Pause 2 beats between inversion changes.',
          rootMidi: rightHandRoot,
          steps: arpeggioSteps,
          repeatCount: 3,
          tempoBpm: 72,
        ),
        _buildTask(
          id: 'broken-chords-$keySlug',
          title: '$keyName Broken Chords (I–IV–V–I)',
          description:
              'Play broken triads: I, IV, V, I. Pattern: 1-5-3-5. Two octaves, hands together. Start at 60 BPM and keep pedal clean.',
          rootMidi: rightHandRoot,
          steps: arpeggioSteps,
          repeatCount: 3,
          tempoBpm: 60,
        ),
      ]),
      PracticeSection(title: 'Harmony', tasks: [
        _buildTask(
          id: 'triads-root-$keySlug',
          title: '$keyName Primary Triads (Root Position)',
          description:
              'Play I, IV, V, I in root position. Hold each chord for 4 beats. Focus on clean chord changes and balanced voicing.',
          rootMidi: rightHandRoot,
          steps: inversionSteps,
          repeatCount: 2,
          tempoBpm: 56,
        ),
        _buildTask(
          id: 'triads-inversions-$keySlug',
          title: '$keyName Primary Triads (All Inversions)',
          description:
              'Play I, IV, V in root, 1st, and 2nd inversions. Move by closest inversion (least movement). Hold each for 3 beats.',
          rootMidi: rightHandRoot,
          steps: inversionSteps,
          repeatCount: 2,
          tempoBpm: 56,
        ),
        _buildTask(
          id: 'cadences-$keySlug',
          title: '$keyName Cadences',
          description:
              'Play authentic (V–I), plagal (IV–I), and half (I–V) cadences. Hold each chord 4 beats. Repeat the sequence 4 times.',
          rootMidi: rightHandRoot,
          steps: inversionSteps,
          repeatCount: 4,
          tempoBpm: 60,
        ),
        _buildTask(
          id: 'sevenths-$keySlug',
          title: '$keyName Seventh Chords (I7, IV7, V7)',
          description:
              'Play I7, IV7, V7 in root position, then 1st inversion. Hold each chord 3 beats. Keep the 7th resolved smoothly.',
          rootMidi: rightHandRoot,
          steps: inversionSteps,
          repeatCount: 2,
          tempoBpm: 58,
        ),
      ]),
      PracticeSection(title: 'Articulation & Dynamics', tasks: [
        _buildTask(
          id: 'staccato-legato-$keySlug',
          title: '$keyName Scale (Staccato Then Legato)',
          description:
              'One octave staccato up, one octave legato down. Repeat 5 times. Keep staccato light and legato connected.',
          rootMidi: rightHandRoot,
          steps: scaleSteps,
          repeatCount: 5,
          tempoBpm: 80,
        ),
        _buildTask(
          id: 'dynamics-$keySlug',
          title: '$keyName Scale (pp Up, ff Down)',
          description:
              'Two octaves up from pp to mf, then two octaves down from ff to p. Maintain even rhythm at 72 BPM.',
          rootMidi: rightHandRoot,
          steps: scaleSteps,
          repeatCount: 3,
          tempoBpm: 72,
        ),
      ]),
      PracticeSection(title: 'Rhythm', tasks: [
        _buildTask(
          id: 'rhythm-subdivisions-$keySlug',
          title: '$keyName Scale (8ths, Triplets, 16ths)',
          description:
              'Play two octaves: 8ths up, triplets down, 16ths up, 16ths down. Keep metronome at 60 BPM.',
          rootMidi: rightHandRoot,
          steps: scaleSteps,
          repeatCount: 2,
          tempoBpm: 60,
        ),
        _buildTask(
          id: 'syncopation-$keySlug',
          title: '$keyName Syncopation Drill',
          description:
              'Use a single chord tone. Play off-beat accents (on the “and” of each beat) for 2 minutes. Keep tempo at 72 BPM.',
          rootMidi: rightHandRoot,
          steps: const [0],
          repeatCount: 16,
          tempoBpm: 72,
        ),
      ]),
      PracticeSection(title: 'Musicality', tasks: [
        _buildTask(
          id: 'melodic-pattern-$keySlug',
          title: '$keyName 4-Bar Melodic Pattern',
          description:
              'Create a 4-bar melody using scale tones only. Repeat it 5 times with identical rhythm and phrasing.',
          rootMidi: rightHandRoot,
          steps: scaleSteps,
          repeatCount: 5,
          tempoBpm: 76,
        ),
        _buildTask(
          id: 'progression-pattern-$keySlug',
          title: '$keyName I–vi–IV–V Pattern',
          description:
              'Play block chords once, then broken chords (1-5-3-5). Repeat the full sequence 4 times. Keep tone warm and even.',
          rootMidi: rightHandRoot,
          steps: inversionSteps,
          repeatCount: 4,
          tempoBpm: 64,
        ),
      ]),
    ]);
  }

  static List<int> _majorScaleTwoOctaves() {
    return const [
      0,
      2,
      4,
      5,
      7,
      9,
      11,
      12,
      14,
      16,
      17,
      19,
      21,
      23,
      24,
    ];
  }

  static List<int> _majorArpeggioTwoOctaves() {
    return const [
      0,
      4,
      7,
      12,
      16,
      19,
      24,
    ];
  }

  static List<int> _triadInversionsTwoOctaves() {
    final steps = <int>[];
    for (var octave = 0; octave < 2; octave++) {
      final base = 12 * octave;
      steps.addAll([base + 0, base + 4, base + 7]);
      steps.addAll([base + 4, base + 7, base + 12]);
      steps.addAll([base + 7, base + 12, base + 16]);
    }
    return steps;
  }

  static PracticeTask _buildTask({
    required String id,
    required String title,
    required String description,
    required int rootMidi,
    required List<int> steps,
    required int repeatCount,
    required int tempoBpm,
  }) {
    final sequence = steps
        .map((step) => FingeredNote(midiNote: rootMidi + step, finger: 1))
        .toList();
    final expectedNotes = <FingeredNote>[];
    for (var i = 0; i < repeatCount; i++) {
      expectedNotes.addAll(sequence);
    }
    return PracticeTask(
      id: id,
      title: title,
      description: description,
      expectedNotes: expectedNotes,
      metronomeRequired: true,
      tempoBpm: tempoBpm,
    );
  }
}

import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../helpers/note_name_helper.dart';
import '../models/key_signature.dart';
import '../models/practice_plan.dart';
import '../models/practice_result.dart';
import '../models/practice_task.dart';
import '../models/task_progress.dart';
import '../services/metronome_service.dart';
import '../services/midi_service.dart';
import '../services/plan_factory.dart';
import '../services/practice_evaluator.dart';
import '../services/progress_store.dart';

class AppState extends ChangeNotifier {
  AppState()
      : _selectedKey = KeySignature.cMajor,
        _dailyPlan = PlanFactory.buildDailyPlan(key: KeySignature.cMajor),
        _extrasPlan = PlanFactory.buildExtrasPlan(key: KeySignature.cMajor),
        _progressStore = ProgressStore() {
    _selectedTask = _dailyPlan.sections.first.tasks.first;
    _evaluator = PracticeEvaluator(_selectedTask);
    _init();
  }

  KeySignature _selectedKey;
  PracticePlan _dailyPlan;
  PracticePlan _extrasPlan;
  final ProgressStore _progressStore;
  final MidiServiceFactory _midiFactory = MidiServiceFactory();
  final MetronomeService _metronome = MetronomeService();
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
  StreamSubscription<int>? _beatSubscription;
  int _currentBeat = 0;

  PracticePlan get currentPlan =>
      _selectedPlanIndex == 0 ? _dailyPlan : _extrasPlan;
  int get selectedPlanIndex => _selectedPlanIndex;
  KeySignature get selectedKey => _selectedKey;
  PracticeTask get selectedTask => _selectedTask;
  TaskProgress get progress => _progress;
  String get lastNote => _lastNote;
  String get expectedNote => _expectedNote;
  bool get lastWasCorrect => _lastWasCorrect;
  bool get isRunning => _isRunning;
  bool get isConnected => _isConnected;
  List<MidiDevice> get devices => List.unmodifiable(_devices);
  MidiDevice? get selectedDevice => _selectedDevice;
  int get currentBeat => _currentBeat;

  int get correctCount => _evaluator.correctCount;
  int get expectedIndex => _evaluator.expectedIndex;
  int get totalExpected => _selectedTask.expectedNotes.length;

  Future<void> _init() async {
    _progress = await _progressStore.load();
    await _metronome.initialize();
    await refreshDevices();
    notifyListeners();
  }

  @override
  void dispose() {
    _noteSubscription?.cancel();
    _beatSubscription?.cancel();
    _metronome.dispose();
    _midiFactory.dispose();
    super.dispose();
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

  void setKey(KeySignature key) {
    if (key == _selectedKey) return;

    // Rebuild plans with the new key
    _selectedKey = key;
    _dailyPlan = PlanFactory.buildDailyPlan(key: key);
    _extrasPlan = PlanFactory.buildExtrasPlan(key: key);

    // Reset to the first task of the current plan
    final plan = currentPlan;
    if (plan.sections.isNotEmpty && plan.sections.first.tasks.isNotEmpty) {
      selectTask(plan.sections.first.tasks.first);
    }

    notifyListeners();
  }

  void start() {
    _isRunning = true;
    _evaluator.reset();
    _resetFeedback();

    // Start metronome if required
    if (_selectedTask.metronomeRequired) {
      _beatSubscription?.cancel();
      _beatSubscription = _metronome.beatStream.listen((beat) {
        _currentBeat = beat;
        notifyListeners();
      });
      _metronome.start(_selectedTask.tempoBpm);
    }

    notifyListeners();
  }

  void reset() {
    _metronome.stop();
    _beatSubscription?.cancel();
    _evaluator.reset();
    _resetFeedback();
    notifyListeners();
  }

  void complete() {
    _metronome.stop();
    _beatSubscription?.cancel();
    _isRunning = false;
    _recordResult(TaskVerdict.completed);
    notifyListeners();
  }

  void simulateNote() {
    if (_selectedTask.expectedNotes.isEmpty) return;
    final expected = _selectedTask.expectedNotes[_evaluator.expectedIndex
        .clamp(0, _selectedTask.expectedNotes.length - 1)];
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
}

import '../helpers/note_name_helper.dart';
import '../models/key_signature.dart';
import '../models/practice_task.dart';

class NoteOnEvent {
  const NoteOnEvent({
    required this.midiNote,
    required this.velocity,
    required this.timestamp,
  });

  final int midiNote;
  final int velocity;
  final DateTime timestamp;
}

class NoteFeedback {
  const NoteFeedback({
    required this.expectedNote,
    required this.playedNote,
    required this.isCorrect,
    required this.expectedIndex,
    required this.totalExpected,
  });

  final String expectedNote;
  final String playedNote;
  final bool isCorrect;
  final int expectedIndex;
  final int totalExpected;

  double get progress => totalExpected == 0 ? 0 : expectedIndex / totalExpected;
}

class PracticeEvaluator {
  PracticeEvaluator(
    this.task, {
    required this.keySignature,
  });

  PracticeTask task;
  final KeySignature keySignature;
  int _expectedIndex = 0;
  int _correctCount = 0;
  DateTime? _lastNoteTime;

  int get expectedIndex => _expectedIndex;
  int get correctCount => _correctCount;
  bool get isComplete => _expectedIndex >= task.expectedNotes.length;

  void reset() {
    _expectedIndex = 0;
    _correctCount = 0;
    _lastNoteTime = null;
  }

  NoteFeedback registerNote(NoteOnEvent event) {
    final total = task.expectedNotes.length;
    if (total == 0) {
      return const NoteFeedback(
        expectedNote: '-',
        playedNote: '-',
        isCorrect: false,
        expectedIndex: 0,
        totalExpected: 0,
      );
    }

    final index = _expectedIndex.clamp(0, total - 1);
    final expectedNote = task.expectedNotes[index];
    final expectedName = NoteNameHelper.toName(
      expectedNote.midiNote,
      keySignature: keySignature,
    );
    final playedName = NoteNameHelper.toName(
      event.midiNote,
      keySignature: keySignature,
    );

    final isCorrect = expectedNote.midiNote == event.midiNote;
    if (isCorrect) {
      _correctCount += 1;
      _expectedIndex = (_expectedIndex + 1).clamp(0, total);
    }

    if (task.metronomeRequired && _lastNoteTime != null) {
      // Basic timing check: allow +/- 20% of expected beat interval.
      final beatMs = 60000 / task.tempoBpm;
      final deltaMs = event.timestamp.difference(_lastNoteTime!).inMilliseconds;
      final tolerance = (beatMs * 0.2).round();
      final within = (deltaMs - beatMs).abs() <= tolerance;
      if (!within) {
        // If timing is off, do not advance the index on incorrect timing.
        if (isCorrect) {
          _expectedIndex = (_expectedIndex - 1).clamp(0, total);
          _correctCount = (_correctCount - 1).clamp(0, total);
        }
      }
    }

    _lastNoteTime = event.timestamp;

    return NoteFeedback(
      expectedNote: expectedName,
      playedNote: playedName,
      isCorrect: isCorrect,
      expectedIndex: _expectedIndex,
      totalExpected: total,
    );
  }
}

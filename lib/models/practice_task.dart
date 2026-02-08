import 'fingered_note.dart';

class PracticeTask {
  const PracticeTask({
    required this.id,
    required this.title,
    required this.description,
    required this.expectedNotes,
    required this.metronomeRequired,
    required this.tempoBpm,
  });

  final String id;
  final String title;
  final String description;
  final List<FingeredNote> expectedNotes;
  final bool metronomeRequired;
  final int tempoBpm;
}

class PracticeSection {
  const PracticeSection({
    required this.title,
    required this.tasks,
  });

  final String title;
  final List<PracticeTask> tasks;
}

import 'practice_task.dart';

class PracticePlan {
  const PracticePlan({required this.sections});

  final List<PracticeSection> sections;

  PracticeTask? getTaskById(String id) {
    for (final section in sections) {
      for (final task in section.tasks) {
        if (task.id == id) return task;
      }
    }
    return null;
  }
}

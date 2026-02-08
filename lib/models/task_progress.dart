import 'practice_result.dart';

class TaskProgress {
  TaskProgress({required Map<String, PracticeResult> results})
      : _results = results;

  final Map<String, PracticeResult> _results;

  Map<String, PracticeResult> get results => Map.unmodifiable(_results);

  PracticeResult? resultFor(String taskId) => _results[taskId];

  void upsertResult(PracticeResult result) {
    _results[result.taskId] = result;
  }

  Map<String, dynamic> toJson() => {
        'results': _results.map((key, value) => MapEntry(key, value.toJson())),
      };

  factory TaskProgress.fromJson(Map<String, dynamic> json) {
    final raw = json['results'] as Map<String, dynamic>? ?? {};
    final results = <String, PracticeResult>{};
    for (final entry in raw.entries) {
      results[entry.key] =
          PracticeResult.fromJson(entry.value as Map<String, dynamic>);
    }
    return TaskProgress(results: results);
  }
}

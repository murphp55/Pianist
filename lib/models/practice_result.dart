enum TaskVerdict { pass, needsWork, completed }

class PracticeResult {
  const PracticeResult({
    required this.taskId,
    required this.verdict,
    required this.completedAt,
    required this.correctNotes,
    required this.totalNotes,
  });

  final String taskId;
  final TaskVerdict verdict;
  final DateTime completedAt;
  final int correctNotes;
  final int totalNotes;

  Map<String, dynamic> toJson() => {
        'taskId': taskId,
        'verdict': verdict.name,
        'completedAt': completedAt.toIso8601String(),
        'correctNotes': correctNotes,
        'totalNotes': totalNotes,
      };

  factory PracticeResult.fromJson(Map<String, dynamic> json) {
    return PracticeResult(
      taskId: json['taskId'] as String,
      verdict: TaskVerdict.values.firstWhere(
        (value) => value.name == json['verdict'],
        orElse: () => TaskVerdict.needsWork,
      ),
      completedAt: DateTime.parse(json['completedAt'] as String),
      correctNotes: json['correctNotes'] as int,
      totalNotes: json['totalNotes'] as int,
    );
  }
}

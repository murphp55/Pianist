import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/task_progress.dart';

class ProgressStore {
  static const _fileName = 'progress.json';

  Future<TaskProgress> load() async {
    try {
      final file = await _progressFile();
      if (!await file.exists()) {
        return TaskProgress(results: {});
      }
      final contents = await file.readAsString();
      final jsonMap = jsonDecode(contents) as Map<String, dynamic>;
      return TaskProgress.fromJson(jsonMap);
    } catch (_) {
      return TaskProgress(results: {});
    }
  }

  Future<void> save(TaskProgress progress) async {
    try {
      final file = await _progressFile();
      await file.create(recursive: true);
      final payload = jsonEncode(progress.toJson());
      await file.writeAsString(payload);
    } catch (_) {
      // Best-effort save.
    }
  }

  Future<File> _progressFile() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}${Platform.pathSeparator}$_fileName');
  }
}

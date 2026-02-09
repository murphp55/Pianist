import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/task_progress.dart';
import 'app_logger.dart';

class ProgressStore {
  static const _fileName = 'progress.json';

  Future<TaskProgress> load() async {
    try {
      final file = await _progressFile();
      if (!await file.exists()) {
        AppLogger.info('Progress file does not exist, returning empty progress');
        return TaskProgress(results: {});
      }
      final contents = await file.readAsString();
      final jsonMap = jsonDecode(contents) as Map<String, dynamic>;
      AppLogger.info('Loaded progress with ${(jsonMap['results'] as Map).length} results');
      return TaskProgress.fromJson(jsonMap);
    } on FileSystemException catch (e, stack) {
      AppLogger.error('Failed to load progress file', e, stack);
      return TaskProgress(results: {});
    } on FormatException catch (e, stack) {
      AppLogger.error('Invalid JSON in progress file', e, stack);
      return TaskProgress(results: {});
    } catch (e, stack) {
      AppLogger.error('Unexpected error loading progress', e, stack);
      return TaskProgress(results: {});
    }
  }

  Future<bool> save(TaskProgress progress) async {
    try {
      final file = await _progressFile();
      await file.create(recursive: true);
      final payload = jsonEncode(progress.toJson());
      await file.writeAsString(payload);
      AppLogger.debug('Saved progress successfully');
      return true;
    } on FileSystemException catch (e, stack) {
      AppLogger.error('Failed to save progress file', e, stack);
      return false;
    } catch (e, stack) {
      AppLogger.error('Unexpected error saving progress', e, stack);
      return false;
    }
  }

  Future<File> _progressFile() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}${Platform.pathSeparator}$_fileName');
  }
}

import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:tape_88/core/logging/app_logger.dart';

/// Small resilient JSON store for user data that must not block app startup.
final class JsonFileStore {
  JsonFileStore(this.fileName);

  final String fileName;
  Future<void> _writeQueue = Future.value();

  Future<File> get _file async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$fileName');
  }

  Future<T> load<T>({
    required T fallback,
    required T Function(Object? json) decode,
  }) async {
    await _writeQueue;
    final file = await _file;
    if (!await file.exists()) return fallback;
    try {
      return decode(jsonDecode(await file.readAsString()));
    } catch (error, stackTrace) {
      AppLogger.error(
        'Discarding invalid $fileName',
        error: error,
        stackTrace: stackTrace,
      );
      try {
        await file.delete();
      } on FileSystemException {
        // Startup should continue even when the damaged file cannot be removed.
      }
      return fallback;
    }
  }

  Future<void> save(Object? json) {
    final operation = _writeQueue.then((_) => _saveNow(json));
    _writeQueue = operation.catchError((_) {});
    return operation;
  }

  Future<void> delete() async {
    await _writeQueue;
    final file = await _file;
    if (await file.exists()) await file.delete();
  }

  Future<void> _saveNow(Object? json) async {
    final file = await _file;
    final temporary = File('${file.path}.tmp');
    await temporary.writeAsString(jsonEncode(json), flush: true);
    await temporary.rename(file.path);
  }
}

import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:tape_88/features/library/domain/entities/play_history_entry.dart';
import 'package:tape_88/features/library/domain/repositories/play_history_repository.dart';

final class FilePlayHistoryRepository implements PlayHistoryRepository {
  Future<File> get _file async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/play_history.json');
  }

  @override
  Future<List<PlayHistoryEntry>> load() async {
    final file = await _file;
    if (!await file.exists()) return const [];
    final json = jsonDecode(await file.readAsString()) as List<dynamic>;
    return json
        .map(
          (item) =>
              PlayHistoryEntry.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(growable: false);
  }

  @override
  Future<void> save(List<PlayHistoryEntry> entries) async {
    final file = await _file;
    await file.writeAsString(
      jsonEncode(entries.map((entry) => entry.toJson()).toList()),
    );
  }
}

final class InMemoryPlayHistoryRepository implements PlayHistoryRepository {
  List<PlayHistoryEntry> entries = const [];

  @override
  Future<List<PlayHistoryEntry>> load() async => List.unmodifiable(entries);

  @override
  Future<void> save(List<PlayHistoryEntry> value) async {
    entries = List.unmodifiable(value);
  }
}

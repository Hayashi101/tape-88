import 'package:tape_88/core/storage/json_file_store.dart';
import 'package:tape_88/features/library/domain/entities/play_history_entry.dart';
import 'package:tape_88/features/library/domain/repositories/play_history_repository.dart';

final class FilePlayHistoryRepository implements PlayHistoryRepository {
  final _store = JsonFileStore('play_history.json');

  @override
  Future<List<PlayHistoryEntry>> load() async {
    return _store.load(
      fallback: const <PlayHistoryEntry>[],
      decode: (json) => (json as List<dynamic>)
          .map(
            (item) => PlayHistoryEntry.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(growable: false),
    );
  }

  @override
  Future<void> save(List<PlayHistoryEntry> entries) async {
    await _store.save(entries.map((entry) => entry.toJson()).toList());
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

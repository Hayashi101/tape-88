import 'package:tape_88/core/storage/json_file_store.dart';
import 'package:tape_88/features/search/domain/repositories/search_history_repository.dart';

final class FileSearchHistoryRepository implements SearchHistoryRepository {
  final _store = JsonFileStore('search_history.json');

  @override
  Future<List<String>> load() async {
    return _store.load(
      fallback: const <String>[],
      decode: (json) => List<String>.from(json as List),
    );
  }

  @override
  Future<void> save(List<String> queries) => _store.save(queries);
}

final class InMemorySearchHistoryRepository implements SearchHistoryRepository {
  List<String> queries = const [];

  @override
  Future<List<String>> load() async => List.unmodifiable(queries);

  @override
  Future<void> save(List<String> value) async =>
      queries = List.unmodifiable(value);
}

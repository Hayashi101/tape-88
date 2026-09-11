import 'package:tape_88/core/storage/json_file_store.dart';
import 'package:tape_88/features/library/domain/repositories/favorites_repository.dart';

final class FileFavoritesRepository implements FavoritesRepository {
  final _store = JsonFileStore('favorites.json');

  @override
  Future<Set<String>> load() async {
    return _store.load(
      fallback: const <String>{},
      decode: (json) => (json as List<dynamic>).cast<String>().toSet(),
    );
  }

  @override
  Future<void> save(Set<String> trackIds) async {
    await _store.save(trackIds.toList());
  }
}

final class InMemoryFavoritesRepository implements FavoritesRepository {
  Set<String> trackIds = const {};

  @override
  Future<Set<String>> load() async => Set.unmodifiable(trackIds);

  @override
  Future<void> save(Set<String> value) async {
    trackIds = Set.unmodifiable(value);
  }
}

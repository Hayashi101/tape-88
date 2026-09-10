import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:tape_88/features/library/domain/repositories/favorites_repository.dart';

final class FileFavoritesRepository implements FavoritesRepository {
  Future<File> get _file async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/favorites.json');
  }

  @override
  Future<Set<String>> load() async {
    final file = await _file;
    if (!await file.exists()) return const {};
    final json = jsonDecode(await file.readAsString()) as List<dynamic>;
    return json.cast<String>().toSet();
  }

  @override
  Future<void> save(Set<String> trackIds) async {
    final file = await _file;
    await file.writeAsString(jsonEncode(trackIds.toList()));
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

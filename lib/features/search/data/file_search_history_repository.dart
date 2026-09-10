import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:tape_88/features/search/domain/repositories/search_history_repository.dart';

final class FileSearchHistoryRepository implements SearchHistoryRepository {
  Future<File> get _file async => File(
    '${(await getApplicationDocumentsDirectory()).path}/search_history.json',
  );

  @override
  Future<List<String>> load() async {
    final file = await _file;
    if (!await file.exists()) return const [];
    return List<String>.from(jsonDecode(await file.readAsString()) as List);
  }

  @override
  Future<void> save(List<String> queries) async =>
      (await _file).writeAsString(jsonEncode(queries));
}

final class InMemorySearchHistoryRepository implements SearchHistoryRepository {
  List<String> queries = const [];

  @override
  Future<List<String>> load() async => List.unmodifiable(queries);

  @override
  Future<void> save(List<String> value) async =>
      queries = List.unmodifiable(value);
}

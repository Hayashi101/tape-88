import 'package:flutter/foundation.dart';
import 'package:tape_88/features/search/domain/repositories/search_history_repository.dart';

final class SearchHistoryController extends ChangeNotifier {
  SearchHistoryController(this._repository);
  static const maxEntries = 8;
  final SearchHistoryRepository _repository;
  List<String> queries = const [];

  Future<void> initialize() async {
    try {
      queries = await _repository.load();
    } catch (_) {
      queries = const [];
    }
    notifyListeners();
  }

  Future<void> record(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) return;
    queries = [
      clean,
      ...queries.where((item) => item.toLowerCase() != clean.toLowerCase()),
    ].take(maxEntries).toList(growable: false);
    notifyListeners();
    await _repository.save(queries);
  }

  Future<void> remove(String query) async {
    queries = queries.where((item) => item != query).toList(growable: false);
    notifyListeners();
    await _repository.save(queries);
  }

  Future<void> clear() async {
    queries = const [];
    notifyListeners();
    await _repository.save(queries);
  }
}

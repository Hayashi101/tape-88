import 'package:tape_88/features/library/domain/entities/play_history_entry.dart';

abstract interface class PlayHistoryRepository {
  Future<List<PlayHistoryEntry>> load();
  Future<void> save(List<PlayHistoryEntry> entries);
}

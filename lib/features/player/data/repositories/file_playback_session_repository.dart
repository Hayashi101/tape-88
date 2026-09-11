import 'package:tape_88/core/storage/json_file_store.dart';
import 'package:tape_88/features/player/domain/entities/playback_session.dart';
import 'package:tape_88/features/player/domain/repositories/playback_session_repository.dart';

final class FilePlaybackSessionRepository implements PlaybackSessionRepository {
  final _store = JsonFileStore('playback_session.json');

  @override
  Future<PlaybackSession?> load() async {
    return _store.load<PlaybackSession?>(
      fallback: null,
      decode: (json) =>
          PlaybackSession.fromJson(Map<String, dynamic>.from(json as Map)),
    );
  }

  @override
  Future<void> save(PlaybackSession session) async {
    await _store.save(session.toJson());
  }

  @override
  Future<void> clear() async {
    await _store.delete();
  }
}

final class InMemoryPlaybackSessionRepository
    implements PlaybackSessionRepository {
  PlaybackSession? session;

  @override
  Future<PlaybackSession?> load() async => session;

  @override
  Future<void> save(PlaybackSession value) async => session = value;

  @override
  Future<void> clear() async => session = null;
}

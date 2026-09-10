import 'package:tape_88/features/player/domain/entities/playback_session.dart';

abstract interface class PlaybackSessionRepository {
  Future<PlaybackSession?> load();
  Future<void> save(PlaybackSession session);
  Future<void> clear();
}

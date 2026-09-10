import 'package:tape_88/core/utils/result.dart';
import 'package:tape_88/features/library/domain/entities/track.dart';
import 'package:tape_88/features/player/domain/entities/playback_state.dart';

abstract interface class AudioPlayerRepository {
  Stream<PlaybackState> get stateStream;
  PlaybackState get currentState;
  Future<Result<void>> setQueue(List<Track> tracks, {int initialIndex = 0});
  Future<Result<void>> play();
  Future<Result<void>> pause();
  Future<Result<void>> seek(Duration position);
  Future<Result<void>> skipNext();
  Future<Result<void>> skipPrevious();
  Future<Result<void>> skipToQueueItem(int index);
  Future<Result<void>> reorderQueue(int oldIndex, int newIndex);
  Future<Result<void>> removeQueueItem(int index);
  Future<Result<void>> addToQueue(Track track, {required bool playNext});
  Future<Result<void>> clearQueue();
  Future<Result<void>> setRepeatMode(RepeatMode mode);
  Future<Result<void>> setShuffleEnabled({required bool enabled});
  Future<Result<void>> setVolume(double volume);
  Future<Result<void>> setEqualizerPreset(String preset);
  Future<void> dispose();
}

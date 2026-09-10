import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:tape_88/core/utils/result.dart';
import 'package:tape_88/features/player/domain/entities/playback_state.dart';
import 'package:tape_88/features/player/domain/repositories/audio_player_repository.dart';
import 'package:tape_88/features/library/domain/entities/track.dart';

final class PlayerController extends ChangeNotifier {
  PlayerController(this._repository) : _state = _repository.currentState {
    _subscription = _repository.stateStream.listen((state) {
      final previous = _state;
      _state = state;
      if (previous.currentTrack != state.currentTrack ||
          previous.isPlaying != state.isPlaying ||
          previous.status != state.status) {
        _trackStateChanges.notifyListeners();
      }
      notifyListeners();
    });
  }

  final AudioPlayerRepository _repository;
  final ChangeNotifier _trackStateChanges = ChangeNotifier();
  late final StreamSubscription<PlaybackState> _subscription;
  PlaybackState _state;
  PlaybackState get state => _state;

  /// Updates only when track/playback status changes, excluding position ticks.
  /// List-heavy screens should use this instead of listening to the controller.
  Listenable get trackStateChanges => _trackStateChanges;

  Future<Result<void>> togglePlayback() =>
      _state.isPlaying ? _repository.pause() : _repository.play();
  Future<Result<void>> play() => _repository.play();
  Future<Result<void>> pause() => _repository.pause();
  Future<Result<void>> loadQueue(List<Track> tracks, {int initialIndex = 0}) =>
      _repository.setQueue(tracks, initialIndex: initialIndex);
  Future<Result<void>> seek(Duration position) => _repository.seek(position);
  Future<Result<void>> next() => _repository.skipNext();
  Future<Result<void>> previous() => _repository.skipPrevious();
  Future<Result<void>> selectQueueItem(int index) =>
      _repository.skipToQueueItem(index);
  Future<Result<void>> reorderQueue(int oldIndex, int newIndex) =>
      _repository.reorderQueue(oldIndex, newIndex);
  Future<Result<void>> removeQueueItem(int index) =>
      _repository.removeQueueItem(index);
  Future<Result<void>> addToQueue(Track track, {bool playNext = false}) =>
      _repository.addToQueue(track, playNext: playNext);
  Future<Result<void>> clearQueue() => _repository.clearQueue();
  Future<Result<void>> setVolume(double volume) =>
      _repository.setVolume(volume);
  Future<Result<void>> setEqualizerPreset(String preset) =>
      _repository.setEqualizerPreset(preset);
  Future<Result<void>> toggleShuffle() =>
      _repository.setShuffleEnabled(enabled: !_state.shuffleEnabled);
  Future<Result<void>> setShuffleEnabled({required bool enabled}) =>
      _repository.setShuffleEnabled(enabled: enabled);
  Future<Result<void>> setRepeatMode(RepeatMode mode) =>
      _repository.setRepeatMode(mode);
  Future<Result<void>> cycleRepeatMode() =>
      _repository.setRepeatMode(switch (_state.repeatMode) {
        RepeatMode.off => RepeatMode.all,
        RepeatMode.all => RepeatMode.one,
        RepeatMode.one => RepeatMode.off,
      });

  @override
  void dispose() {
    _subscription.cancel();
    _trackStateChanges.dispose();
    super.dispose();
  }
}

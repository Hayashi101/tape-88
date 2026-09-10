import 'dart:async';

import 'package:tape_88/core/error/failure.dart';
import 'package:tape_88/core/utils/result.dart';
import 'package:tape_88/features/library/domain/entities/track.dart';
import 'package:tape_88/features/player/domain/entities/playback_state.dart';
import 'package:tape_88/features/player/domain/repositories/audio_player_repository.dart';

/// Foundation adapter. Replace this with a just_audio/audio_service adapter.
final class InMemoryAudioPlayerRepository implements AudioPlayerRepository {
  final _controller = StreamController<PlaybackState>.broadcast();
  final List<Track> _queue = [];
  int _index = -1;
  PlaybackState _state = const PlaybackState();

  @override
  PlaybackState get currentState => _state;
  @override
  Stream<PlaybackState> get stateStream => _controller.stream;

  void _emit(PlaybackState state) {
    _state = state;
    _controller.add(state);
  }

  @override
  Future<Result<void>> setQueue(
    List<Track> tracks, {
    int initialIndex = 0,
  }) async {
    if (tracks.isEmpty || initialIndex < 0 || initialIndex >= tracks.length) {
      return const Failed(PlaybackFailure('Hàng đợi phát nhạc không hợp lệ.'));
    }
    _queue
      ..clear()
      ..addAll(tracks);
    _index = initialIndex;
    _emit(
      PlaybackState(
        currentTrack: _queue[_index],
        queue: List.unmodifiable(_queue),
        currentIndex: _index,
      ),
    );
    return const Success(null);
  }

  @override
  Future<Result<void>> play() async {
    if (_state.currentTrack == null) {
      return const Failed(PlaybackFailure('Chưa chọn bài hát.'));
    }
    _emit(_state.copyWith(status: PlaybackStatus.playing, clearError: true));
    return const Success(null);
  }

  @override
  Future<Result<void>> pause() async {
    _emit(_state.copyWith(status: PlaybackStatus.paused));
    return const Success(null);
  }

  @override
  Future<Result<void>> seek(Duration position) async {
    final duration = _state.currentTrack?.duration ?? Duration.zero;
    final safePosition = position < Duration.zero
        ? Duration.zero
        : (position > duration ? duration : position);
    _emit(_state.copyWith(position: safePosition));
    return const Success(null);
  }

  @override
  Future<Result<void>> skipNext() async => _skip(1);
  @override
  Future<Result<void>> skipPrevious() async => _skip(-1);

  @override
  Future<Result<void>> skipToQueueItem(int index) async {
    if (index < 0 || index >= _queue.length) {
      return const Failed(PlaybackFailure('Bài hát không có trong hàng đợi.'));
    }
    _index = index;
    _emit(
      _state.copyWith(
        currentTrack: _queue[_index],
        currentIndex: _index,
        position: Duration.zero,
      ),
    );
    return const Success(null);
  }

  @override
  Future<Result<void>> reorderQueue(int oldIndex, int newIndex) async {
    if (oldIndex < 0 ||
        oldIndex >= _queue.length ||
        newIndex < 0 ||
        newIndex >= _queue.length) {
      return const Failed(PlaybackFailure('Vị trí hàng đợi không hợp lệ.'));
    }
    final currentTrack = _state.currentTrack;
    final moved = _queue.removeAt(oldIndex);
    _queue.insert(newIndex, moved);
    _index = currentTrack == null ? -1 : _queue.indexOf(currentTrack);
    _emit(
      _state.copyWith(queue: List.unmodifiable(_queue), currentIndex: _index),
    );
    return const Success(null);
  }

  @override
  Future<Result<void>> removeQueueItem(int index) async {
    if (index < 0 || index >= _queue.length) {
      return const Failed(PlaybackFailure('Bài hát không có trong hàng đợi.'));
    }
    final removedCurrent = index == _index;
    _queue.removeAt(index);
    if (_queue.isEmpty) return clearQueue();
    if (index < _index) {
      _index -= 1;
    } else if (removedCurrent && _index >= _queue.length) {
      _index = _queue.length - 1;
    }
    _emit(
      _state.copyWith(
        queue: List.unmodifiable(_queue),
        currentIndex: _index,
        currentTrack: _queue[_index],
        position: removedCurrent ? Duration.zero : _state.position,
      ),
    );
    return const Success(null);
  }

  @override
  Future<Result<void>> addToQueue(Track track, {required bool playNext}) async {
    if (_queue.isEmpty) return setQueue([track]);
    final insertionIndex = playNext ? _index + 1 : _queue.length;
    _queue.insert(insertionIndex, track);
    _emit(_state.copyWith(queue: List.unmodifiable(_queue)));
    return const Success(null);
  }

  @override
  Future<Result<void>> clearQueue() async {
    _queue.clear();
    _index = -1;
    _emit(
      PlaybackState(
        volume: _state.volume,
        repeatMode: _state.repeatMode,
        shuffleEnabled: _state.shuffleEnabled,
      ),
    );
    return const Success(null);
  }

  @override
  Future<Result<void>> setRepeatMode(RepeatMode mode) async {
    _emit(_state.copyWith(repeatMode: mode));
    return const Success(null);
  }

  @override
  Future<Result<void>> setShuffleEnabled({required bool enabled}) async {
    _emit(_state.copyWith(shuffleEnabled: enabled));
    return const Success(null);
  }

  @override
  Future<Result<void>> setVolume(double volume) async {
    _emit(_state.copyWith(volume: volume.clamp(0, 1)));
    return const Success(null);
  }

  @override
  Future<Result<void>> setEqualizerPreset(String preset) async =>
      const Success(null);

  Result<void> _skip(int offset) {
    if (_queue.isEmpty) {
      return const Failed(PlaybackFailure('Hàng đợi đang trống.'));
    }
    _index = (_index + offset).clamp(0, _queue.length - 1);
    _emit(
      _state.copyWith(
        currentTrack: _queue[_index],
        currentIndex: _index,
        position: Duration.zero,
      ),
    );
    return const Success(null);
  }

  @override
  Future<void> dispose() => _controller.close();
}

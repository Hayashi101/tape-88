import 'dart:async';

import 'package:audio_service/audio_service.dart' hide PlaybackState;
import 'package:just_audio/just_audio.dart';
import 'package:tape_88/core/error/failure.dart';
import 'package:tape_88/core/utils/result.dart';
import 'package:tape_88/features/library/domain/entities/track.dart';
import 'package:tape_88/features/player/data/services/android_device_volume.dart';
import 'package:tape_88/features/player/data/services/android_home_widget_bridge.dart';
import 'package:tape_88/features/player/data/services/tape_audio_handler.dart';
import 'package:tape_88/features/player/domain/entities/playback_state.dart';
import 'package:tape_88/features/player/domain/repositories/audio_player_repository.dart';

final class JustAudioPlayerRepository implements AudioPlayerRepository {
  JustAudioPlayerRepository(
    this._handler, [
    AndroidDeviceVolume? deviceVolume,
    AndroidHomeWidgetBridge? homeWidget,
  ]) : _deviceVolume = deviceVolume ?? AndroidDeviceVolume(),
       _homeWidget = homeWidget ?? AndroidHomeWidgetBridge() {
    _subscriptions.addAll([
      _handler.player.playerStateStream.listen((_) => _emit()),
      _handler.player.positionStream.listen((_) => _emit()),
      _handler.player.bufferedPositionStream.listen((_) => _emit()),
      _handler.player.currentIndexStream.listen((_) => _emit()),
      _handler.player.loopModeStream.listen((_) => _emit()),
      _handler.player.shuffleModeEnabledStream.listen((_) => _emit()),
      if (!_deviceVolume.isSupported)
        _handler.player.volumeStream.listen((_) => _emit()),
      _handler.player.errorStream.listen((error) {
        _state = _state.copyWith(
          status: PlaybackStatus.error,
          errorMessage: error.message,
        );
        _controller.add(_state);
      }),
    ]);
    if (_deviceVolume.isSupported) {
      _subscriptions.add(
        _deviceVolume.changes.listen((volume) {
          _systemVolume = volume;
          _emit();
        }),
      );
    }
  }

  final TapeAudioHandler _handler;
  final AndroidDeviceVolume _deviceVolume;
  final AndroidHomeWidgetBridge _homeWidget;
  final _controller = StreamController<PlaybackState>.broadcast();
  final List<StreamSubscription<Object?>> _subscriptions = [];
  List<Track> _queue = const [];
  double _systemVolume = 1;
  PlaybackState _state = const PlaybackState();

  Future<void> initializeDeviceVolume() async {
    if (!_deviceVolume.isSupported) return;
    _systemVolume = await _deviceVolume.getVolume();
    _emit();
  }

  @override
  PlaybackState get currentState => _state;

  @override
  Stream<PlaybackState> get stateStream => _controller.stream;

  @override
  Future<Result<void>> setQueue(
    List<Track> tracks, {
    int initialIndex = 0,
  }) async {
    if (tracks.isEmpty || initialIndex < 0 || initialIndex >= tracks.length) {
      return const Failed(PlaybackFailure('Hàng đợi phát nhạc không hợp lệ.'));
    }
    try {
      _queue = List.unmodifiable(tracks);
      await _handler.loadQueue(tracks, initialIndex: initialIndex);
      _emit();
      return const Success(null);
    } catch (error) {
      return Failed(PlaybackFailure('Không thể tải file nhạc.', cause: error));
    }
  }

  @override
  Future<Result<void>> play() => _perform(_handler.play);

  @override
  Future<Result<void>> pause() => _perform(_handler.pause);

  @override
  Future<Result<void>> seek(Duration position) =>
      _perform(() => _handler.seek(position));

  @override
  Future<Result<void>> skipNext() => _perform(_handler.skipToNext);

  @override
  Future<Result<void>> skipPrevious() => _perform(_handler.skipToPrevious);

  @override
  Future<Result<void>> skipToQueueItem(int index) {
    if (index < 0 || index >= _queue.length) {
      return Future.value(
        const Failed(PlaybackFailure('Bài hát không có trong hàng đợi.')),
      );
    }
    return _perform(() => _handler.skipToQueueItem(index));
  }

  @override
  Future<Result<void>> reorderQueue(int oldIndex, int newIndex) async {
    if (oldIndex < 0 ||
        oldIndex >= _queue.length ||
        newIndex < 0 ||
        newIndex >= _queue.length) {
      return const Failed(PlaybackFailure('Vị trí hàng đợi không hợp lệ.'));
    }
    try {
      final mutableQueue = [..._queue];
      final moved = mutableQueue.removeAt(oldIndex);
      mutableQueue.insert(newIndex, moved);
      await _handler.reorderQueue(oldIndex, newIndex);
      _queue = List.unmodifiable(mutableQueue);
      _emit();
      return const Success(null);
    } catch (error) {
      return Failed(
        PlaybackFailure('Không thể sắp xếp hàng đợi.', cause: error),
      );
    }
  }

  @override
  Future<Result<void>> removeQueueItem(int index) async {
    if (index < 0 || index >= _queue.length) {
      return const Failed(PlaybackFailure('Bài hát không có trong hàng đợi.'));
    }
    if (_queue.length == 1) return clearQueue();
    final previousQueue = _queue;
    try {
      final updated = [..._queue]..removeAt(index);
      _queue = List.unmodifiable(updated);
      _emit();
      await _handler.removeQueueItemAt(index);
      return const Success(null);
    } catch (error) {
      _queue = previousQueue;
      _emit();
      return Failed(
        PlaybackFailure('Không thể xóa bài khỏi hàng đợi.', cause: error),
      );
    }
  }

  @override
  Future<Result<void>> addToQueue(Track track, {required bool playNext}) async {
    if (_queue.isEmpty) return setQueue([track]);
    final insertionIndex = playNext
        ? (_handler.player.currentIndex ?? 0) + 1
        : _queue.length;
    final previousQueue = _queue;
    try {
      final updated = [..._queue]..insert(insertionIndex, track);
      _queue = List.unmodifiable(updated);
      await _handler.insertTrackAt(insertionIndex, track);
      _emit();
      return const Success(null);
    } catch (error) {
      _queue = previousQueue;
      return Failed(
        PlaybackFailure('Không thể thêm bài vào hàng đợi.', cause: error),
      );
    }
  }

  @override
  Future<Result<void>> clearQueue() async {
    try {
      _queue = const [];
      await _handler.clearQueue();
      _emit();
      return const Success(null);
    } catch (error) {
      return Failed(PlaybackFailure('Không thể xóa hàng đợi.', cause: error));
    }
  }

  @override
  Future<Result<void>> setRepeatMode(RepeatMode mode) => _perform(
    () => _handler.setRepeatMode(switch (mode) {
      RepeatMode.off => AudioServiceRepeatMode.none,
      RepeatMode.all => AudioServiceRepeatMode.all,
      RepeatMode.one => AudioServiceRepeatMode.one,
    }),
  );

  @override
  Future<Result<void>> setShuffleEnabled({required bool enabled}) => _perform(
    () => _handler.setShuffleMode(
      enabled ? AudioServiceShuffleMode.all : AudioServiceShuffleMode.none,
    ),
  );

  @override
  Future<Result<void>> setVolume(double volume) => _perform(() async {
    final normalized = volume.clamp(0.0, 1.0).toDouble();
    if (_deviceVolume.isSupported) {
      _systemVolume = normalized;
      _emit();
      await _deviceVolume.setVolume(normalized);
    } else {
      await _handler.setVolume(normalized);
    }
  });

  @override
  Future<Result<void>> setEqualizerPreset(String preset) =>
      _perform(() => _handler.setEqualizerPreset(preset));

  Future<Result<void>> _perform(Future<void> Function() action) async {
    try {
      await action();
      return const Success(null);
    } catch (error) {
      return Failed(
        PlaybackFailure('Thao tác phát nhạc thất bại.', cause: error),
      );
    }
  }

  void _emit() {
    final player = _handler.player;
    final index = player.currentIndex ?? 0;
    final track = _queue.isNotEmpty && index < _queue.length
        ? _queue[index]
        : null;
    final status = switch (player.processingState) {
      ProcessingState.idle => PlaybackStatus.idle,
      ProcessingState.loading ||
      ProcessingState.buffering => PlaybackStatus.loading,
      ProcessingState.completed => PlaybackStatus.completed,
      ProcessingState.ready =>
        player.playing ? PlaybackStatus.playing : PlaybackStatus.paused,
    };
    _state = PlaybackState(
      status: status,
      currentTrack: track,
      position: player.position,
      bufferedPosition: player.bufferedPosition,
      repeatMode: switch (player.loopMode) {
        LoopMode.off => RepeatMode.off,
        LoopMode.all => RepeatMode.all,
        LoopMode.one => RepeatMode.one,
      },
      shuffleEnabled: player.shuffleModeEnabled,
      volume: _deviceVolume.isSupported ? _systemVolume : player.volume,
      queue: _queue,
      currentIndex: _queue.isEmpty ? -1 : index,
    );
    _controller.add(_state);
    unawaited(_homeWidget.synchronize(_state));
  }

  @override
  Future<void> dispose() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    await _handler.stop();
    await _handler.disposePlayer();
    await _controller.close();
  }
}

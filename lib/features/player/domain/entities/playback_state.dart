import 'package:flutter/foundation.dart';
import 'package:tape_88/features/library/domain/entities/track.dart';

enum PlaybackStatus { idle, loading, playing, paused, completed, error }

enum RepeatMode { off, all, one }

@immutable
class PlaybackState {
  const PlaybackState({
    this.status = PlaybackStatus.idle,
    this.currentTrack,
    this.position = Duration.zero,
    this.bufferedPosition = Duration.zero,
    this.repeatMode = RepeatMode.off,
    this.shuffleEnabled = false,
    this.volume = 1,
    this.errorMessage,
    this.queue = const [],
    this.currentIndex = -1,
  });

  final PlaybackStatus status;
  final Track? currentTrack;
  final Duration position;
  final Duration bufferedPosition;
  final RepeatMode repeatMode;
  final bool shuffleEnabled;
  final double volume;
  final String? errorMessage;
  final List<Track> queue;
  final int currentIndex;

  bool get isPlaying => status == PlaybackStatus.playing;

  PlaybackState copyWith({
    PlaybackStatus? status,
    Track? currentTrack,
    Duration? position,
    Duration? bufferedPosition,
    RepeatMode? repeatMode,
    bool? shuffleEnabled,
    double? volume,
    String? errorMessage,
    bool clearError = false,
    List<Track>? queue,
    int? currentIndex,
  }) => PlaybackState(
    status: status ?? this.status,
    currentTrack: currentTrack ?? this.currentTrack,
    position: position ?? this.position,
    bufferedPosition: bufferedPosition ?? this.bufferedPosition,
    repeatMode: repeatMode ?? this.repeatMode,
    shuffleEnabled: shuffleEnabled ?? this.shuffleEnabled,
    volume: volume ?? this.volume,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    queue: queue ?? this.queue,
    currentIndex: currentIndex ?? this.currentIndex,
  );
}

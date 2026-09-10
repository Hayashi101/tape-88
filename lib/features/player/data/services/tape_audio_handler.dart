import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'package:tape_88/features/library/domain/entities/track.dart';
import 'package:tape_88/features/library/data/android_artwork_cache.dart';

final class TapeAudioHandler extends BaseAudioHandler with SeekHandler {
  TapeAudioHandler(this._session) {
    player.playbackEventStream.map(_broadcastState).pipe(playbackState);
    player.currentIndexStream.listen((index) {
      final items = queue.value;
      if (index != null && index >= 0 && index < items.length) {
        unawaited(_publishMediaItem(index));
      }
    });
    _becomingNoisySubscription = _session.becomingNoisyEventStream.listen((_) {
      pause();
    });
  }

  final AudioSession _session;
  final AndroidEqualizer equalizer = AndroidEqualizer();
  late final AudioPlayer player = AudioPlayer(
    audioPipeline: AudioPipeline(androidAudioEffects: [equalizer]),
  );
  final AndroidArtworkCache _artworkCache = AndroidArtworkCache();
  List<Track> _tracks = const [];
  String _equalizerPreset = 'Flat';
  late final StreamSubscription<void> _becomingNoisySubscription;

  Future<void> loadQueue(List<Track> tracks, {int initialIndex = 0}) async {
    _tracks = List.unmodifiable(tracks);
    final items = tracks
        .map(
          (track) => MediaItem(
            id: track.source,
            title: track.title,
            artist: track.artist,
            album: track.album,
            duration: track.duration,
            artUri: track.artworkUri,
            extras: {
              'trackId': track.id,
              'mimeType': track.mimeType,
              'trackNumber': track.trackNumber,
            },
          ),
        )
        .toList(growable: false);
    queue.add(items);
    await _publishMediaItem(initialIndex);
    await player.setAudioSources(
      tracks.indexed
          .map(
            (entry) => entry.$2.source.startsWith('assets/')
                ? AudioSource.asset(entry.$2.source, tag: items[entry.$1])
                : AudioSource.uri(
                    Uri.parse(entry.$2.source),
                    tag: items[entry.$1],
                  ),
          )
          .toList(growable: false),
      initialIndex: initialIndex,
      initialPosition: Duration.zero,
    );
    await _applyEqualizerPreset();
  }

  Future<void> setEqualizerPreset(String preset) async {
    _equalizerPreset = preset;
    if (player.audioSources.isNotEmpty) await _applyEqualizerPreset();
  }

  Future<void> _applyEqualizerPreset() async {
    if (_equalizerPreset == 'Flat') {
      await equalizer.setEnabled(false);
      return;
    }
    await equalizer.setEnabled(true);
    final parameters = await equalizer.parameters;
    for (final band in parameters.bands) {
      final frequency = band.centerFrequency;
      final gain = switch (_equalizerPreset) {
        'Warm' =>
          frequency < 250
              ? 3.0
              : frequency < 2000
              ? 1.0
              : -1.0,
        'Bass' =>
          frequency < 180
              ? 5.0
              : frequency < 600
              ? 2.0
              : 0.0,
        'Vocal' =>
          frequency < 250
              ? -1.0
              : frequency < 4000
              ? 3.0
              : 1.0,
        'Bright' =>
          frequency > 4000
              ? 4.0
              : frequency > 1000
              ? 2.0
              : 0.0,
        _ => 0.0,
      };
      await band.setGain(
        gain.clamp(parameters.minDecibels, parameters.maxDecibels),
      );
    }
  }

  Future<void> _publishMediaItem(int index) async {
    final items = [...queue.value];
    if (index < 0 || index >= items.length || index >= _tracks.length) return;
    final cachedArtUri = await _artworkCache.artUriFor(_tracks[index]);
    if (player.currentIndex != null && player.currentIndex != index) return;
    if (cachedArtUri != items[index].artUri) {
      items[index] = items[index].copyWith(artUri: cachedArtUri);
      queue.add(items);
    }
    mediaItem.add(items[index]);
  }

  @override
  Future<void> play() async {
    final items = queue.value;
    final index = player.currentIndex ?? 0;
    if (items.isNotEmpty && index >= 0 && index < items.length) {
      await _publishMediaItem(index);
    }
    final activated = await _session.setActive(true);
    if (!activated) return;
    await player.play();
  }

  @override
  Future<void> pause() => player.pause();

  @override
  Future<void> seek(Duration position) => player.seek(position);

  @override
  Future<void> skipToNext() async {
    if (player.hasNext) await player.seekToNext();
  }

  @override
  Future<void> skipToPrevious() async {
    if (player.position > const Duration(seconds: 3)) {
      await player.seek(Duration.zero);
    } else if (player.hasPrevious) {
      await player.seekToPrevious();
    }
  }

  @override
  Future<void> skipToQueueItem(int index) =>
      player.seek(Duration.zero, index: index);

  Future<void> reorderQueue(int oldIndex, int newIndex) async {
    final reorderedTracks = [..._tracks];
    final movedTrack = reorderedTracks.removeAt(oldIndex);
    reorderedTracks.insert(newIndex, movedTrack);
    _tracks = List.unmodifiable(reorderedTracks);
    await player.moveAudioSource(oldIndex, newIndex);
    final items = [...queue.value];
    final moved = items.removeAt(oldIndex);
    items.insert(newIndex, moved);
    queue.add(items);
    final index = player.currentIndex;
    if (index != null && index >= 0 && index < items.length) {
      mediaItem.add(items[index]);
    }
  }

  @override
  Future<void> removeQueueItemAt(int index) async {
    final tracks = [..._tracks]..removeAt(index);
    final items = [...queue.value]..removeAt(index);
    _tracks = List.unmodifiable(tracks);
    queue.add(items);
    await player.removeAudioSourceAt(index);
    final currentIndex = player.currentIndex;
    if (currentIndex != null &&
        currentIndex >= 0 &&
        currentIndex < items.length) {
      await _publishMediaItem(currentIndex);
    }
  }

  Future<void> insertTrackAt(int index, Track track) async {
    final item = MediaItem(
      id: track.source,
      title: track.title,
      artist: track.artist,
      album: track.album,
      duration: track.duration,
      artUri: track.artworkUri,
      extras: {
        'trackId': track.id,
        'mimeType': track.mimeType,
        'trackNumber': track.trackNumber,
      },
    );
    final tracks = [..._tracks]..insert(index, track);
    final items = [...queue.value]..insert(index, item);
    _tracks = List.unmodifiable(tracks);
    queue.add(items);
    final source = track.source.startsWith('assets/')
        ? AudioSource.asset(track.source, tag: item)
        : AudioSource.uri(Uri.parse(track.source), tag: item);
    await player.insertAudioSource(index, source);
  }

  Future<void> clearQueue() async {
    await player.stop();
    await player.clearAudioSources();
    queue.add(const []);
    _tracks = const [];
    mediaItem.add(null);
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    await player.setLoopMode(switch (repeatMode) {
      AudioServiceRepeatMode.one => LoopMode.one,
      AudioServiceRepeatMode.all ||
      AudioServiceRepeatMode.group => LoopMode.all,
      _ => LoopMode.off,
    });
    playbackState.add(
      _broadcastState(player.playbackEvent).copyWith(repeatMode: repeatMode),
    );
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    final enabled = shuffleMode != AudioServiceShuffleMode.none;
    if (enabled) await player.shuffle();
    await player.setShuffleModeEnabled(enabled);
    playbackState.add(
      _broadcastState(player.playbackEvent).copyWith(shuffleMode: shuffleMode),
    );
  }

  Future<void> setVolume(double volume) => player.setVolume(volume);

  @override
  Future<void> stop() async {
    await player.stop();
    await _session.setActive(false);
    await super.stop();
  }

  Future<void> disposePlayer() async {
    await _becomingNoisySubscription.cancel();
    await player.dispose();
  }

  PlaybackState _broadcastState(PlaybackEvent event) => PlaybackState(
    controls: [
      MediaControl.skipToPrevious,
      if (player.playing) MediaControl.pause else MediaControl.play,
      MediaControl.skipToNext,
      MediaControl.stop,
    ],
    systemActions: const {MediaAction.seek},
    androidCompactActionIndices: const [0, 1, 2],
    processingState: switch (player.processingState) {
      ProcessingState.idle => AudioProcessingState.idle,
      ProcessingState.loading => AudioProcessingState.loading,
      ProcessingState.buffering => AudioProcessingState.buffering,
      ProcessingState.ready => AudioProcessingState.ready,
      ProcessingState.completed => AudioProcessingState.completed,
    },
    playing: player.playing,
    updatePosition: player.position,
    bufferedPosition: player.bufferedPosition,
    speed: player.speed,
    repeatMode: switch (player.loopMode) {
      LoopMode.one => AudioServiceRepeatMode.one,
      LoopMode.all => AudioServiceRepeatMode.all,
      LoopMode.off => AudioServiceRepeatMode.none,
    },
    shuffleMode: player.shuffleModeEnabled
        ? AudioServiceShuffleMode.all
        : AudioServiceShuffleMode.none,
    queueIndex: event.currentIndex,
  );
}

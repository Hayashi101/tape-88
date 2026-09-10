import 'package:flutter_test/flutter_test.dart';
import 'package:tape_88/core/utils/result.dart';
import 'package:tape_88/features/library/domain/entities/track.dart';
import 'package:tape_88/features/player/data/repositories/in_memory_audio_player_repository.dart';
import 'package:tape_88/features/player/domain/entities/playback_state.dart';

void main() {
  test('loads a queue and changes playback state', () async {
    final repository = InMemoryAudioPlayerRepository();
    const track = Track(
      id: '1',
      title: 'Song',
      artist: 'Artist',
      source: 'song.mp3',
      duration: Duration(minutes: 3),
    );
    expect(await repository.setQueue([track]), isA<Success<void>>());
    expect(repository.currentState.currentTrack, track);
    expect(repository.currentState.queue, [track]);
    await repository.play();
    expect(repository.currentState.status, PlaybackStatus.playing);
    await repository.pause();
    expect(repository.currentState.status, PlaybackStatus.paused);
    await repository.setVolume(.45);
    expect(repository.currentState.volume, .45);
    await repository.setShuffleEnabled(enabled: true);
    expect(repository.currentState.shuffleEnabled, isTrue);
    await repository.setRepeatMode(RepeatMode.one);
    expect(repository.currentState.repeatMode, RepeatMode.one);
    await repository.dispose();
  });

  test('selects and reorders the playback queue', () async {
    final repository = InMemoryAudioPlayerRepository();
    const tracks = [
      Track(
        id: '1',
        title: 'One',
        artist: 'Artist',
        source: 'one.mp3',
        duration: Duration(minutes: 3),
      ),
      Track(
        id: '2',
        title: 'Two',
        artist: 'Artist',
        source: 'two.mp3',
        duration: Duration(minutes: 4),
      ),
      Track(
        id: '3',
        title: 'Three',
        artist: 'Artist',
        source: 'three.mp3',
        duration: Duration(minutes: 5),
      ),
    ];
    await repository.setQueue(tracks);

    await repository.skipToQueueItem(2);
    expect(repository.currentState.currentTrack, tracks[2]);
    expect(repository.currentState.currentIndex, 2);

    await repository.reorderQueue(2, 0);
    expect(repository.currentState.queue.first, tracks[2]);
    expect(repository.currentState.currentIndex, 0);
    expect(repository.currentState.currentTrack, tracks[2]);
    await repository.dispose();
  });

  test('clears the queue and current track', () async {
    final repository = InMemoryAudioPlayerRepository();
    const track = Track(
      id: '1',
      title: 'One',
      artist: 'Artist',
      source: 'one.mp3',
      duration: Duration(minutes: 3),
    );
    await repository.setQueue([track]);
    await repository.clearQueue();

    expect(repository.currentState.queue, isEmpty);
    expect(repository.currentState.currentTrack, isNull);
    expect(repository.currentState.currentIndex, -1);
    await repository.dispose();
  });

  test('removes queue items while preserving the current track', () async {
    final repository = InMemoryAudioPlayerRepository();
    const tracks = [
      Track(
        id: '1',
        title: 'One',
        artist: 'Artist',
        source: 'one.mp3',
        duration: Duration(minutes: 3),
      ),
      Track(
        id: '2',
        title: 'Two',
        artist: 'Artist',
        source: 'two.mp3',
        duration: Duration(minutes: 4),
      ),
      Track(
        id: '3',
        title: 'Three',
        artist: 'Artist',
        source: 'three.mp3',
        duration: Duration(minutes: 5),
      ),
    ];
    await repository.setQueue(tracks, initialIndex: 1);
    await repository.play();

    await repository.removeQueueItem(0);
    expect(repository.currentState.queue, [tracks[1], tracks[2]]);
    expect(repository.currentState.currentTrack, tracks[1]);
    expect(repository.currentState.currentIndex, 0);

    await repository.removeQueueItem(0);
    expect(repository.currentState.queue, [tracks[2]]);
    expect(repository.currentState.currentTrack, tracks[2]);
    expect(repository.currentState.currentIndex, 0);
    expect(repository.currentState.status, PlaybackStatus.playing);
    await repository.dispose();
  });

  test('adds tracks to the end or directly after the current track', () async {
    final repository = InMemoryAudioPlayerRepository();
    const one = Track(
      id: '1',
      title: 'One',
      artist: 'Artist',
      source: 'one.mp3',
      duration: Duration(minutes: 3),
    );
    const two = Track(
      id: '2',
      title: 'Two',
      artist: 'Artist',
      source: 'two.mp3',
      duration: Duration(minutes: 3),
    );
    const three = Track(
      id: '3',
      title: 'Three',
      artist: 'Artist',
      source: 'three.mp3',
      duration: Duration(minutes: 3),
    );
    await repository.setQueue([one]);
    await repository.addToQueue(three, playNext: false);
    await repository.addToQueue(two, playNext: true);

    expect(repository.currentState.queue, [one, two, three]);
    expect(repository.currentState.currentTrack, one);
    await repository.dispose();
  });
}

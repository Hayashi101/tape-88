import 'package:flutter_test/flutter_test.dart';
import 'package:tape_88/features/library/domain/entities/track.dart';
import 'package:tape_88/features/player/data/repositories/file_playback_session_repository.dart';
import 'package:tape_88/features/player/data/repositories/in_memory_audio_player_repository.dart';
import 'package:tape_88/features/player/domain/entities/playback_session.dart';
import 'package:tape_88/features/player/domain/entities/playback_state.dart';
import 'package:tape_88/features/player/presentation/controllers/playback_session_controller.dart';
import 'package:tape_88/features/player/presentation/controllers/player_controller.dart';

void main() {
  test('restores a saved queue paused at its previous position', () async {
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
    ];
    final sessionRepository = InMemoryPlaybackSessionRepository()
      ..session = const PlaybackSession(
        queue: tracks,
        currentIndex: 1,
        position: Duration(seconds: 42),
        repeatMode: RepeatMode.all,
        shuffleEnabled: true,
      );
    final audioRepository = InMemoryAudioPlayerRepository();
    final player = PlayerController(audioRepository);
    final session = PlaybackSessionController(player, sessionRepository);

    await session.initialize();
    expect(player.state.currentTrack, tracks[1]);
    expect(player.state.position, const Duration(seconds: 42));
    expect(player.state.status, PlaybackStatus.paused);
    expect(player.state.repeatMode, RepeatMode.all);
    expect(player.state.shuffleEnabled, isTrue);

    await session.dispose();
    player.dispose();
    await audioRepository.dispose();
  });
}

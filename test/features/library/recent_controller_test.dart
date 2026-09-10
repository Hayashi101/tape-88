import 'package:flutter_test/flutter_test.dart';
import 'package:tape_88/features/library/data/file_play_history_repository.dart';
import 'package:tape_88/features/library/domain/entities/track.dart';
import 'package:tape_88/features/library/presentation/controllers/recent_controller.dart';
import 'package:tape_88/features/player/data/repositories/in_memory_audio_player_repository.dart';
import 'package:tape_88/features/player/presentation/controllers/player_controller.dart';

void main() {
  test('records played tracks once and orders newest first', () async {
    const tracks = [
      Track(
        id: '1',
        title: 'One',
        artist: 'Artist',
        source: 'one',
        duration: Duration(minutes: 3),
      ),
      Track(
        id: '2',
        title: 'Two',
        artist: 'Artist',
        source: 'two',
        duration: Duration(minutes: 3),
      ),
    ];
    final audioRepository = InMemoryAudioPlayerRepository();
    final player = PlayerController(audioRepository);
    final historyRepository = InMemoryPlayHistoryRepository();
    final recent = RecentController(player, historyRepository);
    await recent.initialize();

    await player.loadQueue(tracks);
    await player.play();
    await Future<void>.delayed(Duration.zero);
    await player.selectQueueItem(1);
    await Future<void>.delayed(Duration.zero);

    expect(recent.resolveTracks(tracks), [tracks[1], tracks[0]]);

    await recent.clear();
    expect(recent.entries, isEmpty);
    final restored = RecentController(player, historyRepository);
    await restored.initialize();
    expect(restored.entries, isEmpty);

    restored.disposeController();
    recent.disposeController();
    player.dispose();
    await audioRepository.dispose();
  });
}

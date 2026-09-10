import 'package:flutter_test/flutter_test.dart';
import 'package:tape_88/features/playlists/data/file_playlist_repository.dart';
import 'package:tape_88/features/playlists/presentation/controllers/playlist_controller.dart';

void main() {
  test('creates, renames, updates, and deletes a playlist', () async {
    final repository = InMemoryPlaylistRepository();
    final controller = PlaylistController(repository);
    await controller.initialize();

    final playlist = await controller.create('Night Drive');
    expect(playlist, isNotNull);
    expect(controller.playlists.single.name, 'Night Drive');

    await controller.toggleTrack(playlist!.id, 'track-1');
    expect(controller.playlists.single.trackIds, ['track-1']);
    await controller.toggleTrack(playlist.id, 'track-2');
    await controller.toggleTrack(playlist.id, 'track-3');
    await controller.reorderTracks(playlist.id, 0, 2);
    expect(controller.playlists.single.trackIds, [
      'track-2',
      'track-3',
      'track-1',
    ]);

    await controller.rename(playlist.id, 'After Midnight');
    expect(controller.playlists.single.name, 'After Midnight');

    final restored = PlaylistController(repository);
    await restored.initialize();
    expect(restored.playlists.single.name, 'After Midnight');
    expect(restored.playlists.single.trackIds, [
      'track-2',
      'track-3',
      'track-1',
    ]);

    await restored.delete(playlist.id);
    expect(restored.playlists, isEmpty);
  });
}

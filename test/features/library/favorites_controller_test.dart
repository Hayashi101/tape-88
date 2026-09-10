import 'package:flutter_test/flutter_test.dart';
import 'package:tape_88/features/library/data/file_favorites_repository.dart';
import 'package:tape_88/features/library/domain/entities/track.dart';
import 'package:tape_88/features/library/presentation/controllers/favorites_controller.dart';

void main() {
  test(
    'persists favorites and resolves tracks from the current library',
    () async {
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
      final repository = InMemoryFavoritesRepository();
      final favorites = FavoritesController(repository);
      await favorites.initialize();

      await favorites.toggle(tracks[1]);
      expect(favorites.contains(tracks[1]), isTrue);
      expect(favorites.resolveTracks(tracks), [tracks[1]]);

      final restored = FavoritesController(repository);
      await restored.initialize();
      expect(restored.contains(tracks[1]), isTrue);

      await restored.toggle(tracks[1]);
      expect(restored.contains(tracks[1]), isFalse);
    },
  );
}

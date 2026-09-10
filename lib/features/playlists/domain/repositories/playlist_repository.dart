import 'package:tape_88/features/playlists/domain/entities/playlist.dart';

abstract interface class PlaylistRepository {
  Future<List<Playlist>> load();
  Future<void> save(List<Playlist> playlists);
}

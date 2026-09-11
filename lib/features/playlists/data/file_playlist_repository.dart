import 'package:tape_88/core/storage/json_file_store.dart';
import 'package:tape_88/features/playlists/domain/entities/playlist.dart';
import 'package:tape_88/features/playlists/domain/repositories/playlist_repository.dart';

final class FilePlaylistRepository implements PlaylistRepository {
  final _store = JsonFileStore('playlists.json');

  @override
  Future<List<Playlist>> load() async {
    return _store.load(
      fallback: const <Playlist>[],
      decode: (json) => (json as List<dynamic>)
          .map(
            (item) => Playlist.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(growable: false),
    );
  }

  @override
  Future<void> save(List<Playlist> playlists) async {
    await _store.save(playlists.map((item) => item.toJson()).toList());
  }
}

final class InMemoryPlaylistRepository implements PlaylistRepository {
  List<Playlist> _items = const [];

  @override
  Future<List<Playlist>> load() async => List.unmodifiable(_items);

  @override
  Future<void> save(List<Playlist> playlists) async {
    _items = List.unmodifiable(playlists);
  }
}

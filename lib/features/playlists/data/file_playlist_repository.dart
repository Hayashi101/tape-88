import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:tape_88/features/playlists/domain/entities/playlist.dart';
import 'package:tape_88/features/playlists/domain/repositories/playlist_repository.dart';

final class FilePlaylistRepository implements PlaylistRepository {
  Future<File> get _file async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/playlists.json');
  }

  @override
  Future<List<Playlist>> load() async {
    final file = await _file;
    if (!await file.exists()) return const [];
    final decoded = jsonDecode(await file.readAsString()) as List<dynamic>;
    return decoded
        .map(
          (item) => Playlist.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(growable: false);
  }

  @override
  Future<void> save(List<Playlist> playlists) async {
    final file = await _file;
    await file.writeAsString(
      jsonEncode(playlists.map((item) => item.toJson()).toList()),
    );
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

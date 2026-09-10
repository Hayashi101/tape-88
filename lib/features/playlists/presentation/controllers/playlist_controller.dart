import 'package:flutter/foundation.dart';
import 'package:tape_88/features/playlists/domain/entities/playlist.dart';
import 'package:tape_88/features/playlists/domain/repositories/playlist_repository.dart';

final class PlaylistController extends ChangeNotifier {
  PlaylistController(this._repository);

  final PlaylistRepository _repository;
  List<Playlist> playlists = const [];
  bool isLoading = true;
  String? errorMessage;

  Future<void> initialize() async {
    try {
      playlists = await _repository.load();
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<Playlist?> create(String name) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) return null;
    final playlist = Playlist(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: cleanName,
    );
    playlists = [playlist, ...playlists];
    await _persist();
    return playlist;
  }

  Future<void> rename(String id, String name) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) return;
    playlists = [
      for (final playlist in playlists)
        if (playlist.id == id) playlist.copyWith(name: cleanName) else playlist,
    ];
    await _persist();
  }

  Future<void> delete(String id) async {
    playlists = playlists
        .where((item) => item.id != id)
        .toList(growable: false);
    await _persist();
  }

  Future<void> toggleTrack(String playlistId, String trackId) async {
    playlists = [
      for (final playlist in playlists)
        if (playlist.id == playlistId)
          playlist.copyWith(
            trackIds: playlist.trackIds.contains(trackId)
                ? playlist.trackIds.where((id) => id != trackId).toList()
                : [...playlist.trackIds, trackId],
          )
        else
          playlist,
    ];
    await _persist();
  }

  Future<void> reorderTracks(
    String playlistId,
    int oldIndex,
    int newIndex,
  ) async {
    final playlist = find(playlistId);
    if (playlist == null ||
        oldIndex < 0 ||
        oldIndex >= playlist.trackIds.length ||
        newIndex < 0 ||
        newIndex >= playlist.trackIds.length) {
      return;
    }
    final reordered = [...playlist.trackIds];
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, moved);
    playlists = [
      for (final item in playlists)
        if (item.id == playlistId) item.copyWith(trackIds: reordered) else item,
    ];
    await _persist();
  }

  Playlist? find(String id) {
    for (final playlist in playlists) {
      if (playlist.id == id) return playlist;
    }
    return null;
  }

  Future<void> _persist() async {
    notifyListeners();
    try {
      await _repository.save(playlists);
      errorMessage = null;
    } catch (error) {
      errorMessage = error.toString();
      notifyListeners();
    }
  }
}

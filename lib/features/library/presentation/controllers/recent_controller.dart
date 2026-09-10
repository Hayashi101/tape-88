import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:tape_88/features/library/domain/entities/play_history_entry.dart';
import 'package:tape_88/features/library/domain/entities/track.dart';
import 'package:tape_88/features/library/domain/repositories/play_history_repository.dart';
import 'package:tape_88/features/player/presentation/controllers/player_controller.dart';

final class RecentController extends ChangeNotifier {
  RecentController(this._player, this._repository);

  static const maxEntries = 100;
  final PlayerController _player;
  final PlayHistoryRepository _repository;
  List<PlayHistoryEntry> entries = const [];
  String? _recordedTrackId;
  bool _saving = false;

  Future<void> initialize() async {
    try {
      entries = await _repository.load();
    } catch (_) {
      entries = const [];
    }
    _player.addListener(_onPlaybackChanged);
    notifyListeners();
  }

  List<Track> resolveTracks(List<Track> library) {
    final byId = {for (final track in library) track.id: track};
    return entries
        .map((entry) => byId[entry.trackId])
        .whereType<Track>()
        .toList(growable: false);
  }

  Future<void> clear() async {
    entries = const [];
    notifyListeners();
    await _repository.save(entries);
  }

  void _onPlaybackChanged() {
    final state = _player.state;
    final track = state.currentTrack;
    if (!state.isPlaying || track == null) {
      _recordedTrackId = null;
      return;
    }
    if (_recordedTrackId == track.id || _saving) return;
    _recordedTrackId = track.id;
    unawaited(_record(track.id));
  }

  Future<void> _record(String trackId) async {
    _saving = true;
    entries = [
      PlayHistoryEntry(trackId: trackId, playedAt: DateTime.now()),
      ...entries.where((entry) => entry.trackId != trackId),
    ].take(maxEntries).toList(growable: false);
    notifyListeners();
    try {
      await _repository.save(entries);
    } finally {
      _saving = false;
      final current = _player.state.currentTrack;
      if (_player.state.isPlaying &&
          current != null &&
          current.id != _recordedTrackId) {
        _onPlaybackChanged();
      }
    }
  }

  void disposeController() {
    _player.removeListener(_onPlaybackChanged);
    dispose();
  }
}

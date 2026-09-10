import 'dart:async';

import 'package:tape_88/features/player/domain/entities/playback_session.dart';
import 'package:tape_88/features/player/domain/repositories/playback_session_repository.dart';
import 'package:tape_88/features/player/presentation/controllers/player_controller.dart';
import 'package:tape_88/features/library/presentation/controllers/library_controller.dart';
import 'package:tape_88/features/library/domain/entities/track.dart';

final class PlaybackSessionController {
  PlaybackSessionController(this._player, this._repository, [this._library]);

  final PlayerController _player;
  final PlaybackSessionRepository _repository;
  final LibraryController? _library;
  Timer? _saveTimer;
  bool _restoring = false;
  bool _reconciling = false;

  Future<void> initialize() async {
    _restoring = true;
    try {
      final session = await _repository.load();
      final restoredQueue = session == null ? null : _resolve(session.queue);
      if (session != null &&
          session.queue.isNotEmpty &&
          restoredQueue != null &&
          restoredQueue.isEmpty) {
        await _repository.clear();
      }
      if (session != null &&
          restoredQueue != null &&
          restoredQueue.isNotEmpty &&
          session.currentIndex >= 0 &&
          session.currentIndex < session.queue.length) {
        final previousTrackId = session.queue[session.currentIndex].id;
        var restoredIndex = restoredQueue.indexWhere(
          (track) => track.id == previousTrackId,
        );
        final retainedCurrent = restoredIndex >= 0;
        if (!retainedCurrent) {
          restoredIndex = session.currentIndex.clamp(
            0,
            restoredQueue.length - 1,
          );
        }
        await _player.loadQueue(restoredQueue, initialIndex: restoredIndex);
        final duration = restoredQueue[restoredIndex].duration;
        final savedPosition = retainedCurrent
            ? session.position
            : Duration.zero;
        final position = savedPosition > duration ? duration : savedPosition;
        await _player.seek(position);
        await _player.setRepeatMode(session.repeatMode);
        await _player.setShuffleEnabled(enabled: session.shuffleEnabled);
        await _player.pause();
      }
    } catch (_) {
      await _repository.clear();
    } finally {
      _restoring = false;
      _player.addListener(_scheduleSave);
      _library?.addListener(_onLibraryChanged);
    }
  }

  List<Track>? _resolve(List<Track> savedQueue) {
    final library = _library;
    if (library == null) return savedQueue;
    if (library.status != LibraryStatus.ready &&
        library.status != LibraryStatus.empty) {
      return null;
    }
    final byId = {for (final track in library.tracks) track.id: track};
    return savedQueue
        .map((track) => byId[track.id])
        .whereType<Track>()
        .toList(growable: false);
  }

  void _onLibraryChanged() {
    final library = _library;
    if (library == null ||
        _reconciling ||
        (library.status != LibraryStatus.ready &&
            library.status != LibraryStatus.empty)) {
      return;
    }
    unawaited(_reconcileQueue(library.tracks));
  }

  Future<void> _reconcileQueue(List<Track> libraryTracks) async {
    final state = _player.state;
    if (state.queue.isEmpty) return;
    final byId = {for (final track in libraryTracks) track.id: track};
    final updated = state.queue
        .map((track) => byId[track.id])
        .whereType<Track>()
        .toList(growable: false);
    final unchanged =
        updated.length == state.queue.length &&
        updated.indexed.every(
          (entry) =>
              entry.$2.id == state.queue[entry.$1].id &&
              entry.$2.source == state.queue[entry.$1].source,
        );
    if (unchanged) return;

    _reconciling = true;
    try {
      if (updated.isEmpty) {
        await _player.clearQueue();
        await _repository.clear();
        return;
      }
      final wasPlaying = state.isPlaying;
      final currentId = state.currentTrack?.id;
      var index = updated.indexWhere((track) => track.id == currentId);
      final retainedCurrent = index >= 0;
      if (!retainedCurrent) {
        index = state.currentIndex.clamp(0, updated.length - 1);
      }
      await _player.pause();
      await _player.loadQueue(updated, initialIndex: index);
      if (retainedCurrent) {
        await _player.seek(state.position);
      }
      await _player.setRepeatMode(state.repeatMode);
      await _player.setShuffleEnabled(enabled: state.shuffleEnabled);
      if (wasPlaying) {
        await _player.play();
      }
    } finally {
      _reconciling = false;
    }
  }

  void _scheduleSave() {
    if (_restoring || _saveTimer != null) return;
    _saveTimer = Timer(const Duration(seconds: 1), () async {
      _saveTimer = null;
      await _saveCurrentState();
    });
  }

  Future<void> _saveCurrentState() async {
    final state = _player.state;
    if (state.queue.isEmpty || state.currentIndex < 0) {
      await _repository.clear();
      return;
    }
    await _repository.save(
      PlaybackSession(
        queue: state.queue,
        currentIndex: state.currentIndex,
        position: state.position,
        repeatMode: state.repeatMode,
        shuffleEnabled: state.shuffleEnabled,
      ),
    );
  }

  Future<void> dispose() async {
    _player.removeListener(_scheduleSave);
    _library?.removeListener(_onLibraryChanged);
    _saveTimer?.cancel();
    await _saveCurrentState();
  }
}

import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:tape_88/core/logging/app_logger.dart';
import 'package:tape_88/features/player/data/repositories/in_memory_audio_player_repository.dart';
import 'package:tape_88/features/player/data/repositories/file_playback_session_repository.dart';
import 'package:tape_88/features/player/data/repositories/just_audio_player_repository.dart';
import 'package:tape_88/features/player/data/services/tape_audio_handler.dart';
import 'package:tape_88/features/player/domain/repositories/audio_player_repository.dart';
import 'package:tape_88/features/player/presentation/controllers/player_controller.dart';
import 'package:tape_88/features/player/presentation/controllers/playback_session_controller.dart';
import 'package:tape_88/features/library/data/android_media_library.dart';
import 'package:tape_88/features/library/presentation/controllers/library_controller.dart';
import 'package:tape_88/features/library/data/file_play_history_repository.dart';
import 'package:tape_88/features/library/presentation/controllers/recent_controller.dart';
import 'package:tape_88/features/library/data/file_favorites_repository.dart';
import 'package:tape_88/features/library/presentation/controllers/favorites_controller.dart';
import 'package:tape_88/features/playlists/data/file_playlist_repository.dart';
import 'package:tape_88/features/playlists/presentation/controllers/playlist_controller.dart';
import 'package:tape_88/features/settings/data/file_settings_repository.dart';
import 'package:tape_88/features/settings/presentation/controllers/settings_controller.dart';
import 'package:tape_88/features/search/data/file_search_history_repository.dart';
import 'package:tape_88/features/search/presentation/controllers/search_history_controller.dart';

/// Dependency container for app-wide services.
final class ServiceLocator {
  ServiceLocator._();
  static final ServiceLocator instance = ServiceLocator._();

  late final AudioPlayerRepository audioPlayerRepository;
  late final PlayerController playerController;
  late final LibraryController libraryController;
  late final PlaylistController playlistController;
  late final SettingsController settingsController;
  late final PlaybackSessionController playbackSessionController;
  late final RecentController recentController;
  late final FavoritesController favoritesController;
  late final SearchHistoryController searchHistoryController;
  bool _initialized = false;

  Future<void> initialize({bool useInMemory = false}) async {
    if (_initialized) return;

    if (useInMemory) {
      audioPlayerRepository = InMemoryAudioPlayerRepository();
    } else {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());

      final handler = await AudioService.init<TapeAudioHandler>(
        builder: () => TapeAudioHandler(session),
        config: AudioServiceConfig(
          androidNotificationChannelId: 'com.tape88.playback',
          androidNotificationChannelName: 'Tape 88 playback',
          androidNotificationOngoing: true,
          androidStopForegroundOnPause: true,
        ),
      );
      AudioService.asyncError.listen(
        (error) =>
            AppLogger.error('Audio service platform error', error: error),
      );
      final repository = JustAudioPlayerRepository(handler);
      await repository.initializeDeviceVolume();
      audioPlayerRepository = repository;
    }

    playerController = PlayerController(audioPlayerRepository);
    libraryController = LibraryController(AndroidMediaLibrary(), useInMemory);
    playlistController = PlaylistController(
      useInMemory ? InMemoryPlaylistRepository() : FilePlaylistRepository(),
    );
    settingsController = SettingsController(
      useInMemory ? InMemorySettingsRepository() : FileSettingsRepository(),
    );
    playbackSessionController = PlaybackSessionController(
      playerController,
      useInMemory
          ? InMemoryPlaybackSessionRepository()
          : FilePlaybackSessionRepository(),
      libraryController,
    );
    recentController = RecentController(
      playerController,
      useInMemory
          ? InMemoryPlayHistoryRepository()
          : FilePlayHistoryRepository(),
    );
    favoritesController = FavoritesController(
      useInMemory ? InMemoryFavoritesRepository() : FileFavoritesRepository(),
    );
    searchHistoryController = SearchHistoryController(
      useInMemory
          ? InMemorySearchHistoryRepository()
          : FileSearchHistoryRepository(),
    );
    await libraryController.initialize();
    await playlistController.initialize();
    await settingsController.initialize();
    if (!Platform.isAndroid) {
      await playerController.setVolume(settingsController.volume);
    }
    await playbackSessionController.initialize();
    await playerController.setEqualizerPreset(
      settingsController.equalizerPreset,
    );
    await recentController.initialize();
    await favoritesController.initialize();
    await searchHistoryController.initialize();
    _initialized = true;
  }

  Future<void> dispose() async {
    if (!_initialized) return;
    await playbackSessionController.dispose();
    recentController.disposeController();
    playerController.dispose();
    await audioPlayerRepository.dispose();
    _initialized = false;
  }
}

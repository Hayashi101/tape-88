import 'package:flutter/material.dart';
import 'package:tape_88/app/di/service_locator.dart';
import 'package:tape_88/features/library/presentation/pages/library_page.dart';
import 'package:tape_88/features/player/presentation/pages/now_playing_page.dart';
import 'package:tape_88/features/playlists/presentation/pages/playlists_page.dart';
import 'package:tape_88/features/queue/presentation/pages/queue_page.dart';
import 'package:tape_88/features/settings/presentation/pages/settings_page.dart';
import 'package:tape_88/features/player/presentation/widgets/mini_player.dart';

class AppShellPage extends StatefulWidget {
  const AppShellPage({super.key});
  @override
  State<AppShellPage> createState() => _AppShellPageState();
}

class _AppShellPageState extends State<AppShellPage> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final controller = ServiceLocator.instance.playerController;
    final pages = [
      NowPlayingPage(
        controller: controller,
        onBrowse: () => setState(() => _index = 1),
        favoritesController: ServiceLocator.instance.favoritesController,
        onQueue: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => QueuePage(controller: controller),
          ),
        ),
      ),
      LibraryPage(
        controller: controller,
        libraryController: ServiceLocator.instance.libraryController,
        recentController: ServiceLocator.instance.recentController,
        favoritesController: ServiceLocator.instance.favoritesController,
        searchHistoryController:
            ServiceLocator.instance.searchHistoryController,
        onPlay: () => setState(() => _index = 0),
      ),
      PlaylistsPage(
        controller: controller,
        libraryController: ServiceLocator.instance.libraryController,
        playlistController: ServiceLocator.instance.playlistController,
        onShowNowPlaying: () => setState(() => _index = 0),
      ),
      SettingsPage(
        controller: controller,
        libraryController: ServiceLocator.instance.libraryController,
        settingsController: ServiceLocator.instance.settingsController,
      ),
    ];
    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_index != 0)
            MiniPlayer(
              controller: controller,
              onOpen: () => setState(() => _index = 0),
            ),
          NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (value) => setState(() => _index = value),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.play_circle_outline),
                selectedIcon: Icon(Icons.play_circle),
                label: 'PLAYER',
              ),
              NavigationDestination(
                icon: Icon(Icons.album_outlined),
                selectedIcon: Icon(Icons.album),
                label: 'LIBRARY',
              ),
              NavigationDestination(
                icon: Icon(Icons.queue_music),
                label: 'PLAYLISTS',
              ),
              NavigationDestination(icon: Icon(Icons.tune), label: 'SETTINGS'),
            ],
          ),
        ],
      ),
    );
  }
}

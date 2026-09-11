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

class _AppShellPageState extends State<AppShellPage>
    with SingleTickerProviderStateMixin {
  int _index = 0;
  late final AnimationController _nowPlayingTransition = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
    reverseDuration: const Duration(milliseconds: 220),
    value: 1,
  );
  late final Animation<double> _nowPlayingOpacity = CurvedAnimation(
    parent: _nowPlayingTransition,
    curve: Curves.easeOutCubic,
  );
  late final Animation<Offset> _nowPlayingOffset = Tween<Offset>(
    begin: const Offset(0, .06),
    end: Offset.zero,
  ).animate(_nowPlayingOpacity);

  void _selectPage(int index) {
    if (index == _index) return;
    final opensNowPlaying = index == 0;
    setState(() => _index = index);
    if (opensNowPlaying) {
      _nowPlayingTransition.forward(from: 0);
    } else {
      _nowPlayingTransition.value = 1;
    }
  }

  void _showNowPlaying() => _selectPage(0);

  @override
  void dispose() {
    _nowPlayingTransition.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ServiceLocator.instance.playerController;
    final pages = [
      NowPlayingPage(
        controller: controller,
        onBrowse: () => _selectPage(1),
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
        onPlay: _showNowPlaying,
      ),
      PlaylistsPage(
        controller: controller,
        libraryController: ServiceLocator.instance.libraryController,
        playlistController: ServiceLocator.instance.playlistController,
        onShowNowPlaying: _showNowPlaying,
      ),
      SettingsPage(
        controller: controller,
        libraryController: ServiceLocator.instance.libraryController,
        settingsController: ServiceLocator.instance.settingsController,
      ),
    ];
    return Scaffold(
      body: FadeTransition(
        opacity: _nowPlayingOpacity,
        child: SlideTransition(
          position: _nowPlayingOffset,
          child: IndexedStack(index: _index, children: pages),
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_index != 0)
            MiniPlayer(controller: controller, onOpen: _showNowPlaying),
          NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: _selectPage,
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

import 'package:flutter/material.dart';
import 'package:tape_88/core/theme/app_colors.dart';
import 'package:tape_88/core/widgets/retro_panel.dart';
import 'package:tape_88/features/library/domain/entities/track.dart';
import 'package:tape_88/features/library/presentation/widgets/track_artwork.dart';
import 'package:tape_88/features/player/presentation/controllers/player_controller.dart';
import 'package:tape_88/features/player/presentation/widgets/cassette_deck.dart';
import 'package:tape_88/features/player/presentation/widgets/mini_player.dart';

class AlbumPage extends StatelessWidget {
  const AlbumPage({
    required this.album,
    required this.artist,
    required this.controller,
    required this.tracks,
    required this.onShowNowPlaying,
    this.pageLabel = 'ALBUM / VIRTUAL TAPE',
    super.key,
  });
  final String album;
  final String artist;
  final PlayerController controller;
  final List<Track> tracks;
  final String pageLabel;
  final VoidCallback onShowNowPlaying;

  String get _totalDuration {
    final duration = tracks.fold(
      Duration.zero,
      (total, track) => total + track.duration,
    );
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return hours > 0 ? '${hours}H ${minutes}M' : '${duration.inMinutes} MIN';
  }

  Future<void> _playFrom(int index) async {
    await controller.loadQueue(tracks, initialIndex: index);
    await controller.play();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(pageLabel)),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 8),
        child: MiniPlayer(
          controller: controller,
          onOpen: () {
            Navigator.pop(context);
            onShowNowPlaying();
          },
        ),
      ),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            CassetteDeck(
              track:
                  controller.state.currentTrack != null &&
                      tracks.contains(controller.state.currentTrack)
                  ? controller.state.currentTrack!
                  : tracks.first,
              isPlaying:
                  controller.state.isPlaying &&
                  tracks.contains(controller.state.currentTrack),
              progress:
                  controller.state.currentTrack != null &&
                      tracks.contains(controller.state.currentTrack) &&
                      controller.state.currentTrack!.duration.inMilliseconds > 0
                  ? controller.state.position.inMilliseconds /
                        controller.state.currentTrack!.duration.inMilliseconds
                  : 0,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                TrackArtwork(track: tracks.first, size: 72, borderRadius: 8),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        album,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'sans-serif',
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'sans-serif',
                          fontSize: 16,
                          color: AppColors.textWarm,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        '${tracks.length.toString().padLeft(2, '0')} TRACKS  •  $_totalDuration',
                        style: const TextStyle(
                          color: AppColors.cyan,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: () => _playFrom(0),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('PLAY TAPE'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await controller.loadQueue(tracks);
                      await controller.setShuffleEnabled(enabled: true);
                      await controller.play();
                    },
                    icon: const Icon(Icons.shuffle, size: 18),
                    label: const Text('MIX'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Row(
              children: [
                Text(
                  'TAPE PROGRAM',
                  style: TextStyle(
                    color: AppColors.amber,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(child: Divider(color: AppColors.outlineDark)),
              ],
            ),
            const SizedBox(height: 10),
            ...tracks.indexed.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _AlbumTrackSlot(
                  index: entry.$1,
                  track: entry.$2,
                  active: controller.state.currentTrack == entry.$2,
                  playing:
                      controller.state.currentTrack == entry.$2 &&
                      controller.state.isPlaying,
                  onTap: () => _playFrom(entry.$1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlbumTrackSlot extends StatelessWidget {
  const _AlbumTrackSlot({
    required this.index,
    required this.track,
    required this.active,
    required this.playing,
    required this.onTap,
  });

  final int index;
  final Track track;
  final bool active;
  final bool playing;
  final VoidCallback onTap;

  String get duration =>
      '${track.duration.inMinutes}:${track.duration.inSeconds.remainder(60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) => RetroPanel(
    onTap: onTap,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    color: active ? const Color(0xFF30291E) : AppColors.panel,
    child: Row(
      children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.black,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: active ? AppColors.amber : AppColors.outline,
            ),
          ),
          child: playing
              ? const Icon(Icons.graphic_eq, size: 18, color: AppColors.cyan)
              : Text(
                  '${index + 1}'.padLeft(2, '0'),
                  style: TextStyle(
                    color: active ? AppColors.amber : AppColors.textWarm,
                    fontSize: 11,
                  ),
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                track.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: active ? AppColors.amber : AppColors.text,
                  fontFamily: 'sans-serif',
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                track.artist,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textWarm,
                  fontFamily: 'sans-serif',
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          duration,
          style: TextStyle(
            color: active ? AppColors.amberSoft : AppColors.outline,
            fontSize: 11,
          ),
        ),
      ],
    ),
  );
}

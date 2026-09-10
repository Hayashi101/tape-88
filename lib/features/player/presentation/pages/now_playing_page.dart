import 'package:flutter/material.dart';
import 'package:tape_88/core/theme/app_colors.dart';
import 'package:tape_88/core/widgets/retro_header.dart';
import 'package:tape_88/core/widgets/retro_panel.dart';
import 'package:tape_88/features/player/domain/entities/playback_state.dart'
    as player_state;
import 'package:tape_88/features/player/presentation/controllers/player_controller.dart';
import 'package:tape_88/features/player/presentation/widgets/cassette_deck.dart';
import 'package:tape_88/features/player/presentation/widgets/vu_meter.dart';
import 'package:tape_88/features/library/domain/entities/tape_profile.dart';
import 'package:tape_88/features/library/presentation/controllers/favorites_controller.dart';

class NowPlayingPage extends StatefulWidget {
  const NowPlayingPage({
    required this.controller,
    required this.onQueue,
    required this.onBrowse,
    required this.favoritesController,
    super.key,
  });
  final PlayerController controller;
  final VoidCallback onQueue;
  final VoidCallback onBrowse;
  final FavoritesController favoritesController;
  @override
  State<NowPlayingPage> createState() => _NowPlayingPageState();
}

class _NowPlayingPageState extends State<NowPlayingPage> {
  String _time(Duration d) =>
      '${d.inMinutes.toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const RetroHeader(),
    body: ListenableBuilder(
      listenable: Listenable.merge([
        widget.controller,
        widget.favoritesController,
      ]),
      builder: (context, _) {
        final state = widget.controller.state;
        final track = state.currentTrack;
        if (track == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: RetroPanel(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 34,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.eject_outlined,
                        size: 54,
                        color: AppColors.outline,
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'NO TAPE LOADED',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.amber,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(height: 9),
                      const Text(
                        'Select a track from your local music library.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textWarm,
                          fontFamily: 'sans-serif',
                        ),
                      ),
                      const SizedBox(height: 22),
                      FilledButton.icon(
                        onPressed: widget.onBrowse,
                        icon: const Icon(Icons.library_music),
                        label: const Text('OPEN LIBRARY'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
        final rawProgress = track.duration.inMilliseconds <= 0
            ? 0.0
            : state.position.inMilliseconds / track.duration.inMilliseconds;
        final progress = rawProgress.isFinite
            ? rawProgress.clamp(0.0, 1.0)
            : 0.0;
        final favorite = widget.favoritesController.contains(track);
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                children: [
                  RetroPanel(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'VIRTUAL TAPE  •  ${track.tapeProfile.fullLabel}',
                              style: const TextStyle(
                                color: AppColors.cyan,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 80,
                          child: VuMeter(active: state.isPlaying),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          switch (state.status) {
                            player_state.PlaybackStatus.loading => '● BUFFER',
                            player_state.PlaybackStatus.error => '● ERROR',
                            player_state.PlaybackStatus.completed => '● END',
                            player_state.PlaybackStatus.paused => '● PAUSED',
                            _ => '● STEREO',
                          },
                          style: TextStyle(
                            color:
                                state.status ==
                                    player_state.PlaybackStatus.error
                                ? AppColors.error
                                : state.isPlaying
                                ? AppColors.amberSoft
                                : AppColors.outline,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (state.status == player_state.PlaybackStatus.error) ...[
                    const SizedBox(height: 10),
                    _DeckErrorStrip(
                      message: state.errorMessage ?? 'Playback signal lost.',
                      onRetry: widget.controller.play,
                    ),
                  ],
                  const SizedBox(height: 12),
                  CassetteDeck(
                    track: track,
                    isPlaying: state.isPlaying,
                    progress: progress,
                  ),
                  const SizedBox(height: 22),
                  RetroPanel(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 13,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'NOW PLAYING FROM',
                                style: TextStyle(
                                  color: AppColors.amber,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                track.album ?? 'Unknown album',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'sans-serif',
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${track.artist}  •  TRACK ${(track.trackNumber ?? state.currentIndex + 1).toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                  fontFamily: 'sans-serif',
                                  color: AppColors.textWarm,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                track.sourceQualityLabel,
                                style: const TextStyle(
                                  color: AppColors.outline,
                                  fontSize: 9,
                                  letterSpacing: .7,
                                ),
                              ),
                            ],
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOut,
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: favorite
                                ? AppColors.coral.withValues(alpha: .09)
                                : Colors.transparent,
                            border: Border.all(
                              color: favorite
                                  ? AppColors.coral
                                  : AppColors.outlineDark,
                            ),
                            boxShadow: favorite
                                ? [
                                    BoxShadow(
                                      color: AppColors.coral.withValues(
                                        alpha: .65,
                                      ),
                                      blurRadius: 16,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : null,
                          ),
                          child: IconButton(
                            tooltip: favorite
                                ? 'Remove from favorites'
                                : 'Add to favorites',
                            onPressed: () =>
                                widget.favoritesController.toggle(track),
                            icon: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 180),
                              transitionBuilder: (child, animation) =>
                                  ScaleTransition(
                                    scale: animation,
                                    child: child,
                                  ),
                              child: Icon(
                                favorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                key: ValueKey(favorite),
                                color: favorite
                                    ? AppColors.coral
                                    : AppColors.textWarm,
                                size: 27,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 6,
                      activeTrackColor: AppColors.amber,
                      inactiveTrackColor: AppColors.black,
                      thumbColor: AppColors.amberSoft,
                      overlayColor: AppColors.amber.withValues(alpha: .15),
                    ),
                    child: Slider(
                      value: progress.clamp(0, 1),
                      onChanged: (value) =>
                          widget.controller.seek(track.duration * value),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _time(state.position),
                        style: const TextStyle(color: AppColors.textWarm),
                      ),
                      const Text(
                        'MAGNETIC TAPE TRACK',
                        style: TextStyle(
                          color: AppColors.outline,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        _time(track.duration),
                        style: const TextStyle(color: AppColors.textWarm),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  RetroPanel(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _SmallControl(
                          icon: Icons.shuffle,
                          active: state.shuffleEnabled,
                          onTap: widget.controller.toggleShuffle,
                        ),
                        _SmallControl(
                          icon: Icons.fast_rewind,
                          label: 'RW',
                          onTap: widget.controller.previous,
                        ),
                        _PlayButton(
                          playing: state.isPlaying,
                          loading:
                              state.status ==
                              player_state.PlaybackStatus.loading,
                          onTap: widget.controller.togglePlayback,
                        ),
                        _SmallControl(
                          icon: Icons.fast_forward,
                          label: 'FF',
                          onTap: widget.controller.next,
                        ),
                        _SmallControl(
                          icon: state.repeatMode == player_state.RepeatMode.one
                              ? Icons.repeat_one
                              : Icons.repeat,
                          active:
                              state.repeatMode != player_state.RepeatMode.off,
                          onTap: widget.controller.cycleRepeatMode,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: RetroPanel(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 13,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.volume_down,
                                size: 18,
                                color: AppColors.textWarm,
                              ),
                              Expanded(
                                child: Slider(
                                  value: state.volume,
                                  onChanged: widget.controller.setVolume,
                                  activeColor: AppColors.cyan,
                                  inactiveColor: AppColors.black,
                                ),
                              ),
                              const Icon(
                                Icons.volume_up,
                                size: 18,
                                color: AppColors.textWarm,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      RetroPanel(
                        onTap: widget.onQueue,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 18,
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.queue_music,
                              color: AppColors.amber,
                              size: 20,
                            ),
                            SizedBox(width: 7),
                            Text(
                              'UP NEXT',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

class _DeckErrorStrip extends StatelessWidget {
  const _DeckErrorStrip({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(13, 9, 7, 9),
    decoration: BoxDecoration(
      color: AppColors.error.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppColors.error.withValues(alpha: .45)),
    ),
    child: Row(
      children: [
        const Icon(Icons.warning_amber, color: AppColors.error, size: 19),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            message,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textWarm,
              fontFamily: 'sans-serif',
              fontSize: 12,
            ),
          ),
        ),
        TextButton(onPressed: onRetry, child: const Text('RETRY')),
      ],
    ),
  );
}

class _SmallControl extends StatelessWidget {
  const _SmallControl({
    required this.icon,
    required this.onTap,
    this.label,
    this.active = false,
  });
  final IconData icon;
  final String? label;
  final bool active;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(7),
    child: Container(
      width: 54,
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.panelHigh,
        borderRadius: BorderRadius.circular(7),
        boxShadow: const [
          BoxShadow(color: Colors.black45, offset: Offset(0, 3), blurRadius: 3),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: active ? AppColors.cyan : AppColors.text),
          if (label != null) ...[
            const SizedBox(height: 5),
            Text(
              label!,
              style: const TextStyle(color: AppColors.textWarm, fontSize: 9),
            ),
          ],
        ],
      ),
    ),
  );
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({
    required this.playing,
    required this.loading,
    required this.onTap,
  });
  final bool playing;
  final bool loading;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(18),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: 74,
      height: 74,
      decoration: BoxDecoration(
        color: AppColors.amber,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.amber.withValues(alpha: .28),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: loading
          ? const Padding(
              padding: EdgeInsets.all(23),
              child: CircularProgressIndicator(
                color: AppColors.black,
                strokeWidth: 3,
              ),
            )
          : Icon(
              playing ? Icons.pause : Icons.play_arrow,
              color: AppColors.black,
              size: 40,
            ),
    ),
  );
}

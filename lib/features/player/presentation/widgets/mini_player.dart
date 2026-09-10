import 'package:flutter/material.dart';
import 'package:tape_88/core/theme/app_colors.dart';
import 'package:tape_88/features/library/presentation/widgets/track_artwork.dart';
import 'package:tape_88/features/player/domain/entities/playback_state.dart';
import 'package:tape_88/features/player/presentation/controllers/player_controller.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({required this.controller, required this.onOpen, super.key});

  final PlayerController controller;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final state = controller.state;
      final track = state.currentTrack;
      if (track == null) return const SizedBox.shrink();
      final progress = track.duration.inMilliseconds <= 0
          ? 0.0
          : (state.position.inMilliseconds / track.duration.inMilliseconds)
                .clamp(0.0, 1.0);
      return Material(
        color: AppColors.panelHigh,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Color(0x664FDBCC))),
            boxShadow: [
              BoxShadow(
                color: Color(0x990D0E11),
                blurRadius: 12,
                offset: Offset(0, -3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 68,
                child: Row(
                  children: [
                    const SizedBox(width: 10),
                    InkWell(
                      onTap: onOpen,
                      borderRadius: BorderRadius.circular(6),
                      child: TrackArtwork(track: track, size: 46),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: onOpen,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              track.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'sans-serif',
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              track.artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textWarm,
                                fontFamily: 'sans-serif',
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              state.status == PlaybackStatus.loading
                                  ? 'LOADING SIGNAL...'
                                  : state.isPlaying
                                  ? '● PLAYING'
                                  : 'Ⅱ PAUSED',
                              style: TextStyle(
                                color: state.isPlaying
                                    ? AppColors.cyan
                                    : AppColors.outline,
                                fontSize: 8,
                                letterSpacing: .8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    _ControlButton(
                      tooltip: 'Previous',
                      icon: Icons.skip_previous,
                      onPressed: state.currentIndex >= 0
                          ? controller.previous
                          : null,
                    ),
                    _ControlButton(
                      tooltip: state.isPlaying ? 'Pause' : 'Play',
                      icon: state.isPlaying ? Icons.pause : Icons.play_arrow,
                      highlighted: true,
                      loading: state.status == PlaybackStatus.loading,
                      onPressed: controller.togglePlayback,
                    ),
                    _ControlButton(
                      tooltip: 'Next',
                      icon: Icons.skip_next,
                      onPressed:
                          state.currentIndex >= 0 &&
                              state.currentIndex < state.queue.length - 1
                          ? controller.next
                          : null,
                    ),
                    const SizedBox(width: 5),
                  ],
                ),
              ),
              LinearProgressIndicator(
                value: progress,
                minHeight: 2,
                color: AppColors.amber,
                backgroundColor: AppColors.black,
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.highlighted = false,
    this.loading = false,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool highlighted;
  final bool loading;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    onPressed: onPressed,
    constraints: const BoxConstraints.tightFor(width: 38, height: 42),
    padding: EdgeInsets.zero,
    style: highlighted
        ? IconButton.styleFrom(
            backgroundColor: AppColors.amber,
            foregroundColor: AppColors.black,
          )
        : null,
    icon: loading
        ? const SizedBox.square(
            dimension: 17,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.black,
            ),
          )
        : Icon(icon, size: highlighted ? 22 : 21),
  );
}

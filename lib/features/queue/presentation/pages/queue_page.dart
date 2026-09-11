import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tape_88/core/theme/app_colors.dart';
import 'package:tape_88/core/widgets/retro_panel.dart';
import 'package:tape_88/features/library/presentation/widgets/track_artwork.dart';
import 'package:tape_88/features/player/presentation/controllers/player_controller.dart';

class QueuePage extends StatefulWidget {
  const QueuePage({required this.controller, super.key});
  final PlayerController controller;

  @override
  State<QueuePage> createState() => _QueuePageState();
}

class _QueuePageState extends State<QueuePage> {
  // Used only to estimate the initial position. Items remain content-sized so
  // larger accessibility fonts cannot overflow a fixed-height row.
  static const _estimatedItemExtent = 98.0;
  late final int _initialTargetIndex;
  late final ScrollController _scrollController;
  final GlobalKey _initialTargetKey = GlobalKey();
  bool _initialTargetAligned = false;

  PlayerController get controller => widget.controller;
  final Set<int> _ejectingIndices = <int>{};

  @override
  void initState() {
    super.initState();
    final state = widget.controller.state;
    _initialTargetIndex =
        state.currentIndex >= 0 && state.currentIndex < state.queue.length
        ? state.currentIndex
        : -1;
    _scrollController = ScrollController(
      initialScrollOffset: _initialTargetIndex < 0
          ? 0
          : (_initialTargetIndex - 2).clamp(0, state.queue.length).toDouble() *
                _estimatedItemExtent,
    );
    if (_initialTargetIndex >= 0) _scheduleInitialTargetAlignment();
  }

  void _scheduleInitialTargetAlignment([int attempt = 0]) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _initialTargetAligned) return;
      final targetContext = _initialTargetKey.currentContext;
      if (targetContext == null) {
        final itemCount = controller.state.queue.length;
        if (_scrollController.hasClients &&
            itemCount > 1 &&
            _initialTargetIndex < itemCount) {
          // Once the sliver has laid out its first children it knows a much
          // better total scroll extent than our startup pixel estimate. Jump
          // by index ratio so distant targets are built, then align the real
          // widget precisely on the following frame.
          final targetRatio = _initialTargetIndex / (itemCount - 1);
          final position = _scrollController.position;
          final targetOffset = position.maxScrollExtent * targetRatio;
          if ((position.pixels - targetOffset).abs() > 1) {
            _scrollController.jumpTo(targetOffset);
          }
        }
        if (attempt < 6) _scheduleInitialTargetAlignment(attempt + 1);
        return;
      }
      _initialTargetAligned = true;
      unawaited(
        Scrollable.ensureVisible(
          targetContext,
          alignment: .28,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
        ),
      );
    });
  }

  Future<void> _eject(int index) async {
    setState(() => _ejectingIndices.add(index));
    await controller.removeQueueItem(index);
    await Future<void>.microtask(() {});
    if (mounted) setState(() => _ejectingIndices.remove(index));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _duration(Duration value) {
    final minutes = value.inMinutes;
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _confirmClear(BuildContext context) async {
    final shouldClear = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.panel,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'EJECT ALL TAPES?',
                style: TextStyle(
                  color: AppColors.amber,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'This clears the playback queue and stops the current track.',
                style: TextStyle(color: AppColors.textWarm),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(sheetContext, false),
                      child: const Text('KEEP QUEUE'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => Navigator.pop(sheetContext, true),
                      icon: const Icon(Icons.eject),
                      label: const Text('EJECT'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (shouldClear == true) await controller.clearQueue();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('UP NEXT / QUEUE')),
    body: ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final tracks = controller.state.queue;
        if (tracks.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.eject, size: 48, color: AppColors.outline),
                SizedBox(height: 12),
                Text('TAPE QUEUE IS EMPTY'),
              ],
            ),
          );
        }
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                children: [
                  Text(
                    '${tracks.length.toString().padLeft(2, '0')} TAPES LOADED',
                    style: const TextStyle(
                      color: AppColors.amber,
                      fontSize: 10,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _confirmClear(context),
                    icon: const Icon(Icons.eject, size: 15),
                    label: const Text('EJECT ALL'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textWarm,
                      textStyle: const TextStyle(fontSize: 9),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ReorderableListView.builder(
                scrollController: _scrollController,
                padding: const EdgeInsets.all(16),
                buildDefaultDragHandles: false,
                itemCount: tracks.length,
                onReorderItem: controller.reorderQueue,
                itemBuilder: (_, i) {
                  final track = tracks[i];
                  final active = controller.state.currentIndex == i;
                  final itemKey = ValueKey(
                    'queue-${tracks.length}-${track.id}-${track.source}-$i',
                  );
                  if (_ejectingIndices.contains(i)) {
                    return SizedBox.shrink(key: itemKey);
                  }
                  return Dismissible(
                    key: itemKey,
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) => _eject(i),
                    background: const SizedBox.shrink(),
                    secondaryBackground: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      alignment: Alignment.centerRight,
                      decoration: BoxDecoration(
                        color: AppColors.coral.withValues(alpha: .14),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.coral.withValues(alpha: .72),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'EJECT',
                            style: TextStyle(
                              color: AppColors.coral,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.eject, color: AppColors.coral, size: 21),
                        ],
                      ),
                    ),
                    child: KeyedSubtree(
                      key: i == _initialTargetIndex ? _initialTargetKey : null,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: RetroPanel(
                          padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                          onTap: () async {
                            await controller.selectQueueItem(i);
                            await controller.play();
                          },
                          color: active
                              ? const Color(0xFF30291E)
                              : AppColors.panel,
                          child: Row(
                            children: [
                              Icon(
                                active && controller.state.isPlaying
                                    ? Icons.graphic_eq
                                    : Icons.circle,
                                size: active ? 20 : 7,
                                color: active
                                    ? AppColors.cyan
                                    : AppColors.outline,
                              ),
                              const SizedBox(width: 9),
                              TrackArtwork(
                                track: track,
                                size: 50,
                                borderRadius: 4,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      track.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily: 'sans-serif',
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: active
                                            ? AppColors.amber
                                            : AppColors.text,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      track.artist,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontFamily: 'sans-serif',
                                        color: AppColors.textWarm,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 3,
                                    ),
                                    child: Text(
                                      _duration(track.duration),
                                      style: TextStyle(
                                        color: active
                                            ? AppColors.amber
                                            : AppColors.textWarm,
                                        fontSize: 10,
                                        letterSpacing: .6,
                                      ),
                                    ),
                                  ),
                                  ReorderableDragStartListener(
                                    index: i,
                                    child: Container(
                                      width: 34,
                                      height: 28,
                                      alignment: Alignment.center,
                                      child: const Icon(
                                        Icons.drag_indicator,
                                        color: AppColors.cyan,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    ),
  );
}

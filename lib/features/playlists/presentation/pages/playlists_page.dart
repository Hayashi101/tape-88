import 'package:flutter/material.dart';
import 'package:tape_88/core/theme/app_colors.dart';
import 'package:tape_88/core/widgets/retro_header.dart';
import 'package:tape_88/core/widgets/retro_panel.dart';
import 'package:tape_88/core/widgets/retro_notice.dart';
import 'package:tape_88/core/widgets/retro_dialog.dart';
import 'package:tape_88/core/widgets/retro_action_sheet.dart';
import 'package:tape_88/features/library/domain/entities/track.dart';
import 'package:tape_88/features/library/presentation/controllers/library_controller.dart';
import 'package:tape_88/features/player/presentation/controllers/player_controller.dart';
import 'package:tape_88/features/player/presentation/widgets/mini_player.dart';
import 'package:tape_88/features/playlists/domain/entities/playlist.dart';
import 'package:tape_88/features/playlists/presentation/controllers/playlist_controller.dart';

class PlaylistsPage extends StatelessWidget {
  const PlaylistsPage({
    required this.controller,
    required this.libraryController,
    required this.playlistController,
    required this.onShowNowPlaying,
    super.key,
  });

  final PlayerController controller;
  final LibraryController libraryController;
  final PlaylistController playlistController;
  final VoidCallback onShowNowPlaying;

  List<Track> _tracksFor(Playlist playlist) {
    final byId = {
      for (final track in libraryController.tracks) track.id: track,
    };
    return playlist.trackIds.map((id) => byId[id]).whereType<Track>().toList();
  }

  Future<void> _create(BuildContext context) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const RetroTextInputDialog(
        title: 'NEW MIXTAPE',
        confirmLabel: 'CREATE',
        hintText: 'Mixtape name',
      ),
    );
    if (name == null || !context.mounted) return;
    final playlist = await playlistController.create(name);
    if (playlist != null && context.mounted) _open(context, playlist);
  }

  void _open(BuildContext context, Playlist playlist) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => _PlaylistDetailPage(
          playlistId: playlist.id,
          controller: controller,
          libraryController: libraryController,
          playlistController: playlistController,
          onShowNowPlaying: onShowNowPlaying,
        ),
      ),
    );
  }

  Future<void> _rename(BuildContext context, Playlist playlist) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => RetroTextInputDialog(
        title: 'RENAME MIXTAPE',
        confirmLabel: 'SAVE',
        initialValue: playlist.name,
        hintText: 'Mixtape name',
      ),
    );
    if (name != null) await playlistController.rename(playlist.id, name);
  }

  Future<void> _delete(BuildContext context, Playlist playlist) async {
    if (await _confirmDelete(context, playlist) == true) {
      await playlistController.delete(playlist.id);
    }
  }

  Future<void> _showActions(BuildContext context, Playlist playlist) async {
    final action = await _showPlaylistActionSheet(context, playlist);
    if (!context.mounted) return;
    if (action == 'rename') {
      await _rename(context, playlist);
    } else if (action == 'delete') {
      await _delete(context, playlist);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const RetroHeader(compact: true),
    body: ListenableBuilder(
      listenable: Listenable.merge([playlistController, libraryController]),
      builder: (context, _) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          const Text(
            '● MIXTAPE VAULT',
            style: TextStyle(color: AppColors.amber, fontSize: 9),
          ),
          Text(
            '${playlistController.playlists.length} Cassettes\nLoaded',
            style: const TextStyle(
              fontFamily: 'sans-serif',
              fontSize: 26,
              height: 1,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          RetroPanel(
            color: const Color(0xFF2B2117),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '★ BLANK TAPE C-90',
                        style: TextStyle(color: AppColors.amber, fontSize: 9),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Record A New\nMixtape',
                        style: TextStyle(
                          fontFamily: 'sans-serif',
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => _create(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('NEW'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text('▣ CASSETTE RACK'),
          const SizedBox(height: 12),
          if (playlistController.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (playlistController.playlists.isEmpty)
            const _EmptyPlaylists()
          else
            ...playlistController.playlists.indexed.map((entry) {
              final playlist = entry.$2;
              final tracks = _tracksFor(playlist);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _TapeCard(
                  key: ValueKey(playlist.id),
                  playlist: playlist,
                  tracks: tracks,
                  colorIndex: entry.$1,
                  onOpen: () => _open(context, playlist),
                  onMenu: () => _showActions(context, playlist),
                  onPlay: tracks.isEmpty
                      ? null
                      : () async {
                          await controller.loadQueue(tracks);
                          await controller.play();
                        },
                ),
              );
            }),
        ],
      ),
    ),
  );
}

class _PlaylistDetailPage extends StatelessWidget {
  const _PlaylistDetailPage({
    required this.playlistId,
    required this.controller,
    required this.libraryController,
    required this.playlistController,
    required this.onShowNowPlaying,
  });

  final String playlistId;
  final PlayerController controller;
  final LibraryController libraryController;
  final PlaylistController playlistController;
  final VoidCallback onShowNowPlaying;

  List<Track> _tracks(Playlist playlist) {
    final byId = {
      for (final track in libraryController.tracks) track.id: track,
    };
    return playlist.trackIds.map((id) => byId[id]).whereType<Track>().toList();
  }

  String _totalDuration(List<Track> tracks) {
    final duration = tracks.fold(
      Duration.zero,
      (total, track) => total + track.duration,
    );
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return hours > 0 ? '${hours}H ${minutes}M' : '${duration.inMinutes} MIN';
  }

  Future<void> _rename(BuildContext context, Playlist playlist) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => RetroTextInputDialog(
        title: 'RENAME MIXTAPE',
        confirmLabel: 'SAVE',
        initialValue: playlist.name,
        hintText: 'Mixtape name',
      ),
    );
    if (name != null) await playlistController.rename(playlist.id, name);
  }

  Future<void> _chooseTracks(BuildContext context, Playlist playlist) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.background,
      builder: (_) => _TrackPickerSheet(
        playlistId: playlist.id,
        libraryController: libraryController,
        playlistController: playlistController,
      ),
    );
  }

  Future<void> _showTrackActions(
    BuildContext context,
    Playlist playlist,
    Track track,
  ) async {
    final action = await showRetroActionSheet<String>(
      context: context,
      title: 'TRACK CONTROL',
      subject: track.title,
      actions: const [
        RetroActionItem(
          value: 'next',
          icon: Icons.skip_next,
          label: 'PLAY NEXT',
        ),
        RetroActionItem(
          value: 'queue',
          icon: Icons.queue_music,
          label: 'ADD TO QUEUE',
        ),
        RetroActionItem(
          value: 'remove',
          icon: Icons.remove_circle_outline,
          label: 'REMOVE FROM MIXTAPE',
          destructive: true,
        ),
      ],
    );
    if (!context.mounted || action == null) return;
    if (action == 'remove') {
      await playlistController.toggleTrack(playlist.id, track.id);
      return;
    }
    final result = await controller.addToQueue(
      track,
      playNext: action == 'next',
    );
    if (!context.mounted) return;
    result.fold(
      onSuccess: (_) => showRetroNotice(
        context,
        message: action == 'next' ? 'READY TO PLAY NEXT' : 'ADDED TO QUEUE',
        type: RetroNoticeType.success,
      ),
      onFailure: (failure) => showRetroNotice(
        context,
        message: failure.message,
        type: RetroNoticeType.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([
      playlistController,
      libraryController,
      controller,
    ]),
    builder: (context, _) {
      final playlist = playlistController.find(playlistId);
      if (playlist == null) {
        return const Scaffold(body: Center(child: Text('MIXTAPE NOT FOUND')));
      }
      final tracks = _tracks(playlist);
      return Scaffold(
        appBar: AppBar(
          title: Text(playlist.name),
          actions: [
            IconButton(
              tooltip: 'Mixtape actions',
              onPressed: () async {
                final action = await _showPlaylistActionSheet(
                  context,
                  playlist,
                );
                if (!context.mounted || action == null) return;
                if (action == 'rename') {
                  await _rename(context, playlist);
                } else if (action == 'delete') {
                  if (await _confirmDelete(context, playlist) == true) {
                    await playlistController.delete(playlist.id);
                    if (context.mounted) Navigator.pop(context);
                  }
                }
              },
              icon: const Icon(Icons.more_horiz),
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: Column(
                children: [
                  RetroPanel(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.album,
                          size: 44,
                          color: AppColors.amber,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${tracks.length} TRACKS',
                                style: const TextStyle(
                                  color: AppColors.amber,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _totalDuration(tracks),
                                style: const TextStyle(
                                  color: AppColors.cyan,
                                  fontSize: 10,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton.filled(
                          tooltip: 'Play mixtape',
                          onPressed: tracks.isEmpty
                              ? null
                              : () async {
                                  await controller.loadQueue(tracks);
                                  await controller.play();
                                },
                          icon: const Icon(Icons.play_arrow),
                        ),
                        const SizedBox(width: 6),
                        IconButton.outlined(
                          tooltip: 'Shuffle mixtape',
                          style: IconButton.styleFrom(
                            foregroundColor: AppColors.cyan,
                            side: BorderSide(
                              color: AppColors.cyan.withValues(alpha: .72),
                            ),
                          ),
                          onPressed: tracks.isEmpty
                              ? null
                              : () async {
                                  await controller.loadQueue(tracks);
                                  await controller.setShuffleEnabled(
                                    enabled: true,
                                  );
                                  await controller.play();
                                },
                          icon: const Icon(Icons.shuffle, size: 19),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _chooseTracks(context, playlist),
                      icon: const Icon(Icons.playlist_add),
                      label: const Text('ADD / REMOVE TRACKS'),
                    ),
                  ),
                  if (tracks.length > 1) ...[
                    const SizedBox(height: 8),
                    const Row(
                      children: [
                        Icon(
                          Icons.drag_indicator,
                          size: 14,
                          color: AppColors.outline,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'DRAG HANDLE TO REORDER TAPE',
                          style: TextStyle(
                            color: AppColors.outline,
                            fontSize: 9,
                            letterSpacing: .7,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: tracks.isEmpty
                  ? const Center(child: Text('THIS MIXTAPE IS BLANK'))
                  : ReorderableListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 2, 16, 16),
                      buildDefaultDragHandles: false,
                      itemCount: tracks.length,
                      onReorderItem: (oldIndex, newIndex) => playlistController
                          .reorderTracks(playlist.id, oldIndex, newIndex),
                      itemBuilder: (context, index) {
                        final track = tracks[index];
                        final active = controller.state.currentTrack == track;
                        return Padding(
                          key: ValueKey(track.id),
                          padding: const EdgeInsets.only(bottom: 8),
                          child: RetroPanel(
                            onTap: () async {
                              await controller.loadQueue(
                                tracks,
                                initialIndex: index,
                              );
                              await controller.play();
                            },
                            padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
                            color: active
                                ? const Color(0xFF30291E)
                                : AppColors.panel,
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 28,
                                  child: active && controller.state.isPlaying
                                      ? const Icon(
                                          Icons.graphic_eq,
                                          size: 18,
                                          color: AppColors.cyan,
                                        )
                                      : Text(
                                          '${index + 1}'.padLeft(2, '0'),
                                          style: TextStyle(
                                            color: active
                                                ? AppColors.amber
                                                : AppColors.outline,
                                            fontSize: 11,
                                          ),
                                        ),
                                ),
                                const SizedBox(width: 7),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        track.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: active
                                              ? AppColors.amber
                                              : AppColors.text,
                                          fontFamily: 'sans-serif',
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
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
                                IconButton(
                                  tooltip: 'Track actions',
                                  onPressed: () => _showTrackActions(
                                    context,
                                    playlist,
                                    track,
                                  ),
                                  icon: const Icon(
                                    Icons.more_vert,
                                    color: AppColors.amberSoft,
                                    size: 20,
                                  ),
                                ),
                                ReorderableDragStartListener(
                                  index: index,
                                  child: const Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Icon(
                                      Icons.drag_indicator,
                                      color: AppColors.cyan,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
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
      );
    },
  );
}

Future<String?> _showPlaylistActionSheet(
  BuildContext context,
  Playlist playlist,
) => showRetroActionSheet<String>(
  context: context,
  title: 'MIXTAPE CONTROL',
  subject: playlist.name,
  actions: const [
    RetroActionItem(
      value: 'rename',
      icon: Icons.edit_outlined,
      label: 'RENAME MIXTAPE',
    ),
    RetroActionItem(
      value: 'delete',
      icon: Icons.delete_outline,
      label: 'DELETE MIXTAPE',
      destructive: true,
    ),
  ],
);

Future<bool?> _confirmDelete(BuildContext context, Playlist playlist) =>
    showDialog<bool>(
      context: context,
      builder: (_) => RetroConfirmDialog(
        title: 'ERASE MIXTAPE?',
        message: 'Delete “${playlist.name}”? This cannot be undone.',
        confirmLabel: 'DELETE',
        destructive: true,
      ),
    );

class _TrackPickerSheet extends StatefulWidget {
  const _TrackPickerSheet({
    required this.playlistId,
    required this.libraryController,
    required this.playlistController,
  });

  final String playlistId;
  final LibraryController libraryController;
  final PlaylistController playlistController;

  @override
  State<_TrackPickerSheet> createState() => _TrackPickerSheetState();
}

class _TrackPickerSheetState extends State<_TrackPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  List<Track> get _results {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return widget.libraryController.tracks;
    return widget.libraryController.tracks
        .where((track) {
          final text = '${track.title} ${track.artist} ${track.album ?? ''}'
              .toLowerCase();
          return text.contains(query);
        })
        .toList(growable: false);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playlist = widget.playlistController.find(widget.playlistId);
    final selectedIds = playlist?.trackIds ?? const <String>[];
    final results = _results;
    return FractionallySizedBox(
      heightFactor: .9,
      child: Column(
        children: [
          Container(
            width: 38,
            height: 4,
            margin: const EdgeInsets.only(top: 9, bottom: 5),
            decoration: BoxDecoration(
              color: AppColors.outlineDark,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
                const Expanded(
                  child: Text(
                    'SELECT TRACKS',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.amber,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('DONE'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: AppColors.cyan),
                hintText: 'Search title, artist or album...',
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                        icon: const Icon(Icons.clear),
                      ),
                filled: true,
                fillColor: AppColors.panelHigh,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
            child: Row(
              children: [
                Text(
                  '${selectedIds.length} SELECTED',
                  style: const TextStyle(color: AppColors.cyan, fontSize: 9),
                ),
                const Spacer(),
                Text(
                  '${results.length} RESULTS',
                  style: const TextStyle(color: AppColors.outline, fontSize: 9),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0x334FDBCC)),
          Expanded(
            child: results.isEmpty
                ? const Center(child: Text('NO MATCHING TRACKS'))
                : ListView.builder(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final track = results[index];
                      return CheckboxListTile(
                        value: selectedIds.contains(track.id),
                        title: Text(
                          track.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${track.artist} • ${track.album ?? 'Unknown album'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onChanged: (_) async {
                          await widget.playlistController.toggleTrack(
                            widget.playlistId,
                            track.id,
                          );
                          if (mounted) setState(() {});
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPlaylists extends StatelessWidget {
  const _EmptyPlaylists();

  @override
  Widget build(BuildContext context) => const RetroPanel(
    padding: EdgeInsets.all(28),
    child: Column(
      children: [
        Icon(Icons.video_library_outlined, size: 46, color: AppColors.outline),
        SizedBox(height: 12),
        Text('CASSETTE RACK IS EMPTY'),
        SizedBox(height: 6),
        Text(
          'Create your first personal mixtape.',
          style: TextStyle(color: AppColors.textWarm, fontFamily: 'sans-serif'),
        ),
      ],
    ),
  );
}

class _TapeCard extends StatelessWidget {
  const _TapeCard({
    required this.playlist,
    required this.tracks,
    required this.colorIndex,
    required this.onOpen,
    required this.onPlay,
    required this.onMenu,
    super.key,
  });

  final Playlist playlist;
  final List<Track> tracks;
  final int colorIndex;
  final VoidCallback onOpen;
  final VoidCallback? onPlay;
  final VoidCallback onMenu;

  static const colors = [
    (Color(0xFF3E2712), AppColors.amber),
    (Color(0xFF003630), AppColors.cyan),
    (Color(0xFF302B27), AppColors.textWarm),
    (Color(0xFF510D18), AppColors.coral),
  ];

  @override
  Widget build(BuildContext context) {
    final (color, accent) = colors[colorIndex % colors.length];
    final total = tracks.fold(
      Duration.zero,
      (sum, track) => sum + track.duration,
    );
    final duration = total.inHours > 0
        ? '${total.inHours}h ${total.inMinutes.remainder(60)}m'
        : '${total.inMinutes}m';
    return RetroPanel(
      onTap: onOpen,
      padding: const EdgeInsets.all(6),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 10, 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: accent.withValues(alpha: .28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'TAPE 88  •  PERSONAL MIXTAPE',
                  style: TextStyle(
                    color: accent,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Mixtape actions',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 32,
                    height: 28,
                  ),
                  icon: Icon(Icons.more_horiz, color: accent, size: 19),
                  onPressed: onMenu,
                ),
              ],
            ),
            const SizedBox(height: 1),
            Text(
              playlist.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'sans-serif',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                fontStyle: FontStyle.italic,
                color: accent,
              ),
            ),
            const SizedBox(height: 7),
            _MixtapeWindow(accent: accent, trackCount: tracks.length),
            const SizedBox(height: 7),
            Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: tracks.isEmpty ? AppColors.outlineDark : accent,
                    shape: BoxShape.circle,
                    boxShadow: tracks.isEmpty
                        ? null
                        : [BoxShadow(color: accent, blurRadius: 6)],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${tracks.length} TRACKS  •  $duration',
                    style: TextStyle(
                      color: accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: .55,
                    ),
                  ),
                ),
                IconButton.filled(
                  onPressed: onPlay,
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: AppColors.black,
                    minimumSize: const Size(38, 34),
                    maximumSize: const Size(38, 34),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  tooltip: 'Play mixtape',
                  icon: const Icon(Icons.play_arrow, size: 21),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MixtapeWindow extends StatelessWidget {
  const _MixtapeWindow({required this.accent, required this.trackCount});

  final Color accent;
  final int trackCount;

  @override
  Widget build(BuildContext context) => Container(
    height: 68,
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
    decoration: BoxDecoration(
      color: AppColors.black.withValues(alpha: .88),
      borderRadius: BorderRadius.circular(5),
      border: Border.all(color: Colors.black),
    ),
    child: Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          child: Align(
            child: Container(height: 7, color: accent.withValues(alpha: .42)),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _TapeReel(accent: accent),
            Container(
              width: 74,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFF17181C),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: accent.withValues(alpha: .24)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    trackCount.toString().padLeft(2, '0'),
                    style: TextStyle(
                      color: accent,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'TRACKS',
                    style: TextStyle(
                      color: accent.withValues(alpha: .75),
                      fontSize: 7,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
            _TapeReel(accent: accent),
          ],
        ),
      ],
    ),
  );
}

class _TapeReel extends StatelessWidget {
  const _TapeReel({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) => Container(
    width: 43,
    height: 43,
    decoration: BoxDecoration(
      color: accent.withValues(alpha: .26),
      shape: BoxShape.circle,
      border: Border.all(color: accent.withValues(alpha: .65), width: 2),
    ),
    child: Icon(Icons.settings, color: accent, size: 29),
  );
}

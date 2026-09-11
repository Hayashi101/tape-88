import 'package:flutter/material.dart';
import 'package:tape_88/core/theme/app_colors.dart';
import 'package:tape_88/core/widgets/retro_header.dart';
import 'package:tape_88/core/widgets/retro_panel.dart';
import 'package:tape_88/core/widgets/retro_notice.dart';
import 'package:tape_88/core/widgets/retro_dialog.dart';
import 'package:tape_88/core/widgets/retro_action_sheet.dart';
import 'package:tape_88/features/albums/presentation/pages/album_page.dart';
import 'package:tape_88/features/library/domain/entities/track.dart';
import 'package:tape_88/features/library/domain/entities/tape_profile.dart';
import 'package:tape_88/features/library/presentation/controllers/library_controller.dart';
import 'package:tape_88/features/library/presentation/controllers/recent_controller.dart';
import 'package:tape_88/features/library/presentation/controllers/favorites_controller.dart';
import 'package:tape_88/features/library/presentation/widgets/track_artwork.dart';
import 'package:tape_88/features/player/presentation/controllers/player_controller.dart';
import 'package:tape_88/features/search/presentation/pages/search_page.dart';
import 'package:tape_88/features/search/presentation/controllers/search_history_controller.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({
    required this.controller,
    required this.libraryController,
    required this.onPlay,
    required this.recentController,
    required this.favoritesController,
    required this.searchHistoryController,
    super.key,
  });
  final PlayerController controller;
  final LibraryController libraryController;
  final VoidCallback onPlay;
  final RecentController recentController;
  final FavoritesController favoritesController;
  final SearchHistoryController searchHistoryController;
  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  int _filter = 0;
  _LibrarySort _sort = _LibrarySort.trackNumber;
  bool _sortAscending = true;
  final Map<int, bool> _tabSortAscending = {
    1: true,
    2: true,
    3: false,
    4: true,
  };
  static const filters = [
    'ALL SONGS',
    'ALBUMS',
    'ARTISTS',
    'RECENT',
    'FAVORITES',
  ];

  Future<void> _play(Track track) async {
    final tracks = _sortedTracks;
    final index = tracks.indexOf(track);
    await widget.controller.loadQueue(tracks, initialIndex: index);
    await widget.controller.play();
  }

  List<Track> get _sortedTracks {
    final tracks = [...widget.libraryController.tracks];
    int text(String a, String b) => a.toLowerCase().compareTo(b.toLowerCase());
    final compare = switch (_sort) {
      _LibrarySort.title => (a, b) => text(a.title, b.title),
      _LibrarySort.artist => (a, b) {
        final result = text(a.artist, b.artist);
        return result != 0 ? result : text(a.title, b.title);
      },
      _LibrarySort.album => (a, b) {
        final result = text(a.album ?? '', b.album ?? '');
        return result != 0 ? result : text(a.title, b.title);
      },
      _LibrarySort.duration => (a, b) => a.duration.compareTo(b.duration),
      _LibrarySort.trackNumber => (a, b) {
        final result = (a.trackNumber ?? 999999).compareTo(
          b.trackNumber ?? 999999,
        );
        return result != 0 ? result : text(a.title, b.title);
      },
    };
    tracks.sort((a, b) => _sortAscending ? compare(a, b) : compare(b, a));
    return tracks;
  }

  Future<void> _chooseSort() async {
    final selected = await showModalBottomSheet<_LibrarySort>(
      context: context,
      backgroundColor: AppColors.background,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'LIBRARY SORT MODE',
                style: TextStyle(
                  color: AppColors.amber,
                  fontSize: 10,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              RetroPanel(
                padding: EdgeInsets.zero,
                child: Column(
                  children: _LibrarySort.values
                      .map(
                        (sort) => ListTile(
                          title: Text(sort.label),
                          leading: Icon(
                            sort.icon,
                            color: sort == _sort
                                ? AppColors.cyan
                                : AppColors.outline,
                          ),
                          trailing: Icon(
                            sort == _sort
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color: sort == _sort
                                ? AppColors.amber
                                : AppColors.outlineDark,
                          ),
                          onTap: () => Navigator.pop(sheetContext, sort),
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (selected != null && mounted) {
      setState(() {
        _sort = selected;
        _sortAscending = true;
      });
    }
  }

  Future<void> _rescanLibrary() async {
    await widget.libraryController.refresh();
    if (!mounted) return;
    final count = widget.libraryController.tracks.length;
    showRetroNotice(
      context,
      message: 'LIBRARY RESCANNED • $count TRACKS FOUND',
      type: RetroNoticeType.success,
    );
  }

  Future<void> _playRecent(Track track) async {
    final tracks = _recentTracks;
    await widget.controller.loadQueue(
      tracks,
      initialIndex: tracks.indexOf(track),
    );
    await widget.controller.play();
  }

  Future<void> _playFavorite(Track track) async {
    final tracks = _favoriteTracks;
    await widget.controller.loadQueue(
      tracks,
      initialIndex: tracks.indexOf(track),
    );
    await widget.controller.play();
  }

  Future<void> _playTrackSet(
    List<Track> tracks, {
    required bool shuffle,
  }) async {
    if (tracks.isEmpty) return;
    await widget.controller.loadQueue(tracks);
    await widget.controller.setShuffleEnabled(enabled: shuffle);
    await widget.controller.play();
  }

  Future<void> _confirmClearRecent() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const RetroConfirmDialog(
        title: 'CLEAR PLAY HISTORY?',
        message:
            'Remove every track from Recent? Your music files and favorites will not be changed.',
        cancelLabel: 'KEEP HISTORY',
        confirmLabel: 'CLEAR',
        destructive: true,
      ),
    );
    if (confirmed == true) await widget.recentController.clear();
  }

  Future<void> _showTrackActions(Track track) async {
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
          value: 'album',
          icon: Icons.album_outlined,
          label: 'OPEN ALBUM',
        ),
      ],
    );
    if (!mounted || action == null) return;
    if (action == 'album') {
      _openTrackAlbum(track);
      return;
    }
    final result = await widget.controller.addToQueue(
      track,
      playNext: action == 'next',
    );
    if (!mounted) return;
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

  void _openTrackAlbum(Track track) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AlbumPage(
          album: track.album ?? 'Album',
          artist: track.artist,
          tracks: widget.libraryController.tracks
              .where(
                (candidate) =>
                    candidate.album == track.album &&
                    candidate.artist == track.artist,
              )
              .toList(growable: false),
          controller: widget.controller,
          onShowNowPlaying: widget.onPlay,
        ),
      ),
    );
  }

  List<_TrackCollection> _collectionsByAlbum(List<Track> tracks) {
    final grouped = <String, List<Track>>{};
    for (final track in tracks) {
      final key = '${track.album ?? 'Unknown album'}\u0000${track.artist}';
      grouped.putIfAbsent(key, () => []).add(track);
    }
    final collections = grouped.entries.map((entry) {
      final separator = entry.key.indexOf('\u0000');
      return _TrackCollection(
        title: entry.key.substring(0, separator),
        subtitle: entry.key.substring(separator + 1),
        tracks: entry.value,
      );
    }).toList();
    final ascending = _tabSortAscending[1] ?? true;
    collections.sort(
      (a, b) => ascending
          ? a.title.toLowerCase().compareTo(b.title.toLowerCase())
          : b.title.toLowerCase().compareTo(a.title.toLowerCase()),
    );
    return collections;
  }

  List<_TrackCollection> _collectionsByArtist(List<Track> tracks) {
    final grouped = <String, List<Track>>{};
    for (final track in tracks) {
      grouped.putIfAbsent(track.artist, () => []).add(track);
    }
    final collections = grouped.entries
        .map(
          (entry) => _TrackCollection(
            title: entry.key,
            subtitle: '${entry.value.length} tracks',
            tracks: entry.value,
          ),
        )
        .toList();
    final ascending = _tabSortAscending[2] ?? true;
    collections.sort(
      (a, b) => ascending
          ? a.title.toLowerCase().compareTo(b.title.toLowerCase())
          : b.title.toLowerCase().compareTo(a.title.toLowerCase()),
    );
    return collections;
  }

  List<Track> get _recentTracks {
    final tracks = widget.recentController.resolveTracks(
      widget.libraryController.tracks,
    );
    return (_tabSortAscending[3] ?? false)
        ? tracks.reversed.toList(growable: false)
        : tracks;
  }

  List<Track> get _favoriteTracks {
    final tracks = [
      ...widget.favoritesController.resolveTracks(
        widget.libraryController.tracks,
      ),
    ];
    tracks.sort((a, b) {
      final result = a.title.toLowerCase().compareTo(b.title.toLowerCase());
      return (_tabSortAscending[4] ?? true) ? result : -result;
    });
    return tracks;
  }

  bool get _activeSortAscending =>
      _filter == 0 ? _sortAscending : _tabSortAscending[_filter] ?? true;

  void _reverseActiveSort() => setState(() {
    if (_filter == 0) {
      _sortAscending = !_sortAscending;
    } else {
      _tabSortAscending[_filter] = !(_tabSortAscending[_filter] ?? true);
    }
  });

  void _openCollection(_TrackCollection collection, {required bool artist}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AlbumPage(
          album: collection.title,
          artist: artist ? 'Artist collection' : collection.subtitle,
          tracks: collection.tracks,
          controller: widget.controller,
          pageLabel: artist ? 'ARTIST / ARCHIVE' : 'ALBUM / VIRTUAL TAPE',
          onShowNowPlaying: widget.onPlay,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const RetroHeader(),
    body: ListenableBuilder(
      listenable: Listenable.merge([
        widget.controller.trackStateChanges,
        widget.libraryController,
        widget.recentController,
        widget.favoritesController,
      ]),
      builder: (context, _) => CustomScrollView(
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: _LibraryControlsDelegate(
              selectedFilter: _filter,
              filters: filters,
              onFilterChanged: (index) => setState(() => _filter = index),
              onRescan: _rescanLibrary,
              onSearch: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => SearchPage(
                    controller: widget.controller,
                    libraryController: widget.libraryController,
                    historyController: widget.searchHistoryController,
                    onShowNowPlaying: widget.onPlay,
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            sliver: SliverList.list(
              children: [
                RetroPanel(
                  color: const Color(0xFF232B2B),
                  child: Row(
                    children: [
                      if (widget.controller.state.currentTrack != null)
                        TrackArtwork(
                          track: widget.controller.state.currentTrack!,
                          size: 56,
                        )
                      else
                        const SizedBox.square(
                          dimension: 56,
                          child: ColoredBox(
                            color: AppColors.black,
                            child: Icon(Icons.album, color: AppColors.amber),
                          ),
                        ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'DECK A  ●',
                              style: TextStyle(
                                color: AppColors.amber,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              widget.controller.state.currentTrack?.title ??
                                  'NO TAPE LOADED',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.amber,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              widget.controller.state.currentTrack == null
                                  ? 'Select a local track to begin'
                                  : '${widget.controller.state.currentTrack!.artist} • ${widget.controller.state.currentTrack!.album ?? 'Unknown album'}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.textWarm,
                                fontFamily: 'sans-serif',
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton.filled(
                        onPressed: widget.controller.state.currentTrack == null
                            ? null
                            : widget.controller.togglePlayback,
                        icon: Icon(
                          widget.controller.state.isPlaying
                              ? Icons.pause
                              : Icons.play_arrow,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          switch (_filter) {
                            1 => 'ALBUM ARCHIVE',
                            2 => 'ARTIST ARCHIVE',
                            3 => 'RECENT TAPES',
                            4 => 'FAVORITE TAPES',
                            _ => 'MAGNETIC TAPES',
                          },
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.panelHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${switch (_filter) {
                          3 => _recentTracks.length,
                          4 => _favoriteTracks.length,
                          _ => widget.libraryController.tracks.length,
                        }} LOADED',
                        style: const TextStyle(fontSize: 9),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _CompactSortControl(
                      label: switch (_filter) {
                        1 => 'ALBUM',
                        2 => 'ARTIST',
                        3 => 'PLAYED',
                        4 => 'TITLE',
                        _ => _sort.shortLabel,
                      },
                      ascending: _activeSortAscending,
                      onSort: _filter == 0 ? _chooseSort : null,
                      onReverse: _reverseActiveSort,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (widget.libraryController.status != LibraryStatus.ready)
                  _LibraryStatePanel(controller: widget.libraryController),
                if (widget.libraryController.status == LibraryStatus.ready &&
                    (_filter == 3 || _filter == 4) &&
                    (_filter == 3 ? _recentTracks : _favoriteTracks)
                        .isNotEmpty) ...[
                  _TrackSetControls(
                    showClear: _filter == 3,
                    onPlay: () => _playTrackSet(
                      _filter == 3 ? _recentTracks : _favoriteTracks,
                      shuffle: false,
                    ),
                    onShuffle: () => _playTrackSet(
                      _filter == 3 ? _recentTracks : _favoriteTracks,
                      shuffle: true,
                    ),
                    onClear: _confirmClearRecent,
                  ),
                  const SizedBox(height: 10),
                ],
                if (widget.libraryController.status == LibraryStatus.ready &&
                    _filter == 0)
                  ..._sortedTracks.map(
                    (track) => Padding(
                      padding: const EdgeInsets.only(bottom: 7),
                      child: _TrackRow(
                        track: track,
                        active: widget.controller.state.currentTrack == track,
                        onTap: () => _play(track),
                        onMenu: () => _showTrackActions(track),
                        onAlbum: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => AlbumPage(
                              album: track.album ?? 'Album',
                              artist: track.artist,
                              tracks: widget.libraryController.tracks
                                  .where(
                                    (candidate) =>
                                        candidate.album == track.album &&
                                        candidate.artist == track.artist,
                                  )
                                  .toList(growable: false),
                              controller: widget.controller,
                              onShowNowPlaying: widget.onPlay,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (widget.libraryController.status == LibraryStatus.ready &&
                    _filter == 3 &&
                    _recentTracks.isEmpty)
                  const RetroPanel(
                    padding: EdgeInsets.all(28),
                    child: Column(
                      children: [
                        Icon(Icons.history, size: 42, color: AppColors.outline),
                        SizedBox(height: 12),
                        Text('NO PLAY HISTORY'),
                        SizedBox(height: 5),
                        Text(
                          'Tracks you play will appear here.',
                          style: TextStyle(
                            color: AppColors.textWarm,
                            fontFamily: 'sans-serif',
                          ),
                        ),
                      ],
                    ),
                  ),
                if (widget.libraryController.status == LibraryStatus.ready &&
                    _filter == 3)
                  ..._recentTracks.map(
                    (track) => Padding(
                      padding: const EdgeInsets.only(bottom: 7),
                      child: _TrackRow(
                        track: track,
                        active: widget.controller.state.currentTrack == track,
                        onTap: () => _playRecent(track),
                        onMenu: () => _showTrackActions(track),
                        onAlbum: () => _openTrackAlbum(track),
                      ),
                    ),
                  ),
                if (widget.libraryController.status == LibraryStatus.ready &&
                    _filter == 1)
                  ..._collectionsByAlbum(widget.libraryController.tracks).map(
                    (collection) => _CollectionRow(
                      collection: collection,
                      icon: Icons.album,
                      onTap: () => _openCollection(collection, artist: false),
                    ),
                  ),
                if (widget.libraryController.status == LibraryStatus.ready &&
                    _filter == 4 &&
                    _favoriteTracks.isEmpty)
                  const RetroPanel(
                    padding: EdgeInsets.all(28),
                    child: Column(
                      children: [
                        Icon(
                          Icons.favorite_border,
                          size: 42,
                          color: AppColors.outline,
                        ),
                        SizedBox(height: 12),
                        Text('NO FAVORITE TAPES'),
                        SizedBox(height: 5),
                        Text(
                          'Tap the heart on Now Playing to save a track.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textWarm,
                            fontFamily: 'sans-serif',
                          ),
                        ),
                      ],
                    ),
                  ),
                if (widget.libraryController.status == LibraryStatus.ready &&
                    _filter == 4)
                  ..._favoriteTracks.map(
                    (track) => Padding(
                      padding: const EdgeInsets.only(bottom: 7),
                      child: _TrackRow(
                        track: track,
                        active: widget.controller.state.currentTrack == track,
                        onTap: () => _playFavorite(track),
                        onMenu: () => _showTrackActions(track),
                        onAlbum: () => _openTrackAlbum(track),
                      ),
                    ),
                  ),
                if (widget.libraryController.status == LibraryStatus.ready &&
                    _filter == 2)
                  ..._collectionsByArtist(widget.libraryController.tracks).map(
                    (collection) => _CollectionRow(
                      collection: collection,
                      icon: Icons.person_outline,
                      onTap: () => _openCollection(collection, artist: true),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

enum _LibrarySort {
  trackNumber('TRACK NO.', 'TRACK', Icons.format_list_numbered),
  title('TITLE A–Z', 'TITLE', Icons.sort_by_alpha),
  artist('ARTIST A–Z', 'ARTIST', Icons.person_outline),
  album('ALBUM A–Z', 'ALBUM', Icons.album_outlined),
  duration('DURATION', 'TIME', Icons.timer_outlined);

  const _LibrarySort(this.label, this.shortLabel, this.icon);
  final String label;
  final String shortLabel;
  final IconData icon;
}

class _LibraryControlsDelegate extends SliverPersistentHeaderDelegate {
  const _LibraryControlsDelegate({
    required this.selectedFilter,
    required this.filters,
    required this.onFilterChanged,
    required this.onSearch,
    required this.onRescan,
  });

  final int selectedFilter;
  final List<String> filters;
  final ValueChanged<int> onFilterChanged;
  final VoidCallback onSearch;
  final VoidCallback onRescan;

  @override
  double get minExtent => 116;

  @override
  double get maxExtent => 116;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => DecoratedBox(
    decoration: BoxDecoration(
      color: AppColors.background,
      border: const Border(bottom: BorderSide(color: Color(0x334FDBCC))),
      boxShadow: overlapsContent
          ? const [
              BoxShadow(
                color: Color(0x660D0E11),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ]
          : null,
    ),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: onSearch,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppColors.panelHigh,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.search, color: AppColors.outline),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Search local archive...',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: AppColors.outline),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 7),
              _HeaderControl(
                tooltip: 'Rescan library',
                icon: Icons.sync,
                onTap: onRescan,
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: filters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, index) => _LibraryFilterChip(
                label: Text(filters[index]),
                selected: selectedFilter == index,
                onTap: () => onFilterChanged(index),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  @override
  bool shouldRebuild(_LibraryControlsDelegate oldDelegate) =>
      selectedFilter != oldDelegate.selectedFilter ||
      filters != oldDelegate.filters;
}

class _LibraryFilterChip extends StatelessWidget {
  const _LibraryFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final Widget label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? AppColors.amber : AppColors.panelLow.withAlpha(160),
    borderRadius: BorderRadius.circular(9),
    shadowColor: selected ? AppColors.amber : Colors.transparent,
    elevation: selected ? 4 : 0,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          child: DefaultTextStyle(
            style: TextStyle(
              color: selected ? AppColors.black : AppColors.textWarm,
              fontSize: 10,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              letterSpacing: 1,
            ),
            child: label,
          ),
        ),
      ),
    ),
  );
}

class _HeaderControl extends StatelessWidget {
  const _HeaderControl({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });
  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: Material(
      color: AppColors.panelHigh,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox.square(
          dimension: 50,
          child: Icon(icon, color: AppColors.cyan, size: 21),
        ),
      ),
    ),
  );
}

class _TrackSetControls extends StatelessWidget {
  const _TrackSetControls({
    required this.showClear,
    required this.onPlay,
    required this.onShuffle,
    required this.onClear,
  });
  final bool showClear;
  final VoidCallback onPlay;
  final VoidCallback onShuffle;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => RetroPanel(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    color: const Color(0xFF232B2B),
    child: Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: onPlay,
            icon: const Icon(Icons.play_arrow, size: 18),
            label: const Text('PLAY ALL'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onShuffle,
            icon: const Icon(Icons.shuffle, size: 16),
            label: const Text('MIX'),
          ),
        ),
        if (showClear) ...[
          const SizedBox(width: 5),
          IconButton(
            tooltip: 'Clear recent history',
            onPressed: onClear,
            icon: const Icon(
              Icons.delete_sweep_outlined,
              color: AppColors.coral,
            ),
          ),
        ],
      ],
    ),
  );
}

class _CompactSortControl extends StatelessWidget {
  const _CompactSortControl({
    required this.label,
    required this.ascending,
    this.onSort,
    required this.onReverse,
  });

  final String label;
  final bool ascending;
  final VoidCallback? onSort;
  final VoidCallback onReverse;

  @override
  Widget build(BuildContext context) => Container(
    height: 30,
    decoration: BoxDecoration(
      color: AppColors.black,
      borderRadius: BorderRadius.circular(5),
      border: Border.all(color: AppColors.outlineDark),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: onSort == null
              ? 'Fixed sort mode for this tab'
              : 'Choose sort mode',
          child: InkWell(
            onTap: onSort,
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(4),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  const Icon(Icons.sort, size: 14, color: AppColors.cyan),
                  const SizedBox(width: 5),
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.amberSoft,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: .5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const VerticalDivider(width: 1, color: Color(0x66544434)),
        Tooltip(
          message: ascending ? 'Ascending' : 'Descending',
          child: InkWell(
            onTap: onReverse,
            borderRadius: const BorderRadius.horizontal(
              right: Radius.circular(4),
            ),
            child: SizedBox(
              width: 29,
              height: 30,
              child: Icon(
                ascending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 15,
                color: ascending ? AppColors.cyan : AppColors.amber,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _TrackRow extends StatelessWidget {
  const _TrackRow({
    required this.track,
    required this.active,
    required this.onTap,
    required this.onAlbum,
    required this.onMenu,
  });
  final Track track;
  final bool active;
  final VoidCallback onTap;
  final VoidCallback onAlbum;
  final VoidCallback onMenu;
  String get time =>
      '${track.duration.inMinutes.toString().padLeft(2, '0')}:${(track.duration.inSeconds % 60).toString().padLeft(2, '0')}';
  @override
  Widget build(BuildContext context) => RetroPanel(
    onTap: onTap,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    color: active ? const Color(0xFF292D2D) : AppColors.panel,
    child: Row(
      children: [
        Container(
          width: 4,
          height: 42,
          decoration: BoxDecoration(
            color: active ? AppColors.amber : Colors.transparent,
            boxShadow: active
                ? const [BoxShadow(color: AppColors.amber, blurRadius: 8)]
                : null,
          ),
        ),
        const SizedBox(width: 12),
        TrackArtwork(track: track, size: 42),
        const SizedBox(width: 18),
        Expanded(
          child: GestureDetector(
            onLongPress: onAlbum,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  track.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'sans-serif',
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: active ? AppColors.amber : AppColors.text,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  track.artist,
                  style: const TextStyle(
                    fontFamily: 'sans-serif',
                    color: AppColors.textWarm,
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
          color: AppColors.black,
          child: Text(
            track.tapeProfile.typeLabel,
            style: TextStyle(
              color: track.tapeProfile == TapeProfile.typeI
                  ? AppColors.textWarm
                  : AppColors.cyan,
              fontSize: 8,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          time,
          style: const TextStyle(color: AppColors.textWarm, fontSize: 11),
        ),
        IconButton(
          tooltip: 'Track actions',
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints.tightFor(width: 32, height: 32),
          padding: EdgeInsets.zero,
          onPressed: onMenu,
          icon: const Icon(Icons.more_vert, color: AppColors.cyan, size: 19),
        ),
      ],
    ),
  );
}

final class _TrackCollection {
  const _TrackCollection({
    required this.title,
    required this.subtitle,
    required this.tracks,
  });

  final String title;
  final String subtitle;
  final List<Track> tracks;
}

class _CollectionRow extends StatelessWidget {
  const _CollectionRow({
    required this.collection,
    required this.icon,
    required this.onTap,
  });

  final _TrackCollection collection;
  final IconData icon;
  final VoidCallback onTap;

  String get totalTime {
    final duration = collection.tracks.fold(
      Duration.zero,
      (total, track) => total + track.duration,
    );
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return hours > 0 ? '${hours}h ${minutes}m' : '${duration.inMinutes} min';
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: RetroPanel(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        children: [
          Stack(
            children: [
              TrackArtwork(track: collection.tracks.first, size: 54),
              Positioned(
                right: 2,
                bottom: 2,
                child: Icon(icon, size: 15, color: AppColors.amber),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  collection.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'sans-serif',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  collection.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textWarm,
                    fontFamily: 'sans-serif',
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${collection.tracks.length} TRACKS • $totalTime',
                  style: const TextStyle(color: AppColors.outline, fontSize: 9),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.cyan),
        ],
      ),
    ),
  );
}

class _LibraryStatePanel extends StatelessWidget {
  const _LibraryStatePanel({required this.controller});
  final LibraryController controller;

  @override
  Widget build(BuildContext context) {
    final (icon, title, message) = switch (controller.status) {
      LibraryStatus.loading => (
        Icons.sync,
        'SCANNING TAPES',
        'Đang đọc thư viện nhạc trên thiết bị...',
      ),
      LibraryStatus.permissionDenied => (
        Icons.folder_off_outlined,
        'AUDIO ACCESS REQUIRED',
        'Cho phép Tape 88 đọc các file nhạc trên thiết bị.',
      ),
      LibraryStatus.empty => (
        Icons.library_music_outlined,
        'NO TAPES FOUND',
        'Hãy chép bài hát dài ít nhất 30 giây vào Music hoặc Download/Music rồi quét lại.',
      ),
      LibraryStatus.error => (
        Icons.error_outline,
        'DECK ERROR',
        controller.errorMessage ?? 'Không thể đọc thư viện nhạc.',
      ),
      LibraryStatus.ready => (Icons.album, '', ''),
    };
    return RetroPanel(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          if (controller.status == LibraryStatus.loading)
            const CircularProgressIndicator(color: AppColors.amber)
          else
            Icon(icon, size: 38, color: AppColors.amber),
          const SizedBox(height: 14),
          Text(title, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textWarm,
              fontFamily: 'sans-serif',
            ),
          ),
          if (controller.status != LibraryStatus.loading) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: controller.status == LibraryStatus.permissionDenied
                  ? controller.requestPermission
                  : controller.refresh,
              icon: Icon(
                controller.status == LibraryStatus.permissionDenied
                    ? Icons.lock_open
                    : Icons.refresh,
              ),
              label: Text(
                controller.status == LibraryStatus.permissionDenied
                    ? 'ALLOW ACCESS'
                    : 'SCAN AGAIN',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

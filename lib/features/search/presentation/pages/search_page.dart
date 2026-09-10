import 'package:flutter/material.dart';
import 'package:tape_88/core/theme/app_colors.dart';
import 'package:tape_88/core/widgets/retro_panel.dart';
import 'package:tape_88/features/albums/presentation/pages/album_page.dart';
import 'package:tape_88/features/library/domain/entities/track.dart';
import 'package:tape_88/features/library/presentation/controllers/library_controller.dart';
import 'package:tape_88/features/library/presentation/widgets/track_artwork.dart';
import 'package:tape_88/features/player/presentation/controllers/player_controller.dart';
import 'package:tape_88/features/player/presentation/widgets/mini_player.dart';
import 'package:tape_88/features/search/presentation/controllers/search_history_controller.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({
    required this.controller,
    required this.libraryController,
    required this.onShowNowPlaying,
    required this.historyController,
    super.key,
  });
  final PlayerController controller;
  final LibraryController libraryController;
  final VoidCallback onShowNowPlaying;
  final SearchHistoryController historyController;
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  String query = '';

  String get _normalizedQuery => query.trim().toLowerCase();

  List<Track> get songMatches {
    if (_normalizedQuery.isEmpty) return const [];
    return widget.libraryController.tracks
        .where((track) => track.title.toLowerCase().contains(_normalizedQuery))
        .toList(growable: false);
  }

  List<_SearchCollection> get albumMatches {
    if (_normalizedQuery.isEmpty) return const [];
    final groups = <String, List<Track>>{};
    for (final track in widget.libraryController.tracks) {
      final album = track.album ?? 'Unknown album';
      if (!album.toLowerCase().contains(_normalizedQuery)) continue;
      groups.putIfAbsent('$album\u0000${track.artist}', () => []).add(track);
    }
    return groups.entries
        .map((entry) {
          final separator = entry.key.indexOf('\u0000');
          return _SearchCollection(
            title: entry.key.substring(0, separator),
            subtitle: entry.key.substring(separator + 1),
            tracks: entry.value,
          );
        })
        .toList(growable: false);
  }

  List<_SearchCollection> get artistMatches {
    if (_normalizedQuery.isEmpty) return const [];
    final groups = <String, List<Track>>{};
    for (final track in widget.libraryController.tracks) {
      if (!track.artist.toLowerCase().contains(_normalizedQuery)) continue;
      groups.putIfAbsent(track.artist, () => []).add(track);
    }
    return groups.entries
        .map(
          (entry) => _SearchCollection(
            title: entry.key,
            subtitle: '${entry.value.length} TRACKS',
            tracks: entry.value,
          ),
        )
        .toList(growable: false);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _play(Track track) async {
    await widget.historyController.record(query);
    final tracks = widget.libraryController.tracks;
    await widget.controller.loadQueue(
      tracks,
      initialIndex: tracks.indexOf(track),
    );
    await widget.controller.play();
    _searchFocus.unfocus();
  }

  Future<void> _openCollection(
    _SearchCollection collection, {
    required bool artist,
  }) async {
    await widget.historyController.record(query);
    if (!mounted) return;
    _searchFocus.unfocus();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AlbumPage(
          album: collection.title,
          artist: artist ? 'Artist collection' : collection.subtitle,
          controller: widget.controller,
          tracks: collection.tracks,
          pageLabel: artist ? 'ARTIST / ARCHIVE' : 'ALBUM / VIRTUAL TAPE',
          onShowNowPlaying: () {
            Navigator.pop(context);
            widget.onShowNowPlaying();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SEARCH TERMINAL')),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 8),
        child: MiniPlayer(
          controller: widget.controller,
          onOpen: () {
            Navigator.pop(context);
            widget.onShowNowPlaying();
          },
        ),
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([
          widget.controller,
          widget.libraryController,
          widget.historyController,
        ]),
        builder: (context, _) {
          final songs = songMatches;
          final albums = albumMatches;
          final artists = artistMatches;
          final resultCount = songs.length + albums.length + artists.length;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  focusNode: _searchFocus,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (value) {
                    widget.historyController.record(value);
                    _searchFocus.unfocus();
                  },
                  onChanged: (value) => setState(() => query = value),
                  style: const TextStyle(color: AppColors.cyan),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.chevron_right,
                      color: AppColors.amber,
                    ),
                    suffixIcon: query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            onPressed: () {
                              _searchController.clear();
                              setState(() => query = '');
                              _searchFocus.requestFocus();
                            },
                            icon: const Icon(Icons.close),
                          ),
                    hintText: 'SONG / ALBUM / ARTIST_',
                    filled: true,
                    fillColor: AppColors.black,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      '${resultCount.toString().padLeft(2, '0')} SIGNALS FOUND',
                      style: const TextStyle(
                        color: AppColors.amber,
                        fontSize: 11,
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      'LOCAL INDEX',
                      style: TextStyle(color: AppColors.cyan, fontSize: 9),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: _normalizedQuery.isEmpty
                      ? _RecentSearches(
                          queries: widget.historyController.queries,
                          onSelected: (value) {
                            _searchController.text = value;
                            _searchController.selection =
                                TextSelection.collapsed(offset: value.length);
                            setState(() => query = value);
                          },
                          onRemove: widget.historyController.remove,
                          onClear: widget.historyController.clear,
                        )
                      : resultCount == 0
                      ? const _SearchMessage(
                          icon: Icons.signal_cellular_off,
                          title: 'NO SIGNAL / NO MATCHES',
                          message: 'Try a different song, album or artist.',
                        )
                      : ListView(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          children: [
                            if (songs.isNotEmpty) ...[
                              _SectionLabel(
                                label: 'SONGS',
                                count: songs.length,
                              ),
                              ...songs.map(
                                (track) => _SongResult(
                                  track: track,
                                  query: query.trim(),
                                  active:
                                      widget.controller.state.currentTrack ==
                                      track,
                                  playing:
                                      widget.controller.state.currentTrack ==
                                          track &&
                                      widget.controller.state.isPlaying,
                                  onTap: () => _play(track),
                                ),
                              ),
                            ],
                            if (albums.isNotEmpty) ...[
                              _SectionLabel(
                                label: 'ALBUMS',
                                count: albums.length,
                              ),
                              ...albums.map(
                                (album) => _CollectionResult(
                                  collection: album,
                                  query: query.trim(),
                                  icon: Icons.album,
                                  onTap: () =>
                                      _openCollection(album, artist: false),
                                ),
                              ),
                            ],
                            if (artists.isNotEmpty) ...[
                              _SectionLabel(
                                label: 'ARTISTS',
                                count: artists.length,
                              ),
                              ...artists.map(
                                (artist) => _CollectionResult(
                                  collection: artist,
                                  query: query.trim(),
                                  icon: Icons.person_outline,
                                  onTap: () =>
                                      _openCollection(artist, artist: true),
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                          ],
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SearchCollection {
  const _SearchCollection({
    required this.title,
    required this.subtitle,
    required this.tracks,
  });

  final String title;
  final String subtitle;
  final List<Track> tracks;
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.count});
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(2, 14, 2, 8),
    child: Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.amber,
            fontWeight: FontWeight.bold,
            fontSize: 11,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Divider(color: AppColors.outlineDark)),
        const SizedBox(width: 8),
        Text('$count', style: const TextStyle(color: AppColors.outline)),
      ],
    ),
  );
}

class _SongResult extends StatelessWidget {
  const _SongResult({
    required this.track,
    required this.query,
    required this.active,
    required this.playing,
    required this.onTap,
  });
  final Track track;
  final String query;
  final bool active;
  final bool playing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: RetroPanel(
      onTap: onTap,
      padding: const EdgeInsets.all(11),
      color: active ? const Color(0xFF292D2D) : AppColors.panel,
      child: Row(
        children: [
          TrackArtwork(track: track, size: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HighlightedText(
                  text: track.title,
                  query: query,
                  active: active,
                ),
                Text(
                  '${track.artist} • ${track.album ?? 'Unknown album'}',
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
          Icon(
            playing ? Icons.graphic_eq : Icons.play_arrow,
            color: active ? AppColors.amber : AppColors.cyan,
          ),
        ],
      ),
    ),
  );
}

class _CollectionResult extends StatelessWidget {
  const _CollectionResult({
    required this.collection,
    required this.query,
    required this.icon,
    required this.onTap,
  });
  final _SearchCollection collection;
  final String query;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: RetroPanel(
      onTap: onTap,
      padding: const EdgeInsets.all(11),
      child: Row(
        children: [
          Stack(
            children: [
              TrackArtwork(track: collection.tracks.first, size: 48),
              Positioned(
                right: 2,
                bottom: 2,
                child: Icon(icon, size: 15, color: AppColors.amber),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HighlightedText(text: collection.title, query: query),
                Text(
                  collection.subtitle,
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
          const Icon(Icons.chevron_right, color: AppColors.cyan),
        ],
      ),
    ),
  );
}

class _HighlightedText extends StatelessWidget {
  const _HighlightedText({
    required this.text,
    required this.query,
    this.active = false,
  });
  final String text;
  final String query;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final index = text.toLowerCase().indexOf(query.toLowerCase());
    final normal = TextStyle(
      color: active ? AppColors.amber : AppColors.text,
      fontFamily: 'sans-serif',
      fontSize: 16,
      fontWeight: FontWeight.w700,
    );
    if (query.isEmpty || index < 0) {
      return Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: normal,
      );
    }
    return Text.rich(
      TextSpan(
        style: normal,
        children: [
          TextSpan(text: text.substring(0, index)),
          TextSpan(
            text: text.substring(index, index + query.length),
            style: const TextStyle(
              color: AppColors.black,
              backgroundColor: AppColors.amber,
            ),
          ),
          TextSpan(text: text.substring(index + query.length)),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _RecentSearches extends StatelessWidget {
  const _RecentSearches({
    required this.queries,
    required this.onSelected,
    required this.onRemove,
    required this.onClear,
  });
  final List<String> queries;
  final ValueChanged<String> onSelected;
  final ValueChanged<String> onRemove;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    if (queries.isEmpty) {
      return const _SearchMessage(
        icon: Icons.radar,
        title: 'AWAITING INPUT',
        message: 'Search your local tape archive.',
      );
    }
    return ListView(
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'RECENT COMMANDS',
                style: TextStyle(color: AppColors.amber, fontSize: 10),
              ),
            ),
            TextButton(onPressed: onClear, child: const Text('CLEAR ALL')),
          ],
        ),
        ...queries.map(
          (query) => Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: RetroPanel(
              onTap: () => onSelected(query),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.chevron_right, color: AppColors.cyan),
                  const SizedBox(width: 7),
                  Expanded(child: Text(query)),
                  IconButton(
                    tooltip: 'Remove search',
                    onPressed: () => onRemove(query),
                    icon: const Icon(
                      Icons.close,
                      size: 17,
                      color: AppColors.outline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchMessage extends StatelessWidget {
  const _SearchMessage({
    required this.icon,
    required this.title,
    required this.message,
  });
  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 46, color: AppColors.outline),
        const SizedBox(height: 12),
        Text(title, style: const TextStyle(color: AppColors.amber)),
        const SizedBox(height: 5),
        Text(message, style: const TextStyle(color: AppColors.outline)),
      ],
    ),
  );
}

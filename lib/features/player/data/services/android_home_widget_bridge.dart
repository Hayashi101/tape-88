import 'dart:io';

import 'package:flutter/services.dart';
import 'package:tape_88/features/player/domain/entities/playback_state.dart';

/// Sends coarse playback state to the Android 4×2 home-screen widget.
///
final class AndroidHomeWidgetBridge {
  static const _channel = MethodChannel('tape_88/home_widget');
  static const _artworkChannel = MethodChannel('tape_88/media_library');
  static const _progressInterval = Duration(seconds: 5);

  String? _lastSignature;
  final Map<String, Future<Uint8List?>> _artworkCache = {};

  Future<void> synchronize(PlaybackState state) async {
    if (!Platform.isAndroid) return;
    final track = state.currentTrack;
    final progressBucket = state.isPlaying
        ? state.position.inMilliseconds ~/ _progressInterval.inMilliseconds
        : state.position.inMilliseconds;
    final signature =
        '${track?.id}|${track?.source}|${state.isPlaying}|$progressBucket';
    if (_lastSignature == signature) return;
    _lastSignature = signature;

    try {
      final artwork = track == null
          ? null
          : await _artworkCache.putIfAbsent(track.source, () async {
              try {
                return await _artworkChannel.invokeMethod<Uint8List>(
                  'loadArtwork',
                  {'source': track.source, 'trackId': track.id},
                );
              } on PlatformException {
                return null;
              }
            });
      if (_lastSignature != signature) return;
      await _channel.invokeMethod<void>('updatePlayback', {
        'title': track?.title,
        'artist': track?.artist,
        'hasTrack': track != null,
        'isPlaying': state.isPlaying,
        'positionMs': state.position.inMilliseconds,
        'durationMs': track?.duration.inMilliseconds ?? 0,
        'artwork': artwork,
      });
    } on PlatformException {
      // The widget is an optional Android surface; playback must never fail if
      // a launcher or platform channel cannot accept an update.
    } on MissingPluginException {
      // Native changes require a full restart, but the player remains usable.
    }
  }
}

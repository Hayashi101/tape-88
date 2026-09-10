import 'dart:io';

import 'package:flutter/services.dart';
import 'package:tape_88/features/library/domain/entities/track.dart';

final class AndroidMediaLibrary {
  static const _channel = MethodChannel('tape_88/media_library');
  static const _channelReadyDelay = Duration(milliseconds: 120);
  static const _channelReadyAttempts = 5;

  Future<T?> _invoke<T>(
    String method, [
    Map<String, Object?>? arguments,
  ]) async {
    for (var attempt = 0; attempt < _channelReadyAttempts; attempt++) {
      try {
        return await _channel.invokeMethod<T>(method, arguments);
      } on MissingPluginException {
        if (attempt == _channelReadyAttempts - 1) rethrow;
        await Future<void>.delayed(_channelReadyDelay);
      }
    }
    return null;
  }

  Future<bool> hasPermission() async =>
      !Platform.isAndroid || await _invoke<bool>('hasPermission') == true;

  Future<bool> requestPermission() async =>
      !Platform.isAndroid || await _invoke<bool>('requestPermission') == true;

  Future<List<Track>> queryTracks() async {
    if (!Platform.isAndroid) return const [];
    final rows = await _invoke<List<dynamic>>('queryTracks') ?? const [];
    return rows.indexed
        .map((entry) {
          final row = Map<String, dynamic>.from(entry.$2 as Map);
          String clean(String? value, String fallback) {
            if (value == null || value.trim().isEmpty || value == '<unknown>') {
              return fallback;
            }
            return value.trim();
          }

          return Track(
            id: row['id'] as String,
            title: clean(row['title'] as String?, 'Unknown title'),
            artist: clean(row['artist'] as String?, 'Unknown artist'),
            album: clean(row['album'] as String?, 'Unknown album'),
            source: row['source'] as String,
            duration: Duration(
              milliseconds: (row['durationMs'] as num).toInt(),
            ),
            artworkUri: row['artworkUri'] == null
                ? null
                : Uri.tryParse(row['artworkUri'] as String),
            mimeType: row['mimeType'] as String?,
            trackNumber: row['trackNumber'] as int?,
            bitrate: row['bitrate'] as int?,
          );
        })
        .toList(growable: false);
  }
}

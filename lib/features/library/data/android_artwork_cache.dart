import 'dart:io';

import 'package:flutter/services.dart';
import 'package:tape_88/features/library/domain/entities/track.dart';

final class AndroidArtworkCache {
  static const _channel = MethodChannel('tape_88/media_library');
  final Map<String, Future<Uri?>> _cache = {};

  Future<Uri?> artUriFor(Track track) =>
      _cache.putIfAbsent(track.id, () => _cacheArtwork(track));

  Future<Uri?> _cacheArtwork(Track track) async {
    if (!Platform.isAndroid) return track.artworkUri;
    try {
      final path = await _channel.invokeMethod<String>('cacheArtwork', {
        'source': track.source,
        'trackId': track.id,
      });
      return path == null ? track.artworkUri : Uri.file(path);
    } on PlatformException {
      return track.artworkUri;
    }
  }
}

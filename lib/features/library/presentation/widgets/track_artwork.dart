import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tape_88/core/theme/app_colors.dart';
import 'package:tape_88/features/library/domain/entities/track.dart';

class TrackArtwork extends StatelessWidget {
  const TrackArtwork({
    required this.track,
    this.size = 48,
    this.borderRadius = 5,
    super.key,
  });

  final Track track;
  final double size;
  final double borderRadius;

  static const _channel = MethodChannel('tape_88/media_library');
  static final Map<String, Future<Uint8List?>> _cache = {};

  Future<Uint8List?> _load() => _cache.putIfAbsent(track.source, () async {
    if (!Platform.isAndroid) return null;
    try {
      return await _channel.invokeMethod<Uint8List>('loadArtwork', {
        'source': track.source,
        'trackId': track.id,
      });
    } on PlatformException {
      return null;
    }
  });

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(borderRadius),
    child: SizedBox.square(
      dimension: size,
      child: FutureBuilder<Uint8List?>(
        future: _load(),
        builder: (context, snapshot) {
          final bytes = snapshot.data;
          if (bytes != null && bytes.isNotEmpty) {
            return Image.memory(
              bytes,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              cacheWidth: 128,
              cacheHeight: 128,
              filterQuality: FilterQuality.low,
            );
          }
          return const ColoredBox(
            color: AppColors.black,
            child: Icon(Icons.album, color: AppColors.amber),
          );
        },
      ),
    ),
  );
}

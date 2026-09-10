import 'package:tape_88/features/library/domain/entities/track.dart';

enum TapeProfile {
  typeI,
  typeII;

  String get typeLabel => switch (this) {
    typeI => 'TYPE I',
    typeII => 'TYPE II',
  };

  String get equalizationLabel => switch (this) {
    typeI => 'NORMAL • EQ 120µs',
    typeII => 'HIGH BIAS • EQ 70µs',
  };

  String get fullLabel => '$typeLabel  •  $equalizationLabel';
}

extension TrackTapeProfile on Track {
  /// A deterministic visual profile for the virtual cassette UI.
  /// Digital audio files do not contain real cassette type/bias metadata.
  TapeProfile get tapeProfile {
    final mime = mimeType?.toLowerCase() ?? '';
    const losslessMarkers = ['flac', 'wav', 'wave', 'alac', 'aiff', 'ape'];
    final lossless = losslessMarkers.any(mime.contains);
    final highBitrate = (bitrate ?? 0) >= 256000;
    return lossless || highBitrate ? TapeProfile.typeII : TapeProfile.typeI;
  }

  String get sourceQualityLabel {
    final mime = mimeType?.toLowerCase() ?? '';
    const losslessMarkers = ['flac', 'wav', 'wave', 'alac', 'aiff', 'ape'];
    if (losslessMarkers.any(mime.contains)) return 'LOSSLESS SOURCE';
    final kbps = bitrate == null || bitrate! <= 0 ? null : bitrate! ~/ 1000;
    return kbps == null ? 'QUALITY UNKNOWN' : '$kbps KBPS SOURCE';
  }
}

import 'package:tape_88/features/library/domain/entities/track.dart';
import 'package:tape_88/features/player/domain/entities/playback_state.dart';

class PlaybackSession {
  const PlaybackSession({
    required this.queue,
    required this.currentIndex,
    required this.position,
    required this.repeatMode,
    required this.shuffleEnabled,
  });

  final List<Track> queue;
  final int currentIndex;
  final Duration position;
  final RepeatMode repeatMode;
  final bool shuffleEnabled;

  Map<String, Object> toJson() => {
    'queue': queue.map((track) => track.toJson()).toList(),
    'currentIndex': currentIndex,
    'positionMs': position.inMilliseconds,
    'repeatMode': repeatMode.name,
    'shuffleEnabled': shuffleEnabled,
  };

  factory PlaybackSession.fromJson(Map<String, dynamic> json) {
    final repeatName = json['repeatMode'] as String?;
    return PlaybackSession(
      queue: (json['queue'] as List<dynamic>? ?? const [])
          .map((item) => Track.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(growable: false),
      currentIndex: (json['currentIndex'] as num?)?.toInt() ?? -1,
      position: Duration(
        milliseconds: (json['positionMs'] as num?)?.toInt() ?? 0,
      ),
      repeatMode: RepeatMode.values.firstWhere(
        (mode) => mode.name == repeatName,
        orElse: () => RepeatMode.off,
      ),
      shuffleEnabled: json['shuffleEnabled'] as bool? ?? false,
    );
  }
}

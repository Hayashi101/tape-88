class PlayHistoryEntry {
  const PlayHistoryEntry({required this.trackId, required this.playedAt});

  final String trackId;
  final DateTime playedAt;

  Map<String, String> toJson() => {
    'trackId': trackId,
    'playedAt': playedAt.toIso8601String(),
  };

  factory PlayHistoryEntry.fromJson(Map<String, dynamic> json) =>
      PlayHistoryEntry(
        trackId: json['trackId'] as String,
        playedAt: DateTime.parse(json['playedAt'] as String),
      );
}

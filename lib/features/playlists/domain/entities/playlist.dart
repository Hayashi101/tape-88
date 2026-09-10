import 'package:flutter/foundation.dart';

@immutable
class Playlist {
  const Playlist({
    required this.id,
    required this.name,
    this.trackIds = const [],
  });

  final String id;
  final String name;
  final List<String> trackIds;

  Playlist copyWith({String? name, List<String>? trackIds}) => Playlist(
    id: id,
    name: name ?? this.name,
    trackIds: trackIds ?? this.trackIds,
  );

  Map<String, Object> toJson() => {
    'id': id,
    'name': name,
    'trackIds': trackIds,
  };

  factory Playlist.fromJson(Map<String, dynamic> json) => Playlist(
    id: json['id'] as String,
    name: json['name'] as String,
    trackIds: List<String>.from(json['trackIds'] as List? ?? const []),
  );
}

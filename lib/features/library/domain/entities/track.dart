import 'package:flutter/foundation.dart';

@immutable
class Track {
  const Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.source,
    required this.duration,
    this.album,
    this.artworkUri,
    this.mimeType,
    this.trackNumber,
    this.bitrate,
  });

  final String id;
  final String title;
  final String artist;
  final String source;
  final Duration duration;
  final String? album;
  final Uri? artworkUri;
  final String? mimeType;
  final int? trackNumber;
  final int? bitrate;

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'artist': artist,
    'source': source,
    'durationMs': duration.inMilliseconds,
    'album': album,
    'artworkUri': artworkUri?.toString(),
    'mimeType': mimeType,
    'trackNumber': trackNumber,
    'bitrate': bitrate,
  };

  factory Track.fromJson(Map<String, dynamic> json) => Track(
    id: json['id'] as String,
    title: json['title'] as String,
    artist: json['artist'] as String,
    source: json['source'] as String,
    duration: Duration(milliseconds: (json['durationMs'] as num).toInt()),
    album: json['album'] as String?,
    artworkUri: json['artworkUri'] == null
        ? null
        : Uri.tryParse(json['artworkUri'] as String),
    mimeType: json['mimeType'] as String?,
    trackNumber: json['trackNumber'] as int?,
    bitrate: json['bitrate'] as int?,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Track && other.id == id;
  @override
  int get hashCode => id.hashCode;
}

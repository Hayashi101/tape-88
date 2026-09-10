import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:tape_88/features/player/domain/entities/playback_session.dart';
import 'package:tape_88/features/player/domain/repositories/playback_session_repository.dart';

final class FilePlaybackSessionRepository implements PlaybackSessionRepository {
  Future<File> get _file async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/playback_session.json');
  }

  @override
  Future<PlaybackSession?> load() async {
    final file = await _file;
    if (!await file.exists()) return null;
    final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    return PlaybackSession.fromJson(json);
  }

  @override
  Future<void> save(PlaybackSession session) async {
    final file = await _file;
    await file.writeAsString(jsonEncode(session.toJson()));
  }

  @override
  Future<void> clear() async {
    final file = await _file;
    if (await file.exists()) await file.delete();
  }
}

final class InMemoryPlaybackSessionRepository
    implements PlaybackSessionRepository {
  PlaybackSession? session;

  @override
  Future<PlaybackSession?> load() async => session;

  @override
  Future<void> save(PlaybackSession value) async => session = value;

  @override
  Future<void> clear() async => session = null;
}

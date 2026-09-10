import 'package:tape_88/core/utils/result.dart';
import 'package:tape_88/features/library/domain/entities/track.dart';

abstract interface class MusicLibraryRepository {
  Future<Result<List<Track>>> getTracks();
  Future<Result<List<Track>>> search(String query);
  Stream<List<Track>> watchFavorites();
  Future<Result<void>> setFavorite(String trackId, {required bool isFavorite});
}

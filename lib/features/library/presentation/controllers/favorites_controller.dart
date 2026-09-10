import 'package:flutter/foundation.dart';
import 'package:tape_88/features/library/domain/entities/track.dart';
import 'package:tape_88/features/library/domain/repositories/favorites_repository.dart';

final class FavoritesController extends ChangeNotifier {
  FavoritesController(this._repository);

  final FavoritesRepository _repository;
  Set<String> trackIds = const {};
  String? errorMessage;

  Future<void> initialize() async {
    try {
      trackIds = await _repository.load();
    } catch (error) {
      errorMessage = error.toString();
    }
    notifyListeners();
  }

  bool contains(Track track) => trackIds.contains(track.id);

  List<Track> resolveTracks(List<Track> library) =>
      library.where(contains).toList(growable: false);

  Future<void> toggle(Track track) async {
    final updated = {...trackIds};
    if (!updated.add(track.id)) updated.remove(track.id);
    trackIds = Set.unmodifiable(updated);
    notifyListeners();
    try {
      await _repository.save(trackIds);
      errorMessage = null;
    } catch (error) {
      errorMessage = error.toString();
      notifyListeners();
    }
  }
}

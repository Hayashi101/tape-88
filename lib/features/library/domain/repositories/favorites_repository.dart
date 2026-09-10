abstract interface class FavoritesRepository {
  Future<Set<String>> load();
  Future<void> save(Set<String> trackIds);
}

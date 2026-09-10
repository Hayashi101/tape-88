abstract interface class SettingsRepository {
  Future<double> loadVolume();
  Future<void> saveVolume(double volume);
  Future<String> loadEqualizerPreset();
  Future<void> saveEqualizerPreset(String preset);
}

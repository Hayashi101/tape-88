import 'package:flutter/foundation.dart';
import 'package:tape_88/features/settings/domain/repositories/settings_repository.dart';

final class SettingsController extends ChangeNotifier {
  SettingsController(this._repository);

  final SettingsRepository _repository;
  double volume = 1;
  String equalizerPreset = 'Flat';
  String? errorMessage;

  Future<void> initialize() async {
    try {
      volume = await _repository.loadVolume();
      equalizerPreset = await _repository.loadEqualizerPreset();
    } catch (error) {
      errorMessage = error.toString();
    }
    notifyListeners();
  }

  Future<void> setEqualizerPreset(String preset) async {
    equalizerPreset = preset;
    notifyListeners();
    try {
      await _repository.saveEqualizerPreset(preset);
      errorMessage = null;
    } catch (error) {
      errorMessage = error.toString();
      notifyListeners();
    }
  }

  Future<void> setVolume(double value) async {
    volume = value.clamp(0, 1);
    notifyListeners();
    try {
      await _repository.saveVolume(volume);
      errorMessage = null;
    } catch (error) {
      errorMessage = error.toString();
      notifyListeners();
    }
  }
}

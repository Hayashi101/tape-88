import 'package:flutter_test/flutter_test.dart';
import 'package:tape_88/features/settings/data/file_settings_repository.dart';
import 'package:tape_88/features/settings/presentation/controllers/settings_controller.dart';

void main() {
  test('persists and restores master volume', () async {
    final repository = InMemorySettingsRepository();
    final controller = SettingsController(repository);
    await controller.initialize();
    await controller.setVolume(.42);
    await controller.setEqualizerPreset('Warm');

    final restored = SettingsController(repository);
    await restored.initialize();
    expect(restored.volume, .42);
    expect(restored.equalizerPreset, 'Warm');
  });
}

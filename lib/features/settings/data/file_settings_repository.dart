import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:tape_88/features/settings/domain/repositories/settings_repository.dart';

final class FileSettingsRepository implements SettingsRepository {
  Future<File> get _file async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/settings.json');
  }

  Future<Map<String, dynamic>> _loadJson() async {
    final file = await _file;
    if (!await file.exists()) return {};
    return jsonDecode(await file.readAsString()) as Map<String, dynamic>;
  }

  Future<void> _saveValue(String key, Object value) async {
    final json = await _loadJson()
      ..[key] = value;
    await (await _file).writeAsString(jsonEncode(json));
  }

  @override
  Future<double> loadVolume() async {
    final json = await _loadJson();
    return ((json['volume'] as num?)?.toDouble() ?? 1).clamp(0, 1);
  }

  @override
  Future<void> saveVolume(double volume) async {
    await _saveValue('volume', volume.clamp(0, 1));
  }

  @override
  Future<String> loadEqualizerPreset() async =>
      (await _loadJson())['equalizerPreset'] as String? ?? 'Flat';

  @override
  Future<void> saveEqualizerPreset(String preset) =>
      _saveValue('equalizerPreset', preset);
}

final class InMemorySettingsRepository implements SettingsRepository {
  double volume = 1;
  String equalizerPreset = 'Flat';

  @override
  Future<double> loadVolume() async => volume;

  @override
  Future<void> saveVolume(double value) async => volume = value.clamp(0, 1);

  @override
  Future<String> loadEqualizerPreset() async => equalizerPreset;

  @override
  Future<void> saveEqualizerPreset(String preset) async {
    equalizerPreset = preset;
  }
}

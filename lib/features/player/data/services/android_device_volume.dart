import 'dart:io';

import 'package:flutter/services.dart';

final class AndroidDeviceVolume {
  static const _methods = MethodChannel('tape_88/device_volume');
  static const _events = EventChannel('tape_88/device_volume_changes');

  bool get isSupported => Platform.isAndroid;

  Stream<double> get changes => isSupported
      ? _events.receiveBroadcastStream().map(
          (value) => (value as num).toDouble().clamp(0, 1),
        )
      : const Stream<double>.empty();

  Future<double> getVolume() async {
    if (!isSupported) return 1;
    final value = await _methods.invokeMethod<num>('getMediaVolume');
    return (value?.toDouble() ?? 1).clamp(0, 1);
  }

  Future<void> setVolume(double value) async {
    if (!isSupported) return;
    await _methods.invokeMethod<void>('setMediaVolume', {
      'volume': value.clamp(0, 1),
    });
  }
}

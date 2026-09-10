import 'package:flutter/foundation.dart';

abstract final class AppLogger {
  static void info(String message) {
    if (kDebugMode) debugPrint('[INFO] $message');
  }

  static void error(String message, {Object? error, StackTrace? stackTrace}) {
    if (!kDebugMode) return;
    debugPrint('[ERROR] $message${error == null ? '' : ': $error'}');
    if (stackTrace != null) debugPrintStack(stackTrace: stackTrace);
  }
}

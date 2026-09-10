sealed class AppException implements Exception {
  const AppException(this.message, {this.cause});
  final String message;
  final Object? cause;
  @override
  String toString() => '$runtimeType: $message';
}

final class CacheException extends AppException {
  const CacheException(super.message, {super.cause});
}

final class PermissionException extends AppException {
  const PermissionException(super.message, {super.cause});
}

final class PlaybackException extends AppException {
  const PlaybackException(super.message, {super.cause});
}

final class UnexpectedException extends AppException {
  const UnexpectedException(super.message, {super.cause});
}

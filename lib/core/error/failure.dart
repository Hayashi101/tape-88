sealed class Failure {
  const Failure(this.message, {this.cause});
  final String message;
  final Object? cause;
}

final class StorageFailure extends Failure {
  const StorageFailure(super.message, {super.cause});
}

final class PermissionFailure extends Failure {
  const PermissionFailure(super.message, {super.cause});
}

final class PlaybackFailure extends Failure {
  const PlaybackFailure(super.message, {super.cause});
}

final class UnexpectedFailure extends Failure {
  const UnexpectedFailure(super.message, {super.cause});
}

import 'package:tape_88/core/error/failure.dart';

sealed class Result<T> {
  const Result();
  R fold<R>({
    required R Function(T) onSuccess,
    required R Function(Failure) onFailure,
  }) => switch (this) {
    Success<T>(value: final value) => onSuccess(value),
    Failed<T>(failure: final failure) => onFailure(failure),
  };
}

final class Success<T> extends Result<T> {
  const Success(this.value);
  final T value;
}

final class Failed<T> extends Result<T> {
  const Failed(this.failure);
  final Failure failure;
}

import 'package:tape_88/core/utils/result.dart';

abstract interface class UseCase<Output, Input> {
  Future<Result<Output>> call(Input input);
}

final class NoParams {
  const NoParams();
}

import 'package:flutter_test/flutter_test.dart';
import 'package:tape_88/core/error/failure.dart';
import 'package:tape_88/core/utils/result.dart';

void main() {
  test('fold maps success and failure values', () {
    const Result<int> success = Success(88);
    const Result<int> failed = Failed(UnexpectedFailure('error'));
    expect(
      success.fold(
        onSuccess: (value) => '$value',
        onFailure: (failure) => failure.message,
      ),
      '88',
    );
    expect(
      failed.fold(
        onSuccess: (value) => '$value',
        onFailure: (failure) => failure.message,
      ),
      'error',
    );
  });
}

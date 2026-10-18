import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/shared/support/held_run.dart';

// A held flow always gets its way out back: a Failure and a bug both reach
// onFailed, the bug reported first (closing acceptance 2026-10-18 LIB-6).

void main() {
  test('a write that lands calls nothing', () async {
    var calls = 0;
    await runHeld(() async {}, onFailed: (_) => calls++);
    expect(calls, 0);
  });

  test('a Failure reaches onFailed as itself and is not reported', () async {
    final reported = <FlutterErrorDetails>[];
    final previous = FlutterError.onError;
    FlutterError.onError = reported.add;
    addTearDown(() => FlutterError.onError = previous);
    Failure? seen;
    var calls = 0;

    await runHeld(
      () async => throw const DatabaseLockedFailure(cause: 'locked'),
      onFailed: (failure) {
        calls++;
        seen = failure;
      },
    );

    expect(calls, 1);
    expect(seen, isA<DatabaseLockedFailure>());
    expect(reported, isEmpty);
  });

  test('a bug is reported, then reaches onFailed as null', () async {
    final reported = <FlutterErrorDetails>[];
    final previous = FlutterError.onError;
    FlutterError.onError = reported.add;
    addTearDown(() => FlutterError.onError = previous);
    final seen = <Failure?>[];

    await runHeld(() async => throw StateError('a bug'), onFailed: seen.add);

    expect(seen, [null]);
    expect(reported.single.exception, isA<StateError>());
  });
}

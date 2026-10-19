import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/shared/support/held_run.dart';

import '../../support/held_bug_capture.dart';

// A held flow always gets its way out back: a Failure and a bug both reach
// onFailed, the bug reported first (closing acceptance 2026-10-18 LIB-6).
// The write's result comes back to the caller, which does what follows a
// landed write outside the held run (REG-HELD-SCOPE).

void main() {
  test('a write that lands returns its result and calls nothing', () async {
    var calls = 0;
    final result = await runHeld(() async => 7, onFailed: (_) => calls++);
    expect(result, 7);
    expect(calls, 0);
  });

  test('a Failure reaches onFailed as itself, is not reported, and returns '
      'null', () async {
    final reported = captureReportedBugs();
    final seen = <Failure?>[];

    final result = await runHeld<int>(
      () async => throw const DatabaseLockedFailure(cause: 'locked'),
      onFailed: seen.add,
    );

    expect(result, isNull);
    expect(seen.single, isA<DatabaseLockedFailure>());
    expect(reported, isEmpty);
  });

  test('a bug is reported, then reaches onFailed as null', () async {
    final reported = captureReportedBugs();
    final seen = <Failure?>[];

    final result = await runHeld<int>(
      () async => throw StateError('a bug'),
      onFailed: seen.add,
    );

    expect(result, isNull);
    expect(seen, [null]);
    expectOneBugReported(reported);
  });
}

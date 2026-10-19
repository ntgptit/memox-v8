import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/topik/di/topik_attempt_repository_provider.dart';
import 'package:memox/features/topik/domain/failures/topik_failure.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_model.dart';
import 'package:memox/features/topik/domain/repositories/topik_attempt_repository.dart';
import 'package:memox/features/topik/domain/models/topik_test_model.dart';
import 'package:memox/features/topik/presentation/controllers/topik_attempt_controller.dart';

import '../../../support/held_bug.dart';
import '../../../support/topik_content_fixtures.dart';
import '../../../support/topik_screen_fixtures.dart';

/// An attempt store whose submit dies on a bug, not a Failure (ADR-016).
final class _BuggyAttempts implements TopikAttemptRepository {
  @override
  Future<Outcome<TopikAttempt, TopikRejection>> submit({
    required String attemptId,
    required TopikTest test,
    required int elapsedMs,
    DateTime? now,
  }) async => throw heldBug();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// LIB-6: screen 37's submit holds the attempt (BR-TOPIK-014). It releases on
// a bug as on a Failure, by its `finally`, so it needs no runHeld: the bug
// itself still reaches the caller.
void main() {
  test('a submit that dies on a bug lets the person go on: the attempt is '
      'not held for good', () async {
    final test0 = topikTestFixture();
    final container = ProviderContainer(
      overrides: [
        ...topikContentOverrides([test0]),
        topikAttemptRepositoryProvider.overrideWithValue(_BuggyAttempts()),
      ],
    );
    addTearDown(container.dispose);
    final provider = topikAttemptControllerProvider('a1');
    container.listen(provider, (_, _) {});
    final controller = container.read(provider.notifier);

    await expectLater(
      controller.submit(test0.testId),
      throwsA(isA<StateError>()),
    );

    expect(container.read(provider), isFalse);
  });
}

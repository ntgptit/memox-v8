import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/starter_decks/domain/failures/starter_failure.dart';
import 'package:memox/features/starter_decks/domain/models/added_starter_deck_model.dart';
import 'package:memox/features/starter_decks/domain/repositories/starter_library_repository.dart';
import 'package:memox/features/starter_decks/domain/usecases/add_starter_deck_use_case.dart';
import 'package:memox/features/starter_decks/presentation/controllers/starter_add_controller.dart';
import 'package:memox/features/starter_decks/presentation/providers/add_starter_deck_use_case_provider.dart';

import '../../../support/held_bug.dart';
import '../../../support/library_harness.dart';
import '../../../support/starter_screen_fixtures.dart';

/// A library whose add dies on a bug, not a Failure (ADR-016).
final class _BuggyLibrary implements StarterLibraryRepository {
  @override
  Future<Outcome<AddedStarterDeck, StarterRejection>> addStarterDeck({
    required String templateId,
    required SchedulerType schedulerType,
    bool allowSecondCopy = false,
    DateTime? now,
  }) async => throw heldBug();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// LIB-6: a held write that meets a bug releases its flow and reports the
// bug (runHeld). The sheet shows the failed banner, as for a Failure.
void main() {
  libraryTest('an add that dies on a bug is no longer adding: the sheet shows '
      'the failed banner and Try again (addFailed)', (tester, env) async {
    final container = libraryContainer(
      env,
      overrides: [
        addStarterDeckUseCaseProvider.overrideWithValue(
          AddStarterDeckUseCase(_BuggyLibrary()),
        ),
      ],
    );
    // The sheet keeps the auto-disposed controller alive.
    container.listen(starterAddControllerProvider, (_, _) {});

    final result = await container
        .read(starterAddControllerProvider.notifier)
        .add(
          templateId: hangulTemplate.templateId,
          schedulerType: SchedulerType.sm2,
          allowSecondCopy: false,
        );

    expect(result, isNull);
    expectBugReported(tester);
    final state = container.read(starterAddControllerProvider);
    expect(state.isAdding, isFalse);
    expect(state.hasFailed, isTrue);
  });
}

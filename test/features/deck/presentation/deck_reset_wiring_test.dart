import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/presentation/controllers/deck_actions_controller.dart';
import 'package:memox/features/deck/presentation/providers/reset_learning_summary_provider.dart';
import 'package:memox/features/srs/domain/failures/srs_failure.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';

void main() {
  libraryTest('the summary counts the tree and what a reset takes', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean', SchedulerType.sm2);
    final words = await env.decks.sub(korean.id, 'Words');
    await insertCard(
      env.db,
      id: 'a',
      deckId: words.id,
      learnedAt: DateTime(2026, 9, 1),
      dueAt: DateTime(2026, 9, 30),
    );
    await insertCard(env.db, id: 'b', deckId: words.id);
    final container = libraryContainer(env);
    final provider = resetLearningSummaryProvider(korean.id);
    // An auto-disposed provider needs a listener while it is awaited.
    container.listen(provider, (_, _) {});

    final outcome = await container.read(provider.future);

    final summary = switch (outcome) {
      Ok(:final value) => value,
      Rejected(:final reason) => fail('refused: $reason'),
    };
    expect(summary.cardCount, 2);
    expect(summary.learnedCardCount, 1);
    expect(summary.schedulerType, SchedulerType.sm2);
    expect(summary.hasProgressToLose, isTrue);
  });

  libraryTest('resetLearning starts a new cycle with the chosen algorithm', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean', SchedulerType.sm2);
    await lockScheduler(env.db, korean.id);
    final container = libraryContainer(env);

    final outcome = await container
        .read(deckActionsControllerProvider.notifier)
        .resetLearning(
          rootDeckId: korean.id,
          schedulerType: SchedulerType.eightBox,
        );

    expect(outcome, isA<Ok<void, SrsRejection>>());
    final root = await env.db
        .customSelect(
          'SELECT generation, scheduler_type, first_answered_at '
          'FROM deck WHERE id = ?',
          variables: [Variable<String>(korean.id)],
        )
        .getSingle();
    expect(root.read<int>('generation'), 2);
    expect(root.read<String>('scheduler_type'), SchedulerType.eightBox.code);
    expect(root.read<DateTime?>('first_answered_at'), isNull);
  });
}

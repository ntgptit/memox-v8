import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/progress/di/progress_repository_provider.dart';
import 'package:memox/features/progress/domain/models/progress_days_model.dart';
import 'package:memox/features/progress/domain/models/progress_level_model.dart';
import 'package:memox/features/progress/domain/models/progress_model.dart';
import 'package:memox/features/progress/domain/repositories/progress_repository.dart';
import 'package:memox/features/progress/presentation/providers/deck_progress_provider.dart';
import 'package:memox/features/progress/presentation/providers/progress_provider.dart';
import 'package:memox/features/progress/presentation/providers/progress_range_provider.dart';

import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';
import '../../../support/progress_fixtures.dart';
import '../../../support/test_database.dart';
import '../../../support/fake_day_clock.dart';

// FE-A9 D3, D4, D8: the two reads of screen 22 and the tab's range.

/// A read that fails the way the database does (Progress spec §6.6).
final class _FailingProgress implements ProgressRepository {
  var reads = 0;

  @override
  Stream<Progress> watchProgress(ProgressDays days) {
    reads++;
    return Stream.error(
      UnknownDatabaseFailure(cause: StateError('read failed')),
    );
  }

  @override
  Stream<DeckProgress> watchDeckProgress({
    required String deckId,
    required ProgressDays days,
  }) => Stream.error(UnknownDatabaseFailure(cause: StateError('read failed')));
}

void main() {
  late LibraryEnv env;

  setUp(() => env = LibraryEnv(openTestDatabase(), FakeDayClock(libraryToday)));
  tearDown(() => env.db.close());

  /// A root deck with one learned card [cardId]; returns the root's id.
  Future<String> deck(String name, String cardId) async {
    final root = await env.decks.root(name);
    await learnedCard(env.db, root.id, cardId);
    await lockScheduler(env.db, root.id);
    return root.id;
  }

  test(
    'a new answer updates the library level; nothing else is read',
    () async {
      await deck('Korean', 'a');
      final container = libraryContainer(env);
      final seen = <Progress>[];
      container.listen(
        progressProvider,
        (_, next) => next.whenData(seen.add),
        fireImmediately: true,
      );
      await pumpEventQueue();
      expect(seen.single.level.total.week.activeCards, 0);

      await answer(env.db, 'a', libraryToday);
      await pumpEventQueue();

      expect(seen.last.level.total.week.activeCards, 1);
      expect(seen.last.overview.today.total, 1);
    },
  );

  test("a deck's level lists its children; a deck that is gone is a value, "
      'not an error (UC-PROGRESS-002 E2)', () async {
    final root = await env.decks.root('Korean');
    await env.decks.sub(root.id, 'Verbs');
    final container = libraryContainer(env);
    container.listen(deckProgressProvider(root.id), (_, _) {});
    container.listen(deckProgressProvider('gone'), (_, _) {});

    final level = await container.read(deckProgressProvider(root.id).future);
    final gone = await container.read(deckProgressProvider('gone').future);

    expect(
      (level as DeckProgressLevel).level
          .decksFor(ProgressRange.week)
          .map((row) => row.name),
      ['Verbs'],
    );
    expect(gone, isA<ProgressDeckMissing>());
  });

  test('a failed read is an error; Retry reads again, once (UC-PROGRESS-001 '
      'E1, E2)', () async {
    final failing = _FailingProgress();
    final container = libraryContainer(
      env,
      overrides: [progressRepositoryProvider.overrideWithValue(failing)],
    );
    container.listen(progressProvider, (_, _) {});
    await pumpEventQueue();
    expect(container.read(progressProvider).hasError, isTrue);

    container.invalidate(progressProvider);
    await pumpEventQueue();

    expect(container.read(progressProvider).hasError, isTrue);
    expect(failing.reads, 2);
  });

  test('the range starts at 7 days and is one choice for every level (D4)', () {
    final container = libraryContainer(env);
    container.listen(progressRangeChoiceProvider, (_, _) {});
    expect(container.read(progressRangeChoiceProvider), ProgressRange.week);

    container
        .read(progressRangeChoiceProvider.notifier)
        .choose(ProgressRange.month);

    expect(container.read(progressRangeChoiceProvider), ProgressRange.month);
  });
}

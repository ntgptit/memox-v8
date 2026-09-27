import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/srs/domain/models/review_action_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/study/domain/usecases/preview_self_assess_intervals_use_case.dart';
import 'package:memox/features/study_mode/domain/models/session_kind_model.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/fake_day_clock.dart';
import '../../../support/test_database.dart';

// FE-A6 D11b, handoff 16a: previews on a scheduled turn only.

void main() {
  late AppDatabase db;
  late PreviewSelfAssessIntervalsUseCase useCase;
  final now = DateTime(2026, 9, 24, 9);
  setUp(() async {
    db = openTestDatabase();
    final decks = DeckRepositoryImpl(db, now: () => now);
    final root = await decks.root('Korean', SchedulerType.sm2);
    final leaf = await decks.sub(root.id, 'Lesson');
    await insertCard(
      db,
      id: 'c1',
      deckId: leaf.id,
      learnedAt: DateTime(2026, 9, 1),
      dueAt: DateTime(2026, 9, 20),
      intervalDays: 6,
    );
    await insertCard(db, id: 'n1', deckId: leaf.id);
    useCase = PreviewSelfAssessIntervalsUseCase(
      ScheduleRepositoryImpl(db),
      FakeDayClock(now),
    );
  });
  tearDown(() => db.close());

  test("a review's first turn previews each grade (16a)", () async {
    final preview = await useCase(
      kind: SessionKind.reviewing,
      cardId: 'c1',
      round: 1,
      answersInSession: 0,
    );

    expect(preview, {
      Sm2Action.again: 1,
      Sm2Action.hard: 6,
      Sm2Action.good: 6,
      Sm2Action.easy: 6,
    });
  });

  test('a relearning turn previews nothing: the schedule does not move '
      '(BR-SRS-016, BR-SRS-017)', () async {
    expect(
      await useCase(
        kind: SessionKind.reviewing,
        cardId: 'c1',
        round: 1,
        answersInSession: 1,
      ),
      isNull,
    );
  });

  test(
    'a learning turn previews nothing: the card is not scheduled yet',
    () async {
      expect(
        await useCase(
          kind: SessionKind.learning,
          cardId: 'n1',
          round: 1,
          answersInSession: 0,
        ),
        isNull,
      );
    },
  );

  test('a card gone meanwhile previews nothing', () async {
    expect(
      await useCase(
        kind: SessionKind.reviewing,
        cardId: 'gone',
        round: 1,
        answersInSession: 0,
      ),
      isNull,
    );
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/domain/models/deck_deletion_summary_model.dart';
import 'package:memox/features/deck/domain/models/deck_placement_model.dart';
import 'package:memox/features/deck/domain/usecases/change_deck_scheduler_use_case.dart';
import 'package:memox/features/deck/domain/usecases/create_root_deck_use_case.dart';
import 'package:memox/features/deck/domain/usecases/create_sub_deck_use_case.dart';
import 'package:memox/features/deck/domain/usecases/delete_deck_use_case.dart';
import 'package:memox/features/deck/domain/usecases/get_deck_deletion_summary_use_case.dart';
import 'package:memox/features/deck/domain/usecases/move_deck_use_case.dart';
import 'package:memox/features/deck/domain/usecases/rename_deck_use_case.dart';
import 'package:memox/features/deck/domain/usecases/reorder_deck_use_case.dart';
import 'package:memox/features/deck/domain/usecases/undo_deck_deletion_use_case.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/srs/domain/failures/srs_failure.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';

import '../../../support/test_database.dart';

// The write use cases forward to one repository call each (AD-12). They are
// exercised here over the real repositories, so the test asserts what a
// person sees in the tree, not that a fake was called.

T _value<T>(Outcome<T, DeckRejection> result) =>
    (result as Ok<T, DeckRejection>).value;

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl decks;
  setUp(() {
    db = openTestDatabase();
    decks = DeckRepositoryImpl(db, now: () => DateTime(2026, 9, 23));
  });
  tearDown(() => db.close());

  test('the deck write use cases drive the tree end to end (UC-DECK-001, UC-DECK-002, UC-DECK-004, UC-DECK-005, UC-DECK-006)', () async {
    final root = _value(
      await CreateRootDeckUseCase(decks)(
        name: 'Korean',
        schedulerType: SchedulerType.eightBox,
      ),
    );
    final createSub = CreateSubDeckUseCase(decks);
    final nouns = _value(await createSub(parentId: root.id, name: 'Nouns'));
    final verbs = _value(await createSub(parentId: root.id, name: 'Verbs'));
    final food = _value(await createSub(parentId: nouns.id, name: 'Food'));

    await RenameDeckUseCase(decks)(deckId: nouns.id, name: 'Things');
    await ReorderDeckUseCase(decks)(
      deckId: verbs.id,
      anchorId: nouns.id,
      placement: DeckPlacement.before,
    );
    await MoveDeckUseCase(decks)(deckId: food.id, newParentId: verbs.id);
    final summary = _value<DeckDeletionSummary>(
      await GetDeckDeletionSummaryUseCase(decks)(deckId: root.id),
    );
    await DeleteDeckUseCase(decks)(deckId: verbs.id);

    expect((await decks.findById(nouns.id))!.name, 'Things');
    expect((summary.subDeckCount, summary.cardCount), (3, 0));
    expect(await decks.findById(verbs.id), isNull);
    expect(
      await decks.findById(food.id),
      isNull,
      reason: 'deleted with its parent',
    );
  });

  test(
    'ChangeDeckSchedulerUseCase changes the scheduler of an unlocked root',
    () async {
      final root = _value<DeckEntity>(
        await CreateRootDeckUseCase(decks)(
          name: 'Korean',
          schedulerType: SchedulerType.eightBox,
        ),
      );

      final result = await ChangeDeckSchedulerUseCase(
        ScheduleRepositoryImpl(db),
      )(rootDeckId: root.id, schedulerType: SchedulerType.sm2);

      expect(result, isA<Ok<void, SrsRejection>>());
      expect((await decks.findById(root.id))!.schedulerType, SchedulerType.sm2);
    },
  );

  test(
    'Undo right after a delete brings the deck back (BR-TRASH-008)',
    () async {
      final root = _value<DeckEntity>(
        await CreateRootDeckUseCase(decks)(
          name: 'Korean',
          schedulerType: SchedulerType.eightBox,
        ),
      );
      final batchId = _value(await DeleteDeckUseCase(decks)(deckId: root.id));

      expect(
        await UndoDeckDeletionUseCase(decks)(batchId: batchId),
        isA<Ok<void, DeckRejection>>(),
      );
      expect(await decks.findById(root.id), isNotNull);
    },
  );
}

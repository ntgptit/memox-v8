import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/clock/di/day_clock_provider.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/presentation/controllers/deck_actions_controller.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:drift/drift.dart' show Variable;
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/models/deck_placement_model.dart';
import 'package:memox/features/deck/domain/repositories/deck_repository.dart';
import 'package:memox/features/srs/domain/failures/srs_failure.dart';

import '../../../support/fake_day_clock.dart';
import '../../../support/library_harness.dart';
import '../../../support/test_database.dart';
import '../../../support/deck_fixtures.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = openTestDatabase();
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        dayClockProvider.overrideWithValue(FakeDayClock(libraryToday)),
      ],
    );
  });
  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<int> deckCount() async =>
      (await db.customSelect('SELECT COUNT(*) AS n FROM deck').getSingle())
          .read<int>('n');

  Future<int> activeDeckCount() async =>
      (await db
              .customSelect(
                'SELECT COUNT(*) AS n FROM deck WHERE delete_batch_id IS NULL',
              )
              .getSingle())
          .read<int>('n');

  test('createRootDeck hands back the new deck', () async {
    final outcome = await container
        .read(deckActionsControllerProvider.notifier)
        .createRootDeck(name: 'Korean', schedulerType: SchedulerType.sm2);

    expect(outcome, isA<Ok<Object?, DeckRejection>>());
    expect(await deckCount(), 1);
  });

  test('a blank name is refused and nothing is written', () async {
    final before = await totalChanges(db);
    final outcome = await container
        .read(deckActionsControllerProvider.notifier)
        .createRootDeck(name: '   ', schedulerType: SchedulerType.eightBox);

    expect(
      outcome,
      isA<Rejected<Object?, DeckRejection>>().having(
        (rejected) => rejected.reason,
        'reason',
        DeckRejection.blankName,
      ),
    );
    expect(await totalChanges(db), before);
  });

  DeckActionsController actions() =>
      container.read(deckActionsControllerProvider.notifier);
  DeckRepository decks() => DeckRepositoryImpl(db);

  Future<List<String>> rootOrder() async => [
    for (final row
        in await db
            .customSelect(
              'SELECT name FROM deck WHERE parent_id IS NULL '
              'ORDER BY sibling_position',
            )
            .get())
      row.read<String>('name'),
  ];

  Future<String?> parentOf(String id) async =>
      (await db
              .customSelect(
                'SELECT parent_id FROM deck WHERE id = ?',
                variables: [Variable<String>(id)],
              )
              .getSingle())
          .read<String?>('parent_id');

  test('createSubDeck adds a deck under its parent', () async {
    final korean = await decks().root('Korean');
    final outcome = await actions().createSubDeck(
      parentId: korean.id,
      name: 'Words',
    );

    expect(outcome, isA<Ok<Object?, DeckRejection>>());
    expect(await deckCount(), 2);
  });

  test('renameDeck gives the deck its new name', () async {
    final korean = await decks().root('Korean');
    await actions().renameDeck(deckId: korean.id, name: 'Hàn Quốc');

    expect((await decks().findById(korean.id))!.name, 'Hàn Quốc');
  });

  test(
    'deleteDeck moves the subtree to the Trash and hands back its batch',
    () async {
      final korean = await decks().root('Korean');
      await decks().sub(korean.id, 'Words');
      final outcome = await actions().deleteDeck(deckId: korean.id);

      expect(outcome, isA<Ok<String, DeckRejection>>());
      expect(await activeDeckCount(), 0);
      expect(await deckCount(), 2, reason: 'the rows stay, marked');
    },
  );

  test('moveDeck puts the deck under its new parent', () async {
    final korean = await decks().root('Korean');
    final words = await decks().sub(korean.id, 'Words');
    final grammar = await decks().sub(korean.id, 'Grammar');
    await actions().moveDeck(deckId: grammar.id, newParentId: words.id);

    expect(await parentOf(grammar.id), words.id);
  });

  test('reorderDeck places the deck next to its anchor', () async {
    final a = await decks().root('A');
    await decks().root('B');
    final c = await decks().root('C');
    await actions().reorderDeck(
      deckId: c.id,
      anchorId: a.id,
      placement: DeckPlacement.before,
    );

    expect(await rootOrder(), ['C', 'A', 'B']);
  });

  test('changeScheduler switches an unlocked root', () async {
    final korean = await decks().root('Korean');
    final outcome = await actions().changeScheduler(
      rootDeckId: korean.id,
      schedulerType: SchedulerType.sm2,
    );

    expect(outcome, isA<Ok<Object?, SrsRejection>>());
    expect(
      (await decks().findById(korean.id))!.schedulerType,
      SchedulerType.sm2,
    );
  });

  test('changeScheduler is refused once the root is locked', () async {
    final korean = await decks().root('Korean');
    await lockScheduler(db, korean.id);
    final outcome = await actions().changeScheduler(
      rootDeckId: korean.id,
      schedulerType: SchedulerType.sm2,
    );

    expect(
      outcome,
      isA<Rejected<Object?, SrsRejection>>().having(
        (rejected) => rejected.reason,
        'reason',
        SrsRejection.schedulerLocked,
      ),
    );
  });
}

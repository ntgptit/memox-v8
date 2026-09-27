import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';
import 'package:memox/features/trash/data/repositories/trash_repository_impl.dart';
import 'package:memox/features/trash/domain/entities/trash_entry_entity.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/test_database.dart';
import '../../../support/trash_fixtures.dart';

// UC-TRASH-001 steps 3-4: the Trash lists every batch by the item the person
// deleted, newest first, with where it was and what went with it
// (BR-TRASH-012; trash spec §9).

/// [entry] as a line a test can read: the item, its origin and its counts.
String _line(TrashEntry entry) {
  final origin = [for (final deck in entry.origin) deck.name].join(' › ');
  return switch (entry) {
    TrashDeckEntry(:final name, :final subDeckCount, :final cardCount) =>
      'deck $name in [$origin] with $subDeckCount decks, $cardCount cards',
    TrashCardEntry(:final front) => 'card $front in [$origin]',
  };
}

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl decks;
  late CardRepositoryImpl cards;
  late TrashRepositoryImpl trash;
  var clock = DateTime(2026, 9, 25, 9);

  setUp(() {
    clock = DateTime(2026, 9, 25, 9);
    db = openTestDatabase();
    decks = DeckRepositoryImpl(db, now: () => clock);
    cards = CardRepositoryImpl(
      db,
      ScheduleRepositoryImpl(db, now: () => clock),
      TagRepositoryImpl(db, now: () => clock),
      now: () => clock,
    );
    trash = TrashRepositoryImpl(db);
  });
  tearDown(() => db.close());

  Future<String> deleteDeck(String deckId) async {
    clock = clock.add(const Duration(minutes: 1));
    return ((await decks.deleteDeck(
      deckId: deckId,
    )) as Ok<String, DeckRejection>).value;
  }

  Future<List<String>> deleteCards(Set<String> cardIds) async {
    clock = clock.add(const Duration(minutes: 1));
    return ((await cards.deleteCards(
      cardIds: cardIds,
    )) as Ok<List<String>, CardRejection>).value;
  }

  Future<List<String>> lines() async => [
    for (final entry in await trash.watchEntries().first) _line(entry),
  ];

  test(
    'every batch, newest first, with the counts of its own rows and the '
    'path of decks it was in, decks in the Trash included (BR-TRASH-003)',
    () async {
      final korean = await decks.root('Korean');
      final words = await decks.sub(korean.id, 'Words');
      final food = await decks.sub(words.id, 'Food');
      final drinks = await decks.sub(words.id, 'Drinks');
      await decks.sub(drinks.id, 'Tea');
      await insertCard(db, id: 'f1', front: 'apple', deckId: food.id);
      await insertCard(db, id: 'f2', front: 'bread', deckId: food.id);
      await insertCard(db, id: 'd1', front: 'water', deckId: drinks.id);
      await deleteCards({'f1'});
      await deleteDeck(food.id);
      await deleteDeck(words.id);

      expect(await lines(), [
        'deck Words in [Korean] with 2 decks, 1 cards',
        'deck Food in [Korean › Words] with 0 decks, 1 cards',
        'card apple in [Korean › Words › Food]',
      ]);
    },
  );

  test('cards deleted in one call share a time and list in batch id order, '
      'the same on every emission', () async {
    final korean = await decks.root('Korean');
    final lesson = await decks.sub(korean.id, 'Lesson');
    final ids = {for (var i = 1; i <= 6; i++) 'c$i'};
    for (final id in ids) {
      await insertCard(db, id: id, deckId: lesson.id);
    }
    final batchIds = await deleteCards(ids);
    final order = [...batchIds]..sort();
    final emissions = trash.watchEntries().map(
      (entries) => [
        for (final entry in entries) (entry.batchId, entry.deletedAt),
      ],
    );

    final followed = expectLater(
      emissions,
      emitsInOrder([
        [for (final id in order) (id, clock)],
        [for (final id in order) (id, clock)],
      ]),
    );
    await pumpEventQueue();
    await decks.sub(korean.id, 'Later');
    await followed;
  });

  test('a root deck has no origin and says it is a root', () async {
    final korean = await decks.root('Korean');
    final batchId = await deleteDeck(korean.id);

    final [entry] = await trash.watchEntries().first;

    expect(entry.batchId, batchId);
    expect((entry as TrashDeckEntry).isRoot, isTrue);
    expect(entry.origin, isEmpty);
    expect(entry.deletedAt, clock);
    expect(entry.expiresAt, clock.add(trashRetention));
  });

  test(
    'a batch whose item root is missing is not listed (invariant 37)',
    () async {
      await insertDeleteBatch(
        db,
        'orphan',
        itemType: 'deck',
        rootItemId: 'gone',
      );

      expect(await lines(), isEmpty);
    },
  );

  test('the list follows a delete, a restore and a purge', () async {
    final korean = await decks.root('Korean');
    final words = await decks.sub(korean.id, 'Words');
    final entries = trash.watchEntries().map(
      (entries) => [for (final entry in entries) _line(entry)],
    );

    final followed = expectLater(
      entries,
      emitsInOrder([
        isEmpty,
        emitsThrough(['deck Words in [Korean] with 0 decks, 0 cards']),
        emitsThrough(isEmpty),
        emitsThrough(['deck Words in [Korean] with 0 decks, 0 cards']),
        emitsThrough(isEmpty),
      ]),
    );
    await pumpEventQueue();
    final first = await deleteDeck(words.id);
    await pumpEventQueue();
    await decks.restoreDecks(batchIds: {first}, parentId: korean.id);
    await pumpEventQueue();
    final second = await deleteDeck(words.id);
    await pumpEventQueue();
    await trash.purge(batchIds: {second}, now: clock);
    await followed;
  });
}

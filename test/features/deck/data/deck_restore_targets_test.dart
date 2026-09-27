import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/domain/models/deck_restore_targets_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/test_database.dart';

// BR-TRASH-006 and UC-TRASH-001 step 5: where the decks of a Trash selection
// may go back (trash spec §7.4).

/// The names [targets] offers, the top level as `/`.
List<String> _namesOf(DeckRestoreTargets targets) => switch (targets) {
  DeckRestoreTopLevel() => ['/'],
  DeckRestoreUnder(:final decks) => [for (final deck in decks) deck.name],
};

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl decks;
  setUp(() {
    db = openTestDatabase();
    decks = DeckRepositoryImpl(db, now: () => DateTime(2026, 9, 25, 9));
  });
  tearDown(() => db.close());

  Future<String> delete(String deckId) async => ((await decks.deleteDeck(
    deckId: deckId,
  )) as Ok<String, DeckRejection>).value;

  Future<List<String>> namesFor(Set<String> batchIds) async =>
      _namesOf(await decks.watchRestoreTargets(batchIds).first);

  test('a sub-deck may go back under its old parent, or where a move of it '
      'may go: not into a deck of cards, its own subtree or another '
      'scheduler', () async {
    final korean = await decks.root('Korean');
    final words = await decks.sub(korean.id, 'Words');
    final food = await decks.sub(words.id, 'Food');
    await decks.sub(food.id, 'Fruit');
    final cards = await decks.sub(korean.id, 'Cards');
    await insertCard(db, id: 'c1', deckId: cards.id);
    await decks.root('Other', SchedulerType.sm2);
    await decks.root('English');
    final batch = await delete(food.id);

    final targets = await decks.watchRestoreTargets({batch}).first;

    expect(_namesOf(targets), ['Korean', 'Words', 'English']);
    final under = (targets as DeckRestoreUnder).decks;
    expect([for (final entry in under[1].path) entry.name], ['Korean']);
  });

  test('root decks go back to the top level; roots and sub-decks together, '
      'or a batch that is gone, have no common place (E1)', () async {
    final korean = await decks.root('Korean');
    final english = await decks.root('English');
    final words = await decks.sub(english.id, 'Words');
    final root = await delete(korean.id);
    final sub = await delete(words.id);

    expect(await namesFor({root}), ['/']);
    expect(await namesFor({root, sub}), isEmpty);
    expect(await namesFor({sub, 'missing'}), isEmpty);
  });

  test('a sub-deck whose root went to the Trash after it may go back into '
      'the decks of another root of its scheduler and generation', () async {
    final korean = await decks.root('Korean');
    final words = await decks.sub(korean.id, 'Words');
    await decks.root('Other', SchedulerType.sm2);
    final english = await decks.root('English');
    await decks.sub(english.id, 'Grammar');
    final batch = await delete(words.id);
    await delete(korean.id);

    expect(await namesFor({batch}), ['English', 'Grammar']);
  });

  test('several batches keep the decks that take all of them: the tallest '
      'subtree sets the depth (BR-DECK-001)', () async {
    final korean = await decks.root('Korean');
    var deepest = korean.id;
    for (var level = 2; level <= 9; level++) {
      deepest = (await decks.sub(deepest, 'L$level')).id;
    }
    final tall = await decks.sub(korean.id, 'Tall');
    await decks.sub(tall.id, 'Inside');
    final flat = await decks.sub(korean.id, 'Flat');
    final tallBatch = await delete(tall.id);
    final flatBatch = await delete(flat.id);

    expect(await namesFor({flatBatch}), contains('L9'));
    expect(await namesFor({tallBatch}), isNot(contains('L9')));
    expect(await namesFor({tallBatch, flatBatch}), [
      for (final name in await namesFor({tallBatch})) name,
    ]);
  });

  test('the list follows a write: a new deck joins it, a deck sent to the '
      'Trash leaves it (E2)', () async {
    final korean = await decks.root('Korean');
    final words = await decks.sub(korean.id, 'Words');
    final batch = await delete(words.id);
    final targets = decks.watchRestoreTargets({batch}).map(_namesOf);

    final followed = expectLater(
      targets,
      emitsInOrder([
        ['Korean'],
        emitsThrough(['Korean', 'Grammar']),
        emitsThrough(['Korean']),
      ]),
    );
    await pumpEventQueue();
    final grammar = await decks.sub(korean.id, 'Grammar');
    await pumpEventQueue();
    await delete(grammar.id);
    await followed;
  });
}

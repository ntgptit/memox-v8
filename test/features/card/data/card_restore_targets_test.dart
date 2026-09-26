import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/test_database.dart';

// BR-TRASH-006 and UC-TRASH-001 step 5: where the cards of a Trash selection
// may go back (trash spec §7.4).

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl decks;
  late CardRepositoryImpl cards;
  setUp(() {
    db = openTestDatabase();
    DateTime now() => DateTime(2026, 9, 25, 9);
    decks = DeckRepositoryImpl(db, now: now);
    cards = CardRepositoryImpl(
      db,
      ScheduleRepositoryImpl(db, now: now),
      TagRepositoryImpl(db, now: now),
      now: now,
    );
  });
  tearDown(() => db.close());

  Future<List<String>> delete(Set<String> cardIds) async =>
      ((await cards.deleteCards(
        cardIds: cardIds,
      )) as Ok<List<String>, CardRejection>).value;

  Future<List<String>> namesFor(Set<String> batchIds) async => [
    for (final target in await cards.watchRestoreTargets(batchIds).first)
      target.name,
  ];

  test('cards may go back into any deck of their root that holds cards or '
      'nothing, their old deck included', () async {
    final korean = await decks.root('Korean');
    final lesson = await decks.sub(korean.id, 'Lesson');
    final parent = await decks.sub(korean.id, 'Parent');
    await decks.sub(parent.id, 'Child');
    final english = await decks.root('English');
    await decks.sub(english.id, 'Words');
    await insertCard(db, id: 'c1', deckId: lesson.id);
    await insertCard(db, id: 'c2', deckId: lesson.id);
    final batchIds = await delete({'c1', 'c2'});

    final targets = await cards.watchRestoreTargets(batchIds.toSet()).first;

    expect([for (final target in targets) target.name], ['Lesson', 'Child']);
    expect(
      [for (final entry in targets[1].path) entry.name],
      ['Korean', 'Parent'],
    );
  });

  test('cards of two roots have no common deck, and a batch that is gone has '
      'none (E1)', () async {
    final korean = await decks.root('Korean');
    final lesson = await decks.sub(korean.id, 'Lesson');
    final english = await decks.root('English');
    final words = await decks.sub(english.id, 'Words');
    await insertCard(db, id: 'c1', deckId: lesson.id);
    await insertCard(db, id: 'c2', deckId: words.id);
    final [first, second] = await delete({'c1', 'c2'});

    expect(await namesFor({first}), ['Lesson']);
    expect(await namesFor({first, second}), isEmpty);
    expect(await namesFor({first, 'missing'}), isEmpty);
  });

  test('the list follows a write (E2)', () async {
    final korean = await decks.root('Korean');
    final lesson = await decks.sub(korean.id, 'Lesson');
    await insertCard(db, id: 'c1', deckId: lesson.id);
    final batchIds = await delete({'c1'});
    final names = cards
        .watchRestoreTargets(batchIds.toSet())
        .map((targets) => [for (final target in targets) target.name]);

    final followed = expectLater(
      names,
      emitsInOrder([
        ['Lesson'],
        emitsThrough(['Lesson', 'Other']),
      ]),
    );
    await pumpEventQueue();
    await decks.sub(korean.id, 'Other');
    await followed;
  });
}

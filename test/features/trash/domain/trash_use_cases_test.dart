import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/domain/models/deck_restore_targets_model.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';
import 'package:memox/features/trash/data/repositories/trash_repository_impl.dart';
import 'package:memox/features/trash/domain/entities/trash_entry_entity.dart';
import 'package:memox/features/trash/domain/usecases/purge_expired_trash_use_case.dart';
import 'package:memox/features/trash/domain/usecases/purge_trash_use_case.dart';
import 'package:memox/features/trash/domain/usecases/restore_cards_from_trash_use_case.dart';
import 'package:memox/features/trash/domain/usecases/restore_decks_from_trash_use_case.dart';
import 'package:memox/features/trash/domain/usecases/watch_card_restore_targets_use_case.dart';
import 'package:memox/features/trash/domain/usecases/watch_deck_restore_targets_use_case.dart';
import 'package:memox/features/trash/domain/usecases/watch_trash_use_case.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/fake_day_clock.dart';
import '../../../support/test_database.dart';

// The Trash use cases forward to one repository call each (AD-12), over the
// real repositories, so the test asserts what a person sees in the Trash.

void main() {
  late AppDatabase db;
  late FakeDayClock clock;
  late DeckRepositoryImpl decks;
  late CardRepositoryImpl cards;
  late TrashRepositoryImpl trash;

  setUp(() {
    db = openTestDatabase();
    clock = FakeDayClock(DateTime(2026, 9, 25, 9));
    decks = DeckRepositoryImpl(db, now: clock.now);
    cards = CardRepositoryImpl(
      db,
      ScheduleRepositoryImpl(db, now: clock.now),
      TagRepositoryImpl(db, now: clock.now),
      now: clock.now,
    );
    trash = TrashRepositoryImpl(db);
  });
  tearDown(() => db.close());

  test('a deck and a card go to the Trash, come back where the person '
      'chooses, and go for good when purged (UC-TRASH-001)', () async {
    final korean = await decks.root('Korean');
    final words = await decks.sub(korean.id, 'Words');
    final lesson = await decks.sub(korean.id, 'Lesson');
    final other = await decks.sub(korean.id, 'Other');
    await insertCard(db, id: 'c1', deckId: lesson.id);
    final deckBatch = ((await decks.deleteDeck(
      deckId: words.id,
    )) as Ok<String, DeckRejection>).value;
    final [cardBatch] = ((await cards.deleteCards(
      cardIds: {'c1'},
    )) as Ok<List<String>, CardRejection>).value;

    final entries = await WatchTrashUseCase(trash)().first;
    expect(entries, hasLength(2));

    final deckTargets = await WatchDeckRestoreTargetsUseCase(decks)(
      batchIds: {deckBatch},
    ).first;
    expect(
      [for (final deck in (deckTargets as DeckRestoreUnder).decks) deck.name],
      ['Korean', 'Lesson', 'Other'],
    );
    final cardTargets = await WatchCardRestoreTargetsUseCase(cards)(
      batchIds: {cardBatch},
    ).first;
    expect([for (final deck in cardTargets) deck.name], ['Lesson', 'Other']);

    expect(
      await RestoreDecksFromTrashUseCase(decks)(
        batchIds: {deckBatch},
        parentId: other.id,
      ),
      isA<Ok<void, DeckRejection>>(),
    );
    expect(
      await RestoreCardsFromTrashUseCase(cards)(
        batchIds: {cardBatch},
        deckId: lesson.id,
      ),
      isA<Ok<void, CardRejection>>(),
    );
    expect(await WatchTrashUseCase(trash)().first, isEmpty);

    final again = ((await decks.deleteDeck(
      deckId: words.id,
    )) as Ok<String, DeckRejection>).value;
    expect((await PurgeTrashUseCase(trash, clock)(batchIds: {again})).purged, {
      again,
    });

    final last = ((await decks.deleteDeck(
      deckId: other.id,
    )) as Ok<String, DeckRejection>).value;
    clock.current = clock.current.add(trashRetention);
    expect((await PurgeExpiredTrashUseCase(trash, clock)()).purged, {last});
  });
}

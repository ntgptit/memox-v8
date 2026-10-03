import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/sync/sync_store.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';
import 'package:memox/features/trash/data/repositories/trash_repository_impl.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/fake_day_clock.dart';
import '../../../support/test_database.dart';

// BR-TRASH-009 (R10), write side: a device clock set back never stamps a
// batch older than the last server time seen, so a later purge cannot take a
// fresh batch for an old one.
void main() {
  late AppDatabase db;
  late FakeDayClock clock;
  late DeckRepositoryImpl decks;
  late CardRepositoryImpl cards;
  final serverNow = DateTime.utc(2026, 10, 3, 8);
  final yearBehind = DateTime.utc(2025, 10, 3, 8);

  setUp(() {
    db = openTestDatabase();
    clock = FakeDayClock(yearBehind);
    decks = DeckRepositoryImpl(db, now: clock.now);
    cards = CardRepositoryImpl(
      db,
      ScheduleRepositoryImpl(db, now: clock.now),
      TagRepositoryImpl(db, now: clock.now),
      now: clock.now,
    );
  });
  tearDown(() => db.close());

  Future<List<DateTime>> deletedAts() async => [
    for (final row in await db.select(db.deleteBatches).get()) row.deletedAt,
  ];

  test('a deck deleted with the clock a year behind is stamped with the last '
      'server time and survives the purge once the clock is right', () async {
    await SyncStore(db).recordServerTime(serverNow);
    final korean = await decks.root('Korean');
    await decks.deleteDeck(deckId: korean.id);

    expect((await deletedAts()).single.toUtc(), serverNow);

    // The clock is fixed, a sync says a day later: the batch is a day old.
    final later = serverNow.add(const Duration(days: 1));
    clock.current = later;
    final report = await TrashRepositoryImpl(db).purgeExpired(now: later);
    expect(report.purged, isEmpty);
    expect(await deletedAts(), hasLength(1));
  });

  test('a card batch is stamped the same way', () async {
    await SyncStore(db).recordServerTime(serverNow);
    final korean = await decks.root('Korean');
    final words = await decks.sub(korean.id, 'Words');
    await insertCard(db, id: 'c1', deckId: words.id);
    await cards.deleteCards(cardIds: {'c1'});

    expect((await deletedAts()).single.toUtc(), serverNow);
  });

  test(
    'the device clock wins when it is ahead, or when nothing synced',
    () async {
      final korean = await decks.root('Korean');
      final words = await decks.sub(korean.id, 'Words');
      await decks.deleteDeck(deckId: words.id);
      expect((await deletedAts()).single.toUtc(), yearBehind);

      await SyncStore(db)
          .recordServerTime(yearBehind.subtract(const Duration(days: 3)));
      await decks.deleteDeck(deckId: korean.id);
      expect(
        (await deletedAts()).map((at) => at.toUtc()),
        everyElement(yearBehind),
      );
    },
  );
}

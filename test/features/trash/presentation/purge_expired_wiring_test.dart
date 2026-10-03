import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/clock/di/day_clock_provider.dart';
import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/core/sync/sync_store.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/trash/domain/entities/trash_entry_entity.dart';
import 'package:memox/features/trash/presentation/providers/purge_expired_trash_use_case_provider.dart';

import '../../../support/deck_fixtures.dart';
import '../../../support/fake_day_clock.dart';
import '../../../support/test_database.dart';

// The real wiring of R10: the use case reads the server time the sync stored.
void main() {
  test('the auto-purge waits for a stored server time and never runs ahead '
      'of it (SP2b 2.30)', () async {
    final db = openTestDatabase();
    addTearDown(db.close);
    final deletedAt = DateTime(2026, 9, 25, 9);
    final clock = FakeDayClock(deletedAt);
    final decks = DeckRepositoryImpl(db, now: clock.now);
    final korean = await decks.root('Korean');
    final words = await decks.sub(korean.id, 'Words');
    await decks.deleteDeck(deckId: words.id);
    clock.current = deletedAt.add(const Duration(days: 60));
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        dayClockProvider.overrideWithValue(clock),
      ],
    );
    addTearDown(container.dispose);
    Future<int> purgedCount() async => (await container.read(
      purgeExpiredTrashUseCaseProvider,
    )()).purged.length;

    // Never synced: the batch is expired by the device clock and stays.
    expect(await purgedCount(), 0);

    // The server last said 10 days: not expired there, whatever the device says.
    final store = SyncStore(db);
    await store.recordServerTime(deletedAt.add(const Duration(days: 10)));
    expect(await purgedCount(), 0);

    await store.recordServerTime(deletedAt.add(trashRetention));
    expect(await purgedCount(), 1);
  });
}

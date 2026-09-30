import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/account/data/repositories/account_device_repository_impl.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/test_database.dart';

void main() {
  late AppDatabase db;
  late AccountDeviceRepositoryImpl repository;

  setUp(() {
    db = openTestDatabase();
    repository = AccountDeviceRepositoryImpl(db);
  });
  tearDown(() => db.close());

  test('a fresh device has not answered Welcome', () async {
    expect(await repository.isWelcomeSeen(), isFalse);
  });

  test('answering Welcome is kept, and queues nothing to sync', () async {
    await repository.markWelcomeSeen();

    expect(await repository.isWelcomeSeen(), isTrue);
    final outbox = await db
        .customSelect('SELECT COUNT(*) AS n FROM sync_outbox')
        .getSingle();
    expect(outbox.read<int>('n'), 0);
  });

  test('an empty device has nothing to merge', () async {
    final library = await repository.countLibrary();

    expect((library.decks, library.cards), (0, 0));
    expect(library.isEmpty, isTrue);
  });

  test('counts live decks and cards, never the Trash', () async {
    final decks = DeckRepositoryImpl(db);
    final korean = await decks.root('Korean');
    await decks.root('English');
    await insertCard(db, id: 'c1', deckId: korean.id);
    await insertCard(db, id: 'c2', deckId: korean.id, deleteBatchId: 'b1');

    final library = await repository.countLibrary();

    expect((library.decks, library.cards), (2, 1));
    expect(library.isEmpty, isFalse);
  });
}

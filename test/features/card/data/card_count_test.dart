import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/card/data/repositories/card_transfer_repository_impl.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/test_database.dart';

// The count a whole-deck export names before its sheet opens
// (UC-TRANSFER-002 step 1).

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl decks;
  late CardTransferRepositoryImpl cards;
  setUp(() {
    db = openTestDatabase();
    decks = DeckRepositoryImpl(db);
    cards = CardTransferRepositoryImpl(
      db,
      CardRepositoryImpl(db, ScheduleRepositoryImpl(db), TagRepositoryImpl(db)),
    );
  });
  tearDown(() => db.close());

  test(
    'counts the live cards of the deck, not those of others or in the Trash',
    () async {
      final root = await decks.root('r');
      final leaf = await decks.sub(root.id, 'l');
      final other = await decks.sub(root.id, 'o');
      await insertCard(db, id: 'a', deckId: leaf.id);
      await insertCard(db, id: 'b', deckId: leaf.id);
      await insertCard(db, id: 'c', deckId: leaf.id, deleteBatchId: 'batch');
      await insertCard(db, id: 'x', deckId: other.id);

      expect(await cards.countCards(leaf.id), 2);
      expect(await cards.countCards(root.id), 0);
      expect(await cards.countCards('missing'), 0);
    },
  );
}

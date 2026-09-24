import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/domain/models/deck_view_model.dart';
import 'package:memox/features/deck/domain/usecases/search_decks_use_case.dart';
import 'package:memox/features/deck/domain/usecases/watch_deck_move_targets_use_case.dart';
import 'package:memox/features/deck/domain/usecases/watch_deck_use_case.dart';

import '../../../support/deck_fixtures.dart';
import '../../../support/test_database.dart';

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl decks;
  setUp(() {
    db = openTestDatabase();
    decks = DeckRepositoryImpl(db, now: () => DateTime(2026, 9, 23));
  });
  tearDown(() => db.close());

  test(
    'WatchDeckUseCase answers notFound once the open deck is deleted',
    () async {
      final root = await decks.root('Korean');
      final leaf = await decks.sub(root.id, 'Nouns');
      final results = <Outcome<DeckView, DeckRejection>>[];
      final subscription = WatchDeckUseCase(decks)(deckId: leaf.id)
          .listen(results.add);
      await pumpEventQueue();

      await decks.deleteDeck(deckId: leaf.id);
      await pumpEventQueue();

      expect(results.first, isA<Ok<DeckView, DeckRejection>>());
      expect(
        (results.last as Rejected<DeckView, DeckRejection>).reason,
        DeckRejection.notFound,
      );
      await subscription.cancel();
    },
  );

  test(
    'SearchDecksUseCase folds the term, and a blank term finds nothing',
    () async {
      final root = await decks.root('Korean');
      await decks.sub(root.id, 'Academic words');
      final search = SearchDecksUseCase(decks);

      final hits = await search(scopeDeckId: null, term: '  ACADEMIC ').first;
      final none = await search(scopeDeckId: null, term: '   ').first;

      expect([for (final hit in hits) hit.name], ['Academic words']);
      expect(none, isEmpty);
    },
  );

  test('WatchDeckMoveTargetsUseCase lists where a deck may go', () async {
    final root = await decks.root('Korean');
    final moving = await decks.sub(root.id, 'Moving');
    await decks.sub(root.id, 'Other');

    final targets = await WatchDeckMoveTargetsUseCase(decks)(deckId: moving.id)
        .first;

    expect([for (final target in targets) target.name], ['Other']);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/models/card_detail_model.dart';
import 'package:memox/features/card/domain/models/review_history_model.dart';
import 'package:memox/features/card/domain/usecases/load_card_history_page_use_case.dart';
import 'package:memox/features/card/domain/usecases/watch_card_detail_use_case.dart';
import 'package:memox/features/card/domain/usecases/watch_card_move_targets_use_case.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/test_database.dart';

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl decks;
  late CardRepositoryImpl cards;
  late DeckEntity leaf;
  setUp(() async {
    db = openTestDatabase();
    DateTime now() => DateTime(2026, 9, 23);
    decks = DeckRepositoryImpl(db, now: now);
    cards = CardRepositoryImpl(
      db,
      ScheduleRepositoryImpl(db, now: now),
      TagRepositoryImpl(db, now: now),
      now: now,
    );
    final root = await decks.root('Korean');
    leaf = await decks.sub(root.id, 'Nouns');
  });
  tearDown(() => db.close());

  test('WatchCardDetailUseCase answers notFound once the card is deleted (UC-CARD-002, BR-CARD-019)', () async {
    final card = await cards.card(leaf.id);
    final results = <Outcome<CardDetail, CardRejection>>[];
    final subscription = WatchCardDetailUseCase(cards)(cardId: card.id)
        .listen(results.add);
    await pumpEventQueue();

    await cards.deleteCards(cardIds: {card.id});
    await pumpEventQueue();

    expect(results.first, isA<Ok<CardDetail, CardRejection>>());
    expect(
      (results.last as Rejected<CardDetail, CardRejection>).reason,
      CardRejection.notFound,
    );
    await subscription.cancel();
  });

  test(
    'LoadCardHistoryPageUseCase gives an empty first page, or notFound',
    () async {
      final card = await cards.card(leaf.id);
      final load = LoadCardHistoryPageUseCase(cards);

      final page = await load(cardId: card.id);
      final missing = await load(cardId: 'missing');

      expect(
        (page as Ok<ReviewHistoryPage, CardRejection>).value.entries,
        isEmpty,
      );
      expect(
        (missing as Rejected<ReviewHistoryPage, CardRejection>).reason,
        CardRejection.notFound,
      );
    },
  );

  test(
    'WatchCardMoveTargetsUseCase lists where the cards of a deck may go',
    () async {
      final other = await decks.sub(leaf.parentId!, 'Verbs');

      final targets = await WatchCardMoveTargetsUseCase(cards)(
        sourceDeckId: leaf.id,
      ).first;

      expect([for (final target in targets) target.id], [other.id]);
    },
  );
}

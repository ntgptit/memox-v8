import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/card/domain/entities/card_entity.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/card/domain/usecases/add_tag_to_cards_use_case.dart';
import 'package:memox/features/card/domain/usecases/create_card_use_case.dart';
import 'package:memox/features/card/domain/usecases/delete_cards_use_case.dart';
import 'package:memox/features/card/domain/usecases/edit_card_use_case.dart';
import 'package:memox/features/card/domain/usecases/move_cards_use_case.dart';
import 'package:memox/features/card/domain/usecases/remove_tag_from_cards_use_case.dart';
import 'package:memox/features/card/domain/usecases/set_cards_flagged_use_case.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';

import '../../../support/deck_fixtures.dart';
import '../../../support/test_database.dart';

// The card write use cases forward to one repository call each (AD-12). They
// run here over the real repositories, so the test asserts what a person
// sees, not that a fake was called.

void main() {
  late AppDatabase db;
  setUp(() => db = openTestDatabase());
  tearDown(() => db.close());

  test(
    'the card write use cases drive a deck of cards end to end (UC-CARD-001)',
    () async {
      DateTime now() => DateTime(2026, 9, 23);
      final decks = DeckRepositoryImpl(db, now: now);
      final tags = TagRepositoryImpl(db, now: now);
      final cards = CardRepositoryImpl(
        db,
        ScheduleRepositoryImpl(db, now: now),
        tags,
        now: now,
      );
      final root = await decks.root('Korean');
      final nouns = await decks.sub(root.id, 'Nouns');
      final verbs = await decks.sub(root.id, 'Verbs');
      final create = CreateCardUseCase(cards);
      CardEntity created(Outcome<CardEntity, CardRejection> result) =>
          (result as Ok<CardEntity, CardRejection>).value;

      final apple = created(
        await create(
          deckId: nouns.id,
          draft: const CardDraft(front: '사과', back: 'apple'),
        ),
      );
      final pear = created(
        await create(
          deckId: nouns.id,
          draft: const CardDraft(front: '배', back: 'pear'),
        ),
      );
      await EditCardUseCase(cards)(
        cardId: apple.id,
        draft: const CardDraft(front: '사과', back: 'an apple'),
      );
      await SetCardsFlaggedUseCase(cards)(
        cardIds: {apple.id, pear.id},
        isFlagged: true,
      );
      await AddTagToCardsUseCase(tags)(
        cardIds: {apple.id, pear.id},
        tagName: 'Fruit',
      );
      final fruitId =
          (await db
                  .customSelect(
                    "SELECT id FROM tags WHERE name_folded = 'fruit'",
                  )
                  .getSingle())
              .read<String>('id');
      await RemoveTagFromCardsUseCase(tags)(cardIds: {pear.id}, tagId: fruitId);
      await MoveCardsUseCase(cards)(cardIds: {pear.id}, targetDeckId: verbs.id);
      await DeleteCardsUseCase(cards)(cardIds: {apple.id});

      final rows = await db
          .customSelect('SELECT id, deck_id, back, is_flagged FROM card')
          .get();
      expect(
        [
          for (final row in rows)
            (
              row.read<String>('id'),
              row.read<String>('deck_id'),
              row.read<int>('is_flagged'),
            ),
        ],
        [(pear.id, verbs.id, 1)],
      );
      final links = await db
          .customSelect(
            'SELECT COUNT(*) AS n FROM card_tags WHERE card_id = ?',
            variables: [Variable(pear.id)],
          )
          .getSingle();
      expect(links.read<int>('n'), 0);
      expect(
        (await decks.findById(nouns.id))!.contentType,
        DeckContentType.unset,
      );
      expect(
        (await decks.findById(verbs.id))!.contentType,
        DeckContentType.card,
      );
    },
  );
}

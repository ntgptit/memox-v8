import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/deck/data/datasources/deck_tree_data_source.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/test_database.dart';

// BR-CARD-009 (DEV-220): the flag is not content to edit, so an edit never
// writes back the flag its draft was seeded with.

DateTime _t0() => DateTime(2026, 9, 23);
final _later = DateTime(2026, 9, 24);

void main() {
  late AppDatabase db;
  late CardRepositoryImpl cards;
  late DeckEntity nouns;
  setUp(() async {
    db = openTestDatabase();
    final decks = DeckRepositoryImpl(db, now: _t0);
    cards = CardRepositoryImpl(
      db,
      ScheduleRepositoryImpl(db, now: _t0),
      TagRepositoryImpl(db, now: _t0),
      DeckTreeDataSource(db),
      now: _t0,
    );
    final root = await decks.root('Korean');
    nouns = await decks.sub(root.id, 'Nouns');
  });
  tearDown(() => db.close());

  Future<Map<String, Object?>> cardRow(String cardId) async =>
      (await db
              .customSelect(
                'SELECT * FROM card WHERE id = ?',
                variables: [Variable(cardId)],
              )
              .getSingle())
          .data;

  group('editCard (BR-CARD-009)', () {
    test('keeps a flag set while the editor held an older draft '
        '(BR-CARD-009, DEV-220)', () async {
      final card = await cards.card(
        nouns.id,
        const CardDraft(front: 'f', back: 'b'),
      );
      // The system (BR-STUDY-073) or another device sets the flag while the
      // editor, seeded from the unflagged card, is open.
      await cards.setFlagged(cardIds: {card.id}, isFlagged: true);

      final result = await cards.editCard(
        cardId: card.id,
        draft: const CardDraft(front: 'f', back: 'changed'),
        now: _later,
      );

      expect(result, isA<Ok<void, CardRejection>>());
      final row = await cardRow(card.id);
      expect((row['back'], row['is_flagged']), ('changed', 1));
    });
  });
}

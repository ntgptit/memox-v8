import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';

import '../../../support/deck_fixtures.dart';
import '../../../support/test_database.dart';

// The state the card batch write tests share. A fresh database and decks are
// opened in each test by [useBatchWritesFixture]; the files that use it run
// one test at a time, so the state is never shared between two tests.

DateTime _t0() => DateTime(2026, 9, 23);

late AppDatabase db;
late DeckRepositoryImpl decks;
late CardRepositoryImpl cards;
late DeckEntity root;
late DeckEntity nouns;
late DeckEntity verbs;

/// Opens the database and the Korean deck tree before each test, and closes
/// the database after it.
void useBatchWritesFixture() {
  setUp(() async {
    db = openTestDatabase();
    decks = DeckRepositoryImpl(db, now: _t0);
    cards = CardRepositoryImpl(
      db,
      ScheduleRepositoryImpl(db, now: _t0),
      TagRepositoryImpl(db, now: _t0),
      now: _t0,
    );
    root = await decks.root('Korean');
    nouns = await decks.sub(root.id, 'Nouns');
    verbs = await decks.sub(root.id, 'Verbs');
  });
  tearDown(() => db.close());
}

Future<int> count(String table) async =>
    (await db.customSelect('SELECT COUNT(*) AS n FROM $table').getSingle())
        .read<int>('n');

Future<DeckContentType> contentTypeOf(String deckId) async =>
    (await decks.findById(deckId))!.contentType;

Future<Map<String, Object?>> cardRow(String cardId) async =>
    (await db
            .customSelect(
              'SELECT * FROM card WHERE id = ?',
              variables: [Variable(cardId)],
            )
            .getSingle())
        .data;

Future<List<String>> tagNamesOf(String cardId) async => [
  for (final row
      in await db
          .customSelect(
            'SELECT t.name FROM card_tags ct JOIN tags t ON t.id = ct.tag_id '
            'WHERE ct.card_id = ? ORDER BY t.name_folded',
            variables: [Variable(cardId)],
          )
          .get())
    row.read<String>('name'),
];

Future<void> learn(String cardId) => db.customStatement(
  'UPDATE card_schedule SET learned_at = 1, due_at = 2, current_box = 3 '
  'WHERE card_id = ?',
  [cardId],
);

/// A card's stored seconds, as Drift writes a DateTime.
int seconds(DateTime at) => at.millisecondsSinceEpoch ~/ 1000;

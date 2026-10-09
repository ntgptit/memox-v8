import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/data/datasources/card_dao.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/card/data/repositories/card_transfer_repository_impl.dart';
import 'package:memox/features/card/domain/models/card_export_snapshot_model.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/deck/data/datasources/deck_tree_data_source.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';

import '../../../support/deck_fixtures.dart';
import '../../../support/test_database.dart';

// BE-C2: a batch over more ids than SQLite binds in one statement works,
// with the result of a small batch (local backend spec 2026-09-27 §5).

const _many = 33000;

DateTime _now() => DateTime(2026, 9, 27);

/// [_many] live cards in [deckId], ids `c00000`…, created in id order.
Future<Set<String>> _seed(AppDatabase db, String deckId) async {
  await db.customStatement(
    'WITH RECURSIVE n(i) AS (SELECT 0 UNION ALL SELECT i + 1 FROM n '
    'WHERE i + 1 < ?) '
    'INSERT INTO card (id, deck_id, front, back, front_folded, back_folded, '
    'created_at, updated_at) '
    "SELECT printf('c%05d', i), ?, 'f', 'b', 'f', 'b', i, i FROM n",
    [_many, deckId],
  );
  return {for (var i = 0; i < _many; i++) 'c${'$i'.padLeft(5, '0')}'};
}

void main() {
  late AppDatabase db;
  late CardRepositoryImpl cards;
  late CardDao dao;
  late String from;
  late String to;
  late Set<String> ids;

  setUp(() async {
    db = openTestDatabase();
    final decks = DeckRepositoryImpl(db, now: _now);
    cards = CardRepositoryImpl(
      db,
      ScheduleRepositoryImpl(db, now: _now),
      TagRepositoryImpl(db, now: _now),
      DeckTreeDataSource(db),
      now: _now,
    );
    dao = CardDao(db);
    final root = await decks.root('r');
    from = (await decks.sub(root.id, 'from')).id;
    to = (await decks.sub(root.id, 'to')).id;
    await db.customStatement(
      "UPDATE deck SET content_type = 'card' WHERE id IN (?, ?)",
      [from, to],
    );
    ids = await _seed(db, from);
  });
  tearDown(() => db.close());

  Future<int> count(String sql, [List<Object> args = const []]) async =>
      (await db
              .customSelect(sql, variables: [for (final a in args) Variable(a)])
              .getSingle())
          .read<int>('n');

  test('flagging more cards than SQLite binds flags them all', () async {
    final result = await cards.setFlagged(cardIds: ids, isFlagged: true);

    expect(result, isA<Ok<void, CardRejection>>());
    expect(
      await count('SELECT COUNT(*) AS n FROM card WHERE is_flagged = 1'),
      _many,
    );
  });

  test('moving more cards than SQLite binds moves them all', () async {
    final result = await cards.moveCards(cardIds: ids, targetDeckId: to);

    expect(result, isA<Ok<void, CardRejection>>());
    expect(
      await count('SELECT COUNT(*) AS n FROM card WHERE deck_id = ?', [to]),
      _many,
    );
  });

  test('an export of more cards than SQLite binds keeps created_at order '
      'across the chunks', () async {
    final rows = await dao.exportRows(from, ids);

    expect(rows, hasLength(_many));
    expect([for (final row in rows) row.id], [...ids.toList()..sort()]);
  });

  test('the live rows and root ids of a large set are read whole', () async {
    expect(await dao.liveRows(ids), hasLength(_many));
    expect(await dao.rootIdsOf({from, to}), hasLength(1));
  });

  test('a whole-deck and a selected export of more cards than SQLite binds '
      'carry every card with its tags (BR-TRANSFER-010)', () async {
    final transfer = CardTransferRepositoryImpl(
      db,
      cards,
      DeckRepositoryImpl(db, now: _now),
    );
    await db.customStatement(
      "INSERT INTO tags (id, name, name_folded, created_at) "
      "VALUES ('t', 'Noun', 'noun', 0)",
    );
    await db.customStatement(
      "INSERT INTO card_tags (card_id, tag_id) VALUES ('c32999', 't')",
    );

    for (final scope in [null, ids]) {
      final result = await transfer.exportSnapshot(
        deckId: from,
        cardIds: scope,
      );
      final rows = (result as Ok<CardExportSnapshot, CardRejection>).value.rows;

      expect(rows, hasLength(_many), reason: '$scope');
      expect(rows.last.tagNames, ['Noun'], reason: '$scope');
    }
  });
}

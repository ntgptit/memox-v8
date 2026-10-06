import 'dart:io';

import 'package:drift/drift.dart' show QueryRow, Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/search/data/datasources/search_dao.dart';

import '../../../support/test_database.dart';

/// DEV-209: the cost of the card statement at 10k cards, a third of them
/// tagged, against the statement before it (two correlated subqueries per
/// card, kept here as text). Both must find the same hits with the same
/// tags. Timings print for the ledger; the ratio is asserted only when
/// `MEMOX_PROBE=1`, so a slow machine cannot fail the suite.
const _cards = 10000;
const _tags = 300;

const _before = """
WITH hits AS (
  SELECT c.id, c.deck_id, c.front, c.back, c.front_folded, c.created_at,
    CASE WHEN c.front_folded = ?1 THEN 0
      WHEN instr(c.front_folded, ?1) = 1 THEN 1
      WHEN instr(c.front_folded, ?1) > 0 THEN 2 ELSE 3 END AS front_tier,
    CASE WHEN c.back_folded = ?1 THEN 0
      WHEN instr(c.back_folded, ?1) = 1 THEN 1
      WHEN instr(c.back_folded, ?1) > 0 THEN 2 ELSE 3 END AS back_tier,
    COALESCE((
      SELECT MIN(CASE WHEN t.name_folded = ?1 THEN 0
        WHEN instr(t.name_folded, ?1) = 1 THEN 1
        WHEN instr(t.name_folded, ?1) > 0 THEN 2 ELSE 3 END)
      FROM card_tags ct JOIN tags t ON t.id = ct.tag_id
      WHERE ct.card_id = c.id), 3) AS tag_tier,
    (SELECT t.name FROM card_tags ct JOIN tags t ON t.id = ct.tag_id
     WHERE ct.card_id = c.id AND instr(t.name_folded, ?1) > 0
     ORDER BY CASE WHEN t.name_folded = ?1 THEN 0
       WHEN instr(t.name_folded, ?1) = 1 THEN 1
       WHEN instr(t.name_folded, ?1) > 0 THEN 2 ELSE 3 END,
       t.name_folded, t.id
     LIMIT 1) AS tag_name
  FROM card c JOIN deck k ON k.id = c.deck_id
  WHERE c.delete_batch_id IS NULL AND k.delete_batch_id IS NULL),
tiered AS (SELECT hits.*, MIN(front_tier, back_tier, tag_tier) AS tier FROM hits)
SELECT id, deck_id, front, back, front_folded, created_at, front_tier,
  back_tier, tier, tag_name
FROM tiered WHERE tier < 3
ORDER BY tier, front_folded, created_at, id
""";

Future<void> _seed(AppDatabase db) => db.transaction(() async {
  await db.customStatement(
    "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, scheduler_type, "
    "scheduler_version, generation, sibling_position, created_at, updated_at) "
    "VALUES ('R', 'r', NULL, 'R', 1, 'deck', 'sm2', 1, 1, 0, 0, 0)",
  );
  for (var t = 0; t < _tags; t++) {
    // Every fifth tag holds the term; the rest do not.
    final name = t % 5 == 0 ? 'học $t' : 'tag $t';
    await db.customStatement(
      'INSERT INTO tags (id, name, name_folded, created_at) VALUES (?, ?, ?, 0)',
      ['T$t', name, name],
    );
  }
  for (var i = 0; i < _cards; i++) {
    await db.customStatement(
      'INSERT INTO card (id, deck_id, front, back, created_at, updated_at) '
      "VALUES (?, 'R', ?, ?, ?, 0)",
      ['K$i', 'front $i', 'back $i', i],
    );
    if (i % 3 == 0) {
      await db.customStatement(
        'INSERT INTO card_tags (card_id, tag_id) VALUES (?, ?)',
        ['K$i', 'T${i % _tags}'],
      );
    }
  }
});

Future<Duration> _time(Future<void> Function() run) async {
  await run(); // warm
  final watch = Stopwatch()..start();
  for (var i = 0; i < 5; i++) {
    await run();
  }
  return watch.elapsed ~/ 5;
}

void main() {
  test('the tag side of the card statement costs a fraction of before, for '
      'the same hits (DEV-209)', () async {
    final db = openTestDatabase();
    addTearDown(db.close);
    await _seed(db);
    final dao = SearchDao(db);
    Future<List<QueryRow>> before({int? limit}) => db
        .customSelect(
          limit == null ? _before : '$_before LIMIT $limit',
          variables: [const Variable('học')],
        )
        .get();

    // Timed as the app reads: one page of searchPageSize rows, so the rows'
    // mapping, the same on both sides, does not hide the statements' cost.
    final beforeMs = await _time(() => before(limit: 50));
    // The generated statement, mapped as the old one is: rows, not records.
    final afterMs = await _time(
      () => dao
          .searchCardHits(
            'học',
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            50,
          )
          .get(),
    );
    final scanMs = await _time(
      () => db
          .customSelect(
            'SELECT c.id FROM card c WHERE c.delete_batch_id IS NULL AND '
            '(instr(c.front_folded, ?1) > 0 OR instr(c.back_folded, ?1) > 0)',
            variables: [const Variable('học')],
          )
          .get(),
    );
    final hits = await dao.cardHits(term: 'học');
    final old = await before();

    stdout.writeln(
      'DEV-209 probe ($_cards cards, 1/3 tagged, a page of 50): before '
      '${beforeMs.inMicroseconds / 1000} ms, after '
      '${afterMs.inMicroseconds / 1000} ms (face scan alone '
      '${scanMs.inMicroseconds / 1000} ms), ${hits.length} hits',
    );
    expect(hits, isNotEmpty);
    expect(
      [for (final h in hits) (h.id, h.tagName)],
      [for (final r in old) (r.read<String>('id'), r.data['tag_name'])],
    );
    if (Platform.environment['MEMOX_PROBE'] != '1') return;
    expect(afterMs * 3 <= beforeMs, isTrue, reason: 'three times faster');
  });
}

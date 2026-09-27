import 'package:drift/drift.dart';
import 'package:memox/core/text/folded_text.dart';
import 'package:memox/core/text/stored_text.dart';

// Migration v3 → v4 (BE-C5, local backend spec 2026-09-27 §4). Released
// once, then never changed. Raw SQL only: a step never calls application
// queries (.claude/skills/flutter-drift/references/migrations.md).

/// Puts every user text in its stored form (trimmed, NFC), recomputes the
/// folded columns from it, and merges tags that become one name. A row
/// already in that form is not written.
///
/// Decks and cards are read [pageSize] rows at a time, by `id`, so a large
/// library upgrades in bounded memory. Tags are read whole: the merge needs
/// every tag in age order, and a tag is only its name.
Future<void> normalizeStoredText(
  DatabaseConnectionUser db, {
  int pageSize = 1000,
}) async {
  await _normalizeDecks(db, pageSize);
  await _normalizeCards(db, pageSize);
  await _normalizeTags(db);
}

/// The rows of `SELECT [columns] FROM [table]`, [pageSize] at a time in `id`
/// order. A step rewrites text, never an id, so the cursor stays valid.
Stream<QueryRow> _pages(
  DatabaseConnectionUser db,
  String table,
  String columns,
  int pageSize,
) async* {
  var after = '';
  while (true) {
    final page = await db
        .customSelect(
          'SELECT $columns FROM $table WHERE id > ? ORDER BY id LIMIT ?',
          variables: [Variable<String>(after), Variable<int>(pageSize)],
        )
        .get();
    yield* Stream.fromIterable(page);
    if (page.length < pageSize) return;
    after = page.last.read<String>('id');
  }
}

Future<void> _normalizeDecks(DatabaseConnectionUser db, int pageSize) async {
  await for (final row in _pages(db, 'deck', 'id, name', pageSize)) {
    final name = row.read<String>('name');
    final stored = storedText(name);
    if (stored == name) continue;
    await db.customStatement('UPDATE deck SET name = ? WHERE id = ?', [
      stored,
      row.read<String>('id'),
    ]);
  }
}

Future<void> _normalizeCards(DatabaseConnectionUser db, int pageSize) async {
  await for (final row in _pages(
    db,
    'card',
    'id, front, back, front_folded, back_folded, example, hint, pronunciation',
    pageSize,
  )) {
    final front = row.read<String>('front');
    final back = row.read<String>('back');
    final before = <String?>[
      front,
      back,
      row.read<String>('front_folded'),
      row.read<String>('back_folded'),
      row.readNullable<String>('example'),
      row.readNullable<String>('hint'),
      row.readNullable<String>('pronunciation'),
    ];
    final after = <String?>[
      storedText(front),
      storedText(back),
      foldText(front),
      foldText(back),
      storedTextOrNull(before[4]),
      storedTextOrNull(before[5]),
      storedTextOrNull(before[6]),
    ];
    if (_same(before, after)) continue;
    await db.customStatement(
      'UPDATE card SET front = ?, back = ?, front_folded = ?, '
      'back_folded = ?, example = ?, hint = ?, pronunciation = ? '
      'WHERE id = ?',
      [...after, row.read<String>('id')],
    );
  }
}

/// Tags group by owner and new folded name. The oldest of a group (by
/// `created_at`, then `id`) keeps its id and takes every link of the
/// others, which are then deleted: the semantics of a rename that merges
/// (BR-TAG-007). The folded values change in two phases, so no intermediate
/// state trips the unique index.
Future<void> _normalizeTags(DatabaseConnectionUser db) async {
  final tags = await db
      .customSelect(
        'SELECT id, name, name_folded, owner_id FROM tags '
        'ORDER BY created_at, id',
      )
      .get();
  final keptByKey = <String, String>{};
  final updates = <String, ({String name, String folded})>{};
  for (final row in tags) {
    final id = row.read<String>('id');
    final name = row.read<String>('name');
    final folded = foldText(name);
    final key = '${row.readNullable<String>('owner_id') ?? ''}\u0000$folded';
    final kept = keptByKey[key];
    if (kept != null) {
      await db.customStatement(
        'INSERT OR IGNORE INTO card_tags (card_id, tag_id) '
        'SELECT card_id, ? FROM card_tags WHERE tag_id = ?',
        [kept, id],
      );
      // Foreign keys are off while a migration runs (they are switched on
      // in beforeOpen), so the tag's links go explicitly, not by cascade.
      await db.customStatement('DELETE FROM card_tags WHERE tag_id = ?', [id]);
      await db.customStatement('DELETE FROM tags WHERE id = ?', [id]);
      continue;
    }
    keptByKey[key] = id;
    final stored = storedText(name);
    if (stored != name || folded != row.read<String>('name_folded')) {
      updates[id] = (name: stored, folded: folded);
    }
  }
  // Phase 1: move every changing folded value out of the way.
  for (final id in updates.keys) {
    await db.customStatement(
      'UPDATE tags SET name_folded = char(0) || id WHERE id = ?',
      [id],
    );
  }
  // Phase 2: set the final values, now unique by construction.
  for (final MapEntry(key: id, value: (:name, :folded)) in updates.entries) {
    await db.customStatement(
      'UPDATE tags SET name = ?, name_folded = ? WHERE id = ?',
      [name, folded, id],
    );
  }
}

bool _same(List<String?> a, List<String?> b) {
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

import 'package:characters/characters.dart';
import 'package:drift/drift.dart';

// Migration v17 → v18 (deck name 32 spec 2026-10-21 §5). Released once,
// then never changed. Raw SQL only: a step never calls application
// queries (.claude/skills/flutter-drift/references/migrations.md).

/// BR-DECK-020's bounds as v18 ships them, copied so this step never moves
/// when the rule does.
const _maxCharacters = 32;
const _maxCodePoints = 128;

/// A deck name the step shortened.
typedef DeckNameCut = ({String id, String from, String to});

/// Cuts every deck name over BR-DECK-020's bounds (Trash included) to its
/// longest start of whole characters within both, trimmed at its end, and
/// stamps `updated_at` with [now]; the capture trigger queues each for sync.
/// A stored name starts with a non-space, so a cut is never blank.
///
/// Decks are read [pageSize] rows at a time, by `id`, so a large library
/// upgrades in bounded memory.
Future<List<DeckNameCut>> shortenDeckNames(
  DatabaseConnectionUser db, {
  required DateTime now,
  int pageSize = 1000,
}) async {
  final cuts = <DeckNameCut>[];
  var after = '';
  while (true) {
    final page = await db
        .customSelect(
          'SELECT id, name FROM deck WHERE id > ? ORDER BY id LIMIT ?',
          variables: [Variable<String>(after), Variable<int>(pageSize)],
        )
        .get();
    for (final row in page) {
      final name = row.read<String>('name');
      final cut = _cut(name);
      if (cut == name) continue;
      final id = row.read<String>('id');
      await db.customUpdate(
        'UPDATE deck SET name = ?, updated_at = ? WHERE id = ?',
        variables: [
          Variable<String>(cut),
          Variable<DateTime>(now),
          Variable<String>(id),
        ],
      );
      cuts.add((id: id, from: name, to: cut));
    }
    if (page.length < pageSize) return cuts;
    after = page.last.read<String>('id');
  }
}

/// The longest start of whole characters of [name] within both bounds.
String _cut(String name) {
  final kept = StringBuffer();
  var count = 0;
  var codePoints = 0;
  for (final character in name.characters) {
    final size = character.runes.length;
    if (count == _maxCharacters || codePoints + size > _maxCodePoints) break;
    kept.write(character);
    count++;
    codePoints += size;
  }
  return kept.toString().trimRight();
}

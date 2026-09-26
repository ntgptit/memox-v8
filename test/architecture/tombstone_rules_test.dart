import 'package:flutter_test/flutter_test.dart';

import 'tombstone_rules.dart';

/// [sql] as a DAO holds it, in [member] of `lib/x_dao.dart`.
Map<String, String> _dao(String sql, {String member = 'read'}) => {
  'lib/x_dao.dart':
      'final class XDao {\n'
      '  Future<void> $member() => _db.customSelect(\n'
      "    '$sql',\n"
      '  );\n'
      '}\n',
};

void main() {
  group('SQL in Dart', () {
    test('a read of card without the filter is a violation', () {
      final sources = _dao('SELECT id FROM card WHERE id = ?');

      expect(tombstoneViolations(sources, {}), ['lib/x_dao.dart#read: card']);
    });

    test('a read that names delete_batch_id passes', () {
      final sources = _dao(
        'SELECT id FROM card WHERE id = ? AND delete_batch_id IS NULL',
      );

      expect(tombstoneViolations(sources, {}), isEmpty);
    });

    test('each aliased table needs its own filter', () {
      final sources = _dao(
        'SELECT c.id FROM card c JOIN deck d ON d.id = c.deck_id'
        ' WHERE c.delete_batch_id IS NULL',
      );

      expect(tombstoneViolations(sources, {}), ['lib/x_dao.dart#read: deck d']);
    });

    test('card_schedule and card_tags are other tables', () {
      final sources = _dao(
        'SELECT s.card_id FROM card_schedule s JOIN card_tags t'
        ' ON t.card_id = s.card_id',
      );

      expect(tableStatements(sources), isEmpty);
    });

    test('adjacent literals make one statement, an interpolation with its '
        'own quotes included', () {
      const source = r'''
final _hits =
    'SELECT c.id FROM card c'
    ' WHERE ${_live('c')} AND c.front = ?';
''';

      expect(stringGroups(source).map((group) => group.text), [
        r"SELECT c.id FROM card c WHERE ${_live('c')} AND c.front = ?",
      ]);
    });

    test('a statement belongs to the member it is written in', () {
      const source = r'''
final _top = 'SELECT id FROM deck';

final class XDao {
  Future<List<String>> first(String id) async {
    final rows = await _db.customSelect('SELECT id FROM card');
    return rows;
  }

  Stream<int> second() => _db.customSelect('SELECT id FROM deck d');
}
''';

      expect(
        [for (final s in dartStatements('lib/x_dao.dart', source)) s.member],
        ['_top', 'first', 'second'],
      );
    });
  });

  group('the query builder', () {
    Map<String, String> builder(String call) => {
      'lib/x_dao.dart':
          'final class XDao {\n'
          '  Future<void> read(String id) => $call;\n'
          '}\n',
    };

    test('a read without deleteBatchId is a violation', () {
      final sources = builder(
        '(_db.select(_db.card)..where((card) => card.id.equals(id))).get()',
      );

      expect(tombstoneViolations(sources, {}), [
        'lib/x_dao.dart#read: query builder',
      ]);
    });

    test('a read with deleteBatchId passes', () {
      final sources = builder(
        '(_db.select(_db.card)..where((card) => '
        'card.id.equals(id) & card.deleteBatchId.isNull())).get()',
      );

      expect(tombstoneViolations(sources, {}), isEmpty);
    });

    test('a write addressed by its id passes: its reads checked the row', () {
      final sources = builder(
        '(_db.update(_db.deck)..where((deck) => deck.id.equals(id)))'
        '.write(row)',
      );

      expect(tombstoneViolations(sources, {}), isEmpty);
    });
  });

  group('drift files', () {
    test('a named query is named by its name; comments do not count', () {
      const source = '''
import '../tables/deck.drift';

-- The names, FROM deck.
deckNames(:id AS TEXT) AS DeckNameRow:
SELECT d.name FROM deck d WHERE d.id = :id;
''';

      expect(tombstoneViolations({'lib/q.drift': source}, {}), [
        'lib/q.drift#deckNames: deck d',
      ]);
    });

    test("a trigger is named by its own name, with its BEGIN … END", () {
      const source = '''
CREATE TRIGGER t_no_delete BEFORE DELETE ON review_log
BEGIN
  SELECT RAISE(ABORT, 'no') WHERE EXISTS (SELECT 1 FROM card WHERE id = 1);
END;
''';

      expect(tombstoneViolations({'lib/t.drift': source}, {}), [
        'lib/t.drift#t_no_delete: card',
      ]);
    });

    test('tables and indexes read nothing', () {
      const source = '''
CREATE TABLE x (deck_id TEXT REFERENCES deck (id));
CREATE INDEX idx_x ON x (deck_id);
''';

      expect(tableStatements({'lib/t.drift': source}), isEmpty);
    });
  });

  group('the allowlist', () {
    final sources = _dao('SELECT id FROM card', member: 'everything');
    const entry = 'lib/x_dao.dart#everything';

    test('an allowlisted statement passes, and its entry excuses it', () {
      final allowlist = {entry: 'reads the tombstones on purpose'};

      expect(tombstoneViolations(sources, allowlist), isEmpty);
      expect(staleAllowlistEntries(sources, allowlist), isEmpty);
    });

    test('an entry that names no statement is stale', () {
      expect(
        staleAllowlistEntries(sources, {entry: 'x', 'lib/y.dart#z': 'x'}),
        ['lib/y.dart#z'],
      );
    });

    test('an entry whose statement is filtered now is stale', () {
      final filtered = _dao(
        'SELECT id FROM card WHERE delete_batch_id IS NULL',
        member: 'everything',
      );

      expect(staleAllowlistEntries(filtered, {entry: 'x'}), [entry]);
    });
  });
}

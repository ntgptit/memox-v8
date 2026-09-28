import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';

import 'generated/schema.dart';

// BE-C5: v4 → v5 puts the store in NFC, recomputes the folded columns and
// merges tags that become one name (local backend spec 2026-09-27 §4). Its
// deck-name rewrites run under sync's capture triggers (ADR-013).

void main() {
  late SchemaVerifier verifier;
  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  group('a v4 database with text in mixed Unicode forms (BE-C5)', () {
    late AppDatabase db;
    late Map<String, Object?> untouchedCard;

    setUp(() async {
      final schema = await verifier.schemaAt(4);
      final raw = schema.rawDatabase;
      for (final statement in [
        "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, scheduler_type, scheduler_version, generation, sibling_position, created_at, updated_at) VALUES ('R', 'Tiếng Việt', NULL, 'R', 1, 'deck', 'eight_box', 1, 1, 0, 0, 0)",
        "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, sibling_position, created_at, updated_at) VALUES ('L', 'Bài 1', 'R', 'R', 2, 'card', 0, 0, 0)",
        "INSERT INTO card (id, deck_id, front, back, front_folded, back_folded, example, hint, pronunciation, created_at, updated_at) VALUES "
            "('d', 'L', 'Công', '밥', 'công', '밥', 'việc', NULL, NULL, 1, 1), "
            "('n', 'L', 'công', 'work', 'công', 'work', NULL, NULL, NULL, 2, 2)",
        // Three tags that are one name once in NFC; 't-old' is the oldest.
        // 't-new' also carries a stale fold (a trailing space).
        "INSERT INTO tags (id, name, name_folded, created_at) VALUES "
            "('t-old', 'Công việc', 'công việc', 10), "
            "('t-mid', 'Công việc', 'công việc', 20), "
            "('t-new', 'CÔNG VIỆC', 'công việc ', 30), "
            "('t-solo', 'Hàn', 'hàn', 40)",
        // 'd' carries two of the colliding tags; 'n' the newest only.
        "INSERT INTO card_tags (card_id, tag_id) VALUES ('d', 't-old'), ('d', 't-mid'), ('n', 't-new'), ('n', 't-solo')",
      ]) {
        raw.execute(statement);
      }
      // As if every row were acknowledged: only what v5 rewrites is queued.
      raw.execute('DELETE FROM sync_outbox');
      untouchedCard = {
        ...raw.select("SELECT * FROM card WHERE id = 'n'").single,
      };
      db = AppDatabase(schema.newConnection());
      await verifier.migrateAndValidate(db, 5);
    });
    tearDown(() => db.close());

    Future<List<Map<String, Object?>>> rows(String sql) async => [
      for (final row in await db.customSelect(sql).get()) row.data,
    ];

    test(
      'user text is stored in NFC and the folded columns are recomputed',
      () async {
        expect(await rows("SELECT name FROM deck WHERE id = 'R'"), [
          {'name': 'Tiếng Việt'},
        ]);
        expect(
          await rows(
            'SELECT front, back, front_folded, back_folded, example FROM card '
            "WHERE id = 'd'",
          ),
          [
            {
              'front': 'Công',
              'back': '밥',
              'front_folded': 'công',
              'back_folded': '밥',
              'example': 'việc',
            },
          ],
        );
        expect(
          await rows("SELECT name, name_folded FROM tags WHERE id = 't-solo'"),
          [
            {'name': 'Hàn', 'name_folded': 'hàn'},
          ],
        );
      },
    );

    test('a deck whose name v5 rewrites is queued for sync, and a deck '
        'already in NFC is not (ADR-013)', () async {
      expect(
        await rows(
          "SELECT entity_type, entity_id, op FROM sync_outbox ORDER BY entity_id",
        ),
        [
          {'entity_type': 'deck', 'entity_id': 'R', 'op': 'upsert'},
        ],
      );
    });

    test('a row already in NFC is not written, updated_at included', () async {
      expect(
        (await rows("SELECT * FROM card WHERE id = 'n'")).single,
        untouchedCard,
      );
    });

    test(
      'colliding tags merge into the oldest, keeping every card link once',
      () async {
        expect(
          await rows('SELECT id, name, name_folded FROM tags ORDER BY id'),
          [
            {'id': 't-old', 'name': 'Công việc', 'name_folded': 'công việc'},
            {'id': 't-solo', 'name': 'Hàn', 'name_folded': 'hàn'},
          ],
        );
        expect(
          await rows(
            'SELECT card_id, tag_id FROM card_tags ORDER BY card_id, tag_id',
          ),
          [
            {'card_id': 'd', 'tag_id': 't-old'},
            {'card_id': 'n', 'tag_id': 't-old'},
            {'card_id': 'n', 'tag_id': 't-solo'},
          ],
        );
      },
    );

    test('passes the integrity and foreign key checks', () async {
      final integrity = await db.customSelect('PRAGMA integrity_check').get();
      expect([for (final row in integrity) row.data.values.single], ['ok']);
      expect(await db.customSelect('PRAGMA foreign_key_check').get(), isEmpty);
    });
  });

  test('two tags whose folded values swap do not trip the unique index '
      '(BE-C5)', () async {
    final schema = await verifier.schemaAt(4);
    // 'a' re-folds to the value 'b' holds, and 'b' re-folds to another.
    schema.rawDatabase.execute(
      'INSERT INTO tags (id, name, name_folded, created_at) VALUES '
      "('a', 'É', 'x', 1), ('b', 'X', 'é', 2)",
    );
    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 9);

    final tags = await db
        .customSelect('SELECT id, name, name_folded FROM tags ORDER BY id')
        .get();
    expect(
      [for (final row in tags) row.data],
      [
        {'id': 'a', 'name': 'É', 'name_folded': 'é'},
        {'id': 'b', 'name': 'X', 'name_folded': 'x'},
      ],
    );
  });
}

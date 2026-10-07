import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:sqlite3/sqlite3.dart' show Database, SqliteException;

import 'generated/schema.dart';

// DEV-194: a migration is atomic (.claude/skills/flutter-drift/references/
// migrations.md). A step that stops halfway, here because one of its
// statements fails, leaves the database at the version it had, with nothing
// of the next one; once the cause is gone the next open upgrades it whole.
// Drift runs the statements of a migration past any interceptor, so the stop
// is planted in the database: an object the step wants to create already
// exists.

int _userVersion(Database raw) =>
    raw.select('PRAGMA user_version').first.values.single! as int;

List<String> _objects(Database raw, String type) => [
  for (final row in raw.select(
    'SELECT name FROM sqlite_master WHERE type = ? ORDER BY name',
    [type],
  ))
    row['name'] as String,
];

List<String> _columns(Database raw, String table) => [
  for (final row in raw.select('PRAGMA table_info($table)'))
    row['name'] as String,
];

void main() {
  late SchemaVerifier verifier;
  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  /// Opens [schema] with the current build; the upgrade stops at the planted
  /// statement.
  Future<void> openAndStop(InitializedSchema schema) async {
    final db = AppDatabase(schema.newConnection());
    await expectLater(
      db.customSelect('SELECT 1').get(),
      throwsA(isA<SqliteException>()),
    );
    await db.close();
  }

  test(
    'stopping between the tables and the triggers of v4 leaves v3 whole, and '
    'the next open upgrades it',
    () async {
      final schema = await verifier.schemaAt(3);
      final raw = schema.rawDatabase
        ..execute(
          "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, scheduler_type, "
          "scheduler_version, generation, sibling_position, created_at, updated_at) "
          "VALUES ('R', 'r', NULL, 'R', 1, 'deck', 'eight_box', 1, 1, 0, 0, 0)",
        )
        // from3To4 creates the trigger of this name after its tables and
        // columns; it fails there.
        ..execute(
          'CREATE TRIGGER deck_sync_insert AFTER INSERT ON deck BEGIN SELECT 1; END',
        );

      await openAndStop(schema);

      expect(_userVersion(raw), 3);
      expect(_objects(raw, 'table'), isNot(contains('sync_outbox')));
      expect(_objects(raw, 'table'), isNot(contains('sync_state')));
      expect(_columns(raw, 'deck'), isNot(contains('server_version')));
      expect(
        _columns(raw, 'delete_batches'),
        isNot(contains('server_version')),
      );
      // v3's own triggers and the planted one; none of v4's.
      expect(
        _objects(raw, 'trigger').where((name) => name.contains('_sync_')),
        ['deck_sync_insert'],
      );

      raw.execute('DROP TRIGGER deck_sync_insert');
      final db = AppDatabase(schema.newConnection());
      addTearDown(db.close);
      await verifier.migrateAndValidate(db, 16);
      final queued = await db
          .customSelect(
            "SELECT entity_id FROM sync_outbox WHERE entity_type = 'deck'",
          )
          .get();
      expect(queued.map((r) => r.read<String>('entity_id')), ['R']);
    },
  );

  test(
    'stopping between the two seeds of v10 leaves v9 whole, and the next open '
    'queues the schedule and the review once',
    () async {
      final schema = await verifier.schemaAt(9);
      final raw = schema.rawDatabase
        ..execute(
          "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, scheduler_type, "
          "scheduler_version, generation, sibling_position, created_at, updated_at) "
          "VALUES ('R', 'r', NULL, 'R', 1, 'deck', 'eight_box', 1, 1, 0, 0, 0)",
        )
        ..execute(
          "INSERT INTO card (id, deck_id, front, back, created_at, updated_at) VALUES ('K', 'R', 'f', 'b', 0, 0)",
        )
        ..execute(
          "INSERT INTO card_schedule (card_id, scheduler_type, scheduler_version, generation, "
          "answer_count, lapse_count, current_box) VALUES ('K', 'eight_box', 1, 1, 0, 0, 1)",
        )
        ..execute(
          "INSERT INTO review_log (id, card_id, session_id, scheduler_type, generation, kind, mode, "
          "\"action\", answered_at) VALUES ('V', 'K', 's', 'eight_box', 1, 'learning', 'self_assess', 'remembered', 1)",
        )
        ..execute('DELETE FROM sync_outbox')
        // from9To10 seeds the schedules, then the reviews; the second seed
        // fails on this row (UNIQUE entity_type, entity_id).
        ..execute(
          "INSERT INTO sync_outbox (op_id, entity_type, entity_id, op, created_at) "
          "VALUES ('planted', 'review_log', 'V', 'upsert', 0)",
        );

      await openAndStop(schema);

      expect(_userVersion(raw), 9);
      expect(
        [
          for (final row in raw.select('SELECT op_id FROM sync_outbox'))
            row['op_id'],
        ],
        ['planted'],
      );
      final triggers = _objects(raw, 'trigger');
      expect(triggers, isNot(contains('review_log_sync_insert')));
      expect(triggers, isNot(contains('card_schedule_sync_insert')));
      expect(triggers, isNot(contains('card_schedule_sync_update')));

      raw.execute("DELETE FROM sync_outbox WHERE op_id = 'planted'");
      final db = AppDatabase(schema.newConnection());
      addTearDown(db.close);
      await verifier.migrateAndValidate(db, 16);
      final queued = await db
          .customSelect(
            'SELECT entity_type, entity_id FROM sync_outbox ORDER BY rowid',
          )
          .get();
      expect(
        queued.map(
          (r) =>
              '${r.read<String>('entity_type')}/${r.read<String>('entity_id')}',
        ),
        ['card_schedule/K', 'review_log/V'],
      );
    },
  );
}

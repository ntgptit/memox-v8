import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';

import 'generated/schema.dart';

// DEV-228: an upgrade keeps the sync state of a device whole: what it has not
// sent yet (the outbox, with each entry's op_id, created_at and attempts),
// what the server acknowledged (server_version), what it refused
// (sync_rejection) and where it stands (sync_state). The fixture starts at
// the last released version (`_releasedVersion`, raised at every release)
// and upgrades to the current one; a new step that rebuilds a table without
// server_version, or seeds the outbox again, fails here and nowhere else
// (.claude/skills/flutter-drift/references/migrations.md).

/// The schema version of the last release.
const _releasedVersion = 11;

/// The tables of the sync state, each read whole and compared as values.
const _syncTables = ['sync_outbox', 'sync_state', 'sync_rejection'];

/// A row as text, its columns in name order.
String _canonical(Map<String, Object?> row) =>
    ([...row.keys]..sort()).map((column) => '$column=${row[column]}').join('|');

List<String> _values(Iterable<Map<String, Object?>> rows) =>
    [for (final row in rows) _canonical(row)]..sort();

void main() {
  late SchemaVerifier verifier;
  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  late AppDatabase db;
  late Map<String, List<String>> before;

  setUp(() async {
    final schema = await verifier.schemaAt(_releasedVersion);
    final raw = schema.rawDatabase;
    // The library: two decks and two cards the server acknowledged, one deck
    // changed since, one card deleted since. The triggers queue these writes;
    // the outbox is then set to what the device really holds.
    raw
      ..execute(
        "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, scheduler_type, "
        "scheduler_version, generation, sibling_position, server_version, created_at, updated_at) "
        "VALUES ('R', 'Korean', NULL, 'R', 1, 'deck', 'eight_box', 1, 1, 0, 5, 0, 0)",
      )
      ..execute(
        "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, sibling_position, "
        "server_version, created_at, updated_at) "
        "VALUES ('R1', 'Food', 'R', 'R', 2, 'card', 0, 7, 0, 9)",
      )
      ..execute(
        "INSERT INTO card (id, deck_id, front, back, server_version, created_at, updated_at) "
        "VALUES ('k1', 'R1', '밥', 'Cơm', 5, 1, 1), ('k2', 'R1', '물', 'Nước', 7, 2, 2)",
      )
      ..execute('DELETE FROM sync_outbox')
      ..execute(
        "INSERT INTO sync_outbox (op_id, entity_type, entity_id, op, created_at, attempts) "
        "VALUES ('op-deck-r1', 'deck', 'R1', 'upsert', 9, 2), "
        "('op-card-k3', 'card', 'k3', 'delete', 10, 0)",
      )
      ..execute(
        "INSERT INTO sync_rejection (entity_type, entity_id, code, rejected_at) "
        "VALUES ('card', 'k2', 'invalid_payload', 8)",
      )
      ..execute(
        "INSERT INTO sync_state (name, value) VALUES "
        "('since', '42'), ('device_id', 'device-a'), "
        "('pull_entity_types', 'deck,card'), ('last_success_at', '2026-10-01T00:00:00Z')",
      );
    before = {
      for (final table in _syncTables)
        table: _values(raw.select('SELECT * FROM $table')),
      'server_version': _values(
        raw.select(
          "SELECT 'deck' AS t, id, server_version FROM deck "
          "UNION ALL SELECT 'card', id, server_version FROM card",
        ),
      ),
    };
    db = AppDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, db.schemaVersion);
  });
  tearDown(() => db.close());

  test('keeps every outbox entry, state and rejection row as it was', () async {
    for (final table in _syncTables) {
      final after = await db.customSelect('SELECT * FROM $table').get();
      expect(
        _values([for (final row in after) row.data]),
        before[table],
        reason: table,
      );
    }
    expect(before['sync_outbox'], hasLength(2));
    expect(before['sync_rejection'], hasLength(1));
    expect(before['sync_state'], hasLength(4));
  });

  test('keeps the acknowledged version of every deck and card', () async {
    final after = await db
        .customSelect(
          "SELECT 'deck' AS t, id, server_version FROM deck "
          "UNION ALL SELECT 'card', id, server_version FROM card",
        )
        .get();
    expect(
      _values([for (final row in after) row.data]),
      before['server_version'],
    );
    expect(before['server_version'], hasLength(4));
  });

  test('passes the integrity and foreign key checks', () async {
    final integrity = await db.customSelect('PRAGMA integrity_check').get();
    expect([for (final row in integrity) row.data.values.single], ['ok']);
    expect(await db.customSelect('PRAGMA foreign_key_check').get(), isEmpty);
  });
}

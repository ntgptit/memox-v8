import 'package:characters/characters.dart';
import 'package:drift/drift.dart' show Variable;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/migrations/deck_name_length_migration.dart';
import 'package:memox/core/logging/app_logger.dart';

import '../support/recording_log_sink.dart';
import '../support/test_database.dart';
import 'generated/schema.dart';

// Deck name 32 spec 2026-10-21 §5: v17 → v18 cuts every deck name over
// BR-DECK-020's bounds to its longest start of whole characters within
// them, trimmed; the capture trigger queues each cut, and each is logged.

const _family = '👨‍👩‍👧'; // one character, five code points
const _long = 'Thuật ngữ Kinh tế – Tài chính cho kỳ thi quốc tế'; // 48

String _first32(String name) => name.characters.take(32).toString().trimRight();

/// Each deck of the fixture, by id: its name before and after v18. 'T' sits
/// in the Trash.
final _cases = <String, ({String before, String after})>{
  'L': (before: _long, after: _first32(_long)),
  'E': (before: 'a' * 32, after: 'a' * 32),
  // The 32nd character is a space: the cut is trimmed at its end.
  'S': (before: '${'a' * 31} b', after: 'a' * 31),
  // 30 characters, 150 code points: the 128 ceiling stops it at 25.
  'F': (before: _family * 30, after: _family * 25),
  'T': (before: _long, after: _first32(_long)),
};

void main() {
  late SchemaVerifier verifier;
  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  group('a v17 database with deck names over 32 characters', () {
    late AppDatabase db;
    late RecordingLogSink log;
    late AppLogger previous;

    setUp(() async {
      log = RecordingLogSink();
      previous = appLogger;
      AppLogger.install(AppLogger(sinks: [log]));
      final schema = await verifier.schemaAt(17);
      final raw = schema.rawDatabase;
      raw.execute(
        'INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, '
        'scheduler_type, scheduler_version, generation, sibling_position, '
        "created_at, updated_at) VALUES ('R', 'Root', NULL, 'R', 1, 'deck', "
        "'eight_box', 1, 1, 0, 0, 0)",
      );
      raw.execute(
        'INSERT INTO delete_batches (id, item_type, root_item_id, deleted_at) '
        "VALUES ('B', 'deck', 'T', 0)",
      );
      var position = 1;
      for (final MapEntry(key: id, value: c) in _cases.entries) {
        raw.execute(
          'INSERT INTO deck (id, name, parent_id, root_id, depth, '
          'content_type, sibling_position, created_at, updated_at, '
          "delete_batch_id) VALUES (?, ?, 'R', 'R', 2, 'card', ?, 0, 0, ?)",
          [id, c.before, position++, id == 'T' ? 'B' : null],
        );
      }
      // As if every row were acknowledged: only what v18 cuts is queued.
      raw.execute('DELETE FROM sync_outbox');
      // But E has an edit waiting from before the upgrade: it must come
      // out exactly as it went in (migrations.md, sync state).
      raw.execute(
        'INSERT INTO sync_outbox (op_id, entity_type, entity_id, op, '
        "created_at, attempts) VALUES ('op-E', 'deck', 'E', 'upsert', 7, 2)",
      );
      db = AppDatabase(schema.newConnection());
      await verifier.migrateAndValidate(db, 18);
    });
    tearDown(() async {
      AppLogger.install(previous);
      await db.close();
    });

    for (final MapEntry(key: id, value: c) in _cases.entries) {
      test('$id is "${c.after}" after the upgrade', () async {
        final row = await db
            .customSelect(
              'SELECT name FROM deck WHERE id = ?',
              variables: [Variable<String>(id)],
            )
            .getSingle();
        expect(row.read<String>('name'), c.after);
      });
    }

    test(
      'the upgraded store passes the integrity and foreign key checks',
      () async {
        final integrity = await db.customSelect('PRAGMA integrity_check').get();
        expect(integrity.single.data.values.single, 'ok');
        expect(
          await db.customSelect('PRAGMA foreign_key_check').get(),
          isEmpty,
        );
      },
    );

    test('each cut is queued for sync and logged once; an untouched name is '
        'neither', () async {
      final queued = {
        for (final row
            in await db.customSelect('SELECT entity_id FROM sync_outbox').get())
          row.read<String>('entity_id'),
      };
      expect(queued, {'E', 'L', 'S', 'F', 'T'});
      final pending = await db
          .customSelect(
            "SELECT op_id, attempts, created_at FROM sync_outbox "
            "WHERE entity_id = 'E'",
          )
          .getSingle();
      expect(pending.data, {'op_id': 'op-E', 'attempts': 2, 'created_at': 7});
      final cuts = [
        for (final entry in log.entries)
          if (entry.event == 'db.deck_name_cut') entry,
      ];
      expect(cuts.map((e) => e.context['deckId']).toList()..sort(), [
        'F',
        'L',
        'S',
        'T',
      ]);
      // Kept past the 7 days of an info log, for recovery by hand
      // (ADR-018 §5, final review 2026-10-21).
      expect(cuts.every((e) => e.level == LogLevel.warning), isTrue);
      final cutOfL = cuts.firstWhere((e) => e.context['deckId'] == 'L');
      expect(
        (cutOfL.context['from'], cutOfL.context['to']),
        (_long, _first32(_long)),
      );
    });
  });

  test('a large library is read a page at a time and every page is cut', () async {
    final db = openTestDatabase();
    addTearDown(db.close);
    await db.customStatement(
      'INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, '
      'scheduler_type, scheduler_version, generation, sibling_position, '
      "created_at, updated_at) VALUES ('R', 'Root', NULL, 'R', 1, 'deck', "
      "'eight_box', 1, 1, 0, 0, 0)",
    );
    for (var i = 0; i < 5; i++) {
      await db.customStatement(
        'INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, '
        "sibling_position, created_at, updated_at) VALUES (?, ?, 'R', 'R', 2, "
        "'card', ?, 0, 0)",
        ['c$i', 'x' * 40, i],
      );
    }
    final cuts = await shortenDeckNames(
      db,
      now: DateTime(2026, 10, 21),
      pageSize: 2,
    );
    expect(cuts.map((c) => c.id), ['c0', 'c1', 'c2', 'c3', 'c4']);
    expect(cuts.every((c) => c.to == 'x' * 32), isTrue);
  });
}

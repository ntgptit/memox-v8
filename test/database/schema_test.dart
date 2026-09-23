import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';

import '../support/test_database.dart';

Future<void> _root(
  AppDatabase db,
  String id, {
  String scheduler = 'eight_box',
}) => db.customStatement(
  "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, "
  "scheduler_type, scheduler_version, generation, sibling_position, created_at, updated_at) "
  "VALUES (?, 'r', NULL, ?, 1, 'deck', ?, 1, 1, 0, 0, 0)",
  [id, id, scheduler],
);

Future<void> _child(
  AppDatabase db,
  String id,
  String parent,
  String root,
  int depth, {
  String content = 'unset',
}) => db.customStatement(
  'INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, '
  'sibling_position, created_at, updated_at) '
  "VALUES (?, 'c', ?, ?, ?, ?, 0, 0, 0)",
  [id, parent, root, depth, content],
);

Future<int> _count(AppDatabase db, String table) async {
  final row = await db
      .customSelect('SELECT COUNT(*) AS n FROM $table')
      .getSingle();
  return row.read<int>('n');
}

Future<Failure> _failureOf(Future<void> Function() body) async {
  try {
    await body();
  } catch (e) {
    return mapDatabaseError(e);
  }
  fail('expected the statement to fail');
}

void main() {
  late AppDatabase db;
  setUp(() => db = openTestDatabase());
  tearDown(() => db.close());

  test('foreign keys are enforced', () async {
    final row = await db.customSelect('PRAGMA foreign_keys').getSingle();
    expect(row.read<int>('foreign_keys'), 1);
  });

  test(
    'depth 11 violates a constraint and maps to ConstraintFailure',
    () async {
      await _root(db, 'r');
      final f = await _failureOf(() => _child(db, 'x', 'r', 'r', 11));
      expect(f, isA<ConstraintFailure>());
    },
  );

  test('a constraint error from a background-isolate connection maps to ConstraintFailure', () async {
    // The app opens its database through drift_flutter in a background
    // isolate, where a SqliteException arrives wrapped in DriftRemoteException.
    final dir = await Directory.systemTemp.createTemp('memox_schema_test');
    final background = AppDatabase(
      NativeDatabase.createInBackground(File('${dir.path}/memox.sqlite')),
    );
    addTearDown(() async {
      await background.close();
      await dir.delete(recursive: true);
    });

    await _root(background, 'r');
    final f = await _failureOf(() => _child(background, 'x', 'r', 'r', 11));
    expect(f, isA<ConstraintFailure>());
  });

  test('a sub-deck cannot carry a scheduler', () async {
    await _root(db, 'r');
    final f = await _failureOf(
      () => db.customStatement(
        'INSERT INTO deck (id, name, parent_id, root_id, depth, scheduler_type, '
        'scheduler_version, generation, sibling_position, created_at, updated_at) '
        "VALUES ('s', 'x', 'r', 'r', 2, 'sm2', 1, 1, 0, 0, 0)",
      ),
    );
    expect(f, isA<ConstraintFailure>());
  });

  test('deleting a root cascades to sub-decks, cards, schedules, logs and sessions', () async {
    await _root(db, 'r');
    await _child(db, 's', 'r', 'r', 2, content: 'card');
    await db.customStatement(
      "INSERT INTO card (id, deck_id, front, back, created_at, updated_at) VALUES ('c', 's', 'f', 'b', 0, 0)",
    );
    await db.customStatement(
      "INSERT INTO card_schedule (card_id, scheduler_type, scheduler_version, generation, current_box) "
      "VALUES ('c', 'eight_box', 1, 1, 1)",
    );
    await db.customStatement(
      "INSERT INTO study_session (id, deck_id, root_id, generation, session_kind, current_mode, "
      "status, cursor, card_limit, started_at) VALUES ('ses', 'r', 'r', 1, 'reviewing', 'self_assess', "
      "'in_progress', 0, 20, 0)",
    );
    await db.customStatement(
      "INSERT INTO review_log (id, card_id, session_id, scheduler_type, generation, kind, mode, "
      "action, answered_at) VALUES ('l', 'c', 'ses', 'eight_box', 1, 'scheduled', 'self_assess', 'remembered', 0)",
    );

    await db.customStatement("DELETE FROM deck WHERE id = 'r'");

    for (final table in [
      'deck',
      'card',
      'card_schedule',
      'review_log',
      'study_session',
    ]) {
      expect(await _count(db, table), 0, reason: table);
    }
  });

  test('a schedule row carries exactly one scheduler state', () async {
    await _root(db, 'r');
    await _child(db, 's', 'r', 'r', 2, content: 'card');
    await db.customStatement(
      "INSERT INTO card (id, deck_id, front, back, created_at, updated_at) VALUES ('c', 's', 'f', 'b', 0, 0)",
    );
    final f = await _failureOf(
      () => db.customStatement(
        "INSERT INTO card_schedule (card_id, scheduler_type, scheduler_version, generation, "
        "current_box, ease_factor, interval_days, repetitions) VALUES ('c', 'eight_box', 1, 1, 1, 2.5, 0, 0)",
      ),
    );
    expect(f, isA<ConstraintFailure>());
  });

  test('review_log rejects a direct UPDATE (append-only)', () async {
    await _root(db, 'r');
    await _child(db, 's', 'r', 'r', 2, content: 'card');
    await db.customStatement(
      "INSERT INTO card (id, deck_id, front, back, created_at, updated_at) VALUES ('c', 's', 'f', 'b', 0, 0)",
    );
    await db.customStatement(
      "INSERT INTO study_session (id, deck_id, root_id, generation, session_kind, current_mode, "
      "status, cursor, card_limit, started_at) VALUES ('ses', 'r', 'r', 1, 'reviewing', 'self_assess', "
      "'in_progress', 0, 20, 0)",
    );
    await db.customStatement(
      "INSERT INTO review_log (id, card_id, session_id, scheduler_type, generation, kind, mode, "
      "action, answered_at) VALUES ('l', 'c', 'ses', 'eight_box', 1, 'scheduled', 'self_assess', 'good', 0)",
    );
    await expectLater(
      db.customStatement(
        "UPDATE review_log SET action = 'easy' WHERE id = 'l'",
      ),
      throwsA(anything),
    );
  });

  test('study_session accepts only the valid status x end_reason pairs (invariant 12)', () async {
    await _root(db, 'r');
    Future<void> insert(
      String status,
      String? reason, {
      int? ended,
    }) => db.customStatement(
      "INSERT INTO study_session (id, deck_id, root_id, generation, session_kind, current_mode, "
      "status, end_reason, cursor, card_limit, started_at, ended_at) "
      "VALUES (?, 'r', 'r', 1, 'reviewing', 'self_assess', ?, ?, 0, 20, 0, ?)",
      ['$status-${reason ?? 'none'}', status, reason, ended],
    );

    await insert('in_progress', null);
    await insert('completed', null, ended: 1);
    await insert('abandoned', 'user_exit', ended: 1);
    await insert('invalidated', 'stale_generation', ended: 1);
    await insert('failed', 'persistence_error', ended: 1);

    expect(
      await _failureOf(() => insert('completed', 'user_exit', ended: 1)),
      isA<ConstraintFailure>(),
    );
    expect(
      await _failureOf(() => insert('abandoned', 'stale_generation', ended: 1)),
      isA<ConstraintFailure>(),
    );
    expect(
      await _failureOf(() => insert('in_progress', null, ended: 1)),
      isA<ConstraintFailure>(),
    );
  });

  test('deleting a card or a tag removes its card_tags links', () async {
    await _root(db, 'r');
    await _child(db, 'd', 'r', 'r', 2, content: 'card');
    await db.customStatement(
      "INSERT INTO card (id, deck_id, front, back, created_at, updated_at) "
      "VALUES ('c1', 'd', 'f', 'b', 0, 0), ('c2', 'd', 'f', 'b', 0, 0)",
    );
    await db.customStatement(
      "INSERT INTO tags (id, name, name_folded, created_at) "
      "VALUES ('t1', 'Noun', 'noun', 0), ('t2', 'Verb', 'verb', 0)",
    );
    await db.customStatement(
      "INSERT INTO card_tags (card_id, tag_id) VALUES ('c1', 't1'), ('c2', 't2')",
    );
    await db.customStatement("DELETE FROM card WHERE id = 'c1'");
    await db.customStatement("DELETE FROM tags WHERE id = 't2'");
    expect(await _count(db, 'card_tags'), 0);
  });

  test(
    'a tag name is unique for the local profile (NULL owner) after folding',
    () async {
      await db.customStatement(
        "INSERT INTO tags (id, name, name_folded, created_at) VALUES ('t1', 'Noun', 'noun', 0)",
      );
      final f = await _failureOf(
        () => db.customStatement(
          "INSERT INTO tags (id, name, name_folded, created_at) VALUES ('t2', 'noun', 'noun', 0)",
        ),
      );
      expect(f, isA<ConstraintFailure>());
    },
  );

  test('a tag name is unique per owner after folding', () async {
    await db.customStatement(
      "INSERT INTO tags (id, name, name_folded, owner_id, created_at) "
      "VALUES ('t1', 'Động từ', 'động từ', 'p', 0)",
    );
    final f = await _failureOf(
      () => db.customStatement(
        "INSERT INTO tags (id, name, name_folded, owner_id, created_at) "
        "VALUES ('t2', 'động từ', 'động từ', 'p', 0)",
      ),
    );
    expect(f, isA<ConstraintFailure>());
  });

  test('a snapshot exists for the current schema version', () {
    final snapshot = File(
      'drift_schemas/drift_schema_v${db.schemaVersion}.json',
    );
    expect(
      snapshot.existsSync(),
      isTrue,
      reason: 'run: dart run drift_dev schema dump lib/core/database/app_database.dart drift_schemas/',
    );
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/tables/sync_keys.dart';

import '../support/test_database.dart';

// TOPIK spec 2026-10-15 §7.2, §13.2, BR-TOPIK-026: only a submitted attempt
// reaches the outbox, as one upsert carrying the attempt id; deleting it
// queues a final delete. An attempt in progress and its answers never do.

Future<void> _open(AppDatabase db, String id) async {
  await db.customStatement(
    'INSERT INTO topik_attempt (id, test_id, level, section, round, mode, '
    'status, started_at, updated_at, current_question_no, question_count, '
    "max_score, content_version) VALUES (?, 'T-$id', 'topik2', 'reading', 96, "
    "'practice', 'in_progress', 10, 10, 1, 1, 2, 1)",
    [id],
  );
  await db.customStatement(
    'INSERT INTO topik_attempt_answer (attempt_id, question_no) VALUES (?, 1)',
    [id],
  );
}

Future<void> _submit(AppDatabase db, String id) async {
  await db.customStatement(
    'UPDATE topik_attempt_answer SET correct_idx = 1, points = 2, '
    "points_earned = 0, question_type = 'R2_fill_blank' WHERE attempt_id = ?",
    [id],
  );
  await db.customStatement(
    "UPDATE topik_attempt SET status = 'completed', completed_at = 30, "
    'updated_at = 30, score = 0, correct_count = 0, answered_count = 0 '
    'WHERE id = ?',
    [id],
  );
}

Future<List<(String, String, String)>> _outbox(AppDatabase db) async => [
  for (final row
      in await db
          .customSelect(
            'SELECT entity_type, entity_id, op FROM sync_outbox ORDER BY entity_id',
          )
          .get())
    (
      row.read<String>('entity_type'),
      row.read<String>('entity_id'),
      row.read<String>('op'),
    ),
];

void main() {
  late AppDatabase db;
  setUp(() => db = openTestDatabase());
  tearDown(() => db.close());

  test('an attempt in progress queues nothing, whatever is written', () async {
    await _open(db, 'A');
    await db.customStatement(
      'UPDATE topik_attempt_answer SET selected_idx = 2, answered_at = 11, '
      "time_spent_ms = 900 WHERE attempt_id = 'A'",
    );
    await db.customStatement(
      "UPDATE topik_attempt SET total_time_ms = 900, updated_at = 11 WHERE id = 'A'",
    );
    await db.customStatement("DELETE FROM topik_attempt WHERE id = 'A'");
    expect(await _outbox(db), isEmpty);
  });

  test('submit queues one upsert of the attempt', () async {
    await _open(db, 'A');
    await _submit(db, 'A');
    expect(await _outbox(db), [('topik_attempt', 'A', 'upsert')]);
  });

  test("the server's acknowledgement queues nothing more", () async {
    await _open(db, 'A');
    await _submit(db, 'A');
    await db.customStatement('DELETE FROM sync_outbox');
    await db.customStatement(
      "UPDATE topik_attempt SET server_version = 4 WHERE id = 'A'",
    );
    expect(await _outbox(db), isEmpty);
  });

  test('deleting a submitted attempt queues its delete, replacing a pending '
      'upsert (BR-TOPIK-018)', () async {
    await _open(db, 'A');
    await _submit(db, 'A');
    await db.customStatement("DELETE FROM topik_attempt WHERE id = 'A'");
    expect(await _outbox(db), [('topik_attempt', 'A', 'delete')]);
  });

  test('rows applied from the server queue nothing', () async {
    await db.customStatement(
      'INSERT INTO sync_state (name, value) VALUES (?, ?)',
      [syncApplyingRemoteKey, '1'],
    );
    await _open(db, 'A');
    await _submit(db, 'A');
    await db.customStatement("DELETE FROM topik_attempt WHERE id = 'A'");
    expect(await _outbox(db), isEmpty);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';

import '../support/test_database.dart';

// TOPIK spec 2026-10-15 §13.1: the attempt tables enforce what BR-TOPIK-010,
// BR-TOPIK-011, BR-TOPIK-012 and BR-TOPIK-013 promise, whatever writes them.

Future<void> _openAttempt(AppDatabase db, String id, {String test = 'T'}) =>
    db.customStatement(
      'INSERT INTO topik_attempt (id, test_id, level, section, round, mode, '
      'status, started_at, updated_at, current_question_no, question_count, '
      "max_score, content_version) VALUES (?, ?, 'topik2', 'reading', 96, "
      "'practice', 'in_progress', 10, 10, 1, 2, 4, 1)",
      [id, test],
    );

Future<void> _answers(AppDatabase db, String attemptId) => db.customStatement(
  'INSERT INTO topik_attempt_answer (attempt_id, question_no) '
  'VALUES (?, 1), (?, 2)',
  [attemptId, attemptId],
);

/// Submits [id] as the store does: answers first, then the attempt.
Future<void> _complete(AppDatabase db, String id) async {
  await db.customStatement(
    'UPDATE topik_attempt_answer SET selected_idx = 1, answered_at = 20 '
    'WHERE attempt_id = ? AND question_no = 1',
    [id],
  );
  await db.customStatement(
    'UPDATE topik_attempt_answer SET correct_idx = 1, points = 2, '
    "points_earned = CASE WHEN selected_idx = 1 THEN 2 ELSE 0 END, "
    "question_type = 'R2_fill_blank' WHERE attempt_id = ?",
    [id],
  );
  await db.customStatement(
    "UPDATE topik_attempt SET status = 'completed', completed_at = 30, "
    'updated_at = 30, score = 2, correct_count = 1, answered_count = 1 '
    'WHERE id = ?',
    [id],
  );
}

void main() {
  late AppDatabase db;
  setUp(() => db = openTestDatabase());
  tearDown(() => db.close());

  test('an attempt in progress takes answers, time and moves', () async {
    await _openAttempt(db, 'A');
    await _answers(db, 'A');
    await db.customStatement(
      'UPDATE topik_attempt_answer SET selected_idx = 3, answered_at = 11, '
      "time_spent_ms = 500 WHERE attempt_id = 'A' AND question_no = 2",
    );
    await db.customStatement(
      'UPDATE topik_attempt SET total_time_ms = 500, current_question_no = 2, '
      "updated_at = 11 WHERE id = 'A'",
    );
    expect(await rowCount(db, 'topik_attempt_answer'), 2);
  });

  test('a completed attempt refuses a change to any column but '
      'server_version (BR-TOPIK-010)', () async {
    await _openAttempt(db, 'A');
    await _answers(db, 'A');
    await _complete(db, 'A');
    final columns = [
      for (final row
          in await db.customSelect('PRAGMA table_info(topik_attempt)').get())
        row.read<String>('name'),
    ];
    expect(columns, contains('server_version'));
    for (final column in columns.where((c) => c != 'server_version')) {
      await expectLater(
        db.customStatement(
          'UPDATE topik_attempt SET "$column" = "$column" WHERE id = ?',
          ['A'],
        ),
        throwsA(anything),
        reason: column,
      );
    }
    await db.customStatement(
      "UPDATE topik_attempt SET server_version = 7 WHERE id = 'A'",
    );
  });

  test('the answers of a completed attempt refuse any change', () async {
    await _openAttempt(db, 'A');
    await _answers(db, 'A');
    await _complete(db, 'A');
    await expectLater(
      db.customStatement(
        'UPDATE topik_attempt_answer SET time_spent_ms = 1 '
        "WHERE attempt_id = 'A' AND question_no = 2",
      ),
      throwsA(anything),
    );
  });

  test('deleting an attempt deletes its answers, in progress or completed '
      '(BR-TOPIK-018)', () async {
    await _openAttempt(db, 'A');
    await _answers(db, 'A');
    await _openAttempt(db, 'B', test: 'U');
    await _answers(db, 'B');
    await _complete(db, 'B');

    await db.customStatement(
      "DELETE FROM topik_attempt WHERE id IN ('A', 'B')",
    );

    expect(await rowCount(db, 'topik_attempt_answer'), 0);
  });

  test('a test has at most one attempt in progress (BR-TOPIK-011)', () async {
    await _openAttempt(db, 'A');
    await expectLater(_openAttempt(db, 'B'), throwsA(anything));
    await _answers(db, 'A');
    await _complete(db, 'A');
    await _openAttempt(db, 'B');
    await _answers(db, 'B');
    await _complete(db, 'B');
    expect(await rowCount(db, 'topik_attempt'), 2);
  });

  group('CHECKs refuse', () {
    test('a snapshot on an attempt in progress', () async {
      await expectLater(
        db.customStatement(
          'INSERT INTO topik_attempt (id, test_id, level, section, round, '
          'mode, status, started_at, updated_at, current_question_no, '
          'question_count, max_score, content_version, score) VALUES '
          "('A', 'T', 'topik2', 'reading', 96, 'practice', 'in_progress', 10, "
          '10, 1, 2, 4, 1, 0)',
        ),
        throwsA(anything),
      );
    });

    test('a completed attempt without its snapshot', () async {
      await _openAttempt(db, 'A');
      await expectLater(
        db.customStatement(
          "UPDATE topik_attempt SET status = 'completed' WHERE id = 'A'",
        ),
        throwsA(anything),
      );
    });

    test('a server version on an attempt in progress', () async {
      await _openAttempt(db, 'A');
      await expectLater(
        db.customStatement(
          "UPDATE topik_attempt SET server_version = 1 WHERE id = 'A'",
        ),
        throwsA(anything),
      );
    });

    test('an option outside 1–4', () async {
      await _openAttempt(db, 'A');
      await _answers(db, 'A');
      await expectLater(
        db.customStatement(
          'UPDATE topik_attempt_answer SET selected_idx = 5, answered_at = 1 '
          "WHERE attempt_id = 'A' AND question_no = 1",
        ),
        throwsA(anything),
      );
    });

    test('a choice without its time, or a time without a choice', () async {
      await _openAttempt(db, 'A');
      await _answers(db, 'A');
      await expectLater(
        db.customStatement(
          'UPDATE topik_attempt_answer SET selected_idx = 2 '
          "WHERE attempt_id = 'A' AND question_no = 1",
        ),
        throwsA(anything),
      );
      await expectLater(
        db.customStatement(
          'UPDATE topik_attempt_answer SET answered_at = 1 '
          "WHERE attempt_id = 'A' AND question_no = 1",
        ),
        throwsA(anything),
      );
    });

    test('points earned on a wrong option, or a partial snapshot', () async {
      await _openAttempt(db, 'A');
      await _answers(db, 'A');
      await expectLater(
        db.customStatement(
          'UPDATE topik_attempt_answer SET correct_idx = 1, points = 2, '
          "points_earned = 2, question_type = 'R2_fill_blank' "
          "WHERE attempt_id = 'A' AND question_no = 2",
        ),
        throwsA(anything),
      );
      await expectLater(
        db.customStatement(
          'UPDATE topik_attempt_answer SET correct_idx = 1 '
          "WHERE attempt_id = 'A' AND question_no = 2",
        ),
        throwsA(anything),
      );
    });

    test('an unknown level, section, mode or status', () async {
      const valid = {
        'level': 'topik2',
        'section': 'reading',
        'mode': 'practice',
        'status': 'in_progress',
      };
      const unknown = {
        'level': 'topik3',
        'section': 'writing',
        'mode': 'exam',
        'status': 'paused',
      };
      for (final column in valid.keys) {
        final codes = {...valid, column: unknown[column]!};
        await expectLater(
          db.customStatement(
            'INSERT INTO topik_attempt (id, test_id, level, section, round, '
            'mode, status, started_at, updated_at, current_question_no, '
            'question_count, max_score, content_version) VALUES '
            "('X', 'T', ?, ?, 96, ?, ?, 10, 10, 1, 2, 4, 1)",
            [codes['level'], codes['section'], codes['mode'], codes['status']],
          ),
          throwsA(anything),
          reason: column,
        );
      }
    });
  });
}

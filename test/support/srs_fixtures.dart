import 'package:drift/drift.dart' show QueryRow, Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';

// Trees for the srs tests, written as SQL so that every column is set on
// purpose.

/// A card row and nothing else: the caller writes its schedule row.
Future<void> insertBareCard(AppDatabase db, String cardId, String deckId) =>
    db.customStatement(
      "INSERT INTO card (id, deck_id, front, back, created_at, updated_at) VALUES (?, ?, 'f', 'b', 0, 0)",
      [cardId, deckId],
    );

/// One tree per [rootId]: a root at generation 1 running [scheduler], a
/// sub-deck `<rootId>-leaf` holding one card, that card's start-value
/// schedule row, and an `in_progress` session of the root.
/// Returns (rootId, cardId, sessionId).
Future<(String, String, String)> insertStudyTree(
  AppDatabase db,
  String rootId, {
  String scheduler = 'eight_box',
}) async {
  final cardId = '$rootId-card';
  final sessionId = '$rootId-session';
  await db.customStatement(
    'INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, scheduler_type, '
    'scheduler_version, generation, sibling_position, created_at, updated_at) '
    "VALUES (?, 'root', NULL, ?, 1, 'deck', ?, 1, 1, 0, 0, 0)",
    [rootId, rootId, scheduler],
  );
  await db.customStatement(
    'INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, '
    'sibling_position, created_at, updated_at) '
    "VALUES (?, 'leaf', ?, ?, 2, 'card', 0, 0, 0)",
    ['$rootId-leaf', rootId, rootId],
  );
  await insertBareCard(db, cardId, '$rootId-leaf');
  await db.customStatement(
    scheduler == 'sm2'
        ? 'INSERT INTO card_schedule (card_id, scheduler_type, scheduler_version, generation, '
              "ease_factor, interval_days, repetitions) VALUES (?, 'sm2', 1, 1, 2.5, 0, 0)"
        : 'INSERT INTO card_schedule (card_id, scheduler_type, scheduler_version, generation, '
              "current_box) VALUES (?, 'eight_box', 1, 1, 1)",
    [cardId],
  );
  await db.customStatement(
    'INSERT INTO study_session (id, deck_id, root_id, generation, session_kind, current_mode, '
    "status, cursor, card_limit, started_at) VALUES (?, ?, ?, 1, 'learning', 'self_assess', "
    "'in_progress', 0, 20, 0)",
    [sessionId, rootId, rootId],
  );
  return (rootId, cardId, sessionId);
}

/// A card two levels below [rootId] (root → branch → deep) in an `eight_box`
/// tree: a statement that reaches only the root's children misses it.
Future<String> insertDeepCard(AppDatabase db, String rootId) async {
  final cardId = '$rootId-deep-card';
  await db.customStatement(
    'INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, '
    'sibling_position, created_at, updated_at) '
    "VALUES (?, 'branch', ?, ?, 2, 'deck', 1, 0, 0), (?, 'deep', ?, ?, 3, 'card', 0, 0, 0)",
    [
      '$rootId-branch',
      rootId,
      rootId,
      '$rootId-deep',
      '$rootId-branch',
      rootId,
    ],
  );
  await insertBareCard(db, cardId, '$rootId-deep');
  await db.customStatement(
    'INSERT INTO card_schedule (card_id, scheduler_type, scheduler_version, generation, current_box) '
    "VALUES (?, 'eight_box', 1, 1, 1)",
    [cardId],
  );
  return cardId;
}

Future<QueryRow> _row(AppDatabase db, String table, String column, String id) =>
    db
        .customSelect(
          'SELECT * FROM $table WHERE $column = ?',
          variables: [Variable(id)],
        )
        .getSingle();

Future<QueryRow> deckRowOf(AppDatabase db, String id) =>
    _row(db, 'deck', 'id', id);

Future<QueryRow> scheduleRowOf(AppDatabase db, String cardId) =>
    _row(db, 'card_schedule', 'card_id', cardId);

Future<QueryRow> sessionRowOf(AppDatabase db, String id) =>
    _row(db, 'study_session', 'id', id);

/// [row] holds the start values of [scheduler] at [generation].
void expectStartValues(
  QueryRow row, {
  required String scheduler,
  required int generation,
}) {
  expect(row.read<String>('scheduler_type'), scheduler);
  expect(row.read<int>('generation'), generation);
  expect(row.data['learned_at'], isNull);
  expect(row.data['due_at'], isNull);
  expect(row.data['last_answered_at'], isNull);
  expect(row.read<int>('answer_count'), 0);
  expect(row.read<int>('lapse_count'), 0);
  if (scheduler == 'sm2') {
    expect(row.data['current_box'], isNull);
    expect(row.read<double>('ease_factor'), 2.5);
    expect(row.read<int>('interval_days'), 0);
    expect(row.read<int>('repetitions'), 0);
    return;
  }
  expect(row.read<int>('current_box'), 1);
  expect(row.data['ease_factor'], isNull);
}

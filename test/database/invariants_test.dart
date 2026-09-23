// Generated from docs/shared/data/schema.md ("Bất biến") by the foundation
// plan's Task 5. Every query is copied verbatim; invariants 33-37 need
// delete_batches, which does not exist yet (Clarification 2).
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';

import '../support/test_database.dart';

const _invariants = <int, String>{
  1: r'''
SELECT c.id FROM card c
JOIN deck d ON d.id = c.deck_id
WHERE d.parent_id IS NULL AND c.delete_batch_id IS NULL
''',
  2: r'''
SELECT d.id FROM deck d
WHERE d.content_type = 'unset' AND d.delete_batch_id IS NULL
  AND (EXISTS (SELECT 1 FROM card c
               WHERE c.deck_id = d.id AND c.delete_batch_id IS NULL)
    OR EXISTS (SELECT 1 FROM deck s
               WHERE s.parent_id = d.id AND s.delete_batch_id IS NULL))
''',
  3: r'''
SELECT d.id FROM deck d
WHERE d.content_type = 'card' AND d.delete_batch_id IS NULL
  AND EXISTS (SELECT 1 FROM deck s
              WHERE s.parent_id = d.id AND s.delete_batch_id IS NULL)
''',
  4: r'''
SELECT d.id FROM deck d
WHERE d.content_type = 'deck' AND d.delete_batch_id IS NULL
  AND EXISTS (SELECT 1 FROM card c
              WHERE c.deck_id = d.id AND c.delete_batch_id IS NULL)
''',
  5: r'''
SELECT d.id FROM deck d
WHERE d.parent_id IS NULL AND d.content_type <> 'deck'
''',
  6: r'''
SELECT d.id FROM deck d
JOIN deck p ON p.id = d.parent_id
WHERE d.root_id <> p.root_id
''',
  7: r'''
SELECT d.id FROM deck d
WHERE d.parent_id IS NULL AND d.root_id <> d.id
''',
  8: r'''
WITH RECURSIVE up(start_id, node_id, depth) AS (
  SELECT id, parent_id, 1 FROM deck WHERE parent_id IS NOT NULL
  UNION ALL
  SELECT u.start_id, d.parent_id, u.depth + 1
  FROM up u JOIN deck d ON d.id = u.node_id
  WHERE u.node_id IS NOT NULL AND u.depth < 64
)
SELECT DISTINCT start_id FROM up WHERE node_id = start_id
''',
  9: r'''
SELECT s.card_id FROM card_schedule s
JOIN card c ON c.id = s.card_id
JOIN deck d ON d.id = c.deck_id
JOIN deck root ON root.id = d.root_id
WHERE s.generation <> root.generation
   OR s.scheduler_type <> root.scheduler_type
''',
  10: r'''
SELECT d.id FROM deck d
WHERE d.parent_id IS NOT NULL
  AND (d.scheduler_type IS NOT NULL OR d.generation IS NOT NULL)
''',
  11: r'''
SELECT d.id FROM deck d
WHERE d.parent_id IS NULL
  AND (d.scheduler_type IS NULL OR d.generation IS NULL)
''',
  12: r'''
SELECT id FROM study_session
WHERE NOT (
     (status = 'in_progress' AND end_reason IS NULL)
  OR (status = 'completed'   AND end_reason IS NULL)
  OR (status = 'abandoned'   AND end_reason IN ('user_exit','interrupted'))
  OR (status = 'invalidated'
      AND end_reason IN ('scheduler_reset','scheduler_changed','stale_generation','content_deleted'))
  OR (status = 'failed'      AND end_reason = 'persistence_error')
)
''',
  13: r'''
SELECT id FROM study_session
WHERE status <> 'in_progress' AND ended_at IS NULL
''',
  14: r'''
SELECT id FROM review_log
WHERE kind = 'relearning'
  AND (previous_box IS NOT next_box
    OR previous_ease_factor IS NOT next_ease_factor
    OR previous_interval_days IS NOT next_interval_days)
''',
  15: r'''
WITH RECURSIVE levels(id, depth) AS (
  SELECT id, 1 FROM deck
  WHERE parent_id IS NULL AND delete_batch_id IS NULL
  UNION ALL
  SELECT d.id, l.depth + 1
  FROM deck d JOIN levels l ON d.parent_id = l.id
  WHERE l.depth < 64 AND d.delete_batch_id IS NULL
)
SELECT id FROM levels WHERE depth > 10
''',
  16: r'''
SELECT s.id FROM study_session s
WHERE s.status = 'completed'
  AND EXISTS (SELECT 1 FROM study_queue_items q
              WHERE q.session_id = s.id AND q.status = 'pending')
''',
  17: r'''
SELECT session_id FROM study_queue_items
WHERE available_at < 0 OR answers_in_session < 0 OR round < 1
   OR (mode = 'self_assess' AND answers_in_session > 4)
''',
  18: r'''
SELECT q.session_id FROM study_queue_items q
JOIN study_session s ON s.id = q.session_id
GROUP BY q.session_id, s.card_limit
HAVING COUNT(DISTINCT q.card_id) > s.card_limit
''',
  19: r'''
SELECT q.session_id FROM study_queue_items q
WHERE q.round > 1
  AND NOT EXISTS (SELECT 1 FROM study_queue_items p
                  WHERE p.session_id = q.session_id AND p.mode = q.mode
                    AND p.round = q.round - 1)
''',
  20: r'''
SELECT q.session_id FROM study_queue_items q
WHERE q.round > 1
  AND NOT EXISTS (SELECT 1 FROM study_queue_items p
                  WHERE p.session_id = q.session_id AND p.mode = q.mode
                    AND p.round = q.round - 1 AND p.card_id = q.card_id)
''',
  21: r'''
SELECT session_id FROM study_queue_items
WHERE (mode <> 'recall' AND (remaining_ms IS NOT NULL OR is_revealed <> 0))
   OR remaining_ms < 0 OR remaining_ms > 20000
''',
  22: r'''
SELECT id FROM review_log
WHERE outcome_reason IS NOT NULL
  AND (outcome_reason <> 'timeout' OR mode <> 'recall')
''',
  23: r'''
SELECT id FROM review_log
WHERE mode <> 'fill' AND (comparison_version IS NOT NULL OR used_hint IS NOT NULL)
''',
  24: r'''
SELECT card_id FROM card_schedule
WHERE learned_at IS NOT NULL AND due_at IS NULL
''',
  25: r'''
SELECT a.id FROM review_log a
JOIN card_schedule s ON s.card_id = a.card_id
WHERE a.kind = 'scheduled' AND s.learned_at IS NULL
''',
  26: r'''
SELECT a.id FROM review_log a
JOIN study_session ss ON ss.id = a.session_id
WHERE a.kind = 'learning' AND ss.session_kind <> 'learning'
''',
  27: r'''
SELECT id FROM deck
WHERE parent_id IS NOT NULL AND study_config IS NOT NULL
''',
  28: r'''
SELECT card_id FROM card_schedule
WHERE learned_at IS NULL AND due_at IS NOT NULL
''',
  29: r'''
SELECT d.id
FROM deck d
WHERE d.parent_id IS NOT NULL
  AND d.delete_batch_id IS NULL
  AND d.content_type IN ('card', 'deck')
  AND NOT EXISTS (
    SELECT 1 FROM card c
    WHERE c.deck_id = d.id AND c.delete_batch_id IS NULL
  )
  AND NOT EXISTS (
    SELECT 1 FROM deck child
    WHERE child.parent_id = d.id AND child.delete_batch_id IS NULL
  )
''',
  30: r'''
SELECT root.id FROM deck root
WHERE root.parent_id IS NULL
  AND root.first_answered_at IS NULL
  AND EXISTS (
    SELECT 1 FROM card_schedule s
    JOIN card c ON c.id = s.card_id
    JOIN deck d ON d.id = c.deck_id
    WHERE d.root_id = root.id AND s.learned_at IS NOT NULL
  )
''',
  31: r'''
SELECT s.id FROM study_session s
WHERE (s.direction IS NOT NULL
       AND (s.session_kind <> 'reviewing' OR s.current_mode <> 'self_assess'))
   OR EXISTS (SELECT 1 FROM study_queue_items q
              WHERE q.session_id = s.id
                AND ((q.direction IS NOT NULL AND q.mode <> 'self_assess')
                  OR (q.direction IS NOT NULL AND s.direction IS NULL)
                  OR (s.direction IS NOT NULL AND q.mode = 'self_assess'
                      AND q.direction IS NULL)))
''',
  32: r'''
SELECT a.id FROM review_log a
WHERE EXISTS (SELECT 1 FROM study_queue_items q
              WHERE q.session_id = a.session_id AND q.card_id = a.card_id
                AND q.mode = a.mode)
  AND NOT EXISTS (SELECT 1 FROM study_queue_items q
                  WHERE q.session_id = a.session_id AND q.card_id = a.card_id
                    AND q.mode = a.mode AND q.direction IS a.direction)
''',
};

const _summaries = <int, String>{
  1: "a root deck holds no card (BR-DECK-004)",
  2: "an unset deck holds nothing (BR-DECK-006, BR-DECK-008)",
  3: "a card deck has no sub-deck (BR-DECK-009)",
  4: "a deck of decks has no direct card (BR-DECK-010)",
  5: "a root deck is a deck of decks",
  6: "a descendant points at its parent's root (BR-DECK-019)",
  7: "a root deck is its own root (BR-DECK-002)",
  8: "the deck tree has no cycle (BR-DECK-016)",
  9: "a schedule row runs its root's scheduler and generation (BR-SRS-028, BR-SRS-029)",
  10: "a sub-deck carries no scheduler column (BR-DECK-025)",
  11: "a root deck has a scheduler and a generation (BR-SRS-001)",
  12: "a session's status and end reason form a valid pair (BR-STUDY-010..018)",
  13: "an ended session has ended_at",
  14: "a relearning turn does not change the schedule (BR-SRS-017)",
  15: "no deck is deeper than 10 levels (BR-DECK-001)",
  16: "a completed session has no pending queue item (BR-STUDY-013)",
  17: "queue counters are not negative and self_assess stays within 4 turns (BR-STUDY-073)",
  18: "a session loads no more distinct cards than its card_limit (BR-STUDY-003, BR-STUDY-024)",
  19: "a round follows the round before it (BR-STUDY-059)",
  20: "a later round holds only cards of the round before (BR-STUDY-059)",
  21: "timer state appears only on recall, within 20 seconds (BR-STUDY-031, BR-STUDY-036)",
  22: "a timeout appears only on recall (BR-STUDY-034)",
  23: "fill-only columns appear only on fill (BR-STUDY-027, BR-STUDY-028)",
  24: "a learned card has a due date (BR-STUDY-053, BR-STUDY-058)",
  25: "an unlearned card has no scheduled turn (BR-STUDY-053, BR-STUDY-058)",
  26: "a learning turn belongs to a learning session (BR-STUDY-052)",
  27: "study options live on the root only (BR-STUDY-056)",
  28: "an unlearned card has no due date (BR-STUDY-053)",
  29: "an emptied sub-deck returns to unset (BR-DECK-015)",
  30: "a tree with a learned card has its scheduler locked (BR-SRS-003, BR-STUDY-053)",
  31: "a question direction appears only where it is allowed (BR-MODE-013, BR-MODE-015)",
  32: "a turn carries the direction of its queue row (BR-MODE-016)",
};

/// Rows that satisfy all 32 invariants: three trees (eight_box, sm2, empty),
/// learned and new cards, three sessions (completed, open, invalidated) with
/// queue rows in four modes, and review turns of all three kinds.
const _seed = <String>[
  "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, scheduler_type, scheduler_version, generation, first_answered_at, sibling_position, created_at, updated_at) VALUES ('A', 'A', NULL, 'A', 1, 'deck', 'eight_box', 1, 1, 100, 0, 0, 0)",
  "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, sibling_position, created_at, updated_at) VALUES ('A1', 'A1', 'A', 'A', 2, 'card', 0, 0, 0), ('A2', 'A2', 'A', 'A', 2, 'deck', 1, 0, 0), ('A2a', 'A2a', 'A2', 'A', 3, 'card', 0, 0, 0), ('A3', 'A3', 'A', 'A', 2, 'unset', 2, 0, 0)",
  "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, scheduler_type, scheduler_version, generation, study_config, sibling_position, created_at, updated_at) VALUES ('B', 'B', NULL, 'B', 1, 'deck', 'sm2', 1, 2, '{\"cardLimit\": 10}', 1, 0, 0)",
  "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, sibling_position, created_at, updated_at) VALUES ('B1', 'B1', 'B', 'B', 2, 'card', 0, 0, 0)",
  "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, scheduler_type, scheduler_version, generation, sibling_position, created_at, updated_at) VALUES ('C', 'C', NULL, 'C', 1, 'deck', 'eight_box', 1, 1, 2, 0, 0)",
  "INSERT INTO card (id, deck_id, front, back, created_at, updated_at) VALUES ('c1', 'A1', 'f', 'b', 0, 0), ('c2', 'A1', 'f', 'b', 0, 0), ('c3', 'A2a', 'f', 'b', 0, 0), ('c4', 'B1', 'f', 'b', 0, 0)",
  "INSERT INTO card_schedule (card_id, scheduler_type, scheduler_version, generation, learned_at, due_at, last_answered_at, answer_count, lapse_count, current_box) VALUES ('c1', 'eight_box', 1, 1, 100, 200, 121, 1, 0, 3)",
  "INSERT INTO card_schedule (card_id, scheduler_type, scheduler_version, generation, current_box) VALUES ('c2', 'eight_box', 1, 1, 1), ('c3', 'eight_box', 1, 1, 1)",
  "INSERT INTO card_schedule (card_id, scheduler_type, scheduler_version, generation, ease_factor, interval_days, repetitions) VALUES ('c4', 'sm2', 1, 2, 2.5, 0, 0)",
  "INSERT INTO study_session (id, deck_id, root_id, generation, session_kind, current_mode, status, end_reason, direction, started_at, ended_at) VALUES ('s1', 'A1', 'A', 1, 'learning', 'match', 'completed', NULL, NULL, 90, 150), ('s2', 'A', 'A', 1, 'reviewing', 'self_assess', 'in_progress', NULL, 'mixed', 110, NULL), ('s3', 'B', 'B', 2, 'reviewing', 'recall', 'invalidated', 'scheduler_reset', NULL, 280, 300)",
  "INSERT INTO study_queue_items (session_id, mode, round, card_id, position, status, answers_in_session, remaining_ms, is_revealed, direction) VALUES ('s1', 'self_assess', 1, 'c1', 0, 'completed', 1, NULL, 0, NULL), ('s1', 'self_assess', 1, 'c2', 1, 'completed', 1, NULL, 0, NULL), ('s1', 'match', 1, 'c1', 0, 'completed', 1, NULL, 0, NULL), ('s1', 'match', 1, 'c2', 1, 'completed', 2, NULL, 0, NULL), ('s1', 'match', 2, 'c2', 0, 'completed', 1, NULL, 0, NULL), ('s1', 'recall', 1, 'c1', 0, 'completed', 1, 20000, 1, NULL), ('s1', 'fill', 1, 'c1', 0, 'completed', 1, NULL, 0, NULL), ('s2', 'self_assess', 1, 'c1', 0, 'pending', 2, NULL, 0, 'korean_to_meaning')",
  "INSERT INTO review_log (id, card_id, session_id, scheduler_type, generation, kind, mode, direction, \"action\", answered_at, previous_box, next_box) VALUES ('l1', 'c1', 's1', 'eight_box', 1, 'learning', 'self_assess', NULL, 'remembered', 100, 1, 2), ('l3', 'c1', 's2', 'eight_box', 1, 'scheduled', 'self_assess', 'korean_to_meaning', 'remembered', 120, 2, 3), ('l4', 'c1', 's2', 'eight_box', 1, 'relearning', 'self_assess', 'korean_to_meaning', 'forgotten', 121, 3, 3)",
  "INSERT INTO review_log (id, card_id, session_id, scheduler_type, generation, kind, mode, comparison_version, used_hint, \"action\", answered_at) VALUES ('l2', 'c1', 's1', 'eight_box', 1, 'learning', 'fill', 1, 0, 'remembered', 101)",
  "INSERT INTO review_log (id, card_id, session_id, scheduler_type, generation, kind, mode, outcome_reason, \"action\", answered_at) VALUES ('l5', 'c1', 's1', 'eight_box', 1, 'learning', 'recall', 'timeout', 'forgotten', 102)",
  "INSERT INTO tags (id, name, name_folded, created_at) VALUES ('t1', 'Noun', 'noun', 0)",
  "INSERT INTO card_tags (card_id, tag_id) VALUES ('c1', 't1')",
  "INSERT INTO app_settings (id, updated_at) VALUES (1, 0)",
];

/// Writes the schema accepts but the invariant must catch.
const _planted = <int, List<String>>{
  1: [
    "INSERT INTO card (id, deck_id, front, back, created_at, updated_at) VALUES ('bad', 'A', 'f', 'b', 0, 0)",
  ],
  2: [
    "INSERT INTO card (id, deck_id, front, back, created_at, updated_at) VALUES ('bad', 'A3', 'f', 'b', 0, 0)",
  ],
  3: [
    "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, sibling_position, created_at, updated_at) VALUES ('bad', 'x', 'A1', 'A', 3, 'unset', 0, 0, 0)",
  ],
  4: [
    "INSERT INTO card (id, deck_id, front, back, created_at, updated_at) VALUES ('bad', 'A2', 'f', 'b', 0, 0)",
  ],
  6: [
    "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, sibling_position, created_at, updated_at) VALUES ('bad', 'x', 'A2', 'B', 3, 'unset', 0, 0, 0)",
  ],
  8: ["UPDATE deck SET parent_id = 'A2a' WHERE id = 'A2'"],
  9: ["UPDATE card_schedule SET generation = 7 WHERE card_id = 'c1'"],
  14: [
    "INSERT INTO review_log (id, card_id, session_id, scheduler_type, generation, kind, mode, direction, \"action\", answered_at, previous_box, next_box) VALUES ('bad', 'c1', 's2', 'eight_box', 1, 'relearning', 'self_assess', 'korean_to_meaning', 'forgotten', 130, 3, 1)",
  ],
  15: [
    "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, sibling_position, created_at, updated_at) VALUES ('d2', 'x', 'C', 'C', 2, 'unset', 0, 0, 0)",
    "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, sibling_position, created_at, updated_at) VALUES ('d3', 'x', 'd2', 'C', 3, 'unset', 0, 0, 0)",
    "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, sibling_position, created_at, updated_at) VALUES ('d4', 'x', 'd3', 'C', 4, 'unset', 0, 0, 0)",
    "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, sibling_position, created_at, updated_at) VALUES ('d5', 'x', 'd4', 'C', 5, 'unset', 0, 0, 0)",
    "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, sibling_position, created_at, updated_at) VALUES ('d6', 'x', 'd5', 'C', 6, 'unset', 0, 0, 0)",
    "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, sibling_position, created_at, updated_at) VALUES ('d7', 'x', 'd6', 'C', 7, 'unset', 0, 0, 0)",
    "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, sibling_position, created_at, updated_at) VALUES ('d8', 'x', 'd7', 'C', 8, 'unset', 0, 0, 0)",
    "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, sibling_position, created_at, updated_at) VALUES ('d9', 'x', 'd8', 'C', 9, 'unset', 0, 0, 0)",
    "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, sibling_position, created_at, updated_at) VALUES ('d10', 'x', 'd9', 'C', 10, 'unset', 0, 0, 0)",
    "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, sibling_position, created_at, updated_at) VALUES ('d11', 'x', 'd10', 'C', 10, 'unset', 0, 0, 0)",
  ],
  16: [
    "UPDATE study_queue_items SET status = 'pending' WHERE session_id = 's1' AND mode = 'match' AND round = 2",
  ],
  18: ["UPDATE study_session SET card_limit = 1 WHERE id = 's1'"],
  19: [
    "INSERT INTO study_queue_items (session_id, mode, round, card_id, position, status) VALUES ('s1', 'match', 4, 'c1', 0, 'completed')",
  ],
  20: [
    "INSERT INTO study_queue_items (session_id, mode, round, card_id, position, status) VALUES ('s1', 'match', 2, 'c3', 1, 'completed')",
  ],
  24: ["UPDATE card_schedule SET due_at = NULL WHERE card_id = 'c1'"],
  25: [
    "INSERT INTO review_log (id, card_id, session_id, scheduler_type, generation, kind, mode, direction, \"action\", answered_at, previous_box, next_box) VALUES ('bad', 'c2', 's2', 'eight_box', 1, 'scheduled', 'self_assess', NULL, 'remembered', 130, 1, 2)",
  ],
  26: [
    "INSERT INTO review_log (id, card_id, session_id, scheduler_type, generation, kind, mode, direction, \"action\", answered_at, previous_box, next_box) VALUES ('bad', 'c1', 's2', 'eight_box', 1, 'learning', 'self_assess', 'korean_to_meaning', 'remembered', 130, 3, 3)",
  ],
  29: ["DELETE FROM card WHERE id = 'c3'"],
  30: ["UPDATE deck SET first_answered_at = NULL WHERE id = 'A'"],
  32: [
    "INSERT INTO review_log (id, card_id, session_id, scheduler_type, generation, kind, mode, direction, \"action\", answered_at, previous_box, next_box) VALUES ('bad', 'c1', 's2', 'eight_box', 1, 'scheduled', 'self_assess', 'meaning_to_korean', 'remembered', 130, 3, 4)",
  ],
};

/// Writes a CHECK must refuse, so the invariant can never be broken.
const _refused = <int, String>{
  5: "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, scheduler_type, scheduler_version, generation, sibling_position, created_at, updated_at) VALUES ('bad', 'x', NULL, 'bad', 1, 'unset', 'eight_box', 1, 1, 3, 0, 0)",
  7: "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, scheduler_type, scheduler_version, generation, sibling_position, created_at, updated_at) VALUES ('bad', 'x', NULL, 'A', 1, 'deck', 'eight_box', 1, 1, 3, 0, 0)",
  10: "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, generation, sibling_position, created_at, updated_at) VALUES ('bad', 'x', 'A', 'A', 2, 'unset', 1, 3, 0, 0)",
  11: "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, sibling_position, created_at, updated_at) VALUES ('bad', 'x', NULL, 'bad', 1, 'deck', 3, 0, 0)",
  12: "UPDATE study_session SET end_reason = 'user_exit' WHERE id = 's3'",
  13: "UPDATE study_session SET ended_at = NULL WHERE id = 's1'",
  17: "UPDATE study_queue_items SET answers_in_session = 5 WHERE session_id = 's2'",
  21: "UPDATE study_queue_items SET remaining_ms = 5000 WHERE session_id = 's1' AND mode = 'match'",
  22: "INSERT INTO review_log (id, card_id, session_id, scheduler_type, generation, kind, mode, direction, \"action\", answered_at, outcome_reason) VALUES ('bad', 'c1', 's1', 'eight_box', 1, 'learning', 'self_assess', NULL, 'forgotten', 130, 'timeout')",
  23: "INSERT INTO review_log (id, card_id, session_id, scheduler_type, generation, kind, mode, direction, \"action\", answered_at, comparison_version) VALUES ('bad', 'c1', 's1', 'eight_box', 1, 'learning', 'self_assess', NULL, 'remembered', 130, 1)",
  27: "UPDATE deck SET study_config = '{}' WHERE id = 'A1'",
  28: "UPDATE card_schedule SET due_at = 500 WHERE card_id = 'c2'",
  31: "UPDATE study_session SET direction = 'mixed' WHERE id = 's1'",
};

Future<List<String>> _violations(AppDatabase db, int number) async {
  final rows = await db.customSelect(_invariants[number]!).get();
  return [for (final row in rows) '${row.data.values.first}'];
}

void main() {
  late AppDatabase db;
  setUp(() async {
    db = openTestDatabase();
    for (final statement in _seed) {
      await db.customStatement(statement);
    }
  });
  tearDown(() => db.close());

  group('the seed holds', () {
    for (final number in _invariants.keys) {
      test('invariant $number: ${_summaries[number]}', () async {
        expect(await _violations(db, number), isEmpty);
      });
    }
  });

  group('a planted violation is caught', () {
    for (final MapEntry(key: number, value: statements) in _planted.entries) {
      test('invariant $number: ${_summaries[number]}', () async {
        for (final statement in statements) {
          await db.customStatement(statement);
        }
        expect(await _violations(db, number), isNotEmpty);
      });
    }
  });

  group('a violation is refused by the schema', () {
    for (final MapEntry(key: number, value: statement) in _refused.entries) {
      test('invariant $number: ${_summaries[number]}', () async {
        Object? error;
        try {
          await db.customStatement(statement);
        } catch (e) {
          error = e;
        }
        expect(error, isNotNull, reason: 'the schema accepted: $statement');
        expect(mapDatabaseError(error!), isA<ConstraintFailure>());
        expect(await _violations(db, number), isEmpty);
      });
    }
  });
}

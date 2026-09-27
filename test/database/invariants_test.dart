import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';

import '../support/invariant_queries.dart';
import '../support/test_database.dart';

/// Rows that satisfy every invariant: three trees (eight_box, sm2, empty),
/// learned and new cards, three sessions (completed, open, invalidated) with
/// queue rows in five modes, a guess question with its five options, review
/// turns of all three kinds, and the Trash: a sub-deck in it with a card, an
/// older card batch inside that sub-deck, and a card batch of its own.
const _seed = <String>[
  "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, scheduler_type, scheduler_version, generation, first_answered_at, sibling_position, created_at, updated_at) VALUES ('A', 'A', NULL, 'A', 1, 'deck', 'eight_box', 1, 1, 100, 0, 0, 0)",
  "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, sibling_position, created_at, updated_at) VALUES ('A1', 'A1', 'A', 'A', 2, 'card', 0, 0, 0), ('A2', 'A2', 'A', 'A', 2, 'deck', 1, 0, 0), ('A2a', 'A2a', 'A2', 'A', 3, 'card', 0, 0, 0), ('A3', 'A3', 'A', 'A', 2, 'unset', 2, 0, 0)",
  "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, scheduler_type, scheduler_version, generation, study_config, sibling_position, created_at, updated_at) VALUES ('B', 'B', NULL, 'B', 1, 'deck', 'sm2', 1, 2, '{\"cardLimit\": 10}', 1, 0, 0)",
  "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, sibling_position, created_at, updated_at) VALUES ('B1', 'B1', 'B', 'B', 2, 'card', 0, 0, 0)",
  "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, scheduler_type, scheduler_version, generation, sibling_position, created_at, updated_at) VALUES ('C', 'C', NULL, 'C', 1, 'deck', 'eight_box', 1, 1, 2, 0, 0)",
  "INSERT INTO card (id, deck_id, front, back, created_at, updated_at) VALUES ('c1', 'A1', 'f', 'b', 0, 0), ('c2', 'A1', 'f', 'b', 0, 0), ('c3', 'A2a', 'f', 'b', 0, 0), ('c4', 'B1', 'f', 'b', 0, 0), ('c5', 'A1', 'f', 'b', 0, 0), ('c6', 'A1', 'f', 'b', 0, 0)",
  "INSERT INTO card_schedule (card_id, scheduler_type, scheduler_version, generation, learned_at, due_at, last_answered_at, answer_count, lapse_count, current_box) VALUES ('c1', 'eight_box', 1, 1, 100, 200, 121, 1, 0, 3)",
  "INSERT INTO card_schedule (card_id, scheduler_type, scheduler_version, generation, current_box) VALUES ('c2', 'eight_box', 1, 1, 1), ('c3', 'eight_box', 1, 1, 1), ('c5', 'eight_box', 1, 1, 1), ('c6', 'eight_box', 1, 1, 1)",
  "INSERT INTO card_schedule (card_id, scheduler_type, scheduler_version, generation, ease_factor, interval_days, repetitions) VALUES ('c4', 'sm2', 1, 2, 2.5, 0, 0)",
  "INSERT INTO study_session (id, deck_id, root_id, generation, session_kind, current_mode, status, end_reason, direction, started_at, ended_at) VALUES ('s1', 'A1', 'A', 1, 'learning', 'match', 'completed', NULL, NULL, 90, 150), ('s2', 'A', 'A', 1, 'reviewing', 'self_assess', 'in_progress', NULL, 'mixed', 110, NULL), ('s3', 'B', 'B', 2, 'reviewing', 'recall', 'invalidated', 'scheduler_reset', NULL, 280, 300)",
  "INSERT INTO study_queue_items (session_id, mode, round, card_id, position, status, answers_in_session, remaining_ms, is_revealed, direction, hint_shown, meaning_slot) VALUES ('s1', 'self_assess', 1, 'c1', 0, 'completed', 1, NULL, 0, NULL, 0, NULL), ('s1', 'self_assess', 1, 'c2', 1, 'completed', 1, NULL, 0, NULL, 0, NULL), ('s1', 'match', 1, 'c1', 0, 'completed', 1, NULL, 0, NULL, 0, 1), ('s1', 'match', 1, 'c2', 1, 'completed', 2, NULL, 0, NULL, 0, 0), ('s1', 'match', 2, 'c2', 0, 'completed', 1, NULL, 0, NULL, 0, 0), ('s1', 'guess', 1, 'c1', 0, 'completed', 1, NULL, 0, NULL, 0, NULL), ('s1', 'recall', 1, 'c1', 0, 'completed', 1, 20000, 1, NULL, 0, NULL), ('s1', 'fill', 1, 'c1', 0, 'completed', 1, NULL, 0, NULL, 1, NULL), ('s2', 'self_assess', 1, 'c1', 0, 'pending', 2, NULL, 0, 'korean_to_meaning', 0, NULL)",
  "INSERT INTO study_guess_options (session_id, round, card_id, slot, option_card_id) VALUES ('s1', 1, 'c1', 0, 'c5'), ('s1', 1, 'c1', 1, 'c3'), ('s1', 1, 'c1', 2, 'c1'), ('s1', 1, 'c1', 3, 'c6'), ('s1', 1, 'c1', 4, 'c2')",
  "INSERT INTO review_log (id, card_id, session_id, scheduler_type, generation, kind, mode, direction, \"action\", answered_at, previous_box, next_box) VALUES ('l1', 'c1', 's1', 'eight_box', 1, 'learning', 'self_assess', NULL, 'remembered', 100, 1, 2), ('l3', 'c1', 's2', 'eight_box', 1, 'scheduled', 'self_assess', 'korean_to_meaning', 'remembered', 120, 2, 3), ('l4', 'c1', 's2', 'eight_box', 1, 'relearning', 'self_assess', 'korean_to_meaning', 'forgotten', 121, 3, 3)",
  "INSERT INTO review_log (id, card_id, session_id, scheduler_type, generation, kind, mode, comparison_version, used_hint, \"action\", answered_at) VALUES ('l2', 'c1', 's1', 'eight_box', 1, 'learning', 'fill', 1, 0, 'remembered', 101)",
  "INSERT INTO review_log (id, card_id, session_id, scheduler_type, generation, kind, mode, outcome_reason, \"action\", answered_at) VALUES ('l5', 'c1', 's1', 'eight_box', 1, 'learning', 'recall', 'timeout', 'forgotten', 102)",
  // A session the Reset of tree B closed, and the scheduled turn it kept from
  // generation 1 (BR-SRS-023) while c4 started over at generation 2.
  "INSERT INTO study_session (id, deck_id, root_id, generation, session_kind, current_mode, status, "
      "end_reason, direction, started_at, ended_at) "
      "VALUES ('s0', 'B', 'B', 1, 'reviewing', 'self_assess', 'invalidated', 'scheduler_reset', NULL, 200, 260)",
  "INSERT INTO review_log (id, card_id, session_id, scheduler_type, generation, kind, mode, \"action\", "
      "answered_at, previous_ease_factor, next_ease_factor, previous_interval_days, next_interval_days) "
      "VALUES ('l6', 'c4', 's0', 'sm2', 1, 'scheduled', 'self_assess', 'good', 250, 2.5, 2.5, 1, 6)",
  "INSERT INTO tags (id, name, name_folded, created_at) VALUES ('t1', 'Noun', 'noun', 0)",
  "INSERT INTO card_tags (card_id, tag_id) VALUES ('c1', 't1')",
  // The Trash (BR-TRASH-001, BR-TRASH-003): c8 went first, then the deck A4
  // with c7, then c9 on its own.
  "INSERT INTO delete_batches (id, item_type, root_item_id, deleted_at) VALUES ('b0', 'card', 'c8', 50), ('b1', 'deck', 'A4', 60), ('b2', 'card', 'c9', 70)",
  "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, delete_batch_id, sibling_position, created_at, updated_at) VALUES ('A4', 'A4', 'A', 'A', 2, 'card', 'b1', 3, 0, 0)",
  "INSERT INTO card (id, deck_id, front, back, delete_batch_id, created_at, updated_at) VALUES ('c7', 'A4', 'f', 'b', 'b1', 0, 0), ('c8', 'A4', 'f', 'b', 'b0', 0, 0), ('c9', 'A1', 'f', 'b', 'b2', 0, 0)",
  "INSERT INTO card_schedule (card_id, scheduler_type, scheduler_version, generation, current_box) VALUES ('c7', 'eight_box', 1, 1, 1), ('c8', 'eight_box', 1, 1, 1), ('c9', 'eight_box', 1, 1, 1)",
  // The settings row exists from the first open (BR-SETTINGS-001).
  "UPDATE app_settings SET updated_at = 0 WHERE id = 1",
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
  39: [
    "UPDATE study_queue_items SET meaning_slot = 1 WHERE session_id = 's1' AND mode = 'match' AND round = 1 AND card_id = 'c2'",
  ],
  40: [
    "DELETE FROM study_guess_options WHERE session_id = 's1' AND option_card_id = 'c1'",
  ],
  32: [
    "INSERT INTO review_log (id, card_id, session_id, scheduler_type, generation, kind, mode, direction, \"action\", answered_at, previous_box, next_box) VALUES ('bad', 'c1', 's2', 'eight_box', 1, 'scheduled', 'self_assess', 'meaning_to_korean', 'remembered', 130, 3, 4)",
  ],
  33: ["UPDATE card SET delete_batch_id = NULL WHERE id = 'c7'"],
  34: [
    "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, sibling_position, created_at, updated_at) VALUES ('bad', 'x', 'A4', 'A', 3, 'unset', 0, 0, 0)",
  ],
  35: [
    "INSERT INTO delete_batches (id, item_type, root_item_id, deleted_at) VALUES ('bad', 'card', 'c1', 80)",
  ],
  36: [
    "INSERT INTO delete_batches (id, item_type, root_item_id, deleted_at) VALUES ('b3', 'deck', 'bad', 90)",
    "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, delete_batch_id, sibling_position, created_at, updated_at) VALUES ('bad', 'x', 'A4', 'A', 3, 'unset', 'b3', 0, 0, 0)",
  ],
  37: ["UPDATE delete_batches SET root_item_id = 'c1' WHERE id = 'b2'"],
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
  38: "UPDATE study_queue_items SET hint_shown = 1 WHERE session_id = 's1' AND mode = 'match'",
  39: "UPDATE study_queue_items SET meaning_slot = 0 WHERE session_id = 's2'",
  40: "INSERT INTO study_guess_options (session_id, round, card_id, slot, option_card_id) VALUES ('s1', 1, 'c1', 5, 'c4')",
};

Future<List<String>> _violations(AppDatabase db, int number) async {
  final rows = await db.customSelect(invariantQueries[number]!).get();
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

  test('schema.md states invariants 1 to 40', () {
    expect(
      invariantQueries.keys,
      unorderedEquals([for (var n = 1; n <= 40; n++) n]),
    );
  });

  test('only the "Bất biến" section is read, not a mention of it or a later section', () {
    const markdown = '''
# Schema

Cited in prose as `## Bất biến`, before the section.

```sql
-- 2. An example before the section
SELECT 2;
```

## Bất biến — phải kiểm tra được bằng query

```sql
-- 1. The invariant
--    A note under its title.
SELECT 1;
```

## A later section

```sql
-- 3. Not an invariant
SELECT 3;
```
''';
    expect(parseInvariantQueries(markdown), {1: 'SELECT 1'});
  });

  group('the seed holds', () {
    for (final number in invariantQueries.keys) {
      test('invariant $number: ${invariantSummaries[number]}', () async {
        expect(await _violations(db, number), isEmpty);
      });
    }
  });

  group('a planted violation is caught', () {
    for (final MapEntry(key: number, value: statements) in _planted.entries) {
      test('invariant $number: ${invariantSummaries[number]}', () async {
        for (final statement in statements) {
          await db.customStatement(statement);
        }
        expect(await _violations(db, number), isNotEmpty);
      });
    }
  });

  group('a violation is refused by the schema', () {
    for (final MapEntry(key: number, value: statement) in _refused.entries) {
      test('invariant $number: ${invariantSummaries[number]}', () async {
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

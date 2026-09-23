// Generated from docs/shared/data/schema.md ("Bất biến") for the foundation
// plan's Task 5. Every query is copied verbatim; invariants 33-37 need
// delete_batches, which does not exist yet (Clarification 2).

/// Invariant queries 1-32 of schema.md: each must return no row.
const invariantQueries = <int, String>{
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

/// What each invariant holds, with the rules it cites.
const invariantSummaries = <int, String>{
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

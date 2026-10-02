# Every query in `.drift`, P4 (srs) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move `SrsDao` to a `@DriftAccessor` whose every query lives in `.drift`, and take `srs_dao.dart` off the guard's temporary exclude.

**Architecture:** P0–P3 set the pattern (ADR-020).
- **`srs_queries.drift`.** `SrsDao` includes a new `srs_queries.drift` and the shared `live_row_queries.drift`.
- **The tree predicate.** The Dart helper `_ofTree` ("the sessions of the tree of a root") is written out in SQL in the two queries that use it, both in the same file. Its wording and its BR comment stay with each copy.
- **Partial writes.** These keep taking Companions through `SET $values`.
- **The tree's schedule rewrite.** It reads card and deck tombstones on purpose, D11. It becomes two named statements, and the tombstone allowlist entry splits into two keys.

**Tech Stack:** Flutter 3.47.5, Drift 2.35, Python 3.13 guard.

**Spec:** `docs/superpowers/specs/2026-10-01-drift-queries-only-design.md` (§4 P4; D1–D7, D11). ADR-020.

## Global Constraints

These are the same as P2 and P3:
- behaviour-preserving;
- generated `*.g.dart` stays uncommitted;
- guard commands use `python3.13`;
- generated parameters follow first appearance in the SQL;
- card and deck reads and writes in `.drift` name `delete_batch_id`, or carry an allowlist entry `<file>#<queryName>`;
- each new query file gets an impact-map owner row;
- a query name never collides with a DAO method name.

## Review Focus

1. **A reset or a scheduler change closes every open session of the tree, including a session holding a card that moved into the tree mid-session** (BR-STUDY-015, BR-STUDY-016, IT-CONT-006). Pinned by the srs reset and scheduler-change tests.
2. **The reset summary counts leave the Trash out and count open sessions the same way the closing does.** Pinned by the reset summary tests.
3. **The tree's schedule rewrite covers tombstones (D11).** Pinned by the allowlist entries and the srs reset tests.
4. **`updateDeck` only ever touches a live root.** Every caller reads the root through `deckRow` or `rootOfCard`, which are live, in the same transaction.

---

### Task 1: `SrsDao`

**Files:**
- Create: `lib/core/database/queries/srs_queries.drift`
- Modify: `lib/features/srs/data/datasources/srs_dao.dart` (whole file)
- Modify: `test/architecture/tombstone_filter_test.dart` (`srs_dao.dart#replaceTreeSchedules` → two keys)
- Modify: guard `scopes.yaml`, `MIGRATED_TO_DRIFT`, impact map
- Tests (existing): `test/features/srs/`, `test/features/study/`, `test/features/deck/`, `test/architecture/`

**Interfaces:**
- Produces: `SrsDao(AppDatabase)` with unchanged method names and types.

- [ ] **Step 1: Red.** Delete `      - lib/features/srs/data/datasources/srs_dao.dart` from `scopes.yaml` and add it to `MIGRATED_TO_DRIFT`. Run the guard. Expected: exit 1 on `srs_dao.dart`.

- [ ] **Step 2: Queries.** Create `lib/core/database/queries/srs_queries.drift`:

```sql
import '../tables/deck.drift';
import '../tables/card.drift';
import '../tables/srs.drift';
import '../tables/study.drift';

-- BR-DECK-003, BE-C3: the root of :card_id's tree, reached through
-- card.deck_id and then deck.root_id; nothing when the card, its deck or
-- the root is in the Trash.
rootOfLiveCard(:card_id AS TEXT):
SELECT root.* FROM card c
JOIN deck d ON d.id = c.deck_id
JOIN deck root ON root.id = d.root_id
WHERE c.id = :card_id AND c.delete_batch_id IS NULL
  AND d.delete_batch_id IS NULL AND root.delete_batch_id IS NULL;

-- UC-DECK-003: the deck :deck_id with what a reset of its tree would clear,
-- in one statement; the counts leave the Trash out, as the deck list does.
-- The open sessions are those of the tree: opened on its root, or holding a
-- card that now lives in it (BR-SRS-006, IT-CONT-006, BR-STUDY-015,
-- BR-STUDY-016).
resetSummaryOf(:deck_id AS TEXT) AS ResetSummaryRow:
SELECT d.**,
  (SELECT COUNT(*) FROM card c JOIN deck k ON k.id = c.deck_id
   WHERE k.root_id = d.id AND c.delete_batch_id IS NULL
     AND k.delete_batch_id IS NULL) AS card_count,
  (SELECT COUNT(*) FROM card c JOIN deck k ON k.id = c.deck_id
   JOIN card_schedule cs ON cs.card_id = c.id
   WHERE k.root_id = d.id AND c.delete_batch_id IS NULL
     AND k.delete_batch_id IS NULL AND cs.learned_at IS NOT NULL)
    AS learned_card_count,
  (SELECT COUNT(*) FROM study_session s
   WHERE s.status = 'in_progress' AND (s.root_id = d.id OR EXISTS (
     SELECT 1 FROM study_queue_items q
     JOIN card c ON c.id = q.card_id JOIN deck k ON k.id = c.deck_id
     WHERE q.session_id = s.id AND k.root_id = d.id
       AND c.delete_batch_id IS NULL AND k.delete_batch_id IS NULL)))
    AS open_session_count
FROM deck d
WHERE d.id = :deck_id AND d.delete_batch_id IS NULL;

scheduleOfCard(:card_id AS TEXT):
SELECT * FROM card_schedule WHERE card_id = :card_id;

createSchedule: INSERT INTO card_schedule $row;

updateScheduleOf(:card_id AS TEXT):
UPDATE card_schedule SET $values WHERE card_id = :card_id;

createReviewLog: INSERT INTO review_log $row;

-- A root's scheduler, generation or first answer; only a live root.
updateLiveDeck(:deck_id AS TEXT):
UPDATE deck SET $values WHERE id = :deck_id AND delete_batch_id IS NULL;

-- D11, schema.md: every schedule row of :root_id's tree, tombstones
-- included, goes before the tree gets new ones.
deleteTreeSchedules(:root_id AS TEXT):
DELETE FROM card_schedule WHERE card_id IN (
  SELECT c.id FROM card c JOIN deck d ON d.id = c.deck_id
  WHERE d.root_id = :root_id);

-- D11, schema.md: every card of :root_id's tree, at any depth and
-- tombstones included, gets a schedule row of these values.
insertTreeSchedules(:scheduler_type AS TEXT, :scheduler_version AS INTEGER,
  :generation AS INTEGER, :learned_at AS DATETIME OR NULL,
  :due_at AS DATETIME OR NULL, :last_answered_at AS DATETIME OR NULL,
  :answer_count AS INTEGER, :lapse_count AS INTEGER,
  :current_box AS INTEGER OR NULL, :ease_factor AS REAL OR NULL,
  :interval_days AS INTEGER OR NULL, :repetitions AS INTEGER OR NULL,
  :root_id AS TEXT):
INSERT INTO card_schedule (card_id, scheduler_type, scheduler_version,
  generation, learned_at, due_at, last_answered_at, answer_count,
  lapse_count, current_box, ease_factor, interval_days, repetitions)
SELECT c.id, :scheduler_type, :scheduler_version, :generation, :learned_at,
  :due_at, :last_answered_at, :answer_count, :lapse_count, :current_box,
  :ease_factor, :interval_days, :repetitions
FROM card c JOIN deck d ON d.id = c.deck_id WHERE d.root_id = :root_id;

-- BR-STUDY-015, BR-STUDY-016: every in_progress session of :root_id's tree
-- closes as invalidated with :end_reason: opened on the root, or holding a
-- card that now lives in its tree (BR-SRS-006, IT-CONT-006).
invalidateOpenSessionsOfTree(:end_reason AS TEXT, :now AS DATETIME,
  :root_id AS TEXT):
UPDATE study_session
SET status = 'invalidated', end_reason = :end_reason, ended_at = :now
WHERE status = 'in_progress' AND (study_session.root_id = :root_id OR EXISTS (
  SELECT 1 FROM study_queue_items q
  JOIN card c ON c.id = q.card_id JOIN deck k ON k.id = c.deck_id
  WHERE q.session_id = study_session.id AND k.root_id = :root_id
    AND c.delete_batch_id IS NULL AND k.delete_batch_id IS NULL));
```

- [ ] **Step 3: DAO.** Replace `srs_dao.dart` with:

```dart
import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';

part 'srs_dao.g.dart';

/// Row access for `card_schedule` and `review_log`, plus the reads of `deck`
/// srs needs and the sessions a reset closes (`srs_queries.drift`). It
/// returns Drift rows, never domain values, and runs inside the caller's
/// transaction.
@DriftAccessor(
  include: {
    'package:memox/core/database/queries/srs_queries.drift',
    'package:memox/core/database/queries/live_row_queries.drift',
  },
)
final class SrsDao extends DatabaseAccessor<AppDatabase> with _$SrsDaoMixin {
  SrsDao(super.attachedDatabase);

  /// The deck [id] names, unless it is in the Trash (spec §8).
  Future<Deck?> deckRow(String id) => liveDeckRow(id).getSingleOrNull();

  /// The root of [cardId]'s tree, reached through `card.deck_id` and then
  /// `deck.root_id` (BR-DECK-003); null when the card or its deck is in the
  /// Trash (BE-C3).
  Future<Deck?> rootOfCard(String cardId) =>
      rootOfLiveCard(cardId).getSingleOrNull();

  /// The deck [id] names with what a reset of its tree would clear, in one
  /// statement; null when it does not exist or is in the Trash. The counts
  /// leave the Trash out, as the deck list does (UC-DECK-003).
  Future<
    ({Deck deck, int cardCount, int learnedCardCount, int openSessionCount})?
  >
  resetSummaryRow(String id) async {
    final row = await resetSummaryOf(id).getSingleOrNull();
    if (row == null) return null;
    return (
      deck: row.d,
      cardCount: row.cardCount,
      learnedCardCount: row.learnedCardCount,
      openSessionCount: row.openSessionCount,
    );
  }

  Future<CardSchedule?> scheduleRow(String cardId) =>
      scheduleOfCard(cardId).getSingleOrNull();

  Future<void> insertSchedule(CardScheduleCompanion row) =>
      createSchedule(row);

  Future<void> updateSchedule(String cardId, CardScheduleCompanion values) =>
      updateScheduleOf(values, cardId);

  Future<void> insertReviewLog(ReviewLogCompanion row) =>
      createReviewLog(row);

  Future<void> updateDeck(String id, DeckCompanion values) =>
      updateLiveDeck(values, id);

  /// Gives every card of [rootId]'s tree, at any depth, a schedule row of
  /// [values]: the rows are deleted and created again (schema.md). Every
  /// column of [values] must be present.
  Future<void> replaceTreeSchedules(
    String rootId,
    CardScheduleCompanion values,
  ) async {
    await deleteTreeSchedules(rootId);
    await insertTreeSchedules(
      values.schedulerType.value,
      values.schedulerVersion.value,
      values.generation.value,
      values.learnedAt.value,
      values.dueAt.value,
      values.lastAnsweredAt.value,
      values.answerCount.value,
      values.lapseCount.value,
      values.currentBox.value,
      values.easeFactor.value,
      values.intervalDays.value,
      values.repetitions.value,
      rootId,
    );
  }

  /// Closes every `in_progress` session of [rootId]'s tree as `invalidated`
  /// with [endReason], in the transaction of the reset or the scheduler
  /// change (BR-STUDY-015, BR-STUDY-016).
  Future<void> invalidateOpenSessions(
    String rootId, {
    required String endReason,
    required DateTime now,
  }) => invalidateOpenSessionsOfTree(endReason, now, rootId);
}
```

- [ ] **Step 4: Allowlist.** In `tombstone_filter_test.dart`, replace the single `srs_dao.dart#replaceTreeSchedules` entry with two entries keyed `lib/core/database/queries/srs_queries.drift#deleteTreeSchedules` and `…#insertTreeSchedules`, both with the same reason.

- [ ] **Step 5: Build and match the signatures.** Run build_runner and read the generated signatures in `srs_dao.g.dart`:
  - `updateScheduleOf(values, cardId)`, `updateLiveDeck(values, deckId)` and `invalidateOpenSessionsOfTree(endReason, now, rootId)`. Each follows first appearance in its SQL.
  - `insertTreeSchedules`: its parameters must follow the order the variables appear in the `SELECT`, with `rootId` last.
  - `resetSummaryOf` must give `ResetSummaryRow` with `Deck d` and `int` counts.

  Fix any call that does not match the generated signature.

- [ ] **Step 6: Verify.** Add `"srs_queries": ["srs", "study", "deck"]` to the impact map and add `"srs"` to `live_row_queries`. Then run:
  - analyze;
  - the guard and its tests;
  - the CI tooling tests;
  - `TZ=UTC flutter test test/features/srs/ test/features/study/ test/features/deck/ test/architecture/`.

  Expected: all green.

- [ ] **Step 7: Commit** `refactor(srs): SrsDao reads and writes through .drift (ADR-020 P4)`.

### Task 2: WBS and gate

- [ ] Run `dod_check.sh`. Expected: green.
- [ ] Set FE-D21 to `xong`, regenerate and check the docs, then commit `docs(wbs): FE-D21 done`.

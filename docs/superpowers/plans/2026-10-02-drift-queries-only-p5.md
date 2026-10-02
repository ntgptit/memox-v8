# Every query in `.drift`, P5 (study) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move `StudySessionDao`, `StudyQueueDao`, `StudyRoundDao` and `StudyViewDao` to `@DriftAccessor`s whose own queries live in `.drift`, and take all four off the guard's temporary exclude.

**Architecture:** P0–P4 set the pattern (ADR-020). The plan applies four rules.
- **One query file per DAO.** Each DAO gets its own query file. Every DAO also includes `live_row_queries.drift` where it reads a live deck or card.
- **Fixed SQL instead of string templates.** Dart string templates (`_subtree`, `_lowestPendingRound`, `_resumable`, `_newestFirst`) become SQL written out in each query that uses them, inside one file. Optional clauses become two fixed queries.
- **`batch` becomes a loop (D9).** The two `batch(insertAll)` calls become loops over a generated insert, inside the caller's transaction.
- **Two broad watches are rebuilt.** `watchSessionRow` and `watchDeckRow` declare `readsFrom` tables their SQL does not read, so that the session and entry screens re-emit on those writes. A generated query only watches what it reads. So they become `tableChanges(<the same tables>).asyncMap(<generated read>)`. That is the pattern `homeChanges` and Progress already use (spec §7 risk).
- **`deckLevelOfRoots` stays on `attachedDatabase`.** It belongs to the shared `deck_queries.drift` until P6.

**Tech Stack:** Flutter 3.47.5, Drift 2.35, Python 3.13 guard.

**Spec:** `docs/superpowers/specs/2026-10-01-drift-queries-only-design.md` (§4 P5; D1–D9, D11; §7 stream risk). ADR-020.

## Global Constraints

These are the same as P2–P4:
- Behaviour-preserving.
- Generated `*.g.dart` stays uncommitted.
- Guard commands use `python3.13`.
- Generated parameters follow first appearance in the SQL.
- Card and deck reads in `.drift` name `delete_batch_id`, or carry an allowlist entry.
- Every new query file gets an impact-map owner row.
- Query names never collide with DAO members.
- **Result class names.** They must not collide with the Dart record typedefs these files already declare: `StudyCardRow`, `SubtreeCounts`, `SessionViewRow`, `RoundCounts`, `ResumableRow`, `SummaryCounts`, `OptionRecord`, `BoardPairRecord`, `TrailRecord`, `RoundRowRecord`.
- **Status and code values.** Codes that come from Dart enums (`SessionStatus`, `SessionEndReason`) stay bound parameters. The queue's `'pending'` and `'completed'` literals, which were Dart string constants, are written into the SQL.

## Review Focus

1. **The session screen and the Study Entry re-emit on every write they re-emitted on before.** The table sets passed to `tableChanges` must be exactly the old `readsFrom` sets. Pinned by the study session and study entry stream tests.
2. **The serving order is unchanged.** The queue head keeps the lowest pending round, due-at-the-cursor before later, then position (BR-STUDY-005). Pinned by the queue tests.
3. **Round 1 and the guess options keep their order.** The `batch` → loop change must keep inserting in order, and an error half-way must roll back with the caller's transaction. Pinned by the study start and guess tests.
4. **The resumable session comes from the same set as before.** Same day, same generation, out of the Trash, with a queue row left. Of all decks or of one deck, newest first with the id as tie-break (BR-STUDY-075). Pinned by the resume tests.
5. **The summary counts.** The lapse actions are now an `IN :lapse_actions` list, and must count exactly as the placeholder list did. Pinned by the summary tests.

---

### Task 1: `StudySessionDao`

**Files:** Create `lib/core/database/queries/study_session_queries.drift`. Modify `lib/features/study/data/datasources/study_session_dao.dart` (whole file), the guard scope and `MIGRATED_TO_DRIFT`, and the impact map.

- [ ] **Step 1: Red.** Take `lib/features/study/data/datasources/study_session_dao.dart` off `scopes.yaml` and add it to `MIGRATED_TO_DRIFT`. Run the guard. Expected: exit 1 on that file.

- [ ] **Step 2: Queries.** `study_session_queries.drift`:

```sql
import '../tables/deck.drift';
import '../tables/card.drift';
import '../tables/srs.drift';
import '../tables/study.drift';

-- The subtree of :deck_id is its active decks, walked through parent_id
-- (schema.md "Duyệt cây"); it is written out in each query that reads it.

-- BR-STUDY-051, BR-STUDY-057: the active cards of :deck_id's whole subtree
-- not learned yet, oldest first.
newCardsOfSubtree(:deck_id AS TEXT) AS NewSubtreeCardRow:
WITH RECURSIVE subtree(id) AS (
  SELECT id FROM deck WHERE id = :deck_id AND delete_batch_id IS NULL
  UNION
  SELECT d.id FROM deck d JOIN subtree s ON d.parent_id = s.id
  WHERE d.delete_batch_id IS NULL)
SELECT c.id, c.example IS NOT NULL AS has_example
FROM card c JOIN card_schedule cs ON cs.card_id = c.id
WHERE c.deck_id IN (SELECT id FROM subtree) AND c.delete_batch_id IS NULL
  AND cs.learned_at IS NULL
ORDER BY c.created_at, c.id;

-- BR-STUDY-001, BR-STUDY-002, BR-STUDY-051: the active learned cards of
-- :deck_id's whole subtree due at :now, earliest due first.
dueCardsOfSubtree(:deck_id AS TEXT, :now AS DATETIME) AS DueSubtreeCardRow:
WITH RECURSIVE subtree(id) AS (
  SELECT id FROM deck WHERE id = :deck_id AND delete_batch_id IS NULL
  UNION
  SELECT d.id FROM deck d JOIN subtree s ON d.parent_id = s.id
  WHERE d.delete_batch_id IS NULL)
SELECT c.id, c.example IS NOT NULL AS has_example
FROM card c JOIN card_schedule cs ON cs.card_id = c.id
WHERE c.deck_id IN (SELECT id FROM subtree) AND c.delete_batch_id IS NULL
  AND cs.learned_at IS NOT NULL AND cs.due_at <= :now
ORDER BY cs.due_at, c.created_at, c.id;

-- BR-STUDY-051, BR-STUDY-068, BR-STUDY-008: the new and the due cards of
-- :deck_id's subtree at :now, the due ones that fell due before
-- :start_of_today, and the earliest due_at after :now.
subtreeCountsOf(:deck_id AS TEXT, :now AS DATETIME,
  :start_of_today AS DATETIME) AS SubtreeCountsRow:
WITH RECURSIVE subtree(id) AS (
  SELECT id FROM deck WHERE id = :deck_id AND delete_batch_id IS NULL
  UNION
  SELECT d.id FROM deck d JOIN subtree s ON d.parent_id = s.id
  WHERE d.delete_batch_id IS NULL)
SELECT
  COUNT(CASE WHEN cs.learned_at IS NULL THEN 1 END) AS new_count,
  COUNT(CASE WHEN cs.learned_at IS NOT NULL AND cs.due_at <= :now
    THEN 1 END) AS due_count,
  COUNT(CASE WHEN cs.learned_at IS NOT NULL AND cs.due_at < :start_of_today
    THEN 1 END) AS overdue_count,
  MIN(CASE WHEN cs.learned_at IS NOT NULL AND cs.due_at > :now
    THEN cs.due_at END) AS next_due_at
FROM card c JOIN card_schedule cs ON cs.card_id = c.id
WHERE c.deck_id IN (SELECT id FROM subtree) AND c.delete_batch_id IS NULL;

-- BR-CARD-003: whether :card_id has a hint; a blank one is stored as NULL.
liveCardHasHint(:card_id AS TEXT):
SELECT hint IS NOT NULL FROM card
WHERE id = :card_id AND delete_batch_id IS NULL;

-- BR-STUDY-038: the distinct meanings of :session_card_ids and of the
-- learned, active cards of :root_id's tree, the distractor source of guess.
distinctMeaningCountOf(:root_id AS TEXT):
SELECT COUNT(DISTINCT c.back_folded) FROM card c
JOIN deck d ON d.id = c.deck_id
JOIN card_schedule cs ON cs.card_id = c.id
WHERE d.root_id = :root_id AND c.delete_batch_id IS NULL
  AND d.delete_batch_id IS NULL
  AND (cs.learned_at IS NOT NULL OR c.id IN :session_card_ids);

-- BR-STUDY-072: every open session ends; user_exit when it started today,
-- interrupted when it started on an earlier local day.
closeAllOpenSessions(:abandoned AS TEXT, :now AS DATETIME,
  :start_of_today AS DATETIME, :user_exit AS TEXT, :interrupted AS TEXT,
  :in_progress AS TEXT):
UPDATE study_session SET status = :abandoned, ended_at = :now,
  end_reason = CASE WHEN started_at >= :start_of_today
    THEN :user_exit ELSE :interrupted END
WHERE status = :in_progress;

-- BR-STUDY-072: every open session that started before :start_of_today
-- ends as interrupted.
closeSessionsStartedBefore(:abandoned AS TEXT, :interrupted AS TEXT,
  :now AS DATETIME, :in_progress AS TEXT, :start_of_today AS DATETIME):
UPDATE study_session
SET status = :abandoned, end_reason = :interrupted, ended_at = :now
WHERE status = :in_progress AND started_at < :start_of_today;

createSession: INSERT INTO study_session $row;

sessionById(:session_id AS TEXT):
SELECT * FROM study_session WHERE id = :session_id;

updateSessionRow(:session_id AS TEXT):
UPDATE study_session SET $values WHERE id = :session_id;
```

- [ ] **Step 3: DAO.**
  - Keep the file's `StudyCardRow` / `SubtreeCounts` typedefs and the `session_status_model` import.
  - Drop `_subtree`.
  - The class becomes `@DriftAccessor(include: {study_session_queries.drift, live_row_queries.drift})`, `final class StudySessionDao extends DatabaseAccessor<AppDatabase> with _$StudySessionDaoMixin`, with constructor `StudySessionDao(super.attachedDatabase)`.
  - The public members keep their names, signatures and doc comments. Their bodies become:
    - `deckRow(id)` → `liveDeckRow(id).getSingleOrNull()`
    - `newCards(deckId)` → `[for (final r in await newCardsOfSubtree(deckId).get()) (cardId: r.id, hasExample: r.hasExample)]`
    - `dueCards(deckId, now)` → the same over `dueCardsOfSubtree(deckId, now)`
    - `subtreeCounts(deckId, now, startOfToday:)` → read `subtreeCountsOf(deckId, now, startOfToday).getSingle()` into the record (`newCount`, `dueCount`, `overdueCount`, `nextDueAt`)
    - `cardRow(id)` → `liveCardRow(id).getSingle()`
    - `hasHint(cardId)` → `(await liveCardHasHint(cardId).getSingleOrNull()) ?? false`
    - `distinctMeaningCount(rootId, ids)` → `distinctMeaningCountOf(rootId, ids).getSingle()`
    - `closeOpenSessions(now:, startOfToday:)` → `closeAllOpenSessions(SessionStatus.abandoned.code, now, startOfToday, SessionEndReason.userExit.code, SessionEndReason.interrupted.code, SessionStatus.inProgress.code)`
    - `closeStaleSessions(now:, startOfToday:)` → `closeSessionsStartedBefore(SessionStatus.abandoned.code, SessionEndReason.interrupted.code, now, SessionStatus.inProgress.code, startOfToday)`
    - `insertSession(row)` → `createSession(row)`
    - `sessionRow(id)` → `sessionById(id).getSingleOrNull()`
    - `_updateSession(id, values)` → `updateSessionRow(values, id)`
    - `setCursor`, `setCurrentMode` and `endSession` keep calling `_updateSession`.

- [ ] **Step 4: Build and match** the generated signatures. If `subtreeCountsOf`'s `nextDueAt` is not `DateTime?`, or `hasExample` is not `bool`, cast in the DAO, not the SQL.
- [ ] **Step 5: Verify and commit.**
  - Impact map: `"study_session_queries": ["study"]`, and add `"study"` to `live_row_queries`.
  - Run analyze, the guard, the guard tests, the CI tooling tests, and `TZ=UTC flutter test test/features/study/ test/architecture/`.
  - Commit: `refactor(study): StudySessionDao reads and writes through .drift (ADR-020 P5)`.

### Task 2: `StudyQueueDao`

**Files:** Create `lib/core/database/queries/study_queue_queries.drift`. Modify `study_queue_dao.dart`, the guard and the impact map.

- [ ] **Step 1: Red** on `study_queue_dao.dart`.
- [ ] **Step 2: Queries.** `study_queue_queries.drift`:

```sql
import '../tables/card.drift';
import '../tables/study.drift';

-- BR-STUDY-007: a queue row is 'pending' until it is served for good, then
-- 'completed'. A row at position -1 is enrolled in a round not built yet
-- (spec D7).

createQueueItem: INSERT INTO study_queue_items $row;

-- schema.md "cursor + available_at", BR-STUDY-005: the row :session_id
-- serves next in :mode at :cursor: in the lowest round with a pending row,
-- the first by position among the rows due at the cursor, else the one due
-- soonest. Nothing when the mode has no pending row or that round is not
-- built yet.
queueHeadRow(:session_id AS TEXT, :mode AS TEXT, :cursor AS INTEGER):
SELECT q.* FROM study_queue_items q
WHERE q.session_id = :session_id AND q.mode = :mode AND q.status = 'pending'
  AND q.position >= 0
  AND q.round = (SELECT MIN(p.round) FROM study_queue_items p
                 WHERE p.session_id = q.session_id AND p.mode = q.mode
                   AND p.status = 'pending')
ORDER BY q.available_at > :cursor,
  CASE WHEN q.available_at > :cursor THEN q.available_at ELSE 0 END,
  q.position
LIMIT 1;

-- match: :card_id's pending row in the lowest pending round of :mode, once
-- that round is built.
queueBoardRow(:session_id AS TEXT, :mode AS TEXT, :card_id AS TEXT):
SELECT q.* FROM study_queue_items q
WHERE q.session_id = :session_id AND q.mode = :mode AND q.status = 'pending'
  AND q.card_id = :card_id AND q.position >= 0
  AND q.round = (SELECT MIN(p.round) FROM study_queue_items p
                 WHERE p.session_id = q.session_id AND p.mode = q.mode
                   AND p.status = 'pending');

queueItemOf(:session_id AS TEXT, :mode AS TEXT, :round AS INTEGER,
  :card_id AS TEXT):
SELECT * FROM study_queue_items
WHERE session_id = :session_id AND mode = :mode AND round = :round
  AND card_id = :card_id;

updateQueueItem(:session_id AS TEXT, :mode AS TEXT, :round AS INTEGER,
  :card_id AS TEXT):
UPDATE study_queue_items SET $values
WHERE session_id = :session_id AND mode = :mode AND round = :round
  AND card_id = :card_id;

-- BR-STUDY-041: the options stored for a guess question, in the order shown.
guessOptionIdsOf(:session_id AS TEXT, :mode AS TEXT, :round AS INTEGER,
  :card_id AS TEXT):
SELECT option_card_id FROM study_guess_options
WHERE session_id = :session_id AND mode = :mode AND round = :round
  AND card_id = :card_id
ORDER BY slot;

-- Graded modes spec §7.6: the pending pairs of a round between two
-- positions, with each card's back_folded.
pendingMeaningsOf(:session_id AS TEXT, :mode AS TEXT, :round AS INTEGER,
  :from_position AS INTEGER, :to_position AS INTEGER) AS PendingMeaningRow:
SELECT q.card_id, c.back_folded FROM study_queue_items q
JOIN card c ON c.id = q.card_id AND c.delete_batch_id IS NULL
WHERE q.session_id = :session_id AND q.mode = :mode AND q.round = :round
  AND q.status = 'pending'
  AND q.position BETWEEN :from_position AND :to_position;

-- BR-STUDY-060, BR-STUDY-062: :card_id enrolls in :round of :mode once; a
-- second enrollment changes nothing.
enrollQueueItem(:session_id AS TEXT, :mode AS TEXT, :round AS INTEGER,
  :card_id AS TEXT):
INSERT OR IGNORE INTO study_queue_items
  (session_id, mode, round, card_id, position, status)
VALUES (:session_id, :mode, :round, :card_id, -1, 'pending');

queueHasPendingRowsOf(:session_id AS TEXT, :card_id AS TEXT):
SELECT EXISTS (SELECT 1 FROM study_queue_items
  WHERE session_id = :session_id AND card_id = :card_id
    AND status = 'pending');

lowestPendingRoundOf(:session_id AS TEXT, :mode AS TEXT):
SELECT MIN(round) FROM study_queue_items
WHERE session_id = :session_id AND mode = :mode AND status = 'pending';

-- Spec D7: whether :round of :mode still waits to be built.
roundIsUnbuilt(:session_id AS TEXT, :mode AS TEXT, :round AS INTEGER):
SELECT EXISTS (SELECT 1 FROM study_queue_items
  WHERE session_id = :session_id AND mode = :mode AND round = :round
    AND position < 0);

-- The cards of a round in serving order; a round not built yet lists them
-- by id, so a seeded shuffle of it repeats.
roundCardIds(:session_id AS TEXT, :mode AS TEXT, :round AS INTEGER):
SELECT card_id FROM study_queue_items
WHERE session_id = :session_id AND mode = :mode AND round = :round
ORDER BY position, card_id;
```

- [ ] **Step 3: DAO.** `@DriftAccessor(include: {study_queue_queries.drift})`, same accessor shape as Task 1. Keep the `_pending` / `_completed` / `_unbuilt` constants only where Dart still uses them; `leave` uses `_completed`, `insertFirstRound` uses `_pending`. Bodies:
  - `insertFirstRound(...)` → `for (final (position, cardId) in cardIds.indexed) await createQueueItem(StudyQueueItemsCompanion.insert(sessionId: …, mode: …, cardId: cardId, position: position, status: _pending, direction: Value(directions?[position])));`
    - The method becomes `async`.
    - Its doc comment adds: "One insert per card, inside the caller's transaction (ADR-020 D9)."
  - `headRow(s, m, cursor)` → `queueHeadRow(s, m, cursor).getSingleOrNull()`
  - `boardRow(s, m, cardId)` → `queueBoardRow(s, m, cardId).getSingleOrNull()`
  - Delete `_lowestPendingRound`.
  - `optionIds(row)` → `guessOptionIdsOf(row.sessionId, row.mode, row.round, row.cardId).get()`
  - `pendingMeanings(row, from:, to:)` → `{for (final p in await pendingMeaningsOf(row.sessionId, row.mode, row.round, from, to).get()) p.cardId: p.backFolded}`
  - `swapMeaningSlots(row, otherCardId)` → read `other` with `queueItemOf(row.sessionId, row.mode, row.round, otherCardId).getSingle()`, then the two `_update` calls as before.
  - `enroll(s, m, round, cardId)` → `enrollQueueItem(s, m, round, cardId)`
  - `hasPendingRows(s, cardId)` → `queueHasPendingRowsOf(s, cardId).getSingle()`
  - `lowestPendingRound(s, m)` → `lowestPendingRoundOf(s, m).getSingle()`
  - `isUnbuilt(s, m, round)` → `roundIsUnbuilt(s, m, round).getSingle()`
  - `cardsOf(s, m, round)` → `roundCardIds(s, m, round).get()`
  - `build(...)` → loop `updateQueueItem(StudyQueueItemsCompanion(position: Value(position)), sessionId, mode, round, cardId)`
  - `_update(row, values)` → `updateQueueItem(values, row.sessionId, row.mode, row.round, row.cardId)`

  Only the DAO uses `_unbuilt`, and the SQL now carries `-1`, so delete the constant if nothing else references it.
- [ ] **Step 4: Build and match. Step 5: Verify and commit.**
  - Impact map: `"study_queue_queries": ["study"]`.
  - Run `TZ=UTC flutter test test/features/study/ test/architecture/`.
  - Commit: `refactor(study): StudyQueueDao reads and writes through .drift (ADR-020 P5)`.

### Task 3: `StudyRoundDao`

**Files:** Create `lib/core/database/queries/study_round_queries.drift`. Modify `study_round_dao.dart`, the guard and the impact map.

- [ ] **Step 1: Red** on `study_round_dao.dart`.
- [ ] **Step 2: Queries.** `study_round_queries.drift`:

```sql
import '../tables/deck.drift';
import '../tables/card.drift';
import '../tables/srs.drift';
import '../tables/study.drift';

-- Graded modes spec §8.2: the built rows of a round in position order, with
-- each card's back_folded and the options its question has stored.
builtRoundRows(:session_id AS TEXT, :mode AS TEXT, :round AS INTEGER)
  AS BuiltRoundRow:
SELECT q.card_id, q.position, q.status, q.meaning_slot, c.back_folded,
  (SELECT COUNT(*) FROM study_guess_options o
   WHERE o.session_id = q.session_id AND o.mode = q.mode
     AND o.round = q.round AND o.card_id = q.card_id) AS option_count
FROM study_queue_items q
JOIN card c ON c.id = q.card_id AND c.delete_batch_id IS NULL
WHERE q.session_id = :session_id AND q.mode = :mode AND q.round = :round
  AND q.position >= 0
ORDER BY q.position;

-- BR-STUDY-038, package 2a spec D5: the cards a guess question can draw on,
-- those of the session's queue and the learned, active cards of :root_id's
-- tree, each with its back_folded; sorted, so a seeded draw repeats.
meaningSourceOf(:root_id AS TEXT, :session_id AS TEXT) AS MeaningSourceRow:
SELECT c.id, c.back_folded AS meaning_folded FROM card c
JOIN deck d ON d.id = c.deck_id
JOIN card_schedule cs ON cs.card_id = c.id
WHERE d.root_id = :root_id AND c.delete_batch_id IS NULL
  AND d.delete_batch_id IS NULL
  AND (cs.learned_at IS NOT NULL OR c.id IN
    (SELECT card_id FROM study_queue_items WHERE session_id = :session_id))
ORDER BY c.back_folded, c.id;

setRoundMeaningSlot(:slot AS INTEGER, :session_id AS TEXT, :mode AS TEXT,
  :round AS INTEGER, :card_id AS TEXT):
UPDATE study_queue_items SET meaning_slot = :slot
WHERE session_id = :session_id AND mode = :mode AND round = :round
  AND card_id = :card_id;

deleteGuessOptionsOf(:session_id AS TEXT, :round AS INTEGER,
  :card_id AS TEXT):
DELETE FROM study_guess_options
WHERE session_id = :session_id AND round = :round AND card_id = :card_id;

createGuessOption: INSERT INTO study_guess_options $row;
```

- [ ] **Step 3: DAO.** `@DriftAccessor(include: {study_round_queries.drift})`. Bodies:
  - `builtRows` → map `builtRoundRows(...)` rows into `RoundRowRecord`, with `isPending: r.status == 'pending'`.
  - `meaningSource` → `[for (final r in await meaningSourceOf(rootId, sessionId).get()) (cardId: r.id, meaningFolded: r.meaningFolded)]`
  - `setMeaningSlots` → loop `setRoundMeaningSlot(slot, sessionId, mode, round, cardId)`
  - `replaceOptions` → `deleteGuessOptionsOf(sessionId, round, cardId)`; return if `optionIds == null`; otherwise loop `createGuessOption(StudyGuessOptionsCompanion.insert(...))` in slot order. Its doc comment adds the D9 note.
- [ ] **Step 4: Build and match. Step 5: Verify and commit.**
  - Impact map: `"study_round_queries": ["study"]`.
  - Run the study and architecture tests.
  - Commit: `refactor(study): StudyRoundDao reads and writes through .drift (ADR-020 P5)`.

### Task 4: `StudyViewDao`

**Files:** Create `lib/core/database/queries/study_view_queries.drift`. Modify `study_view_dao.dart`, the guard and the impact map.

- [ ] **Step 1: Red** on `study_view_dao.dart`.
- [ ] **Step 2: Queries.** `study_view_queries.drift`:

```sql
import '../tables/deck.drift';
import '../tables/card.drift';
import '../tables/srs.drift';
import '../tables/study.drift';

-- BR-TRASH-002: a session's row with its deck's name and its root's
-- scheduler; nothing once its deck or root is in the Trash.
sessionWithDeckOf(:session_id AS TEXT) AS SessionDeckRow:
SELECT s.**, d.name AS deck_name, r.scheduler_type AS root_scheduler
FROM study_session s
JOIN deck d ON d.id = s.deck_id
JOIN deck r ON r.id = s.root_id
WHERE s.id = :session_id
  AND d.delete_batch_id IS NULL AND r.delete_batch_id IS NULL;

-- BR-STUDY-075, Study Home spec D6: the sessions Continue and Resume may
-- take up: open, started on or after :start_of_today, at the root's
-- generation, out of the Trash and with a queue row left; the newest, of
-- two started at once the higher id. Of any deck:
resumableSession(:start_of_today AS DATETIME) AS ResumableSessionRow:
SELECT s.**, d.name AS deck_name
FROM study_session s
JOIN deck d ON d.id = s.deck_id
JOIN deck r ON r.id = s.root_id
WHERE s.status = 'in_progress' AND s.started_at >= :start_of_today
  AND s.generation = r.generation
  AND d.delete_batch_id IS NULL AND r.delete_batch_id IS NULL
  AND EXISTS (SELECT 1 FROM study_queue_items q WHERE q.session_id = s.id)
ORDER BY s.started_at DESC, s.id DESC
LIMIT 1;

-- The same, of :deck_id only.
resumableSessionOfDeck(:start_of_today AS DATETIME, :deck_id AS TEXT)
  AS ResumableDeckSessionRow:
SELECT s.**, d.name AS deck_name
FROM study_session s
JOIN deck d ON d.id = s.deck_id
JOIN deck r ON r.id = s.root_id
WHERE s.status = 'in_progress' AND s.started_at >= :start_of_today
  AND s.generation = r.generation
  AND d.delete_batch_id IS NULL AND r.delete_batch_id IS NULL
  AND EXISTS (SELECT 1 FROM study_queue_items q WHERE q.session_id = s.id)
  AND s.deck_id = :deck_id
ORDER BY s.started_at DESC, s.id DESC
LIMIT 1;

-- Study Home spec D4: the earliest due date after :now of a learned card
-- out of the Trash.
nextDueAtAfter(:now AS DATETIME):
SELECT MIN(cs.due_at) FROM card c
JOIN deck k ON k.id = c.deck_id
JOIN card_schedule cs ON cs.card_id = c.id
WHERE c.delete_batch_id IS NULL AND k.delete_batch_id IS NULL
  AND cs.learned_at IS NOT NULL AND cs.due_at > :now;

modesOfSession(:session_id AS TEXT):
SELECT DISTINCT mode FROM study_queue_items WHERE session_id = :session_id
ORDER BY mode;

roundCountsOf(:session_id AS TEXT, :mode AS TEXT, :round AS INTEGER)
  AS RoundCountsRow:
SELECT COALESCE(SUM(status = 'completed'), 0) AS completed,
  COUNT(*) AS total
FROM study_queue_items
WHERE session_id = :session_id AND mode = :mode AND round = :round;

-- Graded modes spec §9, BR-TRASH-002: the options of a guess question in
-- the order shown; an option card in the Trash is left out.
guessOptionsOf(:session_id AS TEXT, :round AS INTEGER, :card_id AS TEXT)
  AS GuessOptionRow:
SELECT o.option_card_id, c.back FROM study_guess_options o
JOIN card c ON c.id = o.option_card_id
WHERE o.session_id = :session_id AND o.round = :round
  AND o.card_id = :card_id AND c.delete_batch_id IS NULL
ORDER BY o.slot;

-- Graded modes spec §9: the pairs of a round between two positions, a
-- board, in position order.
boardPairsOf(:session_id AS TEXT, :mode AS TEXT, :round AS INTEGER,
  :from_position AS INTEGER, :to_position AS INTEGER) AS BoardPairRow:
SELECT q.card_id, q.status, q.meaning_slot, c.front, c.back
FROM study_queue_items q
JOIN card c ON c.id = q.card_id AND c.delete_batch_id IS NULL
WHERE q.session_id = :session_id AND q.mode = :mode AND q.round = :round
  AND q.position BETWEEN :from_position AND :to_position
ORDER BY q.position;

-- BR-STUDY-048, BR-TRASH-002: the completed rows of a round in the order
-- served; a card in the Trash is left out.
trailOf(:session_id AS TEXT, :mode AS TEXT, :round AS INTEGER) AS TrailRow:
SELECT c.id, c.front, c.back, c.pronunciation, c.example
FROM study_queue_items q
JOIN card c ON c.id = q.card_id AND c.delete_batch_id IS NULL
WHERE q.session_id = :session_id AND q.mode = :mode AND q.round = :round
  AND q.status = 'completed' AND q.position >= 0
ORDER BY q.position;

-- FE-A6 D11: the distinct cards of the session's queue, those now learned,
-- its graded turns and the distinct cards they answered, and its logs whose
-- action is one of :lapse_actions.
summaryCountsOf(:session_id AS TEXT) AS SummaryCountsRow:
SELECT
  (SELECT COUNT(DISTINCT card_id) FROM study_queue_items
   WHERE session_id = :session_id) AS card_count,
  (SELECT COUNT(DISTINCT q.card_id) FROM study_queue_items q
   JOIN card_schedule cs ON cs.card_id = q.card_id
   WHERE q.session_id = :session_id AND cs.learned_at IS NOT NULL)
    AS learned_count,
  (SELECT COUNT(DISTINCT card_id) FROM review_log
   WHERE session_id = :session_id) AS answered_count,
  (SELECT COUNT(*) FROM review_log WHERE session_id = :session_id)
    AS turn_count,
  (SELECT COUNT(*) FROM review_log
   WHERE session_id = :session_id AND action IN :lapse_actions)
    AS wrong_count;
```

- [ ] **Step 3: DAO.** `@DriftAccessor(include: {study_view_queries.drift, live_row_queries.drift})`.
  - Keep the record typedefs.
  - Drop `_resumable` and `_newestFirst`.
  - Bodies:
    - `watchSessionRow(id)` → `tableChanges(attachedDatabase, [attachedDatabase.studySession, attachedDatabase.studyQueueItems, attachedDatabase.studyGuessOptions, attachedDatabase.deck, attachedDatabase.card, attachedDatabase.cardSchedule, attachedDatabase.reviewLog]).asyncMap((_) => sessionWithDeckOf(id).getSingleOrNull()).map((row) => row == null ? null : (session: row.s, deckName: row.deckName, schedulerType: row.rootScheduler!))`.
      - Update its doc comment: "…Emits again on every write the session screen can see, through `tableChanges`, since the read itself touches fewer tables."
      - Use the `!` only if `rootScheduler` is nullable in the generated row.
    - `watchDeckRow(id)` → `tableChanges(attachedDatabase, [deck, card, cardSchedule, appSettings, studySession, studyQueueItems] via attachedDatabase).asyncMap((_) => liveDeckRow(id).getSingleOrNull())`
    - `resumableSessionRow(deckId:, startOfToday:)` → when `deckId == null`, read `resumableSession(startOfToday)`; otherwise `resumableSessionOfDeck(startOfToday, deckId)`. Map to `(session: row.s, deckName: row.deckName)`.
    - `rootDeckRows` → keep `attachedDatabase.deckLevelOfRoots(startOfToday, now).get()`.
    - `nextDueAt(now:)` → `nextDueAtAfter(now).getSingle()`
    - `homeChanges()` → `tableChanges(attachedDatabase, [...same tables via attachedDatabase])`
    - `cardRow(id)` → `liveCardRow(id).getSingleOrNull()`
    - `modesOf(s)` → `(await modesOfSession(s).get()).toSet()`
    - `roundCounts` → `(completed: r.completed, total: r.total)`
    - `guessOptions` → `(cardId: r.optionCardId, back: r.back)`
    - `boardPairs` → map with `isCompleted: r.status == 'completed'`
    - `trail` → map
    - `summaryCounts(s, lapseActions:)` → `summaryCountsOf(s, lapseActions)`, mapped
- [ ] **Step 4: Build and match.** Read every generated signature. Check:
  - the nested field names (`s`) of `SessionDeckRow` and the resumable rows;
  - the nullability of `rootScheduler`, `completed` and `next due`;
  - that each `asyncMap` stream gives the same type as before.
- [ ] **Step 5: Verify and commit.**
  - Impact map: `"study_view_queries": ["study"]`.
  - Run `TZ=UTC flutter test test/features/study/ test/features/settings/ test/architecture/`.
  - Commit: `refactor(study): StudyViewDao reads through .drift (ADR-020 P5)`.

### Task 5: WBS and gate

- [ ] Run `dod_check.sh`. Expected: green.
- [ ] Set FE-D23 to `xong`, regenerate and check the docs, then commit `docs(wbs): FE-D23 done`.

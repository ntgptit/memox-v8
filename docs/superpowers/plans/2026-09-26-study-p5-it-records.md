# Study P5 — the host IT set, records closed — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** close FE-A6. It adds a test, carrying the scenario's id, for every host-layer (`HOST-FLOW`, `HOST-WIDGET`) study IT scenario that no test covers yet. It also closes or registers the deferred minors of P1–P4, and moves the records to their final state: index rows aligned, and WBS FE-A6 marked `xong`.

**Architecture:** no new product code, beyond three minor closures that do not change behaviour.

- `HOST-FLOW` scenarios are tested at the data layer (the repositories on the in-memory database), as `IT-LEARN-001` and `IT-CONT-001` already are.
- `HOST-WIDGET` scenarios are tested through the study screens and the app's routes, as `IT-NAV-008` is.

**Tech Stack:** Flutter 3.47.5, Riverpod 3, Drift (in-memory in tests).

**Spec:** [2026-09-26-study-ui-design.md](../specs/2026-09-26-study-ui-design.md) §3 (the P5 row), §4. Roadmap: [2026-09-26-study-chain-roadmap.md](2026-09-26-study-chain-roadmap.md) (P5; approved by the owner). Scenarios: [study IT](../../features/study/it-scenarios.md), [study-mode IT](../../features/study-mode/it-scenarios.md), [host coverage map](../../shared/testing/host-coverage-map.md).

**Rulings (pre-plan):**

- **P5-1:** `tools/docs/check.py` does not count IT ids; the roadmap assumed it did. The gap list is found by searching `test/` for each id in the two scenario files.
  - Eleven ids have no test. Seven are host-layer and in scope: `IT-CONT-004`, `IT-MODE-012`, `IT-NAV-009` and `IT-NAV-010` (`HOST-WIDGET`), and `IT-LEARN-011`, `IT-LEARN-012` and `IT-STUDY-002` (`HOST-FLOW`).
  - Four are `DEVICE-E2E` (`IT-CONT-008`, `IT-PLAT-002`, `IT-PLAT-003`, `IT-PLAT-005`). They run on a device, not in this suite, and stay listed as device work.
- **P5-2:** scenarios that expect a confirm on ✕ or system Back (`IT-CONT-004` step 1–2, `IT-NAV-010` step 1–2) are tested against the owner's ruling on D8: ✕ and Back end the session at once, with no confirm, and the same route shows "You left early". The scenario's own wording allows this ("if the UI uses one"). Steps 3–4 are tested as written.
- **P5-3:** `IT-NAV-009`'s "mode picker" screen is the Study Entry's inline review list in V8 (P3 E1: the first available mode is picked at first; nothing is written). The test pins what the scenario protects: no session is made, Back returns to the source deck, and a second visit offers no Continue.
- **P5-4:** a scenario already covered by a test that lacks its id gets that test tagged with the id, plus any missing step, instead of a duplicate test.

## Global Constraints

- Tests never read the wall clock (`libraryToday`, `FakeDayClock`, `_now`); cards live in a sub-deck leaf.
- A test's description carries the IT id in parentheses, as the existing ones do: `(IT-LEARN-011, BR-STUDY-003)`.
- No `pumpAndSettle` while a Recall clock runs.
- Records are Vietnamese where the file is (the WBS), English elsewhere.

## Review Focus

1. `IT-LEARN-011`: the limit is per session, not per day. A second session on the same day opens on the card left over.
2. `IT-LEARN-012`: an abandoned learning session leaves every card new, with nothing due. A new session starts again from Browse.
3. `IT-STUDY-002`: reading the entry (counts, badges) never writes a session; only Learn does.

---

## File map

| File | Action | Responsibility |
|---|---|---|
| `test/features/study/data/open_learning_session_test.dart` | modify | IT-LEARN-011 |
| `test/features/study/data/session_endings_test.dart` | modify | IT-LEARN-012 |
| `test/features/study/data/watch_entry_test.dart` | modify | IT-STUDY-002 |
| `test/features/study/presentation/study_session_screen_test.dart` | modify | IT-CONT-004, IT-NAV-010 |
| `test/features/study/presentation/study_self_assess_test.dart` (or the file holding 16a's reveal test), `study_entry_screen_test.dart` | modify | IT-MODE-012 |
| `test/app/library_routes_test.dart` | modify | IT-NAV-009 |
| `lib/features/study/presentation/widgets/sections/study_guess_widget.dart`, `study_fill_widget.dart`, `screens/study_session_screen.dart` | modify | three minor closures |
| `docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md` §9 | modify | two minors registered |
| index, WBS, spec §3, host coverage map | modify | records |

---

### Task 1: HOST-FLOW scenarios

**Files:** the three data tests above.

**Interfaces — Consumes:**
- `answerServed(db, sessions, id, right:)`, `servedCard`, `sessionOf` (`test/support/study_fixtures.dart`);
- `studyEntryRepository(db, now)`;
- the file's own setup helpers.

- [ ] **Step 1: IT-LEARN-011.** In `open_learning_session_test.dart`:
  1. Seed 21 new eight_box cards with examples and the limit at 20 (the file's existing limit test shows how the limit is set).
  2. Open a learning session and assert its queue holds 20 distinct cards.
  3. Answer every served turn right until the session is `completed` (a loop on `answerServed`, bounded at 20 × 6 × 3 turns to fail fast).
  4. Assert the entry reads `newCardCount == 1`.
  5. Open a second learning session on the same day: it succeeds and holds 1 card.
  6. Complete it, and assert the entry reads `newCardCount == 0`.
  7. Assert two sessions exist, each `completed`.
- [ ] **Step 2: IT-LEARN-012.** In `session_endings_test.dart`:
  1. Seed five new eight_box cards and open a learning session.
  2. Answer all of Browse, then one right and one wrong Match pair.
  3. Abandon it: `end_reason` is `user_exit`.
  4. Assert that every card is still new (`learned_at IS NULL`) and none has a schedule due (entry: `newCardCount 5`, `dueCardCount 0`, `resumable == null`).
  5. Open a new learning session: its `current_mode` is `browse`.
- [ ] **Step 3: IT-STUDY-002.** In `watch_entry_test.dart`:
  1. Seed five new cards.
  2. Read the entry (the watch stream's first value) and the deck counts twice.
  3. Assert `study_session` has 0 rows and `resumable == null`.
  4. Then `openLearningSession`: 1 row, `browse`.
- [ ] **Step 4:** Run `flutter test test/features/study/data`. Expected: PASS. If a step finds a bug, stop and ledger it: that is a finding, not a test to bend.
- [ ] **Step 5:** Commit: `test(study): host-flow IT scenarios IT-LEARN-011, IT-LEARN-012, IT-STUDY-002 (FE-A6 P5)`.

---

### Task 2: HOST-WIDGET scenarios

**Files:** the screen, entry, 16a and route tests above.

- [ ] **Step 1: IT-CONT-004 and IT-NAV-010** (P5-2). Tag the two existing tests in `study_session_screen_test.dart`: "✕ abandons at once…" gets `IT-CONT-004`, and "system Back mid-session abandons too…" gets `IT-NAV-010`. In each, answer one turn first, then add step 4: the session keeps its turn (`review_log` count 1, or the queue row's completed status for Browse), and the entry of its deck (`studyEntryRepository(...).watchEntry` first value) has `resumable == null`.
- [ ] **Step 2: IT-MODE-012.** Tag 16a's test that shows the grades only after Show answer, adding the double-tap guard if it is not asserted there (a second grade tap writes nothing). In `study_entry_screen_test.dart`, tag the eight_box list test with `IT-MODE-012` and assert that no row reads `cardModeSelfAssess`.
- [ ] **Step 3: IT-NAV-009** (P5-3). In `library_routes_test.dart`:
  1. Seed an eight_box deck with due cards.
  2. Open its Study Entry from the deck's action sheet, as `IT-NAV-008` does.
  3. Assert the review list shows, with Match picked.
  4. Press system Back: the deck shows again.
  5. Assert no `study_session` row exists.
  6. Open the entry again: no Continue banner (`studyEntryResumeTitle` or the resume widget absent).
- [ ] **Step 4:** Run `flutter test test/features/study test/app`. Expected: PASS.
- [ ] **Step 5:** Commit: `test(study): host-widget IT scenarios IT-CONT-004, IT-NAV-009, IT-NAV-010, IT-MODE-012 (FE-A6 P5)`.

---

### Task 3: Deferred minors of P1–P4

The only deferred minors are from P3 and P4; P1 and P2 deferred none that is still open. Each closure is behaviour-preserving, and the existing tests are its proof.

- [ ] **Step 1: Close.**
  - Guess's wrong announcement names `widget.item.back` (the served card's meaning is the right option's meaning, BR-STUDY-041) instead of a `firstWhere` with no `orElse`.
  - The screen's `_heldResultOf` becomes `turn.held?.result`, since the item on screen is the held one whenever a turn is held.
  - Fill's wrong-answer Continue is disabled while a write runs, as Recall's is.
- [ ] **Step 2: Register** in UI-base §9, continuing its numbering:
  - Match's and Guess's widget-local geometry constants (`_badgeTint`, `_ring`, `_columnOrder`) are named but not tokens (FE-A6 P3).
  - Screen 14's Learn row and footer are two tap paths to one action, as the kit draws them (FE-A6 P2).
- [ ] **Step 3:** Run `flutter test test/features/study`. Expected: PASS, with goldens unchanged (`TZ=UTC flutter test --tags golden test/features/study`).
- [ ] **Step 4:** Commit: `refactor(study): close P3–P4 deferred minors; register two in UI-base §9 (FE-A6 P5)`.

---

### Task 4: Records

- [ ] **Step 1:**
  - Index rows 14, 16, 16a and 17–21 → `aligned`.
  - Spec §3: the P5 row points to this plan.
  - `wbs_FE.md`: FE-A6 → `xong`, with P5 in its notes and next step "—". FE-A8 becomes the next item; its dependency on FE-A6 P1 is met.
  - The host coverage map: add each newly covered id's test file if the map lists test files (read its format first; change nothing if it maps layers only).
- [ ] **Step 2:** Run `python3 tools/docs/generate.py && python3 tools/docs/check.py`. Expected: PASS.
- [ ] **Step 3: Gate:** `GUARD_PY=python3.13 bash .claude/skills/flutter-workflow/scripts/dod_check.sh` and `TZ=UTC flutter test --tags golden`. Expected: green.
- [ ] **Step 4:** Commit: `docs(study): FE-A6 closed — index aligned, WBS, spec §3 (P5)`.

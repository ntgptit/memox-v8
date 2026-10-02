# Every query in `.drift`, P6 (progress, search, shared deck reads) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Take `deck_queries.drift` off `AppDatabase`. Move `ProgressDao`, `SearchDao` and `ReminderWorkloadDao` to `@DriftAccessor`s whose queries live in `.drift`, and take progress and search off the guard's temporary exclude.

**Architecture:** P0–P5 set the pattern (ADR-020).

- **Shared deck reads (owner ruling 2026-10-02, spec D3/D4 as written).**
  - **Which DAOs include it.** `deck_queries.drift` (`deckLevelOfRoots`, `deckLevelOfChildren`, `deckAndAncestors`) is included by every DAO that calls it: `DeckDao`, `StudyViewDao`, `ReminderWorkloadDao` and `ProgressDao`.
  - **Generated classes repeat.** Drift generates its result class `DeckTileRow` once per including accessor. The copies are only in generated code.
  - **Each feature uses its own copy.** Each feature's mapper imports the `DeckTileRow` of its own DAO's library, and no file imports two of them.
  - **`@DriftDatabase` holds tables only** from this phase on.
- **Fixed SQL instead of string templates.** Progress's `_answers`, `_cardDays`, `_childScope` and `_numbers`, and Search's `_live`, `_tierOf`, `_tagsOfCard` and `_cardHits`, are written out in each query that uses them, inside one file. This is P4's ruling.
- **Search's optional cursor clauses become nullable parameters.** `after` and `through` become `(:x_tier IS NULL OR (tier, front_folded, created_at, id) > (…))`. `limit` becomes `LIMIT COALESCE(:limit, -1)`, where SQLite reads -1 as no limit. That is one fixed statement in place of eight string variants. Checked on a probe: `AS INTEGER OR NULL` generates nullable Dart parameters.
- **Local-day arithmetic is cast.** Drift types `answered_at + :offset` as `DATETIME`, so each local-day expression in a selected column is `CAST(… AS INTEGER)`. The value is unchanged, because SQLite already divides integers. Checked on a probe.
- **Search tiers are literals.** `SearchTier.exact/prefix/contains` were interpolated as `.index`. They become `0/1/2` and "no tier" becomes `3`, and a test pins `SearchTier.values` to that order.

**Tech Stack:** Flutter 3.47.5, Drift 2.35, Python 3.13 guard.

**Spec:** `docs/superpowers/specs/2026-10-01-drift-queries-only-design.md` (§4 P3/P6; D1–D4, D11). ADR-020.

## Global Constraints

These are the same as P2–P5:
- Behaviour-preserving.
- Generated `*.g.dart` stays uncommitted.
- Guard commands use `python3.13`.
- Generated parameters follow first appearance in the SQL.
- Card and deck reads in `.drift` name `delete_batch_id`.
- Every new query file gets an impact-map owner row.
- Query names never collide with DAO members.
- DAO public APIs and record typedefs stay, so repositories do not change: `ActiveDayRow`, `CountsRow`, `LevelRow`, `SearchDeckRow`, `SearchCardRow`.

## Review Focus

1. **The four shared deck reads are unchanged.** The deck, study, reminder and progress paths still call the same statements. Only where they are included moved. Pinned by the Library, Study Home, reminder and progress tests.
2. **Progress numbers are unchanged.**
   - Same card-day rule (BR-PROGRESS-005), same scope (live cards, no `browse`), same week and month bounds.
   - The child level still counts the parent's own cards in the total only (BR-PROGRESS-004).
   - Pinned by the progress repository tests.
3. **Search order and paging are unchanged.** Same tiers, the key `(tier, front_folded, created_at, id)`, `after` exclusive and `through` inclusive, no `OFFSET` (BR-SEARCH-004, BR-SEARCH-007). Pinned by the search tests.

---

### Task 1: `deck_queries.drift` leaves `AppDatabase`

**Files:**
- `lib/core/database/app_database.dart`.
- `lib/features/deck/data/datasources/deck_dao.dart`.
- `lib/features/study/data/datasources/study_view_dao.dart`.
- `lib/features/reminders/data/datasources/reminder_workload_dao.dart` and `lib/features/reminders/data/mappers/reminder_workload_mapper.dart`.
- The impact map (`deck_queries` owners).

- [ ] **Step 1: Includes.**
  - Remove `deck_queries.drift` from `@DriftDatabase`.
  - `DeckDao` and `StudyViewDao` add it to their `include`. Their calls drop `attachedDatabase.`, and the "until P6" comments go.
- [ ] **Step 2: `ReminderWorkloadDao`.** It becomes `@DriftAccessor(include: {deck_queries.drift})`, `ReminderWorkloadDao(super.attachedDatabase)`, and `rootDeckRows` calls `deckLevelOfRoots(startOfToday, now).get()`. `reminder_workload_mapper.dart` imports `reminder_workload_dao.dart` for `DeckTileRow`.
- [ ] **Step 3: Impact map.** Change `"deck_queries": ["deck"]` to `["deck", "study", "reminders", "progress"]`.
- [ ] **Step 4: Verify.**
  - Run `dart run build_runner build --delete-conflicting-outputs`.
  - `flutter analyze` must be clean.
  - Run `flutter test test/features/deck test/features/study test/features/reminders test/architecture`.
- [ ] **Step 5: Commit.** `refactor(database): deck_queries.drift is included by its DAOs (ADR-020 P6)`.

### Task 2: `ProgressDao`

**Files:** Create `lib/core/database/queries/progress_queries.drift`. Modify `progress_dao.dart` (whole file), the guard scope, `MIGRATED_TO_DRIFT` and the impact map (`"progress_queries": ["progress"]`).

- [ ] **Step 1: Red.** Take `progress_dao.dart` off `scopes.yaml` and add it to `MIGRATED_TO_DRIFT`. Run the guard. Expected: exit 1 on that file.
- [ ] **Step 2: Queries.** Write `progress_queries.drift`:
  - **`progressActiveDays(:offset, :today)`.** Returns `int`.
  - **`progressWeekActivity(:offset, :week_start, :today) AS WeekActivityRow`.**
  - **`progressRootLevel(:offset, :week_start, :month_start, :today) AS ProgressLevelRow`.**
  - **`progressChildLevel(:deck_id, :offset, :week_start, :month_start, :today) AS ProgressLevelRow`.**

  Each has the old SQL, with the templates written out. In both level queries, `tiles.*` becomes the eight named number columns, and the total row selects `NULL, NULL` plus the eight numbers.
- [ ] **Step 3: DAO.**
  - Write `@DriftAccessor(include: {progress_queries.drift, deck_queries.drift})`.
  - The level reads map `ProgressLevelRow` to `LevelRow`; a null count is 0, as before.
  - `deckPath` is `deckAndAncestors(deckId).get()`.
  - `changes()` is `tableChanges(attachedDatabase, [...])`.
- [ ] **Step 4: Verify.**
  - Build. The generated `deckId`/`name` must be nullable. If Drift infers them non-null from the first select, write the total row's `NULL`s as `CAST(NULL AS TEXT)`.
  - Run the guard (green) and `flutter test test/features/progress test/architecture`.
- [ ] **Step 5: Commit.** `refactor(progress): ProgressDao reads through .drift (ADR-020 P6)`.

### Task 3: `SearchDao`

**Files:**
- Create `lib/core/database/queries/search_queries.drift`.
- Modify `search_dao.dart` (whole file).
- Update the guard scope, `MIGRATED_TO_DRIFT` and the impact map (`"search_queries": ["search"]`).
- Add one test to `test/features/search/` that pins the `SearchTier` order.

- [ ] **Step 1: Red.** Take the file off the guard's exclude list and run the guard. Expected: exit 1.
- [ ] **Step 2: Queries.**
  - **`searchDeckForest AS SearchDeckForestRow`.**
  - **`searchCardHits(:term, :after_tier, :after_text, :after_created_at, :after_id, :through_tier, :through_text, :through_created_at, :through_id, :limit) AS SearchCardHitRow`.**
    - The cursor and limit parameters are `OR NULL`.
    - The old CTE is written out, with tier literals 0–3.
    - The cursor clauses are guarded by `IS NULL`, with `LIMIT COALESCE(:limit, -1)`.
- [ ] **Step 3: DAO.**
  - Write `@DriftAccessor(include: {search_queries.drift})`.
  - `cardHits` passes the cursor's fields or nulls, then maps to `SearchCardRow`; tier 3 maps to null.
  - `changes()` is `tableChanges(attachedDatabase, [...])`.
- [ ] **Step 4: Tier pin.** Add a test asserting that `SearchTier.values` is `[exact, prefix, contains]` (the literals in `search_queries.drift`).
- [ ] **Step 5: Verify.** Build, then run the guard (green) and `flutter test test/features/search test/architecture`.
- [ ] **Step 6: Commit.** `refactor(search): SearchDao reads through .drift (ADR-020 P6)`.

### Task 4: WBS and gate

- [ ] **Step 1: WBS.** Set FE-D24 to done, with its plan link. Run `python3 tools/docs/generate.py`.
- [ ] **Step 2: Gate.** `bash .claude/skills/flutter-workflow/scripts/dod_check.sh` must be green.
- [ ] **Step 3: Review and PR.**
  - Run the final whole-branch review and fix its findings.
  - Open the PR stacked on P5 (#185).

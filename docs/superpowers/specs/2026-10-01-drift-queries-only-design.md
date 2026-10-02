# Every query in `.drift`: DAOs become Drift accessors

Status: approved by the owner 2026-10-01 (ADR-020) · 2026-10-01 · infrastructure refactor, no behaviour change

## 1. Intent

An investigation on master `8aaa29c` asked whether the app's SQL lives in `.drift`
files. It does not:

- `lib/core/database/queries/` holds 15 named queries in three files
  (`card_queries`, `deck_queries`, `trash_queries`).
- 82 calls pass SQL as a Dart string: `customSelect`, `customUpdate`,
  `customInsert`, `customStatement`. 49 sit in feature DAOs, 8 in `core/sync`,
  25 in migrations, bootstrap, `local_data_reset` and the log database.
- About 120 more go through Drift's Dart query builder (`select(…)..where`,
  `update(…).write`, `into(…).insert`, joins, `batch`), in about 26 files across
  `lib/features/*/data/datasources/`, `core/sync`, `core/auth` and `core/notes`.

So one DAO can read through a `.drift` query, a string and a builder chain, and
the SQL for a screen has no single place to be found, reviewed or checked.

The owner's ruling: **consistency is the requirement.** Every query, read or
write, is written in `.drift`. The Dart builder stays only to build an
`Expression` or `OrderingTerm` passed into a `.drift` query's `$predicate` or
`$order` placeholder.

Success, at the end of P8:

- no `customSelect` / `customUpdate` / `customInsert` / `customStatement` and no
  builder entry point (`select(`, `selectOnly(`, `update(`, `delete(`, `into(`,
  `.join(`, `batch(`) under `lib/` outside the three exceptions (D7);
- every DAO is a `@DriftAccessor` and `@DriftDatabase` includes tables only;
- the guard enforces it, and `dod_check.sh` is green;
- every existing test passes without a behaviour change.

## 2. Decisions

| # | Decision | Why |
|---|---|---|
| D1 | Every query lives in a `.drift` file under `lib/core/database/queries/`. | One place for SQL. `drift_dev` type-checks it against the schema at build time and generates `readsFrom` / `updates`, so a stream cannot go silent because a table was left out by hand. |
| D2 | Each DAO is `@DriftAccessor(include: {…})`, `final class XDao extends DatabaseAccessor<AppDatabase> with _$XDaoMixin`, constructed as `XDao(db)`. | Generated query methods land on the DAO that owns them, not on `AppDatabase`. About 200 queries on one class would be one global namespace with no owner. The constructor shape is unchanged, so repositories and providers do not change. |
| D3 | `.drift` query files are named by data topic (`tag_queries.drift`, `study_view_queries.drift`, `sync_outbox_queries.drift`). A DAO may include several files, and a file may be included by several DAOs. A DAO never calls another DAO. | A query used by two features (for example `deckLevelOfRoots`, used by deck, study and reminders) lives in one file both include. It is not copied, and features do not reach into each other's data layer. |
| D4 | `@DriftDatabase` includes `tables/*.drift` only. Each existing `queries/*` include moves to its DAOs when the last DAO that calls it through `AppDatabase` migrates. | Tables stay central (project baseline). Queries belong to accessors. |
| D5 | Naming. A read query is a noun for its result set (`cardDetail`, `trashDeckEntries`). A result with its own shape is named `AS …Row`. A write query is a verb (`insertDeleteBatch`). The DAO's public methods keep the `get` / `find` / `list` / `watch` / `count` / `exists` prefixes of `query-conventions.md`. | This matches the 15 queries already in the repo. The prefix contract stays where callers see it. |
| D6 | A shape that varies uses `$predicate` / `$order` placeholders and a `:row_limit` parameter. The `Expression` is built by a private helper in the DAO. | Drift checks the fixed part of the statement and composes the varying part safely. `CardListDao._predicate` stays the one source for the window, the filter counts and Select all (BR-CARD-012). |
| D7 | Exceptions, the only places SQL may stay in Dart: (a) migration code, meaning `app_database.dart` `onUpgrade` and `core/database/migrations/**`; (b) `customStatement('PRAGMA …')`; (c) `core/database/local_data_reset.dart`. | (a) A `.drift` query is checked against the current schema, while a migration step runs on an older schema. Using a current query there breaks once the schema moves again. (b) A PRAGMA is connection setup, not a query. (c) It deletes from a table list known only at run time. |
| D8 | The log database moves to `core/database/log/log.drift` (table and its one cleanup query). | The owner chose not to make it an exception: one convention, two databases. |
| D9 | `batch(…insertAll…)` in sync becomes a loop over a generated upsert inside the caller's transaction. | Generated queries cannot be batched. SQLite reuses the prepared statement inside a transaction. P7 measures a 1,000-row pull before and after. |
| D10 | Enforcement is a guard rule, `memox.data_model.queries_in_drift` (severity error), on a new scope `drift_query_sites`. Not yet migrated files are listed in a temporary exclude. Each PR from P1 to P7 removes its files, and P8 deletes the list. | The guard is where repo invariants live and it already runs in `dod_check.sh`. A new file is caught from P0 on. `check_drift.sh` is outside the gate and gets no second copy of the rule. |
| D11 | Behaviour-preserving refactor. Before a DAO migrates, its tests must cover what the migration could break: result order and tie-breakers, stream re-emission on each table it reads, null and empty results, and rollback for multi-statement writes. Gaps are filled with characterization tests first, against the current code. | The existing DAO and repository tests are the safety net only where they exist. |
| D12 | Each migrated hot query (card list window, study queue, Library levels, search, progress) gets an `EXPLAIN QUERY PLAN` check before and after, in the PR description. | The rewrite must not lose an index. |

## 3. Feasibility (spike, thrown away)

Run on Drift 2.35 against this schema, then deleted before any commit:

| Capability | Result |
|---|---|
| `@DriftAccessor(include: queries/x.drift)` referencing tables declared on `AppDatabase` | Generates methods on `_$XDaoMixin` |
| `INSERT INTO deck $row ON CONFLICT (id) DO UPDATE SET …` | Takes `Insertable<Deck>` (a Companion), generates `updates: {deck}`, a watching stream re-emits |
| `WHERE id IN :ids` | Generates `List<String> ids` |
| `WHERE $predicate` | Takes `Expression<bool> Function(Card c)`. `readsFrom` includes the predicate's tables |
| `WITH RECURSIVE` | Works |

`$predicate` makes the query's parameters positional in the generated
signature. DAO helpers name them at their own boundary.

## 4. Phases

Each phase is one PR and leaves `dod_check.sh` green.

| Phase | Scope |
|---|---|
| **P0** | Foundation: ADR-020, guard rule + scope + tests, skill/docs updates, `check_drift.sh` noise fix, WBS rows, pilot `TrashDao` + `AccountDeviceDao` (§5) |
| P1 | `tag_dao`, `settings_dao`, `starter_dao`, `core/notes/dismissed_note_store` |
| P2 | `card_dao`, `card_list_dao` (`$predicate`, `$order`), `card_detail_dao`; `card_queries.drift` leaves `@DriftDatabase` |
| P3 | `deck_dao`, `reminder_workload_dao`; `deck_queries.drift` split by topic where D3 needs it (`deckLevelOfRoots`, `deckLevelOfChildren` and `deckAndAncestors` are also called by study and progress, so their include leaves `@DriftDatabase` when P6 migrates the last caller) |
| P4 | `srs_dao` (shared `_ofTree` predicate becomes a `.drift` fragment or a `$predicate` helper) |
| P5 | `study_queue_dao`, `study_session_dao`, `study_round_dao`, `study_view_dao` |
| P6 | `progress_dao`, `search_dao` (heaviest string composition) |
| P7 | `core/sync/*` adapters and `sync_store`, `core/auth/account_store` (D9) |
| P8 | Log database to `log.drift` (D8); delete the temporary exclude; `@DriftDatabase` holds tables only |

The phase order is a default. A later phase may move earlier if feature work is
about to touch its files.

## 5. P0 in detail

### 5.1 ADR-020

`docs/shared/decisions/ADR-020-moi-truy-van-nam-trong-drift.md`, `status: active`
once the owner approves this spec. Contents: context (§1 figures), decision
(D1–D9), exceptions (D7), consequences (generated `readsFrom`/`updates`; `batch`
becomes a loop; `AppDatabase` stops carrying queries), and rollback (an
accessor's include can move back to `@DriftDatabase` with no schema change).

### 5.2 Guard rule

In `code-verification-guard-v2/registries/projects/memox-v8/rules/memox-data-model-rules.yaml`:

- `memox.data_model.queries_in_drift`, `type: regex`, `severity: error`.
- Patterns, line-anchored with the comment exemption the file's other rules use:
  - `\bcustom(?:Select|Update|Insert|Statement|WriteReturning)\s*\(` unless the
    same line's first argument starts with `'PRAGMA`;
  - builder entry points on a database or accessor: `\b(?:select|selectOnly|update|delete|into)\s*\(\s*(?:_?db\.|attachedDatabase\.)?[a-z]\w*\s*\)`,
    `\.join\s*\(\s*\[`, `\bbatch\s*\(`.
- Scope `drift_query_sites` in
  `code-verification-guard-v2/registries/projects/memox-v8/config/scopes.yaml`:
  include `lib/features/*/data/**/*.dart` and `lib/core/**/*.dart`, exclude `**/*.g.dart`,
  `lib/core/database/schema_versions.dart`, `lib/core/database/migrations/**`,
  `lib/core/database/app_database.dart`, `lib/core/database/local_data_reset.dart`,
  and the temporary list of files not yet migrated. That list sits under a
  comment that names this spec and says P1–P7 shrink it and P8 deletes it.
- Tests in `code-verification-guard-v2/tests/test_memox_v8_data_model_guard_rules.py`,
  both ways: each pattern fires on a violating line, and stays quiet on a
  generated-query call, a `PRAGMA` statement, a comment, an `Expression` built
  inside a `$predicate` helper, and `tableChanges(…)`.

The pattern list is a starting point. Writing the tests in the plan is where
false positives are found and the patterns tightened (agent-yaml-contract:
improve the rule, not the source, for a false positive).

### 5.3 Rules and docs

Each says the same thing as ADR-020, in its own words:

- `.claude/skills/flutter-feature-slice/SKILL.md` §Step 2 (line 127): every query in
  `.drift`; DAOs are accessors; the three exceptions.
- `.claude/skills/flutter-drift/SKILL.md` Step 1–2 and the review path.
- `.claude/skills/flutter-drift/references/dynamic-sql.md`: the level table
  becomes "static `.drift` query, or a `.drift` query with `$predicate`/`$order`".
  Levels 3 and 4 are allowed only inside D7's exceptions.
- `.claude/skills/flutter-drift/references/layering.md`: a DAO is a `@DriftAccessor`.
- `.claude/skills/flutter-drift/references/project-baseline.md`: the layout
  (`queries/` by topic, included by accessors) and D7.
- `.claude/skills/flutter-drift/references/review-checklist.md`: an anti-pattern
  row for SQL or builder chains in Dart.
- `.claude/skills/flutter-data-layer/` wherever it describes how a DAO queries.

### 5.4 `check_drift.sh`

`check_drift.py` skips `lib/core/database/schema_versions.dart` (generated; 19
false ERRORs today). No new rule here (D10).

### 5.5 Pilot

- `TrashDao`: becomes an accessor including `trash_queries.drift`. That file
  also holds `insertDeleteBatch`, `deckIsInTrash` and
  `closeSessionsTouchingBatch`, which `card_dao` and `deck_dao` call through
  `AppDatabase`. Those three move to a new `delete_batch_queries.drift` that
  stays on `@DriftDatabase` until P2 and P3. The rest of `trash_queries.drift`
  leaves `@DriftDatabase` now. `TrashDao`'s three builder calls move into
  `trash_queries.drift`.
- `AccountDeviceDao`: becomes an accessor including a new
  `account_device_queries.drift` for its `app_settings` read, its `welcome_seen`
  write and its one `customSelect`.
- Tests: `test/features/trash/data/*` (3 files) and
  `test/features/account/data/account_device_repository_impl_test.dart`. Gaps
  are filled per D11 before the code moves.
- Both DAOs leave the guard's temporary exclude.

### 5.6 WBS

Rows P0–P8 in `docs/wbs_FE.md` §"Hạ tầng và kiểm chứng", P0 marked in progress.

### 5.7 Verification

- `dart run build_runner build --delete-conflicting-outputs` is clean, and
  `check_generated` agrees.
- `bash .claude/skills/flutter-workflow/scripts/dod_check.sh` is green. It covers
  format, analyze, architecture, the guard, the guard's self-tests and the full
  suite.
- The guard is shown to catch a deliberate violation (a `customSelect` added to
  a migrated DAO), which is then removed.
- No golden changes; nothing under `presentation/` changes.

## 6. Out of scope

- Any schema change, index change or migration. Queries move as they are;
  a query that looks wrong is filed, not fixed in passing.
- Splitting `.drift` table files by feature (the project baseline declines it).
- `memox-api-services/` (frozen) and `supabase/` SQL (server side, its own gate).
- Tests under `test/` that call `customSelect` to inspect rows. Test helpers are
  not app queries, and the guard scope is `lib/` only.

## 7. Risks

| Risk | Mitigation |
|---|---|
| A rewritten query changes order or drops a tie-breaker | D11 characterization tests; `check_drift.sh` ordering checks |
| A stream that used to re-emit on a table no longer does, or the reverse | Generated `readsFrom` is now derived from the SQL. A screen that relied on a hand-added table it does not read (for example `watchDeckRow` listing `card_schedule`) keeps that through `tableChanges` in the DAO, and its test proves it |
| `$predicate` changes a hot query's plan | D12 |
| Sync pull slows down without `batch` | D9 measurement in P7; if it regresses, the ADR records the exception before P7 merges |
| Phases stall half-way | Each phase stands alone; the guard keeps new code on the convention whatever the pace |

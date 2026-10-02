# Every query in `.drift`, P8 (log database, end of the exclude) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Declare the log database's table, index and every query in `lib/core/database/log/log.drift` (D8). Then delete the guard's temporary exclude, so the rule holds over all of `lib/` minus its permanent exceptions (D7, D10).

**Architecture:**
- **Same table, no migration.**
  - `log_entry` moves from a Dart `Table` to `CREATE TABLE … AS "LogRow/LogEntries"`, which keeps both generated names, so no caller changes. The `/` form is Drift's own override of the table class name.
  - `log_entry_occurred_at` becomes a `CREATE INDEX` in the file, so `createAll` makes it. `onCreate` loses its hand-made index.
  - A characterization test, committed first, pins the table that `PRAGMA table_info`/`index_list` report on today's code: columns, types, NOT NULL, the `'{}'` default, key and index. Installed devices keep their schema-version-1 table untouched.
- **Queries on `LogDatabase`.** The log database has no DAO, and D8 puts the table and its queries in one file that `@DriftDatabase` includes.
  - `insertAll` loses its `batch`: it becomes a loop over `INSERT OR IGNORE … $row` inside one transaction (D9's pattern).
  - The Not sent list's optional level filter is `(:level_count = 0 OR level IN :levels)`, as in the card list (P2).
  - `prune`'s two deletes become `pruneExpiredLogs` and `pruneLogExcess`. The short-lived levels `debug` and `info` are literals.
- **The exclude ends.**
  - `drift_query_sites` keeps only its permanent excludes: migrations, `schema_versions.dart`, `app_database.dart` and `local_data_reset.dart`.
  - The guard test that lists the temporary exclude now asserts it is empty.
  - The spec's P8 row and the ADR need no change.

**Spec:** `docs/superpowers/specs/2026-10-01-drift-queries-only-design.md` (§4 P8; D7, D8, D10). ADR-020.

## Review Focus

1. **The log table is byte-for-byte the same schema.** Pinned by `log_schema_test.dart`, written before the move.
2. **Every log read and write behaves as before.** This covers order, the 300-character list cut, the level filter, `byId`, prune by age then by cap, and `insertOrIgnore`. Pinned by `log_database_test.dart`, `log_database_pending_test.dart`, `log_shipper_test.dart` and the monitoring tests.
3. **The guard now covers all of `lib/`** except D7's exceptions.

### Task 1: characterization test

- [ ] Add `test/core/database/log/log_schema_test.dart` and run it green on today's code.
- [ ] Commit: `test(log): pin the log table's schema before it moves to .drift`.

### Task 2: `log.drift`

- [ ] **Red.** Take `log_database.dart` off the exclude and add it to `MIGRATED_TO_DRIFT`. The guard must fail.
- [ ] **`log.drift`.** Write the table, the index, and these queries:
  - `insertLogEntry`;
  - `oldestLogRows`;
  - `pendingLogLines` (`AS PendingLogLine`);
  - `logRowById`;
  - `deleteLogRows`;
  - `logEntryCount`;
  - `pruneExpiredLogs`;
  - `pruneLogExcess`.
- [ ] **`LogDatabase`.** Use `@DriftDatabase(include: {'log.drift'})` with no Dart table, and call the generated methods.
- [ ] **Verify.** Build, run the guard, then `flutter test test/core/database/log test/core/logging test/features/monitoring test/app/logging_bootstrap_test.dart test/core/database/tracing_interceptor_test.dart`.
- [ ] Commit: `refactor(log): the log database's table and queries live in log.drift (ADR-020 P8)`.

### Task 3: the exclude ends

- [ ] Delete the temporary exclude from `scopes.yaml`. Make the guard test assert there is none, and update its comment.
- [ ] Mark FE-D25 done, then run the docs generator and the gate.
- [ ] Run the final review, then open the PR stacked on P7 (#187).

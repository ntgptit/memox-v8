# Database error guard: one helper instead of nine copies

Status: draft for owner review · 2026-09-29 · infrastructure refactor, no behaviour change

## 1. Intent

An external review of master `227698d0` found the Future half of database error
mapping copied into nine repositories. The owner chose to remove the copies (sub-project
A of that review; B, logging and Drift tracing, and D, network interceptors, follow as
their own specs; C, dropping thin use cases, was not taken: ADR-011 D4/D5 stands).

Today:

- Streams are already uniform: `Stream.mapDatabaseErrors()` in `core/error/failure.dart`.
- Futures are not. Nine repositories define the same private helpers:
  - `_mapped(body)`: run `body`, and rethrow any error as `mapDatabaseError(error)`
    with its stack trace;
  - `_write(body)`: `_mapped(() => _db.transaction(body))`, or the same inlined.

  Files: `card_repository_impl`, `card_transfer_repository_impl`, `deck_repository_impl`,
  `settings_repository_impl`, `schedule_repository_impl`,
  `starter_library_repository_impl` (only `_mapped`), `study_entry_repository_impl`,
  `study_session_repository_impl`, `tag_repository_impl` (only `_write`, inlined).
  About 67 call sites.
- Three more repositories inline the same `try … mapDatabaseError` without a helper:
  `reminder_workload_repository_impl` (`rootWorkloads`), `schedule_repository_impl`
  (`scheduleOf`) and `trash_repository_impl` (`_purge`, around a transaction). Found by the
  D5 test during the build; they move to the same helpers.

Success: the nine private helpers are gone; each call site uses one shared helper;
every existing test passes unchanged; no repository constructor, provider or DI file
changes.

## 2. Decisions

| # | Decision | Why |
|---|---|---|
| D1 | `guardDatabase<T>(Future<T> Function() body)` in `core/error/failure.dart`, beside `mapDatabaseError` and `Stream.mapDatabaseErrors()` | It is `_mapped`, word for word; the Future twin of the stream extension, in the file that owns the mapping |
| D2 | `extension MappedTransaction on AppDatabase { Future<T> mappedTransaction<T>(Future<T> Function() body) }` in `core/database/mapped_transaction.dart` | It is `_write`: `guardDatabase(() => transaction(body))`. It needs `AppDatabase`, so it lives in `core/database`, and `core/error` keeps not importing the database |
| D3 | A closure, not an extension on `Future` | `_mapped` also catches an error thrown while the body builds its future; `future.mapDatabaseErrors()` would not |
| D4 | No class, no provider, no new constructor parameter | Owner ruling 2026-09-29 (helper + extension over an injected `DatabaseExecutor`): a pass-through layer with DI churn in nine repositories, their providers and their tests buys nothing the helper does not |
| D5 | An architecture test keeps it so: outside `lib/core/`, no file calls `mapDatabaseError(` | Stops the copy from coming back; the stream extension and the two helpers are the only entry points |
| D6 (DEV-178) | A second architecture test keeps D2 so: under `lib/features/*/data/`, a raw `transaction(` body calls no write (`test/architecture/write_gate_test.dart`, rules in `write_gate_rules.dart`, allowlist by `file#member` with a reason) | The account's gate (auth spec R3) sits in `mappedTransaction`; a write through a raw transaction would pass it by. `ScheduleRepositoryImpl.initializeCard` was the one such write and now joins its caller through `mappedTransaction` |

## 3. Changes

| Where | Change |
|---|---|
| `lib/core/error/failure.dart` | Add `guardDatabase` (D1, D3) |
| `lib/core/database/mapped_transaction.dart` | New: `MappedTransaction` (D2) |
| The nine repositories, and the three inline sites | Delete `_write`/`_mapped`; `_write(x)` → `_db.mappedTransaction(x)`, `_mapped(x)` → `guardDatabase(x)`; drop imports no longer used |
| `test/core/error/failure_test.dart` | `guardDatabase`: a `SqliteException` leaves as its `Failure` with the original stack trace; a value passes through; a synchronous throw in the body is mapped too |
| `test/core/database/mapped_transaction_test.dart` | New: a throw inside rolls the transaction back and leaves as a `Failure`; a success commits |
| `test/architecture/` | D5 |

## 4. Verification

- The repository and invariant tests already cover each repository's error paths; they
  must pass without edits.
- `dod_check.sh` full gate; goldens are unaffected (no UI change).

## 5. Risks

- A repository whose `_write` differed subtly from the others would change behaviour.
  Checked on master: all nine are the same two shapes (§1). The plan diffs each before
  deleting it.
- Rollback: revert the PR.

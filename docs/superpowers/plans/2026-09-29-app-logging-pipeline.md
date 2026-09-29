# App Logging Pipeline (B1) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Every log in the app goes through `AppLogger`, is buffered in its own Drift database, and is pushed to an admin-only `public.app_log` table on Supabase, with retention by level and a status for warnings and errors.

**Architecture:** `core/logging` holds the record, the logger, a console sink, a buffer sink over a separate `LogDatabase`, and a `LogShipper` that reuses `SyncScheduler` for timing and backoff. The Supabase migration adds the table, the admin check, three RPCs, a server-side log helper and a `pg_cron` purge. Capture points: a Drift `QueryInterceptor`, Flutter/platform error hooks, a Riverpod `ProviderObserver`, a GoRouter `NavigatorObserver`, lifecycle, sync, and the four existing `dart:developer` calls.

**Tech Stack:** Flutter 3.47.5, Drift 2.35, Riverpod 3, supabase_flutter, package_info_plus (new, owner-approved), Postgres/pgTAP.

**Spec:** `docs/superpowers/specs/2026-09-29-app-logging-design.md` (and ADR-018)

## Global Constraints

- Every level is persisted and pushed, `debug` included (spec §3, owner ruling).
- Nothing is redacted (ADR-018 §1).
- The log database never gets an interceptor, and a log write never logs itself.
- `LogConfig.persistMinLevel` defaults to `debug`.
- Retention: `debug`/`info` 7 days; `warning`/`error` 180 days. The device cap is 50 000 rows, dropping `debug` first, then `info`, then `warning`/`error`.
- `log_push` takes at most 500 entries and uses `on conflict (id) do nothing`.
- The admin check is `app_metadata.role = 'admin'`; a non-admin call raises `FORBIDDEN`.
- Supabase tables have RLS on, no policy, and no client privileges (ADR-015 pattern).
- Outside `lib/core/logging/`, no file imports `dart:developer`.
- No log call may block or fail the caller: sink errors go to the console only.

## Review Focus

1. **A burst of `debug` rows during study.** The buffer batches, so there is one write
   per 2 s or per 50 entries, not one per log. Task 2 has a test that 120 logs cause
   at most 3 writes.
2. **The app killed between a log call and the flush.** Entries still in memory are
   lost, but everything already flushed survives. Task 2 flushes on pause; a test
   checks that a pause flushes.
3. **A push that times out after the server inserted.** The retry sends the same ids,
   and the server keeps one row each. Task 4 has a pgTAP test for a double push.
4. **The tracer and a log write feeding each other forever.** The log database has no
   interceptor. Task 5 has a test that a log write adds no traced statement.
5. **A non-admin calling the admin RPCs.** They get `FORBIDDEN`. Task 4 has a pgTAP
   test for this.

---

### Task 1: Record, logger, console sink

**Files:**
- Create: `lib/core/logging/log_entry.dart`, `lib/core/logging/app_logger.dart`, `lib/core/logging/console_sink.dart`, `lib/core/logging/log_config.dart`
- Test: `test/core/logging/app_logger_test.dart`

**Interfaces (Produces):**
- `enum LogLevel { debug, info, warning, error }` (ordered; `code` = name)
- `enum LogCategory { ui, navigation, state, db, sync, reminder, lifecycle, server }`
- `final class LogEntry` with the §2 client fields (`id`, `occurredAt`, `level`, `category`, `event`, `message`, `errorType`, `errorMessage`, `stackTrace`, `context` `Map<String, Object?>`, `deviceId`, `appVersion`, `buildNumber`, `platform`, `osVersion`), `toJson()` and `fromJson()`
- `abstract interface class LogSink { void write(LogEntry entry); Future<void> flush(); }`
- `final class AppLogger { void debug/info/warning/error(String event, {LogCategory category = LogCategory.state, String? message, Object? error, StackTrace? stackTrace, Map<String, Object?> context = const {}}); static void install(AppLogger logger); }` and top-level `AppLogger get appLogger`
- `final class LogStamp` holding `deviceId`, `appVersion`, `buildNumber`, `platform`, `osVersion`, set once by bootstrap
- `final class LogConfig { final LogLevel persistMinLevel; const LogConfig({this.persistMinLevel = LogLevel.debug}); }`

- [ ] **Step 1: Write failing tests.**
  - An `error` call with an error and a stack builds one entry with `errorType`,
    `errorMessage` (with a `Failure`'s `cause` appended) and `stackTrace`, and hands it
    to every sink.
  - Each entry gets a fresh v4 `id`, and `occurredAt` from the injected clock in UTC.
  - A sink that throws does not throw from the log call, and the other sinks still
    receive the entry.
  - Before `install`, `appLogger` is a console-only logger.
  - `LogEntry.toJson` / `fromJson` round-trips, with `context` kept as a map.
- [ ] **Step 2: Run** `flutter test test/core/logging/app_logger_test.dart` — Expected: FAIL (missing files).
- [ ] **Step 3: Implement.**
  - `AppLogger({required List<LogSink> sinks, DateTime Function()? now, LogStamp? stamp})`.
  - `_log` builds the entry and writes to each sink inside `try/catch`, sending the
    sink's own error to `developer.log`.
  - `errorMessage` is `error.toString()`, and for a `Failure` it adds `' cause: ${failure.cause}'`.
  - `ConsoleSink` calls `developer.log('[$event] $message', name: category.name, level: <800/900/1000 by level>, error:, stackTrace:)`.
- [ ] **Step 4: Run** — Expected: PASS.
- [ ] **Step 5: Commit** `feat(logging): the log record, AppLogger and the console sink`.

### Task 2: Log database and buffer sink

**Files:**
- Create: `lib/core/logging/log_database.dart` (+ `.g.dart`), `lib/core/logging/buffer_sink.dart`
- Test: `test/core/logging/log_database_test.dart`, `test/core/logging/buffer_sink_test.dart`

**Interfaces:**
- Consumes: `LogEntry`, `LogSink`, `LogLevel`.
- Produces:
  - `@DriftDatabase(tables: [LogEntries]) class LogDatabase` with `schemaVersion 1`, an
    `insertAll(List<LogEntry>)`, `oldest(int limit) → List<LogEntry>`,
    `deleteIds(Iterable<String>)`, `prune({required DateTime now, int cap = 50000})`
    and `watchPending()`;
  - `LogDatabase openLogDatabase() => LogDatabase(driftDatabase(name: 'memox_logs'))`;
  - `BufferSink(LogDatabase db, {Duration flushEvery = 2 s, int flushAt = 50, LogConfig config})`.

- [ ] **Step 1: Write failing tests** (in-memory `NativeDatabase.memory()`):
  - Insert then `oldest` returns entries in `occurred_at` order.
  - `deleteIds` removes only those rows.
  - `prune` drops `debug`/`info` older than 7 days and `warning`/`error` older than
    180 days, and past the cap drops `debug`, then `info`, then the rest, oldest first.
  - `BufferSink`: 120 writes inside `fakeAsync` cause at most 3 inserts; `flush()`
    writes what is queued; entries below `persistMinLevel` are dropped; an insert that
    throws is caught.
- [ ] **Step 2: Run** — Expected: FAIL.
- [ ] **Step 3: Implement.**
  - The table is `log_entry`:
    - columns `id` text pk, `occurred_at` int (epoch ms UTC), `level`, `category`,
      `event`, `message`, `error_type`, `error_message`, `stack_trace`, `context` (JSON
      text), `device_id`, `app_version`, `build_number`, `platform`, `os_version`;
    - index `(occurred_at)`.
  - Run `dart run build_runner build --delete-conflicting-outputs`.
  - The migration strategy is `createAll` only (version 1).
  - Its schema dump goes in `drift_schemas/log_database/`, if the repo's drift
    verification scripts expect a dump for each database; otherwise ledger a ruling.
- [ ] **Step 4: Run** — Expected: PASS.
- [ ] **Step 5: Commit** `feat(logging): the log buffer in its own Drift database`.

### Task 3: Supabase table, RPCs, server log, retention

**Files:**
- Create: `supabase/migrations/20261003000000_app_log.sql`
- Test: `supabase/tests/database/09_app_log.sql`
- Modify: `supabase/tests/database/01_schema_privileges.sql` and `04_function_privileges.sql` (if they enumerate tables and functions)

- [ ] **Step 1: Write the pgTAP test first**, in `07_account_settings_sync.sql`'s style (`set local role authenticated; set_config('request.jwt.claims', …)`):
  - `app_log` has no privileges for `anon` and `authenticated`, and RLS is on;
  - `log_push` inserts 2 entries, and `user_id` is the claim's `sub`, not a value from
    the client;
  - pushing the same 2 ids again keeps 2 rows;
  - 501 entries raise `VALIDATION_FAILED`, and so does a level outside the list;
  - a `warning` arrives with status `open`, an `info` with status null;
  - a non-admin calling `log_query` or `log_set_status` raises `FORBIDDEN`;
  - an admin (claims `app_metadata.role = 'admin'`) gets the rows from `log_query`,
    filtered by level and paginated by cursor;
  - `log_set_status(id, 'fixed', 'note')` stamps `status_changed_by` and `status_note`;
  - `private.log_server('warning', …)` writes a `source = 'server'` row;
  - `private.purge_app_log()` deletes an `info` 8 days old and an `error` 181 days old,
    and keeps an `info` 6 days old and an `error` 179 days old;
  - a cron job named `app-log-retention` exists.
- [ ] **Step 2: Try it locally:** `npx supabase db start` then `npx supabase test db`
  (Docker). Expected: the new file fails. If Docker is unavailable, ledger it and verify
  in Step 4 through CI.
- [ ] **Step 3: Write the migration.**
  - The table as in spec §2, with `check` constraints on `level`, `source`, `category`
    and `status`, and the three indexes.
  - `revoke all … from public, anon, authenticated` and `enable row level security`.
  - `private.is_admin()`.
  - `public.log_push(entries jsonb)`: security definer, `search_path = ''`, raises
    `NOT_AUTHENTICATED` / `VALIDATION_FAILED`, uses `insert … select from jsonb_to_recordset`
    and `on conflict (id) do nothing`, and returns `{accepted: [ids]}`.
  - `public.log_query(filter jsonb)` and `public.log_set_status(log_id uuid, new_status text, note text)`.
  - `private.log_server(...)` and `private.purge_app_log()`.
  - `create extension if not exists pg_cron`, then `select cron.schedule('app-log-retention', '41 3 * * *', 'select private.purge_app_log()')`.
  - Grants: execute on the three public RPCs to `authenticated` only.
  - `public.sync_push` is replaced to call `private.log_server('warning', 'sync',
    'sync.rejected', …)` for each rejected result. The body is otherwise identical to
    the last migration that defined it; copy it verbatim.
- [ ] **Step 4: Run** the pgTAP suite locally, or else trigger the CI workflow on the
  branch (`workflow_dispatch`, job `supabase`) and read its result. Expected: PASS.
- [ ] **Step 5: Commit** `feat(supabase): app_log, log_push and the admin log RPCs, retention by level`.

### Task 4: Log API and shipper

**Files:**
- Create: `lib/core/logging/log_api.dart`, `lib/core/logging/log_shipper.dart`, `lib/core/logging/di/logging_providers.dart`
- Test: `test/core/logging/log_shipper_test.dart`

**Interfaces:**
- Consumes: `LogDatabase`, `RpcCall`/`SessionGuard` (from `supabase_sync_api.dart`), `SyncScheduler`.
- Produces:
  - `LogApi({required SessionGuard ensureSession, required RpcCall rpc})` with
    `push(List<LogEntry>) → Set<String> accepted`;
  - `LogShipper(LogDatabase db, LogApi api, {int batch = 500})` with `runOnce()`;
  - providers `logDatabaseProvider` (keepAlive), `logApiProvider`, and
    `logSchedulerProvider` (a `SyncScheduler` over `runOnce`, with triggers
    `Stream.periodic(5 min)` merged with lifecycle resumes; null when Supabase is off).

- [ ] **Step 1: Write failing tests:**
  - `runOnce` sends the oldest 500 and deletes exactly the accepted ids;
  - it loops until fewer than 500 remain;
  - a thrown RPC keeps the rows and rethrows, so the scheduler backs off;
  - an empty buffer makes no call.
- [ ] **Step 2: Run** — Expected: FAIL.
- [ ] **Step 3: Implement.** The shipper's own failures go to `developer.log` in
  `core/logging` only, and never to `appLogger`.
- [ ] **Step 4: Run** — Expected: PASS.
- [ ] **Step 5: Commit** `feat(logging): LogShipper pushes the buffer to Supabase`.

### Task 5: Capture points and bootstrap

**Files:**
- Create: `lib/core/database/tracing_interceptor.dart`, `lib/core/logging/log_provider_observer.dart`, `lib/app/router/log_navigator_observer.dart`
- Modify:
  - `lib/core/database/connection.dart` (`.interceptWith(TracingInterceptor())`);
  - `lib/main.dart`: installs the logger with the stamp from `package_info_plus`, the
    device id and `Platform`; sets `FlutterError.onError` and
    `PlatformDispatcher.instance.onError`; adds `ProviderContainer(observers: [LogProviderObserver()])`;
    starts `logSchedulerProvider`; logs lifecycle start;
  - `lib/app/app.dart` or the lifecycle owner: resume and pause (a pause flushes the
    buffer);
  - `lib/app/router/app_router.dart`: GoRouter `observers`;
  - `lib/core/sync/sync_coordinator.dart` and `sync_scheduler.dart`: `appLogger` events;
  - `lib/features/reminders/di/reminder_background_bindings.dart`;
  - `pubspec.yaml` (`flutter pub add package_info_plus`).
- Create: `test/architecture/logging_rules_test.dart`
- Test: `test/core/database/tracing_interceptor_test.dart`, `test/core/logging/log_provider_observer_test.dart`, `test/app/log_navigator_observer_test.dart`

- [ ] **Step 1: Write failing tests:**
  - **Tracer** (with `openTestDatabase(interceptor: TracingInterceptor(logger: fake))`):
    - a select logs `debug db.query` with `sql`, `args` and `duration_ms`;
    - a statement made slow by a clock seam at 60 ms logs `info db.slow_query`, and one
      at 200 ms logs `warning`;
    - a failing statement logs `error db.query_failed` and rethrows the original error;
    - a transaction logs one `debug db.transaction`;
    - writing through `BufferSink` to a `LogDatabase` adds no tracer event.
  - **Observer:** a provider that throws logs `error state.provider_failed` with the
    provider's name; a `Failure` logs `warning`.
  - **Navigator observer:** a push logs `info nav.push` with the route's name.
  - **Architecture:** outside `lib/core/logging/`, no file imports `dart:developer`
    (plus its planted-violation test).
- [ ] **Step 2: Run** — Expected: FAIL.
- [ ] **Step 3: Implement** each capture point. Then move the four existing calls to
  `appLogger` (`warning`/`error`, with the error and stack).
- [ ] **Step 4: Run** `flutter analyze` and `flutter test --exclude-tags golden` — Expected: all pass.
- [ ] **Step 5: Commit** `feat(logging): capture points — Drift tracing, errors, providers, navigation, lifecycle, sync`.

### Task 6: Docs and gate

**Files:**
- Modify:
  - `docs/shared/rules/BR-CORE-002-khong-log-noi-dung.md`: `status: superseded`,
    `superseded_by: ADR-018`;
  - `docs/shared/decisions/ADR-002-…md` and `ADR-016-…md`: a note on the rows ADR-018
    replaces;
  - `.claude/skills/flutter-ship/SKILL.md` "Logging": point to `core/logging` and
    ADR-018;
  - `supabase/README.md`: how the owner sets `app_metadata.role = 'admin'` for their
    user id (SQL `update auth.users set raw_app_meta_data = raw_app_meta_data || '{"role":"admin"}' where id = '<uuid>'`),
    and that the cron job runs daily;
  - `docs/wbs_BE.md` / `docs/wbs_supabase.md`: a line for B1 done, B2 next.
- [ ] **Step 1:** Edit the docs; run `python3 tools/docs/generate.py`.
- [ ] **Step 2:** Run the `dod_check.sh` full gate and `TZ=UTC flutter test --tags golden` — Expected: green; goldens unchanged.
- [ ] **Step 3: Commit** `docs: ADR-018 supersedes BR-CORE-002; admin setup for the log RPCs`.

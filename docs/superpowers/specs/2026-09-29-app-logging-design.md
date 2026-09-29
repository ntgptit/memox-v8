# App logging: one pipeline from every layer to an admin-only table

Status: draft for owner review · 2026-09-29 · decisions in
[ADR-018](../../shared/decisions/ADR-018-log-tap-trung-va-monitoring.md)

## 1. Intent

Sub-project B of the 2026-09-29 infrastructure review, reshaped by the owner. The
immediate goal is a log pipeline that lets a later admin monitoring app (and, from this
work on, a Monitoring section in Settings) see everything the app and the server did:
UI, data, sync, errors, slow queries.

Owner rulings (2026-09-29):

- Log everything, including card content, SQL arguments and tokens. BR-CORE-002 is
  superseded (ADR-018 §1).
- Logs live on Supabase; the device only buffers them until it can push.
- Retention: `debug`/`info` for 7 days; `warning`/`error` for 6 months.
- `warning`/`error` carry a status, `open` or `fixed`, that an admin sets.
- For now only the admin uses the app. Monitoring lives in Settings and is shown only
  to an admin.
- Build the whole pipeline now: client, table, RPCs, cron and screen.

Success:

- Every log call in `lib/` goes through `AppLogger`; no `dart:developer` call is left
  outside `core/logging`.
- A log written offline reaches `public.app_log` after the next successful push, exactly
  once.
- The admin sees and triages logs in Settings › Monitoring; a non-admin sees no entry
  and gets `FORBIDDEN` from the admin RPCs.
- The retention job deletes by level and age, and the pgTAP tests prove it.

## 2. The record

One schema for client and server (`app_log` on Supabase, `log_entry` in the device
buffer; the same fields):

| Field | Type | Notes |
|---|---|---|
| `id` | uuid | Generated where the log is written; the push is idempotent on it |
| `occurred_at` | timestamptz | When it happened (UTC, ADR-008) |
| `level` | text | `debug` · `info` · `warning` · `error` |
| `source` | text | `app` · `server` |
| `category` | text | `ui` · `navigation` · `state` · `db` · `sync` · `reminder` · `lifecycle` · `server` |
| `event` | text | Dotted name, e.g. `db.slow_query`, `sync.push_failed`, `nav.push`, `ui.uncaught` |
| `message` | text | Free text, may hold content |
| `error_type` | text? | `runtimeType` of the error |
| `error_message` | text? | `toString()` of the error, and its `cause` for a `Failure` |
| `stack_trace` | text? | Full trace |
| `context` | jsonb | Any key/values: ids, SQL, arguments, `duration_ms`, route, provider name |
| `user_id` | uuid? | Set by the server from `auth.uid()`, never trusted from the client |
| `device_id` | text? | The sync device id (`SyncStore.deviceId`) |
| `app_version`, `build_number`, `platform`, `os_version` | text? | `platform`/`os_version` from `dart:io` `Platform`; version and build from `package_info_plus` (owner approved the dependency, §8) |
| `status` | text? | `open` for `warning`/`error` on arrival, null otherwise; `fixed` when an admin marks it |
| `status_changed_at`, `status_changed_by`, `status_note` | | Set by `log_set_status` |
| `received_at` | timestamptz | Server time of insert |

## 3. Client

```
AppLogger ──► ConsoleSink (dart:developer, every level)
          └─► BufferSink ──► LogDatabase (memox_logs, own Drift file)
                                   │
                         LogShipper ── log_push(entries) ──► Supabase public.app_log
```

- **`core/logging/app_logger.dart`**: `AppLogger` with `debug`/`info`/`warning`/
  `error(String event, {String? message, Object? error, StackTrace? stackTrace,
  Map<String, Object?> context, LogCategory category})`. One instance, installed at
  bootstrap (`AppLogger.install`) and read through `appLogger` (top level), because
  logging happens where there is no `Ref`: the Drift interceptor, the reminder
  background isolate and `main`. A `Provider` exposes the same instance for code that
  has a `Ref`. Before `install`, and in tests, it has the console sink only.
- **`BufferSink`** queues entries in memory and writes them in one batch every 2 s, or
  at 50 entries, or when the app pauses. A failed write falls back to the console and
  never logs itself.
- **`LogDatabase`** (`core/logging/log_database.dart`): its own Drift database, file
  `memox_logs`, one table `log_entry` with §2's fields (no status columns), and no
  interceptor. Pruning runs at start: `debug`/`info` older than 7 days, `warning`/`error`
  older than 180 days, and a hard cap of 50 000 rows. Past the cap, the oldest `debug`
  rows go first, then `info`, and `warning`/`error` last.
- **`LogShipper`** (`core/logging/log_shipper.dart`) runs at start, on resume, when a
  push succeeds after the connection returns, and every 5 minutes while the app is in
  the foreground. It sends up to 500 entries per `log_push` call, oldest first, and
  deletes the ids the server accepted. On failure it keeps the rows and backs off like
  `SyncScheduler`; the failure goes to the console only.
- **Every level is persisted and pushed, `debug` included** (owner ruling 2026-09-29).
  The tracer logs every statement, and watch streams re-run their queries on each write,
  so study produces many `debug` rows. Three things keep this affordable: the
  `BufferSink` batches, the log database is separate, and `debug` lives 7 days. When
  the local cap bites, `debug` rows go first.

### What is logged (the capture points)

| Where | Level · event | Context |
|---|---|---|
| Drift `QueryInterceptor` on `AppDatabase` (`core/database/tracing_interceptor.dart`) | every statement `debug db.query`; ≥ 50 ms `info db.slow_query`; ≥ 150 ms `warning db.slow_query`; a failing statement `error db.query_failed` | `sql`, `args`, `duration_ms`, `kind` (select/insert/…/transaction/batch) |
| `FlutterError.onError`, `PlatformDispatcher.instance.onError` | `error ui.uncaught` | library, widget context |
| Riverpod `ProviderObserver.providerDidFail` | `error state.provider_failed` (a `Failure`: `warning`) | provider name, argument |
| GoRouter `NavigatorObserver` | `info nav.push` / `nav.pop` / `nav.replace` | route location, arguments |
| App lifecycle | `info lifecycle.start` / `resume` / `pause` | app version |
| Sync (`SyncCoordinator`, `SyncScheduler`) | `info sync.push` / `sync.pull` (counts, duration); `warning sync.rejected`; `error sync.failed` | entity, id, code, counts |
| Reminders (`main`, background bindings) | the two existing calls, as `warning reminder.*` | error |

The four existing `dart:developer` calls move to `appLogger`. An architecture test
forbids `dart:developer` imports outside `lib/core/logging/`.

## 4. Server (Supabase migration)

- **Table** `public.app_log` (§2): RLS on, no policy, all privileges revoked from
  `anon` and `authenticated`, as for the sync tables. It has indexes on
  `(occurred_at desc)`, `(level, status, occurred_at desc)` and `(user_id, occurred_at desc)`.
- **`private.is_admin()`**: `coalesce(auth.jwt()->'app_metadata'->>'role', '') = 'admin'`.
- **`public.log_push(entries jsonb) returns jsonb`**, for authenticated users:
  - refuses a call of more than 500 entries;
  - skips, rather than refuses, a row it cannot take (bad level, category, id,
    time or shape), returns its id as accepted so the device drops it, and logs
    `warning server.log_rejected` with the count: one bad row must not block every
    later log of a device;
  - keeps a context over 256 kB as its `kind` and `sql` plus `truncated: true`, so
    one bulk import cannot fill the Free-tier database;
  - inserts with `user_id = auth.uid()` and `status = 'open'` for `warning`/`error`;
  - uses `on conflict (id) do nothing`;
  - returns the accepted ids and the number skipped.
- **Client, the same concern:** `AppLogger` replaces NUL and lone UTF-16 surrogates,
  which Postgres cannot store; `LogShipper` halves a batch the server refuses whole
  until the refused row is alone, and drops it only when the row after it goes
  through (a broken RPC refuses both, so it never empties the buffer); the log push
  never signs in itself, it waits for sync's session. The reminder's background
  isolate logs to the same buffer and writes it before the fire ends.
- **`public.log_query(filter jsonb) returns jsonb`**, admin only (otherwise `FORBIDDEN`):
  - filters on level, source, category, status, text search on `event`/`message`, a
    date range and user;
  - keyset pagination on `(occurred_at, id)`, 100 per page.
- **`public.log_set_status(log_id uuid, new_status text, note text)`**, admin only:
  `open` ↔ `fixed`, stamps `status_changed_at` and `status_changed_by`.
- **`private.log_server(level, category, event, message, context)`** writes a
  `source = 'server'` row. The sync RPCs call it where they reject an operation
  (`warning sync.rejected`) and in `exception` blocks (`error server.exception`).
- **`private.purge_app_log()`** deletes `debug`/`info` older than 7 days and
  `warning`/`error` older than 180 days, counted from `received_at`: a device clock
  set years ahead cannot keep a row forever. `private.log_server` never fails its
  caller, so a log that cannot be written does not roll back a sync. `cron.schedule('app-log-retention', '41 3 * * *', ...)`
  runs it daily; the migration enables `pg_cron` if it is off.
- **pgTAP** (`supabase/tests/database/09_app_log.sql`) covers:
  - privileges and admin checks;
  - `log_push` idempotency, validation and `user_id`;
  - query filters and pagination;
  - status changes;
  - purge by level and age.

## 5. Settings › Monitoring (admin only)

- A **Monitoring** row in Settings, shown when the session's `app_metadata.role` is
  `admin` (read from the Supabase session; the RPCs enforce it again).
- **Screen** with two tabs:
  - **Server:** `log_query` results, newest first; filter chips for level and status;
    a search field; infinite scroll.
  - **Not sent:** the device buffer, read-only.
- **Row:** level badge, event, time, first line of the message, status badge.
- **Detail:**
  - message, error, stack trace and pretty-printed context;
  - device, app and platform;
  - **Mark fixed** / **Reopen** with an optional note.
- **Design:** the kit has no such screen, so Impeccable `shape` runs before its plan
  (CLAUDE.md, a screen's workflow). It is a data-dense admin tool built from the
  existing Mx widgets; its states are loading, empty, error, not admin and offline
  (the server tab says so, the not-sent tab still works).

## 6. Delivery

Two plans, each a PR:

1. **B1, pipeline:** `core/logging`, `LogDatabase`, `BufferSink`, `LogShipper`, tracing
   interceptor, capture points, moving the four calls, the architecture test, the
   Supabase migration with pgTAP, ADR-018 and the BR-CORE-002/ADR-002/ADR-016 updates.
2. **B2, Monitoring screen:** the Impeccable shape, then the screen, its controller over
   the two RPCs, l10n en/vi, goldens and the visual-audit companion.

## 7. Risks

- **Volume:** every statement is persisted at `debug` (owner ruling). If the upload or
  the table grows too much, the knob is `LogConfig.persistMinLevel` (default `debug`),
  not the architecture.
- **Push cost:** it is batched and runs only when the app is in the foreground; a
  failure never blocks study or sync.
- **Tokens in logs:** accepted by the owner (ADR-018 §1). Nothing logs the Supabase
  session on purpose, but `args` or an error message could carry one.
- **Rollback:**
  - B1: revert the PR. The `memox_logs` file stays on the device, harmless.
  - B2: revert the PR.

## 8. Owner rulings on the open points

- **D-dep (2026-09-29):** add `package_info_plus` to stamp `app_version` and
  `build_number`.
- **Persisted level (2026-09-29):** `debug` and above, not `info` and above.

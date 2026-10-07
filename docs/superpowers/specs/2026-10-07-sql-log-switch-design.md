# SQL log switch: an admin turns statement logging on or off, per account

Status: draft for owner review · 2026-10-07 · amends
[ADR-018](../../shared/decisions/ADR-018-log-tap-trung-va-monitoring.md) §3 and the
[app logging spec](2026-09-29-app-logging-design.md) §3; extends the
[library and study sync spec](2026-09-28-sync-library-and-study-design.md) §3.5

## 1. Intent

The tracer logs every statement `AppDatabase` runs as a `debug db.query` row with its
SQL text and arguments (ADR-018 §3). The owner keeps that while the app is under test:
an admin follows performance and checks the data from the log (ruling 2026-10-07,
DEV-207). The cost is volume: a bulk sync writes 3–4 rows per change, and every study
answer 30–50 rows. The owner asked (2026-10-07) for a switch an admin flips on screen,
stored with the account so every device of that account follows it, taking effect at
once without a restart.

Owner rulings (2026-10-07):

- The switch is a setting of the **account**, not of the device: it syncs like the
  study and display settings (SB-S5), so an admin signing in on another phone gets it.
- It is **on by default** while the app is under test.
- Off drops only the per-statement `debug db.query` rows. Slow and failed statements
  and the per-transaction row stay, so an admin still sees what went wrong.
- The switch is shown in two places, both admin-only: Settings › Admin (screen 23) and
  Monitoring › Not sent (screen 28).

Success:

- An admin flips the switch; the next statement on that device is, or is not, logged,
  with no restart.
- The same account on a second device follows after its next pull.
- A non-admin never sees the switch; their account still carries the column (default
  on) and nothing changes for them.
- `dod_check.sh` passes; the Supabase pgTAP suite passes on a machine with Docker.

## 2. Out of scope

- Changing the default to off for release: a later decision, one migration.
- A server-side switch an admin sets for every account at once.
- Reducing the rows in any other way (a summary entry per bulk apply, statement names
  instead of SQL): rejected by the ruling on DEV-207.
- Syncing other device-only settings (reminders, dismissed notes, the welcome flag):
  each has its own ruling and stays as it is.

## 3. Data and sync

### 3.1 Local column

`app_settings.log_sql_statements INTEGER NOT NULL DEFAULT 1 CHECK (log_sql_statements IN (0, 1))`,
schema 15, migration step 14→15: `addColumn`; every existing row gets `1`. Documented
in `schema.md` (the `app_settings` table and the SB-S5 line).

### 3.2 Synced, the fifth account-settings column

- The update trigger `app_settings_sync_update` queues the account-settings row when
  this column changes too. A trigger cannot be altered, so the step drops and recreates
  it (as step 12→13 did for the deck and card triggers).
- Wire (sync spec §3.5): row key `logSqlStatements`, a boolean. `AccountSettingsSyncDao`
  puts it in the pushed row and applies it from a pulled row; a pulled row without the
  key leaves the column as it is, so a server not yet migrated breaks nothing.
- `LocalDataReset` (an account switch) resets the synced settings to their defaults,
  this column included (back to on); the first pull of the new account sets it.
- "Use app defaults" on screen 23 resets the study and display settings. It does
  **not** touch this column: the switch is an admin's tool, not a person's preference.
- Conflicts between two devices follow SB-S5 as for the other four columns.

### 3.3 Server

One new migration (never editing one already pushed):

- `alter table public.account_settings add column log_sql_statements boolean not null default true`;
- `create or replace function private.account_settings_change(...)`: the row gains
  `'logSqlStatements', s.log_sql_statements`;
- `create or replace function private.account_settings_upsert(...)`: reads
  `coalesce((r->>'logSqlStatements')::boolean, true)`, so an older app that pushes
  without the key keeps the default.

pgTAP, in a new file after `07_account_settings_sync.sql`: a push with the key stores
it and the next `sync_changes` returns it; a push without the key stores `true`; the
column has no client privilege (the schema-privileges test already covers the table).

### 3.4 Verification constraint

`npx supabase test db` and `tools/supabase/run_auth_it.sh` need Docker, which the
cloud container does not have. The server part is verified on the owner's machine (or
a session with Docker) before the PR merges; the PR says so. The Dart side, the
migration step and the trigger are covered by the gate.

## 4. The switch at runtime

### 4.1 `SqlLogSwitch`

`core/logging/sql_log_switch.dart`: a `ValueNotifier<bool>` subclass with one job,
whether the tracer logs `db.query`. It starts `true` (the column's default) so the
statements that run before the first read are logged as today.

### 4.2 The tracer reads it

`TracingInterceptor({SqlLogSwitch? sqlLog})`. In `_done`, when the elapsed time is
under `slowMs` and the switch is off, nothing is logged. `db.slow_query` (info and
warning), `db.query_failed` and `db.transaction` are unchanged. `openAppDatabase` takes
the switch and hands it to the tracer; `database_provider.dart` reads it from
`sqlLogSwitchProvider` (keep-alive, in `core/logging/di/logging_providers.dart`).

### 4.3 The row feeds the switch

The row in `app_settings` is the only source of truth. A keep-alive provider in
`core/logging/di` listens to the settings DAO's watch of the column (a stream, as
`watchAppSettings` is) and sets the switch; the UI writes the row and never the switch.
The same stream drives the toggle in both screens, so they agree with the tracer.

When the value changes, the logger writes one `info logging.sql_statements_changed`
row with `{'enabled': bool}`, so the server log explains why `db.query` rows stop or
start on a device.

### 4.4 Settings feature

- `AppSettingsEntity` gains `logSqlStatements`; the mapper reads the column.
- `SettingsRepository.setLogSqlStatements({required bool enabled})`, one transaction
  like `setTheme`; a use case `SetLogSqlStatementsUseCase`.
- `AccountSettingsSyncDao.readRow` and `upsertFromServer` carry the key (3.2).

## 5. UI

One widget in the monitoring feature, `MonitoringSqlLogRowWidget`: an `MxSettingsRow`
with the database tile, label "Log SQL statements", a one-line subtitle, and a trailing
`MxToggle`; the toggle is disabled while a save is in flight; a failed save shows the
settings error snackbar and the toggle returns to the row's value. The widget reads the
settings stream and calls the use case.

- Screen 23, Admin section: the third row after Monitoring and Users, through the
  `adminRows` slot `app/router/admin_routes.dart` fills. Visible only while the account
  is an admin, as the section already is.
- Screen 28, Not sent tab: the same widget above the `MxNote`, under the admin gate the
  screen already has.
- Copy (en / vi): "Log SQL statements" / "Ghi câu SQL vào log"; subtitle "Each
  statement the app runs is logged, for performance checks. Turn off to keep the log
  small." / "Mỗi câu lệnh app chạy đều được ghi log để kiểm tra hiệu năng. Tắt để log
  gọn." TalkBack reads the row as a switch with its label.
- Goldens: `settings_admin_rows_*` and `monitoring_not_sent_*` change; a golden review
  before merge. `DESIGN.md` does not change (no new component or token). The detail
  files 23 and 28 and their rows in the screen index record the row. Impeccable
  critiques both screens against `DESIGN.md` before the plan (CLAUDE.md, a screen's
  workflow).

## 6. Testing

- Migration step: the column exists with default `1` on an upgraded database; existing
  rows keep their other values.
- Trigger: changing the column queues one `account_settings` upsert; changing
  `reminder_enabled` still queues nothing.
- `AccountSettingsSyncDao`: the pushed row carries `logSqlStatements`; a pulled row
  applies it; a pulled row without the key leaves it.
- `LocalDataReset`: the column returns to `1`.
- Tracer: with the switch off no `db.query` is logged while `db.slow_query`,
  `db.query_failed` and `db.transaction` are; flipping it on mid-run logs the next
  statement.
- The feeding provider: a row update moves the switch and logs the `info` row once.
- Repository: `setLogSqlStatements` writes the column and `updated_at` in one
  transaction; "Use app defaults" leaves it.
- Widget: the row in both screens shows the value, calls the use case on a tap, and is
  absent for a non-admin.
- pgTAP (3.3), on a machine with Docker.

## 7. Risks

- Off on a device loses per-statement rows for diagnosing that device; the admin chose
  it, and the `info` row marks when.
- A device on an old build keeps logging until it updates, and its pushes carry no
  key, so the server's `coalesce` stores `true` and turns the account's switch back on.
  Accepted while under test: every tester runs the current build.
- Rollback: revert the app PR; the server column stays, harmless, and the old
  functions can be restored by a further migration.

## 8. Owner rulings on the open points

- **Where it lives (2026-10-07):** the account, synced as the fifth account-settings
  column; both screens 23 and 28 show it.
- **Default (2026-10-07):** on, while the app is under test.
- **What off removes (2026-10-07):** only `debug db.query`.

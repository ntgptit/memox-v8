# SQL log switch Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** An admin flips "Log SQL statements" on screen 23 or 28; the tracer stops or resumes its `debug db.query` rows at once on that device, and every device of the account follows after its next pull.

**Architecture:** A fifth synced column of `app_settings` (`log_sql_statements`, SB-S5 path: local trigger, `AccountSettingsSyncDao`, one Supabase migration). A `SqlLogSwitch` (`ValueNotifier<bool>`) in `core/logging` that the tracer reads and a feeder provider keeps equal to the row. One toggle row widget in the settings feature that `app/` composes into both screens through slots, as the Admin rows already are (ADR-011: a feature never imports another feature's `presentation/`).

**Tech Stack:** Flutter 3.47, Riverpod 3 codegen, Drift (`.drift` queries, `drift_dev` schema snapshots), Supabase SQL + pgTAP, gen-l10n (en, vi), goldens in the Linux container.

**Spec:** [`docs/superpowers/specs/2026-10-07-sql-log-switch-design.md`](../specs/2026-10-07-sql-log-switch-design.md). Also read ADR-018 §3, ADR-011 (import rules), the sync spec §3.5 ([`2026-09-28-sync-library-and-study-design.md`](../specs/2026-09-28-sync-library-and-study-design.md)), the logging spec §3 ([`2026-09-29-app-logging-design.md`](../specs/2026-09-29-app-logging-design.md)) and `.claude/skills/flutter-drift/references/migrations.md`.

## Preconditions

1. `master` holds DEV-207 (PR 255, `lib/core/logging/buffer_sink.dart` has `cap`) and the spec commit `0c3f199`. Verify: `grep -n "this.cap = logBufferCap" lib/core/logging/buffer_sink.dart`.
2. `flutter pub get` and `dart run build_runner build --delete-conflicting-outputs` ran once on this checkout; `flutter gen-l10n` too.
3. Docker is **not** in the cloud container: Task 7's pgTAP suite runs on the owner's machine (spec §3.4). Everything else runs here.

Keep an **execution ledger** at the end of this file as you go: one line per task with its commit and any deviation from the plan, with the reason. It travels to the PR.

## Deviations from the spec, decided here

- **Where the toggle widget lives (spec §5 says the monitoring feature):** it lives in the **settings** feature (`SqlLogRowWidget`), because it reads the settings stream and calls a settings use case, which ADR-011 forbids another feature's `presentation/` from importing. `MonitoringScreen` gains a `pendingHeader` slot and `app/` passes the widget in, exactly as `SettingsScreen.adminRows` works. Task 8 records this in spec §5.
- **How the feeder reads the row (spec §4.3 says the settings DAO):** `core/logging` cannot import `features/settings`, so the feeder reads one `.drift` query of its own (`sql_log_queries.drift`, `SqlLogDao` in `core/logging`), the same shape as `core/auth`'s `AccountDeviceDao` over `account_device_queries.drift`. Task 8 records it.

## Impeccable critique, before the plan (CLAUDE.md, a screen's workflow step 3)

Judged against `DESIGN.md` › Components:

- The row is an `MxSettingsRow` with a trailing `MxToggle`, the exact pairing the Reminder row uses; no new component, token or copy pattern. `DESIGN.md` does not change.
- Screen 23: a third row in the Admin `MxSection`, which already draws the hairlines; the lead tile uses `AppIcons.levelDebug` (the glyph the log list already uses for the debug level), tinted, like Monitoring's `monitoring` tile.
- Screen 28, Not sent: the row goes **first** in the tab's column, above the `MxNote`, with the 48 row floor and the row's own 16 inset; the note and the Level chip keep their paddings. The toggle keeps its 48 touch area inside the row (`MxToggle`). Nothing else on the tab moves.
- Copy follows the hint pattern of the Admin rows (label, one-line reason). TalkBack: the toggle's `semanticLabel` is the row label, as the Reminder toggle does.

No ruling needed; the build runs one bounded `impeccable audit` of the two goldens after Task 6 (CLAUDE.md).

## Global Constraints

- Column: `app_settings.log_sql_statements INTEGER NOT NULL DEFAULT 1 CHECK (log_sql_statements IN (0, 1))`, schema **15**, step **14→15** (spec §3.1).
- Wire key `logSqlStatements`, a boolean; a pulled row without the key leaves the column (spec §3.2). Server column `log_sql_statements boolean not null default true`; `coalesce((r->>'logSqlStatements')::boolean, true)` on push (spec §3.3).
- Off removes only `debug db.query`; `db.slow_query`, `db.query_failed`, `db.transaction` stay (spec §1).
- The switch starts `true`; the row is the only source of truth; the UI writes the row, never the switch (spec §4).
- One `info logging.sql_statements_changed {enabled}` row per change, none for the first read (spec §4.3).
- "Use app defaults" (`resetToDefaults`) leaves the column; `LocalDataReset` (`resetSyncedDefaults`) sets it back to 1 (spec §3.2).
- Copy: en "Log SQL statements" / "Each statement the app runs is logged, for performance checks. Turn off to keep the log small."; vi "Ghi câu SQL vào log" / "Mỗi câu lệnh app chạy đều được ghi log để kiểm tra hiệu năng. Tắt để log gọn." (spec §5).
- Goldens change only in `settings_admin_rows_*` and `monitoring_not_sent_*`; golden review before merge (spec §5).
- Never edit a Supabase migration already pushed; a new file only (supabase/README).

## Review Focus

1. **A server not yet migrated** sends settings rows without `logSqlStatements`: the device must keep its column (Task 2's "a pulled row without the key leaves it" test).
2. **The feed stream errors** (the database closed on account switch): the switch keeps its last value and the app keeps running (Task 4's error test).
3. **Two taps while a save runs**: the second is ignored, the toggle shows the row's value again after the save (Task 5's controller test).
4. **A failed save**: the toggle returns to the row's value and a snackbar says so, nothing else changes (Task 5's widget test).
5. **An upgraded database with the column already present** (a dev build ran the step twice): `addColumn` would fail; the step runs once per version by Drift's contract, and Task 1's v14→v15 test proves the normal path; `PRAGMA integrity_check` after it.

---

### Task 1: Schema 15 — the column and the trigger

**Files:**
- Modify: `lib/core/database/tables/settings.drift` (after `welcome_seen`)
- Modify: `lib/core/database/tables/sync.drift:168-183` (`app_settings_sync_update`)
- Modify: `lib/core/database/app_database.dart:62` (`schemaVersion`), the `_steps` map after `from13To14`
- Modify: `test/drift/migration_test.dart`, `test/drift/outbox_payload_migration_test.dart`, `test/drift/account_migration_test.dart`, `test/drift/interrupted_migration_test.dart` (the target version 14 → 15)
- Create: `test/drift/sql_log_switch_migration_test.dart`
- Generated (run the commands, never edit): `drift_schemas/drift_schema_v15.json`, `lib/core/database/schema_versions.dart`, `test/drift/generated/*`
- Docs: `docs/shared/data/schema.md` (the `app_settings` table row and the SB-S5 trigger paragraph)

**Interfaces:**
- Produces: `AppSetting.logSqlStatements` (`int`, 0/1), `AppSettingsCompanion.logSqlStatements`, `schema.appSettings.logSqlStatements`, the recreated trigger `app_settings_sync_update` that also fires on this column.

- [ ] **Step 1: Write the failing trigger test (fresh database)**

```dart
// test/drift/sql_log_switch_migration_test.dart
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';

import '../support/test_database.dart';
import 'generated/schema.dart';

// Spec 2026-10-07-sql-log-switch-design.md §3.1–3.2: the fifth synced
// settings column, on for every existing row, queued like the other four.
void main() {
  late SchemaVerifier verifier;
  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  Future<List<String>> queued(AppDatabase db) async {
    final rows = await db
        .customSelect('SELECT entity_type, op FROM sync_outbox ORDER BY rowid')
        .get();
    return [
      for (final row in rows)
        '${row.read<String>('entity_type')}:${row.read<String>('op')}',
    ];
  }

  test('changing the switch queues the account settings; a reminder change '
      'queues nothing', () async {
    final db = openTestDatabase();
    addTearDown(db.close);
    await db.customStatement('DELETE FROM sync_outbox');

    await db.customStatement(
      'UPDATE app_settings SET log_sql_statements = 0 WHERE id = 1',
    );
    expect(await queued(db), ['account_settings:upsert']);

    await db.customStatement('DELETE FROM sync_outbox');
    await db.customStatement(
      'UPDATE app_settings SET reminder_enabled = 1 WHERE id = 1',
    );
    expect(await queued(db), isEmpty);
  });

  test('v14 gets log_sql_statements = 1, keeps its settings, and its '
      'recreated trigger queues the switch', () async {
    final schema = await verifier.schemaAt(14);
    schema.rawDatabase
      ..execute(
        'INSERT OR IGNORE INTO app_settings (id, updated_at) VALUES (1, 0)',
      )
      ..execute(
        "UPDATE app_settings SET card_limit = 35, theme_mode = 'dark', "
        'welcome_seen = 1 WHERE id = 1',
      );
    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 15);

    final row = await db.select(db.appSettings).getSingle();
    expect(row.logSqlStatements, 1);
    expect(row.cardLimit, 35);
    expect(row.themeMode, 'dark');
    expect(row.welcomeSeen, 1);

    await db.customStatement('DELETE FROM sync_outbox');
    await db.customStatement(
      'UPDATE app_settings SET log_sql_statements = 0 WHERE id = 1',
    );
    expect(await queued(db), ['account_settings:upsert']);

    final integrity = await db.customSelect('PRAGMA integrity_check').get();
    expect(integrity.single.data.values.single, 'ok');
    expect(await db.customSelect('PRAGMA foreign_key_check').get(), isEmpty);
  });
}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `export PATH=/root/.flutter-sdk/3.47.5/flutter/bin:$PATH && flutter test test/drift/sql_log_switch_migration_test.dart`
Expected: FAIL — `no such column: log_sql_statements` in the first test; the second fails to compile on `row.logSqlStatements` (also expected: the column does not exist yet).

- [ ] **Step 3: Add the column and widen the trigger**

In `lib/core/database/tables/settings.drift`, after the `welcome_seen` line:

```sql
  -- SQL log switch (spec 2026-10-07-sql-log-switch-design.md §3): 1 logs
  -- every statement at debug. Synced with the account, the fifth synced
  -- column (SB-S5); on by default while the app is under test.
  log_sql_statements INTEGER NOT NULL DEFAULT 1 CHECK (log_sql_statements IN (0, 1)),
```

In `lib/core/database/tables/sync.drift`, replace the trigger's comment and `WHEN`:

```sql
-- SB-S5: the study and display settings and the SQL log switch sync per
-- account; reminders and a write that changes none of the five columns queue
-- nothing (library and study sync spec §3.5). The entity id is the nil UUID (D2).
CREATE TRIGGER app_settings_sync_update AFTER UPDATE ON app_settings
WHEN (SELECT value FROM sync_state WHERE name = 'applying_remote') IS NULL
  AND (old.card_limit IS NOT new.card_limit OR old.new_card_order IS NOT new.new_card_order
    OR old.theme_mode IS NOT new.theme_mode OR old.language IS NOT new.language
    OR old.log_sql_statements IS NOT new.log_sql_statements)
```

(the `BEGIN … END` body stays as it is.)

- [ ] **Step 4: Bump the version and write the step**

In `lib/core/database/app_database.dart`: `int get schemaVersion => 15;` and, after `from13To14`:

```dart
    from14To15: (m, schema) async {
      // SQL log switch (spec 2026-10-07-sql-log-switch-design.md §3): the
      // fifth synced settings column, on for every existing row, and the
      // settings trigger recreated to queue it too (a trigger cannot be
      // altered, as in 12→13). No row changes, no seed: a device's default
      // never overwrites the account (sync spec §3.5).
      await m.addColumn(
        schema.appSettings,
        schema.appSettings.logSqlStatements,
      );
      await customStatement('DROP TRIGGER IF EXISTS app_settings_sync_update');
      await m.createTrigger(schema.appSettingsSyncUpdate);
    },
```

- [ ] **Step 5: Regenerate the schema snapshots and code**

Run, in this order:

```bash
export PATH=/root/.flutter-sdk/3.47.5/flutter/bin:$PATH
dart run build_runner build --delete-conflicting-outputs
dart run drift_dev schema dump lib/core/database/app_database.dart drift_schemas/
dart run drift_dev schema steps drift_schemas/ lib/core/database/schema_versions.dart
dart run drift_dev schema generate drift_schemas/ test/drift/generated/
dart run build_runner build --delete-conflicting-outputs
```

Expected: `drift_schemas/drift_schema_v15.json` exists; `git status` shows `schema_versions.dart`, `test/drift/generated/schema_v15.dart` and `schema.dart` changed. `git add` the new files (the gate's generated-code check needs them in git).

- [ ] **Step 6: Point the upgrade tests at 15**

```bash
grep -rl "migrateAndValidate(db, 14)" test/drift | xargs sed -i 's/migrateAndValidate(db, 14)/migrateAndValidate(db, 15)/'
grep -rl "schema of v14" test/drift | xargs sed -i 's/schema of v14/schema of v15/'
```

In `test/drift/migration_test.dart`, after the `v13 upgrades to the schema of v15` test, add:

```dart
  test('v14 upgrades to the schema of v15', () async {
    final db = AppDatabase((await verifier.schemaAt(14)).newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 15);
  });
```

(copy the exact body shape of the `v13` test above it, which may differ in one line; keep that shape).

- [ ] **Step 7: Run the migration tests to verify they pass**

Run: `flutter test test/drift/sql_log_switch_migration_test.dart test/drift/migration_test.dart test/drift/outbox_payload_migration_test.dart test/drift/account_migration_test.dart test/drift/interrupted_migration_test.dart test/core/sync/sync_store_test.dart`
Expected: all PASS.

- [ ] **Step 8: Record the column in `schema.md`**

In `docs/shared/data/schema.md`, in the `app_settings` table after the `welcome_seen` row:

```markdown
| `log_sql_statements` | INTEGER NOT NULL DEFAULT 1 | `0` \| `1`; tracer ghi từng câu SQL ở `debug` hay không (spec `2026-10-07-sql-log-switch-design.md`). Đồng bộ theo tài khoản như bốn cột học/trình bày (SB-S5, schema 15); mặc định bật trong giai đoạn test. `CHECK (log_sql_statements IN (0, 1))` |
```

and in the SB-S5 trigger paragraph change "chỉ khi đổi `card_limit`, `new_card_order`, `theme_mode` hoặc `language`" to "chỉ khi đổi `card_limit`, `new_card_order`, `theme_mode`, `language` hoặc, từ schema 15, `log_sql_statements`". Run `python3 tools/docs/generate.py && python3 tools/docs/check.py` → `PASS — 0 error(s)` (29 pre-existing warnings).

- [ ] **Step 9: Drift review check and commit**

Run: `bash .claude/skills/flutter-drift/scripts/check_drift.sh --diff` → `0 error(s)`.

```bash
git add -A
git commit -m "DEV-nnn: schema 15 adds app_settings.log_sql_statements, synced with the account"
```

(`DEV-nnn` is this task's sub-issue; the epic's sub-issues are created with the plan.)

---

### Task 2: The settings data layer carries the switch

**Files:**
- Modify: `lib/features/settings/domain/entities/app_settings_entity.dart`
- Modify: `lib/features/settings/data/mappers/app_settings_mapper.dart` (`appSettingsOf`)
- Modify: `lib/features/settings/data/datasources/settings_dao.dart` (`resetSyncedDefaults`)
- Modify: `lib/features/settings/data/datasources/account_settings_sync_dao.dart`
- Modify: `lib/features/settings/domain/repositories/settings_repository.dart`, `lib/features/settings/data/repositories/settings_repository_impl.dart`
- Create: `lib/features/settings/domain/usecases/set_log_sql_statements_use_case.dart`
- Create: `test/features/settings/data/account_settings_sync_dao_test.dart`
- Modify: `test/features/settings/data/app_settings_repository_test.dart`, `test/core/database/local_data_reset_test.dart`

**Interfaces:**
- Consumes: `AppSetting.logSqlStatements` (Task 1).
- Produces: `AppSettingsEntity.logSqlStatements` (`bool`, default `true`); `SettingsRepository.setLogSqlStatements({required bool enabled})` → `Future<Outcome<void, SettingsRejection>>`; `SetLogSqlStatementsUseCase.call({required bool enabled})`; wire key `logSqlStatements` in `AccountSettingsSyncDao`.

- [ ] **Step 1: Write the failing sync DAO test**

```dart
// test/features/settings/data/account_settings_sync_dao_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/settings/data/datasources/account_settings_sync_dao.dart';

import '../../../support/test_database.dart';

// Sync spec §3.5 and the SQL log switch spec §3.2: the fifth synced column
// travels under `logSqlStatements`; a row without the key leaves it.
void main() {
  late AppDatabase db;
  late AccountSettingsSyncDao dao;

  setUp(() {
    db = openTestDatabase();
    dao = AccountSettingsSyncDao(db);
  });
  tearDown(() => db.close());

  Future<int> flag() async =>
      (await db.select(db.appSettings).getSingle()).logSqlStatements;

  test('the pushed row carries the switch as a boolean', () async {
    await db.customStatement(
      'UPDATE app_settings SET log_sql_statements = 0 WHERE id = 1',
    );
    final row = await dao.readRow('00000000-0000-0000-0000-000000000000');
    expect(row!['logSqlStatements'], false);
  });

  test('a pulled row applies the switch', () async {
    await dao.upsertFromServer({
      'logSqlStatements': false,
      'updatedAt': '2026-10-07T00:00:00Z',
    }, 1);
    expect(await flag(), 0);
  });

  test('a pulled row without the key leaves the switch', () async {
    await db.customStatement(
      'UPDATE app_settings SET log_sql_statements = 0 WHERE id = 1',
    );
    await dao.upsertFromServer({
      'themeMode': 'dark',
      'updatedAt': '2026-10-07T00:00:00Z',
    }, 1);
    expect(await flag(), 0);
  });
}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test test/features/settings/data/account_settings_sync_dao_test.dart`
Expected: the first and second tests FAIL (`null` instead of `false`; `1` instead of `0`); the third passes already.

- [ ] **Step 3: Entity, mapper, reset, sync DAO**

`app_settings_entity.dart`: add the field, optional so existing constructions keep compiling:

```dart
  const AppSettingsEntity({
    required this.studyDefaults,
    required this.theme,
    required this.language,
    required this.reminder,
    this.logSqlStatements = true,
  });
  …
  /// Whether the tracer logs every statement at `debug` (SQL log switch
  /// spec §1); an admin's tool, on by default while the app is under test.
  final bool logSqlStatements;
```

`app_settings_mapper.dart`, in `appSettingsOf`: `logSqlStatements: row.logSqlStatements == 1,`.

`settings_dao.dart`, in `resetSyncedDefaults`, add to the companion: `logSqlStatements: Value(defaults.logSqlStatements ? 1 : 0),` and change its doc's first line to "The synced settings, the SQL log switch included, back to [AppSettingsEntity.defaults]; …".

`account_settings_sync_dao.dart`: in `readRow` add `'logSqlStatements': row.logSqlStatements == 1,` before `'updatedAt'`; in `upsertFromServer` add `logSqlStatements: Value.absentIfNull(_flagOf(row['logSqlStatements'] as bool?)),` after `language`, and the helper:

```dart
  /// A wire boolean as the column stores it; null when the row has no key.
  static int? _flagOf(bool? value) =>
      value == null ? null : (value ? 1 : 0);
```

Update the class doc's first sentence: "Syncs the study and display settings and the SQL log switch of `app_settings` row 1 …".

- [ ] **Step 4: Run the sync DAO test to verify it passes**

Run: `flutter test test/features/settings/data/account_settings_sync_dao_test.dart`
Expected: 3 PASS.

- [ ] **Step 5: Write the failing repository and reset tests**

In `test/features/settings/data/app_settings_repository_test.dart`, add two tests inside `main`, using that file's existing `db` / `repository` setup (read the file's `setUp` and reuse its names exactly):

```dart
  test('setLogSqlStatements writes the column and updated_at', () async {
    final before = (await db.select(db.appSettings).getSingle()).updatedAt;
    expect(await repository.setLogSqlStatements(enabled: false), isA<Ok<void, SettingsRejection>>());
    final row = await db.select(db.appSettings).getSingle();
    expect(row.logSqlStatements, 0);
    expect(row.updatedAt.isAfter(before), isTrue);
  });

  test('Use app defaults leaves the SQL log switch alone', () async {
    await repository.setLogSqlStatements(enabled: false);
    await repository.resetToDefaults();
    expect((await db.select(db.appSettings).getSingle()).logSqlStatements, 0);
  });
```

In `test/core/database/local_data_reset_test.dart`, in the UPDATE statement at line 25 append `, log_sql_statements = 0`, and after `expect(settings.language, 'system');` add `expect(settings.logSqlStatements, 1);`.

- [ ] **Step 6: Run them to verify they fail**

Run: `flutter test test/features/settings/data/app_settings_repository_test.dart test/core/database/local_data_reset_test.dart`
Expected: the repository file fails to compile (`setLogSqlStatements` undefined). The reset test already passes, since Step 3 wired `resetSyncedDefaults`; it stays as the regression guard.

- [ ] **Step 7: Repository method and use case**

`settings_repository.dart`, after `setLanguage`:

```dart
  /// The SQL log switch (SQL log switch spec §4.4): an admin's tool, synced
  /// with the account like the theme, never touched by [resetToDefaults].
  Future<Outcome<void, SettingsRejection>> setLogSqlStatements({
    required bool enabled,
  });
```

`settings_repository_impl.dart`, after `setLanguage`:

```dart
  @override
  Future<Outcome<void, SettingsRejection>> setLogSqlStatements({
    required bool enabled,
  }) => _save(AppSettingsCompanion(logSqlStatements: Value(enabled ? 1 : 0)));
```

`set_log_sql_statements_use_case.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/settings/domain/failures/settings_failure.dart';
import 'package:memox/features/settings/domain/repositories/settings_repository.dart';

/// The SQL log switch, saved on the tap (SQL log switch spec §4.4).
final class SetLogSqlStatementsUseCase {
  const SetLogSqlStatementsUseCase(this._settings);

  final SettingsRepository _settings;

  Future<Outcome<void, SettingsRejection>> call({required bool enabled}) =>
      _settings.setLogSqlStatements(enabled: enabled);
}
```

Every fake `SettingsRepository` in `test/` must implement the new method: run `grep -rln "implements SettingsRepository" test lib` and add to each

```dart
  @override
  Future<Outcome<void, SettingsRejection>> setLogSqlStatements({
    required bool enabled,
  }) async => const Ok(null);
```

- [ ] **Step 8: Run the settings tests to verify they pass**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/settings test/core/database/local_data_reset_test.dart test/core/sync`
Expected: all PASS.

- [ ] **Step 9: Commit**

```bash
git add -A
git commit -m "DEV-nnn: the settings entity, repository and sync adapter carry the SQL log switch"
```

---

### Task 3: `SqlLogSwitch` and the tracer

**Files:**
- Create: `lib/core/logging/sql_log_switch.dart`
- Modify: `lib/core/database/tracing_interceptor.dart:15-31` (constructor, fields), `:188-196` (`_done`)
- Modify: `lib/core/database/connection.dart` (`openAppDatabase`)
- Modify: `lib/core/logging/di/logging_providers.dart` (new provider), `lib/core/database/di/database_provider.dart`
- Test: `test/core/database/tracing_interceptor_test.dart`

**Interfaces:**
- Produces: `final class SqlLogSwitch extends ValueNotifier<bool>` (starts `true`); `TracingInterceptor({AppLogger? logger, int Function()? micros, SqlLogSwitch? sqlLog})`; `AppDatabase openAppDatabase({SqlLogSwitch? sqlLog})`; `sqlLogSwitchProvider` (keep-alive) in `core/logging/di/logging_providers.dart`.

- [ ] **Step 1: Write the failing tracer test**

Append to `test/core/database/tracing_interceptor_test.dart`, inside `main` after the existing tests (it reuses `sink`, `logger` and `_Takes`), and add `import 'package:memox/core/logging/sql_log_switch.dart';`:

```dart
  test('with the switch off a statement logs no db.query; slow, failed and '
      'transaction rows stay, and flipping it on logs the next statement',
      () async {
    final sqlLog = SqlLogSwitch();
    addTearDown(sqlLog.dispose);
    final takes = _Takes();
    final db = AppDatabase(
      NativeDatabase.memory()
          .interceptWith(takes)
          .interceptWith(
            TracingInterceptor(
              logger: logger,
              micros: () => takes.micros,
              sqlLog: sqlLog,
            ),
          ),
    );
    addTearDown(db.close);
    await db.customSelect('SELECT 1').get();
    sink.entries.clear();

    sqlLog.value = false;
    takes.durations.addAll([0, 60]);
    await db.customSelect('SELECT 1').get();
    await db.customSelect('SELECT 2').get();
    await expectLater(
      db.customSelect('SELECT * FROM no_such_table').get(),
      throwsA(anything),
    );
    await db.transaction(() async {
      await db.customSelect('SELECT 3').get();
    });
    expect(sink.events, ['db.slow_query', 'db.query_failed', 'db.transaction']);

    sink.entries.clear();
    sqlLog.value = true;
    await db.customSelect('SELECT 4').get();
    expect(sink.events, ['db.query']);
  });
```

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test test/core/database/tracing_interceptor_test.dart`
Expected: compile error, `sql_log_switch.dart` not found / no named parameter `sqlLog`.

- [ ] **Step 3: The switch**

```dart
// lib/core/logging/sql_log_switch.dart
import 'package:flutter/foundation.dart';

/// Whether the tracer logs every statement as `debug db.query` (SQL log
/// switch spec §4.1). It starts on, the column's default, so the statements
/// that run before the account's row is read are logged as before; the
/// feeder in `logging_providers.dart` then keeps it equal to the row.
final class SqlLogSwitch extends ValueNotifier<bool> {
  SqlLogSwitch() : super(true);
}
```

- [ ] **Step 4: The tracer reads it**

In `tracing_interceptor.dart`: add `import 'package:memox/core/logging/sql_log_switch.dart';`; change the constructor and fields:

```dart
  TracingInterceptor({
    AppLogger? logger,
    int Function()? micros,
    SqlLogSwitch? sqlLog,
  }) : _logger = logger,
       _sqlLog = sqlLog,
       _micros = micros ?? (() => _stopwatch.elapsedMicroseconds);
  …
  final AppLogger? _logger;
  final SqlLogSwitch? _sqlLog;
  final int Function() _micros;

  /// Off drops only the per-statement debug row (spec §1); no switch means on.
  bool get _logsStatements => _sqlLog?.value ?? true;
```

and in `_done`, the last branch:

```dart
    } else if (_logsStatements) {
      _log.debug('db.query', category: LogCategory.db, context: context);
    }
```

Update the class doc with one line: "An admin's switch (`SqlLogSwitch`) turns the per-statement row off; slow, failed and transaction rows always log."

- [ ] **Step 5: Wire the provider**

`connection.dart`:

```dart
/// Every statement is traced into the log (ADR-018 §3); [sqlLog] turns the
/// per-statement row off (SQL log switch spec §4.2).
AppDatabase openAppDatabase({SqlLogSwitch? sqlLog}) => AppDatabase(
  driftDatabase(name: 'memox').interceptWith(TracingInterceptor(sqlLog: sqlLog)),
);
```

(add the import `package:memox/core/logging/sql_log_switch.dart`).

`logging_providers.dart`, add the import and:

```dart
/// The tracer's SQL log switch (SQL log switch spec §4.1). The database
/// provider hands it to the tracer; [sqlLogSwitchFeeder] keeps it equal to
/// the account's row.
@Riverpod(keepAlive: true)
SqlLogSwitch sqlLogSwitch(Ref ref) {
  final sqlLog = SqlLogSwitch();
  ref.onDispose(sqlLog.dispose);
  return sqlLog;
}
```

`database_provider.dart`: `final db = openAppDatabase(sqlLog: ref.watch(sqlLogSwitchProvider));` with `import 'package:memox/core/logging/di/logging_providers.dart';`.

Run `dart run build_runner build --delete-conflicting-outputs`.

- [ ] **Step 6: Run the tracer tests to verify they pass**

Run: `flutter test test/core/database/tracing_interceptor_test.dart test/core/logging test/app`
Expected: all PASS (the `database_provider` change must not break `test/app`'s startup tests).

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "DEV-nnn: SqlLogSwitch, read by the tracer for its db.query rows"
```

---

### Task 4: The feeder keeps the switch equal to the row

**Files:**
- Create: `lib/core/database/queries/sql_log_queries.drift`
- Create: `lib/core/logging/sql_log_dao.dart`
- Create: `lib/core/logging/sql_log_switch_feeder.dart`
- Modify: `lib/core/logging/di/logging_providers.dart` (new provider)
- Modify: `lib/app/app_bootstrap.dart` (`_startFromDatabase`)
- Test: `test/core/logging/sql_log_switch_feeder_test.dart`, `test/core/logging/sql_log_dao_test.dart`

**Interfaces:**
- Consumes: `SqlLogSwitch`, `sqlLogSwitchProvider` (Task 3), `databaseProvider`, `AppSetting.logSqlStatements` (Task 1).
- Produces: `SqlLogDao.watchLogSqlStatements()` → `Stream<bool>`; `SqlLogSwitchFeeder({required SqlLogSwitch target, required Stream<bool> flags, AppLogger? logger})` with `dispose()`; `sqlLogSwitchFeederProvider` (keep-alive).

- [ ] **Step 1: Write the failing feeder test**

```dart
// test/core/logging/sql_log_switch_feeder_test.dart
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/logging/app_logger.dart';
import 'package:memox/core/logging/sql_log_switch.dart';
import 'package:memox/core/logging/sql_log_switch_feeder.dart';

import '../../support/recording_log_sink.dart';

// SQL log switch spec §4.3: the row is the source of truth; the switch
// follows it, and each change after the first read is logged once.
void main() {
  late SqlLogSwitch target;
  late StreamController<bool> flags;
  late RecordingLogSink sink;
  late SqlLogSwitchFeeder feeder;

  setUp(() {
    target = SqlLogSwitch();
    flags = StreamController<bool>();
    sink = RecordingLogSink();
    feeder = SqlLogSwitchFeeder(
      target: target,
      flags: flags.stream,
      logger: AppLogger(sinks: [sink]),
    );
  });
  tearDown(() async {
    feeder.dispose();
    await flags.close();
    target.dispose();
  });

  test('the first read sets the switch without a log row', () async {
    flags.add(false);
    await Future<void>.delayed(Duration.zero);
    expect(target.value, isFalse);
    expect(sink.events, isEmpty);
  });

  test('a later change moves the switch and logs it once', () async {
    flags
      ..add(true)
      ..add(false)
      ..add(false)
      ..add(true);
    await Future<void>.delayed(Duration.zero);
    expect(target.value, isTrue);
    expect(sink.events, ['logging.sql_statements_changed', 'logging.sql_statements_changed']);
    expect(sink.entries.first.context['enabled'], false);
    expect(sink.entries.last.context['enabled'], true);
  });

  test('a failing stream leaves the switch and logs a warning', () async {
    flags
      ..add(false)
      ..addError(StateError('closed'));
    await Future<void>.delayed(Duration.zero);
    expect(target.value, isFalse);
    expect(sink.events, ['logging.sql_switch_unavailable']);
    expect(sink.entries.single.level, LogLevel.warning);
  });
}
```

(add `import 'package:memox/core/logging/log_entry.dart';` for `LogLevel`.)

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test test/core/logging/sql_log_switch_feeder_test.dart`
Expected: compile error, `sql_log_switch_feeder.dart` not found.

- [ ] **Step 3: The feeder**

```dart
// lib/core/logging/sql_log_switch_feeder.dart
import 'dart:async';

import 'package:memox/core/logging/app_logger.dart';
import 'package:memox/core/logging/log_entry.dart';
import 'package:memox/core/logging/sql_log_switch.dart';

/// Keeps [target] equal to the account's `log_sql_statements` row (SQL log
/// switch spec §4.3). The first value is the start of the app or of a new
/// account and is not logged; every later change writes one `info` row, so
/// the server log says why `db.query` rows stop or start on this device. A
/// failing stream leaves the switch as it is and is logged once.
final class SqlLogSwitchFeeder {
  SqlLogSwitchFeeder({
    required SqlLogSwitch target,
    required Stream<bool> flags,
    AppLogger? logger,
  }) : _target = target,
       _logger = logger {
    _subscription = flags.listen(_apply, onError: _unavailable);
  }

  final SqlLogSwitch _target;
  final AppLogger? _logger;
  late final StreamSubscription<bool> _subscription;
  var _hasRead = false;

  AppLogger get _log => _logger ?? appLogger;

  void _apply(bool enabled) {
    final isFirst = !_hasRead;
    _hasRead = true;
    if (_target.value == enabled) return;
    _target.value = enabled;
    if (isFirst) return;
    _log.info(
      'logging.sql_statements_changed',
      category: LogCategory.lifecycle,
      context: {'enabled': enabled},
    );
  }

  void _unavailable(Object error, StackTrace stackTrace) => _log.warning(
    'logging.sql_switch_unavailable',
    category: LogCategory.lifecycle,
    error: error,
    stackTrace: stackTrace,
  );

  void dispose() => unawaited(_subscription.cancel());
}
```

- [ ] **Step 4: Run the feeder test to verify it passes**

Run: `flutter test test/core/logging/sql_log_switch_feeder_test.dart`
Expected: 3 PASS.

- [ ] **Step 5: Write the failing DAO test**

```dart
// test/core/logging/sql_log_dao_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/logging/sql_log_dao.dart';

import '../../support/test_database.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = openTestDatabase());
  tearDown(() => db.close());

  test('watchLogSqlStatements follows the row', () async {
    final dao = SqlLogDao(db);
    final seen = <bool>[];
    final subscription = dao.watchLogSqlStatements().listen(seen.add);
    addTearDown(subscription.cancel);
    await Future<void>.delayed(Duration.zero);
    await db.customStatement(
      'UPDATE app_settings SET log_sql_statements = 0 WHERE id = 1',
    );
    await Future<void>.delayed(Duration.zero);
    expect(seen, [true, false]);
  });
}
```

- [ ] **Step 6: Run it to verify it fails**

Run: `flutter test test/core/logging/sql_log_dao_test.dart`
Expected: compile error, `sql_log_dao.dart` not found.

- [ ] **Step 7: The query and the DAO**

```sql
-- lib/core/database/queries/sql_log_queries.drift
import '../tables/settings.drift';

-- The SQL log switch of the account (SQL log switch spec §4.3): the tracer
-- follows it through SqlLogDao. Read only; the settings feature writes it.
logSqlStatementsFlag(:row_id AS INTEGER):
SELECT log_sql_statements FROM app_settings WHERE id = :row_id;
```

```dart
// lib/core/logging/sql_log_dao.dart
import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';

part 'sql_log_dao.g.dart';

/// Reads the SQL log switch's column for the feeder (SQL log switch spec
/// §4.3), the way `core/auth`'s `AccountDeviceDao` reads its flags: `core`
/// never imports a feature's DAO.
@DriftAccessor(
  include: {'package:memox/core/database/queries/sql_log_queries.drift'},
)
final class SqlLogDao extends DatabaseAccessor<AppDatabase>
    with _$SqlLogDaoMixin {
  SqlLogDao(super.attachedDatabase);

  /// The switch, again after every write of the row.
  Stream<bool> watchLogSqlStatements() => logSqlStatementsFlag(
    appSettingsRowId,
  ).watchSingle().map((flag) => flag == 1);
}
```

Run `dart run build_runner build --delete-conflicting-outputs`, then `flutter test test/core/logging/sql_log_dao_test.dart` → PASS.

- [ ] **Step 8: The provider and the start**

`logging_providers.dart` (imports: `database_provider.dart`, `sql_log_dao.dart`, `sql_log_switch_feeder.dart`):

```dart
/// Keeps [sqlLogSwitch] equal to the account's row (SQL log switch spec
/// §4.3). `startApp` reads it once the database has opened; it lives as long
/// as the container, and a new database (Retry on the recovery screen)
/// rebuilds it.
@Riverpod(keepAlive: true)
SqlLogSwitchFeeder sqlLogSwitchFeeder(Ref ref) {
  final feeder = SqlLogSwitchFeeder(
    target: ref.watch(sqlLogSwitchProvider),
    flags: SqlLogDao(ref.watch(databaseProvider)).watchLogSqlStatements(),
  );
  ref.onDispose(feeder.dispose);
  return feeder;
}
```

`app_bootstrap.dart`, in `_startFromDatabase`, right after `if (unavailable != null) return unavailable;`:

```dart
  // The tracer follows the account's SQL log switch from here on (SQL log
  // switch spec §4.3); until this read it logs every statement.
  container.read(sqlLogSwitchFeederProvider);
```

Run `dart run build_runner build --delete-conflicting-outputs`.

- [ ] **Step 9: Run the startup and logging tests**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/app test/core/logging test/core/database`
Expected: all PASS.

- [ ] **Step 10: Architecture check and commit**

Run: `bash .claude/skills/flutter-architecture/scripts/check_architecture.sh` → no violation (`core/logging` imports `core/database` only).

```bash
git add -A
git commit -m "DEV-nnn: the SQL log switch follows the account's row and logs each change"
```

---

### Task 5: The toggle row in the settings feature

**Files:**
- Create: `lib/features/settings/presentation/providers/set_log_sql_statements_use_case_provider.dart`
- Create: `lib/features/settings/presentation/states/sql_log_state.dart`
- Create: `lib/features/settings/presentation/controllers/sql_log_controller.dart`
- Create: `lib/features/settings/presentation/widgets/items/sql_log_row_widget.dart`
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb`
- Test: `test/features/settings/presentation/sql_log_controller_test.dart`, `test/features/settings/presentation/sql_log_row_widget_test.dart`

**Interfaces:**
- Consumes: `appSettingsProvider` (`Stream<AppSettingsEntity>`), `SetLogSqlStatementsUseCase` (Task 2), `settingsRepositoryProvider`.
- Produces: `SqlLogRowWidget()` (a `ConsumerWidget`, no parameters); `sqlLogControllerProvider` with `set({required bool enabled})` and `dismissFailure()`; l10n keys `settingsLogSql`, `settingsLogSqlHint`, `settingsLogSqlSaveFailed`.

- [ ] **Step 1: l10n keys**

`app_en.arb`, after `settingsMonitoringHint`'s block:

```json
  "settingsLogSql": "Log SQL statements",
  "@settingsLogSql": {
    "description": "Admin row on screens 23 and 28: the SQL log switch (SQL log switch spec §5)."
  },
  "settingsLogSqlHint": "Each statement the app runs is logged, for performance checks. Turn off to keep the log small.",
  "@settingsLogSqlHint": {
    "description": "Subtitle of the SQL log switch row."
  },
  "settingsLogSqlSaveFailed": "Couldn't change that. The switch is unchanged.",
  "@settingsLogSqlSaveFailed": {
    "description": "Snackbar after a failed save of the SQL log switch."
  },
```

`app_vi.arb`, in the same place:

```json
  "settingsLogSql": "Ghi câu SQL vào log",
  "settingsLogSqlHint": "Mỗi câu lệnh app chạy đều được ghi log để kiểm tra hiệu năng. Tắt để log gọn.",
  "settingsLogSqlSaveFailed": "Không đổi được. Công tắc giữ nguyên.",
```

Run `flutter gen-l10n`.

- [ ] **Step 2: Write the failing controller test**

```dart
// test/features/settings/presentation/sql_log_controller_test.dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/settings/domain/failures/settings_failure.dart';
import 'package:memox/features/settings/domain/usecases/set_log_sql_statements_use_case.dart';
import 'package:memox/features/settings/presentation/controllers/sql_log_controller.dart';
import 'package:memox/features/settings/presentation/providers/set_log_sql_statements_use_case_provider.dart';

import '../../../support/settings_fakes.dart';

// SQL log switch spec §5: one save at a time; a failure is reported once.
void main() {
  late FakeSettingsRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = FakeSettingsRepository();
    container = ProviderContainer(
      overrides: [
        setLogSqlStatementsUseCaseProvider.overrideWithValue(
          SetLogSqlStatementsUseCase(repository),
        ),
      ],
    );
    addTearDown(container.dispose);
  });

  test('set saves once and ignores a second tap while saving', () async {
    final gate = Completer<Outcome<void, SettingsRejection>>();
    repository.nextSetLogSql = gate.future;
    final controller = container.read(sqlLogControllerProvider.notifier);
    final first = controller.set(enabled: false);
    expect(container.read(sqlLogControllerProvider).isSaving, isTrue);
    await controller.set(enabled: true);
    gate.complete(const Ok(null));
    await first;
    expect(repository.setLogSqlCalls, [false]);
    expect(container.read(sqlLogControllerProvider).isSaving, isFalse);
  });

  test('a refused save is reported, then dismissed', () async {
    repository.nextSetLogSql = Future.value(
      const Rejected(SettingsRejection.storage),
    );
    final controller = container.read(sqlLogControllerProvider.notifier);
    await controller.set(enabled: false);
    expect(
      container.read(sqlLogControllerProvider).failure,
      SettingsRejection.storage,
    );
    controller.dismissFailure();
    expect(container.read(sqlLogControllerProvider).failure, isNull);
  });
}
```

Read `test/support/settings_fakes.dart` first: if `FakeSettingsRepository` lives elsewhere (`grep -rn "class FakeSettingsRepository" test/support`), import that file, and add to it:

```dart
  Future<Outcome<void, SettingsRejection>>? nextSetLogSql;
  final setLogSqlCalls = <bool>[];

  @override
  Future<Outcome<void, SettingsRejection>> setLogSqlStatements({
    required bool enabled,
  }) {
    setLogSqlCalls.add(enabled);
    final next = nextSetLogSql;
    nextSetLogSql = null;
    return next ?? Future.value(const Ok(null));
  }
```

`SettingsRejection.storage`: use whichever value `settings_failure.dart` defines for a failed write (`grep -n "enum SettingsRejection" -A 6 lib/features/settings/domain/failures/settings_failure.dart`); replace `storage` in both places with that name.

- [ ] **Step 3: Run it to verify it fails**

Run: `flutter test test/features/settings/presentation/sql_log_controller_test.dart`
Expected: compile error, `sql_log_controller.dart` not found.

- [ ] **Step 4: Provider, state, controller**

```dart
// set_log_sql_statements_use_case_provider.dart
import 'package:memox/features/settings/di/settings_repository_provider.dart';
import 'package:memox/features/settings/domain/usecases/set_log_sql_statements_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'set_log_sql_statements_use_case_provider.g.dart';

@riverpod
SetLogSqlStatementsUseCase setLogSqlStatementsUseCase(Ref ref) =>
    SetLogSqlStatementsUseCase(ref.watch(settingsRepositoryProvider));
```

```dart
// sql_log_state.dart
import 'package:memox/features/settings/domain/failures/settings_failure.dart';

/// The SQL log switch row's own state: the row's value comes from the
/// settings stream, this holds only the save in flight and its failure.
final class SqlLogState {
  const SqlLogState({this.isSaving = false, this.failure});

  final bool isSaving;
  final SettingsRejection? failure;
}
```

```dart
// sql_log_controller.dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/settings/presentation/providers/set_log_sql_statements_use_case_provider.dart';
import 'package:memox/features/settings/presentation/states/sql_log_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sql_log_controller.g.dart';

/// The SQL log switch's save (SQL log switch spec §5): one at a time, a
/// second tap while one runs is ignored, a refusal is reported once.
@riverpod
class SqlLogController extends _$SqlLogController {
  @override
  SqlLogState build() => const SqlLogState();

  Future<void> set({required bool enabled}) async {
    if (state.isSaving) return;
    state = const SqlLogState(isSaving: true);
    final outcome = await ref.read(setLogSqlStatementsUseCaseProvider)(
      enabled: enabled,
    );
    state = switch (outcome) {
      Ok() => const SqlLogState(),
      Rejected(:final reason) => SqlLogState(failure: reason),
    };
  }

  void dismissFailure() => state = const SqlLogState();
}
```

Run `dart run build_runner build --delete-conflicting-outputs`, then `flutter test test/features/settings/presentation/sql_log_controller_test.dart` → 2 PASS.

- [ ] **Step 5: Write the failing widget test**

```dart
// test/features/settings/presentation/sql_log_row_widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/settings/domain/entities/app_settings_entity.dart';
import 'package:memox/features/settings/domain/failures/settings_failure.dart';
import 'package:memox/features/settings/domain/usecases/set_log_sql_statements_use_case.dart';
import 'package:memox/features/settings/presentation/providers/app_settings_provider.dart';
import 'package:memox/features/settings/presentation/providers/set_log_sql_statements_use_case_provider.dart';
import 'package:memox/features/settings/presentation/widgets/items/sql_log_row_widget.dart';
import 'package:memox/shared/widgets/mx_toggle.dart';

import '../../../support/settings_fakes.dart';
import '../../../support/widget_harness.dart';

void main() {
  late FakeSettingsRepository repository;

  AppSettingsEntity settings(bool enabled) => AppSettingsEntity(
    studyDefaults: AppSettingsEntity.defaults.studyDefaults,
    theme: AppSettingsEntity.defaults.theme,
    language: AppSettingsEntity.defaults.language,
    reminder: AppSettingsEntity.defaults.reminder,
    logSqlStatements: enabled,
  );

  Widget row({bool enabled = true}) => ProviderScope(
    overrides: [
      appSettingsProvider.overrideWith(
        (ref) => Stream.value(settings(enabled)),
      ),
      setLogSqlStatementsUseCaseProvider.overrideWithValue(
        SetLogSqlStatementsUseCase(repository),
      ),
    ],
    child: const Scaffold(body: SqlLogRowWidget()),
  );

  setUp(() => repository = FakeSettingsRepository());

  testWidgets('shows the row's value and saves the flipped one', (tester) async {
    await pumpMx(tester, row());
    await tester.pump();
    expect(find.text('Log SQL statements'), findsOneWidget);
    expect(tester.widget<MxToggle>(find.byType(MxToggle)).isOn, isTrue);
    await tester.tap(find.byType(MxToggle));
    await tester.pump();
    expect(repository.setLogSqlCalls, [false]);
  });

  testWidgets('a refused save shows the snackbar and keeps the value', (
    tester,
  ) async {
    repository.nextSetLogSql = Future.value(
      const Rejected(SettingsRejection.storage),
    );
    await pumpMx(tester, row());
    await tester.pump();
    await tester.tap(find.byType(MxToggle));
    await tester.pump();
    await tester.pump();
    expect(find.text("Couldn't change that. The switch is unchanged."), findsOneWidget);
    expect(tester.widget<MxToggle>(find.byType(MxToggle)).isOn, isTrue);
  });
}
```

`pumpMx` wraps the child in a `MaterialApp` with the app's localizations (read `test/support/widget_harness.dart`); if it has no `ScaffoldMessenger`, the `Scaffold` above provides one.

- [ ] **Step 6: Run it to verify it fails**

Run: `flutter test test/features/settings/presentation/sql_log_row_widget_test.dart`
Expected: compile error, `sql_log_row_widget.dart` not found.

- [ ] **Step 7: The widget**

```dart
// lib/features/settings/presentation/widgets/items/sql_log_row_widget.dart
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/features/settings/presentation/controllers/sql_log_controller.dart';
import 'package:memox/features/settings/presentation/providers/app_settings_provider.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_settings_row.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';
import 'package:memox/shared/widgets/mx_toggle.dart';

/// The SQL log switch row (SQL log switch spec §5): an `MxSettingsRow` with
/// a trailing toggle, drawn by `app/` in screen 23's Admin section and at
/// the top of screen 28's Not sent tab, for an admin only (both hosts gate
/// it). The toggle shows the account's row and is disabled while a save
/// runs; a refused save says so and the row keeps its value.
class SqlLogRowWidget extends ConsumerWidget {
  const SqlLogRowWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final enabled = ref.watch(
      appSettingsProvider.select((s) => s.value?.logSqlStatements),
    );
    final isSaving = ref.watch(
      sqlLogControllerProvider.select((s) => s.isSaving),
    );
    ref.listen(sqlLogControllerProvider.select((s) => s.failure), (_, failure) {
      if (failure == null) return;
      showMxSnackbar(context, message: l10n.settingsLogSqlSaveFailed);
      ref.read(sqlLogControllerProvider.notifier).dismissFailure();
    });
    return MxSettingsRow(
      label: l10n.settingsLogSql,
      subtitle: l10n.settingsLogSqlHint,
      icon: AppIcons.levelDebug,
      trailing: MxToggle(
        isOn: enabled ?? true,
        semanticLabel: l10n.settingsLogSql,
        onChanged: enabled == null || isSaving
            ? null
            : (value) => unawaited(
                ref.read(sqlLogControllerProvider.notifier).set(enabled: value),
              ),
      ),
    );
  }
}
```

- [ ] **Step 8: Run the widget test to verify it passes**

Run: `flutter test test/features/settings/presentation/sql_log_row_widget_test.dart test/features/settings/presentation/sql_log_controller_test.dart`
Expected: all PASS.

- [ ] **Step 9: Commit**

```bash
git add -A
git commit -m "DEV-nnn: the SQL log switch row, an admin toggle in the settings feature"
```

---

### Task 6: Compose the row into screens 23 and 28, regenerate the goldens

**Files:**
- Modify: `lib/app/router/admin_routes.dart` (`adminSettingsRows`)
- Modify: `lib/features/monitoring/presentation/screens/monitoring_screen.dart` (a `pendingHeader` slot)
- Modify: `lib/features/monitoring/presentation/widgets/sections/monitoring_pending_tab_widget.dart` (a `header` slot)
- Modify: `lib/app/router/app_router.dart:299` (pass the row)
- Modify: `test/features/account/presentation/users_golden_test.dart` (`_settings()`), `test/features/monitoring/presentation/monitoring_screen_golden_test.dart` (`_screen`), `test/features/monitoring/presentation/monitoring_not_sent_test.dart`, `test/support/monitoring_screen_harness.dart`
- Goldens: `test/features/account/presentation/goldens/settings_admin_rows_{light,dark}.png`, `test/features/monitoring/presentation/goldens/monitoring_not_sent_{light,dark}.png`

**Interfaces:**
- Consumes: `SqlLogRowWidget` (Task 5).
- Produces: `MonitoringScreen({…, Widget? pendingHeader})`; `MonitoringPendingTabWidget({required onOpenLog, Widget? header})`.

- [ ] **Step 1: Write the failing Not sent header test**

In `test/support/monitoring_screen_harness.dart`, add a `Widget? pendingHeader` parameter to `pumpMonitoring` and pass it to `MonitoringScreen(pendingHeader: pendingHeader, …)`. Then in `test/features/monitoring/presentation/monitoring_not_sent_test.dart` add, in the shape of that file's first test (same `repository`, `pumpMonitoring`, tab switch):

```dart
  testWidgets('the Not sent tab draws the header it is given above the note', (
    tester,
  ) async {
    final repository = FakeMonitoringRepository()..autoPage = pageOf(1);
    await pumpMonitoring(
      tester,
      env,
      repository,
      pendingHeader: const Text('header', key: ValueKey('header')),
    );
    await tester.tap(find.textContaining('Not sent'));
    await tester.pumpAndSettle();
    final header = tester.getTopLeft(find.byKey(const ValueKey('header')));
    final note = tester.getTopLeft(find.byType(MxNote));
    expect(header.dy, lessThan(note.dy));
  });
```

(`env` is the `LibraryEnv` the file's other tests receive; use the same `libraryTest` wrapper they use, and import `mx_note.dart`.)

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test test/features/monitoring/presentation/monitoring_not_sent_test.dart`
Expected: compile error, no named parameter `pendingHeader`.

- [ ] **Step 3: The slots**

`monitoring_screen.dart`: add `this.pendingHeader,` to the constructor and

```dart
  /// A row `app/` draws at the top of the Not sent tab: the SQL log switch
  /// (SQL log switch spec §5). The screen never imports the settings feature
  /// (ADR-011), so it takes the row as a slot, as Settings takes the Admin rows.
  final Widget? pendingHeader;
```

and pass `header: pendingHeader` where `MonitoringPendingTabWidget` is built.

`monitoring_pending_tab_widget.dart`: add `this.header,` and `final Widget? header;` with the doc "Drawn first, above the note (SQL log switch spec §5)."; in the `Column`'s `children`, before the note's `if`:

```dart
        ?header,
```

`admin_routes.dart`: add `import 'package:memox/features/settings/presentation/widgets/items/sql_log_row_widget.dart';` and `const SqlLogRowWidget(),` as the third row; update the doc comment: "Monitoring, then Users, then the SQL log switch (SQL log switch spec §5)".

`app_router.dart:299`: `child: MonitoringScreen(pendingHeader: const SqlLogRowWidget(), onOpenServerLog: …`, with the same import.

- [ ] **Step 4: Run the Not sent test to verify it passes**

Run: `flutter test test/features/monitoring/presentation/monitoring_not_sent_test.dart test/features/monitoring/presentation/monitoring_screen_test.dart`
Expected: PASS.

- [ ] **Step 5: Put the row into the two goldens**

`users_golden_test.dart`, `_settings()`'s `adminRows`: add `const SqlLogRowWidget(),` after `UsersEntryRowWidget(onOpen: () {}),` (import the widget). `monitoring_screen_golden_test.dart`: in `_screen` (the `MonitoringScreen` the goldens pump) add `pendingHeader: const SqlLogRowWidget(),`. Both harnesses run on `LibraryEnv`'s real database, so the row reads the default `1`.

- [ ] **Step 6: Regenerate the goldens (Linux container only)**

Run: `bash .claude/skills/flutter-workflow/scripts/run_goldens.sh --update > /tmp/goldens.log 2>&1; tail -3 /tmp/goldens.log; git status --short | grep png`
Expected: exit 0; exactly four PNGs changed: `settings_admin_rows_{light,dark}.png`, `monitoring_not_sent_{light,dark}.png`. Any other PNG means a layout leak: stop and find it.

- [ ] **Step 7: One bounded Impeccable audit of the two goldens**

Open the four PNGs (`Read`) and check against the critique above: the row sits third in Admin with the section's hairlines; on Not sent it sits above the note, 48 tall, toggle on, both themes legible. Fix anything found in one batch; write the result into the ledger (it goes into the PR body).

- [ ] **Step 8: Architecture check and commit**

Run: `bash .claude/skills/flutter-architecture/scripts/check_architecture.sh` → clean (`features/monitoring` imports no other feature; `app/` may import both).

```bash
git add -A
git commit -m "DEV-nnn: screens 23 and 28 show the SQL log switch row"
```

---

### Task 7: Supabase — the server stores and returns the switch

**Files:**
- Create: `supabase/migrations/20261015000000_account_settings_log_sql.sql`
- Create: `supabase/tests/database/16_account_settings_log_sql.sql` (15 landed on master meanwhile)

**Interfaces:**
- Consumes: the wire key `logSqlStatements` (Task 2).
- Produces: `public.account_settings.log_sql_statements boolean not null default true`; `private.account_settings_change` returns it; `private.account_settings_upsert` stores it with `coalesce(…, true)`.

- [ ] **Step 1: Write the failing pgTAP test**

```sql
-- supabase/tests/database/16_account_settings_log_sql.sql
begin;
create extension if not exists pgtap with schema extensions;
select plan(4);
insert into auth.users (id) values ('aaaaaaaa-0000-0000-0000-000000000001') on conflict (id) do nothing;

create function public.t_nil() returns uuid language sql immutable as $$
  select '00000000-0000-0000-0000-000000000000'::uuid $$;
create function public.t_settings(p_extra jsonb) returns jsonb language sql as $$
  select jsonb_build_object('cardLimit', 30, 'newCardOrder', 'random', 'themeMode', 'dark',
    'language', 'vi', 'updatedAt', '2026-10-07T00:00:00Z') || p_extra $$;
create function public.t_op(p_op int, p_row jsonb) returns jsonb language sql as $$
  select jsonb_build_object('opId', format('00000000-0000-0000-0000-%s', lpad((200000 + p_op)::text, 12, '0')),
    'entityType', 'account_settings', 'entityId', public.t_nil(), 'op', 'upsert', 'row', p_row) $$;
create function public.t_push(p_ops jsonb) returns jsonb language sql as $$
  select public.sync_push(jsonb_build_object('deviceId', '00000000-0000-0000-0000-0000000000d1',
    'operations', p_ops))->'results' $$;
create function public.t_row() returns jsonb language sql as $$
  select c->'row' from jsonb_array_elements(public.sync_changes(0, 500)->'changes') c
  where c->>'entityType' = 'account_settings' $$;

set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"aaaaaaaa-0000-0000-0000-000000000001","role":"authenticated"}', true);

-- SQL log switch spec §3.3: the fifth synced column.
select is(public.t_push(jsonb_build_array(public.t_op(1, public.t_settings('{"logSqlStatements": false}'))))->0->>'status',
  'applied', 'a push with the switch is applied');
select is(public.t_row()->>'logSqlStatements', 'false', 'the switch reads back as a boolean');
select is(public.t_push(jsonb_build_array(public.t_op(2, public.t_settings('{}'))))->0->>'status',
  'applied', 'a push without the key is applied');
select is(public.t_row()->>'logSqlStatements', 'true', 'a push without the key stores true (an older app)');

select * from finish();
rollback;
```

Note the `t_*` helper names are created inside this transaction and rolled back, as `07_account_settings_sync.sql` does; each test file is its own transaction.

- [ ] **Step 2: The migration**

```sql
-- supabase/migrations/20261015000000_account_settings_log_sql.sql
-- SQL log switch (spec 2026-10-07-sql-log-switch-design.md §3.3): the fifth
-- synced settings column. An admin turns the tracer's per-statement rows on
-- or off for the account; on by default while the app is under test. The two
-- functions are those of 20261001000000_account_settings_sync.sql with the
-- column added; a push without the key (an older app) stores true.

alter table public.account_settings
  add column log_sql_statements boolean not null default true;

create or replace function private.account_settings_change(s public.account_settings) returns jsonb
language sql stable set search_path = '' as $$
  select jsonb_build_object(
    'entityType', 'account_settings', 'entityId', '00000000-0000-0000-0000-000000000000'::uuid,
    'serverVersion', s.server_version, 'deleted', false,
    'row', jsonb_build_object('cardLimit', s.card_limit, 'newCardOrder', s.new_card_order,
      'themeMode', s.theme_mode, 'language', s.language, 'logSqlStatements', s.log_sql_statements,
      'updatedAt', private.wire_time(s.updated_at)))
$$;

create or replace function private.account_settings_upsert(p_user uuid, p_device uuid, p_id uuid, r jsonb) returns bigint
language plpgsql set search_path = '' as $$
declare
  v_version bigint;
begin
  if p_id is distinct from '00000000-0000-0000-0000-000000000000'::uuid then
    raise exception 'VALIDATION_FAILED';
  end if;
  v_version := private.allocate_versions(p_user, 1);
  insert into public.account_settings (user_id, card_limit, new_card_order, theme_mode, language,
    log_sql_statements, updated_at, server_version, last_device_id)
  values (p_user, (r->>'cardLimit')::integer, r->>'newCardOrder', r->>'themeMode', r->>'language',
    coalesce((r->>'logSqlStatements')::boolean, true),
    (r->>'updatedAt')::timestamptz, v_version, p_device)
  on conflict (user_id) do update set
    card_limit = excluded.card_limit, new_card_order = excluded.new_card_order,
    theme_mode = excluded.theme_mode, language = excluded.language,
    log_sql_statements = excluded.log_sql_statements, updated_at = excluded.updated_at,
    server_version = excluded.server_version, last_device_id = excluded.last_device_id;
  return v_version;
end
$$;
```

Before writing, confirm the current bodies: `grep -n "account_settings_change\|account_settings_upsert" supabase/migrations/*.sql` must show only `20261001000000` defining them (a later redefinition would be the body to start from).

- [ ] **Step 3: Update the existing pgTAP expectation**

`07_account_settings_sync.sql`'s second assertion compares the whole wire row; it now carries `'logSqlStatements', true`. Add it to that `jsonb_build_object('cardLimit', 30, …)` after `'language', 'vi'`.

- [ ] **Step 4: Run the suite where Docker exists**

On a machine with Docker: `npx supabase db start && npx supabase test db` → every file passes, `15_…` included. In the cloud container this step cannot run: write "pgTAP: not run here (no Docker); owner runs `npx supabase test db` before merge" in the ledger and in the PR body, and ask the owner for the result on the PR.

- [ ] **Step 5: Commit**

```bash
git add supabase/migrations/20261015000000_account_settings_log_sql.sql supabase/tests/database/15_account_settings_log_sql.sql supabase/tests/database/07_account_settings_sync.sql
git commit -m "DEV-nnn: account_settings.log_sql_statements on the server, with pgTAP"
```

---

### Task 8: Documents

**Files:**
- Modify: `docs/superpowers/specs/2026-09-28-sync-library-and-study-design.md` §3.5
- Modify: `docs/superpowers/specs/2026-09-29-app-logging-design.md` §3 (`LogDatabase`/tracer bullets), §8
- Modify: `docs/shared/decisions/ADR-018-log-tap-trung-va-monitoring.md` (row 3 of Quyết định)
- Modify: `docs/shared/ui/screen-handoff/23-settings.md`, `28-monitoring.md`, `00-index.md`
- Modify: `docs/superpowers/specs/2026-10-07-sql-log-switch-design.md` §4.3 and §5 (the two deviations)
- Modify: `supabase/README.md` only if it lists the account-settings columns (`grep -n "account_settings" supabase/README.md`; if nothing, skip)

- [ ] **Step 1: Sync spec §3.5**

"Synced: `card_limit`, `new_card_order`, `theme_mode`, `language`, `log_sql_statements` (schema 15, SQL log switch spec), and `updated_at`." Wire row: add `logSqlStatements` (a boolean; absent from an older app, then the server stores `true`). "one of the four synced columns" → "one of the five synced columns".

- [ ] **Step 2: Logging spec**

§3, the tracer bullet: add "An admin's switch, stored with the account (`app_settings.log_sql_statements`, SQL log switch spec 2026-10-07), turns the per-statement `debug db.query` row off on every device of the account; `db.slow_query`, `db.query_failed` and `db.transaction` always log." §8: "- **SQL log switch (2026-10-07):** an admin turns statement logging off per account from screens 23 and 28; default on while under test (spec `2026-10-07-sql-log-switch-design.md`)."

- [ ] **Step 3: ADR-018 row 3**

Append to the cell: "Bổ sung 2026-10-07: admin có thể tắt dòng `debug db.query` theo tài khoản (cột `app_settings.log_sql_statements`, đồng bộ SB-S5; spec `2026-10-07-sql-log-switch-design.md`); `slow_query`, `query_failed` và `transaction` luôn ghi."

- [ ] **Step 4: Detail files and index**

`23-settings.md`, the Admin row: "`MxSettingsRow` × 2" → "× 3": add "then "Log SQL statements" / "Each statement the app runs is logged, for performance checks. Turn off to keep the log small." with a trailing `MxToggle` (debug-level tile), the SQL log switch spec 2026-10-07; the toggle disables while its save runs, a refused save shows "Couldn't change that. The switch is unchanged."". Copy section: add the three strings. `28-monitoring.md`, the Not sent row: "the SQL log switch row (`MxSettingsRow` + `MxToggle`, the same row as screen 23's) first, above the `MxNote`". `00-index.md`: in rows 23 and 28 add "SQL log switch (2026-10-07)" to the sources column, keep the state `built`.

- [ ] **Step 5: The switch spec's two deviations**

§4.3: replace "listens to the settings DAO's watch of the column" with "listens to its own `.drift` query (`sql_log_queries.drift`, `SqlLogDao` in `core/logging`), as `core/auth` reads its device flags: `core` never imports a feature (ADR-011)". §5: replace "One widget in the monitoring feature, `MonitoringSqlLogRowWidget`" with "One widget in the settings feature, `SqlLogRowWidget` (it reads the settings stream and a settings use case, which ADR-011 keeps out of another feature); `MonitoringScreen` takes it through a `pendingHeader` slot and `app/` passes it, as it passes the Admin rows".

- [ ] **Step 6: Docs check and commit**

Run: `python3 tools/docs/generate.py && python3 tools/docs/check.py` → `PASS — 0 error(s)`.

```bash
git add -A
git commit -m "DEV-nnn: documents for the SQL log switch (sync spec, logging spec, ADR-018, screens 23 and 28)"
```

---

### Task 9: Gate, golden review, PR

- [ ] **Step 1: Bring master in**

`git fetch origin master && git merge origin/master`; on any change: `dart run build_runner build --delete-conflicting-outputs && flutter gen-l10n`.

- [ ] **Step 2: The gate**

Run: `bash .claude/skills/flutter-workflow/scripts/dod_check.sh > /tmp/dod.log 2>&1; echo exit=$?; grep -E "PASS|FAIL|All other tests|exit=" /tmp/dod.log | tail -5`
Expected: `PASS — 0 error(s)`, `All other tests passed!`, `exit=0`. Then `bash .claude/skills/flutter-workflow/scripts/run_goldens.sh` (no `--update`) → all golden tests pass.

- [ ] **Step 3: Golden review page**

`python3 .claude/skills/golden-compare/scripts/golden_compare.py build --base "$(git merge-base origin/master HEAD)" --out <scratchpad>/golden-compare-sql-log`; fill `notes.json` (one family "Công tắc Ghi câu SQL" with both shots; `why` in Vietnamese: the row appears third in Admin / first on Not sent, nothing else moves); `render`; publish with the Artifact tool (`root` = that dir, `files` = `publish_batches.json[0]`, `icon: "compare"`).

- [ ] **Step 4: Push and open the PR**

`git push -u origin <branch>`; PR title "DEV-nnn (epic DEV-eee): an admin turns SQL statement logging on or off, per account"; body: Linear links, the spec, root cause / solution, the two deviations, tests (red first), the golden review link, the gate line, **"pgTAP not run here (no Docker): owner runs `npx supabase test db` before merge"**, risks (spec §7), the Impeccable audit line, and the ledger. Then: Linear issues In Review, comment with the PR; merge only after the owner approves the goldens and reports pgTAP green.

---

## Execution ledger

(one line per task: commit, deviation and reason)


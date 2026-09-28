# Account settings sync (SB-S5) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The study and display settings (`card_limit`, `new_card_order`, `theme_mode`, `language`) sync per account. Reminders stay on the device, and a fresh install's defaults never overwrite the account.

**Architecture:** A fourth Supabase migration adds `public.account_settings`, keyed by `user_id`. On the wire the entity type is `account_settings` and the entity id is the nil UUID. Drift schema 9 adds an `AFTER UPDATE` trigger on `app_settings` that queues the row only when one of the four synced columns changes. The v8 → v9 step queues the row once when those columns differ from the defaults. `AccountSettingsSyncAdapter` reads and writes row `id = 1`. It has no `server_version` column, and acknowledgements and deletes are no-ops.

**Tech Stack:** Flutter 3.47.5, Drift, Riverpod 3, Supabase Postgres (PL/pgSQL, pgTAP).

**Spec:** [`docs/superpowers/specs/2026-09-28-sync-library-and-study-design.md`](../specs/2026-09-28-sync-library-and-study-design.md) §3.5 (D2), §4, §5. Previous slices: [card sync](2026-09-28-card-sync.md), [tag sync](2026-09-28-tag-sync.md); R1–R10 hold.

## Global Constraints

- Server integrity only. The new table has RLS on, no policy and no client privilege. The migration ends with `revoke all on all functions in schema private from public, anon, authenticated;`.
- The CHECKs mirror Drift's `app_settings` CHECKs: `new_card_order in ('created','random')`, `theme_mode in ('system','light','dark')`, `language in ('system','en','vi')`. `card_limit` has no CHECK, as in Drift.
- The nil UUID `00000000-0000-0000-0000-000000000000` is the only valid entity id for `account_settings`.
- `reminder_enabled`, `reminder_minute_of_day` and `reminder_last_delivered_at` are never read or written by sync.
- `lib/core` never imports `lib/features`; a shipped Drift step never changes.

## Review Focus

1. **A reminder change, or a write that only touches `updated_at`, queues nothing.** Tested in Task 2.
2. **A fresh install (defaults) syncing for the first time pushes nothing**, so it cannot overwrite the account. Tested in Tasks 2 and 3.
3. **A pulled settings row leaves the device's reminders alone.** Tested in Task 3.
4. **A push naming a non-nil entity id, or a delete, is refused**, so no second row or tombstone appears. Tested in Task 1.
5. **Two users each have their own row.** Tested in Task 1.

## Rulings made while planning

- **R11 — seed only non-defaults.** The v8 → v9 step queues the settings row only when a synced column differs from the Drift default. An install that never changed a setting does not push its defaults.
- **R12 — `updatedAt` travels, reminders do not.** A pulled row sets the four columns and `updated_at`.

## File Structure

| File | Responsibility |
|---|---|
| `supabase/migrations/20261001000000_account_settings_sync.sql` (new) | table, upsert, change feed, dispatch |
| `supabase/tests/database/07_account_settings_sync.sql` (new), `01_schema_privileges.sql` | pgTAP |
| `lib/core/database/tables/sync.drift`, `app_database.dart` | schema 9 trigger and seed |
| `lib/core/sync/account_settings_sync_adapter.dart` (new) | wire row ↔ `app_settings` id 1 |
| `lib/core/sync/di/sync_providers.dart` | registers the adapter last |
| tests under `test/core/sync/`, `test/drift/`; docs |

---

### Task 1: Server

**Files:** Create `supabase/migrations/20261001000000_account_settings_sync.sql`, `supabase/tests/database/07_account_settings_sync.sql`; modify `01_schema_privileges.sql`.

**Interfaces:** Produces entity type `account_settings`, entity id nil UUID, row `cardLimit` (int), `newCardOrder`, `themeMode`, `language`, `updatedAt`.

- [ ] **Step 1: Failing pgTAP** `07_account_settings_sync.sql`:

```sql
begin;
create extension if not exists pgtap with schema extensions;
select plan(9);

create function public.t_nil() returns uuid language sql immutable as $$
  select '00000000-0000-0000-0000-000000000000'::uuid $$;
create function public.t_settings(p_theme text) returns jsonb language sql as $$
  select jsonb_build_object('cardLimit', 30, 'newCardOrder', 'random', 'themeMode', p_theme,
    'language', 'vi', 'updatedAt', '2026-09-28T00:00:00Z') $$;
create function public.t_op(p_op int, p_id uuid, p_kind text, p_row jsonb) returns jsonb language sql as $$
  select jsonb_build_object('opId', format('00000000-0000-0000-0000-%s', lpad((100000 + p_op)::text, 12, '0')),
    'entityType', 'account_settings', 'entityId', p_id, 'op', p_kind, 'row', p_row) $$;
create function public.t_push(p_ops jsonb) returns jsonb language sql as $$
  select public.sync_push(jsonb_build_object('deviceId', '00000000-0000-0000-0000-0000000000d1',
    'operations', p_ops))->'results' $$;
create function public.t_changes() returns jsonb language sql as $$
  select coalesce(jsonb_agg(c), '[]') from jsonb_array_elements(public.sync_changes(0, 500)->'changes') c
  where c->>'entityType' = 'account_settings' $$;

set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"aaaaaaaa-0000-0000-0000-000000000001","role":"authenticated"}', true);

select is(public.t_push(jsonb_build_array(public.t_op(1, public.t_nil(), 'upsert', public.t_settings('dark'))))->0->>'status',
  'applied', 'settings are applied');
select is(public.t_changes()->0,
  jsonb_build_object('entityType', 'account_settings', 'entityId', public.t_nil(), 'serverVersion', 1,
    'deleted', false, 'row', jsonb_build_object('cardLimit', 30, 'newCardOrder', 'random',
      'themeMode', 'dark', 'language', 'vi', 'updatedAt', '2026-09-28T00:00:00.000000Z')),
  'settings read back in the wire shape, under the nil id');
select is(public.t_push(jsonb_build_array(public.t_op(2, public.t_nil(), 'upsert', public.t_settings('light'))))->0->>'status',
  'applied', 'a second upsert is applied');
select is(jsonb_array_length(public.t_changes()), 1, 'one row per user');
select is(public.t_changes()->0->'row'->>'themeMode', 'light', 'the later upsert wins');
select is(public.t_push(jsonb_build_array(public.t_op(3, '00000000-0000-0000-0000-000000000001', 'upsert',
    public.t_settings('dark'))))->0->>'code', 'VALIDATION_FAILED', 'only the nil id names the settings');
select is(public.t_push(jsonb_build_array(public.t_op(4, public.t_nil(), 'upsert', public.t_settings('neon'))))->0->>'code',
  'VALIDATION_FAILED', 'a theme outside the CHECK is refused');
select is(public.t_push(jsonb_build_array(public.t_op(5, public.t_nil(), 'delete', null)))->0->>'code',
  'VALIDATION_FAILED', 'settings are never deleted');

select set_config('request.jwt.claims',
  '{"sub":"bbbbbbbb-0000-0000-0000-000000000002","role":"authenticated"}', true);
select is(public.t_changes(), '[]'::jsonb, 'another user sees no settings');

select * from finish();
rollback;
```

In `01_schema_privileges.sql`: `plan(10)`; add `select has_table('public', 'account_settings', 'account_settings exists');`; add `'account_settings'` to the three name lists; the RLS count becomes `8`.

- [ ] **Step 2: Run** — `bash tools/supabase/local_pgtap.sh` → `01` FAIL and `07` ERROR/FAIL.

- [ ] **Step 3: Migration** —

```sql
-- SB-S5 / library and study sync spec §3.5: the study and display settings, one row per user.
-- On the wire the entity id is the nil UUID (D2); reminders stay on the device.

create table public.account_settings (
  user_id uuid primary key,
  card_limit integer not null,
  new_card_order text not null check (new_card_order in ('created', 'random')),
  theme_mode text not null check (theme_mode in ('system', 'light', 'dark')),
  language text not null check (language in ('system', 'en', 'vi')),
  updated_at timestamptz not null,
  server_version bigint not null,
  last_device_id uuid not null
);
create unique index uq_account_settings_user_version on public.account_settings (user_id, server_version);

alter table public.account_settings enable row level security;
revoke all on table public.account_settings from public, anon, authenticated;

create function private.account_settings_change(s public.account_settings) returns jsonb
language sql stable set search_path = '' as $$
  select jsonb_build_object(
    'entityType', 'account_settings', 'entityId', '00000000-0000-0000-0000-000000000000'::uuid,
    'serverVersion', s.server_version, 'deleted', false,
    'row', jsonb_build_object('cardLimit', s.card_limit, 'newCardOrder', s.new_card_order,
      'themeMode', s.theme_mode, 'language', s.language, 'updatedAt', private.wire_time(s.updated_at)))
$$;

create function private.account_settings_upsert(p_user uuid, p_device uuid, p_id uuid, r jsonb) returns bigint
language plpgsql set search_path = '' as $$
declare
  v_version bigint;
begin
  if p_id is distinct from '00000000-0000-0000-0000-000000000000'::uuid then
    raise exception 'VALIDATION_FAILED';
  end if;
  v_version := private.allocate_versions(p_user, 1);
  insert into public.account_settings (user_id, card_limit, new_card_order, theme_mode, language, updated_at,
    server_version, last_device_id)
  values (p_user, (r->>'cardLimit')::integer, r->>'newCardOrder', r->>'themeMode', r->>'language',
    (r->>'updatedAt')::timestamptz, v_version, p_device)
  on conflict (user_id) do update set
    card_limit = excluded.card_limit, new_card_order = excluded.new_card_order,
    theme_mode = excluded.theme_mode, language = excluded.language, updated_at = excluded.updated_at,
    server_version = excluded.server_version, last_device_id = excluded.last_device_id;
  return v_version;
end
$$;
```

Then `create or replace`, each copying its SB-S3 body (`20260930000000_tag_sync.sql`) verbatim plus only this change:
- `private.current_change`: an `account_settings` branch, `select * into v_settings from public.account_settings where user_id = p_user;` → `private.account_settings_change(v_settings)`. `p_id` is ignored.
- `private.apply_operation`: an upsert branch for `account_settings`. There is no delete branch, so a delete falls through to `VALIDATION_FAILED`.
- `private.push_one`: the type list gains `'account_settings'`.
- `public.sync_changes`: a fifth `union all` branch, `(select 'account_settings', '00000000-0000-0000-0000-000000000000'::uuid, s.server_version from public.account_settings s where s.user_id = v_user and s.server_version > v_since order by s.server_version limit v_limit + 1)`. `private.current_change` is called with that nil id, and the branch above ignores it.

End with `revoke all on all functions in schema private from public, anon, authenticated;`.

- [ ] **Step 4: Run** — `bash tools/supabase/local_pgtap.sh` → all ok, `07 (9)`.
- [ ] **Step 5: Commit** — `SB-S5: server account_settings, one row per user under the nil id`.

---

### Task 2: Drift schema 9 — settings trigger and seed

**Files:** modify `lib/core/database/tables/sync.drift`, `app_database.dart`; regenerate the schema files; tests `test/core/sync/sync_triggers_test.dart`, `test/drift/migration_test.dart` (and move the `nfc_migration_test.dart` targets that sit at 8 to 9).

**Interfaces:** Produces the trigger `app_settings_sync_update` (entity `account_settings`, id nil UUID) and the Dart constant `accountSettingsEntityId = '00000000-0000-0000-0000-000000000000'` in `lib/core/database/tables/sync_keys.dart`.

- [ ] **Step 1: Failing tests** — in `sync_triggers_test.dart`:

```dart
  test('changing a synced setting queues the account settings', () async {
    await db.customStatement("UPDATE app_settings SET theme_mode = 'dark' WHERE id = 1");
    final entry = (await _outbox(db)).single;
    expect(entry['entity_type'], 'account_settings');
    expect(entry['entity_id'], accountSettingsEntityId);
    expect(entry['op'], 'upsert');
  });

  test('a reminder or updated_at alone queues nothing', () async {
    await db.customStatement(
      'UPDATE app_settings SET reminder_enabled = 1, reminder_minute_of_day = 600, updated_at = 99 WHERE id = 1',
    );
    await db.customStatement("UPDATE app_settings SET theme_mode = theme_mode WHERE id = 1");
    expect(await _outbox(db), isEmpty);
  });

  test('settings written under applying_remote queue nothing', () async {
    await db.customStatement(
      "INSERT INTO sync_state (name, value) VALUES ('$syncApplyingRemoteKey', '1')",
    );
    await db.customStatement("UPDATE app_settings SET language = 'vi' WHERE id = 1");
    expect(await _outbox(db), isEmpty);
  });
```

(Import `sync_keys.dart` if not already.) Add `const accountSettingsEntityId = '00000000-0000-0000-0000-000000000000';` with a doc line (`The wire id of the account settings: one row per user (library and study sync spec §3.5, D2).`) to `sync_keys.dart` now, so the test compiles and fails on the missing trigger. Run → FAIL.

- [ ] **Step 2: Trigger** — in `sync.drift`, `import 'settings.drift';` and:

```sql
-- SB-S5: the study and display settings sync per account; reminders and a
-- write that changes none of the four columns queue nothing (library and study
-- sync spec §3.5). The entity id is the nil UUID (D2).
CREATE TRIGGER app_settings_sync_update AFTER UPDATE ON app_settings
WHEN (SELECT value FROM sync_state WHERE name = 'applying_remote') IS NULL
  AND (old.card_limit IS NOT new.card_limit OR old.new_card_order IS NOT new.new_card_order
    OR old.theme_mode IS NOT new.theme_mode OR old.language IS NOT new.language)
BEGIN
  INSERT INTO sync_outbox (op_id, entity_type, entity_id, op, created_at)
  VALUES (<the op_id expression every trigger uses>,
          'account_settings', '00000000-0000-0000-0000-000000000000', 'upsert', CAST(strftime('%s', 'now') AS INTEGER))
  ON CONFLICT (entity_type, entity_id) DO UPDATE SET op_id = excluded.op_id, op = excluded.op;
END;
```

`schemaVersion => 9`; regenerate (build_runner, schema dump, steps, generate).

- [ ] **Step 3: Migration tests** — move the `8` targets to `9` (titles `of v9`), add `v8 upgrades to the schema of v9`, and:

```dart
  test('a v8 database queues its settings only when they are not the defaults', () async {
    for (final (theme, queued) in [('system', 0), ('dark', 1)]) {
      final schema = await verifier.schemaAt(8);
      schema.rawDatabase
        ..execute(
          'INSERT OR IGNORE INTO app_settings (id, updated_at) VALUES (1, 0)',
        )
        ..execute("UPDATE app_settings SET theme_mode = '$theme' WHERE id = 1")
        ..execute('DELETE FROM sync_outbox');
      final db = AppDatabase(schema.newConnection());
      await verifier.migrateAndValidate(db, 9);
      final rows = await db
          .customSelect("SELECT 1 FROM sync_outbox WHERE entity_type = 'account_settings'")
          .get();
      expect(rows, hasLength(queued), reason: theme);
      await db.close();
    }
  });
```

Run → FAIL (no `from8To9`).

- [ ] **Step 4: Step** —

```dart
      from8To9: (m, schema) async {
        // SB-S5: the study and display settings sync per account (library and
        // study sync spec §3.5). They are queued once only when they differ
        // from the defaults, so an untouched install never overwrites the
        // account (plan R11).
        await m.createTrigger(schema.appSettingsSyncUpdate);
        await customStatement(
          "INSERT INTO sync_outbox (op_id, entity_type, entity_id, op, created_at) "
          "SELECT lower(hex(randomblob(4)) || '-' || hex(randomblob(2)) || '-4' || "
          "substr(hex(randomblob(2)), 2) || '-' || substr('89ab', 1 + (abs(random()) % 4), 1) || "
          "substr(hex(randomblob(2)), 2) || '-' || hex(randomblob(6))), "
          "'account_settings', '$accountSettingsEntityId', 'upsert', "
          "CAST(strftime('%s', 'now') AS INTEGER) FROM app_settings "
          "WHERE id = $appSettingsRowId AND (card_limit <> 20 OR new_card_order <> 'created' "
          "OR theme_mode <> 'system' OR language <> 'system')",
        );
      },
```

(import `sync_keys.dart` in `app_database.dart`). Run `flutter test test/drift/ test/core/sync/sync_triggers_test.dart` → PASS; `flutter analyze` clean.

- [ ] **Step 5: Commit** — `SB-S5: Drift schema 9 — the settings trigger, seeded only when not the defaults`.

---

### Task 3: Adapter, wiring, convergence

**Files:** Create `lib/core/sync/account_settings_sync_adapter.dart`, `test/core/sync/account_settings_sync_test.dart`; modify `di/sync_providers.dart` and the `_Device`s of `sync_coordinator_test.dart`, `card_sync_convergence_test.dart`, `tag_sync_convergence_test.dart`, `sync_bulk_test.dart` (the adapter goes last).

**Interfaces:** Produces `AccountSettingsSyncAdapter(AppDatabase db)`, `static const type = 'account_settings'`.

- [ ] **Step 1: Failing test** `account_settings_sync_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/tables/sync_keys.dart';
import 'package:memox/core/sync/account_settings_sync_adapter.dart';
import 'package:memox/core/sync/card_sync_adapter.dart';
import 'package:memox/core/sync/deck_sync_adapter.dart';
import 'package:memox/core/sync/delete_batch_sync_adapter.dart';
import 'package:memox/core/sync/sync_coordinator.dart';
import 'package:memox/core/sync/sync_store.dart';
import 'package:memox/core/sync/tag_sync_adapter.dart';

import '../../support/test_database.dart';
import 'fake_sync_server.dart';

class _Device {
  _Device(FakeSyncServer server) : db = openTestDatabase() {
    final store = SyncStore(db);
    final cards = CardSyncAdapter(db);
    coordinator = SyncCoordinator(
      api: server,
      store: store,
      adapters: [
        DeleteBatchSyncAdapter(db),
        DeckSyncAdapter(db),
        TagSyncAdapter(db, store),
        cards,
        AccountSettingsSyncAdapter(db),
      ],
      afterPull: cards.ensureSchedules,
    );
  }
  final AppDatabase db;
  late final SyncCoordinator coordinator;
}

Future<AppSetting> _settings(AppDatabase db) =>
    (db.select(db.appSettings)..where((s) => s.id.equals(appSettingsRowId))).getSingle();

void main() {
  late FakeSyncServer server;
  late _Device a;
  late _Device b;
  setUp(() async {
    server = FakeSyncServer();
    a = _Device(server);
    b = _Device(server);
    await _settings(a.db); // opens both, creating row 1
    await _settings(b.db);
  });
  tearDown(() async {
    await a.db.close();
    await b.db.close();
  });

  test('the adapter reads row 1 in the wire shape', () async {
    await a.db.customStatement(
      "UPDATE app_settings SET card_limit = 30, theme_mode = 'dark', updated_at = 1790553600 WHERE id = 1",
    );
    expect(await AccountSettingsSyncAdapter(a.db).readRow(accountSettingsEntityId), {
      'cardLimit': 30,
      'newCardOrder': 'created',
      'themeMode': 'dark',
      'language': 'system',
      'updatedAt': '2026-09-28T00:00:00Z',
    });
  });

  test('a setting changed on one device reaches the other; its reminders stay', () async {
    await b.db.customStatement(
      'UPDATE app_settings SET reminder_enabled = 1, reminder_minute_of_day = 480 WHERE id = 1',
    );
    await a.db.customStatement(
      "UPDATE app_settings SET theme_mode = 'dark', language = 'vi' WHERE id = 1",
    );
    await a.coordinator.runOnce();
    await b.coordinator.runOnce();

    final settings = await _settings(b.db);
    expect(settings.themeMode, 'dark');
    expect(settings.language, 'vi');
    expect(settings.reminderEnabled, 1);
    expect(settings.reminderMinuteOfDay, 480);
    expect(await b.db.select(b.db.syncOutbox).get(), isEmpty);
  });

  test('a device on the defaults pushes no settings', () async {
    await b.coordinator.runOnce();
    expect(server.pushed.where((k) => k.startsWith('account_settings/')), isEmpty);
  });
}
```

Run → FAIL (no adapter).

- [ ] **Step 2: Adapter**:

```dart
import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/sync/entity_sync_adapter.dart';

/// Syncs the study and display settings of `app_settings` row 1 as the one
/// account row the server keeps per user (library and study sync spec §3.5).
/// Reminders never leave the device. The row has no server version and is
/// never deleted, so acknowledgements and deletes do nothing.
class AccountSettingsSyncAdapter implements EntitySyncAdapter {
  AccountSettingsSyncAdapter(this._db);

  static const type = 'account_settings';

  final AppDatabase _db;

  @override
  String get entityType => type;

  @override
  Future<Map<String, Object?>?> readRow(String id) async {
    final row = await (_db.select(
      _db.appSettings,
    )..where((s) => s.id.equals(appSettingsRowId))).getSingleOrNull();
    if (row == null) {
      return null;
    }
    return {
      'cardLimit': row.cardLimit,
      'newCardOrder': row.newCardOrder,
      'themeMode': row.themeMode,
      'language': row.language,
      'updatedAt': toWireTime(row.updatedAt)!.replaceFirst(RegExp(r'\.\d+Z$'), 'Z'),
    };
  }

  @override
  Future<void> upsertFromServer(Map<String, Object?> row, int serverVersion) =>
      (_db.update(_db.appSettings)..where((s) => s.id.equals(appSettingsRowId))).write(
        AppSettingsCompanion(
          cardLimit: Value(row['cardLimit'] as int),
          newCardOrder: Value(row['newCardOrder'] as String),
          themeMode: Value(row['themeMode'] as String),
          language: Value(row['language'] as String),
          updatedAt: Value(fromWireTime(row['updatedAt'])!),
        ),
      );

  @override
  Future<void> deleteFromServer(String id) async {}

  @override
  Future<void> markAcknowledged(String id, int serverVersion) async {}
}
```

- [ ] **Step 3: Wiring** — `AccountSettingsSyncAdapter(db)` goes last in `sync_providers.dart` and in each test `_Device` listed above. Run `flutter test test/core/sync/` → PASS.

- [ ] **Step 4: Commit** — `SB-S5: account settings adapter; a setting reaches the other device, reminders stay`.

---

### Task 4: Docs, gate, WBS

- [ ] `schema.md`: the outbox `entity_type` list gains `account_settings` (schema 9, id nil UUID); the trigger paragraph names `app_settings` (the four columns only). `flutter-data-layer` skill: "decks, trash batches, cards, tags and account settings sync today".
- [ ] Gate: `bash .claude/skills/flutter-workflow/scripts/dod_check.sh`, `bash tools/supabase/local_pgtap.sh`, `python3 tools/docs/generate.py && python3 tools/docs/check.py`. A test that snapshots every table after a settings write (like BR-TAG-009's helper) may now see `sync_outbox` change. Handle it as SB-S3 did, with a ledgered ruling.
- [ ] WBS: SB-S5 `xong` with the PR link, this plan, the migration and tests; a dated line under "Ngữ cảnh cập nhật".
- [ ] Execution ledger appended here; commit `SB-S5: docs, WBS and ledger`.

## Execution ledger

Executed inline (executing-plans) on 2026-09-28.

- Spec: docs/superpowers/specs/2026-09-28-sync-library-and-study-design.md
- Pre-flight:
- - T1→T3: wire row keys (cardLimit, newCardOrder, themeMode, language, updatedAt) and nil id — consistent.
- - T2→T3: accountSettingsEntityId in sync_keys.dart — consistent.
- Task 1: complete (commits 47f44fd..d48415b, tests: bash tools/supabase/local_pgtap.sh → ok    07_account_settings_sync.sql (9))
- Task 2: complete (commits d48415b..a200ec3, tests: flutter test test/drift/ test/core/sync/sync_triggers_test.dart → 00:03 +42: All tests passed!)
- Task 3: complete (commits a200ec3..142bb62, tests: flutter test test/core/sync/ → 00:10 +89: All tests passed!)
- Task 4: Ruling: app_settings_repository_test's reset-to-defaults test counted total_changes() = before + 1; the SB-S5 trigger adds the outbox row, so it now expects before + 2 and asserts exactly one account_settings outbox entry — the 'one write' intent holds for app_settings — cost if wrong: none
- Final review: fresh reviewer — ready; no Critical/Important.
- Final: minor (deferred): spec §3.5 lists `deleted_at` on `account_settings`; the table has none, since settings are never deleted.
- Final: minor (handled): the SB-S5 WBS row gets its PR link after the PR opens.

Gate: `dod_check.sh` green (2591 tests), `tools/supabase/local_pgtap.sh` 104/104, docs check PASS.

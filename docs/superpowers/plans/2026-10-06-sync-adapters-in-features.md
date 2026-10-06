# Sync adapters in features Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move the seven concrete sync adapters out of `lib/core/sync/` into the features that
own their tables, register them at the composition root, and leave each duplicated rule with one
owner.

**Architecture:** `core/sync` keeps the infrastructure and declares two providers that throw
until the root overrides them:

- `syncAdaptersProvider` (the ordered adapter list);
- `syncedSettingsResetProvider` (the synced-settings reset `LocalDataReset` calls).

`lib/app/sync_tables.dart` builds both from feature DAOs, and `main.dart` installs them.

Each adapter becomes a `<Name>SyncDao` Drift accessor in
`features/<owner>/data/datasources/`. `EntitySyncAdapter.afterPull()` replaces the
coordinator's `afterPull` argument.

**Tech Stack:**
- Flutter 3.47.5 and Dart 3.13;
- Riverpod 3 with codegen (`riverpod_annotation`);
- Drift accessors (`@DriftAccessor`, `.drift` query files);
- `build_runner` (the `.g.dart` files are git-ignored and regenerated).

**Spec:** `docs/superpowers/specs/2026-10-06-sync-adapters-in-features-design.md`

## Global Constraints

- `core/` never imports `features/`, `app/` or `shared/` (ADR-011; `boundaries_test.dart`).
- **Adapter files.**
  - Path: `lib/features/<owner>/data/datasources/<name>_sync_dao.dart`.
  - Class: `<Name>SyncDao implements EntitySyncAdapter`, using the `_dao` suffix (ruling S1).
- **Wire unchanged.** Entity type strings, wire maps and `.drift` queries keep their content;
  the `.drift` files stay in `lib/core/database/queries/`.
- **Adapter order:** delete batches, decks, tags, cards, card schedules, review logs, account
  settings.
- **Settings reset scope.** Reset touches only `card_limit`, `new_card_order`, `theme_mode`,
  `language` and `updated_at`. Reminder and welcome columns stay.
- **Generated code.** After any change to an annotated file, run
  `dart run build_runner build -d`. Never commit `.g.dart`.
- **Gate.**
  - The final check is `bash .claude/skills/flutter-workflow/scripts/dod_check.sh`.
  - Partial runs use `bash .claude/skills/flutter-workflow/scripts/run_tests.sh <paths>`.
- **Commits.** Messages start `DEV-173:` and end with the session's `Co-Authored-By` and
  `Claude-Session` lines.

## Plan rulings

- **P1 · Tag relink, a deviation from spec §3.5.** `mergeTagLinks` cannot be reused when a
  pulled tag absorbs a local one.
  - The folded name is unique, so the local tag must be deleted before the pulled one lands.
  - Deleting it cascades away the links that `mergeTagLinks` would copy.
  - `TagSyncDao` therefore keeps its relink query (`linkSyncedTagCard`, `INSERT OR IGNORE`).
  - The merge rule now has one owner, the tags feature, and the spec's goal holds.
  - The PR states this deviation.

## Review Focus

1. **A pull applies cards whose decks arrived in an earlier page.** `afterPull` must give every
   card without a schedule its root's initial state. Covered in Task 4: the convergence tests,
   plus a new two-scheduler test.
2. **A pull fails mid-way.** `afterPull` must not run. Covered in Task 1, test
   `afterPull is not called when a pull fails`.
3. **Account switch while the settings row has reminder and welcome set.** Both must survive the
   reset. Covered in Task 2: `local_data_reset_test` keeps its assertions.
4. **A build or test that forgets the override.** The provider must fail loudly with the
   override hint, not silently sync nothing. Covered in Task 2: `sync_providers_test`.
5. **A pulled tag whose folded name clashes with a local tag carried by a card that already has
   the pulled tag.** The relink must not fail on the primary key. Covered in Task 5: the
   existing `tag_sync_adapter_test` cases move unchanged.

---

### Task 1: `afterPull()` on the adapter contract

**Files:**
- Modify: `lib/core/sync/entity_sync_adapter.dart`
- Modify: `lib/core/sync/sync_coordinator.dart` (constructor `_afterPull`, line ~198)
- Modify: `lib/core/sync/card_sync_adapter.dart` (`ensureSchedules` → `afterPull` override)
- Modify: `lib/core/sync/di/sync_providers.dart` (drop `afterPull:`)
- Modify tests that pass `afterPull: cards.ensureSchedules`:
  - `test/core/sync/sync_coordinator_test.dart`
  - `study_history_convergence_test.dart`
  - `account_settings_sync_test.dart`
  - `sync_bulk_test.dart`
  - `card_sync_convergence_test.dart`
  - `tag_sync_convergence_test.dart`
  - `card_sync_adapter_test.dart` (calls `ensureSchedules`)

**Interfaces:**
- Produces: `EntitySyncAdapter.afterPull()`, of type `Future<void> afterPull() async {}`.
- Produces: `SyncCoordinator` without an `afterPull` parameter; it calls `afterPull()` on each
  adapter in list order at the end of a successful pull.

- [ ] **Step 1: Write the failing tests** in `test/core/sync/sync_coordinator_test.dart`, using
  the file's existing fake server and store setup.

```dart
class _RecordingAdapter implements EntitySyncAdapter {
  _RecordingAdapter(this.entityType, this.calls);
  @override
  final String entityType;
  final List<String> calls;
  @override
  Future<Map<String, Object?>?> readRow(String id) async => null;
  @override
  Future<void> upsertFromServer(Map<String, Object?> row, int v) async {}
  @override
  Future<void> deleteFromServer(String id) async {}
  @override
  Future<void> markAcknowledged(String id, int v) async {}
  @override
  Future<void> afterPull() async => calls.add(entityType);
}

test('afterPull runs on every adapter in list order after a pull', () async {
  final calls = <String>[];
  final coordinator = SyncCoordinator(
    api: server, // the file's FakeSyncServer
    store: store,
    adapters: [_RecordingAdapter('a', calls), _RecordingAdapter('b', calls)],
    now: () => DateTime.utc(2026),
  );
  await coordinator.runOnce();
  expect(calls, ['a', 'b']);
});

test('afterPull is not called when a pull fails', () async {
  final calls = <String>[];
  server.failNextPull = true; // add this switch to FakeSyncServer if absent
  final coordinator = SyncCoordinator(
    api: server,
    store: store,
    adapters: [_RecordingAdapter('a', calls)],
    now: () => DateTime.utc(2026),
  );
  await expectLater(coordinator.runOnce(), throwsA(anything));
  expect(calls, isEmpty);
});
```

- [ ] **Step 2: Run them and see them fail.**
  - Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/core/sync/sync_coordinator_test.dart`
  - Expected: compile error, `afterPull` is not a member of `EntitySyncAdapter`.

- [ ] **Step 3: Implement.**
  - In `entity_sync_adapter.dart`, add to `EntitySyncAdapter`:

```dart
  /// Runs once at the end of a successful pull, in list order, still under
  /// `applying_remote`: the place for a rule that needs every pulled row,
  /// such as giving new cards their schedule (BR-CARD-004). None by default.
  Future<void> afterPull() async {}
```

  - In `sync_coordinator.dart`:
    - Delete the `_afterPull` field and constructor parameter.
    - Replace `await _afterPull?.call();` (line ~198) with:

```dart
      for (final adapter in _adapters) {
        await adapter.afterPull();
      }
```

  (keep it at the same place, inside the applying-remote section). In `card_sync_adapter.dart` rename `ensureSchedules` to:

```dart
  /// Gives every card without a schedule its root's initial row
  /// (BR-CARD-004). Moves to srs with DEV-173 Task 4.
  @override
  Future<void> afterPull() => ensureCardSchedules();
```

  - In `sync_providers.dart`, drop `afterPull: cards.ensureSchedules,` and the `cards` local.
  - In each listed test, drop the `afterPull:` argument. In `card_sync_adapter_test.dart`,
    replace `adapter.ensureSchedules()` with `adapter.afterPull()`.

- [ ] **Step 4: Regenerate and run.**
  - Regenerate: `dart run build_runner build -d`.
  - Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/core/sync`
  - Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git add -A lib/core/sync test/core/sync
git commit -m "DEV-173: afterPull is an adapter hook, not a coordinator argument"
```

### Task 2: Root-overridden providers, settings reset from the settings feature

**Files:**
- Modify: `lib/core/sync/di/sync_providers.dart`
- Modify: `lib/core/auth/di/auth_providers.dart`
- Modify: `lib/core/database/local_data_reset.dart`
- Modify: `lib/features/settings/data/datasources/settings_dao.dart`
- Create: `lib/app/sync_tables.dart`
- Modify: `lib/main.dart`
- Test: `test/core/sync/sync_providers_test.dart`, `test/core/database/local_data_reset_test.dart`, `test/support/auth_fakes.dart` (only if `FakeLocalDataReset`'s constructor no longer matches)

**Interfaces:**
- Produces:
  - `syncAdaptersProvider`: `List<EntitySyncAdapter>`.
  - `syncedSettingsResetProvider`: `Future<void> Function()`, declared in
    `lib/core/auth/di/auth_providers.dart`.
  - `LocalDataReset(AppDatabase db, {required Future<void> Function() resetSyncedSettings, DateTime Function()? now})`.
  - `SettingsDao.resetSyncedDefaults(DateTime at)`.
  - `syncTableOverrides` in `lib/app/sync_tables.dart`, built from `appSyncAdapters(Ref)` and
    `appSyncedSettingsReset(Ref)`.

- [ ] **Step 1: Write the failing tests.**
  - In `test/core/sync/sync_providers_test.dart` add:

```dart
test('the coordinator cannot be built without the root override', () {
  final container = ProviderContainer(
    overrides: [databaseProvider.overrideWithValue(openTestDatabase())],
  );
  addTearDown(container.dispose);
  expect(
    () => container.read(syncCoordinatorProvider),
    throwsA(isA<UnimplementedError>()),
  );
});

test('with the app overrides the coordinator syncs the seven tables in order',
    () {
  final db = openTestDatabase();
  addTearDown(db.close);
  final container = ProviderContainer(
    overrides: [databaseProvider.overrideWithValue(db), ...syncTableOverrides],
  );
  addTearDown(container.dispose);
  expect(
    container.read(syncAdaptersProvider).map((a) => a.entityType),
    ['delete_batch', 'deck', 'tag', 'card', 'card_schedule', 'review_log',
     'account_settings'],
  );
});
```

  (Read each adapter's `static const type` and use its exact strings.)
  - In `test/core/database/local_data_reset_test.dart`, change
    `LocalDataReset(db).run()` to:

```dart
    await LocalDataReset(
      db,
      resetSyncedSettings: () =>
          SettingsDao(db).resetSyncedDefaults(DateTime.utc(2026)),
    ).run();
```

  Keep all of the test's assertions: `cardLimit` 20, `'created'`, `'system'`, `'system'`,
  reminder 1 and 480, `welcomeSeen` 1.

- [ ] **Step 2: Run them and see them fail.**
  - Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/core/sync/sync_providers_test.dart test/core/database/local_data_reset_test.dart`
  - Expected: compile errors (`syncAdaptersProvider`, `syncTableOverrides`,
    `resetSyncedSettings` and `resetSyncedDefaults` are undefined).

- [ ] **Step 3: Implement the providers.**
  - In `sync_providers.dart`:

```dart
/// The synced tables, parent before child: the list order is the push and
/// the apply order (decks before cards, cards before schedules). Overridden
/// at the composition root (`lib/app/sync_tables.dart`), which may import
/// the features that own the tables (ADR-011).
@Riverpod(keepAlive: true)
List<EntitySyncAdapter> syncAdapters(Ref ref) => throw UnimplementedError(
  'override syncAdaptersProvider at the root (lib/app/sync_tables.dart)',
);

@Riverpod(keepAlive: true)
SyncCoordinator syncCoordinator(Ref ref) {
  final clock = ref.watch(dayClockProvider);
  return SyncCoordinator(
    api: ref.watch(syncApiProvider),
    store: ref.watch(syncStoreProvider),
    adapters: ref.watch(syncAdaptersProvider),
    now: clock.now,
  );
}
```

  Remove the seven adapter imports from this file.
  - In `auth_providers.dart`:

```dart
/// Returns the synced settings to their defaults inside LocalDataReset's
/// transaction; the device's own columns (reminder, welcome) stay. Overridden
/// at the composition root by the settings feature.
@Riverpod(keepAlive: true)
Future<void> Function() syncedSettingsReset(Ref ref) => throw UnimplementedError(
  'override syncedSettingsResetProvider at the root (lib/app/sync_tables.dart)',
);
```

  and build `LocalDataReset(db, resetSyncedSettings: ref.watch(syncedSettingsResetProvider), now: clock.now)`.

- [ ] **Step 4: Implement the reset.**
  - In `local_data_reset.dart`:
    - Add the required named parameter `this._resetSyncedSettings`, typed
      `Future<void> Function()`.
    - Replace the raw `UPDATE app_settings …` statement with
      `await _resetSyncedSettings();`, at the same place inside the transaction.
    - Keep `_db.appSettings` in `markTablesUpdated`.
    - If `appSettingsRowId` is now unused, drop its import.
  - In `settings_dao.dart`, add:

```dart
  /// The synced settings back to [AppSettingsEntity.defaults]; the device's
  /// own columns (reminder, welcome) are left alone. Used by the account
  /// reset (auth spec §4).
  Future<void> resetSyncedDefaults(DateTime at) {
    const defaults = AppSettingsEntity.defaults;
    return updateRow(
      AppSettingsCompanion(
        cardLimit: Value(defaults.studyDefaults.cardLimit),
        newCardOrder: Value(defaults.studyDefaults.newCardOrder.name),
        themeMode: Value(defaults.theme.name),
        language: Value(defaults.language.name),
        updatedAt: Value(at),
      ),
    );
  }
```

  (import `package:memox/features/settings/domain/entities/app_settings_entity.dart`; match the
  names `SettingsRepositoryImpl.resetToDefaults` uses for the same four fields, lines 63-70).

- [ ] **Step 5: Create the composition root, `lib/app/sync_tables.dart`.**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/auth/di/auth_providers.dart';
import 'package:memox/core/clock/di/day_clock_provider.dart';
import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/core/sync/di/sync_providers.dart';
import 'package:memox/core/sync/entity_sync_adapter.dart';
import 'package:memox/features/settings/data/datasources/settings_dao.dart';
// Tasks 4 and 5 point these imports at the features.
import 'package:memox/core/sync/account_settings_sync_adapter.dart';
import 'package:memox/core/sync/card_schedule_sync_adapter.dart';
import 'package:memox/core/sync/card_sync_adapter.dart';
import 'package:memox/core/sync/deck_sync_adapter.dart';
import 'package:memox/core/sync/delete_batch_sync_adapter.dart';
import 'package:memox/core/sync/review_log_sync_adapter.dart';
import 'package:memox/core/sync/tag_sync_adapter.dart';

/// The synced tables the app ships, parent before child: the order is the
/// push and the apply order (DEV-173).
List<EntitySyncAdapter> appSyncAdapters(Ref ref) {
  final db = ref.watch(databaseProvider);
  final store = ref.watch(syncStoreProvider);
  final now = ref.watch(dayClockProvider).now;
  return [
    DeleteBatchSyncAdapter(db),
    DeckSyncAdapter(db),
    TagSyncAdapter(db, store, now: now),
    CardSyncAdapter(db),
    CardScheduleSyncAdapter(db, store, now: now),
    ReviewLogSyncAdapter(db),
    AccountSettingsSyncAdapter(db),
  ];
}

/// The settings feature's reset of the synced settings (DEV-173).
Future<void> Function() appSyncedSettingsReset(Ref ref) {
  final dao = SettingsDao(ref.watch(databaseProvider));
  final now = ref.watch(dayClockProvider).now;
  return () => dao.resetSyncedDefaults(now());
}

/// What `main.dart` and the tests install so core's sync and reset see the
/// app's tables.
final syncTableOverrides = [
  syncAdaptersProvider.overrideWith(appSyncAdapters),
  syncedSettingsResetProvider.overrideWith(appSyncedSettingsReset),
];
```

- [ ] **Step 6: Install it in `main.dart`.**
  - Change `ProviderContainer(retry: _noRetry, observers: […])` to also pass
    `overrides: syncTableOverrides`.
  - Import `package:memox/app/sync_tables.dart`.

- [ ] **Step 7: Regenerate, run, analyze.**
  - Regenerate: `dart run build_runner build -d`.
  - Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/core test/features/account test/features/settings test/app`
  - Run: `dart analyze lib test`
  - Expected: all pass, no new issues.
  - If `FakeLocalDataReset` in `test/support/auth_fakes.dart` no longer compiles, give it the
    new constructor shape. Its own constructor keeps `this.device`; only the `implements` member
    set matters.

- [ ] **Step 8: Commit**

```bash
git add -A lib test
git commit -m "DEV-173: core declares the adapter list and the settings reset; the root provides them"
```

### Task 3: The ADR-017 conflict rule moves to srs

**Files:**
- Move: `lib/core/sync/schedule_progress.dart` → `lib/features/srs/domain/models/schedule_progress_model.dart`
- Move: `test/core/sync/schedule_progress_test.dart` → `test/features/srs/domain/models/schedule_progress_model_test.dart`
- Modify: `lib/core/sync/card_schedule_sync_adapter.dart` (temporarily: Task 4 moves it into srs anyway; until then core imports a feature, so do Task 3 and Task 4 in one commit if `boundaries_test` fails in between)

**Interfaces:**
- Produces: `compareScheduleProgress(...)` at `package:memox/features/srs/domain/models/schedule_progress_model.dart`. Its signature is unchanged.

- [ ] **Step 1: Move the files.**

```bash
mkdir -p lib/features/srs/domain/models test/features/srs/domain/models
git mv lib/core/sync/schedule_progress.dart lib/features/srs/domain/models/schedule_progress_model.dart
git mv test/core/sync/schedule_progress_test.dart test/features/srs/domain/models/schedule_progress_model_test.dart
```

  - Fix the test's import to the new path.
  - The file must stay pure Dart: no Drift, no Flutter. If it imports anything from `core/`
    other than pure value types, report it instead of proceeding.

- [ ] **Step 2:** Do not commit yet. Continue with Task 4, which moves the only caller into srs,
  and commit the two together.

### Task 4: Card and card-schedule adapters move; new-card schedules get one owner

**Files:**
- Move: `lib/core/sync/card_sync_adapter.dart` → `lib/features/card/data/datasources/card_sync_dao.dart` (class `CardSyncDao`)
- Move: `lib/core/sync/card_schedule_sync_adapter.dart` → `lib/features/srs/data/datasources/card_schedule_sync_dao.dart` (class `CardScheduleSyncDao`)
- Create: `lib/features/srs/data/mappers/card_schedule_mapper.dart` (`cardScheduleColumnsOf`, moved from `schedule_repository_impl.dart:311` `_columnsOf`)
- Modify: `lib/features/srs/data/repositories/schedule_repository_impl.dart` (use the mapper)
- Modify: `lib/core/database/queries/sync_card_queries.drift` (delete `ensureCardSchedules`)
- Modify: `lib/core/database/queries/sync_card_schedule_queries.drift` (add `cardsWithoutSchedule`)
- Modify: `test/architecture/tombstone_filter_test.dart:29` (the entry for `ensureCardSchedules` goes; add one for `cardsWithoutSchedule` only if the test demands every card query be listed)
- Modify: `lib/app/sync_tables.dart`
- Move tests:
  - `test/core/sync/card_sync_adapter_test.dart` → `test/features/card/data/card_sync_dao_test.dart`;
  - the schedule cases of `study_history_adapters_test.dart` that build
    `CardScheduleSyncAdapter` → `test/features/srs/data/card_schedule_sync_dao_test.dart`;
  - the review-log cases stay for Task 5.

**Interfaces:**
- Consumes: `compareScheduleProgress` (Task 3), `EntitySyncAdapter.afterPull` (Task 1).
- Produces:
  - `CardSyncDao(AppDatabase)`, `type == 'card'`, no `afterPull`.
  - `CardScheduleSyncDao(AppDatabase, SyncStore, {DateTime Function() now})`, with `afterPull`
    giving every card without a schedule `CardScheduleState.initial`.
  - `CardScheduleCompanion cardScheduleColumnsOf(CardScheduleState, {required SchedulerType type, required int version})`.

- [ ] **Step 1: Write the failing test.** In
  `test/features/srs/data/card_schedule_sync_dao_test.dart`, carry over the two-scheduler case
  from `card_sync_adapter_test.dart:86`, reworded:

```dart
for (final scheduler in SchedulerType.values) {
  test('afterPull writes what initializeCard writes ($scheduler)', () async {
    final db = openTestDatabase();
    addTearDown(db.close);
    // Seed a root of [scheduler] with a card under it and no schedule, the
    // way the old test did (copy its seeding helper as-is).
    await seedCardWithoutSchedule(db, scheduler: scheduler, cardId: 'K');
    // The reference row: what the srs repository writes for a new card.
    await seedCardWithoutSchedule(db, scheduler: scheduler, cardId: 'REF');
    await ScheduleRepositoryImpl(db).initializeCard(cardId: 'REF');

    await CardScheduleSyncDao(db, SyncStore(db)).afterPull();
    await CardScheduleSyncDao(db, SyncStore(db)).afterPull(); // idempotent

    final rows = {
      for (final row in await db.select(db.cardSchedule).get()) row.cardId: row,
    };
    expect(rows.keys, containsAll(['K', 'REF']));
    expect(
      rows['K']!.toJson()..remove('cardId'),
      rows['REF']!.toJson()..remove('cardId'),
    );
  });
}
```

  Delete the old equality test from the moved `card_sync_dao_test.dart`.

- [ ] **Step 2: Run it and see it fail.**
  - Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/srs/data/card_schedule_sync_dao_test.dart`
  - Expected: compile error (`CardScheduleSyncDao` is undefined).

- [ ] **Step 3: Move and rename.**

```bash
git mv lib/core/sync/card_sync_adapter.dart lib/features/card/data/datasources/card_sync_dao.dart
git mv lib/core/sync/card_schedule_sync_adapter.dart lib/features/srs/data/datasources/card_schedule_sync_dao.dart
git mv test/core/sync/card_sync_adapter_test.dart test/features/card/data/card_sync_dao_test.dart
```

  - In each moved file:
    - rename the class (`CardSyncAdapter` → `CardSyncDao`, `CardScheduleSyncAdapter` →
      `CardScheduleSyncDao`);
    - fix the `part` directive (`card_sync_dao.g.dart`, `card_schedule_sync_dao.g.dart`) and
      the `_$…Mixin` name;
    - import `compareScheduleProgress` from its srs path.
  - Remove `afterPull`/`ensureSchedules` from `CardSyncDao`, and its doc paragraph.
  - Update every reference: `grep -rln "CardSyncAdapter\|CardScheduleSyncAdapter" lib test`.

- [ ] **Step 4: The mapper.**
  - Create `lib/features/srs/data/mappers/card_schedule_mapper.dart` holding the body of
    `_columnsOf` from `schedule_repository_impl.dart:311-328`, renamed and public:

```dart
import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/srs/domain/models/card_schedule_state_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';

/// The `card_schedule` columns of [state] under [type] at [version].
CardScheduleCompanion cardScheduleColumnsOf(
  CardScheduleState state, {
  required SchedulerType type,
  required int version,
}) => CardScheduleCompanion(
  schedulerType: Value(type.code),
  schedulerVersion: Value(version),
  generation: Value(state.generation),
  learnedAt: Value(state.learnedAt),
  dueAt: Value(state.dueAt),
  lastAnsweredAt: Value(state.lastAnsweredAt),
  answerCount: Value(state.answerCount),
  lapseCount: Value(state.lapseCount),
  currentBox: Value(state.currentBox),
  easeFactor: Value(state.easeFactor),
  intervalDays: Value(state.intervalDays),
  repetitions: Value(state.repetitions),
);
```

  - In `schedule_repository_impl.dart`, delete `_columnsOf` and call `cardScheduleColumnsOf`
    at its three call sites (lines ~49, ~112, ~128).

- [ ] **Step 5: The query.**
  - In `sync_card_queries.drift`, delete the `ensureCardSchedules` statement and its comment.
  - In `sync_card_schedule_queries.drift`, add:

```sql
-- BR-CARD-004: the cards without a schedule, each with its root's scheduler
-- and generation; CardScheduleSyncDao.afterPull gives each the initial row.
-- A card in the Trash is included, as a local card keeps its row when trashed.
cardsWithoutSchedule:
SELECT c.id AS card_id, r.scheduler_type, r.scheduler_version, r.generation
FROM card c JOIN deck d ON d.id = c.deck_id JOIN deck r ON r.id = d.root_id
WHERE NOT EXISTS (SELECT 1 FROM card_schedule s WHERE s.card_id = c.id);
```

  - In `test/architecture/tombstone_filter_test.dart`, drop the `ensureCardSchedules` entry.
    Add one for `cardsWithoutSchedule` with the same justification only if the test fails
    without it.

- [ ] **Step 6: `afterPull` in `CardScheduleSyncDao`.**

```dart
  /// Gives every card without a schedule the row a new card starts with
  /// (BR-CARD-004): its root's scheduler at the root's generation, nothing
  /// learned, the same row `ScheduleRepository.initializeCard` writes. Runs
  /// at the end of a pull, under `applying_remote`; one read and one batch.
  @override
  Future<void> afterPull() async {
    final missing = await cardsWithoutSchedule().get();
    if (missing.isEmpty) return;
    await batch((batch) {
      for (final row in missing) {
        final type = SchedulerType.fromCode(row.schedulerType!);
        batch.insert(
          attachedDatabase.cardSchedule,
          cardScheduleColumnsOf(
            CardScheduleState.initial(type, generation: row.generation!),
            type: type,
            version: row.schedulerVersion!,
          ).copyWith(cardId: Value(row.cardId)),
        );
      }
    });
  }
```

  If Drift types the root columns as non-nullable in this result, drop the `!`. Match whatever
  the generated row class gives.

- [ ] **Step 7: Composition.** In `lib/app/sync_tables.dart`:
  - point the two imports at the new paths;
  - use `CardSyncDao(db)` and `CardScheduleSyncDao(db, store, now: now)`.

- [ ] **Step 8: Regenerate and run.**
  - Regenerate: `dart run build_runner build -d`.
  - Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/core/sync test/features/card test/features/srs test/architecture`
  - Expected: all pass, including the five convergence and bulk tests, the new two-scheduler
    test and `boundaries_test`.

- [ ] **Step 9: Commit (Tasks 3 and 4).**

```bash
git add -A lib test
git commit -m "DEV-173: card and schedule sync move to card and srs; srs gives pulled cards their schedule"
```

### Task 5: The remaining five adapters move

**Files:**
- Move, with the `{X}SyncAdapter` → `{X}SyncDao` class renames:
  - `lib/core/sync/delete_batch_sync_adapter.dart` → `lib/features/trash/data/datasources/delete_batch_sync_dao.dart`
  - `lib/core/sync/deck_sync_adapter.dart` → `lib/features/deck/data/datasources/deck_sync_dao.dart`
  - `lib/core/sync/tag_sync_adapter.dart` → `lib/features/tags/data/datasources/tag_sync_dao.dart`
  - `lib/core/sync/review_log_sync_adapter.dart` → `lib/features/srs/data/datasources/review_log_sync_dao.dart`
  - `lib/core/sync/account_settings_sync_adapter.dart` → `lib/features/settings/data/datasources/account_settings_sync_dao.dart`
- Move tests:
  - `test/core/sync/deck_sync_adapter_test.dart` → `test/features/deck/data/deck_sync_dao_test.dart`
  - `test/core/sync/tag_sync_adapter_test.dart` → `test/features/tags/data/tag_sync_dao_test.dart`
  - the review-log cases of `test/core/sync/study_history_adapters_test.dart` → `test/features/srs/data/review_log_sync_dao_test.dart`. Delete the old file once empty.
- Modify: `lib/app/sync_tables.dart`
- Add an assertion to `test/architecture/boundaries_test.dart`.

**Interfaces:**
- Consumes: `syncTableOverrides` (Task 2).
- Produces:
  - `DeleteBatchSyncDao(db)`, `DeckSyncDao(db)`, `TagSyncDao(db, store, now:)`,
    `ReviewLogSyncDao(db)`, `AccountSettingsSyncDao(db)`;
  - `lib/core/sync/` with no adapter left.

- [ ] **Step 1: Write the failing boundary test.** Add to
  `test/architecture/boundaries_test.dart`:

```dart
test('core/sync names no feature table (DEV-173)', () {
  const companions = [
    'DeckCompanion', 'CardCompanion', 'TagsCompanion',
    'CardScheduleCompanion', 'ReviewLogCompanion', 'AppSettingsCompanion',
    'DeleteBatchesCompanion',
  ];
  final offenders = <String>[];
  for (final file in Directory('lib/core/sync').listSync(recursive: true)) {
    if (file is! File || !file.path.endsWith('.dart')) continue;
    if (file.path.endsWith('.g.dart')) continue;
    final source = file.readAsStringSync();
    for (final name in companions) {
      if (source.contains(name)) offenders.add('${file.path}: $name');
    }
  }
  expect(offenders, isEmpty);
});
```

- [ ] **Step 2: Run it and see it fail.**
  - Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/architecture/boundaries_test.dart`
  - Expected: FAIL, listing the five adapter files.

- [ ] **Step 3: Move the five.** For each, `git mv` the source, then:
  - rename the class;
  - fix its `part` directive and `_$…Mixin` name;
  - fix every reference (`grep -rln "<OldName>" lib test`).

  `TagSyncDao` keeps `linkSyncedTagCard` (plan ruling P1). In its doc comment, add one line:

```dart
/// The pulled tag absorbs a local tag of the same folded name (BR-TAG-006);
/// the local one goes first because the folded name is unique, so its cards
/// are relinked here with `INSERT OR IGNORE` rather than `mergeTagLinks`.
```

- [ ] **Step 4: Composition.** In `lib/app/sync_tables.dart`, point the remaining imports at the
  new paths and use the new class names. Remove the "Tasks 4 and 5" comment.

- [ ] **Step 5: Regenerate and run.**
  - Regenerate: `dart run build_runner build -d`.
  - Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/core test/features test/architecture test/app`
  - Expected: all pass, and `ls lib/core/sync/*_sync_adapter.dart` finds nothing.

- [ ] **Step 6: Commit**

```bash
git add -A lib test
git commit -m "DEV-173: deck, trash, tag, review-log and settings sync move to their features"
```

### Task 6: Documents and the gate

**Files:**
- Modify: `docs/shared/decisions/ADR-011-*.md`
- Modify: `.claude/skills/flutter-architecture/SKILL.md:45,56`
- Modify: `.claude/skills/flutter-data-layer/SKILL.md:27`

- [ ] **Step 1: ADR-011.** Under "Cây thư mục" (folder tree), after the suffix bullet, add
  (Vietnamese, as the ADR is):

```markdown
- Adapter sync của một bảng là một `_sync_dao` trong `data/datasources/` của feature sở hữu
  bảng (`deck_sync_dao.dart`, …); `core/sync/` chỉ giữ hạ tầng và khai báo
  `syncAdaptersProvider`, override ở `lib/app/sync_tables.dart` (DEV-173).
```

- [ ] **Step 2: The skills.**
  - `flutter-architecture` line 45: replace "sync's are in `core/sync/`" with "a table's sync
    adapter is a `_sync_dao` in its feature's `data/datasources/`".
  - Line 56: after "`core/sync/` the sync (ADR-013, ADR-015)", add "infrastructure; each
    table's adapter lives in the feature that owns the table and is listed in
    `lib/app/sync_tables.dart` (DEV-173)".
  - `flutter-data-layer` line 27: make the same correction. `lib/core/sync/` pushes and pulls
    through the adapters the app lists in `lib/app/sync_tables.dart`, each in the feature that
    owns its table.

- [ ] **Step 3: The gate.**
  - Run: `bash .claude/skills/flutter-workflow/scripts/dod_check.sh`
  - Expected: PASS. If only format fails, run `dart format .` and re-check with
    `dart format --output=none --set-exit-if-changed .`.
  - Then run `bash .claude/skills/flutter-workflow/scripts/run_goldens.sh`. Expected: 489 pass
    and no golden changes.

- [ ] **Step 4: Commit and push**

```bash
git add -A docs .claude/skills
git commit -m "DEV-173: ADR-011 and the skills say where a table's sync adapter lives"
git push origin claude/nifty-maxwell-nz5nl3
```

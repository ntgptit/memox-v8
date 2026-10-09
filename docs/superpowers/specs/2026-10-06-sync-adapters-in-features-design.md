# Sync adapters live with the tables they sync — design

Status: owner rulings 2026-10-06 (chat), spec awaiting review ·
Path: architectural (a core contract, two root-overridden providers, seven files moving across
five features, `ADR-011`) ·
Linear: DEV-173 (ARCH-001), epic DEV-172 · branch `claude/nifty-maxwell-nz5nl3`.

## 1. Intent

**The problem.** `core/` may not import a feature (ADR-011). Yet `lib/core/sync/` holds the seven
concrete sync adapters, and each one needs its table's rules. Unable to call the feature, each
adapter re-implements the rule it needs, so the same rule exists in two places with two owners:

- `CardSyncAdapter.ensureSchedules` and the `ensureCardSchedules` query rewrite
  `CardScheduleState.initial` in SQL. A test holds the two copies equal.
- `CardScheduleSyncAdapter` carries the ADR-017 conflict rule (`compareScheduleProgress`) in
  `core/sync/schedule_progress.dart`.
- `TagSyncAdapter` re-implements merging two tags that fold to one name (BR-TAG-006).
- `LocalDataReset` hardcodes the default settings (`20`, `'created'`, `'system'`, `'system'`) a
  third time, after `settings.drift` and `AppSettingsEntity.defaults`.

643 of `core/sync`'s 1,641 lines are table knowledge.

**Success means:**

- `lib/core/sync/` names no column of a feature table. A grep for `DeckCompanion`,
  `CardCompanion`, `TagsCompanion`, `CardScheduleCompanion`, `ReviewLogCompanion` and
  `AppSettingsCompanion` under it finds nothing.
- `CardScheduleState.initial`, the ADR-017 rule and the tag merge are each implemented once.
  The settings defaults live only in `AppSettingsEntity.defaults` and `settings.drift`.
- The convergence tests pass unchanged in scenario: `card_sync_convergence_test`,
  `tag_sync_convergence_test`, `study_history_convergence_test`, `account_settings_sync_test`
  and `sync_bulk_test`.
- `boundaries_test.dart` and the gate pass.

## 2. Owner rulings (2026-10-06)

- **S1 · Where an adapter lives.**
  - Path: `features/<owner>/data/datasources/<name>_sync_dao.dart`.
  - Class: `<Name>SyncDao implements EntitySyncAdapter`.
  - It is a Drift accessor like the feature's other DAOs, so it uses the existing bucket and
    `_dao` suffix. No new bucket.
- **S2 · After a pull.** `EntitySyncAdapter` gains `afterPull()`, which does nothing by default.
  - The coordinator calls it on every adapter, in list order, at the end of a pull.
  - The srs schedule adapter implements it with srs's own rule.
  - This replaces the coordinator's `afterPull` argument.
- **S3 · Reset defaults.** Core declares a provider that resets the synced settings to their
  defaults. It must be overridden.
  - The settings feature implements it with `AppSettingsEntity.defaults` through its own DAO.
  - `LocalDataReset` calls it inside its transaction.
  - This is the same pattern as the adapter list.

## 3. Design

### 3.1 What stays in `core/sync`

The infrastructure stays:

- `EntitySyncAdapter`, `SyncCoordinator`, `SyncStore`, `SyncScheduler`, `SyncControl`,
  `SyncCommands`;
- `SyncApi` and `SupabaseSyncApi`, `sync_models`, `sync_failure`, `sync_status`.

The only changes in this group:

- `EntitySyncAdapter` gains `Future<void> afterPull() async {}`.
- `SyncCoordinator` loses its `afterPull` constructor argument. After applying a pull's pages,
  it awaits `afterPull()` on each adapter in order, still under `applying_remote`, exactly where
  the single callback ran.

### 3.2 Providers: core declares, the root provides

`lib/core/sync/di/sync_providers.dart`:

```dart
/// The synced tables, parent before child: the order is the push and the
/// apply order (decks before cards, cards before schedules). Overridden at
/// the composition root, which may import features (ADR-011).
@Riverpod(keepAlive: true)
List<EntitySyncAdapter> syncAdapters(Ref ref) =>
    throw UnimplementedError('override syncAdaptersProvider at the root');
```

`syncCoordinatorProvider` reads `syncAdaptersProvider` instead of building seven adapters.
`lib/core/auth/di/auth_providers.dart`, where `LocalDataReset` is built, declares:

```dart
/// Returns the synced settings to their defaults; device-only columns
/// (reminder, welcome) stay. Runs inside LocalDataReset's transaction.
@Riverpod(keepAlive: true)
Future<void> Function() syncedSettingsReset(Ref ref) =>
    throw UnimplementedError('override syncedSettingsResetProvider at the root');
```

`LocalDataReset` takes that function in its constructor. Its raw `UPDATE app_settings …` goes.

### 3.3 The composition root

A new file, `lib/app/sync_tables.dart`, holds the two root providers. It builds:

- the adapter list, in today's order: delete batches, decks, tags, cards, card schedules,
  review logs, account settings;
- the settings reset, from the feature DAOs.

`lib/app/` may import features, and the file sits flat in `app/` because ADR-011 rules out
`app/di/`. It exposes one list for `main.dart`:

```dart
final syncTableOverrides = [
  syncAdaptersProvider.overrideWith(appSyncAdapters),
  syncedSettingsResetProvider.overrideWith(appSyncedSettingsReset),
];
```

`main.dart` spreads it into `ProviderContainer(overrides: …)`. When DEV-176 (`startApp`) lands,
the list moves there unchanged. Tests and harnesses that reach the sync providers use the same
list, so they wire exactly what the app wires. Tests that build a `SyncCoordinator` by hand
build the adapters from their new homes.

### 3.4 The seven moves

| From `lib/core/sync/` | To | Class |
|---|---|---|
| `delete_batch_sync_adapter.dart` | `trash/data/datasources/delete_batch_sync_dao.dart` | `DeleteBatchSyncDao` |
| `deck_sync_adapter.dart` | `deck/data/datasources/deck_sync_dao.dart` | `DeckSyncDao` |
| `tag_sync_adapter.dart` | `tags/data/datasources/tag_sync_dao.dart` | `TagSyncDao` |
| `card_sync_adapter.dart` | `card/data/datasources/card_sync_dao.dart` | `CardSyncDao` |
| `card_schedule_sync_adapter.dart` | `srs/data/datasources/card_schedule_sync_dao.dart` | `CardScheduleSyncDao` |
| `review_log_sync_adapter.dart` | `srs/data/datasources/review_log_sync_dao.dart` | `ReviewLogSyncDao` |
| `account_settings_sync_adapter.dart` | `settings/data/datasources/account_settings_sync_dao.dart` | `AccountSettingsSyncDao` |

- **Query files stay put.** The `sync_*_queries.drift` files stay in
  `core/database/queries/`, as every feature DAO's queries do; only the Dart accessor moves.
- **The wire stays the same.** Each entity type string, wire shape and query is unchanged.

### 3.5 One implementation per rule

- **New-card schedules (S2).**
  - `CardScheduleSyncDao.afterPull()` reads the cards without a schedule, each with its root's
    scheduler and generation.
  - It writes `CardScheduleState.initial(type, generation:)` for each, through the srs mapper, in
    one batch.
  - The `ensureCardSchedules` SQL goes, and so do `CardSyncAdapter.ensureSchedules` and the test
    that held the two copies equal.
  - The read is one query, and the writes are one Drift batch, so a large pull stays one round
    trip each way.
- **ADR-017 conflict rule.** `core/sync/schedule_progress.dart` moves to
  `srs/domain/models/schedule_progress_model.dart`. It is pure Dart, and srs owns the rule. Its
  test moves with it.
- **Tag merge.**
  - `TagSyncDao.upsertFromServer` keeps the sync-only steps: free the name first, enqueue the
    moved cards and the losing tag.
  - Moving the links goes through the tags feature's own merge query (`mergeTagLinks`, what
    `TagDao.merge` uses), not a per-card relink of its own.
- **Settings defaults (S3).**
  - The settings feature's reset writes `AppSettingsEntity.defaults`' synced fields (card
    limit, new-card order, theme, language) through its DAO.
  - It leaves the reminder and welcome columns as they are, as the raw `UPDATE` did.

## 4. Documents

- **ADR-011:** one line in D1 or the folder tree: a table's sync adapter is a `_sync_dao` in
  the owning feature's `data/datasources/`, and the adapter list is composed in `lib/app/`.
- **Skills:** `flutter-architecture` and `flutter-data-layer` say "sync's are in
  `core/sync/`". Each becomes: "the infrastructure is in `core/sync/`; each table's adapter is in
  its feature".
- **Specs left alone:** the specs that describe today's layout are history.
- **Linear:** DEV-173 gets the PR, and is Done on merge.

## 5. Testing

- **Unit:** `SyncCoordinator` calls `afterPull()` on each adapter after applying a pull, in
  order, and not after a failed pull.
- **Moves:**
  - Each adapter's test moves to `test/features/<f>/data/` and keeps its cases.
  - `card_sync_adapter_test.dart:86`, the test that held the two schedule copies equal, becomes
    a test that `afterPull` writes what `initializeCard` writes for both schedulers.
- **Providers:**
  - `sync_providers_test.dart`: reading `syncCoordinatorProvider` without the override throws.
  - With `syncTableOverrides` the coordinator holds the seven adapters in order.
- **Reset:** the `LocalDataReset` test asserts the synced settings return to
  `AppSettingsEntity.defaults` and that reminder and welcome survive.
- **Convergence:** the five convergence and bulk tests run unchanged in scenario. Only their
  imports and wiring change.
- **Architecture:** `boundaries_test.dart` passes with the adapters in features. The grep in §1
  becomes an assertion in `boundaries_test.dart`, so the knowledge cannot drift back.
- **Gate:** `dod_check.sh`. No golden changes, since no UI changes.

## 6. Out of scope

- DEV-176's `startApp`: this work overrides in `main.dart`; DEV-176 moves the list later.
- DEV-123, the command-based sync for decks and cards.
- Any change to the wire format, the RPCs or the Supabase schema.
- Moving the `.drift` query files out of `core/database/queries/`.

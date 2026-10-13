# SB-U1 Sync Status Implementation Plan

> **Historical (ADR-019).** Written against the "Mobile UI Kit v3", retired on 2026-09-30; its kit references and screen captures are history, not authority. The app, `DESIGN.md` and the goldens decide the UI; each screen's current state is in its detail file under `docs/shared/ui/screen-handoff/`.

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Record every sync run and every refused row in Drift, and show them on
Settings (a row), a new Sync screen (27) and a Study home banner.

**Architecture:** `lib/core/sync/` records outcomes (`sync_state` keys, a new
`sync_rejection` table, schema 6) and exposes a `SyncStatus` stream plus three
commands; the settings feature draws screen 23's row and screen 27; the study feature
draws screen 13's banner. Everything is hidden when the build has no Supabase.

**Tech Stack:** Flutter, Riverpod 3 codegen, Drift (`.drift` files, `stepByStep`
migrations), `supabase_flutter` 2.17.2, `http` 1.6.0, `intl`, `fake_async`, golden
tests on Linux.

**Spec:** `docs/superpowers/specs/2026-09-28-sync-status-design.md`

## Global Constraints

- Every user-facing string lives in `lib/l10n/app_en.arb` (with an `@key`
  description) and `lib/l10n/app_vi.arb`; run `flutter gen-l10n` after editing them.
- No error code, id, SQL or exception message reaches the UI (BR-CORE-005).
- Times are stored in UTC; `sync_state` times are UTC epoch **milliseconds** as text.
- Shown times are absolute (R6): "Today, 14:32", "Yesterday, 09:10", "26 Sep, 14:32".
- The banner rule is `rejectedCount > 0 || oldest pending change older than 24 h`.
- Only `MxSection`, `MxSettingsRow`, `MxInlineBanner` (`warning`), `MxButton`,
  `MxSnackbar`, `MxSkeletonList`, `MxErrorState`, `MxAppBar`, `MxAppShell`,
  `MxScreenScroll`, `MxIconButton`; one new icon `AppIcons.sync`; no new shared widget.
- A released migration never changes; schema goes 5 → 6 only.
- `syncStatusProvider` emits `null` when `SupabaseConfig.isEnabled` is false; every
  surface hides then.
- Goldens are written on Linux: `flutter test --update-goldens --tags golden <file>`.
- Before each commit: `dart format` on touched files and `flutter analyze` clean.

## Review Focus

1. A failure recorded after a success in the same second must still show (so times are
   milliseconds), and a success after a failure hides it — Task 3 test "a later success
   hides the failure; a later failure shows".
2. Sync now tapped while a background run is in flight returns the result of the run
   that starts after it, not the one already running — Task 5 test "syncNow during a run
   waits for the next run".
3. A refused entity deleted locally before Try again is re-queued as a delete, not an
   upsert of a missing row — Task 4 test "requeue turns a vanished entity into a
   delete".
4. The day boundary is the local calendar day, not 24 h: a sync at 23:50 read at 00:30
   is "Yesterday" — Task 7 formatter test.
5. Vietnamese copy at text scale 2 wraps without overflow on screen 27 and in the Study
   home banner — Task 8 and Task 10 text-scale tests.

---

### Task 1: `sync_rejection` table and schema 6

**Files:**
- Modify: `lib/core/database/tables/sync.drift` (append the table)
- Modify: `lib/core/database/app_database.dart` (`schemaVersion` 6, `from5To6`)
- Create (generated): `drift_schemas/drift_schema_v6.json`,
  `lib/core/database/schema_versions.dart` (regenerated),
  `test/drift/generated/schema_v6.dart` and `test/drift/generated/schema.dart`
  (regenerated)
- Modify: `test/drift/migration_test.dart`

**Interfaces:**
- Produces: Drift table `syncRejection` (`SyncRejectionEntry`, companion
  `SyncRejectionCompanion`) with `entityType`, `entityId`, `code`, `rejectedAt`.

- [ ] **Step 1: Snapshot check**

Run: `ls drift_schemas/` — expect `drift_schema_v1.json` … `drift_schema_v5.json`.

- [ ] **Step 2: Add the table** at the end of `lib/core/database/tables/sync.drift`:

```sql
-- SB-U1: a pushed row the server refused and never saw (no `current`); the
-- row stays local and is listed until it is pushed, re-queued or kept
-- (sync status spec §4). A later refusal of the same entity replaces it.
CREATE TABLE sync_rejection (
  entity_type TEXT NOT NULL,
  entity_id TEXT NOT NULL,
  code TEXT NOT NULL,
  rejected_at DATETIME NOT NULL,
  PRIMARY KEY (entity_type, entity_id)
) AS SyncRejectionEntry;
```

- [ ] **Step 3: Bump the version** in `app_database.dart`: `int get schemaVersion => 6;`

- [ ] **Step 4: Regenerate**

```bash
dart run build_runner build --delete-conflicting-outputs
dart run drift_dev schema dump lib/core/database/app_database.dart drift_schemas/
dart run drift_dev schema steps drift_schemas/ lib/core/database/schema_versions.dart
dart run drift_dev schema generate drift_schemas/ test/drift/generated/
```

Expected: `drift_schemas/drift_schema_v6.json` exists; `schema_versions.dart` has
`Schema6` and `stepByStep` now requires `from5To6`.

- [ ] **Step 5: Change the migration test first** — in `test/drift/migration_test.dart`
replace every `migrateAndValidate(db, 5)` with `migrateAndValidate(db, 6)`, rename the
tests `'vN upgrades to the schema of v5'` → `'… of v6'` and `'a new database has the
schema of v5, …'` → `v6`, and add after the v4 test:

```dart
  test('v5 upgrades to the schema of v6', () async {
    final db = AppDatabase(await verifier.startAt(5));
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 6);
  });
```

Also update the header comment: `v6 records refused sync rows (SB-U1).` Check
`test/drift/nfc_migration_test.dart` for a hard-coded `5` target and move it to 6 the
same way.

- [ ] **Step 6: Run it to see it fail**

Run: `flutter test test/drift/migration_test.dart`
Expected: FAIL — `from5To6` missing (compile error in `app_database.dart`).

- [ ] **Step 7: Write the step** in `stepByStep(...)` after `from4To5`:

```dart
      from5To6: (m, schema) async {
        // SB-U1: refused sync rows are recorded (sync status spec §4). A new,
        // empty table; no row changes.
        await m.createTable(schema.syncRejection);
      },
```

- [ ] **Step 8: Run the drift tests**

Run: `flutter test test/drift/`
Expected: PASS.

- [ ] **Step 9: Commit**

```bash
git add lib/core/database/tables/sync.drift lib/core/database/app_database.dart \
  lib/core/database/schema_versions.dart drift_schemas/drift_schema_v6.json \
  test/drift/
git commit -m "feat(sync): sync_rejection table, schema 6 (SB-U1)"
```

---

### Task 2: classify a failed run

**Files:**
- Modify: `pubspec.yaml` (dependencies: `http: ^1.6.0`, alphabetical)
- Create: `lib/core/sync/sync_failure.dart`
- Test: `test/core/sync/sync_failure_test.dart`

**Interfaces:**
- Produces: `enum SyncFailureKind { network, signIn, server, unknown }` with
  `static SyncFailureKind? parse(String? name)`;
  `SyncFailureKind classifySyncFailure(Object error)`.

- [ ] **Step 1: Declare `http`** — add `  http: ^1.6.0` under `dependencies:` in
alphabetical order, then run `flutter pub get`. Expected: `pubspec.lock` keeps
`http 1.6.0` and only changes `dependency: transitive` → `direct main`.

- [ ] **Step 2: Write the failing test** `test/core/sync/sync_failure_test.dart`:

```dart
import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:memox/core/sync/sync_failure.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('no connection is network', () {
    expect(
      classifySyncFailure(const SocketException('down')),
      SyncFailureKind.network,
    );
    expect(
      classifySyncFailure(TimeoutException('slow')),
      SyncFailureKind.network,
    );
    expect(
      classifySyncFailure(http.ClientException('reset')),
      SyncFailureKind.network,
    );
    expect(
      classifySyncFailure(AuthRetryableFetchException(message: 'down')),
      SyncFailureKind.network,
    );
  });

  test('a refused anonymous sign-in is signIn', () {
    expect(
      classifySyncFailure(const AuthException('anonymous sign-ins disabled')),
      SyncFailureKind.signIn,
    );
  });

  test('a refused or unreadable RPC is server', () {
    expect(
      classifySyncFailure(const PostgrestException(message: 'denied')),
      SyncFailureKind.server,
    );
    expect(
      classifySyncFailure(const FormatException('bad json')),
      SyncFailureKind.server,
    );
    expect(classifySyncFailure(TypeError()), SyncFailureKind.server);
  });

  test('anything else is unknown', () {
    expect(classifySyncFailure(StateError('x')), SyncFailureKind.unknown);
  });

  test('a kind round-trips through its name', () {
    for (final kind in SyncFailureKind.values) {
      expect(SyncFailureKind.parse(kind.name), kind);
    }
    expect(SyncFailureKind.parse(null), isNull);
    expect(SyncFailureKind.parse('gone'), isNull);
  });
}
```

- [ ] **Step 3: Run it to see it fail**

Run: `flutter test test/core/sync/sync_failure_test.dart`
Expected: FAIL — `sync_failure.dart` not found.

- [ ] **Step 4: Implement** `lib/core/sync/sync_failure.dart`:

```dart
import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Why a sync run failed, as screen 27 says it (sync status spec §4, §5.4).
/// Stored by name in `sync_state`.
enum SyncFailureKind {
  network,
  signIn,
  server,
  unknown;

  static SyncFailureKind? parse(String? name) {
    for (final kind in values) {
      if (kind.name == name) return kind;
    }
    return null;
  }
}

/// The kind of [error] a run threw. The transport's errors are checked
/// before the sign-in's, since a retryable fetch is also an AuthException.
SyncFailureKind classifySyncFailure(Object error) => switch (error) {
  SocketException() ||
  TimeoutException() ||
  http.ClientException() ||
  AuthRetryableFetchException() => SyncFailureKind.network,
  AuthException() => SyncFailureKind.signIn,
  PostgrestException() || FormatException() || TypeError() =>
    SyncFailureKind.server,
  _ => SyncFailureKind.unknown,
};
```

- [ ] **Step 5: Run it to see it pass**

Run: `flutter test test/core/sync/sync_failure_test.dart` — Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/core/sync/sync_failure.dart test/core/sync/sync_failure_test.dart
git commit -m "feat(sync): classify a failed run (SB-U1)"
```

---

### Task 3: record outcomes and read the status

**Files:**
- Modify: `lib/core/database/tables/sync_keys.dart`
- Create: `lib/core/sync/sync_status.dart`
- Modify: `lib/core/sync/sync_store.dart`
- Test: `test/core/sync/sync_status_test.dart`, `test/core/sync/sync_store_test.dart`

**Interfaces:**
- Consumes: `SyncFailureKind` (Task 2), table `syncRejection` (Task 1).
- Produces:
  - `final class LastSyncFailure { const LastSyncFailure(this.kind, this.at); final SyncFailureKind kind; final DateTime at; }`
  - `final class SyncStatus { lastSuccessAt, lastFailure, pendingCount, oldestPendingAt, rejectedCount }`
  - `const Duration syncAttentionAge = Duration(hours: 24);`
  - `bool needsAttention(SyncStatus status, DateTime now)`
  - `SyncStore`: `recordSuccess(DateTime now)`, `recordFailure(SyncFailureKind kind, DateTime now)`,
    `recordRejection(String entityType, String entityId, String code, DateTime now)`,
    `clearRejection(String entityType, String entityId)`,
    `Future<List<SyncRejectionEntry>> rejections()`, `forgetRejected()`,
    `enqueue(String entityType, String entityId, String op, DateTime now)`,
    `Future<T> inTransaction<T>(Future<T> Function() body)`,
    `Stream<SyncStatus> watchStatus()`.

- [ ] **Step 1: Keys** — append to `sync_keys.dart`:

```dart
/// When the last run ended without an error: UTC epoch milliseconds (SB-U1).
const syncLastSuccessAtKey = 'last_success_at';

/// When the last run failed: UTC epoch milliseconds (SB-U1).
const syncLastFailureAtKey = 'last_failure_at';

/// The `SyncFailureKind` name of the last failed run (SB-U1).
const syncLastFailureKindKey = 'last_failure_kind';
```

- [ ] **Step 2: Failing test for the rule** `test/core/sync/sync_status_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/sync/sync_status.dart';

void main() {
  final now = DateTime.utc(2026, 9, 28, 12);

  test('nothing pending and nothing refused needs no attention', () {
    expect(needsAttention(const SyncStatus(), now), isFalse);
  });

  test('a change waiting just under a day needs no attention', () {
    final status = SyncStatus(
      pendingCount: 1,
      oldestPendingAt: now.subtract(const Duration(hours: 23, minutes: 59)),
    );
    expect(needsAttention(status, now), isFalse);
  });

  test('a change waiting over a day needs attention', () {
    final status = SyncStatus(
      pendingCount: 1,
      oldestPendingAt: now.subtract(const Duration(hours: 24, minutes: 1)),
    );
    expect(needsAttention(status, now), isTrue);
  });

  test('a refused row needs attention at once', () {
    expect(needsAttention(const SyncStatus(rejectedCount: 1), now), isTrue);
  });
}
```

- [ ] **Step 3: Run it** — `flutter test test/core/sync/sync_status_test.dart`
Expected: FAIL — file not found.

- [ ] **Step 4: Implement** `lib/core/sync/sync_status.dart`:

```dart
import 'package:flutter/foundation.dart';
import 'package:memox/core/sync/sync_failure.dart';

/// How long a change may wait for the server before Study home says so
/// (sync status spec R2).
const Duration syncAttentionAge = Duration(hours: 24);

/// The last failed run, shown only while no success came after it.
@immutable
final class LastSyncFailure {
  const LastSyncFailure(this.kind, this.at);

  final SyncFailureKind kind;
  final DateTime at;
}

/// What sync has done, read from Drift (sync status spec §4). Times are UTC.
@immutable
final class SyncStatus {
  const SyncStatus({
    this.lastSuccessAt,
    this.lastFailure,
    this.pendingCount = 0,
    this.oldestPendingAt,
    this.rejectedCount = 0,
  });

  final DateTime? lastSuccessAt;
  final LastSyncFailure? lastFailure;

  /// Outbox entries not yet acknowledged.
  final int pendingCount;

  /// When the longest-waiting of them first went unsent.
  final DateTime? oldestPendingAt;

  /// Rows the server refused and never saw (`sync_rejection`).
  final int rejectedCount;
}

/// Study home shows its banner (R2): a refused row, or a change that has
/// waited longer than [syncAttentionAge].
bool needsAttention(SyncStatus status, DateTime now) {
  if (status.rejectedCount > 0) return true;
  final oldest = status.oldestPendingAt;
  if (oldest == null) return false;
  return now.difference(oldest) > syncAttentionAge;
}
```

- [ ] **Step 5: Run** — `flutter test test/core/sync/sync_status_test.dart` — PASS.

- [ ] **Step 6: Failing store tests** — append to `test/core/sync/sync_store_test.dart`
inside `main()` (add imports `package:memox/core/sync/sync_failure.dart` and
`package:memox/core/sync/sync_status.dart`):

```dart
  final t0 = DateTime.utc(2026, 9, 28, 10);

  test('a later success hides the failure; a later failure shows', () async {
    await store.recordFailure(SyncFailureKind.network, t0);
    var status = await store.watchStatus().first;
    expect(status.lastFailure?.kind, SyncFailureKind.network);

    await store.recordSuccess(t0.add(const Duration(milliseconds: 1)));
    status = await store.watchStatus().first;
    expect(status.lastFailure, isNull);
    expect(status.lastSuccessAt, t0.add(const Duration(milliseconds: 1)));

    await store.recordFailure(
      SyncFailureKind.server,
      t0.add(const Duration(milliseconds: 2)),
    );
    status = await store.watchStatus().first;
    expect(status.lastFailure?.kind, SyncFailureKind.server);
  });

  test('pending changes and their oldest time are counted', () async {
    await _root(db, 'R');
    await _root(db, 'S');
    final status = await store.watchStatus().first;
    expect(status.pendingCount, 2);
    expect(status.oldestPendingAt, isNotNull);
  });

  test('a rejection is recorded, replaced, cleared and forgotten', () async {
    await store.recordRejection('deck', 'R', 'VALIDATION_FAILED', t0);
    await store.recordRejection('deck', 'R', 'DECK_PARENT_MISSING', t0);
    await store.recordRejection('deck', 'S', 'VALIDATION_FAILED', t0);
    expect(
      (await store.rejections()).map((r) => '${r.entityId}:${r.code}'),
      ['R:DECK_PARENT_MISSING', 'S:VALIDATION_FAILED'],
    );
    expect((await store.watchStatus().first).rejectedCount, 2);

    await store.clearRejection('deck', 'R');
    expect(await store.rejections(), hasLength(1));

    await store.forgetRejected();
    expect(await store.rejections(), isEmpty);
  });

  test('enqueue adds an entry, or replaces the op id and keeps the time', () async {
    await _root(db, 'R');
    final before = (await store.pendingBatch({'deck'}, 10)).single;

    await store.enqueue('deck', 'R', 'delete', t0);
    await store.enqueue('deck', 'X', 'upsert', t0);

    final after = await store.pendingBatch({'deck'}, 10);
    final r = after.firstWhere((e) => e.entityId == 'R');
    expect(r.op, 'delete');
    expect(r.opId, isNot(before.opId));
    expect(r.createdAt, before.createdAt);
    expect(after.map((e) => e.entityId), containsAll(['R', 'X']));
  });

  test('the status stream emits on each change', () async {
    final seen = <int>[];
    final sub = store.watchStatus().listen((s) => seen.add(s.rejectedCount));
    await pumpEventQueue();
    await store.recordRejection('deck', 'R', 'VALIDATION_FAILED', t0);
    await pumpEventQueue();
    await sub.cancel();
    expect(seen, [0, 1]);
  });
```

- [ ] **Step 7: Run** — `flutter test test/core/sync/sync_store_test.dart`
Expected: FAIL — methods not defined.

- [ ] **Step 8: Implement** — in `sync_store.dart` add imports
`package:memox/core/sync/sync_failure.dart` and
`package:memox/core/sync/sync_status.dart`, then add these members to `SyncStore`:

```dart
  Future<T> inTransaction<T>(Future<T> Function() body) =>
      _db.transaction(body);

  Future<void> recordSuccess(DateTime now) =>
      _put(syncLastSuccessAtKey, _millis(now));

  Future<void> recordFailure(SyncFailureKind kind, DateTime now) =>
      _db.transaction(() async {
        await _put(syncLastFailureAtKey, _millis(now));
        await _put(syncLastFailureKindKey, kind.name);
      });

  /// A refusal without a server copy (spec §4); replaces an earlier one.
  Future<void> recordRejection(
    String entityType,
    String entityId,
    String code,
    DateTime now,
  ) => _db
      .into(_db.syncRejection)
      .insertOnConflictUpdate(
        SyncRejectionCompanion.insert(
          entityType: entityType,
          entityId: entityId,
          code: code,
          rejectedAt: now.toUtc(),
        ),
      );

  Future<void> clearRejection(String entityType, String entityId) =>
      (_db.delete(_db.syncRejection)..where(
            (r) =>
                r.entityType.equals(entityType) & r.entityId.equals(entityId),
          ))
          .go();

  Future<List<SyncRejectionEntry>> rejections() =>
      (_db.select(_db.syncRejection)..orderBy([
            (r) => OrderingTerm(expression: r.entityType),
            (r) => OrderingTerm(expression: r.entityId),
          ]))
          .get();

  /// Keep on this device (R7): the records go, the rows stay local.
  Future<void> forgetRejected() => _db.delete(_db.syncRejection).go();

  /// Queues [entityId] as the capture triggers would: a new op id, and the
  /// first unsent time kept when it was already pending.
  Future<void> enqueue(
    String entityType,
    String entityId,
    String op,
    DateTime now,
  ) => _db.customStatement(
    'INSERT INTO sync_outbox (op_id, entity_type, entity_id, op, created_at) '
    'VALUES (?, ?, ?, ?, ?) '
    'ON CONFLICT (entity_type, entity_id) DO UPDATE SET '
    'op_id = excluded.op_id, op = excluded.op',
    [
      _uuid.v4(),
      entityType,
      entityId,
      op,
      now.toUtc().millisecondsSinceEpoch ~/ Duration.millisecondsPerSecond,
    ],
  );

  /// One row read from the three tables, re-read whenever any changes.
  Stream<SyncStatus> watchStatus() => _db
      .customSelect(
        'SELECT '
        "(SELECT value FROM sync_state WHERE name = '$syncLastSuccessAtKey') "
        'AS last_success_at, '
        "(SELECT value FROM sync_state WHERE name = '$syncLastFailureAtKey') "
        'AS last_failure_at, '
        "(SELECT value FROM sync_state WHERE name = '$syncLastFailureKindKey') "
        'AS last_failure_kind, '
        '(SELECT COUNT(*) FROM sync_outbox) AS pending_count, '
        '(SELECT MIN(created_at) FROM sync_outbox) AS oldest_pending_at, '
        '(SELECT COUNT(*) FROM sync_rejection) AS rejected_count',
        readsFrom: {_db.syncState, _db.syncOutbox, _db.syncRejection},
      )
      .watchSingle()
      .map(_statusOf);

  static SyncStatus _statusOf(QueryRow row) {
    final success = _fromMillis(row.readNullable<String>('last_success_at'));
    final failureAt = _fromMillis(row.readNullable<String>('last_failure_at'));
    final kind = SyncFailureKind.parse(
      row.readNullable<String>('last_failure_kind'),
    );
    // Inline, so failureAt and kind are promoted to non-null.
    final lastFailure =
        failureAt != null &&
            kind != null &&
            (success == null || failureAt.isAfter(success))
        ? LastSyncFailure(kind, failureAt)
        : null;
    final oldest = row.readNullable<int>('oldest_pending_at');
    return SyncStatus(
      lastSuccessAt: success,
      lastFailure: lastFailure,
      pendingCount: row.read<int>('pending_count'),
      oldestPendingAt: oldest == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
              oldest * Duration.millisecondsPerSecond,
              isUtc: true,
            ),
      rejectedCount: row.read<int>('rejected_count'),
    );
  }

  static String _millis(DateTime at) =>
      '${at.toUtc().millisecondsSinceEpoch}';

  static DateTime? _fromMillis(String? value) {
    final millis = value == null ? null : int.tryParse(value);
    return millis == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
  }
```

Also add `import 'package:memox/core/database/tables/sync_keys.dart';` if not present
(it is) and keep `Uuid` usage (`_uuid` exists).

- [ ] **Step 9: Run** — `flutter test test/core/sync/` — Expected: PASS.

- [ ] **Step 10: Commit**

```bash
git add lib/core/database/tables/sync_keys.dart lib/core/sync/sync_status.dart \
  lib/core/sync/sync_store.dart test/core/sync/sync_status_test.dart test/core/sync/sync_store_test.dart
git commit -m "feat(sync): record runs and refusals, read them as one status (SB-U1)"
```

---

### Task 4: the coordinator records, clears and re-queues refusals

**Files:**
- Modify: `lib/core/sync/sync_coordinator.dart`
- Test: `test/core/sync/sync_coordinator_test.dart`

**Interfaces:**
- Consumes: `SyncStore.recordRejection/clearRejection/rejections/enqueue/inTransaction` (Task 3).
- Produces: `SyncCoordinator({..., DateTime Function() now = DateTime.now})`;
  `Future<void> requeueRejected()`.

- [ ] **Step 1: Failing tests** — append to `sync_coordinator_test.dart` `main()`:

```dart
  test('a refusal without a server copy is recorded; a later apply clears it', () async {
    await _root(a.db, 'R', name: 'offline only');
    server.rejectNext['deck/R'] = 'VALIDATION_FAILED';

    await a.coordinator.runOnce();
    final store = SyncStore(a.db);
    expect(
      (await store.rejections()).map((r) => '${r.entityId}:${r.code}'),
      ['R:VALIDATION_FAILED'],
    );

    await a.coordinator.requeueRejected();
    await a.coordinator.runOnce();
    expect(await store.rejections(), isEmpty);
  });

  test('a refusal with a server copy is not recorded', () async {
    await _root(a.db, 'R');
    await a.coordinator.runOnce();
    await a.db.customStatement("UPDATE deck SET name = 'x' WHERE id = 'R'");
    server.rejectNext['deck/R'] = 'SYNC_ENTITY_CONFLICT';

    await a.coordinator.runOnce();

    expect(await SyncStore(a.db).rejections(), isEmpty);
  });

  test('requeue turns a vanished entity into a delete', () async {
    await _root(a.db, 'R');
    server.rejectNext['deck/R'] = 'VALIDATION_FAILED';
    await a.coordinator.runOnce();
    await SyncStore(a.db).applyingRemote(
      () => a.db.customStatement("DELETE FROM deck WHERE id = 'R'"),
    );

    await a.coordinator.requeueRejected();

    final queued = await SyncStore(a.db).pendingBatch({'deck'}, 10);
    expect(queued.single.op, 'delete');
  });
```

- [ ] **Step 2: Run** — `flutter test test/core/sync/sync_coordinator_test.dart`
Expected: FAIL — `requeueRejected` not defined.

- [ ] **Step 3: Implement** in `sync_coordinator.dart`:

Constructor and field:

```dart
  SyncCoordinator({
    required this._api,
    required this._store,
    required List<EntitySyncAdapter> adapters,
    DateTime Function() now = DateTime.now,
  }) : _adapters = {for (final a in adapters) a.entityType: a},
       _now = now;

  final DateTime Function() _now;
```

In `_push`, replace the `if (result.isApplied) { … } else if (result.current == null) { … }` branches with:

```dart
          if (result.isApplied) {
            await adapter.markAcknowledged(
              entry.entityId,
              result.serverVersion!,
            );
            await _store.clearRejection(entry.entityType, entry.entityId);
          } else if (result.current == null) {
            // The server never saw this row: keep it (and its cards) rather
            // than delete data that exists nowhere else, and list it on
            // screen 27 (sync status spec §4).
            log(
              'Sync rejected ${entry.entityType}/${entry.entityId}: ${result.code}',
            );
            await _store.recordRejection(
              entry.entityType,
              entry.entityId,
              result.code ?? 'UNKNOWN',
              _now(),
            );
          } else {
```

Add the method after `runOnce`:

```dart
  /// Try again (sync status spec §4): each refused entity goes back to the
  /// outbox, as an upsert while it exists locally and as a delete once it
  /// is gone. The records stay until the next push answers.
  Future<void> requeueRejected() => _store.inTransaction(() async {
    for (final rejection in await _store.rejections()) {
      final adapter = _adapters[rejection.entityType];
      if (adapter == null) continue;
      final exists = await adapter.readRow(rejection.entityId) != null;
      await _store.enqueue(
        rejection.entityType,
        rejection.entityId,
        exists ? _upsert : _delete,
        _now(),
      );
    }
  });
```

- [ ] **Step 4: Run** — `flutter test test/core/sync/` — Expected: PASS (old tests
included).

- [ ] **Step 5: Commit**

```bash
git add lib/core/sync/sync_coordinator.dart test/core/sync/sync_coordinator_test.dart
git commit -m "feat(sync): refused rows are recorded, cleared on apply, re-queued on demand (SB-U1)"
```

---

### Task 5: the scheduler reports each run and runs on demand

**Files:**
- Modify: `lib/core/sync/sync_scheduler.dart`
- Test: `test/core/sync/sync_scheduler_test.dart`

**Interfaces:**
- Produces: `SyncScheduler({..., Future<void> Function()? onSucceeded,
  Future<void> Function(Object error)? onFailed})`; `Future<bool> syncNow()`.

- [ ] **Step 1: Failing tests** — append to `sync_scheduler_test.dart`:

```dart
  test('each run reports success or its error', () {
    fakeAsync((clock) {
      final reports = <String>[];
      var fail = true;
      final scheduler = SyncScheduler(
        run: () async {
          if (fail) throw StateError('offline');
        },
        triggers: const Stream.empty(),
        onSucceeded: () async => reports.add('ok'),
        onFailed: (error) async => reports.add('failed:$error'),
      )..start();

      clock.elapse(Duration.zero);
      fail = false;
      clock.elapse(const Duration(seconds: 5));
      expect(reports, ['failed:Bad state: offline', 'ok']);
      scheduler.dispose();
    });
  });

  test('syncNow runs at once, forgets the backoff and says how it went', () {
    fakeAsync((clock) {
      var fail = true;
      final scheduler = SyncScheduler(
        run: () async {
          if (fail) throw StateError('offline');
        },
        triggers: const Stream.empty(),
      )..start();
      clock.elapse(Duration.zero);

      bool? result;
      fail = false;
      scheduler.syncNow().then((value) => result = value);
      clock.elapse(Duration.zero);
      expect(result, isTrue);
      scheduler.dispose();
    });
  });

  test('syncNow during a run waits for the next run', () {
    fakeAsync((clock) {
      final gate = Completer<void>();
      var runs = 0;
      final scheduler = SyncScheduler(
        run: () async {
          runs++;
          if (runs == 1) await gate.future;
          if (runs == 1) throw StateError('first run fails');
        },
        triggers: const Stream.empty(),
      )..start();
      clock.elapse(Duration.zero);

      bool? result;
      scheduler.syncNow().then((value) => result = value);
      gate.complete();
      clock.elapse(Duration.zero);
      expect(runs, 2);
      expect(result, isTrue);
      scheduler.dispose();
    });
  });

  test('a report that throws does not stop the scheduler', () {
    fakeAsync((clock) {
      var runs = 0;
      final triggers = StreamController<void>();
      final scheduler = SyncScheduler(
        run: () async => runs++,
        triggers: triggers.stream,
        onSucceeded: () async => throw StateError('disk full'),
      )..start();
      clock.elapse(Duration.zero);
      triggers.add(null);
      clock.elapse(const Duration(seconds: 2));
      expect(runs, 2);
      scheduler.dispose();
      triggers.close();
    });
  });
```

- [ ] **Step 2: Run** — `flutter test test/core/sync/sync_scheduler_test.dart`
Expected: FAIL — named parameters and `syncNow` not defined.

- [ ] **Step 3: Implement** — replace the constructor, add fields and rewrite
`_tick`/`dispose` in `sync_scheduler.dart`:

```dart
  SyncScheduler({
    required this._run,
    required this._triggers,
    this._reconnects = const Stream.empty(),
    this._onSucceeded,
    this._onFailed,
    this.debounce = const Duration(seconds: 2),
    this.minBackoff = const Duration(seconds: 5),
    this.maxBackoff = const Duration(minutes: 5),
  });

  /// Records a run that ended without an error (sync status spec §4).
  final Future<void> Function()? _onSucceeded;

  /// Records a run's error; the scheduler still backs off.
  final Future<void> Function(Object error)? _onFailed;

  /// Callers of [syncNow] waiting for the next run to end.
  final _waiters = <Completer<bool>>[];
```

```dart
  /// Sync now (screen 27): forget the backoff and run at once, or right after
  /// the run in progress. True when that run succeeded.
  Future<bool> syncNow() {
    final waiter = Completer<bool>();
    _waiters.add(waiter);
    _failures = 0;
    if (_running) {
      _rerun = true;
    } else {
      _schedule(Duration.zero);
    }
    return waiter.future;
  }

  void dispose() {
    _timer?.cancel();
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    for (final waiter in _waiters) {
      waiter.complete(false);
    }
    _waiters.clear();
  }
```

```dart
  Future<void> _tick() async {
    if (_running) {
      _rerun = true;
      return;
    }
    _running = true;
    final waiting = [..._waiters];
    _waiters.clear();
    var succeeded = false;
    try {
      await _run();
      succeeded = true;
      _failures = 0;
      await _report(() async => _onSucceeded?.call());
    } catch (error, stackTrace) {
      _failures++;
      log('Sync failed; retrying', error: error, stackTrace: stackTrace);
      await _report(() async => _onFailed?.call(error));
    } finally {
      _running = false;
      for (final waiter in waiting) {
        waiter.complete(succeeded);
      }
      if (_waiters.isNotEmpty || (succeeded && _rerun)) {
        _schedule(Duration.zero);
      } else if (!succeeded) {
        _schedule(backoffFor(_failures));
      }
      _rerun = false;
    }
  }

  /// A report that fails is logged; it never stops sync.
  Future<void> _report(Future<void> Function() report) async {
    try {
      await report();
    } catch (error, stackTrace) {
      log('Sync status not recorded', error: error, stackTrace: stackTrace);
    }
  }
```

- [ ] **Step 4: Run** — `flutter test test/core/sync/sync_scheduler_test.dart`
Expected: PASS, including the existing backoff tests.

- [ ] **Step 5: Commit**

```bash
git add lib/core/sync/sync_scheduler.dart test/core/sync/sync_scheduler_test.dart
git commit -m "feat(sync): the scheduler reports each run and runs on demand (SB-U1)"
```

---

### Task 6: providers and commands

**Files:**
- Create: `lib/core/sync/sync_commands.dart`
- Modify: `lib/core/sync/di/sync_providers.dart`
- Test: `test/core/sync/sync_providers_test.dart`

**Interfaces:**
- Consumes: Tasks 3–5.
- Produces:
  - `class SyncCommands { Future<bool> syncNow(); Future<bool> retryRejected(); Future<void> keepRejectedOnDevice(); }`
  - providers `syncStoreProvider` (`SyncStore`), `syncCoordinatorProvider`
    (`SyncCoordinator`), `syncSchedulerProvider` (`SyncScheduler?`, unchanged name),
    `syncStatusProvider` (`Stream<SyncStatus?>`), `syncCommandsProvider`
    (`SyncCommands?`).

- [ ] **Step 1: Failing test** `test/core/sync/sync_providers_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/core/network/supabase_config.dart';
import 'package:memox/core/sync/di/sync_providers.dart';

import '../../support/test_database.dart';

void main() {
  test('a build without Supabase has no status and no commands', () async {
    final db = openTestDatabase();
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        supabaseConfigProvider.overrideWithValue(
          const SupabaseConfig(url: '', publishableKey: ''),
        ),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await db.close();
    });

    expect(await container.read(syncStatusProvider.future), isNull);
    expect(container.read(syncCommandsProvider), isNull);
  });

  test('a build with Supabase reads the status from Drift', () async {
    final db = openTestDatabase();
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        supabaseConfigProvider.overrideWithValue(
          const SupabaseConfig(url: 'https://x.supabase.co', publishableKey: 'k'),
        ),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await db.close();
    });

    final status = await container.read(syncStatusProvider.future);
    expect(status?.pendingCount, 0);
  });
}
```

- [ ] **Step 2: Run** — `flutter test test/core/sync/sync_providers_test.dart`
Expected: FAIL — `syncStatusProvider` not defined.

- [ ] **Step 3: Implement** `lib/core/sync/sync_commands.dart`:

```dart
import 'package:memox/core/sync/sync_coordinator.dart';
import 'package:memox/core/sync/sync_scheduler.dart';
import 'package:memox/core/sync/sync_store.dart';

/// Screen 27's three commands, over the running sync (sync status spec §5.2).
class SyncCommands {
  SyncCommands({
    required SyncScheduler scheduler,
    required SyncCoordinator coordinator,
    required SyncStore store,
  }) : _scheduler = scheduler,
       _coordinator = coordinator,
       _store = store;

  final SyncScheduler _scheduler;
  final SyncCoordinator _coordinator;
  final SyncStore _store;

  Future<bool> syncNow() => _scheduler.syncNow();

  /// Try again: the refused rows go back to the outbox, then a run.
  Future<bool> retryRejected() async {
    await _coordinator.requeueRejected();
    return _scheduler.syncNow();
  }

  /// Keep on this device (R7).
  Future<void> keepRejectedOnDevice() => _store.forgetRejected();
}
```

Replace the body of `lib/core/sync/di/sync_providers.dart` after `syncApi` with:

```dart
@Riverpod(keepAlive: true)
SyncStore syncStore(Ref ref) => SyncStore(ref.watch(databaseProvider));

@Riverpod(keepAlive: true)
SyncCoordinator syncCoordinator(Ref ref) {
  final db = ref.watch(databaseProvider);
  return SyncCoordinator(
    api: ref.watch(syncApiProvider),
    store: ref.watch(syncStoreProvider),
    adapters: [DeckSyncAdapter(db), DeleteBatchSyncAdapter(db)],
    now: ref.watch(dayClockProvider).now,
  );
}

/// The running sync, or null when this build names no Supabase project.
@Riverpod(keepAlive: true)
SyncScheduler? syncScheduler(Ref ref) {
  if (!ref.watch(supabaseConfigProvider).isEnabled) {
    return null;
  }
  final store = ref.watch(syncStoreProvider);
  final clock = ref.watch(dayClockProvider);
  final online = Connectivity().onConnectivityChanged
      .where((results) => !results.contains(ConnectivityResult.none))
      .map((_) {});
  final scheduler = SyncScheduler(
    run: ref.watch(syncCoordinatorProvider).runOnce,
    triggers: store.outboxChanges().skip(1),
    reconnects: online,
    onSucceeded: () => store.recordSuccess(clock.now()),
    onFailed: (error) =>
        store.recordFailure(classifySyncFailure(error), clock.now()),
  )..start();
  ref.onDispose(scheduler.dispose);
  return scheduler;
}

/// What sync has done (screens 13, 23, 27); null when sync is off. Kept
/// alive: three screens read it and the Drift stream is cheap.
@Riverpod(keepAlive: true)
Stream<SyncStatus?> syncStatus(Ref ref) {
  if (!ref.watch(supabaseConfigProvider).isEnabled) {
    return Stream.value(null);
  }
  return ref.watch(syncStoreProvider).watchStatus();
}

/// Screen 27's commands; null when sync is off.
@Riverpod(keepAlive: true)
SyncCommands? syncCommands(Ref ref) {
  final scheduler = ref.watch(syncSchedulerProvider);
  if (scheduler == null) return null;
  return SyncCommands(
    scheduler: scheduler,
    coordinator: ref.watch(syncCoordinatorProvider),
    store: ref.watch(syncStoreProvider),
  );
}
```

Add imports: `package:memox/core/clock/di/day_clock_provider.dart`,
`package:memox/core/sync/sync_commands.dart`,
`package:memox/core/sync/sync_failure.dart`,
`package:memox/core/sync/sync_status.dart`. Keep `syncApi` and `supabaseConfig`
unchanged. Then run `dart run build_runner build --delete-conflicting-outputs`.

Note: the second test reads `syncStatusProvider` only; it never builds the scheduler,
so `Supabase.instance` is not touched.

- [ ] **Step 4: Run** — `flutter test test/core/sync/` — Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/sync/sync_commands.dart lib/core/sync/di/sync_providers.dart test/core/sync/sync_providers_test.dart
git commit -m "feat(sync): status stream and commands for the UI; hidden without Supabase (SB-U1)"
```

---

### Task 7: copy, icon and labels

**Files:**
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb`
- Modify: `lib/core/theme/foundations/app_icons.dart`
- Create: `lib/features/settings/presentation/widgets/support/sync_labels.dart`
- Test: `test/features/settings/presentation/sync_labels_test.dart`

**Interfaces:**
- Produces: `AppIcons.sync`;
  `String syncTimeLabel(AppLocalizations l10n, DateTime at, DateTime now)`;
  `String syncStatusLine(AppLocalizations l10n, SyncStatus status, DateTime now)`;
  `String syncFailureSentence(AppLocalizations l10n, SyncFailureKind kind)`;
  ARB keys listed below.

- [ ] **Step 1: Icon** — in `app_icons.dart`, next to `offline`:

```dart
  static const IconData sync = Icons.cloud_sync_outlined; // cloud-sync
```

- [ ] **Step 2: English strings** — add to `app_en.arb` (before the final `}`), each
with its description:

```json
  "settingsSync": "Sync",
  "@settingsSync": {"description": "Screen 23 (SB-U1): the Sync section title and its row that opens screen 27."},
  "syncTitle": "Sync",
  "@syncTitle": {"description": "Screen 27 (SB-U1): the app bar title."},
  "syncStatusRejected": "{count, plural, =1{1 change kept only on this device} other{{count} changes kept only on this device}}",
  "@syncStatusRejected": {"placeholders": {"count": {"type": "int", "format": "decimalPattern"}}, "description": "Screen 23 (SB-U1): the Sync row while refused rows remain (spec §5.1 rule 1)."},
  "syncStatusFailedNetwork": "Couldn't sync · no connection",
  "@syncStatusFailedNetwork": {"description": "Screen 23 (SB-U1): the Sync row after a failed run, network."},
  "syncStatusFailedSignIn": "Couldn't sync · couldn't sign in",
  "@syncStatusFailedSignIn": {"description": "Screen 23 (SB-U1): the Sync row after a failed run, sign-in."},
  "syncStatusFailedServer": "Couldn't sync · server error",
  "@syncStatusFailedServer": {"description": "Screen 23 (SB-U1): the Sync row after a failed run, server."},
  "syncStatusFailedUnknown": "Couldn't sync · something went wrong",
  "@syncStatusFailedUnknown": {"description": "Screen 23 (SB-U1): the Sync row after a failed run, unknown."},
  "syncStatusSynced": "Synced {time}",
  "@syncStatusSynced": {"placeholders": {"time": {"type": "String"}}, "description": "Screen 23 (SB-U1): the Sync row after a success; {time} is from syncTime*."},
  "syncStatusNever": "Not synced yet",
  "@syncStatusNever": {"description": "Screen 23 (SB-U1): the Sync row before any run ended."},
  "syncTimeToday": "Today, {time}",
  "@syncTimeToday": {"placeholders": {"time": {"type": "String"}}, "description": "SB-U1: an absolute time today (R6); {time} is HH:mm."},
  "syncTimeYesterday": "Yesterday, {time}",
  "@syncTimeYesterday": {"placeholders": {"time": {"type": "String"}}, "description": "SB-U1: an absolute time yesterday (R6); {time} is HH:mm."},
  "syncTimeOnDay": "{day}, {time}",
  "@syncTimeOnDay": {"placeholders": {"day": {"type": "String"}, "time": {"type": "String"}}, "description": "SB-U1: an absolute time on an earlier day (R6); {day} is the short month and day."},
  "syncStatusSection": "Status",
  "@syncStatusSection": {"description": "Screen 27 (SB-U1): the Status section title."},
  "syncLastSynced": "Last synced",
  "@syncLastSynced": {"description": "Screen 27 (SB-U1): the row naming the last success."},
  "syncLastSyncedNever": "Not yet",
  "@syncLastSyncedNever": {"description": "Screen 27 (SB-U1): Last synced before any success."},
  "syncWaiting": "Waiting to sync",
  "@syncWaiting": {"description": "Screen 27 (SB-U1): the row counting pending changes."},
  "syncWaitingCount": "{count, plural, =1{1 change} other{{count} changes}}",
  "@syncWaitingCount": {"placeholders": {"count": {"type": "int", "format": "decimalPattern"}}, "description": "Screen 27 (SB-U1): the pending count."},
  "syncWaitingNone": "Nothing waiting",
  "@syncWaitingNone": {"description": "Screen 27 (SB-U1): no pending change."},
  "syncNote": "MemoX syncs on its own when you're online. Your study never waits for it.",
  "@syncNote": {"description": "Screen 27 (SB-U1): the Status section note."},
  "syncNow": "Sync now",
  "@syncNow": {"description": "Screen 27 (SB-U1): the button that runs a sync."},
  "syncRejectedTitle": "{count, plural, =1{1 change is kept only on this device} other{{count} changes are kept only on this device}}",
  "@syncRejectedTitle": {"placeholders": {"count": {"type": "int", "format": "decimalPattern"}}, "description": "Screen 27 (SB-U1): the refused-rows banner title."},
  "syncRejectedBody": "The server didn't accept them. They're safe here. Try again, or keep them on this device only.",
  "@syncRejectedBody": {"description": "Screen 27 (SB-U1): the refused-rows banner message (local-first voice)."},
  "syncTryAgain": "Try again",
  "@syncTryAgain": {"description": "Screen 27 (SB-U1): re-queues the refused rows and syncs."},
  "syncKeepOnDevice": "Keep on this device",
  "@syncKeepOnDevice": {"description": "Screen 27 (SB-U1): forgets the refusals; the data stays local (R7)."},
  "syncFailedNetwork": "No connection. Your changes are safe on this device and will sync when you're back online.",
  "@syncFailedNetwork": {"description": "Screen 27 (SB-U1): the failure banner, network (spec §5.4)."},
  "syncFailedSignIn": "Couldn't sign in to sync. Your changes are safe on this device. MemoX will try again.",
  "@syncFailedSignIn": {"description": "Screen 27 (SB-U1): the failure banner, sign-in."},
  "syncFailedServer": "The server couldn't take the changes. They're safe on this device. MemoX will try again.",
  "@syncFailedServer": {"description": "Screen 27 (SB-U1): the failure banner, server."},
  "syncFailedUnknown": "Sync stopped with an error. Your changes are safe on this device. MemoX will try again.",
  "@syncFailedUnknown": {"description": "Screen 27 (SB-U1): the failure banner, unknown."},
  "syncDone": "Synced",
  "@syncDone": {"description": "Screen 27 (SB-U1): toast after Sync now or Try again succeeded."},
  "syncNotDone": "Couldn't sync. Nothing was lost.",
  "@syncNotDone": {"description": "Screen 27 (SB-U1): toast after Sync now or Try again failed."},
  "syncKept": "Kept on this device",
  "@syncKept": {"description": "Screen 27 (SB-U1): toast after Keep on this device."},
  "syncChangeFailed": "Couldn't change that. Nothing was lost.",
  "@syncChangeFailed": {"description": "Screen 27 (SB-U1): toast when Try again or Keep on this device could not write (spec §6)."},
  "syncLoadErrorTitle": "Couldn't open Sync",
  "@syncLoadErrorTitle": {"description": "Screen 27 (SB-U1): the status stream failed (spec §6)."},
  "studyHomeSyncRejected": "{count, plural, =1{1 change is kept only on this device.} other{{count} changes are kept only on this device.}}",
  "@studyHomeSyncRejected": {"placeholders": {"count": {"type": "int", "format": "decimalPattern"}}, "description": "Screen 13 (SB-U1): the sync banner while refused rows remain (spec §5.3)."},
  "studyHomeSyncStale": "Some changes haven't reached the server for over a day. They're safe on this device.",
  "@studyHomeSyncStale": {"description": "Screen 13 (SB-U1): the sync banner when a change waited over 24 h."},
  "studyHomeSyncDetails": "Details",
  "@studyHomeSyncDetails": {"description": "Screen 13 (SB-U1): opens screen 27."}
```

- [ ] **Step 3: Vietnamese strings** — add to `app_vi.arb`:

```json
  "settingsSync": "Đồng bộ",
  "syncTitle": "Đồng bộ",
  "syncStatusRejected": "{count, plural, other{{count} thay đổi chỉ lưu trên máy này}}",
  "syncStatusFailedNetwork": "Chưa đồng bộ được · không có mạng",
  "syncStatusFailedSignIn": "Chưa đồng bộ được · không đăng nhập được",
  "syncStatusFailedServer": "Chưa đồng bộ được · lỗi máy chủ",
  "syncStatusFailedUnknown": "Chưa đồng bộ được · có lỗi xảy ra",
  "syncStatusSynced": "Đã đồng bộ {time}",
  "syncStatusNever": "Chưa đồng bộ lần nào",
  "syncTimeToday": "Hôm nay, {time}",
  "syncTimeYesterday": "Hôm qua, {time}",
  "syncTimeOnDay": "{day}, {time}",
  "syncStatusSection": "Trạng thái",
  "syncLastSynced": "Lần đồng bộ gần nhất",
  "syncLastSyncedNever": "Chưa có",
  "syncWaiting": "Đang chờ đồng bộ",
  "syncWaitingCount": "{count, plural, other{{count} thay đổi}}",
  "syncWaitingNone": "Không có gì đang chờ",
  "syncNote": "MemoX tự đồng bộ khi có mạng. Việc học không bao giờ phải chờ đồng bộ.",
  "syncNow": "Đồng bộ ngay",
  "syncRejectedTitle": "{count, plural, other{{count} thay đổi chỉ được lưu trên máy này}}",
  "syncRejectedBody": "Máy chủ không nhận các thay đổi này. Chúng vẫn an toàn trên máy. Hãy thử lại, hoặc chỉ giữ chúng trên máy này.",
  "syncTryAgain": "Thử lại",
  "syncKeepOnDevice": "Giữ trên máy này",
  "syncFailedNetwork": "Không có mạng. Thay đổi của bạn vẫn an toàn trên máy và sẽ đồng bộ khi có mạng trở lại.",
  "syncFailedSignIn": "Không đăng nhập được để đồng bộ. Thay đổi của bạn vẫn an toàn trên máy. MemoX sẽ thử lại.",
  "syncFailedServer": "Máy chủ chưa nhận được các thay đổi. Chúng vẫn an toàn trên máy. MemoX sẽ thử lại.",
  "syncFailedUnknown": "Đồng bộ dừng vì có lỗi. Thay đổi của bạn vẫn an toàn trên máy. MemoX sẽ thử lại.",
  "syncDone": "Đã đồng bộ",
  "syncNotDone": "Chưa đồng bộ được. Không mất gì cả.",
  "syncKept": "Đã giữ trên máy này",
  "syncChangeFailed": "Chưa đổi được. Không mất gì cả.",
  "syncLoadErrorTitle": "Không mở được Đồng bộ",
  "studyHomeSyncRejected": "{count, plural, other{{count} thay đổi chỉ được lưu trên máy này.}}",
  "studyHomeSyncStale": "Một số thay đổi đã hơn một ngày chưa lên máy chủ. Chúng vẫn an toàn trên máy.",
  "studyHomeSyncDetails": "Chi tiết"
```

Run: `flutter gen-l10n` — Expected: no errors; `test/app/l10n_test.dart` still passes
(`flutter test test/app/l10n_test.dart`).

- [ ] **Step 4: Failing labels test**
`test/features/settings/presentation/sync_labels_test.dart`:

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:memox/core/sync/sync_failure.dart';
import 'package:memox/core/sync/sync_status.dart';
import 'package:memox/features/settings/presentation/widgets/support/sync_labels.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final vi = lookupAppLocalizations(const Locale('vi'));
  setUpAll(() async {
    await initializeDateFormatting('en');
    await initializeDateFormatting('vi');
  });

  final now = DateTime(2026, 9, 28, 0, 30);

  test('today, yesterday by the calendar day, and earlier days', () {
    expect(syncTimeLabel(en, DateTime(2026, 9, 28, 0, 5), now), 'Today, 00:05');
    expect(
      syncTimeLabel(en, DateTime(2026, 9, 27, 23, 50), now),
      'Yesterday, 23:50',
    );
    expect(syncTimeLabel(en, DateTime(2026, 9, 26, 14, 32), now), 'Sep 26, 14:32');
    expect(syncTimeLabel(vi, DateTime(2026, 9, 27, 9, 10), now), 'Hôm qua, 09:10');
  });

  test('the status line: refused, then failure, then success, then never', () {
    final success = DateTime(2026, 9, 28, 0, 10);
    expect(
      syncStatusLine(en, const SyncStatus(rejectedCount: 2), now),
      '2 changes kept only on this device',
    );
    expect(
      syncStatusLine(
        en,
        SyncStatus(
          lastSuccessAt: success,
          lastFailure: LastSyncFailure(SyncFailureKind.network, now),
        ),
        now,
      ),
      "Couldn't sync · no connection",
    );
    expect(
      syncStatusLine(en, SyncStatus(lastSuccessAt: success), now),
      'Synced Today, 00:10',
    );
    expect(syncStatusLine(en, const SyncStatus(), now), 'Not synced yet');
  });

  test('every failure kind has its sentence', () {
    for (final kind in SyncFailureKind.values) {
      expect(syncFailureSentence(en, kind), isNotEmpty);
    }
  });
}
```

Note: `DateFormat.MMMd('en')` gives "Sep 26" — the spec's "26 Sep" is the en_GB form;
this plan uses the app's `en` locale as-is and records it in Task 11's docs.

- [ ] **Step 5: Run** — `flutter test test/features/settings/presentation/sync_labels_test.dart`
Expected: FAIL — `sync_labels.dart` not found.

- [ ] **Step 6: Implement**
`lib/features/settings/presentation/widgets/support/sync_labels.dart`:

```dart
import 'package:intl/intl.dart';
import 'package:memox/core/sync/sync_failure.dart';
import 'package:memox/core/sync/sync_status.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

/// An absolute time (R6), by the local calendar day of [now].
String syncTimeLabel(AppLocalizations l10n, DateTime at, DateTime now) {
  final local = at.toLocal();
  final time = DateFormat.Hm(l10n.localeName).format(local);
  final day = DateTime(local.year, local.month, local.day);
  final today = DateTime(now.year, now.month, now.day);
  if (day == today) return l10n.syncTimeToday(time);
  if (day == DateTime(now.year, now.month, now.day - 1)) {
    return l10n.syncTimeYesterday(time);
  }
  return l10n.syncTimeOnDay(DateFormat.MMMd(l10n.localeName).format(local), time);
}

/// Screen 23's Sync row subtitle (spec §5.1): the first rule that applies.
String syncStatusLine(AppLocalizations l10n, SyncStatus status, DateTime now) {
  if (status.rejectedCount > 0) {
    return l10n.syncStatusRejected(status.rejectedCount);
  }
  if (status.lastFailure case final failure?) {
    return switch (failure.kind) {
      SyncFailureKind.network => l10n.syncStatusFailedNetwork,
      SyncFailureKind.signIn => l10n.syncStatusFailedSignIn,
      SyncFailureKind.server => l10n.syncStatusFailedServer,
      SyncFailureKind.unknown => l10n.syncStatusFailedUnknown,
    };
  }
  if (status.lastSuccessAt case final success?) {
    return l10n.syncStatusSynced(syncTimeLabel(l10n, success, now));
  }
  return l10n.syncStatusNever;
}

/// Screen 27's failure banner (spec §5.4): local-first, no code or message.
String syncFailureSentence(AppLocalizations l10n, SyncFailureKind kind) =>
    switch (kind) {
      SyncFailureKind.network => l10n.syncFailedNetwork,
      SyncFailureKind.signIn => l10n.syncFailedSignIn,
      SyncFailureKind.server => l10n.syncFailedServer,
      SyncFailureKind.unknown => l10n.syncFailedUnknown,
    };
```

- [ ] **Step 7: Run** — the labels test — Expected: PASS.

- [ ] **Step 8: Commit**

```bash
git add lib/l10n/app_en.arb lib/l10n/app_vi.arb lib/core/theme/foundations/app_icons.dart \
  lib/features/settings/presentation/widgets/support/sync_labels.dart \
  test/features/settings/presentation/sync_labels_test.dart
git commit -m "feat(settings): sync copy in English and Vietnamese, the status line and times (SB-U1)"
```

---

### Task 8: screen 27 "Sync"

**Files:**
- Create: `lib/features/settings/presentation/states/sync_screen_state.dart`
- Create: `lib/features/settings/presentation/controllers/sync_controller.dart`
- Create: `lib/features/settings/presentation/widgets/sections/sync_problem_banners_widget.dart`
- Create: `lib/features/settings/presentation/widgets/sections/sync_status_section_widget.dart`
- Create: `lib/features/settings/presentation/screens/sync_screen.dart`
- Modify: `lib/app/router/app_routes.dart`, `lib/app/router/app_router.dart`
- Test: `test/features/settings/presentation/sync_screen_test.dart`,
  `test/features/settings/presentation/sync_screen_golden_test.dart`

**Interfaces:**
- Consumes: `syncStatusProvider`, `syncCommandsProvider`, `SyncCommands`,
  `syncTimeLabel`, `syncFailureSentence`, `dayClockProvider`.
- Produces: `SyncScreen` (const, no parameters); `AppRoutes.settingsSync`
  (`/settings/sync`), `AppRoutes.settingsSyncChild` (`sync`).

- [ ] **Step 1: State** `sync_screen_state.dart`:

```dart
import 'package:flutter/foundation.dart';

/// Screen 27's commands (spec §5.2); one runs at a time.
enum SyncTask { syncNow, retry, keep }

/// What screen 27 says when a command ends. Each is a new object.
sealed class SyncNotice {}

final class SyncSucceeded extends SyncNotice {}

final class SyncNotSucceeded extends SyncNotice {}

final class SyncKeptOnDevice extends SyncNotice {}

/// Try again or Keep on this device could not write (spec §6).
final class SyncChangeFailed extends SyncNotice {
  SyncChangeFailed(this.task);

  final SyncTask task;
}

@immutable
final class SyncScreenState {
  const SyncScreenState({this.task, this.notice});

  /// The command running, or null.
  final SyncTask? task;
  final SyncNotice? notice;
}
```

- [ ] **Step 2: Controller** `sync_controller.dart`:

```dart
import 'package:memox/core/sync/di/sync_providers.dart';
import 'package:memox/features/settings/presentation/states/sync_screen_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sync_controller.g.dart';

/// Screen 27's commands (spec §5.2): one at a time; each ends in a notice.
@riverpod
class SyncController extends _$SyncController {
  @override
  SyncScreenState build() => const SyncScreenState();

  Future<void> run(SyncTask task) async {
    final commands = ref.read(syncCommandsProvider);
    if (commands == null || state.task != null) return;
    state = SyncScreenState(task: task);
    final SyncNotice notice;
    try {
      notice = switch (task) {
        SyncTask.syncNow => await commands.syncNow()
            ? SyncSucceeded()
            : SyncNotSucceeded(),
        SyncTask.retry => await commands.retryRejected()
            ? SyncSucceeded()
            : SyncNotSucceeded(),
        SyncTask.keep => await _keep(commands.keepRejectedOnDevice),
      };
    } on Object {
      if (!ref.mounted) return;
      state = SyncScreenState(notice: SyncChangeFailed(task));
      return;
    }
    if (!ref.mounted) return;
    state = SyncScreenState(notice: notice);
  }

  static Future<SyncNotice> _keep(Future<void> Function() keep) async {
    await keep();
    return SyncKeptOnDevice();
  }
}
```

Run `dart run build_runner build --delete-conflicting-outputs`.

- [ ] **Step 3: Banners** `sync_problem_banners_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/sync/sync_status.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/settings/presentation/states/sync_screen_state.dart';
import 'package:memox/features/settings/presentation/widgets/support/sync_labels.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';

/// Screen 27's problems (spec §5.2): the refused rows first, then the last
/// failed run. Nothing when all is well.
class SyncProblemBannersWidget extends StatelessWidget {
  const SyncProblemBannersWidget({
    super.key,
    required this.status,
    required this.task,
    required this.onRun,
  });

  final SyncStatus status;
  final SyncTask? task;
  final ValueChanged<SyncTask> onRun;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isIdle = task == null;
    final failure = status.lastFailure;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.gutter,
      children: [
        if (status.rejectedCount > 0)
          MxInlineBanner(
            tone: MxBannerTone.warning,
            title: l10n.syncRejectedTitle(status.rejectedCount),
            message: l10n.syncRejectedBody,
            actions: [
              MxButton(
                label: l10n.syncTryAgain,
                size: MxButtonSize.compact,
                isLoading: task == SyncTask.retry,
                onPressed: isIdle ? () => onRun(SyncTask.retry) : null,
              ),
              MxButton(
                label: l10n.syncKeepOnDevice,
                size: MxButtonSize.compact,
                tone: MxButtonTone.outline,
                isLoading: task == SyncTask.keep,
                onPressed: isIdle ? () => onRun(SyncTask.keep) : null,
              ),
            ],
          ),
        if (failure != null)
          MxInlineBanner(
            tone: MxBannerTone.warning,
            message: syncFailureSentence(l10n, failure.kind),
          ),
      ],
    );
  }
}
```

- [ ] **Step 4: Status section** `sync_status_section_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/sync/sync_status.dart';
import 'package:memox/features/settings/presentation/widgets/support/sync_labels.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_section.dart';
import 'package:memox/shared/widgets/mx_settings_row.dart';

/// Screen 27's Status section (spec §5.2): the last success and what waits.
class SyncStatusSectionWidget extends StatelessWidget {
  const SyncStatusSectionWidget({
    super.key,
    required this.status,
    required this.now,
  });

  final SyncStatus status;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final success = status.lastSuccessAt;
    return MxSection(
      title: l10n.syncStatusSection,
      note: l10n.syncNote,
      children: [
        MxSettingsRow(
          label: l10n.syncLastSynced,
          subtitle: success == null
              ? l10n.syncLastSyncedNever
              : syncTimeLabel(l10n, success, now),
        ),
        MxSettingsRow(
          label: l10n.syncWaiting,
          subtitle: status.pendingCount == 0
              ? l10n.syncWaitingNone
              : l10n.syncWaitingCount(status.pendingCount),
        ),
      ],
    );
  }
}
```

- [ ] **Step 5: Screen** `sync_screen.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/clock/di/day_clock_provider.dart';
import 'package:memox/core/sync/di/sync_providers.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/features/settings/presentation/controllers/sync_controller.dart';
import 'package:memox/features/settings/presentation/states/sync_screen_state.dart';
import 'package:memox/features/settings/presentation/widgets/sections/sync_problem_banners_widget.dart';
import 'package:memox/features/settings/presentation/widgets/sections/sync_status_section_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';

/// Screen 27, Sync (SB-U1, sync status spec §5.2): what sync did, what
/// waits, the last problem, and Sync now. Not in the kit (v3 predates the
/// server); shaped with Impeccable 2026-09-28.
class SyncScreen extends ConsumerWidget {
  const SyncScreen({super.key});

  static const int _skeletonRows = 2;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    ref.listen(
      syncControllerProvider.select((state) => state.notice),
      (_, notice) => _say(context, ref, notice),
    );
    final task = ref.watch(syncControllerProvider.select((s) => s.task));
    void run(SyncTask next) =>
        unawaited(ref.read(syncControllerProvider.notifier).run(next));
    return MxAppShell(
      appBar: MxAppBar(
        title: l10n.syncTitle,
        density: MxAppBarDensity.content,
        leading: MxIconButton(
          icon: AppIcons.back,
          semanticLabel: l10n.commonBack,
          onPressed: () => unawaited(Navigator.of(context).maybePop()),
        ),
      ),
      body: switch (ref.watch(syncStatusProvider)) {
        AsyncData(:final value?) => MxScreenScroll(
          children: [
            SyncProblemBannersWidget(status: value, task: task, onRun: run),
            SyncStatusSectionWidget(
              status: value,
              now: ref.watch(dayClockProvider).now(),
            ),
            MxButton(
              label: l10n.syncNow,
              icon: AppIcons.sync,
              isBlock: true,
              isLoading: task == SyncTask.syncNow,
              onPressed: task == null ? () => run(SyncTask.syncNow) : null,
            ),
          ],
        ),
        AsyncData() || AsyncError() => MxScreenScroll(
          children: [
            MxErrorState(
              title: l10n.syncLoadErrorTitle,
              body: l10n.libraryLoadErrorBody,
              retryLabel: l10n.commonRetry,
              onRetry: () => ref.invalidate(syncStatusProvider),
            ),
          ],
        ),
        _ => MxScreenScroll(
          children: [
            MxSkeletonList(semanticLabel: l10n.commonLoading, rows: _skeletonRows),
          ],
        ),
      },
    );
  }

  void _say(BuildContext context, WidgetRef ref, SyncNotice? notice) {
    final l10n = context.l10n;
    switch (notice) {
      case null:
        return;
      case SyncSucceeded():
        showMxSnackbar(context, message: l10n.syncDone);
      case SyncNotSucceeded():
        showMxSnackbar(context, message: l10n.syncNotDone);
      case SyncKeptOnDevice():
        showMxSnackbar(context, message: l10n.syncKept);
      case SyncChangeFailed(:final task):
        showMxSnackbar(
          context,
          message: l10n.syncChangeFailed,
          actionLabel: l10n.commonRetry,
          onAction: () =>
              unawaited(ref.read(syncControllerProvider.notifier).run(task)),
        );
    }
  }
}
```

Check `MxScreenScroll` spaces its children (it does for Settings sections); if it does
not, wrap the three children in a `Column(spacing: AppSpacing.gutter)` as Study home
does.

- [ ] **Step 6: Route** — `app_routes.dart`, after the reminder entries:

```dart
  /// Sync (screen 27, SB-U1), relative to [settings], on the root
  /// navigator like Theme and Language.
  static const String settingsSyncChild = 'sync';
  static const String settingsSync = '$settings/$settingsSyncChild';
```

`app_router.dart`: import `sync_screen.dart` and add under the settings route's
`routes:` after the reminder route:

```dart
                  GoRoute(
                    path: AppRoutes.settingsSyncChild,
                    parentNavigatorKey: rootNavigator,
                    builder: (context, state) => const SyncScreen(),
                  ),
```

- [ ] **Step 7: Failing widget test** `sync_screen_test.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/sync/di/sync_providers.dart';
import 'package:memox/core/sync/sync_commands.dart';
import 'package:memox/core/sync/sync_failure.dart';
import 'package:memox/core/sync/sync_status.dart';
import 'package:memox/features/settings/presentation/screens/sync_screen.dart';

import '../../../support/library_harness.dart';

class FakeSyncCommands implements SyncCommands {
  var syncs = 0;
  var retries = 0;
  var keeps = 0;
  bool result = true;
  Completer<bool>? hold;

  @override
  Future<bool> syncNow() async {
    syncs++;
    return hold?.future ?? result;
  }

  @override
  Future<bool> retryRejected() async {
    retries++;
    return result;
  }

  @override
  Future<void> keepRejectedOnDevice() async => keeps++;
}

List<Override> syncOverrides(SyncStatus status, FakeSyncCommands commands) => [
  syncStatusProvider.overrideWith((ref) => Stream.value(status)),
  syncCommandsProvider.overrideWithValue(commands),
];

void main() {
  libraryTest('Sync now runs and says Synced', (tester, env) async {
    final commands = FakeSyncCommands();
    await pumpLibraryScreen(
      tester,
      env,
      const SyncScreen(),
      overrides: syncOverrides(const SyncStatus(), commands),
    );
    await tester.tap(find.text('Sync now'));
    await tester.pump();
    await tester.pump();
    expect(commands.syncs, 1);
    expect(find.text('Synced'), findsOneWidget);
  });

  libraryTest('a failed Sync now says nothing was lost', (tester, env) async {
    final commands = FakeSyncCommands()..result = false;
    await pumpLibraryScreen(
      tester,
      env,
      const SyncScreen(),
      overrides: syncOverrides(const SyncStatus(), commands),
    );
    await tester.tap(find.text('Sync now'));
    await tester.pump();
    await tester.pump();
    expect(find.text("Couldn't sync. Nothing was lost."), findsOneWidget);
  });

  libraryTest('refused rows offer Try again and Keep on this device', (
    tester,
    env,
  ) async {
    final commands = FakeSyncCommands();
    await pumpLibraryScreen(
      tester,
      env,
      const SyncScreen(),
      overrides: syncOverrides(const SyncStatus(rejectedCount: 3), commands),
    );
    expect(find.text('3 changes are kept only on this device'), findsOneWidget);
    await tester.tap(find.text('Keep on this device'));
    await tester.pump();
    await tester.pump();
    expect(commands.keeps, 1);
    expect(find.text('Kept on this device'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pump();
    await tester.pump();
    expect(commands.retries, 1);
  });

  libraryTest('a failure shows its sentence and no code', (tester, env) async {
    await pumpLibraryScreen(
      tester,
      env,
      const SyncScreen(),
      overrides: syncOverrides(
        SyncStatus(
          lastFailure: LastSyncFailure(SyncFailureKind.network, env.clock.now()),
        ),
        FakeSyncCommands(),
      ),
    );
    expect(find.textContaining('No connection.'), findsOneWidget);
  });

  libraryTest('Vietnamese at text scale 2 does not overflow', (tester, env) async {
    await pumpLibraryScreen(
      tester,
      env,
      const SyncScreen(),
      locale: const Locale('vi'),
      textScale: 2,
      overrides: syncOverrides(
        SyncStatus(
          rejectedCount: 1234,
          pendingCount: 1234,
          lastFailure: LastSyncFailure(SyncFailureKind.server, env.clock.now()),
        ),
        FakeSyncCommands(),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
```

(`Override` comes from `flutter_riverpod`; add `import 'package:flutter_riverpod/flutter_riverpod.dart';`.)

- [ ] **Step 8: Run** — `flutter test test/features/settings/presentation/sync_screen_test.dart`
Expected: PASS (the implementation from steps 1–6 is in place; if a finder fails, fix
the widget, not the test copy).

- [ ] **Step 9: Goldens** `sync_screen_golden_test.dart` (tag `golden`), for each
`Brightness` and each state, pumping with `pumpLibraryGolden(..., overrides: …)` inside
`withRealShadows` and comparing with
`expectBoundaryGolden(tester, 'goldens/sync_<state>_<theme>.png')`:

| state | status override |
|---|---|
| `synced` | `SyncStatus(lastSuccessAt: env.clock.now().subtract(const Duration(minutes: 5)))` |
| `never_synced` | `const SyncStatus()` |
| `pending` | `SyncStatus(lastSuccessAt: …, pendingCount: 12, oldestPendingAt: env.clock.now())` |
| `failed_network` | `SyncStatus(lastSuccessAt: …, lastFailure: LastSyncFailure(SyncFailureKind.network, env.clock.now()))` |
| `failed_server` | same with `SyncFailureKind.server` |
| `rejected` | `SyncStatus(lastSuccessAt: …, rejectedCount: 2)` |
| `syncing` | `const SyncStatus()` with `FakeSyncCommands()..hold = Completer<bool>()`, after `tester.tap(find.text('Sync now'))` and `tester.pump()` |

Import `FakeSyncCommands` and `syncOverrides` from `sync_screen_test.dart` — move them
into `test/features/settings/presentation/sync_test_support.dart` first so both files
share them.

Run: `flutter test --update-goldens --tags golden test/features/settings/presentation/sync_screen_golden_test.dart`,
open three of the PNGs to check the layout, then run without `--update-goldens` —
Expected: PASS.

- [ ] **Step 10: Commit**

```bash
git add lib/features/settings lib/app/router test/features/settings
git commit -m "feat(settings): screen 27 Sync — status, Sync now, refused rows (SB-U1)"
```

---

### Task 9: screen 23's Sync section

**Files:**
- Create: `lib/features/settings/presentation/widgets/sections/settings_sync_section_widget.dart`
- Modify: `lib/features/settings/presentation/screens/settings_screen.dart`
- Modify: `lib/app/router/app_router.dart`
- Test: `test/features/settings/presentation/settings_sync_section_test.dart`,
  `test/features/settings/presentation/settings_screen_golden_test.dart`

**Interfaces:**
- Consumes: `syncStatusProvider`, `syncStatusLine`, `AppIcons.sync`.
- Produces: `SettingsScreen({..., required VoidCallback onOpenSync})`.

- [ ] **Step 1: Widget** `settings_sync_section_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/sync/sync_status.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/features/settings/presentation/widgets/support/sync_labels.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_section.dart';
import 'package:memox/shared/widgets/mx_settings_row.dart';

/// Screen 23's Sync section (SB-U1, spec §5.1): one row naming the state,
/// opening screen 27.
class SettingsSyncSectionWidget extends StatelessWidget {
  const SettingsSyncSectionWidget({
    super.key,
    required this.status,
    required this.now,
    required this.onOpenSync,
  });

  final SyncStatus status;
  final DateTime now;
  final VoidCallback onOpenSync;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MxSection(
      title: l10n.settingsSync,
      children: [
        MxSettingsRow(
          label: l10n.settingsSync,
          subtitle: syncStatusLine(l10n, status, now),
          icon: AppIcons.sync,
          onTap: onOpenSync,
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Screen** — `SettingsScreen` gains `required this.onOpenSync` (field
`final VoidCallback onOpenSync;`, doc "Opens screen 27 (SB-U1).") and, between
`SettingsAppSectionWidget(...)` and the Reset `MxSection`:

```dart
            if (ref.watch(syncStatusProvider).value case final status?)
              SettingsSyncSectionWidget(
                status: status,
                now: ref.watch(dayClockProvider).now(),
                onOpenSync: onOpenSync,
              ),
```

Imports: `day_clock_provider.dart`, `sync_providers.dart`,
`settings_sync_section_widget.dart`. Update every `SettingsScreen(` call in `lib/` and
`test/` to pass `onOpenSync: () {}` (tests) or, in `app_router.dart`,
`onOpenSync: () => context.push(AppRoutes.settingsSync),`.

- [ ] **Step 3: Test** `settings_sync_section_test.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/sync/di/sync_providers.dart';
import 'package:memox/core/sync/sync_status.dart';
import 'package:memox/features/settings/presentation/screens/settings_screen.dart';

import '../../../support/library_harness.dart';

SettingsScreen _screen({void Function()? onOpenSync}) => SettingsScreen(
  onOpenTheme: () {},
  onOpenLanguage: () {},
  onOpenReminder: () {},
  onAppOptionsReset: () {},
  onOpenSync: onOpenSync ?? () {},
);

void main() {
  libraryTest('no Sync section without Supabase', (tester, env) async {
    await pumpLibraryScreen(tester, env, _screen());
    expect(find.text('Sync'), findsNothing);
  });

  libraryTest('the Sync row names the state and opens screen 27', (
    tester,
    env,
  ) async {
    var opened = 0;
    await pumpLibraryScreen(
      tester,
      env,
      _screen(onOpenSync: () => opened++),
      overrides: [
        syncStatusProvider.overrideWith(
          (ref) => Stream.value(const SyncStatus(rejectedCount: 1)),
        ),
      ],
    );
    await tester.scrollUntilVisible(
      find.text('1 change kept only on this device'),
      200,
    );
    await tester.tap(find.text('1 change kept only on this device'));
    expect(opened, 1);
  });
}
```

Run: `flutter test test/features/settings/presentation/` — Expected: PASS, and the
existing Settings goldens unchanged (the section is hidden without Supabase).

- [ ] **Step 4: Goldens** — in `settings_screen_golden_test.dart` add, per brightness,
`settings_sync_{synced,failed,rejected}_<theme>.png` with the `syncStatusProvider`
override (synced 5 minutes ago; network failure; 2 refused), scrolled so the Sync
section is in view (`tester.scrollUntilVisible(find.text('Sync').last, 200)` before the
capture). Generate with `--update-goldens --tags golden`, inspect, re-run.

- [ ] **Step 5: Commit**

```bash
git add lib/features/settings lib/app/router test/features/settings
git commit -m "feat(settings): the Sync row on screen 23 (SB-U1)"
```

---

### Task 10: screen 13's banner

**Files:**
- Create: `lib/features/study/presentation/widgets/sections/study_home_sync_banner_widget.dart`
- Modify: `lib/features/study/presentation/screens/study_home_screen.dart`
- Modify: `lib/app/router/app_router.dart`
- Test: `test/features/study/presentation/study_home_sync_banner_test.dart`,
  golden in the Study home golden test file (find it with
  `ls test/features/study/presentation/*home*golden*`).

**Interfaces:**
- Consumes: `syncStatusProvider`, `needsAttention`, `dayClockProvider`.
- Produces: `StudyHomeScreen({..., required VoidCallback onOpenSync})`.

- [ ] **Step 1: Widget**:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/sync/sync_status.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';

/// Screen 13's sync banner (SB-U1, spec §5.3): refused rows, or a change
/// that waited over a day. No close button (R7); Details opens screen 27.
class StudyHomeSyncBannerWidget extends StatelessWidget {
  const StudyHomeSyncBannerWidget({
    super.key,
    required this.status,
    required this.onOpenSync,
  });

  final SyncStatus status;
  final VoidCallback onOpenSync;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MxInlineBanner(
      tone: MxBannerTone.warning,
      message: status.rejectedCount > 0
          ? l10n.studyHomeSyncRejected(status.rejectedCount)
          : l10n.studyHomeSyncStale,
      actions: [
        MxButton(
          label: l10n.studyHomeSyncDetails,
          size: MxButtonSize.compact,
          onPressed: onOpenSync,
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Screen** — `StudyHomeScreen` gains `required this.onOpenSync`
(`final VoidCallback onOpenSync;`, doc "Opens screen 27 when the sync banner's Details
is tapped (SB-U1)."). In `_loaded`, compute before `return`:

```dart
    final sync = ref.watch(syncStatusProvider).value;
    final showsSync =
        sync != null && needsAttention(sync, ref.watch(dayClockProvider).now());
```

and put first in the returned list:

```dart
      if (showsSync) ...[
        StudyHomeSyncBannerWidget(status: sync, onOpenSync: onOpenSync),
        const SizedBox(height: AppSpacing.gutter),
      ],
```

Router: `onOpenSync: () => context.go(AppRoutes.settingsSync),` — the same cross-branch
move Study home already makes for the Library; Back from screen 27 lands on Settings.
Update every other `StudyHomeScreen(` call in `test/` with `onOpenSync: () {}`.

- [ ] **Step 3: Tests** `study_home_sync_banner_test.dart` — using the Study home test
helpers already used by `test/features/study/presentation/study_home_screen_test.dart`
(copy its pump helper and screen factory, adding `onOpenSync`):
  - no banner with `const SyncStatus()` and with sync off;
  - `SyncStatus(rejectedCount: 2)` → "2 changes are kept only on this device." and
    Details calls `onOpenSync`;
  - `SyncStatus(pendingCount: 1, oldestPendingAt: env.clock.now().toUtc().subtract(const Duration(hours: 25)))`
    → the stale sentence;
  - `pendingCount: 1, oldestPendingAt: 23 h ago` → no banner;
  - Vietnamese at text scale 2 with the rejected banner → `tester.takeException()` is
    null.

Run: `flutter test test/features/study/presentation/` — Expected: PASS.

- [ ] **Step 4: Golden** — add `study_home_sync_rejected_<theme>.png` and
`study_home_sync_stale_<theme>.png` to the Study home golden file with the override;
generate, inspect, re-run.

- [ ] **Step 5: Commit**

```bash
git add lib/features/study lib/app/router test/features/study
git commit -m "feat(study): Study home says when a change waits or was refused (SB-U1)"
```

---

### Task 11: documents and the gate

**Files:**
- Create: `docs/shared/ui/screen-handoff/27-sync.md`
- Modify: `docs/shared/ui/screen-handoff/00-index.md`, `23-settings.md`,
  `13-study-home.md`
- Modify: `docs/shared/data/schema.md`
- Modify: `docs/superpowers/specs/2026-09-28-sync-status-design.md` (status approved;
  §5.3 Details uses `context.go`; §4 note that `en` shows "Sep 26")
- Modify: `docs/wbs_supabase.md` (SB-U1 `xong` with the PR), `docs/wbs_FE.md` (the
  screen row)

- [ ] **Step 1: Screen handoff 27** — follow `24-daily-reminder.md`'s layout: header
comment, intro with spec link, Entry points (screen 23 Sync row; screen 13 Details),
Layout table (app bar, banners, Status section, Sync now), States table (the seven
goldens, each "V8 addition — not in kit v3"), Deviations (the whole screen: kit v3
removed network UI; shaped with Impeccable 2026-09-28), Copy (every string of Task 7
for screen 27).

- [ ] **Step 2: 23 and 13** — 23: a Layout row "Sync" (`MxSection` + `MxSettingsRow`,
status line rules, hidden without Supabase), a States row per new golden, a Deviation
row, the Copy line. 13: a Layout row for the banner, States rows for the two goldens,
a Deviation row (kit removed the offline banner; V8 restores a sync banner under R2),
the Copy line. Index: add screen 27's row (FE item `SB-U1`, status `aligned`) and
update 13 and 23's state counts.

- [ ] **Step 3: schema.md** — add `sync_rejection` (columns, PK, meaning) and the three
`sync_state` keys next to the existing sync entries; schema version 6.

- [ ] **Step 4: WBS** — `wbs_supabase.md` SB-U1 → `xong`, evidence the PR (filled after
it is opened) and "Bước tiếp theo" item 3 removed; add an update-context line.
`wbs_FE.md`: a row for screen 27 and the banner under the same PR, pointing to
`wbs_supabase.md` SB-U1.

- [ ] **Step 5: Gate**

```bash
python3 tools/docs/check.py
bash .claude/skills/flutter-workflow/scripts/dod_check.sh
```

Expected: docs PASS with no new warning; `✓ mechanical gates passed`.

- [ ] **Step 6: Commit**

```bash
git add docs/
git commit -m "docs: screen 27 Sync, the Settings row and the Study home banner; schema 6; SB-U1 done"
```

# TOPIK attempt sync Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Submitted TOPIK attempts sync between devices of one account: the app pushes and pulls the `topik_attempt` entity (the attempt with all its answers), and Supabase stores it insert-only with a final tombstone, checking integrity only (spec §7.2, §13.2, §13.3; Phase 2 plan 3 of §13.9, epic DEV-394).

**Architecture:** The capture triggers already exist (schema v17, plan 2 R1). This plan adds the client adapter `TopikAttemptSyncDao` (readRow, upsertFromServer, deleteFromServer, markAcknowledged), registers it last in `appSyncAdaptersOf`, adds the `markAllPending` seed, and ships one Supabase migration: two tables, the change/upsert/delete functions, the four dispatch functions rewritten in full, and `merge_user_data` rewritten to move the new rows.

**Tech Stack:** Dart 3.13 / Flutter 3.47.5, Drift, Riverpod 3; Supabase Postgres 17 (plpgsql), pgTAP.

**Spec:** `docs/superpowers/specs/2026-10-15-topik-practice-design.md` (§7.2, §7.3, §13.2, §13.3). Rules: `BR-TOPIK-018`, `BR-TOPIK-026`, `BR-TOPIK-027`, `BR-TOPIK-028`. Server conventions: `supabase/README.md#rules`, `docs/superpowers/specs/2026-09-27-server-sync-design.md` §4–§7.

## Global Constraints

- Wire shape: camelCase keys; times are ISO-8601 UTC without fractions on the client side (`Drift stores whole seconds`), the server writes `private.wire_time` (microseconds); `fromWireTime` reads both.
- The attempt row carries its answers as `answers: [...]`, one entity type `topik_attempt`; answers have no entity of their own.
- Server: insert-only. The same id of the same user is idempotent (`applied` with its version); another user's id raises `SYNC_ENTITY_CONFLICT`; an upsert onto a tombstone raises `ENTITY_TOMBSTONED`; integrity failures raise `VALIDATION_FAILED`. A delete is a final tombstone (`deleted_at`), its answers deleted physically, as `tag_delete`.
- Server tables: RLS on, no policy, no client privilege; `user_id` references `auth.users` `on delete cascade`; `(user_id, server_version)` unique.
- The four dispatch functions (`private.push_one`, `private.apply_operation`, `private.current_change`, `public.sync_changes`) are rewritten in full in one migration (DEV-199); `15_sync_entity_dispatch.sql` pins the type list.
- A released migration is never edited; the new one is `supabase/migrations/20261016000000_topik_attempt_sync.sql`.
- Client: pulled rows are written with `INSERT` after an existence check, never `INSERT OR REPLACE` (it would bypass the immutability trigger); `markAcknowledged` writes `server_version` only (plan 2 final review).
- Forward compatibility (plan 2 R4): a pulled attempt whose `level`, `section`, `mode` or `status` this build does not know, or with no `answers` list, is skipped with one `topik.sync_skipped` warning, never a failed pull.
- Supabase runs locally with `SUPABASE_INTERNAL_IMAGE_REGISTRY=docker.io` in this container (ECR is blocked by the proxy; Docker Hub works).
- Gates: `bash .claude/skills/flutter-workflow/scripts/dod_check.sh`; `npx supabase db start` + `npx supabase test db`; `bash tools/supabase/run_auth_it.sh` (the PR changes `supabase/migrations/`).
- Commits name the task's sub-issue and end with the session's attribution lines.

## Review Focus

1. **A pull that brings an attempt this device already has** (its own push, pulled back after a re-pull from 0): no duplicate answers, no immutability-trigger abort; only `server_version` is set (Task 2).
2. **A delete of an attempt the server never saw** (submitted then deleted offline; the outbox op collapses to `delete`): the server acknowledges it without creating a tombstone or failing (Task 4).
3. **A push with duplicate question numbers or sums that do not add up** (a corrupt or forged payload): `VALIDATION_FAILED`, nothing stored, the version counter unchanged (Task 4).
4. **An account merge**: the source user's attempts and their answers move to the target with fresh versions; nothing stays behind (Task 4).
5. **A newer build's attempt with an unknown code** (`mode = 'exam'`): skipped on pull, the rest of the page applied (Task 2).

---

### Task 1: Queue submitted attempts when everything is re-queued

**Files:**
- Modify: `lib/core/database/queries/sync_outbox_queries.drift` (import `topik.drift`, `seedTopikAttemptOutbox`)
- Modify: `lib/core/sync/sync_store.dart` (`markAllPending` calls it)
- Modify: `test/core/sync/sync_store_test.dart`

**Interfaces:**
- Produces: `seedTopikAttemptOutbox()` (generated); `SyncStore.markAllPending()` queues every completed attempt, oldest submit first, after `review_log` and before `account_settings`.

- [ ] **Step 1: Write the failing test**

In `test/core/sync/sync_store_test.dart`, inside `markAllPending queues every row parents first, once, and rewinds the cursor`, add to the seed list (inside `applyingRemote`, after the review_log insert):

```dart
        "INSERT INTO topik_attempt (id, test_id, level, section, round, mode, status, started_at, updated_at, current_question_no, question_count, max_score, content_version) VALUES ('TA', 'topik2-96-reading', 'topik2', 'reading', 96, 'practice', 'in_progress', 0, 0, 1, 1, 2, 1), ('TB', 'topik2-96-listening', 'topik2', 'listening', 96, 'practice', 'in_progress', 0, 0, 1, 1, 2, 1)",
        "INSERT INTO topik_attempt_answer (attempt_id, question_no) VALUES ('TA', 1), ('TB', 1)",
        "UPDATE topik_attempt_answer SET correct_idx = 1, points = 2, points_earned = 0, question_type = 'L2_picture' WHERE attempt_id = 'TB'",
        "UPDATE topik_attempt SET status = 'completed', completed_at = 5, updated_at = 5, score = 0, correct_count = 0, answered_count = 0 WHERE id = 'TB'",
```

and in the expected list, after `'review_log:V:upsert',`:

```dart
        'topik_attempt:TB:upsert',
```

(TA is in progress and never queued, BR-TOPIK-026.)

- [ ] **Step 2: Run it to verify it fails**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/core/sync/sync_store_test.dart`
Expected: FAIL — the queued list lacks `topik_attempt:TB:upsert`.

- [ ] **Step 3: Implement**

`sync_outbox_queries.drift`: add `import '../tables/topik.drift';` after `import '../tables/trash.drift';`, and after `seedReviewLogOutbox`:

```sql
-- Submitted TOPIK attempts only: one in progress is bound to its device
-- (BR-TOPIK-026), oldest submit first.
seedTopikAttemptOutbox:
INSERT INTO sync_outbox (op_id, entity_type, entity_id, op, created_at)
SELECT lower(hex(randomblob(4)) || '-' || hex(randomblob(2)) || '-4' ||
  substr(hex(randomblob(2)), 2) || '-' ||
  substr('89ab', 1 + (abs(random()) % 4), 1) ||
  substr(hex(randomblob(2)), 2) || '-' || hex(randomblob(6))),
  'topik_attempt', id, 'upsert', CAST(strftime('%s', 'now') AS INTEGER)
FROM topik_attempt WHERE status = 'completed' ORDER BY completed_at, id
ON CONFLICT (entity_type, entity_id) DO NOTHING;
```

`sync_store.dart` `markAllPending`: add `await seedTopikAttemptOutbox();` after `await seedReviewLogOutbox();`.

Run `dart run build_runner build --delete-conflicting-outputs`.

- [ ] **Step 4: Run the tests**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/core/sync test/core/auth`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/database/queries/sync_outbox_queries.drift lib/core/sync/sync_store.dart test/core/sync/sync_store_test.dart
git commit -m "<DEV-n> feat(sync): re-queue submitted TOPIK attempts with the rest"
```

---

### Task 2: The attempt sync adapter

**Files:**
- Create: `lib/core/database/queries/sync_topik_attempt_queries.drift`
- Create: `lib/features/topik/data/datasources/topik_attempt_sync_dao.dart`
- Test: `test/features/topik/data/topik_attempt_sync_dao_test.dart`

**Interfaces:**
- Consumes: v17 tables; `EntitySyncAdapter`, `toWireTime`, `fromWireTime` (`lib/core/sync/entity_sync_adapter.dart`); `TopikAttemptStatus`, `TopikAttemptMode`, `TopikLevel`, `TopikSection`; `appLogger` (`lib/core/logging/app_logger.dart`).
- Produces: `class TopikAttemptSyncDao extends DatabaseAccessor<AppDatabase> with _$TopikAttemptSyncDaoMixin, EntitySyncAdapter` with `static const type = 'topik_attempt'`.

Wire row (keys in this order):

```
id, testId, level, section, round, mode, status, startedAt, completedAt, updatedAt,
totalTimeMs, currentQuestionNo, questionCount, maxScore, score, correctCount,
answeredCount, contentVersion,
answers: [{questionNo, selectedIdx, timeSpentMs, answeredAt, correctIdx, points,
           pointsEarned, questionType}]
```

- [ ] **Step 1: Write the failing test**

`test/features/topik/data/topik_attempt_sync_dao_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart' show AppDatabase;
import 'package:memox/core/sync/sync_store.dart';
import 'package:memox/features/topik/data/datasources/topik_attempt_sync_dao.dart';
import 'package:memox/features/topik/data/repositories/topik_attempt_repository_impl.dart';
import 'package:memox/features/topik/domain/models/topik_level_model.dart';
import 'package:memox/features/topik/domain/models/topik_section_model.dart';

import '../../../support/test_database.dart';
import '../../../support/topik_attempt_fixtures.dart';
import '../../../support/topik_content_fixtures.dart';

// TOPIK spec §13.2: the adapter reads a submitted attempt with its answers,
// writes a pulled one once, deletes a tombstoned one and records versions.
final _test = topikTestFixture(
  level: TopikLevel.topik1,
  section: TopikSection.listening,
);
final _t0 = DateTime.utc(2026, 10, 15, 9);

Future<String> _submitted(TopikAttemptRepositoryImpl repository) async {
  final attempt = topikOk(await repository.start(_test, now: _t0));
  topikOk(
    await repository.answer(
      attemptId: attempt.id,
      questionNo: 1,
      selectedIdx: 1,
      elapsedMs: 1500,
      now: _t0.add(const Duration(seconds: 2)),
    ),
  );
  topikOk(
    await repository.submit(
      attemptId: attempt.id,
      test: _test,
      elapsedMs: 0,
      now: _t0.add(const Duration(seconds: 9)),
    ),
  );
  return attempt.id;
}

void main() {
  late AppDatabase db;
  late TopikAttemptSyncDao dao;
  late TopikAttemptRepositoryImpl repository;
  setUp(() {
    db = openTestDatabase();
    dao = TopikAttemptSyncDao(db);
    repository = TopikAttemptRepositoryImpl(db, now: () => _t0);
  });
  tearDown(() => db.close());

  test('reads a submitted attempt with its answers in wire shape', () async {
    final id = await _submitted(repository);

    final row = (await dao.readRow(id))!;

    expect(row['id'], id);
    expect(row['testId'], _test.testId);
    expect(row['status'], 'completed');
    expect(row['score'], 4);
    expect(row['startedAt'], '2026-10-15T09:00:00Z');
    expect(row['completedAt'], '2026-10-15T09:00:09Z');
    final answers = (row['answers']! as List).cast<Map<String, Object?>>();
    expect(answers, hasLength(30));
    expect(answers.first, {
      'questionNo': 1,
      'selectedIdx': 1,
      'timeSpentMs': 1500,
      'answeredAt': '2026-10-15T09:00:02Z',
      'correctIdx': 1,
      'points': 4,
      'pointsEarned': 4,
      'questionType': 'L1_answer_question',
    });
  });

  test('an attempt in progress or gone reads as null', () async {
    final open = topikOk(await repository.start(_test));
    expect(await dao.readRow(open.id), isNull);
    expect(await dao.readRow('gone'), isNull);
  });

  test('a pulled attempt lands once, with its answers and version, and '
      'queues nothing', () async {
    final id = await _submitted(repository);
    final row = (await dao.readRow(id))!;
    final other = openTestDatabase();
    addTearDown(other.close);
    final pulled = TopikAttemptSyncDao(other);

    await SyncStore(other).applyingRemote(() async {
      await pulled.upsertFromServer(row, 7);
      await pulled.upsertFromServer(row, 9);
    });

    final stored = (await topikAttemptRow(other, id))!;
    expect(stored.status, 'completed');
    expect(stored.serverVersion, 9);
    expect(await topikAnswerRows(other, id), hasLength(30));
    expect(await other.select(other.syncOutbox).get(), isEmpty);
    expect(await pulled.readRow(id), row);
  });

  test('a pulled copy of its own attempt only records the version', () async {
    final id = await _submitted(repository);
    final row = (await dao.readRow(id))!;

    await SyncStore(db).applyingRemote(() => dao.upsertFromServer(row, 11));

    expect((await topikAttemptRow(db, id))!.serverVersion, 11);
    expect(await topikAnswerRows(db, id), hasLength(30));
  });

  test('a pulled attempt with a code this build does not know is skipped '
      '(plan 2 R4)', () async {
    final id = await _submitted(repository);
    final row = {...(await dao.readRow(id))!, 'mode': 'exam'};
    final other = openTestDatabase();
    addTearDown(other.close);

    await SyncStore(other).applyingRemote(
      () => TopikAttemptSyncDao(other).upsertFromServer(row, 7),
    );

    expect(await topikAttemptRow(other, id), isNull);
  });

  test('a tombstone deletes the attempt and its answers; an unknown id is a '
      'no-op', () async {
    final id = await _submitted(repository);
    await db.customStatement('DELETE FROM sync_outbox');

    await SyncStore(db).applyingRemote(() async {
      await dao.deleteFromServer(id);
      await dao.deleteFromServer('gone');
    });

    expect(await topikAttemptRow(db, id), isNull);
    expect(await topikAnswerRows(db, id), isEmpty);
    expect(await db.select(db.syncOutbox).get(), isEmpty);
  });

  test('an acknowledgement records the version only', () async {
    final id = await _submitted(repository);

    await dao.markAcknowledged(id, 5);

    final stored = (await topikAttemptRow(db, id))!;
    expect(stored.serverVersion, 5);
    expect(stored.score, 4);
  });
}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/topik/data/topik_attempt_sync_dao_test.dart`
Expected: FAIL — `topik_attempt_sync_dao.dart` does not exist.

- [ ] **Step 3: Write the queries**

`lib/core/database/queries/sync_topik_attempt_queries.drift`:

```sql
import '../tables/topik.drift';

-- Sync of topik_attempt (TOPIK spec 2026-10-15 §13.2). A submitted attempt
-- is an immutable record: a pulled one is inserted once, and only
-- server_version ever changes after that (topik_attempt_completed_immutable).

-- The attempt :id when it is submitted; one in progress never syncs.
syncTopikAttemptRow(:id AS TEXT):
SELECT * FROM topik_attempt WHERE id = :id AND status = 'completed';

syncTopikAttemptAnswers(:attempt_id AS TEXT):
SELECT * FROM topik_attempt_answer WHERE attempt_id = :attempt_id
ORDER BY question_no;

syncTopikAttemptExists(:id AS TEXT):
SELECT EXISTS (SELECT 1 FROM topik_attempt WHERE id = :id);

insertSyncedTopikAttempt: INSERT INTO topik_attempt $row;

insertSyncedTopikAnswer: INSERT INTO topik_attempt_answer $row;

-- A tombstone; the answers go by cascade.
deleteSyncedTopikAttempt(:id AS TEXT):
DELETE FROM topik_attempt WHERE id = :id;

acknowledgeTopikAttempt(:id AS TEXT, :server_version AS INTEGER):
UPDATE topik_attempt SET server_version = :server_version
WHERE id = :id AND status = 'completed';
```

- [ ] **Step 4: Write the adapter**

`lib/features/topik/data/datasources/topik_attempt_sync_dao.dart`:

```dart
import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/logging/app_logger.dart';
import 'package:memox/core/sync/entity_sync_adapter.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_status_model.dart';
import 'package:memox/features/topik/domain/models/topik_level_model.dart';
import 'package:memox/features/topik/domain/models/topik_section_model.dart';

part 'topik_attempt_sync_dao.g.dart';

/// Syncs submitted TOPIK attempts, each with all its answers (TOPIK spec
/// §7.2, §13.2, BR-TOPIK-026). The server keeps them insert-only with a final
/// tombstone, so a pulled attempt is written once and only its version is
/// recorded after that; one in progress never leaves the device.
@DriftAccessor(
  include: {
    'package:memox/core/database/queries/sync_topik_attempt_queries.drift',
  },
)
class TopikAttemptSyncDao extends DatabaseAccessor<AppDatabase>
    with _$TopikAttemptSyncDaoMixin, EntitySyncAdapter {
  TopikAttemptSyncDao(super.attachedDatabase);

  static const type = 'topik_attempt';

  @override
  String get entityType => type;

  @override
  Future<Map<String, Object?>?> readRow(String id) async {
    final a = await syncTopikAttemptRow(id).getSingleOrNull();
    if (a == null) return null;
    return {
      'id': a.id,
      'testId': a.testId,
      'level': a.level,
      'section': a.section,
      'round': a.round,
      'mode': a.mode,
      'status': a.status,
      'startedAt': _time(a.startedAt),
      'completedAt': _time(a.completedAt),
      'updatedAt': _time(a.updatedAt),
      'totalTimeMs': a.totalTimeMs,
      'currentQuestionNo': a.currentQuestionNo,
      'questionCount': a.questionCount,
      'maxScore': a.maxScore,
      'score': a.score,
      'correctCount': a.correctCount,
      'answeredCount': a.answeredCount,
      'contentVersion': a.contentVersion,
      'answers': [
        for (final x in await syncTopikAttemptAnswers(id).get())
          {
            'questionNo': x.questionNo,
            'selectedIdx': x.selectedIdx,
            'timeSpentMs': x.timeSpentMs,
            'answeredAt': _time(x.answeredAt),
            'correctIdx': x.correctIdx,
            'points': x.points,
            'pointsEarned': x.pointsEarned,
            'questionType': x.questionType,
          },
      ],
    };
  }

  @override
  Future<void> upsertFromServer(
    Map<String, Object?> row,
    int serverVersion,
  ) async {
    final id = row['id'] as String;
    if (await syncTopikAttemptExists(id).getSingle()) {
      await acknowledgeTopikAttempt(id, serverVersion);
      return;
    }
    final answers = row['answers'];
    if (!_isKnown(row) || answers is! List) {
      appLogger.warning(
        'topik.sync_skipped',
        category: LogCategory.sync,
        context: {'id': id, 'mode': row['mode'], 'status': row['status']},
      );
      return;
    }
    await insertSyncedTopikAttempt(
      TopikAttemptCompanion.insert(
        id: id,
        testId: row['testId'] as String,
        level: row['level'] as String,
        section: row['section'] as String,
        round: row['round'] as int,
        mode: row['mode'] as String,
        status: row['status'] as String,
        startedAt: fromWireTime(row['startedAt'])!,
        completedAt: Value(fromWireTime(row['completedAt'])),
        updatedAt: fromWireTime(row['updatedAt'])!,
        totalTimeMs: Value(row['totalTimeMs'] as int),
        currentQuestionNo: row['currentQuestionNo'] as int,
        questionCount: row['questionCount'] as int,
        maxScore: row['maxScore'] as int,
        score: Value(row['score'] as int?),
        correctCount: Value(row['correctCount'] as int?),
        answeredCount: Value(row['answeredCount'] as int?),
        contentVersion: row['contentVersion'] as int,
        serverVersion: Value(serverVersion),
      ),
    );
    for (final answer in answers.cast<Map<String, Object?>>()) {
      await insertSyncedTopikAnswer(
        TopikAttemptAnswerCompanion.insert(
          attemptId: id,
          questionNo: answer['questionNo'] as int,
          selectedIdx: Value(answer['selectedIdx'] as int?),
          timeSpentMs: Value(answer['timeSpentMs'] as int),
          answeredAt: Value(fromWireTime(answer['answeredAt'])),
          correctIdx: Value(answer['correctIdx'] as int?),
          points: Value(answer['points'] as int?),
          pointsEarned: Value(answer['pointsEarned'] as int?),
          questionType: Value(answer['questionType'] as String?),
        ),
      );
    }
  }

  @override
  Future<void> deleteFromServer(String id) => deleteSyncedTopikAttempt(id);

  @override
  Future<void> markAcknowledged(String id, int serverVersion) =>
      acknowledgeTopikAttempt(id, serverVersion);

  /// Whether every code of [row] is one this build stores; a newer build's
  /// attempt (Exam mode, a new section) is skipped, not a failed pull.
  static bool _isKnown(Map<String, Object?> row) =>
      TopikLevel.ofCode(row['level']) != null &&
      TopikSection.ofCode(row['section']) != null &&
      TopikAttemptMode.values.any((m) => m.code == row['mode']) &&
      row['status'] == TopikAttemptStatus.completed.code;

  /// Drift stores whole seconds; the wire drops the fraction so a round trip
  /// is exact.
  static String? _time(DateTime? value) =>
      toWireTime(value)?.replaceFirst(RegExp(r'\.\d+Z$'), 'Z');
}
```

If a generated Companion field name or `Value` wrapping differs (a column with a default is `Value<T>`), align to `app_database.g.dart`; the analyzer reports each mismatch.

- [ ] **Step 5: Generate and run the tests**

```bash
dart run build_runner build --delete-conflicting-outputs
bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/topik test/database
```

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/core/database/queries/sync_topik_attempt_queries.drift lib/features/topik/data/datasources/topik_attempt_sync_dao.dart test/features/topik/data/topik_attempt_sync_dao_test.dart
git commit -m "<DEV-n> feat(topik): the attempt sync adapter"
```

---

### Task 3: Register the adapter; two devices converge

**Files:**
- Modify: `lib/app/sync_tables.dart` (register last)
- Modify: `test/core/sync/sync_providers_test.dart` (eight types)
- Test: `test/core/sync/topik_attempt_convergence_test.dart`

**Interfaces:**
- Consumes: `TopikAttemptSyncDao` (Task 2), `TopikAttemptRepositoryImpl` (plan 2), `FakeSyncServer` (`test/core/sync/fake_sync_server.dart`), `SyncCoordinator`.

- [ ] **Step 1: Write the failing tests**

In `test/core/sync/sync_providers_test.dart`, rename the test to `'with the app overrides sync covers the eight tables, parent before child (DEV-173)'` and add `'topik_attempt',` after `'account_settings',` in the expected list.

`test/core/sync/topik_attempt_convergence_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart' show AppDatabase;
import 'package:memox/core/sync/sync_coordinator.dart';
import 'package:memox/core/sync/sync_store.dart';
import 'package:memox/features/topik/data/datasources/topik_attempt_sync_dao.dart';
import 'package:memox/features/topik/data/repositories/topik_attempt_repository_impl.dart';

import '../../support/test_database.dart';
import '../../support/topik_attempt_fixtures.dart';
import '../../support/topik_content_fixtures.dart';
import 'fake_sync_server.dart';

/// TOPIK spec §7.2, BR-TOPIK-026: a submitted attempt reaches every device of
/// the account; one in progress stays on its device; a delete is final.
class _Device {
  _Device(FakeSyncServer server) : db = openTestDatabase() {
    coordinator = SyncCoordinator(
      api: server,
      store: SyncStore(db),
      adapters: [TopikAttemptSyncDao(db)],
    );
    attempts = TopikAttemptRepositoryImpl(db);
  }
  final AppDatabase db;
  late final SyncCoordinator coordinator;
  late final TopikAttemptRepositoryImpl attempts;
}

void main() {
  final test = topikTestFixture();
  late FakeSyncServer server;
  late _Device a;
  late _Device b;

  Future<void> run(List<_Device> order) async {
    for (final device in order) {
      await device.coordinator.runOnce();
    }
  }

  setUp(() {
    server = FakeSyncServer();
    a = _Device(server);
    b = _Device(server);
  });
  tearDown(() async {
    await a.db.close();
    await b.db.close();
  });

  test('a submitted attempt reaches the other device with its answers', () async {
    final attempt = topikOk(await a.attempts.start(test));
    topikOk(
      await a.attempts.answer(
        attemptId: attempt.id,
        questionNo: 1,
        selectedIdx: 1,
        elapsedMs: 800,
      ),
    );
    topikOk(
      await a.attempts.submit(attemptId: attempt.id, test: test, elapsedMs: 0),
    );

    await run([a, b]);

    final copy = (await topikAttemptRow(b.db, attempt.id))!;
    expect(copy.status, 'completed');
    expect(copy.score, 2);
    expect(copy.serverVersion, isNotNull);
    expect(await topikAnswerRows(b.db, attempt.id), hasLength(50));
    expect((await topikAttemptRow(a.db, attempt.id))!.serverVersion, isNotNull);
    expect(await a.db.select(a.db.syncOutbox).get(), isEmpty);
  });

  test('an attempt in progress never leaves its device', () async {
    final attempt = topikOk(await a.attempts.start(test));

    await run([a, b]);

    expect(await topikAttemptRow(b.db, attempt.id), isNull);
    expect(server.row('topik_attempt', attempt.id), isNull);
  });

  test('deleting a submitted attempt removes it everywhere', () async {
    final attempt = topikOk(await a.attempts.start(test));
    topikOk(
      await a.attempts.submit(attemptId: attempt.id, test: test, elapsedMs: 0),
    );
    await run([a, b]);

    topikOk(await a.attempts.delete(attempt.id));
    await run([a, b]);

    expect(await topikAttemptRow(b.db, attempt.id), isNull);
    expect(await topikAnswerRows(b.db, attempt.id), isEmpty);
  });
}
```

(If `FakeSyncServer.row` returns a tombstone object rather than null for a never-pushed id, assert on what it returns for an unknown key; read `fake_sync_server.dart:44` first.)

- [ ] **Step 2: Run them to verify they fail**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/core/sync/sync_providers_test.dart test/core/sync/topik_attempt_convergence_test.dart`
Expected: the providers test FAILS (seven types); the convergence test PASSES already, because it builds its own adapter list — it pins the adapter end to end, not the registration. Record that in the ledger.

- [ ] **Step 3: Register the adapter**

In `lib/app/sync_tables.dart`, import `package:memox/features/topik/data/datasources/topik_attempt_sync_dao.dart` and add `TopikAttemptSyncDao(db),` after `AccountSettingsSyncDao(db),` (no parent: last; spec §13.2). Run `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/architecture` to confirm `lib/app/` may import the feature's data layer, as it does for the others.

- [ ] **Step 4: Run the tests**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/core/sync test/app test/architecture`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/app/sync_tables.dart test/core/sync
git commit -m "<DEV-n> feat(sync): register the TOPIK attempt adapter"
```

---

### Task 4: The Supabase migration and its pgTAP tests

**Files:**
- Create: `supabase/migrations/20261016000000_topik_attempt_sync.sql`
- Create: `supabase/tests/database/17_topik_attempt_sync.sql`
- Modify: `supabase/tests/database/01_schema_privileges.sql` (tables in the RLS/privilege lists)
- Modify: `supabase/tests/database/12_account.sql` (`t_seed` and `t_owned` include an attempt)
- Modify: `supabase/tests/database/15_sync_entity_dispatch.sql` (eight types)

**Interfaces:**
- Produces: `public.topik_attempt`, `public.topik_attempt_answer`, `private.topik_attempt_change`, `private.topik_attempt_consistent`, `private.topik_attempt_upsert`, `private.topik_attempt_delete`; rewritten `private.current_change`, `private.apply_operation`, `private.push_one`, `public.sync_changes`, `private.merge_user_data`.

- [ ] **Step 1: Write the failing pgTAP test**

`supabase/tests/database/17_topik_attempt_sync.sql`:

```sql
begin;
create extension if not exists pgtap with schema extensions;
select plan(13);
-- TOPIK spec 2026-10-15 §7.2, §13.3, BR-TOPIK-026, BR-TOPIK-028: submitted
-- attempts sync insert-only with a final tombstone; the server checks
-- integrity only.
insert into auth.users (id) values
  ('aaaaaaaa-0000-0000-0000-000000000001'), ('bbbbbbbb-0000-0000-0000-000000000002')
on conflict (id) do nothing;

create function public.t_uuid(n int) returns uuid language sql immutable as $$
  select format('00000000-0000-0000-0000-%s', lpad(n::text, 12, '0'))::uuid $$;
-- A submitted two-question attempt: question 1 right (2 points), question 2 unanswered.
create function public.t_attempt(p_id uuid) returns jsonb language sql as $$
  select jsonb_build_object('id', p_id, 'testId', 'topik2-96-reading', 'level', 'topik2',
    'section', 'reading', 'round', 96, 'mode', 'practice', 'status', 'completed',
    'startedAt', '2026-10-15T09:00:00Z', 'completedAt', '2026-10-15T09:10:00Z',
    'updatedAt', '2026-10-15T09:10:00Z', 'totalTimeMs', 5000, 'currentQuestionNo', 2,
    'questionCount', 2, 'maxScore', 4, 'score', 2, 'correctCount', 1, 'answeredCount', 1,
    'contentVersion', 1,
    'answers', jsonb_build_array(
      jsonb_build_object('questionNo', 1, 'selectedIdx', 3, 'timeSpentMs', 3000,
        'answeredAt', '2026-10-15T09:05:00Z', 'correctIdx', 3, 'points', 2, 'pointsEarned', 2,
        'questionType', 'R2_fill_blank'),
      jsonb_build_object('questionNo', 2, 'selectedIdx', null, 'timeSpentMs', 2000,
        'answeredAt', null, 'correctIdx', 1, 'points', 2, 'pointsEarned', 0,
        'questionType', 'R2_fill_blank'))) $$;
create function public.t_op(p_op int, p_type text, p_id uuid, p_kind text, p_row jsonb) returns jsonb
  language sql as $$
  select jsonb_build_object('opId', public.t_uuid(100000 + p_op), 'entityType', p_type,
    'entityId', p_id, 'op', p_kind, 'row', p_row) $$;
create function public.t_push1(p_op jsonb) returns jsonb language sql as $$
  select public.sync_push(jsonb_build_object('deviceId', '00000000-0000-0000-0000-0000000000d1',
    'operations', jsonb_build_array(p_op)))->'results'->0 $$;
create function public.t_change(p_id uuid) returns jsonb language sql as $$
  select c from jsonb_array_elements(public.sync_changes(0, 500)->'changes') c
  where c->>'entityType' = 'topik_attempt' and c->>'entityId' = p_id::text $$;
create function public.t_version(p_user uuid) returns bigint language sql security definer as $$
  select coalesce((select version from public.user_sync_version where user_id = p_user), 0) $$;

set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"aaaaaaaa-0000-0000-0000-000000000001","role":"authenticated"}', true);

select is(public.t_push1(public.t_op(1, 'topik_attempt', public.t_uuid(1), 'upsert',
    public.t_attempt(public.t_uuid(1))))->>'status', 'applied', 'a submitted attempt is applied');
select is(public.t_change(public.t_uuid(1))->'row'->'answers'->0->>'pointsEarned', '2',
  'it reads back with its answers');
select is(public.t_push1(public.t_op(2, 'topik_attempt', public.t_uuid(1), 'upsert',
    public.t_attempt(public.t_uuid(1))))->>'serverVersion',
  public.t_change(public.t_uuid(1))->>'serverVersion',
  'sent again under a new op id it keeps its version');

select is(public.t_push1(public.t_op(3, 'topik_attempt', public.t_uuid(2), 'upsert',
    public.t_attempt(public.t_uuid(2)) || '{"score": 3}'))->>'code', 'VALIDATION_FAILED',
  'a score that is not the sum of the points earned is refused');
select is(public.t_push1(public.t_op(4, 'topik_attempt', public.t_uuid(2), 'upsert',
    jsonb_set(public.t_attempt(public.t_uuid(2)), '{answers,1,questionNo}', '1')))->>'code',
  'VALIDATION_FAILED', 'a question number twice is refused');
select is(public.t_push1(public.t_op(5, 'topik_attempt', public.t_uuid(2), 'upsert',
    public.t_attempt(public.t_uuid(2)) || '{"status": "in_progress"}'))->>'code',
  'VALIDATION_FAILED', 'an attempt in progress is refused');
select is(public.t_push1(public.t_op(6, 'topik_attempt', public.t_uuid(2), 'upsert',
    public.t_attempt(public.t_uuid(2)) || '{"totalTimeMs": 1}'))->>'code',
  'VALIDATION_FAILED', 'a total time that is not the sum of the answers is refused');
select ok(public.t_change(public.t_uuid(2)) is null, 'nothing of the refused attempt is stored');

select is(public.t_push1(public.t_op(7, 'topik_attempt', public.t_uuid(3), 'delete', null))->>'status',
  'applied', 'a delete of an attempt the server never saw is acknowledged');
select ok(public.t_change(public.t_uuid(3)) is null, 'and leaves no tombstone');

select is(public.t_push1(public.t_op(8, 'topik_attempt', public.t_uuid(1), 'delete', null))->>'status',
  'applied', 'a delete tombstones the attempt');
select is(public.t_push1(public.t_op(9, 'topik_attempt', public.t_uuid(1), 'upsert',
    public.t_attempt(public.t_uuid(1))))->>'code', 'ENTITY_TOMBSTONED',
  'an upsert onto the tombstone is refused');

-- The wire of the previous slice still applies (server sync spec §4).
select is(public.t_push1(public.t_op(10, 'deck', public.t_uuid(20), 'upsert',
    jsonb_build_object('id', public.t_uuid(20), 'name', 'Root', 'parentId', null,
      'rootId', public.t_uuid(20), 'depth', 1, 'contentType', 'deck', 'schedulerType', 'eight_box',
      'schedulerVersion', 1, 'schedulerConfig', '{}', 'studyConfig', '{}', 'generation', 1,
      'firstAnsweredAt', null, 'sourceTemplateId', null, 'sourceTemplateVersion', null,
      'deleteBatchId', null, 'siblingPosition', 0, 'createdAt', '2026-10-15T00:00:00Z',
      'updatedAt', '2026-10-15T00:00:00Z')))->>'status', 'applied',
  'a deck push of the previous wire is still applied');

select * from finish();
rollback;
```

(Copy the deck row of `08_study_history_sync.sql`'s `t_root` if a key differs. User B and `SYNC_ENTITY_CONFLICT` are covered once the account fixture in `12_account.sql` includes an attempt; add a 14th assertion here if a cross-user push is cheap to set up.)

- [ ] **Step 2: Run it to verify it fails**

```bash
SUPABASE_INTERNAL_IMAGE_REGISTRY=docker.io npx --yes supabase db start
SUPABASE_INTERNAL_IMAGE_REGISTRY=docker.io npx --yes supabase test db
```

Expected: `17_topik_attempt_sync.sql` FAILS (`SYNC_ENTITY_UNSUPPORTED`).

- [ ] **Step 3: Write the migration**

`supabase/migrations/20261016000000_topik_attempt_sync.sql`:

```sql
-- TOPIK spec 2026-10-15 §7.2, §13.3 (ADR-023 #6, BR-TOPIK-026, BR-TOPIK-028):
-- submitted TOPIK attempts sync as insert-only records with a final
-- tombstone. The server checks integrity only; scoring stays in the app
-- (ADR-015). One entity type, topik_attempt; its answers ride in the row.

create table public.topik_attempt (
  id uuid primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  test_id text not null,
  level text not null check (level in ('topik1', 'topik2')),
  section text not null check (section in ('listening', 'reading')),
  round integer not null check (round > 0),
  mode text not null check (mode in ('practice')),
  status text not null check (status = 'completed'),
  started_at timestamptz not null,
  completed_at timestamptz not null,
  updated_at timestamptz not null,
  total_time_ms integer not null check (total_time_ms >= 0),
  current_question_no integer not null,
  question_count integer not null check (question_count > 0),
  max_score integer not null check (max_score > 0),
  score integer not null,
  correct_count integer not null,
  answered_count integer not null,
  content_version integer not null check (content_version > 0),
  server_version bigint not null,
  last_device_id uuid not null,
  deleted_at timestamptz null,
  check (score between 0 and max_score),
  check (answered_count between 0 and question_count),
  check (correct_count between 0 and answered_count)
);
create unique index uq_topik_attempt_user_version on public.topik_attempt (user_id, server_version);

-- Part of the attempt's row; not a sync entity, so no version (as card_tags).
create table public.topik_attempt_answer (
  attempt_id uuid not null references public.topik_attempt (id) on delete cascade,
  question_no integer not null check (question_no > 0),
  selected_idx integer check (selected_idx between 1 and 4),
  time_spent_ms integer not null check (time_spent_ms >= 0),
  answered_at timestamptz,
  correct_idx integer not null check (correct_idx between 1 and 4),
  points integer not null check (points > 0),
  points_earned integer not null,
  question_type text not null,
  check ((selected_idx is null) = (answered_at is null)),
  check (points_earned = case when selected_idx = correct_idx then points else 0 end),
  primary key (attempt_id, question_no)
);

alter table public.topik_attempt enable row level security;
alter table public.topik_attempt_answer enable row level security;
revoke all on table public.topik_attempt, public.topik_attempt_answer from public, anon, authenticated;

create function private.topik_attempt_change(a public.topik_attempt) returns jsonb
language sql stable set search_path = '' as $$
  select jsonb_build_object(
    'entityType', 'topik_attempt', 'entityId', a.id, 'serverVersion', a.server_version,
    'deleted', a.deleted_at is not null,
    'row', case when a.deleted_at is not null then null else jsonb_build_object(
      'id', a.id, 'testId', a.test_id, 'level', a.level, 'section', a.section, 'round', a.round,
      'mode', a.mode, 'status', a.status, 'startedAt', private.wire_time(a.started_at),
      'completedAt', private.wire_time(a.completed_at), 'updatedAt', private.wire_time(a.updated_at),
      'totalTimeMs', a.total_time_ms, 'currentQuestionNo', a.current_question_no,
      'questionCount', a.question_count, 'maxScore', a.max_score, 'score', a.score,
      'correctCount', a.correct_count, 'answeredCount', a.answered_count,
      'contentVersion', a.content_version,
      'answers', (select coalesce(jsonb_agg(jsonb_build_object(
          'questionNo', x.question_no, 'selectedIdx', x.selected_idx,
          'timeSpentMs', x.time_spent_ms, 'answeredAt', private.wire_time(x.answered_at),
          'correctIdx', x.correct_idx, 'points', x.points, 'pointsEarned', x.points_earned,
          'questionType', x.question_type) order by x.question_no), '[]'::jsonb)
        from public.topik_attempt_answer x where x.attempt_id = a.id)) end)
$$;

-- BR-TOPIK-028: the stored snapshot adds up over the stored answers.
create function private.topik_attempt_consistent(p_id uuid) returns boolean
language sql stable set search_path = '' as $$
  select a.question_count = s.n and a.max_score = s.points and a.score = s.earned
     and a.correct_count = s.correct and a.answered_count = s.answered
     and a.total_time_ms = s.time_ms
  from public.topik_attempt a,
  lateral (select count(*) as n, coalesce(sum(x.points), 0) as points,
             coalesce(sum(x.points_earned), 0) as earned,
             count(*) filter (where x.selected_idx = x.correct_idx) as correct,
             count(*) filter (where x.selected_idx is not null) as answered,
             coalesce(sum(x.time_spent_ms), 0) as time_ms
           from public.topik_attempt_answer x where x.attempt_id = a.id) s
  where a.id = p_id
$$;

-- Insert-only: the same id of the same user is acknowledged with its own
-- version; a tombstone is final (server sync spec §5).
create function private.topik_attempt_upsert(p_user uuid, p_device uuid, p_id uuid, r jsonb) returns bigint
language plpgsql set search_path = '' as $$
declare
  v_existing public.topik_attempt;
  v_answers jsonb := r->'answers';
  v_version bigint;
begin
  if (r->>'id')::uuid is distinct from p_id or jsonb_typeof(v_answers) is distinct from 'array' then
    raise exception 'VALIDATION_FAILED';
  end if;
  select * into v_existing from public.topik_attempt where id = p_id for update;
  if found then
    if v_existing.user_id <> p_user then
      raise exception 'SYNC_ENTITY_CONFLICT';
    end if;
    if v_existing.deleted_at is not null then
      raise exception 'ENTITY_TOMBSTONED';
    end if;
    return v_existing.server_version;
  end if;
  if (select count(distinct a->>'questionNo') from jsonb_array_elements(v_answers) a)
      <> jsonb_array_length(v_answers) then
    raise exception 'VALIDATION_FAILED';
  end if;
  v_version := private.allocate_versions(p_user, 1);
  insert into public.topik_attempt (id, user_id, test_id, level, section, round, mode, status,
    started_at, completed_at, updated_at, total_time_ms, current_question_no, question_count,
    max_score, score, correct_count, answered_count, content_version, server_version, last_device_id)
  values (p_id, p_user, r->>'testId', r->>'level', r->>'section', (r->>'round')::integer,
    r->>'mode', r->>'status', (r->>'startedAt')::timestamptz, (r->>'completedAt')::timestamptz,
    (r->>'updatedAt')::timestamptz, (r->>'totalTimeMs')::integer,
    (r->>'currentQuestionNo')::integer, (r->>'questionCount')::integer, (r->>'maxScore')::integer,
    (r->>'score')::integer, (r->>'correctCount')::integer, (r->>'answeredCount')::integer,
    (r->>'contentVersion')::integer, v_version, p_device);
  insert into public.topik_attempt_answer (attempt_id, question_no, selected_idx, time_spent_ms,
    answered_at, correct_idx, points, points_earned, question_type)
  select p_id, (a->>'questionNo')::integer, (a->>'selectedIdx')::integer,
    (a->>'timeSpentMs')::integer, (a->>'answeredAt')::timestamptz, (a->>'correctIdx')::integer,
    (a->>'points')::integer, (a->>'pointsEarned')::integer, a->>'questionType'
  from jsonb_array_elements(v_answers) a;
  if not private.topik_attempt_consistent(p_id) then
    raise exception 'VALIDATION_FAILED';
  end if;
  return v_version;
end
$$;

-- A final tombstone, as tag_delete; the answers go physically.
create function private.topik_attempt_delete(p_user uuid, p_device uuid, p_id uuid) returns bigint
language plpgsql set search_path = '' as $$
declare
  v_existing public.topik_attempt;
  v_version bigint;
begin
  select * into v_existing from public.topik_attempt where id = p_id for update;
  if not found then
    return private.current_version(p_user);
  end if;
  if v_existing.user_id <> p_user then
    raise exception 'SYNC_ENTITY_CONFLICT';
  end if;
  if v_existing.deleted_at is not null then
    return v_existing.server_version;
  end if;
  delete from public.topik_attempt_answer where attempt_id = p_id;
  v_version := private.allocate_versions(p_user, 1);
  update public.topik_attempt set deleted_at = now(), server_version = v_version, last_device_id = p_device
  where id = p_id;
  return v_version;
end
$$;
```

Then append the five rewritten functions, each copied **in full** from its latest definition and extended:

1. `private.current_change` from `20261002000000_study_history_sync.sql`: add `v_topik public.topik_attempt;` to `declare`, and before `return null;`:

```sql
  if p_type = 'topik_attempt' then
    select * into v_topik from public.topik_attempt where id = p_id and user_id = p_user;
    if found then
      return private.topik_attempt_change(v_topik);
    end if;
  end if;
```

2. `private.apply_operation` from `20261011000000_trash_purge_rules.sql` (the one whose `deck_delete` and `card_delete` take `p_row`): in the upsert branch after `card_schedule`:

```sql
    if p_type = 'topik_attempt' then
      return private.topik_attempt_upsert(p_user, p_device, p_id, p_row);
    end if;
```

and in the delete branch after `tag`:

```sql
    if p_type = 'topik_attempt' then
      return private.topik_attempt_delete(p_user, p_device, p_id);
    end if;
```

3. `private.push_one` from `20261002000000_study_history_sync.sql`: the accepted list becomes `('deck', 'delete_batch', 'card', 'tag', 'account_settings', 'review_log', 'card_schedule', 'topik_attempt')`.

4. `public.sync_changes` from `20261014000000_sync_requires_profile.sql` (it starts with `private.require_current_profile()`): add a union branch after `review_log`:

```sql
      union all
      (select 'topik_attempt', ta.id, ta.server_version from public.topik_attempt ta
       where ta.user_id = v_user and ta.server_version > v_since
       order by ta.server_version limit v_limit + 1)
```

5. `private.merge_user_data` from `20261010000000_accounts.sql`: add `+ (select count(*) from public.topik_attempt where user_id = p_source)` to `v_total`, and after the `review_log` update:

```sql
    update public.topik_attempt x set user_id = p_target, server_version = v_next + s.n
    from (select id, row_number() over (order by server_version) as n
          from public.topik_attempt where user_id = p_source) s
    where x.id = s.id;
    get diagnostics v_rows = row_count; v_next := v_next + v_rows;
```

End the file with `revoke all on all functions in schema private from public, anon, authenticated;` as the previous migrations do.

- [ ] **Step 4: Update the pinned tests**

- `01_schema_privileges.sql`: add `has_table('public', 'topik_attempt', …)` and `has_table('public', 'topik_attempt_answer', …)` (raise `plan(n)` by 2), and add both names to the three `in (...)` lists of RLS-on / no-policy / no-privilege tables.
- `15_sync_entity_dispatch.sql`: the expected array becomes `array['account_settings', 'card', 'card_schedule', 'deck', 'delete_batch', 'review_log', 'tag', 'topik_attempt']` and the description "the eight synced entity types". The delete-branch assertion already removes only `account_settings`.
- `12_account.sql`: in `t_seed`, insert one completed attempt with one answer for `p_user` (version `v_base + 9`; raise the other base offsets if `t_seed` reserves fewer than 9 versions per user), and add `+ (select count(*) from public.topik_attempt where user_id = p_user)` to `t_owned`. Re-read the merge assertions: their expected counts grow by one where they count the source's or target's rows.

- [ ] **Step 5: Run the database tests**

```bash
SUPABASE_INTERNAL_IMAGE_REGISTRY=docker.io npx --yes supabase db reset
SUPABASE_INTERNAL_IMAGE_REGISTRY=docker.io npx --yes supabase test db
```

Expected: `Result: PASS`, 17 files.

- [ ] **Step 6: Commit**

```bash
git add supabase/migrations/20261016000000_topik_attempt_sync.sql supabase/tests/database
git commit -m "<DEV-n> feat(supabase): sync submitted TOPIK attempts"
```

---

### Task 5: Docs and the gates

**Files:**
- Modify: `docs/superpowers/specs/2026-09-27-server-sync-design.md` (contract keys, conflict rules)
- Modify: `docs/superpowers/specs/2026-10-15-topik-practice-design.md` (§13.3 migration file name as built)
- Modify: `docs/features/topik/README.md` (`code:` adds the sync DAO's queries)

- [ ] **Step 1: Document**

- Server sync spec §4, contract keys table: add a row `| \`topik_attempt\` | \`id\`, \`testId\`, \`level\`, \`section\`, \`round\`, \`mode\`, \`status\`, \`startedAt\`, \`completedAt\`, \`updatedAt\`, \`totalTimeMs\`, \`currentQuestionNo\`, \`questionCount\`, \`maxScore\`, \`score\`, \`correctCount\`, \`answeredCount\`, \`contentVersion\`, \`answers\` (each: \`questionNo\`, \`timeSpentMs\`, \`correctIdx\`, \`points\`, \`pointsEarned\`, \`questionType\`) |`.
- Server sync spec §5: add a row `| \`topik_attempt\` (with its answers) | Append-only with a final tombstone. Insert-if-absent by \`id\`; an existing id is \`applied\` without change; a delete tombstones it and an upsert onto the tombstone is refused (\`ENTITY_TOMBSTONED\`). Integrity only (BR-TOPIK-028): counts, sums and unique question numbers, else \`VALIDATION_FAILED\`. An attempt in progress never syncs |`.
- TOPIK spec §13.3: replace `2026101X000000_topik_attempt_sync.sql` with `20261016000000_topik_attempt_sync.sql`.
- Feature README `code:`: add `lib/core/database/queries/sync_topik_attempt_queries.drift`.

- [ ] **Step 2: Run every gate**

```bash
python3 tools/docs/check.py
bash .claude/skills/flutter-workflow/scripts/dod_check.sh
SUPABASE_INTERNAL_IMAGE_REGISTRY=docker.io npx --yes supabase test db
SUPABASE_INTERNAL_IMAGE_REGISTRY=docker.io bash tools/supabase/run_auth_it.sh
```

Expected: all PASS. If `run_auth_it.sh` cannot pull an image through the proxy, record the exact error as a blocker in the PR and on the issue; do not report it as run.

- [ ] **Step 3: Commit**

```bash
git add docs
git commit -m "<DEV-n> docs(sync): the topik_attempt contract and conflict rule"
```

## Plan-time rulings

| # | Ruling | Why |
|---|---|---|
| S1 | The server table holds only completed attempts (`status = 'completed'` CHECK) and keeps `current_question_no`. | §7.2: only completed attempts sync; the local column is NOT NULL, so a pulled row needs it. |
| S2 | Duplicate question numbers are caught before the insert and raise `VALIDATION_FAILED`, not the primary key's `unique_violation` (`CONFLICT`). | BR-TOPIK-028 names it an integrity check; `CONFLICT` means something else on the wire. |
| S3 | A pulled attempt the device already has records its version only (existence check, then `INSERT`), never `INSERT OR REPLACE`. | The immutability trigger and the plan-2 final review. |
| S4 | The adapter skips a pulled attempt with an unknown code (plan 2 R4) and logs `topik.sync_skipped`. | Forward compatibility with Phase B (`exam`) and Phase C (writing). |
| S5 | Migration date `20261016000000`, the day after the last released one. | Ordering after `20261015000000_account_settings_log_sql.sql`. |

## Out of this plan

Statistics, use cases and the duration formatter (plan 4); audio (plan 5); screens (plan 6), whose entry criterion is that this plan is merged (plan 2 R1).

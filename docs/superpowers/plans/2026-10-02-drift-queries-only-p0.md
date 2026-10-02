# Every query in `.drift`, P0 (foundation and pilot) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Put ADR-020 in force: the guard rejects new SQL strings and builder chains outside `.drift`, the skills say so, and two DAOs (`AccountDeviceDao`, `TrashDao`) show the target shape as `@DriftAccessor`s.

**Architecture:** A guard regex rule, `memox.data_model.queries_in_drift`, runs on a new scope, `drift_query_sites`. The scope's exclude list holds the files not yet migrated and shrinks with each phase. Each pilot DAO becomes `@DriftAccessor(include: {queries/x.drift})` and calls the methods Drift generates. Its constructor stays `XDao(db)`, so repositories and providers do not change.

**Tech Stack:** Flutter 3.47.5, Drift 2.35 (`.drift` files, `drift_dev`), Python 3.12 guard (`code-verification-guard-v2`, pytest).

**Spec:** `docs/superpowers/specs/2026-10-01-drift-queries-only-design.md` (§5 is P0).

## Global Constraints

- Behaviour-preserving refactor. No schema change, no `schemaVersion` bump, no migration, no index change.
- DAO public method names stay as they are, so callers do not change (renames are out of scope).
- Generated `*.g.dart` files are not committed. Run `dart run build_runner build --delete-conflicting-outputs` after every `.drift` or `@DriftAccessor` change.
- Commit messages follow the repo's `type(scope): summary` style and end with the session attribution lines.
- Docs, ADRs and WBS are in Vietnamese. Skills, specs and code comments are in English (repo convention).
- On Linux run the full suite as `TZ=UTC flutter test --exclude-tags golden`. Never pass `--update-goldens`.

## Review Focus

1. **Trash list after a purge through generated SQL.** The list must still re-emit when a batch is purged, because the cascade to `deck`/`card` must still notify. This is pinned by the existing `trash_entries_test.dart` ('the list follows a delete, a restore and a purge'), which Task 4 runs.
2. **Purge candidates with a stale choice.** A chosen id that no longer exists, a chosen batch not yet expired, an expired batch not chosen, and two batches deleted at the same second must come back as one ordered set by `(deleted_at, id)`. Task 4, Step 1.
3. **Library counts with Trash in the tree.** A deck in the Trash, and a live card whose deck is in the Trash, are not counted. Task 3, Step 1.
4. **Guard false positives in `lib/core`.** A method named `delete(String key)`, `_storage.delete(key: key)`, `list.join(', ')` and a `PRAGMA` must not trip the rule. Task 2, Step 1 test, plus the full guard run in Task 2, Step 6.
5. **A migrated file slipping back.** Once a file leaves the exclude list it must never be re-added. Task 2's scope test pins the migrated set, and Tasks 3 and 4 extend it.

---

### Task 1: ADR-020

**Files:**
- Create: `docs/shared/decisions/ADR-020-moi-truy-van-nam-trong-drift.md`

**Interfaces:**
- Produces: the ADR id `ADR-020` and its path, which later tasks cite.

- [ ] **Step 1: Write the ADR**

```markdown
---
id: ADR-020
title: Mọi truy vấn SQLite nằm trong file .drift; DAO là @DriftAccessor
status: active
superseded_by:
---
## Bối cảnh

Rà soát master `8aaa29c` (2026-10-01): `lib/core/database/queries/` chỉ có 15 query
đặt tên, trong khi 82 lời gọi truyền SQL dạng chuỗi Dart (`customSelect`,
`customUpdate`, `customInsert`, `customStatement`) và khoảng 120 lời gọi dùng query
builder của Drift (`select(…)..where`, `update(…).write`, `into(…).insert`, join,
`batch`) nằm rải trong khoảng 26 file DAO, `core/sync`, `core/auth`, `core/notes`.
Một DAO có thể đọc qua ba cách khác nhau, SQL của một màn không có một chỗ duy nhất
để tìm, review hay kiểm tra; `readsFrom`/`updates` của chuỗi SQL phải khai tay.

## Quyết định

- Mọi truy vấn, đọc lẫn ghi, viết trong file `.drift` dưới
  `lib/core/database/queries/`, đặt tên theo chủ đề dữ liệu.
- Mỗi DAO là `@DriftAccessor(include: {…})`, `extends DatabaseAccessor<AppDatabase>`,
  khởi tạo `XDao(db)`. DAO gọi method Drift sinh ra; một file `.drift` có thể được
  nhiều DAO include; DAO không gọi DAO khác.
- `@DriftDatabase` chỉ include `tables/*.drift`.
- Query builder của Drift chỉ còn dùng để dựng `Expression`/`OrderingTerm` truyền
  vào chỗ `$predicate`/`$order` của một query `.drift`.
- Ngoại lệ, chỉ ba chỗ được giữ SQL trong Dart: code migration (`onUpgrade` trong
  `app_database.dart`, `core/database/migrations/**`), `customStatement('PRAGMA …')`,
  và `core/database/local_data_reset.dart`.
- Log database chuyển sang `core/database/log/log.drift`.
- Guard rule `memox.data_model.queries_in_drift` giữ quy tắc này; danh sách file
  chưa chuyển nằm trong exclude tạm của scope `drift_query_sites` và co lại theo
  từng phase.

Thiết kế và các phase: [spec](../../superpowers/specs/2026-10-01-drift-queries-only-design.md).

## Hệ quả

- `drift_dev` kiểm tra mọi câu SQL với schema lúc build và tự sinh `readsFrom`/
  `updates`; stream không còn im vì khai thiếu bảng.
- Một stream cần phát lại theo bảng mà câu SQL không đọc giữ hành vi đó bằng
  `tableChanges(...)` trong DAO, có test chứng minh.
- `batch(...insertAll...)` trong sync thành vòng lặp gọi query upsert trong cùng
  transaction; P7 đo trước và sau.
- Rollback: chuyển include của một accessor về `@DriftDatabase`; không đổi schema.
```

- [ ] **Step 2: Check document integrity**

Run: `python3 tools/docs/check.py`
Expected: `PASS — 0 error(s)` (warnings that already existed are fine).

- [ ] **Step 3: Commit**

```bash
git add docs/shared/decisions/ADR-020-moi-truy-van-nam-trong-drift.md
git commit -m "docs(adr): ADR-020 every query lives in .drift, DAOs are accessors"
```

---

### Task 2: Guard rule, scope, probes, and the `check_drift` noise fix

**Files:**
- Modify: `code-verification-guard-v2/registries/projects/memox-v8/rules/memox-data-model-rules.yaml` (append one rule)
- Modify: `code-verification-guard-v2/registries/projects/memox-v8/config/scopes.yaml` (add scope after `drift_sql_files`)
- Test: `code-verification-guard-v2/tests/test_memox_v8_data_model_guard_rules.py` (append)
- Modify: `.claude/skills/flutter-drift/scripts/check_drift.py:76-80`

**Interfaces:**
- Produces: rule id `memox.data_model.queries_in_drift`; scope `drift_query_sites`; the Python constant `MIGRATED_TO_DRIFT` in the test file, which Tasks 3 and 4 extend.

- [ ] **Step 1: Write the failing probes**

Append to `code-verification-guard-v2/tests/test_memox_v8_data_model_guard_rules.py`:

```python
QUERIES_IN_DRIFT = "memox.data_model.queries_in_drift"

SCOPES_PATH = (
    Path(__file__).parents[1]
    / "registries"
    / "projects"
    / "memox-v8"
    / "config"
    / "scopes.yaml"
)

# ADR-020: files that have moved to `.drift` and must never return to the
# scope's temporary exclude. Each phase adds the files it migrates.
MIGRATED_TO_DRIFT: tuple[str, ...] = ()

# The exceptions ADR-020 grants for good, which no phase removes.
PERMANENT_EXCLUDES = (
    "**/*.g.dart",
    "lib/core/database/schema_versions.dart",
    "lib/core/database/migrations/**",
    "lib/core/database/app_database.dart",
    "lib/core/database/local_data_reset.dart",
)


def test_queries_in_drift_goes_red_on_sql_strings_and_builder_chains(tmp_path: Path) -> None:
    for bad in (
        "    final row = await _db.customSelect('SELECT 1').getSingle();\n",
        "        .customSelect(\n",
        "    await _db.customUpdate(\n",
        "    await customInsert('INSERT INTO t VALUES (1)');\n",
        "    await _db.customStatement('DELETE FROM sync_outbox');\n",
        "      (_db.select(_db.card)..where((c) => c.id.equals(id))).getSingle();\n",
        "    final byId = await (_db.select(\n",
        "      .into(_db.card)\n",
        "      (_db.update(_db.appSettings)\n",
        "    await (select(logEntries)..limit(1)).get();\n",
        "    final query = selectOnly(logEntries)\n",
        "    (delete(logEntries)..where((t) => t.id.isIn(ids))).go();\n",
        "        _db.select(_card).join([\n",
        "    await _db.batch((b) => b.insertAll(_db.card, rows));\n",
    ):
        assert _violations(QUERIES_IN_DRIFT, tmp_path, DAO, bad), bad


def test_queries_in_drift_leaves_generated_queries_pragmas_and_predicates_alone(
    tmp_path: Path,
) -> None:
    good = """
  /// Reads through `customSelect` were the old shape; ADR-020 moved them.
  // await _db.customSelect('SELECT 1');
  Future<List<TrashDeckEntryRow>> deckEntryRows() => trashDeckEntries().get();
  Future<void> purge(String batchId) => purgeDeleteBatch(batchId);
  Stream<void> entryChanges() =>
      tableChanges(attachedDatabase, [attachedDatabase.deleteBatches]);
  Future<void> defer() => _db.customStatement('PRAGMA defer_foreign_keys = ON');
  Expression<bool> _predicate(Card c) => c.deckId.equals(deckId) & c.deleteBatchId.isNull();
  Future<void> delete(String key) => _storage.delete(key: key);
  final names = parts.join(', ');
"""
    assert not _violations(QUERIES_IN_DRIFT, tmp_path, DAO, good)


def _scope(name: str) -> dict:
    return yaml.safe_load(SCOPES_PATH.read_text(encoding="utf-8"))["scopes"][name]


def test_drift_query_sites_keeps_adr_020_exceptions_and_never_readmits_a_migrated_file() -> None:
    scope = _scope("drift_query_sites")
    excluded = set(scope["exclude"])

    assert set(PERMANENT_EXCLUDES) <= excluded
    assert excluded.isdisjoint(MIGRATED_TO_DRIFT)
```

- [ ] **Step 2: Run the probes to see them fail**

Run: `cd code-verification-guard-v2 && python3 -m pytest -q tests/test_memox_v8_data_model_guard_rules.py -k "queries_in_drift or drift_query_sites"`
Expected: FAIL with `AssertionError: Rule not found: memox.data_model.queries_in_drift` and `KeyError: 'drift_query_sites'`.

- [ ] **Step 3: Add the scope**

In `code-verification-guard-v2/registries/projects/memox-v8/config/scopes.yaml`, directly after the `drift_sql_files:` block:

```yaml
  # ADR-020: where a query may not be written outside `.drift`. The first five
  # excludes are the ADR's exceptions and stay. The rest are the files not yet
  # migrated (spec 2026-10-01-drift-queries-only-design.md §4): each phase
  # removes its own, P8 deletes the block. Never add a file back.
  drift_query_sites:
    include:
      - lib/features/*/data/**/*.dart
      - lib/core/**/*.dart
    exclude:
      - '**/*.g.dart'
      - lib/core/database/schema_versions.dart
      - lib/core/database/migrations/**
      - lib/core/database/app_database.dart
      - lib/core/database/local_data_reset.dart
      # ---- not yet migrated (temporary) ----
      - lib/core/auth/account_store.dart
      - lib/core/database/log/log_database.dart
      - lib/core/notes/dismissed_note_store.dart
      - lib/core/sync/account_settings_sync_adapter.dart
      - lib/core/sync/card_schedule_sync_adapter.dart
      - lib/core/sync/card_sync_adapter.dart
      - lib/core/sync/deck_sync_adapter.dart
      - lib/core/sync/delete_batch_sync_adapter.dart
      - lib/core/sync/review_log_sync_adapter.dart
      - lib/core/sync/sync_store.dart
      - lib/core/sync/tag_sync_adapter.dart
      - lib/features/account/data/datasources/account_device_dao.dart
      - lib/features/card/data/datasources/card_dao.dart
      - lib/features/card/data/datasources/card_list_dao.dart
      - lib/features/deck/data/datasources/deck_dao.dart
      - lib/features/progress/data/datasources/progress_dao.dart
      - lib/features/search/data/datasources/search_dao.dart
      - lib/features/settings/data/datasources/settings_dao.dart
      - lib/features/srs/data/datasources/srs_dao.dart
      - lib/features/starter_decks/data/datasources/starter_dao.dart
      - lib/features/study/data/datasources/study_queue_dao.dart
      - lib/features/study/data/datasources/study_round_dao.dart
      - lib/features/study/data/datasources/study_session_dao.dart
      - lib/features/study/data/datasources/study_view_dao.dart
      - lib/features/tags/data/datasources/tag_dao.dart
      - lib/features/trash/data/datasources/trash_dao.dart
```

- [ ] **Step 4: Add the rule**

Append to `rules:` in `code-verification-guard-v2/registries/projects/memox-v8/rules/memox-data-model-rules.yaml`:

```yaml
  # ADR-020: every query lives in a `.drift` file and the DAO, a
  # @DriftAccessor, calls what Drift generates from it. A SQL string and a
  # builder chain are both off the convention. The builder stays only to build
  # an Expression for a `$predicate` / `$order` placeholder, which no pattern
  # here matches. The scope carries the exceptions; a PRAGMA is allowed
  # anywhere. Patterns are line-anchored with this file's comment exemption.
  # A builder call is caught three ways because a chain splits across lines:
  # on a database receiver, bare inside an accessor (a lowercase table
  # argument, which keeps a `delete(String key)` declaration legal), or as a
  # `.into(` / `.select(` link whose argument is a database table.
  - id: memox.data_model.queries_in_drift
    type: regex
    severity: error
    enabled: true
    message: >-
      ADR-020 — write the query in a `.drift` file under
      lib/core/database/queries/ and call the method Drift generates on the
      DAO (a @DriftAccessor). No SQL in a Dart string, no
      select/selectOnly/update/delete/into/join/batch builder chain; the
      builder only builds an Expression for `$predicate` / `$order`.
    scopes:
      - drift_query_sites
    patterns:
      - '^(?!\s*(?://|\*)).*\bcustom(?:Select|Update|Insert|Statement|WriteReturning)\s*\((?!\s*''PRAGMA)'
      - '^(?!\s*(?://|\*)).*\b(?:_db|db|attachedDatabase)\s*\.\s*(?:select|selectOnly|update|delete|into)\s*\('
      - '^(?!\s*(?://|\*)).*(?<![\w$.])(?:select|selectOnly|update|delete|into)\s*\(\s*(?:[a-z_]\w*\s*[,)]|$)'
      - '^(?!\s*(?://|\*)).*\.(?:select|selectOnly|update|delete|into)\s*\(\s*(?:_db|db|attachedDatabase)\.'
      - '^(?!\s*(?://|\*)).*\.join\s*\(\s*\['
      - '^(?!\s*(?://|\*)).*\bbatch\s*\(\s*\('
    tags:
      - memox
      - data-model
      - convention
    fix:
      hint: >-
        Add a named query to the topic's `.drift` file, include that file in
        the DAO's @DriftAccessor, and call the generated method (ADR-020).
```

- [ ] **Step 5: Run the probes and the guard's own suite**

Run: `cd code-verification-guard-v2 && python3 -m pytest -q`
Expected: all pass, including the three new tests.

- [ ] **Step 6: Run the guard on the repo, then prove it bites**

Run: `python3 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8`
Expected: no `queries_in_drift` finding. Every flagged file is in the exclude list, and the rule has no false positives elsewhere in `lib/core` or `lib/features/*/data`.

Then add `  Future<void> probe() => _db.customStatement('DELETE FROM card');` to `lib/features/card/data/datasources/card_detail_dao.dart` (in scope, not excluded) and rerun. Expected: one `memox.data_model.queries_in_drift` error on that line. Remove the line.

- [ ] **Step 7: Silence `check_drift` on the generated schema steps**

In `.claude/skills/flutter-drift/scripts/check_drift.py`, replace:

```python
GENERATED_SUFFIXES = (".g.dart", ".freezed.dart", ".drift.dart")


def is_generated(path: Path) -> bool:
    return path.name.endswith(GENERATED_SUFFIXES)
```

with:

```python
GENERATED_SUFFIXES = (".g.dart", ".freezed.dart", ".drift.dart")
# `drift_dev schema steps` writes this file and it is committed, but it is as
# generated as a `.g.dart`: 19 interpolation ERRORs in it were noise.
GENERATED_FILES = ("lib/core/database/schema_versions.dart",)


def is_generated(path: Path) -> bool:
    return path.name.endswith(GENERATED_SUFFIXES) or rel(path) in GENERATED_FILES
```

Run: `bash .claude/skills/flutter-drift/scripts/check_drift.sh | grep -c schema_versions`
Expected: `0`.

- [ ] **Step 8: Commit**

```bash
git add code-verification-guard-v2/registries/projects/memox-v8 code-verification-guard-v2/tests/test_memox_v8_data_model_guard_rules.py .claude/skills/flutter-drift/scripts/check_drift.py
git commit -m "feat(guard): queries_in_drift keeps every query in .drift (ADR-020)"
```

---

### Task 3: Pilot `AccountDeviceDao` as an accessor

**Files:**
- Create: `lib/core/database/queries/account_device_queries.drift`
- Modify: `lib/features/account/data/datasources/account_device_dao.dart` (whole file)
- Modify: `code-verification-guard-v2/registries/projects/memox-v8/config/scopes.yaml` (remove one exclude line)
- Modify: `code-verification-guard-v2/tests/test_memox_v8_data_model_guard_rules.py` (`MIGRATED_TO_DRIFT`)
- Test: `test/features/account/data/account_device_repository_impl_test.dart`

**Interfaces:**
- Consumes: scope `drift_query_sites` and `MIGRATED_TO_DRIFT` from Task 2.
- Produces: `AccountDeviceDao(AppDatabase db)` with unchanged `welcomeSeen()`, `setWelcomeSeen()` and `liveCounts() -> Future<(int, int)>`; generated `welcomeSeenFlag(int rowId)`, `markWelcomeSeen(int rowId)` and `liveLibraryCounts() -> Selectable<LiveLibraryCountsRow>`.

- [ ] **Step 1: Characterization test for the Trash in the counts**

Add to `test/features/account/data/account_device_repository_impl_test.dart`, inside `main()` after the last test:

```dart
  test('a deck in the Trash, and every card under it, is not counted', () async {
    final decks = DeckRepositoryImpl(db);
    final korean = await decks.root('Korean');
    final english = await decks.root('English');
    await insertCard(db, id: 'c1', deckId: korean.id);
    await insertCard(db, id: 'c2', deckId: english.id);
    await decks.deleteDeck(deckId: english.id);

    final library = await repository.countLibrary();

    expect((library.decks, library.cards), (1, 1));
  });
```

- [ ] **Step 2: Run it against the current code**

Run: `TZ=UTC flutter test test/features/account/data/account_device_repository_impl_test.dart`
Expected: PASS (5 tests). It pins today's behaviour before the code moves. If it fails, stop: the fixture is wrong, not the DAO.

- [ ] **Step 3: Write the queries**

Create `lib/core/database/queries/account_device_queries.drift`:

```sql
import '../tables/settings.drift';
import '../tables/deck.drift';
import '../tables/card.drift';

-- Whether this device has answered Welcome (device-only, never synced).
welcomeSeenFlag(:row_id AS INTEGER):
SELECT welcome_seen FROM app_settings WHERE id = :row_id;

-- Only welcome_seen changes, so the settings sync trigger, which watches the
-- four synced columns, stays silent.
markWelcomeSeen(:row_id AS INTEGER):
UPDATE app_settings SET welcome_seen = 1 WHERE id = :row_id;

-- Live decks, and live cards whose deck is live too.
liveLibraryCounts AS LiveLibraryCountsRow:
SELECT
  (SELECT COUNT(*) FROM deck WHERE delete_batch_id IS NULL) AS decks,
  (SELECT COUNT(*) FROM card c JOIN deck d ON d.id = c.deck_id
   WHERE c.delete_batch_id IS NULL AND d.delete_batch_id IS NULL) AS cards;
```

- [ ] **Step 4: Rewrite the DAO**

Replace `lib/features/account/data/datasources/account_device_dao.dart` with:

```dart
import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';

part 'account_device_dao.g.dart';

/// Row access for the account screens' device-only reads
/// (`account_device_queries.drift`). It returns plain values and runs inside
/// the caller's guard.
@DriftAccessor(
  include: {'package:memox/core/database/queries/account_device_queries.drift'},
)
final class AccountDeviceDao extends DatabaseAccessor<AppDatabase>
    with _$AccountDeviceDaoMixin {
  AccountDeviceDao(super.attachedDatabase);

  Future<bool> welcomeSeen() async =>
      await welcomeSeenFlag(appSettingsRowId).getSingle() == 1;

  Future<void> setWelcomeSeen() => markWelcomeSeen(appSettingsRowId);

  Future<(int, int)> liveCounts() async {
    final row = await liveLibraryCounts().getSingle();
    return (row.decks, row.cards);
  }
}
```

- [ ] **Step 5: Generate and check what Drift wrote**

Run: `dart run build_runner build --delete-conflicting-outputs`
Then run: `grep -n "welcomeSeenFlag\|markWelcomeSeen\|class LiveLibraryCountsRow\|updates:" lib/features/account/data/datasources/account_device_dao.g.dart`
Expected:
- the three methods exist;
- `markWelcomeSeen` carries `updates: {appSettings}`;
- `LiveLibraryCountsRow` has `int decks` and `int cards`. If Drift put the class elsewhere, `grep -rn "class LiveLibraryCountsRow" lib` names the file to import.

- [ ] **Step 6: Run the tests**

Run: `TZ=UTC flutter test test/features/account/`
Expected: PASS, with no test edited except Step 1's addition.

- [ ] **Step 7: Take the file off the exclude list**

- In `scopes.yaml` delete the line `      - lib/features/account/data/datasources/account_device_dao.dart`.
- In the test file set:

```python
MIGRATED_TO_DRIFT: tuple[str, ...] = (
    "lib/features/account/data/datasources/account_device_dao.dart",
)
```

Run: `cd code-verification-guard-v2 && python3 -m pytest -q tests/test_memox_v8_data_model_guard_rules.py && cd .. && python3 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8`
Expected: pytest passes, and the guard has no `queries_in_drift` finding.

- [ ] **Step 8: Commit**

```bash
git add lib/core/database/queries/account_device_queries.drift lib/features/account/data/datasources/account_device_dao.dart test/features/account/data/account_device_repository_impl_test.dart code-verification-guard-v2/registries/projects/memox-v8/config/scopes.yaml code-verification-guard-v2/tests/test_memox_v8_data_model_guard_rules.py
git commit -m "refactor(account): AccountDeviceDao reads through .drift (ADR-020 pilot)"
```

---

### Task 4: Pilot `TrashDao` as an accessor, and split the delete-batch queries

**Files:**
- Create: `lib/core/database/queries/delete_batch_queries.drift`
- Modify: `lib/core/database/queries/trash_queries.drift` (move three queries out, add three)
- Modify: `lib/core/database/app_database.dart:22-24` (`include` list)
- Modify: `lib/features/trash/data/datasources/trash_dao.dart` (whole file)
- Modify: `lib/features/trash/data/mappers/trash_mapper.dart:1` (import), only if Step 5 shows the row classes moved
- Modify: `code-verification-guard-v2/registries/projects/memox-v8/config/scopes.yaml`, `code-verification-guard-v2/tests/test_memox_v8_data_model_guard_rules.py`
- Test: `test/features/trash/data/trash_purge_candidates_test.dart` (create)

**Interfaces:**
- Consumes: Task 2's scope and `MIGRATED_TO_DRIFT`; Task 3's pattern.
- Produces: `TrashDao(AppDatabase db)` with unchanged `entryChanges()`, `deckEntryRows()`, `cardEntryRows()`, `forestRows()`, `purgeCandidates({required Set<String> chosen, required DateTime cutoff}) -> Future<List<DeleteBatch>>`, `blockersOf(String)` and `purge(String)`. `AppDatabase` keeps `insertDeleteBatch`, `deckIsInTrash` and `closeSessionsTouchingBatch`, which `card_dao` and `deck_dao` still call.

- [ ] **Step 1: Characterization test for purge candidates**

Create `test/features/trash/data/trash_purge_candidates_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/trash/data/datasources/trash_dao.dart';

import '../../../support/test_database.dart';

// BR-TRASH-009, BR-TRASH-010: a purge takes the chosen batches that still
// exist and every expired one, each once, oldest first, ties by id.
void main() {
  late AppDatabase db;
  setUp(() => db = openTestDatabase());
  tearDown(() => db.close());

  Future<void> batch(String id, DateTime at) => db.customStatement(
    'INSERT INTO delete_batches (id, item_type, root_item_id, deleted_at) '
    "VALUES (?, 'card', ?, ?)",
    [id, 'c-$id', at.millisecondsSinceEpoch ~/ 1000],
  );

  test('chosen and expired batches come once, ordered by time then id', () async {
    final cutoff = DateTime.utc(2026, 9, 1);
    final expired = cutoff.subtract(const Duration(days: 1));
    final fresh = cutoff.add(const Duration(days: 1));
    await batch('b-expired-2', expired);
    await batch('b-expired-1', expired);
    await batch('b-fresh-chosen', fresh);
    await batch('b-fresh-left', fresh);

    final rows = await TrashDao(db).purgeCandidates(
      chosen: {'b-fresh-chosen', 'b-expired-2', 'b-gone'},
      cutoff: cutoff,
    );

    expect([for (final row in rows) row.id], [
      'b-expired-1',
      'b-expired-2',
      'b-fresh-chosen',
    ]);
  });
}
```

Run: `TZ=UTC flutter test test/features/trash/data/trash_purge_candidates_test.dart`
Expected: PASS against the current code.

- [ ] **Step 2: Split the delete-batch queries out of `trash_queries.drift`**

Create `lib/core/database/queries/delete_batch_queries.drift`. Its content is the first lines of today's `trash_queries.drift`: the four imports and the three queries `insertDeleteBatch`, `deckIsInTrash` and `closeSessionsTouchingBatch`, each with its comment, copied verbatim. Add a header comment at the top:

```sql
-- ADR-020: the delete-batch writes `card_dao` and `deck_dao` share. Included
-- on AppDatabase until P2 and P3 make those DAOs accessors that include it.
```

Delete those three queries and their comments from `trash_queries.drift`. Keep its imports and the four `trash*` queries.

- [ ] **Step 3: Add the purge queries to `trash_queries.drift`**

Append:

```sql
-- BR-TRASH-009: every batch deleted at or before :cutoff, which a purge takes
-- whether chosen or not.
deleteBatchesDeletedBy(:cutoff AS DATETIME):
SELECT * FROM delete_batches WHERE deleted_at <= :cutoff
ORDER BY deleted_at, id;

-- BE-C2: the chosen batches that still exist, one chunk of ids at a time.
deleteBatchesIn:
SELECT * FROM delete_batches WHERE id IN :ids
ORDER BY deleted_at, id;

-- BR-TRASH-010: the batch goes for good; the keys delete its decks and
-- cards, and theirs everything that hangs on them.
purgeDeleteBatch(:batch_id AS TEXT):
DELETE FROM delete_batches WHERE id = :batch_id;
```

- [ ] **Step 4: Repoint the includes and rewrite the DAO**

In `lib/core/database/app_database.dart` replace the line
`    'package:memox/core/database/queries/trash_queries.drift',`
with
`    'package:memox/core/database/queries/delete_batch_queries.drift',`.

Replace `lib/features/trash/data/datasources/trash_dao.dart` with:

```dart
import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/id_chunks.dart';
import 'package:memox/core/database/table_changes.dart';

part 'trash_dao.g.dart';

/// Row access for the Trash (`trash_queries.drift`). It returns Drift rows,
/// never domain values, and runs inside the caller's transaction.
@DriftAccessor(
  include: {'package:memox/core/database/queries/trash_queries.drift'},
)
final class TrashDao extends DatabaseAccessor<AppDatabase>
    with _$TrashDaoMixin {
  TrashDao(super.attachedDatabase);

  /// Fires once, then after every write to the batches, the decks or the
  /// cards: the Trash follows a delete, a restore and a purge.
  Stream<void> entryChanges() => tableChanges(attachedDatabase, [
    attachedDatabase.deleteBatches,
    attachedDatabase.deck,
    attachedDatabase.card,
  ]);

  Future<List<TrashDeckEntryRow>> deckEntryRows() => trashDeckEntries().get();

  Future<List<TrashCardEntryRow>> cardEntryRows() => trashCardEntries().get();

  Future<List<TrashForestRow>> forestRows() => trashDeckForest().get();

  /// The batches a purge takes: [chosen] ones that still exist, and every
  /// one deleted at or before [cutoff], oldest first (BR-TRASH-009,
  /// BR-TRASH-010). [chosen] is read in chunks, each batch once (BE-C2).
  Future<List<DeleteBatch>> purgeCandidates({
    required Set<String> chosen,
    required DateTime cutoff,
  }) async {
    final byId = <String, DeleteBatch>{
      for (final batch in await deleteBatchesDeletedBy(cutoff).get())
        batch.id: batch,
      for (final chunk in idChunks(chosen))
        for (final batch in await deleteBatchesIn(chunk).get()) batch.id: batch,
    };
    return byId.values.toList()..sort((a, b) {
      final byTime = a.deletedAt.compareTo(b.deletedAt);
      return byTime != 0 ? byTime : a.id.compareTo(b.id);
    });
  }

  /// What still sits in the decks of [batchId] and is not of it: another
  /// batch's id, or null for an active row (BR-TRASH-010).
  Future<List<String?>> blockersOf(String batchId) =>
      trashBlockersOf(batchId).get();

  /// [batchId] goes for good: the keys delete its decks and cards, and
  /// theirs everything that hangs on them (BR-TRASH-010).
  Future<void> purge(String batchId) => purgeDeleteBatch(batchId);
}
```

- [ ] **Step 5: Generate and resolve the row classes' home**

Run: `dart run build_runner build --delete-conflicting-outputs`
Then run: `grep -rn "class TrashDeckEntryRow\|class TrashCardEntryRow\|class TrashForestRow" lib --include=*.g.dart`
Expected: the classes are found in exactly one generated file.
- If that file is `trash_dao.g.dart`, change `trash_mapper.dart`'s import `package:memox/core/database/app_database.dart` to `package:memox/features/trash/data/datasources/trash_dao.dart`. Keep `app_database.dart` too if the mapper still uses another type from it.
- If the file is `app_database.g.dart`, leave the import alone.

Also confirm the purge statement notifies: `grep -n "purgeDeleteBatch" -A8 lib/features/trash/data/datasources/trash_dao.g.dart` shows `updates: {deleteBatches}` and `updateKind: UpdateKind.delete`.

- [ ] **Step 6: Run analyze and the Trash, card and deck tests**

Run: `flutter analyze --no-fatal-infos lib/features/trash lib/features/card lib/features/deck lib/core/database`
Expected: no errors.

Run: `TZ=UTC flutter test test/features/trash/ test/features/card/ test/features/deck/ test/database/`
Expected: PASS. This includes 'the list follows a delete, a restore and a purge' and the delete paths that call `insertDeleteBatch` / `closeSessionsTouchingBatch` through `AppDatabase`.

- [ ] **Step 7: Take the file off the exclude list**

- In `scopes.yaml` delete `      - lib/features/trash/data/datasources/trash_dao.dart`.
- In the test file:

```python
MIGRATED_TO_DRIFT: tuple[str, ...] = (
    "lib/features/account/data/datasources/account_device_dao.dart",
    "lib/features/trash/data/datasources/trash_dao.dart",
)
```

Run: `cd code-verification-guard-v2 && python3 -m pytest -q tests/test_memox_v8_data_model_guard_rules.py && cd .. && python3 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8`
Expected: pass, and no `queries_in_drift` finding.

- [ ] **Step 8: Commit**

```bash
git add lib/core/database/queries/ lib/core/database/app_database.dart lib/features/trash/ test/features/trash/data/trash_purge_candidates_test.dart code-verification-guard-v2/registries/projects/memox-v8/config/scopes.yaml code-verification-guard-v2/tests/test_memox_v8_data_model_guard_rules.py
git commit -m "refactor(trash): TrashDao reads and purges through .drift (ADR-020 pilot)"
```

---

### Task 5: Skills, references and WBS say what ADR-020 says

**Files:**
- Modify: `.claude/skills/flutter-feature-slice/SKILL.md:127-130`
- Modify: `.claude/skills/flutter-drift/SKILL.md` (Step 1 and Step 2 paragraphs)
- Modify: `.claude/skills/flutter-drift/references/dynamic-sql.md` (level table and the paragraphs that cite levels 3 and 4)
- Modify: `.claude/skills/flutter-drift/references/layering.md` (`## DAO` section)
- Modify: `.claude/skills/flutter-drift/references/project-baseline.md` (layout tree and the "Tables and queries are central" paragraph)
- Modify: `.claude/skills/flutter-drift/references/review-checklist.md:18` and `:28`
- Modify: `docs/wbs_FE.md` (§"Hạ tầng và kiểm chứng" table)

`flutter-data-layer` has no text on how a DAO queries (checked: `SKILL.md:15` only points to `flutter-drift`), so it is left as is.

**Interfaces:**
- Consumes: ADR-020 path (Task 1); pilot DAOs (Tasks 3–4) as the cited example.

- [ ] **Step 1: `flutter-feature-slice`**

Replace:

```markdown
SQL goes in `.drift` files under `lib/core/database/` so `drift_dev` type-checks
it at build time. No business SQL in Dart. Multi-step writes run inside
```

with:

```markdown
Every query, read or write, goes in a `.drift` file under
`lib/core/database/queries/`, and the DAO is a `@DriftAccessor` that calls what
Drift generates (ADR-020). No SQL string and no builder chain in Dart: the
builder only builds an `Expression` for a `$predicate` / `$order` placeholder.
The exceptions are migrations, `PRAGMA` and `local_data_reset.dart`; the guard's
`memox.data_model.queries_in_drift` holds the line. Multi-step writes run inside
```

- [ ] **Step 2: `flutter-drift/SKILL.md`**

After the paragraph that ends "…the same SQL in a Dart string is checked at runtime by your users." in Step 1, add:

```markdown
That holds for queries too, not only tables: every query lives in
`lib/core/database/queries/<topic>_queries.drift`, and the DAO is a
`@DriftAccessor(include: {...})` that calls the generated method (ADR-020).
`TrashDao` and `AccountDeviceDao` are the reference shape.
```

In Step 2, replace the sentence that begins "If the query's **shape** varies" through "…are all gone at once." with:

```markdown
If the query's **shape** varies — an optional filter, a sort the user picks, a
window — read `references/dynamic-sql.md` before writing it. The shape varies
through a `$predicate` / `$order` placeholder in the `.drift` query, filled by
an `Expression` the DAO builds; it is never SQL text and never a builder chain
standing in for the query (ADR-020).
```

- [ ] **Step 3: `dynamic-sql.md`**

Replace the table under "## Pick the lowest level that works" with:

```markdown
| Level | Use | When |
|---|---|---|
| 1 | Static named query in `.drift` | The shape is fixed. Always prefer this |
| 2 | `.drift` query with Dart components — `$predicate`, `$order`, `:row_limit` | The `WHERE`/`ORDER BY`/`LIMIT` varies; the DAO builds the `Expression` |

There is no level 3 or 4 in app code (ADR-020). A builder chain or a
`customSelect` is allowed only in migrations, a `PRAGMA` and
`local_data_reset.dart`, and the guard rejects it anywhere else.
```

Replace the paragraph "The card list is level 3: …" with:

```markdown
The card list moves to level 2 in P2 (spec 2026-10-01-drift-queries-only):
its window, filter counts and Select all become `.drift` queries that take
the one `CardListDao._predicate` as `$predicate`, so they still never
disagree about which cards a query lets through (BR-CARD-012). A template
can also declare a default (`$predicate = TRUE`) for callers that pass
nothing.
```

Replace the paragraph "Level 4 is a last resort, …" with:

```markdown
Inside the exceptions, a `customSelect` must declare `readsFrom` and a
`customUpdate` `updates`, or the streams that should react go silent (see
`riverpod-drift.md`). A generated query declares both itself.
```

- [ ] **Step 4: `layering.md`**

In `## DAO`, replace:

```markdown
**May:** call generated queries, compose query builders, run `transaction` and
`batch`, return Drift rows / `Selectable` / typed result classes.

**Must not:** know domain entities, apply domain rules, build SQL strings, return
a UI model.
```

with:

```markdown
A DAO is a `@DriftAccessor(include: {...queries/<topic>_queries.drift})`
extending `DatabaseAccessor<AppDatabase>`, built as `XDao(db)` (ADR-020).

**May:** call the queries Drift generates from its included files, build an
`Expression` / `OrderingTerm` for a `$predicate` / `$order` placeholder, use
`tableChanges(...)`, return Drift rows / `Selectable` / typed result classes.

**Must not:** know domain entities, apply domain rules, build SQL strings,
compose a builder chain (`select`, `update`, `into`, `delete`, `join`,
`batch`), call another DAO, return a UI model.
```

- [ ] **Step 5: `project-baseline.md`**

In the layout tree, replace `└── queries/                     card, deck and trash queries (.drift)` with:

```
└── queries/                     every query, by topic (.drift), included by
                                 the DAOs' @DriftAccessor (ADR-020)
```

After the paragraph that starts "**Tables and queries are central, DAOs are feature-owned**", add:

```markdown
Since ADR-020 a query file is included by the DAOs that use it, not by
`AppDatabase`: `@DriftDatabase` keeps `tables/*.drift` (and, until the
migration's P8, the query files DAOs not yet migrated still call through it).
Migrations, `PRAGMA` and `local_data_reset.dart` are the only Dart that may
hold SQL.
```

- [ ] **Step 6: `review-checklist.md`**

Replace line 18:

```markdown
- SQL strings scattered through Dart instead of `.drift` files.
```

with:

```markdown
- A query outside `.drift`: a SQL string, or a `select`/`update`/`into`/
  `delete`/`join`/`batch` builder chain in a DAO (ADR-020; the guard's
  `queries_in_drift` catches most, review catches the rest).
```

At line 28, prefix the bullet so it reads:

```markdown
- Inside ADR-020's exceptions only: `customSelect` without `readsFrom`, or a raw write that does not declare the
```

Keep the rest of the line unchanged.

- [ ] **Step 7: WBS rows**

Append to the table under `### Hạ tầng và kiểm chứng` in `docs/wbs_FE.md`:

```markdown
| FE-D8 | Mọi truy vấn trong `.drift` — P0: ADR-020, guard `queries_in_drift`, skill cập nhật, pilot `TrashDao` và `AccountDeviceDao` thành `@DriftAccessor` | đang làm | — | M | [spec](superpowers/specs/2026-10-01-drift-queries-only-design.md) và [plan](superpowers/plans/2026-10-02-drift-queries-only-p0.md) | P1 |
| FE-D9 | `.drift` P1: `tag_dao`, `settings_dao`, `starter_dao`, `dismissed_note_store` | chưa làm | FE-D8 | M | — | — |
| FE-D10 | `.drift` P2: `card_dao`, `card_list_dao` (`$predicate`/`$order`), `card_detail_dao` | chưa làm | FE-D8 | L | — | — |
| FE-D11 | `.drift` P3: `deck_dao`, `reminder_workload_dao` | chưa làm | FE-D8 | M | — | — |
| FE-D12 | `.drift` P4: `srs_dao` | chưa làm | FE-D8 | M | — | — |
| FE-D13 | `.drift` P5: `study_queue_dao`, `study_session_dao`, `study_round_dao`, `study_view_dao` | chưa làm | FE-D8 | L | — | — |
| FE-D14 | `.drift` P6: `progress_dao`, `search_dao` | chưa làm | FE-D8 | L | — | — |
| FE-D15 | `.drift` P7: `core/sync`, `core/auth/account_store` (upsert thay `batch`, đo pull 1.000 dòng) | chưa làm | FE-D8 | L | — | — |
| FE-D16 | `.drift` P8: log DB sang `log.drift`, xoá exclude tạm, `@DriftDatabase` chỉ còn bảng | chưa làm | FE-D9…FE-D15 | S | — | — |
```

Run: `python3 tools/docs/check.py`
Expected: `PASS — 0 error(s)`.

- [ ] **Step 8: Commit**

```bash
git add .claude/skills/flutter-feature-slice/SKILL.md .claude/skills/flutter-drift docs/wbs_FE.md
git commit -m "docs(skills): flutter-drift and feature-slice follow ADR-020"
```

---

### Task 6: Gate

**Files:** none. Verification only. A fix found here goes back to the task that owns it.

- [ ] **Step 1: Full gate**

Run: `bash .claude/skills/flutter-workflow/scripts/dod_check.sh`
Expected: every step green: format, analyze, generated code, architecture, docs, guard self-tests, guard, and the full suite.

- [ ] **Step 2: `check_drift` delta**

Run: `bash .claude/skills/flutter-drift/scripts/check_drift.sh | tail -1`
Expected: fewer errors than the 59 recorded on `8aaa29c`. The `schema_versions.dart` and pilot DAO findings are gone. Record the new count in the PR description.

- [ ] **Step 3: No goldens, no presentation**

Run: `git diff --stat origin/master...HEAD -- 'test/**/goldens/*.png' 'lib/features/*/presentation/**'`
Expected: empty.

- [ ] **Step 4: Mark P0 done in the WBS**

In `docs/wbs_FE.md`, row FE-D8: set the state to `xong` and the evidence column to the spec, the plan and "`dod_check.sh` xanh". Then commit:

```bash
git add docs/wbs_FE.md
git commit -m "docs(wbs): FE-D8 done"
```

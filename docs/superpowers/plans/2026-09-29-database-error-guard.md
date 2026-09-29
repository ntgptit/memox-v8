# Database Error Guard Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the nine private `_write`/`_mapped` copies with one `guardDatabase` helper and one `AppDatabase.mappedTransaction` extension, with no behaviour change.

**Architecture:** `guardDatabase` sits in `core/error/failure.dart` beside `mapDatabaseError` and `Stream.mapDatabaseErrors()`; `MappedTransaction` sits in `core/database/` because it needs `AppDatabase`. Repositories call them directly; no class, provider or constructor change. An architecture test keeps `mapDatabaseError(` inside `lib/core/`.

**Tech Stack:** Dart 3.13, Drift, flutter_test.

**Spec:** `docs/superpowers/specs/2026-09-29-database-error-guard-design.md`

## Global Constraints

- No repository constructor, provider or `di/` file changes (spec D4).
- `guardDatabase` takes a closure, not a `Future` (spec D3).
- `core/error` does not import `core/database` (spec D2).
- Existing repository, invariant and sync tests pass without edits.

## Review Focus

1. A synchronous throw inside the body (before any `await`) is still mapped — Task 1 test.
2. A `Failure` thrown inside a transaction (a repository's own refusal path) leaves unchanged, not wrapped — Task 1 test (`mapDatabaseError` returns a `Failure` as it is).
3. The stack trace reaching the caller is the original one, not the helper's — Task 1 test.
4. A throw inside `mappedTransaction` rolls back every write made before it — Task 1 test.
5. A repository whose helper differed from the two shapes would silently change — Task 2 step 1 diffs every helper before deleting it.

---

### Task 1: `guardDatabase` and `MappedTransaction`

**Files:**
- Modify: `lib/core/error/failure.dart`
- Create: `lib/core/database/mapped_transaction.dart`
- Test: `test/core/error/failure_test.dart`
- Test: `test/core/database/mapped_transaction_test.dart`

**Interfaces:**
- Produces: `Future<T> guardDatabase<T>(Future<T> Function() body)`;
  `extension MappedTransaction on AppDatabase { Future<T> mappedTransaction<T>(Future<T> Function() body) }`.

- [ ] **Step 1: Write the failing tests.** Append to `failure_test.dart`:

```dart
group('guardDatabase', () {
  test('a value passes through', () async {
    expect(await guardDatabase(() async => 7), 7);
  });

  test('a database error leaves as its Failure, with the original stack', () async {
    StackTrace? thrownAt;
    Future<int> body() async {
      try {
        throw sqlite3.SqliteException(extendedResultCode: 5, message: 'locked');
      } on Object catch (_, stack) {
        thrownAt = stack;
        rethrow;
      }
    }

    await expectLater(
      guardDatabase(body),
      throwsA(isA<DatabaseLockedFailure>()),
    );
    try {
      await guardDatabase(body);
    } on Failure catch (_, stack) {
      expect(stack.toString(), thrownAt.toString());
    }
  });

  test('a throw before the first await is mapped too', () async {
    Future<int> body() => throw StateError('sync');
    await expectLater(
      guardDatabase(body),
      throwsA(isA<UnknownDatabaseFailure>()),
    );
  });

  test('a Failure thrown inside leaves as it is', () async {
    const refusal = ConstraintFailure(cause: 'x');
    await expectLater(
      guardDatabase<int>(() async => throw refusal),
      throwsA(same(refusal)),
    );
  });
});
```

Create `test/core/database/mapped_transaction_test.dart`:

```dart
void main() {
  late AppDatabase db;
  setUp(() => db = openTestDatabase());
  tearDown(() => db.close());

  test('a success commits', () async {
    await db.mappedTransaction(() => insertRootDeck(db, 'a'));
    expect(await db.select(db.decks).get(), hasLength(1));
  });

  test('a throw rolls every write back and leaves as a Failure', () async {
    await expectLater(
      db.mappedTransaction(() async {
        await insertRootDeck(db, 'a');
        throw StateError('boom');
      }),
      throwsA(isA<UnknownDatabaseFailure>()),
    );
    expect(await db.select(db.decks).get(), isEmpty);
  });
}
```

Use the real deck-insert fixture from `test/support/deck_fixtures.dart` (read it; if it has no plain insert, write the row with `db.into(db.decks).insert(...)` using the columns the fixture uses).

- [ ] **Step 2: Run** `flutter test test/core/error/failure_test.dart test/core/database/mapped_transaction_test.dart` — Expected: FAIL (undefined `guardDatabase`, `mappedTransaction`).

- [ ] **Step 3: Implement.** In `failure.dart`, after `mapDatabaseError`:

```dart
/// [body], with an unexpected database error leaving as the [Failure]
/// [mapDatabaseError] makes of it, with its original stack trace. The Future
/// twin of [DatabaseErrorStream.mapDatabaseErrors]; a closure, so a throw
/// before the body's first await is mapped too.
Future<T> guardDatabase<T>(Future<T> Function() body) async {
  try {
    return await body();
  } on Object catch (error, stackTrace) {
    Error.throwWithStackTrace(mapDatabaseError(error), stackTrace);
  }
}
```

`lib/core/database/mapped_transaction.dart`:

```dart
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';

/// A transaction whose unexpected error leaves as its [Failure], after the
/// rollback.
extension MappedTransaction on AppDatabase {
  Future<T> mappedTransaction<T>(Future<T> Function() body) =>
      guardDatabase(() => transaction(body));
}
```

- [ ] **Step 4: Run** the two test files — Expected: PASS.
- [ ] **Step 5: Commit** `feat(core): guardDatabase and mappedTransaction, the Future twins of mapDatabaseErrors`.

### Task 2: The nine repositories use them

**Files (modify):** `lib/features/card/data/repositories/card_repository_impl.dart`,
`card_transfer_repository_impl.dart`, `lib/features/deck/data/repositories/deck_repository_impl.dart`,
`lib/features/settings/data/repositories/settings_repository_impl.dart`,
`lib/features/srs/data/repositories/schedule_repository_impl.dart`,
`lib/features/starter_decks/data/repositories/starter_library_repository_impl.dart`,
`lib/features/study/data/repositories/study_entry_repository_impl.dart`,
`study_session_repository_impl.dart`, `lib/features/tags/data/repositories/tag_repository_impl.dart`.

**Interfaces:** Consumes Task 1's two helpers.

- [ ] **Step 1: Prove the helpers are the two shapes.** For each file print its helper
  bodies (`grep -n -A8 "Future<T> _write<T>\|Future<T> _mapped<T>"`). Each must be
  either `_mapped(() => _db.transaction(body))` + the `try/await body()/throwWithStackTrace(mapDatabaseError…)`
  body, or `_write` with `try { return await _db.transaction(body); } …` inline. Any other
  shape: stop and ledger a ruling.
- [ ] **Step 2: Rewrite** in each file: `_write(` → `_db.mappedTransaction(`, `_mapped(` → `guardDatabase(`;
  delete the helper methods and their doc comments; add
  `import 'package:memox/core/database/mapped_transaction.dart';` where `mappedTransaction`
  is used; keep `failure.dart` imported where `guardDatabase`/`mapDatabaseErrors` remain.
  Where the field is not `_db`, use the file's own `AppDatabase` field name.
- [ ] **Step 3: Run** `dart format lib`, `flutter analyze`, then
  `flutter test test/features test/core test/app test/architecture` — Expected: all pass, no test edited.
- [ ] **Step 4: Commit** `refactor(data): nine repositories drop their private error-mapping copies`.

### Task 3: Keep it so

**Files:**
- Create: `test/architecture/database_error_guard_test.dart`

- [ ] **Step 1: Write the rule and its planted-violation test** in one file:

```dart
/// Spec D5: outside lib/core/, no file calls mapDatabaseError( directly;
/// repositories go through guardDatabase, mappedTransaction or
/// mapDatabaseErrors().
List<String> directMappings(Map<String, String> sources) => [
  for (final MapEntry(key: path, value: text) in sources.entries)
    if (!path.startsWith('lib/core/') && text.contains('mapDatabaseError('))
      path,
];

void main() {
  test('a direct call outside core is reported', () {
    expect(
      directMappings({
        'lib/features/x/data/repositories/x.dart': 'mapDatabaseError(e)',
        'lib/core/error/failure.dart': 'mapDatabaseError(e)',
      }),
      ['lib/features/x/data/repositories/x.dart'],
    );
  });

  test('lib/ calls mapDatabaseError( only inside core', () {
    final sources = {
      for (final file in Directory('lib').listSync(recursive: true))
        if (file is File && file.path.endsWith('.dart') &&
            !file.path.endsWith('.g.dart'))
          file.path: file.readAsStringSync(),
    };
    expect(directMappings(sources), isEmpty);
  });
}
```

- [ ] **Step 2: Run** it on the Task 2 tree — Expected: PASS. Then temporarily restore one
  `_mapped` copy (git stash of Task 2 is not needed: the planted test already proves the
  rule fires) — the first test is the RED proof.
- [ ] **Step 3: Gate:** `bash .claude/skills/flutter-workflow/scripts/dod_check.sh` — Expected: mechanical gates passed.
- [ ] **Step 4: Commit** `test(architecture): database errors are mapped only through core`.

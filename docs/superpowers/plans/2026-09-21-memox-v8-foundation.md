# MemoX V8 Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the MemoX V8 foundation: a runnable Flutter skeleton with the core data model, pure-Dart SRS schedulers, deck-tree rules and their transactional invariants, all guarded by tests. No product UI.

**Architecture:** Feature-first single package. `srs` and deck rules are pure Dart. Drift/SQLite is the only source of truth; each feature declares its own `.drift` tables and `core/db` assembles them into one `AppDatabase`. Feature stores (plain classes over `AppDatabase`) run every write inside one Drift transaction. No repository layer, no single-implementation interfaces.

**Tech Stack:** Flutter 3.44.8 / Dart 3.12.2, `flutter_riverpod` 3.4.3 + `riverpod_annotation` 4.0.7 + `riverpod_generator` 4.0.9, `drift` / `drift_dev` 2.35.0, `drift_flutter` 0.3.1, `sqlite3` 3.6.0, `go_router` 18.0.1, `uuid` 4.6.0, `build_runner` 2.16.1. (Versions read from pub.dev on 2026-09-21; if `flutter pub get` reports a resolution conflict, lower the offending package to the newest version that resolves and note it in the commit message.)

**Spec:** `docs/superpowers/specs/2026-09-21-memox-v8-foundation-design.md`

## Global Constraints

Every task's requirements implicitly include these, copied from the spec.

- Android is the only release target; local-only; no network; no auth.
- State: Riverpod 3 + `riverpod_generator` (codegen). No freezed: models are plain Dart 3 classes / `sealed` / records, so codegen is only Riverpod + Drift.
- Database: Drift/SQLite is the single source of truth; IDs are client-generated UUIDs.
- Structure: `lib/{main.dart, app/, core/, features/{decks,cards,srs,study,progress}}`. A folder is created only when it holds a real file.
- `srs` algorithm code is pure Dart: no Flutter or Drift imports.
- `Scheduler` is the only interface (two real implementations). No repository layer, no single-implementation interface.
- Depth is at most 10 (root is level 1). A root deck holds only sub-decks. Emptying a sub-deck sets it back to `unset` in the same transaction. Moving a subtree under a root with a different scheduler or generation is blocked, never converted.
- Scheduler and generation are stored only on the root deck; resolve via `root_id`, never `COALESCE(parent_id, id)`.
- The scheduler is locked after the first review; changing it needs Reset learning progress. Reset increments `generation`. A review from a stale-`generation` session is rejected, never applied.
- `review_log.kind` and session `status` / `end_reason` are stored, never inferred.
- Expected business rejections return `Ok` / `Rejected(reason)`; unexpected DB errors are mapped in one place; Riverpod auto-retry is disabled.
- Card content is never logged at any level.
- Verification gate: `flutter analyze` and `flutter test` (after `dart run build_runner build --delete-conflicting-outputs`). Generated `*.g.dart` files are not committed.

## Clarifications to the spec (confirm during plan review)

The spec is silent or slightly ambiguous on these; the plan makes the smallest choice and flags it.

1. **Public surface of a feature** is its barrel file `lib/features/<x>/<x>.dart`. The spec said "public providers"; pure rules and value types must also be reachable, so cross-feature imports must go through the barrel. Enforced by a test.
2. **`srs` depends on no feature** at the Dart level. Its *tables* reference `card` (foreign key), which is a schema relationship, not a Dart import. The boundary test checks Dart imports only.
3. **Moving a root deck is rejected** (`Rejection.rootCannotMove`). The spec only describes moving sub-deck subtrees.
4. **`review_log.session_id` has no foreign key**, so `srs` does not depend on `study`'s table.
5. **`study_session` in the foundation is a table only** (id, deck, root, generation, status, end reason, timestamps, with the V7 status × end_reason matrix as a CHECK). Session behavior belongs to the core-learning-slice sub-project.
6. **Blank deck names and blank card front/back are rejected** (`blankName`, `blankContent`), a trust-boundary check.
7. **Application id** is `com.memox.memox` (from `flutter create --org com.memox --project-name memox`). Change before the first release build if you want another.
8. **`decks` may import the `srs` barrel**, to type the scheduler chosen when a root deck is created (`SchedulerType`). The spec lists `srs` as depending on no feature but does not restrict `decks`. The dependency map is `decks → srs`, `cards → decks, srs`, `study, progress → decks, cards, srs`.
9. **Stores take an optional `now` clock** instead of a global `core/clock`, because only stores need it and the SRS core already receives `now` as an argument.
10. **Feature stores are exposed through Riverpod providers** (`deckStoreProvider`, `scheduleStoreProvider`, `cardStoreProvider`) exported by each barrel. They are the "public providers" the spec names.

## Review Focus

Inputs the spec implies but its rules do not spell out. Each line has a test in the named task.

1. Blank or whitespace-only deck name / card text is rejected, not stored (Tasks 7, 9).
2. An action the deck's scheduler does not support (e.g. `hard` on an `eight_box` deck) is rejected, not applied (Task 8).
3. Moving a deck onto itself or into its own descendant is rejected and changes nothing (Task 7).
4. Reviewing a card that was deleted mid-session returns `notFound` and does not crash or write a log row (Task 8).
5. Due-date calculation across a month and year end (`eight_box` box 8, 128 days) lands on local midnight of the right day (Task 3).

## File Structure

```
pubspec.yaml, analysis_options.yaml, README.md
drift_schemas/drift_schema_v1.json                   schema snapshot
lib/main.dart                                        ProviderScope(retry: noRetry) + runApp
lib/app/app.dart, router.dart                        MemoxApp, noRetry, placeholder route
lib/core/ids.dart                                    newId()
lib/core/outcome.dart                                Outcome / Ok / Rejected / Rejection
lib/core/failure.dart                                Failure + mapDatabaseError
lib/core/db/app_database.dart                        AppDatabase (assembles the .drift files)
lib/core/db/database_provider.dart                   databaseProvider (codegen)
lib/features/decks/decks.dart                        barrel
lib/features/decks/decks_providers.dart              deckStoreProvider
lib/features/decks/data/deck.drift, deck_store.dart
lib/features/decks/logic/deck_rules.dart             pure rules
lib/features/cards/cards.dart                        barrel
lib/features/cards/cards_providers.dart              cardStoreProvider
lib/features/cards/data/card.drift, card_store.dart
lib/features/srs/srs.dart                            barrel
lib/features/srs/srs_providers.dart                  scheduleStoreProvider
lib/features/srs/data/srs.drift, schedule_store.dart
lib/features/srs/logic/scheduler.dart, schedulers.dart, eight_box.dart, sm2.dart,
                       due_date.dart, review_kind.dart
lib/features/study/data/study_session.drift          table only (no Dart yet)
test/architecture/boundaries_test.dart
test/core/**, test/features/**, test/integration/**, test/app/**,
test/support/test_database.dart
```

`progress/` is not created (no file in this plan). `study/` holds only its table; it gets a barrel when it gets Dart code.

---

### Task 1: Project skeleton, toolchain and boundary guard

**Files:**
- Create: Flutter project files at the repo root (via `flutter create`), `README.md`, `analysis_options.yaml`, `test/architecture/boundaries_test.dart`
- Modify: `pubspec.yaml`, `.gitignore`

**Interfaces:**
- Produces: a green `flutter analyze` + `flutter test` baseline; `test/architecture/boundaries_test.dart` enforcing the import rules in every later task.

- [ ] **Step 1: Scaffold the project in place**

`CLAUDE.md` and `docs/` already exist; `flutter create` leaves them alone.

```bash
flutter create . --project-name memox --org com.memox --platforms android --empty
```

Expected: `lib/main.dart`, `android/`, `pubspec.yaml`, `analysis_options.yaml` created.

- [ ] **Step 2: Add dependencies**

```bash
flutter pub add flutter_riverpod:^3.4.3 riverpod_annotation:^4.0.7 go_router:^18.0.1 drift:^2.35.0 drift_flutter:^0.3.1 sqlite3:^3.6.0 uuid:^4.6.0
flutter pub add --dev build_runner:^2.16.1 drift_dev:^2.35.0 riverpod_generator:^4.0.9
flutter pub get
```

Expected: `Got dependencies!`. If resolution fails, follow the note in the Tech Stack line.

- [ ] **Step 3: Replace `analysis_options.yaml`**

```yaml
include: package:flutter_lints/flutter.yaml

analyzer:
  language:
    strict-casts: true
    strict-inference: true
    strict-raw-types: true
  exclude:
    - "**/*.g.dart"

linter:
  rules:
    always_use_package_imports: true
    avoid_print: true
    prefer_const_constructors: true
```

`always_use_package_imports` is what makes the boundary test reliable: every import is a `package:memox/...` path.

- [ ] **Step 4: Ignore generated code**

Append to `.gitignore`:

```
# generated by build_runner
*.g.dart
```

- [ ] **Step 5: Write `README.md`**

````markdown
# MemoX V8

Flutter flashcard / spaced-repetition app. Rules: see `CLAUDE.md`. Design:
`docs/superpowers/specs/`. Plans: `docs/superpowers/plans/`.

## Commands

Generated code is not committed. A fresh clone does not analyze or test until:

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

Verification gate:

```bash
flutter analyze
flutter test
```
````

- [ ] **Step 6: Write the failing boundary test**

Create `test/architecture/boundaries_test.dart`:

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

final _importPattern = RegExp(
  r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''',
  multiLine: true,
);

/// Which other features each feature may import (through their barrel only).
const _allowedFeatureImports = <String, Set<String>>{
  'decks': {'srs'},
  'srs': {},
  'cards': {'decks', 'srs'},
  'study': {'decks', 'cards', 'srs'},
  'progress': {'decks', 'cards', 'srs'},
};

/// Folders that must stay free of Flutter, Riverpod and Drift.
const _pureFolders = [
  'lib/features/srs/logic/',
  'lib/features/decks/logic/',
];

const _forbiddenInPure = [
  'package:flutter/',
  'package:flutter_riverpod/',
  'package:riverpod_annotation/',
  'package:drift/',
  'package:memox/core/db/',
];

const _featurePrefix = 'package:memox/features/';

class _Source {
  _Source(this.path, this.imports);
  final String path;
  final List<String> imports;
}

List<_Source> _sources() {
  final dir = Directory('lib');
  if (!dir.existsSync()) return const [];
  return [
    for (final file in dir.listSync(recursive: true).whereType<File>())
      if (file.path.endsWith('.dart') && !file.path.endsWith('.g.dart'))
        _Source(
          file.path.replaceAll(r'\', '/'),
          [
            for (final m in _importPattern.allMatches(file.readAsStringSync()))
              m.group(1)!,
          ],
        ),
  ];
}

/// `lib/features/<name>/...` -> `<name>`, otherwise null.
String? _featureOf(String path) {
  const prefix = 'lib/features/';
  if (!path.startsWith(prefix)) return null;
  return path.substring(prefix.length).split('/').first;
}

void main() {
  final sources = _sources();

  test('pure folders import no Flutter, Riverpod, Drift or core/db', () {
    final violations = [
      for (final s in sources)
        if (_pureFolders.any(s.path.startsWith))
          for (final i in s.imports)
            if (_forbiddenInPure.any(i.startsWith)) '${s.path} imports $i',
    ];
    expect(violations, isEmpty);
  });

  test('features import other features only through an allowed barrel', () {
    final violations = <String>[];
    for (final s in sources) {
      final own = _featureOf(s.path);
      if (own == null) continue;
      for (final i in s.imports) {
        if (!i.startsWith(_featurePrefix)) continue;
        final rest = i.substring(_featurePrefix.length);
        final target = rest.split('/').first;
        if (target == own) continue;
        final allowed = _allowedFeatureImports[own] ?? const <String>{};
        if (!allowed.contains(target)) {
          violations.add('${s.path} may not depend on feature $target');
        } else if (rest != '$target/$target.dart') {
          violations.add('${s.path} must import $target via its barrel: $i');
        }
      }
    }
    expect(violations, isEmpty);
  });

  test('app and core never import feature internals', () {
    final violations = [
      for (final s in sources)
        if (s.path.startsWith('lib/app/') || s.path.startsWith('lib/core/'))
          for (final i in s.imports)
            if (i.startsWith(_featurePrefix) &&
                !RegExp(r'^package:memox/features/(\w+)/\1\.dart$').hasMatch(i))
              '${s.path} imports $i',
    ];
    expect(violations, isEmpty);
  });
}
```

Note the third test lets `app/` and `core/` import a barrel (`core/db/app_database.dart` needs none; `app/` will import barrels later) but never internals.

- [ ] **Step 7: Run it (baseline passes)**

Run: `flutter test test/architecture/boundaries_test.dart`
Expected: PASS (3 tests), since `lib/` has only `main.dart`.

- [ ] **Step 8: Prove the guard can fail**

Create `lib/features/srs/logic/bad.dart`:

```dart
import 'package:flutter/material.dart';
```

Run: `flutter test test/architecture/boundaries_test.dart`
Expected: FAIL, message `lib/features/srs/logic/bad.dart imports package:flutter/material.dart`.

Then delete the file: `rm lib/features/srs/logic/bad.dart` (and the now-empty folders).

- [ ] **Step 9: Run the full gate**

```bash
flutter analyze
flutter test
```

Expected: no analyzer issues; tests pass. If the generated `lib/main.dart` triggers a lint, fix it in place.

- [ ] **Step 10: Commit**

```bash
git add -A
git commit -m "chore: scaffold Flutter project with toolchain and boundary guard" -m "Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

### Task 2: Core primitives (ids, outcome, failure mapping)

**Files:**
- Create: `lib/core/ids.dart`, `lib/core/outcome.dart`, `lib/core/failure.dart`
- Test: `test/core/ids_test.dart`, `test/core/outcome_test.dart`, `test/core/failure_test.dart`

**Interfaces:**
- Produces:
  - `String newId()`
  - `enum Rejection { blankName, blankContent, maxDepthExceeded, wrongContentType, rootHoldsOnlyDecks, rootCannotMove, cannotMoveIntoOwnSubtree, schedulerMismatch, schedulerLocked, staleGeneration, unsupportedAction, notFound }`
  - `sealed class Outcome<T>` with `Ok<T>(T value)` and `Rejected<T>(Rejection reason)`
  - `sealed class Failure` with `ConstraintFailure`, `DatabaseLockedFailure`, `UnexpectedFailure`, and `Failure mapDatabaseError(Object error)`

- [ ] **Step 1: Write the failing tests**

`test/core/ids_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/ids.dart';

void main() {
  test('newId returns distinct UUID v4 strings', () {
    final a = newId();
    final b = newId();
    expect(a, isNot(b));
    expect(a, matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')));
  });
}
```

`test/core/outcome_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/outcome.dart';

String describe(Outcome<int> o) => switch (o) {
      Ok(:final value) => 'ok $value',
      Rejected(:final reason) => 'rejected ${reason.name}',
    };

void main() {
  test('Outcome switches exhaustively over Ok and Rejected', () {
    expect(describe(const Ok(3)), 'ok 3');
    expect(describe(const Rejected(Rejection.notFound)), 'rejected notFound');
  });
}
```

`test/core/failure_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/failure.dart';
import 'package:sqlite3/common.dart';

void main() {
  test('constraint violation maps to ConstraintFailure', () {
    expect(mapDatabaseError(SqliteException(19, 'CHECK failed')),
        isA<ConstraintFailure>());
  });

  test('busy and locked map to DatabaseLockedFailure', () {
    expect(mapDatabaseError(SqliteException(5, 'busy')),
        isA<DatabaseLockedFailure>());
    expect(mapDatabaseError(SqliteException(6, 'locked')),
        isA<DatabaseLockedFailure>());
  });

  test('anything else maps to UnexpectedFailure', () {
    expect(mapDatabaseError(StateError('boom')), isA<UnexpectedFailure>());
    expect(mapDatabaseError(SqliteException(1, 'generic')),
        isA<UnexpectedFailure>());
  });

  test('toString never includes the cause text', () {
    final f = mapDatabaseError(StateError('secret card content'));
    expect(f.toString(), isNot(contains('secret card content')));
  });
}
```

- [ ] **Step 2: Run to verify failure**

Run: `flutter test test/core`
Expected: FAIL, "Target of URI doesn't exist" for the three `lib/core` files.

- [ ] **Step 3: Implement**

`lib/core/ids.dart`:

```dart
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

String newId() => _uuid.v4();
```

`lib/core/outcome.dart`:

```dart
/// Why a business rule refused an operation. The UI maps these to copy.
enum Rejection {
  blankName,
  blankContent,
  maxDepthExceeded,
  wrongContentType,
  rootHoldsOnlyDecks,
  rootCannotMove,
  cannotMoveIntoOwnSubtree,
  schedulerMismatch,
  schedulerLocked,
  staleGeneration,
  unsupportedAction,
  notFound,
}

sealed class Outcome<T> {
  const Outcome();
}

final class Ok<T> extends Outcome<T> {
  const Ok(this.value);
  final T value;
}

final class Rejected<T> extends Outcome<T> {
  const Rejected(this.reason);
  final Rejection reason;
}
```

`lib/core/failure.dart`:

```dart
import 'package:drift/drift.dart';
import 'package:sqlite3/common.dart';

const _sqliteBusy = 5;
const _sqliteLocked = 6;
const _sqliteConstraint = 19;

/// Unexpected persistence errors. Expected business refusals are `Rejected`.
sealed class Failure {
  const Failure(this.cause);

  /// Kept for debugging. Never print it: a SQLite message can carry a bound
  /// value, and a value can be card content.
  final Object? cause;

  @override
  String toString() => runtimeType.toString();
}

final class ConstraintFailure extends Failure {
  const ConstraintFailure(super.cause);
}

final class DatabaseLockedFailure extends Failure {
  const DatabaseLockedFailure(super.cause);
}

final class UnexpectedFailure extends Failure {
  const UnexpectedFailure(super.cause);
}

/// The only place that knows what a Drift or SQLite exception looks like.
Failure mapDatabaseError(Object error) {
  final inner = error is DriftWrappedException ? (error.cause ?? error) : error;
  if (inner is SqliteException) {
    switch (inner.resultCode) {
      case _sqliteConstraint:
        return ConstraintFailure(inner);
      case _sqliteBusy || _sqliteLocked:
        return DatabaseLockedFailure(inner);
    }
  }
  return UnexpectedFailure(inner);
}
```

- [ ] **Step 4: Run to verify pass**

Run: `flutter test test/core`
Expected: PASS (6 tests). If `resultCode` is not a member in the installed `sqlite3`, use `inner.extendedResultCode & 0xFF` instead and note it.

- [ ] **Step 5: Gate and commit**

```bash
flutter analyze
git add lib/core test/core
git commit -m "feat(core): add ids, outcome and database failure mapping" -m "Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

### Task 3: SRS core types, due-date rule and `eight_box`

**Files:**
- Create: `lib/features/srs/logic/scheduler.dart`, `lib/features/srs/logic/due_date.dart`, `lib/features/srs/logic/eight_box.dart`
- Test: `test/features/srs/due_date_test.dart`, `test/features/srs/eight_box_test.dart`

**Interfaces:**
- Consumes: nothing.
- Produces (in `scheduler.dart`):
  - `enum SchedulerType { eightBox('eight_box'), sm2('sm2') }` with `final String value` and `static SchedulerType fromValue(String v)`
  - `enum ReviewAction { forgotten, remembered, again, hard, good, easy }`
  - `sealed class ScheduleState`; `final class EightBoxState(int box)`; `final class Sm2State({double easeFactor, int intervalDays, int repetitions})`
  - `final class ScheduleResult(ScheduleState state, DateTime dueAt)`, `dueAt` in UTC
  - `abstract interface class Scheduler { SchedulerType get type; List<ReviewAction> get supportedActions; ScheduleState get initialState; ScheduleResult next(ScheduleState state, ReviewAction action, DateTime now); }`
  - `DateTime startOfLearningDay(DateTime now, int days)` (in `due_date.dart`): 00:00 local time of the day `days` after `now`, returned as UTC
  - `class EightBoxScheduler implements Scheduler` (const constructor)

Rules (from V7 BR-15, BR-16, BR-105): `forgotten` → box 1; `remembered` → `min(8, box + 1)`; interval days by box 1..8 = 1, 2, 4, 8, 16, 32, 64, 128; due = start of the learning day, not `now + N*24h`.

- [ ] **Step 1: Write the failing tests**

`test/features/srs/due_date_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/srs/logic/due_date.dart';

void main() {
  test('lands on local midnight, returned as UTC', () {
    final due = startOfLearningDay(DateTime(2026, 3, 10, 15, 30), 1);
    expect(due.isUtc, isTrue);
    expect(due, DateTime(2026, 3, 11).toUtc());
    expect(due.toLocal().hour, 0);
  });

  test('day zero is the start of today', () {
    expect(startOfLearningDay(DateTime(2026, 3, 10, 23, 59), 0),
        DateTime(2026, 3, 10).toUtc());
  });

  test('rolls over month ends', () {
    expect(startOfLearningDay(DateTime(2026, 1, 31, 12), 1),
        DateTime(2026, 2, 1).toUtc());
  });
}
```

`test/features/srs/eight_box_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/srs/logic/eight_box.dart';
import 'package:memox/features/srs/logic/scheduler.dart';

void main() {
  const scheduler = EightBoxScheduler();
  final now = DateTime(2026, 3, 10, 9);

  EightBoxState boxOf(ScheduleResult r) => r.state as EightBoxState;

  test('declares its actions and initial state', () {
    expect(scheduler.type, SchedulerType.eightBox);
    expect(scheduler.supportedActions,
        [ReviewAction.forgotten, ReviewAction.remembered]);
    expect((scheduler.initialState as EightBoxState).box, 1);
  });

  test('forgotten always returns to box 1, due tomorrow', () {
    final r = scheduler.next(const EightBoxState(5), ReviewAction.forgotten, now);
    expect(boxOf(r).box, 1);
    expect(r.dueAt, DateTime(2026, 3, 11).toUtc());
  });

  test('remembered moves up one box with the box interval', () {
    const expectedDays = [2, 4, 8, 16, 32, 64, 128];
    for (var box = 1; box <= 7; box++) {
      final r = scheduler.next(EightBoxState(box), ReviewAction.remembered, now);
      expect(boxOf(r).box, box + 1);
      expect(r.dueAt, DateTime(2026, 3, 10 + expectedDays[box - 1]).toUtc());
    }
  });

  test('box 8 stays box 8 and is rescheduled in 128 days', () {
    final r = scheduler.next(const EightBoxState(8), ReviewAction.remembered, now);
    expect(boxOf(r).box, 8);
    expect(r.dueAt, DateTime(2026, 3, 10 + 128).toUtc());
  });

  test('128 days across a year end lands on local midnight of the right day', () {
    final r = scheduler.next(
      const EightBoxState(7),
      ReviewAction.remembered,
      DateTime(2026, 12, 31, 15, 30),
    );
    expect(r.dueAt, DateTime(2027, 5, 8).toUtc());
    expect(r.dueAt.toLocal().hour, 0);
  });

  test('rejects actions and states it does not own', () {
    expect(() => scheduler.next(const EightBoxState(1), ReviewAction.hard, now),
        throwsArgumentError);
    expect(
        () => scheduler.next(
            const Sm2State(easeFactor: 2.5, intervalDays: 0, repetitions: 0),
            ReviewAction.remembered,
            now),
        throwsArgumentError);
  });
}
```

- [ ] **Step 2: Run to verify failure**

Run: `flutter test test/features/srs`
Expected: FAIL, missing `lib/features/srs/logic/*` files.

- [ ] **Step 3: Implement**

`lib/features/srs/logic/scheduler.dart`:

```dart
enum SchedulerType {
  eightBox('eight_box'),
  sm2('sm2');

  const SchedulerType(this.value);

  /// The value stored in the database.
  final String value;

  static SchedulerType fromValue(String value) =>
      values.firstWhere((t) => t.value == value);
}

enum ReviewAction { forgotten, remembered, again, hard, good, easy }

sealed class ScheduleState {
  const ScheduleState();
}

final class EightBoxState extends ScheduleState {
  const EightBoxState(this.box);
  final int box;
}

final class Sm2State extends ScheduleState {
  const Sm2State({
    required this.easeFactor,
    required this.intervalDays,
    required this.repetitions,
  });
  final double easeFactor;
  final int intervalDays;
  final int repetitions;
}

final class ScheduleResult {
  const ScheduleResult(this.state, this.dueAt);
  final ScheduleState state;

  /// UTC.
  final DateTime dueAt;
}

abstract interface class Scheduler {
  SchedulerType get type;

  /// The review UI renders its buttons from this list.
  List<ReviewAction> get supportedActions;

  ScheduleState get initialState;

  /// Throws [ArgumentError] for a state or action this scheduler does not own.
  ScheduleResult next(ScheduleState state, ReviewAction action, DateTime now);
}
```

`lib/features/srs/logic/due_date.dart`:

```dart
/// 00:00 local time of the learning day `days` after [now], returned as UTC.
///
/// Not `now + days * 24h`: a day is a calendar day, so daylight-saving shifts
/// and late-night reviews do not move the due time.
DateTime startOfLearningDay(DateTime now, int days) {
  final local = now.toLocal();
  return DateTime(local.year, local.month, local.day + days).toUtc();
}
```

`lib/features/srs/logic/eight_box.dart`:

```dart
import 'dart:math';

import 'package:memox/features/srs/logic/due_date.dart';
import 'package:memox/features/srs/logic/scheduler.dart';

const _intervalDaysByBox = [1, 2, 4, 8, 16, 32, 64, 128];
const _firstBox = 1;
const _lastBox = 8;

final class EightBoxScheduler implements Scheduler {
  const EightBoxScheduler();

  @override
  SchedulerType get type => SchedulerType.eightBox;

  @override
  List<ReviewAction> get supportedActions =>
      const [ReviewAction.forgotten, ReviewAction.remembered];

  @override
  ScheduleState get initialState => const EightBoxState(_firstBox);

  @override
  ScheduleResult next(ScheduleState state, ReviewAction action, DateTime now) {
    if (state is! EightBoxState) {
      throw ArgumentError.value(state, 'state', 'expected EightBoxState');
    }
    final box = switch (action) {
      ReviewAction.forgotten => _firstBox,
      ReviewAction.remembered => min(_lastBox, state.box + 1),
      _ => throw ArgumentError.value(action, 'action', 'not an eight_box action'),
    };
    return ScheduleResult(
      EightBoxState(box),
      startOfLearningDay(now, _intervalDaysByBox[box - 1]),
    );
  }
}
```

- [ ] **Step 4: Run to verify pass**

Run: `flutter test test/features/srs`
Expected: PASS (9 tests).

- [ ] **Step 5: Gate and commit**

```bash
flutter analyze
flutter test
git add lib/features/srs test/features/srs
git commit -m "feat(srs): add scheduler types, due-date rule and eight_box" -m "Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

### Task 4: `sm2` scheduler, scheduler lookup and `srs` barrel

**Files:**
- Create: `lib/features/srs/logic/sm2.dart`, `lib/features/srs/logic/schedulers.dart`, `lib/features/srs/srs.dart`
- Test: `test/features/srs/sm2_test.dart`, `test/features/srs/schedulers_test.dart`

**Interfaces:**
- Consumes: everything from Task 3.
- Produces:
  - `class Sm2Scheduler implements Scheduler` (const constructor)
  - `Scheduler schedulerFor(SchedulerType type)` (in `schedulers.dart`)
  - `lib/features/srs/srs.dart` exporting `logic/scheduler.dart` and `logic/schedulers.dart`

Rules (V7 BR-17, BR-18, BR-19): quality `again`=0, `hard`=3, `good`=4, `easy`=5. Ease factor updates **first**: `ef = max(1.3, ef + (0.1 - (5-q) * (0.08 + (5-q) * 0.02)))`, on every review including `q < 3`. Then, if `q < 3`: `repetitions = 0`, `interval = 1`; otherwise `interval` = 1 when `repetitions == 0`, 6 when `repetitions == 1`, else `round(interval * ef)` using the **new** `ef`; then `repetitions += 1`. Initial state: `ef 2.5`, `interval 0`, `repetitions 0`.

- [ ] **Step 1: Write the failing tests**

`test/features/srs/sm2_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/srs/logic/scheduler.dart';
import 'package:memox/features/srs/logic/sm2.dart';

void main() {
  const scheduler = Sm2Scheduler();
  final now = DateTime(2026, 3, 10, 9);

  Sm2State after(Sm2State from, ReviewAction a) =>
      scheduler.next(from, a, now).state as Sm2State;

  Sm2State state(double ef, int interval, int reps) =>
      Sm2State(easeFactor: ef, intervalDays: interval, repetitions: reps);

  test('declares its actions and initial state', () {
    expect(scheduler.type, SchedulerType.sm2);
    expect(scheduler.supportedActions, [
      ReviewAction.again,
      ReviewAction.hard,
      ReviewAction.good,
      ReviewAction.easy,
    ]);
    final s = scheduler.initialState as Sm2State;
    expect((s.easeFactor, s.intervalDays, s.repetitions), (2.5, 0, 0));
  });

  test('again resets repetitions, interval 1, ease drops', () {
    final s = after(state(2.5, 10, 3), ReviewAction.again);
    expect(s.easeFactor, closeTo(1.7, 1e-9));
    expect((s.intervalDays, s.repetitions), (1, 0));
  });

  test('ease factor is updated before it multiplies the interval (BR-18)', () {
    // hard: 2.5 -> 2.36, and 10 * 2.36 = 23.6 -> 24 (not 25).
    final s = after(state(2.5, 10, 2), ReviewAction.hard);
    expect(s.easeFactor, closeTo(2.36, 1e-9));
    expect((s.intervalDays, s.repetitions), (24, 3));
  });

  test('good leaves ease alone and walks 1 -> 6 -> round(interval * ef)', () {
    var s = after(state(2.5, 0, 0), ReviewAction.good);
    expect((s.intervalDays, s.repetitions), (1, 1));
    s = after(s, ReviewAction.good);
    expect((s.intervalDays, s.repetitions), (6, 2));
    s = after(s, ReviewAction.good);
    expect(s.easeFactor, closeTo(2.5, 1e-9));
    expect((s.intervalDays, s.repetitions), (15, 3));
  });

  test('easy raises ease by 0.1', () {
    expect(after(state(2.5, 6, 2), ReviewAction.easy).easeFactor,
        closeTo(2.6, 1e-9));
  });

  test('ease factor never goes below 1.3', () {
    var s = state(2.5, 10, 3);
    for (var i = 0; i < 10; i++) {
      s = after(s, ReviewAction.again);
    }
    expect(s.easeFactor, 1.3);
  });

  test('due date is the start of the learning day', () {
    final r = scheduler.next(state(2.5, 0, 0), ReviewAction.good, now);
    expect(r.dueAt, DateTime(2026, 3, 11).toUtc());
  });

  test('rejects actions and states it does not own', () {
    expect(() => scheduler.next(state(2.5, 0, 0), ReviewAction.forgotten, now),
        throwsArgumentError);
    expect(
        () => scheduler.next(const EightBoxState(1), ReviewAction.good, now),
        throwsArgumentError);
  });
}
```

`test/features/srs/schedulers_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/srs/srs.dart';

void main() {
  test('schedulerFor returns the scheduler of that type', () {
    for (final type in SchedulerType.values) {
      expect(schedulerFor(type).type, type);
    }
  });

  test('SchedulerType round-trips through its stored value', () {
    for (final type in SchedulerType.values) {
      expect(SchedulerType.fromValue(type.value), type);
    }
    expect(() => SchedulerType.fromValue('nope'), throwsStateError);
  });
}
```

- [ ] **Step 2: Run to verify failure**

Run: `flutter test test/features/srs`
Expected: FAIL, missing `sm2.dart`, `schedulers.dart`, `srs.dart`.

- [ ] **Step 3: Implement**

`lib/features/srs/logic/sm2.dart`:

```dart
import 'dart:math';

import 'package:memox/features/srs/logic/due_date.dart';
import 'package:memox/features/srs/logic/scheduler.dart';

const _initialEaseFactor = 2.5;
const _minEaseFactor = 1.3;
const _failingQuality = 3; // quality below this is a lapse
const _firstInterval = 1;
const _secondInterval = 6;
const _qualityByAction = {
  ReviewAction.again: 0,
  ReviewAction.hard: 3,
  ReviewAction.good: 4,
  ReviewAction.easy: 5,
};

final class Sm2Scheduler implements Scheduler {
  const Sm2Scheduler();

  @override
  SchedulerType get type => SchedulerType.sm2;

  @override
  List<ReviewAction> get supportedActions => _qualityByAction.keys.toList();

  @override
  ScheduleState get initialState => const Sm2State(
        easeFactor: _initialEaseFactor,
        intervalDays: 0,
        repetitions: 0,
      );

  @override
  ScheduleResult next(ScheduleState state, ReviewAction action, DateTime now) {
    if (state is! Sm2State) {
      throw ArgumentError.value(state, 'state', 'expected Sm2State');
    }
    final q = _qualityByAction[action] ??
        (throw ArgumentError.value(action, 'action', 'not an sm2 action'));

    final miss = 5 - q;
    final easeFactor = max(
      _minEaseFactor,
      state.easeFactor + (0.1 - miss * (0.08 + miss * 0.02)),
    );

    final int intervalDays;
    final int repetitions;
    if (q < _failingQuality) {
      intervalDays = _firstInterval;
      repetitions = 0;
    } else {
      intervalDays = switch (state.repetitions) {
        0 => _firstInterval,
        1 => _secondInterval,
        _ => (state.intervalDays * easeFactor).round(),
      };
      repetitions = state.repetitions + 1;
    }

    return ScheduleResult(
      Sm2State(
        easeFactor: easeFactor,
        intervalDays: intervalDays,
        repetitions: repetitions,
      ),
      startOfLearningDay(now, intervalDays),
    );
  }
}
```

`lib/features/srs/logic/schedulers.dart`:

```dart
import 'package:memox/features/srs/logic/eight_box.dart';
import 'package:memox/features/srs/logic/scheduler.dart';
import 'package:memox/features/srs/logic/sm2.dart';

Scheduler schedulerFor(SchedulerType type) => switch (type) {
      SchedulerType.eightBox => const EightBoxScheduler(),
      SchedulerType.sm2 => const Sm2Scheduler(),
    };
```

`lib/features/srs/srs.dart`:

```dart
export 'package:memox/features/srs/logic/scheduler.dart';
export 'package:memox/features/srs/logic/schedulers.dart';
```

- [ ] **Step 4: Run to verify pass**

Run: `flutter test test/features/srs`
Expected: PASS.

- [ ] **Step 5: Gate and commit**

```bash
flutter analyze
flutter test
git add lib/features/srs test/features/srs
git commit -m "feat(srs): add sm2 scheduler, scheduler lookup and barrel" -m "Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

### Task 5: Database schema and `AppDatabase`

**Files:**
- Create: `lib/features/decks/data/deck.drift`, `lib/features/cards/data/card.drift`, `lib/features/srs/data/srs.drift`, `lib/features/study/data/study_session.drift`, `lib/core/db/app_database.dart`, `test/support/test_database.dart`, `drift_schemas/drift_schema_v1.json` (generated)
- Test: `test/core/db/schema_test.dart`

**Interfaces:**
- Consumes: `mapDatabaseError`, `ConstraintFailure` (Task 2).
- Produces:
  - `class AppDatabase extends _$AppDatabase` with constructor `AppDatabase(QueryExecutor executor)`, `schemaVersion == 1`, foreign keys ON at open.
  - Generated accessors: `db.deck`, `db.card`, `db.cardSchedule`, `db.reviewLog`, `db.studySession`; row classes `Deck`, `CardRow`, `CardSchedule`, `ReviewLog`, `StudySession`; companions `DeckCompanion`, `CardRowCompanion`, ... (names follow the `AS` clause).
  - `AppDatabase openTestDatabase()` in `test/support/test_database.dart` (in-memory).

Column names in SQL are snake_case; Drift exposes them as camelCase (`root_id` → `rootId`). Datetimes are stored by Drift as UTC unix seconds.

- [ ] **Step 1: Write the `.drift` files**

`lib/features/decks/data/deck.drift`:

```sql
CREATE TABLE deck (
  id TEXT NOT NULL PRIMARY KEY,
  parent_id TEXT REFERENCES deck (id) ON DELETE CASCADE,
  root_id TEXT NOT NULL,
  depth INTEGER NOT NULL CHECK (depth BETWEEN 1 AND 10),
  name TEXT NOT NULL,
  content_type TEXT NOT NULL DEFAULT 'unset'
    CHECK (content_type IN ('unset', 'card', 'deck')),
  -- scheduler and generation live on the root only; descendants resolve them via root_id
  scheduler TEXT CHECK (scheduler IN ('eight_box', 'sm2')),
  generation INTEGER,
  first_reviewed_at DATETIME,
  created_at DATETIME NOT NULL,
  CHECK ((parent_id IS NULL) = (scheduler IS NOT NULL)),
  CHECK ((parent_id IS NULL) = (generation IS NOT NULL)),
  CHECK ((parent_id IS NULL) = (depth = 1)),
  CHECK (parent_id IS NOT NULL OR content_type = 'deck'),
  CHECK (parent_id IS NOT NULL OR root_id = id)
) AS Deck;

CREATE INDEX deck_parent_id ON deck (parent_id);
CREATE INDEX deck_root_id ON deck (root_id);
```

`lib/features/cards/data/card.drift`:

```sql
import 'package:memox/features/decks/data/deck.drift';

CREATE TABLE card (
  id TEXT NOT NULL PRIMARY KEY,
  deck_id TEXT NOT NULL REFERENCES deck (id) ON DELETE CASCADE,
  front TEXT NOT NULL,
  back TEXT NOT NULL,
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL
) AS CardRow;

CREATE INDEX card_deck_id ON card (deck_id);
```

`CardRow`, not `Card`, so the generated class never collides with Flutter's `Card` widget.

`lib/features/srs/data/srs.drift`:

```sql
import 'package:memox/features/cards/data/card.drift';

CREATE TABLE card_schedule (
  card_id TEXT NOT NULL PRIMARY KEY REFERENCES card (id) ON DELETE CASCADE,
  generation INTEGER NOT NULL,
  current_box INTEGER CHECK (current_box BETWEEN 1 AND 8),
  ease_factor REAL,
  interval_days INTEGER,
  repetitions INTEGER,
  due_at DATETIME,
  -- exactly one scheduler's state: box, or the three sm2 columns together
  CHECK ((current_box IS NOT NULL) <> (ease_factor IS NOT NULL)),
  CHECK ((ease_factor IS NULL) = (interval_days IS NULL)),
  CHECK ((ease_factor IS NULL) = (repetitions IS NULL))
) AS CardSchedule;

CREATE INDEX card_schedule_due_at ON card_schedule (due_at);

-- session_id has no foreign key on purpose: srs must not depend on study's table.
CREATE TABLE review_log (
  id TEXT NOT NULL PRIMARY KEY,
  card_id TEXT NOT NULL REFERENCES card (id) ON DELETE CASCADE,
  session_id TEXT NOT NULL,
  generation INTEGER NOT NULL,
  kind TEXT NOT NULL CHECK (kind IN ('learning', 'scheduled', 'relearning')),
  action TEXT NOT NULL
    CHECK (action IN ('forgotten', 'remembered', 'again', 'hard', 'good', 'easy')),
  reviewed_at DATETIME NOT NULL
) AS ReviewLog;

CREATE INDEX review_log_card_id ON review_log (card_id, reviewed_at);

CREATE TRIGGER review_log_append_only
BEFORE UPDATE ON review_log
BEGIN
  SELECT RAISE(ABORT, 'review_log is append-only');
END;
```

`lib/features/study/data/study_session.drift`:

```sql
import 'package:memox/features/decks/data/deck.drift';

CREATE TABLE study_session (
  id TEXT NOT NULL PRIMARY KEY,
  deck_id TEXT NOT NULL REFERENCES deck (id) ON DELETE CASCADE,
  root_deck_id TEXT NOT NULL,
  scheduler_generation INTEGER NOT NULL,
  status TEXT NOT NULL CHECK (
    status IN ('in_progress', 'completed', 'abandoned', 'invalidated', 'failed')
  ),
  end_reason TEXT CHECK (
    end_reason IN (
      'user_exit', 'interrupted', 'scheduler_reset', 'scheduler_changed',
      'stale_generation', 'persistence_error', 'content_deleted'
    )
  ),
  started_at DATETIME NOT NULL,
  ended_at DATETIME,
  CHECK (
    (status IN ('in_progress', 'completed') AND end_reason IS NULL)
    OR (status = 'abandoned' AND end_reason IN ('user_exit', 'interrupted'))
    OR (status = 'invalidated' AND end_reason IN (
      'scheduler_reset', 'scheduler_changed', 'stale_generation', 'content_deleted'
    ))
    OR (status = 'failed' AND end_reason = 'persistence_error')
  ),
  CHECK ((status = 'in_progress') = (ended_at IS NULL))
) AS StudySession;
```

- [ ] **Step 2: Write `AppDatabase`**

`lib/core/db/app_database.dart`:

```dart
import 'package:drift/drift.dart';

part 'app_database.g.dart';

@DriftDatabase(
  include: {
    'package:memox/features/decks/data/deck.drift',
    'package:memox/features/cards/data/card.drift',
    'package:memox/features/srs/data/srs.drift',
    'package:memox/features/study/data/study_session.drift',
  },
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
```

`test/support/test_database.dart`:

```dart
import 'package:drift/native.dart';
import 'package:memox/core/db/app_database.dart';

AppDatabase openTestDatabase() => AppDatabase(NativeDatabase.memory());
```

- [ ] **Step 3: Generate code**

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected: `app_database.g.dart` generated with no errors. If a `.drift` file fails to parse, the error names the file and line; fix the SQL there.

- [ ] **Step 4: Write the failing schema tests**

`test/core/db/schema_test.dart`:

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/db/app_database.dart';
import 'package:memox/core/failure.dart';

import '../../support/test_database.dart';

Future<void> _root(AppDatabase db, String id, {String scheduler = 'eight_box'}) =>
    db.customStatement(
      "INSERT INTO deck (id, parent_id, root_id, depth, name, content_type, "
      "scheduler, generation, created_at) VALUES (?, NULL, ?, 1, 'r', 'deck', ?, 1, 0)",
      [id, id, scheduler],
    );

Future<void> _child(AppDatabase db, String id, String parent, String root,
        int depth, {String content = 'unset'}) =>
    db.customStatement(
      'INSERT INTO deck (id, parent_id, root_id, depth, name, content_type, created_at) '
      "VALUES (?, ?, ?, ?, 'c', ?, 0)",
      [id, parent, root, depth, content],
    );

Future<int> _count(AppDatabase db, String table) async {
  final row = await db.customSelect('SELECT COUNT(*) AS n FROM $table').getSingle();
  return row.read<int>('n');
}

Future<Failure> _failureOf(Future<void> Function() body) async {
  try {
    await body();
  } catch (e) {
    return mapDatabaseError(e);
  }
  fail('expected the statement to fail');
}

void main() {
  late AppDatabase db;
  setUp(() => db = openTestDatabase());
  tearDown(() => db.close());

  test('foreign keys are enforced', () async {
    final row = await db.customSelect('PRAGMA foreign_keys').getSingle();
    expect(row.read<int>('foreign_keys'), 1);
  });

  test('depth 11 violates a constraint and maps to ConstraintFailure', () async {
    await _root(db, 'r');
    final f = await _failureOf(() => _child(db, 'x', 'r', 'r', 11));
    expect(f, isA<ConstraintFailure>());
  });

  test('a sub-deck cannot carry a scheduler', () async {
    await _root(db, 'r');
    final f = await _failureOf(() => db.customStatement(
          'INSERT INTO deck (id, parent_id, root_id, depth, name, scheduler, generation, created_at) '
          "VALUES ('s', 'r', 'r', 2, 'x', 'sm2', 1, 0)",
        ));
    expect(f, isA<ConstraintFailure>());
  });

  test('a root deck must be content_type deck and its own root', () async {
    final f = await _failureOf(() => db.customStatement(
          "INSERT INTO deck (id, parent_id, root_id, depth, name, content_type, scheduler, generation, created_at) "
          "VALUES ('r', NULL, 'r', 1, 'x', 'unset', 'sm2', 1, 0)",
        ));
    expect(f, isA<ConstraintFailure>());
  });

  test('deleting a root cascades to sub-decks, cards, schedules and logs', () async {
    await _root(db, 'r');
    await _child(db, 's', 'r', 'r', 2, content: 'card');
    await db.customStatement(
      "INSERT INTO card (id, deck_id, front, back, created_at, updated_at) VALUES ('c', 's', 'f', 'b', 0, 0)",
    );
    await db.customStatement(
      "INSERT INTO card_schedule (card_id, generation, current_box) VALUES ('c', 1, 1)",
    );
    await db.customStatement(
      "INSERT INTO review_log (id, card_id, session_id, generation, kind, action, reviewed_at) "
      "VALUES ('l', 'c', 'ses', 1, 'scheduled', 'remembered', 0)",
    );

    await db.customStatement("DELETE FROM deck WHERE id = 'r'");

    for (final table in ['deck', 'card', 'card_schedule', 'review_log']) {
      expect(await _count(db, table), 0, reason: table);
    }
  });

  test('a schedule row carries exactly one scheduler state', () async {
    await _root(db, 'r');
    await _child(db, 's', 'r', 'r', 2, content: 'card');
    await db.customStatement(
      "INSERT INTO card (id, deck_id, front, back, created_at, updated_at) VALUES ('c', 's', 'f', 'b', 0, 0)",
    );
    final f = await _failureOf(() => db.customStatement(
          "INSERT INTO card_schedule (card_id, generation, current_box, ease_factor, interval_days, repetitions) "
          "VALUES ('c', 1, 1, 2.5, 0, 0)",
        ));
    expect(f, isA<ConstraintFailure>());
  });

  test('review_log is append-only', () async {
    await _root(db, 'r');
    await _child(db, 's', 'r', 'r', 2, content: 'card');
    await db.customStatement(
      "INSERT INTO card (id, deck_id, front, back, created_at, updated_at) VALUES ('c', 's', 'f', 'b', 0, 0)",
    );
    await db.customStatement(
      "INSERT INTO review_log (id, card_id, session_id, generation, kind, action, reviewed_at) "
      "VALUES ('l', 'c', 'ses', 1, 'scheduled', 'good', 0)",
    );
    await expectLater(
      db.customStatement("UPDATE review_log SET action = 'easy' WHERE id = 'l'"),
      throwsA(anything),
    );
  });

  test('study_session accepts only the valid status x end_reason pairs', () async {
    await _root(db, 'r');
    Future<void> insert(String status, String? reason, {int? ended}) =>
        db.customStatement(
          'INSERT INTO study_session (id, deck_id, root_deck_id, scheduler_generation, status, end_reason, started_at, ended_at) '
          "VALUES (?, 'r', 'r', 1, ?, ?, 0, ?)",
          ['$status-${reason ?? 'none'}', status, reason, ended],
        );

    await insert('in_progress', null);
    await insert('completed', null, ended: 1);
    await insert('abandoned', 'user_exit', ended: 1);
    await insert('invalidated', 'stale_generation', ended: 1);
    await insert('failed', 'persistence_error', ended: 1);

    expect(await _failureOf(() => insert('completed', 'user_exit', ended: 1)),
        isA<ConstraintFailure>());
    expect(await _failureOf(() => insert('abandoned', 'stale_generation', ended: 1)),
        isA<ConstraintFailure>());
    expect(await _failureOf(() => insert('in_progress', null, ended: 1)),
        isA<ConstraintFailure>());
  });

  test('a snapshot exists for the current schema version', () {
    final snapshot = File('drift_schemas/drift_schema_v${db.schemaVersion}.json');
    expect(snapshot.existsSync(), isTrue,
        reason: 'run: dart run drift_dev schema dump lib/core/db/app_database.dart drift_schemas/');
  });
}
```

- [ ] **Step 5: Run to verify the expected failure**

Run: `flutter test test/core/db/schema_test.dart`
Expected: everything passes **except** the last test (no snapshot yet). If a constraint test returns `UnexpectedFailure` instead of `ConstraintFailure`, the exception arrives wrapped or with another code: inspect `f.cause`, then extend `mapDatabaseError` in `lib/core/failure.dart` (and its test) accordingly.

- [ ] **Step 6: Dump the v1 snapshot**

```bash
dart run drift_dev schema dump lib/core/db/app_database.dart drift_schemas/
```

Expected: `drift_schemas/drift_schema_v1.json` created.

- [ ] **Step 7: Run to verify pass**

Run: `flutter test test/core`
Expected: PASS.

- [ ] **Step 8: Gate and commit**

```bash
flutter analyze
flutter test
git add lib/core/db/app_database.dart lib/features/*/data test/support test/core/db drift_schemas
git commit -m "feat(db): add v1 schema and AppDatabase with constraint tests" -m "Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

### Task 6: Deck tree rules (pure) and `decks` barrel

**Files:**
- Create: `lib/features/decks/logic/deck_rules.dart`, `lib/features/decks/decks.dart`
- Test: `test/features/decks/deck_rules_test.dart`

**Interfaces:**
- Consumes: `Rejection` (Task 2).
- Produces (in `deck_rules.dart`, re-exported by `decks.dart`):
  - `const int maxDeckDepth = 10`
  - `enum ContentType { unset, card, deck }` (stored as `.name`)
  - `Rejection? checkDeckName(String name)`
  - `Rejection? checkAddChildDeck({required int parentDepth, required ContentType parentContent})`
  - `Rejection? checkAddCard({required bool parentIsRoot, required ContentType parentContent})`
  - `Rejection? checkMoveSubtree({required int subtreeHeight, required int newParentDepth, required ContentType newParentContent, required (String, int) currentRoot, required (String, int) targetRoot})`, where a root is `(scheduler value, generation)` and `subtreeHeight` is the number of levels below the moved deck (0 for a leaf)

All functions return `null` when allowed and the `Rejection` otherwise.

- [ ] **Step 1: Write the failing tests**

`test/features/decks/deck_rules_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/outcome.dart';
import 'package:memox/features/decks/decks.dart';

void main() {
  group('checkDeckName', () {
    test('rejects blank and whitespace-only names', () {
      for (final name in ['', '   ', '\n\t ']) {
        expect(checkDeckName(name), Rejection.blankName, reason: name);
      }
    });

    test('accepts non-blank names including Vietnamese and emoji', () {
      for (final name in ['Từ vựng', 'A', '📚 TOPIK']) {
        expect(checkDeckName(name), isNull, reason: name);
      }
    });
  });

  group('checkAddChildDeck', () {
    test('allows a child up to level 10', () {
      expect(checkAddChildDeck(parentDepth: 9, parentContent: ContentType.deck), isNull);
    });

    test('refuses a child below level 10', () {
      expect(checkAddChildDeck(parentDepth: 10, parentContent: ContentType.unset),
          Rejection.maxDepthExceeded);
    });

    test('refuses a deck under a parent that holds cards', () {
      expect(checkAddChildDeck(parentDepth: 2, parentContent: ContentType.card),
          Rejection.wrongContentType);
    });

    test('allows a deck under unset or deck parents', () {
      for (final c in [ContentType.unset, ContentType.deck]) {
        expect(checkAddChildDeck(parentDepth: 2, parentContent: c), isNull);
      }
    });
  });

  group('checkAddCard', () {
    test('a root deck never holds cards', () {
      expect(checkAddCard(parentIsRoot: true, parentContent: ContentType.deck),
          Rejection.rootHoldsOnlyDecks);
    });

    test('refuses a card under a parent that holds decks', () {
      expect(checkAddCard(parentIsRoot: false, parentContent: ContentType.deck),
          Rejection.wrongContentType);
    });

    test('allows a card under unset or card parents', () {
      for (final c in [ContentType.unset, ContentType.card]) {
        expect(checkAddCard(parentIsRoot: false, parentContent: c), isNull);
      }
    });
  });

  group('checkMoveSubtree', () {
    const rootA = ('eight_box', 1);

    Rejection? move({
      int height = 0,
      int parentDepth = 2,
      ContentType content = ContentType.deck,
      (String, int) from = rootA,
      (String, int) to = rootA,
    }) =>
        checkMoveSubtree(
          subtreeHeight: height,
          newParentDepth: parentDepth,
          newParentContent: content,
          currentRoot: from,
          targetRoot: to,
        );

    test('allows a move whose deepest descendant lands on level 10', () {
      expect(move(height: 1, parentDepth: 8), isNull);
    });

    test('refuses a move that pushes the deepest descendant past level 10', () {
      expect(move(height: 2, parentDepth: 8), Rejection.maxDepthExceeded);
    });

    test('refuses a move under a parent that holds cards', () {
      expect(move(content: ContentType.card), Rejection.wrongContentType);
    });

    test('refuses a move to a root with another scheduler', () {
      expect(move(to: ('sm2', 1)), Rejection.schedulerMismatch);
    });

    test('refuses a move to a root with another generation', () {
      expect(move(to: ('eight_box', 2)), Rejection.schedulerMismatch);
    });
  });
}
```

- [ ] **Step 2: Run to verify failure**

Run: `flutter test test/features/decks`
Expected: FAIL, missing `decks.dart`.

- [ ] **Step 3: Implement**

`lib/features/decks/logic/deck_rules.dart`:

```dart
import 'package:memox/core/outcome.dart';

/// The root is level 1.
const int maxDeckDepth = 10;

/// What a sub-deck holds. Stored as `.name`. A new sub-deck is `unset`; its
/// first child fixes the kind, and emptying it puts it back to `unset`.
enum ContentType { unset, card, deck }

Rejection? checkDeckName(String name) =>
    name.trim().isEmpty ? Rejection.blankName : null;

Rejection? checkAddChildDeck({
  required int parentDepth,
  required ContentType parentContent,
}) {
  if (parentDepth + 1 > maxDeckDepth) return Rejection.maxDepthExceeded;
  if (parentContent == ContentType.card) return Rejection.wrongContentType;
  return null;
}

Rejection? checkAddCard({
  required bool parentIsRoot,
  required ContentType parentContent,
}) {
  if (parentIsRoot) return Rejection.rootHoldsOnlyDecks;
  if (parentContent == ContentType.deck) return Rejection.wrongContentType;
  return null;
}

/// [subtreeHeight] is the number of levels below the moved deck (0 for a leaf).
/// A root is `(scheduler value, generation)`; moving across roots is refused
/// when they differ, never converted.
Rejection? checkMoveSubtree({
  required int subtreeHeight,
  required int newParentDepth,
  required ContentType newParentContent,
  required (String, int) currentRoot,
  required (String, int) targetRoot,
}) {
  if (newParentContent == ContentType.card) return Rejection.wrongContentType;
  if (newParentDepth + 1 + subtreeHeight > maxDeckDepth) {
    return Rejection.maxDepthExceeded;
  }
  if (currentRoot != targetRoot) return Rejection.schedulerMismatch;
  return null;
}
```

`lib/features/decks/decks.dart`:

```dart
export 'package:memox/features/decks/logic/deck_rules.dart';
```

- [ ] **Step 4: Run to verify pass**

Run: `flutter test test/features/decks test/architecture`
Expected: PASS. The boundary test now sees `lib/features/decks/logic/` and confirms it imports no Flutter/Drift/`core/db`.

- [ ] **Step 5: Gate and commit**

```bash
flutter analyze
flutter test
git add lib/features/decks test/features/decks
git commit -m "feat(decks): add pure deck tree rules and barrel" -m "Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

### Task 7: `DeckStore` (transactional deck-tree operations)

**Files:**
- Create: `lib/features/decks/data/deck_store.dart`
- Modify: `lib/features/decks/decks.dart` (add export)
- Test: `test/features/decks/deck_store_test.dart`

**Interfaces:**
- Consumes: `AppDatabase`, `Deck` (Task 5); `Outcome`, `Ok`, `Rejected`, `Rejection`, `newId` (Task 2); deck rules and `ContentType` (Task 6); `SchedulerType` from the `srs` barrel (Task 4).
- Produces (`DeckStore(AppDatabase db, {DateTime Function()? now})`):
  - `Future<Deck?> deckById(String id)`
  - `Future<Outcome<String>> createRootDeck({required String name, required SchedulerType scheduler})` returns the new id; root: depth 1, `root_id = id`, `content_type = deck`, generation 1
  - `Future<Outcome<String>> createSubDeck({required String parentId, required String name})`
  - `Future<Outcome<void>> deleteDeck(String id)` (cascades)
  - `Future<Outcome<void>> moveDeck({required String id, required String newParentId})`
  - `Future<void> claimContentType(String deckId, ContentType kind)` sets the kind only if the deck is `unset`
  - `Future<void> releaseContentTypeIfEmpty(String deckId)` sets a non-root deck back to `unset` when it has no child deck and no card
  - The last two are for other stores to call **inside their own transaction**.

- [ ] **Step 1: Write the failing tests**

`test/features/decks/deck_store_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/db/app_database.dart';
import 'package:memox/core/outcome.dart';
import 'package:memox/features/decks/data/deck_store.dart';
import 'package:memox/features/decks/decks.dart';
import 'package:memox/features/srs/srs.dart';

import '../../support/test_database.dart';

String idOf(Outcome<String> o) => (o as Ok<String>).value;

Rejection? reasonOf(Outcome<Object?> o) => o is Rejected ? o.reason : null;

Future<List<Map<String, dynamic>>> tree(AppDatabase db) async => (await db
        .customSelect(
            'SELECT id, parent_id, root_id, depth, content_type FROM deck ORDER BY id')
        .get())
    .map((r) => r.data)
    .toList();

Future<int> count(AppDatabase db, String table) async =>
    (await db.customSelect('SELECT COUNT(*) AS n FROM $table').getSingle())
        .read<int>('n');

Future<void> addCardRaw(AppDatabase db, String id, String deckId) =>
    db.customStatement(
      'INSERT INTO card (id, deck_id, front, back, created_at, updated_at) '
      "VALUES (?, ?, 'f', 'b', 0, 0)",
      [id, deckId],
    );

void main() {
  late AppDatabase db;
  late DeckStore store;

  setUp(() {
    db = openTestDatabase();
    store = DeckStore(db, now: () => DateTime.utc(2026, 1, 1));
  });
  tearDown(() => db.close());

  Future<String> root([SchedulerType s = SchedulerType.eightBox]) async =>
      idOf(await store.createRootDeck(name: 'Root', scheduler: s));

  Future<String> sub(String parent, [String name = 'Sub']) async =>
      idOf(await store.createSubDeck(parentId: parent, name: name));

  /// Root plus sub-decks down to [levels]; returns ids from level 1.
  Future<List<String>> chain(int levels) async {
    final ids = [await root()];
    for (var i = 2; i <= levels; i++) {
      ids.add(await sub(ids.last, 'L$i'));
    }
    return ids;
  }

  group('createRootDeck', () {
    test('stores a level-1 root with its scheduler and generation 1', () async {
      final id = idOf(await store.createRootDeck(
          name: '  TOPIK  ', scheduler: SchedulerType.sm2));
      final d = (await store.deckById(id))!;
      expect(d.name, 'TOPIK');
      expect((d.parentId, d.rootId, d.depth), (null, id, 1));
      expect((d.contentType, d.scheduler, d.generation), ('deck', 'sm2', 1));
    });

    test('rejects a blank name and stores nothing', () async {
      final o = await store.createRootDeck(
          name: '   ', scheduler: SchedulerType.eightBox);
      expect(reasonOf(o), Rejection.blankName);
      expect(await count(db, 'deck'), 0);
    });
  });

  group('createSubDeck', () {
    test('inherits the root, goes one level down and starts unset', () async {
      final r = await root();
      final s = (await store.deckById(await sub(r)))!;
      expect((s.parentId, s.rootId, s.depth, s.contentType), (r, r, 2, 'unset'));
      expect(s.scheduler, isNull);
    });

    test('the first child deck sets the parent to deck', () async {
      final r = await root();
      final a = await sub(r);
      await sub(a);
      expect((await store.deckById(a))!.contentType, 'deck');
    });

    test('rejects a blank name and a missing parent', () async {
      final r = await root();
      expect(reasonOf(await store.createSubDeck(parentId: r, name: ' ')),
          Rejection.blankName);
      expect(reasonOf(await store.createSubDeck(parentId: 'nope', name: 'x')),
          Rejection.notFound);
      expect(await count(db, 'deck'), 1);
    });

    test('refuses level 11 and writes nothing', () async {
      final ids = await chain(10);
      final before = await tree(db);
      expect(reasonOf(await store.createSubDeck(parentId: ids.last, name: 'x')),
          Rejection.maxDepthExceeded);
      expect(await tree(db), before);
    });

    test('refuses a deck under a deck that holds cards', () async {
      final s = await sub(await root());
      await addCardRaw(db, 'c', s);
      await store.claimContentType(s, ContentType.card);
      expect(reasonOf(await store.createSubDeck(parentId: s, name: 'x')),
          Rejection.wrongContentType);
    });
  });

  group('deleteDeck', () {
    test('deleting the last child puts the parent back to unset', () async {
      final r = await root();
      final a = await sub(r);
      final b = await sub(a);
      expect(await store.deleteDeck(b), isA<Ok<void>>());
      expect((await store.deckById(a))!.contentType, 'unset');
      expect((await store.deckById(r))!.contentType, 'deck'); // root stays deck
    });

    test('a parent that still has another child stays deck', () async {
      final a = await sub(await root());
      final b1 = await sub(a, 'b1');
      await sub(a, 'b2');
      await store.deleteDeck(b1);
      expect((await store.deckById(a))!.contentType, 'deck');
    });

    test('cascades to descendants and cards', () async {
      final a = await sub(await root());
      final b = await sub(a);
      await addCardRaw(db, 'c', b);
      await store.deleteDeck(a);
      expect(await count(db, 'deck'), 1);
      expect(await count(db, 'card'), 0);
    });

    test('an unknown deck is notFound', () async {
      expect(reasonOf(await store.deleteDeck('nope')), Rejection.notFound);
    });
  });

  group('moveDeck', () {
    test('re-roots and re-levels the whole subtree', () async {
      final r = await root();
      final a = await sub(r, 'A');
      final a1 = await sub(a, 'A1');
      final a11 = await sub(a1, 'A11');
      final b = await sub(r, 'B');

      expect(await store.moveDeck(id: a, newParentId: b), isA<Ok<void>>());

      Future<(int, String, String?)> at(String id) async {
        final d = (await store.deckById(id))!;
        return (d.depth, d.rootId, d.parentId);
      }

      expect(await at(a), (3, r, b));
      expect(await at(a1), (4, r, a));
      expect(await at(a11), (5, r, a1));
      expect((await store.deckById(b))!.contentType, 'deck');
    });

    test('moves across roots that share scheduler and generation', () async {
      final r1 = await root();
      final r2 = await root();
      final a = await sub(r1);
      final a1 = await sub(a);
      await store.moveDeck(id: a, newParentId: r2);
      expect((await store.deckById(a))!.rootId, r2);
      expect((await store.deckById(a1))!.rootId, r2);
      expect((await store.deckById(a1))!.depth, 3);
    });

    test('emptying the old parent puts it back to unset', () async {
      final r = await root();
      final x = await sub(r, 'X');
      final a = await sub(x, 'A');
      await store.moveDeck(id: a, newParentId: r);
      expect((await store.deckById(x))!.contentType, 'unset');
      expect((await store.deckById(a))!.depth, 2);
    });

    test('moving under the current parent is a no-op', () async {
      final r = await root();
      final a = await sub(r);
      final before = await tree(db);
      expect(await store.moveDeck(id: a, newParentId: r), isA<Ok<void>>());
      expect(await tree(db), before);
    });

    test('refuses a move onto itself or into its own descendant', () async {
      final r = await root();
      final a = await sub(r);
      final a1 = await sub(a);
      final before = await tree(db);
      expect(reasonOf(await store.moveDeck(id: a, newParentId: a)),
          Rejection.cannotMoveIntoOwnSubtree);
      expect(reasonOf(await store.moveDeck(id: a, newParentId: a1)),
          Rejection.cannotMoveIntoOwnSubtree);
      expect(await tree(db), before);
    });

    test('refuses to move a root', () async {
      final r1 = await root();
      final r2 = await root();
      expect(reasonOf(await store.moveDeck(id: r1, newParentId: r2)),
          Rejection.rootCannotMove);
    });

    test('refuses a move to a root with another scheduler', () async {
      final r1 = await root();
      final r2 = await root(SchedulerType.sm2);
      final a = await sub(r1);
      final before = await tree(db);
      expect(reasonOf(await store.moveDeck(id: a, newParentId: r2)),
          Rejection.schedulerMismatch);
      expect(await tree(db), before);
    });

    test('refuses a move to a root with another generation', () async {
      final r1 = await root();
      final r2 = await root();
      final a = await sub(r1);
      await db.customStatement("UPDATE deck SET generation = 2 WHERE id = ?", [r2]);
      expect(reasonOf(await store.moveDeck(id: a, newParentId: r2)),
          Rejection.schedulerMismatch);
    });

    test('refuses a move that pushes a descendant past level 10', () async {
      final ids = await chain(9); // levels 1..9
      final a = await sub(ids[0], 'A'); // level 2
      await sub(a, 'A1'); // level 3
      final before = await tree(db);
      // A would land at level 10, so A1 at level 11.
      expect(reasonOf(await store.moveDeck(id: a, newParentId: ids[8])),
          Rejection.maxDepthExceeded);
      expect(await tree(db), before);
    });

    test('refuses a move under a deck that holds cards', () async {
      final r = await root();
      final a = await sub(r, 'A');
      final holder = await sub(r, 'H');
      await addCardRaw(db, 'c', holder);
      await store.claimContentType(holder, ContentType.card);
      expect(reasonOf(await store.moveDeck(id: a, newParentId: holder)),
          Rejection.wrongContentType);
    });

    test('unknown ids are notFound', () async {
      final r = await root();
      expect(reasonOf(await store.moveDeck(id: 'nope', newParentId: r)),
          Rejection.notFound);
    });
  });
}
```

- [ ] **Step 2: Run to verify failure**

Run: `flutter test test/features/decks/deck_store_test.dart`
Expected: FAIL, missing `deck_store.dart`.

- [ ] **Step 3: Implement**

`lib/features/decks/data/deck_store.dart`:

```dart
import 'package:drift/drift.dart';
import 'package:memox/core/db/app_database.dart';
import 'package:memox/core/ids.dart';
import 'package:memox/core/outcome.dart';
import 'package:memox/features/decks/logic/deck_rules.dart';
import 'package:memox/features/srs/srs.dart';

const _firstGeneration = 1;

/// Recursive CTE naming a deck and every descendant; bind the deck id once.
const _subtreeCte = 'WITH RECURSIVE subtree(id) AS ('
    'SELECT id FROM deck WHERE id = ? '
    'UNION ALL SELECT d.id FROM deck d JOIN subtree s ON d.parent_id = s.id)';

class DeckStore {
  DeckStore(this._db, {DateTime Function()? now}) : _now = now ?? DateTime.now;

  final AppDatabase _db;
  final DateTime Function() _now;

  Future<Deck?> deckById(String id) =>
      (_db.select(_db.deck)..where((d) => d.id.equals(id))).getSingleOrNull();

  Future<Outcome<String>> createRootDeck({
    required String name,
    required SchedulerType scheduler,
  }) async {
    final reason = checkDeckName(name);
    if (reason != null) return Rejected<String>(reason);
    final id = newId();
    await _db.into(_db.deck).insert(
          DeckCompanion.insert(
            id: id,
            rootId: id,
            depth: 1,
            name: name.trim(),
            createdAt: _now(),
            contentType: Value(ContentType.deck.name),
            scheduler: Value(scheduler.value),
            generation: const Value(_firstGeneration),
          ),
        );
    return Ok(id);
  }

  Future<Outcome<String>> createSubDeck({
    required String parentId,
    required String name,
  }) async {
    final blank = checkDeckName(name);
    if (blank != null) return Rejected<String>(blank);
    return _db.transaction<Outcome<String>>(() async {
      final parent = await deckById(parentId);
      if (parent == null) return const Rejected<String>(Rejection.notFound);
      final reason = checkAddChildDeck(
        parentDepth: parent.depth,
        parentContent: _contentOf(parent),
      );
      if (reason != null) return Rejected<String>(reason);
      final id = newId();
      await _db.into(_db.deck).insert(
            DeckCompanion.insert(
              id: id,
              parentId: Value(parent.id),
              rootId: parent.rootId,
              depth: parent.depth + 1,
              name: name.trim(),
              createdAt: _now(),
            ),
          );
      await claimContentType(parent.id, ContentType.deck);
      return Ok(id);
    });
  }

  Future<Outcome<void>> deleteDeck(String id) {
    return _db.transaction<Outcome<void>>(() async {
      final deck = await deckById(id);
      if (deck == null) return const Rejected<void>(Rejection.notFound);
      await (_db.delete(_db.deck)..where((d) => d.id.equals(id))).go();
      final parentId = deck.parentId;
      if (parentId != null) await releaseContentTypeIfEmpty(parentId);
      return const Ok<void>(null);
    });
  }

  Future<Outcome<void>> moveDeck({
    required String id,
    required String newParentId,
  }) {
    return _db.transaction<Outcome<void>>(() async {
      final deck = await deckById(id);
      final target = await deckById(newParentId);
      if (deck == null || target == null) {
        return const Rejected<void>(Rejection.notFound);
      }
      final oldParentId = deck.parentId;
      if (oldParentId == null) {
        return const Rejected<void>(Rejection.rootCannotMove);
      }
      if (await _inSubtree(subtreeOf: id, candidate: target.id)) {
        return const Rejected<void>(Rejection.cannotMoveIntoOwnSubtree);
      }
      if (oldParentId == target.id) return const Ok<void>(null);

      final currentRoot = (await deckById(deck.rootId))!;
      final targetRoot = (await deckById(target.rootId))!;
      final reason = checkMoveSubtree(
        subtreeHeight: await _deepestLevel(id) - deck.depth,
        newParentDepth: target.depth,
        newParentContent: _contentOf(target),
        currentRoot: (currentRoot.scheduler!, currentRoot.generation!),
        targetRoot: (targetRoot.scheduler!, targetRoot.generation!),
      );
      if (reason != null) return Rejected<void>(reason);

      await _db.customUpdate(
        '$_subtreeCte UPDATE deck SET root_id = ?, depth = depth + ? '
        'WHERE id IN (SELECT id FROM subtree)',
        variables: [
          Variable<String>(id),
          Variable<String>(target.rootId),
          Variable<int>(target.depth + 1 - deck.depth),
        ],
        updates: {_db.deck},
      );
      await (_db.update(_db.deck)..where((d) => d.id.equals(id)))
          .write(DeckCompanion(parentId: Value(target.id)));
      await claimContentType(target.id, ContentType.deck);
      await releaseContentTypeIfEmpty(oldParentId);
      return const Ok<void>(null);
    });
  }

  /// Sets [kind] only if the deck is still `unset`. Call inside the
  /// transaction that adds the child.
  Future<void> claimContentType(String deckId, ContentType kind) async {
    await _db.customUpdate(
      "UPDATE deck SET content_type = ? WHERE id = ? AND content_type = 'unset'",
      variables: [Variable<String>(kind.name), Variable<String>(deckId)],
      updates: {_db.deck},
    );
  }

  /// Puts a non-root deck back to `unset` when it holds no deck and no card.
  /// Call inside the transaction that removed its last child.
  Future<void> releaseContentTypeIfEmpty(String deckId) async {
    await _db.customUpdate(
      "UPDATE deck SET content_type = 'unset' WHERE id = ? "
      'AND parent_id IS NOT NULL '
      'AND NOT EXISTS (SELECT 1 FROM deck c WHERE c.parent_id = deck.id) '
      'AND NOT EXISTS (SELECT 1 FROM card WHERE card.deck_id = deck.id)',
      variables: [Variable<String>(deckId)],
      updates: {_db.deck},
      updateKind: UpdateKind.update,
    );
  }

  ContentType _contentOf(Deck d) => ContentType.values.byName(d.contentType);

  /// True when [candidate] is [subtreeOf] itself or one of its descendants.
  Future<bool> _inSubtree({
    required String subtreeOf,
    required String candidate,
  }) async {
    final rows = await _db.customSelect(
      '$_subtreeCte SELECT 1 AS hit FROM subtree WHERE id = ?',
      variables: [Variable<String>(subtreeOf), Variable<String>(candidate)],
      readsFrom: {_db.deck},
    ).get();
    return rows.isNotEmpty;
  }

  Future<int> _deepestLevel(String deckId) async {
    final row = await _db.customSelect(
      '$_subtreeCte SELECT MAX(depth) AS deepest FROM deck '
      'WHERE id IN (SELECT id FROM subtree)',
      variables: [Variable<String>(deckId)],
      readsFrom: {_db.deck},
    ).getSingle();
    return row.read<int>('deepest');
  }
}
```

Replace `lib/features/decks/decks.dart` with:

```dart
export 'package:memox/features/decks/data/deck_store.dart';
export 'package:memox/features/decks/logic/deck_rules.dart';
```

This file now imports the `srs` barrel (`decks → srs`); the boundary map in Task 1 already allows it.

- [ ] **Step 4: Run to verify pass**

Run: `flutter test test/features/decks test/architecture`
Expected: PASS. Possible adjustments, in this order of likelihood:
- `updateKind: UpdateKind.update` may not be a parameter of `customUpdate` in the installed Drift; if the analyzer rejects it, delete that line (it only affects stream invalidation).
- If `deckById` and the generated `Deck` type conflict with an import, check the generated class name in `app_database.g.dart` and use that.

- [ ] **Step 5: Gate and commit**

```bash
flutter analyze
flutter test
git add lib/features/decks test/features/decks
git commit -m "feat(decks): add transactional DeckStore" -m "Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

### Task 8: `ScheduleStore` (schedule rows, reviews, scheduler change, reset)

**Files:**
- Create: `lib/features/srs/logic/review_kind.dart`, `lib/features/srs/data/schedule_store.dart`
- Modify: `lib/features/srs/srs.dart` (add exports)
- Test: `test/features/srs/schedule_store_test.dart`

**Interfaces:**
- Consumes: `AppDatabase`, `CardSchedule`, `Deck` rows (Task 5); `Outcome`, `Rejection`, `newId` (Task 2); `Scheduler`, `SchedulerType`, `ReviewAction`, `ScheduleState`, `schedulerFor` (Tasks 3–4).
- Produces:
  - `enum ReviewKind { learning, scheduled, relearning }` (stored as `.name`)
  - `ScheduleStore(AppDatabase db)`:
    - `Future<CardSchedule?> scheduleOf(String cardId)`
    - `Future<void> initSchedule({required String cardId, required SchedulerType scheduler, required int generation})` (call inside the card-creating transaction; `due_at` stays null)
    - `Future<Outcome<void>> recordReview({required String sessionId, required int sessionGeneration, required String cardId, required ReviewAction action, required ReviewKind kind, required DateTime now})`
    - `Future<Outcome<void>> changeScheduler({required String rootDeckId, required SchedulerType scheduler})`
    - `Future<Outcome<void>> resetProgress(String rootDeckId)`

Behavior (spec sections 5 and 7; V7 BR-09, BR-13, BR-14, BR-77, BR-78):
- `recordReview` order of checks: card exists → session generation equals the root's → action is in the scheduler's `supportedActions`. Only `kind == scheduled` moves the schedule; every accepted review appends one `review_log` row; the first accepted review stamps `first_reviewed_at` on the root, which locks the scheduler.
- `changeScheduler`: root only; refused once `first_reviewed_at` is set; re-initializes every card's schedule in the tree.
- `resetProgress`: root only; `generation + 1`; clears `first_reviewed_at`; re-initializes every schedule; keeps content and `review_log`.
- Closing open study sessions on reset or scheduler change (V7 BR-83, BR-164) belongs to the core-learning slice; until then the stale-generation check protects correctness.

- [ ] **Step 1: Write the failing tests**

`test/features/srs/schedule_store_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/db/app_database.dart';
import 'package:memox/core/outcome.dart';
import 'package:memox/features/decks/decks.dart';
import 'package:memox/features/srs/srs.dart';

import '../../support/test_database.dart';

Rejection? reasonOf(Outcome<Object?> o) => o is Rejected ? o.reason : null;

Future<int> count(AppDatabase db, String table) async =>
    (await db.customSelect('SELECT COUNT(*) AS n FROM $table').getSingle())
        .read<int>('n');

void main() {
  late AppDatabase db;
  late DeckStore decks;
  late ScheduleStore schedules;
  final now = DateTime(2026, 3, 10, 9);

  setUp(() {
    db = openTestDatabase();
    decks = DeckStore(db);
    schedules = ScheduleStore(db);
  });
  tearDown(() => db.close());

  /// A root deck, one card-holding sub-deck and one card with its schedule.
  Future<({String root, String card})> fixture(
      [SchedulerType type = SchedulerType.eightBox]) async {
    final root = (await decks.createRootDeck(name: 'R', scheduler: type) as Ok<String>).value;
    final sub = (await decks.createSubDeck(parentId: root, name: 'S') as Ok<String>).value;
    await decks.claimContentType(sub, ContentType.card);
    await db.customStatement(
      "INSERT INTO card (id, deck_id, front, back, created_at, updated_at) VALUES ('c', ?, 'f', 'b', 0, 0)",
      [sub],
    );
    await schedules.initSchedule(cardId: 'c', scheduler: type, generation: 1);
    return (root: root, card: 'c');
  }

  Future<Outcome<void>> review(String card, ReviewAction a,
          {int generation = 1, ReviewKind kind = ReviewKind.scheduled}) =>
      schedules.recordReview(
        sessionId: 'ses',
        sessionGeneration: generation,
        cardId: card,
        action: a,
        kind: kind,
        now: now,
      );

  group('initSchedule', () {
    test('eight_box starts in box 1 with no due date', () async {
      final f = await fixture();
      final s = (await schedules.scheduleOf(f.card))!;
      expect((s.currentBox, s.easeFactor, s.dueAt, s.generation), (1, null, null, 1));
    });

    test('sm2 starts at 2.5 / 0 / 0 with no due date', () async {
      final f = await fixture(SchedulerType.sm2);
      final s = (await schedules.scheduleOf(f.card))!;
      expect((s.currentBox, s.easeFactor, s.intervalDays, s.repetitions, s.dueAt),
          (null, 2.5, 0, 0, null));
    });
  });

  group('recordReview', () {
    test('a scheduled review moves the schedule and appends a log row', () async {
      final f = await fixture();
      expect(await review(f.card, ReviewAction.remembered), isA<Ok<void>>());

      final s = (await schedules.scheduleOf(f.card))!;
      expect(s.currentBox, 2);
      expect(s.dueAt!.isAtSameMomentAs(DateTime(2026, 3, 12)), isTrue);

      final log = await db.customSelect('SELECT kind, action, generation FROM review_log').getSingle();
      expect((log.read<String>('kind'), log.read<String>('action'), log.read<int>('generation')),
          ('scheduled', 'remembered', 1));
      expect((await decks.deckById(f.root))!.firstReviewedAt, isNotNull);
    });

    test('a learning review is logged but leaves the schedule alone', () async {
      final f = await fixture();
      await review(f.card, ReviewAction.remembered, kind: ReviewKind.learning);
      final s = (await schedules.scheduleOf(f.card))!;
      expect((s.currentBox, s.dueAt), (1, null));
      expect(await count(db, 'review_log'), 1);
    });

    test('a stale generation is rejected and nothing is written', () async {
      final f = await fixture();
      await schedules.resetProgress(f.root); // generation becomes 2
      final o = await review(f.card, ReviewAction.remembered, generation: 1);
      expect(reasonOf(o), Rejection.staleGeneration);
      expect(await count(db, 'review_log'), 0);
      expect((await schedules.scheduleOf(f.card))!.currentBox, 1);
    });

    test('an action the scheduler does not support is rejected', () async {
      final f = await fixture(); // eight_box has no `hard`
      expect(reasonOf(await review(f.card, ReviewAction.hard)),
          Rejection.unsupportedAction);
      expect(await count(db, 'review_log'), 0);
      expect((await schedules.scheduleOf(f.card))!.currentBox, 1);
    });

    test('a card deleted mid-session is notFound and writes no log row', () async {
      final f = await fixture();
      await db.customStatement("DELETE FROM card WHERE id = 'c'");
      expect(reasonOf(await review(f.card, ReviewAction.remembered)),
          Rejection.notFound);
      expect(await count(db, 'review_log'), 0);
    });
  });

  group('changeScheduler', () {
    test('before the first review it re-initializes every card', () async {
      final f = await fixture();
      expect(await schedules.changeScheduler(rootDeckId: f.root, scheduler: SchedulerType.sm2),
          isA<Ok<void>>());
      expect((await decks.deckById(f.root))!.scheduler, 'sm2');
      final s = (await schedules.scheduleOf(f.card))!;
      expect((s.currentBox, s.easeFactor, s.intervalDays, s.repetitions),
          (null, 2.5, 0, 0));
    });

    test('after the first review it is locked', () async {
      final f = await fixture();
      await review(f.card, ReviewAction.remembered);
      final o = await schedules.changeScheduler(
          rootDeckId: f.root, scheduler: SchedulerType.sm2);
      expect(reasonOf(o), Rejection.schedulerLocked);
      expect((await decks.deckById(f.root))!.scheduler, 'eight_box');
    });

    test('only a root deck can change scheduler', () async {
      final f = await fixture();
      final sub = (await db.customSelect("SELECT id FROM deck WHERE parent_id IS NOT NULL").getSingle()).read<String>('id');
      expect(reasonOf(await schedules.changeScheduler(rootDeckId: sub, scheduler: SchedulerType.sm2)),
          Rejection.notFound);
      expect(f.root, isNotEmpty);
    });
  });

  group('resetProgress', () {
    test('bumps generation, clears the lock and schedule, keeps content and history', () async {
      final f = await fixture();
      await review(f.card, ReviewAction.remembered);

      expect(await schedules.resetProgress(f.root), isA<Ok<void>>());

      final root = (await decks.deckById(f.root))!;
      expect((root.generation, root.firstReviewedAt), (2, null));
      final s = (await schedules.scheduleOf(f.card))!;
      expect((s.currentBox, s.dueAt, s.generation), (1, null, 2));
      expect(await count(db, 'review_log'), 1);
      expect(await count(db, 'card'), 1);

      // the lock is gone, so the scheduler can change now
      expect(await schedules.changeScheduler(rootDeckId: f.root, scheduler: SchedulerType.sm2),
          isA<Ok<void>>());
    });

    test('an unknown root is notFound', () async {
      expect(reasonOf(await schedules.resetProgress('nope')), Rejection.notFound);
    });
  });
}
```

- [ ] **Step 2: Run to verify failure**

Run: `flutter test test/features/srs/schedule_store_test.dart`
Expected: FAIL, missing `ScheduleStore` / `ReviewKind`.

- [ ] **Step 3: Implement**

`lib/features/srs/logic/review_kind.dart`:

```dart
/// Stored on every review, never inferred from before/after state: a
/// `scheduled` review of a box-8 card leaves the box unchanged.
enum ReviewKind { learning, scheduled, relearning }
```

`lib/features/srs/data/schedule_store.dart`:

```dart
import 'package:drift/drift.dart';
import 'package:memox/core/db/app_database.dart';
import 'package:memox/core/ids.dart';
import 'package:memox/core/outcome.dart';
import 'package:memox/features/srs/logic/review_kind.dart';
import 'package:memox/features/srs/logic/scheduler.dart';
import 'package:memox/features/srs/logic/schedulers.dart';

class ScheduleStore {
  ScheduleStore(this._db);

  final AppDatabase _db;

  Future<CardSchedule?> scheduleOf(String cardId) => (_db.select(_db.cardSchedule)
        ..where((s) => s.cardId.equals(cardId)))
      .getSingleOrNull();

  /// Call inside the transaction that creates the card. `due_at` stays null
  /// until the card finishes its first learning.
  Future<void> initSchedule({
    required String cardId,
    required SchedulerType scheduler,
    required int generation,
  }) =>
      _put(cardId, generation, schedulerFor(scheduler).initialState, null);

  Future<Outcome<void>> recordReview({
    required String sessionId,
    required int sessionGeneration,
    required String cardId,
    required ReviewAction action,
    required ReviewKind kind,
    required DateTime now,
  }) {
    return _db.transaction<Outcome<void>>(() async {
      final card = await (_db.select(_db.card)..where((c) => c.id.equals(cardId)))
          .getSingleOrNull();
      if (card == null) return const Rejected<void>(Rejection.notFound);
      final deck = await _deck(card.deckId);
      final root = (await _deck(deck.rootId));
      final generation = root.generation!;
      if (generation != sessionGeneration) {
        return const Rejected<void>(Rejection.staleGeneration);
      }
      final scheduler = schedulerFor(SchedulerType.fromValue(root.scheduler!));
      if (!scheduler.supportedActions.contains(action)) {
        return const Rejected<void>(Rejection.unsupportedAction);
      }

      if (kind == ReviewKind.scheduled) {
        final current = (await scheduleOf(cardId))!;
        final next = scheduler.next(_stateOf(current), action, now);
        await _put(cardId, generation, next.state, next.dueAt);
      }
      await _db.into(_db.reviewLog).insert(
            ReviewLogCompanion.insert(
              id: newId(),
              cardId: cardId,
              sessionId: sessionId,
              generation: generation,
              kind: kind.name,
              action: action.name,
              reviewedAt: now,
            ),
          );
      if (root.firstReviewedAt == null) {
        await (_db.update(_db.deck)..where((d) => d.id.equals(root.id)))
            .write(DeckCompanion(firstReviewedAt: Value(now)));
      }
      return const Ok<void>(null);
    });
  }

  Future<Outcome<void>> changeScheduler({
    required String rootDeckId,
    required SchedulerType scheduler,
  }) {
    return _db.transaction<Outcome<void>>(() async {
      final root = await _rootOrNull(rootDeckId);
      if (root == null) return const Rejected<void>(Rejection.notFound);
      if (root.firstReviewedAt != null) {
        return const Rejected<void>(Rejection.schedulerLocked);
      }
      await (_db.update(_db.deck)..where((d) => d.id.equals(root.id)))
          .write(DeckCompanion(scheduler: Value(scheduler.value)));
      await _reinitialize(root.id, scheduler, root.generation!);
      return const Ok<void>(null);
    });
  }

  /// Keeps content and `review_log`; the new generation makes any open session
  /// stale.
  Future<Outcome<void>> resetProgress(String rootDeckId) {
    return _db.transaction<Outcome<void>>(() async {
      final root = await _rootOrNull(rootDeckId);
      if (root == null) return const Rejected<void>(Rejection.notFound);
      final generation = root.generation! + 1;
      await (_db.update(_db.deck)..where((d) => d.id.equals(root.id))).write(
        DeckCompanion(
          generation: Value(generation),
          firstReviewedAt: const Value(null),
        ),
      );
      await _reinitialize(
        root.id,
        SchedulerType.fromValue(root.scheduler!),
        generation,
      );
      return const Ok<void>(null);
    });
  }

  Future<Deck> _deck(String id) =>
      (_db.select(_db.deck)..where((d) => d.id.equals(id))).getSingle();

  Future<Deck?> _rootOrNull(String id) async {
    final deck = await (_db.select(_db.deck)..where((d) => d.id.equals(id)))
        .getSingleOrNull();
    return deck != null && deck.parentId == null ? deck : null;
  }

  Future<void> _reinitialize(
    String rootId,
    SchedulerType scheduler,
    int generation,
  ) async {
    final rows = await _db.customSelect(
      'SELECT c.id AS id FROM card c JOIN deck d ON c.deck_id = d.id '
      'WHERE d.root_id = ?',
      variables: [Variable<String>(rootId)],
      readsFrom: {_db.card, _db.deck},
    ).get();
    for (final row in rows) {
      await initSchedule(
        cardId: row.read<String>('id'),
        scheduler: scheduler,
        generation: generation,
      );
    }
  }

  Future<void> _put(
    String cardId,
    int generation,
    ScheduleState state,
    DateTime? dueAt,
  ) async {
    await _db.into(_db.cardSchedule).insert(
          _row(cardId, generation, state, dueAt),
          mode: InsertMode.insertOrReplace,
        );
  }

  CardScheduleCompanion _row(
    String cardId,
    int generation,
    ScheduleState state,
    DateTime? dueAt,
  ) =>
      switch (state) {
        EightBoxState(:final box) => CardScheduleCompanion.insert(
            cardId: cardId,
            generation: generation,
            currentBox: Value(box),
            dueAt: Value(dueAt),
          ),
        Sm2State(:final easeFactor, :final intervalDays, :final repetitions) =>
          CardScheduleCompanion.insert(
            cardId: cardId,
            generation: generation,
            easeFactor: Value(easeFactor),
            intervalDays: Value(intervalDays),
            repetitions: Value(repetitions),
            dueAt: Value(dueAt),
          ),
      };

  ScheduleState _stateOf(CardSchedule s) => s.currentBox != null
      ? EightBoxState(s.currentBox!)
      : Sm2State(
          easeFactor: s.easeFactor!,
          intervalDays: s.intervalDays!,
          repetitions: s.repetitions!,
        );
}
```

Replace `lib/features/srs/srs.dart` with:

```dart
export 'package:memox/features/srs/data/schedule_store.dart';
export 'package:memox/features/srs/logic/review_kind.dart';
export 'package:memox/features/srs/logic/scheduler.dart';
export 'package:memox/features/srs/logic/schedulers.dart';
```

- [ ] **Step 4: Run to verify pass**

Run: `flutter test test/features/srs test/architecture`
Expected: PASS. `srs` imports no other feature (its Dart reads `deck` and `card` rows through `AppDatabase`), so the boundary test stays green. If `Value(null)` for `firstReviewedAt` reports a type error, write `const Value<DateTime?>(null)`.

- [ ] **Step 5: Gate and commit**

```bash
flutter analyze
flutter test
git add lib/features/srs test/features/srs
git commit -m "feat(srs): add ScheduleStore for reviews, scheduler change and reset" -m "Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

### Task 9: `CardStore`

**Files:**
- Create: `lib/features/cards/data/card_store.dart`, `lib/features/cards/cards.dart`
- Test: `test/features/cards/card_store_test.dart`

**Interfaces:**
- Consumes: `AppDatabase`, `CardRow` (Task 5); `Outcome`, `Rejection`, `newId` (Task 2); `DeckStore`, `checkAddCard`, `ContentType` (Tasks 6–7); `ScheduleStore`, `SchedulerType` (Tasks 4, 8).
- Produces (`CardStore(AppDatabase db, DeckStore decks, ScheduleStore schedules, {DateTime Function()? now})`):
  - `Future<CardRow?> cardById(String id)`
  - `Future<Outcome<String>> createCard({required String deckId, required String front, required String back})` returns the new id; creates the card **and** its schedule (root's scheduler and current generation, `due_at` null) in one transaction and claims the deck's content type as `card`
  - `Future<Outcome<void>> updateCard({required String id, required String front, required String back})` touches only `front`, `back`, `updated_at`
  - `Future<Outcome<void>> deleteCard(String id)` releases the deck to `unset` when it was the last child
  - `lib/features/cards/cards.dart` exporting `card_store.dart`

Card text is stored exactly as given; it is only rejected when blank after trimming.

- [ ] **Step 1: Write the failing tests**

`test/features/cards/card_store_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/db/app_database.dart';
import 'package:memox/core/outcome.dart';
import 'package:memox/features/cards/cards.dart';
import 'package:memox/features/decks/decks.dart';
import 'package:memox/features/srs/srs.dart';

import '../../support/test_database.dart';

String idOf(Outcome<String> o) => (o as Ok<String>).value;

Rejection? reasonOf(Outcome<Object?> o) => o is Rejected ? o.reason : null;

Future<int> count(AppDatabase db, String table) async =>
    (await db.customSelect('SELECT COUNT(*) AS n FROM $table').getSingle())
        .read<int>('n');

void main() {
  late AppDatabase db;
  late DeckStore decks;
  late ScheduleStore schedules;
  late CardStore cards;
  var clock = DateTime.utc(2026, 1, 1);

  setUp(() {
    clock = DateTime.utc(2026, 1, 1);
    db = openTestDatabase();
    decks = DeckStore(db);
    schedules = ScheduleStore(db);
    cards = CardStore(db, decks, schedules, now: () => clock);
  });
  tearDown(() => db.close());

  Future<({String root, String sub})> deckFixture(
      [SchedulerType type = SchedulerType.eightBox]) async {
    final root = idOf(await decks.createRootDeck(name: 'R', scheduler: type));
    final sub = idOf(await decks.createSubDeck(parentId: root, name: 'S'));
    return (root: root, sub: sub);
  }

  Future<String> newCard(String deckId, [String front = 'f']) async =>
      idOf(await cards.createCard(deckId: deckId, front: front, back: 'b'));

  group('createCard', () {
    test('creates the card and an eight_box schedule in one go', () async {
      final f = await deckFixture();
      final id = await newCard(f.sub, '  안녕 ');
      final card = (await cards.cardById(id))!;
      expect((card.deckId, card.front, card.back), (f.sub, '  안녕 ', 'b'));
      final s = (await schedules.scheduleOf(id))!;
      expect((s.currentBox, s.dueAt, s.generation), (1, null, 1));
      expect((await decks.deckById(f.sub))!.contentType, 'card');
    });

    test('an sm2 root gives an sm2 schedule', () async {
      final f = await deckFixture(SchedulerType.sm2);
      final s = (await schedules.scheduleOf(await newCard(f.sub)))!;
      expect((s.currentBox, s.easeFactor, s.intervalDays, s.repetitions),
          (null, 2.5, 0, 0));
    });

    test('a card created after a reset gets the new generation', () async {
      final f = await deckFixture();
      await schedules.resetProgress(f.root);
      final s = (await schedules.scheduleOf(await newCard(f.sub)))!;
      expect(s.generation, 2);
    });

    test('a root deck never holds cards', () async {
      final f = await deckFixture();
      final o = await cards.createCard(deckId: f.root, front: 'f', back: 'b');
      expect(reasonOf(o), Rejection.rootHoldsOnlyDecks);
      expect(await count(db, 'card'), 0);
    });

    test('a deck that holds decks refuses cards', () async {
      final f = await deckFixture();
      await decks.createSubDeck(parentId: f.sub, name: 'child');
      final o = await cards.createCard(deckId: f.sub, front: 'f', back: 'b');
      expect(reasonOf(o), Rejection.wrongContentType);
    });

    test('blank front or back is rejected and nothing is stored', () async {
      final f = await deckFixture();
      for (final (front, back) in [('', 'b'), ('f', '   '), (' \n', '\t')]) {
        final o = await cards.createCard(deckId: f.sub, front: front, back: back);
        expect(reasonOf(o), Rejection.blankContent, reason: '"$front" / "$back"');
      }
      expect(await count(db, 'card'), 0);
      expect(await count(db, 'card_schedule'), 0);
      expect((await decks.deckById(f.sub))!.contentType, 'unset');
    });

    test('an unknown deck is notFound', () async {
      final o = await cards.createCard(deckId: 'nope', front: 'f', back: 'b');
      expect(reasonOf(o), Rejection.notFound);
    });
  });

  group('updateCard', () {
    test('changes text and updated_at but never the schedule (BR-10)', () async {
      final f = await deckFixture();
      final id = await newCard(f.sub);
      await schedules.recordReview(
        sessionId: 's',
        sessionGeneration: 1,
        cardId: id,
        action: ReviewAction.remembered,
        kind: ReviewKind.scheduled,
        now: DateTime(2026, 3, 10, 9),
      );
      final before = (await schedules.scheduleOf(id))!;

      clock = DateTime.utc(2026, 1, 2);
      expect(await cards.updateCard(id: id, front: 'new f', back: 'new b'),
          isA<Ok<void>>());

      final card = (await cards.cardById(id))!;
      expect((card.front, card.back), ('new f', 'new b'));
      expect(card.updatedAt.isAtSameMomentAs(clock), isTrue);
      expect(card.createdAt.isAtSameMomentAs(DateTime.utc(2026, 1, 1)), isTrue);
      expect(await schedules.scheduleOf(id), before);
      expect(await count(db, 'review_log'), 1);
    });

    test('rejects blank text and unknown cards', () async {
      final f = await deckFixture();
      final id = await newCard(f.sub);
      expect(reasonOf(await cards.updateCard(id: id, front: ' ', back: 'b')),
          Rejection.blankContent);
      expect((await cards.cardById(id))!.front, 'f');
      expect(reasonOf(await cards.updateCard(id: 'nope', front: 'f', back: 'b')),
          Rejection.notFound);
    });
  });

  group('deleteCard', () {
    test('deleting the last card puts the deck back to unset', () async {
      final f = await deckFixture();
      final id = await newCard(f.sub);
      expect(await cards.deleteCard(id), isA<Ok<void>>());
      expect(await count(db, 'card_schedule'), 0);
      expect((await decks.deckById(f.sub))!.contentType, 'unset');
    });

    test('a deck that still has cards stays card', () async {
      final f = await deckFixture();
      final a = await newCard(f.sub, 'a');
      await newCard(f.sub, 'b');
      await cards.deleteCard(a);
      expect((await decks.deckById(f.sub))!.contentType, 'card');
    });

    test('an unknown card is notFound', () async {
      expect(reasonOf(await cards.deleteCard('nope')), Rejection.notFound);
    });
  });
}
```

- [ ] **Step 2: Run to verify failure**

Run: `flutter test test/features/cards`
Expected: FAIL, missing `cards.dart`.

- [ ] **Step 3: Implement**

`lib/features/cards/data/card_store.dart`:

```dart
import 'package:drift/drift.dart';
import 'package:memox/core/db/app_database.dart';
import 'package:memox/core/ids.dart';
import 'package:memox/core/outcome.dart';
import 'package:memox/features/decks/decks.dart';
import 'package:memox/features/srs/srs.dart';

class CardStore {
  CardStore(this._db, this._decks, this._schedules, {DateTime Function()? now})
      : _now = now ?? DateTime.now;

  final AppDatabase _db;
  final DeckStore _decks;
  final ScheduleStore _schedules;
  final DateTime Function() _now;

  Future<CardRow?> cardById(String id) =>
      (_db.select(_db.card)..where((c) => c.id.equals(id))).getSingleOrNull();

  Future<Outcome<String>> createCard({
    required String deckId,
    required String front,
    required String back,
  }) async {
    if (_isBlank(front) || _isBlank(back)) {
      return const Rejected<String>(Rejection.blankContent);
    }
    return _db.transaction<Outcome<String>>(() async {
      final deck = await _decks.deckById(deckId);
      if (deck == null) return const Rejected<String>(Rejection.notFound);
      final reason = checkAddCard(
        parentIsRoot: deck.parentId == null,
        parentContent: ContentType.values.byName(deck.contentType),
      );
      if (reason != null) return Rejected<String>(reason);

      final root = (await _decks.deckById(deck.rootId))!;
      final id = newId();
      final now = _now();
      await _db.into(_db.card).insert(
            CardRowCompanion.insert(
              id: id,
              deckId: deckId,
              front: front,
              back: back,
              createdAt: now,
              updatedAt: now,
            ),
          );
      await _schedules.initSchedule(
        cardId: id,
        scheduler: SchedulerType.fromValue(root.scheduler!),
        generation: root.generation!,
      );
      await _decks.claimContentType(deckId, ContentType.card);
      return Ok(id);
    });
  }

  /// Touches content only; the schedule and history are never read or written.
  Future<Outcome<void>> updateCard({
    required String id,
    required String front,
    required String back,
  }) async {
    if (_isBlank(front) || _isBlank(back)) {
      return const Rejected<void>(Rejection.blankContent);
    }
    final updated = await (_db.update(_db.card)..where((c) => c.id.equals(id)))
        .write(CardRowCompanion(
      front: Value(front),
      back: Value(back),
      updatedAt: Value(_now()),
    ));
    return updated == 0
        ? const Rejected<void>(Rejection.notFound)
        : const Ok<void>(null);
  }

  Future<Outcome<void>> deleteCard(String id) {
    return _db.transaction<Outcome<void>>(() async {
      final card = await cardById(id);
      if (card == null) return const Rejected<void>(Rejection.notFound);
      await (_db.delete(_db.card)..where((c) => c.id.equals(id))).go();
      await _decks.releaseContentTypeIfEmpty(card.deckId);
      return const Ok<void>(null);
    });
  }

  bool _isBlank(String text) => text.trim().isEmpty;
}
```

`lib/features/cards/cards.dart`:

```dart
export 'package:memox/features/cards/data/card_store.dart';
```

- [ ] **Step 4: Run to verify pass**

Run: `flutter test test/features/cards test/architecture`
Expected: PASS. `cards` imports only the `decks` and `srs` barrels, which the boundary map allows.

- [ ] **Step 5: Gate and commit**

```bash
flutter analyze
flutter test
git add lib/features/cards test/features/cards
git commit -m "feat(cards): add CardStore that creates the schedule with the card" -m "Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

### Task 10: Wiring (providers, app shell, retry policy) and end-to-end smoke

**Files:**
- Create: `lib/core/db/database_provider.dart`, `lib/features/decks/decks_providers.dart`, `lib/features/srs/srs_providers.dart`, `lib/features/cards/cards_providers.dart`, `lib/app/app.dart`, `lib/app/router.dart`
- Modify: `lib/main.dart`, the three barrels (`decks.dart`, `srs.dart`, `cards.dart`) to export their providers file
- Test: `test/integration/core_flow_test.dart`, `test/app/app_test.dart`

**Interfaces:**
- Consumes: all stores (Tasks 7–9), `AppDatabase` (Task 5).
- Produces:
  - `databaseProvider` (keep-alive; opens `driftDatabase(name: 'memox')`; closes on dispose)
  - `deckStoreProvider`, `scheduleStoreProvider`, `cardStoreProvider`
  - `Duration? noRetry(int retryCount, Object error)` in `lib/app/app.dart`, passed as `ProviderScope(retry: noRetry, ...)`
  - `MemoxApp` (ConsumerWidget, `MaterialApp.router`) and `routerProvider`; one placeholder route `/`. The real screens are the design-system and core-learning-slice sub-projects.

- [ ] **Step 1: Write the failing tests**

`test/integration/core_flow_test.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/db/database_provider.dart';
import 'package:memox/core/outcome.dart';
import 'package:memox/features/cards/cards.dart';
import 'package:memox/features/decks/decks.dart';
import 'package:memox/features/srs/srs.dart';

import '../support/test_database.dart';

void main() {
  test('create deck -> sub-deck -> card -> review, through the providers', () async {
    final db = openTestDatabase();
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(() async {
      container.dispose();
      await db.close();
    });

    final decks = container.read(deckStoreProvider);
    final cards = container.read(cardStoreProvider);
    final schedules = container.read(scheduleStoreProvider);

    final root = ((await decks.createRootDeck(
            name: 'TOPIK', scheduler: SchedulerType.eightBox)) as Ok<String>)
        .value;
    final sub =
        ((await decks.createSubDeck(parentId: root, name: 'Unit 1')) as Ok<String>)
            .value;
    final card = ((await cards.createCard(deckId: sub, front: '사과', back: 'apple'))
            as Ok<String>)
        .value;

    final result = await schedules.recordReview(
      sessionId: 'session-1',
      sessionGeneration: 1,
      cardId: card,
      action: ReviewAction.remembered,
      kind: ReviewKind.scheduled,
      now: DateTime(2026, 3, 10, 9),
    );

    expect(result, isA<Ok<void>>());
    expect((await schedules.scheduleOf(card))!.currentBox, 2);
  });
}
```

`test/app/app_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/app.dart';

final _failing = FutureProvider<int>((ref) async => throw StateError('boom'));

void main() {
  testWidgets('the app shell renders its placeholder route', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(retry: noRetry, child: MemoxApp()),
    );
    await tester.pumpAndSettle();
    expect(find.text('MemoX V8'), findsOneWidget);
  });

  test('a failing provider surfaces AsyncError with no hidden retries', () async {
    final container = ProviderContainer(retry: noRetry);
    addTearDown(container.dispose);

    await expectLater(container.read(_failing.future), throwsStateError);
    expect(container.read(_failing), isA<AsyncError<int>>());
  });
}
```

- [ ] **Step 2: Run to verify failure**

Run: `flutter test test/integration test/app`
Expected: FAIL, missing providers and `app.dart`.

- [ ] **Step 3: Implement providers**

`lib/core/db/database_provider.dart`:

```dart
import 'package:drift_flutter/drift_flutter.dart';
import 'package:memox/core/db/app_database.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'database_provider.g.dart';

@Riverpod(keepAlive: true)
AppDatabase database(Ref ref) {
  final db = AppDatabase(driftDatabase(name: 'memox'));
  ref.onDispose(db.close);
  return db;
}
```

`lib/features/decks/decks_providers.dart`:

```dart
import 'package:memox/core/db/database_provider.dart';
import 'package:memox/features/decks/data/deck_store.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'decks_providers.g.dart';

@riverpod
DeckStore deckStore(Ref ref) => DeckStore(ref.watch(databaseProvider));
```

`lib/features/srs/srs_providers.dart`:

```dart
import 'package:memox/core/db/database_provider.dart';
import 'package:memox/features/srs/data/schedule_store.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'srs_providers.g.dart';

@riverpod
ScheduleStore scheduleStore(Ref ref) =>
    ScheduleStore(ref.watch(databaseProvider));
```

`lib/features/cards/cards_providers.dart`:

```dart
import 'package:memox/core/db/database_provider.dart';
import 'package:memox/features/cards/data/card_store.dart';
import 'package:memox/features/decks/decks.dart';
import 'package:memox/features/srs/srs.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'cards_providers.g.dart';

@riverpod
CardStore cardStore(Ref ref) => CardStore(
      ref.watch(databaseProvider),
      ref.watch(deckStoreProvider),
      ref.watch(scheduleStoreProvider),
    );
```

Add one export line to each barrel:
- `lib/features/decks/decks.dart`: `export 'package:memox/features/decks/decks_providers.dart';`
- `lib/features/srs/srs.dart`: `export 'package:memox/features/srs/srs_providers.dart';`
- `lib/features/cards/cards.dart`: `export 'package:memox/features/cards/cards_providers.dart';`

- [ ] **Step 4: Implement the app shell**

`lib/app/router.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'router.g.dart';

@Riverpod(keepAlive: true)
GoRouter router(Ref ref) => GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('MemoX V8'))),
        ),
      ],
    );
```

`lib/app/app.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/app/router.dart';

/// Riverpod 3 retries a failed provider with backoff and reports `AsyncLoading`
/// meanwhile. A database error is not transient, so surface it at once.
Duration? noRetry(int retryCount, Object error) => null;

class MemoxApp extends ConsumerWidget {
  const MemoxApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'MemoX',
      routerConfig: ref.watch(routerProvider),
    );
  }
}
```

Replace `lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/app/app.dart';

void main() {
  runApp(const ProviderScope(retry: noRetry, child: MemoxApp()));
}
```

- [ ] **Step 5: Generate code and run to verify pass**

```bash
dart run build_runner build --delete-conflicting-outputs
flutter test test/integration test/app test/architecture
```

Expected: PASS. If `Ref` is not exported by `riverpod_annotation` in the installed version, import `package:flutter_riverpod/flutter_riverpod.dart` for `Ref` instead; the generated provider names stay `databaseProvider`, `deckStoreProvider`, `scheduleStoreProvider`, `cardStoreProvider`, `routerProvider`.

- [ ] **Step 6: Full acceptance gate**

```bash
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
flutter build apk --debug
```

Expected: analyzer clean, every test green, an APK built. If the Android SDK is not installed on the machine, skip only the last command and report that it was skipped and why.

- [ ] **Step 7: Commit**

```bash
git add lib test
git commit -m "feat(app): wire providers, app shell and retry policy" -m "Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

## Plan self-review

- **Spec coverage:** structure and boundaries (sections 4) → Tasks 1, 6–10; data model (5) → Tasks 5, 8, 9; SRS core and lock/reset/generation (5) → Tasks 3, 4, 8; deck tree rules and transactions (6) → Tasks 6, 7; data flow (7) → Tasks 8–10; errors (8) → Tasks 2, 5, 10; testing (9) → every task plus Task 1 (import boundary) and Task 5 (schema snapshot). Explicitly deferred with the spec: `study` behavior, `progress`, UI, Trash.
- **Placeholders:** none; every code step contains the code.
- **Type consistency:** `SchedulerType`, `ReviewAction`, `ReviewKind`, `Outcome`/`Rejected`/`Rejection`, `DeckStore`, `ScheduleStore`, `CardStore` and their method names match across tasks 2–10.

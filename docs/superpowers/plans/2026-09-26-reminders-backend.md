# MemoX V8 Daily Reminder Backend Implementation Plan (package 11a)

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build BE-B5a of [`docs/wbs_BE.md`](../../wbs_BE.md), every rule of the daily
reminder that can be verified without a device (UC-REMINDER-001;
BR-REMINDER-001…BR-REMINDER-012, and BR-SETTINGS-008's reset now covering the reminder),
behind a port to the operating system whose only adapter says "unsupported", so that
BE-B5b adds the Android adapter and FE-B5 builds screen 24 on six use cases.

**Architecture:** The settings feature keeps every column of `app_settings`: it gains
`ReminderSettings`, a snapshot read in one statement, a one-column write of the last
delivery, and a reset of six values. A new feature, `lib/features/reminders` (domain,
data, di), imports the domain of `settings`, `deck` and `srs`. Its pure rules order the
root decks (BR-REMINDER-006), build the digest, compute the next fire in local time and
check a fire. It reads the workload through the statement the Library's root level and
Study Home already read. `ReminderPlatformRepository` is its one way to the operating
system: typed answers, no plugin type, no call that throws, and in this package only
`UnsupportedReminderPlatformRepositoryImpl`. Six use cases (watch, enable, disable,
change the time, reconcile, deliver) put them together; each takes its `now` from
`DayClock`. No schema change.

**Tech Stack:** Flutter 3.47.5 (Dart 3.13.4), `drift` 2.35, `flutter_riverpod` 3 with
`riverpod_generator`. No dependency is added; the generated outputs two tasks need are
the new providers' (`build_runner`, Tasks 4 and 5).

**Spec:**
[`docs/superpowers/specs/2026-09-26-reminders-backend-design.md`](../specs/2026-09-26-reminders-backend-design.md),
approved 2026-09-26. Business rules: `docs/features/reminders/rules/`
(BR-REMINDER-001…BR-REMINDER-012) and `docs/features/settings/rules/`
(BR-SETTINGS-008); use cases:
`docs/features/reminders/usecases/UC-REMINDER-001-bat-nhac-hoc-hang-ngay.md` and
UC-SETTINGS-001 A3; data model:
[`shared/data/schema.md`](../../shared/data/schema.md), `app_settings`.

**Prerequisite:** `claude/be-reminders` holds the spec (`1b8418b`), its approval
(`37e41f9`) and this plan, on `master` at `5844ad3` (#77). The plan runs on that
branch, from this plan's commit; the gate passes there with 1915 tests. Generated
code is not committed: in a fresh working tree, run `flutter pub get`,
`flutter gen-l10n` and `dart run build_runner build --delete-conflicting-outputs`
first (root `README.md`, "Commands").

**How this plan was checked:** every code block below was written and run first, in
a scratch copy of the repository, task by task, test first. Each task's tests failed
as its "Expected" line says, then passed, and after every task the gate passed. Each
rule the tests pin was also broken on purpose in the scratch copy, one at a time: in
Task 1, a minute of 1440 taken; a minute of -1 taken; the reminder on by default; a
default time of 21:00; the app defaults holding another reminder; `saveReminder`
without its check; the switch read inverted; the switch always written off; the
snapshot without the last delivery; the snapshot in the system language; the
snapshot read in two statements; a delivery that also writes `updated_at`; a
delivery that rewrites the reminder; a reset that keeps the reminder; a reset that
clears the last delivery; in Task 2, overdue cards not the first key; overdue cards
ascending; the overdue age ignored; the cards due today ignored; names compared by
code units; no id at the end; a root with nothing due counted; the due count as the
overdue cards only; the top root counted among the others; the digest showing the
grand total; in Task 3, tomorrow's fire as today plus 24 hours; a delivery compared
on its UTC date; the very minute counted as ahead; a delivered day ignored by the
next fire; a reminder that is off firing; an early fire read as due; a delivered day
firing again; in Task 4, the overdue and due-today counts swapped; no overdue age;
the name as the id; a failed read left raw; in Task 5, no reminders read as
supported; no reminders granting the permission; no reminders scheduling; the watch
stopping after the first reminder; reconcile asking for the permission; reconcile
ignoring the last delivery; reconcile leaving a pending reminder while off;
reconcile reporting a refused schedule as `Ok`; reconcile working on a platform
without reminders; in Task 6, enable without the minute check; enable going on
without reminders; enable going on without the permission; enable saving after a
refused schedule; enable keeping the schedule when the save fails; enable ignoring
the last delivery; disable cancelling first; disable never saving; disable saving
when already off; disable reporting a refused cancel as `Ok`; disable cancelling on
a platform without reminders; the time change without the minute check; the time
change scheduling while off; the time change saving after a refused schedule; the
time change keeping the new time when the save fails; the time change ignoring the
last delivery; in Task 7, deliver working on a platform without reminders; deliver
rescheduling while off; deliver showing before its time; deliver showing twice a
day; today's cards read as overdue; deliver recording a refused show; deliver
recording nothing; deliver writing in the system language; a skipped fire scheduling
nothing; an unreadable workload escaping. That is 71 breaks. Every break compiled
and failed at least one test. Two of them show only where local time is not UTC, so
they ran with `TZ=Europe/Berlin`, and Task 3 runs its time tests there too. Three
first got past the tests: a delivery compared on its UTC date, the overdue and
due-today counts swapped, and today's cards read as overdue. Task 3's test of a
delivery just after local midnight and the seeds of Tasks 4 and 7 were changed until
each failed, and the whole sweep was run again on the final code. After the first
pass, the Review Focus test of the double tap was added to Task 6; it passed on the
code as it stood. This document was then applied, step by step as written, onto a
clean checkout of this plan's commit: each task's files matched the scratch
commit's, no other file moved, and the outputs and counts below are that run's.

## Global Constraints

Every task's requirements implicitly include these.

- Backend only: no screen, no route, no copy text, no provider but the two repositories'.
  Screen 24 is FE-B5's, the Settings rows are FE-A3's, and the Android adapter, its
  plugins, the manifest, gradle and the background entry point are BE-B5b's (spec §13).
- No schema change, no migration, no dependency, no Android or iOS file (D1).
- The settings feature keeps every column of `app_settings`, the reminder's included.
  `reminders` imports the domain of `settings`, `deck` and `srs` and nothing else of
  another feature: the import map gains `'reminders': {'settings', 'deck', 'srs'}` (D2,
  ADR-011).
- `Reset to defaults` writes six values in one transaction: the four of package 1,
  `reminder_enabled = 0` and `reminder_minute_of_day = 1200`. It leaves
  `reminder_last_delivered_at` as it is (D3).
- `recordReminderDelivered` writes `reminder_last_delivered_at` and nothing else, not
  even `updated_at` (D5, `schema.md`).
- `ReminderPlatformRepository` uses no plugin type, and no call of it throws: a platform
  error comes back as a typed `Rejected` (D6). The one adapter in this package is
  `UnsupportedReminderPlatformRepositoryImpl`, on every platform (D7).
- The workload is read by `deckLevelOfRoots`, once, as Study Home reads it (D8). The digest
  names the most urgent root, that root's own due count and the number of other roots with
  cards due (D9). Names sort by `foldText`, then by id (D10).
- `nextReminderAt` builds the instant from calendar fields in local time and never adds
  24 hours (D11). A fire before the chosen minute on the day it lands, or on a day that had
  its digest, shows nothing and is rescheduled (D12).
- Enable and change-time schedule, then save; disable saves, then cancels (D13). Only
  Enable asks for the permission, after the minute and the capability (D14). Reconcile
  is idempotent (D15). Deliver shows, then records, and reschedules whenever it read the
  settings and found the reminder on (D16). Changing the time while off only saves it
  (D17).
- Each use case is a class `<Name>UseCase` in `<name>_use_case.dart` exposing `call`
  (AD-12), takes its `now` from `DayClock`, and opens no transaction (guard
  `no_transaction_outside_data_layer`).
- Domain files end in `_entity`, `_repository`, `_use_case`, `_scheduler`, `_mode`,
  `_failure` or `_model`, and data files in `_repository_impl`, `_dao`, `_mapper`,
  `_model`, `_data_source` or `_loader` (guard `naming`); booleans read as predicates
  (`isEnabled`, `isRecorded`).
- Every statement on `card` or `deck` filters `delete_batch_id` (BR-TRASH-002). This
  package writes no statement: it calls `deckLevelOfRoots`, which already does.
- After every task the gate of the root `README.md` passes:
  `bash .claude/skills/flutter-workflow/scripts/dod_check.sh`. It runs the host suite with
  `TZ=UTC` and `--exclude-tags golden`. Its generated-code check asks every source under
  `lib/` to be in git, so each task stages its files, runs the gate, then commits.
- Docs and code change in the same commit (`docs/README.md`). A task whose tests name a
  use case id runs `python3 tools/docs/generate.py` and commits `docs/_generated/`.
- The contract documents change only as spec §12 says, with the two additions of
  Clarifications 6 and 7.
- Code, identifiers, test names and commit messages are in English; `docs/` keeps its
  Vietnamese. Every commit message ends with the session's attribution trailers.

## Clarifications to confirm during plan review

Writing and running the code settled what the spec left to the plan. Each is decided
here and implemented as described; say so if one is wrong.

1. **Where the overdue age is computed** (Task 4; spec §7). The data mapper
   `reminderDeckWorkloadOf(row, startOfToday)` computes it through
   `DeckScheduleStatus.overdueDays`, the helper the deck list uses, from the row's
   `oldest_due_at`. The domain model only carries the number, and the DAO method is named
   `rootDeckRows`, as Study Home's is.
2. **A refusal of `saveReminder` inside Enable reads as `minuteOutOfRange`** (Task 6).
   It is the one reason `saveReminder` has, and Enable checks the minute before anything
   else, so the path is never taken; it still takes the schedule back first. Disable and
   change-time drop the `Outcome` of their save: a stored minute is in range (its
   `CHECK`), and change-time checked the new one first.
3. **One failure type is caught, the one the repositories raise** (Tasks 6 and 7). Enable,
   change-time and deliver catch `Failure` only: every error a repository meets leaves it
   as a `Failure` (`mapDatabaseError`), and anything else is a bug that should surface.
4. **The platform provider lives as long as the app** (Task 5).
   `reminderPlatformRepositoryProvider` is `keepAlive`, as `dayClockProvider` is: the
   Android adapter of BE-B5b holds the plugins' initialisation.
5. **The clock-change test needs a zone with clock changes** (Task 3). The host suite runs
   with `TZ=UTC`, where no day is 23 or 25 hours, so the test of D11 passes there whatever
   the code does. Task 3 runs the time tests once more with `TZ=Europe/Berlin`, and the
   break "tomorrow is today plus 24 hours" was run under that zone in the sweep above,
   where it failed.
6. **The CI impact map follows the reminders README** (Task 8). `depends_on` gains
   `settings` (spec §12), and `test_ci_tooling.py` checks that
   `verification_impact_map.json` lists each feature's dependents as the inverse of the
   READMEs: `settings` now lists `reminders`.
7. **A stale line of `wbs_FE.md`** (Task 8). "Bước tiếp theo" item 5 still said BE-B3…BE-B5
   had not started; BE-B3 and BE-B4 are done since #72 and package 10. It now says
   BE-B1…BE-B4 are done and FE-B5 waits for BE-B5b.
8. **The plan's date.** The plan is written on 2026-09-26, the spec's day.

## Review Focus

The inputs and conditions the spec implies that are most likely to bite a person, beyond
what spec §11 already lists, each pinned by a test in the task that owns the code:

1. **A double tap on the switch**: two Enables at once both succeed, the reminder ends on
   and pending at its time, and neither takes the other's schedule back — Task 6, "two
   taps on the switch at once both succeed …".
2. **A clock change between today and the next fire**: the next fire stays on the chosen
   wall-clock time — Task 3, "the time is built from calendar fields, never 24 hours added",
   run in its own step with `TZ=Europe/Berlin` (Clarification 5).
3. **The background delivery writing while the person changes the reminder**: the
   delivery's write touches its one column, so the switch, the time and `updated_at` the
   person just saved stay — Task 1, "recording a delivery writes that one column …".
4. **A reset while the reminder is on**: the next reconcile cancels the pending reminder,
   and a fire before that shows nothing and schedules nothing — Task 5, "a reminder that is
   off cancels what is pending …", and Task 7, "a reminder that is off shows nothing …".
5. **An alarm deferred past midnight**: no notification for yesterday's reminder at 00:30,
   and today's stays at its time — Task 3, "a fire deferred past midnight …", and Task 7,
   "a fire before its time shows nothing …".

The other inputs that could bite (a denied permission, a platform that refuses, a save or
a read that fails, nothing due, a day already delivered, a platform without reminders) are
spec §11's, and their tests are in Tasks 1 and 4–7.

## File Structure

```
lib/features/settings/
├── domain/models/reminder_settings_model.dart       ReminderSettings (1)
├── domain/models/reminder_snapshot_model.dart       ReminderSnapshot (1)
├── domain/failures/settings_failure.dart            reminderMinuteOutOfRange (1)
├── domain/entities/app_settings_entity.dart         reminder (1)
├── domain/repositories/settings_repository.dart     saveReminder, reminderSnapshot,
│                                                    recordReminderDelivered (1)
├── data/datasources/settings_dao.dart               row() (1)
├── data/mappers/app_settings_mapper.dart            reminderSnapshotOf,
│                                                    reminderColumnsOf (1)
└── data/repositories/settings_repository_impl.dart  the three methods; reset of six (1)

lib/features/reminders/                              (new)
├── domain/
│   ├── models/reminder_digest_model.dart            ReminderDeckWorkload,
│   │                                                compareReminderDecks,
│   │                                                ReminderDigest, reminderDigestOf (2)
│   ├── models/reminder_time_model.dart              nextReminderAt, ReminderFireCheck,
│   │                                                reminderFireCheckOf (3)
│   ├── repositories/reminder_workload_repository.dart   (4)
│   ├── models/reminder_platform_model.dart          ReminderCapability,
│   │                                                ReminderPermission (5)
│   ├── failures/reminder_failure.dart               ReminderRejection (5)
│   ├── repositories/reminder_platform_repository.dart   the port (5)
│   ├── models/reminder_status_model.dart            ReminderStatus (5)
│   ├── models/reminder_fire_report_model.dart       ReminderFireOutcome,
│   │                                                ReminderFireReport (7)
│   └── usecases/                                    watch_reminder, reconcile_reminder (5);
│                                                    enable_reminder, disable_reminder,
│                                                    change_reminder_time (6);
│                                                    deliver_reminder (7)
├── data/
│   ├── datasources/reminder_workload_dao.dart       rootDeckRows (4)
│   ├── mappers/reminder_workload_mapper.dart        reminderDeckWorkloadOf (4)
│   └── repositories/                                reminder_workload_repository_impl (4),
│                                                    unsupported_reminder_platform_
│                                                    repository_impl (5)
└── di/                                              reminder_workload_repository_provider (4),
                                                     reminder_platform_repository_provider (5)

test/architecture/boundary_rules.dart                'reminders': {...} (2)
test/support/fake_reminder_platform.dart             FakeReminderPlatform, PlatformCall (5)
test/features/settings/                              reminder_settings_model_test,
                                                     reminder_settings_repository_test, the
                                                     reset test of app_settings_repository_test (1)
test/features/reminders/domain/                      reminder_digest_model_test (2),
                                                     reminder_time_model_test (3),
                                                     watch_reminder_use_case_test,
                                                     reconcile_reminder_use_case_test (5),
                                                     enable_, disable_,
                                                     change_reminder_time_use_case_test (6),
                                                     deliver_reminder_use_case_test (7)
test/features/reminders/data/                        reminder_workload_repository_test (4),
                                                     unsupported_reminder_platform_
                                                     repository_test (5)
```

Other changed files: `docs/_generated/` where a task's tests name a use case id (every
task); UC-SETTINGS-001 and the settings README (Task 1); and in Task 8 UC-REMINDER-001,
the reminders README, row 108 of the UI-base spec's register, `wbs_BE.md`, `wbs_FE.md`
and `verification_impact_map.json`.

---


### Task 1: Settings keeps the reminder's values, and a reset covers them

**Files:**
- Create: `lib/features/settings/domain/models/reminder_settings_model.dart`, `lib/features/settings/domain/models/reminder_snapshot_model.dart`
- Modify: `docs/features/settings/README.md`, `docs/features/settings/usecases/UC-SETTINGS-001-dat-tuy-chon-ung-dung.md`, `lib/features/settings/data/datasources/settings_dao.dart`, `lib/features/settings/data/mappers/app_settings_mapper.dart`, `lib/features/settings/data/repositories/settings_repository_impl.dart`, `lib/features/settings/domain/entities/app_settings_entity.dart`, `lib/features/settings/domain/failures/settings_failure.dart`, `lib/features/settings/domain/repositories/settings_repository.dart`
- Test (create): `test/features/settings/data/reminder_settings_repository_test.dart`, `test/features/settings/domain/reminder_settings_model_test.dart`
- Test (modify): `test/features/settings/data/app_settings_repository_test.dart`
- Regenerate: `docs/_generated/` (`python3 tools/docs/generate.py`)

**Interfaces:**
- Consumes: `SettingsRepositoryImpl` and `SettingsDao` as they stand; `StudyOptions.check()`
  as the pattern; the `app_settings` columns `reminder_enabled`, `reminder_minute_of_day`
  and `reminder_last_delivered_at` (schema.md); `openTestDatabase`, `totalChanges`,
  `SelectCounter` and `FailingUpdates` of `test/support/test_database.dart`.
- Produces:
  - `final class ReminderSettings { const ReminderSettings({required bool isEnabled, required int minuteOfDay}); static const minMinuteOfDay = 0; static const maxMinuteOfDay = 1439; static const defaultMinuteOfDay = 1200; static const defaults; Outcome<void, SettingsRejection> check(); }`
    (`settings/domain/models/reminder_settings_model.dart`).
  - `final class ReminderSnapshot { const ReminderSnapshot({required ReminderSettings reminder, required DateTime? lastDeliveredAt, required LanguageChoice language}); }`
    (`settings/domain/models/reminder_snapshot_model.dart`).
  - `SettingsRejection.reminderMinuteOutOfRange`; `AppSettingsEntity.reminder`.
  - In `SettingsRepository`:
    `Future<Outcome<void, SettingsRejection>> saveReminder({required ReminderSettings reminder})`,
    `Future<ReminderSnapshot> reminderSnapshot()` and
    `Future<void> recordReminderDelivered({required DateTime at})`; `resetToDefaults()`
    writes six values.

Spec §5, D2, D3, D5; Review Focus 3. The reset test of package 1 said the
reminder columns stay; it now says six values return and the last delivery stays.

- [ ] **Step 1: Write the failing tests**

In `test/features/settings/data/app_settings_repository_test.dart`:

Replace

```dart

  test('reset to defaults returns the four values and writes nothing else: '
      'not the reminder columns, not a root override '
      '(UC-SETTINGS-001 A3, BR-SETTINGS-008)', () async {
    await _insertRootWithOverride(db);
```

with

```dart

  test('reset to defaults returns the six values in one write and nothing '
      'else: not the last delivery, not a root override '
      '(UC-SETTINGS-001 A3, BR-SETTINGS-008, reminders spec D3)', () async {
    await _insertRootWithOverride(db);
```

Replace

```dart
    await db.customStatement(
      'UPDATE app_settings SET reminder_enabled = 1, reminder_minute_of_day = 480 '
      'WHERE id = 1',
    );
```

with

```dart
    await db.customStatement(
      'UPDATE app_settings SET reminder_enabled = 1, reminder_minute_of_day = 480, '
      'reminder_last_delivered_at = 1790000000 WHERE id = 1',
    );
```

Replace

```dart
    expect(current.language, LanguageChoice.system);
    final row = await settingsRow(db);
    expect(row['reminder_enabled'], 1);
    expect(row['reminder_minute_of_day'], 480);
  });
```

with

```dart
    expect(current.language, LanguageChoice.system);
    expect(current.reminder.isEnabled, isFalse);
    expect(current.reminder.minuteOfDay, 1200);
    final row = await settingsRow(db);
    expect(row['reminder_enabled'], 0);
    expect(row['reminder_minute_of_day'], 1200);
    expect(row['reminder_last_delivered_at'], 1790000000);
  });
```

Create `test/features/settings/data/reminder_settings_repository_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:memox/features/settings/domain/failures/settings_failure.dart';
import 'package:memox/features/settings/domain/models/language_choice_model.dart';
import 'package:memox/features/settings/domain/models/reminder_settings_model.dart';

import '../../../support/test_database.dart';

// The daily reminder's values in the one `app_settings` row: the settings
// feature writes them for the reminders feature (reminders spec §5, D2).

DateTime _t0() => DateTime(2026, 9, 26, 9);

final _deliveredAt = DateTime(2026, 9, 26, 20, 1);

const _onAt0800 = ReminderSettings(isEnabled: true, minuteOfDay: 480);

Future<Map<String, Object?>> _row(AppDatabase db) async =>
    (await db
            .customSelect('SELECT * FROM app_settings WHERE id = 1')
            .getSingle())
        .data;

void main() {
  late AppDatabase db;
  late SettingsRepositoryImpl settings;
  setUp(() {
    db = openTestDatabase();
    settings = SettingsRepositoryImpl(db, now: _t0);
  });
  tearDown(() => db.close());

  test('a fresh install has the reminder off at 20:00 and nothing delivered '
      '(BR-REMINDER-001, UC-REMINDER-001 step 1)', () async {
    final current = await settings.watchAppSettings().first;
    final snapshot = await settings.reminderSnapshot();

    expect(current.reminder.isEnabled, isFalse);
    expect(current.reminder.minuteOfDay, 1200);
    expect(snapshot.reminder.isEnabled, isFalse);
    expect(snapshot.lastDeliveredAt, isNull);
    expect(snapshot.language, LanguageChoice.system);
  });

  test('saving the reminder writes both values and every watcher sees them '
      '(UC-REMINDER-001 step 3, A1)', () async {
    final seen = <(bool, int)>[];
    final subscription = settings.watchAppSettings().listen(
      (current) =>
          seen.add((current.reminder.isEnabled, current.reminder.minuteOfDay)),
    );
    await pumpEventQueue();

    final result = await settings.saveReminder(reminder: _onAt0800);
    await pumpEventQueue();
    await subscription.cancel();

    expect(result, isA<Ok<void, SettingsRejection>>());
    expect(seen, [(false, 1200), (true, 480)]);
    final row = await _row(db);
    expect(row['reminder_enabled'], 1);
    expect(row['reminder_minute_of_day'], 480);
  });

  test('a minute out of range is refused before the database is touched '
      '(BR-REMINDER-002)', () async {
    await settings.watchAppSettings().first;
    final before = await totalChanges(db);

    final result = await settings.saveReminder(
      reminder: const ReminderSettings(isEnabled: true, minuteOfDay: 1440),
    );

    expect(
      result,
      isA<Rejected<void, SettingsRejection>>().having(
        (rejected) => rejected.reason,
        'reason',
        SettingsRejection.reminderMinuteOutOfRange,
      ),
    );
    expect(await totalChanges(db), before);
  });

  test('the snapshot reads the reminder, the last delivery and the language '
      'in one statement (schema.md, reminders spec §5)', () async {
    final counter = SelectCounter();
    final counted = openTestDatabase(interceptor: counter);
    addTearDown(counted.close);
    final repository = SettingsRepositoryImpl(counted, now: _t0);
    await repository.setLanguage(language: LanguageChoice.vi);
    await repository.saveReminder(reminder: _onAt0800);
    await repository.recordReminderDelivered(at: _deliveredAt);
    counter.selects = 0;

    final snapshot = await repository.reminderSnapshot();

    expect(counter.selects, 1);
    expect(snapshot.reminder.isEnabled, isTrue);
    expect(snapshot.reminder.minuteOfDay, 480);
    expect(snapshot.lastDeliveredAt!.isAtSameMomentAs(_deliveredAt), isTrue);
    expect(snapshot.language, LanguageChoice.vi);
  });

  test(
    'recording a delivery writes that one column: the switch, the time '
    'and updated_at stay as they were (schema.md, BR-REMINDER-004)',
    () async {
      await settings.saveReminder(reminder: _onAt0800);
      final before = await _row(db);
      final changes = await totalChanges(db);

      await settings.recordReminderDelivered(at: _deliveredAt);

      final after = await _row(db);
      expect(await totalChanges(db), changes + 1);
      expect(
        {...after}..remove('reminder_last_delivered_at'),
        {...before}..remove('reminder_last_delivered_at'),
      );
      expect(before['reminder_last_delivered_at'], isNull);
      final snapshot = await settings.reminderSnapshot();
      expect(snapshot.lastDeliveredAt!.isAtSameMomentAs(_deliveredAt), isTrue);
    },
  );

  test('a snapshot of a settings row that is gone is a read failure, never '
      'made-up values (UC-REMINDER-001 E7)', () async {
    await db.customStatement('DELETE FROM app_settings');

    await expectLater(
      settings.reminderSnapshot(),
      throwsA(isA<UnknownDatabaseFailure>()),
    );
  });

  test('a failed save of the reminder leaves as a typed Failure and the stored '
      'reminder stays (UC-REMINDER-001 E4)', () async {
    final failing = openTestDatabase(interceptor: FailingUpdates());
    addTearDown(failing.close);
    final broken = SettingsRepositoryImpl(failing, now: _t0);

    await expectLater(
      broken.saveReminder(reminder: _onAt0800),
      throwsA(isA<ConstraintFailure>()),
    );
    expect((await broken.watchAppSettings().first).reminder.isEnabled, isFalse);
  });
}
```

Create `test/features/settings/domain/reminder_settings_model_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/settings/domain/entities/app_settings_entity.dart';
import 'package:memox/features/settings/domain/failures/settings_failure.dart';
import 'package:memox/features/settings/domain/models/reminder_settings_model.dart';

// The daily reminder's two values: off until a person turns it on, at a
// minute of the local day (BR-REMINDER-001, BR-REMINDER-002).

void main() {
  test('the reminder is off at 20:00 by default, in the app defaults too '
      '(BR-REMINDER-001, BR-REMINDER-002)', () {
    expect(ReminderSettings.defaults.isEnabled, isFalse);
    expect(ReminderSettings.defaults.minuteOfDay, 1200);
    expect(AppSettingsEntity.defaults.reminder.isEnabled, isFalse);
    expect(AppSettingsEntity.defaults.reminder.minuteOfDay, 1200);
  });

  for (final minute in [0, 1439]) {
    test('minute $minute of the local day is a reminder time '
        '(BR-REMINDER-002)', () {
      final result = ReminderSettings(
        isEnabled: true,
        minuteOfDay: minute,
      ).check();

      expect(result, isA<Ok<void, SettingsRejection>>());
    });
  }

  for (final minute in [-1, 1440]) {
    test('minute $minute is refused with its reason (BR-REMINDER-002)', () {
      final result = ReminderSettings(
        isEnabled: true,
        minuteOfDay: minute,
      ).check();

      expect(
        result,
        isA<Rejected<void, SettingsRejection>>().having(
          (rejected) => rejected.reason,
          'reason',
          SettingsRejection.reminderMinuteOutOfRange,
        ),
      );
    });
  }
}
```

- [ ] **Step 2: Run them to see them fail**

```bash
flutter test test/features/settings/data/app_settings_repository_test.dart \
  test/features/settings/data/reminder_settings_repository_test.dart \
  test/features/settings/domain/reminder_settings_model_test.dart
```

Expected: `+0 -3: Some tests failed.` None of the three test files compiles:
`Error: Error when reading 'lib/features/settings/domain/models/reminder_settings_model.dart': No such file or directory`,
then `Error: The getter 'reminder' isn't defined for the type 'AppSettingsEntity'.`,
`Error: The method 'saveReminder' isn't defined for the type 'SettingsRepositoryImpl'.`,
the same for `reminderSnapshot` and `recordReminderDelivered`, and
`Error: Member not found: 'reminderMinuteOutOfRange'.` The tool may then print `Error: The Dart compiler exited unexpectedly.`
and a stack trace; the run still ends as above.

- [ ] **Step 3: Name the reminder, its bounds, its snapshot and its refusal**

Create `lib/features/settings/domain/models/reminder_settings_model.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/settings/domain/failures/settings_failure.dart';

/// The daily reminder a person set (UC-REMINDER-001): whether it is on, and
/// its time as a minute of the local day. This is the one definition of its
/// bounds and defaults; `app_settings` stores both values.
final class ReminderSettings {
  const ReminderSettings({required this.isEnabled, required this.minuteOfDay});

  /// BR-REMINDER-002: 00:00 to 23:59 of the local day.
  static const minMinuteOfDay = 0;
  static const maxMinuteOfDay = 1439;

  /// 20:00, the suggested time (BR-REMINDER-002).
  static const defaultMinuteOfDay = 1200;

  /// Off until the person turns it on (BR-REMINDER-001).
  static const defaults = ReminderSettings(
    isEnabled: false,
    minuteOfDay: defaultMinuteOfDay,
  );

  final bool isEnabled;

  /// Minutes after local midnight, read in the offset of the moment it is
  /// used and never converted to UTC (BR-REMINDER-002).
  final int minuteOfDay;

  Outcome<void, SettingsRejection> check() {
    if (minuteOfDay < minMinuteOfDay || minuteOfDay > maxMinuteOfDay) {
      return const Rejected(SettingsRejection.reminderMinuteOutOfRange);
    }
    return const Ok(null);
  }
}
```

Create `lib/features/settings/domain/models/reminder_snapshot_model.dart`:

```dart
import 'package:memox/features/settings/domain/models/language_choice_model.dart';
import 'package:memox/features/settings/domain/models/reminder_settings_model.dart';

/// What scheduling and delivering the reminder read of `app_settings`, at one
/// moment: `schema.md` keeps the last delivery in the same row so that it is
/// read together with the switch and the time.
final class ReminderSnapshot {
  const ReminderSnapshot({
    required this.reminder,
    required this.lastDeliveredAt,
    required this.language,
  });

  final ReminderSettings reminder;

  /// When the last digest was shown; null before the first
  /// (BR-REMINDER-004).
  final DateTime? lastDeliveredAt;

  /// The language the digest is written in (BR-SETTINGS-006).
  final LanguageChoice language;
}
```

In `lib/features/settings/domain/failures/settings_failure.dart`:

Replace

```dart
  notARootDeck,
}
```

with

```dart
  notARootDeck,

  /// BR-REMINDER-002: the reminder's minute is outside 0 to 1439.
  reminderMinuteOutOfRange,
}
```

Replace the whole of `lib/features/settings/domain/entities/app_settings_entity.dart` with:

```dart
import 'package:memox/features/settings/domain/models/language_choice_model.dart';
import 'package:memox/features/settings/domain/models/reminder_settings_model.dart';
import 'package:memox/features/settings/domain/models/study_options_model.dart';
import 'package:memox/features/settings/domain/models/theme_choice_model.dart';

/// The values of the one `app_settings` row a person can set
/// (BR-SETTINGS-001): the study defaults, the theme, the language and the
/// daily reminder.
final class AppSettingsEntity {
  const AppSettingsEntity({
    required this.studyDefaults,
    required this.theme,
    required this.language,
    required this.reminder,
  });

  /// What a fresh database holds and what `Reset to defaults` returns to
  /// (BR-SETTINGS-008).
  static const defaults = AppSettingsEntity(
    studyDefaults: StudyOptions.defaults,
    theme: ThemeChoice.system,
    language: LanguageChoice.system,
    reminder: ReminderSettings.defaults,
  );

  final StudyOptions studyDefaults;
  final ThemeChoice theme;
  final LanguageChoice language;
  final ReminderSettings reminder;
}
```

- [ ] **Step 4: Read and write the reminder, and reset six values**

In `lib/features/settings/domain/repositories/settings_repository.dart`:

Replace

```dart
import 'package:memox/features/settings/domain/models/language_choice_model.dart';
import 'package:memox/features/settings/domain/models/study_options_model.dart';
```

with

```dart
import 'package:memox/features/settings/domain/models/language_choice_model.dart';
import 'package:memox/features/settings/domain/models/reminder_settings_model.dart';
import 'package:memox/features/settings/domain/models/reminder_snapshot_model.dart';
import 'package:memox/features/settings/domain/models/study_options_model.dart';
```

Replace

```dart

  /// The four values a person can set back to their defaults, and nothing
  /// else (BR-SETTINGS-008).
  Future<Outcome<void, SettingsRejection>> resetToDefaults();

```

with

```dart

  /// The six values a person can set back to their defaults, in one
  /// transaction, and nothing else: not the last delivery of the reminder,
  /// which is bookkeeping (BR-SETTINGS-008; reminders spec D3).
  Future<Outcome<void, SettingsRejection>> resetToDefaults();

  /// The daily reminder's switch and time (UC-REMINDER-001 steps 2-3, A1,
  /// A2). A minute out of range is refused before anything is written
  /// (BR-REMINDER-002).
  Future<Outcome<void, SettingsRejection>> saveReminder({
    required ReminderSettings reminder,
  });

  /// The reminder, its last delivery and the language, read in one
  /// statement: the moment a schedule or a delivery is decided from.
  Future<ReminderSnapshot> reminderSnapshot();

  /// Records that the digest was shown at [at]. It writes that one column and
  /// nothing else, not even `updated_at`: the background delivery must never
  /// overwrite a choice the person just changed (`schema.md`).
  Future<void> recordReminderDelivered({required DateTime at});

```

In `lib/features/settings/data/datasources/settings_dao.dart`:

Replace

```dart
  )..where((row) => row.id.equals(appSettingsRowId))).watchSingle();

```

with

```dart
  )..where((row) => row.id.equals(appSettingsRowId))).watchSingle();

  /// [watchRow] read once.
  Future<AppSetting> row() => (_db.select(
    _db.appSettings,
  )..where((row) => row.id.equals(appSettingsRowId))).getSingle();

```

Replace the whole of `lib/features/settings/data/mappers/app_settings_mapper.dart` with:

```dart
import 'package:drift/drift.dart' show Value;
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/settings/domain/entities/app_settings_entity.dart';
import 'package:memox/features/settings/domain/models/language_choice_model.dart';
import 'package:memox/features/settings/domain/models/reminder_settings_model.dart';
import 'package:memox/features/settings/domain/models/reminder_snapshot_model.dart';
import 'package:memox/features/settings/domain/models/study_options_model.dart';
import 'package:memox/features/settings/domain/models/theme_choice_model.dart';

/// The stored codes are the enum names, and the table's `CHECK` constraints
/// keep them valid: an unknown code is corrupt data and throws.
AppSettingsEntity appSettingsOf(AppSetting row) => AppSettingsEntity(
  studyDefaults: StudyOptions(
    cardLimit: row.cardLimit,
    newCardOrder: NewCardOrder.values.byName(row.newCardOrder),
  ),
  theme: ThemeChoice.values.byName(row.themeMode),
  language: LanguageChoice.values.byName(row.language),
  reminder: _reminderOf(row),
);

ReminderSnapshot reminderSnapshotOf(AppSetting row) => ReminderSnapshot(
  reminder: _reminderOf(row),
  lastDeliveredAt: row.reminderLastDeliveredAt,
  language: LanguageChoice.values.byName(row.language),
);

/// The two reminder columns of [reminder]. `reminder_enabled` stores the
/// switch as 0 or 1.
AppSettingsCompanion reminderColumnsOf(ReminderSettings reminder) =>
    AppSettingsCompanion(
      reminderEnabled: Value(reminder.isEnabled ? 1 : 0),
      reminderMinuteOfDay: Value(reminder.minuteOfDay),
    );

ReminderSettings _reminderOf(AppSetting row) => ReminderSettings(
  isEnabled: row.reminderEnabled == 1,
  minuteOfDay: row.reminderMinuteOfDay,
);
```

In `lib/features/settings/data/repositories/settings_repository_impl.dart`:

Replace

```dart
import 'package:memox/features/settings/domain/models/language_choice_model.dart';
import 'package:memox/features/settings/domain/models/study_options_model.dart';
```

with

```dart
import 'package:memox/features/settings/domain/models/language_choice_model.dart';
import 'package:memox/features/settings/domain/models/reminder_settings_model.dart';
import 'package:memox/features/settings/domain/models/reminder_snapshot_model.dart';
import 'package:memox/features/settings/domain/models/study_options_model.dart';
```

Replace

```dart
    return _save(
      AppSettingsCompanion(
        cardLimit: Value(defaults.studyDefaults.cardLimit),
```

with

```dart
    return _save(
      reminderColumnsOf(defaults.reminder).copyWith(
        cardLimit: Value(defaults.studyDefaults.cardLimit),
```

Replace

```dart
      ),
    );
  }

  @override
  Stream<EffectiveStudyOptions?> watchStudyOptions({required String deckId}) =>
```

with

```dart
      ),
    );
  }

  @override
  Future<Outcome<void, SettingsRejection>> saveReminder({
    required ReminderSettings reminder,
  }) {
    final at = _now();
    return _write(() async {
      if (reminder.check() case Rejected(:final reason)) {
        return Rejected(reason);
      }
      await _dao.updateRow(
        reminderColumnsOf(reminder).copyWith(updatedAt: Value(at)),
      );
      return const Ok(null);
    });
  }

  @override
  Future<ReminderSnapshot> reminderSnapshot() =>
      _mapped(() async => reminderSnapshotOf(await _dao.row()));

  @override
  Future<void> recordReminderDelivered({required DateTime at}) => _mapped(
    () => _dao.updateRow(
      AppSettingsCompanion(reminderLastDeliveredAt: Value(at)),
    ),
  );

  @override
  Stream<EffectiveStudyOptions?> watchStudyOptions({required String deckId}) =>
```

- [ ] **Step 5: Say six values in UC-SETTINGS-001, and what settings stores**

Replace the whole of `docs/features/settings/README.md` with:

```markdown
---
feature: settings
code: [lib/features/settings/domain, lib/features/settings/data, lib/features/settings/di]
depends_on: [deck, srs, study]
---
## Phạm vi

Tuỳ chọn ứng dụng (V8.0): mặc định học toàn app, theme và ngôn ngữ trong một dòng `app_settings`. Feature này cũng lưu công tắc, giờ và lần gửi gần nhất của nhắc học hằng ngày trong dòng đó, cho feature `reminders` ([spec gói 11a](../../superpowers/specs/2026-09-26-reminders-backend-design.md) D2).

## Màn hình → Use case

| Màn hình | UC |
|---|---|
| Tab Settings | UC-SETTINGS-001 |

Nguồn: trigger của UC-SETTINGS-001 ("Mở tab `Settings` của navigation shell, hoặc deep link `/settings`"). Nhắc học hằng ngày (UC-REMINDER-001) nằm trong branch Settings nhưng thuộc feature `reminders`.

## Không thuộc phạm vi

| Thứ | Vì sao |
|---|---|
| Override theo root deck | Luật ở BR-STUDY-056 (feature `study`) |
| Nhắc học hằng ngày: lịch, quyền, nội dung notification | Feature `reminders`; settings chỉ lưu giá trị của nó |
```

In `docs/features/settings/usecases/UC-SETTINGS-001-dat-tuy-chon-ung-dung.md`:

Replace

```markdown
  xác nhận và nói rõ hành động này **không** đụng tiến độ học. Xác nhận đưa cả
  bốn giá trị về mặc định trong một transaction (BR-SETTINGS-008).
- **A4 — Bấm lưu lần thứ hai khi lần đầu chưa xong:** hệ thống bỏ qua lần bấm
```

with

```markdown
  xác nhận và nói rõ hành động này **không** đụng tiến độ học. Xác nhận đưa cả
  sáu giá trị về mặc định trong một transaction: bốn tuỳ chọn học và trình bày,
  cùng công tắc và giờ của nhắc học hằng ngày (BR-SETTINGS-008). Lần gửi nhắc
  gần nhất là bookkeeping, không đổi.
- **A4 — Bấm lưu lần thứ hai khi lần đầu chưa xong:** hệ thống bỏ qua lần bấm
```

Run:

```bash
python3 tools/docs/generate.py
python3 tools/docs/check.py
```

Expected: `check.py` ends with `PASS — 0 error(s), 46 warning(s)`.

- [ ] **Step 6: Run the task's tests**

```bash
flutter test test/features/settings/data/app_settings_repository_test.dart \
  test/features/settings/data/reminder_settings_repository_test.dart \
  test/features/settings/domain/reminder_settings_model_test.dart
```

Expected: `+21: All tests passed!`

- [ ] **Step 7: Stage the task's files**

The gate asks every source under `lib/` to be in git, so the task is staged before it runs.

```bash
git add docs/features/settings/README.md \
  docs/features/settings/usecases/UC-SETTINGS-001-dat-tuy-chon-ung-dung.md \
  lib/features/settings/data/datasources/settings_dao.dart \
  lib/features/settings/data/mappers/app_settings_mapper.dart \
  lib/features/settings/data/repositories/settings_repository_impl.dart \
  lib/features/settings/domain/entities/app_settings_entity.dart \
  lib/features/settings/domain/failures/settings_failure.dart \
  lib/features/settings/domain/models/reminder_settings_model.dart \
  lib/features/settings/domain/models/reminder_snapshot_model.dart \
  lib/features/settings/domain/repositories/settings_repository.dart \
  test/features/settings/data/app_settings_repository_test.dart \
  test/features/settings/data/reminder_settings_repository_test.dart \
  test/features/settings/domain/reminder_settings_model_test.dart \
  docs/_generated
git status --short
```

Expected: every path `git status --short` lists is staged: a letter in its first column, a space in its second.

- [ ] **Step 8: Run the gate**

Run:

```bash
bash .claude/skills/flutter-workflow/scripts/dod_check.sh
```

Expected: it ends with `✓ mechanical gates passed`. Among its steps:
`No issues found!`; `✓ generated code is fresh, complete and uncommitted`;
`✓ architecture boundaries clean`; `PASS — 0 error(s), 46 warning(s)` (the
warnings are older than this plan); the CI tooling tests `Ran 77 tests` and
`OK (skipped=8)` (eight of them need PowerShell 7); `204 passed` (the guard's
self-tests); `Code verification passed.`; `+1927: All tests passed!`.

- [ ] **Step 9: Commit**

```bash
git commit -F - <<'EOF'
feat(settings): keep the daily reminder's values; a reset covers them

ReminderSettings (on or off, and a minute of the local day in 0-1439, off at
20:00 by default) joins AppSettingsEntity, so watchAppSettings carries it and
its defaults are defined once. SettingsRepository gains saveReminder, checked
before anything is written (BR-REMINDER-002); reminderSnapshot, the reminder,
its last delivery and the language in one statement; and
recordReminderDelivered, which writes that one column and not updated_at
(schema.md). Reset to defaults returns six values in one transaction and
keeps the last delivery (BR-SETTINGS-008; reminders spec D3, D5).
UC-SETTINGS-001 A3 says six values; the settings README says what it stores
for the reminders feature.
EOF
```

Append the session's attribution trailers to the message when you commit.


### Task 2: The most urgent root deck, and the digest

**Files:**
- Create: `lib/features/reminders/domain/models/reminder_digest_model.dart`
- Test (create): `test/features/reminders/domain/reminder_digest_model_test.dart`
- Test (modify): `test/architecture/boundary_rules.dart`
- Regenerate: `docs/_generated/` (`python3 tools/docs/generate.py`)

**Interfaces:**
- Consumes: `foldText` (`lib/core/text/folded_text.dart`).
- Produces:
  - `ReminderDeckWorkload({required String deckId, required String name, required int overdueCount, required int overdueDays, required int dueTodayCount})`
    with `int get dueCount`;
    `int compareReminderDecks(ReminderDeckWorkload a, ReminderDeckWorkload b)`;
    `ReminderDigest({required String deckName, required int dueCount, required int otherDeckCount})`;
    `ReminderDigest? reminderDigestOf(List<ReminderDeckWorkload> workloads)`
    (`reminders/domain/models/reminder_digest_model.dart`).
  - The import map entry `'reminders': {'settings', 'deck', 'srs'}`.

Spec §7, D9, D10. The import map lets `reminders` import the domain of
`settings`, `deck` and `srs` from here on.

- [ ] **Step 1: Write the failing tests**

In `test/architecture/boundary_rules.dart`:

Replace

```dart
  'starter_decks': {'deck', 'card', 'srs'},
};
```

with

```dart
  'starter_decks': {'deck', 'card', 'srs'},
  'reminders': {'settings', 'deck', 'srs'},
};
```

Create `test/features/reminders/domain/reminder_digest_model_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/reminders/domain/models/reminder_digest_model.dart';

// What the day's notification says: the most urgent root deck by
// BR-REMINDER-006, that deck's own due count and the other roots with cards
// due (BR-REMINDER-005; reminders spec D9, D10).

ReminderDeckWorkload _root(
  String id, {
  String? name,
  int overdue = 0,
  int days = 0,
  int dueToday = 0,
}) => ReminderDeckWorkload(
  deckId: id,
  name: name ?? id,
  overdueCount: overdue,
  overdueDays: days,
  dueTodayCount: dueToday,
);

List<String> _ordered(List<ReminderDeckWorkload> roots) => [
  for (final root in [...roots]..sort(compareReminderDecks)) root.deckId,
];

void main() {
  test('nothing due is no digest, whatever the new cards '
      '(BR-REMINDER-003, UC-REMINDER-001 A3, A4)', () {
    expect(reminderDigestOf(const []), isNull);
    expect(reminderDigestOf([_root('a'), _root('b')]), isNull);
  });

  test("the digest names the most urgent root, that root's own due count and "
      'the other roots with cards due (BR-REMINDER-005, spec D9)', () {
    final digest = reminderDigestOf([
      _root('a', name: 'Alpha', overdue: 2, dueToday: 3),
      _root('b', name: 'Beta', overdue: 5),
      _root('c', name: 'Gamma', dueToday: 4),
      _root('d', name: 'Delta'),
    ])!;

    expect(digest.deckName, 'Beta');
    expect(digest.dueCount, 5);
    expect(digest.otherDeckCount, 2);
  });

  test("a root's due count is its overdue and its due-today cards together "
      '(BR-REMINDER-003)', () {
    final digest = reminderDigestOf([
      _root('a', name: 'Alpha', overdue: 2, dueToday: 3),
    ])!;

    expect(digest.dueCount, 5);
    expect(digest.otherDeckCount, 0);
  });

  test('more overdue cards come first (BR-REMINDER-006)', () {
    expect(
      _ordered([
        _root('a', overdue: 2, days: 9, dueToday: 9),
        _root('b', overdue: 3),
      ]),
      ['b', 'a'],
    );
  });

  test('with as many overdue cards, the older backlog comes first '
      '(BR-REMINDER-006, BR-STUDY-067)', () {
    expect(
      _ordered([
        _root('a', overdue: 2, days: 1, dueToday: 9),
        _root('b', overdue: 2, days: 4),
      ]),
      ['b', 'a'],
    );
  });

  test('with the same overdue cards and age, more cards due today come '
      'first (BR-REMINDER-006)', () {
    expect(
      _ordered([
        _root('a', overdue: 2, days: 1, dueToday: 2),
        _root('b', overdue: 2, days: 1, dueToday: 5),
      ]),
      ['b', 'a'],
    );
  });

  test('then the folded name, not the code units: "alpha" before "Beta" '
      '(BR-REMINDER-006, spec D10)', () {
    expect(
      _ordered([
        _root('b', name: 'Beta', dueToday: 1),
        _root('a', name: 'alpha', dueToday: 1),
      ]),
      ['a', 'b'],
    );
  });

  test('two roots equal in every count and in the folded name are ordered '
      'by id, never by the order they were read in (BR-REMINDER-006)', () {
    final first = _root('x1', name: 'Deck', dueToday: 1);
    final second = _root('x2', name: ' deck ', dueToday: 1);

    expect(_ordered([second, first]), ['x1', 'x2']);
    expect(_ordered([first, second]), ['x1', 'x2']);
    expect(reminderDigestOf([second, first])!.deckName, 'Deck');
  });
}
```

- [ ] **Step 2: Run them to see them fail**

```bash
flutter test test/features/reminders/domain/reminder_digest_model_test.dart
```

Expected: `+0 -1: Some tests failed.` The test file does not compile:
`Error: Error when reading 'lib/features/reminders/domain/models/reminder_digest_model.dart': No such file or directory`,
then `Error: Type 'ReminderDeckWorkload' not found.`,
`Error: Undefined name 'compareReminderDecks'.` and
`Error: Method not found: 'reminderDigestOf'.`

- [ ] **Step 3: Order the roots and build the digest**

Create `lib/features/reminders/domain/models/reminder_digest_model.dart`:

```dart
import 'package:memox/core/text/folded_text.dart';

/// One root deck's cards due when the reminder fires: its whole tree, grouped
/// by `root_id` so that each card counts once (BR-REMINDER-007). Learned
/// cards only; a card still being learned is never due (BR-REMINDER-003).
final class ReminderDeckWorkload {
  const ReminderDeckWorkload({
    required this.deckId,
    required this.name,
    required this.overdueCount,
    required this.overdueDays,
    required this.dueTodayCount,
  });

  final String deckId;
  final String name;

  /// Due before the start of today (BR-STUDY-068).
  final int overdueCount;

  /// The local day boundaries passed since the oldest due card fell due; 0
  /// when nothing is overdue (BR-STUDY-067).
  final int overdueDays;

  /// Due from the start of today up to now (BR-STUDY-068).
  final int dueTodayCount;

  int get dueCount => overdueCount + dueTodayCount;
}

/// BR-REMINDER-006: the most urgent first. Overdue cards, then the oldest
/// overdue age, then the cards due today, each descending; then the folded
/// name (`foldText`, as Study Home sorts), then the id, so that no two roots
/// tie.
int compareReminderDecks(ReminderDeckWorkload a, ReminderDeckWorkload b) {
  final overdue = b.overdueCount.compareTo(a.overdueCount);
  if (overdue != 0) return overdue;
  final age = b.overdueDays.compareTo(a.overdueDays);
  if (age != 0) return age;
  final dueToday = b.dueTodayCount.compareTo(a.dueTodayCount);
  if (dueToday != 0) return dueToday;
  final name = foldText(a.name).compareTo(foldText(b.name));
  if (name != 0) return name;
  return a.deckId.compareTo(b.deckId);
}

/// What the day's one notification may say (BR-REMINDER-005): the most
/// urgent root deck, that deck's own due count, and how many other root
/// decks have cards due (reminders spec D9). Never a card, a tag or a
/// history.
final class ReminderDigest {
  const ReminderDigest({
    required this.deckName,
    required this.dueCount,
    required this.otherDeckCount,
  });

  final String deckName;
  final int dueCount;
  final int otherDeckCount;
}

/// The digest of [workloads], or null when no root deck has a card due: the
/// reminder then shows nothing (BR-REMINDER-003).
ReminderDigest? reminderDigestOf(List<ReminderDeckWorkload> workloads) {
  final due = [
    for (final workload in workloads)
      if (workload.dueCount > 0) workload,
  ]..sort(compareReminderDecks);
  if (due.isEmpty) return null;
  final top = due.first;
  return ReminderDigest(
    deckName: top.name,
    dueCount: top.dueCount,
    otherDeckCount: due.length - 1,
  );
}
```

- [ ] **Step 4: Regenerate the docs index**

Run:

```bash
python3 tools/docs/generate.py
python3 tools/docs/check.py
```

Expected: `check.py` ends with `PASS — 0 error(s), 46 warning(s)`.

- [ ] **Step 5: Run the task's tests**

```bash
flutter test test/features/reminders/domain/reminder_digest_model_test.dart
```

Expected: `+8: All tests passed!`

- [ ] **Step 6: Stage the task's files**

The gate asks every source under `lib/` to be in git, so the task is staged before it runs.

```bash
git add lib/features/reminders/domain/models/reminder_digest_model.dart \
  test/architecture/boundary_rules.dart \
  test/features/reminders/domain/reminder_digest_model_test.dart \
  docs/_generated
git status --short
```

Expected: every path `git status --short` lists is staged: a letter in its first column, a space in its second.

- [ ] **Step 7: Run the gate**

Run:

```bash
bash .claude/skills/flutter-workflow/scripts/dod_check.sh
```

Expected: it ends with `✓ mechanical gates passed`. Among its steps:
`No issues found!`; `✓ generated code is fresh, complete and uncommitted`;
`✓ architecture boundaries clean`; `PASS — 0 error(s), 46 warning(s)` (the
warnings are older than this plan); the CI tooling tests `Ran 77 tests` and
`OK (skipped=8)` (eight of them need PowerShell 7); `204 passed` (the guard's
self-tests); `Code verification passed.`; `+1935: All tests passed!`.

- [ ] **Step 8: Commit**

```bash
git commit -F - <<'EOF'
feat(reminders): the most urgent root deck, and the digest

The reminders feature starts with its order and its digest, pure Dart:
compareReminderDecks sorts roots by overdue cards, the oldest overdue age,
the cards due today, the folded name and the id (BR-REMINDER-006), and
reminderDigestOf names the most urgent root with its own due count and the
number of other roots with cards due, or nothing when none is due
(BR-REMINDER-003, BR-REMINDER-005; spec D9, D10). The import map gains
'reminders': {settings, deck, srs}.
EOF
```

Append the session's attribution trailers to the message when you commit.


### Task 3: The next fire and the fire check, in local time

**Files:**
- Create: `lib/features/reminders/domain/models/reminder_time_model.dart`
- Test (create): `test/features/reminders/domain/reminder_time_model_test.dart`
- Regenerate: `docs/_generated/` (`python3 tools/docs/generate.py`)

**Interfaces:**
- Consumes: Task 1's `ReminderSettings`.
- Produces (`reminders/domain/models/reminder_time_model.dart`):
  - `DateTime nextReminderAt({required DateTime now, required int minuteOfDay, DateTime? lastDeliveredAt})`.
  - `enum ReminderFireCheck { disabled, beforeReminderTime, alreadyDeliveredToday, due }`
    and
    `ReminderFireCheck reminderFireCheckOf({required ReminderSettings reminder, required DateTime now, DateTime? lastDeliveredAt})`.

Spec §8, D11, D12; Clarification 5; Review Focus 2 and 5.

- [ ] **Step 1: Write the failing tests**

Create `test/features/reminders/domain/reminder_time_model_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/reminders/domain/models/reminder_time_model.dart';
import 'package:memox/features/settings/domain/models/reminder_settings_model.dart';

// When the reminder fires next, and whether a fire is the day's reminder: a
// minute of the local day, read in the offset of the moment it is used
// (BR-REMINDER-002, BR-REMINDER-004; reminders spec D11, D12).

const _on2000 = ReminderSettings(isEnabled: true, minuteOfDay: 1200);

void main() {
  group('nextReminderAt', () {
    test("a time still ahead today is today's reminder "
        '(UC-REMINDER-001 step 3)', () {
      expect(
        nextReminderAt(now: DateTime(2026, 9, 26, 19), minuteOfDay: 1200),
        DateTime(2026, 9, 26, 20),
      );
    });

    test("a time already passed today is tomorrow's "
        '(UC-REMINDER-001 step 3)', () {
      expect(
        nextReminderAt(now: DateTime(2026, 9, 26, 21), minuteOfDay: 1200),
        DateTime(2026, 9, 27, 20),
      );
    });

    test('the very minute is not ahead: the next one is tomorrow', () {
      expect(
        nextReminderAt(now: DateTime(2026, 9, 26, 20), minuteOfDay: 1200),
        DateTime(2026, 9, 27, 20),
      );
    });

    test('a day that already had its digest moves to tomorrow, even with its '
        'new time still ahead (BR-REMINDER-004)', () {
      expect(
        nextReminderAt(
          now: DateTime(2026, 9, 26, 21),
          minuteOfDay: 1320,
          lastDeliveredAt: DateTime(2026, 9, 26, 20, 1),
        ),
        DateTime(2026, 9, 27, 22),
      );
    });

    test("yesterday's digest leaves today's reminder where it is "
        '(BR-REMINDER-004)', () {
      expect(
        nextReminderAt(
          now: DateTime(2026, 9, 26, 19),
          minuteOfDay: 1200,
          lastDeliveredAt: DateTime(2026, 9, 25, 20, 1),
        ),
        DateTime(2026, 9, 26, 20),
      );
    });

    test('month and year ends roll over to the first of the next', () {
      expect(
        nextReminderAt(now: DateTime(2026, 12, 31, 23), minuteOfDay: 1200),
        DateTime(2027, 1, 1, 20),
      );
      expect(
        nextReminderAt(now: DateTime(2026, 2, 28, 23), minuteOfDay: 1200),
        DateTime(2026, 3, 1, 20),
      );
    });

    test("minute 0 and minute 1439 are the day's first and last minute "
        '(BR-REMINDER-002)', () {
      final noon = DateTime(2026, 9, 26, 12);

      expect(nextReminderAt(now: noon, minuteOfDay: 0), DateTime(2026, 9, 27));
      expect(
        nextReminderAt(now: noon, minuteOfDay: 1439),
        DateTime(2026, 9, 26, 23, 59),
      );
    });

    test('the time is built from calendar fields, never 24 hours added: '
        'across a clock change it stays 20:00 (BR-REMINDER-002, spec D11)', () {
      // Europe moves its clocks on 29 March and 25 October 2026; 24 hours
      // after 20:00 lands on 21:00 or 19:00 there. Run with
      // TZ=Europe/Berlin to see it.
      final spring = nextReminderAt(
        now: DateTime(2026, 3, 28, 21),
        minuteOfDay: 1200,
      );
      final autumn = nextReminderAt(
        now: DateTime(2026, 10, 24, 21),
        minuteOfDay: 1200,
      );

      expect(spring, DateTime(2026, 3, 29, 20));
      expect(spring.hour, 20);
      expect(autumn, DateTime(2026, 10, 25, 20));
      expect(autumn.hour, 20);
    });
  });

  group('reminderFireCheckOf', () {
    test('a reminder that is off never fires (UC-REMINDER-001 E6)', () {
      expect(
        reminderFireCheckOf(
          reminder: const ReminderSettings(isEnabled: false, minuteOfDay: 1200),
          now: DateTime(2026, 9, 26, 20),
        ),
        ReminderFireCheck.disabled,
      );
    });

    test("at the chosen minute the fire is the day's reminder "
        '(UC-REMINDER-001 step 4)', () {
      expect(
        reminderFireCheckOf(reminder: _on2000, now: DateTime(2026, 9, 26, 20)),
        ReminderFireCheck.due,
      );
    });

    test('a fire late on the same day is still that day\'s reminder '
        '(spec D12)', () {
      expect(
        reminderFireCheckOf(
          reminder: _on2000,
          now: DateTime(2026, 9, 26, 23, 10),
        ),
        ReminderFireCheck.due,
      );
    });

    test('a minute early, the fire is not the reminder yet (spec D12)', () {
      expect(
        reminderFireCheckOf(
          reminder: _on2000,
          now: DateTime(2026, 9, 26, 19, 59),
        ),
        ReminderFireCheck.beforeReminderTime,
      );
    });

    test("a fire deferred past midnight is not yesterday's reminder, and not "
        "today's either (spec D12)", () {
      expect(
        reminderFireCheckOf(
          reminder: _on2000,
          now: DateTime(2026, 9, 27, 0, 30),
          lastDeliveredAt: DateTime(2026, 9, 25, 20, 1),
        ),
        ReminderFireCheck.beforeReminderTime,
      );
    });

    test('a day that already had its digest gets no second one '
        '(BR-REMINDER-004)', () {
      expect(
        reminderFireCheckOf(
          reminder: _on2000,
          now: DateTime(2026, 9, 26, 22),
          lastDeliveredAt: DateTime(2026, 9, 26, 20, 1),
        ),
        ReminderFireCheck.alreadyDeliveredToday,
      );
    });

    test('a delivery read back in UTC is compared on the local date '
        '(ADR-008)', () {
      // Just after local midnight, the UTC date east of Greenwich is still
      // the day before. Run with TZ=Europe/Berlin to see it.
      final delivered = DateTime(2026, 9, 26, 0, 30).toUtc();

      expect(
        reminderFireCheckOf(
          reminder: const ReminderSettings(isEnabled: true, minuteOfDay: 0),
          now: DateTime(2026, 9, 26, 22),
          lastDeliveredAt: delivered,
        ),
        ReminderFireCheck.alreadyDeliveredToday,
      );
    });
  });
}
```

- [ ] **Step 2: Run them to see them fail**

```bash
flutter test test/features/reminders/domain/reminder_time_model_test.dart
```

Expected: `+0 -1: Some tests failed.` The test file does not compile:
`Error: Error when reading 'lib/features/reminders/domain/models/reminder_time_model.dart': No such file or directory`,
then `Error: Method not found: 'nextReminderAt'.`,
`Error: Method not found: 'reminderFireCheckOf'.` and
`Error: Undefined name 'ReminderFireCheck'.`

- [ ] **Step 3: Compute the next fire, and check a fire**

Create `lib/features/reminders/domain/models/reminder_time_model.dart`:

```dart
import 'package:memox/features/settings/domain/models/reminder_settings_model.dart';

/// The next time the reminder fires: today at [minuteOfDay] while that is
/// still ahead and nothing was delivered today, tomorrow at [minuteOfDay]
/// otherwise (BR-REMINDER-002, BR-REMINDER-004).
///
/// Built from calendar fields in local time, never by adding 24 hours: the
/// offset of the day it lands on is the one used, so a clock change or a new
/// time zone keeps it on the chosen wall-clock time (reminders spec D11).
DateTime nextReminderAt({
  required DateTime now,
  required int minuteOfDay,
  DateTime? lastDeliveredAt,
}) {
  final local = now.toLocal();
  final hour = minuteOfDay ~/ Duration.minutesPerHour;
  final minute = minuteOfDay % Duration.minutesPerHour;
  final today = DateTime(local.year, local.month, local.day, hour, minute);
  if (today.isAfter(local) && !_deliveredOn(local, lastDeliveredAt)) {
    return today;
  }
  return DateTime(local.year, local.month, local.day + 1, hour, minute);
}

/// What a fire of the reminder is (reminders spec D12).
enum ReminderFireCheck {
  /// The reminder is off: the fire is left over from before.
  disabled,

  /// The local time has not reached the chosen minute: the alarm was
  /// deferred past midnight, or the person moved west.
  beforeReminderTime,

  /// The local day already had its digest (BR-REMINDER-004).
  alreadyDeliveredToday,

  /// The day's reminder.
  due,
}

ReminderFireCheck reminderFireCheckOf({
  required ReminderSettings reminder,
  required DateTime now,
  DateTime? lastDeliveredAt,
}) {
  if (!reminder.isEnabled) return ReminderFireCheck.disabled;
  final local = now.toLocal();
  final minuteNow = local.hour * Duration.minutesPerHour + local.minute;
  if (minuteNow < reminder.minuteOfDay) {
    return ReminderFireCheck.beforeReminderTime;
  }
  if (_deliveredOn(local, lastDeliveredAt)) {
    return ReminderFireCheck.alreadyDeliveredToday;
  }
  return ReminderFireCheck.due;
}

/// Whether [deliveredAt] falls on the local date of [day].
bool _deliveredOn(DateTime day, DateTime? deliveredAt) {
  if (deliveredAt == null) return false;
  final delivered = deliveredAt.toLocal();
  return delivered.year == day.year &&
      delivered.month == day.month &&
      delivered.day == day.day;
}
```

- [ ] **Step 4: Regenerate the docs index**

Run:

```bash
python3 tools/docs/generate.py
python3 tools/docs/check.py
```

Expected: `check.py` ends with `PASS — 0 error(s), 46 warning(s)`.

- [ ] **Step 5: Run the task's tests**

```bash
flutter test test/features/reminders/domain/reminder_time_model_test.dart
```

Expected: `+15: All tests passed!`

- [ ] **Step 6: Run the time tests where clocks change**

```bash
TZ=Europe/Berlin flutter test test/features/reminders/domain/reminder_time_model_test.dart
```

Expected: `+15: All tests passed!` Berlin moves its clocks on 29 March
and 25 October 2026 and is east of Greenwich, so the test across a clock change and the
test of a delivery just after local midnight now see what they are written for; in UTC,
where the gate runs, both pass whatever the code does with local time.

- [ ] **Step 7: Stage the task's files**

The gate asks every source under `lib/` to be in git, so the task is staged before it runs.

```bash
git add lib/features/reminders/domain/models/reminder_time_model.dart \
  test/features/reminders/domain/reminder_time_model_test.dart \
  docs/_generated
git status --short
```

Expected: every path `git status --short` lists is staged: a letter in its first column, a space in its second.

- [ ] **Step 8: Run the gate**

Run:

```bash
bash .claude/skills/flutter-workflow/scripts/dod_check.sh
```

Expected: it ends with `✓ mechanical gates passed`. Among its steps:
`No issues found!`; `✓ generated code is fresh, complete and uncommitted`;
`✓ architecture boundaries clean`; `PASS — 0 error(s), 46 warning(s)` (the
warnings are older than this plan); the CI tooling tests `Ran 77 tests` and
`OK (skipped=8)` (eight of them need PowerShell 7); `204 passed` (the guard's
self-tests); `Code verification passed.`; `+1950: All tests passed!`.

- [ ] **Step 9: Commit**

```bash
git commit -F - <<'EOF'
feat(reminders): the next fire and the fire check, in local time

nextReminderAt builds the next fire from calendar fields in local time:
today's while it is ahead and nothing was delivered today, tomorrow's
otherwise, so a clock change keeps it on the chosen wall-clock time
(BR-REMINDER-002, BR-REMINDER-004; spec D11). reminderFireCheckOf says what a
fire is: the reminder off, before its time on the day it lands (a fire
deferred past midnight, or a move west), a day that had its digest, or due
(spec D12).
EOF
```

Append the session's attribution trailers to the message when you commit.


### Task 4: Read the workload of each root deck at fire time

**Files:**
- Create: `lib/features/reminders/data/datasources/reminder_workload_dao.dart`, `lib/features/reminders/data/mappers/reminder_workload_mapper.dart`, `lib/features/reminders/data/repositories/reminder_workload_repository_impl.dart`, `lib/features/reminders/di/reminder_workload_repository_provider.dart`, `lib/features/reminders/domain/repositories/reminder_workload_repository.dart`
- Test (create): `test/features/reminders/data/reminder_workload_repository_test.dart`
- Regenerate: the `*.g.dart` files (build_runner, not committed), `docs/_generated/` (`python3 tools/docs/generate.py`)

**Interfaces:**
- Consumes: Task 2's `ReminderDeckWorkload`; `AppDatabase.deckLevelOfRoots` and its
  `DeckTileRow`; `DeckScheduleStatus.overdueDays`; `mapDatabaseError`;
  `databaseProvider`; `startOfLocalDay`; `insertCard`, the `DeckFixtures` extension,
  `trashCardRow` and `trashDeckRows` of `test/support/`.
- Produces:
  - `abstract interface class ReminderWorkloadRepository { Future<List<ReminderDeckWorkload>> rootWorkloads({required DateTime now, required DateTime startOfToday}); }`.
  - `ReminderWorkloadDao(AppDatabase)` with
    `Future<List<DeckTileRow>> rootDeckRows({required DateTime now, required DateTime startOfToday})`;
    `ReminderDeckWorkload reminderDeckWorkloadOf(DeckTileRow row, DateTime startOfToday)`;
    `ReminderWorkloadRepositoryImpl(AppDatabase db)`;
    `reminderWorkloadRepositoryProvider`.

Spec §7, D8; Clarification 1. The failing read fails only the workload's
statement, so the database opens and the error is the read's own.

- [ ] **Step 1: Write the failing tests**

Create `test/features/reminders/data/reminder_workload_repository_test.dart`:

```dart
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/reminders/data/repositories/reminder_workload_repository_impl.dart';
import 'package:memox/features/reminders/domain/models/reminder_digest_model.dart';
import 'package:memox/features/srs/domain/models/due_date_model.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/test_database.dart';
import '../../../support/trash_fixtures.dart';

// The cards due when the reminder fires, per root deck: the statement the
// Library's root level and Study Home read (reminders spec §7, D8).

final _now = DateTime(2026, 9, 26, 20);
final _startOfToday = startOfLocalDay(_now);

/// Fails the one statement the workload is read by, the way a locked or
/// broken database does, and nothing else.
final class _FailingWorkloadRead extends QueryInterceptor {
  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    if (statement.contains('due_today_count')) {
      throw SqliteException(
        extendedResultCode: 5,
        message: 'database is locked',
      );
    }
    return super.runSelect(executor, statement, args);
  }
}

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl decks;
  late ReminderWorkloadRepositoryImpl workloads;
  setUp(() {
    db = openTestDatabase();
    decks = DeckRepositoryImpl(db, now: () => _now);
    workloads = ReminderWorkloadRepositoryImpl(db);
  });
  tearDown(() => db.close());

  /// A learned card of [deckId] due at [dueAt].
  Future<void> learned(String deckId, String id, DateTime dueAt) => insertCard(
    db,
    id: id,
    deckId: deckId,
    back: 'meaning $id',
    learnedAt: DateTime(2026, 9, 1),
    dueAt: dueAt,
    box: 2,
  );

  Future<Map<String, ReminderDeckWorkload>> read() async => {
    for (final workload in await workloads.rootWorkloads(
      now: _now,
      startOfToday: _startOfToday,
    ))
      workload.name: workload,
  };

  test('a root counts the overdue and due-today cards of its whole tree, '
      'each once, and a root with none counts zero (BR-REMINDER-007, '
      'BR-STUDY-068)', () async {
    final korean = await decks.root('Korean');
    final lesson = await decks.sub(korean.id, 'Lesson A');
    final part = await decks.sub(lesson.id, 'Part 1');
    await decks.root('Empty');
    await learned(part.id, 'o1', DateTime(2026, 9, 20));
    await learned(lesson.id, 'o2', DateTime(2026, 9, 25));
    await learned(lesson.id, 't1', _startOfToday);
    await learned(part.id, 't2', _startOfToday);
    await learned(part.id, 't3', _startOfToday);
    await learned(part.id, 'later', DateTime(2026, 9, 27));

    final roots = await read();

    expect(roots.keys, unorderedEquals(['Korean', 'Empty']));
    expect(roots['Korean']!.deckId, korean.id);
    expect(roots['Korean']!.overdueCount, 2);
    expect(roots['Korean']!.dueTodayCount, 3);
    expect(roots['Korean']!.dueCount, 5);
    expect(roots['Empty']!.dueCount, 0);
  });

  test('the overdue age is the local days since the oldest due card fell due '
      '(BR-REMINDER-006, BR-STUDY-067)', () async {
    final korean = await decks.root('Korean');
    final lesson = await decks.sub(korean.id, 'Lesson A');
    await learned(lesson.id, 'o1', DateTime(2026, 9, 20));
    await learned(lesson.id, 'o2', DateTime(2026, 9, 25));
    final today = await decks.root('Today only');
    final todayLesson = await decks.sub(today.id, 'Lesson');
    await learned(todayLesson.id, 't1', _startOfToday);

    final roots = await read();

    expect(roots['Korean']!.overdueDays, 6);
    expect(roots['Today only']!.overdueDays, 0);
  });

  test('a card still being learned is never due, and a root holding only '
      'those counts zero (BR-REMINDER-003, UC-REMINDER-001 A4)', () async {
    final korean = await decks.root('Korean');
    final lesson = await decks.sub(korean.id, 'Lesson A');
    await insertCard(db, id: 'n1', deckId: lesson.id, back: 'new');

    expect((await read())['Korean']!.dueCount, 0);
  });

  test('cards in the Trash are not due, and a root in the Trash is not read '
      '(BR-TRASH-002)', () async {
    final korean = await decks.root('Korean');
    final lesson = await decks.sub(korean.id, 'Lesson A');
    await learned(lesson.id, 'kept', DateTime(2026, 9, 20));
    await learned(lesson.id, 'binned', DateTime(2026, 9, 20));
    await trashCardRow(db, 'binned');
    final old = await decks.root('Old');
    final oldLesson = await decks.sub(old.id, 'Lesson');
    await learned(oldLesson.id, 'gone', DateTime(2026, 9, 20));
    await trashDeckRows(db, old.id);

    final roots = await read();

    expect(roots.keys, ['Korean']);
    expect(roots['Korean']!.overdueCount, 1);
  });

  test('a read that fails leaves as its Failure, for the delivery to skip '
      '(UC-REMINDER-001 E5)', () async {
    final failing = AppDatabase(
      NativeDatabase.memory().interceptWith(_FailingWorkloadRead()),
    );
    addTearDown(failing.close);

    await expectLater(
      ReminderWorkloadRepositoryImpl(failing)
          .rootWorkloads(now: _now, startOfToday: _startOfToday),
      throwsA(isA<DatabaseLockedFailure>()),
    );
  });
}
```

- [ ] **Step 2: Run them to see them fail**

```bash
flutter test test/features/reminders/data/reminder_workload_repository_test.dart
```

Expected: `+0 -1: Some tests failed.` The test file does not compile:
`Error: Error when reading 'lib/features/reminders/data/repositories/reminder_workload_repository_impl.dart': No such file or directory`,
then `Error: 'ReminderWorkloadRepositoryImpl' isn't a type.` and
`Error: Method not found: 'ReminderWorkloadRepositoryImpl'.`

- [ ] **Step 3: Name the read**

Create `lib/features/reminders/domain/repositories/reminder_workload_repository.dart`:

```dart
import 'package:memox/features/reminders/domain/models/reminder_digest_model.dart';

/// The cards due when the reminder fires. The one implementation is
/// `ReminderWorkloadRepositoryImpl` (data layer); the contract exists for
/// ADR-010's reason: domain stays framework-free and tests substitute a fake.
abstract interface class ReminderWorkloadRepository {
  /// Every root deck outside the Trash with the cards of its whole tree due
  /// at [now], split at [startOfToday] into overdue and due today
  /// (BR-STUDY-068), read once, at fire time (BR-REMINDER-003). A database
  /// error leaves as its `Failure`.
  Future<List<ReminderDeckWorkload>> rootWorkloads({
    required DateTime now,
    required DateTime startOfToday,
  });
}
```

- [ ] **Step 4: Read the Library's root statement once, and map its rows**

The provider's `part` file does not exist until the next step generates it.

Create `lib/features/reminders/data/datasources/reminder_workload_dao.dart`:

```dart
import 'package:memox/core/database/app_database.dart';

/// Row access for the reminder's workload. It returns Drift rows, never
/// domain values.
final class ReminderWorkloadDao {
  ReminderWorkloadDao(this._db);

  final AppDatabase _db;

  /// Every root deck outside the Trash with the counts of its whole tree,
  /// grouped by `root_id` (BR-REMINDER-007): the statement the Library's
  /// root level and Study Home read, so the reminder counts what they show
  /// (reminders spec D8).
  Future<List<DeckTileRow>> rootDeckRows({
    required DateTime now,
    required DateTime startOfToday,
  }) => _db.deckLevelOfRoots(startOfToday, now).get();
}
```

Create `lib/features/reminders/data/mappers/reminder_workload_mapper.dart`:

```dart
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/deck/domain/models/deck_schedule_status_model.dart';
import 'package:memox/features/reminders/domain/models/reminder_digest_model.dart';

/// The overdue age counts the local day boundaries since the oldest due card
/// fell due, on calendar dates (BR-STUDY-067).
ReminderDeckWorkload reminderDeckWorkloadOf(
  DeckTileRow row,
  DateTime startOfToday,
) => ReminderDeckWorkload(
  deckId: row.id,
  name: row.name,
  overdueCount: row.overdueCount,
  overdueDays: DeckScheduleStatus.overdueDays(row.oldestDueAt, startOfToday),
  dueTodayCount: row.dueTodayCount,
);
```

Create `lib/features/reminders/data/repositories/reminder_workload_repository_impl.dart`:

```dart
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/reminders/data/datasources/reminder_workload_dao.dart';
import 'package:memox/features/reminders/data/mappers/reminder_workload_mapper.dart';
import 'package:memox/features/reminders/domain/models/reminder_digest_model.dart';
import 'package:memox/features/reminders/domain/repositories/reminder_workload_repository.dart';

final class ReminderWorkloadRepositoryImpl
    implements ReminderWorkloadRepository {
  ReminderWorkloadRepositoryImpl(AppDatabase db)
    : _dao = ReminderWorkloadDao(db);

  final ReminderWorkloadDao _dao;

  @override
  Future<List<ReminderDeckWorkload>> rootWorkloads({
    required DateTime now,
    required DateTime startOfToday,
  }) async {
    try {
      final rows = await _dao.rootDeckRows(
        now: now,
        startOfToday: startOfToday,
      );
      return [
        for (final row in rows) reminderDeckWorkloadOf(row, startOfToday),
      ];
    } on Object catch (error, stackTrace) {
      Error.throwWithStackTrace(mapDatabaseError(error), stackTrace);
    }
  }
}
```

Create `lib/features/reminders/di/reminder_workload_repository_provider.dart`:

```dart
import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/features/reminders/data/repositories/reminder_workload_repository_impl.dart';
import 'package:memox/features/reminders/domain/repositories/reminder_workload_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reminder_workload_repository_provider.g.dart';

@riverpod
ReminderWorkloadRepository reminderWorkloadRepository(Ref ref) =>
    ReminderWorkloadRepositoryImpl(ref.watch(databaseProvider));
```

- [ ] **Step 5: Generate the provider**

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected: it prints `Built with build_runner/aot in …; wrote … outputs.`, and
`lib/features/reminders/di/reminder_workload_repository_provider.g.dart` now exists.
Like every `*.g.dart` file, it is not committed.

- [ ] **Step 6: Regenerate the docs index**

Run:

```bash
python3 tools/docs/generate.py
python3 tools/docs/check.py
```

Expected: `check.py` ends with `PASS — 0 error(s), 46 warning(s)`.

- [ ] **Step 7: Run the task's tests**

```bash
flutter test test/features/reminders/data/reminder_workload_repository_test.dart
```

Expected: `+5: All tests passed!`

- [ ] **Step 8: Stage the task's files**

The gate asks every source under `lib/` to be in git, so the task is staged before it runs.

```bash
git add lib/features/reminders/data/datasources/reminder_workload_dao.dart \
  lib/features/reminders/data/mappers/reminder_workload_mapper.dart \
  lib/features/reminders/data/repositories/reminder_workload_repository_impl.dart \
  lib/features/reminders/di/reminder_workload_repository_provider.dart \
  lib/features/reminders/domain/repositories/reminder_workload_repository.dart \
  test/features/reminders/data/reminder_workload_repository_test.dart \
  docs/_generated
git status --short
```

Expected: every path `git status --short` lists is staged: a letter in its first column, a space in its second.

- [ ] **Step 9: Run the gate**

Run:

```bash
bash .claude/skills/flutter-workflow/scripts/dod_check.sh
```

Expected: it ends with `✓ mechanical gates passed`. Among its steps:
`No issues found!`; `✓ generated code is fresh, complete and uncommitted`;
`✓ architecture boundaries clean`; `PASS — 0 error(s), 46 warning(s)` (the
warnings are older than this plan); the CI tooling tests `Ran 77 tests` and
`OK (skipped=8)` (eight of them need PowerShell 7); `204 passed` (the guard's
self-tests); `Code verification passed.`; `+1955: All tests passed!`.

- [ ] **Step 10: Commit**

```bash
git commit -F - <<'EOF'
feat(reminders): read the workload of each root deck at fire time

ReminderWorkloadRepositoryImpl reads deckLevelOfRoots once, the statement the
Library's root level and Study Home read, so the reminder counts what they
show: learned cards only, each once under its root, the Trash left out
(BR-REMINDER-003, BR-REMINDER-007; spec D8). The overdue age counts local day
boundaries on calendar dates (BR-STUDY-067). A read that fails leaves as its
Failure (UC-REMINDER-001 E5).
EOF
```

Append the session's attribution trailers to the message when you commit.


### Task 5: The platform port, a platform without reminders, watch and reconcile

**Files:**
- Create: `lib/features/reminders/data/repositories/unsupported_reminder_platform_repository_impl.dart`, `lib/features/reminders/di/reminder_platform_repository_provider.dart`, `lib/features/reminders/domain/failures/reminder_failure.dart`, `lib/features/reminders/domain/models/reminder_platform_model.dart`, `lib/features/reminders/domain/models/reminder_status_model.dart`, `lib/features/reminders/domain/repositories/reminder_platform_repository.dart`, `lib/features/reminders/domain/usecases/reconcile_reminder_use_case.dart`, `lib/features/reminders/domain/usecases/watch_reminder_use_case.dart`
- Test (create): `test/features/reminders/data/unsupported_reminder_platform_repository_test.dart`, `test/features/reminders/domain/reconcile_reminder_use_case_test.dart`, `test/features/reminders/domain/watch_reminder_use_case_test.dart`, `test/support/fake_reminder_platform.dart`
- Regenerate: the `*.g.dart` files (build_runner, not committed), `docs/_generated/` (`python3 tools/docs/generate.py`)

**Interfaces:**
- Consumes: Task 1's settings methods; Task 2's `ReminderDigest`; Task 3's
  `nextReminderAt`; `DayClock` and `FakeDayClock`; `LanguageChoice`.
- Produces:
  - `enum ReminderCapability { supported, unsupported }` and
    `enum ReminderPermission { granted, denied }`
    (`reminders/domain/models/reminder_platform_model.dart`).
  - `enum ReminderRejection { unsupported, permissionDenied, minuteOutOfRange, couldNotSchedule, couldNotCancel, couldNotShow }`
    (`reminders/domain/failures/reminder_failure.dart`).
  - `abstract interface class ReminderPlatformRepository` with
    `Future<ReminderCapability> capability()`,
    `Future<ReminderPermission> requestPermission()`,
    `Future<Outcome<void, ReminderRejection>> schedule({required DateTime at})`,
    `Future<Outcome<void, ReminderRejection>> cancel()` and
    `Future<Outcome<void, ReminderRejection>> show({required ReminderDigest digest, required LanguageChoice language})`.
  - `ReminderStatus({required ReminderCapability capability, required ReminderSettings reminder})`.
  - `const UnsupportedReminderPlatformRepositoryImpl()`;
    `reminderPlatformRepositoryProvider` (keep-alive).
  - `WatchReminderUseCase(SettingsRepository, ReminderPlatformRepository)` with
    `Stream<ReminderStatus> call()`;
    `ReconcileReminderUseCase(SettingsRepository, ReminderPlatformRepository, DayClock)`
    with `Future<Outcome<DateTime?, ReminderRejection>> call()`.
  - `FakeReminderPlatform` and `enum PlatformCall` (`test/support/fake_reminder_platform.dart`).

Spec §6, §9, D6, D7, D15; Clarification 4; Review Focus 4. The fake platform has
one pending slot and one shown slot, and records every call, so a test measures what was
asked of the platform.

- [ ] **Step 1: Write the failing tests**

Create `test/support/fake_reminder_platform.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/reminders/domain/failures/reminder_failure.dart';
import 'package:memox/features/reminders/domain/models/reminder_digest_model.dart';
import 'package:memox/features/reminders/domain/models/reminder_platform_model.dart';
import 'package:memox/features/reminders/domain/repositories/reminder_platform_repository.dart';
import 'package:memox/features/settings/domain/models/language_choice_model.dart';

/// A call the reminder's use cases make of the platform.
enum PlatformCall { capability, requestPermission, schedule, cancel, show }

/// The operating system as the reminder's use cases see it, with the two
/// slots a real one has: at most one pending reminder, which a schedule
/// replaces (BR-REMINDER-010), and at most one notification on the shade,
/// which a show replaces (BR-REMINDER-004). Every call is recorded, so a test
/// measures what was asked of the platform instead of assuming it.
final class FakeReminderPlatform implements ReminderPlatformRepository {
  FakeReminderPlatform({
    this.capabilityValue = ReminderCapability.supported,
    this.permission = ReminderPermission.granted,
  });

  ReminderCapability capabilityValue;
  ReminderPermission permission;

  /// The calls the platform refuses, the way a failing plugin does.
  final Set<PlatformCall> refusing = {};

  /// Every call, in order.
  final List<PlatformCall> calls = [];

  /// The one pending reminder, if any.
  DateTime? pending;

  /// The one notification on the shade, if any.
  ReminderDigest? shown;

  /// The language [shown] was written in.
  LanguageChoice? shownIn;

  @override
  Future<ReminderCapability> capability() async {
    calls.add(PlatformCall.capability);
    return capabilityValue;
  }

  @override
  Future<ReminderPermission> requestPermission() async {
    calls.add(PlatformCall.requestPermission);
    return permission;
  }

  @override
  Future<Outcome<void, ReminderRejection>> schedule({
    required DateTime at,
  }) async {
    calls.add(PlatformCall.schedule);
    if (refusing.contains(PlatformCall.schedule)) {
      return const Rejected(ReminderRejection.couldNotSchedule);
    }
    pending = at;
    return const Ok(null);
  }

  @override
  Future<Outcome<void, ReminderRejection>> cancel() async {
    calls.add(PlatformCall.cancel);
    if (refusing.contains(PlatformCall.cancel)) {
      return const Rejected(ReminderRejection.couldNotCancel);
    }
    pending = null;
    shown = null;
    shownIn = null;
    return const Ok(null);
  }

  @override
  Future<Outcome<void, ReminderRejection>> show({
    required ReminderDigest digest,
    required LanguageChoice language,
  }) async {
    calls.add(PlatformCall.show);
    if (refusing.contains(PlatformCall.show)) {
      return const Rejected(ReminderRejection.couldNotShow);
    }
    shown = digest;
    shownIn = language;
    return const Ok(null);
  }
}
```

Create `test/features/reminders/data/unsupported_reminder_platform_repository_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/reminders/data/repositories/unsupported_reminder_platform_repository_impl.dart';
import 'package:memox/features/reminders/domain/failures/reminder_failure.dart';
import 'package:memox/features/reminders/domain/models/reminder_digest_model.dart';
import 'package:memox/features/reminders/domain/models/reminder_platform_model.dart';
import 'package:memox/features/settings/domain/models/language_choice_model.dart';

// The platform side where there are no reminders: Web, and every platform
// until BE-B5b (reminders spec D7).

Matcher _refusedAsUnsupported() =>
    isA<Rejected<void, ReminderRejection>>().having(
      (rejected) => rejected.reason,
      'reason',
      ReminderRejection.unsupported,
    );

void main() {
  const platform = UnsupportedReminderPlatformRepositoryImpl();

  test('an unsupported platform says so, and never pretends to be on '
      '(BR-REMINDER-012, UC-REMINDER-001 E2)', () async {
    expect(await platform.capability(), ReminderCapability.unsupported);
    expect(await platform.requestPermission(), ReminderPermission.denied);
  });

  test('every other call is refused with its reason, never thrown '
      '(BR-REMINDER-012)', () async {
    const digest = ReminderDigest(
      deckName: 'Korean',
      dueCount: 3,
      otherDeckCount: 0,
    );

    expect(
      await platform.schedule(at: DateTime(2026, 9, 26, 20)),
      _refusedAsUnsupported(),
    );
    expect(await platform.cancel(), _refusedAsUnsupported());
    expect(
      await platform.show(digest: digest, language: LanguageChoice.en),
      _refusedAsUnsupported(),
    );
  });
}
```

Create `test/features/reminders/domain/reconcile_reminder_use_case_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/reminders/domain/failures/reminder_failure.dart';
import 'package:memox/features/reminders/domain/models/reminder_platform_model.dart';
import 'package:memox/features/reminders/domain/usecases/reconcile_reminder_use_case.dart';
import 'package:memox/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:memox/features/settings/domain/models/reminder_settings_model.dart';

import '../../../support/fake_day_clock.dart';
import '../../../support/fake_reminder_platform.dart';
import '../../../support/test_database.dart';

// UC-REMINDER-001 A5: the pending reminder brought in line with the stored
// one, at app start and after a reset (BR-REMINDER-009, BR-REMINDER-010;
// reminders spec D15).

const _on2000 = ReminderSettings(isEnabled: true, minuteOfDay: 1200);

void main() {
  late AppDatabase db;
  late SettingsRepositoryImpl settings;
  late FakeReminderPlatform platform;
  late FakeDayClock clock;
  setUp(() {
    db = openTestDatabase();
    settings = SettingsRepositoryImpl(db, now: () => DateTime(2026, 9, 26, 9));
    platform = FakeReminderPlatform();
    clock = FakeDayClock(DateTime(2026, 9, 26, 19));
  });
  tearDown(() => db.close());

  ReconcileReminderUseCase reconcile() =>
      ReconcileReminderUseCase(settings, platform, clock);

  test('a reminder that is on is pending once at its next time, however many '
      'times reconcile runs, and the permission is never asked '
      '(BR-REMINDER-010, BR-REMINDER-011, UC-REMINDER-001 A5)', () async {
    await settings.saveReminder(reminder: _on2000);

    final first = await reconcile()();
    final second = await reconcile()();

    for (final result in [first, second]) {
      expect(
        result,
        isA<Ok<DateTime?, ReminderRejection>>().having(
          (ok) => ok.value,
          'nextAt',
          DateTime(2026, 9, 26, 20),
        ),
      );
    }
    expect(platform.pending, DateTime(2026, 9, 26, 20));
    expect(platform.calls, isNot(contains(PlatformCall.requestPermission)));
  });

  test('a day that already had its digest is scheduled for tomorrow '
      '(BR-REMINDER-004)', () async {
    await settings.saveReminder(
      reminder: const ReminderSettings(isEnabled: true, minuteOfDay: 1320),
    );
    await settings.recordReminderDelivered(at: DateTime(2026, 9, 26, 20, 1));
    clock.current = DateTime(2026, 9, 26, 21);

    await reconcile()();

    expect(platform.pending, DateTime(2026, 9, 27, 22));
  });

  test('a reminder that is off cancels what is pending: a leftover of a '
      'reset or of UC-REMINDER-001 E6 (BR-REMINDER-009, spec D15)', () async {
    await settings.saveReminder(reminder: _on2000);
    await reconcile()();
    expect(platform.pending, isNotNull);

    await settings.resetToDefaults();
    final result = await reconcile()();

    expect(result, isA<Ok<DateTime?, ReminderRejection>>());
    expect((result as Ok<DateTime?, ReminderRejection>).value, isNull);
    expect(platform.pending, isNull);
  });

  test('an unsupported platform is asked nothing but its capability '
      '(BR-REMINDER-012)', () async {
    platform.capabilityValue = ReminderCapability.unsupported;
    await settings.saveReminder(reminder: _on2000);

    final result = await reconcile()();

    expect((result as Ok<DateTime?, ReminderRejection>).value, isNull);
    expect(platform.calls, [PlatformCall.capability]);
  });

  test('a refusal of the platform comes back as its reason '
      '(UC-REMINDER-001 E3, E6)', () async {
    platform.refusing.addAll({PlatformCall.schedule, PlatformCall.cancel});
    await settings.saveReminder(reminder: _on2000);

    final scheduling = await reconcile()();
    await settings.resetToDefaults();
    final cancelling = await reconcile()();

    expect(
      scheduling,
      isA<Rejected<DateTime?, ReminderRejection>>().having(
        (rejected) => rejected.reason,
        'reason',
        ReminderRejection.couldNotSchedule,
      ),
    );
    expect(
      cancelling,
      isA<Rejected<DateTime?, ReminderRejection>>().having(
        (rejected) => rejected.reason,
        'reason',
        ReminderRejection.couldNotCancel,
      ),
    );
  });

  test('a settings read that fails leaves as its Failure', () async {
    await db.customStatement('DELETE FROM app_settings');

    await expectLater(reconcile()(), throwsA(isA<UnknownDatabaseFailure>()));
  });
}
```

Create `test/features/reminders/domain/watch_reminder_use_case_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/reminders/domain/models/reminder_platform_model.dart';
import 'package:memox/features/reminders/domain/usecases/watch_reminder_use_case.dart';
import 'package:memox/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:memox/features/settings/domain/models/reminder_settings_model.dart';

import '../../../support/fake_reminder_platform.dart';
import '../../../support/test_database.dart';

// UC-REMINDER-001 step 1: what the reminder screen shows, from the stored
// reminder and the platform's capability (reminders spec §9).

void main() {
  late AppDatabase db;
  late SettingsRepositoryImpl settings;
  setUp(() {
    db = openTestDatabase();
    settings = SettingsRepositoryImpl(db, now: () => DateTime(2026, 9, 26, 9));
  });
  tearDown(() => db.close());

  test('the screen shows the stored reminder, again after every save, and '
      'watching asks nothing of the platform but its capability '
      '(UC-REMINDER-001 step 1, BR-REMINDER-011)', () async {
    final platform = FakeReminderPlatform();
    final seen = <(ReminderCapability, bool, int)>[];
    final subscription = WatchReminderUseCase(settings, platform)().listen(
      (status) => seen.add((
        status.capability,
        status.reminder.isEnabled,
        status.reminder.minuteOfDay,
      )),
    );
    await pumpEventQueue();

    await settings.saveReminder(
      reminder: const ReminderSettings(isEnabled: true, minuteOfDay: 480),
    );
    await pumpEventQueue();
    await subscription.cancel();

    expect(seen, [
      (ReminderCapability.supported, false, 1200),
      (ReminderCapability.supported, true, 480),
    ]);
    expect(platform.calls, [PlatformCall.capability]);
  });

  test('an unsupported platform is shown as such, even over a reminder '
      'stored as on (BR-REMINDER-012, UC-REMINDER-001 E2)', () async {
    await settings.saveReminder(
      reminder: const ReminderSettings(isEnabled: true, minuteOfDay: 1200),
    );
    final platform = FakeReminderPlatform(
      capabilityValue: ReminderCapability.unsupported,
    );

    final status = await WatchReminderUseCase(settings, platform)().first;

    expect(status.capability, ReminderCapability.unsupported);
    expect(status.reminder.isEnabled, isTrue);
  });

  test('a settings read that fails reaches the stream as its Failure, never '
      'as made-up values (UC-REMINDER-001 E7)', () async {
    await db.customStatement('DELETE FROM app_settings');

    await expectLater(
      WatchReminderUseCase(settings, FakeReminderPlatform())().first,
      throwsA(isA<UnknownDatabaseFailure>()),
    );
  });
}
```

- [ ] **Step 2: Run them to see them fail**

```bash
flutter test test/features/reminders/data/unsupported_reminder_platform_repository_test.dart \
  test/features/reminders/domain/reconcile_reminder_use_case_test.dart \
  test/features/reminders/domain/watch_reminder_use_case_test.dart
```

Expected: `+0 -3: Some tests failed.` None of the three test files compiles:
`Error: Error when reading 'lib/features/reminders/domain/models/reminder_platform_model.dart': No such file or directory`,
the same for `reminder_failure.dart`, `reminder_platform_repository.dart`,
`unsupported_reminder_platform_repository_impl.dart`, `watch_reminder_use_case.dart` and
`reconcile_reminder_use_case.dart`, then, in `test/support/fake_reminder_platform.dart`,
`Error: Type 'ReminderCapability' not found.`, `Error: Type 'ReminderRejection' not found.`
and `Error: Not a constant expression.`, and in the tests
`Error: Method not found: 'WatchReminderUseCase'.` The tool may then print `Error: The Dart compiler exited unexpectedly.`
and a stack trace; the run still ends as above.

- [ ] **Step 3: Name the platform's answers, the reasons, the port and the status**

Create `lib/features/reminders/domain/models/reminder_platform_model.dart`:

```dart
/// Whether the platform can deliver the reminder at all (BR-REMINDER-012).
enum ReminderCapability { supported, unsupported }

/// The answer to the notification permission request (BR-REMINDER-011).
enum ReminderPermission { granted, denied }
```

Create `lib/features/reminders/domain/failures/reminder_failure.dart`:

```dart
/// Why a reminder action did not do what was asked (ADR-011 D6). The
/// reminder screen shows each as a state of its own (UC-REMINDER-001).
enum ReminderRejection {
  /// This platform has no reminders (BR-REMINDER-012, E2).
  unsupported,

  /// The person refused the notification permission; nothing was saved or
  /// scheduled (BR-REMINDER-011, E1).
  permissionDenied,

  /// The minute is outside 0 to 1439 (BR-REMINDER-002).
  minuteOutOfRange,

  /// The platform refused to schedule; the stored reminder is as it was
  /// (E3).
  couldNotSchedule,

  /// The platform refused to cancel. When the reminder was being turned off,
  /// the settings are off already: only the pending reminder may remain
  /// (E6).
  couldNotCancel,

  /// The platform refused to show the digest. Only a delivery meets it.
  couldNotShow,
}
```

Create `lib/features/reminders/domain/repositories/reminder_platform_repository.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/reminders/domain/failures/reminder_failure.dart';
import 'package:memox/features/reminders/domain/models/reminder_digest_model.dart';
import 'package:memox/features/reminders/domain/models/reminder_platform_model.dart';
import 'package:memox/features/settings/domain/models/language_choice_model.dart';

/// The operating system's side of the reminder, and the one place that may
/// reach a notification plugin: its types are the app's own, and no call
/// throws, as a platform error comes back as a typed reason
/// (BR-REMINDER-012, UC-REMINDER-001 E3).
///
/// `reminderPlatformRepositoryProvider` picks the implementation:
/// `UnsupportedReminderPlatformRepositoryImpl` on every platform until
/// BE-B5b adds Android's (reminders spec D6, D7).
abstract interface class ReminderPlatformRepository {
  /// Whether this platform can deliver the reminder at all
  /// (BR-REMINDER-012).
  Future<ReminderCapability> capability();

  /// Asks for the notification permission, and only when called: after the
  /// person turned the reminder on (BR-REMINDER-011). `granted` at once
  /// where no permission exists; a failure to ask is `denied`.
  Future<ReminderPermission> requestPermission();

  /// One inexact reminder at [at], replacing the pending one, so that at most
  /// one is ever pending (BR-REMINDER-009, BR-REMINDER-010). A refusal is
  /// `couldNotSchedule`.
  Future<Outcome<void, ReminderRejection>> schedule({required DateTime at});

  /// Removes the pending reminder and the notification shown. Nothing to
  /// remove is `Ok`; a refusal is `couldNotCancel`.
  Future<Outcome<void, ReminderRejection>> cancel();

  /// Shows [digest] as the day's one notification, under one fixed id that
  /// replaces the day before's (BR-REMINDER-004), written in [language] from
  /// the digest alone (BR-REMINDER-005). A tap opens Study Home
  /// (BR-REMINDER-008). A refusal is `couldNotShow`.
  Future<Outcome<void, ReminderRejection>> show({
    required ReminderDigest digest,
    required LanguageChoice language,
  });
}
```

Create `lib/features/reminders/domain/models/reminder_status_model.dart`:

```dart
import 'package:memox/features/reminders/domain/models/reminder_platform_model.dart';
import 'package:memox/features/settings/domain/models/reminder_settings_model.dart';

/// What the reminder screen shows (UC-REMINDER-001 step 1): whether the
/// platform has reminders, and the reminder as stored. An unsupported
/// platform shows no toggle, even over a reminder stored as on
/// (BR-REMINDER-012).
final class ReminderStatus {
  const ReminderStatus({required this.capability, required this.reminder});

  final ReminderCapability capability;
  final ReminderSettings reminder;
}
```

- [ ] **Step 4: A platform without reminders, and its provider**

The provider's `part` file does not exist until the step after next generates it.

Create `lib/features/reminders/data/repositories/unsupported_reminder_platform_repository_impl.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/reminders/domain/failures/reminder_failure.dart';
import 'package:memox/features/reminders/domain/models/reminder_digest_model.dart';
import 'package:memox/features/reminders/domain/models/reminder_platform_model.dart';
import 'package:memox/features/reminders/domain/repositories/reminder_platform_repository.dart';
import 'package:memox/features/settings/domain/models/language_choice_model.dart';

/// The platform side where there are no reminders: Web, and every platform
/// until BE-B5b adds Android's (reminders spec D7). It says so, and does
/// nothing else (BR-REMINDER-012).
final class UnsupportedReminderPlatformRepositoryImpl
    implements ReminderPlatformRepository {
  const UnsupportedReminderPlatformRepositoryImpl();

  @override
  Future<ReminderCapability> capability() async =>
      ReminderCapability.unsupported;

  @override
  Future<ReminderPermission> requestPermission() async =>
      ReminderPermission.denied;

  @override
  Future<Outcome<void, ReminderRejection>> schedule({
    required DateTime at,
  }) async => const Rejected(ReminderRejection.unsupported);

  @override
  Future<Outcome<void, ReminderRejection>> cancel() async =>
      const Rejected(ReminderRejection.unsupported);

  @override
  Future<Outcome<void, ReminderRejection>> show({
    required ReminderDigest digest,
    required LanguageChoice language,
  }) async => const Rejected(ReminderRejection.unsupported);
}
```

Create `lib/features/reminders/di/reminder_platform_repository_provider.dart`:

```dart
import 'package:memox/features/reminders/data/repositories/unsupported_reminder_platform_repository_impl.dart';
import 'package:memox/features/reminders/domain/repositories/reminder_platform_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reminder_platform_repository_provider.g.dart';

/// The platform side of the reminder: none on any platform until BE-B5b
/// adds Android's here, and Web keeps none (reminders spec D7).
@Riverpod(keepAlive: true)
ReminderPlatformRepository reminderPlatformRepository(Ref ref) =>
    const UnsupportedReminderPlatformRepositoryImpl();
```

- [ ] **Step 5: Watch the reminder, and reconcile the pending one**

Create `lib/features/reminders/domain/usecases/watch_reminder_use_case.dart`:

```dart
import 'package:memox/features/reminders/domain/models/reminder_status_model.dart';
import 'package:memox/features/reminders/domain/repositories/reminder_platform_repository.dart';
import 'package:memox/features/settings/domain/repositories/settings_repository.dart';

/// UC-REMINDER-001 step 1: the reminder screen, again after every save. The
/// platform's capability is read once; a settings read that fails reaches the
/// stream as its `Failure` (E7).
final class WatchReminderUseCase {
  const WatchReminderUseCase(this._settings, this._platform);

  final SettingsRepository _settings;
  final ReminderPlatformRepository _platform;

  Stream<ReminderStatus> call() async* {
    final capability = await _platform.capability();
    yield* _settings.watchAppSettings().map(
      (settings) =>
          ReminderStatus(capability: capability, reminder: settings.reminder),
    );
  }
}
```

Create `lib/features/reminders/domain/usecases/reconcile_reminder_use_case.dart`:

```dart
import 'package:memox/core/clock/day_clock.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/reminders/domain/failures/reminder_failure.dart';
import 'package:memox/features/reminders/domain/models/reminder_platform_model.dart';
import 'package:memox/features/reminders/domain/models/reminder_time_model.dart';
import 'package:memox/features/reminders/domain/repositories/reminder_platform_repository.dart';
import 'package:memox/features/settings/domain/repositories/settings_repository.dart';

/// UC-REMINDER-001 A5: the pending reminder brought in line with the stored
/// one, at app start, after a reset and after a platform event such as a new
/// time zone (BR-REMINDER-009). Running it again changes nothing, as a
/// schedule replaces the pending reminder (BR-REMINDER-010), and it never
/// asks for the permission (BR-REMINDER-011).
///
/// `Ok(nextAt)` when it scheduled; `Ok(null)` when the reminder is off and
/// whatever was pending is cancelled, or when the platform has no reminders.
/// A settings read that fails leaves as its `Failure`.
final class ReconcileReminderUseCase {
  const ReconcileReminderUseCase(this._settings, this._platform, this._clock);

  final SettingsRepository _settings;
  final ReminderPlatformRepository _platform;
  final DayClock _clock;

  Future<Outcome<DateTime?, ReminderRejection>> call() async {
    if (await _platform.capability() == ReminderCapability.unsupported) {
      return const Ok(null);
    }
    final snapshot = await _settings.reminderSnapshot();
    if (!snapshot.reminder.isEnabled) {
      return switch (await _platform.cancel()) {
        Ok() => const Ok(null),
        Rejected(:final reason) => Rejected(reason),
      };
    }
    final nextAt = nextReminderAt(
      now: _clock.now(),
      minuteOfDay: snapshot.reminder.minuteOfDay,
      lastDeliveredAt: snapshot.lastDeliveredAt,
    );
    return switch (await _platform.schedule(at: nextAt)) {
      Ok() => Ok(nextAt),
      Rejected(:final reason) => Rejected(reason),
    };
  }
}
```

- [ ] **Step 6: Generate the provider**

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected: it prints `Built with build_runner/aot in …; wrote … outputs.`, and
`lib/features/reminders/di/reminder_platform_repository_provider.g.dart` now exists.
Like every `*.g.dart` file, it is not committed.

- [ ] **Step 7: Regenerate the docs index**

Run:

```bash
python3 tools/docs/generate.py
python3 tools/docs/check.py
```

Expected: `check.py` ends with `PASS — 0 error(s), 46 warning(s)`.

- [ ] **Step 8: Run the task's tests**

```bash
flutter test test/features/reminders/data/unsupported_reminder_platform_repository_test.dart \
  test/features/reminders/domain/reconcile_reminder_use_case_test.dart \
  test/features/reminders/domain/watch_reminder_use_case_test.dart
```

Expected: `+11: All tests passed!`

- [ ] **Step 9: Stage the task's files**

The gate asks every source under `lib/` to be in git, so the task is staged before it runs.

```bash
git add lib/features/reminders/data/repositories/unsupported_reminder_platform_repository_impl.dart \
  lib/features/reminders/di/reminder_platform_repository_provider.dart \
  lib/features/reminders/domain/failures/reminder_failure.dart \
  lib/features/reminders/domain/models/reminder_platform_model.dart \
  lib/features/reminders/domain/models/reminder_status_model.dart \
  lib/features/reminders/domain/repositories/reminder_platform_repository.dart \
  lib/features/reminders/domain/usecases/reconcile_reminder_use_case.dart \
  lib/features/reminders/domain/usecases/watch_reminder_use_case.dart \
  test/features/reminders/data/unsupported_reminder_platform_repository_test.dart \
  test/features/reminders/domain/reconcile_reminder_use_case_test.dart \
  test/features/reminders/domain/watch_reminder_use_case_test.dart \
  test/support/fake_reminder_platform.dart \
  docs/_generated
git status --short
```

Expected: every path `git status --short` lists is staged: a letter in its first column, a space in its second.

- [ ] **Step 10: Run the gate**

Run:

```bash
bash .claude/skills/flutter-workflow/scripts/dod_check.sh
```

Expected: it ends with `✓ mechanical gates passed`. Among its steps:
`No issues found!`; `✓ generated code is fresh, complete and uncommitted`;
`✓ architecture boundaries clean`; `PASS — 0 error(s), 46 warning(s)` (the
warnings are older than this plan); the CI tooling tests `Ran 77 tests` and
`OK (skipped=8)` (eight of them need PowerShell 7); `204 passed` (the guard's
self-tests); `Code verification passed.`; `+1966: All tests passed!`.

- [ ] **Step 11: Commit**

```bash
git commit -F - <<'EOF'
feat(reminders): the platform port, no reminders yet, watch and reconcile

ReminderPlatformRepository is the one way to the operating system: typed
answers, no plugin type, and no call that throws (BR-REMINDER-012; spec D6).
UnsupportedReminderPlatformRepositoryImpl is its only adapter until BE-B5b
(D7). WatchReminderUseCase shows the capability and the stored reminder
(UC-REMINDER-001 step 1, E2, E7). ReconcileReminderUseCase schedules the next
fire while the reminder is on and cancels while it is off, the same however
often it runs, and never asks for the permission (A5; BR-REMINDER-010,
BR-REMINDER-011; D15).
EOF
```

Append the session's attribution trailers to the message when you commit.


### Task 6: Turn the reminder on, off, and change its time

**Files:**
- Create: `lib/features/reminders/domain/usecases/change_reminder_time_use_case.dart`, `lib/features/reminders/domain/usecases/disable_reminder_use_case.dart`, `lib/features/reminders/domain/usecases/enable_reminder_use_case.dart`
- Test (create): `test/features/reminders/domain/change_reminder_time_use_case_test.dart`, `test/features/reminders/domain/disable_reminder_use_case_test.dart`, `test/features/reminders/domain/enable_reminder_use_case_test.dart`
- Regenerate: `docs/_generated/` (`python3 tools/docs/generate.py`)

**Interfaces:**
- Consumes: Task 1's settings methods; Task 3's `nextReminderAt`; Task 5's port,
  `ReminderRejection`, `FakeReminderPlatform` and `PlatformCall`.
- Produces:
  - `EnableReminderUseCase(SettingsRepository, ReminderPlatformRepository, DayClock)`
    with `Future<Outcome<DateTime, ReminderRejection>> call({required int minuteOfDay})`.
  - `DisableReminderUseCase(SettingsRepository, ReminderPlatformRepository)` with
    `Future<Outcome<void, ReminderRejection>> call()`.
  - `ChangeReminderTimeUseCase(SettingsRepository, ReminderPlatformRepository, DayClock)`
    with `Future<Outcome<DateTime?, ReminderRejection>> call({required int minuteOfDay})`.

Spec §9, D13, D14, D17; Clarifications 2 and 3; Review Focus 1.

- [ ] **Step 1: Write the failing tests**

Create `test/features/reminders/domain/change_reminder_time_use_case_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/reminders/domain/failures/reminder_failure.dart';
import 'package:memox/features/reminders/domain/usecases/change_reminder_time_use_case.dart';
import 'package:memox/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:memox/features/settings/domain/models/reminder_settings_model.dart';

import '../../../support/fake_day_clock.dart';
import '../../../support/fake_reminder_platform.dart';
import '../../../support/test_database.dart';

// UC-REMINDER-001 A1: a new time, scheduled before it is saved while the
// reminder is on (reminders spec D13, D17).

DateTime _t0() => DateTime(2026, 9, 26, 9);

const _on2000 = ReminderSettings(isEnabled: true, minuteOfDay: 1200);

void main() {
  late AppDatabase db;
  late SettingsRepositoryImpl settings;
  late FakeReminderPlatform platform;
  late FakeDayClock clock;
  setUp(() {
    db = openTestDatabase();
    settings = SettingsRepositoryImpl(db, now: _t0);
    platform = FakeReminderPlatform();
    clock = FakeDayClock(DateTime(2026, 9, 26, 19));
  });
  tearDown(() => db.close());

  ChangeReminderTimeUseCase change() =>
      ChangeReminderTimeUseCase(settings, platform, clock);

  Future<ReminderSettings> stored() async =>
      (await settings.reminderSnapshot()).reminder;

  test('while on, the new time is scheduled and saved, and no permission is '
      'asked (UC-REMINDER-001 A1, BR-REMINDER-009)', () async {
    await settings.saveReminder(reminder: _on2000);
    platform.pending = DateTime(2026, 9, 26, 20);

    final result = await change()(minuteOfDay: 1260);

    expect(
      result,
      isA<Ok<DateTime?, ReminderRejection>>().having(
        (ok) => ok.value,
        'nextAt',
        DateTime(2026, 9, 26, 21),
      ),
    );
    expect(platform.pending, DateTime(2026, 9, 26, 21));
    expect((await stored()).minuteOfDay, 1260);
    expect((await stored()).isEnabled, isTrue);
    expect(platform.calls, isNot(contains(PlatformCall.requestPermission)));
  });

  test('a schedule the platform refuses keeps the old time and its schedule, '
      'and writes nothing (UC-REMINDER-001 E3)', () async {
    await settings.saveReminder(reminder: _on2000);
    platform
      ..pending = DateTime(2026, 9, 26, 20)
      ..refusing.add(PlatformCall.schedule);
    final before = await totalChanges(db);

    final result = await change()(minuteOfDay: 1260);

    expect(
      result,
      isA<Rejected<DateTime?, ReminderRejection>>().having(
        (rejected) => rejected.reason,
        'reason',
        ReminderRejection.couldNotSchedule,
      ),
    );
    expect(await totalChanges(db), before);
    expect((await stored()).minuteOfDay, 1200);
    expect(platform.pending, DateTime(2026, 9, 26, 20));
  });

  test('a save that fails puts the old time back on the platform and leaves '
      'as its Failure (UC-REMINDER-001 E4, spec D13)', () async {
    final failing = openTestDatabase(interceptor: FailingUpdates());
    addTearDown(failing.close);
    await failing.customStatement(
      'UPDATE app_settings SET reminder_enabled = 1 WHERE id = 1',
    );
    final broken = SettingsRepositoryImpl(failing, now: _t0);
    platform.pending = DateTime(2026, 9, 26, 20);

    await expectLater(
      ChangeReminderTimeUseCase(broken, platform, clock)(minuteOfDay: 1260),
      throwsA(isA<ConstraintFailure>()),
    );
    expect(platform.pending, DateTime(2026, 9, 26, 20));
    expect((await broken.reminderSnapshot()).reminder.minuteOfDay, 1200);
  });

  test('while off, only the time is saved, nothing is scheduled and '
      'Ok(null) comes back (spec D17)', () async {
    final result = await change()(minuteOfDay: 480);

    expect(result, isA<Ok<DateTime?, ReminderRejection>>());
    expect((result as Ok<DateTime?, ReminderRejection>).value, isNull);
    expect((await stored()).isEnabled, isFalse);
    expect((await stored()).minuteOfDay, 480);
    expect(platform.calls, isEmpty);
  });

  test('a minute out of range is refused before anything is read or written '
      '(BR-REMINDER-002)', () async {
    await settings.saveReminder(reminder: _on2000);
    final before = await totalChanges(db);

    final result = await change()(minuteOfDay: -1);

    expect(
      result,
      isA<Rejected<DateTime?, ReminderRejection>>().having(
        (rejected) => rejected.reason,
        'reason',
        ReminderRejection.minuteOutOfRange,
      ),
    );
    expect(platform.calls, isEmpty);
    expect(await totalChanges(db), before);
  });

  test('a day that already had its digest takes the new time tomorrow '
      '(BR-REMINDER-004)', () async {
    await settings.saveReminder(reminder: _on2000);
    await settings.recordReminderDelivered(at: DateTime(2026, 9, 26, 20, 1));
    clock.current = DateTime(2026, 9, 26, 21);

    await change()(minuteOfDay: 1320);

    expect(platform.pending, DateTime(2026, 9, 27, 22));
  });
}
```

Create `test/features/reminders/domain/disable_reminder_use_case_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/reminders/domain/failures/reminder_failure.dart';
import 'package:memox/features/reminders/domain/models/reminder_platform_model.dart';
import 'package:memox/features/reminders/domain/usecases/disable_reminder_use_case.dart';
import 'package:memox/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:memox/features/settings/domain/models/reminder_settings_model.dart';

import '../../../support/fake_reminder_platform.dart';
import '../../../support/test_database.dart';

// UC-REMINDER-001 A2, E4 and E6: turning the reminder off saves it off
// first, then cancels what is pending (reminders spec D13).

DateTime _t0() => DateTime(2026, 9, 26, 9);

final _pendingAt = DateTime(2026, 9, 26, 20);

void main() {
  late AppDatabase db;
  late SettingsRepositoryImpl settings;
  late FakeReminderPlatform platform;
  setUp(() async {
    db = openTestDatabase();
    settings = SettingsRepositoryImpl(db, now: _t0);
    platform = FakeReminderPlatform()..pending = _pendingAt;
    await settings.saveReminder(
      reminder: const ReminderSettings(isEnabled: true, minuteOfDay: 1200),
    );
  });
  tearDown(() => db.close());

  DisableReminderUseCase disable() =>
      DisableReminderUseCase(settings, platform);

  test('turning it off saves it off, keeps its time and cancels what is '
      'pending, asking for no permission (UC-REMINDER-001 A2)', () async {
    final result = await disable()();

    expect(result, isA<Ok<void, ReminderRejection>>());
    final stored = (await settings.reminderSnapshot()).reminder;
    expect(stored.isEnabled, isFalse);
    expect(stored.minuteOfDay, 1200);
    expect(platform.pending, isNull);
    expect(platform.calls, [PlatformCall.capability, PlatformCall.cancel]);
  });

  test('a cancel the platform refuses comes back as couldNotCancel with the '
      'reminder already off (UC-REMINDER-001 E6)', () async {
    platform.refusing.add(PlatformCall.cancel);

    final result = await disable()();

    expect(
      result,
      isA<Rejected<void, ReminderRejection>>().having(
        (rejected) => rejected.reason,
        'reason',
        ReminderRejection.couldNotCancel,
      ),
    );
    expect((await settings.reminderSnapshot()).reminder.isEnabled, isFalse);
    expect(platform.pending, _pendingAt);
  });

  test(
    'trying again writes nothing and cancels (UC-REMINDER-001 E6)',
    () async {
      platform.refusing.add(PlatformCall.cancel);
      await disable()();
      platform.refusing.clear();
      final before = await totalChanges(db);

      final retry = await disable()();

      expect(retry, isA<Ok<void, ReminderRejection>>());
      expect(await totalChanges(db), before);
      expect(platform.pending, isNull);
    },
  );

  test('a save that fails leaves as its Failure and cancels nothing: the '
      'reminder is still on and still pending (UC-REMINDER-001 E4)', () async {
    final failing = openTestDatabase(interceptor: FailingUpdates());
    addTearDown(failing.close);
    await failing.customStatement(
      'UPDATE app_settings SET reminder_enabled = 1 WHERE id = 1',
    );
    final broken = SettingsRepositoryImpl(failing, now: _t0);

    await expectLater(
      DisableReminderUseCase(broken, platform)(),
      throwsA(isA<ConstraintFailure>()),
    );
    expect(platform.calls, isNot(contains(PlatformCall.cancel)));
    expect(platform.pending, _pendingAt);
    expect((await broken.reminderSnapshot()).reminder.isEnabled, isTrue);
  });

  test('on a platform without reminders it is saved off and nothing else is '
      'asked (BR-REMINDER-012)', () async {
    platform.capabilityValue = ReminderCapability.unsupported;

    expect(await disable()(), isA<Ok<void, ReminderRejection>>());
    expect((await settings.reminderSnapshot()).reminder.isEnabled, isFalse);
    expect(platform.calls, [PlatformCall.capability]);
  });
}
```

Create `test/features/reminders/domain/enable_reminder_use_case_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/reminders/domain/failures/reminder_failure.dart';
import 'package:memox/features/reminders/domain/models/reminder_platform_model.dart';
import 'package:memox/features/reminders/domain/usecases/enable_reminder_use_case.dart';
import 'package:memox/features/settings/data/repositories/settings_repository_impl.dart';

import '../../../support/fake_day_clock.dart';
import '../../../support/fake_reminder_platform.dart';
import '../../../support/test_database.dart';

// UC-REMINDER-001 steps 2-3 and E1-E4: turning the reminder on asks for the
// permission only then, and schedules before it saves, so that "on" is
// never stored without a pending reminder (reminders spec D13, D14).

DateTime _t0() => DateTime(2026, 9, 26, 9);

Matcher _refused(ReminderRejection reason) =>
    isA<Rejected<DateTime, ReminderRejection>>().having(
      (rejected) => rejected.reason,
      'reason',
      reason,
    );

void main() {
  late AppDatabase db;
  late SettingsRepositoryImpl settings;
  late FakeReminderPlatform platform;
  late FakeDayClock clock;
  setUp(() {
    db = openTestDatabase();
    settings = SettingsRepositoryImpl(db, now: _t0);
    platform = FakeReminderPlatform();
    clock = FakeDayClock(DateTime(2026, 9, 26, 19));
  });
  tearDown(() => db.close());

  EnableReminderUseCase enable() =>
      EnableReminderUseCase(settings, platform, clock);

  Future<bool> storedOn() async =>
      (await settings.reminderSnapshot()).reminder.isEnabled;

  test('turning it on asks for the permission, schedules the next time and '
      'saves it on (UC-REMINDER-001 steps 2-3, BR-REMINDER-011)', () async {
    final result = await enable()(minuteOfDay: 1200);

    expect(
      result,
      isA<Ok<DateTime, ReminderRejection>>().having(
        (ok) => ok.value,
        'nextAt',
        DateTime(2026, 9, 26, 20),
      ),
    );
    expect(platform.calls, [
      PlatformCall.capability,
      PlatformCall.requestPermission,
      PlatformCall.schedule,
    ]);
    expect(platform.pending, DateTime(2026, 9, 26, 20));
    final stored = (await settings.reminderSnapshot()).reminder;
    expect(stored.isEnabled, isTrue);
    expect(stored.minuteOfDay, 1200);
  });

  test(
    'two taps on the switch at once both succeed and leave the reminder '
    'on and pending once, with nothing taken back (BR-REMINDER-010)',
    () async {
      final results = await Future.wait([
        enable()(minuteOfDay: 1200),
        enable()(minuteOfDay: 1200),
      ]);

      for (final result in results) {
        expect(result, isA<Ok<DateTime, ReminderRejection>>());
      }
      expect(platform.pending, DateTime(2026, 9, 26, 20));
      expect(platform.calls, isNot(contains(PlatformCall.cancel)));
      expect(await storedOn(), isTrue);
    },
  );

  test('a minute out of range is refused before anything is asked or written '
      '(BR-REMINDER-002)', () async {
    await settings.reminderSnapshot();
    final before = await totalChanges(db);

    expect(
      await enable()(minuteOfDay: 1440),
      _refused(ReminderRejection.minuteOutOfRange),
    );
    expect(platform.calls, isEmpty);
    expect(await totalChanges(db), before);
  });

  test('an unsupported platform is refused without asking for the '
      'permission (BR-REMINDER-012, UC-REMINDER-001 E2)', () async {
    platform.capabilityValue = ReminderCapability.unsupported;

    expect(
      await enable()(minuteOfDay: 1200),
      _refused(ReminderRejection.unsupported),
    );
    expect(platform.calls, [PlatformCall.capability]);
    expect(await storedOn(), isFalse);
  });

  test('a denied permission leaves the reminder off with nothing scheduled, '
      'asked once (BR-REMINDER-011, UC-REMINDER-001 E1)', () async {
    platform.permission = ReminderPermission.denied;

    expect(
      await enable()(minuteOfDay: 1200),
      _refused(ReminderRejection.permissionDenied),
    );
    expect(
      platform.calls.where((call) => call == PlatformCall.requestPermission),
      hasLength(1),
    );
    expect(platform.pending, isNull);
    expect(await storedOn(), isFalse);
  });

  test('a schedule the platform refuses leaves the reminder off and writes '
      'nothing (UC-REMINDER-001 E3, spec D13)', () async {
    platform.refusing.add(PlatformCall.schedule);
    await settings.reminderSnapshot();
    final before = await totalChanges(db);

    expect(
      await enable()(minuteOfDay: 1200),
      _refused(ReminderRejection.couldNotSchedule),
    );
    expect(await totalChanges(db), before);
    expect(await storedOn(), isFalse);
  });

  test('a save that fails takes the schedule back and leaves as its Failure, '
      'the reminder still off (UC-REMINDER-001 E4, spec D13)', () async {
    final failing = openTestDatabase(interceptor: FailingUpdates());
    addTearDown(failing.close);
    final broken = SettingsRepositoryImpl(failing, now: _t0);

    await expectLater(
      EnableReminderUseCase(broken, platform, clock)(minuteOfDay: 1200),
      throwsA(isA<ConstraintFailure>()),
    );
    expect(platform.calls.last, PlatformCall.cancel);
    expect(platform.pending, isNull);
    expect((await broken.reminderSnapshot()).reminder.isEnabled, isFalse);
  });

  test('a day that already had its digest is scheduled for tomorrow '
      '(BR-REMINDER-004)', () async {
    await settings.recordReminderDelivered(at: DateTime(2026, 9, 26, 18, 1));

    await enable()(minuteOfDay: 1200);

    expect(platform.pending, DateTime(2026, 9, 27, 20));
  });
}
```

- [ ] **Step 2: Run them to see them fail**

```bash
flutter test test/features/reminders/domain/change_reminder_time_use_case_test.dart \
  test/features/reminders/domain/disable_reminder_use_case_test.dart \
  test/features/reminders/domain/enable_reminder_use_case_test.dart
```

Expected: `+0 -3: Some tests failed.` None of the three test files compiles:
`Error: Error when reading 'lib/features/reminders/domain/usecases/enable_reminder_use_case.dart': No such file or directory`,
the same for `disable_reminder_use_case.dart` and `change_reminder_time_use_case.dart`,
then `Error: 'EnableReminderUseCase' isn't a type.`,
`Error: Method not found: 'DisableReminderUseCase'.`,
`Error: Method not found: 'ChangeReminderTimeUseCase'.` and, for the double tap,
`Error: The argument type 'List<dynamic>' can't be assigned to the parameter type 'Iterable<Future<dynamic>>'.` The tool may then print `Error: The Dart compiler exited unexpectedly.`
and a stack trace; the run still ends as above.

- [ ] **Step 3: Turn it on: ask, schedule, then save**

Create `lib/features/reminders/domain/usecases/enable_reminder_use_case.dart`:

```dart
import 'package:memox/core/clock/day_clock.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/reminders/domain/failures/reminder_failure.dart';
import 'package:memox/features/reminders/domain/models/reminder_platform_model.dart';
import 'package:memox/features/reminders/domain/models/reminder_time_model.dart';
import 'package:memox/features/reminders/domain/repositories/reminder_platform_repository.dart';
import 'package:memox/features/settings/domain/failures/settings_failure.dart';
import 'package:memox/features/settings/domain/models/reminder_settings_model.dart';
import 'package:memox/features/settings/domain/repositories/settings_repository.dart';

/// UC-REMINDER-001 steps 2-3: the person turns the reminder on at
/// [minuteOfDay]. Only now is the permission asked (BR-REMINDER-011), and
/// the reminder is scheduled before it is saved, so that "on" is never
/// stored without a pending reminder (reminders spec D13, D14).
///
/// `Ok(nextAt)`. `minuteOutOfRange`, `unsupported`, `permissionDenied` and
/// `couldNotSchedule` leave everything as it was (E1-E3). A save that fails
/// takes the schedule back, then leaves as its `Failure` (E4).
final class EnableReminderUseCase {
  const EnableReminderUseCase(this._settings, this._platform, this._clock);

  final SettingsRepository _settings;
  final ReminderPlatformRepository _platform;
  final DayClock _clock;

  Future<Outcome<DateTime, ReminderRejection>> call({
    required int minuteOfDay,
  }) async {
    final reminder = ReminderSettings(
      isEnabled: true,
      minuteOfDay: minuteOfDay,
    );
    if (reminder.check() case Rejected()) {
      return const Rejected(ReminderRejection.minuteOutOfRange);
    }
    if (await _platform.capability() == ReminderCapability.unsupported) {
      return const Rejected(ReminderRejection.unsupported);
    }
    if (await _platform.requestPermission() == ReminderPermission.denied) {
      return const Rejected(ReminderRejection.permissionDenied);
    }
    final snapshot = await _settings.reminderSnapshot();
    final nextAt = nextReminderAt(
      now: _clock.now(),
      minuteOfDay: minuteOfDay,
      lastDeliveredAt: snapshot.lastDeliveredAt,
    );
    if (await _platform.schedule(at: nextAt) case Rejected(:final reason)) {
      return Rejected(reason);
    }
    return switch (await _saveOrCancel(reminder)) {
      Ok() => Ok(nextAt),
      Rejected() => const Rejected(ReminderRejection.minuteOutOfRange),
    };
  }

  /// Saves [reminder]. A save that is refused or fails takes the schedule
  /// back first, so nothing is left pending for a reminder that stays off.
  /// The only refusal of `saveReminder` is the minute's range.
  Future<Outcome<void, SettingsRejection>> _saveOrCancel(
    ReminderSettings reminder,
  ) async {
    try {
      final saved = await _settings.saveReminder(reminder: reminder);
      if (saved case Rejected()) await _platform.cancel();
      return saved;
    } on Failure {
      await _platform.cancel();
      rethrow;
    }
  }
}
```

- [ ] **Step 4: Turn it off: save, then cancel**

Create `lib/features/reminders/domain/usecases/disable_reminder_use_case.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/reminders/domain/failures/reminder_failure.dart';
import 'package:memox/features/reminders/domain/models/reminder_platform_model.dart';
import 'package:memox/features/reminders/domain/repositories/reminder_platform_repository.dart';
import 'package:memox/features/settings/domain/models/reminder_settings_model.dart';
import 'package:memox/features/settings/domain/repositories/settings_repository.dart';

/// UC-REMINDER-001 A2: the person turns the reminder off. It is saved off
/// first, keeping its time, then the pending reminder is cancelled
/// (reminders spec D13). No permission is asked.
///
/// `couldNotCancel` comes back with the settings already off: a reminder may
/// still fire once, and skips itself when it reads them (E6). Calling this
/// again is the retry: it writes nothing and cancels. A save that fails
/// leaves as its `Failure` with nothing cancelled (E4).
final class DisableReminderUseCase {
  const DisableReminderUseCase(this._settings, this._platform);

  final SettingsRepository _settings;
  final ReminderPlatformRepository _platform;

  Future<Outcome<void, ReminderRejection>> call() async {
    final stored = (await _settings.reminderSnapshot()).reminder;
    if (stored.isEnabled) {
      // The stored minute is in range (its CHECK), so this is never refused.
      await _settings.saveReminder(
        reminder: ReminderSettings(
          isEnabled: false,
          minuteOfDay: stored.minuteOfDay,
        ),
      );
    }
    if (await _platform.capability() == ReminderCapability.unsupported) {
      return const Ok(null);
    }
    return _platform.cancel();
  }
}
```

- [ ] **Step 5: Change its time: schedule, then save**

Create `lib/features/reminders/domain/usecases/change_reminder_time_use_case.dart`:

```dart
import 'package:memox/core/clock/day_clock.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/reminders/domain/failures/reminder_failure.dart';
import 'package:memox/features/reminders/domain/models/reminder_platform_model.dart';
import 'package:memox/features/reminders/domain/models/reminder_time_model.dart';
import 'package:memox/features/reminders/domain/repositories/reminder_platform_repository.dart';
import 'package:memox/features/settings/domain/models/reminder_settings_model.dart';
import 'package:memox/features/settings/domain/repositories/settings_repository.dart';

/// UC-REMINDER-001 A1: the person picks a new time. While the reminder is
/// on, the new time is scheduled before it is saved (reminders spec D13): a
/// refusal keeps the old time and its schedule (`couldNotSchedule`), and a
/// save that fails puts the old time back on the platform, as far as it
/// can, then leaves as its `Failure` (E4). While it is off, or the platform
/// has no reminders, only the time is saved and `Ok(null)` comes back
/// (spec D17). No permission is asked.
final class ChangeReminderTimeUseCase {
  const ChangeReminderTimeUseCase(this._settings, this._platform, this._clock);

  final SettingsRepository _settings;
  final ReminderPlatformRepository _platform;
  final DayClock _clock;

  Future<Outcome<DateTime?, ReminderRejection>> call({
    required int minuteOfDay,
  }) async {
    final wanted = ReminderSettings(isEnabled: true, minuteOfDay: minuteOfDay);
    if (wanted.check() case Rejected()) {
      return const Rejected(ReminderRejection.minuteOutOfRange);
    }
    final snapshot = await _settings.reminderSnapshot();
    final old = snapshot.reminder;
    final changed = ReminderSettings(
      isEnabled: old.isEnabled,
      minuteOfDay: minuteOfDay,
    );
    if (!old.isEnabled ||
        await _platform.capability() == ReminderCapability.unsupported) {
      // The minute was checked above, so this save is never refused.
      await _settings.saveReminder(reminder: changed);
      return const Ok(null);
    }
    final now = _clock.now();
    final nextAt = nextReminderAt(
      now: now,
      minuteOfDay: minuteOfDay,
      lastDeliveredAt: snapshot.lastDeliveredAt,
    );
    if (await _platform.schedule(at: nextAt) case Rejected(:final reason)) {
      return Rejected(reason);
    }
    try {
      await _settings.saveReminder(reminder: changed);
    } on Failure {
      await _platform.schedule(
        at: nextReminderAt(
          now: now,
          minuteOfDay: old.minuteOfDay,
          lastDeliveredAt: snapshot.lastDeliveredAt,
        ),
      );
      rethrow;
    }
    return Ok(nextAt);
  }
}
```

- [ ] **Step 6: Regenerate the docs index**

Run:

```bash
python3 tools/docs/generate.py
python3 tools/docs/check.py
```

Expected: `check.py` ends with `PASS — 0 error(s), 46 warning(s)`.

- [ ] **Step 7: Run the task's tests**

```bash
flutter test test/features/reminders/domain/change_reminder_time_use_case_test.dart \
  test/features/reminders/domain/disable_reminder_use_case_test.dart \
  test/features/reminders/domain/enable_reminder_use_case_test.dart
```

Expected: `+19: All tests passed!`

- [ ] **Step 8: Stage the task's files**

The gate asks every source under `lib/` to be in git, so the task is staged before it runs.

```bash
git add lib/features/reminders/domain/usecases/change_reminder_time_use_case.dart \
  lib/features/reminders/domain/usecases/disable_reminder_use_case.dart \
  lib/features/reminders/domain/usecases/enable_reminder_use_case.dart \
  test/features/reminders/domain/change_reminder_time_use_case_test.dart \
  test/features/reminders/domain/disable_reminder_use_case_test.dart \
  test/features/reminders/domain/enable_reminder_use_case_test.dart \
  docs/_generated
git status --short
```

Expected: every path `git status --short` lists is staged: a letter in its first column, a space in its second.

- [ ] **Step 9: Run the gate**

Run:

```bash
bash .claude/skills/flutter-workflow/scripts/dod_check.sh
```

Expected: it ends with `✓ mechanical gates passed`. Among its steps:
`No issues found!`; `✓ generated code is fresh, complete and uncommitted`;
`✓ architecture boundaries clean`; `PASS — 0 error(s), 46 warning(s)` (the
warnings are older than this plan); the CI tooling tests `Ran 77 tests` and
`OK (skipped=8)` (eight of them need PowerShell 7); `204 passed` (the guard's
self-tests); `Code verification passed.`; `+1985: All tests passed!`.

- [ ] **Step 10: Commit**

```bash
git commit -F - <<'EOF'
feat(reminders): turn the reminder on, off, and change its time

EnableReminderUseCase checks the minute and the capability, asks for the
permission only then, schedules, and saves last, so a refusal or a failure
leaves the reminder off; a save that fails takes the schedule back
(UC-REMINDER-001 steps 2-3, E1-E4; spec D13, D14). DisableReminderUseCase
saves off, then cancels; a cancel that fails says so with the settings off
already, and trying again only cancels (A2, E6). ChangeReminderTimeUseCase
schedules the new time before saving it, puts the old one back when the
save fails, and only saves the minute while the reminder is off (A1, D17).
EOF
```

Append the session's attribution trailers to the message when you commit.


### Task 7: Deliver the day's digest when the reminder fires

**Files:**
- Create: `lib/features/reminders/domain/models/reminder_fire_report_model.dart`, `lib/features/reminders/domain/usecases/deliver_reminder_use_case.dart`
- Test (create): `test/features/reminders/domain/deliver_reminder_use_case_test.dart`
- Regenerate: `docs/_generated/` (`python3 tools/docs/generate.py`)

**Interfaces:**
- Consumes: Task 1's snapshot and `recordReminderDelivered`; Task 2's
  `reminderDigestOf`; Task 3's `reminderFireCheckOf` and `nextReminderAt`; Task 4's
  `ReminderWorkloadRepository`; Task 5's port and `FakeReminderPlatform`;
  `startOfLocalDay`.
- Produces:
  - `enum ReminderFireOutcome { delivered, unsupported, settingsUnreadable, disabled, beforeReminderTime, alreadyDeliveredToday, workloadUnreadable, nothingDue, couldNotShow }`
    and
    `ReminderFireReport({required ReminderFireOutcome outcome, int dueCount = 0, int otherDeckCount = 0, bool isRecorded = false, DateTime? nextAt})`
    (`reminders/domain/models/reminder_fire_report_model.dart`).
  - `DeliverReminderUseCase(SettingsRepository, ReminderWorkloadRepository, ReminderPlatformRepository, DayClock)`
    with `Future<ReminderFireReport> call()`.

Spec §9, D12, D16; Clarification 3; Review Focus 4 and 5.

- [ ] **Step 1: Write the failing tests**

Create `test/features/reminders/domain/deliver_reminder_use_case_test.dart`:

```dart
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/reminders/data/repositories/reminder_workload_repository_impl.dart';
import 'package:memox/features/reminders/domain/models/reminder_digest_model.dart';
import 'package:memox/features/reminders/domain/models/reminder_fire_report_model.dart';
import 'package:memox/features/reminders/domain/models/reminder_platform_model.dart';
import 'package:memox/features/reminders/domain/repositories/reminder_workload_repository.dart';
import 'package:memox/features/reminders/domain/usecases/deliver_reminder_use_case.dart';
import 'package:memox/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:memox/features/settings/domain/models/language_choice_model.dart';
import 'package:memox/features/settings/domain/models/reminder_settings_model.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/fake_day_clock.dart';
import '../../../support/fake_reminder_platform.dart';
import '../../../support/test_database.dart';

// UC-REMINDER-001 step 4, A3, A4, E5: what a fire of the reminder does. It
// reads the settings and the workload again, shows at most one digest a day
// and schedules the next fire (reminders spec §9, D12, D16).

DateTime _t0() => DateTime(2026, 9, 26, 9);

final _firedAt = DateTime(2026, 9, 26, 20, 5);
final _tomorrowAt2000 = DateTime(2026, 9, 27, 20);

/// The workload read failing the way a locked database does (E5).
final class _UnreadableWorkload implements ReminderWorkloadRepository {
  @override
  Future<List<ReminderDeckWorkload>> rootWorkloads({
    required DateTime now,
    required DateTime startOfToday,
  }) async => throw const DatabaseLockedFailure(cause: 'locked');
}

/// Fails the one write that records a delivery, and nothing else.
final class _FailingDeliveryRecord extends QueryInterceptor {
  @override
  Future<int> runUpdate(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    if (statement.contains('reminder_last_delivered_at')) {
      throw SqliteException(
        extendedResultCode: 5,
        message: 'database is locked',
      );
    }
    return super.runUpdate(executor, statement, args);
  }
}

void main() {
  late AppDatabase db;
  late SettingsRepositoryImpl settings;
  late FakeReminderPlatform platform;
  late FakeDayClock clock;

  Future<void> useDatabase(AppDatabase database) async {
    db = database;
    settings = SettingsRepositoryImpl(db, now: _t0);
    await settings.setLanguage(language: LanguageChoice.vi);
    await settings.saveReminder(
      reminder: const ReminderSettings(isEnabled: true, minuteOfDay: 1200),
    );
  }

  setUp(() async {
    platform = FakeReminderPlatform();
    clock = FakeDayClock(_firedAt);
    await useDatabase(openTestDatabase());
  });
  tearDown(() => db.close());

  DeliverReminderUseCase deliver({ReminderWorkloadRepository? workloads}) =>
      DeliverReminderUseCase(
        settings,
        workloads ?? ReminderWorkloadRepositoryImpl(db),
        platform,
        clock,
      );

  /// Korean: one overdue and one due today; English: three due today, so it
  /// would come first if today's cards were read as overdue; Empty: nothing.
  Future<void> seedDueCards() async {
    final decks = DeckRepositoryImpl(db, now: _t0);
    final korean = await decks.root('Korean');
    final lesson = await decks.sub(korean.id, 'Lesson A');
    final english = await decks.root('English');
    final words = await decks.sub(english.id, 'Words');
    await decks.root('Empty');
    Future<void> learned(String deckId, String id, DateTime dueAt) =>
        insertCard(
          db,
          id: id,
          deckId: deckId,
          back: 'meaning $id',
          learnedAt: DateTime(2026, 9, 1),
          dueAt: dueAt,
          box: 2,
        );
    await learned(lesson.id, 'k1', DateTime(2026, 9, 20));
    await learned(lesson.id, 'k2', DateTime(2026, 9, 26));
    for (final id in ['e1', 'e2', 'e3']) {
      await learned(words.id, id, DateTime(2026, 9, 26));
    }
  }

  Future<DateTime?> lastDelivery() async =>
      (await settings.reminderSnapshot()).lastDeliveredAt;

  test('at its time with cards due, it shows one digest of the most urgent '
      'root in the chosen language, records it and schedules tomorrow '
      '(UC-REMINDER-001 step 4, BR-REMINDER-004, BR-REMINDER-005)', () async {
    await seedDueCards();

    final report = await deliver()();

    expect(report.outcome, ReminderFireOutcome.delivered);
    expect(report.dueCount, 2);
    expect(report.otherDeckCount, 1);
    expect(report.isRecorded, isTrue);
    expect(report.nextAt, _tomorrowAt2000);
    expect(platform.shown!.deckName, 'Korean');
    expect(platform.shown!.dueCount, 2);
    expect(platform.shownIn, LanguageChoice.vi);
    expect(platform.pending, _tomorrowAt2000);
    expect((await lastDelivery())!.isAtSameMomentAs(_firedAt), isTrue);
  });

  test('with nothing due it shows nothing, records nothing and schedules '
      'tomorrow (UC-REMINDER-001 A3, A4, BR-REMINDER-003)', () async {
    final decks = DeckRepositoryImpl(db, now: _t0);
    final korean = await decks.root('Korean');
    final lesson = await decks.sub(korean.id, 'Lesson A');
    await insertCard(db, id: 'n1', deckId: lesson.id, back: 'new');

    final report = await deliver()();

    expect(report.outcome, ReminderFireOutcome.nothingDue);
    expect(report.nextAt, _tomorrowAt2000);
    expect(platform.shown, isNull);
    expect(await lastDelivery(), isNull);
  });

  test('the workload is read when the reminder fires, not when it was '
      'scheduled: cards studied since leave nothing to show '
      '(BR-REMINDER-003)', () async {
    await seedDueCards();
    await db.customStatement('UPDATE card_schedule SET due_at = ?', [
      DateTime(2026, 9, 30).millisecondsSinceEpoch ~/ 1000,
    ]);

    final report = await deliver()();

    expect(report.outcome, ReminderFireOutcome.nothingDue);
    expect(platform.shown, isNull);
  });

  test('a fire before its time shows nothing and is scheduled for the time '
      'today (spec D12)', () async {
    await seedDueCards();
    clock.current = DateTime(2026, 9, 26, 19, 30);

    final report = await deliver()();

    expect(report.outcome, ReminderFireOutcome.beforeReminderTime);
    expect(report.nextAt, DateTime(2026, 9, 26, 20));
    expect(platform.shown, isNull);
  });

  test('a second fire on the same day shows nothing more '
      '(BR-REMINDER-004)', () async {
    await seedDueCards();
    await deliver()();
    clock.current = DateTime(2026, 9, 26, 21);

    final report = await deliver()();

    expect(report.outcome, ReminderFireOutcome.alreadyDeliveredToday);
    expect(report.nextAt, _tomorrowAt2000);
    expect(
      platform.calls.where((call) => call == PlatformCall.show),
      hasLength(1),
    );
  });

  test('a reminder that is off shows nothing and schedules nothing: a fire '
      'left over from before (UC-REMINDER-001 E6, spec D16)', () async {
    await seedDueCards();
    await settings.saveReminder(
      reminder: const ReminderSettings(isEnabled: false, minuteOfDay: 1200),
    );

    final report = await deliver()();

    expect(report.outcome, ReminderFireOutcome.disabled);
    expect(report.nextAt, isNull);
    expect(platform.calls, [PlatformCall.capability]);
  });

  test('a workload read that fails shows nothing, keeps the day open and '
      'schedules the next fire (UC-REMINDER-001 E5)', () async {
    final report = await deliver(workloads: _UnreadableWorkload())();

    expect(report.outcome, ReminderFireOutcome.workloadUnreadable);
    expect(report.nextAt, _tomorrowAt2000);
    expect(platform.shown, isNull);
    expect(await lastDelivery(), isNull);
  });

  test('settings that cannot be read show nothing and schedule nothing: no '
      'time is known (spec D16)', () async {
    await db.customStatement('DELETE FROM app_settings');

    final report = await deliver()();

    expect(report.outcome, ReminderFireOutcome.settingsUnreadable);
    expect(report.nextAt, isNull);
    expect(platform.calls, [PlatformCall.capability]);
  });

  test('a digest the platform refuses is not recorded, and the next fire is '
      'still scheduled (spec D16)', () async {
    await seedDueCards();
    platform.refusing.add(PlatformCall.show);

    final report = await deliver()();

    expect(report.outcome, ReminderFireOutcome.couldNotShow);
    expect(report.isRecorded, isFalse);
    expect(report.nextAt, _tomorrowAt2000);
    expect(await lastDelivery(), isNull);
  });

  test('a delivery that cannot be recorded is still delivered, and tomorrow '
      'is scheduled from it (spec D16)', () async {
    await db.close();
    await useDatabase(
      AppDatabase(
        NativeDatabase.memory().interceptWith(_FailingDeliveryRecord()),
      ),
    );
    await seedDueCards();

    final report = await deliver()();

    expect(report.outcome, ReminderFireOutcome.delivered);
    expect(report.isRecorded, isFalse);
    expect(report.nextAt, _tomorrowAt2000);
  });

  test('a platform without reminders is asked nothing more, and nothing is '
      'read (BR-REMINDER-012)', () async {
    platform.capabilityValue = ReminderCapability.unsupported;

    final report = await deliver()();

    expect(report.outcome, ReminderFireOutcome.unsupported);
    expect(platform.calls, [PlatformCall.capability]);
  });
}
```

- [ ] **Step 2: Run them to see them fail**

```bash
flutter test test/features/reminders/domain/deliver_reminder_use_case_test.dart
```

Expected: `+0 -1: Some tests failed.` The test file does not compile:
`Error: Error when reading 'lib/features/reminders/domain/models/reminder_fire_report_model.dart': No such file or directory`,
the same for `deliver_reminder_use_case.dart`, then
`Error: 'DeliverReminderUseCase' isn't a type.` and
`Error: Undefined name 'ReminderFireOutcome'.`

- [ ] **Step 3: Name how a fire ended**

Create `lib/features/reminders/domain/models/reminder_fire_report_model.dart`:

```dart
/// What a fire of the reminder ended in (reminders spec §9).
enum ReminderFireOutcome {
  /// The digest was shown.
  delivered,

  /// The platform has no reminders.
  unsupported,

  /// The settings could not be read: nothing is shown and nothing is
  /// rescheduled, and the next reconcile restores the schedule (spec D16).
  settingsUnreadable,

  /// The reminder is off: a fire left over from before, not rescheduled.
  disabled,

  /// The local time has not reached the reminder's minute (spec D12).
  beforeReminderTime,

  /// The local day already had its digest (BR-REMINDER-004).
  alreadyDeliveredToday,

  /// The workload could not be read: nothing is shown (UC-REMINDER-001 E5).
  workloadUnreadable,

  /// No card is due (BR-REMINDER-003; UC-REMINDER-001 A3, A4).
  nothingDue,

  /// The platform refused to show the digest; nothing is recorded.
  couldNotShow,
}

/// A fire of the reminder, told in typed reasons and counts only, so that a
/// log line built from it can never carry a deck name, a card or the
/// digest's text (BR-REMINDER-005).
final class ReminderFireReport {
  const ReminderFireReport({
    required this.outcome,
    this.dueCount = 0,
    this.otherDeckCount = 0,
    this.isRecorded = false,
    this.nextAt,
  });

  final ReminderFireOutcome outcome;

  /// The digest's two counts; 0 unless it was delivered.
  final int dueCount;
  final int otherDeckCount;

  /// Whether the delivery was recorded; false unless it was delivered.
  final bool isRecorded;

  /// The next fire; null when nothing was scheduled.
  final DateTime? nextAt;
}
```

- [ ] **Step 4: Deliver**

Create `lib/features/reminders/domain/usecases/deliver_reminder_use_case.dart`:

```dart
import 'package:memox/core/clock/day_clock.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/reminders/domain/models/reminder_digest_model.dart';
import 'package:memox/features/reminders/domain/models/reminder_fire_report_model.dart';
import 'package:memox/features/reminders/domain/models/reminder_platform_model.dart';
import 'package:memox/features/reminders/domain/models/reminder_time_model.dart';
import 'package:memox/features/reminders/domain/repositories/reminder_platform_repository.dart';
import 'package:memox/features/reminders/domain/repositories/reminder_workload_repository.dart';
import 'package:memox/features/settings/domain/models/reminder_snapshot_model.dart';
import 'package:memox/features/settings/domain/repositories/settings_repository.dart';
import 'package:memox/features/srs/domain/models/due_date_model.dart';

/// UC-REMINDER-001 step 4: what runs when the reminder fires, from the
/// platform's background callback (BE-B5b). It reads the settings and the
/// workload again, at fire time (BR-REMINDER-003), shows at most one digest
/// a local day (BR-REMINDER-004) and schedules the next fire. The only write
/// is the last delivery (reminders spec D16).
///
/// The report holds typed reasons and counts only (BR-REMINDER-005).
final class DeliverReminderUseCase {
  const DeliverReminderUseCase(
    this._settings,
    this._workloads,
    this._platform,
    this._clock,
  );

  final SettingsRepository _settings;
  final ReminderWorkloadRepository _workloads;
  final ReminderPlatformRepository _platform;
  final DayClock _clock;

  Future<ReminderFireReport> call() async {
    if (await _platform.capability() == ReminderCapability.unsupported) {
      return const ReminderFireReport(outcome: ReminderFireOutcome.unsupported);
    }
    final ReminderSnapshot snapshot;
    try {
      snapshot = await _settings.reminderSnapshot();
    } on Failure {
      return const ReminderFireReport(
        outcome: ReminderFireOutcome.settingsUnreadable,
      );
    }
    final now = _clock.now();
    final check = reminderFireCheckOf(
      reminder: snapshot.reminder,
      now: now,
      lastDeliveredAt: snapshot.lastDeliveredAt,
    );
    return switch (check) {
      ReminderFireCheck.disabled => const ReminderFireReport(
        outcome: ReminderFireOutcome.disabled,
      ),
      ReminderFireCheck.beforeReminderTime => _skipped(
        ReminderFireOutcome.beforeReminderTime,
        snapshot,
        now,
      ),
      ReminderFireCheck.alreadyDeliveredToday => _skipped(
        ReminderFireOutcome.alreadyDeliveredToday,
        snapshot,
        now,
      ),
      ReminderFireCheck.due => _deliver(snapshot, now),
    };
  }

  Future<ReminderFireReport> _deliver(
    ReminderSnapshot snapshot,
    DateTime now,
  ) async {
    final List<ReminderDeckWorkload> workloads;
    try {
      workloads = await _workloads.rootWorkloads(
        now: now,
        startOfToday: startOfLocalDay(now),
      );
    } on Failure {
      return _skipped(ReminderFireOutcome.workloadUnreadable, snapshot, now);
    }
    final digest = reminderDigestOf(workloads);
    if (digest == null) {
      return _skipped(ReminderFireOutcome.nothingDue, snapshot, now);
    }
    final shown = await _platform.show(
      digest: digest,
      language: snapshot.language,
    );
    if (shown case Rejected()) {
      return _skipped(ReminderFireOutcome.couldNotShow, snapshot, now);
    }
    return ReminderFireReport(
      outcome: ReminderFireOutcome.delivered,
      dueCount: digest.dueCount,
      otherDeckCount: digest.otherDeckCount,
      isRecorded: await _recorded(now),
      nextAt: await _scheduleNext(snapshot, now, deliveredAt: now),
    );
  }

  /// A fire that showed nothing: the day stays open, and the next fire is
  /// scheduled.
  Future<ReminderFireReport> _skipped(
    ReminderFireOutcome outcome,
    ReminderSnapshot snapshot,
    DateTime now,
  ) async => ReminderFireReport(
    outcome: outcome,
    nextAt: await _scheduleNext(
      snapshot,
      now,
      deliveredAt: snapshot.lastDeliveredAt,
    ),
  );

  /// Records the delivery at [at]. A record that fails is reported, not
  /// thrown: the digest is on the screen already.
  Future<bool> _recorded(DateTime at) async {
    try {
      await _settings.recordReminderDelivered(at: at);
      return true;
    } on Failure {
      return false;
    }
  }

  /// The next fire, scheduled; null when the platform refused it.
  Future<DateTime?> _scheduleNext(
    ReminderSnapshot snapshot,
    DateTime now, {
    required DateTime? deliveredAt,
  }) async {
    final nextAt = nextReminderAt(
      now: now,
      minuteOfDay: snapshot.reminder.minuteOfDay,
      lastDeliveredAt: deliveredAt,
    );
    return switch (await _platform.schedule(at: nextAt)) {
      Ok() => nextAt,
      Rejected() => null,
    };
  }
}
```

- [ ] **Step 5: Regenerate the docs index**

Run:

```bash
python3 tools/docs/generate.py
python3 tools/docs/check.py
```

Expected: `check.py` ends with `PASS — 0 error(s), 46 warning(s)`.

- [ ] **Step 6: Run the task's tests**

```bash
flutter test test/features/reminders/domain/deliver_reminder_use_case_test.dart
```

Expected: `+11: All tests passed!`

- [ ] **Step 7: Stage the task's files**

The gate asks every source under `lib/` to be in git, so the task is staged before it runs.

```bash
git add lib/features/reminders/domain/models/reminder_fire_report_model.dart \
  lib/features/reminders/domain/usecases/deliver_reminder_use_case.dart \
  test/features/reminders/domain/deliver_reminder_use_case_test.dart \
  docs/_generated
git status --short
```

Expected: every path `git status --short` lists is staged: a letter in its first column, a space in its second.

- [ ] **Step 8: Run the gate**

Run:

```bash
bash .claude/skills/flutter-workflow/scripts/dod_check.sh
```

Expected: it ends with `✓ mechanical gates passed`. Among its steps:
`No issues found!`; `✓ generated code is fresh, complete and uncommitted`;
`✓ architecture boundaries clean`; `PASS — 0 error(s), 46 warning(s)` (the
warnings are older than this plan); the CI tooling tests `Ran 77 tests` and
`OK (skipped=8)` (eight of them need PowerShell 7); `204 passed` (the guard's
self-tests); `Code verification passed.`; `+1996: All tests passed!`.

- [ ] **Step 9: Commit**

```bash
git commit -F - <<'EOF'
feat(reminders): deliver the day's digest when the reminder fires

DeliverReminderUseCase is what the background callback of BE-B5b runs: it
reads the settings and the workload again, shows at most one digest a local
day, records it, and schedules the next fire (UC-REMINDER-001 step 4, A3, A4,
E5; BR-REMINDER-003, BR-REMINDER-004; spec D16). ReminderFireReport tells how
a fire ended in typed reasons and counts only (BR-REMINDER-005).
EOF
```

Append the session's attribution trailers to the message when you commit.


### Task 8: The package's documents

**Files:**
- Modify: `.claude/skills/flutter-workflow/scripts/verification_impact_map.json`, `docs/features/reminders/README.md`, `docs/features/reminders/usecases/UC-REMINDER-001-bat-nhac-hoc-hang-ngay.md`, `docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md`, `docs/wbs_BE.md`, `docs/wbs_FE.md`
- Regenerate: `docs/_generated/` (`python3 tools/docs/generate.py`)

**Interfaces:**
- Consumes: the six use cases of Tasks 5–7, for the `code` fields.
- Produces: the documents of spec §12, and Clarifications 6 and 7.

Spec §12; Clarifications 6 and 7.

- [ ] **Step 1: Follow the reminders README's new dependency in the CI impact map**

In `.claude/skills/flutter-workflow/scripts/verification_impact_map.json`:

Replace

```json
    "search": [],
    "settings": [],
    "srs": [
```

with

```json
    "search": [],
    "settings": [
      "reminders"
    ],
    "srs": [
```

- [ ] **Step 2: Record the package in the reminder documents, the UI-base register and both WBS**

Replace the whole of `docs/features/reminders/README.md` with:

```markdown
---
feature: reminders
code: [lib/features/reminders/domain, lib/features/reminders/data, lib/features/reminders/di]
depends_on: [deck, settings, study]
---
## Phạm vi

**Phạm vi:** sub-project sau — nhắc học hằng ngày (spec §2). Phần logic xong ở BE-B5a
([spec](../../superpowers/specs/2026-09-26-reminders-backend-design.md)); adapter Android là BE-B5b; màn 24 thuộc FE-B5.

Nhắc học hằng ngày (UC-REMINDER-001). Công tắc, giờ nhắc và lần gửi gần nhất nằm trong
dòng `app_settings`, do feature `settings` ghi. Feature này giữ port tới nền tảng
(`ReminderPlatformRepository`), workload đọc lúc fire, digest và thứ tự của nó, giờ nhắc
kế tiếp theo giờ địa phương, và sáu use case.

## Màn hình → Use case

| Màn hình | UC |
|---|---|
| `Settings → Daily reminder` | UC-REMINDER-001 |

Nguồn: trigger của UC-REMINDER-001.

## Không thuộc phạm vi

| Thứ | Vì sao |
|---|---|
| Nhắc theo thẻ mới, nhiều lượt nhắc trong ngày, nhắc theo từng deck | Ngoài phạm vi (trước migrate: `use-cases/README.md` mục "Điều đã cố ý không đặc tả") |
```

In `docs/features/reminders/usecases/UC-REMINDER-001-bat-nhac-hoc-hang-ngay.md`:

Replace

```markdown
rules: [BR-DECK-003, BR-CORE-001, BR-CORE-002, BR-CORE-004, BR-REMINDER-001, BR-REMINDER-002, BR-REMINDER-003, BR-REMINDER-004, BR-REMINDER-005, BR-REMINDER-006, BR-REMINDER-007, BR-REMINDER-008, BR-REMINDER-009, BR-REMINDER-010, BR-REMINDER-011, BR-REMINDER-012, BR-STUDY-051, BR-STUDY-067, BR-STUDY-074]
code: []
---
```

with

```markdown
rules: [BR-DECK-003, BR-CORE-001, BR-CORE-002, BR-CORE-004, BR-REMINDER-001, BR-REMINDER-002, BR-REMINDER-003, BR-REMINDER-004, BR-REMINDER-005, BR-REMINDER-006, BR-REMINDER-007, BR-REMINDER-008, BR-REMINDER-009, BR-REMINDER-010, BR-REMINDER-011, BR-REMINDER-012, BR-STUDY-051, BR-STUDY-067, BR-STUDY-074]
code: [lib/features/reminders/domain/usecases/watch_reminder_use_case.dart, lib/features/reminders/domain/usecases/enable_reminder_use_case.dart, lib/features/reminders/domain/usecases/disable_reminder_use_case.dart, lib/features/reminders/domain/usecases/change_reminder_time_use_case.dart, lib/features/reminders/domain/usecases/reconcile_reminder_use_case.dart, lib/features/reminders/domain/usecases/deliver_reminder_use_case.dart]
---
```

Replace

```markdown

**Phạm vi:** sub-project sau — nhắc học hằng ngày (spec §2).

```

with

```markdown

**Phạm vi:** sub-project sau — nhắc học hằng ngày (spec §2). Phần logic xong ở BE-B5a
([spec](../../../superpowers/specs/2026-09-26-reminders-backend-design.md)); adapter Android (lịch nền, notification, quyền) là BE-B5b; màn
24 thuộc FE-B5.

```

Replace

```markdown

- [ ] OPEN QUESTION: nguồn chưa có acceptance criteria dạng Given/When/Then; Postconditions giữ nguyên văn ở `## Local`.
```

with

```markdown

- [ ] **Given** nhắc học đang tắt, **when** người dùng bật lúc 20:00 và cấp quyền, **then** quyền được xin đúng lúc này, đúng một lượt nhắc được đặt cho lần 20:00 địa phương kế tiếp, rồi settings mới lưu bật cùng giờ (BR-REMINDER-009, BR-REMINDER-011; main 2–3).
- [ ] **Given** người dùng từ chối quyền, **when** bật, **then** settings vẫn tắt, không có lượt nào chờ, và hệ thống không tự xin lại (E1).
- [ ] **Given** nền tảng không hỗ trợ nhắc học, **when** mở màn hoặc bật, **then** capability báo không hỗ trợ và không có gì được xin, lưu hay đặt lịch (E2).
- [ ] **Given** nền tảng từ chối đặt lịch, **when** bật hoặc đổi giờ, **then** settings giữ nguyên giá trị cũ và không có gì được ghi (E3).
- [ ] **Given** lưu settings thất bại, **when** bật, **then** lượt vừa đặt bị gỡ và lỗi đến tay người gọi dưới dạng `Failure` (E4).
- [ ] **Given** nhắc học đang bật và có thẻ đến hạn, **when** đến giờ, **then** workload được đọc lại, đúng một digest hiện tên root deck cấp bách nhất theo BR-REMINDER-006, số thẻ đến hạn của deck đó và số deck khác còn thẻ đến hạn, lần gửi được ghi, và lượt của ngày mai được đặt (main 4).
- [ ] **Given** không còn thẻ đến hạn, hoặc chỉ còn thẻ chưa học, **when** đến giờ, **then** không hiện gì và lượt kế tiếp vẫn được đặt (A3, A4).
- [ ] **Given** đọc workload thất bại lúc fire, **when** đến giờ, **then** không hiện gì và lượt kế tiếp vẫn được đặt (E5).
- [ ] **Given** một ngày địa phương đã có digest, **when** lượt nhắc fire lần nữa trong ngày đó, **then** không hiện thêm (BR-REMINDER-004).
- [ ] **Given** nhắc học đang bật, **when** người dùng đổi giờ, **then** giờ mới được đặt lịch rồi mới lưu, trong cùng một thao tác (A1).
- [ ] **Given** người dùng tắt nhắc học, **when** huỷ lịch thất bại, **then** settings đã tắt và lý do là `couldNotCancel`; thử lại chỉ huỷ, không ghi gì (A2, E6).
- [ ] **Given** app mở lại nhiều lần trong ngày khi đang bật, **when** hoà giải chạy, **then** vẫn đúng một lượt chờ; khi đang tắt, lượt còn sót bị huỷ (A5, BR-REMINDER-010).
- [ ] **Given** đọc settings thất bại khi mở màn, **then** stream báo `Failure`, không có giá trị bịa (E7).
- [ ] Main 5 và A6 (chạm và vuốt bỏ notification) được kiểm ở BE-B5b và FE-B5, trên thiết bị.
```

In `docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md`:

Replace

```markdown
| 107 | Card import shows one spinner card while a large import writes, with no progress or waiting line | critique 2026-09-26 P3 (transfer) |

```

with

```markdown
| 107 | Card import shows one spinner card while a large import writes, with no progress or waiting line | critique 2026-09-26 P3 (transfer) |
| 108 | "Reset app options" also turns the daily reminder off and puts it back at 20:00 (BR-SETTINGS-008): the kit's confirmation body ("Theme, language, cards per session and new-card order go back to their defaults.") and the row's sub-line ("Theme, language, study defaults") leave it out, and FE-A3 names it in both | reminders spec D3, D4 |

```

In `docs/wbs_BE.md`:

Replace

```markdown
| BE-B4 | Starter decks: thư viện template, sao chép template vào dữ liệu người dùng (UC-STARTER-001; BR-STARTER-001…BR-STARTER-010) | xong | BE-03, BE-04 | M | [spec](superpowers/specs/2026-09-26-starter-decks-backend-design.md) và [plan](superpowers/plans/2026-09-26-starter-decks-backend.md); test trong `test/features/starter_decks/` | FE-B4 dựng màn 03 trên hai use case của `starter_decks` |
| BE-B5 | Nhắc học hằng ngày (UC-REMINDER-001; BR-REMINDER-001…BR-REMINDER-012) | chưa bắt đầu | BE-03, BE-A4 | M | Các cột `reminder_*` trong `app_settings` đã có | Cần quyết định dependency thông báo cục bộ (xem Điểm chặn) |

```

with

```markdown
| BE-B4 | Starter decks: thư viện template, sao chép template vào dữ liệu người dùng (UC-STARTER-001; BR-STARTER-001…BR-STARTER-010) | xong | BE-03, BE-04 | M | [spec](superpowers/specs/2026-09-26-starter-decks-backend-design.md) và [plan](superpowers/plans/2026-09-26-starter-decks-backend.md); test trong `test/features/starter_decks/` | FE-B4 dựng màn 03 trên hai use case của `starter_decks` |
| BE-B5a | Nhắc học hằng ngày, phần logic (UC-REMINDER-001; BR-REMINDER-001…BR-REMINDER-012, BR-SETTINGS-008): giá trị nhắc trong settings, reset sáu giá trị, port tới nền tảng với adapter "không hỗ trợ", workload đọc lúc fire, digest và thứ tự BR-REMINDER-006, giờ nhắc theo giờ địa phương, sáu use case | xong | BE-03, BE-A4 | M | [spec](superpowers/specs/2026-09-26-reminders-backend-design.md) và [plan](superpowers/plans/2026-09-26-reminders-backend.md); test trong `test/features/reminders/` và `test/features/settings/` | FE-B5 dựng màn 24 trên sáu use case, sau BE-B5b |
| BE-B5b | Nhắc học hằng ngày, phần Android: adapter của `ReminderPlatformRepository` (lịch inexact, notification id cố định, quyền Android 13+, chạm mở Study Home), manifest và gradle, entry point nền gọi `DeliverReminderUseCase`, hoà giải lúc app khởi động | chưa bắt đầu | BE-B5a | M | [Spec gói 11a](superpowers/specs/2026-09-26-reminders-backend-design.md) §13 ghi hai plugin ứng viên | Cần chọn dependency và có Android SDK hoặc thiết bị (xem Điểm chặn) |

```

Replace

```markdown
| BE-D3 | Sửa tài liệu đã lệch với code: [host-coverage-map.md](shared/testing/host-coverage-map.md) còn ghi "V8 chưa có test nào"; skill `flutter-workflow` còn trỏ tới `docs/wbs.md` của V7 | chưa bắt đầu | — | S | Khảo sát ngày 2026-09-24. `code:` của README srs và README settings đã sửa cùng BE-A1 và BE-A2; của README study và README study-mode cùng gói 2a | Sửa trong commit của hạng mục chạm tới phần đó (tài liệu và code cùng commit, [`docs/README.md`](README.md)) |
| BE-D4 | Acceptance criteria dạng Given/When/Then cho 22 UC; dùng chung với FE | bị chặn | — | M | [`open-questions.md`](_generated/open-questions.md) ghi thiếu ở 19 UC; UC-TRANSFER-001 và UC-TRANSFER-002 (BE-B3), UC-STARTER-001 (BE-B4) đã có, trong phạm vi spec của gói | Sửa UC `ready` là sửa hợp đồng: chủ dự án nêu phạm vi file được sửa, rồi viết theo từng nhóm hạng mục |
| BE-D5 | Tỉa phần chỉ phục vụ CI của `build_verification_plan.py` (shard, `--github-output`, cờ Widgetbook và memox-api) cùng test của nó; sửa lời giúp của `dod_check.sh`, nơi `--changed` và `--fast` còn được tả theo CI của V7 | chưa bắt đầu | BE-D2 | M | CI của V8 chạy gate đầy đủ, không dùng planner ([spec gói 6](superpowers/specs/2026-09-25-ci-gate-design.md) D2, D11); planner vẫn phục vụ `dod_check.sh --changed` | Giữ phần `--changed` dùng, bỏ phần chỉ CI của V7 cần, kèm test |
```

with

```markdown
| BE-D3 | Sửa tài liệu đã lệch với code: [host-coverage-map.md](shared/testing/host-coverage-map.md) còn ghi "V8 chưa có test nào"; skill `flutter-workflow` còn trỏ tới `docs/wbs.md` của V7 | chưa bắt đầu | — | S | Khảo sát ngày 2026-09-24. `code:` của README srs và README settings đã sửa cùng BE-A1 và BE-A2; của README study và README study-mode cùng gói 2a | Sửa trong commit của hạng mục chạm tới phần đó (tài liệu và code cùng commit, [`docs/README.md`](README.md)) |
| BE-D4 | Acceptance criteria dạng Given/When/Then cho 22 UC; dùng chung với FE | bị chặn | — | M | [`open-questions.md`](_generated/open-questions.md) ghi thiếu ở 18 UC; UC-TRANSFER-001 và UC-TRANSFER-002 (BE-B3), UC-STARTER-001 (BE-B4), UC-REMINDER-001 (BE-B5a) đã có, trong phạm vi spec của gói | Sửa UC `ready` là sửa hợp đồng: chủ dự án nêu phạm vi file được sửa, rồi viết theo từng nhóm hạng mục |
| BE-D5 | Tỉa phần chỉ phục vụ CI của `build_verification_plan.py` (shard, `--github-output`, cờ Widgetbook và memox-api) cùng test của nó; sửa lời giúp của `dod_check.sh`, nơi `--changed` và `--fast` còn được tả theo CI của V7 | chưa bắt đầu | BE-D2 | M | CI của V8 chạy gate đầy đủ, không dùng planner ([spec gói 6](superpowers/specs/2026-09-25-ci-gate-design.md) D2, D11); planner vẫn phục vụ `dod_check.sh --changed` | Giữ phần `--changed` dùng, bỏ phần chỉ CI của V7 cần, kèm test |
```

Replace

```markdown
  final review toàn nhánh trước khi mở PR.
- **BE-D2** (gói 6, [spec](superpowers/specs/2026-09-25-ci-gate-design.md),
```

with

```markdown
  final review toàn nhánh trước khi mở PR.
- **BE-B5a** (gói 11a, [spec](superpowers/specs/2026-09-26-reminders-backend-design.md),
  [plan](superpowers/plans/2026-09-26-reminders-backend.md)): gate xanh sau mỗi task, final review
  toàn nhánh trước khi mở PR.
- **BE-D2** (gói 6, [spec](superpowers/specs/2026-09-25-ci-gate-design.md),
```

Replace

```markdown
  `gate`, `goldens` và `CI gate` đỏ, rồi commit hoàn lại đưa cả ba về xanh trước khi merge.
- **Traceability:** có test chứa ID cho 21/22 UC (UC-CARD-001, UC-CARD-002, UC-DECK-001…UC-DECK-006, UC-PROGRESS-001, UC-PROGRESS-002, UC-SEARCH-001, UC-SETTINGS-001, UC-SRS-001, UC-STARTER-001, UC-STUDY-001…UC-STUDY-003, UC-TAG-001, UC-TRANSFER-001, UC-TRANSFER-002, UC-TRASH-001).
  UC còn lại (UC-REMINDER-001) chưa có code.

```

with

```markdown
  `gate`, `goldens` và `CI gate` đỏ, rồi commit hoàn lại đưa cả ba về xanh trước khi merge.
- **Traceability:** có test chứa ID cho 22/22 UC (UC-CARD-001, UC-CARD-002, UC-DECK-001…UC-DECK-006, UC-PROGRESS-001, UC-PROGRESS-002, UC-REMINDER-001, UC-SEARCH-001, UC-SETTINGS-001, UC-SRS-001, UC-STARTER-001, UC-STUDY-001…UC-STUDY-003, UC-TAG-001, UC-TRANSFER-001, UC-TRANSFER-002, UC-TRASH-001).

```

Replace

```markdown

Không có hạng mục backend nào đang làm sau gói 10 (BE-B4).

```

with

```markdown

Không có hạng mục backend nào đang làm sau gói 11a (BE-B5a).

```

Replace

```markdown
| Mastery của danh sách deck | Chưa BR/UC nào nói thanh mastery, donut và dòng "Mastered" của màn 01 đếm gì, cũng như sort "tiến độ" mà UC-DECK-006 nhắc tới (đang là Coming soon). Trạng thái thẻ đã có ở BR-CARD-006…BR-CARD-008, và panel "mastered" của card list (IT-ORG-010) đã dựng trên số đếm của BE-A9 | Chỉ hai phần đó của danh sách deck; không thuộc Progress (BE-A7, spec gói 4 D1) | Bổ sung định nghĩa vào BR/UC của deck trước khi làm |
| BE-B5 | Cần một dependency thông báo cục bộ | Thêm package vào dự án | Quyết trong spec của BE-B5, kèm lý do và cách rollback |
| BE-B5 | BR-SETTINGS-008 ghi `Reset to defaults` đưa toàn bộ giá trị của `app_settings` về mặc định; BE-A1 (spec D6) chỉ đưa về mặc định bốn giá trị người dùng đặt được ở V8.0, chưa đụng `reminder_enabled`, `reminder_minute_of_day` | `Reset to defaults` khi nhắc học đã có giao diện | Quyết trong spec của BE-B5; sửa câu chữ BR-SETTINGS-008 cần chủ dự án cho phép |
| BE-D4 | Sửa UC `ready` là sửa hợp đồng ([`docs/README.md`](README.md), mục "Hợp đồng và phạm vi sửa") | 19 UC còn thiếu | Chủ dự án nêu phạm vi file được sửa |

```

with

```markdown
| Mastery của danh sách deck | Chưa BR/UC nào nói thanh mastery, donut và dòng "Mastered" của màn 01 đếm gì, cũng như sort "tiến độ" mà UC-DECK-006 nhắc tới (đang là Coming soon). Trạng thái thẻ đã có ở BR-CARD-006…BR-CARD-008, và panel "mastered" của card list (IT-ORG-010) đã dựng trên số đếm của BE-A9 | Chỉ hai phần đó của danh sách deck; không thuộc Progress (BE-A7, spec gói 4 D1) | Bổ sung định nghĩa vào BR/UC của deck trước khi làm |
| BE-B5b | Cần dependency cho lịch nền và notification cục bộ | Thêm package vào dự án | Quyết trong spec của BE-B5b, kèm lý do và cách rollback; ứng viên ở [spec gói 11a](superpowers/specs/2026-09-26-reminders-backend-design.md) §13 |
| BE-B5b | Container của agent không có Android SDK (`dl.google.com` bị chặn trong network policy) và không có thiết bị | Không kiểm chứng được adapter, manifest và lịch nền | Chủ dự án mở `dl.google.com` cho môi trường, hoặc làm BE-B5b trên máy có SDK và thiết bị |
| BE-D4 | Sửa UC `ready` là sửa hợp đồng ([`docs/README.md`](README.md), mục "Hợp đồng và phạm vi sửa") | 18 UC còn thiếu | Chủ dự án nêu phạm vi file được sửa |

```

Replace

```markdown

1. BE-B5 theo ưu tiên sản phẩm. Truy vấn mới của nó đọc `card` hoặc `deck` sẽ
   gặp test hình dạng của BR-TRASH-002 (spec gói 7 §11).
2. BE-D5 khi thuận tiện; không hạng mục nào chờ nó.
```

with

```markdown

1. BE-B5b cùng hoặc sau FE-B5, khi có Android SDK hoặc thiết bị (xem Điểm chặn).
2. BE-D5 khi thuận tiện; không hạng mục nào chờ nó.
```

Replace

```markdown
  schema. Thêm lại BE-C5 (Unicode NFC), dòng gói 9a đã thêm nhưng không merge.
- **Cập nhật cùng commit:** sửa file này trong cùng commit với việc nó mô tả.
```

with

```markdown
  schema. Thêm lại BE-C5 (Unicode NFC), dòng gói 9a đã thêm nhưng không merge.
- **Cập nhật ngày 2026-09-26:** chủ dự án tách BE-B5 thành BE-B5a và BE-B5b. BE-B5a xong
  trong gói 11a: toàn bộ logic của nhắc học sau một port tới nền tảng, với adapter
  "không hỗ trợ"; không đổi schema, không thêm dependency. Điểm chặn BR-SETTINGS-008 đóng:
  reset đưa cả nhắc học về mặc định (quyết định của chủ dự án). Dependency notification
  chuyển sang BE-B5b.
- **Cập nhật cùng commit:** sửa file này trong cùng commit với việc nó mô tả.
```

In `docs/wbs_FE.md`:

Replace

```markdown
| FE-A2 | Card: danh sách card (filter, tìm, đếm, Select all, thao tác hàng loạt), tạo/sửa card có tag, chi tiết card và lịch sử ôn (UC-CARD-001, UC-CARD-002) | đang làm | BE-04, BE-05, FE-A1 | L | Danh sách: [PR #31](https://github.com/ntgptit/memox-v8/pull/31), căn màn 07 ở [PR #46](https://github.com/ntgptit/memox-v8/pull/46), [#49](https://github.com/ntgptit/memox-v8/pull/49); editor và chi tiết: [#33](https://github.com/ntgptit/memox-v8/pull/33), [#35](https://github.com/ntgptit/memox-v8/pull/35); field editor theo kit: [#51](https://github.com/ntgptit/memox-v8/pull/51), [#52](https://github.com/ntgptit/memox-v8/pull/52) | Chức năng xong; companion `test/visual_audit/` xong ở FE-D2. Còn: file chi tiết handoff cho màn 08–10 |
| FE-A3 | Cài đặt: mặc định học, theme, ngôn ngữ, reset về mặc định. Lưu theme và ngôn ngữ thay cho theme hệ thống đang cố định trong `app.dart` (UC-SETTINGS-001; BR-SETTINGS-005, BR-SETTINGS-006) | chưa bắt đầu | BE-A1 | M | `lib/app/app.dart` để `ThemeMode.system` tới khi feature settings lưu được lựa chọn; spec UI base §10 để việc lưu theme và ngôn ngữ ngoài phạm vi; [ui.md](features/settings/ui.md); backend sẵn: 8 use case trong `lib/features/settings/domain/usecases/` | Đọc màn 15, 23, 25, 26 trong kit, viết file chi tiết handoff, rồi lập plan |
| FE-A4 | Xác nhận "Đặt lại tiến độ học" trên một root deck (UC-SRS-001) | xong | BE-A2, FE-A1 | S | [ui.md](features/srs/ui.md) | Màn 02 của screen handoff, phase D của FE-A11 (#42) |
```

with

```markdown
| FE-A2 | Card: danh sách card (filter, tìm, đếm, Select all, thao tác hàng loạt), tạo/sửa card có tag, chi tiết card và lịch sử ôn (UC-CARD-001, UC-CARD-002) | đang làm | BE-04, BE-05, FE-A1 | L | Danh sách: [PR #31](https://github.com/ntgptit/memox-v8/pull/31), căn màn 07 ở [PR #46](https://github.com/ntgptit/memox-v8/pull/46), [#49](https://github.com/ntgptit/memox-v8/pull/49); editor và chi tiết: [#33](https://github.com/ntgptit/memox-v8/pull/33), [#35](https://github.com/ntgptit/memox-v8/pull/35); field editor theo kit: [#51](https://github.com/ntgptit/memox-v8/pull/51), [#52](https://github.com/ntgptit/memox-v8/pull/52) | Chức năng xong; companion `test/visual_audit/` xong ở FE-D2. Còn: file chi tiết handoff cho màn 08–10 |
| FE-A3 | Cài đặt: mặc định học, theme, ngôn ngữ, reset về mặc định. Lưu theme và ngôn ngữ thay cho theme hệ thống đang cố định trong `app.dart` (UC-SETTINGS-001; BR-SETTINGS-005, BR-SETTINGS-006) | chưa bắt đầu | BE-A1 | M | `lib/app/app.dart` để `ThemeMode.system` tới khi feature settings lưu được lựa chọn; spec UI base §10 để việc lưu theme và ngôn ngữ ngoài phạm vi; [ui.md](features/settings/ui.md); backend sẵn: 8 use case trong `lib/features/settings/domain/usecases/` | Đọc màn 15, 23, 25, 26 trong kit, viết file chi tiết handoff, rồi lập plan. Câu chữ reset nêu cả nhắc học (dòng 108 của sổ nợ UI-base), và sau khi reset thì gọi `ReconcileReminderUseCase` ([spec gói 11a](superpowers/specs/2026-09-26-reminders-backend-design.md) §9) |
| FE-A4 | Xác nhận "Đặt lại tiến độ học" trên một root deck (UC-SRS-001) | xong | BE-A2, FE-A1 | S | [ui.md](features/srs/ui.md) | Màn 02 của screen handoff, phase D của FE-A11 (#42) |
```

Replace

```markdown
| FE-B4 | Thư viện starter: child flow trong Thư viện, kèm empty state khi chưa có deck (UC-STARTER-001) | chưa bắt đầu | BE-B4, FE-A1 | M | BE-B4 xong: hợp đồng cho UI ở §9 của [spec gói 10](superpowers/specs/2026-09-26-starter-decks-backend-design.md); [ui.md](features/starter-decks/ui.md) | Màn 03 trên 2 use case của `starter_decks`: `WatchStarterLibraryUseCase` cho `loading`, `list`, `none`, `loadFailed`; `AddStarterDeckUseCase` cho `adding`, `added` (Open tới `rootDeckId`), `alreadyPresent` (`alreadyInLibrary`), `secondCopy` (xác nhận rồi gọi lại với `allowSecondCopy`) và `addFailed`; sheet chọn scheduler chọn sẵn `suggestedScheduler`; tên ngôn ngữ lấy từ thẻ BCP 47; note "Development fixture" theo BR-STARTER-010 |
| FE-B5 | Nhắc học hằng ngày trong Cài đặt; chỉ xin quyền notification sau khi người dùng bật (UC-REMINDER-001; BR-REMINDER-011) | chưa bắt đầu | BE-B5, FE-A3 | S–M | [README reminders](features/reminders/README.md) | Sau BE-B5 |

```

with

```markdown
| FE-B4 | Thư viện starter: child flow trong Thư viện, kèm empty state khi chưa có deck (UC-STARTER-001) | chưa bắt đầu | BE-B4, FE-A1 | M | BE-B4 xong: hợp đồng cho UI ở §9 của [spec gói 10](superpowers/specs/2026-09-26-starter-decks-backend-design.md); [ui.md](features/starter-decks/ui.md) | Màn 03 trên 2 use case của `starter_decks`: `WatchStarterLibraryUseCase` cho `loading`, `list`, `none`, `loadFailed`; `AddStarterDeckUseCase` cho `adding`, `added` (Open tới `rootDeckId`), `alreadyPresent` (`alreadyInLibrary`), `secondCopy` (xác nhận rồi gọi lại với `allowSecondCopy`) và `addFailed`; sheet chọn scheduler chọn sẵn `suggestedScheduler`; tên ngôn ngữ lấy từ thẻ BCP 47; note "Development fixture" theo BR-STARTER-010 |
| FE-B5 | Nhắc học hằng ngày trong Cài đặt; chỉ xin quyền notification sau khi người dùng bật (UC-REMINDER-001; BR-REMINDER-011) | chưa bắt đầu | BE-B5a, BE-B5b, FE-A3 | S–M | [README reminders](features/reminders/README.md); hợp đồng sáu use case ở [spec gói 11a](superpowers/specs/2026-09-26-reminders-backend-design.md) §9 | Sau BE-B5b |

```

Replace

```markdown
4. FE-C1 sau khi có quyết định; FE-C5 khi mở lại phạm vi tablet.
5. Sau V8.0: FE-B1…FE-B5 theo thứ tự các hạng mục BE-B tương ứng. BE-B1 và BE-B2 xong
   trong gói 7 và gói 8, nên FE-B1 và FE-B2 không còn chờ backend; BE-B3…BE-B5 chưa bắt
   đầu.

```

with

```markdown
4. FE-C1 sau khi có quyết định; FE-C5 khi mở lại phạm vi tablet.
5. Sau V8.0: FE-B1…FE-B5 theo thứ tự các hạng mục BE-B tương ứng. BE-B1…BE-B4 đã xong,
   nên FE-B1…FE-B4 không còn chờ backend. BE-B5a xong trong gói 11a; FE-B5 còn chờ
   BE-B5b, adapter Android.

```

Run:

```bash
python3 tools/docs/generate.py
python3 tools/docs/check.py
```

Expected: `check.py` ends with `PASS — 0 error(s), 45 warning(s)`.

- [ ] **Step 3: Stage the task's files**

The gate asks every source under `lib/` to be in git, so the task is staged before it runs.

```bash
git add .claude/skills/flutter-workflow/scripts/verification_impact_map.json \
  docs/features/reminders/README.md \
  docs/features/reminders/usecases/UC-REMINDER-001-bat-nhac-hoc-hang-ngay.md \
  docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md \
  docs/wbs_BE.md \
  docs/wbs_FE.md \
  docs/_generated
git status --short
```

Expected: every path `git status --short` lists is staged: a letter in its first column, a space in its second.

- [ ] **Step 4: Run the gate**

Run:

```bash
bash .claude/skills/flutter-workflow/scripts/dod_check.sh
```

Expected: it ends with `✓ mechanical gates passed`. Among its steps:
`No issues found!`; `✓ generated code is fresh, complete and uncommitted`;
`✓ architecture boundaries clean`; `PASS — 0 error(s), 45 warning(s)` (the
warnings are older than this plan); the CI tooling tests `Ran 77 tests` and
`OK (skipped=8)` (eight of them need PowerShell 7); `204 passed` (the guard's
self-tests); `Code verification passed.`; `+1996: All tests passed!`.

- [ ] **Step 5: Commit**

```bash
git commit -F - <<'EOF'
docs(reminders): the package's documents

UC-REMINDER-001 names its six use cases and its scope (BE-B5a done, BE-B5b
the Android adapter, screen 24 FE-B5), with Given/When/Then in place of the
open question. The reminders README names its code and depends on settings,
and the CI impact map follows it. Row 108 of the UI-base register: FE-A3's
reset copy names the reminder (spec D4). wbs_BE.md splits BE-B5 into BE-B5a
(done) and BE-B5b, moves the notification dependency to BE-B5b with a device
blocker, closes the BR-SETTINGS-008 blocker, and counts 22/22 UC with tests
and 18 without Given/When/Then. wbs_FE.md: FE-A3 and FE-B5 point at spec
§9. docs/_generated.
EOF
```

Append the session's attribution trailers to the message when you commit.


## After the final review: the pull request

- [ ] **Step 1: Open the pull request**

Push `claude/be-reminders` and open its pull request against `master`, then subscribe to
its activity.

Expected: CI is paused during active development (root `README.md`, "CI"), so no check
runs on the pull request; it merges on the local gate.

- [ ] **Step 2: Merge**

Merge `master` into `claude/be-reminders` if it moved, run the gate once more on the
branch head, and squash-merge only while it ends with `✓ mechanical gates passed`. Then
unsubscribe from the pull request's activity.


## Plan self-review

- **Spec coverage.** D1: no task touches the schema, a dependency or a platform folder.
  D2, D3, D5, §5: Task 1, and Task 2 for the import map. D4: Task 8. D6, D7: Task 5. D8,
  §7's workload: Task 4. D9, D10, §7's order and digest: Task 2. D11, D12, §8: Task 3. D13,
  D14, D17: Task 6, and Task 5 for D14's "reconcile never asks". D15: Task 5. D16: Task 7.
  D18, §13: Task 8's WBS rows. §9's six use cases: Tasks 5–7. §10: every rule's holder is
  in a task above. §11: every line has its test in Tasks 1–7. §12: Tasks 1 and 8.
- **Placeholders.** None: every step carries its code or its command and its expected
  output.
- **Type consistency.** The Interfaces blocks name each signature once; the dry run
  compiled every task on top of the previous one.
- **Review Focus.** Each of the five lines has its test in the task that owns the code.

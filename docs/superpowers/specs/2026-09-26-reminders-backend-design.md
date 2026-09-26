# MemoX V8 — Daily reminder backend design (package 11a)

Status: approved 2026-09-26 · Path: architectural

## 1. Intent

Build the first half of BE-B5 of [`docs/wbs_BE.md`](../../wbs_BE.md), the daily study
reminder: UC-REMINDER-001 with BR-REMINDER-001…BR-REMINDER-012, and BR-SETTINGS-008's
reset now covering the reminder.

The owner split BE-B5 in two (2026-09-26):

- **11a, this package (BE-B5a):** every business rule that can be verified without a
  device. It covers the reminder settings, the local-time schedule, the workload read at
  fire time, the digest's content and order, the idempotent reconcile and the reset. The
  operating system is reached through a port, and the one adapter shipped here reports
  "unsupported". No dependency is added.
- **11b, later (BE-B5b):** the Android adapter behind that port, with the plugins, the
  manifest and gradle changes, the background entry point and the wiring at app start.
  It is done with or after FE-B5, when it can be tested on a device.

The package writes a new feature `lib/features/reminders/` (`domain/`, `data/`, `di/`) and
extends `lib/features/settings/`. Screen 24 of the kit ("Daily reminder") belongs to FE-B5
in [`docs/wbs_FE.md`](../../wbs_FE.md); §9 is its contract.

Success means:

- turning the reminder on asks for the permission only then. It schedules before it
  saves, so a refusal or a failure leaves the reminder off and nothing pending;
- turning it off, changing its time, a reset and a reconcile each leave `app_settings`
  and the pending reminder in agreement, or say exactly which half failed (E3, E4, E6);
- at fire time the workload is read again, and the reminder shows nothing when nothing is
  due. When something is due it shows one digest naming the most urgent root deck, that
  deck's due count and the number of other decks with cards due. It never fires twice on
  one local day, and never before the chosen time on the day it lands;
- every rule the package owns has a test that fails when it breaks, and the phased gate
  of the root `README.md` passes after every task.

## 2. Context (2026-09-26)

- `master` is at `5844ad3`. Every backend item before BE-B5 is done; BE-B4 merged in #77.
- **The use case.** UC-REMINDER-001 is `ready` with `code: []` and no Given/When/Then (an
  open question in the file). Its flows are:
  - main 1–5;
  - A1 change the time, A2 turn off, A3 nothing due at fire, A4 only new cards, A5
    reconcile at start or after a time-zone change, A6 dismiss;
  - E1 permission denied, E2 unsupported platform, E3 scheduling fails, E4 saving fails,
    E5 the workload read fails at fire, E6 cancelling fails when turning off, E7 the
    settings read fails on open.
- **The rules, in short.**
  - BR-001 to BR-003:
    - Off by default. Nothing is asked, scheduled or shown before the person turns it on
      (BR-001).
    - The time is a minute of the local day, 0…1439, default 1200, interpreted in the
      offset of the moment it is computed and never stored as UTC (BR-002).
    - A notification only when overdue + due today > 0, measured at fire time. Unlearned
      cards never count (BR-003).
  - BR-004 to BR-007:
    - At most one digest per local day, under one fixed id (BR-004).
    - Its content may name the most urgent root deck, the due count and the number of
      other decks, never card content. Logs carry reasons and counts only (BR-005).
    - "Most urgent" is a total order: overdue count, oldest overdue age in local day
      boundaries, due-today count, name, id (BR-006).
    - Counts are grouped by `deck.root_id`, each card once (BR-007).
  - BR-008 to BR-012:
    - A tap opens Study Home and writes nothing; a dismissal writes nothing (BR-008).
    - Inexact scheduling only, rescheduled on enable, time change, offset change and,
      where the platform needs it, reboot or update. Turning off cancels (BR-009).
    - Reconciling is idempotent: one pending reminder at most (BR-010).
    - The permission is asked only after the tap. A denial is a typed, recoverable state
      that stays off and is never asked again by itself (BR-011).
    - An unsupported platform reports it as a typed value, never crashes, and never
      pretends to be on. Business code and UI import no plugin type, check no platform
      and touch no platform IO (BR-012).
- **What exists.**
  - `app_settings` already holds the three reminder columns.
    - `reminder_enabled` is 0/1, default 0.
    - `reminder_minute_of_day` is 0…1439, default 1200, local.
    - `reminder_last_delivered_at` is a nullable UTC instant.
    - `schema.md` wants the last-delivered bookkeeping read together with the other two
      and written by its own one-column `UPDATE`, because the background writer must not
      overwrite a choice just changed. No schema change is needed.
  - The settings feature (package 1) is the only writer of `app_settings`. The rest of
    its surface:
    - `AppSettingsEntity{studyDefaults, theme, language}` with `defaults`;
    - `StudyOptions.check()`;
    - `SettingsRejection {cardLimitOutOfRange, deckNotFound, notARootDeck}`;
    - `resetToDefaults()`, which writes four values in one transaction. Its spec (D6) left
      the reminder columns "for the reminders sub-project to decide".
  - BR-SETTINGS-008 already says reset returns **all** values of `app_settings` to their
    defaults. Only UC-SETTINGS-001 A3 says "four".
  - `deckLevelOfRoots(start_of_today, now)` (`lib/core/database/queries/deck_queries.drift`)
    returns every root outside the Trash with the counts of its whole tree, grouped by
    `root_id`: `overdue_count`, `due_today_count` (learned cards only, split at
    `start_of_today`) and `oldest_due_at`. The Library's root level watches it, and
    Study Home reads it once (`StudyViewDao.rootDeckRows`, `.get()`).
  - The domain helpers already exist:
    - `DeckScheduleStatus.overdueDays(oldestDueAt, startOfToday)` counts local day
      boundaries on calendar dates (BR-STUDY-067);
    - `startOfLocalDay(now)` (srs domain);
    - `foldText` (`lib/core/text/`), which Study Home sorts names by;
    - `DayClock` (`lib/core/clock/`), which gives use cases their `now`.
  - The guard admits these suffixes under `domain/`: `_entity`, `_repository`,
    `_use_case`, `_scheduler`, `_mode`, `_failure`, `_model`. It bans `dio`,
    `connectivity_plus` and `flutter_secure_storage`.
  - The BR-TRASH-002 shape check scans every statement of `lib/` that reads `card` or
    `deck`.
- **The kit.**
  - Screen 24 "Daily reminder" (`ReminderScreenV3`) has these states: `off`, `turningOn`,
    `on`, `changingTime`, `permDenied` (a banner with "Open system settings" and "Try
    again"), `couldNotSchedule`, `unavailable`, `offMayShow` and `loading`. Its sample
    digest reads "86 cards are due in 한국어 TOPIK I · Từ vựng, and 2 other decks have
    cards waiting.".
  - Screen 23 "Settings" has a "Daily reminder" row (sub-line "Off") and a "Reset app
    options" row (sub-line "Theme, language, study defaults").
    - Its confirmation reads "Theme, language, cards per session and new-card order go
      back to their defaults.".
- **The platform.**
  - Android is the only release target, with a minimum SDK of 23. Web is a
    development-only target, and no plugin may break the Web build (ADR-001).
  - This container has no Android SDK, `dl.google.com` is blocked by its network policy,
    and there is no device. Nothing platform-side can be verified here, which is why the
    split was made.

## 3. Decisions

| # | Decision | Why |
|---|---|---|
| D1 | Scope: BE-B5a only. No dependency, no schema change, no migration, no Android or iOS file. | The owner's split (2026-09-26); §2 "The platform". |
| D2 | The settings feature owns every column of `app_settings`, the reminder's included. The reminders feature reads and writes them through `SettingsRepository`, and the import map gains `'reminders': {'settings', 'deck', 'srs'}`. | The owner's choice of approach A (2026-09-26). If reminders owned its own columns, settings' reset would need the reminder defaults from reminders while reminders needs `language` from settings: a cycle ADR-011 forbids. A separate table would contradict `schema.md`. |
| D3 | `Reset to defaults` returns six values in one transaction: the four of package 1, plus `reminder_enabled = 0` and `reminder_minute_of_day = 1200`. `reminder_last_delivered_at` is left as it is. UC-SETTINGS-001 A3 says six. This closes the question D6 of the settings spec left open. | The owner's decision (2026-09-26); BR-SETTINGS-008 already says "all values". Bookkeeping is not a person's choice (`schema.md`). A reminder still pending after a reset skips itself when it fires, because it reads "off". |
| D4 | The kit's reset copy (the dialog body and the row's sub-line) leaves the reminder out. FE-A3 names it. This is recorded as row 108 of the UI-base debt register (§9 of the UI-base spec). | A BR beats the kit (CLAUDE.md). Screen 23 has no detail file yet. |
| D5 | `recordReminderDelivered` writes `reminder_last_delivered_at` and nothing else, not even `updated_at`. | `schema.md`: the background writer must not overwrite a choice the person just changed, and bookkeeping is not an edit of the settings. |
| D6 | The operating system is reached through one domain contract, `ReminderPlatformRepository` (§6), which uses no plugin type. Its calls never throw: a platform error comes back as a typed `Rejected`. | BR-012; E3 ("a platform error maps to a typed reason"). The guard admits `_repository` as the suffix of a domain contract. |
| D7 | 11a ships `UnsupportedReminderPlatformRepositoryImpl` as the only adapter, on every platform. 11b replaces it on Android through a conditional import, and Web keeps it. | ADR-001 (no plugin may break the Web build); BR-012 (`unavailable`, never a toggle that does nothing). |
| D8 | The workload is read by the same statement as the Library's root level and Study Home (`deckLevelOfRoots`, `.get()`), so the number on the notification is the number Study Home shows when it is tapped. | BR-003's sets and BR-007's grouping are already in it (BR-STUDY-068), and so is BR-TRASH-002. No new statement is written. |
| D9 | The digest carries the most urgent root's name, **that root's** due count (overdue + due today of its tree) and the number of other roots with cards due. | The owner's decision (2026-09-26): the kit's sample sentence. BR-005's "tổng số thẻ đến hạn" is read as the root's total, grouped per BR-007. |
| D10 | Names sort by `foldText`, then by id, as in Study Home. | BR-006; the same text key as the app's other name orders. |
| D11 | `nextReminderAt` builds the instant from calendar fields in local time (`DateTime(y, m, d, h, min)`) and never adds 24 hours. It returns today's occurrence when that is still ahead and nothing was delivered today, and tomorrow's otherwise. | BR-002 (the offset is taken when computing); BR-004. Across a clock change a day is not 24 hours (BR-STUDY-074's lesson). |
| D12 | A fire counts as "today's reminder" only when the local time has reached the chosen minute. A fire before it is skipped and rescheduled: Android deferred it past midnight, or the person flew west. So is a fire on a day that already had its digest. | No notification at 00:30 for yesterday's reminder. The next fire lands on the chosen wall-clock time in the new offset (BR-002 edge case, BR-009). |
| D13 | Enable and change-time **schedule, then save**. If the save fails, they undo the schedule: cancel it, or re-schedule the old time, then throw the save's `Failure`. Disable **saves, then cancels**. | BR-011 and E3: "on" is never saved before the schedule exists. A leftover pending reminder is harmless, since it reads the settings at fire time. E6 describes exactly save-then-cancel. |
| D14 | The permission is asked only by Enable, after the minute and the capability were checked. Reconcile, change-time and deliver never ask. | BR-011; BR-001. |
| D15 | Reconcile is idempotent. It does nothing on an unsupported platform, schedules `nextReminderAt` when the reminder is on (replacing the pending one) and cancels when it is off. FE calls it at app start and after a successful reset, and 11b calls it wherever the platform needs (boot, time-zone change). | BR-009, BR-010, A5. Cancelling when off also clears what E6 or a reset left behind. |
| D16 | Deliver shows first and records the delivery second. Whenever it read the settings and found the reminder on, it reschedules with `nextReminderAt`. When the settings cannot be read it skips and does not reschedule: no reliable time exists, and the next reconcile restores the schedule. | BR-003, BR-004, E5. A failed show is not recorded, so it is not mistaken for a delivered day. |
| D17 | Changing the time while the reminder is off saves the minute and schedules nothing. | The kit shows the time inactive when off; saving it is the only sensible meaning if FE-B5 lets it be picked. |
| D18 | The notification plugins are chosen in 11b's spec, with the reason and the rollback. §13 records the candidates. | They can only be verified on a device (§2). The WBS blocker moves to BE-B5b. |

## 4. Structure

```
lib/features/reminders/
├── domain/
│   ├── models/        reminder_platform_model (ReminderCapability, ReminderPermission),
│   │                  reminder_status_model, reminder_digest_model (workload, order,
│   │                  digest), reminder_time_model (nextReminderAt, fire check),
│   │                  reminder_fire_report_model
│   ├── repositories/  reminder_platform_repository, reminder_workload_repository
│   ├── failures/      reminder_failure (enum ReminderRejection)
│   └── usecases/      watch_reminder, enable_reminder, disable_reminder,
│                      change_reminder_time, reconcile_reminder, deliver_reminder
├── data/
│   ├── datasources/   reminder_workload_dao (deckLevelOfRoots, .get())
│   ├── mappers/       reminder_workload_mapper
│   └── repositories/  reminder_workload_repository_impl,
│                      unsupported_reminder_platform_repository_impl
└── di/                reminder_workload_repository_provider,
                       reminder_platform_repository_provider
```

Outside the feature, in `lib/features/settings/`:

- `domain/models/`: `reminder_settings_model.dart` and `reminder_snapshot_model.dart`.
- `AppSettingsEntity.reminder`.
- The new reason `SettingsRejection.reminderMinuteOutOfRange`.
- Three `SettingsRepository` methods and the six-value reset.
- A one-shot row read in `SettingsDao`, and the mapper.

The import map gains D2's entry. There is no presentation layer: FE-B5 adds it, with the
use-case providers.

## 5. Settings: the reminder values

- `ReminderSettings{isEnabled, minuteOfDay}` has these members:
  - the bounds `minMinuteOfDay = 0` and `maxMinuteOfDay = 1439`, and
    `defaultMinuteOfDay = 1200`;
  - `defaults = (false, 1200)`;
  - `check()`, which returns `Rejected(SettingsRejection.reminderMinuteOutOfRange)`
    outside the bounds. It runs before the database is touched, as `StudyOptions.check()`
    does (BR-002).
- `AppSettingsEntity` gains `reminder`, and `AppSettingsEntity.defaults.reminder` is
  `ReminderSettings.defaults`: the defaults are defined once. `watchAppSettings()`
  therefore carries the reminder too, so screen 23's row can show "Off" or the time.
- `ReminderSnapshot{reminder, lastDeliveredAt, language}` holds what the schedule and the
  delivery need, read at one moment.
- `SettingsRepository` gains three methods:
  - `saveReminder({required ReminderSettings reminder})` →
    `Future<Outcome<void, SettingsRejection>>`. It runs in one transaction: `check()`,
    then `reminder_enabled`, `reminder_minute_of_day` and `updated_at`.
  - `reminderSnapshot()` → `Future<ReminderSnapshot>`. It is one `SELECT` of the row, and
    a database error leaves as its `Failure`.
  - `recordReminderDelivered({required DateTime at})` → `Future<void>`. It is an `UPDATE`
    of `reminder_last_delivered_at` only (D5).
- `resetToDefaults()` writes D3's six values from `AppSettingsEntity.defaults`, in its
  one transaction.

## 6. The platform port

```dart
abstract interface class ReminderPlatformRepository {
  Future<ReminderCapability> capability();            // supported | unsupported
  Future<ReminderPermission> requestPermission();     // granted | denied
  Future<Outcome<void, ReminderRejection>> schedule({required DateTime at});
  Future<Outcome<void, ReminderRejection>> cancel();
  Future<Outcome<void, ReminderRejection>> show({
    required ReminderDigest digest,
    required LanguageChoice language,
  });
}
```

Every implementation is held to this contract (11b's included):

- **No call throws.**
  - A platform error comes back as `Rejected` with the reason of the call: `schedule` →
    `couldNotSchedule`, `cancel` → `couldNotCancel`, `show` → `couldNotShow`.
  - A failure to ask for the permission comes back as `denied`, whose recovery ("open
    system settings, try again") fits it too.
- **`schedule`**
  - It is inexact, and no exact-alarm permission is declared (BR-009).
  - It replaces the pending reminder, since one fixed alarm id means at most one is ever
    pending (BR-010).
  - `at` is an instant computed in local time (§8).
- **`cancel`** removes the pending reminder and the shown notification. Cancelling
  nothing is `Ok`.
- **`show`**
  - It posts under one fixed notification id, which replaces yesterday's (BR-004).
  - Its text is built from the digest alone, in `language` (`system` resolves as the app
    does).
  - A tap opens Study Home (BR-008; 11b and FE-B5).
- **`requestPermission`** asks only when called. Where no permission exists (Android
  below 13) it is `granted` at once.
- **The reasons:** `ReminderRejection { unsupported, permissionDenied, minuteOutOfRange,
  couldNotSchedule, couldNotCancel, couldNotShow }`. `couldNotShow` only ever reaches the
  fire report (§9).
- **In 11a**, `UnsupportedReminderPlatformRepositoryImpl` behaves as follows:
  - `capability()` is `unsupported`;
  - `requestPermission()` is `denied`;
  - every other call is `Rejected(unsupported)`.

## 7. Workload, order and digest

- **The workload.** `ReminderWorkloadRepository.rootWorkloads({required DateTime now,
  required DateTime startOfToday})` → `Future<List<ReminderDeckWorkload>>`.
  - It reads D8's statement once. A database error leaves as its `Failure`.
  - Each root becomes `ReminderDeckWorkload{deckId, name, overdueCount, overdueDays,
    dueTodayCount}`, with `overdueDays = DeckScheduleStatus.overdueDays(oldestDueAt,
    startOfToday)` and `dueCount = overdueCount + dueTodayCount`.
- **The order.** `compareReminderDecks` sorts by:
  1. `overdueCount`, descending;
  2. `overdueDays`, descending;
  3. `dueTodayCount`, descending;
  4. `foldText(name)`, ascending;
  5. `deckId`, ascending.

  This is BR-006's total order, and no two roots tie.
- **The digest.** `reminderDigestOf(workloads)` → `ReminderDigest?`.
  - It is null when no root has `dueCount > 0` (BR-003, A3, A4).
  - Otherwise it is `ReminderDigest{deckName, dueCount, otherDeckCount}`: the first root
    in that order among the roots with `dueCount > 0`, its `dueCount`, and how many other
    roots have `dueCount > 0` (D9).

## 8. Time: the next fire and the fire check

Both functions are pure, in the reminders domain. Each takes `now` and `lastDeliveredAt`
through `toLocal()`, so a UTC value read from the database compares correctly.

- **`nextReminderAt({required DateTime now, required int minuteOfDay, DateTime?
  lastDeliveredAt})`** applies D11.
  - "Delivered today" means `lastDeliveredAt` falls on `now`'s local date.
  - An occurrence equal to `now` is not ahead, so the next one is tomorrow's.
- **`reminderFireCheckOf({required ReminderSettings reminder, DateTime? lastDeliveredAt,
  required DateTime now})`** → `ReminderFireCheck`. The checks run in this order:
  1. `disabled` when the reminder is off;
  2. `beforeReminderTime` when `now.hour * 60 + now.minute < minuteOfDay` (D12);
  3. `alreadyDeliveredToday` when something was delivered on `now`'s local date;
  4. `due` otherwise.

## 9. Use cases and the contracts for FE-B5, FE-A3 and 11b

Every use case takes its `now` from `DayClock`. None opens a transaction, and each is a
plain class, so 11b's background entry point can build it without Riverpod.

| Use case | Signature | Kit states |
|---|---|---|
| `WatchReminderUseCase` | `Stream<ReminderStatus> call()` | `loading` (no value yet), `off`, `on`, `unavailable` (`capability` unsupported), E7 (a `Failure` on the stream) |
| `EnableReminderUseCase` | `Future<Outcome<DateTime, ReminderRejection>> call({required int minuteOfDay})` | `turningOn`, `on` (`Ok(nextAt)`), `permDenied`, `couldNotSchedule`, `unavailable`; a `Failure` is E4 |
| `DisableReminderUseCase` | `Future<Outcome<void, ReminderRejection>> call()` | `off` (`Ok`), `offMayShow` (`couldNotCancel`, **settings already off**); a `Failure` is E4 |
| `ChangeReminderTimeUseCase` | `Future<Outcome<DateTime?, ReminderRejection>> call({required int minuteOfDay})` | `changingTime`, `on` (`Ok(nextAt)`), `couldNotSchedule`; `Ok(null)` when off (D17); a `Failure` is E4 |
| `ReconcileReminderUseCase` | `Future<Outcome<DateTime?, ReminderRejection>> call()` | none: app start, after a reset, 11b's platform events |
| `DeliverReminderUseCase` | `Future<ReminderFireReport> call()` | none: 11b's background callback |

- **Watch.** `ReminderStatus{capability, reminder}`: the capability is read once, and
  the reminder follows `watchAppSettings()`.
- **Enable.** The steps run in this order:
  1. `check()` the minute; out of range is `minuteOutOfRange`.
  2. The capability; unsupported is `unsupported`.
  3. `requestPermission()`; denied is `permissionDenied`, with nothing saved or
     scheduled (E1).
  4. `reminderSnapshot()` for `lastDeliveredAt`.
  5. `schedule(nextReminderAt(...))`; a refusal is `couldNotSchedule`, with nothing saved
     (E3).
  6. `saveReminder(on, minute)`. If it fails, `cancel()` and rethrow the `Failure` (E4).
  7. `Ok(nextAt)`.
- **Disable.**
  1. `reminderSnapshot()`.
  2. If the reminder is on, `saveReminder(off, same minute)`. A `Failure` leaves as it is,
     with nothing cancelled.
  3. On an unsupported platform, `Ok`.
  4. `cancel()`; a refusal is `couldNotCancel`, with the settings already off (E6). "Try
     again" calls Disable again, which writes nothing and cancels.
  5. `Ok`.
- **Change time.**
  1. `check()` the minute.
  2. `reminderSnapshot()`. When the reminder is off or the platform is unsupported, save
     the new minute with the on/off state unchanged and return `Ok(null)`.
  3. `schedule(nextReminderAt(new minute))`; a refusal is `couldNotSchedule`, with the
     old time and the old schedule kept.
  4. `saveReminder(on, new minute)`. If it fails, re-schedule at the old minute (best
     effort) and rethrow.
  5. `Ok(nextAt)`.
- **Reconcile.** D15; it never asks for the permission. The result is `Ok(nextAt)` when
  it scheduled, `Ok(null)` when the reminder is off or the platform is unsupported, and
  `couldNotSchedule` or `couldNotCancel` when the platform refused. A settings read that
  fails leaves as its `Failure`.
- **Deliver.**
  1. The capability; unsupported ends here.
  2. `reminderSnapshot()`. A `Failure` means `settingsUnreadable`, with no reschedule
     (D16).
  3. `reminderFireCheckOf`. Anything but `due` is reported and rescheduled with
     `nextReminderAt`; `disabled` is not rescheduled.
  4. `rootWorkloads(now, startOfLocalDay(now))`. A `Failure` means `workloadUnreadable`,
     then a reschedule (E5).
  5. `reminderDigestOf`. Null means `nothingDue`, then a reschedule (A3, A4).
  6. `show(digest, language)`. A refusal means `couldNotShow`, with nothing recorded,
     then a reschedule.
  7. `recordReminderDelivered(now)`. A `Failure` is noted in the report, and the
     reschedule still uses `now` as the delivery, so it goes to tomorrow.
  8. `schedule(nextReminderAt(...))`. A refusal leaves `nextAt` null.
- **The report.** `ReminderFireReport{outcome, dueCount, otherDeckCount, isRecorded,
  nextAt}`, with `ReminderFireOutcome { delivered, unsupported, settingsUnreadable,
  disabled, beforeReminderTime, alreadyDeliveredToday, workloadUnreadable, nothingDue,
  couldNotShow }`.
  - The two counts are 0 unless the reminder was delivered. `isRecorded` is true only
    when a delivery was recorded. `nextAt` is null when nothing was rescheduled
    (`unsupported`, `settingsUnreadable`, `disabled`) or the platform refused the
    schedule.
  - The report has no text field, so a log line built from it cannot carry a deck name
    (BR-005).
- **For FE-A3.**
  - Call `ReconcileReminderUseCase` after a successful `Reset to defaults`.
  - Name the daily reminder in the reset copy (D4).
- **For FE-B5.**
  - The screen watches `ReminderStatus`. `permDenied`, `couldNotSchedule` and `offMayShow`
    are the results above, held in the controller rather than stored.
  - "Try again" on `permDenied` calls Enable again, which is the person's tap (BR-011).
- **For 11b.**
  - The adapter follows §6, and Deliver runs in the background callback.
  - Reconcile runs at app start, after boot where the plugin does not restore the alarm
    itself, and on a time-zone change.
  - The background isolate opens the database through the app's single connection site
    (the guard's `single_database_connection_site`).

## 10. The rules, where each is held

| Rule | Held by |
|---|---|
| BR-REMINDER-001 | `ReminderSettings.defaults` and the column default. Only Enable asks or schedules on a person's tap (D14). |
| BR-REMINDER-002 | `ReminderSettings.check()` and the column's `CHECK`; §8's local-time functions (D11). |
| BR-REMINDER-003 | Deliver reads the workload at fire time. D8's statement counts learned cards only, and `reminderDigestOf` is null at zero. |
| BR-REMINDER-004 | The fixed ids of §6; `alreadyDeliveredToday`; `nextReminderAt` skips a delivered day. |
| BR-REMINDER-005 | `ReminderDigest` holds a name and two counts. The report holds no text, and 11a logs nothing. |
| BR-REMINDER-006 | `compareReminderDecks` (D10). |
| BR-REMINDER-007 | D8's statement groups by `root_id`; there is no `COALESCE(parent_id, id)`. |
| BR-REMINDER-008 | No 11a API writes on a tap or a dismissal. The tap's route is 11b's and FE-B5's. |
| BR-REMINDER-009 | §6's inexact `schedule`; the reschedule on enable, change-time, fire and reconcile; D12 for an offset change between two fires; boot is 11b's. |
| BR-REMINDER-010 | `schedule` replaces the pending reminder, and Reconcile is idempotent (D15). |
| BR-REMINDER-011 | D13 and D14. A denial saves nothing, schedules nothing and is never repeated by the app. |
| BR-REMINDER-012 | D6 and D7: the typed capability, the unsupported adapter, and no plugin type in the domain. |
| BR-SETTINGS-008 | D3. |
| BR-STUDY-067 | `overdueDays` from `DeckScheduleStatus` (§7). |

## 11. Tests

| Layer | What |
|---|---|
| Settings domain | `ReminderSettings.check()` at -1, 0, 1439 and 1440; `AppSettingsEntity.defaults.reminder` |
| Settings repository (Drift in memory) | `saveReminder` writes both columns and refuses out of range without writing; `reminderSnapshot` reads the three values and the language in one go; `recordReminderDelivered` changes `reminder_last_delivered_at` alone (`updated_at` and a minute saved just before stay); reset returns the six values and keeps `reminder_last_delivered_at`; `watchAppSettings` carries the reminder |
| Reminders domain | `compareReminderDecks` on each key, the folded name, then the id; `reminderDigestOf` at zero, the top root's own count and the count of other roots; `nextReminderAt` ahead, equal, passed, delivered today, month and year ends, calendar-field construction (run once more with `TZ=Europe/Berlin` across a clock change); `reminderFireCheckOf` at the minute, one minute before, after midnight, and on a delivered day |
| Workload (Drift in memory) | sub-decks count once, under their root; the Trash is left out; unlearned cards are left out; overdue and due today split at the start of the day; `overdueDays` counted on calendar dates |
| Use cases (fake platform with one pending slot and one shown slot, recording each call) | every path of §9: E1–E6, A1–A5, D13's order and compensations, D14 (no permission request outside Enable), D15 (reconciling twice leaves one pending), D16, D17; the fire report of each outcome |
| Architecture | the import map entry; the guard (no plugin import, the suffixes) |

A mutation sweep follows, as in the packages before: each rule of §10 broken on purpose
must fail a test.

## 12. Documents

- **UC-REMINDER-001:**
  - `code`;
  - the scope line: 11a done, 11b the adapter, screen 24 FE-B5;
  - Given/When/Then for main 2–4, A1–A5 and E1–E7 at the use-case level, in place of the
    open question.
- **UC-SETTINGS-001 A3:** six values (D3).
- **The reminders README:**
  - `code`;
  - `depends_on` gains `settings`;
  - the scope;
  - the open question on missing code is removed.
- **The settings README:** its out-of-scope row says the settings feature stores the
  reminder's values.
- **UI-base debt register, row 108:** D4.
- **`docs/wbs_BE.md`:**
  - BE-B5 becomes BE-B5a (done, with its evidence) and BE-B5b (the adapter, the plugins
    with reason and rollback, the manifest and gradle changes, the background entry point,
    the app-start wiring, and the device test);
  - the notification-dependency blocker moves to BE-B5b, and a device or Android SDK
    blocker is added there;
  - the BR-SETTINGS-008 blocker closes;
  - traceability is 22/22 UC, and BE-D4 counts 18 UC.
- **`docs/wbs_FE.md`:** FE-A3 (row 108, reconcile after a reset) and FE-B5 (depends on
  BE-B5b; §9).
- **`docs/_generated`:** regenerated.

## 13. Out of scope

- **11b (BE-B5b):**
  - the Android adapter and its plugins;
  - `AndroidManifest.xml` (`POST_NOTIFICATIONS`, the boot receiver) and gradle
    (desugaring);
  - the background entry point, and the app-start reconcile;
  - the tap route to Study Home;
  - the device test.

  The candidates, to be decided in 11b's spec with the reason and the rollback, are
  `android_alarm_manager_plus` (inexact `oneShotAt`, `allowWhileIdle`,
  `rescheduleOnReboot`, a Dart callback) and `flutter_local_notifications` (show with a
  fixed id, the tap payload). Web keeps D7's adapter.
- **FE-B5 and FE-A3:** screen 24, the copy of the digest in two languages, and the Settings
  rows.
- **A permission revoked while the reminder is on:** the kit has no state for it, and 11b
  may revisit it with the real adapter. A fire in that state ends in `couldNotShow`.
- **iOS** (ADR-001).

## 14. Risks and rollback

- **The port meets the real plugins only in 11b.** The use-case tests pin behaviour, not
  plugin calls, and every operation of §6 exists in the candidate stack. If 11b needs
  another shape, it changes the port and the one adapter; the use cases keep their tests.
- **Deferred alarms.** D12 keeps a late fire from showing after midnight. A fire deferred
  within the same day still shows, late.
- **Rollback.** The package adds a feature and extends settings. Reverting the merge
  removes them.
  - The reminder columns keep whatever they hold. With the unsupported adapter, nothing
    was ever scheduled or shown.
  - The reset returns to four values.

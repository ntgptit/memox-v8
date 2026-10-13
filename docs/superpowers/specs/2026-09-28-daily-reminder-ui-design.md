# FE-B5: the Daily reminder UI — design

Status: approved 2026-09-28 ·
Path: architectural · Owner rulings 2026-09-28 (§3): D1, D2

## 1. Intent

The daily reminder has its logic (BE-B5a,
[spec](2026-09-26-reminders-backend-design.md)) and its Android adapter on the host
(BE-B5b, gate, background entry point, tap to Study Home, reconcile at start). Nobody can
turn it on: screen 24 is not built and screen 23 has no Daily reminder row. FE-B5 puts
UC-REMINDER-001 on screen:

- **Screen 24 "Daily reminder":** the toggle, the time, the privacy line, and every
  outcome of Enable, Disable and Change time.
- **Screen 23 "Settings":** the Daily reminder row in the App section, the reset copy that
  names the reminder, and a reconcile after a reset (FE-A3 D4, UI-base register row 123).

Success means three things:

- every state of kit 24 is built from `Mx*` widgets, or is recorded as a deviation with
  its reason;
- each UC-REMINDER-001 flow the screen owns (main 1–3, A1, A2, E1–E4, E6, E7) has a test;
- no reminder operation started on the screen runs while another one runs (reminders
  spec §14).

What is not in FE-B5: the on-device check of main 4–5 and A6 (a fire, a tap, a reboot),
which stays with BE-B5b.

## 2. Context (2026-09-28)

- **Use cases** (`lib/features/reminders/domain/usecases/`): `WatchReminderUseCase`,
  `EnableReminderUseCase`, `DisableReminderUseCase`, `ChangeReminderTimeUseCase`,
  `ReconcileReminderUseCase`, `DeliverReminderUseCase`. Their results and the kit states
  they map to are in §9 of the backend spec.
- **The gate:** `reminderOperationGateProvider` (keep-alive) runs this isolate's reminder
  operations one at a time. `reconcileReminderProvider` already goes through it; the app
  reconciles at start and on resume (`lib/app/app.dart`).
- **Stored reminder:** `AppSettingsEntity.reminder` (`ReminderSettings`: on/off and the
  minute of the day). Reset returns it to off at 20:00 (BR-SETTINGS-008).
- **Imports:** `reminders → settings` exists, so `settings` may not import `reminders`
  (the feature import map is acyclic, `test/architecture/boundary_rules.dart`).
- **Widgets on hand:** `MxSection` (with `note`), `MxSettingsRow` (`trailing` takes "a
  toggle, a time button or a value"; `subtitle` is text only), `MxToggle`, `MxNote`,
  `MxInlineBanner` (`warning`, `danger`), `MxSpinner`, `MxStepper` (hold to repeat, tap to
  type), `MxDialog`, `MxErrorState`, `MxSkeletonList`, `showMxSnackbar`.
- **Kit 24** (`ReminderScreenV3`): nine states — off, turningOn, on, changingTime,
  permDenied, couldNotSchedule, unavailable, offMayShow, loading.

## 3. Decisions

| # | Decision | Why |
|---|---|---|
| D1 | `permDenied` shows the kit's guidance and **Try again** only; the kit's "Open system settings" is hidden | Owner 2026-09-28. The port has no such operation and `flutter_local_notifications` 22 has no API for it; adding one needs a package or native code that cannot be built in the container. BR-REMINDER-011 asks for the way back in system settings and a retry, which the guidance and Try again give. A control without its feature is hidden (screen handoff rule). New item FE-B6 adds the button with the device check. **Closed by FE-B6 (2026-09-28):** `ReminderPlatformRepository.openNotificationSettings` over a `MainActivity` method channel; the banner shows the kit's two actions |
| D2 | The time dialog is `MxDialog` with two `MxStepper`s, hour 0–23 and minute 0–59 | Owner 2026-09-28: no new component; the stepper already repeats on hold and takes typed digits |
| D3 | The stream of `WatchReminderUseCase` is the data; `ReminderController` holds only the operation in flight and the last outcome | Backend spec §9 ("held in the controller rather than stored"); a re-emitted stream must not clear a `permDenied` banner (flutter-state-riverpod: data apart from task status) |
| D4 | Enable, Disable and Change time go through `reminderOperationGateProvider`, and the screen starts no operation while one is in flight | Reminders spec §14; the controls are disabled while an operation runs |
| D5 | Route `/settings/reminder`, a child of the Settings branch like Theme and Language | `navigation.md` places the reminder under Settings |
| D6 | Screen 23's row reads `AppSettingsEntity.reminder`: "Off", or "On · {time}" | The entity already carries it; no import of `reminders` from `settings` |
| D7 | `SettingsScreen` takes `resetAppOptions`, the reset as `app/` composes it: the reminders feature's `resetAppOptionsProvider`, which resets the settings and reconciles the reminder in one turn of the gate (amended by DEV-218; before it, the screen called `onAppOptionsReset` after the reset, and `app/` reconciled outside the gate) | Backend spec §9 "For FE-A3"; `app/` composes the two features, as it already reconciles at start |
| D8 | `offMayShow` is a `warning` `MxInlineBanner` with the kit's sentence and **Try again** (Disable again) | UC-REMINDER-001 E6 asks for a retry; the kit draws a Note, which takes no action. `MxInlineBanner` has no info tone, and a reminder that may still appear is a mild warning |
| D9 | Times show as 24-hour `HH:mm` in English and Vietnamese | The kit draws "20:00"; BR-REMINDER-002 stores a minute of the local day |
| D10 | Loading draws `MxSkeletonList`, not skeleton sub-lines inside the rows | `MxSettingsRow.subtitle` is text; UI-base ruling O3 (one list skeleton shape), as on screen 13 |

## 4. Structure

```
lib/features/reminders/presentation/
  controllers/reminder_controller.dart        # operation in flight + last outcome
  states/reminder_action_state.dart           # sealed: idle, busy(op), permDenied, couldNotSchedule, offMayShow
  providers/watch_reminder_provider.dart      # stream of ReminderStatus
  providers/reminder_operations_provider.dart # enable/disable/changeTime through the gate
  screens/reminder_screen.dart                # screen 24
  widgets/sections/reminder_settings_section_widget.dart
  widgets/sections/reminder_banners_widget.dart
  widgets/sections/reminder_preview_section_widget.dart
  widgets/overlays/reminder_time_dialog_widget.dart
lib/features/settings/presentation/
  widgets/sections/settings_app_section_widget.dart   # + Daily reminder row
  screens/settings_screen.dart                         # + onOpenReminder, onAppOptionsReset
lib/app/router/                                        # route + wiring
```

The file names follow the existing presentation folders; the plan may merge a widget file
that turns out to be a few lines.

## 5. Behaviour

### 5.1 Screen 24 states

| State | Source | Drawn |
|---|---|---|
| loading | stream has no value | App bar "Daily reminder", `MxSkeletonList` (D10) |
| off | `capability` supported, reminder off, idle | Section with note "Fires once a day, only when cards are due. Never for new cards, never twice."; row bell "Daily reminder", sub "Off · nothing is scheduled", `MxToggle` off; row clock "Time", sub "Turn the reminder on to choose a time", disabled, time button "20:00" dimmed; section "What it says" with the kit's sample sentence and its sub-line |
| turningOn | controller `busy(enable)` | Toggle replaced by `MxSpinner`; time row disabled |
| on | reminder on, idle | Sub "One notification a day at the time below"; toggle on; time row enabled, sub "Local time · stays the same if you travel", time button "{HH:mm}" |
| changingTime | dialog open, or `busy(changeTime)` | Time button outlined while the dialog is open; a spinner in the time button while the change is saved |
| permDenied | last outcome `permissionDenied` | Toggle off, sub "Off · notification permission was refused"; `warning` banner "Notifications are blocked for MemoX" / "Allow them in Android Settings › Apps › MemoX › Notifications, then turn the reminder on again." / Open system settings, Try again (FE-B6; D1 closed) |
| couldNotSchedule | last outcome `couldNotSchedule` | `danger` banner "Couldn't schedule the reminder. It stays off. Try turning it on again." / Retry |
| offMayShow | last outcome `couldNotCancel` from Disable | `warning` banner "Turned off. A reminder already scheduled for today may still appear once." / Try again (D8) |
| unavailable | `capability` unsupported | One section, row bell-off "Reminders are not available on this device", sub "This build cannot deliver notifications. Nothing to turn on here."; no toggle, no time, no preview (BR-REMINDER-012) |
| read error (E7) | stream error | `MxErrorState` "Couldn't read the reminder setting" / "Nothing was changed. Try reading it again." / Retry (re-subscribes) |

- **Enable** (toggle on, or Try again / Retry after `permDenied` / `couldNotSchedule`):
  `busy(enable)`, then Enable with the stored minute. `Ok` → idle; a rejection → its
  state; a `Failure` → idle and the E4 snackbar. The permission is asked for only here
  (BR-REMINDER-011).
- **Disable** (toggle off, or Try again after `offMayShow`): `busy(disable)`, then
  Disable. `Ok` → idle; `couldNotCancel` → `offMayShow`; a `Failure` → idle and the E4
  snackbar. No confirmation (A2).
- **Change time** (time button while on): the dialog opens on the stored time. Cancel
  changes nothing. Save calls Change time with `hour * 60 + minute`; `Ok` → idle;
  `couldNotSchedule` → its banner, the old time kept; a `Failure` → the E4 snackbar.
- A new operation clears the previous outcome. While `busy`, the toggle, the time button
  and every banner action are disabled (D4).
- **E4:** snackbar "Couldn't save the reminder. Nothing changed." with Retry, which
  repeats the same operation; the screen shows the stored values, since the stream never
  changed.

### 5.2 The time dialog

`MxDialog` titled "Reminder time", content two `MxStepper`s labelled "Hour" and "Minute",
bounds 0–23 and 0–59 (the button at a bound gets a null callback), each typeable
(`onValueSubmitted`, two digits, out-of-range input marks the stepper invalid and keeps
Save disabled); a line under them reads the chosen time "{HH:mm}". Actions Cancel and
Save. The dialog returns the minute of the day, or null.

### 5.3 Screen 23

- **Row:** App section, after Language: bell "Daily reminder", sub "Off" or
  "On · {HH:mm}" (D6), opens `/settings/reminder`.
- **Reset copy:** the row's sub-line becomes "Theme, language, study defaults, reminder";
  the dialog body becomes "Theme, language, cards per session, new-card order and the
  daily reminder (off, 20:00) go back to their defaults." (en and vi). Register row 123
  closes.
- **Reset:** the dialog runs `resetAppOptions`, which `app/` supplies (D7); the reconcile
  is part of it, not a step after it.

## 6. Errors

- No error text carries a table, a path, an id or a plugin message (BR-CORE-005).
- A `Failure` from Enable, Disable or Change time is E4; a stream error is E7. A
  rejection is never shown as a `Failure`, and the reverse.
- Reconcile after a reset reports nothing on screen: a refusal is retried at the next
  start or resume, as today.

## 7. Tests

- **Controller** (fake use cases): each outcome to its state; a new operation clears the
  last outcome; a second operation is refused while one runs; a stream re-emission keeps
  the outcome.
- **Widget** (`ProviderScope` with fakes, English): every row of §5.1; Enable only asks
  for the permission on the toggle (a counter on the fake port); Try again after
  `permDenied` calls Enable; Try again after `offMayShow` calls Disable; the dialog's
  Cancel changes nothing and Save passes the minute; E4 snackbar and Retry; E7 and Retry;
  controls disabled while busy.
- **Goldens,** light and dark: off, turningOn, on, changingTime (dialog open), permDenied,
  couldNotSchedule, offMayShow, unavailable, loading, read error, and on at text scale 2.
  Written on this Linux host after the existing goldens are shown to pass unchanged on it
  (as for screen 13 on 2026-09-28).
- **Visual audit** companion in `test/visual_audit/`.
- **Screen 23:** the row's two sub-lines and its route; reset calls `onAppOptionsReset`
  once on success and not on failure; the new reset copy.
- **IT:** `shared/testing/host-coverage-map.md` traces no scenario to UC-REMINDER-001
  today; FE-B5 adds none, and the acceptance criteria of the UC are the test list.
- **Gate:** `dod_check.sh` in full.

## 8. Documents

- `docs/shared/ui/screen-handoff/24-daily-reminder.md` (new): layout, states with images,
  deviations (D1, D8, D10, and the E4/E7 states the kit does not draw), copy, a11y.
- Index row 24 → `aligned`; checklist rows of screen 24; UI-base register row 123 closed.
- `docs/features/reminders/ui.md` (new, as `settings/ui.md`); UC-REMINDER-001's code list
  gains the screen and the controller.
- `navigation.md`: the reminder route.
- `wbs_FE.md`: FE-B5 `xong` for the host part; new FE-B6 (D1's button, with the device
  check). `wbs_BE.md`: BE-B5b's device check also covers screen 24 on a device.

## 9. Plans

One plan: the controller and providers, then screen 24 state by state, then screen 23,
then goldens and documents.

## 10. Out of scope

- Opening the system notification settings (FE-B6).
- Any change to the use cases, the port, the adapter or the schema.
- Tablet layouts (FE-C5).

## 11. Risks and rollback

- **The Android permission dialog cannot be seen in the container.** Widget tests pin that
  the permission is requested only through Enable; the dialog itself is part of BE-B5b's
  device check.
- **Reset and reconcile race an Enable** on screen 24: both go through the gate, so they
  run one after the other.
- **Rollback:** revert the merge. The stored reminder keeps its value; with the row gone,
  nobody can change it, and reconcile at start keeps the pending alarm in step.

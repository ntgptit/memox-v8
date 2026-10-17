<!-- Hand-written screen record. -->

# 24 · Daily reminder

The daily reminder: turn it on or off, choose its time, and see what the notification
says. The stored reminder comes from `app_settings`; what the last operation left (a
refused permission, a refused schedule, a cancel that failed) is held by the screen only.
UC-REMINDER-001; spec
[2026-09-28-daily-reminder-ui-design.md](../../../superpowers/specs/2026-09-28-daily-reminder-ui-design.md)
(FE-B5).

## Entry points

- Screen 23 (the hub), App section, row "Daily reminder" ("Off" or "On · {HH:mm}"). Route
  `/settings/reminder`, on the root navigator like Theme and Language; Back returns to 23.

## Layout

| Region | Widget | Design |
|---|---|---|
| App bar | `MxAppBar` + back `MxIconButton` | "Daily reminder". |
| Reminder section | `MxSection` with note, two `MxSettingsRow`s | Row bell "Daily reminder" with `MxToggle` (an `MxSpinner` while turning on or off); row clock "Time" with a small `MxButton` "{HH:mm}", disabled while off. The note: "Fires once a day, only when cards are due. Never for new cards, never twice." |
| Banner | `MxInlineBanner` | Only after an operation left a problem: E1 `warning`, E3 `danger`, E6 `warning`. |
| What it says | `MxSection` "What it says", one `MxSettingsRow` | The notification's own sentence, from the strings the notification uses, over the live workload read when the screen opens (`ReadReminderPreviewUseCase` behind `reminderPreviewDigestProvider`); "Nothing is due right now, so today's reminder would stay silent." when nothing is due or the read fails (critique 2026-09-30 part 1); while the read runs the row keeps its place with its hint and shows no error; the line that it never carries a card, a tag or history. |
| Time dialog | `MxDialog` + two `MxStepper`s + `MxSheetActions` | "Reminder time": Hour 0–23, Minute 0–59 shown in two digits ("07" : "05"; hold repeats, tap to type), the chosen "HH:mm", Cancel / Save. |

## States

| State | Golden (light) | Golden (dark) | App |
|---|---|---|---|
| off | `reminder_off_light.png` | `reminder_off_dark.png` | The toggle off; the time row explains how to choose a time. |
| turningOn | `reminder_turning_on_light.png` | `reminder_turning_on_dark.png` | The toggle is a spinner while Enable asks for the permission, schedules and saves; nothing else can start. Golden `reminder_turning_on_*`. |
| on | `reminder_on_light.png` | `reminder_on_dark.png` | The toggle on, the time button and what the notification says (nothing is due in the fixture). |
| previewDue | `reminder_preview_due_light.png` | `reminder_preview_due_dark.png` | Three cards due in Korean: the live sentence (critique 2026-09-30 part 1). |
| changingTime | `reminder_changing_time_light.png` | `reminder_changing_time_dark.png` | The time button is outlined while the dialog is open; the dialog is `MxDialog` with Hour and Minute steppers (see Rulings). |
| permDenied | `reminder_perm_denied_light.png` | `reminder_perm_denied_dark.png` | Try again (outlined), then "Open system settings" (primary, last as every banner's primary; R5 amends FE-B6), which opens the app's notification settings. While Try again runs the banner steps aside and returns in the same order. |
| couldNotSchedule | `reminder_could_not_schedule_light.png` | `reminder_could_not_schedule_dark.png` | On Enable the reminder stays off. A refused schedule on Change time has its own copy (see Rulings). |
| offMayShow | `reminder_off_may_show_light.png` | `reminder_off_may_show_dark.png` | A `warning` banner with Try again (see Rulings). |
| couldNotChangeTime | — | — | (UC-REMINDER-001 E3 on Change time) the reminder stays on at its stored time; a `danger` banner "Couldn't change the time." / "The reminder stays at {HH:mm}." with Retry. No golden; the widget test `reminder_screen_test.dart::couldNotChangeTime: the old time stands, the banner names it (E3)` renders it. |
| savingTime | — | — | After Save in the time dialog the time button spins (`isLoading`) while Change time runs; the toggle and the button are disabled (spec D4). Code read: `reminder_settings_section_widget.dart`; no golden. |
| turningOff | — | — | The toggle is a spinner while Disable cancels and saves; nothing else can start. Code read: `isTurning` covers `turnOff`; the golden `reminder_turning_on_*` shows the same spinner for Enable. |
| unavailable | `reminder_unavailable_light.png` | `reminder_unavailable_dark.png` | One row, no toggle, no time, no preview (BR-REMINDER-012). Golden `reminder_unavailable_*`. |
| loading | `reminder_loading_light.png` | `reminder_loading_dark.png` | `MxSkeletonList` rows. |

Built from UC-REMINDER-001:

- **E4, a save that failed:** snackbar "Couldn't save the reminder. Nothing changed." with
  Retry; the rows keep the stored values.
- **E7, a read that failed:** `MxErrorState` "Couldn't read the reminder setting" /
  "Nothing was changed. Try reading it again." / Retry, in place of every row. Golden
  `reminder_read_error_*`.

**Built (FE-B5):** `ReminderScreen` over `reminderStatusProvider` (the stream of
`WatchReminderUseCase`) and `ReminderController` (Enable, Disable and Change time, each
through `reminderOperationGateProvider`, one at a time). Tests:
`test/features/reminders/presentation/reminder_{controller,screen,screen_golden}_test.dart`,
`test/visual_audit/screens/features/reminders/`.

**Built (FE-B6):** "Open system settings" calls `openNotificationSettingsProvider`, over
`ReminderPlatformRepository.openNotificationSettings`: `MainActivity.kt`'s channel
`memox/notification_settings` opens Android's notification page for MemoX, or App info
where a device has none. It changes nothing stored and asks for nothing; a page that
cannot open leaves the guidance as it is. Checked on the API 36 emulator: the tap opens
`AppNotificationSettingsActivity` for MemoX; allowing there, then Back and Try again,
turns the reminder on.

## Transitions

| From | Event | To | Evidence |
|---|---|---|---|
| loading | the status stream emits | off / on / unavailable | UC-REMINDER-001 step 1. VERIFIED `reminder_screen_test.dart::off: toggle off, time row disabled, note and preview (main 1)`, `::unavailable: one row, no toggle, no time, no preview (E2)`; the skeleton `::loading: the list skeleton` |
| loading | the read fails | read error | E7. VERIFIED `::E7: a failed read replaces the body, Retry reads again` |
| read error | Retry | error with Retry spinning, then the state the read gives | E7. VERIFIED same test |
| off | the toggle on | turningOn | main 2. VERIFIED `::busy: the toggle becomes a spinner, the permission is asked once` |
| turningOn | allowed and scheduled | on | main 2-3. VERIFIED `::on: the toggle asks for the permission, then the time row opens (main 2-3)` |
| turningOn | the permission is refused | permDenied | E1. VERIFIED `::permDenied: the guidance and Try again, which asks again (E1)`; `reminder_controller_test.dart::turnOn refused: permissionDenied, then Retry asks again` |
| turningOn | the schedule is refused | couldNotSchedule: the reminder stays off | E3. VERIFIED `::couldNotSchedule on Enable: danger banner, Retry enables (E3)` |
| turningOn | the save fails | off, toast "Couldn't save the reminder. Nothing changed." with Retry | E4. VERIFIED `::E4: a failed save says so with Retry; the toggle stays off`; `reminder_controller_test.dart::a failed save is ReminderSaveFailed, never a problem (E4)` |
| permDenied | Try again | turningOn (the banner steps aside), then on / permDenied again | E1. VERIFIED `::permDenied: while Try again runs the banner steps aside, then returns in the same order` |
| permDenied | Open system settings | permDenied (nothing asked, nothing written, the banner stays); a page that cannot open leaves the guidance | FE-B6, BR-REMINDER-011. VERIFIED `::permDenied: Open system settings opens them and changes nothing else: no permission asked, nothing written, the banner stays (FE-B6; BR-REMINDER-011)`, `::permDenied: settings that cannot open leave the guidance as it is (FE-B6)`. |
| couldNotSchedule | Retry | turningOn | E3. VERIFIED same test as the entry |
| on | the toggle off | turningOff | A2. `UNVERIFIED (code read)` for the spinner: `reminder_settings_section_widget.dart` |
| turningOff | cancelled and saved | off | A2. `UNVERIFIED (code read)`; the controller path is covered by `reminder_controller_test.dart::turnOff with a refused cancel: mayStillShow; Retry only cancels` for the refusal |
| turningOff | the cancel is refused | offMayShow | E6. VERIFIED `reminder_screen_test.dart::offMayShow: off, the warning and Try again, which only cancels (E6)` |
| offMayShow | Try again | turningOff, then off / offMayShow | E6. VERIFIED same test |
| turningOff | the save fails | on, toast "Couldn't save the reminder. Nothing changed." with Retry | E4. `UNVERIFIED (code read)`: the E4 test turns on; `_run` is shared |
| on | tap the time button | changingTime (the dialog, the button outlined) | A1. VERIFIED `::A1: Cancel changes nothing; Save stores and schedules the new minute`; TalkBack `::TalkBack reads the time button and can press it` |
| off | tap the time button | no change (disabled) | VERIFIED `::off: the time row is disabled`, `::off: the time button draws its own disabled state, dimmed once (critique 2026-09-30 part 3a)` |
| changingTime | Cancel | on, nothing written | A1. VERIFIED the A1 test above |
| changingTime | Back or a scrim tap | on, nothing written | `UNVERIFIED (code read)`: `showMxDialog` returns null, `_pickTime` returns on null |
| changingTime | type a value out of range | Save disabled, the stepper marked | VERIFIED `::a typed minute outside 0–59 disables Save` |
| changingTime | Save with the same time | on, nothing written | `UNVERIFIED (code read)`: `_pickTime` returns when `chosen == minuteOfDay` |
| changingTime | Save with a new time | savingTime | A1. VERIFIED the A1 test (the stored and scheduled minute) |
| savingTime | scheduled and saved | on at the new time | A1. VERIFIED the A1 test |
| savingTime | the schedule is refused | couldNotChangeTime | E3. VERIFIED `::couldNotChangeTime: the old time stands, the banner names it (E3)`; `reminder_controller_test.dart::couldNotSchedule is couldNotTurnOn on Enable and couldNotChangeTime on a change` |
| couldNotChangeTime | Retry | savingTime with the same minute | E3. `UNVERIFIED (code read)`: `ReminderController.changeTime` keeps `again` |
| savingTime | the save fails | on at the stored time, toast with Retry | E4. `UNVERIFIED (code read)` |
| any busy state | a second toggle, time or banner action | ignored | spec D4. VERIFIED `reminder_controller_test.dart::a second operation is ignored while one runs`; the controls are disabled while busy (`isBusy`), `UNVERIFIED (code read)` |
| any | a stream re-emission while a problem shows | the problem stays | VERIFIED `reminder_controller_test.dart::the outcome survives a stream re-emission` |
| any | the next operation starts | the old banner is cleared | `UNVERIFIED (code read)`: `_run` replaces the state with `running` |
| turningOn | the screen is left before the platform answers | the operation ends with no state written | `UNVERIFIED (code read)`: `_run` returns on `!ref.mounted`; the schedule itself is the gate's (`reminderOperationGateProvider`) |
| loaded (off or on) | the preview read lands | the notification's sentence, or "Nothing is due right now, so today's reminder would stay silent." | VERIFIED `reminder_preview_section_test.dart::the preview says what the notification would say now (critique 2026-09-30 part 1)`, `::nothing due: the preview says the reminder stays silent` |
| loaded (off or on) | the preview read fails | the neutral "nothing due" line, no error | VERIFIED `reminder_preview_section_test.dart::a failed read shows the neutral line` |
| loaded (off or on) | the preview read is running | the row keeps its place, no error | VERIFIED `reminder_preview_section_test.dart::while the preview loads the row keeps its place and shows no error` |

## Rulings

- **Critique 2026-09-30 part 1:** the preview reads the live workload (no sample counts), and the Time row's hint stays at full strength while the row is disabled (`MxSettingsRow`).
- **Critique 2026-09-30 part 3d-2 (spec `2026-10-01-critique-fixes-part3d2-design.md`):** the hour and minute steppers read in two digits ("07" : "05", `MxStepper` `minDigits: 2`), matching the "07:05" preview.
- **UC-REMINDER-001 E6 (spec D8):** offMayShow is a `warning` `MxInlineBanner` with Try again, which cancels again and writes nothing; `MxInlineBanner` has no info tone.
- **UC-REMINDER-001 E3:** a refused Change time says "Couldn't change the time. The reminder stays at {HH:mm}." and the reminder stays on.
- **Owner 2026-09-28 (spec D2), UC A1:** the time is chosen in an `MxDialog` with Hour and Minute `MxStepper`s.
- **UI-base ruling O3 (spec D10):** loading is `MxSkeletonList`.
- The note is the section's `MxNote.hint` footnote (critique 2026-09-30); the time button is a small `MxButton`.
- "What it says" is built from the notification's own strings, in en and vi, so it matches what is shown.
- **Q-C-1 (owner, 2026-10-16):** the reminder hints keep each dot on the phrase before it (`metaDots`) (The Wrap Rule; `lib/l10n/meta_line.dart`).

## Accessibility

- The toggle is read as "Daily reminder" with its on/off state; while an operation runs
  it is a spinner named "Loading".
- The time button is read as "Reminder time, {HH:mm}"; disabled while off.
- The steppers name their buttons ("Earlier hour", "Later minute"…) and read their value
  with "Hour" / "Minute"; a typed value out of range marks the stepper and keeps Save off.
- Every control is at least 48 tall; the visual-audit companion checks both themes and
  text scales.

## Copy

- App bar and toggle: "Daily reminder" · "One notification a day at the time below" ·
  "Off · nothing is scheduled" · "Off · notification permission was refused".
- Time: "Time" · "Local time · stays the same if you travel" · "Turn the reminder on to
  choose a time" · "{HH:mm}".
- Note: "Fires once a day, only when cards are due. Never for new cards, never twice."
- E1: "Notifications are blocked for MemoX" · "Allow them in Android Settings › Apps ›
  MemoX › Notifications, then turn the reminder on again." · "Try again".
- E3: "Couldn’t schedule the reminder." · "It stays off. Try turning it on again." ·
  "Retry"; on Change time "Couldn’t change the time." · "The reminder stays at {HH:mm}."
- E6: "Turned off. A reminder already scheduled for today may still appear once." · "Try
  again".
- E2: "Reminders are not available on this device" · "This build cannot deliver
  notifications. Nothing to turn on here."
- E4: "Couldn't save the reminder. Nothing changed." · E7: "Couldn't read the reminder
  setting" · "Nothing was changed. Try reading it again."
- What it says: the notification's sentence, e.g. "“3 cards are due in Korean.”" · "Nothing is due
  right now, so today's reminder would stay silent." · "Deck name and counts only — never a card, tag or history, including
  on the lock screen. Opening it lands on Study."
- Dialog: "Reminder time" · "Hour" · "Minute" · "Cancel" · "Save".
- Screen 23: "Daily reminder" · "Off" · "On · {HH:mm}"; reset body names "the daily
  reminder (off, 20:00)"; the Reset row's line ends with "reminder".

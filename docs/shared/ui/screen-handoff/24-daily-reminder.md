<!-- Hand-written screen record. -->

# 24 · Daily reminder

The daily reminder: turn it on or off, choose its time, and see what the notification
says. The stored reminder comes from `app_settings`; what the last operation left (a
refused permission, a refused schedule, a cancel that failed) is held by the screen only.
UC-REMINDER-001; spec
[2026-09-28-daily-reminder-ui-design.md](../../../superpowers/specs/2026-09-28-daily-reminder-ui-design.md)
(FE-B5).

## Entry points

- Screen 23, App section, row "Daily reminder" ("Off" or "On · {HH:mm}"). Route
  `/settings/reminder`, on the root navigator like Theme and Language; Back returns to 23.

## Layout

| Region | Widget | Design |
|---|---|---|
| App bar | `MxAppBar` (content density) + back `MxIconButton` | "Daily reminder". |
| Reminder section | `MxSection` with note, two `MxSettingsRow`s | Row bell "Daily reminder" with `MxToggle` (an `MxSpinner` while turning on or off); row clock "Time" with a compact `MxButton` "{HH:mm}", disabled while off. The note: "Fires once a day, only when cards are due. Never for new cards, never twice." |
| Banner | `MxInlineBanner` | Only after an operation left a problem: E1 `warning`, E3 `danger`, E6 `warning`; or, with the reminder on, when Android blocks MemoX's notifications (read on open and on resume, never asked): `warning`, titled "Notifications are blocked for MemoX", with "Open system settings" (SP2b 2.34). |
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
| timeInvalid | `reminder_time_invalid_light.png` | `reminder_time_invalid_dark.png` | A typed hour or minute out of range marks its stepper and a line under it names the range; Save stays off until a valid value is typed or a step clears it (SP2b 2.35). |
| permDenied | `reminder_perm_denied_light.png` | `reminder_perm_denied_dark.png` | Try again (outlined), then "Open system settings" (primary, last as every banner's primary; R5 amends FE-B6), which opens the app's notification settings. While Try again runs the banner steps aside and returns in the same order. |
| permRevoked | `reminder_perm_revoked_light.png` | `reminder_perm_revoked_dark.png` | The reminder is on but Android blocks its notifications: the toggle row reads "On · notifications are blocked for MemoX" and a `warning` banner offers "Open system settings". Nothing stored changes; both go when the permission is back on the next resume (SP2b 2.34, 2.36). |
| couldNotSchedule | `reminder_could_not_schedule_light.png` | `reminder_could_not_schedule_dark.png` | On Enable the reminder stays off. A refused schedule on Change time has its own copy (see Rulings). |
| offMayShow | `reminder_off_may_show_light.png` | `reminder_off_may_show_dark.png` | A `warning` banner with Try again (see Rulings). |
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

## Rulings

- **Critique 2026-09-30 part 1:** the preview reads the live workload (no sample counts), and the Time row's hint stays at full ink while the row is disabled (`MxSettingsRow`).
- **Critique 2026-09-30 part 3d-2 (spec `2026-10-01-critique-fixes-part3d2-design.md`):** the hour and minute steppers read in two digits ("07" : "05", `MxStepper` `minDigits: 2`), matching the "07:05" preview.
- **SP2b 2.34 (spec `2026-10-03-ui-hardening-sp2b-design.md`):** the screen reads the permission without asking (`ReminderPlatformRepository.notificationPermission`, `reminderPermissionProvider`) on open and on resume. Unknown or unreadable counts as allowed, so a warning is never false.
- **SP2b 2.35:** a step clears that stepper's invalid flag; the line under it ("Enter an hour from 0 to 23.") says why Save is off.
- **SP2b 2.36:** the "refused" guidance and the "Off · notification permission was refused" hint go on the next resume once the permission is allowed. The toggle stays off; turning it on is the person's tap (BR-REMINDER-011).
- **UC-REMINDER-001 E6 (spec D8):** offMayShow is a `warning` `MxInlineBanner` with Try again, which cancels again and writes nothing; `MxInlineBanner` has no info tone.
- **UC-REMINDER-001 E3:** a refused Change time says "Couldn't change the time. The reminder stays at {HH:mm}." and the reminder stays on.
- **Owner 2026-09-28 (spec D2), UC A1:** the time is chosen in an `MxDialog` with Hour and Minute `MxStepper`s.
- **UI-base ruling O3 (spec D10):** loading is `MxSkeletonList`.
- The note is the section's `MxNote.hint` footnote (critique 2026-09-30); the time button is a compact `MxButton`.
- "What it says" is built from the notification's own strings, in en and vi, so it matches what is shown.

## Accessibility

- The toggle is read as "Daily reminder" with its on/off state; while an operation runs
  it is a spinner named "Loading".
- The time button is read as "Reminder time, {HH:mm}"; disabled while off.
- The steppers name their buttons ("Earlier hour", "Later minute"…) and read their value
  with "Hour" / "Minute"; a typed value out of range marks the stepper, says the range in a line under it (announced), and keeps Save off.
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
- Revoked: "On · notifications are blocked for MemoX" · title "Notifications are blocked for MemoX" · "The reminder is on, but Android won't show it. Allow notifications in Android Settings › Apps › MemoX › Notifications." · "Open system settings".
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
- Dialog: "Reminder time" · "Hour" · "Minute" · "Cancel" · "Save" · "Enter an hour from 0 to 23." · "Enter a minute from 0 to 59."
- Screen 23: "Daily reminder" · "Off" · "On · {HH:mm}"; reset body names "the daily
  reminder (off, 20:00)"; the Reset row's line ends with "reminder".

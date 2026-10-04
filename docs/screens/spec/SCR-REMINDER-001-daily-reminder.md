---
id: SCR-REMINDER-001
name: Daily reminder
domain: reminders
status: ready
route: [/settings/reminder]
---

# Daily reminder

## Purpose

The daily reminder: turn it on or off, choose its time, and see what the notification would say now.
The stored reminder is read live; what the last operation left (a refused permission, a refused
schedule, a cancel that failed) is held by the screen only. On the root navigator with no bottom bar,
like Theme and Language; opened from the Daily reminder row of Settings (SCR-SETTINGS-002), which
reads "Off" or "On · {HH:mm}". Back returns to Settings.

## Related Use Cases

- UC-REMINDER-001

## Layout

- **App bar** — back and "Daily reminder" (content density).
- **Reminder section** — two settings rows and the section's footnote. The bell row "Daily reminder"
  with a toggle (a spinner while turning on or off): "One notification a day at the time below", "Off ·
  nothing is scheduled" or "Off · notification permission was refused". The clock row "Time" with a
  compact button "{HH:mm}", disabled while off: "Local time · stays the same if you travel", or "Turn
  the reminder on to choose a time" at full ink while the row is disabled. The footnote: "Fires once a
  day, only when cards are due. Never for new cards, never twice."
- **Banner** — only after an operation left a problem: the permission refusal (`warning`), a refused
  schedule (`danger`), a cancel that failed (`warning`).
- **What it says** — a section with one row: the notification's own sentence over the live workload
  read when the screen opens, built from the strings the notification uses, e.g. "“3 cards are due in
  Korean.”"; "Nothing is due right now, so today's reminder would stay silent." when nothing is due or
  the read fails. While the read runs the row keeps its place with its hint and shows no error. The
  line under it: "Deck name and counts only — never a card, tag or history, including on the lock
  screen. Opening it lands on Study."
- **Time dialog** — "Reminder time": two steppers, Hour 0–23 and Minute 0–59, shown in two digits
  ("07" : "05"; a hold repeats, a tap on the number types one), the chosen "HH:mm", then Cancel ·
  Save.
- **Toast** — "Couldn't save the reminder. Nothing changed." · Retry; the rows keep the stored values.

## States

### `off` · Off

The toggle off; the time row explains how to choose a time.

Golden: light, dark

### `turning_on` · Turning on

The toggle is a spinner while turning on asks for the permission, schedules and saves; nothing else
can start.

Golden: light, dark

### `on` · On

The toggle on, the time button, and what the notification says (nothing due in the fixture).

Golden: light, dark

### `preview_due` · Something is due

"What it says" reads the live sentence, three cards due in one deck.

Golden: light, dark

### `changing_time` · Changing the time

The time button is outlined while the dialog is open.

Golden: light, dark

### `perm_denied` · Permission refused

The `warning` banner "Notifications are blocked for MemoX" with Try again (outlined), then "Open
system settings" (primary, last). While Try again runs the banner steps aside and returns in the same
order. The toggle stays off.

Golden: light, dark

### `could_not_schedule` · Could not schedule

On turning on, the `danger` banner "Couldn’t schedule the reminder." with Retry; the reminder stays
off. A refused change of time has its own copy and the reminder stays on.

Golden: light, dark

### `off_may_show` · Off, one may still show

The `warning` banner "Turned off. A reminder already scheduled for today may still appear once." with
Try again.

Golden: light, dark

### `unavailable` · Unavailable

One row, no toggle, no time, no preview: "Reminders are not available on this device".

Golden: light, dark

### `loading` · Loading

Skeleton list rows.

Golden: light, dark

### `read_error` · Read error

"Couldn't read the reminder setting" / "Nothing was changed. Try reading it again." with Retry, in
place of every row.

Golden: light, dark

## Controls

### Reminder data

- Type: read
- Invokes: FN-REMINDER-001

#### On failure

- A database failure → `read_error`.

### What it says

- Type: read
- Invokes: FN-REMINDER-002

#### On failure

- The silent sentence, no error.

### Daily reminder toggle (turning on)

- Type: toggle
- Enabled when: no operation is running.
- Invokes: FN-REMINDER-003

#### On success

- `on`.

#### On failure

- `permissionDenied` → `perm_denied`; `couldNotSchedule` → `could_not_schedule`; `unsupported` →
  `unavailable`; a database failure → the toast with Retry. The toggle stays off.

### Daily reminder toggle (turning off)

- Type: toggle
- Enabled when: no operation is running.
- Invokes: FN-REMINDER-007
- Purpose: no confirmation and no permission asked.

#### On success

- `off`.

#### On failure

- `couldNotCancel` → `off_may_show`; a database failure → the toast with Retry, the reminder stays on.

### Time button

- Type: compact button
- Enabled when: the reminder is on and no operation is running.
- Purpose: opens the time dialog (`changing_time`).

### Save (time dialog)

- Type: dialog confirm
- Enabled when: both values are in range.
- Invokes: FN-REMINDER-006

#### On success

- The new time on the button and in the Settings row.

#### On failure

- `couldNotSchedule` → the `danger` banner "Couldn’t change the time." · "The reminder stays at
  {HH:mm}."; a database failure → the toast with Retry. The old time stays.

### Cancel (time dialog)

- Type: dialog action
- Purpose: closes the dialog; nothing changes.

### Try again (`perm_denied`), Retry (`could_not_schedule`)

- Type: banner action
- Invokes: FN-REMINDER-003

### Open system settings (`perm_denied`)

- Type: banner primary action
- Purpose: opens the system's notification page for MemoX (App info where a device has none). It
  writes nothing and asks for nothing; a page that cannot open leaves the guidance as it is.

### Try again (`off_may_show`)

- Type: banner action
- Invokes: FN-REMINDER-007
- Purpose: cancels again and writes nothing.

### Retry (`read_error`)

- Type: button
- Invokes: FN-REMINDER-001

## Responsive Behavior

Follows the shared floor (DESIGN.md, SCREEN_CATALOG.md).

## Accessibility

- The toggle reads "Daily reminder" with its on or off state; while an operation runs it is a spinner
  named "Loading".
- The time button reads "Reminder time, {HH:mm}"; disabled while off.
- The steppers name their buttons ("Earlier hour", "Later minute"…) and read their value with "Hour"
  or "Minute"; a typed value out of range marks the stepper and keeps Save off.
- Otherwise follows the shared floor (DESIGN.md, SCREEN_CATALOG.md).

## UI Invariants

| Invariant | Enforced by |
|---|---|
| The permission is asked only when the person turns the reminder on. | — |
| One operation at a time: while one runs, the toggle and the time button take no other. | — |
| The toggle shows on only once the reminder is stored on. | — |
| "What it says" is built from the notification's own strings and never names a card, a tag or history. | — |
| No row is shown when the reminder cannot be read. | — |

## Copy

- App bar and toggle: "Daily reminder" · "One notification a day at the time below" · "Off · nothing
  is scheduled" · "Off · notification permission was refused".
- Time: "Time" · "Local time · stays the same if you travel" · "Turn the reminder on to choose a
  time" · "{HH:mm}" · "Reminder time, {HH:mm}".
- Footnote: "Fires once a day, only when cards are due. Never for new cards, never twice."
- Permission refused: "Notifications are blocked for MemoX" · "Allow them in Android Settings › Apps ›
  MemoX › Notifications, then turn the reminder on again." · "Try again" · "Open system settings".
- Could not schedule: "Couldn’t schedule the reminder." · "It stays off. Try turning it on again." ·
  "Retry"; on a change of time "Couldn’t change the time." · "The reminder stays at {HH:mm}."
- Off, may show: "Turned off. A reminder already scheduled for today may still appear once." · "Try
  again".
- Unavailable: "Reminders are not available on this device" · "This build cannot deliver
  notifications. Nothing to turn on here."
- Save failed: "Couldn't save the reminder. Nothing changed." · "Retry".
- Read error: "Couldn't read the reminder setting" · "Nothing was changed. Try reading it again." ·
  "Retry".
- What it says: "What it says" · "“{n} cards are due in {deck}.”" · "Nothing is due right now, so
  today's reminder would stay silent." · "Deck name and counts only — never a card, tag or history,
  including on the lock screen. Opening it lands on Study."
- Dialog: "Reminder time" · "Hour" · "Minute" · "Earlier hour" · "Later hour" · "Earlier minute" ·
  "Later minute" · "Cancel" · "Save".

## Rulings

- **Critique 2026-09-30 part 1:** the preview reads the live workload (no sample counts), and the Time
  row's hint stays at full ink while the row is disabled.
- **Critique 2026-09-30 part 3d-2 (spec `2026-10-01-critique-fixes-part3d2-design.md`):** the hour and
  minute steppers read in two digits ("07" : "05"), matching the "07:05" preview.
- **UC-REMINDER-001 E6 (spec D8):** `off_may_show` is a `warning` banner with Try again, which cancels
  again and writes nothing; the inline banner has no info tone.
- **UC-REMINDER-001 E3:** a refused change of time says "Couldn't change the time. The reminder stays
  at {HH:mm}." and the reminder stays on.
- **Owner 2026-09-28 (spec D2), UC-REMINDER-001 A1:** the time is chosen in a dialog with Hour and
  Minute steppers.
- **UI-base ruling O3 (spec D10):** loading is skeleton list rows.
- **R5 (amends FE-B6):** "Open system settings" is the banner's primary and sits last, as every
  banner's primary does.
- **FE-B6:** "Open system settings" opens Android's notification page for MemoX, or App info where a
  device has none; checked on the API 36 emulator (allowing there, then Back and Try again, turns the
  reminder on).
- The footnote is the section's hint footnote (critique 2026-09-30); the time button is compact.
- "What it says" is built from the notification's own strings, in en and vi, so it matches what is
  shown.

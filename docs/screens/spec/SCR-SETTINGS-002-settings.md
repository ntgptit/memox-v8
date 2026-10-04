---
id: SCR-SETTINGS-002
name: Settings
domain: settings
status: ready
route: [/settings]
---

# Settings

## Purpose

The Settings tab: the account, the app-wide study defaults, the Theme, Language and Daily reminder
pages, Sync, the admin pages, and Reset app options. Every value shown is the stored one, or the card
limit being changed. Opened from the Settings tab of the bottom bar and the `/settings` deep link.

## Related Use Cases

- UC-SETTINGS-001

## Layout

- **App bar** — "Settings"; in debug builds only, a gallery icon opening the component gallery.
- **Re-auth banner** — while the sign-in is refused, a warning banner above the Account section:
  "Your sign-in expired. Your decks are still on this phone." · "Sign in".
- **Account** — first. An anonymous device: "Sign in" / "Keep your decks if you reinstall or change
  phones" with the person tile; while the account cannot link yet (offline) the row is disabled with
  "Available when you're online". An attached account: its email / "Your decks sync to this account"
  with a chevron. Hidden in a build with no server.
- **Study defaults** — "Cards per session" / "1 to 200 · default 20" with a stepper under the label
  (−/+, a hold that repeats, a tap on the number types one); "New-card order" / "How new cards enter
  a learning session" with a segmented tray In order · Random, the options stacking when their labels
  do not fit. The note: "Applies to sessions started from now on. A deck with its own study options
  keeps them." The tile sits beside the label on a row with a wide control.
- **Card limit message** — "Enter a number from 1 to 200" under the stepper while a typed value is out
  of range; the sub-line stays.
- **App** — "Theme" with the choice ("Follows the system setting", "Light" or "Dark"); "Language"
  with "System · {language}", "English" or "Tiếng Việt"; "Daily reminder" with "Off" or "On ·
  {HH:mm}". Each opens its page.
- **Sync** — one row with the cloud-sync tile: success when sync is settled, warning when the last run
  failed or a change was refused, tinted otherwise. Its sub-line is the first that applies of "{n}
  changes weren't accepted", "Couldn't sync · no connection" (or "· couldn't sign in", "· server
  error", "· something went wrong"), "Synced {Today, 14:32}", "Not synced yet". Hidden when the build
  has no server.
- **Admin** — "Monitoring" / "Logs of the app and the server" (monitor tile) and "Users" / "Who can
  manage the app" (people tile); only while the account is an admin; hidden for everyone else and in a
  build with no server.
- **Reset** — "Reset app options" / "Theme, language, study defaults, reminder", an action row with no
  chevron (it opens a dialog). The note: "Only these app options return to their defaults. Decks,
  cards, per-deck study options and learning progress are not touched."
- **Reset dialog** — "Reset app options?", "Theme, language, cards per session, new-card order and
  the daily reminder (off, 20:00) go back to their defaults.", the shield note "Your decks, cards,
  schedules and study history stay exactly as they are. This is not “Reset learning progress”.", then
  Cancel (outline) · "Reset options" (primary, spinning while it runs), stacked when a label cannot
  fit. Back and Cancel do nothing while it runs.
- **Toasts** — "Saved"; "Couldn't save cards per session. Still {n}." · Retry; "Couldn't save the
  new-card order." · Retry; "App options reset to defaults"; "Couldn't reset the app options. Nothing
  changed." · Retry.

## States

### `loaded` · Loaded

Theme is a row that opens its page; the Daily reminder row reads "Off" or "On · {HH:mm}".

Golden: light, dark

### `loading` · Loading

Three section-shaped skeleton cards of skeleton rows.

Golden: light, dark

### `saving` · Saving

The stepper's spinner; the other rows stay usable.

Golden: light, dark

### `saved` · Saved

Golden: light, dark

### `invalid_limit` · Limit out of range

The message under the stepper; the sub-line stays.

Golden: light, dark

### `save_failed` · Save failed

The stepper shows the stored value again; the toast with Retry.

Golden: light, dark

### `reset_confirm` · Reset dialog

Golden: light, dark

### `reset_done` · Reset done

Golden: light, dark

### `sync_synced` · Sync row, synced

Golden: light, dark

### `sync_failed` · Sync row, last run failed

Golden: light, dark

### `sync_rejected` · Sync row, changes refused

Golden: light, dark

### `account` · Account, anonymous

The Account section first, with "Sign in".

Golden: light, dark

### `account_signed_in` · Account, signed in

The account row with its email and chevron.

Golden: light, dark

### `account_reauth` · Account, sign-in expired

The re-auth banner leads the Account section.

Golden: light, dark

### `admin_rows` · Admin rows

The Admin section: Monitoring, then Users.

Golden: light, dark

### `read_error` · Read error

"Couldn't open Settings" with the local-first body and Retry; no value is shown.

Golden: none — no golden in V8 (record 23)

## Controls

### Settings data

- Type: read
- Invokes: FN-SETTINGS-001, FN-ACCOUNT-002, FN-ACCOUNT-015

#### On failure

- A database failure → `read_error`.

### Cards per session stepper

- Type: stepper
- Invokes: FN-SETTINGS-002
- Purpose: saves once a change settles — 600 ms after the last step, a hold included, or at once for
  a typed value.

#### On failure

- `cardLimitOutOfRange` → `invalid_limit`, nothing written; a database failure → `save_failed`.

### New-card order tray

- Type: segmented tray
- Invokes: FN-SETTINGS-002
- Purpose: a segment tap saves at once.

#### On failure

- "Couldn't save the new-card order." with Retry.

### Theme, Language, Daily reminder rows

- Type: settings rows

#### On success

- Navigate to: SCR-SETTINGS-003 (Theme), SCR-SETTINGS-004 (Language), SCR-REMINDER-001 (Daily
  reminder).

### Account row, Sign in (re-auth banner)

- Type: settings row / compact button
- Enabled when: the account can link (online) for an anonymous device.

#### On success

- Navigate to: SCR-ACCOUNT-003 (anonymous, or re-auth), SCR-ACCOUNT-005 (an attached account).

### Sync row

- Type: settings row

#### On success

- Navigate to: SCR-ACCOUNT-001

### Monitoring, Users rows

- Type: settings rows

#### On success

- Navigate to: SCR-MONITORING-001 (Monitoring), SCR-ACCOUNT-006 (Users).

### Reset app options

- Type: action row
- Purpose: opens the reset dialog (`reset_confirm`).

### Reset options (reset dialog)

- Type: dialog confirm
- Enabled when: no reset is running.
- Invokes: FN-SETTINGS-005

#### On success

- `reset_done`; the toast "App options reset to defaults".

#### On failure

- "Couldn't reset the app options. Nothing changed." with Retry.

### Cancel (reset dialog)

- Type: dialog action
- Enabled when: no reset is running.

### Retry (`read_error`)

- Type: button
- Invokes: FN-SETTINGS-001

## Responsive Behavior

Tray options stack when their labels do not fit; the reset dialog's buttons stack when a label cannot
fit. Otherwise follows the shared floor (DESIGN.md, SCREEN_CATALOG.md).

## Accessibility

The stepper's −/+ read "Fewer cards per session" / "More cards per session". Otherwise follows the
shared floor (DESIGN.md, SCREEN_CATALOG.md).

## UI Invariants

| Invariant | Enforced by |
|---|---|
| Every value shown is the stored one, or the limit being changed. | — |
| Each option saves on its own; a failure in one touches no other. | — |
| Reset app options asks first and says it is not Reset learning progress. | — |
| The Admin section shows only to an admin. | — |
| No value is shown when the settings cannot be read. | — |

## Copy

- Study defaults: "Study defaults" · "Cards per session" · "1 to {max} · default {n}" · "Fewer cards
  per session" · "More cards per session" · "Enter a number from {min} to {max}" · "New-card order" ·
  "How new cards enter a learning session" · "In order" · "Random" · "Applies to sessions started
  from now on. A deck with its own study options keeps them."
- Account: "Account" · "Sign in" · "Keep your decks if you reinstall or change phones" · "Available
  when you're online" · "Your decks sync to this account" · "Your sign-in expired. Your decks are
  still on this phone."
- App: "App" · "Theme" · "Follows the system setting" · "Light" · "Dark" · "Language" · "System ·
  {language}" · "English" · "Tiếng Việt" · "Daily reminder" · "Off" · "On · {time}".
- Reset: "Reset" · "Reset app options" · "Theme, language, study defaults, reminder" · "Only these
  app options return to their defaults. Decks, cards, per-deck study options and learning progress
  are not touched." · "Reset app options?" · "Theme, language, cards per session, new-card order and
  the daily reminder (off, 20:00) go back to their defaults." · "Your decks, cards, schedules and
  study history stay exactly as they are. This is not “Reset learning progress”." · "Cancel" · "Reset
  options".
- Sync: "Sync" · "{n} changes weren't accepted" · "Couldn't sync · no connection" · "Couldn't sync ·
  couldn't sign in" · "Couldn't sync · server error" · "Couldn't sync · something went wrong" ·
  "Synced {time}" · "Not synced yet"; times "Today, {HH:mm}" · "Yesterday, {HH:mm}" · "{MMM d},
  {HH:mm}".
- Admin: "Admin" · "Monitoring" · "Logs of the app and the server" · "Users" · "Who can manage the
  app".
- Toasts: "Saved" · "Couldn't save cards per session. Still {n}." · "Couldn't save the new-card
  order." · "App options reset to defaults" · "Couldn't reset the app options. Nothing changed." ·
  "Retry".
- Error: "Couldn't open Settings" · "Nothing was lost. Try again in a moment." · "Retry".

## Rulings

- **D2 (owner), UI-base row 124:** Theme is a row naming the choice and opens its page.
- **D1:** the card limit saves once a change settles (600 ms after the last step, a hold included, or
  at once for a typed value); a segment tap saves at once.
- **UC-SETTINGS-001 E1:** "Enter a number from 1 to 200" sits under the stepper and the sub-line
  stays.
- **D6 (owner), UI-base row 126:** the stepper takes −/+, a hold that repeats, and a typed number.
- **UI-base row 125, UC E3:** loading is three section-shaped skeleton cards; a read error is the error
  state with Retry.
- **UI-base row 127:** tray options stack when their labels do not fit.
- **UI-base row 118:** the reset dialog's buttons stack when a label cannot fit.
- **ADR-015, SB-U1 (owner rulings R1, R5):** a Sync section with one row opens the Sync page.
- **UI-base row 128:** the tile sits beside the label on a row with a wide control.
- **Account UI spec §5.5, R2, P3b plan ruling 1:** the attached account opens its Account page; an
  expired sign-in's banner leads the Account section, since Settings owns the problem.
- **ADR-018 §8, monitoring spec §3.1, users spec U2:** the Admin section holds Monitoring and Users,
  drawn by Settings from rows the features supply, only while the account is an admin.
- **Critique 2026-09-30 part 1:** Reset app options is an action row with no chevron: it opens a
  dialog.
- **Critique 2026-09-30 tone pass, T4; part 3d-1, D5:** the Sync row's tile is success when sync is
  settled; warning when the last run failed or a change was refused; tinted otherwise.
- **Critique 2026-09-30 part 3d-2 (spec `2026-10-01-critique-fixes-part3d2-design.md`):** loading
  shows section-shaped skeleton cards (three) of skeleton rows, not a generic list.
- **FE-B5:** the Daily reminder row reads "Off" or "On · {HH:mm}" and opens its page; the reset copy
  names the reminder going off at 20:00.
- **Migration 2026-10-04:** the legacy UC-SETTINGS-001 named three groups (Study defaults,
  Appearance, Language); V8 draws Account, Study defaults, App (Theme, Language, Daily reminder),
  Sync, Admin and Reset. The spec follows the app.

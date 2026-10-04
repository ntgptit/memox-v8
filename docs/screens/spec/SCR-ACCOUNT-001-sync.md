---
id: SCR-ACCOUNT-001
name: Sync
domain: account
status: ready
route: [/settings/sync]
---

# Sync

## Purpose

What sync did and what waits: the last success, the changes not yet on the server, the last failed
run, and the changes the server refused. On the root navigator with no bottom bar, like Theme and
Language. Opened from the Sync row of Settings (SCR-SETTINGS-002), Back returning there, and from the
sync banner's "Details" on Study home (SCR-STUDY-001), which lands on Settings when Back is pressed.
Neither entry exists in a build with no server.

## Related Use Cases

None: the account feature has no use case; its behaviour follows the account, auth and sync status
specs (see `docs/functional-spec/account.md`).

## Layout

- **App bar** — back and "Sync" (content density).
- **Status** — a section "Status" with two rows and a note. "Last synced" · "{Today, 14:32}" or "Not
  yet"; "Waiting to sync" · "{n} changes" or "Nothing waiting", or "No other changes waiting" when
  only refused changes remain. When sync is settled (synced once, nothing waiting, nothing refused or
  failed) the waiting row ends with a success check, not read out. The note: "MemoX syncs on its own
  when you're online. Your study never waits for it."
- **Problem** — under the status, above Sync now. Refused changes win: a `warning` banner "{n}
  changes weren't accepted" over "The server didn't accept them. They're safe here. Try again, or
  keep them on this device only; they won't sync to your other devices.", then Keep on this device
  (outline) · Try again (primary, the screen's one primary). Otherwise the last failed run's
  sentence, local-first, with no code, id or message: a run that failed for want of a network is a
  neutral note with the offline glyph; a sign-in, server or unknown failure is a `warning` banner.
  Nothing when all is well.
- **Sync now** — a block button with the cloud-sync glyph: primary while changes wait or a run failed
  (not for want of a network) and nothing was refused; outline otherwise, since sync is automatic.
  While a run it started is going, a spinner and "Syncing…" stand in its place, in a row of the
  button's height.
- **Keep dialog** — "Keep {n} changes on this device only?" · "They won't sync to your other devices.
  You can't undo this." · Cancel · "Keep on this device" (warning). Only the confirm keeps; Cancel,
  Back or the scrim write nothing.
- **Toasts** — "Synced"; "Couldn't sync. Nothing was lost."; "Kept on this device"; "Couldn't change
  that. Nothing was lost." · Retry.

Only one of Sync now, Try again and Keep on this device runs at a time; the other two are disabled
meanwhile.

## States

### `synced` · Synced

Golden: light, dark

### `never_synced` · Never synced

"Not yet".

Golden: light, dark

### `pending` · Changes waiting

Sync now is primary.

Golden: light, dark

### `failed_network` · Failed, no connection

The neutral offline note; Sync now is outline.

Golden: light, dark

### `failed_server` · Failed, server

The `warning` banner with the server sentence.

Golden: light, dark

### `rejected` · Changes refused

The refused-changes banner with Keep on this device and Try again; the waiting row never says
"Nothing waiting".

Golden: light, dark

### `keep_dialog` · Keep dialog

Golden: light, dark

### `syncing` · Syncing

The spinner and "Syncing…" in the button's place, announced as a live status.

Golden: light, dark

### `loading` · Loading

Skeleton list, two rows.

Golden: none — no golden in V8 (record 27)

### `read_error` · Read error

"Couldn't open Sync" with the local-first body and Retry.

Golden: none — no golden in V8 (record 27)

## Controls

### Sync status

- Type: read
- Invokes: FN-ACCOUNT-015

#### On failure

- A database failure → `read_error`.

### Sync now

- Type: block button
- Enabled when: no other sync command runs.
- Invokes: FN-ACCOUNT-016

#### On success

- `syncing`, then the toast "Synced".

#### On failure

- The toast "Couldn't sync. Nothing was lost."; the status shows the failed run.

### Try again (`rejected`)

- Type: banner primary action
- Enabled when: no other sync command runs.
- Invokes: FN-ACCOUNT-017

#### On success

- The toast "Synced".

#### On failure

- The run that failed: the toast "Couldn't sync. Nothing was lost."; a database failure: "Couldn't
  change that. Nothing was lost." · Retry.

### Keep on this device (`rejected`)

- Type: banner action
- Enabled when: no other sync command runs.
- Purpose: opens the Keep dialog (`keep_dialog`).

### Keep on this device (Keep dialog)

- Type: dialog confirm
- Invokes: FN-ACCOUNT-018

#### On success

- The toast "Kept on this device".

#### On failure

- "Couldn't change that. Nothing was lost." · Retry.

### Cancel (Keep dialog)

- Type: dialog action
- Purpose: writes nothing; so do Back and the scrim.

### Retry (`read_error`)

- Type: button
- Invokes: FN-ACCOUNT-015

## Responsive Behavior

Follows the shared floor (DESIGN.md, SCREEN_CATALOG.md).

## Accessibility

The "Syncing…" row is a live status; the waiting row's success check is not read out. Otherwise
follows the shared floor (DESIGN.md, SCREEN_CATALOG.md).

## UI Invariants

| Invariant | Enforced by |
|---|---|
| A failure is said local-first, with no code, id or message. | — |
| Keeping refused changes asks first; only the confirm keeps. | — |
| One sync command at a time; the others are disabled meanwhile. | — |
| The screen has one primary at most. | — |
| No status is invented when it cannot be read. | — |

## Copy

- App bar: "Sync".
- Refused: "{n} changes weren't accepted" · "1 change wasn't accepted" · "The server didn't accept
  them. They're safe here. Try again, or keep them on this device only; they won't sync to your other
  devices." · "Keep on this device" · "Try again".
- Keep dialog: "Keep {n} changes on this device only?" · "They won't sync to your other devices. You
  can't undo this." · "Cancel" · "Keep on this device".
- Failures: "No connection. Your changes are safe on this device and will sync when you're back
  online." · "Couldn't sign in to sync. Your changes are safe on this device. MemoX will try again." ·
  "The server couldn't take the changes. They're safe on this device. MemoX will try again." · "Sync
  stopped with an error. Your changes are safe on this device. MemoX will try again."
- Status: "Status" · "Last synced" · "Not yet" · "Waiting to sync" · "{n} changes" · "Nothing
  waiting" · "No other changes waiting" · "MemoX syncs on its own when you're online. Your study never
  waits for it." · "Sync now" · "Syncing…".
- Times: "Today, {HH:mm}" · "Yesterday, {HH:mm}" · "{MMM d}, {HH:mm}".
- Toasts: "Synced" · "Couldn't sync. Nothing was lost." · "Kept on this device" · "Couldn't change
  that. Nothing was lost." · "Retry".
- Error: "Couldn't open Sync" · "Nothing was lost. Try again in a moment." · "Retry".

## Rulings

- **ADR-015, SB-U1 owner rulings R1, R3, R5–R7:** sync has its own screen; its problems reach other
  screens as a floating notice (UI-base register row 143); on this screen they sit inline under the
  status, by Sync now (critique 2026-09-30).
- **Critique 2026-09-30 part 1 (spec `2026-09-30-critique-fixes-part1-design.md`), R4:** with refused
  changes Try again is the one primary, the waiting row never says "Nothing waiting", the banner says
  why and what Keep costs, and Keep asks first.
- **Spec R6, FE-B5 D9:** times are 24-hour `HH:mm` in every language; dates read "Sep 26" style in
  English.
- **Critique 2026-09-30 tone pass (spec `2026-09-30-critique-fixes-tone-design.md`), T3:** a settled
  sync ends the waiting row with a success check, not read out.
- **Critique 2026-09-30 part 3d-1 (spec `2026-10-01-critique-fixes-part3d1-design.md`), D5:** while
  Sync now runs, a spinner and "Syncing…" stand in the button's place, announced as a live status.
- **Critique 2026-09-30 part 3d-2 (spec `2026-10-01-critique-fixes-part3d2-design.md`):** the
  "Syncing…" row is the button's height, so the page does not shift at the swap.
- **Critique 2026-10-02 (spec `2026-10-02-critique2-fixes-design.md`), F8:** a run that failed for want
  of a network is a neutral note and Sync now is outline; server, sign-in and unknown failures keep
  the warning banner. Keep confirms in warning.
- **Sync status spec §6:** loading is a two-row skeleton list; a read error is the error state with the
  local-first body and Retry.

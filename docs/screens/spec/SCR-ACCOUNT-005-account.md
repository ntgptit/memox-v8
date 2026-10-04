---
id: SCR-ACCOUNT-005
name: Account
domain: account
status: ready
route: [/settings/account]
---

# Account

## Purpose

The account this phone's data belongs to, and what can be done with it: switch, sign out, delete.
On the root navigator with no bottom bar. Opened from the Account row of Settings (SCR-SETTINGS-002)
once the device holds an account, Back returning there; the link flow (SCR-ACCOUNT-002, 003, 004)
ends here. On a plainly anonymous device the route sends the person to Settings; during a transition
it stays. A finished sign-out, deletion or continue-without lands on Settings.

## Related Use Cases

None: the account feature has no use case; its behaviour follows the account UI and auth specs (see
`docs/functional-spec/account.md`).

## Layout

- **App bar** — back and "Account" (content density).
- **Re-auth banner** — only while the sign-in is refused: a `warning` banner "Your sign-in expired.
  Your decks are still on this phone." · "Sign in" (compact primary).
- **Connection note** — only while the account is being confirmed: "Managing your account needs a
  connection. Your decks are safe on this phone."
- **Account** — a section "ACCOUNT" with one row, not tappable: the person tile, the email (it wraps),
  and "Signed in with Google", "Signed in with email" or "Signed in with Google and email", from the
  session's identities.
- **This phone** — a section "THIS PHONE" of action rows (no chevron): "Switch account" · "Move this
  phone to another account"; "Sign out" · "Removes this phone's data · sign in again to get it back".
- **Delete** — a section "DELETE": "Delete account" · "Your account and its data, for good", a neutral
  action row; the danger colour is only the dialog's confirm.
- **Dialogs** — every command asks first, in the Reset dialog's form; the transition layer
  (SCR-ACCOUNT-003) shows what follows.
  - Switch: "Switch account?" · "This phone's data is replaced by the other account's after your
    changes are sent." · shield note "Your changes are sent first." · Cancel · "Switch account"
    (primary).
  - Sign out, online or nothing unsent: "Sign out?" · "Your changes are sent first, then this phone's
    data is removed. Sign in again to get it back." · Cancel · "Sign out" (warning). Offline with
    changes unsent: "Sign out and lose changes?" · "{n} changes aren't sent yet and will be lost." ·
    Cancel · "Sign out" (destructive). The network is read once as the dialog opens.
  - Delete: "Delete your account?" · "Your account and its decks, cards and progress are deleted from
    the server, and this phone's data is removed. This can't be undone." · Cancel · "Delete account"
    (destructive, trash icon). Offline: the note "Deleting your account needs a connection." and the
    confirm disabled.
  - Last admin: "An admin must remain" · "Give another person the admin role first, then delete the
    account." · OK. Opened by the app root on a refused deletion.
- **Toasts** — a command refused before anything changed: "No connection. Nothing changed; try again
  when you're online." or "Couldn't finish that. Nothing changed; try again."

The three command rows are disabled until the account is confirmed. One command runs at a time: a
tap while one asks or runs is ignored, so no second dialog opens.

## States

### `ready` · Ready

Golden: light, dark

### `validating` · Being confirmed

The connection note; the commands wait for a connection.

Golden: light, dark

### `reauth` · Sign-in expired

The banner; the commands wait. No method line: the refused session names none.

Golden: light, dark

### `switch_confirm` · Switch dialog

Golden: light, dark

### `sign_out_confirm` · Sign-out dialog

Online, or nothing unsent.

Golden: light, dark

### `sign_out_loss` · Sign-out dialog, changes lost

Offline with changes unsent.

Golden: light, dark

### `delete_confirm` · Delete dialog

Golden: light, dark

### `delete_offline` · Delete dialog, offline

The confirm disabled.

Golden: light, dark

### `last_admin` · Last admin

A refused deletion.

Golden: light, dark

## Controls

### Account state

- Type: read
- Invokes: FN-ACCOUNT-002

### Sign in (re-auth banner)

- Type: compact primary button

#### On success

- Navigate to: SCR-ACCOUNT-003 (re-auth, back to this page).

### Switch account

- Type: action row
- Enabled when: the account is confirmed and no command asks or runs.
- Purpose: opens the Switch dialog (`switch_confirm`).

### Switch account (Switch dialog)

- Type: dialog confirm
- Invokes: FN-ACCOUNT-007

#### On success

- The transition layer, then its target sign-in (SCR-ACCOUNT-003).

### Sign out

- Type: action row
- Enabled when: the account is confirmed and no command asks or runs.
- Purpose: opens `sign_out_confirm`, or `sign_out_loss` offline with changes unsent.

### Sign out (Sign-out dialog)

- Type: dialog confirm
- Invokes: FN-ACCOUNT-008

#### On success

- The transition layer; Navigate to: SCR-SETTINGS-002.

#### On failure

- `OfflineFailure`, `ServerFailure` → the layer stops and offers Retry.

### Delete account

- Type: action row
- Enabled when: the account is confirmed and no command asks or runs.
- Purpose: opens `delete_confirm`, or `delete_offline`.

### Delete account (Delete dialog)

- Type: dialog confirm (destructive)
- Enabled when: online.
- Invokes: FN-ACCOUNT-009

#### On success

- The transition layer; Navigate to: SCR-SETTINGS-002.

#### On failure

- `LastAdminFailure` → `last_admin`; `OfflineFailure` → "No connection. Nothing changed; try again
  when you're online."; `ServerFailure` → "Couldn't delete the account. Nothing changed."

### Cancel (any dialog), OK (`last_admin`)

- Type: dialog action
- Purpose: closes the dialog; nothing changes.

## Responsive Behavior

Follows the shared floor (DESIGN.md, SCREEN_CATALOG.md).

## Accessibility

Follows the shared floor (DESIGN.md, SCREEN_CATALOG.md).

## UI Invariants

| Invariant | Enforced by |
|---|---|
| Every command asks first. | — |
| One command at a time; a tap while one asks or runs opens nothing. | — |
| The commands wait until the account is confirmed. | — |
| Signing out offline with changes unsent names the loss. | — |
| Deleting needs a connection; offline its confirm is disabled. | — |
| The Delete row is neutral; only its dialog's confirm is destructive. | — |

## Copy

- "Account" · "ACCOUNT" · "THIS PHONE" · "DELETE".
- "Signed in with Google" · "Signed in with email" · "Signed in with Google and email".
- "Switch account" · "Move this phone to another account" · "Sign out" · "Removes this phone's data ·
  sign in again to get it back" · "Delete account" · "Your account and its data, for good".
- "Your sign-in expired. Your decks are still on this phone." · "Sign in" · "Managing your account
  needs a connection. Your decks are safe on this phone."
- Switch: "Switch account?" · "This phone's data is replaced by the other account's after your changes
  are sent." · "Your changes are sent first." · "Cancel" · "Switch account".
- Sign out: "Sign out?" · "Your changes are sent first, then this phone's data is removed. Sign in
  again to get it back." · "Sign out and lose changes?" · "{n} changes aren't sent yet and will be
  lost." · "Sign out".
- Delete: "Delete your account?" · "Your account and its decks, cards and progress are deleted from the
  server, and this phone's data is removed. This can't be undone." · "Deleting your account needs a
  connection." · "Delete account".
- Last admin: "An admin must remain" · "Give another person the admin role first, then delete the
  account." · "OK".
- Toasts: "No connection. Nothing changed; try again when you're online." · "Couldn't finish that.
  Nothing changed; try again." · "Couldn't delete the account. Nothing changed."

## Rulings

- **B1–B4, B6, B7, B12** (account UI spec §9): the method from the session; one network status; the
  commands wait until the account is confirmed; the sign-out's loss named offline; delete online
  only; the last admin a dialog; the Delete row neutral.
- **P3b plan rulings 1, 2, 4–7, 9:** the banner above the section; the email wraps; the redirect reads
  the account state; finished flows land on Settings; one confirm dialog in the Reset dialog's form;
  the last-admin dialog on the router's navigator; two icons (`switchAccount`, `signOut`).
- **P3b minor M3:** a tap while a command asks or runs is ignored.
- **Critique 2026-10-02 (spec `2026-10-02-critique2-fixes-design.md`), F3:** Switch account, Sign out
  and Delete account are action rows (no chevron); Sign out's hint reads "Removes this phone's data ·
  sign in again to get it back"; its online confirm is warning, the offline loss confirm destructive.

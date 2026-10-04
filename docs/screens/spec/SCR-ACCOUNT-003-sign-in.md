---
id: SCR-ACCOUNT-003
name: Sign-in, the merge sheet and the transition layer
domain: account
status: ready
route: [/settings/sign-in]
---

# Sign-in, the merge sheet and the transition layer

## Purpose

Attach Google or an email to this device's anonymous user (`mode=link`), or sign in again after the
session was refused (`mode=reauth`). The same form signs in a switch's target inside the transition
layer, and the merge sheet asks what happens to this phone's data when the sign-in already has an
account. On the root navigator with no bottom bar.

- **Link** — opened from the Account section's "Sign in" row of Settings (SCR-SETTINGS-002), Back
  returning there, and from Welcome's "Continue with email" (SCR-ACCOUNT-002), with Settings under it.
  A device that already holds an account is sent on to its Account page (SCR-ACCOUNT-005).
- **Re-auth** — opened from the re-auth banner's "Sign in" on Settings and on the Account page, and
  from the notice on Study home (SCR-STUDY-001), which opens it under Settings
  (`/settings/sign-in?mode=reauth&from=…`). A `from` outside the app (a scheme, a host, `//`) is
  ignored for Settings.
- **Transition layer** — over the whole app while a switch, a sign-out, a deletion or a clear runs. It
  is not a route: a host above the router shows it, hides the app from TalkBack, and takes the system
  Back before the router, so Back only steps from the code to the form inside it. Its content is
  centred in the page.

## Related Use Cases

None: the account feature has no use case; its behaviour follows the account UI and auth specs (see
`docs/functional-spec/account.md`).

## Layout

### Form

- **App bar** — back and "Sign in". In the layer there is no app bar, only "Cancel" (text) at the top.
- **Mode line** — link: "Your decks stay on this phone and join the account."; target: "Sign in to the
  account this phone moves to."; re-auth: "Sign in again to keep syncing. Your decks are still here."
- **Google** — an outline block button with the G mark, "Continue with Google".
- **Divider** — two hairlines and "or".
- **Email** — "Email address", a text keyboard; checked on send, its problem under the field. In
  re-auth it is filled with the last account's email; in the layer, with the target's.
- **Send code** — the form's one fill, a primary block button; it spins while sending and never greys
  out for a bad address.
- **Offline note** — "Signing in needs a connection. You can do it later in Settings." while the
  account cannot link yet (link only).
- **Continue without an account** — re-auth only: a text block button under the form.

### Re-auth dialogs

- **Another account, changes unsent** — "Lose {n} changes?" · "{n} changes on this phone aren't sent
  and will be lost." · Cancel · "Continue" (destructive). Signing in again to the same address asks
  nothing. Cancel forgets the Google account picked, so the next press shows the picker again.
- **Continue without an account** — "Continue without an account?" · "This phone's decks from {email}
  are removed. Sign in to {email} later to get them back." With changes unsent, a `danger` banner
  names them: "{n} changes on this phone aren't sent and will be lost." Cancel · "Continue without an
  account" (destructive).

### Merge sheet

- **Title** — "{email} already has an account" or "This Google account is already in use".
- **Choices** — two option rows: "Merge into the account" (selected) · "Your {n} decks and {m} cards
  join it." (or "This phone's decks and cards join it." when the count failed); "Discard this phone's
  data" · "They're removed from this phone. The account's decks come down instead."
- **Warning** — a `danger` banner "This phone's decks and progress go for good." only while Discard is
  chosen.
- **Footer** — Cancel · "Continue" (primary), or "Discard and continue" (destructive).

A phone with no live deck skips the sheet and moves at once.

### Transition layer

- **Running** — a large spinner, the step as a live region ("Sending your changes…", "Getting your
  decks ready…", "Merging…", "Downloading your decks…", "Signing out…", "Deleting your account…"),
  and "Nothing is lost if you close the app."
- **Network error** — a `warning` banner "No connection. Your data is safe on this phone." and Retry
  (primary).
- **Other error** — "Something went wrong. Your data is safe on this phone." and Retry.
- **Sign-out stopped offline** — "No connection. Nothing has been removed yet.", Retry, "Sign out now
  and lose {n} changes" (danger-soft) and Cancel (top bar).
- **Target sign-in** — the form in target mode, the address pre-filled; the code step on the layer's
  own navigator.
- **Stuck** — "Something went wrong while moving your account. Your data is safe on this phone." and
  Retry only.
- **Cancel** — at the top before the target signs in; it returns to where the switch started.

### Notices

At the app root: toasts "Couldn't merge. Your decks are still on this phone." and "Couldn't delete
the account. Nothing changed."; a refused deletion of the last admin is a dialog on the Account page
(SCR-ACCOUNT-005). After a sign-in: "Signed in as {email}" once the account is confirmed, "Signed in"
while it is still being checked; none while the account moves, which the layer speaks for.

## States

### `link` · Link

Golden: light, dark

### `invalid` · Invalid email

"Enter an email address, like name@example.com." under the field.

Golden: light, dark

### `reauth` · Re-auth

The re-auth line, the email filled, and Continue without an account under the form.

Golden: light, dark

### `unsent_loss` · Re-auth, changes unsent

The loss dialog.

Golden: light, dark

### `continue_without` · Re-auth, continue without an account

The dialog, with the `danger` banner when changes are unsent.

Golden: light, dark

### `merge_sheet_merge` · Merge sheet, merge

Golden: light, dark

### `merge_sheet_discard` · Merge sheet, discard

The `danger` banner and "Discard and continue".

Golden: light, dark

### `layer_sending` · Layer, sending

Golden: light, dark

### `layer_merging` · Layer, merging

Golden: light, dark

### `layer_offline` · Layer, offline

Golden: light, dark

### `layer_target` · Layer, target sign-in

Golden: light, dark

### `layer_sign_out_offline` · Layer, sign-out stopped offline

Golden: light, dark

### `layer_stuck` · Layer, stuck

Golden: light, dark

## Controls

### Account state

- Type: read
- Invokes: FN-ACCOUNT-002

### Continue with Google

- Type: outline block button
- Invokes: FN-ACCOUNT-005

#### On success

- Link: the toast; Navigate to: SCR-ACCOUNT-005. Re-auth: Navigate to: SCR-SETTINGS-002, or the `from`
  it came with (SCR-STUDY-001). Target: the layer goes on.

#### On failure

- `IdentityTakenFailure` → the merge sheet; `UnsentChangesFailure` → `unsent_loss`; a cancelled pick
  says nothing; `OfflineFailure` → "No connection. Nothing changed; try again when you're online.";
  `ServerFailure` → "Couldn't sign in. Nothing changed; try again." (toasts).

### Send code

- Type: primary block button
- Invokes: FN-ACCOUNT-003

#### On success

- Navigate to: SCR-ACCOUNT-004

#### On failure

- An address that is not one → `invalid`, nothing sent; `IdentityTakenFailure` → the merge sheet;
  `UnsentChangesFailure` → `unsent_loss`; `RateLimitedFailure` → "Too many tries. Wait a minute, then
  try again."; `OfflineFailure`, `ServerFailure` → their sentences.

### Continue (`unsent_loss`)

- Type: dialog confirm (destructive)
- Invokes: FN-ACCOUNT-003, FN-ACCOUNT-005
- Purpose: the same command again, with the loss confirmed.

### Cancel (`unsent_loss`)

- Type: dialog action
- Purpose: sends nothing and forgets the Google account picked.

### Continue without an account (`continue_without`)

- Type: dialog confirm (destructive)
- Invokes: FN-ACCOUNT-010

#### On success

- The layer clears; Navigate to: SCR-SETTINGS-002.

### Merge sheet choice

- Type: option rows
- Invokes: FN-ACCOUNT-006
- Purpose: the count is read when the sheet opens; a failed count still asks.

### Continue, Discard and continue (merge sheet)

- Type: sheet confirm
- Invokes: FN-ACCOUNT-007

#### On success

- The transition layer.

#### On failure

- `ClaimInvalidFailure` and a refused merge → the toast "Couldn't merge. Your decks are still on this
  phone."; `OfflineFailure`, `ServerFailure` → the layer's errors.

### Retry (layer)

- Type: primary button
- Invokes: FN-ACCOUNT-011

### Sign out now and lose {n} changes (`layer_sign_out_offline`)

- Type: danger-soft button
- Invokes: FN-ACCOUNT-008
- Purpose: the waiting sign-out goes on, with the loss accepted.

### Cancel (layer)

- Type: top-bar text button
- Enabled when: a switch has not signed in its target, or a sign-out waits with nothing removed yet.
- Invokes: FN-ACCOUNT-007, FN-ACCOUNT-008

#### On success

- The device returns to its account as it was; Navigate to: SCR-ACCOUNT-005 (where the switch or the
  sign-out started).

### Back

- Type: app-bar back / system Back
- Purpose: in the layer, steps from the code to the form only.

#### On success

- Navigate to: SCR-SETTINGS-002

## Responsive Behavior

Follows the shared floor (DESIGN.md, SCREEN_CATALOG.md).

## Accessibility

The layer hides the app from TalkBack; its step is a live region. Otherwise follows the shared floor
(DESIGN.md, SCREEN_CATALOG.md).

## UI Invariants

| Invariant | Enforced by |
|---|---|
| Send code never greys out for a bad address; the problem shows under the field. | — |
| Signing in to another account with changes unsent asks first and names how many. | — |
| Discard is destructive and warns only while chosen. | — |
| The layer holds Back and covers the app until the transition ends. | — |
| Every layer error says the data is safe on this phone. | — |

## Copy

- Form: "Sign in" · "Your decks stay on this phone and join the account." · "Sign in to the account
  this phone moves to." · "Continue with Google" · "or" · "Email address" · "Send code" · "Signing in
  needs a connection. You can do it later in Settings." · "Cancel".
- Problems: "Enter an email address, like name@example.com." · "Too many tries. Wait a minute, then
  try again." · "No connection. Nothing changed; try again when you're online." · "Couldn't sign in.
  Nothing changed; try again."
- Re-auth: "Sign in again to keep syncing. Your decks are still here." · "Continue without an account"
  · "Lose {n} changes?" · "{n} changes on this phone aren't sent and will be lost." · "Continue" ·
  "Continue without an account?" · "This phone's decks from {email} are removed. Sign in to {email}
  later to get them back."
- Merge sheet: "{email} already has an account" · "This Google account is already in use" · "Merge
  into the account" · "Your {n} decks and {m} cards join it." · "This phone's decks and cards join
  it." · "Discard this phone's data" · "They're removed from this phone. The account's decks come down
  instead." · "This phone's decks and progress go for good." · "Continue" · "Discard and continue".
- Layer: "Sending your changes…" · "Getting your decks ready…" · "Merging…" · "Downloading your
  decks…" · "Signing out…" · "Deleting your account…" · "Nothing is lost if you close the app." · "No
  connection. Your data is safe on this phone." · "Something went wrong. Your data is safe on this
  phone." · "No connection. Nothing has been removed yet." · "Sign out now and lose {n} changes" ·
  "Something went wrong while moving your account. Your data is safe on this phone." · "Retry".
- Toasts: "Signed in as {email}" · "Signed in" · "Couldn't merge. Your decks are still on this
  phone." · "Couldn't delete the account. Nothing changed."

## Rulings

- **R1:** no `mode=switch`: "Switch account" (SCR-ACCOUNT-005) signs in the target inside the layer.
- **R3:** a wrong and an expired code read alike; a rate limit asks to wait a minute.
- **R6:** a phone with no live deck skips the merge sheet.
- **B8, B9 and P3b plan rulings 3, 10:** the re-auth's loss question and its way out under the form;
  the link ends on the Account page; Study home's notice opens through Settings. Plan ruling 8 (no
  loss question on a resend) is retired by P3b minor M7.
- **P3b minor M1:** a `from` outside the app is ignored for Settings.
- **Final review I1, I2:** Cancel on the loss dialog forgets the Google account picked; continuing
  without an account names the unsent changes in a `danger` banner.
- **P3a plan rulings 1, 2, 7–10, 12, 14:** routes under Settings; the flow ends on the Account page
  (B9); a text keyboard; notices as toasts; Back held by the layer; a failed count still asks;
  Google's sheet title; the `danger` banner on Discard.
- **Impeccable after the build (F1):** the layer's content is centred, not top-aligned.
- **Critique 2026-10-02 (spec `2026-10-02-critique2-fixes-design.md`), F2:** a sign-out stopped offline
  says "No connection. Nothing has been removed yet." and offers Cancel beside Retry and "Sign out now
  and lose {n} changes"; Cancel keeps the account and every deck (auth spec #39a).

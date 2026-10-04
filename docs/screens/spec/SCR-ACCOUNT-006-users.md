---
id: SCR-ACCOUNT-006
name: Users (admin)
domain: account
status: ready
route: [/settings/users]
---

# Users (admin)

## Purpose

An admin finds any signed-in account by email and makes it an admin or a user. On the root navigator
with no bottom bar. Opened from the Admin section's "Users" row of Settings (SCR-SETTINGS-002), shown
only to an admin; Back returns there. A deep link meets the admin gate: a non-admin sees "Only an
admin can see this" under the app bar "Users".

## Related Use Cases

None: the account feature has no use case; its behaviour follows the users admin spec (see
`docs/functional-spec/account.md`).

## Layout

- **App bar** — back and "Users" (content density).
- **Search** — "Search by email"; it asks 400 ms after the last keystroke, and not at all when only
  spaces changed. Hidden in the not-admin state.
- **Overline** — "ACCOUNTS", with no count.
- **Rows** — list rows: the person tile (tinted, the same for all), the email, "Joined {date}" (the
  locale's medium date), and a badge "Admin" (primary) or "User" (neutral); no chevron. The admin's
  own row reads "Joined {date} · You" and does not tap; it is not dimmed.
- **End** — as on Monitoring (SCR-MONITORING-001): the next page loads near the end; "No more users";
  a failed page is a `danger` banner with Retry; a page refused as not an admin turns the screen to the
  not-admin state.
- **Role sheet** — the merge sheet's form: the email as the title; option rows "User" · "Studies and
  syncs their own decks" and "Admin" · "Sees logs and manages roles", the current role selected;
  Cancel · "Save" (primary), enabled only when the choice differs and spinning while it runs. While it
  runs the sheet is held: Back, a scrim tap and a drag wait, so the answer always has a sheet to be
  said in. A save lands over any list still loading, and "not an admin" over any page in flight.

## States

### `loaded` · Loaded

The admin's own row reads "You".

Golden: light, dark

### `empty_search` · No match

"No users match “{query}”".

Golden: light, dark

### `offline` · Offline

Golden: light, dark

### `role_sheet` · Role sheet

The current role selected; Save disabled.

Golden: light, dark

### `role_sheet_changed` · Role sheet, changed

The other role chosen; Save enabled.

Golden: light, dark

### `role_sheet_refused` · Role sheet, refused

A `warning` banner under the options: "An admin must remain. Make someone else an admin first."

Golden: light, dark

### `loading` · Loading

Skeleton list rows.

Golden: none — no golden in V8 (record 33)

### `no_accounts` · No accounts

"No accounts yet".

Golden: none — no golden in V8 (record 33)

### `error` · Error

"Couldn't load users" with Retry.

Golden: none — no golden in V8 (record 33)

### `not_admin` · Not an admin

The lock empty state, "Only an admin can see this"; no search.

Golden: none — no golden in V8 (record 33)

## Controls

### Search, list pages

- Type: search field / list
- Invokes: FN-ACCOUNT-012

#### On failure

- `NotAdminFailure` → `not_admin`; `OfflineFailure` → `offline`; `ServerFailure` → `error`; a failed
  next page → the `danger` banner with Retry.

### User row

- Type: list row
- Enabled when: the row is not the admin's own.
- Purpose: opens the role sheet (`role_sheet`).

### Save (role sheet)

- Type: sheet confirm
- Enabled when: the choice differs from the current role and no save runs.
- Invokes: FN-ACCOUNT-013

#### On success

- The sheet closes, the badge changes in place, and the toast "{email} is now an admin" or "{email} is
  now a user".

#### On failure

- `LastAdminFailure` → `role_sheet_refused`, the sheet stays; `AnonymousUserFailure` → the banner "This
  account isn't signed in with an email or Google.", the sheet stays; an account gone → the sheet
  closes, the toast "That account no longer exists.", the list reloads; `NotAdminFailure` → the sheet
  closes, `not_admin`; `OfflineFailure` → the banner "No connection. Nothing changed."; `ServerFailure`
  → the banner "Couldn't change the role. Nothing changed." A new choice clears the banner.

### Cancel (role sheet)

- Type: sheet action
- Enabled when: no save runs.

### Retry (`error`, a failed page)

- Type: button
- Invokes: FN-ACCOUNT-012

## Responsive Behavior

Follows the shared floor (DESIGN.md, SCREEN_CATALOG.md).

## Accessibility

Follows the shared floor (DESIGN.md, SCREEN_CATALOG.md).

## UI Invariants

| Invariant | Enforced by |
|---|---|
| Only an admin sees the list; a non-admin sees the lock state. | — |
| The admin's own row is read-only. | — |
| A role save that fails changes nothing and says why inside the sheet. | — |
| The sheet cannot be dismissed while a save runs. | — |
| The role lives in the badge alone. | — |

## Copy

- "Users" · "Search by email" · "ACCOUNTS" · "Joined {date}" · "Joined {date} · You" · "Admin" ·
  "User" · "No more users" · "No users match “{query}”" · "No accounts yet" · "Couldn't load users" ·
  "Retry" · "Only an admin can see this".
- Sheet: "User" · "Studies and syncs their own decks" · "Admin" · "Sees logs and manages roles" ·
  "Cancel" · "Save" · "An admin must remain. Make someone else an admin first." · "This account isn't
  signed in with an email or Google." · "No connection. Nothing changed." · "Couldn't change the role.
  Nothing changed."
- Toasts: "{email} is now an admin" · "{email} is now a user" · "That account no longer exists."

## Rulings

- **U1–U5** (users admin spec §1): the own row is read-only; Settings owns the Admin section; the
  data source follows Monitoring's; the route sits behind the admin gate.
- **Users admin spec §6 (shape):** Monitoring is the pattern: pages load at the end of the scroll, no
  "Load more" button; the role lives in the badge alone.
- **P4 plan rulings 1–6:** errors classified as auth errors; the gate takes a title; dates as the
  locale's medium date; the sheet runs the change; the Admin section is gated on the admin role; the
  `users` icon.
- **P4 minors M1–M3, M5:** a save lands over a list still loading; "not an admin" over any page in
  flight; the sheet is held while it saves; spaces alone ask nothing.
- **Final review I1, I2:** a page refused as not an admin turns the screen to `not_admin`; the last
  admin's refusal is a banner in the sheet, since a toast would sit behind it.

---
id: SCR-ACCOUNT-002
name: Welcome
domain: account
status: ready
route: [/welcome]
---

# Welcome

## Purpose

The first launch invites an account: the name, one promise, three benefits, and three ways on in the
thumb zone. Shown once per device, on a build that can sign in: until Welcome is answered, any
location opens Welcome first (`/welcome?from=<location>`). No back arrow: Android Back leaves the app,
as on any root.

## Related Use Cases

None: the account feature has no use case; its behaviour follows the account UI and auth specs (see
`docs/functional-spec/account.md`).

## Layout

- **Head** — a large tinted icon tile with the deck glyph, standing in for the app icon.
- **Name and promise** — "MemoX"; "Sign in to keep your decks safe and the same on every phone."
- **Benefits** — a section of three rows, not tappable: shield "Keep your decks when you reinstall";
  devices "Study on several phones"; cloud-off "Still works offline".
- **Offline note** — "Signing in needs a connection. You can do it later in Settings." Only while the
  account cannot link yet.
- **Actions** — a footer of three buttons, 12 apart: "Continue with Google" (primary, with Google's G
  mark: the one fill); "Continue with email" (outline); "Continue without an account" (text).
- **Toast** — "Signed in as {email}", or "Signed in" while the account is still being checked.

Every exit answers Welcome first, then goes on.

## States

### `ready` · Ready

Golden: light, dark

### `offline` · Offline

The offline note; signing in waits.

Golden: light, dark

## Controls

### Welcome shown

- Type: read
- Invokes: FN-ACCOUNT-001, FN-ACCOUNT-002

### Continue with Google

- Type: primary button
- Invokes: FN-ACCOUNT-005, FN-ACCOUNT-001

#### On success

- The toast; Navigate to: SCR-DECK-001 (the location Welcome stood in for, the Library by default).

#### On failure

- A Google account that belongs to another account opens the merge sheet (SCR-ACCOUNT-003); its
  choice also leaves Welcome. A cancelled pick says nothing; another failure is a toast.

### Continue with email

- Type: outline button
- Invokes: FN-ACCOUNT-001

#### On success

- Navigate to: SCR-ACCOUNT-003 (link mode, with Settings under it).

### Continue without an account

- Type: text button
- Invokes: FN-ACCOUNT-001

#### On success

- Navigate to: SCR-DECK-001 (the location Welcome stood in for).

## Responsive Behavior

Follows the shared floor (DESIGN.md, SCREEN_CATALOG.md).

## Accessibility

Follows the shared floor (DESIGN.md, SCREEN_CATALOG.md).

## UI Invariants

| Invariant | Enforced by |
|---|---|
| Welcome is shown once per device, including one that used the app before the update. | — |
| Every exit answers Welcome before it goes on. | — |
| Only a build that can sign in shows Welcome. | — |
| The Google button is the one fill. | — |

## Copy

"MemoX" · "Sign in to keep your decks safe and the same on every phone." · "Keep your decks when you
reinstall" · "Study on several phones" · "Still works offline" · "Continue with Google" · "Continue
with email" · "Continue without an account" · "Signing in needs a connection. You can do it later in
Settings." · "Signed in as {email}" · "Signed in".

## Rulings

- **U1:** shown once on every device, including one that used the app before the update.
- **U5:** the tile until MemoX has its own icon (UI-base row 149).
- **U6:** Google's G mark on the Google button.
- **P3a plan rulings 3, 4, 6:** only on a build that can sign in; the email exit lands on Sign-in over
  Settings; signing in waits, with a note, while the account cannot link yet.

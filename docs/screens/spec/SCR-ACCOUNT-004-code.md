---
id: SCR-ACCOUNT-004
name: Code
domain: account
status: ready
route: [/settings/sign-in/code]
---

# Code

## Purpose

The six digits sent to the address. Opened by "Send code" on Sign-in (SCR-ACCOUNT-003)
(`/settings/sign-in/code?mode=link&email=…`), on the root navigator; Back and "Use another email"
return to the form. Inside the transition layer, the target's sign-in opens it on the layer's own
navigator.

## Related Use Cases

None: the account feature has no use case; its behaviour follows the account UI and auth specs (see
`docs/functional-spec/account.md`).

## Layout

- **App bar** — back and "Enter the code" (content density).
- **Lead** — "Enter the 6-digit code sent to {email}".
- **Code** — a code field: six digits, a numeric keyboard, one-time-code autofill. Six digits check at
  once; a spinner shows while they do. A wrong code clears the field.
- **Resend** — a text button: "Resend code in 0:42", disabled, until the 60-second wait ends; then
  "Resend code", which toasts "A new code is on its way." and starts the wait again.
- **Another email** — a text button, "Use another email".

A right code attaches the account, toasts "Signed in as {email}" and closes the flow. While the
account is not yet confirmed the toast reads "Signed in"; while the account moves, such as a re-auth
switch that stopped on the way, there is none and the layer says what happened.

## States

### `waiting` · Waiting for the code

Golden: light, dark

### `wrong` · Wrong or expired

"That code is wrong or has expired. Check the latest email, or send a new code." The field is
cleared.

Golden: light, dark

### `verifying` · Verifying

The field disabled, a spinner under it.

Golden: none — no golden in V8 (record 31)

## Controls

### Code field

- Type: code field
- Invokes: FN-ACCOUNT-004
- Purpose: checks as soon as six digits are in.

#### On success

- Link: Navigate to: SCR-ACCOUNT-005. Re-auth: Navigate to: SCR-SETTINGS-002, or the `from` it came
  with. Target: the layer goes on.

#### On failure

- `InvalidCodeFailure` → `wrong`; `RateLimitedFailure` → "Too many tries. Wait a minute, then try
  again."; `OfflineFailure`, `ServerFailure` → their sentences.

### Resend code

- Type: text button
- Enabled when: the 60-second wait has ended.
- Invokes: FN-ACCOUNT-003

#### On success

- The toast "A new code is on its way."; the wait starts again.

#### On failure

- `UnsentChangesFailure` (a re-auth to another account with changes unsent) → Sign-in's loss dialog
  first; Cancel sends nothing.

### Use another email, Back

- Type: text button / app-bar back

#### On success

- Navigate to: SCR-ACCOUNT-003

## Responsive Behavior

Follows the shared floor (DESIGN.md, SCREEN_CATALOG.md).

## Accessibility

The code field reads "Code, 6 digits". Otherwise follows the shared floor (DESIGN.md,
SCREEN_CATALOG.md).

## UI Invariants

| Invariant | Enforced by |
|---|---|
| A wrong and an expired code read alike. | — |
| A wrong code clears the field. | — |
| Resend waits 60 seconds between sends. | — |

## Copy

"Enter the code" · "Enter the 6-digit code sent to {email}" · "Code, 6 digits" · "That code is wrong
or has expired. Check the latest email, or send a new code." · "Resend code in {m:ss}" · "Resend
code" · "A new code is on its way." · "Use another email" · "Signed in as {email}" · "Signed in".

## Rulings

- **R3:** "wrong or expired" is one state: the auth server answers both alike.
- **P3a plan ruling 11:** a wrong code clears the field.
- **P3b minor M7:** a resend to another account with changes unsent asks in Sign-in's loss dialog
  first, since a link may open this screen without passing the form's question.
- **P3b minor M2:** no toast while the account moves; the layer speaks for it.

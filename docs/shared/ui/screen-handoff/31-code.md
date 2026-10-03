<!-- Hand-written screen record. -->

# 31 · Code

The six digits sent to the address. SB-A2; spec
[2026-09-30-account-ui-design.md](../../../superpowers/specs/2026-09-30-account-ui-design.md)
§5.2, §6.

## Entry points

- Screen 30, "Send code". Route `/settings/sign-in/code?mode=link&email=…`, on the root
  navigator; Back and "Use another email" return to 30.
- The transition layer's target sign-in, on the layer's own navigator.

## Layout

| Region | Widget | Design |
|---|---|---|
| App bar | `MxAppBar` (content) + back | "Enter the code". |
| Lead | `emptyBody` | "Enter the 6-digit code sent to {email}". |
| Code | `MxTextField` (code) | Six digits, numeric keyboard, one-time-code autofill, TalkBack "Code, 6 digits". Six digits check at once; a spinner shows while they do. A wrong code clears the field (plan ruling 11) and keeps the keyboard; a code that could not be checked (offline, failed, rate limited) keeps its six digits, shows its problem in a warning `MxInlineBanner` with a compact "Retry" that checks them again, and leaves the field enabled (SP2b 2.45). The field takes the keyboard when the step opens. |
| Resend | `MxButton` (text) | "Resend code in 0:42", disabled, until the 60 s wait ends (counted from the last code sent, so leaving and coming back keeps what is left; a rate-limited resend starts the minute again: SP2b 2.41, 2.44); then "Resend code", which toasts "A new code is on its way." and starts the wait again. In a re-auth to another account with changes unsent, it first asks in screen 30's loss dialog; Cancel sends nothing (P3b minor M7). |
| Another email | `MxButton` (text) | "Use another email". |

A right code attaches the account, toasts "Signed in as {email}" and closes the flow on
Settings. While `me()` has not confirmed it yet the toast reads "Signed in"; while the
account moves, such as a re-auth switch that stopped on the way, there is none and the layer
says what happened (P3b minor M2). While a check or a resend runs, Back (the arrow and the system) waits (SP2b 2.46).

## States

The images are the goldens.

| State | Golden (light) | Golden (dark) | App |
|---|---|---|---|
| waiting | ![](../../../../test/features/account/presentation/goldens/code_waiting_light.png) | ![](../../../../test/features/account/presentation/goldens/code_waiting_dark.png) | Golden `code_waiting_*`. |
| wrong | ![](../../../../test/features/account/presentation/goldens/code_wrong_light.png) | ![](../../../../test/features/account/presentation/goldens/code_wrong_dark.png) | Golden `code_wrong_*`. |
| verifying | — | — | The field stays enabled, `MxSpinner` under it (2.45). |

## Rulings

- **R3:** "wrong or expired" is one state: GoTrue answers both alike.
- **P3a plan ruling 11:** a wrong code clears the field.
- **SP2b 2.41, 2.44, 2.45, 2.46:** the wait persists; a rate-limited resend waits a minute; the digits stay when the check could not run; Back waits.

## Copy

- "Enter the code" · "Enter the 6-digit code sent to {email}" · "Code, 6 digits".
- "That code is wrong or has expired. Check the latest email, or send a new code."
- "Resend code in {m:ss}" · "Resend code" · "A new code is on its way." · "Use another email".
- Kept digits: the problem line (offline, failed, rate limited) as on screen 30, and "Retry".

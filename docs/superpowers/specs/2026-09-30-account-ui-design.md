# Account UI: welcome, sign-in, code, account, transition layer (P3)

Status: approved 2026-09-30 in the P3 brainstorm; P3a implemented by
`docs/superpowers/plans/2026-09-30-account-ui-attach.md`; P3b rulings
approved 2026-09-30 (§9) and implemented by
`docs/superpowers/plans/2026-09-30-account-ui-manage.md`. An addendum to
[the auth spec](2026-09-30-auth-design.md): it settles §7 (router) and §8 (UI)
against what P2 built and against [`DESIGN.md`](../../../DESIGN.md), which is
now the UI authority
([ADR-019](../../shared/decisions/ADR-019-app-la-chuan-ui.md)); §8 was shaped
against the retired kit. Where this file and §7/§8 differ, this file wins.
Everything else in the auth spec stands.

## 1. Owner rulings (2026-09-30)

| # | Ruling |
|---|---|
| U1 | Welcome shows once on **every** device, including one that used the app before the update: `welcome_seen` stays `0` on upgrade, no backfill |
| U2 | Two shared additions, with `DESIGN.md` in the same PR: `MxTextFieldVariant.code` (one line, digits only, 6, centred, numeric keyboard, one-time-code autofill) and `MxButtonTone.text` (no fill, no edge, Indigo Ink label) |
| U3 | Two PRs: **P3a** the base and the attach flow, **P3b** account management (§7) |
| U4 | The transition layer is an **overlay at the app root** (auth spec §7), not a route, with its own `Navigator` |
| U5 | The launcher icon is still Flutter's default, so Welcome shows an `MxIconTile` (large, primary, the deck glyph) until a MemoX icon exists; recorded as UI-base debt |
| U6 | "Continue with Google" carries Google's **G mark** now: a PNG asset (1x–4x) rendered from the official G path, and a third shared change, an `MxButton` brand mark (an image painted at 18 in place of the icon), in `DESIGN.md` |

## 2. Rulings made in the brainstorm

Each can be overturned by the owner; the cost if wrong is in brackets.

- **R1 — no `mode=switch` route.** "Switch account" (32) confirms, then
  `beginSwitch(discard)`; the target sign-in happens inside the transition
  layer, as it must for a merge. Screen 30 has two modes, `link` and `reauth`.
  [One route and one copy line to add back.]
- **R2 — the re-auth banner follows `DESIGN.md`'s Feedback rule:** Settings
  (23) owns the problem and shows an `MxInlineBanner` (warning) in its Account
  section; Study home (13) does not and shows an `MxFloatingNotice` in the
  `MxAppShell.notice` slot. On 13 the re-auth notice takes the slot over the
  sync notice, since the expired sign-in is why sync stopped. [A slot rule.]
- **R3 — one "wrong or expired" code state.** Supabase answers `otp_expired`
  for both, and P2 has one `InvalidCodeFailure`. Rate limiting carries no
  wait (P2's `RateLimitedFailure` has none): the copy asks to wait a minute,
  and the 60 s resend countdown already paces the person. [Copy only.]
- **R4 — no text-scale-2.0 state.** `DESIGN.md`'s Wrap Rule (owner,
  2026-09-30): large text scales are not a design target. Text containers
  still grow and nothing is clamped. [Tests to add.]
- **R5 — the welcome's fallback target is `/decks`,** the app's initial
  location, not `/`. [A constant.]
- **R6 — merge counts come from the account feature's own read** of the
  local library (live decks and cards), not from another feature's code.
  Empty (no live deck) → no sheet, straight to `beginSwitch(discard)`.
  [A query.]

## 3. Structure

- **`lib/features/account/`** (ADR-010 layers, only what is used):
  - `data/`: one local data source over the Drift database for the welcome
    flag (`app_settings.welcome_seen`, a column update that no settings
    reset touches) and the library counts of R6.
  - `presentation/`: screens 29–32, their controllers, the merge sheet, the
    dialogs, the transition layer, the Settings section and the re-auth
    banner/notice. Commands and state come straight from P2's
    `accountCoordinatorProvider` and `authStateProvider`; no pass-through
    repository.
- **Shared** (`lib/shared/widgets/`): the additions of U2 and U6, each with a
  widget test, a gallery entry and a `DESIGN.md` line.
- **Providers**: the welcome flag (read in `main` before the first frame,
  like `readStartupSettings`, so nothing flashes) and the coordinator's
  `notices` as a stream provider.

## 4. Router

- **Routes**, all on the root navigator (no tab bar):
  `/welcome?from=<location>`, `/settings/account` (32),
  `/settings/sign-in?mode=link|reauth` (30) and
  `/settings/sign-in/code?mode=…&email=…` (31), under Settings so Back lands
  there (P3a plan ruling 1).
- `buildAppRouter` takes a read-only **account route guard**: the welcome
  flag, whether the device holds a permanent account, and a `Listenable`
  that fires when either changes (`refreshListenable`). Two rules only:
  - `welcome_seen == false` and not already on `/welcome` → `/welcome?from=`
    the requested location (a deep link survives);
  - `/settings/sign-in?mode=link` (and its code step) while the device holds
    an account → `/settings/account`; P3a sends it to `/settings` until
    screen 32 exists (P3a plan ruling 2).
- No other auth redirect: signing in stays optional, `ReauthRequired` shows
  banners (R2), and a transition shows the layer (§5.4).
- The admin gate (`MonitoringAdminGateWidget`) keeps reading `isAdminProvider`;
  `Validating` shows its loading state (auth spec §7).

## 5. Screens and flows

The copy below is the English source; Vietnamese goes in the ARB files with
the same meaning. Copy is local-first: what is kept before what is asked.

### 5.1 Welcome (29)

Top: the icon tile (U5) and "MemoX", three `MxIconTile` benefit rows (keep
your decks when you reinstall · study on several phones · still works
offline). Bottom, in the thumb zone: "Continue with Google" (primary, G
mark), "Continue with email" (outline) and "Continue without an account"
(text), 12 apart. No back; Android Back
leaves the app as on any root. Every exit sets `welcome_seen = 1` first,
then goes to `from ?? /decks`. Email opens 30 (`link`) above the welcome.

### 5.2 Sign-in (30) and code (31)

- The **sign-in form** (a presentation widget used by 30 and by the layer):
  a mode line, "Continue with Google" (outline, G mark), an "or" divider,
  the email `MxTextField` and "Send code" (primary, the screen's one fill).
  The email is checked on send; its error goes under the field
  (`MxFieldMessage`), and the button never greys out for it.
  - `link`: "Your decks stay on this phone and join the account."
  - `reauth`: "Sign in again to keep syncing. Your decks are still here."
  - target (inside the layer): "Sign in to the account this phone moves to."
- The **code form** (used by 31 and by the layer): "Enter the 6-digit code
  sent to {email}", the `code` field (TalkBack: "Code, 6 digits"); six digits
  submit at once. "Resend code" (text) counts down 60 s in its label. "Use
  another email" (text) returns to the email. States: sending, wrong or
  expired (R3), too many requests (R3), offline.
- **Link succeeds** → `Ready(account)`: the flow closes back to where it
  started and shows "Signed in as {email}".
- **Identity taken** (`IdentityTakenFailure`, #17): local has decks → the
  merge sheet (§5.3); empty → `beginSwitch(discard, targetHint: email)`.
- **Re-auth as another account** (`UnsentChangesFailure(n)`, P3b): a dialog
  "{n} changes on this phone aren't sent and will be lost." → the same
  command with `confirmedLoss: true`. `reauth` also offers "Continue without
  an account" (text) → confirm → `continueWithoutAccount()`.

### 5.3 Merge choice (sheet)

`MxBottomSheet`: "{email} already has an account". Two `MxOptionRow`s:
"Merge into the account" (selected by default) with "Your {n} decks and {m}
cards join it."; "Discard this phone's data" with "They're removed from this
phone. The account's decks come down instead." Selecting Discard shows an
`MxNote` warning and turns the confirm destructive. `MxSheetActions`:
Cancel · "Continue" (primary) or "Discard and continue" (destructive). The
confirm calls `beginSwitch(choice, targetHint: email)`. A destructive choice
takes two deliberate taps; the default stays merge (O4).

### 5.4 Transition layer

Over the whole app while `Transitioning`/`Recovering` holds a Switch,
SignOut, Delete or ClearToAnon (AnonRecovery stays silent: writes are
allowed). `PopScope` swallows Back; the status line is a live region.

| Condition | Shows |
|---|---|
| running | `MxSpinner`, the step ("Sending your changes…", "Merging…", "Downloading your decks…", "Signing out…", "Deleting your account…"), "Nothing is lost if you close the app." |
| `error` is a network failure | "No connection. Your data is safe on this phone." + Retry (`retry()`) |
| SignOut stopped on unsent changes offline | the above + "Sign out now and lose {n} changes" (`signOut(discardUnsent: true)`) |
| `isAwaitingTargetSignIn` | the sign-in form (target line) then the code form, inside the layer's own `Navigator`; Google reuses the account already picked; Cancel → `cancelSwitch()` |
| `Recovering.isStuck` | "Something went wrong while moving your account. Your data is safe on this phone." + Retry |

Notices (`MergeNotDone`, `DeleteRefused`) are read at the app root:
`MergeNotDone` → snackbar "Couldn't merge. Your decks are still on this
phone."; `DeleteRefused(LastAdmin)` → dialog "An admin must remain. Give
another person the admin role first."; any other `DeleteRefused` → snackbar
"Couldn't delete the account. Nothing changed."

### 5.5 Settings › Account (23, first section)

- Anonymous: "Sign in" / "Keep your decks if you reinstall or change phones"
  → 30 (`link`).
- Account: the email and "Google" or "Email"; in P3a a plain row, in P3b a
  chevron row → 32 (subtitle stays "Your decks sync to this account"; the
  method shows on 32, §9 B1).
- `ReauthRequired` (P3b): an `MxInlineBanner` (warning) at the top of the
  section: "Your sign-in expired. Your decks are still on this phone." ·
  "Sign in" → 30 (`reauth`).

### 5.6 Account (32, P3b)

`MxAppBar`, `MxSection` + `MxSettingsRow`: email, sign-in method, "Switch
account" → dialog "This phone's data is replaced by the other account's
after your changes are sent." → `beginSwitch(discard)` (R1). "Sign out" →
dialog "Your changes are sent first, then this phone's data is removed.
Sign in again to get it back." (offline with unsent changes: "{n} changes
aren't sent yet and will be lost." → `signOut(discardUnsent: true)`).
"Delete account" (destructive) → dialog naming what is deleted; offline the
confirm is disabled with "Deleting your account needs a connection."

P3b states and wiring are in §9.

### 5.7 Study home (13, P3b)

`ReauthRequired` → `MxFloatingNotice` in the notice slot (R2), same copy and
action as §5.5. The notice comes from the router as a slot (§9 B5).

## 6. Shape (Impeccable, 2026-09-30)

Critiqued against `DESIGN.md` and the goldens of 23, 27 and 13; the rulings
above already carry the outcome. Layout notes for the builder:

- **One Indigo Rule**: 29's one fill is Google; 30's is "Send code"; the
  merge sheet's is its confirm; the layer's is Retry.
- **Transition layer**: `surface` ground, content centred in the 720
  column: `MxSpinner`, the step in Title, the reassurance in Body variant
  ink. An error is an `MxInlineBanner` (warning: nothing was lost) with
  Retry (primary, block); the offline sign-out escape is `dangerSoft`. The
  target sign-in has no app bar: "Cancel" (text) at the top, then the form.
- **Code field** (`code` variant): Headline 24/700, tabular figures, wide
  tracking, centred. The resend countdown ("Resend code in 0:42") is a
  disabled text button until it reaches zero.
- **Settings › Account**: `MxSection` "ACCOUNT", first; `MxSettingsRow` with
  a person-glyph tile; the email wraps (`DESIGN.md`'s Wrap Rule; P3b plan
  ruling 2).
- **Re-auth on 23** (P3b): `MxInlineBanner` (warning) with "Sign in" as its
  action, leading the Account section (P3b plan ruling 1).
- **Debt** to record in the UI-base register (§9): the Welcome icon tile
  (U5).

## 7. Phasing

| PR | Scope | FE rows |
|---|---|---|
| P3a | U2 and U6 shared changes; welcome flag, route guard and routes; 29, 30 (`link`), 31; merge sheet; transition layer with every kind's copy (a launch may recover any kind); notices; Settings › Account section (anonymous row, plain account row) | new rows for 29–31 and the layer |
| P3b | 32 (switch, sign-out, delete); re-auth banner on 23 and notice on 13; 30 (`reauth`) with the unsent-loss dialog and "Continue without an account"; the Account row's chevron | new rows for 32 and re-auth; SB-A5 (in-app deletion) |

The device check of auth spec §9 closes P3 after the owner's SB-A4 setup;
it is recorded in the auth spec.

## 8. Verification

- Widget tests for every state of §5 in en; router tests (welcome once,
  deep link kept through `from`, `mode=link` redirect, no redirect in
  `ReauthRequired`); layer tests per kind, error, stuck and target sign-in;
  shared-widget tests for U2 and U6.
- Goldens: every new screen, the sheet and the layer's states, light and
  dark, English; rendered in the Linux container; a golden-compare page
  before the owner is asked to merge.
- Impeccable: critique and `shape` against `DESIGN.md` before the plan,
  critique and audit of the goldens after the build (one fix batch).
- Docs: detail files 29–32 in `docs/shared/ui/screen-handoff/`, their rows in
  the screen index, the FE rows in `docs/wbs_FE.md`, `DESIGN.md` for U2 and U6.

## 9. P3b rulings (2026-09-30)

Owner rulings from the P3b brainstorm (B1–B3), then the brainstorm's own
(B4–B11), each with its cost if wrong in brackets.

| # | Ruling |
|---|---|
| B1 | **Sign-in method** (P3a plan ruling 5) comes from the SDK session: `AuthGateway.signInMethods` returns a `Set<SignInMethod>` (`google`, `email`) read from the current user's identities. `AccountUser` and `me()` do not change; it works offline. Both → "Google · Email" |
| B2 | **`networkStatusProvider`** in `lib/core/network/di/`: one `NetworkStatus` shared by the coordinator and the UI. Screen 32's dialogs read `isOnline` once when they open (a hint: the coordinator checks again, and the layer still covers a connection lost midway) |
| B3 | **Screen 32 before `Ready`**: it always shows the email of the last known account. `Validating` → the three commands disabled, with an `MxNote` "Managing your account needs a connection. Your decks are safe on this phone."; `ReauthRequired` → the §5.5 `MxInlineBanner` on top, the three commands disabled. P2 is not changed (auth spec #39 needs `READY`) |
| B4 | **Sign-out dialog** on 32: online, or nothing unsent → the §5.6 copy and `signOut()`; offline with `n > 0` unsent → "{n} changes aren't sent yet and will be lost." with a destructive confirm and `signOut(discardUnsent: true)`. [Copy and one branch] |
| B5 | **Study home (13) gets the re-auth notice as a slot** (`reauthNotice`), built by the account feature in the router, like 23's `accountSection`; study reads core `authStateProvider` to know when it is `ReauthRequired`, and the notice then takes the slot over the sync notice (R2). Study never imports account. [One parameter] |
| B6 | **Delete dialog** names what goes: the account with its decks, cards and progress on the server, and this phone's data; it cannot be undone. One destructive confirm (the row tap plus the confirm are the two deliberate taps); no typed confirmation. Offline: the confirm is disabled with "Deleting your account needs a connection." [A second step to add] |
| B7 | **`DeleteRefused(LastAdmin)` becomes a dialog** (§5.4), replacing P3a's snackbar (P3a plan ruling 8); other refusals stay snackbars. [Back to a snackbar] |
| B8 | **30 `mode=reauth`** shows the reauth mode line (fixing P3a's deferred minor that it rendered the link form). `UnsentChangesFailure(n)` from Google or the code step → a dialog "{n} changes on this phone aren't sent and will be lost." → the same command with `confirmedLoss: true`. "Continue without an account" (text) → a confirm dialog → `continueWithoutAccount()`; the layer shows the ClearToAnon progress |
| B9 | **Where flows end**: the link flow ends on `/settings/account`, and `mode=link` while the device holds an account redirects there (P3a plan ruling 2). A re-auth returns to where it was opened (23, 13 or 32) with "Signed in as {email}". [A route constant] |
| B10 | **Switch account** keeps R1: the §5.6 dialog, then `beginSwitch(discard)`; the layer's target sign-in does the rest |
| B11 | **One PR**, no server change |

### 9.1 Shape (Impeccable, 2026-09-30)

Critiqued against `DESIGN.md` and the goldens of 23 (`settings_account_*`,
`settings_reset_confirm_*`) and 13 (`study_home_sync_*`); approved by the
owner. Every dialog follows 23's Reset dialog: a title ending in "?", the
body, an optional `MxNote`, then `MxSheetActions` (Cancel outline · confirm).

- **32 layout**, three `MxSection`s:
  - `ACCOUNT`: one plain row, the person-glyph tile, the email (it wraps,
    P3b plan ruling 2), subtitle "Signed in with Google" / "Signed in with
    email" / "Signed in with Google and email" (B1).
  - `THIS PHONE`: "Switch account" · "Move this phone to another account";
    "Sign out" · "Your changes are sent first".
  - `DELETE`, last, like 23's `RESET`: "Delete account" · "Your account and
    its data, for good". **B12 (owner): a neutral row** in its own section;
    the danger colour is only the dialog's confirm. `MxSettingsRow` gets no
    tone.
  - `Validating`: an `MxNote` on top (B3 copy), the action rows disabled.
    `ReauthRequired`: the §5.5 `MxInlineBanner` on top with "Sign in", the
    action rows disabled.
- **Dialogs** (32):
  - Switch: "Switch account?", the §5.6 body, a shield `MxNote` "Your
    changes are sent first.", confirm "Switch account" (primary).
  - Sign out, online: "Sign out?", the §5.6 body, confirm "Sign out"
    (**primary**: the data is safe on the server).
  - Sign out, loss (B4): "Sign out and lose changes?", "{n} changes aren't
    sent yet and will be lost.", confirm "Sign out" (destructive).
  - Delete: "Delete your account?", the body naming what goes (B6), no
    reassurance note, confirm "Delete account" (destructive, delete icon).
    Offline: an `MxNote` (offline glyph) "Deleting your account needs a
    connection." and the confirm disabled.
  - Last admin (B7): "An admin must remain", "Give another person the
    admin role first, then delete the account." (after the build: the §5.4
    body repeated the title), one "OK".
- **30 `reauth`**: the reauth mode line; **the email field starts with the
  last account's email** (the usual case is signing in again to the same
  account); "Continue without an account" (text) at the bottom of the
  thumb zone, as on 29.
  - Unsent loss (B8): "Lose {n} changes?", the §5.2 body, confirm
    "Continue" (destructive).
  - Continue without: "Continue without an account?", "This phone's decks
    from {email} are removed. Sign in to {email} later to get them back.",
    confirm "Continue without an account" (destructive).
- **23**: the warning banner leads the Account section, above its overline
  (`MxSection` has no header slot: P3b plan ruling 1, UI-base row 151); the
  account row gets its chevron. 32 places it the same way.
- **13**: the `MxFloatingNotice` of the sync notice's form, "Your sign-in
  expired. Your decks are still on this phone." with a compact primary
  "Sign in".

Verification adds to §8: goldens (light and dark, English) of 32 in `Ready`,
`Validating` and `ReauthRequired`; the switch, sign-out (online and loss),
delete (online and offline), last-admin, unsent-loss and continue-without
dialogs; 23 with the banner; 13 with the notice; 30 in `reauth`. Unit tests
for `signInMethods` and the network provider. Docs: `32-account.md`, updates
to the 13, 23 and 30 detail files, the screen index, and `docs/wbs_FE.md`
(FE-B10) with SB-A5 (in-app deletion) in `docs/wbs_supabase.md`.

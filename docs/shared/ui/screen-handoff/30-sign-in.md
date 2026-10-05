<!-- Hand-written screen record. -->

# 30 · Sign-in, the merge sheet and the transition layer

Attach Google or an email to this device's anonymous user (`link`), or sign in again
after the session was refused (`reauth`, P3b). The same form signs in the
switch's target inside the transition layer, and the merge sheet asks what happens to
this phone's data when the sign-in already has an account. SB-A2; spec
[2026-09-30-account-ui-design.md](../../../superpowers/specs/2026-09-30-account-ui-design.md)
§5.2–§5.4, §6, §9 (B8, B9), §9.1.

## Entry points

- Screen 23, Account section, row "Sign in". Route `/settings/sign-in?mode=link`, on the
  root navigator like Sync; Back returns to 23 (P3a plan ruling 1).
- Screen 29, "Continue with email" (`go`, so Settings sits under it).
- The transition layer, while a switch waits for its target sign-in.
- A device that already holds an account is sent from `mode=link` to screen 32 (P3b B9).
- `reauth`: the re-auth banner's "Sign in" on 23 and 32, and the notice on 13
  (`/settings/sign-in?mode=reauth&from=…`; from 13 it opens under Settings, P3b plan
  ruling 3). A re-auth that succeeds returns to `from`; the link ends on 32 (B9). A
  `from` outside the app (a scheme, a host, `//`) is ignored for Settings, as
  Welcome's is for the Library (P3b minor M1).

## Layout

The sign-in frame (sign-in redesign 2026-10-05, S6): the head (title and lead) and one task in
the body, the actions in an `MxFooterBar` that rides above the keyboard. `SignInFormWidget` is
the whole page.

| Region | Widget | Design |
|---|---|---|
| App bar | `MxAppBar` (content) + back | Back only, no title. The layer has no app bar, only "Cancel" (text) at the top. |
| Title | `screenTitle`, header semantics | "Sign in". |
| Lead | `emptyBody`, `control` (8) under the title | Link: "Your decks stay on this phone and join the account." Target: "Sign in to the account this phone moves to." |
| Email | `fieldLabel` + `MxTextField` (form), `section` (24) under the lead | The label "Email address" is painted above the field (`control`, 8, between) and stays the field's TalkBack name; the hint is "name@example.com". The field rests on the `outline` edge (`hasStrongEdge`, 3:1), not the ghost border (L1). Checked on send; its problem shows under the field (`MxFieldMessage`). Text keyboard (UI-base row 150). |
| Footer | `MxFooterBar` + `MxButton` × 2, `grouped` (12) apart | "Send code" (primary, block, the form's one fill; spins while sending and never greys out for a bad address); "Continue with Google" (outline, block, G mark; spins while picking). Its failure is a toast; a cancelled pick says nothing. No "or" divider (S8). While the keyboard is up the footer keeps "Send code" alone, so a low or landscape window keeps the field in view; Google returns when the keyboard goes (DEV-168). |
| Caption | `MxFooterBar` caption | "Signing in needs a connection. You can do it later in Settings." only while the account cannot link yet (`link` only). |

### Re-auth (`mode=reauth`, P3b)

| Region | Design |
|---|---|
| Eyebrow | "SIGNED OUT · {email}": the label upper-cased, the refused account's email as typed (never upper-cased), above the title (DEV-168). Absent when the email is unknown. |
| Title | "Sign in again". |
| Lead | "This phone was signed out, so syncing paused. Your decks are still here." |
| Email | Filled with the last account's email (the usual case signs in again to it). |
| Way out | `major` (32) under the field, in the body and out of the footer's thumb path (S9): "Continue without this account" (`MxButton` text, block). Opens "Continue without this account?" · "This phone's decks from {email} are removed. Sign in to {email} later to get them back." With changes unsent, a danger `MxInlineBanner` names them: "{n} changes on this phone aren't sent and will be lost." (final review I2), with no margin below it, so the actions sit 16 under it as under a body (L3). Cancel · "Continue without this account" (destructive), an even pair (L2): the long label stacks the two, Cancel on top. Then `continueWithoutAccount()`; the layer clears; the flow lands on 23. Welcome keeps "Continue without an account": that skip removes nothing. |
| Footer | As in the link table above. |
| Another account, changes unsent | A dialog "Lose {n} changes?" · "{n} changes on this phone aren't sent and will be lost." · Cancel · "Lose {n} changes" (destructive, naming what it loses, DEV-168), an even pair (L2), then the same command with the loss confirmed (B8). The same address asks nothing. Cancel forgets the Google account picked, so the next press shows the picker again (final review I1). |
| Code step (31) | A resend to another account names the unsent changes again, in the same dialog: a link may open 31 without passing here (P3b minor M7, which retires plan ruling 8). |

### Merge sheet (auth spec #17)

| Region | Widget | Design |
|---|---|---|
| Title | `compactTitle` | "{email} already has an account" or "This Google account is already in use" (plan ruling 12). |
| Choices | `MxOptionRow` × 2 | "Merge into the account" (selected) · "Your {n} decks and {m} cards join it." (or "This phone's decks and cards join it." when the count failed); "Discard this phone's data" · "They're removed from this phone. The account's decks come down instead." |
| Warning | `MxInlineBanner` (danger) | "This phone's decks and progress go for good." Only while Discard is chosen (plan ruling 14). |
| Footer | `MxSheetActions` (`isEvenSplit`) | Cancel · "Continue" (primary) or "Discard and continue" (destructive), an even pair (L2); the long label stacks them. The title starts 16 in, the edge of the rows and the banner (L4). |

A phone with no live deck skips the sheet and moves at once (R6).

### Transition layer (app root, U4)

Over the whole app while a switch, sign-out, deletion or clear runs. It is not a route:
a host above the router shows it, hides the app from TalkBack, and takes the system Back
with priority over the router (plan ruling 9), so Back never reaches the app beneath: it
steps from the code to the form, and at the layer's root it does what "Cancel" does while
Cancel shows; otherwise it is swallowed (DEV-167). The running, error and stuck states are centred in the page; the target
sign-in follows the sign-in frame (F1 below).

| Condition | Design |
|---|---|
| Running | `MxSpinner` (large), the step in `screenTitle` ("Sending your changes…", "Getting your decks ready…", "Merging…", "Downloading your decks…", "Signing out…", "Deleting your account…") as a live region, "Nothing is lost if you close the app." |
| Network error | `MxInlineBanner` (warning) "No connection. Your data is safe on this phone." centred; Retry (primary) in the `MxFooterBar` (L5). |
| Other error | "Something went wrong. Your data is safe on this phone." + Retry. |
| Sign-out stopped offline | "No connection. Nothing has been removed yet." centred; Retry and "Sign out now and lose {n} changes" (`dangerSoft`) in the footer (L5); Cancel at the top (critique 2026-10-02). |
| Target sign-in | The sign-in frame in target mode: "Cancel" (text) at the top in place of the back arrow, title "Sign in", lead "Sign in to the account this phone moves to.", the address pre-filled, the footer (Send code, Google) at the layer's bottom above the keyboard; the code step on the layer's own navigator. |
| Stuck | "Something went wrong while moving your account. Your data is safe on this phone." centred; Retry only, in the footer (L5). |
| Before the target signs in | "Cancel" at the top returns to where the switch started. |

Notices at the app root: toasts "Couldn't merge. Your decks are still on this phone." and
"Couldn't delete the account. Nothing changed." (plan ruling 8); a refused deletion of the
last admin is a dialog on screen 32's record (P3b B7).

## States

The images are the goldens.

| State | Golden (light) | Golden (dark) | App |
|---|---|---|---|
| link | ![](../../../../test/features/account/presentation/goldens/sign_in_link_light.png) | ![](../../../../test/features/account/presentation/goldens/sign_in_link_dark.png) | Golden `sign_in_link_*`. |
| invalid | ![](../../../../test/features/account/presentation/goldens/sign_in_invalid_light.png) | ![](../../../../test/features/account/presentation/goldens/sign_in_invalid_dark.png) | Golden `sign_in_invalid_*`. |
| merge sheet, merge | ![](../../../../test/features/account/presentation/goldens/merge_sheet_merge_light.png) | ![](../../../../test/features/account/presentation/goldens/merge_sheet_merge_dark.png) | Golden `merge_sheet_merge_*`. |
| merge sheet, discard | ![](../../../../test/features/account/presentation/goldens/merge_sheet_discard_light.png) | ![](../../../../test/features/account/presentation/goldens/merge_sheet_discard_dark.png) | Golden `merge_sheet_discard_*`. |
| layer, sending | ![](../../../../test/features/account/presentation/goldens/layer_sending_light.png) | ![](../../../../test/features/account/presentation/goldens/layer_sending_dark.png) | Golden `layer_sending_*`. |
| layer, merging | ![](../../../../test/features/account/presentation/goldens/layer_merging_light.png) | ![](../../../../test/features/account/presentation/goldens/layer_merging_dark.png) | Golden `layer_merging_*`. |
| layer, offline | ![](../../../../test/features/account/presentation/goldens/layer_offline_light.png) | ![](../../../../test/features/account/presentation/goldens/layer_offline_dark.png) | Golden `layer_offline_*`. |
| layer, target sign-in | ![](../../../../test/features/account/presentation/goldens/layer_target_light.png) | ![](../../../../test/features/account/presentation/goldens/layer_target_dark.png) | Golden `layer_target_*`. |
| layer, sign-out offline | ![](../../../../test/features/account/presentation/goldens/layer_sign_out_offline_light.png) | ![](../../../../test/features/account/presentation/goldens/layer_sign_out_offline_dark.png) | Golden `layer_sign_out_offline_*`. |
| reauth | ![](../../../../test/features/account/presentation/goldens/sign_in_reauth_light.png) | ![](../../../../test/features/account/presentation/goldens/sign_in_reauth_dark.png) | (P3b) Golden `sign_in_reauth_*`. |
| reauth, unsent loss | ![](../../../../test/features/account/presentation/goldens/sign_in_unsent_loss_light.png) | ![](../../../../test/features/account/presentation/goldens/sign_in_unsent_loss_dark.png) | (P3b B8) Golden `sign_in_unsent_loss_*`. |
| reauth, continue without | ![](../../../../test/features/account/presentation/goldens/sign_in_continue_without_light.png) | ![](../../../../test/features/account/presentation/goldens/sign_in_continue_without_dark.png) | (P3b B8) Golden `sign_in_continue_without_*`. |
| layer, stuck | ![](../../../../test/features/account/presentation/goldens/layer_stuck_light.png) | ![](../../../../test/features/account/presentation/goldens/layer_stuck_dark.png) | Golden `layer_stuck_*`. |

## Rulings

- **R1:** no `mode=switch`: "Switch account" (32, P3b) signs in the target inside the layer.
- **R3:** a wrong and an expired code read alike; a rate limit asks to wait a minute.
- **B8, B9 and P3b plan rulings 3, 10:** the re-auth's loss and way out; where flows end; 13 through Settings; the way out under the form. Plan ruling 8 (no loss question on a resend) is retired by P3b minor M7.
- **P3a plan rulings 1, 2, 7–10, 12, 14:** routes under Settings; the flow ended on Settings (now 32, B9); text keyboard; notices as toasts; Back held by the layer (at its root, Back is Cancel while Cancel shows, DEV-167); a failed count still asks; Google's title; the danger banner on Discard.
- **Polish 2026-10-05 (DEV-168):** the footer keeps "Send code" alone while typing; the loss dialog's confirm reads "Lose {n} changes"; the re-auth eyebrow is labelled "Signed out".
- **Layout balance 2026-10-05 (spec `2026-10-05-sign-in-layout-balance-design.md`, L1–L5):** the email field's outline edge, even confirm pairs, one gap above dialog actions, the merge sheet's one edge, and a stopped layer's actions in the footer (DEV-166, sign-in part).
- **Impeccable after the build (F1):** the layer's content is centred, not top-aligned (spec §6); the target sign-in follows the sign-in frame; F1 holds for the running, error and stuck states, whose content stays centred while a stopped layer's actions sit in the footer (layout balance 2026-10-05, L5).
- **Sign-in redesign 2026-10-05 (spec `2026-10-05-sign-in-flow-redesign-design.md`, S1–S10):** the page leads with its title and email field; "Send code" is the fill and Google the outline beside it (S7), the "or" divider is gone (S8), both ways sit in the footer above the keyboard (S6), the offline note is the footer caption, at full ink; the empty address takes the focus on link and target (a prefilled one, and re-auth, do not); the title names the route for TalkBack; re-auth gains the eyebrow, "Sign in again" and the way out named "Continue without this account", 32 under the field (S9); the transition layer's target sign-in uses the same frame.
- **Critique 2026-10-02 (spec `2026-10-02-critique2-fixes-design.md`):** a sign-out stopped offline says "No connection. Nothing has been removed yet." and offers Cancel (top bar) beside Retry and "Sign out now and lose {n} changes"; Cancel keeps the account and every deck (F2; auth spec #39a).

## Copy

- "Sign in" · "Your decks stay on this phone and join the account." · "Email address" (painted label) · "name@example.com" (hint) · "Send code" · "Continue with Google". "or" is gone.
- Problems: "Enter an email address, like name@example.com." · "Too many tries. Wait a minute, then try again." · "No connection. Nothing changed; try again when you're online." · "Couldn't sign in. Nothing changed; try again."
- Offline caption: "Signing in needs a connection. You can do it later in Settings."
- Re-auth: "SIGNED OUT · {email}" (eyebrow) · "Sign in again" · "This phone was signed out, so syncing paused. Your decks are still here." · "Continue without this account" · "Continue without this account?"; the loss confirm "Lose {n} changes"; the dialogs as in the table above.
- Toast: "Signed in as {email}" once `me()` confirmed the account, "Signed in" while it is still being checked; none while the account moves, such as a switch that stopped on the way, which the layer speaks for (P3b minor M2).
- Merge sheet and layer: as in the tables above.

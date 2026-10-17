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
- Screen 29, "Continue with email": pushed over where the launch was headed
  (`/settings/sign-in?mode=link&from=…`), so Back returns there and the link, its code
  and a switch it starts end there too, not on 32 (login navigation review 2026-10-08).
- The transition layer, while a switch waits for its target sign-in. A switch started by
  Google does not ask there: the Google account just picked signs in to the target at
  once, the layer's form showing Google running without taking the keyboard, then the
  progress; if that sign-in fails, the form stays to try again. A switch started by an
  email opens the layer on the code: the form sends that address's code itself, once
  (owner 2026-10-08).
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
| Title | `texts.screenTitle`, header semantics | "Sign in". |
| Lead | `texts.body` in `mutedForeground`, 8 under the title | Link: "Your decks stay on this phone and join the account." Target: "Sign in to the account this phone moves to." |
| Email | `MxTextField` (form; its painted label is the field's label role), 24 under the lead | The label "Email address" is painted above the field and stays the field's TalkBack name; the hint is "name@example.com". The field rests on the outline, as every field does (L1, made app-wide by DEV-166). Checked on send; its problem shows under the field (`MxFieldMessage`). Text keyboard (UI-base row 150). |
| Footer | `MxFooterBar` + `MxButton` × 2, 12 apart | "Send code" (primary, block, the form's one fill; spins while sending and never greys out for a bad address); "Continue with Google" (outline, block, G mark; spins while picking). Its failure is a toast; a cancelled pick says nothing. No "or" divider (S8). While the keyboard is up the footer keeps "Send code" alone, so a low or landscape window keeps the field in view; Google returns when the keyboard goes (DEV-168). |
| Caption | `MxFooterBar` caption | "Signing in needs a connection. Try later in Settings." only while the account is unavailable and cannot link (`link` only); not while it is still starting (Booting, Bootstrapping, Validating), where the ways are disabled and the caption waits (audit 2026-10-17 ACC-2). "Continue without this account" (re-auth) takes one tap at a time: a second tap while the question is being asked opens nothing (ACC-4). The layer's running step is spoken once, by its live region; the spinner carries no label (ACC-6). |

### Re-auth (`mode=reauth`, P3b)

| Region | Design |
|---|---|
| Eyebrow | `texts.meta` in `mutedForeground`. "SIGNED OUT · {email}": the label upper-cased, the refused account's email as typed (never upper-cased), above the title (DEV-168). Absent when the email is unknown. |
| Title | "Sign in again". |
| Lead | "This phone was signed out, so syncing paused. Your decks are still here." |
| Email | Filled with the last account's email (the usual case signs in again to it). |
| Way out | 32 under the field, in the body and out of the footer's thumb path (S9): "Continue without this account" (`MxButton` text, block). Opens "Continue without this account?" · "This phone's decks from {email} are removed. Sign in to {email} later to get them back." With changes unsent, a danger `MxInlineBanner` names them: "{n} changes on this phone aren't sent and will be lost." (final review I2), with no margin below it, so the actions sit 24 under it as under a body (L3, the Material 3 dialog gap). Cancel · "Continue" (destructive; the title asks the whole question, The Footer Pair Rule, DEV-169), an even pair (L2). Then `continueWithoutAccount()`; the layer clears; the flow lands on 23. Welcome keeps "Continue without an account": that skip removes nothing. |
| Footer | As in the link table above. |
| Another account, changes unsent | A dialog "Lose {n} changes?" · "{n} changes on this phone aren't sent and will be lost." · Cancel · "Lose" (destructive; the title names what it loses, DEV-179), an even pair, then the same command with the loss confirmed (B8). The same address asks nothing. Cancel forgets the Google account picked, so the next press shows the picker again (final review I1). |
| Code step (31) | A resend to another account names the unsent changes again, in the same dialog: a link may open 31 without passing here (P3b minor M7, which retires plan ruling 8). |

### Merge sheet (auth spec #17)

| Region | Widget | Design |
|---|---|---|
| Title | `texts.itemTitle` (the sheet's title) | "{email} already has an account" or "This Google account is already in use" (plan ruling 12). |
| Choices | `MxOptionRow` × 2 | "Merge into the account" (selected) · "Your {n} decks and {m} cards join it." (or "This phone's decks and cards join it." when the count failed); "Discard this phone's data" · "They're removed from this phone. The account's decks come down instead." |
| Warning | `MxInlineBanner` (danger) | "This phone's decks and progress go for good." Only while Discard is chosen (plan ruling 14). |
| Footer | `MxSheetActions` | Cancel · "Continue" (primary) or "Discard data" (destructive), an even pair (L2) on one row (The Footer Pair Rule, DEV-169; it was "Discard and continue"). The title starts 16 in, the edge of the rows and the banner (L4). |

A phone with no live deck skips the sheet and moves at once (R6).

### Transition layer (app root, U4)

Over the whole app while a switch, sign-out, deletion or clear runs. It is not a route:
a host above the router shows it, hides the app from TalkBack, and takes the system Back
with priority over the router (plan ruling 9), so Back never reaches the app beneath: it
steps from the code to the form, and at the layer's root it does what "Cancel" does while
Cancel shows; otherwise it is swallowed (DEV-167). While the target signs in (a Google
sign-in or a code being sent), Cancel stays but is disabled and Back is swallowed: a cancel
queued behind a sign-in that succeeds would be refused while the switch goes on (login
navigation review 2026-10-08). The running, error and stuck states are
centred in the page; the target sign-in follows the sign-in frame (F1 below).

| Condition | Design |
|---|---|
| Running | `MxSpinner` (large), the step in `texts.screenTitle` ("Sending your changes…", "Getting your decks ready…", "Merging…", "Downloading your decks…", "Signing out…", "Deleting your account…") as a live region, "Nothing is lost if you close the app." |
| Network error | `MxInlineBanner` (warning) "No connection. Your data is safe on this phone." centred; Retry (primary) in the `MxFooterBar` (L5). |
| Other error | "Something went wrong. Your data is safe on this phone." + Retry. |
| Sign-out stopped offline | "No connection. Nothing has been removed yet." centred; Retry and "Sign out now and lose {n} changes" (`dangerTint`) in the footer (L5); Cancel at the top (critique 2026-10-02). |
| Merge stopped on refused changes | "{n} changes on this phone were refused by the server and can't be merged." centred; Retry and "Continue and lose {n} changes" (`dangerTint`, keeps them on the device then retries) in the footer (L5); Cancel at the top. Retry alone would repeat the refusal (DEV-191). A discard switch goes on without stopping. |
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
| sending | — | — | After Send code: "Send code" spins (`isLoading`), "Continue with Google" is disabled, and the field stays as typed. Code read: `sign_in_form_widget.dart`; no golden. |
| Google running | — | — | After "Continue with Google": its button spins, "Send code" is disabled, the keyboard is not raised (also in the layer, where the picked account signs in at once), and the offline caption never shows (final review F2). `sign_in_screen_test.dart::while Google signs in, the link form never shows the offline caption (final review F2)`, `test/app/account_routes_test.dart::while the picked Google account signs in, the layer does not raise the keyboard (final review 2026-10-08, M2)`; no golden. |
| problem under the field | — | — | An address that is not an address (`invalid` above), no connection ("No connection. Nothing changed; try again when you're online."), a rate limit or any other failure shows under the field; a Google problem is a toast instead. `sign_in_screen_test.dart::offline says that nothing changed`; no golden for the last three. |
| waiting (offline caption) | — | — | `link` only: while the account cannot link yet the field and both buttons are disabled and the footer caption "Signing in needs a connection. Try later in Settings." shows; it clears when linking becomes possible. `sign_in_screen_test.dart::not ready to link: the form waits and says why`; no golden. |
| layer, merge stopped on refused changes | — | — | "{n} changes on this phone were refused by the server and can't be merged." with Retry and "Continue and lose {n} changes". `account_transition_layer_test.dart::a merge stopped on rows the server refused names them, and offers to lose them and go on (DEV-191)`; no golden. |

## Transitions

### The form (link, target, reauth)

| From | Event | To | Evidence |
|---|---|---|---|
| ready | tap Send code with a valid address | sending, then screen 31 | SB-A2. VERIFIED `sign_in_screen_test.dart::an address gets a code, and the code screen is next`; `sign_in_controller_test.dart::a free address gets a code` |
| ready | tap Send code with a mistyped address | invalid: nothing is sent | VERIFIED `::a mistyped address is said under the field, and nothing is sent`; `sign_in_controller_test.dart::a mistyped address is refused before anything is sent` |
| invalid | tap Send code with a valid address | sending (the old problem clears at once) | `UNVERIFIED (code read)`: `SignInController._run` replaces the state |
| sending | no connection, a rate limit or another failure | the problem under the field, ready again | VERIFIED `::offline says that nothing changed`; `sign_in_controller_test.dart::offline says offline`, `::a rate limit says so` |
| sending | the address belongs to another account | the merge sheet (a phone with decks), or the switch at once (an empty phone) | auth spec #17. VERIFIED `::another account's address asks to merge`; `sign_in_controller_test.dart::another account's address is identity taken, with nothing to say`; `merge_choice_sheet_test.dart::an empty phone moves without asking` |
| sending | a second press while it runs | ignored | VERIFIED `sign_in_controller_test.dart::a second press while one runs sends nothing (Review Focus 3)` |
| ready | tap Continue with Google | Google running | VERIFIED `::while Google signs in, the link form never shows the offline caption (final review F2)` |
| Google running | the account is attached | toast "Signed in as {email}"; the flow closes | VERIFIED `::Google attaches the account, says so and leaves`; `sign_in_controller_test.dart::Google attaches the account to this user` |
| Google running | the pick is cancelled | ready, nothing said | VERIFIED `sign_in_controller_test.dart::a cancelled Google pick says nothing` |
| Google running | the sign-in fails | ready, a toast with the problem | VERIFIED for the mark `sign_in_controller_test.dart::a Google failure is marked as Google's`; the toast is `UNVERIFIED (code read)` |
| Google running | the Google account belongs to another account | the merge sheet, or the switch at once on an empty phone | VERIFIED `sign_in_google_switch_test.dart::Google whose account is another account's signs in to it at once on an empty phone (owner 2026-10-08)` |
| merge sheet | Cancel | ready; nothing started; a Google pick is forgotten | VERIFIED `merge_choice_sheet_test.dart::Cancel starts nothing`; `welcome_screen_test.dart::Cancel on the merge sheet forgets the picked Google account: the next press shows the picker again` |
| merge sheet | Continue with Merge or Discard | the switch begins; the transition layer takes over; Discard first shows the danger banner and a destructive confirm | VERIFIED `merge_choice_sheet_test.dart::a phone with decks asks, and merge is the default`, `::discarding is its own choice, confirmed in the destructive tone` |
| merge sheet | the switch cannot begin | the sheet is gone, a toast with the failure, the form stays | `UNVERIFIED (code read)`: `startLinkSwitch` catches `Failure` and `StateError` |
| merge sheet | the count of decks fails | the sheet still asks, without numbers | VERIFIED `merge_choice_sheet_test.dart::Google's title, and a failed count still asks, without numbers` |
| (email switch) | the layer's form opens | it sends the code to the address already asked for, once, and opens on the code | owner 2026-10-08. VERIFIED `test/app/account_routes_test.dart::an email that already has an account gets its sign-in code at once, and the layer opens on the code (owner 2026-10-08)` |
| ready | the keyboard comes up | the footer keeps Send code alone; Google returns when it goes | VERIFIED `sign_in_layout_test.dart::while the keyboard is up the footer keeps Send code alone (DEV-168)`, `::a Google pick in flight keeps its spinning button while typing (final review M2)` |
| waiting | the account becomes able to link | ready | VERIFIED the waiting state `::not ready to link: the form waits and says why`; the return is `UNVERIFIED (code read)` (`canLinkProvider` drives `isEnabled`) |
| link | the device already holds an account | redirect to 32, or to `from` | P3b B9. VERIFIED `test/app/account_redirect_test.dart::the attach flow closes once the device holds an account`; `test/app/account_routes_test.dart::the attach flow is closed to a device that holds an account` |
| link | the code, the flow ends | 32 (from Settings) or `from` (from Welcome) | VERIFIED `test/app/account_routes_test.dart::Settings › Sign in, the code, and the flow ends on screen 32 showing the account (P3b B9)`; `test/app/account_flow_routes_test.dart::Welcome's email, its code, and the flow ends where the launch was headed, saying who signed in` |
| reauth | another address or Google account, changes unsent | the loss dialog | auth spec ruling 6. VERIFIED `::another address with changes unsent asks, then sends`; `sign_in_controller_test.dart::another address with changes unsent asks first`, `::Google as another account asks first too` |
| loss dialog | Lose | the command runs again with the loss confirmed | VERIFIED `::another address with changes unsent asks, then sends` |
| loss dialog | Cancel | ready; a Google pick is forgotten | VERIFIED `::a cancelled loss forgets the Google account, so the next press picks again (final review I1)` |
| reauth | the same address | a code with no word about loss | VERIFIED `sign_in_controller_test.dart::the same address gets its code without a word about loss (Review Focus 1)` |
| reauth | the refused account's address is not known yet | no eyebrow; the eyebrow and the field fill when it lands | VERIFIED `::a re-auth whose address is not known yet shows no eyebrow, then shows it when it lands` |
| reauth | tap Continue without this account | the way-out dialog (with the unsent banner when changes wait) | VERIFIED `::Continue without an account names the changes it loses (final review I2)`, `::re-auth names the account, says why, and keeps its way out in the body, out of the footer` |
| way-out dialog | Continue | the account is given up; the layer clears; the flow lands on 23 | B8. VERIFIED `::Continue without an account asks, then leaves the account` |
| way-out dialog | Cancel | reauth, nothing changed | `UNVERIFIED (code read)` |
| way-out running | the command is refused | a toast (offline or "Couldn't finish that. Nothing changed; try again.") | `UNVERIFIED (code read)`: `sayAccountResult` |
| way-out running | a second tap | ignored: the button is disabled while `isLeaving` | `UNVERIFIED (code read)`: `account_manage_controller_test.dart::a second command while one runs sends nothing (Review Focus 4)` pins the controller |
| reauth | the code, the flow ends | `from` (13 opens it under Settings), and Settings when `from` leaves the app | VERIFIED `test/app/account_routes_test.dart::a re-auth from Study home returns to Study home (P3b B9)`, `::a re-auth whose from leaves the app ends on Settings (P3b minor M1)` |
| any | Back | the page it was pushed over | `UNVERIFIED (code read)` for the bare Back; Welcome's push is VERIFIED `test/app/account_flow_routes_test.dart::Welcome's email opens the sign-in over where the launch was headed, and Back returns there` |

### The transition layer

| From | Event | To | Evidence |
|---|---|---|---|
| (a switch, sign-out, deletion or clear begins) | the coordinator enters a blocking state | layer, running: the step is named, closing loses nothing | U4. VERIFIED `account_transition_layer_test.dart::running, it names the step and says closing loses nothing`, `::a switch covers the app; Back steps from the code to the form, then acts as Cancel and puts the page back (Review Focus 2, DEV-167)`; the steps `account_step_state_test.dart::a switch sends, prepares, merges or downloads by its stage` |
| layer, running | the step advances | the next step's name, announced as a live region | `account_step_state_test.dart::sign-out sends first; deletion deletes first; both then sign out` for the names; the live region is `UNVERIFIED (code read)` |
| layer, running | offline or another failure | layer, offline / error: the banner and Retry | VERIFIED `::no connection says the data is safe, and Retry carries on` |
| layer, error | Retry | layer, running | VERIFIED same test |
| layer, running | the recovery is stuck | layer, stuck: Retry only | VERIFIED `::stuck says the data is safe and offers only Retry` |
| layer, running | a sign-out stops offline | layer, sign-out offline: Retry, "Sign out now and lose {n} changes", Cancel | VERIFIED `::a sign-out stopped offline says nothing is removed yet, and offers to lose the changes or cancel (critique 2026-10-02, F2)` |
| layer, sign-out offline | Cancel, or Back | the account and every change stay; the page returns | VERIFIED `::Cancel on a sign-out stopped offline keeps the account and everything on the phone (critique 2026-10-02, F2)`; `account_layer_back_test.dart::Back on a sign-out stopped offline does what Cancel does: the account and every change stay` |
| layer, sign-out offline | Sign out now | the sign-out goes on, the unsent changes lost | `UNVERIFIED (code read)`: `_SignOutNow`; the button's presence is VERIFIED in the test above |
| layer, merge stopped on refused changes | Continue and lose | the refused rows are kept on the device, then the switch retries | DEV-191. `UNVERIFIED (code read)` for the tap: `_SwitchLosing`; the offer is VERIFIED `::a merge stopped on rows the server refused names them, and offers to lose them and go on (DEV-191)` |
| layer, a sign-out still sending | | no Cancel | R4. VERIFIED `::a sign-out still sending offers no Cancel (R4)` |
| layer, running | Back with no Cancel showing | swallowed | VERIFIED `account_layer_back_test.dart::Back while the layer runs, with no Cancel, is swallowed`; `account_transition_layer_test.dart::a system back swipe at the layer root cancels it and never pops the page beneath; Back works again once the layer closes (DEV-167)`, `::while the layer shows, the framework takes Back, even over a root page (Android predictive back)` |
| layer, target sign-in | the target signs in | the code page closes itself; the switch runs on behind the progress | VERIFIED `::the layer signs in the target, and the switch finishes behind it` |
| layer, target sign-in | Cancel before the target signs in | the page where the switch began | VERIFIED the Back/Cancel test above |
| layer, target sign-in | Cancel or Back while the target signs in | disabled / swallowed | login navigation review 2026-10-08. VERIFIED `test/app/account_flow_routes_test.dart::the layer's Cancel and Back wait while its target signs in, so a switch is never cancelled behind a sign-in that goes on` |
| layer, target sign-in | Cancel is refused (the transition moved past) | no change | `UNVERIFIED (code read)`: `_cancel` returns on `StateError` and toasts a `Failure` |
| (the merge cannot finish) | the coordinator says it | toast "Couldn't merge. Your decks are still on this phone." | VERIFIED `::a refused merge is said once the device is back` |
| (a deletion is refused) | the last admin | the last-admin dialog, not a toast | P3b B7. VERIFIED `::a refused last-admin deletion is a dialog, not a toast (P3b B7)` |

## Rulings

- **R1:** no `mode=switch`: "Switch account" (32, P3b) signs in the target inside the layer.
- **Owner 2026-10-08 (device check of build 18):** a Google account that already has an account signs in to it at once, after the merge sheet when the phone has decks; asking for Google a second time on the layer read as "the sign-in did nothing". A failure leaves the layer's target sign-in and a toast with the problem. Email keeps its code, but its "Send code" is not asked twice: the layer sends the code to the address already typed and opens on the code (login navigation review 2026-10-08).
- **R3:** a wrong and an expired code read alike; a rate limit asks to wait a minute.
- **B8, B9 and P3b plan rulings 3, 10:** the re-auth's loss and way out; where flows end; 13 through Settings; the way out under the form. Plan ruling 8 (no loss question on a resend) is retired by P3b minor M7.
- **P3a plan rulings 1, 2, 7–10, 12, 14:** routes under Settings; the flow ended on Settings (now 32, B9); text keyboard; notices as toasts; Back held by the layer (at its root, Back is Cancel while Cancel shows, DEV-167); a failed count still asks; Google's title; the danger banner on Discard.
- **Polish 2026-10-05 (DEV-168):** the footer keeps "Send code" alone while typing; the loss dialog's confirm reads "Lose {n} changes" (DEV-179 later shortened it to "Lose"); the re-auth eyebrow is labelled "Signed out".
- **Layout balance 2026-10-05 (spec `2026-10-05-sign-in-layout-balance-design.md`, L1–L5):** the email field's outline edge, even confirm pairs, one gap above dialog actions, the merge sheet's one edge, and a stopped layer's actions in the footer (DEV-166, sign-in part).
- **Impeccable after the build (F1):** the layer's content is centred, not top-aligned (spec §6); the target sign-in follows the sign-in frame; F1 holds for the running, error and stuck states, whose content stays centred while a stopped layer's actions sit in the footer (layout balance 2026-10-05, L5).
- **Sign-in redesign 2026-10-05 (spec `2026-10-05-sign-in-flow-redesign-design.md`, S1–S10):** the page leads with its title and email field; "Send code" is the fill and Google the outline beside it (S7), the "or" divider is gone (S8), both ways sit in the footer above the keyboard (S6), the offline note is the footer caption, at full strength; the empty address takes the focus on link and target (a prefilled one, and re-auth, do not); the title names the route for TalkBack; re-auth gains the eyebrow, "Sign in again" and the way out named "Continue without this account", 32 under the field (S9); the transition layer's target sign-in uses the same frame.
- **Critique 2026-10-02 (spec `2026-10-02-critique2-fixes-design.md`):** a sign-out stopped offline says "No connection. Nothing has been removed yet." and offers Cancel (top bar) beside Retry and "Sign out now and lose {n} changes"; Cancel keeps the account and every deck (F2; auth spec #39a).

## Copy

- "Sign in" · "Your decks stay on this phone and join the account." · "Email address" (the field's painted label, 4 above the box on its 16 text inset) · "name@example.com" (hint) · "Send code" · "Continue with Google". "or" is gone.
- Problems: "Enter an email address, like name@example.com." · "Too many tries. Wait a minute, then try again." · "No connection. Nothing changed; try again when you're online." · "Couldn't sign in. Nothing changed; try again."
- Offline caption: "Signing in needs a connection. Try later in Settings."
- Re-auth: "SIGNED OUT · {email}" (eyebrow) · "Sign in again" · "This phone was signed out, so syncing paused. Your decks are still here." · "Continue without this account" · "Continue without this account?"; the loss confirm "Lose {n} changes"; the dialogs as in the table above.
- Toast: "Signed in as {email}" once `me()` confirmed the account, "Signed in" while it is still being checked; none while the account moves, such as a switch that stopped on the way, which the layer speaks for (P3b minor M2).
- Merge sheet and layer: as in the tables above.

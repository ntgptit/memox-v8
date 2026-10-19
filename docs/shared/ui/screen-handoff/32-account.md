<!-- Hand-written screen record. -->

# 32 · Account

The account this phone's data belongs to, and what can be done with it: switch, sign out,
delete. FE-B10, SB-A5; spec
[2026-09-30-account-ui-design.md](../../../superpowers/specs/2026-09-30-account-ui-design.md)
§5.6, §9, §9.1.

## Entry points

- Screen 23, the Account & sync section's account row once the device holds an account (its chevron; settings hub spec D7).
  Route `/settings/account`, on the root navigator; Back returns to 23.
- The link flow (29, 30, 31) ends here (B9).
- On a plainly anonymous device the route redirects to 23; during a transition it stays
  (P3b plan ruling 4). A finished sign-out, deletion or continue-without lands on 23
  (P3b plan ruling 5).

## Layout

| Region | Widget | Design |
|---|---|---|
| App bar | `MxAppBar` (content) + back | "Account". |
| Re-auth banner | `MxInlineBanner` (warning) | Only in `ReauthRequired`: "Your sign-in expired. Your decks are still on this phone." · "Sign in" (small primary) → 30 `reauth`, back to 32. |
| Connection note | `MxNote` | Only in `Validating`: "Managing your account needs a connection. Your decks are safe on this phone." |
| Account | `MxSection` "ACCOUNT" + `MxSettingsRow` | The person tile, the email (wraps, P3b plan ruling 2, breaking after the @ so the domain stays whole: `wrappableEmail`, audit 2026-10-19, G5), "Signed in with Google" / "with email" / "with Google and email" from the session's identities (B1). Not tappable. |
| This phone | `MxSection` "THIS PHONE" | "Switch account" · "Move this phone to another account"; "Sign out" · "Removes this phone's data · sign in again to get it back" (critique 2026-10-02). |
| Delete | `MxSection` "DELETE" | "Delete account" · "Your account and its data, for good". A neutral row; the danger colour is only the dialog's confirm (B12). |

The three command rows are disabled before `Ready` (auth spec #39 needs a confirmed
account). One command runs at a time: a tap while one asks or runs is ignored, so no second
dialog opens (P3b minor M3). Every command asks first, in the Reset dialog's form (§9.1, P3b plan ruling 6);
the transition layer shows what follows.

| Dialog | Design |
|---|---|
| Switch | "Switch account?" · "This phone's data is replaced by the other account's after your changes are sent." · shield note "Your changes are sent first." · Cancel · "Switch" (primary; the title names the account, DEV-179). Then `beginSwitch(discard)`; the layer's target sign-in (R1). |
| Sign out | Online, or nothing unsent: "Sign out?" · "Your changes are sent first, then this phone's data is removed. Sign in again to get it back." · "Sign out" (warning, critique 2026-10-02). Offline with n unsent: "Sign out and lose changes?" · "{n} changes aren't sent yet and will be lost." · "Sign out" (destructive), `discardUnsent` (B4). The network is read once as the dialog opens (B2). |
| Delete | "Delete your account?" · "Your account and its decks, cards and progress are deleted from the server, and this phone's data is removed. This can't be undone." · "Delete" (destructive, no icon; the title already names the account, so the confirm is the verb alone and shares the row 1 : 1 with Cancel, owner 2026-10-06, DEV-179). Offline: note "Deleting your account needs a connection." and the confirm disabled (B6). |
| Last admin | "An admin must remain" · "Give another person the admin role first, then delete the account." · OK. Opened by the app root on a refused deletion (B7, P3b plan ruling 7). |

A command refused before anything changed toasts "No connection. Nothing changed; try again
when you're online." or "Couldn't finish that. Nothing changed; try again."

## States

The images are the goldens.

| State | Golden (light) | Golden (dark) | App |
|---|---|---|---|
| ready | ![](../../../../test/features/account/presentation/goldens/account_ready_light.png) | ![](../../../../test/features/account/presentation/goldens/account_ready_dark.png) |  Golden `account_ready_*`. |
| validating | ![](../../../../test/features/account/presentation/goldens/account_validating_light.png) | ![](../../../../test/features/account/presentation/goldens/account_validating_dark.png) | The commands wait for a connection (B3). Golden `account_validating_*`. |
| reauth | ![](../../../../test/features/account/presentation/goldens/account_reauth_light.png) | ![](../../../../test/features/account/presentation/goldens/account_reauth_dark.png) | The banner; the commands wait (B3). No method line: the refused session names none. Golden `account_reauth_*`. |
| switch dialog | ![](../../../../test/features/account/presentation/goldens/account_switch_confirm_light.png) | ![](../../../../test/features/account/presentation/goldens/account_switch_confirm_dark.png) |  Golden `account_switch_confirm_*`. |
| sign-out dialog | ![](../../../../test/features/account/presentation/goldens/account_sign_out_confirm_light.png) | ![](../../../../test/features/account/presentation/goldens/account_sign_out_confirm_dark.png) | Online, or nothing unsent. Golden `account_sign_out_confirm_*`. |
| sign-out, loss | ![](../../../../test/features/account/presentation/goldens/account_sign_out_loss_light.png) | ![](../../../../test/features/account/presentation/goldens/account_sign_out_loss_dark.png) | Offline with changes unsent (B4). Golden `account_sign_out_loss_*`. |
| delete dialog | ![](../../../../test/features/account/presentation/goldens/account_delete_confirm_light.png) | ![](../../../../test/features/account/presentation/goldens/account_delete_confirm_dark.png) |  Golden `account_delete_confirm_*`. |
| delete, offline | ![](../../../../test/features/account/presentation/goldens/account_delete_offline_light.png) | ![](../../../../test/features/account/presentation/goldens/account_delete_offline_dark.png) | The confirm disabled (B6). Golden `account_delete_offline_*`. |
| last admin | ![](../../../../test/features/account/presentation/goldens/account_last_admin_light.png) | ![](../../../../test/features/account/presentation/goldens/account_last_admin_dark.png) | A refused deletion (B7). Golden `account_last_admin_*`. |
| command running | — | — | A dialog was confirmed and the command is going (`accountManageControllerProvider` is true): the three command rows are disabled until it returns; the transition layer then covers the screen. `account_manage_controller_test.dart::a second command while one runs sends nothing (Review Focus 4)`; no golden. |
| transitioning | — | — | The coordinator is in a blocking transition (a switch, sign-out or deletion): the commands are disabled because the state is not `Ready`, and the layer covers the app; the screen stays under it (P3b plan ruling 4). `account_redirect_test.dart::screen 32 needs an account; a transition keeps it (Review Focus 3)` (in `test/app/`); no golden of the screen itself. |
| command refused | — | — | A toast, with nothing changed: "No connection. Nothing changed; try again when you're online." (offline) or "Couldn't finish that. Nothing changed; try again." (any other failure, or the account no longer in `Ready`). `account_manage_controller_test.dart::a deletion refused offline says so, and nothing changed`, `::a command in the wrong state is a failure, not a crash`; the toast itself is `UNVERIFIED (code read)`: `sayAccountResult`. |

## Transitions

| From | Event | To | Evidence |
|---|---|---|---|
| (entry) | the device is plainly anonymous | redirect to 23 | P3b ruling 4. VERIFIED `test/app/account_redirect_test.dart::screen 32 needs an account; a transition keeps it (Review Focus 3)` |
| ready | tap Switch account | switch dialog | FE-B10. VERIFIED `account_screen_test.dart::Switch account asks, then starts the switch` |
| switch dialog | Cancel, Back or the scrim | ready, nothing started | `UNVERIFIED (code read)`: `confirmAccountStep` is true only on the confirm |
| switch dialog | Switch | command running, then transitioning: the layer's target sign-in (R1) | VERIFIED `::Switch account asks, then starts the switch` |
| ready | tap Sign out | the network is read once, then the sign-out dialog (warning), or the loss dialog (destructive) offline with changes unsent | B2, B4. VERIFIED `::Sign out online confirms in warning: nothing is lost, but the phone is cleared (critique 2026-10-02, F3)`, `::Sign out offline with unsent changes names the loss`; `account_manage_controller_test.dart::online, a sign-out loses nothing; offline, the unsent changes` |
| sign-out dialog | Cancel | ready, nothing started | `UNVERIFIED (code read)` |
| sign-out dialog | the confirm | command running, then transitioning; the changes are sent first | `UNVERIFIED (code read)` for the tap: `AccountScreen._signOut`; the layer is VERIFIED on 30 |
| sign-out dialog | the network goes after the dialog opened online | the sign-out stops on the unsent changes and the layer offers the loss | VERIFIED `account_manage_controller_test.dart::the network gone after the online dialog: the sign-out stops on the unsent changes and the layer offers the loss (Review Focus 2)` |
| ready | tap Delete account | the network is read, then the delete dialog; offline it shows the note and the confirm is disabled | B6. VERIFIED `::Delete offline cannot be confirmed`, `::Delete confirms with the short verb (owner 2026-10-06)`; `account_manage_controller_test.dart::a deletion needs the network` |
| delete dialog | Delete | command running, then transitioning | `UNVERIFIED (code read)` for the tap: `AccountScreen._delete` |
| transitioning (a deletion) | the server refuses: the last admin | the last-admin dialog from the app root, OK closes it | B7. VERIFIED `account_transition_layer_test.dart::a refused last-admin deletion is a dialog, not a toast (P3b B7)`; `account_confirm_dialog_test.dart::the last-admin dialog explains and closes on OK` |
| transitioning | finishes (sign-out, deletion, continue without) | 23, on an anonymous device | P3b ruling 5. VERIFIED `test/app/account_routes_test.dart::signing out from screen 32 lands on Settings`, `::signing out from screen 32 pushed over Settings leaves it (device check D6, F1)` |
| command running | a second tap on any command row | ignored: no second dialog | M3. VERIFIED `::a second tap while a command asks opens no second dialog (P3b minor M3)`; `account_manage_controller_test.dart::a second command while one runs sends nothing (Review Focus 4)` |
| command running | the command is refused (offline, failed, account not `Ready`) | command refused: a toast; the dialog's answer is not repeated | see the state row above; the controller side is VERIFIED |
| command running | the command meets a bug (not a `Failure`) | as a refused command: a toast; nothing is running any more; the bug is reported | VERIFIED `account_held_bug_test.dart::a command that dies on a bug is no longer running and says it failed (_run)`; the account not `Ready` (`StateError`) is the same answer, not reported, `::the account moving on is a failed command, not a bug` |
| ready | the connection check fails | validating: the commands wait and the note says why | B3. VERIFIED `::checked again offline: the commands wait and say why (Review Focus 5)` |
| validating | the account is confirmed | ready: the commands enable | `UNVERIFIED (code read)`: `canManage` follows `authStateProvider` |
| ready | the sign-in is refused | reauth: the banner, the commands wait | FE-B10. VERIFIED golden `account_reauth_*`; the banner and its Sign in `::an expired sign-in shows the banner, whose Sign in opens 30` |
| reauth | tap Sign in | 30 `reauth`; back to 32 when signed in again | B9. VERIFIED `::an expired sign-in shows the banner, whose Sign in opens 30`; the return is `UNVERIFIED (code read)` |
| any | the screen is left while a dialog or a command is open | the answer is dropped | `UNVERIFIED (code read)`: `context.mounted` after each `await` in `account_screen.dart` |
| any | Back | 23 | VERIFIED `test/app/account_routes_test.dart::Settings › the account row opens screen 32; Back returns` |

## Rulings

- **B1–B4, B6, B7, B12** (spec §9): the method from the session; one network status; the
  commands wait before `Ready`; the sign-out's loss named offline; delete online only; the
  last admin a dialog; the delete row neutral.
- **P3b plan rulings 1, 2, 4–7, 9:** the banner above the section; the email wraps; the
  redirect reads the coordinator; finished flows land on 23; one confirm dialog; the
  last-admin dialog on the router's navigator; two new icons (`switchAccount`, `signOut`).
- **Critique 2026-10-02 (spec `2026-10-02-critique2-fixes-design.md`):** Switch account, Sign out and Delete account are action rows (no chevron); Sign out's hint reads "Removes this phone's data · sign in again to get it back"; its online confirm is warning, the offline loss confirm destructive (F3).
- **Q-C-1 (owner, 2026-10-16):** the sign-out hint keeps each dot on the phrase before it (`metaDots`) (The Wrap Rule; `lib/l10n/meta_line.dart`).

## Copy

- "Account" · "ACCOUNT" · "THIS PHONE" · "DELETE".
- "Signed in with Google" · "Signed in with email" · "Signed in with Google and email".
- "Switch account" · "Move this phone to another account" · "Sign out" · "Your changes are
  sent first" · "Delete account" · "Your account and its data, for good".
- The dialogs' copy is in the table above.

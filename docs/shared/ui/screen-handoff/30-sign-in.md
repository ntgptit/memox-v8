<!-- Hand-written screen record. -->

# 30 · Sign-in, the merge sheet and the transition layer

Attach Google or an email to this device's anonymous user. The same form signs in the
switch's target inside the transition layer, and the merge sheet asks what happens to
this phone's data when the sign-in already has an account. SB-A2; spec
[2026-09-30-account-ui-design.md](../../../superpowers/specs/2026-09-30-account-ui-design.md)
§5.2–§5.4, §6.

## Entry points

- Screen 23, Account section, row "Sign in". Route `/settings/sign-in?mode=link`, on the
  root navigator like Sync; Back returns to 23 (P3a plan ruling 1).
- Screen 29, "Continue with email" (`go`, so Settings sits under it).
- The transition layer, while a switch waits for its target sign-in.
- A device that already holds an account is sent from the route to Settings (plan ruling 2).

## Layout

| Region | Widget | Design |
|---|---|---|
| App bar | `MxAppBar` (content) + back | "Sign in". The layer has no app bar, only "Cancel" (text) at the top. |
| Mode line | `emptyBody` | Link: "Your decks stay on this phone and join the account." Target: "Sign in to the account this phone moves to." |
| Google | `MxButton` (outline, block, G mark) | "Continue with Google". Its failure is a toast; a cancelled pick says nothing. |
| Divider | two hairlines + `footerCaption` | "or". |
| Email | `MxTextField` (form) | "Email address". Checked on send; its problem shows under the field (`MxFieldMessage`). Text keyboard (UI-base row 150). |
| Send code | `MxButton` (primary, block) | "Send code", the form's one fill; spins while sending and never greys out for a bad address. |
| Offline note | `MxNote` | "Signing in needs a connection. You can do it later in Settings." while the account cannot link yet. |

### Merge sheet (auth spec #17)

| Region | Widget | Design |
|---|---|---|
| Title | `compactTitle` | "{email} already has an account" or "This Google account is already in use" (plan ruling 12). |
| Choices | `MxOptionRow` × 2 | "Merge into the account" (selected) · "Your {n} decks and {m} cards join it." (or "This phone's decks and cards join it." when the count failed); "Discard this phone's data" · "They're removed from this phone. The account's decks come down instead." |
| Warning | `MxInlineBanner` (danger) | "This phone's decks and progress go for good." Only while Discard is chosen (plan ruling 14). |
| Footer | `MxSheetActions` | Cancel · "Continue" (primary) or "Discard and continue" (destructive). |

A phone with no live deck skips the sheet and moves at once (R6).

### Transition layer (app root, U4)

Over the whole app while a switch, sign-out, deletion or clear runs. It is not a route:
a host above the router shows it, hides the app from TalkBack, and takes the system Back
with priority over the router (plan ruling 9), so Back only steps from the code to the
form inside it. Its content is centred in the page.

| Condition | Design |
|---|---|
| Running | `MxSpinner` (large), the step in `screenTitle` ("Sending your changes…", "Getting your decks ready…", "Merging…", "Downloading your decks…", "Signing out…", "Deleting your account…") as a live region, "Nothing is lost if you close the app." |
| Network error | `MxInlineBanner` (warning) "No connection. Your data is safe on this phone." + Retry (primary). |
| Other error | "Something went wrong. Your data is safe on this phone." + Retry. |
| Sign-out stopped offline | The above + "Sign out now and lose {n} changes" (`dangerSoft`). |
| Target sign-in | The form above in target mode, the address pre-filled; the code step on the layer's own navigator. |
| Stuck | "Something went wrong while moving your account. Your data is safe on this phone." + Retry only. |
| Before the target signs in | "Cancel" at the top returns to where the switch started. |

Notices, as toasts at the app root: "Couldn't merge. Your decks are still on this phone.";
"An admin must remain. Give another person the admin role first."; "Couldn't delete the
account. Nothing changed." (plan ruling 8).

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
| layer, stuck | ![](../../../../test/features/account/presentation/goldens/layer_stuck_light.png) | ![](../../../../test/features/account/presentation/goldens/layer_stuck_dark.png) | Golden `layer_stuck_*`. |

## Rulings

- **R1:** no `mode=switch`: "Switch account" (32, P3b) signs in the target inside the layer.
- **R3:** a wrong and an expired code read alike; a rate limit asks to wait a minute.
- **P3a plan rulings 1, 2, 7–10, 12, 14:** routes under Settings; the flow ends on Settings; text keyboard; notices as toasts; Back held by the layer; a failed count still asks; Google's title; the danger banner on Discard.
- **Impeccable after the build (F1):** the layer's content is centred, not top-aligned (spec §6).

## Copy

- "Sign in" · "Your decks stay on this phone and join the account." · "Continue with Google" · "or" · "Email address" · "Send code".
- Problems: "Enter an email address, like name@example.com." · "Too many tries. Wait a minute, then try again." · "No connection. Nothing changed; try again when you're online." · "Couldn't sign in. Nothing changed; try again."
- Toast: "Signed in as {email}".
- Merge sheet and layer: as in the tables above.

# UI hardening after the 2026-10-02 critique, harden and audit — design

Status: approved 2026-10-03 (SP1 design) ·
Path: architectural, five sub-projects plus a final polish · Owner rulings 2026-10-03 (§3): R1–R7

## 1. Intent

On 2026-10-02/03 the owner ran three Impeccable passes over all 34 screens (01–33,
incl. 16a), after PR #188:

- **critique** (design and UX): 27/40, three P1s, about 70 Minor findings
  (snapshot `.impeccable/critique/2026-10-02T14-56-20Z__docs-shared-ui-screen-handoff-00-index-md.md`);
- **harden** (real data and real situations): no confirmed Critical, about 37 Major and
  40 Minor findings;
- **audit** (native technical): 15/20 (Accessibility, Performance, Theming, Platform,
  Adaptivity at 3 each), about 10 Major findings.

The owner put every finding in scope, Major and Minor (R1). This spec records the whole
backlog (§6) so it survives the session, splits it into five sub-projects (§4), and
designs the first one, Foundations, in detail (§5). SP2–SP5 each get their own
brainstorm, plan and PR, and add their design to this file or a sibling spec.

Success for the whole effort:

- every finding in §5 and §6 is fixed, or closed by a recorded owner ruling;
- `DESIGN.md`, the detail files and the screen index describe the app after the fixes;
- each PR passes `dod_check.sh` and the Linux goldens, and the owner sees the golden
  review page before it merges;
- a final `impeccable polish` pass and one `impeccable audit` run after SP5.

## 2. Sources

- Critique: the snapshot above (per-screen findings, heuristic table).
- Harden and audit: the reports of the 2026-10-02/03 session, transcribed into §6 with
  their evidence. Evidence was checked by the parent session for every Major; two harden
  Criticals on screen 11 were lowered to Major (the read path is guarded by
  `transfer_file_repository_impl.dart:96`; only `previewRows` can strand the spinner, on
  a database failure).
- Known debt that stays out: UI-base register §9 rows 1–5, 56–66, 146 (no two-pane
  layouts), 149 (launcher icon). Large text scales stay out (PRODUCT.md, owner
  2026-09-30).

## 3. Owner rulings (2026-10-03)

| # | Ruling |
|---|---|
| R1 | Every finding of the three passes is in scope, Minor included. |
| R2 | `MxFooterBar`'s caption drops `AppOpacity.muted` (3.50:1 in light) and reads at full `onSurfaceVariant` (7.2:1). `DESIGN.md` changes with it. |
| R3 | Starting a session while another deck's session is open asks first: "This ends your session in {deck}". |
| R4 | The bottom nav and rail stay custom. They gain tab-position semantics, lose the unused blur, and `DESIGN.md` records the exception to Material's `NavigationBar`. |
| R5 | Five sub-projects in the order of §4, then the polish pass. |
| R6 | SP1's design (§5) is approved. |
| R7 | A new toast keeps replacing the one on screen, Undo included (FE-B1 D14 stands). A trashed item stays recoverable for 30 days, and TalkBack is never held back by a queue. The harden finding "toast replacement drops Undo" is closed by this ruling. |

## 4. Decomposition

| # | Sub-project | Scope | Changes |
|---|---|---|---|
| **SP1** (§5) | Foundations | shared widgets, theme, Android resources, `DESIGN.md` rules | `lib/shared`, `lib/core/theme`, `lib/app`, `android/`, goldens |
| SP2 | Data safety and dead ends | every finding that loses typed content, strands a flow, shows a false state or acts on the wrong thing (§6.1) | controllers, repositories, a few widgets |
| SP3 | Library and cards UX (01–12) | the remaining findings of screens 01–12 (§6.2) | features, detail files, goldens |
| SP4 | Study UX (13–22) | the remaining findings of screens 13–22 (§6.3) | features, detail files, goldens |
| SP5 | Settings and account UX (23–33) and performance | the remaining findings of 23–33, and the performance findings (§6.4) | features, goldens |
| Final | Polish and one audit | the whole app | as found |

SP1 goes first because its shared fixes close many findings at once and its `DESIGN.md`
rules are what SP3–SP5 apply. Owner calls deferred to a later sub-project are in §7.

## 5. SP1 — Foundations

### 5.1 Overlays and input

1. **`MxDialog` clears the keyboard** (harden 01/05, audit Adaptivity P1).
   `showGeneralDialog` adds no inset, and `MxDialog` is a bare `Center`
   (`mx_dialog.dart:77`), so on a short phone the keyboard covers the actions of the five
   field dialogs (`deck_name_dialog_widget`, `create_root_deck_dialog_widget`,
   `card_tag_dialog_widget`, `tag_rename_dialog_widget`, `reminder_time_dialog_widget`).
   - Pad the dialog by `MediaQuery.viewInsetsOf(context).bottom` with an
     `AnimatedPadding` (`AppDurations.standard`, zero under `disableAnimations`).
   - Wrap it in `DisplayFeatureSubScreen` so it never straddles a hinge
     (`showDialog` does this; `showGeneralDialog` does not).
2. **`MxDialog.isHeld`** (harden 01/02/23 busy dialogs). A new `bool isHeld = false`
   wraps the dialog in `PopScope(canPop: !isHeld)`. A scrim tap goes through
   `Navigator.maybePop`, so the same scope blocks it. This mirrors `MxBottomSheet`'s
   `isHeld`. SP2 sets it on the dialogs that write.
3. **`MxStepper` commits what was typed** (harden 15, 23). Typed text reaches
   `onValueSubmitted` only on focus loss or Done (`mx_stepper.dart:85-121`), so Save can
   read the old value, and Back with the keyboard up drops it.
   - The field gets `onTapOutside: (_) => _focus.unfocus()`. Pointer-down on Save
     commits before Save's tap fires.
   - `deactivate()` submits when `_isEditing`. This covers a route pop with the keyboard
     up. The callback runs before the subtree is disposed.
4. **`MxScreenScroll` dismisses the keyboard on drag**
   (`keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag`, audit Platform).

### 5.2 Accessibility and platform

5. **Footer caption at full contrast** (R2; `mx_footer_bar.dart:51-58`). Remove the
   `Opacity`. `DESIGN.md` § Components → MxFooterBar drops "its caption at
   `AppOpacity.muted`".
6. **Contrast test gaps** (`test/core/theme/token_contrast_test.dart`). Add the footer
   caption, `statusReviewingInk`, `successInk`, `dangerInk`, the toggle thumb and the
   streak glyph, in both themes.
7. **Toggle thumb in dark** (2.90:1 on `primary`, `mx_toggle.dart:~88`). The ON thumb
   uses `onPrimary` in both themes.
8. **Streak glyph** (2.48:1 in light, `progress_streak_widget.dart:64,135`). Add a
   derived `streakInk` that pulls `streak` toward `onSurface` until it holds 3:1 on the
   card and its tint, the way `warningInk` does. Dark keeps the colour itself.
9. **Section headings** (audit A11y). `MxListSectionHeader` wraps its label in
   `Semantics(header: true)`. That covers its 35 call sites and every `MxSection` title.
   `MxDotOverline` and eyebrows are context lines, not headings, and stay as they are.
10. **Navigation semantics and the blur** (R4).
    - `MxBottomNav` and `MxNavRail` items read
      `MaterialLocalizations.of(context).tabLabel(tabIndex:, tabCount:)` after their
      label ("Library, Tab 1 of 4").
    - The `BackdropFilter` goes (`mx_bottom_nav.dart:67`). The bar is in-flow and never
      over content. The 84% surface stays, so the paint does not change.
    - `DESIGN.md` records why the bar is custom.
11. **System bars** (audit Platform/Theming P1-P2, unverified on device).
    - `MemoxApp`'s `MaterialApp.builder` wraps the child in
      `AnnotatedRegion<SystemUiOverlayStyle>` from the app theme's brightness, not the
      OS: transparent bars, icons opposite to the surface,
      `systemNavigationBarContrastEnforced: false`.
    - The Android launch window uses each theme's surface: a `colors.xml` in `values` and
      `values-night`, `launch_background.xml` filled with it, and `NormalTheme` using it.
    - `values-v31` and `values-night-v31` set `android:windowSplashScreenBackground`.
    - The launcher icon stays (§9 row 149).
12. **Route transitions honour Remove animations** (audit A11y). `AppTheme` sets a
    `pageTransitionsTheme` whose Android builder delegates to Flutter's default and
    returns the child unchanged when `MediaQuery.disableAnimationsOf` is true.
13. **Side insets** (audit Adaptivity). `MxAppShell` insets its body and footer by the
    start and end safe padding that remains (the app bar already does). This keeps
    content off an end-side cutout or 3-button bar in landscape.
14. **`AppTabShell` reads `MediaQuery.sizeOf`** for the breakpoint instead of
    `MediaQuery.of`, so an IME frame no longer rebuilds the nav (`app_tab_shell.dart:26`).

### 5.3 Theme, tokens, haptics and DESIGN.md rules

15. **Component slots** (audit Theming).
    - `progressIndicatorTheme` uses `primaryInk` for the admin screens'
      `RefreshIndicator`.
    - `textSelectionTheme` sets cursor and handles to `primaryInk` and the selection to
      primary at a new `AppOpacity.selection` rung of 0.24 (the Material default
      for selected text).
    - `deck_reorder_list_widget.dart:90` gets a flat `proxyDecorator`: a ghost edge, no
      lift.
16. **Tint rungs in `AppOpacity`** (audit Theming). The ~20 per-widget tint constants
    (`mx_badge.dart:38`, `mx_status_badge.dart:33`, `mx_empty_state.dart:66`,
    `mx_study_top_bar.dart:44`, `mx_action_sheet_command_row.dart:41`,
    `mx_outcome_tile.dart:28`, `mx_bottom_nav.dart:44-45`, `mx_nav_rail.dart:29-30`,
    `mx_skeleton.dart:28-30`, `mx_filter_chip.dart:36-37`,
    `card_removable_tag_chip_widget.dart:23`, `card_schedule_widget.dart:164`) become
    named rungs: `tintFaint` 0.08, `tintSoft` 0.10, `tintMedium` 0.12, and the nav pill
    pair. The values do not change, so no golden moves.
17. **`MxChipTrigger` reads as a control** (critique 28, owner R1).
    - It gains a 1px `ghostBorder` edge.
    - A new `isActive` flag, set while the chip holds a non-default choice, paints the
      `primaryContainer` ground with `onPrimaryContainer` ink.
    - `DESIGN.md` drops "it never reads as selected". Callers set `isActive` in SP3/SP5.
18. **Haptics** (audit Platform).
    - `HapticFeedback.selectionClick()` when a long-press starts a selection: the card
      list and the Trash.
    - `HapticFeedback.lightImpact()` when a grade commits (Self-assess, Recall) and when a
      Match pair is committed.
    - No other haptics.
19. **`DESIGN.md` rules** that SP3–SP5 apply. They are added under Do's and Don'ts and
    the named rules:
    - **Dynamic Color:** not used. The authored Tokyo palette is the identity.
    - **Offline is neutral:** no connection is an `MxNote` (neutral). Warning amber means
      a refusal, a limit or a loss; danger means a loss. This covers the Sync tile on
      23, Users offline on 33, the transition layer on 30, and the off-may-show banner
      on 24.
    - **A note says something new:** a note or banner states what the screen does not
      already show, and does not precede the decision it explains.
    - **A destructive confirm names the loss:** "Lose changes and continue", never
      "Continue".
    - **No overline over a one-row group:** a section of one row has no overline, unless
      the overline separates a destructive group.
    - **A leading tile varies or goes:** a row's lead tile appears only when its glyph
      or tone varies with the content.
    - **A footer caption adds a fact:** it never restates the button or contradicts the
      screen's state.
    - **An eyebrow sits inside its card.**

### 5.4 Testing

- Widget tests, one per behaviour:
  - the dialog clears a 300dp inset, and a held dialog ignores Back and the scrim;
  - the stepper commits on tap-outside and on deactivate;
  - the section header is a heading, and the nav item reads its tab position;
  - the page transition returns the child under `disableAnimations`;
  - the overlay style follows the app brightness;
  - the chip trigger's active state.
- Contrast pairs as in 6.
- Goldens regenerate in the Linux container. Expected movers are the footer caption, the
  chip trigger edge, the dark toggle thumb, the streak glyph and the reorder proxy. The
  owner gets the golden-compare page before the merge.
- The gate: `dod_check.sh`, then `run_goldens.sh`.

## 6. Backlog for SP2–SP5

Source: C critique, H harden, A audit. Severity as reported after the parent's check.

### 6.1 SP2 — data safety and dead ends

| # | Screen | Finding | Fix direction | Src · Sev | Evidence |
|---|---|---|---|---|---|
| 2.01 | 13/14 | Starting any session silently closes every open session, whatever its deck | R3 confirm on the start surface | H · Major | `study_entry_repository_impl.dart:433`, `study_session_queries.drift:75-81` |
| 2.02 | 14 | Try again after a failed start replays the old mode while a new one is selected | clear failed/refused on `pick()` | H · Major | `study_entry_controller.dart:113-118` |
| 2.03 | 14 | Deck gone while another route covers the entry → blank page, no action | render the gone state from the stream value | H · Major | `study_entry_screen.dart:442-445`, `study_entry_body_widget.dart:62` |
| 2.04 | 14 | Back or Study options during `starting` orphans a written session | hold back and options while starting | H · Minor | `study_entry_screen.dart:361-372` |
| 2.05 | 15 | `appSettingsProvider` error → endless skeleton | error branch with Retry for both | H · Major | `study_options_screen.dart:274-325` |
| 2.06 | 15 | Back after editing drops the draft silently | discard confirm when dirty | H · Minor | `study_options_screen.dart:287` |
| 2.07 | session | Deck-gone/reset event while the exit dialog is open → blank page, no exit | re-run leave when the dialog closes | H · Major | `study_session_screen.dart:170-219,230,267` |
| 2.08 | session | Stop's failure is silent; ✕ twice stacks two dialogs | toast on failure; one dialog at a time | H · Minor | `study_session_controller.dart:536-542`, screen `:89-94` |
| 2.09 | session | The last answer's double tap can hit the summary's Done | settle guard on the summary footer | H · Minor | `session_summary_widget.dart:76-95` |
| 2.10 | 16 | Double tap on Next skips an unseen card | settle guard keyed on the card | H · Minor | `study_browse_widget.dart:68-75,128-136` |
| 2.11 | 19 | The 20 s clock runs under the exit dialog; the turn times out unseen | pause while the route is not current | H · Major | `study_recall_widget.dart:129-149` |
| 2.12 | 19 | A failed reveal is silent and restarts the clock | show the write banner | H · Minor | `study_session_controller.dart:519-521` |
| 2.13 | 20 | Keyboard suggestions and autocorrect reveal or change the answer | `autocorrect:false`, `enableSuggestions:false` for the study variant | H · Major | `mx_text_field.dart:269-290` |
| 2.14 | 08/09 | Typed card content is lost on process death | restorable controllers or a keyed local draft | H · Major | `card_editor_form_widget.dart:64-103` |
| 2.15 | 08 | A deck that stops accepting cards strands the typed text | keep the draft; offer to copy the text | H · Major | `card_editor_form_widget.dart:203-255,324-332` |
| 2.16 | 08 | Cancel/close live during save; Discard after a save that lands | hold while saving | H · Minor | `card_editor_form_widget.dart:213-216,305-321` |
| 2.17 | 09 | A sync delete replaces the form and its edits | keep the form, banner above | H · Major | `card_editor_screen.dart:78-100` |
| 2.18 | 09 | Silent last-write-wins against a sync change | compare `updatedAt` at save | H · Minor | `card_repository_impl.dart:87` |
| 2.19 | 07/12 | Stale ids stay selected and make the whole bulk action fail | prune the selection on each emit | H · Major | `card_selection_state.dart:12-18`, `card_repository_impl.dart:94-104`, `card_transfer_repository_impl.dart:96-98` |
| 2.20 | 07 | Bulk Trash has no undo; its confirm carries no count | Undo for a batch; count in the confirm | H · Major | `card_delete_dialog_widget.dart:299-302`, `card_trashed_snackbar_widget.dart:277-296` |
| 2.21 | 07 | A refused bulk Tag does not say which cards are full | name the count refused | H · Minor | `card_tag_dialog_widget.dart:206-208` |
| 2.22 | 11 | `previewRows` throws on a database failure and leaves `isBusy` set | catch, set a problem, clear busy | H · Major | `card_import_controller.dart:136-156` |
| 2.23 | 11 | No size or row cap; the skipped-row list is an eager `Column` | reject over a cap with a typed reason; lazy list | H · Major | `import_file_picker_provider.dart:156-165`, `import_result_widget.dart:126-143` |
| 2.24 | 11 | A headerless file loses its first row as the header | default the header toggle from the mapping found | H · Major | `card_import_state.dart:267`, `card_import_controller.dart:101-110` |
| 2.25 | 11 | No undo after an import; no cancel before the write | "Undo import" on the result | H · Major | `import_commit_bar_widget.dart:312` |
| 2.26 | 01/02/05 | Writing dialogs can be dismissed mid-write and lose their toast | `MxDialog.isHeld` (SP1) on every writing dialog | H · Major | `deck_delete_dialog_widget.dart:182,230`, `create_root_deck_dialog_widget.dart:145`, `deck_reset_dialog_widget.dart:67` |
| 2.27 | 01/06 | Failures inside a dialog go to a toast under the scrim | `MxInlineBanner` with Retry inside the dialog | H · Minor | `create_root_deck_dialog_widget.dart:99`, `deck_name_dialog_widget.dart:275`, `deck_delete_dialog_widget.dart:199,218`, `deck_move_sheet_widget.dart:68` |
| 2.28 | 02 | A failed reset summary disables the confirm for good | Retry for the summary | H · Minor | `deck_reset_dialog_widget.dart:109-145` |
| 2.29 | 03 | A non-`Failure` exception holds the starter sheet forever | catch everything, set `hasFailed` | H · Major | `starter_add_controller.dart:43` |
| 2.30 | 06 | Auto-purge trusts the device clock; a forward jump deletes for good | skip the purge when the clock is implausible | H · Major | `purge_expired_trash_use_case.dart:15`, `trash_repository_impl.dart:50-52` |
| 2.31 | 06 | A blocked purge closes the dialog silently | toast naming the blocked item | H · Major | `trash_purge_dialog_widget.dart:273-282` |
| 2.32 | 06 | A deck purge confirm names no deck and no scope | name the deck, sub-decks and cards | H · Major | `trash_purge_dialog_widget.dart:299-302` |
| 2.33 | 23 | A failed reset closes the dialog; the toast's Retry skips the confirm | keep the dialog, inline error | H · Major | `settings_reset_dialog_widget.dart:445-450`, `settings_controller.dart:127-139` |
| 2.34 | 24 | A revoked notification permission still reads "On · 20:00" | read permission on open and resume; show the banner | H · Major | `android_reminder_platform_repository_impl.dart:28-41`, `reminder_status_model.dart:9-14` |
| 2.35 | 24 | Time dialog: an invalid flag never clears on step; Save stays off with no reason | clear on step; field message | H · Major | `reminder_time_dialog_widget.dart:403-452` |
| 2.36 | 24 | The denied banner stays after permission is granted in system settings | re-check on resume | H · Minor | `reminder_banners_widget.dart:297-303` |
| 2.37 | 27 | A sign-in failure offers only Sync now, which cannot succeed | a Sign in action; demote Sync now | H · Major | `sync_notice_widget.dart:41-47`, `sync_screen.dart:221-224` |
| 2.38 | 28 | A failed refresh replaces the loaded list | keep rows, banner with Retry | H · Major | `monitoring_list_controller.dart:82-88,148-162` |
| 2.39 | 28 | A lost admin role retries Mark fixed forever | map FORBIDDEN to not-admin | H · Minor | `monitoring_detail_controller.dart:225-230` |
| 2.40 | 29/30 | A cancelled merge keeps the picked Google credential; the picker never reopens | forget it whenever the follow-up is cancelled | H · Major | `merge_choice_sheet_widget.dart:45`, `account_coordinator_switch.dart:42-71` |
| 2.41 | 30/31 | Sending again to the same address inside a minute hits the rate limit | remember (email, sentAt) and reopen the code step | H · Major | `sign_in_controller.dart:38-47`, `code_controller.dart:22-30` |
| 2.42 | 30 | Server-rejected addresses read "try again" forever | map validation codes to `invalidEmail` | H · Major | `supabase_auth_errors.dart:46` |
| 2.43 | 30 | A stuck layer after the target signed in has Retry only | one escape path in the stuck state (owner call §7) | H · Major | `account_transition_layer_widget.dart:45-79,254` |
| 2.44 | 31 | A rate-limited resend re-enables Resend at once | restart the 60 s wait | H · Major | `code_controller.dart:83-91` |
| 2.45 | 31 | Any verify failure clears the code and drops focus | clear on wrong code only; keep focus; autofocus | H · Minor | `code_form_widget.dart:55-110` |
| 2.46 | 29/30/31 | Back during a running send, verify or link drops its outcome | hold Back while running, or announce from the root | H · Minor | `welcome_screen.dart:52`, `sign_in_form_widget.dart:79,97`, `code_screen.dart:376` |
| 2.47 | 32 | Delete with a dead session says "Nothing changed", which may be false | neutral "Sign in again to check" | H · Minor | `account_coordinator_leave.dart:155-161` |
| 2.48 | 33 | The role RPC has no explicit timeout; a short first page never loads more | timeout; load more after layout | H · Minor | `user_role_remote_data_source.dart`, `users_list_widget.dart:212-220` |
| 2.49 | 13 | Resume refused/failed toasts are not local-first | "Your answers are kept" | H · Minor | `study_home_screen.dart:289-292` |
| 2.50 | 22 | A stream error after data replaces the figures | keep the last value, banner | H · Minor | `progress_screen.dart:180-196`, `deck_progress_screen.dart:46-66` |
| 2.51 | 21 | The summary vanishes when its deck is lost | keep it; drop only Study this deck | H · Minor | `study_session_screen.dart:176-177` |

### 6.2 SP3 — Library and cards (01–12)

| # | Screen | Finding | Src · Sev |
|---|---|---|---|
| 3.01 | 01 | Due strip reads as an info banner, no verb | C · Minor |
| 3.02 | 01 | Three unlabeled app-bar glyphs; sparkles for Starter decks | C · Minor |
| 3.03 | 01 | "sub-deck" breaks at its hyphen; breakdown orphan | C · Minor |
| 3.04 | 01 | Sort sheet has four left edges; uneven option hints | C · Minor |
| 3.05 | 01 | Own trash shows "moved to Trash or deleted while you were away" | C · Minor |
| 3.06 | 01 | First-deck dialog: algorithm tray with no label, no description, locks after the first review | H · Major |
| 3.07 | 01 | Create deck/sub-deck gives no feedback; sort or filter can hide the new deck | H · Major |
| 3.08 | 01 | Name error stays while editing; only one validation per tap | H · Minor |
| 3.09 | 01 | Reorder disappears from the sheet without a reason | H · Minor |
| 3.10 | 02 | "Locked" said three times; the note points to a Reset far below | C · Minor |
| 3.11 | 02 | Reset dialog's half-width Kept/Lost tiles run five lines | C · Minor |
| 3.12 | 03 | "Required" caption with SM-2 preselected | C · Minor |
| 3.13 | 03 | "Suggests Eight boxes" sits below the add button | C · Minor |
| 3.14 | 03 | Identical sparkles tile on every template | C · Minor |
| 3.15 | 04 | Idle hint rows look tappable; examples hard-coded in KO/VI | C · Minor |
| 3.16 | 04 | Accent rule stated three times; permanent results footer | C · Minor |
| 3.17 | 04 | " · empty" reads as a path segment | C · Minor |
| 3.18 | 04 | Rows flip to skeletons on every keystroke after the debounce | H · Minor |
| 3.19 | 05 | Row tap opens the same menu as ⋮; seeing a tag's cards takes two taps | C · Minor |
| 3.20 | 05 | "Find cards with this tag" runs a text search ("verb" finds "adverb", decks) | H · Major |
| 3.21 | 05 | Delete dialog says "no card is changed" while removing the tag from them | C · Minor |
| 3.22 | 05 | Merge state stacks label, counter, panel, chips, two sentences | C · Minor |
| 3.23 | 05 | Empty state's "Go to library" does not lead to where tags are made | C · Minor |
| 3.24 | 05 | Rename/merge success is silent; Done ignored in the first 250 ms | H · Minor |
| 3.25 | 06 | Newest first hides "1h left"; no expiring-first order | C · Minor |
| 3.26 | 06 | No select-all, no empty-trash | C · Minor |
| 3.27 | 06 | "2 cards selected" over a "2 CARDS" header | C · Minor |
| 3.28 | 06 | Retention note and warning banner push the list to 43% | C · Minor |
| 3.29 | 06 | A backward clock prints "-5 minutes ago" | H · Minor |
| 3.30 | 07 | Hero and chips leave three rows above the fold | C · Minor |
| 3.31 | 07 | Status stated twice per row (NEW + New) | C · Minor |
| 3.32 | 07 | "All 3" next to "Showing 3 of 4" | C · Minor |
| 3.33 | 07 | Bulk-fail banner "Couldn't finish that." names no action | C · Minor |
| 3.34 | 07 | Selection (the only way to move, flag, tag, export, trash) is never taught | H · Major |
| 3.35 | 07 | Search no-match has no Clear action; tag filter not mentioned | H · Minor |
| 3.36 | 07 | A list error replaces the list and the hidden selection | H · Minor |
| 3.37 | 08 | Label, Required and an empty-state counter on each field | C · Minor |
| 3.38 | 08 | ✕ and Cancel both exit through the same guard | C · Minor |
| 3.39 | 08 | No duplicate-term hint on manual create (owner call §7) | H · Minor |
| 3.40 | 08 | "Save and keep adding" wipes tags too | H · Minor |
| 3.41 | 09 | The app-bar flag looks instant but is a draft change | C · Minor |
| 3.42 | 09 | "New · 0 answers · 0 lapses" row on a never-studied card | C · Minor |
| 3.43 | 09 | No success feedback for a flag-only or tag-only save; Trash from the editor drops edits unsaid | H · Minor |
| 3.44 | 10 | History kind heavier than its outcome; unlabeled "Recall Box 4→5" | C · Minor |
| 3.45 | 10 | Two identical stacked overlines | C · Minor |
| 3.46 | 11 | Mapping trigger is bare text, weakest in its row (P1) | C · Major |
| 3.47 | 11 | Four orientation layers before content | C · Major |
| 3.48 | 11 | Empty-state card under "Choose a file" is not tappable | C · Minor |
| 3.49 | 11 | File chip repeats on steps 2–3 | C · Minor |
| 3.50 | 11 | Partial result hero takes 30% with no number | C · Minor |
| 3.51 | 12 | Count in both title and button | C · Minor |
| 3.52 | 12 | Terminal error keeps the dimmed formats | C · Minor |
| 3.53 | 12 | "Export" opens the share sheet unannounced | C · Minor |
| 3.54 | 12 | Very large export holds every row and the file in memory | H · Minor |

### 6.3 SP4 — Study (13–22)

| # | Screen | Finding | Src · Sev |
|---|---|---|---|
| 4.01 | 13 | Eyebrow outside one hero card, inside the other | C · Minor |
| 4.02 | 13 | Filled pause tile competes with Resume | C · Minor |
| 4.03 | 14 | "Start a new review instead" hides that it ends the open session | C · Minor |
| 4.04 | 14 | Stat tiles off the card's text edge | C · Minor |
| 4.05 | 14 | only_new: inert Learn row; orphaned caption word | C · Minor |
| 4.06 | 14 | Eight-box note repeats the row reason and sits under the footer | C · Minor |
| 4.07 | 15 | Four-line scope note precedes the toggle; pushes the tray under the footer | C · Minor |
| 4.08 | 15 | "Saved to this device only" under "Not saved" and beside a disabled Save | C · Minor |
| 4.09 | 15 | Error title borrowed from Settings; invalid typed limit shows the old number | H · Minor |
| 4.10 | 16 | Last card still says "Next card" | C · Minor |
| 4.11 | 16 | Looking back is swipe-only | C · Minor |
| 4.12 | 16 | Browse failure banner says "Your answer is kept" | H · Minor |
| 4.13 | 16a | A relearning card looks like a scheduled one | C · Minor |
| 4.14 | 17 | Matched tiles louder than the remaining ones | C · Minor |
| 4.15 | 17 | A selected tile cannot be deselected; a mis-tap costs a lapse | H · Minor |
| 4.16 | 17 | One long meaning sets every row's height | H · Minor |
| 4.17 | 18 | Prompt card takes 49% for one word | C · Minor |
| 4.18 | 18 | With long options the right one can be below the fold when the hold ends | H · Minor |
| 4.19 | 19 | Turn clock looks like the session track; stale "9s/20s" after reveal | C · Minor |
| 4.20 | 20 | Accent rule told only after a miss | C · Minor |
| 4.21 | 20 | Wrong answer does not mark where the spelling differs | C · Minor |
| 4.22 | 20 | Using the hint collapses the CTA row; "Noted; it changes nothing" | C · Minor |
| 4.23 | 20 | One-line field hides the start of a multi-word answer | H · Minor |
| 4.24 | 20 | Landscape with the keyboard leaves the faces no height | A · Major |
| 4.25 | 21 | "3 of 23 wrong turns", no accuracy, no next due (carried) | C · Major |
| 4.26 | 21 | Footer caption restates Done | C · Minor |
| 4.27 | 21 | Non-plural "The 1 cards"; "0 finished" contradicts Answered | H · Minor |
| 4.28 | 21 | "At the session limit" when due equals the limit exactly | H · Minor |
| 4.29 | 22 | Streak nested three deep; two overlines | C · Minor |
| 4.30 | 22 | "17" has no noun; the unit line strands "day" | C · Minor |
| 4.31 | 22 | Weekday initials "S S" | C · Minor |
| 4.32 | 22 | "Read-only · resets change nothing here" | C · Minor |
| 4.33 | 22 | Never-state repeats one message three times | C · Minor |
| 4.34 | 16–20 | Wrong-outcome pacing differs per mode; Again red vs Forgot neutral; footer hint glyph rule; "Be honest" copy; mode badge width shifts the track | C · Minor |
| 4.35 | 17–19 | `StudyWholeWordTextWidget` has no minimum scale | H · Minor |
| 4.36 | 16/18 | Busy banner copy is mode-agnostic; Guess/Match options stay live while unsaved | H · Minor |
| 4.37 | session, import | `PopScope(canPop:false)` is permanent, disabling the predictive-back preview | A · Minor |

### 6.4 SP5 — Settings and account (23–33) and performance

| # | Screen | Finding | Src · Sev |
|---|---|---|---|
| 5.01 | 23 | Sync tile amber on plain offline while 27 is neutral (P1) | C · Major |
| 5.02 | 23 | One-row sections repeat their overline; Sync and Account far apart | C · Minor |
| 5.03 | 23 | Reset says one thing four times | C · Minor |
| 5.04 | 23/25/26 | Three wordings of "follow the phone" | C · Minor |
| 5.05 | 23 | New-card order tap dropped while a limit write runs; post-failure toast | H · Minor |
| 5.06 | 24 | "What it says" preview dominates while off and under banners (P1) | C · Major |
| 5.07 | 24 | Off-may-show banner: amber "Turned off." with an unnamed Try again | C · Minor |
| 5.08 | 24 | Time cannot be chosen while off | C · Minor |
| 5.09 | 24 | Leaving mid-permission prompt leaves no result | H · Minor |
| 5.10 | 25 | "Applies at once" note states the obvious | C · Minor |
| 5.11 | 25 | A second rapid theme tap is dropped | H · Minor |
| 5.12 | 26 | Unsupported phone language explained only on screen 26 | H · Minor |
| 5.13 | 27 | Refused state: Try again and Sync now both retry | C · Minor |
| 5.14 | 27 | Keep dialog count can go stale; leaving mid-run drops the toast; Today/Yesterday stale at midnight | H · Minor |
| 5.15 | 28 | Filter chips: no edge, two off-screen, no selected state (uses SP1 §5.3-17) | C · Minor |
| 5.16 | 28 | Offline keeps search and chips live | C · Minor |
| 5.17 | 28 | "This log is gone" for a log that was only sent; triage note uncapped; device id unvalidated | H · Minor |
| 5.18 | 29 | Offline note far from the disabled buttons; uneven benefit rows | C · Minor |
| 5.19 | 30 | Re-auth loss confirm labelled "Continue" | C · Minor |
| 5.20 | 30 | Continue-without dialog leads with the smaller loss | C · Minor |
| 5.21 | 30 | Layer error states drop the step title; Cancel has no busy state | C/H · Minor |
| 5.22 | 30 | Re-auth form never says why the email; stale field error | C/H · Minor |
| 5.23 | 31 | Code field has no six-slot shape; "Use another email" duplicates Back | C · Minor |
| 5.24 | 32 | ACCOUNT/DELETE overlines repeat; validating says "needs a connection" | C · Minor |
| 5.25 | 33 | Rows give no tap cue; own row unexplained; role sheet titled by a bare email; offline as danger | C · Minor |
| 5.26 | perf | Deck rows, tag rows and search hits built eagerly in `Column`s | A · Major |
| 5.27 | perf | Card list re-reads the whole growing window on each growth | A · Major |
| 5.28 | perf | Six sequential awaits before the first frame | A · Major |
| 5.29 | perf | Recall countdown rebuilds the bar's texts at 60 Hz | A · Minor |
| 5.30 | perf | `DateFormat`/`NumberFormat` built per row | A · Minor |

## 7. Owner calls deferred to their sub-project

Asked with `AskUserQuestion` at that sub-project's brainstorm:

- **V1 Vocabulary** (C, carried; 02, 08, 10, 14, 16, 19, 21, 22): plain words versus a
  one-line definition for SM-2, Eight boxes, stage, round, cycle, turns, card-days and
  Front·Term. Decided in SP3, applied in SP3/SP4.
- **V2 One tap to study what is due** (C, carried; 13, ruling R2 of the screen). Decided
  in SP4.
- **V3 Guess wrong-pick hold** (C; 18, ruling 3c-2 R2): hold until tap on a wrong pick.
  Decided in SP4.
- **V4 Recall timing under TalkBack** (A; 19, open in its detail file). Decided in SP4.
- **V5 Accent-insensitive fallback** in search (C; 04, BR-SEARCH-002) and the Fill judge
  (H; 20). Decided in SP3/SP4.
- **V6 Duplicate-term hint** on manual create (H; 08). Decided in SP3.
- **V7 Escape from a stuck account layer** (H; 30). Decided in SP2.

## 8. Testing and the gate

- Each sub-project follows TDD for behaviour: a failing widget or unit test first.
- Copy and layout fixes get their goldens updated.
- Each PR runs `bash .claude/skills/flutter-workflow/scripts/dod_check.sh`, then
  `run_goldens.sh` in the Linux container. Windows runs exclude the golden tag.
- Each PR that moves goldens gets a `golden-compare` page for the owner before the merge.
- The detail file and screen-index row of every changed screen change in the same PR.
  `DESIGN.md` changes with any rule in §5.3-19.

## 9. Out of scope

- Larger text scales (PRODUCT.md, owner 2026-09-30).
- Two-pane or tablet-specific layouts (§9 row 146).
- The launcher icon (§9 row 149).
- Changing the toast replacement rule (R7).
- Migrating to Material's `NavigationBar` (R4).

# ForUI research ledger

One record per shared widget and per significant feature UI component, made
before any correction was implemented (owner directive: Investigate → Verify
API → Compare behaviour → Write tests → Implement → Validate). Each record
names the existing contract and its tests, the ForUI APIs considered, the
installed source lines and documentation that settle each claim, the gaps,
and the approach selected at the highest suitable level: native > ForUI
composition > ForUI foundation > justified Flutter fallback.

## Sources and method

- **Installed package** (authoritative for what compiles): forui 0.27.6,
  `~/.pub-cache/hosted/pub.dev/forui-0.27.6/lib/`. Citations read
  `forui-0.27.6/lib/src/...:line`, `fu:` (= `lib/src/widgets/`) or `CAT`
  (= [FORUI_API_CATALOG.md](FORUI_API_CATALOG.md)).
- **Official documentation** for exactly this version: the `.mdx` sources
  `llms.txt` and forui.dev are generated from, in the official repository at
  tag `forui/0.27.6` (commit `e9cb058d`), `docs/content/docs/`. A page's URL
  is `https://forui.dev/docs/<path>`. forui.dev itself answered 403 from this
  environment, so the pages were read from that source.
- **ForUI's own tests** at the same tag (`forui/test/`).
- **Probes** (`PROBE`): throwaway widget tests run against forui 0.27.6 in a
  separate Flutter project outside the repository (`ledger_probe/`), so that
  no probe code entered MemoX. Each probe's result is quoted in the record
  that relies on it; the probe files were session scratch and are not kept.
- **MemoX v9 POC**: not available in this environment; not used.
- Five auditors covered five groups (G1 actions and overlays, G2 inputs and
  selection, G3 layout and navigation, G4 data surfaces, G5 feature
  components). Each ran the component's tests and quotes the counts.

The `Migration status` field inside a record is the status at audit time.
The table below gives the final status after the corrections, which were
implemented test first (each correction's contract tests were run against
the old code, then the new); the evidence is in the resolution column and in
[MIGRATION_EXECUTION.md](MIGRATION_EXECUTION.md).

## Final status (90 records)

8 BLOCKED, 82 MIGRATED.

| Group | Component | Audit status | Final status | Resolution |
|---|---|---|---|---|
| G1 | MxButton, MxButtonTone, MxButtonSize | CORRECTION NEEDED (low) | MIGRATED | Correction declined with evidence: moving the name into `Icon(semanticLabel:)` would only restore the `isFocusable` flag and `focus` action that `FButton.semanticsLabel` drops (`button.dart:302-304`); TalkBack on Android focuses any labelled node and the tap action stays (`tappable.dart:707-723`), keyboard focus is the `Focus` widget, untouched. No user-visible gain on the only target platform. |
| G1 | MxIconButton | CORRECTION NEEDED (low) | MIGRATED | Same decision as MxButton. |
| G1 | MxFab | CORRECTION NEEDED (medium: removes custom code) | MIGRATED (corrected) | `FButton.icon(variant: primary, size: lg)` + `FVariantsDelta.delta([FVariantOperation.all(DecorationDelta.shapeDelta(shadows:))])`; the `FVariants.raw` rebuild is gone. Test: "the shadow stays under the hover and the press". |
| G1 | MxTooltip | MIGRATED | MIGRATED | As audited. |
| G1 | mx_tap_target helpers (`mxTargetStyle`, `mxIconTargetStyle`, `mxInsetDecoration`, `MxInsetShapeBorder`, `mxPaintedOnly`) | BLOCKED (API limit; fallback justified) | BLOCKED (justified fallback) | As audited. |
| G1 | MxActionPair | BLOCKED (no ForUI equivalent; current is minimal) | BLOCKED (justified fallback) | As audited. |
| G1 | MxSheetActions | CORRECTION NEEDED (low) | MIGRATED (corrected) | The sheet rule is an `FDivider` with an `FDividerStyleDelta`; offsets unchanged (test "divider rule on top, then 8 16 16"). |
| G1 | showMxDialog, showMxConfirm, MxDialog, MxDialogWidth | CORRECTION NEEDED (high: functional defect) | MIGRATED (corrected) | Root navigator; `ModalRoute.of(context)?.animation` replaces `_DialogAnimation`; barrier label from `MaterialLocalizations` (ForUI's Vietnamese strings are broken). Tests: shell-branch nav blocked, root-navigator route, barrier strings in English and Vietnamese (red before, green after). |
| G1 | showMxBottomSheet, MxBottomSheet | CORRECTION NEEDED (high) | MIGRATED (corrected, navigator per owner ruling) | Barrier and grabber strings from `MaterialLocalizations`; the sheet stays on the nearest navigator by owner ruling M3C-52 KEEP_EXISTING. Tests: scrim label/hint, Vietnamese carries no literal `$`. |
| G1 | MxHeldRoute (mixin), MxHoldRoute | BLOCKED (API limit; justified) | BLOCKED (justified fallback) | As audited. |
| G1 | showMxSnackbar, MxSnackbarController, MxToastHost, mxUndoWindow | CORRECTION NEEDED (low); host itself BLOCKED/justified | MIGRATED (corrected; host justified) | Toast motion from `FToastMotion` (`toasterStyle.toastStyles.primary.motion`) and `context.accessibility` (fade only under reduced motion or TalkBack, instant when disabled), as ForUI's toaster. Tests: group "motion follows ForUI's toast motion and accessibility" (reduced-motion case red before, green after). |
| G1 | MxDeckPickerSheet, MxDeckPickerLoadingSheet, MxDeckPickerErrorSheet, MxPickerCandidate | MIGRATED | MIGRATED | As audited. |
| G1 | MxFloatingNotice | CORRECTION NEEDED (low; optional, golden may change) | MIGRATED (corrected) | Surface is an `FCard` with a `DecorationDelta.shapeDelta`; padding, 48 height and live region unchanged; corner becomes the theme superellipse (golden review). |
| G1 | MxToggle | MIGRATED | MIGRATED | As audited. |
| G1 | MxSlider | CORRECTION NEEDED (low) | MIGRATED (corrected) | `tooltipBuilder` in the caller's unit when a formatter is given; percentage kept otherwise. Tests: two drag tests. |
| G1 | MxStepper | CORRECTION NEEDED (low; shared with records 2-3) | MIGRATED | Same decision as MxButton for the labelled glyph; the hold-to-repeat foundation stays (owner ruling D2 on screen 24). |
| G1 | MxSpinner, MxSpinnerSize | CORRECTION NEEDED (medium: removes about 60 lines; visual change needs the owner) | MIGRATED (corrected) | `FCircularProgress` + `FCircularProgressMotion(duration:)` inside an `FAccessibilityScope` that maps `disabled` to `reduced`, so a loading state never freezes; the custom painter is gone. Tests: colour/size from the icon theme, turns under disableAnimations and reduceMotion. |
| G2 | MxTextField | MIGRATED | MIGRATED | As audited. |
| G2 | MxCodeField | BLOCKED (API limit: `FOtpField` semantics value, fixed non-shrinking items, controller type; the owner-ruled slot cue). | BLOCKED (justified fallback) | As audited. |
| G2 | MxSearchField | CORRECTION NEEDED (trigger form only; default form is MIGRATED) | MIGRATED (corrected) | Trigger is an `FButton` (lg) with a style delta; `isAutofocused` passes ForUI's `autofocus`. Tests: 8 trigger tests, 2 autofocus tests. |
| G2 | MxFieldMessage | MIGRATED | MIGRATED | As audited. |
| G2 | MxUserEdits | MIGRATED (test gap listed) | MIGRATED (test gap closed) | `test/shared/widgets/mx_user_edits_test.dart`: typing, pasting and deleting report once; text, selection and clear set by the code report nothing; a rewriting formatter reports its result once. No production change. |
| G2 | MxSelectionCheckbox | MIGRATED | MIGRATED | As audited. |
| G2 | MxOptionRow | MIGRATED | MIGRATED | As audited. |
| G2 | MxChoiceTile | CORRECTION NEEDED | MIGRATED (corrected) | `FTappable.static` with the theme focus outline replaces the `GestureDetector`; Tab and Enter now reach it (DEV-391). Tests: 11 new. A screen-level check found the outline cut by the scroll view on the edge tiles of Match and Guess; both boards now leave `context.focusOutlineReach` (read from ForUI's focused outline style) above and below, and `MxChipRow` reads the same value. Tests: `study_choice_focus_ring_test.dart` (red before, green after), `topik_attempt_focus_ring_test.dart`. |
| G2 | MxSegmentedTray | BLOCKED (owner rulings BR-SRS-001 and FE-A3, plus the `FTabs` API limits above) | BLOCKED (justified fallback) | As audited. |
| G2 | MxFilterChip | MIGRATED | MIGRATED | As audited. |
| G2 | MxChipTrigger | MIGRATED | MIGRATED | As audited. |
| G2 | MxChipRow | MIGRATED | MIGRATED | As audited. |
| G2 | mxChipStyle and helpers | MIGRATED | MIGRATED | As audited. |
| G2 | MxTagChip | MIGRATED | MIGRATED | As audited. |
| G2 | MxBadge (and MxToneBadge) | MIGRATED | MIGRATED | As audited. |
| G2 | MxStatusBadge | MIGRATED | MIGRATED | As audited. |
| G3 | MxAppShell | CORRECTION NEEDED (small; the Scaffold decision itself is MIGRATED) | MIGRATED (corrected at the app root) | `AppThemeHost` wraps the app in `AnnotatedRegion<SystemUiOverlayStyle>(value: theme.scaffoldStyle.systemOverlayStyle)`, the value ForUI's `FScaffold` applies; Material `Scaffold` stays as infrastructure. Test: `test/app/app_theme_host_test.dart` (red before, green after). |
| G3 | MxAppBar | MIGRATED | MIGRATED | As audited. |
| G3 | MxStudyTopBar | CORRECTION NEEDED | MIGRATED (corrected) | Track is `MxLinearProgress(tone: primary)` (`FDeterminateProgress`); chip is `MxToneBadge` (`FBadge.raw`). |
| G3 | MxBottomNav (+ MxNavDestination, MxNavItem) | MIGRATED | MIGRATED (test gap closed) | `mx_bottom_nav_test.dart`: "a re-tap of the selected destination still reports it". No production change. |
| G3 | MxNavRail | CORRECTION NEEDED (low value, optional) | MIGRATED (corrected) | `FSidebar.raw` is the frame (its theme decoration: background and end hairline), width = `sizeRail` + the inset of its own side, `contentPadding` zero so the rail padding scrolls. Test: "the frame is ForUI's sidebar in the theme's style" (red before, green after); the inset, scroll and focus tests pass. |
| G3 | MxBreadcrumb (+ MxBreadcrumbSegment) | CORRECTION NEEDED | MIGRATED (corrected) | `FBreadcrumb` + `FBreadcrumbItem` inside the reverse scroll and fade; tap-less ancestors keep `Semantics(button: true)` (DEV-306); the current level is announced as selected. |
| G3 | MxRouteName | MIGRATED | MIGRATED | As audited. |
| G3 | MxScreenScroll (+ MxScrollClearance) | MIGRATED | MIGRATED | As audited. |
| G3 | MxScrollFade (+ MxScrollFadeGround) | MIGRATED | MIGRATED | As audited. |
| G3 | MxFooterBar | MIGRATED | MIGRATED | As audited. |
| G3 | MxListRow | MIGRATED | MIGRATED | As audited. |
| G3 | MxSettingsRow | MIGRATED | MIGRATED | As audited. |
| G3 | MxActionSheetCommandRow | MIGRATED | MIGRATED | As audited. |
| G3 | MxRowInk | CORRECTION NEEDED | MIGRATED (corrected) | `FTappable.static(style: FTheme.of(context).itemStyles.primary.tappableStyle)`: ForUI's item press timing. Test: "press: the ground shows within a frame" (red before, green after). |
| G3 | MxSelectableCardRow | MIGRATED | MIGRATED | As audited. |
| G3 | MxListSectionHeader | MIGRATED | MIGRATED | As audited. |
| G3 | MxDividedColumn | MIGRATED | MIGRATED | As audited. |
| G3 | MxSection | MIGRATED | MIGRATED | As audited. |
| G3 | MxTwoColumns | MIGRATED | MIGRATED | As audited. |
| G4 | MxCard | MIGRATED | MIGRATED | As audited. |
| G4 | MxTintBase | MIGRATED | MIGRATED | As audited. |
| G4 | MxInlineBanner | BLOCKED (API limit; owner decision available) | BLOCKED (justified fallback) | As audited. |
| G4 | MxNote | BLOCKED (API limit) | BLOCKED (justified fallback) | As audited. |
| G4 | MxDashedNote | MIGRATED | MIGRATED | As audited. |
| G4 | MxEmptyState | MIGRATED | MIGRATED | As audited. |
| G4 | MxErrorState | MIGRATED | MIGRATED | As audited. |
| G4 | MxSkeleton (+ MxSkeletonRow, MxSkeletonPulse, MxSkeletonList) | MIGRATED | MIGRATED | As audited. |
| G4 | MxLinearProgress (+ `.mastery`) | CORRECTION NEEDED | MIGRATED (corrected) | `FDeterminateProgress` with an `FDeterminateProgressStyleDelta`; a value shows at once on mount (ForUI animates from 0 on mount, `determinate_progress.dart:89-101`, which would sweep every row scrolled into view), a later change eases. Tests: 13. |
| G4 | MxMasteryDonut | MIGRATED | MIGRATED | As audited. |
| G4 | MxStackedDayBars (+ MxDayBar) | MIGRATED | MIGRATED | As audited. |
| G4 | MxChartLegend (+ MxBarSeries) | MIGRATED | MIGRATED | As audited. |
| G4 | MxDotOverline | MIGRATED | MIGRATED | As audited. |
| G4 | MxIconTile | MIGRATED | MIGRATED | As audited. |
| G4 | MxOutcomeTile | MIGRATED | MIGRATED | As audited. |
| G4 | MxStatTile | MIGRATED | MIGRATED | As audited. |
| G4 | MxWorkloadBreakdownLine | MIGRATED | MIGRATED | As audited. |
| G5 | StudyFaceCardWidget (tap) | MIGRATED (justified Fallback; 82 study tests pass) | MIGRATED | As audited. |
| G5 | StudyBrowseWidget (swipe card) | MIGRATED (justified Fallback) | MIGRATED | As audited. |
| G5 | StudyGuessWidget (tap anywhere once answered) | MIGRATED (justified Fallback) | MIGRATED | As audited. |
| G5 | StudyAppearingWidget (reveal fade-and-rise) | MIGRATED (justified Fallback) | MIGRATED | As audited. |
| G5 | StudySettleGuardWidget (400 ms tap guard with opacity ease) | MIGRATED (justified Fallback) | MIGRATED | As audited. |
| G5 | StudyRecallWidget (turn clock) | MIGRATED | MIGRATED | As audited. |
| G5 | RecallCountdownBarWidget (draining track) | CORRECTION NEEDED (conditional on the shared owner) | MIGRATED (corrected) | `MxLinearProgress(tone: neutral/warning, isInstant: true)`; the feature imports no ForUI. |
| G5 | StudyFillWidget (focus) | MIGRATED | MIGRATED | As audited. |
| G5 | CardRemovableTagChipWidget | CORRECTION NEEDED | MIGRATED (corrected) | `MxChipTrigger(isGhost: false, icon: close, semanticLabel:)` = `FButton` xs outline in the 48 target; five chip helpers that served only it are deleted. Tests: focus and Enter remove it (red before, green after), each chip its own node, geometry and colours unchanged. |
| G5 | CardTagEditorWidget (focus) | MIGRATED | MIGRATED | As audited. |
| G5 | CardEditorFormWidget (front-field focus) | MIGRATED | MIGRATED | As audited. |
| G5 | TopikScoreDonutWidget (custom painting) | MIGRATED (justified Fallback) | MIGRATED | As audited. |
| G5 | TopikQuestionBarChartWidget (bars) | MIGRATED | MIGRATED | As audited. |
| G5 | ReminderTimeDialogWidget (two MxSteppers) | BLOCKED (owner ruling) | BLOCKED (justified fallback) | As audited. |
| G5 | LibrarySearchScreen (focus on arrival) | CORRECTION NEEDED (low value, optional) | MIGRATED (corrected) | `MxSearchField(isAutofocused: true)` → `FTextField(autofocus:)`; the screen's FocusNode and post-frame request are gone. |
| G5 | AccountTransitionLayerWidget (nested Navigator) | MIGRATED (justified Fallback) | MIGRATED | As audited. |
| G5 | UsersListWidget pull-to-refresh | MIGRATED (justified Fallback) | MIGRATED | As audited. |
| G5 | MonitoringServerListWidget pull-to-refresh | MIGRATED (justified Fallback) | MIGRATED | As audited. |
| G5 | DeckReorderListWidget / DeckReorderRowWidget (drag reorder) | MIGRATED (justified Fallback) | MIGRATED | As audited. |
| G5 | MonitoringCodeCardWidget (selectable text) | MIGRATED (justified Fallback) | MIGRATED | As audited. |
| G5 | lib/app/gallery (debug component gallery) | MIGRATED | MIGRATED | As audited. |

## Audit records


## Ledger G1: actions and overlays (lib/shared/widgets/)

Set: mx_button, mx_icon_button, mx_fab, mx_tooltip, mx_tap_target, mx_action_pair, mx_sheet_actions, mx_dialog,
mx_bottom_sheet, mx_held_route, mx_snackbar, mx_deck_picker_sheet, mx_floating_notice, mx_toggle, mx_slider, mx_stepper,
mx_spinner. No repository file was edited. Probes live only in
`ledger_probe/test/` (forui 0.27.6,
Flutter 3.47.5, `FTheme.neutral.light.touch`).

Abbreviations. `F:` = `/root/.pub-cache/hosted/pub.dev/forui-0.27.6/lib/src/` (cited as `forui-0.27.6/lib/src/...:line`).
`CAT` = `docs/forui-migration/FORUI_API_CATALOG.md`. Docs base `https://forui.dev/docs/`.

Test run (quoted, honest): `MEMOX_TEST_BUNDLES=0 bash .claude/skills/flutter-workflow/scripts/run_tests.sh` on the 18 test
files of this set: **231 tests passed, 0 failed, 18 suites** (`+231: All tests passed!`, 31.5 s). Files:
mx_action_pair, mx_bottom_sheet, mx_button_geometry, mx_button_loading, mx_button, mx_button_width, mx_deck_picker_sheet,
mx_dialog, mx_fab, mx_floating_notice, mx_icon_button, mx_sheet_actions, mx_slider, mx_snackbar, mx_spinner,
mx_stepper_input, mx_stepper, mx_toggle (all `test/shared/widgets/*_test.dart`). Goldens were not run.
There is no dedicated test file for mx_tooltip, mx_tap_target or mx_held_route; they are pinned indirectly (see records).

---

### Answers to the six specific questions (evidence in the records)

**(a) MxTooltip: does `semanticsTooltip` (or any FTooltip parameter) remove the unlabelled long-press node? NO. MergeSemantics
stays.** PROBE `ledger_probe/test/tip_test.dart` (semantics tree of `FTooltip > FButton.icon(semanticsLabel:'Close')`):
- A, plain: two nodes, `[4] actions=longPress` (no label) and `[5] isButton label="Close" actions=tap`.
- B, plus `semanticsTooltip:'Close'`: still two nodes; the button node only gains `tooltip="Close"`; `[9] actions=longPress` stays.
- C, current `MergeSemantics`: one node `isButton ... actions=tap,longPress label="Close"` (child `[15 merged]`).
- D, `FTooltip(longPress:false)`: one node, but then the long-press tip is gone (touch discoverability; pinned by
  `mx_icon_button_test` "a long press shows the label as a tooltip").
Source: the long press is a `GestureDetector` around the whole child (`F:widgets/tooltip/tooltip.dart:268`), whose semantics
node is separate from the child's explicit node; `FTooltip` has no semantics parameter (rg `Semantics` in
`widgets/tooltip/*.dart`: only `:333`, the shown tip). `semanticsTooltip` is a field of `FTappable`/`FButton` that sets
`Semantics.tooltip` on the button's own node (`F:foundation/tappable/tappable.dart:711`); its doc says "a tooltip cannot annotate
its child's semantics node" (`F:foundation/doc_templates.dart:101-104`). Conclusion: the wrapper is necessary.

**(b) MxSnackbar: is the custom MxToastHost justified?** Largely yes (BLOCKED by FToaster API); one small correction.
- ForUI's `FToaster` stack wraps all toasts in `GestureDetector(onTap: toggles _autoDismiss)` (`F:widgets/toast/toaster_stack.dart:119-127`),
  unconditional (no style flag): on touch, a tap on a toast cancels auto-dismiss for the whole stack until the next tap. That
  breaks the pinned contract "a toast stays its duration, then goes" (`mx_snackbar_test` "a toast stays its duration..."; FE-B1 D3).
- PROBE `ledger_probe/test/toast_test.dart` (FToaster + `showFToast(bottomCenter, Undo)`): the screen's **root semantics node
  `[1]` gets `actions=tap,scrollLeft,scrollRight,scrollUp,scrollDown` with no label**; the toast node `[5]` is
  `isLiveRegion actions=dismiss`, the Undo button `[6]` is fine. This confirms the MxSnackbar doc comment (the catalog flagged it UNVERIFIED).
- Other gaps for the contract: no keyboard inset (rg `viewInsets|keyboard` in `F:widgets/toast/`: no match; `toaster.dart:392`
  only `SafeArea`); stack of up to `max = 3` instead of replace-on-new (FE-B1 D14; `FToasterEntry.dismiss()` would overlap the
  300 ms dismiss with the next entrance); no `closed` future (only `onDismiss`, `toaster.dart:55`); FToaster itself adds
  `Overlay.wrap` (`toaster.dart:410`).
- Native strengths MxSnackbar does not have: `dismiss` semantics action (`animated_toast.dart:380-381`, probe `[5] actions=dismiss`) and
  motion reduced for `accessibleNavigation` (below).
- Fairness note (PROBE, same file, test 2): MxSnackbar's own `Dismissible` contributes an unlabelled node
  `actions=scrollUp,scrollDown` beside the toast. So the custom path is not free of the same class of wart; impact on TalkBack is UNVERIFIED on a device.
- **Reduced-motion read.** ForUI reads `context.accessibility.motion != all || accessibleNavigation` in the toaster
  (`toaster_stack.dart:66`, `animated_toast.dart:292`). MxSnackbar reads `MediaQuery.disableAnimationsOf` (`mx_snackbar.dart:177,186`).
  Both come from `platformDispatcher.accessibilityFeatures`: `FAccessibilityScope._platform()` maps `disableAnimations -> disabled`,
  `reduceMotion -> reduced` (`F:foundation/accessibility.dart:118-128`); `MediaQueryData.disableAnimations` is the same flag and
  "On iOS, reduced motion ... does not set this flag" (Flutter `widgets/media_query.dart:665-670`). MemoX ships Android only
  (no `ios/` directory; `PRODUCT.md:43`), so `reduced` never occurs. The only observable difference is `accessibleNavigation`
  (TalkBack on): ForUI snaps the toast, MxToast still slides/fades. Recommendation: read `context.accessibility` in `_ToastView` (consistency with the dialog/sheet it floats over, which read FAccessibility),
  keep `Remove animations` honoured (`PRODUCT.md:88`). Note ForUI scopes ignore `MediaQuery` overrides, tests must use `FakeAccessibilityFeatures` (as `mx_dialog_test.dart:190` and `mx_snackbar_test.dart:203` already do).

**(c) showMxDialog / showMxBottomSheet navigator and barrier strings.**
- Both push on `Navigator.of(context)` = the **nearest** navigator (`mx_dialog.dart:20`, `mx_bottom_sheet.dart:16`). ForUI's own
  default is also nearest (`useRootNavigator = false`, `F:widgets/dialog.dart:78`, `F:widgets/sheet/modal_sheet.dart:90`). The old
  Material `showDialog`/`showModalBottomSheet` defaulted to root; MemoX's own pre-migration `mx_dialog` used `showDialog`.
- **Defect (PROBE `ledger_probe/test/nav_test.dart`, go_router 18.0.1, `StatefulShellRoute.indexedStack` with the bottom bar outside the branches exactly like `AppTabShell`, `lib/app/router/app_tab_shell.dart:30-37`):**
  a dialog opened from a branch screen with the nearest navigator leaves the bottom bar tappable through the scrim
  (`rootNavigator=false: ... navTaps=1; dialog still open=true`); with `useRootNavigator: true` the scrim catches it
  (`navTaps=0; dialog still open=false`). So today every sheet/dialog opened from a Library/Study/Progress/Settings screen
  (about 40 call sites) does not cover the bottom nav / rail, and a *held* popup (`isHeld`, work in flight) can be left by a tab switch.
  `CAT` Gaps #7 (line 1897) records the ForUI default. Fix: `Navigator.of(context, rootNavigator: true)`.
- **Barrier strings.** Yes, taken from `FLocalizations` (`mx_dialog.dart:21-27`, `mx_bottom_sheet.dart:17-30`, identical to `showFDialog`
  `F:widgets/dialog.dart:89-90` and `showFSheet` `modal_sheet.dart:101-102`). Vietnamese defects confirmed in source:
  `FLocalizationsVi.barrierLabel => 'Scrim'` and `barrierOnTapHint => 'Đóng \$modalRouteContentName'` (escaped `$`, a literal)
  (`F:localizations/localizations_vi.dart:16-21`). Barrier semantics are built on Android (`CAT:1774`). `MxBottomSheet._grabber`
  also uses `barrierLabel` as the grabber's TalkBack name (`mx_bottom_sheet.dart:173`), so a Vietnamese user hears "Scrim"; the test pins that
  (`mx_bottom_sheet_test.dart:267`). `FLocalizationsVi` is not exported from `package:forui/forui.dart` (`lib/localizations.dart` exports only
  `localizations.dart` and `localization.dart`), so a subclass delegate would need a `src/` import; the clean fix is caller-side strings.

**(d) MxSpinner vs FCircularProgress.** `FCircularProgress` stops only under `FAccessibilityMotion.disabled`
(`F:widgets/progresses/circular_progress.dart:141-144` stops the controller, `:167` returns the bare icon); `reduced` and `accessibleNavigation` keep it
spinning. PROBE `ledger_probe/test/spin_test.dart`: rotation after 250 ms is `-1.0` (quarter turn) for `all` and `reduceMotion`, **no
`Transform` at all** for `disableAnimations` (Android "Remove animations"). So the project text "ForUI's progress stops under reduced motion"
(`mx_spinner.dart:14`, `DESIGN.md:306`, `MIGRATION_EXECUTION.md:26`) is true only for Android's setting, which is the only one MemoX has.
**A knob exists:** `FAccessibilityScope(data: FAccessibility(...motion: reduced...))` is public (`accessibility.dart:75`; explicit `data` is not
overwritten by platform changes, `_update` skips it, `:148`) and the nearest scope wins; PROBE: the scoped spinner rotates under `disableAnimations`
(`scoped [disableAnimations(Android)] ... after250ms=-1.0`). PROBE `spin2_test.dart`: `FCircularProgress(style: FCircularProgressStyleDelta.delta(iconStyle: IconThemeDataDelta.delta(size, color), motion: FCircularProgressMotion(duration: 800ms)))`
gives sizes 20 and 32, a quarter turn per 200 ms under Android disable-animations, silent when wrapped in `ExcludeSemantics`, and `label="Loading"` when named.
Gap that stays: the glyph is the Lucide `loaderCircle` icon (`F:theme/icons.dart:138,257`), so the stroke scales with size (about 1.33 at 16 dp,
not the pinned 2 px) and the caps are round; `mx_spinner_test` pins `arc strokeWidth: 2` and `mx_button_loading_test` reads the private painter's `color`.
That is a visual change (golden + owner), not a behaviour gap. See record 17.

**(e) MxStepper: any ForUI numeric input/stepper? No.** `rg -il "stepper|spinbutton|NumberField"` over `forui-0.27.6/lib/` matches only slider
`stepPercentage` and portal `NumericFocusOrder`; the docs tree has no such page (`widgets/form/` lists autocomplete, button, checkbox, date-field,
date-time-picker, label, multi-select, otp-field, picker, radio, select-group, select, slider, switch, text-field, text-form-field, time-field, time-picker).
Nearest are `FTimePicker`/`FTimeField` (wheels / typed segments). Screen 24 ruling: "Owner 2026-09-28 (spec D2), UC A1: the time is chosen in an
`MxDialog` with Hour and Minute `MxStepper`s" (`docs/shared/ui/screen-handoff/24-daily-reminder.md:70`; also `:25`, `:35`, `:67`, `:81-82`). An owner
ruling beats a ForUI preference, so the wheels are rejected by ruling; the stepper is a documented Composition (FButton.icon + FTextField + FTappable-based MxRowInk).

**(f) MxButton loading: confirmed, FButton has no loading/busy API.** rg `loading|busy` over `F:widgets/button/button.dart` and `button_content.dart`: none.
The documented pattern is `prefix: const FCircularProgress()` with `onPress: null` (`forui-src/docs/content/docs/widgets/form/button.mdx:172-179`;
snippet `docs_snippets/lib/examples/form/button.dart:164`; `CAT:931-932`), which changes the width and applies the disabled paint. The button does provide
`FInheritedCircularProgressStyle` to its content (`F:widgets/button/button_content.dart:60`) and a `circularProgressStyle` per variant
(`button.dart:699-705`). MxButton's contract (keep width, keep resting paint, block presses) therefore stays a Composition around the builder.

---

### Records

#### MxButton, MxButtonTone, MxButtonSize — `lib/shared/widgets/mx_button.dart`
| Field | Record |
|---|---|
| Existing contract | `onPressed` null disables; `isLoading` swaps label for a spinner, keeps width and resting paint (also with `onPressed` null), blocks taps; `isAutofocused`; seven tones, four sizes, every size on a 48 target; `detail` second line; `icon` xor `mark` (18 brand mark, never read); `isBlock`; `isSingleLine`; `semanticLabel` replaces the label on one node that keeps tap + enabled (SW-REV-005); `naturalWidth` one-line measure for MxActionPair. Tests: `mx_button_test` (each size paints its height and keeps a 48 target; tones paint ForUI's variants; text tone is the ghost; dangerTint; warning above 4.5:1; detail line; asserts; dark outline; isAutofocused; tap; disabled; loading; block; small sizes still 48x48; isSingleLine; regular wraps to 2 lines; semanticLabel one node), `mx_button_geometry_test` (glyph size/gap, padding per tone, focus outline), `mx_button_loading_test` (never dimmed; resting foreground; keeps width and ignores taps; M3F-02 spinner contrast per tone/brightness; keeps its name; semanticLabel; geometry per tone/size/direction), `mx_button_width_test` (naturalWidth; brand mark) |
| Call sites | 121 constructor uses in 70 files under `lib/` (gallery included), e.g. `lib/shared/widgets/mx_sheet_actions.dart`, `lib/features/reminders/presentation/widgets/overlays/reminder_time_dialog_widget.dart`, `lib/features/study/presentation/widgets/sections/session_summary_widget.dart` |
| ForUI candidate APIs | `FButton`, `FButton.icon`, `FButton.raw`, `FButtonVariant.{primary,secondary,destructive,outline,ghost}`, `FButtonSizeVariant.{xs,sm,md,lg}`, `FButtonStyleDelta`, `FButtonSizeStyles.inherit`, `FButtonContentStyleDelta`, `FButton.builder/prefix/suffix`, `semanticsLabel`, `semanticsTooltip`, `autofocus`, `FInheritedCircularProgressStyle`, `FCircularProgress` |
| Installed package version | forui 0.27.6 |
| Official documentation | https://forui.dev/docs/widgets/form/button |
| Source evidence | `F:widgets/button/button.dart:178-221` (ctor, no loading param); `:283-285` style lookup; `:304` `excludeSemantics: semanticsLabel != null`; `:343` `FButtonStyles.inherit`; `:509-633` touch min sizes xs 32/sm 40/md 44/lg 48; `:699-705` per-variant `circularProgressStyle`; `button_content.dart:60` inherited progress style; `F:foundation/tappable/tappable.dart:709-725` Semantics with `excludeSemantics`; `:738` `canRequestFocus` |
| API verification | PROBE `ledger_probe/test/iconsem_test.dart` C vs D vs E (`btnsem_test.dart`): `semanticsLabel` node = `isButton,... actions=tap label` **without `isFocusable` and without the `focus` action**; a plain labelled child keeps `isFocusable actions=tap,focus`; `Semantics(label:) over ExcludeSemantics(Text)` inside the builder keeps both (`[4] ... isFocusable actions=tap,focus label="Reminder time 07:05"`, disabled variant correct too). Existing tests above pass (231/231 across the set) |
| Native capability | variants/sizes/states/hover/press/focus ring/disabled paint/autofocus/semantics button+enabled/builder slots/`mainAxisSize`; the five standard tones come from `theme.buttonStyles`; custom tones are built with the ForUI factory `FButtonSizeStyles.inherit` and `FVariants.from`/`DecorationDelta` (no hand-drawn states) |
| Capability gaps | (1) no loading state (above, f); (2) paint heights 40/32 are below 48 and ForUI has no target-expansion knob (rg `tapTarget|hitSlop|minimumSize|kMinInteractive` in tappable/button/theme: none) -> `mxTargetStyle` inset decoration; (3) no `detail` line or wrap/ellipsis policy; (4) no `naturalWidth` (needs `TextPainter` at the style's `textStyle` and padding); (5) `semanticsLabel` drops `isFocusable`/`focus` (`button.dart:304`) |
| Current approach | **Composition**: `FButton(builder:, prefix:, style: mxTargetStyle(...), semanticsLabel:, autofocus:, mainAxisSize:)`; style from `theme.buttonStyles.<tone>.resolve({platform, size})`; `dangerTint`/`warning` from `FButtonSizeStyles.inherit`; loading overlay is a `Stack` with `Visibility.maintain` + `MxSpinner`; `naturalWidth` via `TextPainter`. Fallback parts: naturalWidth, loading overlay, inset decoration |
| Selected approach | Composition (same), with the `semanticLabel` override done in the builder child instead of `FButton.semanticsLabel` |
| Why not a higher-level API? | A pure `FButton(variant:, size:, prefix:)` cannot give the 48 target, the detail line, wrap/ellipsis, width-stable loading or the two extra tones (gaps 1-4). `FButton.raw` would drop the content builder (`button.dart:257-279`) |
| Contract tests | Covered: all items except focusability of the `semanticLabel` node (not pinned either way; SW-REV-005 pins tap + enabled). Missing: a test that `semanticLabel` keeps `isFocusable`/focus action |
| Migration status | CORRECTION NEEDED (low) |
| Correction (if any) | In `_label`, when `semanticLabel != null` wrap the painted label as `Semantics(label: semanticLabel, child: ExcludeSemantics(child: text))` and drop `semanticsLabel:` from the `FButton` call (`mx_button.dart:109`); PROBE E/F shows one node with label, tap, focus, enabled and disabled correct. Risk: `SW-REV-005` tests (`mx_button_test`, `mx_button_loading_test` "semanticLabel: one node ...") must keep one node: re-run them. Add a test asserting `isFocusable`. If MxSpinner is migrated (record 17) the loading spinner keeps working (it inherits via `MxSpinner(color:)`). If `mxTargetStyle` is later expressed as a delta (record 5), `isLoading` must also freeze `circularProgressStyle` |

#### MxIconButton — `lib/shared/widgets/mx_icon_button.dart`
| Field | Record |
|---|---|
| Existing contract | Ghost icon button in a round 48 box with an app-sized glyph (`sizeIcon`), `semanticLabel` names it (one node keeping tap and long press), long press shows the label as a tooltip, null `onPressed` disables (ForUI dim), M3F-07 focus outline offset and not clipped. Tests: `mx_icon_button_test` (round sizeControl box with sizeIcon glyph; ghost icon colour on no fill; semantic label names one node that keeps tap + long press; long press shows tooltip; disabled; M3F-07 outline; not clipped in app bar/row) |
| Call sites | 73 uses in 55 files, e.g. `lib/shared/widgets/mx_app_bar.dart`, `lib/features/deck/presentation/screens/deck_level_screen.dart`, `lib/features/study/presentation/widgets/sections/session_summary_widget.dart` (per `rg "MxIconButton\("`; the first two are indicative, the gallery has the rest) |
| ForUI candidate APIs | `FButton.icon`, `FButtonVariant.ghost`, `FButtonSizeVariant.lg`, `FButtonStyleDelta`, `FButtonIconContentStyleDelta`, `FHeaderAction` (app-bar action), `FTooltip` |
| Installed package version | forui 0.27.6 |
| Official documentation | https://forui.dev/docs/widgets/form/button ; https://forui.dev/docs/widgets/overlay/tooltip ; https://forui.dev/docs/widgets/layout/scaffold (FHeader/FHeaderAction) |
| Source evidence | `F:widgets/button/button.dart:230-254` `FButton.icon`; `:304` `excludeSemantics`; `F:foundation/doc_templates.dart:101-104`; `F:widgets/tooltip/tooltip.dart:268` |
| API verification | PROBE `iconsem_test.dart` A vs B: `semanticsLabel` -> no `isFocusable`/`focus`; `Icon(semanticLabel:)` child -> `[9] ... isFocusable actions=tap,longPress,focus label="Close"` under the same MxTooltip merge. Tests pass |
| Native capability | ghost variant, lg size, disabled dim, hover/press, focus ring, tap/long press, tooltip trigger via FTooltip |
| Capability gaps | (1) glyph size and padding differ from ForUI's icon size (handled with `FButtonIconContentStyleDelta` padding, native); (2) `semanticsLabel` removes input-focus semantics (above); (3) `FHeaderAction` is bound to `FHeader` and 44-dp sized (CAT:573), not a general icon button |
| Current approach | **Composition**: `MxTooltip(FButton.icon(variant: ghost, size: lg, style: FButtonStyleDelta.delta(iconContentStyle: ...), semanticsLabel))` |
| Selected approach | Composition (same), with the label carried by `Icon(icon, size:, semanticLabel: semanticLabel)` |
| Why not a higher-level API? | `FButton.icon` is the highest-level icon button; `FHeaderAction` is for FHeader prefixes/suffixes only |
| Contract tests | Covered; missing assertion on focusability |
| Migration status | CORRECTION NEEDED (low) |
| Correction (if any) | Replace `semanticsLabel: semanticLabel` + `Icon(icon, size:)` by `Icon(icon, size: dimens.sizeIcon, semanticLabel: semanticLabel)` (`mx_icon_button.dart:34,43`). Keeps one labelled node with tap, long press, enabled and now `isFocusable`/`focus` (PROBE B). Risk: the tests above use `isSemantics`/label finders, re-run `mx_icon_button_test`, `mx_app_bar` tests; app-wide semantics goldens none. Same change for MxFab and the stepper buttons (records 3, 16) |

#### MxFab — `lib/shared/widgets/mx_fab.dart`
| Field | Record |
|---|---|
| Existing contract | Square `sizeFab` ForUI primary icon button with ForUI's shadow on every state; `semanticLabel` is the name and the long-press tooltip, never painted; hover layer = primary hover; focus outline; placement is MxAppShell's. Tests: `mx_fab_test` (square sizeFab primary icon button in primary foreground; rests on ForUI's shadow; hover state layer; keyboard focus outline; label is accessible name never painted; M3F-11 label is also the tooltip and one node names it; long press shows tooltip) |
| Call sites | 5 uses in 5 files: `lib/features/card/presentation/widgets/sections/card_add_fab_widget.dart`, `lib/features/deck/presentation/screens/deck_level_screen.dart`, `lib/app/gallery/gallery_chrome_section.dart` |
| ForUI candidate APIs | `FButton.icon(variant: FButtonVariant.primary, size: FButtonSizeVariant.lg, style: FButtonStyleDelta.delta(decoration: FVariantsDelta.delta([FVariantOperation.all(DecorationDelta.shapeDelta(shadows:))]), iconContentStyle: FButtonIconContentStyleDelta.delta(constraints:)))` |
| Installed package version | forui 0.27.6 |
| Official documentation | https://forui.dev/docs/widgets/form/button ; https://forui.dev/docs/guides/customizing-widget-styles ; https://forui.dev/docs/guides/creating-custom-deltas |
| Source evidence | `F:widgets/button/button.design.dart:326-335` `FButtonStyleDelta.delta(decoration: FVariantsDelta<...>?)`; `F:theme/variants.dart:255-300` `FVariantsDelta.delta` / `FVariantOperation.base/all`; `F:theme/delta/decoration.dart:46-148` `DecorationDelta.shapeDelta(shadows:)`; `F:widgets/button/button.dart:230-254` |
| API verification | PROBE `ledger_probe/test/delta_test.dart`: `FButton.icon(variant: primary, size: lg, style: FButtonStyleDelta.delta(decoration: FVariantsDelta.delta([.all(DecorationDelta.shapeDelta(shadows: c.theme.style.shadow))]), iconContentStyle: ...(56x56)))` renders `Size(56, 56)`, `ShapeDecoration` with `shadows.length == 1` and the primary colour. Existing tests pass |
| Native capability | All of the contract by configuration via style deltas; the manual resolution of `theme.buttonStyles.primary.resolve({...})` is not needed when `variant:`/`size:` are passed |
| Capability gaps | none for the shadow/size; label focus semantics as MxIconButton |
| Current approach | **Composition with hand-rebuilt variants**: resolves `theme.buttonStyles.primary.resolve({platform, lg})`, `base.copyWith(decoration: FVariants.raw(_raised(base), {for each entry ... _raised}))`, `_raised` switch on `ShapeDecoration` (`mx_fab.dart:25-63`) |
| Selected approach | Composition through ForUI's delta API (above) |
| Why not a higher-level API? | n/a (FButton.icon is the native widget; there is no ForUI FAB) |
| Contract tests | Covered by `mx_fab_test`; missing nothing beyond focusability |
| Migration status | CORRECTION NEEDED (medium: removes custom code) |
| Correction (if any) | Replace lines 24-52 by `FButton.icon(variant: FButtonVariant.primary, size: FButtonSizeVariant.lg, onPress:, style: FButtonStyleDelta.delta(decoration: FVariantsDelta.delta([FVariantOperation.all(DecorationDelta.shapeDelta(shadows: FTheme.of(context).style.shadow))]), iconContentStyle: FButtonIconContentStyleDelta.delta(constraints: BoxConstraints.tightFor(width: size, height: size))), child: Icon(icon, semanticLabel: semanticLabel))`; delete `_raised`. Removes about 22 lines and the `FVariants.raw`/`MapEntry` reconstruction. Risk: `DecorationDelta.shapeDelta` always yields `ShapeDecoration` (CAT:219); all primary variants are `ShapeDecoration` (the old `_raised` skipped other types, `mx_fab.dart:62`), PROBE confirms. Tests: re-run `mx_fab_test` (hover colour test reads variants) |

#### MxTooltip — `lib/shared/widgets/mx_tooltip.dart`
| Field | Record |
|---|---|
| Existing contract | `label` as ForUI tooltip on long press, hover, focus; the long-press action folds into the control's labelled node. Pinned indirectly: `mx_icon_button_test` ("one node that keeps the tap and the long press", "a long press shows the label as a tooltip"), `mx_fab_test` (M3F-11), `mx_stepper_test` ("each step button is one labelled node that keeps its tap and its long press"). No dedicated test file |
| Call sites | 3 widgets (all in the set): `mx_icon_button.dart`, `mx_fab.dart`, `mx_stepper.dart` |
| ForUI candidate APIs | `FTooltip` (`tipBuilder`, `longPress`, `hover`, `control`), `FTooltipGroup`, `FButton.semanticsTooltip` |
| Installed package version | forui 0.27.6 |
| Official documentation | https://forui.dev/docs/widgets/overlay/tooltip |
| Source evidence | `F:widgets/tooltip/tooltip.dart:139-156` ctor; `:268` long-press `GestureDetector` around the child; `:333` `Semantics(container: true)` on the tip only; `F:foundation/tappable/tappable.dart:711`; `F:foundation/doc_templates.dart:101-104` |
| API verification | PROBE `tip_test.dart` (answer a): `semanticsTooltip` does not remove the unlabelled `longPress` node; `longPress:false` does but removes touch discoverability; MergeSemantics gives one node with `tap,longPress` |
| Native capability | tip, hover/focus/long-press triggers, motion, haptics, Esc |
| Capability gaps | the long-press node is unlabelled and separate from the labelled control (`tooltip.dart:268` vs button node); no FTooltip parameter fixes it |
| Current approach | **Composition**: `MergeSemantics(FTooltip(tipBuilder: Text(label), child:))` |
| Selected approach | same |
| Why not a higher-level API? | n/a (native FTooltip plus the one documented semantics merge); `semanticsTooltip` alone leaves the node (probe B) |
| Contract tests | Indirect only; add a small `mx_tooltip_test` pinning "one node: label + tap + longPress" without going through a button wrapper |
| Migration status | MIGRATED |
| Correction (if any) | none (add the direct test) |

#### mx_tap_target helpers (`mxTargetStyle`, `mxIconTargetStyle`, `mxInsetDecoration`, `MxInsetShapeBorder`, `mxPaintedOnly`) — `lib/shared/widgets/mx_tap_target.dart`
| Field | Record |
|---|---|
| Existing contract | Keep a ForUI button on a 48 touch target while it paints 40 / 32 (decoration inset inside the target); loading keeps resting decoration/foreground in every state; `mxPaintedOnly` paints an interactive ForUI control for a parent that owns tap/focus/semantics. Tests (indirect): `mx_button_test` "each size paints its height and keeps a 48 target", "small painted sizes still offer 48x48 labelled targets", `mx_button_loading_test`, `mx_stepper_test` "small buttons painted in a 48 target", `test/support/forui_expect.dart` unwraps `MxInsetShapeBorder.base` |
| Call sites | `mxTargetStyle`/`mxIconTargetStyle`/`mxInsetDecoration`/`MxInsetShapeBorder`: 4 uses in 3 files (`mx_button.dart`, `mx_chip_style.dart`, `mx_stepper.dart`); `mxPaintedOnly`: 3 files (`mx_option_row.dart`, `mx_search_field.dart`, `mx_selection_checkbox.dart`) |
| ForUI candidate APIs | `FButtonStyleDelta`, `FVariantsDelta.delta([FVariantOperation.all(...)])`, custom `DecorationDelta`, `FButtonSizeVariant.lg` (48), `FTappable` hit-test, `ExcludeSemantics/ExcludeFocus/IgnorePointer` |
| Installed package version | forui 0.27.6 |
| Official documentation | https://forui.dev/docs/guides/customizing-widget-styles ; https://forui.dev/docs/guides/creating-custom-deltas |
| Source evidence | rg `tapTarget|hitSlop|hit_slop|minimumSize|kMinInteractive|expandHit` over `F:foundation/tappable`, `F:widgets/button`, `F:theme`: no hit; `F:theme/sizes.dart:19,46` touch sizes 32/40/44/48; `F:theme/variants.dart:255-300` delta ops; `F:theme/delta/decoration.dart:46-148` |
| API verification | PROBE `delta_test.dart`: a custom `DecorationDelta` implementation (`implements DecorationDelta`) applies through `FVariantsDelta.delta([FVariantOperation.all(delta)])` (rendered shape type = the custom border, height 40 button) |
| Native capability | none for target expansion; ForUI's tappable area is the painted box |
| Capability gaps | 40/32 painted buttons cannot keep a 48 hit area (no knob, rg above) |
| Current approach | **Fallback (justified)**: builds a full `FButtonStyle` via `base.copyWith`, rebuilds `FVariants.raw` maps per entry, custom `MxInsetShapeBorder` (about 60 lines); `mxPaintedOnly` is Foundation (three Flutter exclude widgets) |
| Selected approach | Fallback stays; optionally express the per-entry rebuild as a `FVariantsDelta.delta([.all(_InsetDelta)])` delta (probe-confirmed API) |
| Why not a higher-level API? | no ForUI hit-area API (gap above); `FButtonSizeVariant.lg` is 48 but changes the owner-specified painted heights (DESIGN.md size ladder) |
| Contract tests | Covered indirectly; missing a direct test for `mxInsetDecoration` / `MxInsetShapeBorder` (`lerp`, equality) |
| Migration status | BLOCKED (API limit; fallback justified) |
| Correction (if any) | Optional only: turn `mxTargetStyle`/`mxIconTargetStyle` into `FButtonStyleDelta`-returning helpers using a custom `DecorationDelta`. `MxButton.naturalWidth` needs the resolved style (`mx_button.dart:122`), so the helper would have to keep a resolved path for measurement; low value, not recommended before the higher items |

#### MxActionPair — `lib/shared/widgets/mx_action_pair.dart`
| Field | Record |
|---|---|
| Existing contract | Two footer actions side by side (flex shares, 8 apart) when both labels fit their share on one line, otherwise stacked full width, leading on top; follows window, text scale and label length; paired labels never wrap/ellipsize; asserts block + single-line. Tests: `mx_action_pair_test` (short labels equal widths 8 apart; flex shares; larger text scale stacks; long labels stack; no leading; never ellipsized or wrapped) |
| Call sites | 9 uses in 9 files, e.g. `lib/features/card/presentation/widgets/sections/card_editor_footer_widget.dart`, `lib/features/topik/presentation/screens/topik_review_screen.dart`, plus `mx_sheet_actions.dart` |
| ForUI candidate APIs | `FDialog.adaptive(horizontalBuilder:, verticalBuilder:)`, `FDialogAxisVariant`, `FButton` groups (none exist), `FItemGroup` |
| Installed package version | forui 0.27.6 |
| Official documentation | https://forui.dev/docs/widgets/overlay/dialog |
| Source evidence | `CAT:1789-1791` `FDialog.adaptive` switches on `MediaQuery.sizeOf(context).width < theme.breakpoints.sm` (640, `F:theme/breakpoints.dart:49`); `FDialogAxisVariant` unused in lib (rg); `F:widgets/dialog.dart` adaptive builder |
| API verification | none needed (source reading; the breakpoint is screen width, not label fit) |
| Native capability | none for a measure-and-switch footer |
| Capability gaps | `FDialog.adaptive` is dialog-only and switches by screen width, not by whether the labels fit at the text scale; the pair is also used in sheets |
| Current approach | **Foundation + minimal Flutter**: `LayoutBuilder` + `MxButton.naturalWidth` + `Row`/`Column` |
| Selected approach | same |
| Why not a higher-level API? | `FDialog.adaptive` gap above; no ForUI button-group or flow layout |
| Contract tests | Covered |
| Migration status | BLOCKED (no ForUI equivalent; current is minimal) |
| Correction (if any) | none |

#### MxSheetActions — `lib/shared/widgets/mx_sheet_actions.dart`
| Field | Record |
|---|---|
| Existing contract | Footer of every dialog and sheet: Cancel outline + confirm 1:1 via MxActionPair, tones destructive xor warning, `.single`, `.custom`, loading confirm spins while Cancel stays live, null `onCancel`/`onConfirm` disable, dialog form 24 inset, sheet form = divider rule on top + 8 16 16. Tests: `mx_sheet_actions_test` (14 tests: share/inset, loading confirm, destructive without glyph, warning, null Cancel, disabled confirm leaves Cancel live, sheet rule + 8 16 16, custom children, larger text stacks, equal width/height, single) |
| Call sites | 33 uses in 27 files, e.g. `lib/features/deck/presentation/widgets/overlays/deck_delete_dialog_widget.dart`, `lib/features/account/presentation/widgets/overlays/merge_choice_sheet_widget.dart`, `lib/features/trash/presentation/widgets/overlays/trash_restore_sheet_widget.dart` |
| ForUI candidate APIs | `FDivider` + `FDividerStyleDelta`, `FButton` (via MxButton), `FDialog` layout (caller's) |
| Installed package version | forui 0.27.6 |
| Official documentation | https://forui.dev/docs/widgets/layout/divider |
| Source evidence | `CAT:601-608` `FDivider` = `Container(margin: style.padding, color: style.color, height: style.width)` (`divider.dart:56-61`); `lib/shared/widgets/mx_divided_column.dart:40-47` already uses it with `color: border` and a custom padding; `lib/core/theme/theme_context.dart:27-28` `hairline = FTheme.style.borderWidth` (same value as `FDividerStyle.width`) |
| API verification | none needed (same call pattern already shipping in MxDividedColumn) |
| Native capability | hairline separator in the theme border colour with zero padding via delta |
| Capability gaps | none |
| Current approach | **Composition + Fallback for the rule**: MxActionPair + MxButton; the rule is a hand-built `DecoratedBox(border: top BorderSide(color: border, width: hairline))` (`mx_sheet_actions.dart:140-162`) |
| Selected approach | Composition with `FDivider` for the rule |
| Why not a higher-level API? | n/a (FDivider is the native rule) |
| Contract tests | Covered; the rule test reads `DecoratedBox ... border.top` so it changes with the correction |
| Migration status | CORRECTION NEEDED (low) |
| Correction (if any) | In the sheet form return `Column(mainAxisSize: min, children: [FDivider(style: FDividerStyleDelta.delta(color: context.colors.border, padding: EdgeInsetsGeometryDelta.value(EdgeInsets.zero))), Padding(EdgeInsets.fromLTRB(16, 8, 16, 16), child: row)])`; delete the `DecoratedBox`. Update `mx_sheet_actions_test` "in a sheet: a divider rule on top" to find `FDivider`. Verify the delta field names against `FDividerStyleDelta` before implementing (not compiled here). Golden unchanged if 1 px rule and colour match |

#### showMxDialog, showMxConfirm, MxDialog, MxDialogWidth — `lib/shared/widgets/mx_dialog.dart`
| Field | Record |
|---|---|
| Existing contract | `showMxDialog` pushes ForUI's dialog route over the barrier; scrim tap returns null unless held; returns what the dialog pops with; `showMxConfirm` true only on confirm; `MxDialog` = `FDialog` with title/body/content/actions, 24 edge, scroll if taller, width cap 340/320/300 and min 280, keeps actions above the keyboard, `isHeld` refuses Back and scrim, motion fade+scale (none under remove-animations). Tests: `mx_dialog_test` (ForUI dialog surface; width; title over body 16 in ForUI text styles; scrim tap returns null; returns pop value; fades and scales; reduced motion opens with no transition; one 24 edge; field above keyboard; scrolls when tall; isHeld), `mx_confirm_test` |
| Call sites | `showMxDialog|showMxConfirm`: 25 uses in 21 files; `MxDialog(`: 13 in 13 files, e.g. `lib/features/deck/presentation/widgets/overlays/deck_delete_dialog_widget.dart`, `lib/features/settings/presentation/widgets/overlays/settings_reset_dialog_widget.dart`, `lib/features/reminders/presentation/widgets/overlays/reminder_time_dialog_widget.dart` |
| ForUI candidate APIs | `showFDialog`, `FDialogRoute`, `FDialog`, `FDialog.adaptive`, `FDialogStyle`, `FDialogRouteStyle`, `FLocalizations`, `FTheme.capture`, `ModalRoute.animation` |
| Installed package version | forui 0.27.6 |
| Official documentation | https://forui.dev/docs/widgets/overlay/dialog |
| Source evidence | `F:widgets/dialog.dart:63-95` `showFDialog` (nearest navigator `:78`, barrier strings `:89-90`, `capturedFTheme`/`capturedThemes` `:86-87`); `:101-133` `FDialogRoute` (`barrierDismissible` final field, barrier tap pops `:153`); `FDialog` ctor `CAT:1789` with `constraints` default 280-560 and no title/actions API (docs "does not provide a built-in content layout"); `F:localizations/localizations_vi.dart:16-21` |
| API verification | PROBE `nav_test.dart` (root vs nearest, with go_router shell) and PROBE `anim_test.dart`: `identical(ModalRoute.of(context).animation, builder animation)` is `true` inside `showFDialog`'s builder. Tests pass |
| Native capability | route, scrim (`barrierFilter` blur + tint), fade/scale and reduced motion per `FAccessibilityMotion`, keyboard avoidance, semantics scope + `namesRoute`, captured theme |
| Capability gaps | (1) `FDialogRoute.barrierDismissible` is `final` and the barrier pops past `PopScope` (`dialog.dart:153`), so a *held* dialog needs a subclass (`MxHeldRoute`), hence `showFDialog` cannot be used; (2) no title/body/actions layout in `FDialog` (docs) -> MxDialog composes it; (3) `FLocalizations` vi barrier strings are defective (answer c) |
| Current approach | **Composition on ForUI's route**: own `_MxDialogRoute extends FDialogRoute with MxHeldRoute` (the body of `showFDialog` re-created, `mx_dialog.dart:17-37`), `FDialog(animation:, semanticsLabel: title, constraints:, builder:)`; `_DialogAnimation` InheritedWidget carries the route animation to `MxDialog` (`:177-188`); **nearest navigator** |
| Selected approach | Same composition, with (i) `Navigator.of(context, rootNavigator: true)`, (ii) the route animation read from `ModalRoute.of(context)?.animation`, (iii) caller-supplied barrier strings |
| Why not a higher-level API? | `showFDialog` cannot host the held route (gap 1) and `FDialog` has no layout (gap 2); FDialog.adaptive would not give the 24 edge/pair stacking |
| Contract tests | Covered. Missing: a dialog opened from a shell branch covers the bottom bar (`nav_test` shape); barrier strings in `vi` |
| Migration status | CORRECTION NEEDED (high: functional defect) |
| Correction (if any) | (i) `Navigator.of(context, rootNavigator: true)` in `showMxDialog` and use that navigator's context for `FTheme.capture`/`InheritedTheme.capture` (already written as `navigator.context`). PROBE: with root the shell's bottom bar is behind the scrim. Risks: the account transition layer (`AccountLayerHostWidget`, `lib/features/account/presentation/widgets/sections/account_layer_host_widget.dart:110-114`) hosts its own `Navigator`; a dialog from inside it resolves to that layer's navigator either way (root = outermost ancestor navigator of the context); check `account_confirm_dialog_widget.dart`. Add a widget test with a `StatefulShellRoute`. (ii) Delete `_DialogAnimation` (about 20 lines): `animation: ModalRoute.of(context)?.animation`; null outside a route = no animation as today (PROBE anim_test). (iii) Barrier strings: see record 9 correction; `showMxDialog` is a shared widget that holds no copy (`forui-shared-widgets` skill, line 39), so either add `barrierLabel`/`barrierHint` parameters fed by callers (about 25 call sites) or read `AppLocalizations` once in `showMx*` as an owner-approved exception (reuse-or-write call -> `AskUserQuestion`) |

#### showMxBottomSheet, MxBottomSheet — `lib/shared/widgets/mx_bottom_sheet.dart`
| Field | Record |
|---|---|
| Existing contract | ForUI modal sheet route (btt, safe area, no ratio cap) with the MemoX surface (background, hairline top border, large top radius), optional grabber (32x4 in a 48 target, TalkBack dismiss), `title`/`subtitle` head (2 lines, heading semantics), header/footer stay, only `child` scrolls, 85 % cap minus the keyboard, drag down and scrim dismiss unless `isHeld`, clears the keyboard. Tests: `mx_bottom_sheet_test` (surface; tinted content; 32x4 handle in 48x48; long content stops at 85 % and scrolls with footer; tappable row; scrim tap closes; returns pop value; held sheet ignores drag/scrim/Back; grabber dismisses for a screen reader; clears keyboard; title role/spacing; two-line title; title is a heading) |
| Call sites | `showMxBottomSheet`: 26 uses in 25 files; `MxBottomSheet(`: 28 in 23 files, e.g. `lib/features/deck/presentation/widgets/overlays/deck_action_sheet_widget.dart`, `lib/features/card/presentation/widgets/overlays/card_sort_sheet_widget.dart`, `lib/features/settings/presentation/widgets/overlays/new_card_order_sheet_widget.dart` |
| ForUI candidate APIs | `showFSheet`, `FModalSheetRoute`, `FSheetStyle`/`FModalSheetStyle`, `FLayout.btt`, `showFPersistentSheet`, `FLocalizations` |
| Installed package version | forui 0.27.6 |
| Official documentation | https://forui.dev/docs/widgets/overlay/sheet |
| Source evidence | `F:widgets/sheet/modal_sheet.dart:70-112` `showFSheet` (nearest navigator `:90`, strings `:101-102`); `:225-243` route ctor; `:298`/`:310` barrier pops `Navigator.pop` ignoring `PopScope`; `F:widgets/sheet/shifted_sheet.dart:109-127` max height = `constraints.maxHeight * ratio`, bottom shifted up by `bottomViewInset` and clamped with `max(0, ...)`; `F:widgets/sheet/sheet.dart:150-191` (safe area, drag, `Semantics(scopesRoute, namesRoute, label: sheetSemanticsLabel` except iOS`)`); `CAT:1811` draggable has `excludeFromSemantics: true`; `FModalSheetStyle` has no decoration (surface is the caller's) |
| API verification | PROBE `nav_test.dart` (same mechanism: `Navigator.of(rootNavigator:)`; the sheet route uses the identical line `:90`). Tests pass |
| Native capability | route, slide/fade and reduced motion per FAccessibility, drag to dismiss, scrim, safe area, keyboard shift, semantics scope |
| Capability gaps | (1) no surface/handle/head in ForUI; (2) `mainAxisMaxRatio: 0.85` would size from the full height and push the top off screen when the keyboard shifts the sheet (`shifted_sheet.dart:114,124`), contract "clears the keyboard" (test) needs the `(height - inset) * 0.85` cap; (3) no semantics action for the drag (`CAT:1811`), hence the custom grabber node; (4) route cannot be held (as the dialog); (5) vi barrier strings |
| Current approach | **Composition on ForUI's route + Foundation for the surface**: `_MxSheetRoute extends FModalSheetRoute with MxHeldRoute`, `mainAxisMaxRatio: null`, `useSafeArea: true`, own `ConstrainedBox`/`DecoratedBox`/`ClipRRect`/`SafeArea` surface, custom grabber `Semantics`, `MxHoldRoute` + `GestureDetector` absorber for the held drag; **nearest navigator** |
| Selected approach | Same, with `Navigator.of(context, rootNavigator: true)` and caller-supplied barrier/grabber strings |
| Why not a higher-level API? | `showFSheet` cannot host a held route; ForUI has no sheet surface; ratio gap (2) |
| Contract tests | Covered; missing shell-coverage test and `vi` strings test (`mx_bottom_sheet_test.dart:267` pins `FLocalizations.barrierLabel`, i.e. pins the defect) |
| Migration status | CORRECTION NEEDED (high) |
| Correction (if any) | (i) `rootNavigator: true` as in record 8 (PROBE-proven for dialog; same navigator call). (ii) Vietnamese strings: the grabber name and the route barrier would read "Scrim" and the literal "Đóng $modalRouteContentName" (`localizations_vi.dart:16-21`); pass `barrierLabel` and a hint from `AppLocalizations` (new ARB keys, e.g. a "close" label and a "close {name}" hint; existing `commonOk`/`commonBack` do not fit) and use the same label for the grabber; update `mx_bottom_sheet_test.dart:267`. Needs an owner decision because it adds copy and a shared-widget parameter or exception (`AskUserQuestion`). No `src/` import of `FLocalizationsVi` (not exported) |

#### MxHeldRoute (mixin), MxHoldRoute — `lib/shared/widgets/mx_held_route.dart`
| Field | Record |
|---|---|
| Existing contract | While held, a scrim tap does nothing and the barrier absorbs pointers; `PopScope(canPop: !isHeld)` refuses Back; flag read when the tap lands; barrier semantics follow after the frame. Tests (indirect): `mx_dialog_test` "isHeld: Back and a scrim tap leave the dialog open", `mx_bottom_sheet_test` "a held sheet ignores a drag, a scrim tap and Back", `mx_deck_picker_sheet_test` "isHeld holds its sheet" |
| Call sites | mixed into 2 routes (`mx_dialog.dart`, `mx_bottom_sheet.dart`); `isHeld:` set by 10 files outside shared, e.g. `deck_delete_dialog_widget.dart:117`, `card_move_sheet_widget.dart:86`, `trash_purge_dialog_widget.dart:81` |
| ForUI candidate APIs | `FDialogRoute(barrierDismissible)`, `FModalSheetRoute(barrierDismissible)`, `FModalBarrier`, `showFDialog(barrierDismissible:)` |
| Installed package version | forui 0.27.6 |
| Official documentation | https://forui.dev/docs/widgets/overlay/dialog ; https://forui.dev/docs/widgets/overlay/sheet |
| Source evidence | `F:widgets/dialog.dart:109,153,164` `final bool barrierDismissible`, barrier `onDismiss: ... Navigator.pop(context)`; `F:widgets/sheet/modal_sheet.dart:213-214,298,310` same; `CAT:1784` "no PopScope/WillPop anywhere in the forui lib" ; `F:foundation/barrier.dart:208-214` a non-dismissible barrier plays `SystemSound.alert` on tap |
| API verification | none needed (source); the existing tests exercise it |
| Native capability | static `barrierDismissible` chosen at push time |
| Capability gaps | cannot be toggled while the route is open; Back is not guarded; a non-dismissible barrier beeps |
| Current approach | **Foundation + minimal Flutter**: mixin overriding `barrierDismissible`, a render-object gate on the barrier, `PopScope` |
| Selected approach | same |
| Why not a higher-level API? | gaps above; no ForUI hold/lock concept |
| Contract tests | Indirect; no test of the mixin alone (acceptable) |
| Migration status | BLOCKED (API limit; justified) |
| Correction (if any) | none |

#### showMxSnackbar, MxSnackbarController, MxToastHost, mxUndoWindow — `lib/shared/widgets/mx_snackbar.dart`
| Field | Record |
|---|---|
| Existing contract | One toast at a time: a new one replaces the current (FE-B1 D14); message + one optional 48-target action (outline small MxButton); action hides the toast then calls back once; stays `duration` (4 s, `mxUndoWindow` 8 s); an action toast stays while TalkBack is on; swipe down dismisses; live region; above keyboard and insets; sliding/fading unless remove-animations; `closed` completes however it left; actionLabel/onAction asserted together; wide window: no wider than the toast style, centred; phone: fits the screen. Tests: `mx_snackbar_test` (toast is ForUI's FToast; message alone; short action beside message in a labelled 48 target; long action; Undo hides + once; long message wraps; stays its duration then goes; default 4 s; under TalkBack an action toast stays; new toast replaces; close() completes closed; closed on timeout; actionLabel/onAction assert; wide window; phone) |
| Call sites | `showMxSnackbar`: 82 uses in 46 files, e.g. `lib/app/app_theme_host.dart`, `lib/features/deck/presentation/widgets/support/deck_trashed_snackbar_widget.dart`, `lib/features/monitoring/presentation/screens/monitoring_detail_screen.dart` (uses the controller); `MxToastHost`: `lib/app/app_theme_host.dart:48` |
| ForUI candidate APIs | `FToaster`, `showFToast`, `showRawFToast`, `FToasterEntry`, `FToasterStyle`, `FToast`, `FToastAlignment`, `FAccessibility`/`context.accessibility` |
| Installed package version | forui 0.27.6 |
| Official documentation | https://forui.dev/docs/widgets/overlay/toast |
| Source evidence | `F:widgets/toast/toaster.dart:36-153` `showFToast`/`showRawFToast`; `:293-` `FToaster`, `:392` `SafeArea` only, `:410` `Overlay.wrap`; `F:widgets/toast/toaster_stack.dart:66` reduced-motion read, `:116-127` MouseRegion + unconditional `GestureDetector(onTap: pause)`; `F:widgets/toast/animated_toast.dart:122-124` timer, `:292` reduceMotion, `:378-383` `Semantics(container, liveRegion: visible, onDismiss)`; `F:foundation/accessibility.dart:118-128`; Flutter `widgets/media_query.dart:665-670`; `CAT:1856-1877` |
| API verification | PROBE `toast_test.dart` (semantics of FToaster vs the MxSnackbar shape) |
| Native capability | stack, swipe-to-dismiss, auto-dismiss timer (`duration: null` persists), dismiss semantics action, live region, reduced motion incl. `accessibleNavigation`, SafeArea, `suffixBuilder` action, `onDismiss` |
| Capability gaps | unconditional tap-to-pause (`toaster_stack.dart:119-127`); unlabelled tap + scroll actions on the root semantics node (probe); no keyboard inset; no replace-on-new; no `closed` future; stack up to 3 |
| Current approach | **Foundation + Composition**: own `MxToastHost` (a `Stack` over the Navigator) and `_ToastView` (fade + slide with `Durations`/`Easing`, `Dismissible`, `Semantics(liveRegion)`) around ForUI's `FToast` widget with `toasterStyle.padding`/`toastStyles.primary.constraints`; action = `MxButton`; Timer owned by the controller |
| Selected approach | Same host (BLOCKED for FToaster); `FToast` stays the surface; read motion/screen-reader state from `context.accessibility` |
| Why not a higher-level API? | `FToaster` gaps above (the tap-to-pause cannot be switched off, root-node semantics, keyboard, replace) |
| Contract tests | Covered; missing: keyboard inset, reduced motion (`FakeAccessibilityFeatures(disableAnimations: true)` -> toast appears/disappears at once), screen-reader dismiss action |
| Migration status | CORRECTION NEEDED (low); host itself BLOCKED/justified |
| Correction (if any) | In `_ToastViewState` replace both `MediaQuery.disableAnimationsOf(context)` (`mx_snackbar.dart:177,186`) by `context.accessibility.motion != FAccessibilityMotion.all || context.accessibility.accessibleNavigation`, and `MediaQuery.accessibleNavigationOf(context)` (`:138`) by `context.accessibility.accessibleNavigation` (same source, so no behavioural change on Android except that a TalkBack user no longer gets the slide). Optionally add `onDismiss: widget.controller.close` to the toast `Semantics` so TalkBack gets ForUI's `dismiss` action. Tests to add: reduced-motion toast, dismiss action. Risk: `MxSnackbar` tests that override via `MediaQuery` would stop working for ForUI-scoped reads; they already use `FakeAccessibilityFeatures` |

#### MxDeckPickerSheet, MxDeckPickerLoadingSheet, MxDeckPickerErrorSheet, MxPickerCandidate — `lib/shared/widgets/mx_deck_picker_sheet.dart`
| Field | Record |
|---|---|
| Existing contract | Sheet head (title + rule), chevron candidate rows, ineligible candidate stays visible dimmed with its reason, nowhere-to-go empty state + primary OK, many candidates scroll with a stationary footer, loading sheet keeps the head over a skeleton, error sheet = head + MxErrorState retry + way out, `isHeld` holds the sheet and disables its dismiss. Tests: `mx_deck_picker_sheet_test` (7 tests as listed: head; candidates/reason; empty; scroll + footer; loading head; isHeld; error sheet) |
| Call sites | 10 uses in 4 files: `lib/features/card/presentation/widgets/overlays/card_move_sheet_widget.dart`, `lib/features/deck/presentation/widgets/overlays/deck_move_sheet_widget.dart`, `lib/features/trash/presentation/widgets/overlays/trash_restore_sheet_widget.dart` |
| ForUI candidate APIs | `FItemGroup`, `FItem`, `FTile` (rows), `showFSheet` (sheet) |
| Installed package version | forui 0.27.6 |
| Official documentation | https://forui.dev/docs/widgets/data/item-group ; https://forui.dev/docs/widgets/overlay/sheet |
| Source evidence | rows are `MxListRow`/`MxDividedColumn` (other set, audited with the list rows: `CAT:635-700` for FItem/FItemGroup); sheet = record 9 |
| API verification | none needed here; tests pass |
| Native capability | n/a at this level: pure composition of MemoX widgets |
| Capability gaps | n/a (row-level candidates belong to the MxListRow audit) |
| Current approach | **Composition** (MxBottomSheet + MxSheetActions.single + MxListRow + MxDividedColumn + MxEmptyState + MxErrorState + MxSkeletonList) |
| Selected approach | same; inherits the record 8-9 and 7 corrections |
| Why not a higher-level API? | no ForUI picker-sheet; `FItemGroup` rows are an MxListRow decision, not this file's |
| Contract tests | Covered |
| Migration status | MIGRATED |
| Correction (if any) | none of its own |

#### MxFloatingNotice — `lib/shared/widgets/mx_floating_notice.dart`
| Field | Record |
|---|---|
| Existing contract | Standing warning notice over the page: tinted warning ground, ForUI shadow, 12 radius (`radii.md`), glyph in the warning text colour, one sentence that wraps, one action on the message line or several on their own line at the end, live region, min height 48. Tests: `mx_floating_notice_test` (warning card lifted by the shadow, reads `BoxDecoration`; dark tint; one action on the line; two under; live region) |
| Call sites | 3 uses in 3 files: `lib/features/study/presentation/widgets/sections/study_home_sync_banner_widget.dart`, `lib/features/account/presentation/widgets/sections/account_reauth_notice_widget.dart`, `lib/app/gallery/gallery_overlays_section.dart` (placed by `MxAppShell`) |
| ForUI candidate APIs | `FAlert`, `FCard` + `FCardStyleDelta`, `FToast` |
| Installed package version | forui 0.27.6 |
| Official documentation | https://forui.dev/docs/widgets/feedback/alert ; https://forui.dev/docs/widgets/data/card |
| Source evidence | `FAlert`: `F:widgets/alert.dart:95-135` fixed `Column(Row(icon,title), Row(SizedBox(iconSize), subtitle))`, variants only `primary|destructive` (`CAT:1703-1710`), no action/close slot, padding h16 v12; `FCard`: `DecoratedBox` only, no padding/layout (`CAT:610-617`; `lib/shared/widgets/mx_card.dart:92-104` already uses it with `DecorationDelta.shapeDelta`) |
| API verification | none needed (source reading) |
| Native capability | `FAlert`: live-region container, icon + title; `FCard`: themed surface |
| Capability gaps | `FAlert`: no warning variant, no action slot, layout cannot put one action at the end of the message line; the sentence would need the title style and the actions a hand-built subtitle row indented by the icon (`alert.dart:122-130`). `FCard`: none for the surface |
| Current approach | **Fallback** (custom Flutter): `Semantics(liveRegion)` + `DecoratedBox(BoxDecoration(color, borderRadius, boxShadow))` + own Row/Column |
| Selected approach | Composition: `FCard` as the surface (as MxCard) with the same Row/Column layout; FAlert rejected |
| Why not a higher-level API? | FAlert gaps above |
| Contract tests | Covered, but they read `BoxDecoration`; they change with the surface |
| Migration status | CORRECTION NEEDED (low; optional, golden may change) |
| Correction (if any) | Wrap the padded layout in `FCard(style: FCardStyleDelta.delta(decoration: DecorationDelta.shapeDelta(color: tint, shape: RoundedSuperellipseBorder(borderRadius: context.radii.md), shadows: FTheme.of(context).style.shadow)), child: ...)` and remove the `DecoratedBox`. Result: the notice uses the same superellipse corner as every other ForUI surface (visible change in corner shape; golden review required). Update `_ground()` in the test |

#### MxToggle — `lib/shared/widgets/mx_toggle.dart`
| Field | Record |
|---|---|
| Existing contract | `FSwitch` in a 48x48 box; a tap anywhere in the box flips it once; ForUI focus outline; one TalkBack node with label, toggled, enabled, tap; disabled when `onChanged` null (also unfocusable); pressed-on thumb/track kept apart (M3F-15). Tests: `mx_toggle_test` (14 tests: ForUI switch in a 48 box; 48 tall; off/on tracks; one flip per switch tap; box beside the switch flips; announced as labelled toggle with 48 target; focus colour; M3F-15; ring drops when rebuilt disabled; disabled no second dim; disabled takes no tap; disabled to TalkBack) |
| Call sites | 11 uses in 11 files, e.g. `lib/features/settings/presentation/widgets/sections/settings_session_section_widget.dart`, `lib/features/deck/presentation/widgets/overlays/deck_level_query_sheets_widget.dart`, `lib/app/gallery/gallery_inputs_section.dart` |
| ForUI candidate APIs | `FSwitch` (`value`, `onChange`, `enabled`, `semanticsLabel`, `focusNode`), `FSwitchStyle`, `FLabel` |
| Installed package version | forui 0.27.6 |
| Official documentation | https://forui.dev/docs/widgets/form/switch |
| Source evidence | `F:widgets/switch.dart:151-196` `FSwitch` build: its own `GestureDetector(onTap)` and `Semantics(label, enabled, focusable, focused, toggled)`; **`:175` `CupertinoSwitch(onChanged: ...)` is always non-null, so a disabled FSwitch stays focusable** (hence `ExcludeFocus`); CupertinoSwitch size 51x31 so no 48 height |
| API verification | PROBE `switch_test.dart`/`switch2_test.dart`: `FSwitch(semanticsLabel)` alone `[4] hasEnabledState,isEnabled,hasToggledState,isToggled,isFocusable actions=tap label` rect 360x39 -> 59x39; `MergeSemantics(GestureDetector(opaque, onTap) > 48 box > FSwitch)` -> one node, same flags + `isFocusable`, rect 59x48; a semantic `tap` runs only the outer handler once (`outer=1 inner=0`), a pointer tap on the switch runs the inner once. Tests pass |
| Native capability | switch visuals, states, focus ring colour, label/toggled/enabled semantics |
| Capability gaps | 31 dp tall paint, no hit-area knob; disabled switch still focusable (`switch.dart:175`) |
| Current approach | **Composition**: `FSwitch` inside `GestureDetector` + `ConstrainedBox(48)` + explicit `Semantics(container, label, toggled, enabled, onTap, excludeSemantics: true)` + `ExcludeFocus` |
| Selected approach | Composition (same level) |
| Why not a higher-level API? | n/a (native FSwitch is used; the box and the `ExcludeFocus` close verified gaps) |
| Contract tests | Covered |
| Migration status | MIGRATED |
| Correction (if any) | Optional simplification, not required: `MergeSemantics` + `GestureDetector(...)` + `FSwitch(semanticsLabel: ...)` gives the same single 48 node with label, toggled, enabled, tap and also `isFocusable` (PROBE), removing the six-line explicit `Semantics`; keep `ExcludeFocus` |

#### MxSlider — `lib/shared/widgets/mx_slider.dart`
| Field | Record |
|---|---|
| Existing contract | Seek bar in the caller's unit (`value`, `max`); value past max drawn at max; `max` 0 or null `onChanged` = disabled; `onChanged`/`onChangeEnd`; one merged TalkBack node with the label and a `semanticFormatter` value; 48 target: the whole 48 height seeks; arrow keys move; focus outline round the handle. Tests: `mx_slider_test` (13 tests: ForUI slider from theme; formatter; drags report value and end; tap on track; past max; max 0; null onChanged; focus outline; arrow keys; announced; handle is 48 target; whole 48 target seeks) |
| Call sites | 2 uses: `lib/features/topik/presentation/widgets/sections/topik_audio_bar_widget.dart`, `lib/app/gallery/gallery_inputs_section.dart` |
| ForUI candidate APIs | `FSlider`, `FSliderControl.liftedContinuous`, `FSliderValue`, `trackHitRegionCrossExtent`, `FSliderTooltipControls.disabled()`, `tooltipBuilder`, `semanticFormatterCallback`, `semanticValueFormatterCallback`, `onEnd` |
| Installed package version | forui 0.27.6 |
| Official documentation | https://forui.dev/docs/widgets/form/slider |
| Source evidence | `F:widgets/slider/track.dart:42,71` the slider is sized `max(thumbSize, crossAxisExtent)` = 25 on touch; `:149-153` hit region `Container(height: trackHitRegionCrossExtent ?? max(thumbSize, crossAxisExtent))` inside that box; `:74-` slider `Semantics` with no label; `F:widgets/slider/slider.dart:137` `tooltipBuilder = defaultTooltipBuilder` (percent, `:23`) and `FSliderTooltipControls` default enabled (`slider_control.dart:360-376`); `CAT:1536-1580` |
| API verification | PROBE `slider_test.dart`: with `trackHitRegionCrossExtent: 48` the slider is still `Size(360, 25)`; a tap 20 dp above the centre is ignored (`v=0.20 changes=0 ends=0`), a drag from 18 dp below the centre is ignored, a tap on the track works. PROBE `slider2_test.dart`: the default tooltip shows percent text while dragging (`[20%]`). Tests pass |
| Native capability | normalised value model, drag/tap/keys, focus outline, semantics slider with increase/decrease, formatter callbacks |
| Capability gaps | (1) hit region is bounded by the 25 dp slider box, so the 48 target needs the margin gesture layer (verified by the probe); (2) no `semanticsLabel` (only a visible `label:` widget, `slider.dart` ctor, rg `semanticsLabel`: none) -> merged label wrapper; (3) values are fractions, the caller's unit needs mapping |
| Current approach | **Composition + Foundation fallback**: `FSlider(liftedContinuous)` mapped to the caller's unit, `MergeSemantics(Semantics(label))`, a `Stack` + `LayoutBuilder` + `GestureDetector` (about 40 lines) that re-implements seek-by-position for the margins above/below the track; default tooltips left on |
| Selected approach | Same (margins are a justified fallback, gap 1); pass `tooltipBuilder`/`tooltipControls` so the tooltip speaks the caller's unit |
| Why not a higher-level API? | `trackHitRegionCrossExtent` is the ForUI knob and the probe shows it cannot exceed the 25 dp box, so it cannot give 48; no label parameter |
| Contract tests | Covered; missing: tooltip text while dragging (currently ForUI's percentage, while TalkBack/semantics say e.g. "3s"; the margin gesture shows no tooltip at all) |
| Migration status | CORRECTION NEEDED (low) |
| Correction (if any) | When `semanticFormatter != null` pass `tooltipBuilder: (_, fraction) => FTooltip-style Text(formatter(fraction * max))`, otherwise `tooltipControls: const FSliderTooltipControls.disabled()`; verify the `tooltipBuilder` signature `Widget Function(FTooltipController, double)` (`slider.dart:23`). Risk: golden/visual only while dragging. Optional: pass `trackHitRegionCrossExtent` is useless (probe) so leave the margins |

#### MxStepper — `lib/shared/widgets/mx_stepper.dart`
| Field | Record |
|---|---|
| Existing contract | Bounded integer input: minus / value / plus; bounds, clamping and validation message are the caller's (null callback stops at a bound without dimming); hold repeats (400 ms delay, then 80 ms; a hold that becomes a scroll never repeats); tapping the number types digits (Done / leaving submits); `minDigits` zero-pad ("07"); invalid ring (1 px error edge, no layout shift); busy spinner; disabled dims the value once; the step buttons are 32 painted in 48 targets with labels and tooltips; the number is one TalkBack node (name, value, Edit hint, invalid); Tab reaches the number which draws the primary outline and opens on Enter. Tests: `mx_stepper_test` (13), `mx_stepper_input_test` (10: tap/hold repeat, scroll cancel, bound stop, type + Done, no edge of its own M3F-16, leave submits digits only, not typeable without callback, one TalkBack node, 48 target in a row, M3F-06 focus/Enter, non-editable takes no focus) |
| Call sites | 8 uses in 6 files, production: `lib/features/reminders/presentation/widgets/overlays/reminder_time_dialog_widget.dart:66,92` (screen 24 hour + minute), `lib/features/settings/presentation/widgets/sections/settings_session_section_widget.dart:43`, `lib/features/settings/presentation/widgets/sections/study_options_form_widget.dart:151` |
| ForUI candidate APIs | none for a stepper; `FTimePicker`, `FTimeField`, `FPicker` (wheels), `FTextField`, `FButton.icon`, `FTappable`, `FTooltip` |
| Installed package version | forui 0.27.6 |
| Official documentation | https://forui.dev/docs/widgets/form/text-field ; https://forui.dev/docs/widgets/form/time-picker ; https://forui.dev/docs/widgets/form/button |
| Source evidence | answer (e): no stepper in `forui-0.27.6/lib/` or docs; `F:foundation/tappable/tappable.dart:197-215` `FTappable` exposes `onLongPressStart/Move/End/Cancel`, but `F:widgets/button/button.dart:113-114,297` `FButton` forwards only `onLongPress` (no start/end, no repeat anywhere: rg `repeat|hold` in tappable: none); `FTooltip` is suppressed when its child has its own long press (catalog tooltip section, "does not show if the child has its own long-press", PROBE `tip_test.dart` in the catalog) |
| API verification | PROBE `iconsem_test.dart` A vs B for the step-button labelling (focus semantics); existing tests pass |
| Native capability | `FButton.icon` (secondary, xs) step buttons; `FTextField` for the typed value; `FTappable` via MxRowInk for the number target |
| Capability gaps | no ForUI numeric stepper; no hold-to-repeat on `FButton`; `FButton.onLongPress` would replace the tooltip and has no release event; wheels (`FTimePicker`) rejected by the screen 24 owner ruling |
| Current approach | **Composition + Foundation fallback**: `FButton.icon` secondary xs in `mxIconTargetStyle` + `MxTooltip`, raw `Listener` + `Timer` hold repeat with touch-slop cancel; `FTextField` (digits only) swapped in for the number; value box `DecoratedBox` for the ring; `MxRowInk` for tap/focus/semantics |
| Selected approach | Same (no higher-level ForUI exists; owner ruling) with the step-button labelled via `Icon(semanticLabel:)` |
| Why not a higher-level API? | answer (e) plus the long-press gaps above |
| Contract tests | Covered thoroughly. Missing: input focusability of the step buttons |
| Migration status | CORRECTION NEEDED (low; shared with records 2-3) |
| Correction (if any) | In `_StepButtonState.build` drop `semanticsLabel: widget.label` and use `Icon(widget.icon, size: ..., semanticLabel: widget.label)` (`mx_stepper.dart:360-368`); re-run `mx_stepper_test` "each step button is one labelled node that keeps its tap and its long press". Nothing else changes; do not replace the hold repeat or the typed field |

#### MxSpinner, MxSpinnerSize — `lib/shared/widgets/mx_spinner.dart`
| Field | Record |
|---|---|
| Existing contract | 2 px ring, one quarter open, one turn per 0.8 s, **keeps turning under remove-animations** (ruling O1), four sizes 16/20/24/32 off the icon scale, colour = primary or the caller's foreground (M3F-02), silent unless `semanticLabel`. Tests: `mx_spinner_test` (four sizes; 2 px primary / given colour via `paints..arc(strokeWidth: 2)`; quarter turn every 0.2 s also under reduced motion; named spinner is heard, bare one is not); `mx_button_loading_test` reads the painter's `color` |
| Call sites | 17 uses in 14 files, e.g. `lib/shared/widgets/mx_button.dart`, `lib/features/account/presentation/widgets/sections/code_form_widget.dart`, `lib/shared/widgets/mx_list_row.dart`; screen 24 uses it for the reminder toggle turning on/off |
| ForUI candidate APIs | `FCircularProgress`, `FCircularProgressStyleDelta`, `FCircularProgressMotion`, `FCircularProgressSizeVariant`, `FInheritedCircularProgressStyle`, `FAccessibilityScope`, `FAccessibility` |
| Installed package version | forui 0.27.6 |
| Official documentation | https://forui.dev/docs/widgets/feedback/circular-progress |
| Source evidence | `F:widgets/progresses/circular_progress.dart:129-148` `_setup` (stops only `motion == .disabled`), `:167` bare icon under disabled, `:294-306` `FCircularProgressMotion(duration 1 s, curve, tween)`, `:73` ctor with `style`, `semanticsLabel` (default "Loading"/"Đang tải"), `:130-133` style source; `F:foundation/accessibility.dart:75-161` public `FAccessibilityScope(data:)`; `F:theme/icons.dart:138,257` Lucide `loaderCircle`; `CAT:1713-1724` |
| API verification | PROBE `spin_test.dart` (disable-animations: plain = no `Transform`, scoped = rotates) and PROBE `spin2_test.dart` (full replacement: sizes 20/32 exact, 800 ms cycle quarter turn under disable-animations, bare = no semantics node, named = `label="Loading"`). Both pass |
| Native capability | rotation, colour and size via style delta, semantics label, motion duration; spins under `all` and `reduced`; spins under `disabled` when wrapped in an `FAccessibilityScope` whose `motion` is not `disabled` |
| Capability gaps | stroke width is the Lucide glyph's (scales with size: about 1.33 px at 16 dp vs the pinned 2 px) and the caps are round; the project docs say "ForUI's progress stops under reduced motion" (true only for Android remove-animations, fixed by the scope override) |
| Current approach | **Fallback (custom Flutter)**: `AnimationController.repeat` + `RotationTransition` + `CustomPaint` arc (about 70 lines) |
| Selected approach | Composition: `FCircularProgress` with a style delta (size, colour, 800 ms motion) inside `FAccessibilityScope(data: FAccessibility(accessibleNavigation: a.accessibleNavigation, motion: a.motion == disabled ? reduced : a.motion, focusHighlight: a.focusHighlight))`, `ExcludeSemantics` when no label |
| Why not a higher-level API? | n/a once the scope override is used (native widget). Pure `FCircularProgress` without the override would freeze under Android remove-animations and break ruling O1 |
| Contract tests | Behaviour covered; the painter-level tests (`paints..arc`, `_ringColor`) would be rewritten against the icon colour/size |
| Migration status | CORRECTION NEEDED (medium: removes about 60 lines; visual change needs the owner) |
| Correction (if any) | Replace the file body with the PROBE `spin2_test.dart` shape (a function-built widget keeping `MxSpinner(size, color, semanticLabel)` API). Risks: ring weight/caps differ (goldens that show a spinner: Account sign-in/code form, reminder toggle, Trash/Monitoring; owner decision per `DESIGN.md:306` and `MIGRATION_EXECUTION.md:26`, which should be amended to "stops only under Android remove-animations; overridden by an FAccessibilityScope"); `mx_button_loading_test` `_ringColor` helper; MxButton's spinner colour then comes from `textStyle.color` through the same delta. If the owner prefers the exact 2 px arc, keep the custom ring (status then BLOCKED by the visual ruling) |

---

### Summary table

| Component | Current | Selected | Status |
|---|---|---|---|
| MxButton | Composition (FButton builder) + fallbacks | Composition, semanticLabel in child | CORRECTION NEEDED (low) |
| MxIconButton | Composition (FButton.icon ghost lg + MxTooltip) | Composition, `Icon(semanticLabel:)` | CORRECTION NEEDED (low) |
| MxFab | Composition, hand-rebuilt FVariants | Composition via FVariantsDelta | CORRECTION NEEDED (medium) |
| MxTooltip | Composition (FTooltip + MergeSemantics) | same | MIGRATED |
| mx_tap_target helpers | Fallback (justified) | Fallback | BLOCKED |
| MxActionPair | Foundation (LayoutBuilder) | same | BLOCKED |
| MxSheetActions | Composition + hand-built rule | Composition + FDivider | CORRECTION NEEDED (low) |
| showMxDialog / MxDialog | Composition on FDialogRoute, nearest navigator | + root navigator, ModalRoute animation, caller strings | CORRECTION NEEDED (high) |
| showMxBottomSheet / MxBottomSheet | Composition on FModalSheetRoute + custom surface, nearest navigator | + root navigator, caller strings | CORRECTION NEEDED (high) |
| MxHeldRoute / MxHoldRoute | Foundation | same | BLOCKED |
| showMxSnackbar / MxToastHost | Foundation host + ForUI FToast | same host, FAccessibility reads | CORRECTION NEEDED (low); host justified |
| MxDeckPickerSheet (+Loading/Error) | Composition of Mx widgets | same | MIGRATED |
| MxFloatingNotice | Fallback (DecoratedBox) | Composition (FCard surface) | CORRECTION NEEDED (low) |
| MxToggle | Composition (FSwitch + 48 box) | same (optional MergeSemantics) | MIGRATED |
| MxSlider | Composition + margin fallback | same + unit-aware tooltip | CORRECTION NEEDED (low) |
| MxStepper | Composition + Foundation (hold repeat) | same + labelled Icon | CORRECTION NEEDED (low) |
| MxSpinner | Fallback (custom painter) | Composition (FCircularProgress + FAccessibilityScope) | CORRECTION NEEDED (medium, owner) |

Counts: 17 components: MIGRATED 3, CORRECTION NEEDED 11, BLOCKED 3 (mx_tap_target, MxActionPair, MxHeldRoute).

### Corrections, ordered by value

1. **Root navigator for `showMxDialog` and `showMxBottomSheet`** (records 8, 9). Functional defect, PROBE-proven: the bottom bar stays tappable through the scrim and a held popup can be left by a tab switch. One-line change in two files, no new code; add a shell-route widget test. Tier 1 (`lib/shared/`).
2. **Barrier and grabber strings in Vietnamese** (records 8, 9): "Scrim" and the literal `$modalRouteContentName` reach TalkBack. Needs an owner decision (copy in a shared widget: caller parameters vs one `AppLocalizations` read), new ARB keys, update `mx_bottom_sheet_test.dart:267`.
3. **MxSpinner on `FCircularProgress` + `FAccessibilityScope` override** (record 17): removes about 60 lines of controller + painter, keeps ruling O1 (PROBE); visual change (stroke/caps) -> golden review and owner approval; amend `DESIGN.md:306`, `MIGRATION_EXECUTION.md:26`, the `mx_spinner.dart` doc.
4. **MxFab through `variant: primary, size: lg` + `FVariantsDelta.delta([.all(DecorationDelta.shapeDelta(shadows:))])`** (record 3): removes the `FVariants.raw`/`_raised` rebuild (about 22 lines), PROBE-verified.
5. **MxDialog: delete `_DialogAnimation`, read `ModalRoute.of(context)?.animation`** (record 8): removes about 20 lines, PROBE-verified `identical`.
6. **Keep input-focus semantics on labelled buttons** (records 1, 2, 3, 16): `Icon(semanticLabel:)` / `Semantics(label:)` in the child instead of `FButton.semanticsLabel` (`button.dart:304` drops `isFocusable` and the `focus` action; PROBE). One node, tap, long press unchanged.
7. **MxSnackbar reads `context.accessibility`** (record 11): `motion != all || accessibleNavigation`, same source as ForUI's dialog/sheet; optional `onDismiss` semantics action. The host itself stays (unconditional tap-to-pause, root-node semantics, keyboard inset, replace).
8. **MxSlider tooltip in the caller's unit** (record 15): `tooltipBuilder` from `semanticFormatter` or `FSliderTooltipControls.disabled()`; the percentage tooltip contradicts the time value TalkBack reads.
9. **MxSheetActions rule via `FDivider`** (record 7): same pattern as MxDividedColumn.
10. **MxFloatingNotice surface via `FCard`** (record 13): consistency (superellipse), optional, golden change.
11. Optional only: `mxTargetStyle`/`mxIconTargetStyle` as `FButtonStyleDelta` helpers (record 5); `MxToggle` explicit `Semantics` -> `MergeSemantics` (record 14); a direct `mx_tooltip_test`.

Observations outside the set: `MediaQuery.disableAnimationsOf` is the motion source of about ten other shared/study widgets (rg `disableAnimationsOf`); they honour Android remove-animations correctly and need no change for an Android-only app, but ForUI-owned widgets read `FAccessibility`, which ignores `MediaQuery` overrides in tests.

## ForUI research ledger, set G2: inputs and selection (lib/shared/widgets/)

Package: forui 0.27.6 (`/root/.pub-cache/hosted/pub.dev/forui-0.27.6/lib/`). Source cites below are
`forui-0.27.6/lib/src/<path>:<line>`; `material_ui-1.4.0` is the Material layer under `FTextField`.
Catalog: `docs/forui-migration/FORUI_API_CATALOG.md`. No repository file was edited.

### Test run (this set)

`MEMOX_TEST_BUNDLES=0 bash .claude/skills/flutter-workflow/scripts/run_tests.sh <16 files>` from the repo root:
**173 tests, 16 suites, all passed** (38.8 s). Files: `test/shared/widgets/mx_{badge,chip_row,chip_trigger,
choice_tile,code_field,field_message,filter_chip,option_row,search_field,segmented_tray,selection_checkbox,
status_badge,tag_chip,text_field_decorator_states,text_field_states,text_field}_test.dart`. No goldens were run.

### Probes (all under `scratchpad/ledger_probe/test/`, none in the repo)

Run with `flutter test <file>` in `scratchpad/ledger_probe` (touch theme `FTheme.neutral.light.touch`, 360 wide,
`dump()` from `common.dart` prints semantics nodes).

| ID | File | What it settled |
|---|---|---|
| P1 | `g2_probe_test.dart` (P1a-g) | `FOtpField` semantics, item geometry, paste, onChange. (The test ends with an upstream-looking `setState during build` from re-pumping a second `FOtpField` in one tree; every P1 line printed before it and no claim relies on that exception.) |
| P2 | `g2_probe_test.dart` (P2a-e) | `FSelectGroup` radio, `FItem` as option row, `FSelectTileGroup` radio: semantics flags and heights |
| P3 | `g2_probe_test.dart` (P3a-d) | `FTabs` used bar-only: semantics, heights, controller-length assertion |
| P4 | `g2_probe_test.dart` (P4a-e) | `FTextField` label Row semantics, `counterBuilder` position, `defaultErrorBuilder`, `onChange` firing |
| P5 | `g2_probe_test.dart` (P5) | `FBadge.raw` vs `FBadge(child:)`: same 101.5 x 22 |
| P6 | `g2_probe2_test.dart` | `FItem` restyled as option row: min-height constraint is not honoured (assertion), corner tap missed |
| P7 | `g2_probe3_test.dart` | `FTappable.static` as choice tile: semantics, Tab+Enter, `sortKey` |
| P8 | `g2_probe4_test.dart` | native `FLabel` semantics vs MxTextField's name-on-input shim |
| P9 | `g2_probe5_test.dart` | `FTextField` lg is 48; `FButton` lg is 52 with default padding |
| P10 | `g2_probe6_test.dart` | a wrapping hint keeps a filled box open: 188 vs 44 |
| P11 | `g2_probe7_test.dart` | `FOtpField` items do not shrink in a narrow column |
| P12 | `g2_probe8_test.dart` | `FButton` lg + `FButtonStyleDelta` as a search trigger: 48 tall, tap, button semantics |

### Answers to the six questions

**(a) Can `FOtpField` carry the sign-in code contract? No (BLOCKED by API limits; MxCodeField stays).**
- Controller: `FOtpFieldControl.managed(controller:)` takes only `FOtpController` (`widgets/otp_field/otp_field_control.dart:37`;
  class at :83); `MxTextField` and its one caller hold a plain `TextEditingController` (`code_form_widget.dart:44`, `_code.clear()` at :66).
  Closable by changing the API of `MxTextField` and its caller; not by itself a blocker.
- Digit count: no `length` parameter; slots = count of `FOtpItem` in `children` (`otp_field_control.dart:61, 100-102`); the controller
  truncates to that count (:162). Meets "six" by default. Neutral.
- Keyboard: default `keyboardType = .text` (`otp_field.dart:214`); `.number` must be passed. `autofillHints` defaults to `[oneTimeCode]`
  and the formatter to `digitsOnly` (`otp_field.dart:63`). Meets the contract by configuration.
- Semantics value: **fails.** PROBE P1a: `label="Code\n1\n2\n3" value="￼￼￼￼￼￼"` (U+FFFC x 6, no digits in the value).
  The contract (`mx_code_field_test.dart:277`) reads the field once by its label and never a digit
  (`find.bySemanticsLabel('Code, 6 digits')` one match, `find.bySemanticsLabel('4')` none). With `FOtpField` the label becomes
  "Code, 6 digits\n4" (digits merged into the label) and the value is six object-replacement characters. ForUI's own otp tests do not
  exercise semantics (`rg -i semantics forui/test/src/widgets/otp_field/` is empty). The `builder:` hook wraps only the text field, so a
  `Semantics(excludeSemantics: true)` there would also drop `isTextField`, `focus` and the text actions.
- Geometry: **fails.** Items are `SizedBox.fromSize(itemSize)` (`otp_item.dart:108-109`), default 44x44 (`otp_field_style.dart:75`), joined into
  one box by start/end variants (`otp_field_style.dart:99-145`), no gap. `FOtpFieldStyleDelta.delta(itemSize: Size(48, 48))` compiles and
  gives 48, but PROBE P11: at widths 240 and 200 the items stay 48 wide (last item ends at 288) and nothing shrinks, against the contract
  "a slot is 48 wide at most and shrinks in a narrow column" (`mx_code_field_test.dart:261-276`). Separate rounded slots with an 8 gap would
  need `FOtpDivider` abused as a spacer.
- Caret/edit rule: `FOtpController.value` (`otp_field_control.dart:157-228`) selects the item at the caret so typing replaces a middle digit;
  the contract pins the caret after the last digit and Backspace removing the last one (`mx_code_field_test.dart:296-326`).
- Paste: PROBE P1f: "123" typed then a 9-digit insert gives `123987` (ForUI keeps the typed digits, cuts the paste); the contract wants the
  pasted code to win (`mx_code_field_test.dart:345`). A custom `inputFormatters` entry (`_PasteReplacesFormatter`) would be needed either way.
- Completion: `FOtpField` has no "all slots filled" callback (only `onSubmit` / `onEditingComplete`, `otp_field.dart:130`); the caller derives
  completion from the length (`code_form_widget.dart:61`). Neutral.
- Error cue: `FOtpFieldItemStyles` has `.error` variants (`otp_field_style.dart:239-322`) but the focus cue is a 1 px `foreground` border
  (:147-191), not the owner-ruled 2 dp `primary` next-slot edge that stays in error (screen 31 detail file, "Batch A").

**(b) `MxOptionRow` / `MxChoiceTile` vs `FSelectTileGroup`, `FSelectGroup`, `FRadio`.**
- `FRadio` is used (painted only). `FSelectGroup` radio rows: checked + exclusive semantics are right (PROBE P2a) but each row is 24 dp
  tall (`select_group.dart:231`, `itemPadding` vertical 4 at :267), laid out in a `Column` (:227): below the 48 dp target.
- `FSelectTile`: passes `selected` and `semanticsLabel` to `FTile` only (`select_tile_group/select_tile.dart:171-188`); PROBE P2e:
  `hasSelectedState,isSelected,isButton` and no `isChecked` / `isInMutuallyExclusiveGroup`, 47 dp card look. Fails
  `mx_option_row_test.dart:156` ("announced as a checked exclusive option").
- `FItem` is the only ForUI row that exposes `semanticsChecked` + `semanticsInMutuallyExclusiveGroup` (`item/item.dart:369-371`; P2b: exactly
  the flags the contract wants). It cannot hold the 56 / 72 floor: P6e (`FItem` inside `ConstrainedBox(minHeight: 56)`) asserts
  "_RenderLayout does not meet its constraints ... Size(360.0, 44.0)" because `item_content_layout.dart:154` sets
  `size = Size(constraints.maxWidth, height + top + bottom)` without honouring a minimum; P6b: a tap on the bottom corner of the 56 box missed.
  Natural height is 45 / 59 (P2d). Disabled dims title, subtitle, details and prefix together (`item_content.dart:242-263`), while the row keeps
  the description at full strength and lets `isDimmed: false` keep a blocked row readable. Selected paints `secondary` (`item.dart:580`).
  Verdict: rejected; MxOptionRow stays on `MxRowInk` (FTappable.static) + painted `FRadio`.
- `MxChoiceTile` has no ForUI selection counterpart (right / wrong tones, fade, tint). Its press/focus handling is the correction in its record.

**(c) `MxSegmentedTray` vs `FTabs` / `FSelectGroup`. FTabs does require a content child; and four more gaps. BLOCKED.**
- `FTabEntry.child` is required (`widgets/tabs/tabs.dart:27, 30`); the active child is built under the bar after `SizedBox(height: style.spacing)`
  (:215-226). A bar-only use works with `child: SizedBox.shrink()` and `spacing: 0` (P3a/P3c) but is a workaround, not an API.
- Null selection (BR-SRS-001: "no default", used at `create_root_deck_dialog_widget.dart:124-136`): `FTabControl.lifted` needs `required int index`
  (`tabs/tab_controller.dart:166`).
- Disabled tray: `tabs.dart` has no `enabled` (`rg enabled tabs.dart` is empty) and no disabled variant (`FTab` has only `selected`).
- Stacking when labels do not fit (FE-A3 ruling): `TabBar` is one row (`tabs.dart:197-213`); P3d shows no stacking.
- Semantics: P3a: `role=tabBar` / `role=tab`, label "Opt 0\nTab 1 of 3" (Material's `tabLabel`), `hasSelectedState`, no
  `isInMutuallyExclusiveGroup`; the contract pins "selected exclusive option" (`mx_segmented_tray_test.dart:182`). Also bar is 38 tall (36 min + 2)
  vs 48 per option, the tab list fills the width (`tabAlignment: .fill`, :198) while the tray is its natural width, and the controller length is fixed at
  creation (PROBE P3b-d: "Controller's length property (3) does not match the number of tabs (2)").
- `FSelectGroup` has only checkbox / radio items (`select_group_item.dart`), a `Column`; not a segmented layout.

**(d) Label / description / error vs `FTextField`'s slots.** `MxTextField` already uses the native slots: `label:`, `description:`, `error:`
(`text_field.dart:909-912`, rendered by `FLabel`, `input/input.dart:322-331`). The custom parts sit inside those slots and each has a verified gap:
- The label Row (leading glyph, trailing "Required" / "· optional"): `label` is a bare `Widget` (`text_field.dart:909`), `FLabel` has no leading /
  trailing parameters (`widgets/label/label.dart:112-122`). Needed by the card editor ruling DEV-372 (08-card-create.md: glyph before, "Required" or
  "· optional" after). Required.
- The supporting row (message or support text with the counter at its trailing end): the Material counter (`counterBuilder`,
  `input.dart:300-305`) lands on its own line above the description (P4b: counter y=70, description y=100), not at the end of the supporting row
  (ruling DEV-372). Required.
- The error line: `FFormFieldProperties.defaultErrorBuilder` (`foundation/form_field_properties.dart:11-28`) renders the same glyph
  (`FIcons.error` = `FLucideIcons.circleAlert`, `theme/icons.dart:169`; `AppIcons.alert` is the same icon) and the theme's error text style
  (`theme/form_field_style.dart:58-62`, `body.xs`), while `MxFieldMessage` uses the `caption` role (`body.xs2`) and the warning tone for non-field use.
- Name on the input node: native `LabelSemantics` already merges the label text into the field node (`label/semantics.dart:21-42`; P8a/P8c:
  `label="Front\nRequired"`). The shim (`Semantics(label)` on the input, `ExcludeSemantics` on the label text, marker in its own node) yields
  `label="Front"` + a separate node `"Required"` (P8b/P8d). That is a contract choice recorded in commit b44a570e, not an owner ruling.

**(e) Chips and tags.** `MxFilterChip` / `MxChipTrigger` are `FButton` (xs, outline / ghost, `selected:`) already: native. `FButton` xs is 32 dp
(`button.dart:20`); the 48 dp target is `mxTargetStyle` (DESIGN.md:252; ForUI has no hit-slop: the only hit-region parameter in `lib/src` is
`FSlider.trackHitRegionCrossExtent`). `FBadge` (non-interactive) is `MxTagChip` / `MxBadge` already. `FSelectGroup` has no chip item.
`FMultiSelectTag` (`select/multi/tag.dart:22-140`) is a removable, interactive tag, i.e. the card editor's `CardRemovableTagChipWidget`, not
`MxTagChip` (read-only metadata); it works outside a `FMultiSelect` (`tag.dart:103-105` falls back to the theme's tag style) but is outside this set.

**(f) `MxUserEdits`: does `FTextField` expose a user-edit-only callback? No.** `FTextField` has no `onChanged` (`rg onChange text_field.dart
input/input.dart` finds only doc comments, :648, :685). `FTextFieldControl.managed(onChange:)` is attached as a plain controller listener
(`text_field/text_field_control.dart:35, 50-54`). PROBE P4d/P4e: it fires once for a selection move and twice for a programmatic `controller.text =`;
P1g: same for `FOtpField`. `FTextFieldControl.lifted` runs `onChange` from the proxy controller's setter (:60-83) and would need the caller's
text to move into widget state, while the 13 `MxTextField` callers own a `TextEditingController`. Formatters run only for the person's edits
(`text_field.dart:685` doc), which is the hook `MxUserEdits` uses. Kept.

---

### Records

#### MxTextField — `lib/shared/widgets/mx_text_field.dart`
| Field | Record |
|---|---|
| Existing contract | One `FTextField`, lg (48 floor): `mx_text_field_test.dart` "single line is the large ForUI field tall", "detail starts at the form field's height and grows", "term: wraps and grows, in the input role", "term: Enter moves on and adds no newline", "study is bare: no edge in any state, centred, one line" (48 floor), "edges: border at rest, the primary focused, the disabled" , "an error colours the edge and pushes a message below", "a message sits below any variant". Name with value for TalkBack: "a filled field keeps its name for TalkBack"; `mx_text_field_states_test.dart` "the field keeps the label as its name for TalkBack, painted once", "the painted label sits above ... in ForUI's label style", "an error turns the painted label to the error colour", "a label can carry a leading glyph and a trailing marker", "supporting text sits under the field in ForUI's description style", "the counter ends the supporting row", "disabled: the ForUI disabled values once", "a field first built disabled takes its autofocus once", "the caret is the primary". "a wrapping hint holds its room only while the box is empty"; `onChanged` only for the person's edits ("typing reports the value"); leading / trailing only on `form` (assert, "only a form field takes leading and trailing slots"); decorator states (M3F-16): an error adds exactly one live-region node. |
| Call sites | 14 production sites in 13 files: `card_tag_dialog_widget.dart:106`, `import_deck_row_widget.dart:77`, `create_root_deck_dialog_widget.dart:114`; the code variant has 1 (`code_form_widget.dart:124`). |
| ForUI candidate APIs | `FTextField` (+ `FTextFieldControl.managed` / `.lifted`, `FTextFieldStyleDelta`, `FTextFieldSizeVariant`, `prefixBuilder`, `suffixBuilder`, `counterBuilder`, `inputFormatters`); `FTextField.multiline`; `FTextFormField`; `FLabel`; `FFormFieldProperties.defaultErrorBuilder`; `FOtpField` (code variant, see MxCodeField). |
| Installed package version | forui 0.27.6 |
| Official documentation | https://forui.dev/docs/widgets/form/text-field , https://forui.dev/docs/widgets/form/text-form-field , https://forui.dev/docs/widgets/form/label , https://forui.dev/docs/widgets/form/otp-field |
| Source evidence | `widgets/text_field/text_field.dart:905-966` (ctor: `control`, `size`, `builder`, `label`, `hint`, `description`, `error`, `inputFormatters`, `counterBuilder`, `prefixBuilder`, `suffixBuilder`); `text_field/text_field_control.dart:28-54` (listener), `:60-83` (lifted proxy), `:91-95` (managed); `text_field/input/input.dart:164-170` (stable error widget), `:300-305` (counter), `:322-331` (FLabel vertical), `:377-415` (decoration, hint); `widgets/label/semantics.dart:21-42`, `label/label.dart:306-311`; `foundation/form_field_properties.dart:11-28`; `theme/form_field_style.dart:58-62`; `text_field/text_field_style.dart:81-85` (lg = 48 floor, touch). `material_ui-1.4.0/lib/src/text_field.dart:1824` (read-only drops the semantic tap). |
| API verification | PROBE P4a-e, P8a-d, P10 (`g2_probe_test.dart`, `g2_probe4_test.dart`, `g2_probe6_test.dart`); tests above, 4 files, all pass (part of 173). |
| Native capability | Box, border, focus ring, error tone, disabled values, lg size, label / description / error placement and error animation (`FLabel`), prefix / suffix, `autofocus`, `readOnly`, `maxLines`, `keyboardType`, `textInputAction`, `onSubmit`, `inputFormatters`. All used natively. |
| Capability gaps | (1) label leading glyph + trailing marker: `label` is a bare `Widget` (`text_field.dart:909`). (2) counter at the trailing end of the supporting row: Material counter is its own line above the description (P4b). (3) hint only while empty: PROBE P10, a wrapping hint keeps a filled multiline box at 188 instead of 44; `hint` is a `String` (`text_field.dart:910`) with no `hintMaxLines`. (4) person-only edits callback: none (P4d/P4e). (5) `FTextFieldStyle.border` is typed `InputBorder` from material_ui (`text_field_style.dart` `border:` variants), so the `material_ui` import for the bare `study` variant is forced. (6) the name-on-input shim differs from native (P8). |
| Current approach | Native `FTextField` / `FTextFieldControl.managed` / `FTextFieldStyleDelta` / `FTextFieldSizeVariant.lg`, label, description and error slots; Composition of the label Row and supporting row inside those slots; shims `MxUserEdits` and `_HintWhileEmpty` (Foundation / Fallback). |
| Selected approach | Same. |
| Why not a higher-level API? | Every piece with a native ForUI parameter already uses it. Each remaining custom piece maps to a gap line above ((1) FLabel / DEV-372, (2) P4b, (3) P10, (4) P4d-e, (5) forced type). The one shim that ForUI covers differently is (6): native `FLabel` would read "Front, Required" as one name; replacing it changes TalkBack output and needs an owner decision (not a correction by itself). |
| Contract tests | `mx_text_field_test.dart`, `mx_text_field_states_test.dart`, `mx_text_field_decorator_states_test.dart` (+ `mx_code_field_test.dart` for the code variant). Cover geometry, states, label, counter, hint room, autofocus. Missing: the marker as its own TalkBack node (only positions are pinned); `onChanged` not firing for programmatic / selection changes (see MxUserEdits); `leading` / `trailing` paddings. |
| Migration status | **MIGRATED** |
| Correction (if any) | None required. Owner decision (not scheduled): drop the three semantics shims (`builder: Semantics(label)`, `ExcludeSemantics(Text(name))`, `Semantics(container: true, child: marker)`, about 12 lines) so `LabelSemantics` announces the name with its marker; the pinned tests (`contains('Deck name')`, `bySemanticsLabel('Deck name')` without a hint) would still pass, TalkBack reading changes. |

#### MxCodeField — `lib/shared/widgets/mx_code_field.dart`
| Field | Record |
|---|---|
| Existing contract | `mx_code_field_test.dart`: "the code variant asks for digits and offers the one-time code" (number keyboard, `oneTimeCode`, one line, no cursor), "paints six slots, one digit in each" (48 wide, 48+ tall), "a pasted \"123 456\" fills six slots", "the slot that takes the next digit carries the focus edge" (2 dp primary, error keeps it), "a wrong code keeps the next-slot cue", "a read-only code keeps its digits at full strength", "a disabled code takes the ForUI disabled values once", "a slot has no fill", "a tap on a slot focuses the code", "six slots fit a 288 wide column" and shrink below 48 in a narrower one, "TalkBack reads the code field once, by its label, and not each painted digit", "a tap on the first slot keeps the caret after the last digit", "Backspace after a tap on the first slot deletes the last digit", "keeps six digits and nothing else", "pasting a code after typed digits replaces them", "typing digits one at a time still stops at six", "draws the code variant only". Screen 31: autofocus, six digits check at once, a wrong code clears the field, read-only (not disabled) while checking. |
| Call sites | 1 production (`code_form_widget.dart:124`, through `MxTextField(variant: code)`), 1 gallery. |
| ForUI candidate APIs | `FOtpField`, `FOtpFieldControl.managed`, `FOtpController`, `FOtpItem`, `FOtpDivider`, `FOtpFieldStyleDelta(itemSize)`, `FOtpFieldItemStyles`; current: `FTextField` (hidden). |
| Installed package version | forui 0.27.6 |
| Official documentation | https://forui.dev/docs/widgets/form/otp-field |
| Source evidence | `otp_field/otp_field_control.dart:37` (controller is `FOtpController?`), `:61, :100-102` (slots = items), `:157-228` (value setter: truncate :162, selects the item at the caret), `:83` (`FOtpController extends TextEditingController`); `otp_field/otp_field.dart:63` (digitsOnly default), `:214` (`keyboardType = .text`), `:250`; `otp_field/otp_item.dart:84-98, 108-109` (variants, fixed `itemSize` box); `otp_field/otp_field_style.dart:31, 75, 99-191` (joined 44 items, 1 px foreground focus), `:239-322` (error variants). |
| API verification | PROBE P1a-g (`g2_probe_test.dart`) and P11 (`g2_probe7_test.dart`); existing tests pass (173 total). |
| Native capability | `FOtpField` meets: six slots, digits-only default, one-time autofill hint, `autofocus`, `readOnly`, `enabled`, `onSubmit`, an error variant on items, label / description / error via `FLabel`, and with `keyboardType: .number` the numeric keyboard. |
| Capability gaps | Semantics: `label="Code\n1\n2\n3" value="￼￼￼￼￼￼"` (P1a), digits in the label, FFFC in the value; contract wants label read once and no digit nodes. Geometry: items fixed-size `SizedBox.fromSize` (`otp_item.dart:108-109`), joined, no 8 gap, no shrink (P11: 48 wide at 200 and 240). Controller type `FOtpController` (`otp_field_control.dart:37`) vs plain `TextEditingController` of the caller. Caret rule: the controller selects the item at the caret (`otp_field_control.dart:157-228`) vs "caret after the last digit". Paste: P1f keeps the typed digits and cuts the paste. Focus cue: 1 px `foreground` (`otp_field_style.dart:147-191`) vs 2 dp `primary` (screen 31 Batch A ruling). |
| Current approach | Composition: one hidden `FTextField` (`FTextFieldControl.managed`, `digitsOnly`, `_PasteReplacesFormatter`, `LengthLimitingTextInputFormatter`, `showCursor: false`, `autofillHints`) under six painted slots (Flutter `DecoratedBox`), `ExcludeSemantics` on the slots and a `Semantics(label)` on the hidden field; Foundation: `_keepCaretAtEnd` controller listener; `MxUserEdits`; `MxFieldMessage`. |
| Selected approach | Same (Composition on a hidden `FTextField`). Optional later: resolve idle / disabled / error slot edges from `FTheme.of(context).otpFieldStyle.itemStyles` (the `[.start.and(.end)]`, `.disabled`, `.error` entries) instead of recomputing from `colors.border` / `colors.disable(...)`; the 2 dp primary next-slot cue has no ForUI equivalent and stays. |
| Why not a higher-level API? | `FOtpField` fails the semantics, narrow-column and caret-rule contracts above with the cited lines and probes; the semantics gap cannot be patched through the `builder:` hook without losing the text-field node (`otp_field.dart:473`). |
| Contract tests | `mx_code_field_test.dart`: covers every row above (digits, slots, paste, edge, error, read-only, disabled, 288 / narrow, TalkBack once, caret, Backspace, six-digit cap). Missing: a wrong-code clear from the caller (`code_screen_test.dart` covers it at screen level); `autofocus` / `isAutofocused` is untested at this level. |
| Migration status | **BLOCKED** (API limit: `FOtpField` semantics value, fixed non-shrinking items, controller type; the owner-ruled slot cue). |
| Correction (if any) | None. Re-evaluate `FOtpField` if a later forui fixes the node value / label and lets items flex. |

#### MxSearchField — `lib/shared/widgets/mx_search_field.dart`
| Field | Record |
|---|---|
| Existing contract | `mx_search_field_test.dart`: "a large ForUI field tall, the value in the content style, the muted surface and a muted glyph", "the surface has no edge, at rest or focused", "the hint names the field, empty or holding a query, once", "no clear button until there is a query", "the clear button is a 48 target at the end of the field", "clear empties the query and reports it", "clear keeps the field focused", "focus keeps the search surface and tints the glyph", "a long query stays on one line". Trigger group: "looks like the resting field: as tall, muted surface, hint", "a tap calls onTap once and takes no focus", "hovering leaves the search surface as it is", "the keyboard reaches it at one tab stop, with the outline round the pill", "reads as a button named by the hint, with no clear button". `isRouteName` (DEV-393). |
| Call sites | 6 default sites in 6 files (`tags_screen.dart:146`, `monitoring_server_tab_widget.dart:62`, `card_list_section_widget.dart:411`) + 1 `.trigger` (`deck_library_root_widget.dart:115`). |
| ForUI candidate APIs | `FTextField` (`clearable`, `clearIconBuilder`, `prefixBuilder`, `readOnly`, `canRequestFocus`, `onTap`), `FTextField.prefixIconBuilder`, `FTextField.defaultClearIconBuilder`, `FTappable.static`, `FButton` (lg, `FButtonStyleDelta`), `FFocusedOutlineStyleDelta`. |
| Installed package version | forui 0.27.6 |
| Official documentation | https://forui.dev/docs/widgets/form/text-field , https://forui.dev/docs/widgets/form/button , https://forui.dev/docs/widgets/foundation/tappable |
| Source evidence | `text_field.dart:98-112` (`defaultClearable`, `defaultClearIconBuilder` = `FButton.icon` with `clearButtonStyle`), `:965-966`; `text_field_style.dart:61-63` (clear button = ghost sm = 40 dp), `:81-85` (lg floor 48); `input.dart:372-389` (clear shown only when enabled); `material_ui-1.4.0/lib/src/text_field.dart:1824` (read-only has no semantic tap); `foundation/tappable/tappable.dart:707-725`; `widgets/button/button.dart:20, 295-310`. |
| API verification | PROBE P9 (`FTextField` lg 48 / `FButton` lg 52) and P12 (`FButton` lg + `FButtonStyleDelta.delta(decoration, contentStyle(padding, constraints minHeight 48, spacing), tappableStyle(motion noBounce), focusedOutlineStyle)` compiles: 48 tall, tap fires, node `isButton,isEnabled,isFocusable actions=tap,focus label="Search decks"`). The file's tests pass (16). |
| Native capability | Default form is native: lg field, `clearable` predicate, `clearIconBuilder`, `prefixBuilder`, `inputFormatters`, `textInputAction.search`, style delta for muted ground (`color`) and the borderless pill (`border`). |
| Capability gaps | Native clear button is 40 dp with ForUI's localized label (`text_field_style.dart:61-63`; `text_field.dart:102-111`); the contract is 48 dp with the caller's `clearLabel`, so `clearIconBuilder` stays (it uses `MxIconButton`, another set). Native `prefixIconBuilder` pads 12 / 4 and keeps the muted colour (`text_field.dart:115-122`); the contract is 16 / 8 and a primary glyph when focused. `border` is a material_ui `InputBorder` (forced import). Trigger: a read-only `FTextField` has no semantic tap (material_ui `text_field.dart:1824`), so today it is painted-only + wrapped. |
| Current approach | Default: Native `FTextField` with deltas. Trigger: Composition + Foundation: an inert `FTextField` under `mxPaintedOnly`, `FTappable.static` (focus outline), and a hand-made `Semantics(button, label, onTap, excludeSemantics)` . |
| Selected approach | Default: unchanged. Trigger: native `FButton` (size lg) with a style delta that paints the muted pill. |
| Why not a higher-level API? | Default form: native already. Trigger: a read-only `FTextField` carries no tap semantic (material_ui `text_field.dart:1824`), which is why the current code re-adds the whole button behaviour (painted-only wrapper + `FTappable` + `Semantics`); `FButton` provides button semantics, focus, keyboard, outline natively (P12). |
| Contract tests | `mx_search_field_test.dart` (default form well covered; trigger 5 tests). Missing: trigger `isRouteName` is not offered for trigger (n/a); no test of `onChanged` on typing vs clear ordering beyond "clear ... reports it". |
| Migration status | **CORRECTION NEEDED** (trigger form only; default form is MIGRATED) |
| Correction (if any) | In `MxSearchField.trigger`, replace `Semantics(button ...)` + `FTappable.static` + `mxPaintedOnly(field)` + `canRequestFocus` / `readOnly` flags by `FButton(size: FButtonSizeVariant.lg, mainAxisAlignment: MainAxisAlignment.start, onPress: onTap, prefix: Icon(AppIcons.search...), child: Text(hintText), style: FButtonStyleDelta.delta(decoration: FVariants<FTappableVariantConstraint, FTappableVariant, Decoration, DecorationDelta>.all(ShapeDecoration(color: colors.muted, shape: StadiumBorder())), contentStyle: FButtonContentStyleDelta.delta(padding: EdgeInsetsGeometryDelta.value(EdgeInsetsDirectional.only(start: 16, end: 16)), constraints: BoxConstraints(minHeight: dimens.sizeControl), spacing: 8, textStyle/iconStyle: the hint style and mutedForeground, all variants), tappableStyle: FTappableStyleDelta.delta(motion: .delta(bounceTween: FTappableMotion.noBounceTween)), focusedOutlineStyle: FFocusedOutlineStyleDelta.delta(borderRadius: pill)))` (signatures compile in P12; text / icon style fields per `button_content.dart`). Removes about 20 lines and the painted-only hack on the trigger. Risks: pixel parity with the field's hint typography (screen 01 golden `deck_library_root`: run `golden-compare` before merge); the 5 trigger tests assert `InputDecoration` fill and edge, so they are rewritten to assert the `FButton` decoration; keep "hover leaves the surface as is" by using `.all(...)` for every variant. |

#### MxFieldMessage — `lib/shared/widgets/mx_field_message.dart`
| Field | Record |
|---|---|
| Existing contract | `mx_field_message_test.dart`: "error: glyph and text in the error colour", "warning in dark: the glyph and the text take the warning text colour", "warning: the glyph in warning text on the light page", "a long message wraps instead of truncating", "starts on the field edge with the glyph, as ForUI field messages do" (caption role), "announced as a live region". Also pinned through MxTextField: one added live-region node (decorator test). |
| Call sites | 4 standalone sites (`create_root_deck_dialog_widget.dart:139`, `study_options_form_widget.dart:172`, `settings_session_section_widget.dart:60`, `card_tag_editor_widget.dart:195`, warning tone) + 2 inside `MxTextField` and `MxCodeField`. |
| ForUI candidate APIs | `FFormFieldProperties.defaultErrorBuilder`, `FLabel(error:)`, `FAlert`, `FIcons.error`. |
| Installed package version | forui 0.27.6 |
| Official documentation | https://forui.dev/docs/widgets/form/label (error slot); https://forui.dev/docs/widgets/feedback/alert |
| Source evidence | `foundation/form_field_properties.dart:11-28` (icon + `Flexible(Text)`, icon from `context.theme.icons.error`), `theme/icons.dart:169` (`FLucideIcons.circleAlert`), `widgets/label/label.dart:306-311` (error node `validationResult: invalid`, live region when the platform cannot announce), `label/semantics.dart:21-42`. Catalog D lists `FAlert` as a bordered callout (not an inline line). |
| API verification | PROBE P4c (default error builder renders at x=18, 126 wide). Tests pass. |
| Native capability | In a field: `FTextField(error:)` + `defaultErrorBuilder` gives the glyph, the colour (`errorTextStyle`) and the live announcement. |
| Capability gaps | The `caption` role (`body.xs2`, weight 400) vs ForUI's `errorTextStyle` (`body.xs` on touch); no warning tone; outside a field no ForUI inline message exists (`FLabel` needs a child; `FAlert` is a boxed callout). |
| Current approach | Fallback: Flutter `Row` + `Icon` + `Text` + `Semantics(liveRegion)`. |
| Selected approach | Same for the 4 standalone sites; inside `MxTextField` it could use `defaultErrorBuilder` only together with a theme `formFieldStyle.errorTextStyle` set to the caption role (not done in `lib/core/theme`; `rg formFieldStyle lib/core/theme` is empty). |
| Why not a higher-level API? | No ForUI inline-message widget exists for non-field use; for in-field use the swap would move the message from the `caption` role to `body.xs` unless the theme slot is set, i.e. a look change (goldens) for removing one use of a 56-line file. |
| Contract tests | `mx_field_message_test.dart` (6 tests, covers colours, wrap, live region). Missing: nothing material. |
| Migration status | **MIGRATED** |
| Correction (if any) | None. |

#### MxUserEdits — `lib/shared/widgets/mx_user_edits.dart`
| Field | Record |
|---|---|
| Existing contract | `onChanged` once per edit the person types, pastes or deletes; never for a selection move or text the code sets on the controller. Pinned only indirectly: `mx_text_field_test.dart` "typing reports the value", `mx_search_field_test.dart` "clear empties the query and reports it" (the caller reports explicitly), `code_screen_test.dart` (a wrong code clears via `_code.clear()` without a second `verify`). |
| Call sites | 3 internal users (`mx_text_field.dart`, `mx_search_field.dart`, `mx_code_field.dart`); 0 direct production users. |
| ForUI candidate APIs | `FTextFieldControl.managed(onChange:)`, `FTextFieldControl.lifted`, `FTextFormField(onSaved)`, `inputFormatters`. |
| Installed package version | forui 0.27.6 |
| Official documentation | https://forui.dev/docs/widgets/form/text-field , https://forui.dev/docs/concepts/controls |
| Source evidence | `text_field/text_field_control.dart:35, 50-54` (managed `onChange` = controller listener), `:60-83` (lifted proxy), `text_field.dart:685` (formatters do not run for programmatic changes), `:648` (`onSubmit` doc); no `onChanged` parameter in `FTextField` / `FTextFormField` (`rg onChanged`). |
| API verification | PROBE P4d (selection move fires `onChange` once) and P4e (programmatic `controller.text =` fires it). |
| Native capability | none for "user edits only". |
| Capability gaps | no callback separates the person's edits from selection moves and programmatic sets; `lifted` is not a fit for 13 controller-owning callers. |
| Current approach | Foundation shim on two public ForUI hooks (`inputFormatters` last in the list marks the person's text; `control.onChange` forwards the matching change). |
| Selected approach | Same. |
| Why not a higher-level API? | No native callback exists (P4d / P4e); `MxUserEdits` uses only public ForUI parameters. |
| Contract tests | Indirect only. Missing: a unit test of the mechanism: (1) type / paste / delete report once, (2) `controller.text = 'x'`, `controller.selection = ...` and `controller.clear()` report nothing, (3) a formatter that rewrites the text reports the rewritten text once. |
| Migration status | **MIGRATED** (test gap listed) |
| Correction (if any) | Add `test/shared/widgets/mx_user_edits_test.dart` with the three cases above (no production change). |

#### MxSelectionCheckbox — `lib/shared/widgets/mx_selection_checkbox.dart`
| Field | Record |
|---|---|
| Existing contract | `mx_selection_checkbox_test.dart`: "unchecked: the style size, the card ground, a muted edge", "checked: the primary fill, the primary-foreground check, no edge", "dark checked", "it is painted only: out of the semantics tree and out of reach of a pointer", "it takes no focus of its own: the row is the one tab stop". Ruling I6: the caller's row is the tap target and carries the checked semantics. |
| Call sites | 2 (`mx_selectable_card_row.dart:66`, `card_tag_filter_sheet_widget.dart:193`). |
| ForUI candidate APIs | `FCheckbox`, `FSelectGroup` checkbox items, `FSelectTileGroup`. |
| Installed package version | forui 0.27.6 |
| Official documentation | https://forui.dev/docs/widgets/form/checkbox , https://forui.dev/docs/widgets/form/select-group |
| Source evidence | `widgets/checkbox.dart:107, 118` (`onPress: enabled ? () => onChange?.call(!value) : null`: `onChange` is optional and does not gate the enabled look); catalog `FCheckbox` (box 20 dp, no min target); `select_group.dart:227-231` (24 dp rows). |
| API verification | none needed (source lines); tests pass. |
| Native capability | The box, check glyph, selected fill, motion and `FAccessibility` handling are `FCheckbox`'s. |
| Capability gaps | `FCheckbox` is a 20 dp row-with-label control; the card row is the target, hence painted-only. |
| Current approach | Native `FCheckbox` inside `mxPaintedOnly` (ExcludeSemantics / ExcludeFocus / IgnorePointer). |
| Selected approach | Same. |
| Why not a higher-level API? | n/a (native). `FSelectGroup` / tiles would add a label row and make the checkbox the target. |
| Contract tests | `mx_selection_checkbox_test.dart` (5 tests). Covers the contract. |
| Migration status | **MIGRATED** |
| Correction (if any) | Optional 1-line cleanup: the no-op `onChange: (_) {}` is not needed (`checkbox.dart:118` handles a null callback); same in `MxOptionRow._Radio` (`radio.dart:121`). |

#### MxOptionRow — `lib/shared/widgets/mx_option_row.dart`
| Field | Record |
|---|---|
| Existing contract | `mx_option_row_test.dart`: "unselected: the ring in the muted foreground, no indicator", "selected: ... indicator, in the primary colour", "dark", "56 tall, 72 with a description; a long one grows the row", "a tap selects; announced as a checked exclusive option", "the row is a 48 target", "disabled at the theme disabled opacity", "a row not selectable yet can keep full contrast: isDimmed false", "a selected row that cannot change is not dimmed", "a dimmed row keeps its description at full strength", "a row that cannot be picked is a disabled radio to TalkBack", "M3F-17: a row that cannot be picked blocks its trailing control", "M3F-05: a focused row draws the primary focus outline (light, dark)", "a row that cannot be picked takes no focus", "the whole row is one tab stop". |
| Call sites | 22 sites in 17 files (`starter_algorithm_sheet_widget.dart:136`, `card_export_sheet_widget.dart:233`, `import_option_sheet_widget.dart:51`). |
| ForUI candidate APIs | `FRadio`, `FSelectGroup` + `FSelectGroupItemMixin.radio` + `FMultiValueControl.managedRadio`, `FSelectTileGroup` / `FSelectTile`, `FItem` (`semanticsChecked`, `semanticsInMutuallyExclusiveGroup`), `FTile`, `FTappable.static`. |
| Installed package version | forui 0.27.6 |
| Official documentation | https://forui.dev/docs/widgets/form/radio , https://forui.dev/docs/widgets/form/select-group , https://forui.dev/docs/widgets/tile/select-tile-group , https://forui.dev/docs/widgets/data/item , https://forui.dev/docs/widgets/foundation/tappable |
| Source evidence | `radio.dart:119-121` (checked + exclusive semantics, `onChange(!value)`), `select_group/select_group.dart:227-231, :267`, `select_tile_group/select_tile.dart:171-188`, `foundation/notifiers.dart:98-101` (radio notifier), `item/item.dart:363-379, :548-551, :580`, `item/item_content.dart:242-263`, `item/item_content_layout.dart:154`, `foundation/tappable/tappable.dart:707-725`. |
| API verification | PROBE P2a-e (`g2_probe_test.dart`), P6 (`g2_probe2_test.dart`: min-height assertion, corner tap missed). |
| Native capability | `FRadio` painted; press / hover layer, focus outline and semantics through `FTappable` (in `MxRowInk`). |
| Capability gaps | `FSelectGroup` radio: 24 dp rows (P2a), column of labels. `FSelectTile`: no checked / exclusive semantics (P2e). `FItem`: right semantics (P2b) but cannot take a minimum height (P6, `item_content_layout.dart:154`), natural 45 / 59 vs 56 / 72 (P2d), dims all text on disabled so the description-readable and `isDimmed: false` rules need per-instance style deltas, selected paints `secondary`, 4 dp non-tappable margin. |
| Current approach | Composition / Foundation: `MxRowInk` (`FTappable.static` + `FFocusedOutlineStyleDelta`, shared with MxListRow, MxSettingsRow) + painted `FRadio` + Flutter `Row` / `Column`, `MergeSemantics(Semantics(checked, inMutuallyExclusiveGroup, enabled))`. |
| Selected approach | Same. |
| Why not a higher-level API? | `FItem` is the only candidate with the right semantics and fails the 56 / 72 floor (`item_content_layout.dart:154`, P6e assertion) and the dimming rules; `FSelectGroup` fails 48 dp; `FSelectTile` fails semantics. Press / focus are not reimplemented here: they are `MxRowInk`'s `FTappable.static` (that wrapper belongs to the row-family set). |
| Contract tests | `mx_option_row_test.dart` (16 tests above). Missing: the trailing slot inside a blocked row is covered (M3F-17); nothing material. |
| Migration status | **MIGRATED** |
| Correction (if any) | None (optional: drop the no-op `onChange: (_) {}` on `FRadio`). Cross-reference: whoever audits `MxRowInk` should re-run this `FItem` comparison for the row family, since `FItem` has the same min-height limitation for all rows. |

#### MxChoiceTile — `lib/shared/widgets/mx_choice_tile.dart`
| Field | Record |
|---|---|
| Existing contract | `mx_choice_tile_test.dart`: "one node: its label, a button, selected, and its tap", "without a tap it is inert and not a button", "at least a control tall, whatever its content", "selected is the primary fill with the content on primary", "idle is the card ground with the content on the foreground". Unpinned but implemented: right / wrong tones and edges, recessed ground, faded (`opacityMuted`), tone eases in (`Durations.short4`, `Easing.standard`) and is instant under `disableAnimations`, `sortKey` (used by Match). Screen 37: "Keyboard focus ring on the options: none yet" (DEV-391, open). |
| Call sites | 4 (`study_match_widget.dart:250`, `study_guess_widget.dart:212`, `topik_question_pane_widget.dart:54`, `topik_review_question_widget.dart`). |
| ForUI candidate APIs | `FTappable.static`, `FButton`, `FSelectTile`, `FTile`, `FItem`, `FFocusedOutlineStyleDelta`. |
| Installed package version | forui 0.27.6 |
| Official documentation | https://forui.dev/docs/widgets/foundation/tappable , https://forui.dev/docs/widgets/foundation/focused-outline |
| Source evidence | `foundation/tappable/tappable.dart:404-432` (`.static`: `onPress`, `behavior`, `focusedOutlineStyle`), `:707-735` (Semantics, Shortcuts / Actions, Focus), `:861-863` (outline only when a style is given), catalog `FFocusedOutline` (ring painted only when `focusHighlight`). No `sortKey` parameter in `tappable.dart`. |
| API verification | PROBE P7 (`g2_probe3_test.dart`): `FTappable.static(onPress, selected, semanticsLabel, semanticsButton: onTap != null, excludeSemantics: true, focusedOutlineStyle: .delta())` gives `isButton,isSelected,isEnabled actions=tap label="Option 1, X"`; with `onPress: null` a non-button node without tap; Tab then Enter activates it (`taps=1`); an outer `Semantics(sortKey:)` does not reach the node (`sortKey` null, P7d), so the existing outer `Semantics` must stay. |
| Native capability | `FTappable.static` provides hover / pressed / focus tracking, keyboard activation (Enter), the focus ring and the disabled state. |
| Capability gaps | none blocking the correction. The tone animation (decoration / foreground tween, fade) has no ForUI API and stays; `sortKey` stays on the existing `Semantics`. |
| Current approach | Fallback: `GestureDetector(opaque)` + hand-built `Semantics` (container, button, selected, label, sortKey, onTap, excludeSemantics) + `TweenAnimationBuilder` tones. No focus, no keyboard activation, no ring (the open DEV-391 debt). |
| Selected approach | Foundation: keep the `Semantics` wrapper and the tone tweens; replace `GestureDetector` with `FTappable.static`. |
| Why not a higher-level API? | `FSelectTile` / `FTile` / `FItem` bring tile layout, `selected` fill and no `sortKey`; `FButton` brings button layout and bounce. The surface is a toned content slot (right / wrong tints, fade) with caller content, so the foundation primitive is the highest level that fits. |
| Contract tests | `mx_choice_tile_test.dart` (5 tests: semantics, inert, 48 floor, selected, idle). Missing: right / wrong tone fill and edge, recessed ground, faded opacity, reduced-motion (instant), `sortKey` reaching the node, keyboard focus ring and Enter (new after the correction). |
| Migration status | **CORRECTION NEEDED** |
| Correction (if any) | In `build`, wrap the faded surface in `FTappable.static(onPress: onTap, behavior: HitTestBehavior.opaque, focusedOutlineStyle: FFocusedOutlineStyleDelta.delta(borderRadius: context.radii.md), child: AnimatedOpacity(...))` in place of `GestureDetector(onTap, behavior, excludeFromSemantics)`; keep the outer `Semantics(container, button, selected, label, sortKey, onTap, excludeSemantics: true)` unchanged (it hides FTappable's own node, so no duplicate). Gains keyboard focus, Enter activation and the ring (closes DEV-391 and removes the "none yet" note in screens 17, 18, 37). Risks: the ring is painted 3 dp outside the tile (`FFocusedOutline` spacing 3, width 1), so tiles in a scroll view or grid may clip it (see `MxChipRow` for the same issue); an inert tile passes `onPress: null` (P7b: not a button, no tap, not focusable). Tests to add: Tab then Enter calls `onTap`; focus ring paints in light and dark (helper `focusRingRender` / `paintsFocusRing` as in `mx_search_field_test.dart`); inert tile takes no focus; plus the unpinned rows listed above. Golden review needed only if the ring appears in a golden (it does not at rest). |

#### MxSegmentedTray — `lib/shared/widgets/mx_segmented_tray.dart`
| Field | Record |
|---|---|
| Existing contract | `mx_segmented_tray_test.dart`: "the chosen option is raised on the background with a check and the foreground label; the rest are bare, muted (light, dark)", "the tray sits on the muted ground", "a disabled tray dims its labels and fills nothing but the chosen option", "a null selection draws no check: a choice still to make", "a tap reports the option; every option is a 48 target", "tapping the chosen option reports it again", "the options split the tray evenly with a 4 gap", "announced as a selected exclusive option", "two or three options only" (assert), "a null onSelected disables every option: no tap, and it says so", "a long label stacks the options, one per 48 tall line", "isWide widens the option padding to 16", "short labels stay on one line, also with the check", "keyboard focus draws ForUI's focus outline round the focused option". Rulings: BR-SRS-001 (no default), FE-A3 (stack), screen 36 (Overview / History tray). |
| Call sites | 8 sites in 8 files (`import_deck_row_widget.dart:121`, `monitoring_screen.dart:91`, `progress_range_widget.dart:18`). |
| ForUI candidate APIs | `FTabs` + `FTabEntry` + `FTabControl.lifted` + `FTabsStyleDelta`, `FSelectGroup` (radio), `FTappable.static`, `FFocusedOutlineStyleDelta`. |
| Installed package version | forui 0.27.6 |
| Official documentation | https://forui.dev/docs/widgets/navigation/tabs , https://forui.dev/docs/widgets/form/select-group , https://forui.dev/docs/widgets/foundation/tappable |
| Source evidence | `widgets/tabs/tabs.dart:27, 30` (`child` required), `:197-213` (Material `TabBar`, `tabAlignment: fill` at :198, no overlay), `:215-226` (spacing + content pane), `:151-167` (controller created for `children.length`), `tabs_style.dart:40` (minHeight 36); `tabs/tab_controller.dart:166` (`lifted({required int index ...})`); no `enabled` in `tabs.dart`; `foundation/tappable/tappable.dart:707-725` (`semanticsInMutuallyExclusiveGroup`, `selected`). |
| API verification | PROBE P3a (`role=tabBar` / `tab`, `label="Opt 0\nTab 1 of 3"`, no exclusive flag, 38 tall bar), P3b-d (56 total with the 10 spacing; controller-length assertion when the child count changes). The file's tests pass. |
| Native capability | `FTabs` gives the muted tab-list look, a raised selected pill, per-tab focus outline, selection state, arrow / tap switching. |
| Capability gaps | content child required (`tabs.dart:27`); null selection impossible (`tab_controller.dart:166`); no disabled state; no stacking; tab semantics ("Tab 1 of 3", role tab) instead of selected-exclusive option; 36 dp tab height not 48; fills the width instead of its natural width; no check glyph, no shadow; fixed controller length. |
| Current approach | Foundation: `FTappable.static` per option (`selected`, `semanticsInMutuallyExclusiveGroup`, `FFocusedOutlineStyleDelta`), `FTheme.of(context).style.shadow`, Flutter `Row` / `Column` with a `TextPainter` measurement to decide inline vs stacked. |
| Selected approach | Same. Optional: read the look from `FTheme.of(context).tabsStyle` (`decoration`, `indicatorDecoration`, `labelTextStyle` selected variant) instead of `colors.muted` / `colors.background`, only if the theme starts customizing `FTabsStyle`. |
| Why not a higher-level API? | `FTabs` fails five verified contracts: null selection, disabled, stacking, exclusive-option semantics, 48 dp / natural width (lines above). `FSelectGroup` has no segmented layout. Press, focus ring and selected semantics are already ForUI's `FTappable`; the `TextPainter` measure is a layout decision with no ForUI equivalent. |
| Contract tests | `mx_segmented_tray_test.dart` covers look, 48 targets, gap, semantics, disabled, null selection, stacking, wide padding, keyboard outline. Missing: Vietnamese / long-label stacking at the real call site is covered by screen tests only. |
| Migration status | **BLOCKED** (owner rulings BR-SRS-001 and FE-A3, plus the `FTabs` API limits above) |
| Correction (if any) | None. |

#### MxFilterChip — `lib/shared/widgets/mx_filter_chip.dart`
| Field | Record |
|---|---|
| Existing contract | `mx_filter_chip_test.dart`: "unselected: the outline variant, 32 tall inside a 48 target", "selected: ForUI's selected look and a leading check", "the label is inset by the padding, or by padding + glyph + gap", "selecting swaps the glyph for the check", "keyboard focus draws ForUI's focus outline round the chip", "the count keeps the label foreground" (light, dark), "M3F-03: the resting count is 4.5:1", "a tap reports the flipped selection", "selection is announced on the button node", "a 32 chip with a 48 target", "disabled paints the theme disabled colours, dimmed once", "a label wider than its column ends in an ellipsis", "M3F-04: the leading glyph is 3:1". |
| Call sites | 4 sites in 3 files (`topik_answer_filter_chips_widget.dart:39`, `trash_screen.dart:334`, `card_list_toolbar_widget.dart:82`). |
| ForUI candidate APIs | `FButton` (xs, outline, `selected:`), `FSelectGroup`, `FBadge`, `FMultiSelect` / `FMultiSelectTag`, `FTabs(scrollable: true)`. |
| Installed package version | forui 0.27.6 |
| Official documentation | https://forui.dev/docs/widgets/form/button , https://forui.dev/docs/widgets/data/badge , https://forui.dev/docs/widgets/form/select-group |
| Source evidence | `widgets/button/button.dart:20` (xs = 32 touch), `:295-310` (selected -> `FTappable.selected` + semantics), `:443-444` (outline selected decoration), `:304` (`semanticsLabel` removes focus); `foundation/tappable/tappable.dart:707-725`; `select_group/select_group_item.dart` (checkbox / radio items only). |
| API verification | none needed beyond the file's passing tests; P12 shows `FButtonStyleDelta` compiles the same way. |
| Native capability | `FButton` xs outline with `selected`, prefix / suffix, `mainAxisSize.min`, focus outline, disabled colours, selected semantics. All used. |
| Capability gaps | 32 dp is below 48; ForUI has no hit-slop (only `FSlider.trackHitRegionCrossExtent` exists), so `mxTargetStyle` insets the paint (DESIGN.md:252 ruling). |
| Current approach | Native: `FButton` + `mxChipStyle` (a style delta over ForUI's resolved xs outline style). |
| Selected approach | Same. |
| Why not a higher-level API? | n/a (native). The other candidates are non-interactive (`FBadge`), checkbox / radio rows (`FSelectGroup`), a popover select (`FMultiSelect`), or tab semantics (`FTabs`). |
| Contract tests | `mx_filter_chip_test.dart` (above, covers contract incl. contrast). |
| Migration status | **MIGRATED** |
| Correction (if any) | None. |

#### MxChipTrigger — `lib/shared/widgets/mx_chip_trigger.dart`
| Field | Record |
|---|---|
| Existing contract | `mx_chip_trigger_test.dart`: "ghost: no fill, the ghost label colour, a trailing chevron", "chip geometry: the label inset by the style padding, no edge", "opens its menu on tap and meets the 48 target", "a label wider than its column ends in an ellipsis", "semanticLabel is the one node TalkBack reads; the painted label is unchanged", "without semanticLabel the visible label stays the name". Never reads as selected. |
| Call sites | 8 sites in 8 files (`import_mapping_row_widget.dart:78`, `import_source_section_widget.dart:319`, `deck_level_header_widget.dart:33`). |
| ForUI candidate APIs | `FButton` (xs, ghost, `semanticsLabel`, `suffix`), `FPopoverMenu` (the caller's menu). |
| Installed package version | forui 0.27.6 |
| Official documentation | https://forui.dev/docs/widgets/form/button |
| Source evidence | `button.dart:20, :304` (`semanticsLabel` => `excludeSemantics`), `:450-462` (ghost styles incl. selected); catalog `FButton`. |
| API verification | tests pass (6). |
| Native capability | `FButton` xs ghost with `suffix` and `semanticsLabel`. |
| Capability gaps | 32 dp (same as MxFilterChip); `semanticsLabel` drops the `focus` action and `isFocusable` from the node (`button.dart:304`, catalog gap 6), accepted by the existing test "semanticLabel is the one node TalkBack reads". |
| Current approach | Native: `FButton` + `mxChipStyle(isGhost: true)`. |
| Selected approach | Same. |
| Why not a higher-level API? | n/a (native). |
| Contract tests | `mx_chip_trigger_test.dart` (6). |
| Migration status | **MIGRATED** |
| Correction (if any) | None. |

#### MxChipRow — `lib/shared/widgets/mx_chip_row.dart`
| Field | Record |
|---|---|
| Existing contract | `mx_chip_row_test.dart`: "a focused first chip keeps its whole ring", "a focused last chip keeps its whole ring", "the row lays out as a plain scroll row: chips start at its edge", "a chip scrolled past the edge is still cut a ring away". Chips never shrink or wrap; the row scrolls sideways. |
| Call sites | 3 (`trash_screen.dart:331`, `card_list_toolbar_widget.dart:79`, `topik_answer_filter_chips_widget.dart:28`). |
| ForUI candidate APIs | none in the catalog: a scan of every catalog heading (A-D) finds no chip row or horizontal scroller; `FTabs(scrollable: true)` is a tab list with a content pane; `FLineCalendar` is dates only. |
| Installed package version | forui 0.27.6 |
| Official documentation | https://forui.dev/docs/widgets/foundation/focused-outline (ring reach) |
| Source evidence | catalog `FFocusedOutline` (`foundation/focused_outline.dart:74-91`: ring is stroked outside the child, `spacing` 3 + width 1); Flutter `SingleChildScrollView` clips its child at its own bounds. |
| API verification | tests pass (4). |
| Native capability | none (layout abstraction). |
| Capability gaps | no ForUI widget for the job. |
| Current approach | Fallback: `ClipRect(clipper: inflated by 4)` + `SingleChildScrollView(horizontal, clipBehavior: none)` + `Row(spacing)`. |
| Selected approach | Same. |
| Why not a higher-level API? | No ForUI chip row exists; padding the scroll view by 4 would move the chips off the row edge, which the layout test pins. |
| Contract tests | `mx_chip_row_test.dart` (4): covers ring reach and layout. |
| Migration status | **MIGRATED** |
| Correction (if any) | None. |

#### mxChipStyle and helpers — `lib/shared/widgets/mx_chip_style.dart`
| Field | Record |
|---|---|
| Existing contract | `mxChipStyle`: ForUI's xs touch button (32) inside a 48 target, outline at rest, ghost with `isGhost`; `mxChipDecoration`, `mxChipLabelStyle`, `mxChipIconTheme`, `mxChipPadding`, `mxChipGap`: the resting parts for a chip that is not a button. Pinned through the MxFilterChip, MxChipTrigger tests. |
| Call sites | `MxFilterChip`, `MxChipTrigger`, and `card_removable_tag_chip_widget.dart` (all five part helpers). |
| ForUI candidate APIs | `FTheme.of(context).buttonStyles.outline / ghost .resolve({platform, FButtonSizeVariant.xs})`, `FButtonStyle.copyWith`, `FMultiSelectTag` / `FMultiSelectTagStyle`. |
| Installed package version | forui 0.27.6 |
| Official documentation | https://forui.dev/docs/widgets/form/button , https://forui.dev/docs/widgets/form/multi-select |
| Source evidence | `widgets/button/button.dart:528-533, 590-595` (xs styles), `:426-462` (outline / ghost variants), `select/multi/tag.dart:22-140` (a removable tag, standalone fallback to the theme tag style at :103-105); `mx_tap_target.dart` (`mxTargetStyle`, `MxInsetShapeBorder`). |
| API verification | tests pass; no new probe needed. |
| Native capability | Chip look entirely from ForUI's resolved button style. |
| Capability gaps | 48 dp target: no ForUI API (see MxFilterChip). |
| Current approach | Native style resolution + Foundation shim (`mxTargetStyle`, owned by `mx_tap_target.dart`, another set). |
| Selected approach | Same. |
| Why not a higher-level API? | n/a (native). Pointer for the owner of `CardRemovableTagChipWidget` (not in this set): it rebuilds a removable chip from five `FButtonStyle` parts; `FMultiSelectTag` is ForUI's removable tag and could be probed there (it is 32-ish dp, so the 48 dp target and the "Remove {tag}" label from the caller are the things to check). |
| Contract tests | via MxFilterChip / MxChipTrigger tests. |
| Migration status | **MIGRATED** |
| Correction (if any) | None in this file. |

#### MxTagChip — `lib/shared/widgets/mx_tag_chip.dart`
| Field | Record |
|---|---|
| Existing contract | `mx_tag_chip_test.dart`: "22 default, 18 dense; secondary ground, muted label", "a long tag stops at 140 with an ellipsis". Read-only metadata; text scale grows it (ruling S11). |
| Call sites | 6 sites in 5 files (`search_card_hit_row_widget.dart:49`, `tag_rename_dialog_widget.dart:243`, `card_row_widget.dart`). |
| ForUI candidate APIs | `FBadge(variant: .secondary)`, `FBadge.raw`, `FMultiSelectTag`. |
| Installed package version | forui 0.27.6 |
| Official documentation | https://forui.dev/docs/widgets/data/badge |
| Source evidence | `widgets/badge.dart:62-81` (`FBadge` / `.raw`), `:130-134` (secondary: `secondary` fill, `secondaryForeground` label), `:114-116` (padding 12 x 6). |
| API verification | PROBE P5: `FBadge.raw` with a min-height builder and `FBadge(child:)` + `FBadgeStyleDelta.delta(padding)` give the same 101.5 x 22. Tests pass. |
| Native capability | The pill, secondary fill and label type are `FBadge`'s. |
| Capability gaps | Label colour is `mutedForeground` (tests: "muted label"), not the secondary variant's `secondaryForeground`; the 22 / 18 floor is a min height `FBadge` has no field for. |
| Current approach | Composition: `MxToneBadge` (`FBadge.raw`) with `secondary` fill, `mutedForeground` ink, min height 22 / 18, max width 140. |
| Selected approach | Same. Optional: pass `variant: FBadgeVariant.secondary` so the fill comes from the variant (needs a `variant` parameter on `MxToneBadge`). |
| Why not a higher-level API? | `FBadge` is the widget; the min height has no style field (P5 needed a `ConstrainedBox` inside the child either way). `FMultiSelectTag` is an interactive removable tag, not metadata. |
| Contract tests | `mx_tag_chip_test.dart` (2). Missing: dense text-scale growth is covered in `mx_badge_test.dart` only for MxBadge. |
| Migration status | **MIGRATED** |
| Correction (if any) | None required. |

#### MxBadge (and MxToneBadge) — `lib/shared/widgets/mx_badge.dart`
| Field | Record |
|---|---|
| Existing contract | `mx_badge_test.dart`: "tonal: the tone tinted over the surface under a tone label; a 22 pill, 8 inset", "solid: tone fill under an onPrimary label", "each tone; a tonal warning reads in warning text colour (S3), a tonal mastery in the mastered ink", "a 12 glyph 4 before the label; the pill grows, never clips", "success: the success tint under a success text colour label". Solid is primary only (assert). No streak tone (S1), neutral colour (S2). |
| Call sites | 25 sites in 19 files for MxBadge (`import_deck_row_widget.dart:98`, `import_preview_section_widget.dart:82`, `search_results_widget.dart`); `MxToneBadge` is shared with MxStatusBadge and MxTagChip. |
| ForUI candidate APIs | `FBadge` (`variant`, `style`, `.raw`), `FBadgeStyleDelta`. |
| Installed package version | forui 0.27.6 |
| Official documentation | https://forui.dev/docs/widgets/data/badge |
| Source evidence | `widgets/badge.dart:62-81` (`FBadge` applies `style.padding` and `labelTextStyle` in `Center(Padding(DefaultTextStyle.merge))`; `.raw` hands the builder the resolved style), `:114-116`, `:130-141`. |
| API verification | PROBE P5 (same size both ways). Tests pass (5). |
| Native capability | Pill shape, decoration, label type, `IntrinsicWidth` / `IntrinsicHeight` sizing. |
| Capability gaps | Tonal fill is an opaque blend over `MxTintBase` (`tintOver`) for contrast guarantees; ForUI's tint is `withValues(alpha:)` (`badge.dart:103-107`). No icon slot and no min-height field. |
| Current approach | Composition: `FBadge.raw` with `FBadgeStyleDelta.delta(decoration: shapeDelta(color), labelTextStyle: meta role)` and a builder adding min height, padding, `DefaultTextStyle.merge`, `IconTheme.merge`. |
| Selected approach | Same; optional micro-simplification below. |
| Why not a higher-level API? | `FBadge(child:)` is one step higher than `.raw` and measures identical (P5); the gain is about 10 lines (`DefaultTextStyle.merge`, `Padding(Center)`), not a contract change. `FBadge` variants cannot express the tint-over-surface fill or tonal inks. |
| Contract tests | `mx_badge_test.dart` (5), plus golden tests in `status_widgets_golden_test.dart` (not run). Covers tones, solid, glyph, growth. |
| Migration status | **MIGRATED** |
| Correction (if any) | Optional (low value): in `MxToneBadge` use `FBadge(child: ConstrainedBox(minHeight, Center(widthFactor: 1, child: child)), style: FBadgeStyleDelta.delta(decoration, labelTextStyle, padding: EdgeInsetsGeometryDelta.value(padding)))` instead of `.raw`; icon colours are already explicit at both icon call sites, so `IconTheme.merge` can go. Re-run the badge and status tests. |

#### MxStatusBadge — `lib/shared/widgets/mx_status_badge.dart`
| Field | Record |
|---|---|
| Existing contract | `mx_status_badge_test.dart`: "the status fixes the dot and fill; the label is its foreground", "pill: 22 tall, 6 before the 6 dot, 4 gap, 8 after", "dot only: an 8 circle announced by its label". Label reads in the status ink (AA); `isDot` is the bare 8 dp indicator for dense rows. |
| Call sites | 1 (`card_detail_content_widget.dart:39`) + gallery. |
| ForUI candidate APIs | `FBadge.raw` (through `MxToneBadge`); no dot / indicator widget in the catalog. |
| Installed package version | forui 0.27.6 |
| Official documentation | https://forui.dev/docs/widgets/data/badge |
| Source evidence | `widgets/badge.dart:62-81`; catalog scan: no status-dot widget. |
| API verification | tests pass (3). |
| Native capability | The pill is `FBadge`. |
| Capability gaps | A coloured 6 / 8 dp dot and the dot-only semantics (container, label) have no ForUI widget. |
| Current approach | Composition: `MxToneBadge` + a Flutter `DecoratedBox` circle; bare dot is `Semantics(container, label)` + circle. |
| Selected approach | Same. |
| Why not a higher-level API? | No ForUI dot; `FAvatar` / `FProgress` are not indicators of this kind. |
| Contract tests | `mx_status_badge_test.dart` (3): covers fill / dot colours, pill geometry, dot semantics. |
| Migration status | **MIGRATED** |
| Correction (if any) | None. |

---

### Summary

| Component | Current | Selected | Status |
|---|---|---|---|
| MxTextField | Native `FTextField` + composed label / supporting row + shims | same | MIGRATED |
| MxCodeField | Composition on hidden `FTextField` + painted slots | same (`FOtpField` rejected, probes P1, P11) | BLOCKED (API limit) |
| MxSearchField | default: Native `FTextField`; trigger: painted `FTextField` + `FTappable.static` + `Semantics` | default same; trigger `FButton` lg + style delta | CORRECTION NEEDED (trigger) |
| MxFieldMessage | Fallback (Row / Icon / Text / live region) | same | MIGRATED |
| MxUserEdits | Foundation shim on `inputFormatters` + `control.onChange` | same | MIGRATED (test gap) |
| MxSelectionCheckbox | Native `FCheckbox`, painted only | same | MIGRATED |
| MxOptionRow | `MxRowInk` (`FTappable.static`) + painted `FRadio` | same (`FItem` rejected, P6) | MIGRATED |
| MxChoiceTile | Fallback (`GestureDetector` + `Semantics` + tone tweens) | `FTappable.static` + same `Semantics` + tweens | CORRECTION NEEDED |
| MxSegmentedTray | `FTappable.static` per option | same (`FTabs` rejected, P3) | BLOCKED (owner rulings + API limits) |
| MxFilterChip | Native `FButton` xs outline + `mxChipStyle` | same | MIGRATED |
| MxChipTrigger | Native `FButton` xs ghost + `mxChipStyle` | same | MIGRATED |
| MxChipRow | Fallback (`ClipRect` + `SingleChildScrollView`) | same (no ForUI chip row) | MIGRATED |
| mxChipStyle + helpers | Native style resolution + `mxTargetStyle` | same | MIGRATED |
| MxTagChip | Composition (`FBadge.raw` via `MxToneBadge`) | same | MIGRATED |
| MxBadge / MxToneBadge | Composition (`FBadge.raw`) | same (optional `FBadge(child:)`) | MIGRATED |
| MxStatusBadge | Composition (`FBadge.raw` + Flutter dot) | same | MIGRATED |

Counts: **MIGRATED 12, CORRECTION NEEDED 2, BLOCKED 2** (16 components; `MxToneBadge` is recorded with `MxBadge`).

### Corrections, ordered by value (contract-preserving first, most custom code removed first)

1. **MxChoiceTile: `GestureDetector` -> `FTappable.static`** (`mx_choice_tile.dart`). Contract-preserving (P7 verifies semantics, inert state, Tab+Enter); closes the registered keyboard-focus debt DEV-391 (screens 17, 18, 37 say "none yet"); removes the hand-rolled hit handling and adds focus ring, hover and keyboard activation from ForUI. Keep the outer `Semantics` (the `sortKey` does not survive `FTappable`, P7d). Add the tests listed in its record.
2. **MxSearchField.trigger: `FButton` lg + `FButtonStyleDelta`** (`mx_search_field.dart`). Removes `mxPaintedOnly(field)`, the hand-made button `Semantics`, the `FTappable.static` + outline, and the read-only / `canRequestFocus` flags on the trigger (about 20 lines); P12 verifies 48 dp, tap and button semantics. Needs a `golden-compare` of screen 01's root search and a rewrite of the 5 trigger tests. Owner approval for any `lib/shared/` change as per CLAUDE.md.
3. **Tests, no production change:** add `test/shared/widgets/mx_user_edits_test.dart` (person's edits report once; `controller.text =`, selection moves and `clear()` do not; a rewriting formatter reports the rewritten text), and the unpinned `MxChoiceTile` rows (right / wrong tones, recessed, faded, reduced motion, sortKey).
4. **Owner decision, MxTextField name shim** (`mx_text_field.dart`, about 12 lines): let `FLabel`'s native `LabelSemantics` announce "Front, Required" as one name (P8) instead of "Front" + a separate "Required" node. Changes what TalkBack reads; tests that pin the name still pass.
5. **Optional cleanups:** drop the no-op `onChange: (_) {}` on `FCheckbox` / `FRadio` (`checkbox.dart:118`, `radio.dart:121`); `MxToneBadge` on `FBadge(child:)` (P5) and a `variant` hook for `MxTagChip`.
6. **Cross-set pointers (not in G2):** (a) the row family (`MxRowInk`, `MxListRow`, `MxSettingsRow`) shares the `FItem` min-height limitation found in P6 / `item_content_layout.dart:154`; (b) `CardRemovableTagChipWidget` rebuilds a removable chip from `mxChip*` parts and is the place to evaluate `FMultiSelectTag` (`select/multi/tag.dart:22-140`).

## Ledger G3: layout, navigation, rows (lib/shared/widgets/)

Auditor: G3. forui 0.27.6. No file in the repository was edited. Probes live in
`ledger_probe/test/`
(`g3_shell_test.dart`, `g3_header_test.dart`, `g3_item_test.dart`, `g3_nav_test.dart`, `g3_tappable_test.dart`,
`g3_progress_test.dart`; helpers `g3_common.dart`). Probe host: `MaterialApp` + `FTheme.neutral.light.touch` at 360x800,
not the MemoX theme, so sizes are ForUI defaults and are only used where the claim is about ForUI's structure.

Notation: `fu:` = `/root/.pub-cache/hosted/pub.dev/forui-0.27.6/lib/src/widgets/`, `mx:` = ``.
"CAT" = `docs/forui-migration/FORUI_API_CATALOG.md`.

### Test run (honest result)

`MEMOX_TEST_BUNDLES=0 bash .claude/skills/flutter-workflow/scripts/run_tests.sh` on the 20 test files of this set
(`mx_action_sheet_command_row`, `mx_app_bar_semantics`, `mx_app_bar`, `mx_app_shell_ground`, `mx_app_shell`,
`mx_bottom_nav`, `mx_breadcrumb`, `mx_divided_column`, `mx_footer_bar`, `mx_list_row`, `mx_list_section_header`,
`mx_nav_rail`, `mx_row_ink`, `mx_screen_scroll`, `mx_scroll_fade`, `mx_section`, `mx_selectable_card_row`,
`mx_settings_row`, `mx_study_top_bar`, `mx_two_columns`; all `*_test.dart` under `test/shared/widgets/`):
**+195: All tests passed** (20 suites, 32.1 s). Goldens excluded (`mx_nav_rail_golden_test.dart` not run, by the brief).

### Answers to the seven specific questions (details in the records)

**(a) MxAppShell vs FScaffold: keep Material `Scaffold` as infrastructure.** Evidence:
- FScaffold has no FAB slot: the constructor takes only `child, header, sidebar, footer, childPad, resizeToAvoidBottomInset, scaffoldStyle` (`fu:scaffold.dart:85-93`). `MxAppShell` places the FAB 16 from the column edge, 24+inset or 4 above the nav, RTL-mirrored (`mx:lib/shared/widgets/mx_app_shell.dart` `_MxFabLocation`; pinned by `mx_app_shell_test.dart` FAB tests).
- FScaffold shrinks its child for the keyboard but does not strip the inset for descendants. PROBE `g3_shell_test.dart` P1a: two nested FScaffolds under a 300 dp keyboard on an 800 dp screen give the inner child **200 dp**; two nested Material Scaffolds give **500 dp** (P1b). MemoX nests shells (`mx:lib/app/router/app_tab_shell.dart:34-37` wraps `navigationShell`, whose screens each build an `MxAppShell`). P1d: descendants of FScaffold still see the full `viewInsets` and `padding`.
- FScaffold's footer is not lifted above the keyboard: PROBE P1c, body ends at 500 (keyboard top), footer rect 720-800 = under the keyboard (`fu:scaffold.dart:251-257`). `MxFooterBar` must stay above the keyboard (the shell puts it in the body column).
- No safe-area handling in FScaffold (only `FHeader` applies `SafeArea(bottom: false)`, `fu:header/nested_header.dart:54`, `root_header.dart:38`).
- Sheets host: FScaffold wraps `FSheets` (`fu:scaffold.dart:114`), which only `showFPersistentSheet` needs (`fu:sheet/persistent_sheet.dart:16,91`). `rg showFPersistentSheet|FSheets mx:lib` finds nothing; modal sheets are `showMxBottomSheet` (`FModalSheetRoute`).
- `ScrollNotificationObserver` (used by `_ScrolledUnderScope`) is provided by Scaffold and not by FScaffold: PROBE P1e (`false` vs `true`). Material ancestor: P1f (`false` vs `true`); not needed by ForUI (`fu:text_field/input/input.dart:333` and `tabs/tabs.dart:190` add their own `Material`), and `FTheme` supplies the default text style (`fu:../theme/theme.dart:338`).
- **One finding the Scaffold choice hides**: FScaffold/FHeader apply `FColors.systemOverlayStyle` (`fu:scaffold.dart:109`, header `AnnotatedRegion`), Material's `Scaffold` does not (only `AppBar` does: `rg AnnotatedRegion material_ui-1.4.0/lib/src/*.dart` hits `app_bar.dart` only). `mx:lib/core/theme/app_palette.dart:20,42` define `systemOverlayStyle`, and nothing in `lib/` or `test/` consumes it (`rg "AnnotatedRegion|systemOverlayStyle|SystemUiOverlay"`). Status-bar icon brightness in an in-app Dark theme over a Light OS (or the reverse) is therefore unmanaged. UNVERIFIED on a device (code reading only).

**(b) MxAppBar vs FHeader / FHeader.nested / FHeaderAction: keep the custom bar.**
- Actions: PROBE P2d, `FHeaderAction.back` / default action = **44x44** at the touch theme (`fu:header/header.dart:117,136`), below the 48 floor (`mx:FORUI_ARCHITECTURE.md` "Targets": every interactive control 48). The bar's slots hold `MxIconButton` (48), which FHeader's `prefixes/suffixes: List<Widget>` would accept, so this alone is not blocking.
- Title position: nested header hard-codes `Padding(horizontal: 10)` around the title (`fu:header/nested_header.dart:70`). PROBE P2a: title starts at x=74 after a 52 dp prefix at padding 12 (12+52+10); PROBE P2b with `padding: 16`, no prefix: title at x=26 (16+10). `MxAppBar` puts the title on the screen margin (16) or 4 after the leading control (`test/shared/widgets/mx_app_bar_test.dart` "a content bar without a leading control starts its title on the margin"). The root header has no hard-coded inset (PROBE P2c: title x=16) but no `prefixes`, so a back button is impossible.
- Heading semantics: FHeader puts `Semantics(header: true)` on the **whole bar** (`fu:header/nested_header.dart:56-57`, `root_header.dart:40-41`). PROBE P2a: one node `isHeader label="Library" rect=360x70` (the whole bar). PROBE P2f: a search-field title becomes `isTextField,isHeader label="Search decks" rect=360x70`. `MxAppBar` contract: the title text is the heading, a `titleWidget` "brings its own semantics; no header flag is added" (`mx_app_bar.dart` doc; `mx_app_bar_semantics_test.dart`).
- Route name: FHeader adds no `namesRoute` (P2a dump has only `isHeader`); `MxRouteName` stays.
- Scrolled-under edge: `FHeaderStyle.decoration` is static (`fu:header/header.dart` style fields); no scroll awareness anywhere in forui (`rg scrolledUnder|ScrollNotificationObserver forui lib` = no hits). The shell's `_AppBarGround` stays.
- Title is `maxLines: 1, softWrap: false` via `DefaultTextStyle.merge` (`nested_header.dart:71-75`): fine for `Text` titles, not a blocker. Min height 54/62 vs `sizeAppBar` 64: `FHeaderStyleDelta.delta(constraints:)` could set it; not a blocker.

**(c) MxBreadcrumb vs FBreadcrumb: FBreadcrumb fits with configuration; a correction is needed** (record below).
- `FBreadcrumb` is a plain `Row` with no scroll, collapse or fade (`fu:breadcrumb.dart:64`); `FBreadcrumbItem.collapsed` is a popover menu, "recommended for desktops & web" (CAT 776) and not needed here.
- PROBE `g3_nav_test.dart` P4c: `FBreadcrumb` inside `SingleChildScrollView(horizontal, reverse: true)` lays out without exception; crumbs whose child is `ConstrainedBox(min 48x48)` + `style: .delta(padding: zero)` are 48 tall tap targets; a non-current crumb with `onPress: null` is **plain text, not a button** (semantics dump: `label="Vocabulary"` with no `isButton`), the current crumb is `isSelected`. `MxBreadcrumb` must keep a `Semantics(button: true)` wrapper for tap-less ancestors (DEV-306, `mx_breadcrumb_test.dart`).
- Default crumb padding is 6x10 (`fu:breadcrumb.dart:528`), below 48; fixed by the child constraint above, not by an API.

**(d) MxListRow / MxSettingsRow / MxActionSheetCommandRow vs FItem / FTile (+ groups): keep the Composition on `MxRowInk`.** Verified gaps (all PROBE):
- Heights: `FItem` has no minimum height. P3a (touch theme): title only **41**, with subtitle **59**, with a 50 dp suffix **75**; contract is 56 / 72 and a 48 trailing control must not grow the row (ruling row 43 in `docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md` §9; `mx_list_row_test.dart` "a 48 trailing control does not grow the row"). P3g: `ConstrainedBox(minHeight: 56)` around `FItem` **throws** `_RenderLayout does not meet its constraints` (`fu:item/item_content_layout.dart:154` assigns `size` without clamping). `FItem.raw` with a child that carries its own min height works (P3h, 56 tall), but that is only a tappable frame around the same custom row.
- Disabled blocks inner controls: P3b, `FItem(enabled: false, suffix: button)`: row taps 0, **inner control taps 1**. Contract M3F-17 (`mx_row_ink_test.dart`, `mx_list_row_test.dart` "disabled dims and ignores taps", `mx_selectable_card_row_test.dart` "M3F-17").
- Disabled-with-reason: P3f, a disabled `FItem` dims the subtitle (alpha 0.5, `fu:item/item_content.dart:234`); contract DEV-230 keeps subtitle/meta at full strength (configurable through `subtitleTextStyle` variants, but then the leading `MxIconTile` is not an icon and gets no ForUI dimming).
- Static semantics: P3d, `FItem(selected: true, enabled: false)` with no callbacks emits only `label="Static"`: no selected/disabled flags (`fu:item/item.dart:344` static branch). `MxRowInk` emits them (M3F-10 tests).
- `FItem` exposes no `excludeSemantics`/label substitution (`fu:item/item.dart:345-380` passes none), but `MxSelectableCardRow` needs one sentence replacing the content (SW-REV-005); `FTile` has no `semanticsChecked` at all (`fu:tile/tile.dart` only `semanticsExpanded`, rg), which the checked-row contract needs.
- Selected fill: `FItem` paints `colors.secondary` when selected (`fu:item/item.dart:580-581`); `MxRowInk.isSelected` is used by rows with their own selected look (`topik_question_grid_sheet_widget.dart:139`, `import_source_option_widget.dart:36`), so the fill would double up.

**(e) MxDividedColumn / MxSection vs FItemGroup / FTileGroup: keep.** `FItemGroup.children` is `List<FItemMixin>` and `FTileGroup.children` is `List<FTileMixin>` (`fu:item/item_group.dart:241`, `fu:tile/tile_group.dart:161`): they cannot hold `MxSettingsRow`+`MxToggle`/stepper/message rows or the lazy lists `MxDividedColumn.divided` serves. Every root group is its own shrink-wrapped `CustomScrollView` (`fu:item/item_group.dart:427-431`, `tile_group.dart:319-323`), nested inside `MxScreenScroll`'s `ListView`. `indented` divider runs from the title/child left edge to the item's right edge (`fu:item/item_data.dart` enum doc); the contract is inset 16 at **both** ends (`mx_divided_column_test.dart` "inset 16 on each side"). The `FTileGroup` label is an `FLabel` (`tile_group.dart:348`), not the overline with heading semantics and a trailing slot. `MxDividedColumn` already uses the native `FDivider` with `FDividerStyleDelta`.

**(f) MxNavRail vs FSidebar.** `FSidebar` is **not** fixed at 256: that is only the default of `FSidebarStyle.constraints` (`fu:sidebar/sidebar.dart:257`), overridable with `FSidebarStyleDelta.delta(constraints: BoxConstraints.tightFor(width: 80))` (PROBE `g3_nav_test.dart` P4a: rect 80x800). There is no collapse/rail mode. `FSidebarItem` lays icon and label in a horizontal `Row` (`fu:sidebar/sidebar_item.dart:228-233`), so it cannot give the rail's icon-over-label pill; `MxNavItem` (an `FBottomNavigationBarItem` under a hand-built `FBottomNavigationBarData`) stays the item. `FSidebar.raw` can be the frame (decoration = `colors.background` + end border `colors.border`, `fu:sidebar/sidebar.dart` `FSidebarStyle.inherit`), which is what `MxNavRail` paints by hand: low-value correction.

**(g) MxBottomNav (already `FBottomNavigationBar`): verified.** PROBE P4b: item semantics `label="Library\nTab 1 of 4"`, selected item `isSelected`, each `isButton`; `onChange` fires on a re-tap of the selected item (calls `[1, 2]` after tapping index 1 then 2 with `index: 1`; no equality guard, `fu:bottom_navigation_bar/bottom_navigation_bar_item.dart:92`); `safeAreaBottom: true` uses `SafeArea(bottom:)` and adds no extra inset (`fu:bottom_navigation_bar/bottom_navigation_bar.dart:99-105`). The shell relies on the re-tap (`app_tab_shell.dart` `_onSelected`: `initialLocation: index == currentIndex`), covered at app level (`test/app/library_routes_test.dart:159`, `test/app/app_test.dart:100`, `test/app/tab_shell_test.dart:90`) but **not in `mx_bottom_nav_test.dart`** (missing unit case).

---

### Records

#### MxAppShell: `lib/shared/widgets/mx_app_shell.dart`
| Field | Record |
|---|---|
| Existing contract | One column per screen: top chrome, one scroll body, bottom bar, FAB layered above; app bar and footer are in-flow siblings (ruling R1/R3: app bar grows with text scale, not `Scaffold.appBar`). Footer stays above the keyboard. Body resized above the keyboard; `isTypingOf` survives the Scaffold stripping the inset, also in a nested shell. FAB: 16 from column edge (mirrored RTL), 24+inset or 4 above nav, inset counted once; FAB over footer rejected (assert). Column `sizeContentMax` compact/session, `sizeContentMaxWide` from medium, ground full-bleed. App bar ground: page colour, hairline fading in over `Durations.short4` once the vertical scroll moves under it (instant under reduced motion; cleared when body changes). Notice floats 16 in and pads the body. Pins: `mx_app_shell_test.dart` (14: ground, status inset, footer in-flow, FAB placements, inset once x3, FAB+footer rejected, wide column, wide FAB RTL, notice x2, nav never over body), `mx_app_shell_ground_test.dart` (9), `mx_footer_bar_test.dart` "caption steps aside in a real shell / in a shell nested in a tab shell". |
| Call sites | 57 outside `lib/shared/widgets/` and the gallery (+1 gallery file group). `lib/app/router/app_tab_shell.dart:34`, `lib/app/router/route_not_found_screen.dart`, `lib/app/startup_failure_app.dart`. `isTypingOf`: `session_footer_hint_widget.dart:25`, `sign_in_form_widget.dart:261`, `mx_footer_bar.dart:28`. |
| ForUI candidate APIs | `FScaffold` (+ `FScaffoldStyle`, `childPad`, `resizeToAvoidBottomInset`, `footer`, `header`, `sidebar`), `FSheets`, `FHeader` (as the top chrome), `FBottomNavigationBar` (as footer). |
| Installed package version | forui 0.27.6 |
| Official documentation | https://forui.dev/docs/widgets/layout/scaffold ; https://forui.dev/docs/widgets/navigation/header |
| Source evidence | `fu:scaffold.dart:85-93` (no FAB slot), `:109` AnnotatedRegion(`systemOverlayStyle`), `:113` IconTheme, `:114` FSheets, `:246-257` custom render (size = biggest; footerHeight = max(viewInsets.bottom, footer); footer at `size.height - footer.height`, i.e. under the keyboard), no `removeViewInsets`/`removePadding` in the file; Material: `material_ui-1.4.0/lib/src/app_bar.dart` is the only `AnnotatedRegion<SystemUiOverlayStyle>`. |
| API verification | PROBE `g3_shell_test.dart`: P1a nested FScaffold inner height 200 (vs 500 for nested Scaffold, P1b); P1c footer under keyboard (body 500, footer 720-800); P1d descendants keep full `viewInsets (0,0,0,300)` and `padding`; P1e/P1f no `ScrollNotificationObserver`/`Material` under FScaffold. |
| Native capability | FScaffold provides: background, keyboard-shrinking child (single level), `FSheets` host, system overlay style, icon theme, footer/header decoration slots. |
| Capability gaps | FAB slot and placement (ctor `scaffold.dart:85-93`); descendants not isolated from `viewInsets` so nested shells double-shrink (P1a); footer under keyboard (P1c); no scroll-under signal (P1e); no safe-area handling (`scaffold.dart` has no `SafeArea`/`MediaQuery.removePadding`). |
| Current approach | Fallback (justified): Material `Scaffold`/`ScaffoldPrelayoutGeometry`/`FloatingActionButtonLocation` as layout host (ADR-026, `FORUI_ARCHITECTURE.md` bridge table), `Durations`/`Easing` for the ground fade; everything painted is theme-driven (`context.colors`). No ForUI widget used. |
| Selected approach | Fallback (Scaffold as infrastructure) + one ForUI-native addition: wrap in `AnnotatedRegion<SystemUiOverlayStyle>(value: FTheme.of(context).colors.systemOverlayStyle)` (what `FScaffold` does at `scaffold.dart:109`). |
| Why not a higher-level API? | `FScaffold` would need a hand-written FAB layer, `MediaQuery.removeViewInsets` per child, a footer re-homed into the child column (it only works there), and a replacement for the Scaffold-provided `ScrollNotificationObserver`; that re-creates what the Scaffold gives and the owner already accepted (ADR-026). Evidence P1a-P1f. |
| Contract tests | Strong for geometry/FAB/ground/insets. Missing: (1) the shell applies the theme's system overlay style (none today); (2) FAB lifts with the keyboard (Scaffold behaviour is relied on, not pinned). |
| Migration status | CORRECTION NEEDED (small; the Scaffold decision itself is MIGRATED) |
| Correction (if any) | In `MxAppShell.build`, wrap the result in `AnnotatedRegion<SystemUiOverlayStyle>(value: context.theme.colors.systemOverlayStyle, child: ...)` (public `FColors.systemOverlayStyle`, `fu:../theme/colors.dart:37`; already defined per theme in `app_palette.dart:20,42`; `FTheme.of(context).colors` is the existing way `ThemeContext` reads it). Risk: none to layout; nested shells nest harmless regions. Add a widget test asserting `AnnotatedRegion<SystemUiOverlayStyle>.value` equals the light/dark palette value and that it follows a theme switch. Status is UNVERIFIED on a device until the test or a device run shows the icon colour in Dark-over-Light-OS. |

#### MxAppBar: `lib/shared/widgets/mx_app_bar.dart`
| Field | Record |
|---|---|
| Existing contract | Leading control, flexible one-line ellipsising title (optional muted subtitle line), trailing actions; at least `sizeAppBar` (64) tall, grows with text scale (R1); exactly one of `title`/`titleWidget` (assert); `subtitle` only with `title`; title = screen-title role, **heading + names the route** (`MxRouteName(isHeader: true)`), subtitle in the same node (Q-P6-2); `titleWidget` brings own semantics, optional `isTitleWidgetRouteName`; glyphs sit on the screen margin (48 target reaches past), title on the margin without a leading control; text last action ends on the margin; search-field title gets `space8` above/below; no ground of its own. Pins: `mx_app_bar_test.dart` (17: height, role, margin, ellipsis, asserts, text action, wrapper widgets, search field, glyph alignment per width, ForUI ghost icon buttons, disabled ink, no ground), `mx_app_bar_semantics_test.dart` (7: header, namesRoute per platform, subtitle node, titleWidget routes, asserts). |
| Call sites | 44 outside widgets/gallery: `lib/features/search/presentation/screens/library_search_screen.dart`, `lib/features/transfer/presentation/screens/card_import_screen.dart`, `lib/features/account/presentation/widgets/sections/account_transition_layer_widget.dart`. |
| ForUI candidate APIs | `FHeader` (root), `FHeader.nested(prefixes, suffixes, titleAlignment)`, `FHeaderAction` (+ `.back`, `.x`), `FHeaderStyleDelta`, `FHeaderActionStyleDelta`. |
| Installed package version | forui 0.27.6 |
| Official documentation | https://forui.dev/docs/widgets/navigation/header |
| Source evidence | `fu:header/header.dart:34-70` ctors, `:110` constraints 54/62, `:117,136` action padding (7 / 11), `:120,138` padding; `fu:header/nested_header.dart:54-57` `SafeArea` + `Semantics(header: true)` on the whole bar, `:70` hard-coded `Padding(horizontal: 10)` on the title, `:71-75` `DefaultTextStyle.merge(maxLines: 1, softWrap: false)`; `fu:header/root_header.dart:38-41,51` header flag on the whole bar, `Expanded` title, no prefixes. |
| API verification | PROBE `g3_header_test.dart`: P2a nested (title x=74, header flag node 360x70, buttons separate); P2b nested no prefix padding 16 (title x=26); P2c root padding 16 (title x=16, header 360x64); P2d `FHeaderAction` 44x44; P2e @2x text still ellipsises, header grows to 70; P2f search-field title node `isTextField,isHeader` 360x70. |
| Native capability | SafeArea(top), min height that grows, padding, start-aligned title with ellipsis, RTL, status-bar overlay style, header flag, prefix/suffix layout with the title clamped between them (nested). |
| Capability gaps | Title inset 10 dp not removable (nested_header.dart:70, P2a/P2b); header flag on the whole bar breaks "title is the heading" and "titleWidget adds no header flag" (P2a, P2f); default actions 44 dp (P2d); no `namesRoute`; no scrolled-under edge; root variant has no leading slot (P2c). Subtitle and `isLastActionText`/`isTitleField` insets would be recomputed into `FHeaderStyleDelta.padding` per build, i.e. the same math in another place. |
| Current approach | Fallback (justified): `SafeArea(bottom: false)` + `ConstrainedBox(minHeight)` + `Padding` + `Row(Expanded)` of Flutter basics; slots take `MxIconButton` (`FButton.icon` ghost lg) and the title carries `MxRouteName` (Semantics only). ~25 lines of layout. |
| Selected approach | Same (Fallback justified). |
| Why not a higher-level API? | `FHeader`/`FHeader.nested` break three verified contracts: the 10 dp title inset (P2a/P2b), the whole-bar header flag (P2a/P2f), and 44 dp default actions (P2d). No configuration removes the first two. |
| Contract tests | `mx_app_bar_test.dart` + `mx_app_bar_semantics_test.dart` cover the contract above (24 tests, pass). Gap: none material; `MxRouteName` itself has no direct unit test (record below). |
| Migration status | MIGRATED |
| Correction (if any) | none. |

#### MxStudyTopBar: `lib/shared/widgets/mx_study_top_bar.dart`
| Field | Record |
|---|---|
| Existing contract | Session chrome: close (`MxIconButton`, null `onClose` = disabled node, labelled 48 target), mode chip (upper-cased, read as written via `semanticsLabel`, ellipsises, capped at 40% of the bar, names the route on non-Apple platforms), thin progress track `sizeTrack` (4) tall in `MasteryRamp.track` with a primary fill = current/total, easing over 200 ms (`Durations.short4`, `Easing.standard`), instant under reduced motion, counter "n / total" (polite live region, shrinks, max 25%), side padding puts the close glyph and counter on the screen margin, 56+ min height growing with text scale (R1), paints its own ground. Pins `mx_study_top_bar_test.dart` (12: fill, route naming x2, upper-case, primary fill R8, track R6, 200 ms, close, null close, live region, margins per width, M3F-18 track height, asserts). |
| Call sites | 2 outside widgets/gallery: `lib/features/study/presentation/screens/study_session_screen.dart:373`, `lib/features/topik/presentation/screens/topik_attempt_screen.dart:211`. |
| ForUI candidate APIs | `FDeterminateProgress` (+ `FDeterminateProgressStyleDelta`, `FDeterminateProgressMotion`), `FBadge.raw` (via the existing `MxToneBadge`), `FHeader`. |
| Installed package version | forui 0.27.6 |
| Official documentation | https://forui.dev/docs/widgets/feedback/determinate-progress ; https://forui.dev/docs/widgets/data/badge |
| Source evidence | `fu:progresses/determinate_progress.dart:49-50` ctor (value required), `:66-95` controller starts at 0 and `animateTo` on first build (`_setup`), instant only when `FAccessibilityMotion.disabled`, `:114-118` `Semantics(label, value: percent)`, style `constraints = tightFor(height: 6)` (:135-148) and `FDeterminateProgressMotion(duration 1 s, linear)` are delta-able; `mx:lib/shared/widgets/mx_badge.dart:80-123` `MxToneBadge` = `FBadge.raw` pill (fill, ink, `padding`, `minHeight`) shared by `MxBadge`/`MxStatusBadge`/`MxTagChip`; `mx:lib/shared/widgets/mx_linear_progress.dart` is the same tree as this bar's track (ClipRRect / ColoredBox / TweenAnimationBuilder / FractionallySizedBox). |
| API verification | PROBE `g3_progress_test.dart` P6: `FDeterminateProgress(value .3)` with delta `constraints: tightFor(height: 4)` and `motion: 200 ms, easeOut`: first frame widthFactor **0.0**, 100 ms 0.205, 250 ms 0.3, height 4.0. So height, track/fill decoration and motion are configurable; the first build sweeps from 0 (MemoX's `TweenAnimationBuilder(end:)` shows the final value at once). It adds a progress `Semantics` node, so it needs `ExcludeSemantics` (as `MxLinearProgress` does). |
| Native capability | Layout of close + chip + track + counter is custom. Determinate track and pill are available as shared/ForUI parts. |
| Capability gaps | `FDeterminateProgress`: first-build sweep from 0 (P6) and an extra semantics node (fixable). `MxLinearProgress` has no primary-fill form (only success / mastery fills): reuse needs a shared-widget addition (owner call, CLAUDE.md "Asking the owner"). |
| Current approach | Composition + Fallback: `MxIconButton`, `MxRouteName` (ForUI via those); the chip is a hand-built `DecoratedBox(StadiumBorder, tint)` + `Text`; the track is a hand-built `ClipRRect`/`ColoredBox`/`TweenAnimationBuilder`/`FractionallySizedBox` (inventory row: "track is a custom ColoredBox"). |
| Selected approach | Composition: chip = `MxToneBadge(fill: accent.tintOver(MxTintBase.of(context)), ink: accent, padding: symmetric(space8, space4), minHeight: 0 or the chip's height, child: MxRouteName(child: Text(modeLabel.toUpperCase(), semanticsLabel: modeLabel, maxLines: 1, overflow: ellipsis)))` inside the existing 40% `ConstrainedBox`; track = the shared `MxLinearProgress` (new primary-fill constructor, owner to approve) whose own body then moves to `FDeterminateProgress` (belongs to the `MxLinearProgress` record, not this set). |
| Why not a higher-level API? | The bar as a whole has no ForUI counterpart (`FHeader` fails as in MxAppBar). The two sub-parts have shared owners (`MxToneBadge`, `MxLinearProgress`); duplicating them here is the "per-screen patch over a shared owner" CLAUDE.md rejects. |
| Contract tests | All contract points pinned (12 tests, pass). Missing: none for current code; after the change the 40% cap, upper-case/`semanticsLabel`, route-naming and "fill animates over 200 ms" tests must keep passing against the shared parts. |
| Migration status | CORRECTION NEEDED |
| Correction (if any) | (1) Replace the chip `DecoratedBox` with `MxToneBadge` (verified signature `mx_badge.dart:80-93`; removes ~15 lines; tint call and 40% cap unchanged; `ShapeDecoration(StadiumBorder)` vs `FBadge`'s shape must be compared in the study goldens, which will change: golden-compare page needed). (2) Replace the track with the shared progress widget: needs an owner decision on adding a primary-fill form to `MxLinearProgress` (new shared API). If `MxLinearProgress` moves to `FDeterminateProgress`, pin first-build behaviour (resumed session at 7/10 must not sweep unless that is accepted) and wrap in `ExcludeSemantics`. Tests to add: a golden/widget test that the chip uses `MxToneBadge` ink/fill; keep `_fill` reading `FractionallySizedBox.widthFactor` (FDeterminateProgress builds one too). |

#### MxBottomNav (+ MxNavDestination, MxNavItem): `lib/shared/widgets/mx_bottom_nav.dart`
| Field | Record |
|---|---|
| Existing contract | In-flow bar (never over the scroll) above the gesture inset; four equal columns; selected = primary glyph + label, others muted, glyph swaps to `selectedIcon`; each destination a button named with its place; tap reports index (re-tap too, the shell uses it); cells are accessible targets; `selectedIndex` asserted in range. `MxNavItem` renders one destination outside a bar for the rail. Pins `mx_bottom_nav_test.dart` (11: height+inset, flat bar, four columns, selected colours, selection moves, whole-cell target, tap reports index/selected, positions "Tab i of n", accessible targets, assert, focus outline light/dark). |
| Call sites | 1 production (`lib/app/router/app_tab_shell.dart:34`) + gallery; `MxNavItem` used by `MxNavRail` only. |
| ForUI candidate APIs | `FBottomNavigationBar`, `FBottomNavigationBarItem`, `FBottomNavigationBarData`, `FBottomNavigationBarStyle`. |
| Installed package version | forui 0.27.6 |
| Official documentation | https://forui.dev/docs/widgets/navigation/bottom-navigation-bar |
| Source evidence | `fu:bottom_navigation_bar/bottom_navigation_bar.dart:49-69` ctor (`safeAreaBottom`, `index`, `onChange`), `:99-105` `SafeArea(bottom: safeAreaBottom)` / 2/3 inset otherwise; `bottom_navigation_bar_item.dart:76-92` `MergeSemantics(FTappable(onPress: () => onChange?.call(index)))` (no equality guard), `:98` icon `ExcludeSemantics`, `:112` "Tab i of n" label. |
| API verification | PROBE `g3_nav_test.dart` P4b: semantics `label="Library\nTab 1 of 4"` / `isSelected` on index 1 / `isButton`; `onChange` list `[1, 2]` after tapping the selected index 1 then 2; bar at 705-800 with a 34 dp bottom inset. Tests: `mx_bottom_nav_test.dart` "each destination is named with its position". |
| Native capability | All of it: selection, semantics, safe area, re-tap callback, style. |
| Capability gaps | none for this contract (no per-item badge/disabled needed). |
| Current approach | Native (`FBottomNavigationBar` + `FBottomNavigationBarItem`); `MxNavItem` = Composition via `FBottomNavigationBarData`. |
| Selected approach | Native. |
| Why not a higher-level API? | n/a (native). |
| Contract tests | Covered. Missing: a unit test that a re-tap of the selected destination still calls `onSelected` (covered only at app/rail level: `library_routes_test.dart:159`, `app_test.dart:100`, `tab_shell_test.dart:90`, `mx_nav_rail_test.dart:108`). |
| Migration status | MIGRATED |
| Correction (if any) | none. Optional test: add the re-tap case to `mx_bottom_nav_test.dart`. |

#### MxNavRail: `lib/shared/widgets/mx_nav_rail.dart`
| Field | Record |
|---|---|
| Existing contract | For windows of `breakpointMedium` and wider (FE-C5): `sizeRail` (80) wide, page background, hairline border on the inner edge, destinations from the top as `MxNavItem` (same item as the bar), each at least `sizeControl` wide and 56 tall, selected pill; scrolls when the window is short; takes only the inset of its own side (left in LTR, right in RTL); re-tap reports; 48 targets; focus outline not clipped. Pins `mx_nav_rail_test.dart` (7: frame/size, selected colours, tap+re-tap, semantics + 48 targets, start inset only, short window scrolls, focus outline light/dark) + a golden (not run). |
| Call sites | 1 production (`lib/app/router/app_tab_shell.dart:47`) + gallery. |
| ForUI candidate APIs | `FSidebar` / `FSidebar.raw`, `FSidebarItem`, `FSidebarGroup`, `FSidebarStyleDelta`, `FBottomNavigationBarItem`. |
| Installed package version | forui 0.27.6 |
| Official documentation | https://forui.dev/docs/widgets/navigation/sidebar |
| Source evidence | `fu:sidebar/sidebar.dart:82-130` ctors (`.raw(child)`), `:184-205` `FocusScope > DecoratedBox(style.decoration) > ConstrainedBox(style.constraints) > Column[header, Expanded(content), footer]`, `:257` default `tightFor(width: 256)` (a style field, not fixed), `FSidebarStyle.inherit` decoration = `colors.background` + end border `colors.border`; `fu:sidebar/sidebar_item.dart:228-233` icon and label in a horizontal `Row` with `Expanded(label)`. |
| API verification | PROBE `g3_nav_test.dart` P4a: `FSidebar.raw` with `constraints: tightFor(width: 80)` renders 80x800. |
| Native capability | `FSidebar.raw`: frame (ground + end border), fixed width through style, focus scope with parent-scope traversal. |
| Capability gaps | No collapsed/rail mode. `FSidebarItem` cannot render icon-over-label pills in 80 dp (horizontal Row, label `Expanded`), nor "Tab i of n" semantics. `FSidebar` needs bounded height (Column + Expanded) and its decoration is not inset-aware, so `SafeArea` must be inside its child (not around it) to keep the border full height. |
| Current approach | Composition: `MxNavItem` (FBottomNavigationBarItem under a hand-built `FBottomNavigationBarData`) + a hand-built frame (`DecoratedBox` background + `BorderDirectional` border, `SafeArea`, `SizedBox(width)`, `SingleChildScrollView`). |
| Selected approach | Composition: keep `MxNavItem`; take the frame from `FSidebar.raw`. |
| Why not a higher-level API? | `FSidebarItem` fails the item layout (see gaps); the full `FSidebar(children:)` wraps a `ListView` and the item model of the sidebar, not an icon-over-label rail. |
| Contract tests | Cover size, selected colours, taps, semantics, insets, scroll, focus. After the change the frame test ("on the background with a divider edge") reads `FSidebarStyle.decoration` instead of a `DecoratedBox`. |
| Migration status | CORRECTION NEEDED (low value, optional) |
| Correction (if any) | `FSidebar.raw(style: FSidebarStyleDelta.delta(constraints: BoxConstraints.tightFor(width: dimens.sizeRail), contentPadding: EdgeInsetsGeometryDelta.value(EdgeInsets.symmetric(vertical: dimens.space8))), child: SafeArea(left: isLtr, right: !isLtr, child: SingleChildScrollView(... MxNavItem column ...)))`. Goes away: the hand-built `DecoratedBox`/`BorderDirectional` (~8 lines). Risks: height must be bounded (true in `AppTabShell`'s `Row(stretch)`; the unit test's host must bound it), border/background now come from the ForUI theme (same colours), added focus-scope grouping. Re-run `mx_nav_rail_test.dart` and the rail golden. |

#### MxBreadcrumb (+ MxBreadcrumbSegment): `lib/shared/widgets/mx_breadcrumb.dart`
| Field | Record |
|---|---|
| Existing contract | 48 dp band (R4); never wraps or truncates a segment; scrolls horizontally, opens at its end (reverse) so the current level is visible, starts at the gutter when it fits; deep paths fade the start edge while ancestors are scrolled out (DEV-306); ancestors are 48x48 buttons, muted label role; current = item-title role, not tappable; one border-coloured 16 chevron between segments; `onTap` ignored on the last; a segment without `onTap` is still a button to TalkBack; focus ring on a focused ancestor (M3F-05), none on the current level or a tap-less segment. Pins `mx_breadcrumb_test.dart` (9: tappable ancestors, ink roles, chevron, short path gutter, 10 levels show current, 48x48 targets, deep fade + reachable hidden ancestors, focus ring light/dark, no focus on current/tap-less). |
| Call sites | 5 production: `lib/features/deck/presentation/widgets/sections/deck_context_header_widget.dart`, `deck_study_header_widget.dart`, `lib/features/progress/presentation/screens/deck_progress_screen.dart` (+ `deck_algorithm_screen.dart`, `deck_level_screen.dart`) + gallery. Tap-less non-current segments exist (`deck_context_header_widget.dart:31-35`). |
| ForUI candidate APIs | `FBreadcrumb`, `FBreadcrumbItem`, `FBreadcrumbItem.collapsed` / `.collapsedTiles`, `FBreadcrumbStyleDelta`, `FTappable`. |
| Installed package version | forui 0.27.6 |
| Official documentation | https://forui.dev/docs/widgets/navigation/breadcrumb |
| Source evidence | `fu:breadcrumb.dart:57-70` `Row` of items with a divider icon (no scroll/flex), `:197-238` `_Crumb`: `onPress == null` -> `Semantics(selected: current ? true : null)` + text style + padding (not a button); else `FTappable(selected: current, onPress)` with `style.focusedOutlineStyle`, `tappableStyle` (motion none); `:496-552` `FBreadcrumbStyle` (`textStyle` variants, `iconStyle`, `padding`, `collapsedPadding`), `:528,531` padding touch 6x10 / 6; collapsed crumbs are popover menus (`FBreadcrumbItem.collapsed`, doc "recommended for desktops & web"). |
| API verification | PROBE `g3_nav_test.dart` P4c: `FBreadcrumb(style: .delta(padding: zero))` of five `FBreadcrumbItem`s with a `ConstrainedBox(min 48x48)` + `Center` child, inside `SingleChildScrollView(horizontal, reverse: true)`: no exception; ancestors with `onPress` are `isButton, isFocusable, actions=tap,focus`; a tap-less non-current item "Vocabulary" is a bare `label` node (not a button); the current item `isSelected`. |
| Native capability | The row of crumbs + dividers, crumb text variants (hover/press -> foreground, selected -> foreground), button semantics for tappable crumbs, selected semantics for the current level, theme focus outline, tappable style. |
| Capability gaps | No horizontal scroll, no fade, no reverse-open (wrapper stays, `MxScrollFade` stays); default crumb target is below 48 (fixable by the child constraint, `padding: zero`); tap-less ancestors are not buttons (the `Semantics(button: true)` wrapper stays); feedback is a text colour change, not the full-band `secondary` ground `MxRowInk` paints (visual change); divider spacing has no parameter (padding on the divider widget). |
| Current approach | Composition: `MxRowInk` (FTappable.static + hand press ground) per ancestor, a hand-built `Row` with `Icon(AppIcons.chevronRight)` dividers, `MxScrollFade`, reverse `SingleChildScrollView`. |
| Selected approach | Composition: `FBreadcrumb` + `FBreadcrumbItem` configured by one `FBreadcrumbStyleDelta` (text roles from `context.texts`, `iconStyle` border colour / `sizeIconInline`, `padding: zero`), inside the existing scroll + `MxScrollFade`; 48x48 via the item child; `Semantics(button: true)` kept for tap-less ancestors. |
| Why not a higher-level API? | `FBreadcrumbItem.collapsed` (the ForUI answer to long trails) is a popover menu for desktop and would change the interaction; scrolling/fading is outside FBreadcrumb. |
| Contract tests | Cover all points; will need edits: "ink roles" (read from `FBreadcrumbStyle.textStyle`), "chevron" (divider widget), "focus ring" (outline now from `FBreadcrumbStyle.focusedOutlineStyle`), plus a new case for the current level's `selected` semantics. |
| Migration status | CORRECTION NEEDED |
| Correction (if any) | Replace `_Segment` + the `Row`/chevron code by `FBreadcrumb(style: FBreadcrumbStyleDelta.delta(textStyle: <variants from context.texts>, iconStyle: IconThemeData(color: colors.border, size: sizeIconInline), padding: EdgeInsetsGeometryDelta.value(EdgeInsets.zero)), divider: Padding(horizontal space4, Icon(AppIcons.chevronRight)), children: [FBreadcrumbItem(current:, onPress:, child: ConstrainedBox(minWidth/minHeight sizeControl, Center(widthFactor: 1, Text)))])`. Goes away: `_Segment`, the `MxRowInk` dependency of this file, the chevron `Row` code (~35 lines). Risks: press feedback becomes a colour change (no `secondary` ground) and the current level announces "selected" (accepted improvement, to confirm); breadcrumb goldens change (golden-compare). Check degrade: 5 screens, `mx_scroll_fade_test.dart` "reversed horizontal scroll" unaffected. |

#### MxRouteName: `lib/shared/widgets/mx_route_name.dart`
| Field | Record |
|---|---|
| Existing contract | Semantics-only wrapper: `namesRoute: true` everywhere but iOS/macOS (read from ForUI's platform variant, overridable with `FTheme(platform:)`), optional `header: true`; one such node per route (documented rule). Pinned indirectly through `mx_app_bar_semantics_test.dart` (platform matrix incl. iOS/macOS, `routeNamingNodes`) and `mx_study_top_bar_test.dart` route-naming tests. |
| Call sites | 3 direct outside widgets: `lib/features/account/presentation/widgets/sections/code_form_widget.dart:103`, `sign_in_form_widget.dart:213`, `lib/features/account/presentation/screens/welcome_screen.dart:115`; plus `MxAppBar` and `MxStudyTopBar` (5 in `lib/shared/widgets`). |
| ForUI candidate APIs | `FPlatformVariant` / `context.platformVariant` (already used); `FHeader`, `showFDialog`/`FModalSheetRoute` (internal `namesRoute`). |
| Installed package version | forui 0.27.6 |
| Official documentation | https://forui.dev/docs/concepts/themes (platform variant); no ForUI route-naming API is documented. |
| Source evidence | `namesRoute: true` appears only inside `fu:dialog.dart:486` and `fu:sheet/sheet.dart:176` (private to those routes); `FHeader` adds none (`rg namesRoute fu:header` empty; PROBE P2a dump has only `isHeader`). |
| API verification | PROBE `g3_header_test.dart` P2a (no `namesRoute` from FHeader). Existing tests for the platform matrix. |
| Native capability | none for route naming; only the platform variant read is ForUI. |
| Capability gaps | n/a: no ForUI API exists. |
| Current approach | Fallback (justified, infrastructure): `Semantics(namesRoute, header)` + `context.platformVariant`. |
| Selected approach | Same. |
| Why not a higher-level API? | No public ForUI API sets `namesRoute` (above). |
| Contract tests | Indirect only. Missing: a direct unit test of the four combinations (`isHeader` x platform) and of the three account call sites (the account screens' route naming is untested at the widget level). |
| Migration status | MIGRATED |
| Correction (if any) | none. Optional: add `mx_route_name_test.dart`. |

#### MxScreenScroll (+ MxScrollClearance): `lib/shared/widgets/mx_screen_scroll.dart`
| Field | Record |
|---|---|
| Existing contract | The one scroll region of a screen: `ListView` with the screen margin at both sides and a tail clearance: base 24, `fab` 24+56+24, `fabAboveNav` 4+56+24, plus the bottom gesture inset. Pins `mx_screen_scroll_test.dart` (3: 16 gutter + base tail, FAB tail, FAB-above-nav tail) and `mx_app_shell_test.dart` "the gesture inset is added once". |
| Call sites | 96 outside widgets/gallery: `lib/features/transfer/presentation/screens/card_import_screen.dart`, `lib/features/starter_decks/presentation/screens/starter_library_screen.dart`, `lib/features/monitoring/presentation/widgets/sections/monitoring_server_list_widget.dart`. |
| ForUI candidate APIs | `FScaffold(childPad)`, `FItemGroup`/`FTileGroup` (scrolling groups), `FSidebar`. |
| Installed package version | forui 0.27.6 |
| Official documentation | https://forui.dev/docs/widgets/layout/scaffold |
| Source evidence | `FScaffoldStyle.childPadding` = `pagePadding.copyWith(top: 0, bottom: 0)` = horizontal **12** (`fu:scaffold.dart` inherit; `fu:../theme/style.dart:37`) and no tail/inset logic; ForUI has no page scroll container (`rg "class F\w*Scroll"` finds only calendar/select controllers); groups scroll their own items. |
| API verification | none needed (absence). |
| Native capability | none for a page scroll region. |
| Capability gaps | no scroll container; 12 dp vs the 16 screen margin; no clearance rule. |
| Current approach | Fallback (justified): Flutter `ListView` with padding from `context.screenMargin` / dimens. |
| Selected approach | Same. |
| Why not a higher-level API? | n/a: ForUI has no counterpart (evidence above). |
| Contract tests | Three tests cover the three clearances. Missing: RTL padding (uses `EdgeInsetsDirectional`, untested). |
| Migration status | MIGRATED |
| Correction (if any) | none. |

#### MxScrollFade (+ MxScrollFadeGround): `lib/shared/widgets/mx_scroll_fade.dart`
| Field | Record |
|---|---|
| Existing contract | Gradient over the end edge (vertical: bottom; horizontal: each edge with more content, in the scroll's own direction, reversed views fade the right side) while content lies past it; grounds page/raised/recessed; decorative (no pointer, no semantics); content that fits shows none. Pins `mx_scroll_fade_test.dart` (5). |
| Call sites | 10 production: `monitoring_filter_bar_widget.dart:47`, `card_list_toolbar_widget.dart:77`, `study_face_card_widget.dart:51`, `study_match_widget.dart:138`, `study_browse_widget.dart:302`, `study_guess_widget.dart:131`, 4 TOPIK widgets; plus `MxBreadcrumb`. |
| ForUI candidate APIs | none found (`FSelect` scroll handles are select-specific: `fu:select/content/scroll_handle.dart`). |
| Installed package version | forui 0.27.6 |
| Official documentation | n/a (no page). |
| Source evidence | `rg -l "FadeTransition|LinearGradient|ShaderMask" forui-0.27.6/lib/src` lists only `calendar/day/day_picker.dart`, `tooltip`, `sidebar/sidebar_item.dart`, `dialog`, `checkbox`, `label/label.dart`, `popover`, `context_menu` (transition/state fades, none is a scroll-edge fade over a scroll view); `select/content/scroll_handle.dart` is select-specific. |
| API verification | none needed (absence). |
| Native capability | none. |
| Capability gaps | n/a. |
| Current approach | Fallback (justified): `NotificationListener` + `Stack` + `LinearGradient` with colours from `context.colors`. |
| Selected approach | Same. |
| Why not a higher-level API? | n/a (no ForUI scroll-edge fade). |
| Contract tests | `mx_scroll_fade_test.dart` covers fit/horizontal/reversed/vertical/pointer-and-ground. |
| Migration status | MIGRATED |
| Correction (if any) | none. |

#### MxFooterBar: `lib/shared/widgets/mx_footer_bar.dart`
| Field | Record |
|---|---|
| Existing contract | In-flow commit bar, sibling of the scroll; page fill + hairline top border; padding 8 / 16 / 16+inset with the screen margin at the sides; owns the gesture inset; caption centred, muted, full-strength, hidden while the keyboard is up (also in a real shell and in a shell nested in a tab shell). Pins `mx_footer_bar_test.dart` (7). |
| Call sites | 16 outside widgets/gallery: `lib/features/transfer/presentation/widgets/sections/import_commit_bar_widget.dart`, `lib/features/transfer/presentation/screens/card_import_screen.dart`, `lib/features/monitoring/presentation/screens/monitoring_detail_screen.dart`. |
| ForUI candidate APIs | `FScaffold.footer` (+ `FScaffoldStyle.footerDecoration`), `FBottomNavigationBar` style. |
| Installed package version | forui 0.27.6 |
| Official documentation | https://forui.dev/docs/widgets/layout/scaffold |
| Source evidence | `fu:scaffold.dart:97-99` footer wrapped in `DecoratedBox(style.footerDecoration)` (1 px top border `colors.border`); `:251-257` footer positioned at the bottom edge, under the keyboard; no safe-area. |
| API verification | PROBE `g3_shell_test.dart` P1c (footer 720-800 under a 300 dp keyboard). |
| Native capability | A footer decoration (border) token only. |
| Capability gaps | Footer under the keyboard (P1c) breaks "commit bar stays above the keyboard"; no gesture-inset ownership; no caption logic. |
| Current approach | Fallback (justified): `DecoratedBox(background + top hairline)` + `Padding` + `Column(child, caption)` using `context.colors.border` and `context.hairline` (= `FStyle.borderWidth`). |
| Selected approach | Same. Observation: the border could read `FScaffoldStyle.footerDecoration`, the same token; not required. |
| Why not a higher-level API? | `FScaffold.footer` lands under the keyboard (P1c, `scaffold.dart:251-257`). |
| Contract tests | Cover padding, margins, hairline, caption, keyboard (incl. nested). |
| Migration status | MIGRATED |
| Correction (if any) | none. |

#### MxListRow: `lib/shared/widgets/mx_list_row.dart`
| Field | Record |
|---|---|
| Existing contract | Content row (decks, results, tags, targets): 56 with a title alone, 72 with subtitle or meta; one-line title (2 lines for user-named, `titleMaxLines`) and one-line subtitle with ellipsis so rows share a height; optional `titleMatch` highlight; optional leading (stable 56 column via `hasStableLeading`); trailing control keeps its own node and tap (RF3), a 48 trailing control does not grow the row; chevron xor trailing, subtitle xor meta (asserts); busy spinner replaces the end slot and blocks taps; disabled blocks taps on target **and** trailing, dims leading/title/end but not subtitle/meta (DEV-230); dividers belong to the list. Pins `mx_list_row_test.dart` (16: sizes, heights 56/72, one line, trailing node and tap, 48 trailing, chevron+spinner, disabled, DEV-230 subtitle + meta, asserts, title match x2, two-line user name, stable leading x3). |
| Call sites | 24 outside widgets/gallery: `lib/features/deck/presentation/widgets/items/deck_reorder_row_widget.dart`, `lib/features/transfer/presentation/widgets/sections/import_result_widget.dart`, `lib/features/account/presentation/widgets/items/user_row_widget.dart`. |
| ForUI candidate APIs | `FItem` (title/subtitle/details/prefix/suffix), `FItem.raw`, `FTile`, `FItemGroup`, `FTileGroup`, `FTappable`, `FItemStyleDelta`/`FItemContentStyleDelta`. |
| Installed package version | forui 0.27.6 |
| Official documentation | https://forui.dev/docs/widgets/data/item ; https://forui.dev/docs/widgets/data/item-group ; https://forui.dev/docs/widgets/tile/tile ; https://forui.dev/docs/widgets/foundation/tappable |
| Source evidence | `fu:item/item.dart:316-319` (data/enabled), `:344` static branch when all press callbacks are null, `:599-603` tappable style (no bounce, zero press delay, 25 ms exit), `:580-581` selected fill; `fu:item/item_content.dart:234,266-268` disabled variants for every slot, touch padding 12.5; `fu:item/item_content_layout.dart:154` `size = Size(maxWidth, height + padding)` (no min-height); item.dart FTappable args pass no `excludeSemantics`. |
| API verification | PROBE `g3_item_test.dart`: P3a heights 41 / 59 / 75; P3b disabled `FItem` leaves the suffix control tappable (inner taps 1); P3c enabled item = one merged button node `label="Row\n12 cards"` + the suffix button as its own node; P3d static selected item emits no selected/disabled flags; P3f disabled dims subtitle to alpha 0.5; P3g `minHeight: 56` around `FItem` throws a constraints assertion; P3h `FItem.raw` with a 56-tall child works. |
| Native capability | `FItem`: press/hover ground, focus outline, merged semantics, prefix/suffix/subtitle layout, disabled callbacks gating. |
| Capability gaps | 41/59 heights and no min height (P3a, P3g); inner controls stay live when disabled (P3b); subtitle/meta dim when disabled (P3f; configurable) and non-icon leading is not dimmed; static row loses selected/disabled semantics (P3d); `meta` slot (arbitrary widget in the sub-line, 2 gap) not representable by `subtitle`'s text defaults without custom layout; 48 trailing control grows the row (P3a "c": 75). |
| Current approach | Composition: `MxRowInk` (FTappable.static: ForUI press/hover ground, ForUI focus outline) + own `Row`/`Column`, `MxSpinner`. |
| Selected approach | Same (Composition on `MxRowInk`). |
| Why not a higher-level API? | `FItem`/`FTile` break the 56/72 heights, the no-growth trailing control, M3F-17 blocking and DEV-230 (P3a/P3b/P3f/P3g). `FItem.raw` would only replace `MxRowInk`'s frame (see MxRowInk record). |
| Contract tests | Cover every contract point listed (16, pass). |
| Migration status | MIGRATED |
| Correction (if any) | none (inherits the MxRowInk press-timing correction). |

#### MxSettingsRow: `lib/shared/widgets/mx_settings_row.dart`
| Field | Record |
|---|---|
| Existing contract | Setting row: 56 (label) / 72 (subtitle); 40 lead column with a 36 `MxIconTile` (tone via `iconTone`); label item-title role; chevron only when the row navigates and holds no control and is not an action; trailing xor `wideControl` (assert); trailing control beside the label until text scale 1.5, then under it; wide control on its own line 12 below, tile stays at the top; `message` under the row from the label's start; disabled dims tile/label/non-self-dimming trailing, not the subtitle, no double dim for `MxButton`/`MxToggle`/`MxStepper` (also under `Semantics`); 12/12 inset on the text column only so a 48 toggle does not grow the row. Pins `mx_settings_row_test.dart` (17). |
| Call sites | 34 outside widgets/gallery: `lib/features/transfer/presentation/widgets/sections/import_preview_section_widget.dart`, `import_mapping_section_widget.dart`, `lib/features/account/presentation/widgets/items/account_settings_row_widget.dart`. |
| ForUI candidate APIs | `FItem`, `FTile`, `FSelectTile`, `FSwitch` row patterns; same as MxListRow. |
| Installed package version | forui 0.27.6 |
| Official documentation | https://forui.dev/docs/widgets/data/item ; https://forui.dev/docs/widgets/tile/tile |
| Source evidence | as MxListRow; additionally a `Column`-under-label layout (`wideControl`, `message`, text-scale stacking) has no counterpart in `ItemContentLayout`'s fixed prefix/title/details/suffix slots (`fu:item/item_content_layout.dart:108-154`). |
| API verification | PROBE P3a-P3h as MxListRow. |
| Native capability | Press/focus/semantics frame as MxListRow. |
| Capability gaps | as MxListRow, plus wide control, message line and text-scale stacking. |
| Current approach | Composition: `MxRowInk` + own layout; hosts `MxToggle`/`MxButton`/`MxStepper`, `MxIconTile`. |
| Selected approach | Same. |
| Why not a higher-level API? | Same evidence as MxListRow; the extra slots need a custom layout (`FItem.raw` child) anyway. |
| Contract tests | 17 tests cover the contract; missing: RTL layout of the lead column/message indent. |
| Migration status | MIGRATED |
| Correction (if any) | none. |

#### MxActionSheetCommandRow: `lib/shared/widgets/mx_action_sheet_command_row.dart`
| Field | Record |
|---|---|
| Existing contract | One command in a bottom-sheet list: 30 tile (tinted primary, or error soft tint when destructive) in a 32 column with a 16 glyph, item-title verb (error ink when destructive: named in colour **and** words), optional 2-line subtitle (a consequence must not be cut), chevron only when it opens a surface; 56 / 72; one tap = one call; announced as one button; `isEnabled: false`: dimmed (whole row), announced disabled, no tap action (M3F-17). Pins `mx_action_sheet_command_row_test.dart` (8). |
| Call sites | 18 outside widgets/gallery in 6 files: `lib/features/deck/presentation/widgets/overlays/deck_action_sheet_widget.dart`, `lib/features/tags/presentation/widgets/overlays/tag_actions_sheet_widget.dart`, `lib/features/card/presentation/widgets/overlays/card_flag_sheet_widget.dart`. |
| ForUI candidate APIs | `FItem` (variant `FItemVariant.destructive`, prefix, subtitle, suffix), `FTile`, `FPopoverMenu`/`FItemGroup` menus. |
| Installed package version | forui 0.27.6 |
| Official documentation | https://forui.dev/docs/widgets/data/item ; https://forui.dev/docs/widgets/data/item-group |
| Source evidence | `fu:item/item.dart` `FItemStyles.inherit` destructive variant (`contentStyle` destructive; the raw variant keeps `colors.primary`, item.dart ~488-494 per CAT 660); heights as MxListRow. |
| API verification | PROBE P3a/P3g (heights, no min), P3f (disabled dims the subtitle too, which here is acceptable since the whole row dims). |
| Native capability | `FItem(variant: destructive, enabled: false)` gives destructive colours, whole-row dim and null callbacks. |
| Capability gaps | 56/72 heights (P3a, P3g: the 30/32 tile + 12 inset already needs a min-height frame); 2-line subtitle needs explicit `maxLines`; the 30 tile (tint over `MxTintBase`) is not an icon prefix. Disabled-announces-disabled and no tap are met by FItem; heights are not. |
| Current approach | Composition: `MxRowInk` + own tile/Row. |
| Selected approach | Same. |
| Why not a higher-level API? | Heights (P3a/P3g) and the tile; an `FItem` would also drop the 8 dp horizontal gutter contract (`space8`) set against the sheet's own gutter. |
| Contract tests | 8 tests cover the contract. Observation (not ForUI): the 30 tile duplicates `MxIconTile` small (28, tint, `radius sm`, 16 glyph, `MxIconTileTone.danger` exists); the 30 is pinned by "a 30 tile at the primary tint", so a swap is an owner/contract call for the MxIconTile record. |
| Migration status | MIGRATED |
| Correction (if any) | none. |

#### MxRowInk: `lib/shared/widgets/mx_row_ink.dart`
| Field | Record |
|---|---|
| Existing contract | The tappable-row layer (ruling S13, plan phase 5): ForUI press/hover ground across the row, ForUI focus outline, dim when disabled (`shouldDimWhenDisabled`); no `onTap` = static (no tappable, not focusable); `isEnabled: false` blocks every pointer incl. controls inside and says disabled while the nodes stay in the tree (M3F-17); `isSelected` on the row's one node in enabled, disabled and static modes (M3F-10); `onLongPress` on the target and in the node (SW-REV-005); `borderRadius` shapes ground and outline; the caller's child keeps its place in the tree across enabled/blocked/dimmed/static (GlobalKeys). Pins `mx_row_ink_test.dart` (12 incl. loops: static, radius, tappable + focus ring, disabled, M3F-17 x3, long-press, M3F-10 x3+). |
| Call sites | 7 direct production uses (`import_source_option_widget.dart:30`, `deck_due_strip_widget.dart:29`, `theme_choice_card_widget.dart:98`, `card_add_details_widget.dart:27`, `card_bulk_bar_widget.dart:38`, `topik_question_bar_chart_widget.dart:142`, `topik_question_grid_sheet_widget.dart:137`) + 7 shared widgets (`MxListRow`, `MxSettingsRow`, `MxActionSheetCommandRow`, `MxSelectableCardRow`, `MxBreadcrumb`, `mx_option_row.dart:53`, `mx_stepper.dart:256`). |
| ForUI candidate APIs | `FTappable.static` (used), `FTappable`, `FTappableStyleDelta`, `FFocusedOutline`, `FItem.raw`, `FItemStyleDelta`. |
| Installed package version | forui 0.27.6 |
| Official documentation | https://forui.dev/docs/widgets/foundation/tappable ; https://forui.dev/docs/widgets/foundation/focused-outline ; https://forui.dev/docs/widgets/data/item |
| Source evidence | `fu:../foundation/tappable/tappable.dart:1067-1070` default `FTappableStyle` `pressedEnterDuration` **100 ms**, `pressedExitDuration` 100 ms (`:876` `Future.delayed(_style.pressedEnterDuration)` before the pressed variant); `fu:item/item.dart:599-603` the item style sets enter `.zero`, exit 25 ms, `motion: none`; `item.dart:344` static branch; `item.dart:580-581` selected fill. `mx_row_ink.dart:102-117` passes no `style:`, so it takes the 100 ms defaults. |
| API verification | PROBE `g3_tappable_test.dart` P5: after 16 ms of press, default `FTappable.static` has `pressed=false`, with `FTappableStyleDelta.delta(pressedEnterDuration: Duration.zero, pressedExitDuration: 25 ms)` it has `pressed=true`. FItem.raw probe: `g3_item_test.dart` P3d/P3e/P3h. |
| Native capability | `FTappable.static`: semantics (button/container/selected), keyboard, hover/pressed/focused variants, outline; `FItem.raw`: the same plus a themed ground and a static path. |
| Capability gaps | `FTappable` paints nothing (so the ground is drawn by `MxRowInk`, from `colors.secondary` like `FItem`'s `contentDecoration`); `FItem.raw` (the higher level) would add the 4 dp outer margin, a `RoundedSuperellipse` md shape, a selected fill that clashes with callers' own selected looks (`topik_question_grid_sheet_widget.dart:139`), a static path without semantics (P3d), and still need IgnorePointer, Opacity and the GlobalKey wrappers: zero net removal. |
| Current approach | Foundation: `FTappable.static` + `DecoratedBox` ground + `FFocusedOutlineStyleDelta` + `IgnorePointer`/`Opacity`/`GlobalKey`s + own static `Semantics`. |
| Selected approach | Foundation (`FTappable.static`), with the item's press timing. |
| Why not a higher-level API? | `FItem.raw` evaluated: its selected fill, margin/shape model and semantics-less static branch need cancelling, and the blocking/dim/key layers stay (P3d, `item.dart:344,580`). `FItem`/`FTile` fail as in MxListRow. |
| Contract tests | `mx_row_ink_test.dart` covers static, radius, focus ring, disabled, M3F-17/M3F-10, long-press. Missing: nothing pins when the pressed ground appears. |
| Migration status | CORRECTION NEEDED |
| Correction (if any) | Pass `style: FTappableStyleDelta.delta(pressedEnterDuration: Duration.zero, pressedExitDuration: const Duration(milliseconds: 25))` to `FTappable.static` (verified fields `tappable.design.dart:194-199`), matching ForUI's own item press layer (`item.dart:599-603`), which the file's comment already claims to mirror. 1 line; affects all rows and 14 call sites (press ground appears at once instead of after 100 ms). Add a test: after `startGesture` + one frame, the ground is `colors.secondary`. Also update the file comment. |

#### MxSelectableCardRow: `lib/shared/widgets/mx_selectable_card_row.dart`
| Field | Record |
|---|---|
| Existing contract | List item as a raised card: tap opens (or toggles while selecting), long-press starts selection (BR-CARD-020), checkbox leads while selecting (ticked when selected, centred with the trailing control), 16 in / 12 down, one TalkBack node with the checked state, optional `semanticLabel` replacing the content and keeping tap + long-press on that node (SW-REV-005); `trailing` (e.g. a ⋮) outside the ink, 4 from the edge, keeps its own node and tap; disabled dims the card and blocks target, long-press and trailing (BR-TRASH-011, M3F-17); `isSelected` requires `isSelecting` (assert); 48 targets. Pins `mx_selectable_card_row_test.dart` (7). |
| Call sites | 3 production: `lib/features/deck/presentation/widgets/items/deck_row_widget.dart`, `lib/features/trash/presentation/widgets/items/trash_entry_row_widget.dart`, `lib/features/card/presentation/widgets/items/card_row_widget.dart` (+ gallery). |
| ForUI candidate APIs | `FTile`, `FSelectTile`/`FSelectTileGroup`, `FCard` (via `MxCard`), `FCheckbox` (via `MxSelectionCheckbox`). |
| Installed package version | forui 0.27.6 |
| Official documentation | https://forui.dev/docs/widgets/tile/tile ; https://forui.dev/docs/widgets/tile/select-tile-group |
| Source evidence | `fu:tile/tile.dart:104,193,219` only `semanticsExpanded` (no `semanticsChecked`/`semanticsButton`); `FSelectTile` uses `selected` + a check icon, value type `Set<T>` and requires an `FSelectTileGroup` ancestor (CAT 722-729); `FItem` passes no `excludeSemantics` (item.dart FTappable args). |
| API verification | none needed beyond the cited signatures (absence of parameters). |
| Native capability | Tile card look, press ground, selected flag. |
| Capability gaps | No `checked` semantics, no semantics-label substitution, no long-press-into-selection model with a lead checkbox, trailing control must sit outside the tappable (a tile puts `suffix` inside), selection model is a form field. |
| Current approach | Composition: `MxCard` (FCard) + `MxRowInk` + `MxSelectionCheckbox` (FCheckbox) + explicit `Semantics`. |
| Selected approach | Same. |
| Why not a higher-level API? | Gaps above (semantics and trailing placement are pinned contracts). |
| Contract tests | Cover tap/long-press, checkbox, one-node semantics with and without label, disabled/M3F-17 x2, 48 targets. |
| Migration status | MIGRATED |
| Correction (if any) | none. |

#### MxListSectionHeader: `lib/shared/widgets/mx_list_section_header.dart`
| Field | Record |
|---|---|
| Existing contract | Uppercase meta-role overline that reads the original label, announced as a heading; padding 0 4 8 (2 above after a filter band); one optional trailing affordance at the end, moves under the label when it does not fit. Pins `mx_list_section_header_test.dart` (6). |
| Call sites | 34 outside widgets/gallery in 30 files: `lib/features/progress/presentation/widgets/sections/progress_level_list_widget.dart`, `lib/features/transfer/presentation/widgets/sections/import_preview_section_widget.dart`, `import_source_section_widget.dart`. |
| ForUI candidate APIs | `FLabel`, `FTileGroup(label)`, `FSidebarGroup(label, action)`, `FAccordion`. |
| Installed package version | forui 0.27.6 |
| Official documentation | https://forui.dev/docs/widgets/tile/tile-group ; https://forui.dev/docs/widgets/navigation/sidebar |
| Source evidence | `fu:tile/tile_group.dart:348-356` label only as `FLabel` around a group; `fu:sidebar/sidebar_group.dart:75-120` header `Row(label, action)` with no `Semantics`/heading, wraps the group's children and uses sidebar paddings; `FLabel` merges its label into the child's semantics (CAT 624). |
| API verification | none needed. |
| Native capability | Labels exist only attached to a group/form field. |
| Capability gaps | No standalone heading widget; no uppercase/`semanticsLabel`; no overflow-to-next-line trailing; none sets `header: true` (rg `Semantics` in `sidebar_group.dart` is empty). |
| Current approach | Fallback (justified): `Padding` + `OverflowBar` + `Semantics(header: true)` + `Text(meta)`. |
| Selected approach | Same. |
| Why not a higher-level API? | n/a: no ForUI standalone section header (evidence above). |
| Contract tests | Cover role, heading (x2), padding, trailing, overflow. |
| Migration status | MIGRATED |
| Correction (if any) | none. |

#### MxDividedColumn: `lib/shared/widgets/mx_divided_column.dart`
| Field | Record |
|---|---|
| Existing contract | n rows with n - 1 hairlines between, none after the last (also `MxDividedColumn.divided(rows)` for lazy lists, rows still built on demand); the line is ForUI's `FDivider` in the palette `border` colour, 1 tall (style width), inset 16 at each end. Pins `mx_divided_column_test.dart` (4: n-1 hairlines, FDivider + colour + inset 16/16, one child none, lazy lists). |
| Call sites | 27 outside widgets/gallery: `lib/features/starter_decks/presentation/widgets/overlays/starter_algorithm_sheet_widget.dart`, `lib/features/transfer/presentation/widgets/overlays/card_export_sheet_widget.dart`, `import_option_sheet_widget.dart`; plus `MxSection`. |
| ForUI candidate APIs | `FDivider` (used), `FItemGroup`/`FTileGroup` (divider `full`/`indented`), `FItemDivider`. |
| Installed package version | forui 0.27.6 |
| Official documentation | https://forui.dev/docs/widgets/layout/divider ; https://forui.dev/docs/widgets/data/item-group |
| Source evidence | `fu:divider.dart:48-61` `FDivider` = `Container(margin: style.padding, color: style.color, height: style.width)`, default colour `colors.secondary`, default 16 vertical margin; `fu:item/item_group.dart:241` children typed `List<FItemMixin>`; `fu:item/item_data.dart` `FItemDivider.indented` doc (from the title's left edge to the right edge). |
| API verification | `mx_divided_column_test.dart` (passes). No probe needed. |
| Native capability | `FDivider` + `FDividerStyleDelta.delta(color, padding)`: exact hairline and inset. |
| Capability gaps | `FItemGroup` dividers: wrong geometry (`indented` is start-edge only) and a closed child type. |
| Current approach | Native widget with style delta (`FDivider` + `FDividerStyleDelta`), in a `Column`. |
| Selected approach | Same. Observation: the colour override (`border` instead of the fainter `secondary` default) is a theme matter; the shared owner would be `FThemeData.dividerStyles` in `lib/core/theme/` (outside this set; `FDivider` has this one consumer: `rg FDivider lib` = `mx_divided_column.dart` only), so the local delta is equivalent today. |
| Why not a higher-level API? | `FItemGroup`/`FTileGroup` (gaps above). |
| Contract tests | Cover the contract. |
| Migration status | MIGRATED |
| Correction (if any) | none. |

#### MxSection: `lib/shared/widgets/mx_section.dart`
| Field | Record |
|---|---|
| Existing contract | Overline (optional) + full-bleed card of rows with ghost dividers + optional note (hint `MxNote`, 8 below the card, inset 4); keeps its own 16 below (ruling S9, row 35 of the §9 register). Pins `mx_section_test.dart` (5). |
| Call sites | 36 outside widgets/gallery in 24 files: `lib/features/settings/presentation/widgets/sections/sync_status_section_widget.dart`, `settings_speech_section_widget.dart`, `study_options_form_widget.dart`. |
| ForUI candidate APIs | `FTileGroup(label, description, children)`, `FItemGroup`, `FCard`, `FLabel`. |
| Installed package version | forui 0.27.6 |
| Official documentation | https://forui.dev/docs/widgets/tile/tile-group ; https://forui.dev/docs/widgets/data/card |
| Source evidence | `fu:tile/tile_group.dart:161` children `List<FTileMixin>`; `:319-323` shrink-wrapped `CustomScrollView` per root group; `:348` `FLabel(layout: vertical, label, description, error)`; `fu:item/item_data.dart` indented divider. |
| API verification | none needed (type signatures). |
| Native capability | `FTileGroup` is the ForUI equivalent of "labelled bordered group of rows with dividers and a description". |
| Capability gaps | children must be `FTile`s (the rows here are `MxSettingsRow`/`MxListRow` with toggles, steppers, messages, wide controls); nested scroll view in a page `ListView`; label is `FLabel` typography without heading semantics or a trailing slot; indented divider geometry differs from the 16/16 inset. |
| Current approach | Composition: `MxListSectionHeader` + `MxCard` (`FCard`) + `MxDividedColumn` (`FDivider`) + `MxNote`. |
| Selected approach | Same. |
| Why not a higher-level API? | `FTileGroup` gaps above (closed child type is the decisive one). |
| Contract tests | Cover structure, spacing, dividers, note. |
| Migration status | MIGRATED |
| Correction (if any) | none. |

#### MxTwoColumns: `lib/shared/widgets/mx_two_columns.dart`
| Field | Record |
|---|---|
| Existing contract | One column (gap 16) below a 672 content width or with no `end` blocks, otherwise two equal columns with a `space24` gap; chooses by the width **it is given** (content area, rail already taken off), not the window class. Pins `mx_two_columns_test.dart` (3). |
| Call sites | 2: `lib/features/progress/presentation/screens/progress_screen.dart:78`, `lib/features/study/presentation/screens/study_home_screen.dart:114`. |
| ForUI candidate APIs | `FBreakpoints` (`context.theme.breakpoints`), `FResizable`, `FScaffold.sidebar`. |
| Installed package version | forui 0.27.6 |
| Official documentation | https://forui.dev/docs/concepts/responsive |
| Source evidence | CAT 163/236: `FBreakpoints` are window-width thresholds 640/768/1024/1280/1536 read through the theme and used by the library only in `FDialog.adaptive` (`fu:dialog.dart:342-353`); no layout widget. `FResizable` is a draggable splitter, not a responsive layout (CAT 587-598). |
| API verification | none needed. |
| Native capability | none (a threshold table at most). |
| Capability gaps | thresholds are window-based and not 672; no two-column widget. |
| Current approach | Fallback (justified): `LayoutBuilder` + `Column`/`Row`. |
| Selected approach | Same. |
| Why not a higher-level API? | n/a (no ForUI layout widget; breakpoints are the wrong measure). |
| Contract tests | Cover the three modes. Missing: RTL order. |
| Migration status | MIGRATED |
| Correction (if any) | none. |

---

### Summary table

| Component | Current | Selected | Status |
|---|---|---|---|
| MxAppShell | Fallback (Material Scaffold host) | Fallback + `AnnotatedRegion` from `FColors.systemOverlayStyle` | CORRECTION NEEDED (small) |
| MxAppBar | Fallback (Flutter layout; `MxIconButton`, `MxRouteName`) | Fallback (FHeader rejected: P2a/P2b/P2d/P2f) | MIGRATED |
| MxStudyTopBar | Composition + custom chip + custom track | Composition on `MxToneBadge` and the shared progress track | CORRECTION NEEDED |
| MxBottomNav | Native (`FBottomNavigationBar`) | Native | MIGRATED |
| MxNavRail | Composition (`FBottomNavigationBarItem`) + hand frame | Composition + `FSidebar.raw` frame | CORRECTION NEEDED (low) |
| MxBreadcrumb | Composition via `MxRowInk` + hand Row | `FBreadcrumb`/`FBreadcrumbItem` in the scroll+fade wrapper | CORRECTION NEEDED |
| MxRouteName | Fallback (Semantics + platform variant) | Fallback | MIGRATED |
| MxScreenScroll | Fallback (`ListView`) | Fallback | MIGRATED |
| MxScrollFade | Fallback | Fallback | MIGRATED |
| MxFooterBar | Fallback | Fallback | MIGRATED |
| MxListRow | Composition via `MxRowInk` | Composition via `MxRowInk` | MIGRATED |
| MxSettingsRow | Composition via `MxRowInk` | Composition via `MxRowInk` | MIGRATED |
| MxActionSheetCommandRow | Composition via `MxRowInk` | Composition via `MxRowInk` | MIGRATED |
| MxRowInk | Foundation (`FTappable.static`) | Foundation with the item press timing | CORRECTION NEEDED |
| MxSelectableCardRow | Composition (`FCard`, `FCheckbox`, `MxRowInk`) | Same | MIGRATED |
| MxListSectionHeader | Fallback | Fallback | MIGRATED |
| MxDividedColumn | Native widget with style delta (`FDivider`) | Same | MIGRATED |
| MxSection | Composition | Composition | MIGRATED |
| MxTwoColumns | Fallback | Fallback | MIGRATED |

Counts: MIGRATED 14, CORRECTION NEEDED 5, BLOCKED 0 (19 components). One correction needs an owner decision before
code: the primary-fill form of the shared progress track (MxStudyTopBar item 2).

### Corrections ordered by value (contract-preserving first, most custom code removed first)

1. **MxStudyTopBar: reuse the shared pill (`MxToneBadge`) and the shared progress track** (removes ~45 lines of duplicated
   shared widgets; tests that must keep passing: 40% cap, upper-case + `semanticsLabel`, route naming, 200 ms fill, track
   height). Part (2) of it (primary-fill `MxLinearProgress`, and that widget moving to `FDeterminateProgress`, first-build
   sweep from 0 per P6) needs an owner decision (`AskUserQuestion`, new shared API). Study goldens change.
2. **MxBreadcrumb to `FBreadcrumb`/`FBreadcrumbItem`** (removes `_Segment`, the chevron `Row`, the `MxRowInk` use, ~35 lines;
   keeps 48x48 targets, scroll, fade, tap-less `Semantics(button)`). Visual change: press feedback is a text colour change,
   current level announces "selected". Breadcrumb goldens change.
3. **MxNavRail frame from `FSidebar.raw`** (removes the hand-built `DecoratedBox`/border, ~8 lines; low value, optional).
4. **MxRowInk press timing = ForUI's item style** (1 line; all tappable rows and 14 call sites get an immediate pressed
   ground; P5 shows the 100 ms lag today). Add a pressed-ground test.
5. **MxAppShell applies `FColors.systemOverlayStyle`** (adds one `AnnotatedRegion`; the palette values exist and nothing consumes
   them; UNVERIFIED on a device; add a widget test).

Not corrections (recorded observations): `MxDividedColumn` colour could move to `FThemeData.dividerStyles`;
`MxFooterBar`/`MxNavRail`/`_AppBarGround` hand-draw hairlines that ForUI also exposes as `FScaffoldStyle.footerDecoration`,
`FSidebarStyle.decoration`, `FHeaderStyle.decoration`; `MxActionSheetCommandRow`'s 30 tile overlaps `MxIconTile.small` (28,
pinned as 30 by test); missing tests: `MxBottomNav` re-tap, `MxRouteName` unit test, RTL for `MxScreenScroll`/`MxSettingsRow`/`MxTwoColumns`.

## ForUI research ledger, group G4: data and feedback surfaces

Scope: 17 files in `lib/shared/widgets/` (list in the brief). Repo `/home/user/memox-v8`, forui 0.27.6.
Nothing in the MemoX repo was edited. Probes live only in
`.../scratchpad/ledger_probe/test/g4_probe_test.dart` and `g4_probe2_test.dart` (marked PROBE below).

Conventions
- `PKG` = `forui-0.27.6/lib/src/`. Citations are `PKG<path>:<line>`, each line re-checked with `rg -n` against the installed source.
- `DOCS` = `https://forui.dev/docs/`. Catalog = `docs/forui-migration/FORUI_API_CATALOG.md`.
- Tests run: `MEMOX_TEST_BUNDLES=0 bash .claude/skills/flutter-workflow/scripts/run_tests.sh` on the 17 `test/shared/widgets/mx_*_test.dart` files of this group: **129 tests, 17 suites, all passed** (log `.../scratchpad/g4_tests.log`). No golden was run.
- Call-site counts are files / occurrences of the constructor under `lib/` outside the component's own file; they include `lib/app/gallery/*`.

### 0. The six specific questions, settled

**(a) MxInlineBanner / MxNote vs FAlert.**
- FAlert variants: only `primary` and `destructive` (`PKG widgets/alert.dart:164-205`, `@Variants` header at `:11`); no warning variant. A warning tone is reachable only by a style delta that recolours decoration/icon/title (`FAlertStyleDelta.delta(decoration, iconStyle, titleTextStyle, subtitleTextStyle, padding)`, `PKG widgets/alert.design.dart:183-189`). The banner's tint is `role.tintOver(MxTintBase.of(context))`, which is computable at build time and so deliverable through `DecorationDelta.shapeDelta(color:, shape: ...)` (`PKG theme/delta/decoration.dart:71`).
- Action slot: none. `FAlert` has `title`, `subtitle`, `icon` only (`PKG widgets/alert.dart:87-97`). Compact buttons can only ride inside the `subtitle` widget, which is laid out in a second Row indented by `iconStyle.size` plus `left: 10` (`alert.dart:121-126`).
- Live region: `Semantics(container: true, liveRegion: liveRegion, ...)`, default `true` (`alert.dart:57, 91, 101-103`). Compatible with the banner (`Semantics(liveRegion: true)`, pinned by `mx_inline_banner_test` "actions sit 8 under the message...; a live region"). For MxNote (static info, no live region today) it would need `liveRegion: false`.
- Layout, **PROBE `g4_probe_test.dart`** (FAlert with `padding` 16x12 delta, 16dp icon, message wrapping to many lines, 328dp wide): the icon's top was 112 against a text block 12..228, i.e. **vertically centred on the whole text, not on the first line**; the text started at x=42 (icon right edge 32 + 10). Source cause: the title Row has no `crossAxisAlignment` (default centre, `alert.dart:109-111`) and the gap is the literal `padding: const .only(left: 10)` (`alert.dart:114`, again `:126`); neither is a style field (`FAlertStyleDelta` has no gap or alignment, `alert.design.dart:183-189`).
- Contract those two facts break: `mx_inline_banner_test` "padding 12 16..." pins the message at `Offset(40, 12)` (36,8 in a commit bar) = 8dp gap; `mx_note_test` "the glyph centres on the first line" and "padding 10 12" (`Offset(37, 11)`). The banner's doc comment says "It wraps and never truncates", so multi-line is the normal case.
- Verdict: FAlert is not a drop-in for either widget under the present contract. Not an owner ruling (no DESIGN.md / handoff text rules on glyph alignment or the 8dp gap; searched `rg "first line"`), so it is the owner's call whether to relax (see records).

**(b) MxLinearProgress vs FDeterminateProgress.** A fit with deltas; two behaviour differences, one verified by PROBE.
- Value API: `FDeterminateProgress({required double value, ...})`, `assert(0.0 <= value && value <= 1.0)` (`PKG widgets/progresses/determinate_progress.dart:50`) = MxLinearProgress's own assert.
- Height/colour: `FDeterminateProgressStyleDelta.delta(trackDecoration:, fillDecoration:, constraints:, motion:)` (`determinate_progress.design.dart:90-95`); default `tightFor(height: 6.0)` (`determinate_progress.dart:143`). PROBE: `constraints: tightFor(height: 4)` gave `Size(328, 4)`; colours are build-time deltas, so the by-value `MasteryRamp.fill` colour is passable.
- Motion: default 1s linear (`:171-174`); delta `motion: FDeterminateProgressMotionDelta.delta(duration:, curve:)` (`design.dart:184`). PROBE: with `Durations.short4` + `Easing.standard` the factor read 0.5 after 200 ms (= MxLinearProgress's easing).
- Reduced motion: `_setup` sets `_controller.value = widget.value` when `context.accessibility.motion == disabled`, else `animateTo` (`:96-99`); `disabled` is derived from the platform flag `features.disableAnimations` (`PKG foundation/accessibility.dart:119-125`). PROBE: with `accessibilityFeaturesTestValue(disableAnimations: true)` the factor is the value at once and after an update; with only `MediaQuery(disableAnimations: true)` ForUI did not react (factor 0.0 on the first frame). In production both flags come from the same platform flag; in tests the contract test must set `accessibilityFeaturesTestValue` (as `mx_dialog_test.dart:191` does).
- Semantics: ForUI always emits `label "Loading"` + percent `value` (`:115-117`; PROBE: 1 node with label "Loading"). MxLinearProgress is decorative (`ExcludeSemantics`); PROBE: wrapping in `ExcludeSemantics` leaves 0 such nodes.
- Differences: (1) **First mount**: ForUI's controller starts at 0 and animates up (PROBE: widthFactor 0.0 at the first frame for value 0.5), whereas MemoX's `TweenAnimationBuilder(tween: Tween(end: value))` draws the value at once (PROBE: 0.5 on the first frame). (2) **Fill shape**: ForUI's default fill is a pill `RoundedSuperellipseBorder` (`:156-160`), MemoX draws a square fill clipped by the track. (3) The mastery "keep one track-height in from each end" rule is not in ForUI, but PROBE confirms it composes: `LayoutBuilder` + the existing `_factor` passed as `value` gave 0.02 (= 4/200) for 0.0001.
- Track/fill colours by delta: yes (`DecorationDelta.shapeDelta(color:)`).

**(c) MxSkeleton, any ForUI skeleton?** No. `rg -il "skeleton|shimmer"` over the whole installed package returns nothing, `lib/widgets/*.dart` has no such export, and the docs tree (`.../forui-src/docs/content/docs/widgets/*`) has no skeleton page. The only ForUI loading widgets are `FCircularProgress` (indeterminate spinner), `FProgress` (indeterminate bar), `FDeterminateProgress` (`lib/widgets/progress.dart:11-13`), none of which is a placeholder shape.

**(d) MxCard.** Confirmed: it is `FCard(clipBehavior: Clip.antiAlias, style: FCardStyleDelta.delta(decoration: DecorationDelta.shapeDelta(color:, shape:)))`. `FCardStyleDelta.delta({decoration, titleTextStyle, subtitleTextStyle, padding})` is the documented path (`PKG widgets/card.design.dart:90-95`; `card.dart:33` doc "style: .delta(...)"), `DecorationDelta.shapeDelta({color, image, gradient, shadows, shape})` exists (`PKG theme/delta/decoration.dart:71`) and applies to the card's `ShapeDecoration` (`card.dart:134-139`). Supported way: yes. `clipBehavior` clips to the decoration's inner path (`card.dart:85-99`).

**(e) MxMasteryDonut / MxStackedDayBars.** No ForUI chart, donut or ring. The only circular progress, `FCircularProgress`, has no value: its fields are `size, style, semanticsLabel, icon` (`PKG widgets/progresses/circular_progress.dart:42-72`; `rg value` finds only the animation controller). `FDeterminateProgress` is linear. No bar chart or legend widget exists in `lib/widgets/*.dart` (listing in the section "Widget list checked" below).

**(f) MxEmptyState / MxErrorState.** No ForUI equivalent. `lib/widgets/*.dart` has no empty-state, error-state, placeholder or result widget; `FAlert` is the nearest "feedback" widget but is a one-row callout without actions (see (a)). Both are already compositions over `MxCard` (FCard), `MxButton` (FButton) and `MxNote`.

Widget list checked (`ls forui-0.27.6/lib/widgets`): accordion alert autocomplete avatar badge bottom_navigation_bar breadcrumb button calendar card checkbox context_menu date_field date_time_picker dialog divider header item label line_calendar otp_field pagination picker popover popover_menu progress radio resizable scaffold select select_group select_menu_tile select_tile_group sheet sidebar slider switch tabs text_field tile time_field time_picker toast tooltip.

---

### 1. Records

#### MxCard — `lib/shared/widgets/mx_card.dart`
| Field | Record |
|---|---|
| Existing contract | Non-interactive surface. Default ground `colors.card`, hairline `colors.border`, radius `lg`, padding 24 (16 `isCompact`, 0 `isFullBleed`), content clipped to the radius. At most one of hero/warning/success/danger/recessed (assert). `isSelected` = primary edge at 2x hairline. Sets `MxTintBase` to the ground it paints. Pinned by `mx_card_test.dart` (7 tests x light/dark): "ForUI's card ground, large radius and hairline edge, padding, no shadow", "hero: the accent tint over the page surface", "warning, success and danger cards tint...", "recessed: the muted ground, flat...", "selected: a primary control-weight edge", "full bleed: no padding, clipped, a tappable row works on the card", "a card takes one tone at most". |
| Call sites | 59 files / 73 uses. `lib/features/transfer/presentation/widgets/items/import_source_option_widget.dart`, `lib/features/transfer/presentation/screens/card_import_screen.dart`, `lib/shared/widgets/mx_empty_state.dart` |
| ForUI candidate APIs | `FCard`, `FCardStyleDelta.delta`, `DecorationDelta.shapeDelta`, `FCardStyle.padding` (builder layouts only) |
| Installed package version | forui 0.27.6 |
| Official documentation | `https://forui.dev/docs/widgets/data/card` |
| Source evidence | `PKG widgets/card.dart:84-99` (DecoratedBox + optional InnerPathClipper); `:134-139` (default ShapeDecoration: RoundedSuperellipseBorder, side border, radius lg, colour card); `card.design.dart:90-95` (delta signature); `theme/delta/decoration.dart:71` (`shapeDelta`) |
| API verification | none needed (tests above exercise the real FCard; `mx_card_test` reads the resulting `ShapeDecoration`) |
| Native capability | Ground colour, radius, border, clipping to the radius, theme inheritance of the card style. |
| Capability gaps | FCard applies no padding (`card.dart:84-99`; `FCardStyle.padding` is read only by a `builder`), so the 24/16/0 padding is MemoX's own `Padding`. A tone-specific `isSelected` edge needs a full replacement `ShapeBorder` (shapeDelta takes `ShapeBorder? shape`, not a border-side delta). |
| Current approach | **Composition**: `FCard` + `FCardStyleDelta.delta(decoration: DecorationDelta.shapeDelta(color:, shape: RoundedSuperellipseBorder(radius lg, side: edge)))` + `MxTintBase` + `Padding`. |
| Selected approach | Composition (same). |
| Why not a higher-level API? | n/a (FCard is the native widget; the delta is the supported customisation). |
| Contract tests | `mx_card_test.dart` covers colour, radius, edge, tones, selected, full bleed, assert. **Missing:** `isCompact` padding (space16) has no test (`rg isCompact test/shared/widgets/mx_card_test.dart` finds nothing). |
| Migration status | MIGRATED |
| Correction (if any) | None required. Optional, low value: for a non-selected card the delta restates ForUI's own radius and border (`mx_card.dart:97-104` vs `card.dart:134-139`); passing only `shapeDelta(color: ground)` unless `isSelected` would let the card follow the theme's radius/border by inheritance. Contract tests still pass (they read the same values). Add a test for `isCompact`. |

#### MxTintBase — `lib/shared/widgets/mx_tint_base.dart`
| Field | Record |
|---|---|
| Existing contract | `InheritedWidget` giving the ground that `role.tintOver(...)` is laid over; `of` falls back to `colors.background`; `stepOf` gives one tonal step (muted, or border on a muted/other ground). `updateShouldNotify` on colour change. Pinned by `mx_tint_base_test.dart` (4 tests): "on the page a tint is over the page", "inside a card a tint is over the card", "inside a tinted card a tint is over that tint", "inside a $name a tint is over its ground" (dialog/sheet, both brightnesses). |
| Call sites | 13 files / 14 references (`MxCard`, `MxDialog` mx_dialog.dart:126, `MxBottomSheet` mx_bottom_sheet.dart:116, `topik_group_pane_widget.dart:57`). |
| ForUI candidate APIs | None. Inherited widgets ForUI exposes: `InheritedAccordionData`, slider `InheritedData/Controller/Variants`, resizable `InheritedData`, `FInheritedItemCallbacks/Data`, `_InheritedTheme` (`rg "class .*Inherited\w+ extends Inherited" PKG`). `rg -i "tint|surface|ground" PKG` hits only toast/colour/typography files, not an ancestor-ground concept. |
| Installed package version | forui 0.27.6 |
| Official documentation | `https://forui.dev/docs/concepts/themes` (theme is global, no per-subtree surface) |
| Source evidence | `PKG theme/theme.dart:358` (the only theme inherited widget) |
| API verification | none needed |
| Native capability | none |
| Capability gaps | ForUI has no "ground under me" notion; its colours are global tokens. |
| Current approach | **Fallback** (pure InheritedWidget, infrastructure). |
| Selected approach | Fallback (infrastructure; the tint rule is a MemoX design rule, DESIGN.md "Tints"). |
| Why not a higher-level API? | No ForUI API carries a subtree-relative surface colour (above). |
| Contract tests | `mx_tint_base_test.dart`: sufficient for `of`; `stepOf` is exercised through `mx_skeleton_test` ("one step off the ground"). |
| Migration status | MIGRATED |
| Correction (if any) | None. |

#### MxInlineBanner — `lib/shared/widgets/mx_inline_banner.dart`
| Field | Record |
|---|---|
| Existing contract | Tones warning/danger only (owner: "`MxInlineBanner` has no info tone", `24-daily-reminder.md:68`). Tinted ground over `MxTintBase`, **no border** (tone is not carried by an edge), radius `sm`, glyph 16dp coloured by tone, optional bold title in tone ink + neutral message, compact `MxButton` actions under the message (ruling O6 / §9 row 50, `10-card-detail.md:44`), padding 12x16 (8x12 and no bottom margin in a commit bar), 16 below unless `hasBottomMargin: false` (L3), wraps and never truncates, glyph centred on the first line at any text scale, `Semantics(liveRegion: true)`. Pinned by `mx_inline_banner_test.dart` (7 tests): "warning: amber ground, no border, small corner...", "danger: red ground, no border, error glyph", "titled: a label-role title 2 above the detail...", "padding 12 16, 16 below; 8 12 and 0 in a bar" (message at `Offset(40,12)` / `(36,8)`), "actions sit 8 under the message, 8 apart; a live region", "the title reads in its tone foreground...", "without a bottom margin...". |
| Call sites | 27 files / 35 uses. `lib/features/transfer/presentation/widgets/sections/import_preview_section_widget.dart`, `.../import_mapping_section_widget.dart`, `lib/app/gallery/gallery_overlays_section.dart` |
| ForUI candidate APIs | `FAlert`, `FAlertVariant.primary/destructive`, `FAlertStyleDelta.delta`, `FAlert.liveRegion`, `FAlert.subtitle` |
| Installed package version | forui 0.27.6 |
| Official documentation | `https://forui.dev/docs/widgets/feedback/alert` |
| Source evidence | `PKG widgets/alert.dart:11` (2 variants), `:57,:91,:101-103` (liveRegion default true, container semantics), `:109-111` (title Row, default centre alignment), `:114` and `:126` (literal `left: 10`), `:121-126` (subtitle indented by icon size + 10), `alert.design.dart:183-189` (delta fields: decoration, iconStyle, titleTextStyle, subtitleTextStyle, padding) |
| API verification | PROBE `g4_probe_test.dart` "FAlert: icon alignment and gap with a 3-line message": alert 328x240, icon rect 16..32 x 112..128, text rect 42..312 x 12..228: icon centred on the block, gap 10. |
| Native capability | Tinted/borderless ground (decoration delta), padding 12x16 and 8x12 (`padding` delta), radius sm, icon + title colours per tone (delta), title/subtitle text styles, live region (default), wrapping. Actions could sit in `subtitle`. |
| Capability gaps | (1) Icon is centred on the text block, not the first line (`alert.dart:109-111`; PROBE). Contract: "glyph centres on the first line at any text scale" (also stated in the source and tested for MxNote). (2) Icon-to-text gap is a literal 10, the contract is 8 (`alert.dart:114`; PROBE x=42 vs the pinned 40). (3) No warning variant (only reachable by recolouring a primary). (4) No separate bottom margin or commit-bar variant (these stay MemoX `Padding`). |
| Current approach | **Fallback**: `Padding` > `Semantics(liveRegion)` > `DecoratedBox` > `Row(icon, Column(title, message, Wrap(actions)))`, using only `Icon`, `Text`, `MxButton` from the caller. |
| Selected approach | Fallback (keep), until the owner decides on gaps (1) and (2). If the owner accepts a centred glyph and a 10dp gap: Composition over `FAlert`. |
| Why not a higher-level API? | `FAlert` cannot place the icon on the first line or set an 8dp gap (`alert.dart:109-126`, delta has no field for either), and two tests plus the kit's first-line rule pin both. Not an owner ruling, so the trade is the owner's. |
| Contract tests | `mx_inline_banner_test.dart` covers tone ground, no border, radius, glyph size/colour, title/message styles, padding in and out of a bar, margin, action spacing, live region. **Missing:** a multi-line message test for first-line glyph alignment (MxNote has one, the banner does not). |
| Migration status | BLOCKED (API limit; owner decision available) |
| Correction (if any) | None now. Conditional on owner accepting centred glyph + 10dp gap: `FAlert(variant: FAlertVariant.primary, liveRegion: true, icon: Icon(AppIcons.alert), title: Text(title ?? message, style...), subtitle: title == null ? null : Column(message + Wrap(actions)), style: FAlertStyleDelta.delta(decoration: DecorationDelta.shapeDelta(color: tint, shape: RoundedSuperellipseBorder(borderRadius: context.radii.sm)), iconStyle: IconThemeDataDelta..., padding: EdgeInsetsGeometryDelta.value(...)))`. Removes the hand-built Row/glyph-inset maths (~35 lines); the untitled form needs actions placed under the message, which then must go in `subtitle` with an empty `title`, which FAlert cannot do (title is required, `alert.dart:87`) - so even then the untitled-with-actions form needs a wrapper. Tests to rewrite: padding offsets (42 not 40), centring. Also add the missing multi-line test before any change. |

#### MxNote — `lib/shared/widgets/mx_note.dart`
| Field | Record |
|---|---|
| Existing contract | One calm info line (`DESIGN.md:306` lists it with the feedback set); no tone, no action except an optional close. Boxed form: muted fill, hairline `colors.border`, radius `md`, padding 12+hairline x 10+hairline, 16dp glyph centred on the first line at any text scale, muted body text. `.hint` form: no box, tight vertical padding 4. `onDismiss` requires `dismissLabel` (assert); close is an `MxIconButton` (48dp target through FButton). No live region. Pinned by `mx_note_test.dart` (5 tests): "muted fill, hairline border, medium radius, padding 10 12" (glyph at dx 13, text at `Offset(37, 11)`), "the glyph centres on the first line", "the hint form is a footnote...", "a dismissible note ends in a close button named by its label, and a tap dismisses it", "a note without onDismiss has no close button". |
| Call sites | 23 files / 27 uses of `MxNote(`; `MxNote.hint(` 6 files / 7 uses. `lib/features/transfer/presentation/widgets/sections/import_result_widget.dart`, `.../overlays/card_export_sheet_widget.dart`, `lib/shared/widgets/mx_section.dart` (hint) |
| ForUI candidate APIs | `FAlert` (primary, `liveRegion: false`), `FCard` (+delta), `FItem` (static) |
| Installed package version | forui 0.27.6 |
| Official documentation | `https://forui.dev/docs/widgets/feedback/alert`, `https://forui.dev/docs/widgets/data/card`, `https://forui.dev/docs/widgets/data/item` |
| Source evidence | `PKG widgets/alert.dart:101-131` (layout: icon + title row, no trailing slot), `:109-114` (centre alignment, gap 10); `alert.dart:176-183` (default decoration: card colour, border, md radius); catalog FItem entry (static item has no tappable but is a list-row layout with 10/12.5 padding, item.dart:344-362) |
| API verification | The alignment/gap facts are the same PROBE as MxInlineBanner (same widget, same Row). |
| Native capability | Boxed non-dismissible note: muted fill + border + md radius + padding via decoration/padding deltas; static non-live text (`liveRegion: false`). |
| Capability gaps | Same first-line glyph (`alert.dart:109-111`) and 8dp gap (`:114`) as the banner, pinned by `mx_note_test` ("glyph centres on the first line", `Offset(37,11)`). **No trailing slot**: the dismiss button has nowhere to go (Row is icon + `Flexible(title)` only, `alert.dart:109-119`). The `.hint` form has no box; `FAlert` always wraps a `DecoratedBox` (`alert.dart:88-99`). |
| Current approach | **Fallback** for layout (`DecoratedBox` + `Row`), **Composition** for the close button (`MxIconButton` over FButton). |
| Selected approach | Fallback + composition (keep). |
| Why not a higher-level API? | No dismiss slot, no first-line glyph, no 8dp gap (above); the hint form is not an alert. |
| Contract tests | `mx_note_test.dart` covers boxed geometry, hint, dismiss, first-line centring. **Missing:** a semantic assertion that the note is not a live region (the contract is "calm, static"). |
| Migration status | BLOCKED (API limit) |
| Correction (if any) | None now. |

#### MxDashedNote — `lib/shared/widgets/mx_dashed_note.dart`
| Field | Record |
|---|---|
| Existing contract | One centred line on the muted fill, radius `md`, padding 24x16, dashed 1-hairline outline (4 on / 3 off), a fact never an error or action; read once by TalkBack. Pinned by `mx_dashed_note_test.dart`: "a centred note line on the muted fill, padded 24 16", "TalkBack reads the line once". |
| Call sites | 2 files / 2 uses. `lib/features/progress/presentation/widgets/sections/progress_today_widget.dart`, `.../progress_streak_widget.dart` |
| ForUI candidate APIs | `FCard` (+ delta) for the box; no dashed border anywhere |
| Installed package version | forui 0.27.6 |
| Official documentation | `https://forui.dev/docs/widgets/data/card` |
| Source evidence | `rg -i "dash" PKG` finds only `smartDashesType` text-field options; no dashed `ShapeBorder`/`BorderSide` exists. |
| API verification | none needed |
| Native capability | Only the muted box could be FCard-based. |
| Capability gaps | No dashed outline (rg above). A `DecoratedBox` equals what FCard emits (`card.dart:88`), so moving the box to FCard adds no behaviour; the painted outline stays custom. |
| Current approach | **Fallback**: `CustomPaint(_DashedBorder)` over `DecoratedBox` + `Text`. |
| Selected approach | Fallback. |
| Why not a higher-level API? | No dashed border in ForUI; FCard would only replace a `DecoratedBox` with a `DecoratedBox`. |
| Contract tests | `mx_dashed_note_test.dart` (2). **Missing:** the dash geometry is not asserted (only goldens could show it). |
| Migration status | MIGRATED |
| Correction (if any) | None. |

#### MxEmptyState — `lib/shared/widgets/mx_empty_state.dart`
| Field | Record |
|---|---|
| Existing contract | Centred `MxCard` (full bleed) with a tinted tile (64/r xl2/glyph tile-size, or 52/r lg/24 when `isCompact`), title (sectionTitle / itemTitle), optional body, block actions (primary, secondary - disabled when callback null, tertiary outline), optional `MxNote.hint` footnote 24 below; padding 44/24/32 (compact 32/24); asserts: label with callback (primary, tertiary), secondary callback needs label; five tones with glyph inks (success/warning/primary use text ink, others tone colour). Pinned by `mx_empty_state_test.dart` (11 tests) incl. "title, body and a block primary action", "tone tints the tile and paints the glyph", "full tile is 64/r20/32 glyph, compact 52/r16/24", "a footnote sits space24 below the action as a note", "a secondary action without a callback is disabled", "a third action is an outline block button, 8 under the second", the two assert tests, "in dark the warning glyph reads in warning foreground too". |
| Call sites | 34 files / 53 uses. `lib/features/transfer/presentation/widgets/sections/import_result_widget.dart`, `.../import_source_section_widget.dart`, `lib/features/tags/presentation/screens/tags_screen.dart` |
| ForUI candidate APIs | No empty-state or result widget in `lib/widgets/*.dart`. `FCard` (via MxCard), `FButton` (via MxButton), `FAlert`, `FItem` |
| Installed package version | forui 0.27.6 |
| Official documentation | `https://forui.dev/docs/widgets/data/card`, `https://forui.dev/docs/widgets/form/button` |
| Source evidence | Widget list above (no empty state). `FAlert` has no actions and no tile (`alert.dart:87-131`). |
| API verification | none needed |
| Native capability | Surface (FCard via MxCard), buttons (FButton via MxButton). |
| Capability gaps | The tinted tile itself has no ForUI primitive: `FAvatar` is hard-coded `BoxShape.circle` (`PKG widgets/avatar/avatar.dart:69`), the tile is a rounded square. |
| Current approach | **Composition**: `MxCard`(FCard) + `MxButton`(FButton) + `MxNote.hint`; **Fallback** for the private `_Tile` (`DecoratedBox` + `Icon`). |
| Selected approach | Composition (same). |
| Why not a higher-level API? | No ForUI empty state exists; the pieces that have a ForUI home already use it. |
| Contract tests | `mx_empty_state_test.dart` covers the contract. **Observation (not a defect):** `_Tile` duplicates `MxIconTile`'s mechanism (tinted rounded square + centred glyph) with different sizes (64/52 vs 28/36/44) and tints (warning tone tints `warningFill`, MxIconTile.caution tints `warning`; neutral tints `mutedForeground`, MxIconTile.neutral uses `secondary`); merging would change pixels, so it is recorded, not recommended. |
| Migration status | MIGRATED |
| Correction (if any) | None. |

#### MxErrorState — `lib/shared/widgets/mx_error_state.dart`
| Field | Record |
|---|---|
| Existing contract | Full-bleed `MxCard`, padding 40x24, 52dp danger-tinted tile (r lg, 24dp glyph), title (itemTitle) as a live region ("swaps in for the skeleton in place", SW-REV-006), 4 gap, muted body, optional Retry `MxButton` 16 below with `actionIcon` (retry default, null = none) and `isLoading: isRetrying`; `retryLabel`/`onRetry` come together (assert). A gone item is not a failure (owner 2026-10-08). Pinned by `mx_error_state_test.dart` (9 tests): "a 52 danger-soft tile with a 24 error glyph, 40 from the top", "item-title title, 4 above a body-role body; no Retry by default", "a primary Retry with the refresh glyph, 16 below the body", "retrying holds a spinner in the Retry", "retryLabel and onRetry come together", "the action can carry another icon, as Close does", "a network failure passes the cloud-off glyph", "a null actionIcon draws the action with no glyph", "the title is a live region". |
| Call sites | 38 files / 42 uses. `lib/features/tags/presentation/screens/tags_screen.dart`, `lib/features/study/presentation/screens/study_home_screen.dart`, `lib/features/trash/presentation/screens/trash_screen.dart` |
| ForUI candidate APIs | `FAlert(variant: destructive)`, `FCard`, `FButton` |
| Installed package version | forui 0.27.6 |
| Official documentation | `https://forui.dev/docs/widgets/feedback/alert`, `https://forui.dev/docs/widgets/data/card` |
| Source evidence | `PKG widgets/alert.dart:87-131` (one-row callout: no action slot, no tile, left-aligned) |
| API verification | none needed |
| Native capability | Surface (FCard), Retry button with spinner (FButton via MxButton). |
| Capability gaps | FAlert is a left-aligned callout with no actions (`alert.dart:87-131`); this is a centred whole-card failure state. Same tile gap as MxEmptyState. |
| Current approach | **Composition**: `MxCard` + `MxButton`; **Fallback** for the tile and the `Semantics(liveRegion)` title. |
| Selected approach | Composition (same). |
| Why not a higher-level API? | No ForUI error-state widget; FAlert cannot host a centred layout with a button. |
| Contract tests | `mx_error_state_test.dart` covers the contract. |
| Migration status | MIGRATED |
| Correction (if any) | None. |

#### MxSkeleton (+ MxSkeletonRow, MxSkeletonPulse, MxSkeletonList) — `lib/shared/widgets/mx_skeleton.dart`
| Field | Record |
|---|---|
| Existing contract | Placeholder bar (default 12 tall, radius `sm`, full width, or circle), one tonal step off the ground (`MxTintBase.stepOf`), pulses opacity 0.45 to 0.75 over 1.4s with no shimmer, rests at 0.5 under reduced motion (ticker stopped); one shared ticker per `MxSkeletonPulse`/`MxSkeletonList` (§9 row 66); `MxSkeletonRow` = 28 tile + bars at 70%/45%, as tall as a two-line row (ruling O3); `MxSkeletonList` is one node read as `semanticLabel`, silent without. Pinned by `mx_skeleton_test.dart` (11 tests) incl. "12 tall, the small radius, full width...", "the bar is one step off the ground it sits on, on every ground, light and dark", "pulses 0.45 -> 0.75 -> 0.45 over 1.4s", "reduced motion: rests at 0.5 and nothing runs (RF4)", "skeleton row: a 28 tile and bars at 70% and 45%", "a skeleton row is as tall as a two-line list row", "a list says Loading once and runs one ticker", "a list under reduced motion runs no ticker", "loose skeletons under one MxSkeletonPulse share a ticker". |
| Call sites | `MxSkeleton(`: 6 files / 12 uses (`lib/features/study/presentation/widgets/sections/study_entry_body_widget.dart`, `.../study_home_empty_widget.dart`, `lib/features/search/presentation/widgets/sections/search_body_widget.dart`); `MxSkeletonRow(`: 3 files / 4; `MxSkeletonList(`: 31 files / 31 (`lib/shared/widgets/mx_deck_picker_sheet.dart`, `lib/features/settings/presentation/screens/theme_screen.dart`); `MxSkeletonPulse(`: 6 files / 6. |
| ForUI candidate APIs | `FProgress`, `FCircularProgress`, `FDeterminateProgress` (none is a placeholder), `FAccessibilityContext.motion` (only for the reduced-motion read) |
| Installed package version | forui 0.27.6 |
| Official documentation | `https://forui.dev/docs/widgets/feedback/progress` (no skeleton page exists under `.../docs/widgets/`) |
| Source evidence | `rg -il "skeleton\|shimmer"` over the installed package: no match. `PKG widgets/progresses/*.dart` are the only loading widgets. |
| API verification | none needed |
| Native capability | none |
| Capability gaps | No placeholder shape, no pulse primitive. |
| Current approach | **Fallback**: `FadeTransition` over `DecoratedBox`, `AnimationController`/`TweenSequence`, an `InheritedWidget` for the shared pulse; ground via `MxTintBase.stepOf`. |
| Selected approach | Fallback. |
| Why not a higher-level API? | ForUI has no skeleton (above). |
| Contract tests | `mx_skeleton_test.dart` covers geometry, step, pulse, reduced motion, row, list semantics, ticker sharing. Reduced motion is read from `MediaQuery.disableAnimationsOf` (the repo's convention: `mx_choice_tile.dart:55`, `mx_study_top_bar.dart:69`, `mx_snackbar.dart:177`), while ForUI widgets read `context.accessibility.motion` (platform flag); on Android both derive from `features.disableAnimations` (`PKG foundation/accessibility.dart:123`). |
| Migration status | MIGRATED |
| Correction (if any) | None. |

#### MxLinearProgress (+ `.mastery`) — `lib/shared/widgets/mx_linear_progress.dart`
| Field | Record |
|---|---|
| Existing contract | `value` in [0,1] (assert). `sizeTrack` (4dp) tall pill track in `MasteryRamp.track` (muted), square fill clipped to it; plain form fills `status.successFill`; `.mastery` fills `MasteryRamp.fill` (null at 0, track only) and keeps the fill at least its height in from either end unless 0 or 1. Eases to the value over `Durations.short4` with `Easing.standard`, at once under reduced motion; draws the value at once on first build. Decorative: `ExcludeSemantics`. Pinned by `mx_linear_progress_test.dart` (5 tests): "the fill is the value, and the track says nothing of its own", "sizeTrack tall, filled in the ramp colour", "any mastery shows, and a deck short of 100% never looks full...", "0 paints the track alone", "a value outside 0 to 1 is a programming error". |
| Call sites | `MxLinearProgress(`: 3 files / 3 (`lib/features/study/presentation/widgets/sections/study_home_resume_widget.dart`, `.../study_entry_resume_widget.dart`, `lib/features/topik/presentation/widgets/sections/topik_type_stats_widget.dart`); `.mastery`: 1 file / 2 (`lib/features/deck/presentation/widgets/items/deck_row_widget.dart`). |
| ForUI candidate APIs | `FDeterminateProgress`, `FDeterminateProgressStyleDelta.delta`, `FDeterminateProgressMotionDelta.delta`, `DecorationDelta.shapeDelta`, `FProgress`/`FCircularProgress` (rejected: indeterminate) |
| Installed package version | forui 0.27.6 |
| Official documentation | `https://forui.dev/docs/widgets/feedback/determinate-progress` |
| Source evidence | `PKG widgets/progresses/determinate_progress.dart:50` (value assert), `:89-99` (`_setup`: disabled -> `_controller.value = value`, else `animateTo(value, style.motion.duration, curve)`), `:115-117` (Semantics label + percent), `:119-126` (Align + FractionallySizedBox(widthFactor) + fill Container), `:143` (default height 6), `:156-160` (pill track/fill), `:171-174` (default 1s linear); `determinate_progress.design.dart:90-95, :184`; `foundation/accessibility.dart:119-125` (motion from platform flags) |
| API verification | **PROBE** `g4_probe_test.dart` + `g4_probe2_test.dart`: tightFor(height 4) -> 328x4; short4 + Easing.standard reaches 0.5 after 200 ms; first frame widthFactor 0.0 (MemoX-style `TweenAnimationBuilder`: 0.5); disabled motion -> instant, also after update; MediaQuery-only disableAnimations -> ForUI ignores it; `LayoutBuilder` + MemoX `_factor` as `value` -> 0.02 for 0.0001 on 200dp; `ExcludeSemantics` wrapper -> no "Loading" node; unwrapped -> one node with label "Loading". |
| Native capability | Value API and assert, height, track/fill colour (per-value, via delta), pill track, animation to the value with chosen duration/curve, instant under platform reduced motion, the percent in semantics (which we exclude). |
| Capability gaps | (1) First mount sweeps 0 -> value (`_controller` starts at 0; `:80-99`; PROBE) - the current widget draws the value at once; not configurable except by disabling motion. (2) Fill is a pill (rounded both ends) instead of a square fill clipped by the track (`:156-160`): a visual change at 4dp, owner golden review. (3) Mastery end-inset must stay MemoX code (LayoutBuilder + `_factor`), PROBE-verified. (4) Fill colour null at 0 becomes a zero-width fill (invisible). |
| Current approach | **Fallback**: `ClipRRect` > `SizedBox` > `ColoredBox` track > `LayoutBuilder` > `TweenAnimationBuilder` > `FractionallySizedBox` > `ColoredBox` fill, `ExcludeSemantics`. Uses ForUI nothing. |
| Selected approach | **Composition**: `FDeterminateProgress` with `FDeterminateProgressStyleDelta.delta`, inside `ExcludeSemantics` and a `LayoutBuilder` for the mastery inset. |
| Why not a higher-level API? | n/a (the higher-level API exists and covers the contract except the two behaviours above, which need owner sign-off). |
| Contract tests | Cover value, height, decoration, mastery inset, zero, assert. **Missing:** easing/duration, reduced motion ("at once under Remove animations" is in the doc comment but `rg disableAnimations test/shared/widgets/mx_linear_progress_test.dart` finds nothing), first frame, mastery colour per band. |
| Migration status | CORRECTION NEEDED |
| Correction (if any) | In `build`: `ExcludeSemantics(child: LayoutBuilder(builder: (c, k) => FDeterminateProgress(value: _factor(value, k.maxWidth, height), style: FDeterminateProgressStyleDelta.delta(constraints: BoxConstraints.tightFor(height: height), trackDecoration: DecorationDelta.shapeDelta(color: MasteryRamp.track(colors)), fillDecoration: DecorationDelta.shapeDelta(color: fill ?? colors.primary /* value 0 shows nothing */), motion: FDeterminateProgressMotionDelta.delta(duration: Durations.short4, curve: Easing.standard)))))`. Signatures verified in `determinate_progress.design.dart:90-95, :184` and compiled in `g4_probe2_test.dart`. Code that goes away: `ClipRRect`, track `ColoredBox`, `TweenAnimationBuilder`, `FractionallySizedBox` fill, the `disableAnimationsOf` read (~25 lines). Keep `_factor`, `MasteryRamp`, `ExcludeSemantics`. Risks to put to the owner: pill fill and the 200 ms first-mount sweep change goldens that contain deck rows or resume banners (golden-compare page needed); if the sweep is unwanted, the contract stays with the current widget. Tests to add: reduced motion via `accessibilityFeaturesTestValue(disableAnimations: true)` (not MediaQuery), easing duration, first frame, band colours; adapt the `FractionallySizedBox`/`ColoredBox` finders (ForUI's fill is a `Container(decoration)`). Same-mechanism hits owned by other sets: `lib/shared/widgets/mx_study_top_bar.dart:124-133` (track + animated fill), `lib/features/study/presentation/widgets/support/recall_countdown_bar_widget.dart` (track + fill, `disableAnimationsOf` at `:37`). |

#### MxMasteryDonut — `lib/shared/widgets/mx_mastery_donut.dart`
| Field | Record |
|---|---|
| Existing contract | 56dp box, ring r17/stroke 3 on a 40 viewBox, round cap, clockwise from 12 o'clock, track = `MasteryRamp.track`, arc = `MasteryRamp.fill` (0% -> warningFill, no arc), label = localised percent in the band's text colour (`MasteryRamp.foreground`) scaled down to fit the inner circle; `fraction` in [0,1] and not NaN (assert); with `semanticLabel` one node (label + percent value, children excluded), without it the percent text. No animation. Pinned by `mx_mastery_donut_test.dart` (7 tests): "56 box; the arc in the ramp fill, the label in its band's text colour", "the track is the ramp's progress track in both themes", "0%: the track only; the label in the lowest band", "100%: the full ring...", "the label never rounds to a lie", "out of range or NaN asserts", "a named donut reads its subject with the percentage". |
| Call sites | 3 files / 6 uses. `lib/features/deck/presentation/widgets/sections/deck_summary_card_widget.dart`, `lib/features/card/presentation/widgets/sections/card_deck_summary_widget.dart`, `lib/app/gallery/gallery_status_section.dart` |
| ForUI candidate APIs | `FCircularProgress`, `FDeterminateProgress` |
| Installed package version | forui 0.27.6 |
| Official documentation | `https://forui.dev/docs/widgets/feedback/circular-progress`, `https://forui.dev/docs/widgets/feedback/determinate-progress` |
| Source evidence | `PKG widgets/progresses/circular_progress.dart:42-72` (fields `size, style, semanticsLabel, icon`; no value); linear only in `determinate_progress.dart` |
| API verification | none needed |
| Native capability | none |
| Capability gaps | `FCircularProgress` is an indeterminate spinner icon rotating (`:171`), no value or arc; `FDeterminateProgress` is linear. |
| Current approach | **Fallback**: `CustomPaint` ring + `FittedBox` percent text + `Semantics`. |
| Selected approach | Fallback. |
| Why not a higher-level API? | ForUI has no determinate circular indicator. |
| Contract tests | `mx_mastery_donut_test.dart` covers geometry, colours, edge values, rounding, assert, semantics. |
| Migration status | MIGRATED |
| Correction (if any) | None. |

#### MxStackedDayBars (+ MxDayBar) — `lib/shared/widgets/mx_stacked_day_bars.dart`
| Field | Record |
|---|---|
| Existing contract | One stacked bar per day (top series over base), scaled to the fullest day, 78dp chart, labels below (current day in `foreground`, others muted; long labels scale down), the legend under the labels; an empty day is a 2dp baseline in the progress track colour; each bar is exactly one TalkBack node (`semanticLabel`), labels and legend silent; `days` non-empty and counts non-negative (asserts). Pinned by `mx_stacked_day_bars_test.dart` (5 tests): "the fullest day fills the chart; the rest scale to it", "a day with nothing is a 2-high baseline", "the empty-day mark is the progress track, visible on the card it sits in, light and dark", "each bar is one TalkBack node; labels and legend say nothing more", "the current day is labelled at full strength". |
| Call sites | 1 file / 1 use. `lib/features/progress/presentation/widgets/sections/progress_today_widget.dart` |
| ForUI candidate APIs | none (no chart) |
| Installed package version | forui 0.27.6 |
| Official documentation | none (no chart page in `.../docs/widgets/`) |
| Source evidence | `ls PKG/../widgets` list above; `rg -il "chart" PKG` -> no chart widget |
| API verification | none needed |
| Native capability | none |
| Capability gaps | No chart primitive. |
| Current approach | **Fallback**: `Row`/`Column` of `Container`s with `LayoutBuilder` scale, per-bar `Semantics(excludeSemantics)`. |
| Selected approach | Fallback. |
| Why not a higher-level API? | ForUI has no chart. |
| Contract tests | `mx_stacked_day_bars_test.dart` covers the contract. |
| Migration status | MIGRATED |
| Correction (if any) | None. |

#### MxChartLegend (+ MxBarSeries) — `lib/shared/widgets/mx_chart_legend.dart`
| Field | Record |
|---|---|
| Existing contract | Wrapping row of 6dp dots in each series colour with a muted `meta` label, gaps 12/4; silent to TalkBack (`ExcludeSemantics`; the chart exposes one summary node). Pinned by `mx_chart_legend_test.dart` (2): "each series shows its label beside a dot of its colour", "the legend says nothing to TalkBack". |
| Call sites | 1 production file / 1 use (`lib/features/topik/presentation/widgets/sections/topik_question_bar_chart_widget.dart`), plus `MxStackedDayBars`. |
| ForUI candidate APIs | `FBadge`/`FBadge.raw` |
| Installed package version | forui 0.27.6 |
| Official documentation | `https://forui.dev/docs/widgets/data/badge` |
| Source evidence | Catalog FBadge: pill with decoration, padding 12x6, no icon slot; the legend item has no pill or padding. |
| API verification | none needed |
| Native capability | none |
| Capability gaps | A badge is a bordered/filled pill, a legend entry is a bare dot + label. |
| Current approach | **Fallback**: `Wrap` of `Row(Container dot, Text)`. |
| Selected approach | Fallback. |
| Why not a higher-level API? | No legend widget; FBadge is the wrong shape. |
| Contract tests | `mx_chart_legend_test.dart` (2) covers it. |
| Migration status | MIGRATED |
| Correction (if any) | None. |

#### MxDotOverline — `lib/shared/widgets/mx_dot_overline.dart`
| Field | Record |
|---|---|
| Existing contract | 6dp primary dot (excluded from semantics), 4 gap, upper-cased muted `meta` label that reads as typed (`semanticsLabel`); no padding. Pinned by `mx_dot_overline_test.dart` (2): "a 6px primary dot, 4 before an overline that reads the label", "the label is an eyebrow". |
| Call sites | 2 files / 2 uses. `lib/features/study/presentation/widgets/sections/study_home_resume_widget.dart`, `.../study_entry_resume_widget.dart` |
| ForUI candidate APIs | `FBadge` |
| Installed package version | forui 0.27.6 |
| Official documentation | `https://forui.dev/docs/widgets/data/badge` |
| Source evidence | Catalog FBadge (pill, padded); no eyebrow/overline in the widget list. |
| API verification | none needed |
| Native capability | none |
| Capability gaps | No eyebrow widget; a badge adds a pill and padding. |
| Current approach | **Fallback** (`Row` of dot + `Text`). |
| Selected approach | Fallback. |
| Why not a higher-level API? | No ForUI overline. |
| Contract tests | `mx_dot_overline_test.dart` covers it. |
| Migration status | MIGRATED |
| Correction (if any) | None. |

#### MxIconTile — `lib/shared/widgets/mx_icon_tile.dart`
| Field | Record |
|---|---|
| Existing contract | Square tile that never shrinks: small 28/r sm/16 glyph, medium 36/r md/20, large 44/r md/20; tones tinted (primary or per-deck `seed` tint, `seed` only with tinted - assert), primary solid, warning solid (`warningFill` + `onWarningFill`), success/caution/danger soft tints with a legible ink, neutral (`secondary`); `icon` xor `child` (assert). Decorative: no semantics of its own. Pinned by `mx_icon_tile_test.dart` (9 tests + per-tone/brightness loop) incl. "three steps: 28 small, 36 medium, 44 large", "default: the primary tinted over the page", "seeded: the seed tinted over the surface", "a child replaces the glyph; the tile never shrinks", "an icon or a child, not both", solid primary / solid warning, "a seed only tints", "${tone}, ${brightness}: a soft tint, and the glyph reads 3:1 on it (FE-A6 D14)". |
| Call sites | 30 files / 47 uses. `lib/features/transfer/presentation/widgets/items/import_source_option_widget.dart`, `.../sections/import_result_widget.dart`, `lib/shared/widgets/mx_settings_row.dart` |
| ForUI candidate APIs | `FAvatar.raw`, `FBadge.raw`, `FCard` (+delta), `FItem` prefix |
| Installed package version | forui 0.27.6 |
| Official documentation | `https://forui.dev/docs/widgets/data/avatar`, `.../data/badge`, `.../data/card` |
| Source evidence | `PKG widgets/avatar/avatar.dart:66-72` (`BoxDecoration(shape: .circle)` hard-coded); `badge.dart` (pill + text padding); `card.dart:84-99` (a `DecoratedBox`) |
| API verification | none needed |
| Native capability | none |
| Capability gaps | Avatar is always a circle (`avatar.dart:69`); badge is a pill with text padding; FCard would only supply a `DecoratedBox`, every decoration field being overridden. |
| Current approach | **Fallback**: `SizedBox.square` > `DecoratedBox` > `Center(Icon)`. |
| Selected approach | Fallback. |
| Why not a higher-level API? | No rounded-square glyph tile in ForUI. |
| Contract tests | `mx_icon_tile_test.dart` covers sizes, tones, seed, child, asserts and contrast. |
| Migration status | MIGRATED |
| Correction (if any) | None. |

#### MxOutcomeTile — `lib/shared/widgets/mx_outcome_tile.dart`
| Field | Record |
|---|---|
| Existing contract | Label (meta role, tone ink) over a body (muted), on the tone's tint with a hairline edge, radius `md`, padding 12, gap 4. Kept = success tint + `border` edge + success ink; lost = warning tint + warning edge + warning ink; 4.5:1 on its ground (dialog and sheet grounds). Pinned by `mx_outcome_tile_test.dart` (2 tests, one looped over tone x brightness): "${tone}, ${brightness}: the label reads 4.5:1 on its ground in a dialog", "kept reads in the success foreground, lost in the warning foreground...". |
| Call sites | 2 files / 4 uses. `lib/features/deck/presentation/widgets/overlays/deck_reset_dialog_widget.dart`, `lib/app/gallery/gallery_status_section.dart` |
| ForUI candidate APIs | `FAlert`, `FCard` (+delta), `FItem` |
| Installed package version | forui 0.27.6 |
| Official documentation | `https://forui.dev/docs/widgets/feedback/alert`, `.../data/card` |
| Source evidence | `PKG widgets/alert.dart:109-131` (icon is always rendered: `icon ?? circleAlert`), `:111` ; `card.dart:84-99` |
| API verification | none needed |
| Native capability | A bordered tinted surface could be an FCard delta. |
| Capability gaps | FAlert always draws an icon (`alert.dart:111`), the tile has none; a FCard would restate shape (md radius, coloured side) and colour while contributing only a `DecoratedBox`; MxCard fixes radius `lg` (a visible change from `md`). |
| Current approach | **Fallback**: `DecoratedBox(BoxDecoration)` + `Column(Text, Text)`. |
| Selected approach | Fallback. |
| Why not a higher-level API? | The only surface-level ForUI primitive is FCard, which adds no behaviour here; FAlert forces an icon. |
| Contract tests | `mx_outcome_tile_test.dart` pins contrast and ink only. **Missing:** geometry (padding 12, gap 4, radius md, edge colours) is only covered by goldens. |
| Migration status | MIGRATED |
| Correction (if any) | None. (Optional, if a theme-wide shape consistency pass is wanted: this widget and MxNote/MxInlineBanner/MxDashedNote/MxStatTile/MxIconTile use `BorderRadius` rectangles whereas FCard/FAlert/FDeterminateProgress use `RoundedSuperellipseBorder`, `card.dart:135`, `alert.dart:178`; that is a pixel change for the owner, not a contract fix.) |

#### MxStatTile — `lib/shared/widgets/mx_stat_tile.dart`
| Field | Record |
|---|---|
| Existing contract | A figure (role `figure`, one line, scales down in a narrow column) over an upper-cased muted `meta` label; emphasis primary/plain/muted inks the figure; layout `inline` (centred, no surface) or `boxed` (left-aligned on `muted`, radius `md`, padding 12, full width); one semantics node: label, then value (`semanticValue` replaces the shown figure). Pinned by `mx_stat_tile_test.dart` (7 tests): "one node reads the label, then the value", "a spoken value replaces the shown one", "primary takes the primary text, muted the muted text...", "a boxed tile fills with the muted ground", "the label is upper-cased and a boxed tile does not clip", "a long value keeps one line in a narrow column", "the label is an eyebrow". |
| Call sites | 5 files / 12 uses. `lib/features/study/presentation/widgets/sections/session_summary_hero_widget.dart`, `.../study_entry_hero_widget.dart`, `lib/app/gallery/gallery_status_section.dart` |
| ForUI candidate APIs | `FItem` (static), `FCard` builder (`titleTextStyle/subtitleTextStyle`), `FTile` |
| Installed package version | forui 0.27.6 |
| Official documentation | `https://forui.dev/docs/widgets/data/item`, `.../data/card` |
| Source evidence | Catalog FItem: static item = list-row layout `[prefix][title/subtitle][details][suffix]`, padding 10/12.5, no way to exclude or reorder child semantics (`FItem` exposes no `excludeSemantics`); `card.dart:141-144` title text style are display.md/lg, not MemoX's `figure`. |
| API verification | none needed |
| Native capability | none |
| Capability gaps | A stat is not a list row; reading order "label then value" needs a custom `Semantics(excludeSemantics)` which FItem cannot do; centred inline form has no ForUI equivalent. |
| Current approach | **Fallback**: `Semantics(container, excludeSemantics)` > `DecoratedBox`/`Column` > `FittedBox(Text)`. |
| Selected approach | Fallback. |
| Why not a higher-level API? | See gaps (semantics order and layout). |
| Contract tests | `mx_stat_tile_test.dart` covers semantics, inks, boxed fill, scaling. |
| Migration status | MIGRATED |
| Correction (if any) | None. |

#### MxWorkloadBreakdownLine — `lib/shared/widgets/mx_workload_breakdown_line.dart`
| Field | Record |
|---|---|
| Existing contract | "N overdue . N today . N new (. N scheduled)" with a fixed ink per term (warning, primary, muted; scheduled muted), urgency order, zero terms drop with their separator unless `shouldKeepZeroTerms` (then muted; the flag was removed on 2026-10-20, Study home spec H1); fallback line when nothing is due; `suffix`; one line with ellipsis, or wrapping only between terms (`canWrap`, The Wrap Rule via `meta_line`); `hasIcons` leads each term with its glyph and reads as its words alone (BR-STUDY-076). Counts non-negative; `hasIcons` needs `canWrap` and no suffix (asserts). Pinned by `mx_workload_breakdown_line_test.dart` (14 tests) incl. "all three terms in order, each in its colour", "a zero term drops with its separator (RF4)", "nothing due is the fallback; a suffix follows the terms", "one line with an ellipsis", "a negative count asserts", "a fourth, muted Scheduled term...", "a hero line wraps instead of cutting its suffix", "a statement keeps a zero term, muted...", "with icons each term leads with its own glyph...", "a wrapping line without glyphs never breaks inside a term nor before its dot, at any width". |
| Call sites | 6 files / 7 uses. `lib/features/study/presentation/widgets/sections/study_home_workload_widget.dart`, `.../study_home_decks_widget.dart`, `lib/features/deck/presentation/widgets/support/deck_workload_line_widget.dart` |
| ForUI candidate APIs | none (text composition); `FBadge` rejected |
| Installed package version | forui 0.27.6 |
| Official documentation | none |
| Source evidence | No rich-text/meta-line widget in the widget list. |
| API verification | none needed |
| Native capability | none |
| Capability gaps | A domain text statement; ForUI offers no text composition widgets. |
| Current approach | **Fallback**: `Text.rich` / `Wrap` of `Row(Icon, Text.rich)`; wrapping rule from `lib/l10n/meta_line.dart`. |
| Selected approach | Fallback. |
| Why not a higher-level API? | No ForUI widget does this. |
| Contract tests | `mx_workload_breakdown_line_test.dart` (14) is thorough. |
| Migration status | MIGRATED |
| Correction (if any) | None. |

---

### 2. Summary

| Component | Current | Selected | Status |
|---|---|---|---|
| MxCard | Composition (FCard + FCardStyleDelta) | Composition | MIGRATED |
| MxTintBase | Fallback (infrastructure) | Fallback | MIGRATED |
| MxInlineBanner | Fallback | Fallback (FAlert if owner relaxes glyph/gap) | BLOCKED (API limit) |
| MxNote | Fallback + MxIconButton | Fallback + composition | BLOCKED (API limit) |
| MxDashedNote | Fallback | Fallback | MIGRATED |
| MxEmptyState | Composition (MxCard, MxButton, MxNote) + custom tile | Composition | MIGRATED |
| MxErrorState | Composition (MxCard, MxButton) + custom tile | Composition | MIGRATED |
| MxSkeleton (+Row/Pulse/List) | Fallback | Fallback | MIGRATED |
| MxLinearProgress | Fallback | Composition (FDeterminateProgress) | CORRECTION NEEDED |
| MxMasteryDonut | Fallback | Fallback | MIGRATED |
| MxStackedDayBars | Fallback | Fallback | MIGRATED |
| MxChartLegend | Fallback | Fallback | MIGRATED |
| MxDotOverline | Fallback | Fallback | MIGRATED |
| MxIconTile | Fallback | Fallback | MIGRATED |
| MxOutcomeTile | Fallback | Fallback | MIGRATED |
| MxStatTile | Fallback | Fallback | MIGRATED |
| MxWorkloadBreakdownLine | Fallback | Fallback | MIGRATED |

Counts: MIGRATED 14, CORRECTION NEEDED 1, BLOCKED 2 (17 total).

### 3. Corrections, ordered by value

1. **MxLinearProgress -> FDeterminateProgress** (contract-preserving except two owner-visible behaviours). Removes the track, clip, tween and fill code (~25 lines) and gives ForUI's value assert, motion style and reduced-motion handling. Needs owner approval of (a) pill fill, (b) 200 ms sweep on first mount, plus a golden-compare page. Also fix the same mechanism in `mx_study_top_bar.dart:124-133` and `recall_countdown_bar_widget.dart` (other sets). Add reduced-motion, easing and first-frame tests first.
2. **Owner decision, then optional: MxInlineBanner and MxNote -> FAlert.** Not contract-preserving today (glyph centring on the first line, 8dp gap; MxNote also needs a dismiss slot FAlert lacks). If the owner accepts a centred glyph and a 10dp gap, the banner can become an FAlert composition (removes ~35 lines of Row/glyph-inset code); MxNote cannot (no trailing slot, hint form has no box). Add a multi-line glyph test for the banner first.
3. **MxCard simplification (optional, low value).** For non-selected cards pass only the colour delta so radius and border follow the ForUI theme; add the missing `isCompact` padding test.

No other component in this group has a verified ForUI counterpart (ForUI 0.27.6 has no skeleton, chart, ring, legend, empty or error state, stat or tile-glyph widget).

## Ledger G5: feature-level UI that builds its own interaction, animation, focus, overlay or painting

Set: `lib/features/**` and `lib/app/**` (gallery included). Audited 2026-10-17 against forui 0.27.6.
No repository file was edited. Probes live only in
`ledger_probe/test/g5_probe_test.dart`.

### Method, shared facts, and what limits every correction

**Discovery.** The brief's `rg -l "GestureDetector\(|Listener\(|AnimatedSwitcher\(|AnimatedOpacity\(|CustomPaint\(|FocusNode\(|Focus\(|showDialog|Navigator\("` over `lib/features lib/app` returns 15 files. `Listener\(` only matched `AppLifecycleListener` in `lib/app/app.dart`, `study_recall_widget.dart` and `topik_attempt_screen.dart` (non-UI). I then widened the search (`RefreshIndicator|ReorderableListView|SelectableText|SelectionArea|AnimationController|PopScope|AbsorbPointer|IgnorePointer|NotificationListener|Tween|Transform.|Opacity(|MouseRegion|Shortcuts|...`) and read every hit. There is no `InkWell`, `Overlay`, `showDialog`, `showModalBottomSheet`, `Draggable`, `Dismissible` or `Tooltip` in `lib/features` or `lib/app`. `package:flutter/material.dart` is imported in features only with `show` lists for: `RefreshIndicator` (2), `ReorderableListView` (1), `SelectableText, SelectionArea` (1), `MaterialPageRoute` (1), `Durations, Easing` (2), `Easing` (1), `MaterialLocalizations, TimeOfDay` (2, formatting only).

**Architectural limit that applies to every "use ForUI" correction here.** `docs/forui-migration/FORUI_ARCHITECTURE.md:9` ("features: Mx* widgets only; no package:forui") and lint rule UIL06 (same file, rules table: `package:forui` imported, exempt `lib/core/theme/`, `lib/shared/`, `lib/app/`). A feature widget therefore cannot call `FTappable`, `FButton`, `FDeterminateProgress`, ... itself. A ForUI-backed correction at feature level is either (a) composing an existing Mx facade (for example `MxRowInk` = `FTappable.static`, `MxChipTrigger` = `FButton`), or (b) adding a new Mx widget to `lib/shared/widgets/`, which CLAUDE.md "Asking the owner" requires the owner to approve (AskUserQuestion) and `forui-shared-widgets` ADMIT governs. Corrections below say which.

**Facts established once (cited in records):**

| # | Fact | Evidence |
|---|---|---|
| F1 | ForUI public library has no `CustomPaint`/`CustomPainter`/`drawArc`, no `RefreshIndicator`, no `ReorderableList*`, no `SelectableText`/`SelectionArea` widget, no `PageRoute`/`Navigator(`, no fade/slide switcher widget. `rg -n "drawArc\|CustomPaint\|CustomPainter\|RefreshIndicator\|ReorderableList\|PageRoute\|Navigator\(" forui-0.27.6/lib` returns nothing; `SelectionContainer.disabled` only at `foundation/tappable/tappable.dart:704`; `AnimatedSwitcher` only inside `widgets/avatar/avatar_content.dart:37` and `widgets/checkbox.dart:139` (private use). | rg over `/root/.pub-cache/hosted/pub.dev/forui-0.27.6/lib` |
| F2 | `FTappable` has no horizontal-drag/pan/swipe parameter (params: press, long press, double tap, secondary, variant, focus, hover, semantics). Drag appears in ForUI only in toast swipe, sheet drag-dismiss, resizable, slider. | `foundation/tappable/tappable.dart:41-461` (factory list at `:345-461`); `rg -l "swipeToDismiss\|HorizontalDrag"` lists toast, sheet, resizable, slider, popover_menu, context_menu, tile_mixin |
| F3 | `FTappable` always builds `Semantics(button: true, container: true, enabled, ...)` and a `Focus` around its child; focus and a button semantics node cannot be opted out of (only `excludeSemantics: true`, which drops the child's own semantics). | `tappable.dart:704-748` |
| F4 | `FTappable.static` and `FButton` focus ring, hover, press, Enter activation come from `FTappable`; `FButton(semanticsLabel:)` sets `excludeSemantics: semanticsLabel != null`. | `widgets/button/button.dart:288-306`; catalog "FTappable", "FButton" |
| F5 | `FDeterminateProgress` animates its fill to every new `value` over `style.motion.duration` (default 1000 ms linear); `motion: .delta(duration: Duration.zero)` is accepted by the style delta. | `widgets/progresses/determinate_progress.dart:89-99, 115-124, 171`; `determinate_progress.design.dart:90-95, 184` |
| F6 | `FCircularProgress` is indeterminate only ("An indeterminate circular progress indicator"). There is no circular determinate/donut widget. | `widgets/progresses/circular_progress.dart:36` |
| F7 | `FTimePicker` is wheels only (no text entry); `hour24`, `hourInterval`, `minuteInterval`; semantics are per-wheel adjustable nodes. | `widgets/picker/time/time_picker.dart:28, 55-77, 130-132`; catalog "FTimePicker" |
| F8 | ForUI reads reduced motion as `FAccessibilityMotion` (`disabled` when `features.disableAnimations`), the same platform flag `MediaQuery.disableAnimationsOf` reports; ForUI adds `reduced` (iOS reduceMotion). | `foundation/accessibility.dart:119-130` |

**Probes run (all `PROBE`, in `ledger_probe/test/g5_probe_test.dart`, 7 tests, all pass):**

| Probe | Result |
|---|---|
| P1 `FDeterminateProgress` default motion, value 0.7 then 0.65, pump 16 ms | factor `0.6992` (lags: the bar barely moves) |
| P1b same with `motion: FDeterminateProgressMotionDelta.delta(duration: Duration.zero)`, `constraints: BoxConstraints.tightFor(height: 4)` | factor `0.7`, then `0.65`, then `0.6` after one `pump()` each; `FractionallySizedBox` height `4.0` |
| P1c `Semantics(container, label, value, excludeSemantics)` around the bar | one node: `label="Time to recall" value="14 seconds left" rect=360x4` (the bar adds none) |
| P2 `FTextField(autofocus: true)` on a newly pushed route while the previous route's `FButton` had focus | `hasFocus=true` |
| P2b `FTextField(autofocus: true)` mounted later in a scope where another node already holds focus | `hasFocus=false`, the other node keeps focus |
| P3a `FTappable.static(onPress)` > `Text` | `flags=isButton,isFocusable,hasEnabledState,isEnabled,hasSelectedState actions=tap,focus label="Term face"` |
| P3b `GestureDetector(excludeFromSemantics: true)` > `Text` | `label="Term face"` only (no button, no focus, no tap action) |
| P4 `FButton(xs, outline, mainAxisSize.min, semanticsLabel, suffix: Icon, child: Text)` | `flags=isButton,hasEnabledState,isEnabled actions=tap label="Remove verb"` (width 360 only because the probe host is a tight 360 box) |

**Test runs** (`export PATH=/root/.flutter-sdk/3.47.5/flutter/bin:$PATH; MEMOX_TEST_BUNDLES=0 bash .claude/skills/flutter-workflow/scripts/run_tests.sh <files>`, never goldens):
- Study group, 9 files: `+82: All tests passed!` (`study_browse`, `study_support_widgets`, `study_appearing`, `study_settle_guard`, `study_guess`, `study_self_assess`, `study_recall`, `study_fill`, `study_gutter`).
- Other group, 18 files: `+142: All tests passed!` (`card_primary_text`, `card_tag_input`, `card_editor_keyboard`, `card_editor_blocks`, `topik_summary_widgets`, `reminder_screen`, `account_transition_layer`, `account_layer_back`, `account_transition_gutter`, `monitoring_code_card`, `monitoring_trace`, `monitoring_screen`, `deck_reorder_row_widget`, `deck_reorder_anchor`, `deck_reorder`, `library_search_screen`, `test/app/gallery_test`, `users_screen`).
- Total 224 tests in 27 files, 224 pass, 0 fail.

**Common values for every record:** Installed package version = `forui 0.27.6`.
Doc URL base = `https://forui.dev/docs/` (local copy `.../scratchpad/forui-src/docs/content/docs/`).

---

#### StudyFaceCardWidget (tap) — `lib/features/study/presentation/widgets/support/study_face_card_widget.dart`
| Field | Record |
|---|---|
| Existing contract | One face of the study card: label in flow above, content centred in an `MxScrollFade` scroll, recessed ground when `isAnswer`. Optional `onTap` is "a shortcut only; the screen's button is the accessible path" (class doc): the tap is a `GestureDetector(behavior: opaque, excludeFromSemantics: true)` (`:68-73`), so it adds no TalkBack node, no tab stop, no press layer. Handoff `16a-study-self-assess.md:23,30`: tapping the prompt card reveals, same as "Show answer". Pinned by `study_self_assess_test.dart` "tapping the prompt card reveals, as Show answer does"; `study_support_widgets_test.dart` "a face with more below fades its bottom edge (audit P1)" and "a face that fits shows no fade". |
| Call sites | 7: `study_self_assess_widget.dart:61,71` (with `onTap`), `study_guess_widget.dart:143`, `study_recall_widget.dart:203,222`, `study_fill_widget.dart:128,138` |
| ForUI candidate APIs | `FTappable`, `FTappable.static`, `FFocusedOutline`; via the allowed facade `MxRowInk` (= `FTappable.static`) |
| Installed package version | forui 0.27.6 |
| Official documentation | https://forui.dev/docs/widgets/foundation/tappable |
| Source evidence | `foundation/tappable/tappable.dart:704-748` (Semantics `button: true, container: true` and `Focus` always built); `:861-863` (outline only when `focusedOutlineStyle` non-null) |
| API verification | PROBE P3a/P3b: `FTappable.static` yields `isButton,isFocusable, actions=tap,focus`; `GestureDetector(excludeFromSemantics)` yields none of these |
| Native capability | Tap callback, optional press layer (if the builder paints one) |
| Capability gaps | Cannot be a pointer-only shortcut: it always adds a focusable button node (`tappable.dart:704-748`; P3a), i.e. a second control for the action "Show answer" and a second tab stop, against the class contract. `excludeSemantics: true` would hide the face text from TalkBack. Features may not import `package:forui`; the only facade is `MxRowInk`, which also paints a press layer on a card. |
| Current approach | Fallback: `GestureDetector` (Flutter gesture primitive) on top of `MxCard`/`MxScrollFade` |
| Selected approach | Fallback (unchanged) |
| Why not a higher-level API? | `FTappable` has no "no semantics, no focus" mode (`tappable.dart:704-748`; P3a); adopting it changes the accessibility contract the class and handoff 16a define |
| Contract tests | `study_self_assess_test.dart` (tap reveals), `study_support_widgets_test.dart` (fade). Missing: no test asserts the tap leaves no extra semantics node (the contract's other half) |
| Migration status | MIGRATED (justified Fallback; 82 study tests pass) |
| Correction (if any) | none |

#### StudyBrowseWidget (swipe card) — `lib/features/study/presentation/widgets/sections/study_browse_widget.dart`
| Field | Record |
|---|---|
| Existing contract | Handoff `16-study-browse.md:17,80,81`, BR-STUDY-048, FE-A6 D19/D20: left swipe advances (answers the live card; dropped while `isBusy`), right swipe looks back one shown card (does nothing on the round's first card; writes nothing), card follows the finger unless Remove animations (`:123-126`), distance 70 or velocity 600 thresholds (`:55-56`), TalkBack custom actions "Next card"/"Previous card" on the card's node (`:108-112`), a visible `MxButton` Next beside the swipe (critique 2026-09-30). Tests: `study_browse_test.dart` "left advances one stop; right looks back without writing...", "a right swipe on the round's first card does nothing (FE-A6 D20)", "the card offers Next always and Previous only when there is a card behind" (finds the `GestureDetector` node's custom action ids), "a visible Next moves on like a left swipe". |
| Call sites | 1: `study_session_screen.dart:425` |
| ForUI candidate APIs | `FTappable` (no drag), `FTabs` (content swipe), `FResizable`, `FToast` swipe, `showFSheet` drag |
| Installed package version | forui 0.27.6 |
| Official documentation | https://forui.dev/docs/widgets/foundation/tappable ; https://forui.dev/docs/widgets/navigation/tabs |
| Source evidence | F2: no drag parameter on `FTappable` (`tappable.dart:345-461`). `FTabs` swipe is tied to tab content and `FTabController` (catalog "FTabs", `tab_controller.dart`), not to a history stack. Toast/sheet drag are dismiss gestures (`toast/animated_toast.dart`, `sheet/gesture_detector.dart:22-45`) |
| API verification | none needed (no candidate carries a horizontal drag gesture on arbitrary content) |
| Native capability | none for the swipe/look-back |
| Capability gaps | No ForUI widget offers a free horizontal drag with distance/velocity thresholds and a follow-the-finger offset for arbitrary content (F2) |
| Current approach | Fallback: `GestureDetector(onHorizontalDragUpdate/End)` + `Transform.translate` + `Semantics(customSemanticsActions)`; the Next button is `MxButton` (ForUI via facade) |
| Selected approach | Fallback (unchanged) |
| Why not a higher-level API? | F2 |
| Contract tests | `study_browse_test.dart` covers swipe left/right/first-card/semantic actions/Next button. Missing: the drag-follow offset and the Remove-animations no-follow path (`isStill`) have no test |
| Migration status | MIGRATED (justified Fallback) |
| Correction (if any) | none (optional test: assert no translate under `disableAnimations`) |

#### StudyGuessWidget (tap anywhere once answered) — `lib/features/study/presentation/widgets/sections/study_guess_widget.dart`
| Field | Record |
|---|---|
| Existing contract | FE-A6 P3 ruling G1: once answered "a tap anywhere goes on" (`:174-182`: `GestureDetector(onTap: _continue, behavior: translucent, excludeFromSemantics: true)` only while `_isAnswered`); with `MediaQuery.accessibleNavigationOf` a visible `MxButton` Next replaces it (`:183-191`, ruling C6). Tests: `study_guess_test.dart` "...a tap continues early (G1, C1, C3)", "with TalkBack on nothing advances by itself; Next does (C6)". |
| Call sites | 1: `study_session_screen.dart:440` |
| ForUI candidate APIs | `FTappable`, `FTappable.static` (via `MxRowInk`) |
| Installed package version | forui 0.27.6 |
| Official documentation | https://forui.dev/docs/widgets/foundation/tappable |
| Source evidence | F3 `tappable.dart:704-748`; nested tappables claim the pointer for the deepest enabled one (`tappable.dart:560, 765-785`) |
| API verification | PROBE P3a/P3b (same footprint as StudyFaceCardWidget) |
| Native capability | A tap callback with translucent hit testing |
| Capability gaps | Would wrap the whole answer body (scroll view plus the option tiles) in a focusable button node (F3), duplicating Next for keyboard/TalkBack and changing the accessible path the ruling defines (C6) |
| Current approach | Fallback: `GestureDetector` |
| Selected approach | Fallback (unchanged) |
| Why not a higher-level API? | F3 |
| Contract tests | `study_guess_test.dart` G1/C6 tests above |
| Migration status | MIGRATED (justified Fallback) |
| Correction (if any) | none |

#### StudyAppearingWidget (reveal fade-and-rise) — `lib/features/study/presentation/widgets/support/study_appearing_widget.dart`
| Field | Record |
|---|---|
| Existing contract | A hidden face is a still 140x14 bar (`ExcludeSemantics`, one step off its ground) until `isShown`, then the child fades and rises 4% in over `Durations.short4` with `Easing.standard`; zero duration under Remove animations (`:21-38`; handoff 16a/19 Motion). Test: `study_appearing_test.dart` "the hidden bar is one step off the face it sits on..." (colour only). |
| Call sites | 3: `study_self_assess_widget.dart:146,190`, `study_recall_widget.dart:225` |
| ForUI candidate APIs | none found: `FAccordion`, `FCollapsible`, `FTabs`, `FAvatar` fade are component-internal. `FCollapsible` is size/clip by a caller-driven 0..1 value and has no fade or rise |
| Installed package version | forui 0.27.6 |
| Official documentation | https://forui.dev/docs/widgets/foundation/collapsible ; https://forui.dev/docs/widgets/data/accordion |
| Source evidence | F1 (no public switcher/transition widget; `AnimatedSwitcher` private use at `avatar/avatar_content.dart:37`, `checkbox.dart:139`); `foundation/collapsible.dart:12-39` (size clip only); F8 for the motion flag |
| API verification | none needed |
| Native capability | none |
| Capability gaps | No ForUI widget does a keyed cross-fade with slide between two arbitrary children |
| Current approach | Fallback: Flutter `AnimatedSwitcher` + `FadeTransition` + `SlideTransition`; motion flag from `MediaQuery.disableAnimationsOf` (same platform signal as ForUI's `disabled`, F8) |
| Selected approach | Fallback (unchanged) |
| Why not a higher-level API? | F1 |
| Contract tests | `study_appearing_test.dart` pins the bar colour on both grounds and both themes. Missing: no test for the fade/rise or the zero duration under Remove animations |
| Migration status | MIGRATED (justified Fallback) |
| Correction (if any) | none |

#### StudySettleGuardWidget (400 ms tap guard with opacity ease) — `lib/features/study/presentation/widgets/support/study_settle_guard_widget.dart`
| Field | Record |
|---|---|
| Existing contract | After `phase` changes the row ignores taps for 400 ms (`IgnorePointer(ignoring: _settle.value < 1)`) while opacity eases from `opacityMuted` to 1; `AnimationBehavior.preserve` so Remove animations does not shorten the guard; at full opacity at once under Remove animations; first build is not a swap (`:36-76`). Tests: `study_settle_guard_test.dart`, 5 tests (first build takes a tap; 400 ms no-tap and ease; Remove animations full opacity and still guarded; platform flag does not shorten; same phase is not a swap). |
| Call sites | 3: `study_self_assess_widget.dart:100`, `study_recall_widget.dart:238`, `study_fill_widget.dart:191` |
| ForUI candidate APIs | none: ForUI's disabled state is a null callback per control (`tappable.dart:527-545`), not a time-boxed guard |
| Installed package version | forui 0.27.6 |
| Official documentation | https://forui.dev/docs/widgets/foundation/tappable |
| Source evidence | `tappable.dart:527-558` (disabled = no callbacks); F8 |
| API verification | none needed |
| Native capability | none |
| Capability gaps | No ForUI timed interaction guard |
| Current approach | Fallback: `AnimationController` + `IgnorePointer` + `Opacity` |
| Selected approach | Fallback (unchanged) |
| Why not a higher-level API? | no ForUI primitive with this behaviour |
| Contract tests | the 5 tests above cover the contract |
| Migration status | MIGRATED (justified Fallback) |
| Correction (if any) | none |

#### StudyRecallWidget (turn clock) — `lib/features/study/presentation/widgets/sections/study_recall_widget.dart`
| Field | Record |
|---|---|
| Existing contract | A 20 s `AnimationController` that runs backwards, stops on any lifecycle state but resumed (BR-STUDY-036), saves the remaining time on pause/dispose, resumes after a refused reveal, announces the timeout. Domain timing, no visual of its own. Tests: `study_recall_test.dart` (countdown, reveal, time-up; pass). |
| Call sites | 1: `study_session_screen.dart:460` |
| ForUI candidate APIs | none (ForUI has no timer/countdown/lifecycle widget) |
| Installed package version | forui 0.27.6 |
| Official documentation | n/a |
| Source evidence | F1 (nothing comparable in the public library) |
| API verification | none needed |
| Native capability | n/a |
| Capability gaps | n/a |
| Current approach | Fallback (Flutter `AnimationController`, `AppLifecycleListener`) |
| Selected approach | Fallback (unchanged) |
| Why not a higher-level API? | not a UI component; no ForUI equivalent |
| Contract tests | `study_recall_test.dart` |
| Migration status | MIGRATED |
| Correction (if any) | none |

#### RecallCountdownBarWidget (draining track) — `lib/features/study/presentation/widgets/support/recall_countdown_bar_widget.dart`
| Field | Record |
|---|---|
| Existing contract | One semantics node (`label` = caption, `value` = seconds left, `excludeSemantics`), never announced per tick (V3, V5); a `sizeTrack` (4 dp) track `MasteryRamp.track`, fill `mutedForeground`, or `warningFill` when timed out; under Remove animations the fill steps by whole seconds (V9). Tests: `study_support_widgets_test.dart` "the clock is one node, its caption with the seconds left as its value, and its fill is the time left (V3, V5)" (reads `FractionallySizedBox.widthFactor` and its height 4), "under Remove animations the fill steps by whole seconds (V9)"; `study_gutter_test.dart`. |
| Call sites | 1: `study_recall_widget.dart:181` |
| ForUI candidate APIs | `FDeterminateProgress` (+ `FDeterminateProgressStyle`/`Delta`, `FDeterminateProgressMotion`); `FProgress` (indeterminate, wrong); `FCircularProgress` (wrong) |
| Installed package version | forui 0.27.6 |
| Official documentation | https://forui.dev/docs/widgets/feedback/determinate-progress |
| Source evidence | F5 `determinate_progress.dart:89-99, 115-124, 171`; `determinate_progress.design.dart:90-95, 184` (delta takes `trackDecoration`, `fillDecoration`, `constraints`, `motion.duration`) |
| API verification | PROBE P1 (default 1000 ms motion lags a per-frame value: 0.6992 after a 0.7 to 0.65 change + 16 ms), P1b (`duration: Duration.zero`: exact value after one pump, height 4.0), P1c (one node under the outer `Semantics(excludeSemantics)`) |
| Native capability | Track, fill, height, rounded ends, value to width; semantics are already replaced by the outer node (P1c); Remove-animations stepping stays in the widget's `fraction` |
| Capability gaps | Needs `motion.duration: Duration.zero` (default would lag a countdown, P1); fill is a rounded pill rather than a clipped rectangle (ForUI draws `fillDecoration` as its own shape, `determinate_progress.dart:124`), so end-cap pixels change and `study_recall_fill_golden_test` goldens move; features cannot import ForUI, so it must go through a shared Mx widget. `MxLinearProgress` (the existing shared track) is itself hand-built (`TweenAnimationBuilder`, `ClipRRect`), not on `FDeterminateProgress` |
| Current approach | Fallback: `ClipRRect` > `SizedBox` > `ColoredBox` > `Align` > `FractionallySizedBox` inside `Semantics` |
| Selected approach | Foundation/native composition: a shared Mx track on `FDeterminateProgress` with a zero-duration style, used by this widget |
| Why not a higher-level API? | n/a (a native widget exists and is probe-verified), blocked only by "features may not import forui" and by the shared track not yet using it |
| Contract tests | `study_support_widgets_test.dart` and `study_gutter_test.dart` (contract covered; they query `FractionallySizedBox`, which `FDeterminateProgress` also builds at `:124`, height measured 4.0 in P1b). Missing: none for the contract; the golden needs the golden-compare review if shapes change |
| Migration status | CORRECTION NEEDED (conditional on the shared owner) |
| Correction (if any) | Lowest shared owner first: make `MxLinearProgress` (`lib/shared/widgets/mx_linear_progress.dart`) render `FDeterminateProgress(value:, style: FDeterminateProgressStyleDelta.delta(trackDecoration: ShapeDecoration(color: MasteryRamp.track(colors), shape: <pill>), fillDecoration: ShapeDecoration(color: fill, shape: <pill>), constraints: BoxConstraints.tightFor(height: sizeTrack), motion: FDeterminateProgressMotionDelta.delta(duration: <short4 or Duration.zero>)))`, with an optional zero-motion and fill-colour parameter, then have `RecallCountdownBarWidget` use it and drop its five stacked box widgets. Needs owner approval (shared widget change) and a golden review (`study_recall_fill_golden_test`, mastery bar goldens). Tests to add: motion duration zero keeps the fill exact per frame; fill colour for timed-out. |

#### StudyFillWidget (focus) — `lib/features/study/presentation/widgets/sections/study_fill_widget.dart`
| Field | Record |
|---|---|
| Existing contract | The field has focus when the turn opens (V7); a wrong result `unfocus()`es and announces (`:85-92`); a right answer moves on without a feedback frame (F3); IME Done checks (F2). Tests: `study_fill_test.dart` "the field has focus when the turn opens (V7)", "IME Done checks (F2)", "a right answer moves on at once...". |
| Call sites | 1: `study_session_screen.dart:473` |
| ForUI candidate APIs | `FTextField(autofocus:, focusNode:)` through `MxTextField(isAutofocused:, focusNode:)` |
| Installed package version | forui 0.27.6 |
| Official documentation | https://forui.dev/docs/widgets/form/text-field |
| Source evidence | `widgets/text_field/text_field.dart:152, 393-399` (`autofocus`); `lib/shared/widgets/mx_text_field.dart:45,55,70,101,165-166` (the facade already takes both) |
| API verification | PROBE P2b: a later-mounted `autofocus` field does NOT take focus from a node already focused in the scope; P2: autofocus on a pushed route does |
| Native capability | `focusNode` is passed to `FTextField` natively; `isAutofocused` exists |
| Capability gaps | A new turn is mounted inside the same session route, so `autofocus` is unreliable (P2b) while a post-frame `requestFocus` always works; `unfocus()` on a wrong result needs the node anyway |
| Current approach | Native for the field (`MxTextField` > `FTextField`, `focusNode:`); app-side focus choreography (`requestFocus` post-frame, `unfocus`) |
| Selected approach | Same |
| Why not a higher-level API? | `autofocus` cannot replace an explicit request here (P2b); the node is also needed for `unfocus()` |
| Contract tests | `study_fill_test.dart` (V7, F2, F3). Missing: no test for `unfocus()` on a wrong result |
| Migration status | MIGRATED |
| Correction (if any) | none |

#### CardRemovableTagChipWidget — `lib/features/card/presentation/widgets/items/card_removable_tag_chip_widget.dart`
| Field | Record |
|---|---|
| Existing contract | The shared chip at rest (outline, 32 painted, in a 48 target), label (1 line, ellipsis) and a close glyph; "its whole 48 area removes the tag (ruling P4a-L8)"; its own TalkBack node "Remove {tag}" with `button`, `onTap`, `excludeSemantics` (SW-REV-005) so the editor's row does not merge chips. Tests: `card_primary_text_test.dart` "a removable tag chip: the outline chip's fill, label and glyph", "...TalkBack keeps its tap", "...the chip geometry" (32 tall, shape, icon size, whole widget >= 48, a tap 6 dp above the 32 box still removes); `card_editor_blocks_test.dart:148-160`, `card_editor_screen_test.dart:287` (semantics label, tap removes). |
| Call sites | 1: `card_tag_editor_widget.dart:162` |
| ForUI candidate APIs | `FButton` (xs outline) via `mxChipStyle`, `FFocusedOutline`, `FTappable`; the existing facades `MxChipTrigger` (ghost chip + trailing glyph + `semanticLabel`) and `MxFilterChip` |
| Installed package version | forui 0.27.6 |
| Official documentation | https://forui.dev/docs/widgets/form/button ; https://forui.dev/docs/widgets/foundation/tappable ; https://forui.dev/docs/widgets/foundation/focused-outline |
| Source evidence | `widgets/button/button.dart:37, 188, 198, 288-306` (`semanticsLabel`, `mainAxisSize`, FTappable with focus outline, `excludeSemantics: semanticsLabel != null`); `lib/shared/widgets/mx_chip_trigger.dart:30-52` and `mx_filter_chip.dart:36-47` already build exactly this (`FButton` + `mxChipStyle(context)` + `suffix`) on a 48 target (`mx_chip_style.dart:9-11`, `mx_tap_target.dart:21-60`) |
| API verification | PROBE P4 (`tap` action, label "Remove verb", button, enabled); `test/shared/widgets/mx_filter_chip_test.dart` "unselected: the outline variant, 32 tall inside a 48 target", "keyboard focus draws ForUI's focus outline round the chip", "a 32 chip with a 48 target" exercise the same style/target |
| Native capability | Chip fill/edge/label/glyph tokens, 32 in 48 target, focus ring, hover, press, Enter/Space activation, enabled/button semantics, tap action, label override |
| Capability gaps | `semanticsLabel` drops the node's `isFocusable`/`focus` action for assistive tech (`button.dart:304`; P4 shows `actions=tap`), the same trade the other chips already make. No other gap. |
| Current approach | Fallback: hand-painted chip (`DecoratedBox(mxChipDecoration)`, `Padding(mxChipPadding)`, `IconTheme(mxChipIconTheme)`, `mxChipLabelStyle`, `mxChipGap`) under a bare `GestureDetector` and a manual `Semantics(button, onTap, excludeSemantics)`. Five helper functions in `mx_chip_style.dart` (`mxChipDecoration`, `mxChipLabelStyle`, `mxChipIconTheme`, `mxChipPadding`, `mxChipGap`) have this widget as their only consumer (`rg`: no other use in `lib` or `test`). It has no press, hover or focus state and no keyboard activation: a keyboard/switch user cannot remove a tag. |
| Selected approach | ForUI composition: `FButton` in `mxChipStyle(context)` with a close-glyph suffix, behind a shared Mx widget |
| Why not a higher-level API? | n/a: this is the higher-level native widget; it is not used only because `MxChipTrigger` is ghost-only and "opens a menu" |
| Contract tests | Four test groups above cover geometry, colours, semantics, tap. After the change they need retargeting: the geometry test reads `find.descendant(of: chip, matching: find.byType(DecoratedBox)).first` and `ShapeDecoration`; `mxTargetStyle` insets the decoration (`mx_tap_target.dart:26-50`), so the first `DecoratedBox` differs. Missing today: keyboard focus ring and Enter removal (add as in `mx_filter_chip_test.dart`). |
| Migration status | CORRECTION NEEDED |
| Correction (if any) | Add a shared `MxRemovableChip({label, removeLabel, onRemove})` in `lib/shared/widgets/` (owner approval required: new shared code; alternative: give `MxChipTrigger` an outline/`isGhost: false` parameter) built as `FButton(onPress: onRemove, style: mxChipStyle(context), semanticsLabel: removeLabel, mainAxisSize: MainAxisSize.min, builder: (_, _, _, _, _, _) => Flexible(child: Text(label, maxLines: 1, softWrap: false, overflow: TextOverflow.ellipsis)), suffix: const Icon(AppIcons.close))`, mirroring `MxChipTrigger`. Delete from `card_removable_tag_chip_widget.dart` the `GestureDetector`, outer `Semantics`, `ConstrainedBox`/`Center`/`DecoratedBox`/`Padding`/`IconTheme`/`Row`; delete the five now-unused helpers from `mx_chip_style.dart`. Risks: golden change on card editor goldens (outline chip should be pixel-equal, check with golden-compare); semantic node loses the `focus` action for AT (as every other chip). Tests: retarget the geometry test, add focus-ring and Enter tests, keep the TalkBack tap test. |

#### CardTagEditorWidget (focus) — `lib/features/card/presentation/widgets/sections/card_tag_editor_widget.dart`
| Field | Record |
|---|---|
| Existing contract | Add opens an inline input and focuses it (`:69-72`); Done/Add adds the tag and keeps focus for the next (`:89,100`); a duplicate name clears and refocuses (`:84-88`); Save commits the pending name (`commitPending`, `:107-113`), and a refused name takes focus so its error is in view (final review); `clearInput` for the next card. BR-TAG-001, ruling P4a-L8, critique 2026-09-30 part 3d-2 E8. Tests: `card_tag_input_test.dart` "Add adds the typed tag and keeps the field open", "create: a refused tag stops Save and takes the focus, so its error is in view (final review)", "create: Save adds the pending tag, and the next card starts with none and an empty field", "an invalid tag in the field stops Save and says why". |
| Call sites | 1: `card_editor_form_widget.dart:435` |
| ForUI candidate APIs | `FTextField(focusNode:, autofocus:)` via `MxTextField`; `FAutocomplete`/`FMultiSelect` (tags input) |
| Installed package version | forui 0.27.6 |
| Official documentation | https://forui.dev/docs/widgets/form/text-field ; https://forui.dev/docs/widgets/form/multi-select ; https://forui.dev/docs/widgets/form/autocomplete |
| Source evidence | `text_field.dart:152, 393-399`; catalog "FMultiSelect" (multi-value select with tags, popover list) |
| API verification | PROBE P2b (autofocus is not a re-focus mechanism) |
| Native capability | `focusNode` passthrough |
| Capability gaps | The post-add refocus is an app event (state change then request), not an autofocus case (P2b). `FMultiSelect` selects from a given list; here the person types free new names with the BR-TAG rules (fold, limit 10) and an inline error, which it does not model |
| Current approach | Native field (`MxTextField` > `FTextField`) + app focus choreography; removable chips: see the record above |
| Selected approach | Same |
| Why not a higher-level API? | free-text tag entry with domain rules; no verified ForUI widget does it |
| Contract tests | `card_tag_input_test.dart` (7 tests above, pass) |
| Migration status | MIGRATED |
| Correction (if any) | none (the chip inside it: see CardRemovableTagChipWidget) |

#### CardEditorFormWidget (front-field focus) — `lib/features/card/presentation/widgets/sections/card_editor_form_widget.dart`
| Field | Record |
|---|---|
| Existing contract | After "save and add next" the form clears and focuses the front field (`_clearForNext`, `:280-293`); `FocusNode` passed to `CardFieldWidget` > `MxTextField` (`:410`); `PopScope` guards leaving (`:322`). Tests: `card_editor_keyboard_test.dart`, `card_editor_blocks_test.dart`, `card_editor_screen_test.dart`, `card_tag_input_test.dart` "create: Save adds the pending tag, and the next card starts with none and an empty field". |
| Call sites | 2: `card_editor_screen.dart:45,87` |
| ForUI candidate APIs | `FTextField(focusNode:)` |
| Installed package version | forui 0.27.6 |
| Official documentation | https://forui.dev/docs/widgets/form/text-field |
| Source evidence | `text_field.dart:152` area, `mx_text_field.dart:45,70,165` |
| API verification | PROBE P2b |
| Native capability | `focusNode` to the native field |
| Capability gaps | Re-focus after a save is imperative; `autofocus` cannot do it (P2b) |
| Current approach | Native field, app focus request |
| Selected approach | Same |
| Why not a higher-level API? | n/a (native) |
| Contract tests | the four files above (pass) |
| Migration status | MIGRATED |
| Correction (if any) | none |

#### TopikScoreDonutWidget (custom painting) — `lib/features/topik/presentation/widgets/sections/topik_score_donut_widget.dart`
| Field | Record |
|---|---|
| Existing contract | Screen 38's donut (critique S3): `success` arc over a `muted` track, "{correct} / {total}" and a caption inside; it says nothing to TalkBack itself, its row does ("Its row says the figures to TalkBack"); no arc when total or correct is 0. Test: `topik_summary_widgets_test.dart` "the donut writes correct of total", "the hero: ... and one TalkBack node for the score (critique S2, S3)". |
| Call sites | 1: `topik_summary_hero_widget.dart:76` |
| ForUI candidate APIs | `FCircularProgress` (indeterminate), `FDeterminateProgress` (linear) |
| Installed package version | forui 0.27.6 |
| Official documentation | https://forui.dev/docs/widgets/feedback/circular-progress ; https://forui.dev/docs/widgets/feedback/determinate-progress |
| Source evidence | F6 `circular_progress.dart:36`; F1 (no `drawArc`/`CustomPaint` anywhere in ForUI) |
| API verification | none needed |
| Native capability | none (a spinning glyph is not a donut) |
| Capability gaps | ForUI has no determinate circular indicator or chart (F1, F6) |
| Current approach | Fallback: `CustomPaint` + `CustomPainter` |
| Selected approach | Fallback (unchanged) |
| Why not a higher-level API? | F1, F6 |
| Contract tests | `topik_summary_widgets_test.dart` (text only; nothing asserts the arc fraction or colours) |
| Migration status | MIGRATED (justified Fallback) |
| Correction (if any) | none for ForUI. Observation (not a ForUI item): `_DonutPainter` here and in `lib/shared/widgets/mx_mastery_donut.dart` are two near-identical stroke-arc painters (track + clockwise arc from 12 o'clock, round cap). A shared ring painter would remove the duplicate; adding to `lib/shared` needs owner approval. |

#### TopikQuestionBarChartWidget (bars) — `lib/features/topik/presentation/widgets/sections/topik_question_bar_chart_widget.dart`
| Field | Record |
|---|---|
| Existing contract | One bar per question (height by time, colour by status, glyph and number under it), each bar a control-wide `MxRowInk`; horizontal scroll with edge fade; one summary node for TalkBack and none for the bars (owner 2026-10-17, ruling S4); legend. Tests: `topik_summary_widgets_test.dart` "the time chart names what each colour means". |
| Call sites | 1: `topik_summary_screen.dart:195` |
| ForUI candidate APIs | none (ForUI has no chart); tap target already via `MxRowInk` = `FTappable.static` |
| Installed package version | forui 0.27.6 |
| Official documentation | https://forui.dev/docs/widgets/foundation/tappable |
| Source evidence | F1; `mx_row_ink.dart:104-127` |
| API verification | none needed |
| Native capability | tap/focus/press layer via the facade |
| Capability gaps | no chart widget |
| Current approach | Composition: `MxRowInk` (FTappable.static) per bar, plain Flutter layout for the bars |
| Selected approach | Same |
| Why not a higher-level API? | no ForUI chart |
| Contract tests | the chart test above |
| Migration status | MIGRATED |
| Correction (if any) | none |

#### ReminderTimeDialogWidget (two MxSteppers) — `lib/features/reminders/presentation/widgets/overlays/reminder_time_dialog_widget.dart`
| Field | Record |
|---|---|
| Existing contract | UC-REMINDER-001 A1. **Owner ruling 2026-09-28 (spec D2): "the time is chosen in an `MxDialog` with Hour and Minute `MxStepper`s"** (`24-daily-reminder.md:25,70`); critique 2026-09-30 part 3d-2: two digits "07 : 05"; hold repeats (400 ms delay, 80 ms interval), tap the number to type; a typed out-of-range value marks its stepper and keeps Save off (`:42-50, 66-92`); named buttons "Earlier hour"... for TalkBack (`24-daily-reminder.md:81-82`); shows the chosen "HH:mm". Tests: `reminder_screen_test.dart:315-424` (open dialog, Later hour, Save, out-of-range keeps Save off); `test/shared/widgets/mx_stepper_test.dart` for the stepper. |
| Call sites | 1: `reminder_screen.dart:149` |
| ForUI candidate APIs | `FTimePicker`, `FTimeField` (typed and `.picker`), `FPicker`/`FPickerWheel`, `FDialog` (already under `MxDialog`) |
| Installed package version | forui 0.27.6 |
| Official documentation | https://forui.dev/docs/widgets/form/time-picker ; https://forui.dev/docs/widgets/form/time-field ; https://forui.dev/docs/widgets/form/picker |
| Source evidence | F7 `time_picker.dart:28, 55-77, 130-132`; catalog "FTimeField": `onSubmit` on the typed field is declared but never used (`input/input_time_field.dart:10,21,61`), picker mode is a read-only text field |
| API verification | none needed (decision is the owner ruling, not a missing API) |
| Native capability | `FTimePicker`: hour/minute wheels, 12/24 h, adjustable per-wheel semantics (Up/Down keys, increase/decrease actions). `FTimeField`: typed input or wheel popover, validator on the controller. |
| Capability gaps | None of them is a stepper: no +/- buttons, no hold-to-repeat, no named "Earlier hour/Later minute" buttons, no "invalid typed value keeps Save off" state tied to a two-digit field (F7; catalog "FTimeField"). The owner ruling fixes the interaction to MxSteppers |
| Current approach | Composition: `MxDialog` + `MxSheetActions` + two `MxStepper`s (`MxStepper` is app-built on `FTextField`, `MxRowInk`/tap target, `MxTooltip`, with its own repeat timers) |
| Selected approach | Same, by owner ruling (an `FTimePicker` in `MxDialog` is the ForUI-native alternative if the owner revisits D2) |
| Why not a higher-level API? | Owner ruling 2026-09-28 D2 and UC-REMINDER-001 A1 specify steppers; an owner ruling beats a ForUI preference |
| Contract tests | `reminder_screen_test.dart` covers open, change hour, Save, invalid keeps Save off; the dialog widget has no direct test. Missing: minute stepper path and the 2-digit display are covered only in `mx_stepper_test.dart`/goldens |
| Migration status | BLOCKED (owner ruling) |
| Correction (if any) | none. If the owner chooses to revisit D2: `FTimePicker(control: FTimePickerControl.managed(initial: FTime(h, m), onChange: ...), hour24: true)` inside `MxDialog` through a new Mx facade, dropping `_typed`, `_isHourInvalid`, `_isMinuteInvalid`, `_canSave` and two steppers; handoff 24 rulings, `reminder_screen_test.dart` and the two goldens would change. Not recommended without that decision. |

#### LibrarySearchScreen (focus on arrival) — `lib/features/search/presentation/screens/library_search_screen.dart`
| Field | Record |
|---|---|
| Existing contract | "The person came here to type": the field takes focus on arrival (`:44-48`, post-frame `requestFocus`), and a term given on arrival is typed and searched (FE-B2 spec D11). `MxSearchField(isRouteName: true, focusNode:)` names the route for TalkBack (DEV-393). Tests: `library_search_screen_test.dart` "the field sits in the app bar and takes focus", "a term given on arrival is typed and searched...". |
| Call sites | 1: `app_router.dart:165` |
| ForUI candidate APIs | `FTextField(autofocus: true)` |
| Installed package version | forui 0.27.6 |
| Official documentation | https://forui.dev/docs/widgets/form/text-field |
| Source evidence | `text_field.dart:152, 393-399`; `mx_text_field.dart:55,101,166` (`isAutofocused` exists on `MxTextField`; `MxSearchField` exposes `focusNode` only, `mx_search_field.dart:25,147`); precedent: `trash_purge_dialog_widget.dart:97`, `code_form_widget.dart:128` already use `isAutofocused: true` |
| API verification | PROBE P2: `autofocus` on a pushed route gives focus even when the previous route's button was focused (`hasFocus=true`) |
| Native capability | Focus on a freshly pushed route |
| Capability gaps | `MxSearchField` has no autofocus parameter (shared change); whether TalkBack's route-name announcement (`isRouteName`) is unchanged by autofocus timing is UNVERIFIED |
| Current approach | Native field + app-owned `FocusNode` and a post-frame `requestFocus` (hand-rolled autofocus) |
| Selected approach | Native configuration: `autofocus` through the facade |
| Why not a higher-level API? | n/a (native option exists) |
| Contract tests | the two tests above (assert `hasFocus`); announcements not tested |
| Migration status | CORRECTION NEEDED (low value, optional) |
| Correction (if any) | Add `isAutofocused` to `MxSearchField` (forward to `FTextField(autofocus:)`; shared change, owner approval), then in `LibrarySearchScreen` remove `_focus`, its `dispose`, `focusNode:` and the `requestFocus` line; keep the post-frame `_search(initialQuery)`. Risk: accessibility announcement order (UNVERIFIED, verify on device/TalkBack). Test: existing "takes focus" test must still pass. |

#### AccountTransitionLayerWidget (nested Navigator) — `lib/features/account/presentation/widgets/sections/account_transition_layer_widget.dart`
| Field | Record |
|---|---|
| Existing contract | Account UI spec U4 §5.4/§6, P3a plan ruling 9, DEV-167: a layer over the whole app while a switch/sign-out/deletion/clear runs; its own `Navigator` holds the target sign-in's code step; the host sends system Back to `maybePop` on that navigator; at the root `PopScope(canPop: false)` makes Back = Cancel while Cancel shows, otherwise swallowed; `BlockSemantics` hides the app from TalkBack (`account_layer_host_widget.dart:112`); the code page pops itself when the target signs in (`_LayerCodePage`). Tests: `account_transition_layer_test.dart` (5 states), `account_layer_back_test.dart` ("Back while the layer runs, with no Cancel, is swallowed"), `account_transition_gutter_test.dart`, `test/app/account_flow_routes_test.dart`. |
| Call sites | 1: `account_layer_host_widget.dart:113` (host mounted at `app.dart:196`) |
| ForUI candidate APIs | `FScaffold`/`FHeader` (page frame only), `showFSheet`/`showFDialog`/`showFPersistentSheet` (overlays), `FModalBarrier` |
| Installed package version | forui 0.27.6 |
| Official documentation | https://forui.dev/docs/widgets/layout/scaffold ; https://forui.dev/docs/widgets/overlay/sheet ; https://forui.dev/docs/widgets/overlay/dialog |
| Source evidence | F1 (no `Navigator`/`PageRoute` in ForUI). `FPortal` barrier semantics: "semantics blocking does not work correctly" (`foundation/overlay/portal.dart:256-270`); `showFPersistentSheet` has "no route, no back-button integration" (catalog "showFPersistentSheet"); `showFDialog`/`showFSheet` are routes on the app navigator, not a nested stack with its own Back handling |
| API verification | none needed |
| Native capability | page chrome only (via `MxAppShell`/`MxAppBar`, already used) |
| Capability gaps | ForUI offers no navigator, no route stack, and no layer that owns system Back; overlay routes sit on the app navigator and cannot hold a pushable code step with Back stepping inside the layer |
| Current approach | Fallback for the stack: Flutter `Navigator` + `PageRouteBuilder` (root, zero duration) + `MaterialPageRoute` (code step) + `PopScope`; Composition for the pages (`MxAppShell`, `MxAppBar`, `MxButton`, `MxInlineBanner`, `MxSpinner`, `MxFooterBar`) |
| Selected approach | Same |
| Why not a higher-level API? | F1 and the portal/sheet limits cited |
| Contract tests | the four files above (pass) |
| Migration status | MIGRATED (justified Fallback) |
| Correction (if any) | none |

#### UsersListWidget pull-to-refresh — `lib/features/account/presentation/widgets/sections/users_list_widget.dart`
| Field | Record |
|---|---|
| Existing contract | Pull to refresh over a list that may be shorter than the screen, as screen 28's: `RefreshIndicator` + `AlwaysScrollableScrollPhysics(parent: platform physics)` (`:200-224`); next page prefetched when `extentAfter < 10 rows` via `NotificationListener<ScrollNotification>`. Tests: `users_controller_test.dart` (refresh in the controller); no widget test pulls this list. |
| Call sites | 1: `users_screen.dart:51` |
| ForUI candidate APIs | none |
| Installed package version | forui 0.27.6 |
| Official documentation | n/a (the docs tree has no refresh page: `rg -il "refresh"` in `forui-src/docs/content/docs/widgets` finds only calendar, tabs, toast mentions) |
| Source evidence | F1 (no `RefreshIndicator` or pull-to-refresh anywhere in ForUI) |
| API verification | none needed |
| Native capability | none |
| Capability gaps | no ForUI pull-to-refresh |
| Current approach | Fallback: Material `RefreshIndicator` (`show` import) tinted through the host Material theme built from ForUI colours (`app_theme.dart:56-80`) |
| Selected approach | Same |
| Why not a higher-level API? | F1 |
| Contract tests | Missing: no widget test drives a pull on the users list (the monitoring list has one: `monitoring_screen_test.dart` "pull to refresh asks the first page again") |
| Migration status | MIGRATED (justified Fallback) |
| Correction (if any) | none for ForUI. Observation: the private `_Refreshable` class is byte-identical in this file and in `monitoring_server_list_widget.dart:249-269` (verified with `diff`); a shared owner would remove the duplicate (needs owner approval for `lib/shared`). Add a pull-to-refresh widget test for the users list. |

#### MonitoringServerListWidget pull-to-refresh — `lib/features/monitoring/presentation/widgets/sections/monitoring_server_list_widget.dart`
| Field | Record |
|---|---|
| Existing contract | Same as above for screen 28: pull refreshes the first page; pagination prefetch on scroll. Test: `monitoring_screen_test.dart` "pull to refresh asks the first page again" (flings 400) plus the load-more fling tests (pass). |
| Call sites | 1: `monitoring_server_tab_widget.dart:47` |
| ForUI candidate APIs | none |
| Installed package version | forui 0.27.6 |
| Official documentation | n/a |
| Source evidence | F1 |
| API verification | none needed |
| Native capability | none |
| Capability gaps | no ForUI pull-to-refresh |
| Current approach | Fallback: `RefreshIndicator` + `AlwaysScrollableScrollPhysics` |
| Selected approach | Same |
| Why not a higher-level API? | F1 |
| Contract tests | covered (above) |
| Migration status | MIGRATED (justified Fallback) |
| Correction (if any) | none (dedupe observation under UsersListWidget) |

#### DeckReorderListWidget / DeckReorderRowWidget (drag reorder) — `lib/features/deck/presentation/widgets/sections/deck_reorder_list_widget.dart`
| Field | Record |
|---|---|
| Existing contract | Spec §6.1, ruling P2-L3, M3-D2, D7: drag-to-reorder level, one `MxCard` per deck, handle (`ReorderableDragStartListener`, 48 dp) in the chevron's place, TalkBack move actions from the list, the dropped order shows at once and the stream or a refusal wins, each drop is one `ReorderDeckUseCase` call (`:60-92`). Tests: `deck_reorder_test.dart` ("dragging a deck past the next one saves the new order", "each row offers TalkBack move actions (D7)", "a refused drop snaps back and says why (RF3)", "a level update while a drop saves keeps the dropped order", "reorder mode meets the target guidelines", gutter at 360/700), `deck_reorder_row_widget_test.dart`, `deck_reorder_anchor_test.dart`. |
| Call sites | 1: `deck_level_body_widget.dart:76` |
| ForUI candidate APIs | none |
| Installed package version | forui 0.27.6 |
| Official documentation | n/a (no reorder page in the ForUI docs) |
| Source evidence | F1 (no `ReorderableList*` or drag-sort in ForUI) |
| API verification | none needed |
| Native capability | none |
| Capability gaps | no ForUI drag-reorder list or semantic move actions |
| Current approach | Fallback: Material `ReorderableListView.builder` (`show` import, `buildDefaultDragHandles: false`) with Mx rows |
| Selected approach | Same |
| Why not a higher-level API? | F1 |
| Contract tests | the three files above (pass) |
| Migration status | MIGRATED (justified Fallback) |
| Correction (if any) | none |

#### MonitoringCodeCardWidget (selectable text) — `lib/features/monitoring/presentation/widgets/sections/monitoring_code_card_widget.dart`
| Field | Record |
|---|---|
| Existing contract | A log's message/error/stack trace/context is selectable text, long lines wrap, code in the mono family (handoff 28 lines 52-53, 95; ADR-018 §1 "a log is the one place the app shows an error's own words"); a stack trace is one frame per row in a `SelectionArea` with a joining delegate so a copy returns the trace as written (critique 2026-09-30 part 3d-2). Tests: `monitoring_code_card_test.dart` ("code is the body role in the mono face", "a stack trace frame number is mono in the accent"), `monitoring_trace_test.dart`, `monitoring_detail_screen_test.dart` (pass). |
| Call sites | 4: `monitoring_detail_body_widget.dart:50,69,75,80` |
| ForUI candidate APIs | `FTextField(readOnly: true, enableInteractiveSelection: true)`, `FTappable(selectable: true)` |
| Installed package version | forui 0.27.6 |
| Official documentation | https://forui.dev/docs/widgets/form/text-field ; https://forui.dev/docs/widgets/foundation/tappable |
| Source evidence | F1 (no selectable-text widget); `tappable.dart:125, 703-705` (`selectable` only lets text join an enclosing `SelectionArea`); `text_field.dart:162,175` (`readOnly`, `enableInteractiveSelection`) |
| API verification | none needed |
| Native capability | A read-only `FTextField` can select text |
| Capability gaps | A read-only text field brings field chrome, a textbox semantics node and no per-frame layout or joining copy delegate; the card is rich text in a `MxCard` |
| Current approach | Fallback: Flutter `SelectableText`/`SelectionArea` (selection colours set in the host theme, `app_theme.dart:74-77`) |
| Selected approach | Same |
| Why not a higher-level API? | F1 and the gaps above |
| Contract tests | the three files above |
| Migration status | MIGRATED (justified Fallback) |
| Correction (if any) | none |

#### lib/app/gallery (debug component gallery) — `lib/app/gallery/*.dart` (10 files, 1222 lines)
| Field | Record |
|---|---|
| Existing contract | Debug builds only (ruling G1): every shared widget in its variants and states under a local light/dark and 1x/2x text switch (`gallery_screen.dart:19-80`); opens dialog/sheet/deck picker/snackbar live. Tests: `test/app/gallery_test.dart` (renders, groups present, theme switch, Settings opens it, group F overlays open, Vietnamese). |
| Call sites | routed in `app_router.dart:366` when `hasGallery`; entry from `settings_screen.dart:94` |
| ForUI candidate APIs | n/a |
| Installed package version | forui 0.27.6 |
| Official documentation | n/a |
| Source evidence | `rg` over `lib/app/gallery` for `GestureDetector\|InkWell\|CustomPaint\|AnimatedSwitcher\|FocusNode\|showDialog\|Overlay\|FTappable\|FPopover\|FDialog\|FSheet\|FToast` finds only `Navigator.pop(...)` and `Navigator.of(context).maybePop()` (`gallery_overlays_section.dart:108-168`, `gallery_screen.dart:49`) |
| API verification | none needed |
| Native capability | n/a |
| Capability gaps | none |
| Current approach | Composition of Mx widgets only; `FTheme` wrapper in `gallery_screen.dart:34` (lib/app may import forui) |
| Selected approach | Same |
| Why not a higher-level API? | n/a (no custom interaction) |
| Contract tests | `gallery_test.dart` (pass). Observation: the gallery shows only Mx widgets, so no ForUI-only foundation (`FTappable`, `FPortal`) is exercised there |
| Migration status | MIGRATED |
| Correction (if any) | none |

#### Other hits reviewed, no ForUI item

| Hit | Where | Reading |
|---|---|---|
| `PopScope` | `card_editor_form_widget.dart:322`, `card_list_section_widget.dart:333`, `create_root_deck_dialog_widget.dart:150`, `card_export_sheet_widget.dart:145`, `card_import_screen.dart:69`, `topik_attempt_screen.dart:205`, `study_session_screen.dart:318`, `trash_screen.dart:93`, `account_transition_layer_widget.dart:80` | Back-navigation policy (flutter_widgets), not a ForUI concern; ForUI has no `PopScope` (catalog "showFDialog": "no `PopScope`/`WillPop` anywhere in the forui lib") |
| `AbsorbPointer`/`IgnorePointer` busy guards | `study_grade_row_widget.dart:54`, `card_list_section_widget.dart:359`, `mx_row_ink`-style blocks | State-machine guards (BR-STUDY-004 double-tap, bulk flag), not reimplemented ForUI behaviour |
| `NotificationListener<ScrollNotification>` | `users_list_widget.dart:126`, `monitoring_server_list_widget.dart:169`, `card_list_section_widget.dart:341` | Pagination prefetch; no ForUI scroll-notification API |
| `AppLifecycleListener` | `app.dart:107`, `study_recall_widget.dart:101`, `topik_attempt_screen.dart:83` | Lifecycle, non-UI |
| `MaterialLocalizations.formatTimeOfDay`/`TimeOfDay` | `reminder_settings_section_widget.dart:87-88`, `settings_app_section_widget.dart:79-80` | Time-text formatting only; ForUI's own pickers format with `intl` `DateFormat.Hm/.jm` (`time_picker.dart:130-132`) but expose no formatter API. Not a component, no change proposed |
| `app.dart` (`MaterialApp.router`, `AccountLayerHostWidget` mount) | `app.dart:186-200` | INFRASTRUCTURE (theme host `AppThemeHost` belongs to the theme audit) |
| `FTappable`-backed rows (`MxRowInk`) | e.g. `deck_due_strip_widget.dart:29`, `card_bulk_bar_widget.dart:38`, `theme_choice_card_widget.dart:98`, `topik_question_grid_sheet_widget.dart:137`, `import_source_option_widget.dart:30` | Already the ForUI foundation through the facade; listed so the next reader does not treat them as hand-built taps |

---

### Summary table

| Component | Current | Selected | Status |
|---|---|---|---|
| StudyFaceCardWidget | Fallback (`GestureDetector`) | Fallback | MIGRATED (justified) |
| StudyBrowseWidget | Fallback (drag + custom semantic actions) | Fallback | MIGRATED (justified) |
| StudyGuessWidget (tap anywhere) | Fallback (`GestureDetector`) | Fallback | MIGRATED (justified) |
| StudyAppearingWidget | Fallback (`AnimatedSwitcher`) | Fallback | MIGRATED (justified) |
| StudySettleGuardWidget | Fallback (`AnimationController`, `IgnorePointer`) | Fallback | MIGRATED (justified) |
| StudyRecallWidget (clock) | Fallback (`AnimationController`) | Fallback | MIGRATED |
| RecallCountdownBarWidget | Fallback (hand-built track) | Native `FDeterminateProgress` via shared Mx track | CORRECTION NEEDED |
| StudyFillWidget (focus) | Native field + app focus | same | MIGRATED |
| CardRemovableTagChipWidget | Fallback (hand-painted chip + `GestureDetector`) | Composition: `FButton` + `mxChipStyle` via shared Mx chip | CORRECTION NEEDED |
| CardTagEditorWidget (focus) | Native field + app focus | same | MIGRATED |
| CardEditorFormWidget (focus) | Native field + app focus | same | MIGRATED |
| TopikScoreDonutWidget | Fallback (`CustomPaint`) | Fallback | MIGRATED (justified) |
| TopikQuestionBarChartWidget | Composition (`MxRowInk`) | same | MIGRATED |
| ReminderTimeDialogWidget | Composition (`MxDialog` + 2 `MxStepper`) | same (owner ruling D2) | BLOCKED (owner ruling) |
| LibrarySearchScreen (focus) | Native field + hand-rolled autofocus | Native `autofocus` via `MxSearchField` | CORRECTION NEEDED (low) |
| AccountTransitionLayerWidget | Fallback (`Navigator`, `MaterialPageRoute`) + Composition | same | MIGRATED (justified) |
| UsersListWidget refresh | Fallback (`RefreshIndicator`) | Fallback | MIGRATED (justified) |
| MonitoringServerListWidget refresh | Fallback (`RefreshIndicator`) | Fallback | MIGRATED (justified) |
| DeckReorderListWidget | Fallback (`ReorderableListView`) | Fallback | MIGRATED (justified) |
| MonitoringCodeCardWidget | Fallback (`SelectableText`, `SelectionArea`) | Fallback | MIGRATED (justified) |
| lib/app/gallery | Composition (Mx only) | same | MIGRATED |

Counts: 21 records; MIGRATED 17 (11 of them justified Fallbacks), CORRECTION NEEDED 3, BLOCKED 1.
Tests: 224 run in 27 files, 224 pass, 0 fail (goldens not run).

### Corrections, ordered by value (contract-preserving first, most custom code removed first)

1. **CardRemovableTagChipWidget to a shared `FButton` chip** (`MxRemovableChip`, or an outline option on `MxChipTrigger`). Removes the hand-painted chip, the `GestureDetector` and manual `Semantics` (about 40 lines) and five helpers in `mx_chip_style.dart` that exist only for it; adds focus ring, hover, press and Enter/Space removal that a keyboard or switch user lacks today. Verified by P4 and by `MxFilterChip`/`MxChipTrigger` doing the same on the 48 target. Needs owner approval (new shared code), retargeted geometry test, golden compare.
2. **RecallCountdownBarWidget on `FDeterminateProgress`**, by first moving the shared `MxLinearProgress` onto it (zero-duration motion option). Verified by P1/P1b/P1c; the default 1000 ms motion must not be used (P1). Removes five stacked box widgets here and the same hand-built track in `MxLinearProgress`. Needs owner approval (shared change) and a golden review (fill end-cap shape).
3. **LibrarySearchScreen: `autofocus` through `MxSearchField`**. Removes a `FocusNode`, its dispose and a post-frame line. Verified by P2 for a pushed route; TalkBack route-name order UNVERIFIED. Low value.
4. Not ForUI, for the owner's information only (each needs approval for `lib/shared`): identical `_Refreshable` in two files; two near-identical donut painters (`TopikScoreDonutWidget` and `MxMasteryDonut`); missing tests: users-list pull-to-refresh, browse drag-follow offset, recall/fill `unfocus()`, appearing fade, no-extra-semantics-node for the face-card tap.
5. **Decision for the owner, no code change:** ReminderTimeDialogWidget stays on two `MxStepper`s under owner ruling 2026-09-28 D2; `FTimePicker` is the only ForUI-native alternative (F7) and would replace the typed/stepper contract, so it is BLOCKED unless the owner revisits D2.

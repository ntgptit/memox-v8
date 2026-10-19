# Shared widget inventory after the ForUI migration

Date: 2026-10-17. ForUI: `forui` 0.27.6.

This file inventories the shared UI layer of the MemoX v8 Flutter app after its
move from a hand-built Material 3 design system to ForUI. It covers every Dart
file in `lib/shared/widgets/` (69 files), the theme files in `lib/core/theme/`
(10 files) and `lib/app/app_theme_host.dart` (1 file): 80 files. Each row was
written from reading the file, not from its name. "ForUI components" lists what
the file itself uses; "via `MxX`" means it reaches ForUI only through another
Mx widget. `FTheme` is the theme lookup and is listed only where a file reads
something other than colours, type and dimens from it.

## Classes

Each file has exactly one class.

| Class | Meaning |
|---|---|
| DIRECT_FORUI | A thin facade that renders one ForUI component with little or no restyling (for example `MxToggle` over `FSwitch`). |
| FORUI_ADAPTER | Wraps a ForUI component and adapts behaviour or contract: style deltas, 48 dp target insets, held-route behaviour, API reshaping (for example `MxSnackbarController` over ForUI's `FToast`). |
| FORUI_COMPOSITION | Composes several ForUI components and/or Mx widgets into an app pattern. A file counts here when it instantiates, or is typed on, an Mx widget that renders a ForUI component. |
| CUSTOM_FLUTTER | Built from Flutter widget primitives only, with no ForUI component. The reason is given where the file states one. |
| INFRASTRUCTURE | Theme, host or plumbing with no visible component of its own, or Material used only as infrastructure (`MxAppShell` over `Scaffold`). |
| REVIEW_REQUIRED | Could not be placed with confidence. None in this inventory. |

Where a file states no reason for being custom, the Notes column says only what
the file does. It does not guess why ForUI was not used.

## Summary

| Class | `lib/shared/widgets` | `lib/core/theme` | `lib/app` | Total |
|---|---:|---:|---:|---:|
| DIRECT_FORUI | 3 | 0 | 0 | 3 |
| FORUI_ADAPTER | 24 | 0 | 0 | 24 |
| FORUI_COMPOSITION | 19 | 0 | 0 | 19 |
| CUSTOM_FLUTTER | 23 | 0 | 0 | 23 |
| INFRASTRUCTURE | 5 | 10 | 1 | 16 |
| REVIEW_REQUIRED | 0 | 0 | 0 | 0 |
| **Total** | **74** | **10** | **1** | **85** |

Counts were computed from the Class column of the three tables below, after
the corrections of the ForUI research
([FORUI_RESEARCH_LEDGER.md](FORUI_RESEARCH_LEDGER.md)). The
total (85) equals the number of Dart files listed: 74 from
`rg --files lib/shared/widgets`, 10 in `lib/core/theme/`, plus
`lib/app/app_theme_host.dart`.

## `lib/shared/widgets`

| File | Exports | Class | ForUI components | Material kept | Notes |
|---|---|---|---|---|---|
| `lib/shared/widgets/mx_action_pair.dart` | `MxActionPair` | FORUI_COMPOSITION | via `MxButton` (`FButton`) | none | Side by side when both labels fit (`MxButton.naturalWidth`), otherwise stacked, leading on top. Asserts both buttons are `isBlock` and `isSingleLine`. |
| `lib/shared/widgets/mx_action_sheet_command_row.dart` | `MxActionSheetCommandRow` | FORUI_COMPOSITION | via `MxRowInk` (`FTappable`) | none | 56 dp, 72 dp with a subtitle. `isEnabled: false` dims it and announces it disabled. `isDestructive` is named in colour and words. |
| `lib/shared/widgets/mx_app_bar.dart` | `MxAppBar` | CUSTOM_FLUTTER | none (its slots take `MxIconButton` by contract; uses `MxRouteName`) | none | Minimum `sizeAppBar` tall, grows with text scale. Exactly one of `title` / `titleWidget`. The title names the route. Glyphs sit on the screen margin, the 48 dp touch area reaches past it. |
| `lib/shared/widgets/mx_app_shell.dart` | `MxAppShell` (static `isTypingOf`) | INFRASTRUCTURE | none (paints from the ForUI theme) | `Durations`, `Easing`, `FloatingActionButtonLocation`, `Scaffold`, `ScaffoldPrelayoutGeometry` from `package:flutter/material.dart` | Per the file comment (ADR-026) the SDK `Scaffold` is the layout host only: it places the FAB, resizes the body above the keyboard and carries the bottom bar. `Durations`/`Easing` time the app-bar border fade (instant under reduced motion). App bar and footer are in-flow siblings of the body. |
| `lib/shared/widgets/mx_badge.dart` | `MxBadge`, `MxBadgeTone`, `MxToneBadge` | FORUI_ADAPTER | `FBadge.raw`, `FBadgeStyleDelta` | none | `MxToneBadge` is the one pill (fill and ink from the caller, at least 22 tall, grows with text scale) shared by `MxBadge`, `MxStatusBadge`, `MxTagChip`. A solid `MxBadge` asserts primary tone. |
| `lib/shared/widgets/mx_bar_chart.dart` | `MxBar`, `MxBarChart` | CUSTOM_FLUTTER | none | none | A sideways-scrolling row of bars drawn with fl_chart's `BarChart` (ADR-026, UIL07; audit 2026-10-19, G4): a `sizeControl` cell per bar with its marker and label under it, the cell an `MxRowInk` that opens the bar, a dashed guide at the largest value, the edge fade, the legend. One TalkBack node for the chart; no animation. TOPIK summary (38). |
| `lib/shared/widgets/mx_bottom_nav.dart` | `MxBottomNav`, `MxNavDestination`, `MxNavItem` | DIRECT_FORUI | `FBottomNavigationBar`, `FBottomNavigationBarItem`, `FBottomNavigationBarData` | none | In-flow bar above the gesture inset (`safeAreaBottom`). Tab semantics ("Tab 2 of 4") come from ForUI. `MxNavItem` renders one destination outside a bar, for `MxNavRail`. |
| `lib/shared/widgets/mx_bottom_sheet.dart` | `showMxBottomSheet`, `MxBottomSheet` | FORUI_ADAPTER | `FModalSheetRoute`, `FLayout`, `FTheme.capture` | `MaterialLocalizations` (barrier and grabber strings) | The route is a subclass that mixes in `MxHeldRoute`, pushed on the nearest navigator (owner ruling M3C-52). `isHeld` refuses Back, scrim tap and drag. Caps at 85 % of the screen, only `child` scrolls. Barrier label, hint and the grabber's dismiss label come from `MaterialLocalizations`, because ForUI's Vietnamese strings reach TalkBack broken. `title` is marked as the sheet's heading; a caller that draws its own `header` marks its heading the same way (`Semantics(header: true, namesRoute: true)`), as the merge, tag-actions, starter-scheduler and export sheets do. |
| `lib/shared/widgets/mx_breadcrumb.dart` | `MxBreadcrumb`, `MxBreadcrumbSegment` | FORUI_ADAPTER | `FBreadcrumb`, `FBreadcrumbItem`, `FBreadcrumbStyleDelta`, `FVariants` | none | 48 dp band, scrolls sideways and opens at its end, with `MxScrollFade`. Each crumb is a 48 dp target; an ancestor without a tap is still a button to TalkBack (DEV-306); the current level is announced as selected. |
| `lib/shared/widgets/mx_button.dart` | `MxButton`, `MxButtonTone`, `MxButtonSize` | FORUI_ADAPTER | `FButton`, `FButtonStyle`, `FButtonSizeStyles`, `FButtonSizeVariant`, `FVariants`, `FTappableVariant`, `FTappableVariantConstraint` | none | Adds `dangerTint` and `warning` tones, `chip` and `study` sizes, a detail line, `isLoading` (spinner keeps the width), `semanticLabel`, `naturalWidth`. 48 dp target via `mxTargetStyle`. Null `onPressed` disables. |
| `lib/shared/widgets/mx_card.dart` | `MxCard` | FORUI_ADAPTER | `FCard`, `FCardStyleDelta` | none | Tone flags (hero, warning, success, danger, recessed; at most one, asserted) change the ground. `isSelected` doubles the edge. Sets `MxTintBase` for its content. |
| `lib/shared/widgets/mx_chart_legend.dart` | `MxBarSeries`, `MxChartLegend` | CUSTOM_FLUTTER | none | none | A `space8` dot plus label, wraps. Silent to TalkBack (`ExcludeSemantics`); the chart exposes one summary node. |
| `lib/shared/widgets/mx_chip_row.dart` | `MxChipRow` | CUSTOM_FLUTTER | none | none | Horizontal scroll that clips at its edges plus 4 dp, so ForUI's focus outline on a chip is not cut. |
| `lib/shared/widgets/mx_chip_style.dart` | `mxChipStyle` | FORUI_ADAPTER | `FButtonStyle`, `FButtonSizeVariant.xs`, `FTheme` button styles (outline, ghost) | none | Style resolver, no widget: ForUI's extra-small (32) button inside a 48 dp target (`mxTargetStyle`), outline at rest or ghost. |
| `lib/shared/widgets/mx_chip_trigger.dart` | `MxChipTrigger` | FORUI_ADAPTER | `FButton` | none | A chip that acts on press and never reads as selected: the ghost chip that opens a caller's menu, or with `isGhost: false` the outline chip (the card editor's removable tag). A long label ellipsizes. `semanticLabel` replaces the label; null `onPressed` disables. |
| `lib/shared/widgets/mx_choice_mark.dart` | `MxChoiceMark` | CUSTOM_FLUTTER | none | none | The check or cross of an answered `MxChoiceTile` in the tile's foreground at `sizeIconInline`; idle or selected keep its room empty, so the text beside it holds still (`isMarked` for a centred label). Silent to TalkBack (the tile's label says it). Match (17), Guess (18) and TOPIK review (39) (audit 2026-10-19, G3; final review F2, F7). |
| `lib/shared/widgets/mx_choice_tile.dart` | `MxChoiceTile`, `MxChoiceTone` | FORUI_ADAPTER | `FTappable.static`, `FFocusedOutlineStyleDelta` | `Durations`, `Easing` from `package:flutter/material.dart` | Toned answer surface (idle, selected, right, wrong) on ForUI's tappable; idle is the card (or `muted`) ground inside a `border` hairline, so a tile shows where the card is the page (audit 2026-10-19, G1): Tab reaches it, Enter presses it, ForUI's focus outline sits outside it. Tone eases in (a tone change only: a theme change follows ForUI's own easing, follow-ups spec T1); instant under reduced motion. One semantics node with label, state and `sortKey`; at least `sizeControl` tall; null `onTap` makes it inert. |
| `lib/shared/widgets/mx_code_field.dart` | `MxCodeField` | FORUI_ADAPTER | `FTextField`, `FTextFieldControl.managed` | none | Built by `MxTextField` for the code variant. Six slots are drawn here over one hidden `FTextField`. The comment says `FOtpField` owns its controller type, so this keeps the caller's `TextEditingController`, the paste-replaces-the-code rule and one TalkBack node. |
| `lib/shared/widgets/mx_dashed_note.dart` | `MxDashedNote` | CUSTOM_FLUTTER | none | none | Muted box with a dashed hairline drawn by a `CustomPainter`. A fact, never an error or an action. |
| `lib/shared/widgets/mx_deck_picker_sheet.dart` | `MxPickerCandidate`, `MxDeckPickerSheet`, `MxDeckPickerLoadingSheet`, `MxDeckPickerErrorSheet` | FORUI_COMPOSITION | via `MxBottomSheet`, `MxListRow`, `MxSheetActions`, `MxButton`, `MxDividedColumn` | none | Eligibility is the caller's. An ineligible candidate stays visible, dimmed, with its reason. `isHeld` disables dismiss and every row, so no second target can be picked while the first one's write runs. |
| `lib/shared/widgets/mx_dialog.dart` | `showMxDialog`, `showMxConfirm`, `MxDialog`, `MxDialogWidth` | FORUI_ADAPTER | `FDialog`, `FDialogRoute`, `FTheme.capture` | `MaterialLocalizations` (barrier strings) | The route is a subclass that mixes in `MxHeldRoute`, pushed on the root navigator so the scrim covers the bottom bar. `MxDialog` animates with the route's animation. `showMxConfirm` returns true only on confirm; Cancel, Back and scrim are no. `isHeld` refuses Back and scrim. Width cap 300 / 320 / 340, minimum 280. |
| `lib/shared/widgets/mx_divided_column.dart` | `MxDividedColumn` (static `divided`) | FORUI_COMPOSITION | `MxDivider` | none | Single owner of list dividers: an `MxDivider` (inset 16 dp) between rows, none after the last row. |
| `lib/shared/widgets/mx_divider.dart` | `MxDivider` | FORUI_ADAPTER | `FDivider`, `FDividerStyleDelta` | none | The hairline between two parts: palette `border` colour instead of ForUI's fainter default, inset at each end (16 dp by default), no vertical space. Added 2026-10-18 (closing acceptance AV-3) for Browse's term/meaning line, which drew its own. |
| `lib/shared/widgets/mx_donut.dart` | `MxDonut` | CUSTOM_FLUTTER | none | none | The one ring painter (audit 2026-10-19, G4): a track circle and an arc from twelve o'clock with round caps, the radius filling the box unless given, a child in the middle. `MxMasteryDonut` and the TOPIK score donut draw with it. |
| `lib/shared/widgets/mx_dot_overline.dart` | `MxDotOverline` | CUSTOM_FLUTTER | none | none | Eyebrow with a decorative primary dot (excluded from semantics); label read as typed. |
| `lib/shared/widgets/mx_empty_state.dart` | `MxEmptyState`, `MxEmptyStateTone` | FORUI_COMPOSITION | via `MxCard` (`FCard`), `MxButton`, `MxNote` | none | Tinted tile, title, body, up to three actions and a footnote. The title and the body are one live region (a merged node), as `MxErrorState`'s are. Asserts each action label comes with its callback. |
| `lib/shared/widgets/mx_error_state.dart` | `MxErrorState` | FORUI_COMPOSITION | via `MxCard` (`FCard`), `MxButton` | none | Inline load failure. The title and the body are one live region (a merged node), so "nothing was lost" is announced with the title. Retry shows a spinner while `isRetrying`; `retryLabel` and `onRetry` come together. |
| `lib/shared/widgets/mx_fab.dart` | `MxFab` | FORUI_ADAPTER | `FButton.icon` (`FButtonVariant.primary`, `FButtonSizeVariant.lg`), `FVariantsDelta`, `DecorationDelta`, `FButtonIconContentStyleDelta`, `FTheme` shadow; via `MxTooltip` | none | Square `sizeFab` box; ForUI's shadow added to every decoration variant by a delta. `semanticLabel` is the accessible name and the long-press tooltip, never painted. Placement belongs to `MxAppShell`. |
| `lib/shared/widgets/mx_field_message.dart` | `MxFieldMessage`, `MxFieldMessageTone` | CUSTOM_FLUTTER | none | none | Alert glyph plus caption, a live region, wraps instead of truncating. Used in `MxTextField` and `MxCodeField`. |
| `lib/shared/widgets/mx_filter_chip.dart` | `MxFilterChip` | FORUI_ADAPTER | `FButton` (selected state) | none | `onSelected` receives the flipped value, null disables. A selected chip shows a check. Selection is exposed as state, not only as a look. |
| `lib/shared/widgets/mx_floating_notice.dart` | `MxFloatingNotice` | FORUI_ADAPTER | `FCard`, `DecorationDelta`, `FTheme` shadow | none | Warning-tone standing notice over the page on ForUI's card surface, a live region, wraps. One action sits on the message line, more go on their own line. Placed by `MxAppShell`. |
| `lib/shared/widgets/mx_footer_bar.dart` | `MxFooterBar` | CUSTOM_FLUTTER | none | none | In-flow commit bar. Owns the gesture inset below it. The caption is hidden while the keyboard is up (`MxAppShell.isTypingOf`). |
| `lib/shared/widgets/mx_held_route.dart` | `MxHeldRoute` (mixin), `MxHoldRoute` | INFRASTRUCTURE | none (mixed into the `FDialogRoute` / `FModalSheetRoute` subclasses) | none | Per the comment, ForUI's dialog and sheet barriers pop the route past any `PopScope`. The mixin overrides `barrierDismissible` while held; `MxHoldRoute` also sets `PopScope(canPop: !isHeld)` and syncs the flag after the frame. |
| `lib/shared/widgets/mx_icon_button.dart` | `MxIconButton` | FORUI_ADAPTER | `FButton.icon`, `FButtonVariant.ghost`, `FButtonSizeVariant.lg`, `FButtonStyleDelta`, `FButtonIconContentStyleDelta`; via `MxTooltip` | none | Glyph at `sizeIcon` in a round 48 dp box. `semanticLabel` names it and is its long-press tooltip. Null `onPressed` disables (ForUI dims it). |
| `lib/shared/widgets/mx_icon_tile.dart` | `MxIconTile`, `MxIconTileSize`, `MxIconTileTone` | CUSTOM_FLUTTER | none | none | Tinted square that leads a row; an icon xor a child (asserted); `seed` only with the tinted tone. |
| `lib/shared/widgets/mx_inline_banner.dart` | `MxInlineBanner`, `MxBannerTone` | CUSTOM_FLUTTER | none | none | Tinted ground, no edge, tone on glyph and title. A live region, wraps. Actions are compact `MxButton`s passed by the caller. |
| `lib/shared/widgets/mx_linear_progress.dart` | `MxLinearProgress` (named `.mastery`), `MxProgressTone` | FORUI_ADAPTER | `FDeterminateProgress`, `FDeterminateProgressStyleDelta`, `FDeterminateProgressMotionDelta`, `DecorationDelta` | `Durations`, `Easing` from `package:flutter/material.dart` | Decorative (`ExcludeSemantics`). Shows its value at once on mount (ForUI would sweep from 0), eases a later change, instant under Remove animations (ForUI's rule) or with `isInstant`. `tone` picks success, primary, neutral or warning. The mastery form fills in the `MasteryRamp` colour and keeps the fill at least its height in from either end. |
| `lib/shared/widgets/mx_list_row.dart` | `MxListRow` | FORUI_COMPOSITION | via `MxRowInk` (`FTappable`), `MxSpinner` | none | 56 dp, 72 dp with a subtitle or meta. A disabled or busy row blocks every tap and reads as disabled; it dims leading, title and end but not the subtitle or meta. Subtitle xor meta, trailing xor chevron (asserted). `busyLabel` is what TalkBack hears for the busy spinner; without it the busy state is silent (the tag rows pass "Saving this tag"). |
| `lib/shared/widgets/mx_list_section_header.dart` | `MxListSectionHeader` | CUSTOM_FLUTTER | none | none | Overline read as a heading by screen readers. A trailing widget moves under the label when the row cannot hold both. |
| `lib/shared/widgets/mx_mastery_donut.dart` | `MxMasteryDonut` | CUSTOM_FLUTTER | none | none | Ring drawn by `MxDonut` in the `MasteryRamp` colour. With `semanticLabel` it is one node: label plus percent. |
| `lib/shared/widgets/mx_nav_rail.dart` | `MxNavRail` | FORUI_COMPOSITION | `FSidebar.raw`, `FSidebarStyleDelta`; via `MxNavItem` (`FBottomNavigationBarData`) | none | For windows of `breakpointMedium` and wider. ForUI's sidebar is the frame (background, end hairline); the same item as `MxBottomNav` so the two read as one control. Takes only the inset of its own side; scrolls when short. |
| `lib/shared/widgets/mx_note.dart` | `MxNote` (named `.hint`) | FORUI_COMPOSITION | via `MxIconButton` (dismiss button only) | none | Mostly custom drawing. Info tone only, never an action. A dismissible note must pass `dismissLabel` (asserted). The hint form has no fill or border. |
| `lib/shared/widgets/mx_option_row.dart` | `MxOptionRow` | FORUI_COMPOSITION | `FRadio` (painted only); via `MxRowInk` | none | The whole row is the target (ForUI's radio alone has no 48 dp target). One merged node: checked, mutually exclusive, enabled. Null `onSelected` disables. 56 dp, 72 dp with a description. |
| `lib/shared/widgets/mx_outcome_tile.dart` | `MxOutcomeTile`, `MxOutcomeTone` | CUSTOM_FLUTTER | none | none | Labelled consequence (kept or lost) in its tone's ink over its tint. |
| `lib/shared/widgets/mx_pull_refresh.dart` | `MxPullRefresh` | CUSTOM_FLUTTER | Material `RefreshIndicator`, `AlwaysScrollableScrollPhysics` | none | ForUI has no pull to refresh. Keeps the drag working on a list shorter than the screen. Added 2026-10-18 (closing acceptance AV-1): Users and Monitoring each held the same private wrapper, a Material component inside a feature. A screen that offers it also offers a Refresh action, as the drag has no TalkBack equivalent. |
| `lib/shared/widgets/mx_route_name.dart` | `MxRouteName` | INFRASTRUCTURE | `FPlatformVariant` (read through the platform variant) | none | Semantics only: names the route for a screen reader everywhere but Apple platforms. One such node per route. |
| `lib/shared/widgets/mx_row_ink.dart` | `MxRowInk` | FORUI_ADAPTER | `FTappable.static` (with ForUI's item press timing, `itemStyles.primary.tappableStyle`), `FTappableVariant`, `FFocusedOutlineStyleDelta` | none | Shared tappable-row layer: ForUI press/hover ground and focus outline. `isEnabled: false` blocks every pointer, inner controls included, and says disabled. `isSelected` is said on the row's node. No `onTap` makes a static row. |
| `lib/shared/widgets/mx_screen_scroll.dart` | `MxScreenScroll`, `MxScrollClearance` | CUSTOM_FLUTTER | none | none | The one scroll region of a screen: screen margin plus a tail clearance derived from the pinned chrome and the gesture inset. |
| `lib/shared/widgets/mx_scroll_fade.dart` | `MxScrollFade`, `MxScrollFadeGround` | CUSTOM_FLUTTER | none | none | Gradient over an edge while more content lies past it. A horizontal fade reaches `focusOutlineReach` past each side edge, over a chip row's overhanging focus ring, so that reach must be on its ground (audit 2026-10-19, G6). Decorative: no taps, no semantics. |
| `lib/shared/widgets/mx_search_field.dart` | `MxSearchField` (named `.trigger`) | FORUI_ADAPTER | `FTextField`, `FTextFieldControl.managed`, `FTextFieldStyleDelta`, `FTextFieldSizeVariant`, `FTextFieldVariant`, `FVariants`; the trigger: `FButton`, `FButtonStyleDelta`, `FTappableMotion.noBounceTween`; via `MxIconButton` | `InputBorder`, `OutlineInputBorder` from `package:material_ui` | The import supplies the `InputBorder` type of the field's border slot, used to draw a pill with no edge. The clear button needs `clearLabel`. `isAutofocused` is ForUI's `autofocus`. The `.trigger` form is an `FButton` named by its hint, painted as the resting field. |
| `lib/shared/widgets/mx_section.dart` | `MxSection` | FORUI_COMPOSITION | via `MxCard`, `MxDividedColumn`, `MxListSectionHeader`, `MxNote` | none | Overline, a full-bleed card of rows, an optional note under it. Keeps its own 16 dp below. |
| `lib/shared/widgets/mx_segmented_tray.dart` | `MxSegmentedTray`, `MxSegment` | FORUI_COMPOSITION | `FTappable.static`, `FFocusedOutlineStyleDelta`, `FTheme` shadow | none | The comment says ForUI has no segmented control and `FTabs` owns a content pane, so the tray composes ForUI primitives. Two or three options (asserted); options stack when labels do not fit; each is 48 dp. Null `onSelected` disables; `selected` null draws none as chosen. |
| `lib/shared/widgets/mx_selectable_card_row.dart` | `MxSelectableCardRow` | FORUI_COMPOSITION | via `MxCard`, `MxRowInk`, `MxSelectionCheckbox` (`FCheckbox`) | none | Shared frame for a deck, card or Trash entry: open, long-press into selection, tick. One TalkBack node; `trailing` stays outside the ink with its own tap. A selected row must be selecting (asserted). |
| `lib/shared/widgets/mx_selection_checkbox.dart` | `MxSelectionCheckbox` | FORUI_ADAPTER | `FCheckbox` | none | Painted only (`IgnorePointer`, `ExcludeSemantics`); the caller's row is the tap target and carries the checked semantics. |
| `lib/shared/widgets/mx_settings_row.dart` | `MxSettingsRow` | FORUI_COMPOSITION | via `MxRowInk`, `MxIconTile`; hosts `MxToggle`, `MxButton`, `MxStepper` | none | 56 dp, 72 dp with a subtitle. Chevron only when the row navigates and holds no control. `trailing` xor `wideControl` (asserted). |
| `lib/shared/widgets/mx_sheet_actions.dart` | `MxSheetActions` (named `.single`, `.custom`) | FORUI_COMPOSITION | `FDivider` (the sheet form's rule); via `MxButton`, `MxActionPair` | none | Footer of every dialog and sheet: Cancel and confirm 1 : 1, stacked when a label does not fit. Confirm has one tone (destructive xor warning, asserted); null `onConfirm` disables it. |
| `lib/shared/widgets/mx_skeleton.dart` | `MxSkeleton`, `MxSkeletonRow`, `MxSkeletonPulse`, `MxSkeletonList` | CUSTOM_FLUTTER | none | none | Pulsing placeholder (0.45 to 0.75 opacity), one shared ticker per list, rests at 0.5 under reduced motion. `MxSkeletonList` is read once as `semanticLabel`. |
| `lib/shared/widgets/mx_slider.dart` | `MxSlider` | FORUI_ADAPTER | `FSlider`, `FSliderControl.liftedContinuous`, `FSliderValue` | none | Maps the caller's unit (`value`, `max`, for example milliseconds) to ForUI's fraction and back. `max` of 0 or null `onChanged` disables. One merged TalkBack node. `semanticFormatter` is `String Function(double value)?` and also writes ForUI's tooltip, so the tooltip reads the caller's unit. The inactive track is `border` (style delta), since ForUI's `secondary` equals `muted` (audit 2026-10-19, G2). |
| `lib/shared/widgets/mx_snackbar.dart` | `showMxSnackbar`, `MxSnackbarController`, `mxUndoWindow` | FORUI_ADAPTER | `FToast` (inside `MxToastHost`, a `Stack` above the Navigator, mounted by `app_theme_host.dart`), `FToastMotion` and `context.accessibility` for motion, `MxButton` (outline, small) for the action | none | Not ForUI's toaster: its tap-to-pause gesture lands on the screen's root semantics node as an unlabelled action. Motion is ForUI's toast motion and rule (fade only under reduced motion or TalkBack, none when animations are off). The toast is a live region; a swipe down dismisses it, and a toast kept for TalkBack carries a TalkBack dismiss action too. A new toast replaces the one on screen; when two are shown in one frame the first leaves at once and its `closed` completes. A toast with an action persists while TalkBack is on. A toast with an action leaves when the route of the context that showed it is popped, replaced or removed (`ModalRoute.popped`), since its action acts on that screen; one shown from the root navigator's context (Undo, Tags) outlives every route (owner 2026-10-18, closing acceptance NEW-1). Returns `MxSnackbarController` with `close()` and `closed`. |
| `lib/shared/widgets/mx_spinner.dart` | `MxSpinner`, `MxSpinnerSize` | FORUI_ADAPTER | `FCircularProgress`, `FCircularProgressStyleDelta`, `FCircularProgressMotion`, `FAccessibilityScope` | none | ForUI's progress stands still when animations are off; the scope reports reduced motion instead, so a loading state keeps turning (it is the only sign work is in flight). Silent unless `semanticLabel` is set. |
| `lib/shared/widgets/mx_stacked_day_bars.dart` | `MxDayBar`, `MxStackedDayBars` | CUSTOM_FLUTTER | none (`FTheme`'s tooltip style for the tip's padding and type) | none | Week of stacked bars, drawn with fl_chart's `BarChart` (ADR-026, UIL07; critique 2026-10-19): a dashed guide with the fullest day's count, a tap tooltip with the day's `semanticLabel`, a hairline of the ground (`MxTintBase`) between the parts, a `sizeTrack` floor for a part with any cards taken out of the larger part, so a day's height stays its share of the fullest; the bars ease only when the numbers change. Each bar is one TalkBack node (`semanticLabel`), laid over the chart because fl_chart has no semantics; the drawing, guide and legend say nothing more. `barsHeight` is public (2026-10-19). |
| `lib/shared/widgets/mx_stat_tile.dart` | `MxStatTile`, `MxStatTileEmphasis`, `MxStatTileLayout` | CUSTOM_FLUTTER | none | none | Figure over label, one node reading label then value. `semanticValue` replaces the figure when it reads wrongly aloud. |
| `lib/shared/widgets/mx_status_badge.dart` | `MxStatusBadge`, `MxCardStatus` | FORUI_COMPOSITION | via `MxToneBadge` (`FBadge.raw`) | none | Names a card's lifecycle state. The bare dot form (`isDot`) is a custom 8 dp circle whose semantics label is `label`. |
| `lib/shared/widgets/mx_stepper.dart` | `MxStepper`, `mxStepperRepeatDelay`, `mxStepperRepeatInterval` | FORUI_COMPOSITION | `FButton.icon`, `FButtonSizeVariant.xs`, `FTextField`, `FTextFieldControl.managed`, `FTextFieldStyleDelta`, `FVariants`, `FTheme`; via `MxTooltip`, `MxRowInk`, `MxSpinner`, `mxIconTargetStyle` | `InputBorder` from `package:material_ui` | Holding a step button repeats it (400 ms delay, then 80 ms). A null step callback stops at a bound. The number is typeable when `onValueSubmitted` is set. `valueLabel` wraps the typing field, but TalkBack reaches ForUI's edit box unnamed (REG-CA-6, accepted by the owner 2026-10-19 until ForUI takes a semantics label). Step buttons are 32 dp paint in a 48 dp target. |
| `lib/shared/widgets/mx_study_top_bar.dart` | `MxStudyTopBar` | FORUI_COMPOSITION | via `MxIconButton`, `MxRouteName`, `MxToneBadge` (`FBadge.raw`), `MxLinearProgress` (`FDeterminateProgress`) | none | Close, mode chip, thin progress track, counter. Null `onClose` disables Close. The counter is a live region. The mode names the route. |
| `lib/shared/widgets/mx_tag_chip.dart` | `MxTagChip` | FORUI_COMPOSITION | via `MxToneBadge` (`FBadge.raw`) | none | Read-only tag, 22 dp or 18 dp dense, at most 140 wide. The removable chip in the card editor is a different control. |
| `lib/shared/widgets/mx_tap_target.dart` | `mxTargetStyle`, `mxIconTargetStyle`, `mxInsetDecoration`, `MxInsetShapeBorder` | FORUI_ADAPTER | `FButtonStyle`, `FButtonContentStyleDelta`, `FButtonIconContentStyleDelta`, `FVariants`, `FTappableVariant`, `FTappableVariantConstraint` | none | Style helpers, no widget. Keep a ForUI button on a 48 dp target while it paints smaller (40 small button, 32 chip or stepper step): the decoration is inset inside the target. `isLoading` keeps the resting decoration. |
| `lib/shared/widgets/mx_text_field.dart` | `MxTextField`, `MxTextFieldVariant` | FORUI_ADAPTER | `FTextField`, `FTextFieldControl.managed`, `FTextFieldStyleDelta`, `FTextFieldSizeVariant`, `FTextFieldVariant`, `FTextFieldVariantConstraint`, `FVariants` | `InputBorder` from `package:material_ui` | Variants form, detail, term, study, code (code builds `MxCodeField`). Label is announced with the value. Leading and trailing slots only on the form variant (asserted). `onChanged` fires only for the person's edits (`MxUserEdits`). The bare study field gets a 48 dp floor, and asks the keyboard for no suggestions and no autocorrect (a typed answer is the answer, BR-STUDY-026); the other variants keep both. |
| `lib/shared/widgets/mx_tint_base.dart` | `MxTintBase` | INFRASTRUCTURE | none | none | Inherited ground colour that tints are laid over (`tintOver`). Set by `MxCard`, `MxBottomSheet`, `MxDialog`; defaults to the ForUI `background`. |
| `lib/shared/widgets/mx_toggle.dart` | `MxToggle` | DIRECT_FORUI | `FSwitch` | none | Inside a 48 dp box that flips on a tap anywhere in it. One TalkBack node with label and toggled state. Null `onChanged` disables. |
| `lib/shared/widgets/mx_tooltip.dart` | `MxTooltip` | DIRECT_FORUI | `FTooltip` | none | Shows `label` on long press, hover or focus. Wrapped in `MergeSemantics` so ForUI's long-press action folds into the control's labelled node. |
| `lib/shared/widgets/mx_two_columns.dart` | `MxTwoColumns` | CUSTOM_FLUTTER | none | none | One column, or two from a content width of 672. Chooses by the width it is given, not the window size class. |
| `lib/shared/widgets/mx_user_edits.dart` | `MxUserEdits` | INFRASTRUCTURE | none imported; plugs into the `onChange` of `FTextFieldControl.managed` and the field's input formatters | none | Reports only the person's edits (type, paste, delete), not selection moves, IME composing or text the code sets. Used by `MxTextField`, `MxSearchField`, `MxCodeField`. |
| `lib/shared/widgets/mx_workload_breakdown_line.dart` | `MxWorkloadBreakdownLine` | CUSTOM_FLUTTER | none | none | "N overdue · N today · N new" with a fixed colour per term, in the `meta` role (12/500). Zero terms drop out unless `shouldKeepZeroTerms`. With `hasIcons` the line is read as its words alone. Imports `meta_line` from `lib/l10n`. |

## `lib/core/theme`

| File | Exports | Class | ForUI components | Material kept | Notes |
|---|---|---|---|---|---|
| `lib/core/theme/app_dimens.dart` | `AppDimens` | INFRASTRUCTURE | none imported (rides on `FThemeData.extensions`) | `ThemeExtension` from `package:material_ui` | Spacing scale, margins, breakpoints and the few layout sizes shared widgets use. The comment says component geometry (button, field, chip sizes, radii, borders, focus rings) is ForUI's and is not duplicated here. Does not interpolate. |
| `lib/core/theme/app_icons.dart` | `AppIcons` | INFRASTRUCTURE | `FLucideIcons` (`package:forui/assets.dart`) | none | Every glyph mapped once, by meaning, to ForUI's Lucide set. Lucide has no filled variants, so a selected destination's glyph is its resting glyph. |
| `lib/core/theme/app_palette.dart` | `appLightColors`, `appDarkColors` | INFRASTRUCTURE | `FColors` | none | The one place colour values are written. Light: ForUI's neutral palette with three stated deltas (indigo `primary`, `mutedForeground` for 4.5:1 on `muted`, darker `error`/`destructive`). Dark: the navy page `#0A082D` and the indigo `#564BCB` kept from before the migration, every other value computed from those two and written as hex. Carries `MxStatusColors` in `extensions`. |
| `lib/core/theme/app_theme.dart` | `buildLightTheme`, `buildDarkTheme`, `themeFor`, `materialHostTheme` | INFRASTRUCTURE | `FThemeData` (`touch: true`), `FColors`, `FTypography` | `package:flutter/material.dart` as `sdk` (`ThemeData`, `ColorScheme`, `TextTheme`, `NoSplash`, ...) | `materialHostTheme` derives an SDK theme one way from the ForUI theme for `MaterialApp.router`, the `Scaffold` in `MxAppShell` and the `RefreshIndicator` of two lists. The comment says it has no component themes and nothing reads it back. |
| `lib/core/theme/app_typography.dart` | `AppTypography`, `MxTextRoles` | INFRASTRUCTURE | `FTypography`, `FTypeface`, `FColors` | none | ForUI touch sizes in Be Vietnam Pro with Noto Sans KR fallback. Line heights are raised to at least 1.4 (ForUI's 12 and 14 clip Vietnamese diacritics). `MxTextRoles` holds no value of its own; weights stop at 600. |
| `lib/core/theme/color_tint.dart` | `ColorTint` (`tintOver`) | INFRASTRUCTURE | none | none | A state colour at 16 % over a base surface, rounded per channel. |
| `lib/core/theme/mastery_ramp.dart` | `MasteryRamp` | INFRASTRUCTURE | `FColors` | none | One threshold function (34 %, 67 %) for every mastery fill and text colour; track is `colors.muted`. Paints nothing itself. |
| `lib/core/theme/mx_status_colors.dart` | `MxStatusColors` | INFRASTRUCTURE | `FColors.extensions` (carrier) | `ThemeExtension` from `package:material_ui` | Success, warning and info colours ForUI's `FColors` has no role for, each as ink and fill, and `accentMark` (accent icons and the label on the accent tint: `primary` in light, the text colour in dark). Read as `context.status`. |
| `lib/core/theme/theme_context.dart` | `ThemeContext` (`colors`, `texts`, `status`, `dimens`, `radii`, `hairline`) | INFRASTRUCTURE | `FTheme`, `FColors`, `FBorderRadius` | none | The one way UI code reads the theme. Throws a `StateError` naming the fix when the app's extensions are missing from the `FTheme` in scope. |
| `lib/core/theme/theme_rules.dart` | `WindowSize`, `WindowWidthScope`, `ThemeRules` (`windowSize`, `screenMargin`) | INFRASTRUCTURE | none | none | Window size class and screen margin. `WindowWidthScope` lets a shell that narrows the MediaQuery publish the whole window's width. |

## `lib/app`

| File | Exports | Class | ForUI components | Material kept | Notes |
|---|---|---|---|---|---|
| `lib/app/app_theme_host.dart` | `AppThemeHost`, `resolveBrightness` | INFRASTRUCTURE | `FTheme`, the theme's `scaffoldStyle.systemOverlayStyle` | `ThemeMode` from `package:flutter/material.dart`; `package:material_ui` as `forui_material` for `Theme` | Sits in `MaterialApp.builder`, above the Navigator, so every route, dialog, sheet and overlay inherits one theme. Puts ForUI's status-bar style in an `AnnotatedRegion` (Material's `Scaffold` applies none). The `material_ui` `Theme` is ForUI's `toApproximateMaterialTheme()` bridge for the few `material_ui` pieces ForUI builds on; nothing reads it back. |

## Breaking public API changes

Each item was checked against the code in this branch and against `master`
(read with `git show master:<path>`). Callers were found with `rg` over `lib/`
and `test/`.

### 1. `showMxSnackbar` returns `MxSnackbarController`; `buildMxSnackBar` and `MxSnackbarContent` are removed

Verified. On `master`, `lib/shared/widgets/mx_snackbar.dart` returned
`ScaffoldFeatureController<SnackBar, SnackBarClosedReason>` and defined
`buildMxSnackBar` and `MxSnackbarContent`. Now `showMxSnackbar` returns
`MxSnackbarController` (`close()`, `closed`), and neither removed symbol exists
in `lib/`. Both are listed in `tools/design/removed_symbols.json`.

The parameters of `showMxSnackbar` (`message`, `actionLabel`, `onAction`,
`duration`) are unchanged, so a caller that ignores the return value needs no
edit. Only a caller that used the old `ScaffoldFeatureController` API would.

Callers of `showMxSnackbar` (45 files in `lib/`):

- Return value used: none since 2026-10-18; `monitoring_detail_screen.dart` and `reminder_screen.dart` closed their toast on dispose, which `showMxSnackbar` now does for every toast with an action.
- Return value ignored:
  - `lib/app/gallery/gallery_overlays_section.dart`
  - `lib/features/account/presentation/screens/welcome_screen.dart`
  - `lib/features/account/presentation/widgets/overlays/merge_choice_sheet_widget.dart`
  - `lib/features/account/presentation/widgets/overlays/user_role_sheet_widget.dart`
  - `lib/features/account/presentation/widgets/sections/account_layer_host_widget.dart`
  - `lib/features/account/presentation/widgets/sections/account_transition_layer_widget.dart`
  - `lib/features/account/presentation/widgets/sections/code_form_widget.dart`
  - `lib/features/account/presentation/widgets/sections/sign_in_form_widget.dart`
  - `lib/features/account/presentation/widgets/support/account_labels_widget.dart`
  - `lib/features/card/presentation/widgets/overlays/card_delete_dialog_widget.dart`
  - `lib/features/card/presentation/widgets/overlays/card_move_sheet_widget.dart`
  - `lib/features/card/presentation/widgets/overlays/card_tag_dialog_widget.dart`
  - `lib/features/card/presentation/widgets/sections/card_deck_app_bar_widget.dart`
  - `lib/features/card/presentation/widgets/sections/card_editor_form_widget.dart`
  - `lib/features/card/presentation/widgets/sections/card_list_section_widget.dart`
  - `lib/features/card/presentation/widgets/support/card_trashed_snackbar_widget.dart`
  - `lib/features/deck/presentation/screens/deck_algorithm_screen.dart`
  - `lib/features/deck/presentation/widgets/overlays/create_root_deck_dialog_widget.dart`
  - `lib/features/deck/presentation/widgets/overlays/deck_delete_dialog_widget.dart`
  - `lib/features/deck/presentation/widgets/overlays/deck_move_sheet_widget.dart`
  - `lib/features/deck/presentation/widgets/overlays/deck_name_dialog_widget.dart`
  - `lib/features/deck/presentation/widgets/overlays/deck_reset_dialog_widget.dart`
  - `lib/features/deck/presentation/widgets/sections/deck_reorder_list_widget.dart`
  - `lib/features/deck/presentation/widgets/support/deck_actions_flow_widget.dart`
  - `lib/features/deck/presentation/widgets/support/deck_trashed_snackbar_widget.dart`
  - `lib/features/monitoring/presentation/widgets/items/monitoring_detail_row_widget.dart`
  - `lib/features/reminders/presentation/screens/reminder_screen.dart`
  - `lib/features/settings/presentation/screens/language_screen.dart`
  - `lib/features/settings/presentation/screens/settings_screen.dart`
  - `lib/features/settings/presentation/screens/study_defaults_screen.dart`
  - `lib/features/settings/presentation/screens/study_options_screen.dart`
  - `lib/features/settings/presentation/screens/sync_screen.dart`
  - `lib/features/settings/presentation/screens/theme_screen.dart`
  - `lib/features/settings/presentation/widgets/items/sql_log_row_widget.dart`
  - `lib/features/starter_decks/presentation/screens/starter_library_screen.dart`
  - `lib/features/study/presentation/screens/study_entry_screen.dart`
  - `lib/features/study/presentation/screens/study_home_screen.dart`
  - `lib/features/study/presentation/screens/study_session_screen.dart`
  - `lib/features/tags/presentation/screens/tags_screen.dart`
  - `lib/features/topik/presentation/screens/topik_attempt_screen.dart`
  - `lib/features/topik/presentation/screens/topik_test_detail_screen.dart`
  - `lib/features/transfer/presentation/widgets/overlays/card_export_sheet_widget.dart`
  - `lib/features/trash/presentation/widgets/overlays/trash_purge_dialog_widget.dart`
  - `lib/features/trash/presentation/widgets/overlays/trash_restore_sheet_widget.dart`
- Doc comment only: `lib/app/app_theme_host.dart`.
- Tests: `test/shared/widgets/mx_snackbar_test.dart` (uses `MxSnackbarController`).

Callers of the removed symbols: none in `lib/` or `test/` (`rg` finds both
names only in `tools/design/removed_symbols.json`).

### 2. `mx_chip_style.dart` helpers replaced

Verified. `master` exported `MxChipPaint`, `chipPaint`, `chipDecoration`,
`chipStartInset`, `chipEndInset`, `chipGap` and `chipButtonStyle`, all read
from Material's `ChipThemeData`. The file now exports only `mxChipStyle`,
resolved from ForUI's button styles (the five resting-box helpers the removable
tag chip used went with it when that chip became an `MxChipTrigger`). None of the old names
remains in `lib/` or `test/` (they are mapped in `tools/design/removed_symbols.json`).

Importers of `mx_chip_style.dart`:

- `lib/shared/widgets/mx_filter_chip.dart` (`mxChipStyle`)
- `lib/shared/widgets/mx_chip_trigger.dart` (`mxChipStyle`, ghost)
- The card editor's removable tag reaches it through `MxChipTrigger(isGhost: false)`.

### 3. `MxSlider.semanticFormatter` is `String Function(double value)?`

Verified, with one qualification. On `master` the field was typed with
Material's `SemanticFormatterCallback?`. It is now declared as
`String Function(double value)?`. The signature is the same shape, so a caller
passing a closure needs no change; only code that named the Material typedef
would. The formatter still receives the value in the caller's unit
(`next * max`; the slider itself runs on a 0 to 1 fraction internally).

Callers:

- `lib/features/topik/presentation/widgets/sections/topik_audio_bar_widget.dart` (passes `semanticFormatter: timeOf`)
- `lib/app/gallery/gallery_inputs_section.dart` (`MxSlider`, no formatter)
- `test/shared/widgets/mx_slider_test.dart` (passes a formatter)
- `test/shared/widgets/input_widgets_golden_test.dart` (`MxSlider`, three uses)

### 4. New public symbols

Verified: none of these names exists on `master`. They are additions, not
breaking by themselves. Callers found:

| Symbol | Defined in | Callers |
|---|---|---|
| `MxToneBadge` | `lib/shared/widgets/mx_badge.dart` | `lib/shared/widgets/mx_badge.dart` (`MxBadge`), `lib/shared/widgets/mx_status_badge.dart`, `lib/shared/widgets/mx_tag_chip.dart` |
| `MxTooltip` | `lib/shared/widgets/mx_tooltip.dart` | `lib/shared/widgets/mx_icon_button.dart`, `lib/shared/widgets/mx_fab.dart`, `lib/shared/widgets/mx_stepper.dart` |
| `MxUserEdits` | `lib/shared/widgets/mx_user_edits.dart` | `lib/shared/widgets/mx_text_field.dart`, `lib/shared/widgets/mx_search_field.dart`, `lib/shared/widgets/mx_code_field.dart` |
| `MxHeldRoute`, `MxHoldRoute` | `lib/shared/widgets/mx_held_route.dart` | `lib/shared/widgets/mx_dialog.dart` (route mixin and `MxHoldRoute`), `lib/shared/widgets/mx_bottom_sheet.dart` (route mixin and `MxHoldRoute`) |
| `MxInsetShapeBorder` | `lib/shared/widgets/mx_tap_target.dart` | `test/support/forui_expect.dart` (unwraps `.base` in a test helper); built inside `mxInsetDecoration` |
| `mxInsetDecoration` | `lib/shared/widgets/mx_tap_target.dart` | `lib/shared/widgets/mx_tap_target.dart` only (inside `mxTargetStyle` and `mxIconTargetStyle`); named in a comment in `test/support/forui_expect.dart` |
| `mxTargetStyle` | `lib/shared/widgets/mx_tap_target.dart` | `lib/shared/widgets/mx_button.dart`, `lib/shared/widgets/mx_chip_style.dart` |
| `mxIconTargetStyle` | `lib/shared/widgets/mx_tap_target.dart` | `lib/shared/widgets/mx_stepper.dart` |

Additions from the research corrections, all optional parameters with the
old behaviour as default: `MxProgressTone` and `MxLinearProgress.tone` /
`isInstant` (`lib/shared/widgets/mx_linear_progress.dart`; callers
`mx_study_top_bar.dart`, `recall_countdown_bar_widget.dart`),
`MxChipTrigger.isGhost` (caller `card_removable_tag_chip_widget.dart`),
`MxSearchField.isAutofocused` (caller `library_search_screen.dart`).

No feature code under `lib/features/` calls any of the symbols in the table
directly.

## Judgment calls

No file is REVIEW_REQUIRED. These placements were close and are stated so a
reviewer can overrule them:

- `mx_toggle.dart` is DIRECT_FORUI as the brief names it, although it adds a 48 dp box and its own semantics node around `FSwitch`.
- `mx_bottom_nav.dart` is DIRECT_FORUI for `MxBottomNav`; `MxNavItem` in the same file reshapes `FBottomNavigationBarData` for use outside a bar.
- `mx_chip_style.dart` and `mx_tap_target.dart` hold style helpers with no widget. They are FORUI_ADAPTER (they reshape `FButtonStyle`, including the 48 dp target), not INFRASTRUCTURE.
- `mx_selection_checkbox.dart` is FORUI_ADAPTER, not DIRECT_FORUI, because it removes input and semantics from `FCheckbox`.
- `mx_divider.dart` is FORUI_ADAPTER because it overrides `FDivider`'s colour and padding; `mx_divided_column.dart` composes it.
- `mx_app_bar.dart` and `mx_footer_bar.dart` are CUSTOM_FLUTTER because the file itself draws no ForUI component; their callers fill them with `MxIconButton` / `MxButton`.
- `mx_note.dart` is FORUI_COMPOSITION only because of its optional dismiss `MxIconButton`; the rest is custom drawing.

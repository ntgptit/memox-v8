# Shared widgets review fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix the shared-widget review findings SW-REV-001 to 007, 010 and 011 at their shared root, so every screen inherits the fix.

**Architecture:** Every fix lands in `lib/shared/widgets/` or `lib/core/theme/`; callers change only to drop a workaround the shared fix makes redundant, or where the review placed the fix in the caller (SW-REV-011). No new widget and no new public component.

**Tech Stack:** Flutter 3.47.5, Dart 3.13, the repo's widget harness (`test/support/widget_harness.dart`), `run_tests.sh`, `run_goldens.sh`, `dod_check.sh`.

**Spec:** the review findings recorded as comments on Linear DEV-135 on 2026-10-07 (SW-REV-001 to 011), and `DESIGN.md`.

## Global Constraints

- Colours only from the theme; text and glyph inks hold 4.5:1, non-text edges 3:1 on page, row, low and sheet grounds, in both themes (`DESIGN.md` › The Contrast Floor Rule).
- The edge of every control that must hold 3:1 is `derivedColors.outlineEdge` (`DESIGN.md` › Neutral).
- 0.38 (`AppOpacity.disabled`) is for controls that cannot be used, not for work in progress (`DESIGN.md` › MxButton).
- System insets, the keyboard included, come from the platform (`DESIGN.md` › Layout).
- No hard-coded colour, size or text style; the guard's design-token rules hold.
- Out of scope, waiting on the owner: SW-REV-008 and 009 (new shared API), the tone of the "gone" state, the wording of the two selection close labels.

## Review Focus

- A dialog with a field on a short phone with the keyboard up: the actions stay above the keyboard (Task 3 test).
- A dialog taller than the space left by the keyboard: its text scrolls and its actions stay visible (Task 3 test).
- Back, a scrim tap and Cancel while a held dialog works: none closes it (Task 3 test).
- A loading button whose caller also nulls `onPressed`: it does not dim (Task 2 test).
- A chip label wider than its column: no overflow (Task 6 test).

---

### Task 1: Contrast of control edges, warning glyphs, donut label and chip count (SW-REV-001)

**Files:**
- Modify: `lib/shared/widgets/mx_option_row.dart`, `mx_selection_checkbox.dart`, `mx_toggle.dart`, `mx_field_message.dart`, `mx_floating_notice.dart`, `mx_mastery_donut.dart`, `mx_filter_chip.dart`
- Modify: `lib/core/theme/mastery_ramp.dart`
- Test: `test/core/theme/token_contrast_test.dart`, `test/core/theme/mastery_ramp_test.dart`, the widget tests that pin the old colours

**Interfaces:**
- Produces: `MasteryRamp.ink(MxSemanticColors, MxDerivedColors, double fraction) -> Color` (the status ink of the band; the learning ink at 0).

- [ ] **Step 1: Write the failing tests**
  - `token_contrast_test.dart`: in the control-edge loop (page, field fill, card, sheet, warning ground) add nothing new for `outlineEdge`; replace the pair `('toggle off edge on a row', scheme.outline, row, _nonText)` with the three control edges on every ground, using `derived.outlineEdge`. Add `('warning glyph on the page', derived.warningInk, page, _text)`, `('donut label on the hero', MasteryRamp.ink(..., 0.5), derived.surfaceHero, _text)` and the mastered twin at 0.9, `('selected chip count', scheme.onPrimary, scheme.primary, _text)`.
  - Widget tests: radio, checkbox and toggle off edge expect `derivedColors.outlineEdge`; field message and floating notice warning glyph expect `derivedColors.warningInk`; donut label expects `MasteryRamp.ink`; selected chip count expects full `onPrimary`.
- [ ] **Step 2: Run them and see them fail** (`run_tests.sh` on the touched test files).
- [ ] **Step 3: Implement**
  - Radio, checkbox, toggle: `colors.outline` → `context.derivedColors.outlineEdge`.
  - Field message and floating notice: the warning glyph → `context.derivedColors.warningInk`.
  - `MasteryRamp.ink`: `fraction < 0.34` (0 included) → `derived.statusLearningInk`; `< 0.67` → `derived.statusReviewingInk`; else `derived.statusMasteredInk`. The donut keeps `fill` for the arc and takes `ink` for its label.
  - Filter chip: the selected count is `onPrimary` at full strength (white on #5265F5 is only 4.77:1, so no alpha below 1 passes); the resting count keeps its 0.6.
- [ ] **Step 4: Run the tests and see them pass.**
- [ ] **Step 5: Commit** `Shared widgets: control edges on Outline Edge, warning glyphs and donut label in their ink (SW-REV-001)`.

### Task 2: A loading button is not dimmed (SW-REV-003)

**Files:** Modify `lib/shared/widgets/mx_button.dart`; Test `test/shared/widgets/mx_button_test.dart`.

- [ ] **Step 1: Failing test** — `MxButton(label: 'Save', isLoading: true, onPressed: null)` has no `Opacity` ancestor of its `TextButton`, shows `MxSpinner`, and ignores taps.
- [ ] **Step 2: Run, see it fail.**
- [ ] **Step 3: Implement** — `if (onPressed != null || isLoading) return sized;` and say in the `isLoading` doc that loading wins over the disabled dim.
- [ ] **Step 4: Run, see it pass.**
- [ ] **Step 5: Commit** `MxButton: work in progress is not drawn as disabled (SW-REV-003)`.

### Task 3: MxDialog avoids the keyboard and can be held (SW-REV-002, SW-REV-004)

**Files:**
- Modify: `lib/shared/widgets/mx_dialog.dart`, `mx_sheet_actions.dart`, `mx_deck_picker_sheet.dart`
- Modify callers: `card_delete_dialog_widget.dart`, `deck_delete_dialog_widget.dart`, `deck_reset_dialog_widget.dart`, `settings_reset_dialog_widget.dart`, `trash_purge_dialog_widget.dart`, `card_move_sheet_widget.dart`, `deck_move_sheet_widget.dart`, `trash_restore_sheet_widget.dart`
- Test: `test/shared/widgets/mx_dialog_test.dart`, `mx_sheet_actions_test.dart`, `mx_deck_picker_sheet_test.dart`

**Interfaces:**
- Produces: `MxDialog({…, bool isHeld = false})`; `MxDeckPickerSheet({…, bool isHeld = false})`. `MxSheetActions` disables Cancel while `isConfirmLoading`.

- [ ] **Step 1: Failing tests**
  - Keyboard: 360×640 view, `viewInsets.bottom = 300`, an `MxDialog` with a title, an `MxTextField` and `MxSheetActions`; the confirm's bottom edge is at most 340.
  - Tall dialog: a body of 40 lines under the same keyboard; the confirm is still on screen and the text scrolls.
  - Hold: `MxDialog(isHeld: true)` opened with `showMxDialog`; `tester.binding.handlePopRoute()` and a tap on the scrim leave it open.
  - `MxSheetActions(isConfirmLoading: true, onCancel: …)`: Cancel's `onPressed` is null.
- [ ] **Step 2: Run, see them fail.**
- [ ] **Step 3: Implement**
  - `MxDialog.build`: wrap the `Center` in `AnimatedPadding(padding: MediaQuery.viewInsetsOf(context), duration: disableAnimations ? Duration.zero : AppDurations.fast, curve: Easing.standard)` and wrap the result in `PopScope(canPop: !isHeld)`. The scrim tap goes through `Navigator.maybePop`, so the `PopScope` holds it too.
  - `MxSheetActions`: Cancel gets `onPressed: isConfirmLoading ? null : onCancel`; update the two doc comments.
  - `MxDeckPickerSheet`: pass `isHeld` to its `MxBottomSheet`.
  - Callers: the three delete/reset dialogs pass `isHeld: _isWorking`; settings reset and trash purge drop their own `PopScope` for `isHeld`; the three picker sheets pass `isHeld` while their move or restore runs.
- [ ] **Step 4: Run, see them pass**, plus the callers' feature tests.
- [ ] **Step 5: Commit** `MxDialog: pad for the keyboard and hold while its work runs (SW-REV-002, SW-REV-004)`.

### Task 4: TalkBack actions and states of shared controls (SW-REV-005, SW-REV-006)

**Files:**
- Modify: `lib/shared/widgets/mx_button.dart`, `mx_row_ink.dart`, `mx_option_row.dart`, `mx_toggle.dart`, `mx_list_section_header.dart`, `mx_error_state.dart`
- Modify callers: `trash_entry_row_widget.dart`, `card_row_widget.dart`, `theme_choice_card_widget.dart`, `card_removable_tag_chip_widget.dart`, `reminder_settings_section_widget.dart`
- Modify: `test/support/widget_harness.dart`
- Test: the shared widgets' tests and the callers' feature tests

**Interfaces:**
- Produces: `MxButton({…, String? semanticLabel})`; `MxRowInk({…, VoidCallback? onLongPress})`; `expectSemanticAction(WidgetTester, Finder, SemanticsAction)` in the harness.

- [ ] **Step 1: Failing tests**
  - Harness helper reads `tester.getSemantics(finder).getSemanticsData().hasAction(action)`.
  - Trash row: tap and long-press actions on its node; theme card and removable tag chip: tap action; reminder time button: tap action and its label.
  - `MxOptionRow(onSelected: null)` and `MxToggle(onChanged: null)`: node has `hasEnabledState` and not `isEnabled`.
  - `MxListSectionHeader`: node is a header. `MxErrorState`: a live region.
- [ ] **Step 2: Run, see them fail.**
- [ ] **Step 3: Implement**
  - `MxButton.semanticLabel`: when set, `Semantics(label: semanticLabel, button: true, enabled: onPressed != null && !isLoading, onTap: …, excludeSemantics: true, child: button)`.
  - `MxRowInk.onLongPress`: passed to the `InkWell`; the card and trash rows drop their `GestureDetector`.
  - The four callers' `Semantics(excludeSemantics: true, …)` gain `onTap:` (and `onLongPress:` for Trash), the pattern `log_row_widget.dart` already uses; the reminder uses `MxButton.semanticLabel` instead of its wrapper.
  - `MxOptionRow` and `MxToggle`: `enabled: callback != null` on their `Semantics`.
  - `MxListSectionHeader`: `Semantics(header: true)` around the label.
  - `MxErrorState`: `Semantics(liveRegion: true)` around the title.
- [ ] **Step 4: Run, see them pass.**
- [ ] **Step 5: Commit** `Shared widgets: TalkBack keeps every tap, and controls state what they are (SW-REV-005, SW-REV-006)`.

### Task 5: Theme slots the shared widgets paint through (SW-REV-007)

**Files:** Modify `lib/core/theme/app_theme.dart`, `app_component_themes.dart`; Test `test/core/theme/app_component_themes_test.dart`.

- [ ] **Step 1: Failing test** — for both themes: `splashColor` and `highlightColor` are `onSurface` at `AppOpacity.pressed`; `snackBarTheme.elevation == 0`; `tooltipTheme.decoration` is the inverse surface at `AppRadius.sm` and its text the caption on `onInverseSurface`.
- [ ] **Step 2: Run, see it fail.**
- [ ] **Step 3: Implement** in `_build` and a new `AppComponentThemes.tooltips(scheme, texts)`.
- [ ] **Step 4: Run, see it pass.**
- [ ] **Step 5: Commit** `Theme: row ripple, snackbar and tooltip from the MemoX roles (SW-REV-007)`.

### Task 6: Chips cut a long label instead of overflowing (SW-REV-010)

**Files:** Modify `lib/shared/widgets/mx_chip_trigger.dart`, `mx_filter_chip.dart`; Test their tests.

- [ ] **Step 1: Failing test** — each chip with a 60-character label inside a 200-wide `Align`: no overflow exception, the label ends in an ellipsis.
- [ ] **Step 2: Run, see it fail.**
- [ ] **Step 3: Implement** — `Flexible(child: Text(label, maxLines: 1, softWrap: false, overflow: TextOverflow.ellipsis))`, the row `mainAxisSize: MainAxisSize.min`, as `MxTagChip` does.
- [ ] **Step 4: Run, see it pass.**
- [ ] **Step 5: Commit** `MxChipTrigger, MxFilterChip: a long label ends in an ellipsis (SW-REV-010)`.

### Task 7: Caller and document deviations (SW-REV-011)

**Files:** `card_tag_filter_sheet_widget.dart`, `card_deck_summary_widget.dart`, `card_optional_fields_widget.dart`, `trash_screen.dart`, `DESIGN.md`, `lib/core/theme/foundations/app_spacing.dart` and its test.

- [ ] **Step 1** — the empty tag filter's lone Close is primary (The One Indigo Rule, R8); test asserts the tone.
- [ ] **Step 2** — the Card list hero passes `canWrap: true` to its `MxWorkloadBreakdownLine`; test at 360 with three-digit counts finds no ellipsis.
- [ ] **Step 3** — `card_optional_fields_widget.dart` uses `MxListSectionHeader`.
- [ ] **Step 4** — Trash's selection count in the app bar is a live region, as on Card list.
- [ ] **Step 5** — `DESIGN.md` › Layout states the 24 scroll tail the code and the reviewed goldens use; the unused `AppSpacing.pageEnd` goes.
- [ ] **Step 6: Commit** `Callers: lone Close primary, hero wraps, section header, live selection count; DESIGN.md scroll tail (SW-REV-011)`.

### Task 8: Documents, goldens and the owner's review

- [ ] `DESIGN.md`: Outline Edge lists the radio, checkbox and off toggle; MxDialog pads for the keyboard and can be held; a loading button is not dimmed; MxButton and MxRowInk semantics slots.
- [ ] Spec control edges §3.6 and UI-base register row 78 (and row 104, closed) updated.
- [ ] `bash .claude/skills/flutter-workflow/scripts/dod_check.sh` PASS.
- [ ] `bash .claude/skills/flutter-workflow/scripts/run_goldens.sh --update`, then the `golden-compare` page for the owner before any approve or merge.
- [ ] Final whole-branch review.

# UI Base Debt: Accessibility, Platform, Performance — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close UI-base debt FE-C3, FE-C4, FE-C6 and FE-C8, which are register §9 rows 61, 62, 64, 65 (grabber) and 66 (ticker, derived colours):
- loading states that a screen reader can hear;
- a donut that names what it measures;
- a grabber with a dismiss action;
- predictive Back on Android 14+;
- sheets that clear the keyboard;
- one skeleton ticker per list;
- derived colours resolved once per theme.

**Architecture:**
- **Loading:** a new `MxSkeletonList` replaces the repeated `for (...) const MxSkeletonRow()` loops. It owns one pulse for all its bars and one semantics node carrying the caller's "Loading" label. `MxSkeleton` uses a pulse from an ancestor when one exists, and owns one only when alone.
- **Labels:** `MxSpinner` and `MxMasteryDonut` take an optional `semanticLabel`. Copy stays caller-supplied (PRODUCT.md: components hold no copy).
- **Grabber:** `MxBottomSheet`'s grabber exposes Material's drag-handle semantics (the dismiss label and a tap). The sheet pads for the IME inset.
- **Derived colours:** `context.derivedColors` memoises per `ThemeData` through an `Expando`.

**Tech Stack:** Flutter 3.47.5, Dart 3.13; Android manifest.

**Spec:** `docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md` §9 rows 61, 62, 64, 65, 66; `docs/wbs_FE.md` FE-C3, FE-C4, FE-C6, FE-C8.

## Global Constraints

- Guard `memox-v8` 0/0.
- New copy goes in ARB en and vi (`commonLoading`: "Loading" / "Đang tải").
- **No golden changes.** The golden suite in the Linux container must stay green without `--update-goldens`. The one exception: a sheet with a keyboard, which no golden has.
- Contrast parts of row 66 (skeleton 1.07:1, banner borders 1.11:1) stay with FE-C1, which waits on the owner's contrast decision.

## Review Focus

1. **A list loading on any screen.** TalkBack hears "Loading" once, not once per bar. Pinned in Task 1.
2. **Reduced motion.** Skeletons stay still at their resting opacity, with no ticker. Pinned in Task 1.
3. **A sheet whose field has focus with the keyboard up.** The field sits above the keyboard, and the sheet still scrolls within its cap. Pinned in Task 3.
4. **The grabber under TalkBack.** A double-tap dismisses the sheet. Pinned in Task 3.
5. **A theme switch.** Derived colours follow the new theme, not the memoised old one. Pinned in Task 4.

---

### Task 1: `MxSkeletonList` — one pulse, one "Loading"

**Files:**
- Modify: `lib/shared/widgets/mx_skeleton.dart`, `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb`
- Modify the call sites that loop `MxSkeletonRow`:
  - `card_detail_screen.dart`, `card_editor_screen.dart`, `card_move_sheet_widget.dart`, `card_history_scroll_widget.dart`, `card_list_section_widget.dart`;
  - `deck_algorithm_screen.dart`, `deck_level_screen.dart`, `deck_move_sheet_widget.dart`, `deck_level_body_widget.dart`, `deck_search_results_widget.dart`, `deck_reset_dialog_widget.dart`;
  - the gallery.
- Modify: `deck_context_header_widget.dart`. Its two bars get the loading label.
- Test: `test/shared/widgets/mx_skeleton_test.dart`

**Interfaces:**
- Produces:
  - `MxSkeletonList({required String semanticLabel, int rows = 4})`;
  - `MxSkeleton` reads an ancestor pulse when present;
  - ARB `commonLoading`.

- [ ] **Step 1: Write the failing tests.**
  - `MxSkeletonList(semanticLabel: 'Loading', rows: 4)` has exactly one node labelled "Loading" (`find.bySemanticsLabel('Loading')` finds one).
  - It runs one ticker: `tester.binding.transientCallbackCount == 1` after a pump.
  - Under `MediaQuery(disableAnimations: true)` it runs no ticker.
  - A lone `MxSkeleton` still pulses on its own ticker.
- [ ] **Step 2: Run them.** Expected: FAIL (`MxSkeletonList` is undefined).
- [ ] **Step 3: Implement.**
  - A private `_SkeletonPulse` InheritedWidget carries an `Animation<double>`.
  - `MxSkeletonList` is a `StatefulWidget` with one `AnimationController` (the same duration and `TweenSequence` as today; stopped under reduced motion). It renders `Semantics(label: semanticLabel, container: true, child: ExcludeSemantics(child: _SkeletonPulse(Column(rows × MxSkeletonRow))))`.
  - `MxSkeleton` builds its controller only when `_SkeletonPulse.maybeOf(context)` is null. Otherwise it uses the scope's animation.
  - Replace each `for (var i = 0; i < _skeletonRows; i++) const MxSkeletonRow()` with `MxSkeletonList(semanticLabel: l10n.commonLoading, rows: _skeletonRows)`, and a lone `MxSkeletonRow` with `rows: 1`.
  - In `deck_context_header_widget.dart`, wrap the two bars in `Semantics(label: l10n.commonLoading, container: true, child: ExcludeSemantics(...))`.
- [ ] **Step 4: Run** `flutter test --exclude-tags golden`. Expected: PASS.
- [ ] **Step 5: Commit** `feat(ui): MxSkeletonList — one pulse and one "Loading" per list (§9 rows 61, 66)`.

### Task 2: Spinner and donut names

**Files:**
- Modify: `lib/shared/widgets/mx_spinner.dart`, `lib/shared/widgets/mx_mastery_donut.dart`, `lib/shared/widgets/mx_button.dart` (loading keeps the label for TalkBack), `lib/features/card/presentation/widgets/sections/card_deck_summary_widget.dart`, `lib/features/deck/presentation/widgets/sections/deck_algorithm_options_widget.dart`
- Test: `test/shared/widgets/mx_spinner_test.dart`, `test/shared/widgets/mx_mastery_donut_test.dart`, `test/shared/widgets/mx_button_test.dart`

- [ ] **Step 1: Write the failing tests.**
  - `MxSpinner(semanticLabel: 'Loading')` has a node labelled "Loading"; without a label it has none.
  - `MxMasteryDonut(fraction: .25, semanticLabel: 'Mastered')` reads "Mastered" with value "25%", and the percentage text is not a second node.
  - A loading `MxButton(label: 'Save', isLoading: true)` still exposes "Save" and is disabled.
- [ ] **Step 2: Run them.** Expected: FAIL.
- [ ] **Step 3: Implement.**
  - The spinner: `semanticLabel == null` → `ExcludeSemantics`; else `Semantics(label: …, child: …)`.
  - The donut: with a label, `Semantics(label: label, value: percent, excludeSemantics: true)`; without one, it keeps today's percentage.
  - `MxButton`: the loading body sits in `Semantics(label: label, excludeSemantics: true)`.
  - The card summary passes `l10n.cardStatusMastered`. The algorithm options' switching spinner passes `l10n.commonLoading`.
- [ ] **Step 4: Run** the suite. Expected: PASS.
- [ ] **Step 5: Commit** `feat(ui): spinner and donut take their name (§9 row 61)`.

### Task 3: Sheets — grabber action and keyboard inset

**Files:**
- Modify: `lib/shared/widgets/mx_bottom_sheet.dart`
- Test: `test/shared/widgets/mx_bottom_sheet_test.dart`

- [ ] **Step 1: Write the failing tests.**
  - Open a sheet with a grabber through `showMxBottomSheet`. A semantics node labelled `MaterialLocalizations.modalBarrierDismissLabel` exists with a tap action, and tapping it pops the sheet.
  - An `MxBottomSheet` holding a `TextField` under `MediaQuery(viewInsets: EdgeInsets.only(bottom: 300))` has its bottom edge at `height - 300` or above.
- [ ] **Step 2: Run them.** Expected: FAIL.
- [ ] **Step 3: Implement.**
  - The grabber goes in `Semantics(container: true, button: true, label: MaterialLocalizations.of(context).modalBarrierDismissLabel, onTap: () => Navigator.of(context).maybePop(), child: …)`. This is Material's drag-handle semantics.
  - The sheet wraps in `Padding(padding: EdgeInsets.only(bottom: inset))`, where `inset = MediaQuery.viewInsetsOf(context).bottom`. Its cap becomes `(height - inset) * _maxHeightShare`.
- [ ] **Step 4: Run** the suite. Expected: PASS.
- [ ] **Step 5: Commit** `fix(ui): the sheet grabber dismisses for TalkBack; sheets clear the keyboard (§9 rows 64, 65)`.

### Task 4: Predictive Back and memoised derived colours

**Files:**
- Modify: `android/app/src/main/AndroidManifest.xml`, `lib/core/theme/theme_context.dart`
- Test: `test/app/android_manifest_test.dart`, `test/core/theme/mx_derived_colors_test.dart`

- [ ] **Step 1: Write the failing tests.**
  - The manifest's `<application>` sets `android:enableOnBackInvokedCallback="true"` (a host test reads the file).
  - Two reads of `context.derivedColors` under one theme return the identical object, and a different theme returns a different one.
- [ ] **Step 2: Run them.** Expected: FAIL.
- [ ] **Step 3: Implement.**
  - Add the manifest attribute.
  - Add `final _derived = Expando<MxDerivedColors>();` and `derivedColors => _derived[Theme.of(this)] ??= MxDerivedColors.resolve(colors, semanticColors)`, with a `ponytail:` note that `ThemeData` is immutable and keys the cache.
- [ ] **Step 4: Run** the suite. Expected: PASS.
- [ ] **Step 5: Commit** `fix(ui,android): predictive Back; derived colours resolved once per theme (§9 rows 62, 66)`.

### Task 5: Register, WBS, goldens, gate

- [ ] **Step 1: Close the register rows.**
  - Row 61: "— closed by UI-base debt (FE-C3)".
  - Row 62: closed by FE-C4.
  - Row 64: closed by FE-C6.
  - Row 65: its grabber clause.
  - Row 66: its ticker and derived-colour clauses. The contrast clauses stay open with FE-C1.
- [ ] **Step 2: Update the WBS.** Mark FE-C3, FE-C4, FE-C6 and FE-C8 `xong` in `docs/wbs_FE.md`.
- [ ] **Step 3: Windows gate:**
  - format, analyze, guard;
  - architecture check;
  - `flutter test --exclude-tags golden`;
  - docs check.
- [ ] **Step 4: Goldens.** Run the golden suite in the container without update. Expected: 86/86, no PNG changed.
- [ ] **Step 5: Commit, review, PR.** Commit `docs(ui): close register rows 61, 62, 64 and parts of 65, 66`. Run the final review (opus). Open the PR after the owner's popup.

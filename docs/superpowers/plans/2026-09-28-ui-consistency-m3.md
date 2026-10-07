# UI consistency (M3 review) Implementation Plan

> **Historical (ADR-019).** Written against the "Mobile UI Kit v3", retired on 2026-09-30; its kit references and screen captures are history, not authority. The app, `DESIGN.md` and the goldens decide the UI; each screen's current state is in its detail file under `docs/shared/ui/screen-handoff/`.

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix the 23 verified cross-app consistency defects from the M3 review, so that every screen gets the same role from the same widget, token and size.

**Architecture:** Four small, backward-compatible extensions to `lib/shared/widgets` come first:
- `MxSegmentedTray` gains a disabled state;
- `MxEmptyState` gains a third action;
- `MxErrorState` gains a configurable action icon;
- `MxDeckPickerSheet` gains a loading form.

The feature fixes then land one family at a time: sheets, dialogs, buttons, rows, layout, study. Goldens are regenerated once, at the end, in the Linux renderer.

**Tech Stack:** Flutter 3.47.5, Riverpod 3, flutter_test, golden tests (tag `golden`).

**Spec:** [`docs/superpowers/specs/2026-09-28-ui-consistency-m3-review.md`](../specs/2026-09-28-ui-consistency-m3-review.md). Item IDs (A1…G1) below are the spec's.

## Global Constraints

- Tokens only: `AppSpacing`, `AppSize`, `AppIconSize`, `AppOpacity`, `AppRadius`, `context.textStyles`. No new numeric literal in widget code.
- No new ARB key. Remove a key only when nothing references it; update `app_en.arb` and `app_vi.arb` together; `flutter gen-l10n` regenerates `lib/l10n/generated/`.
- Shared-widget changes are additive: every current call site compiles unchanged.
- Goldens are written only by the Linux renderer (`.claude/skills/flutter-testing/scripts/golden.Dockerfile`, or this Linux container once Task 0 validates it). Never run `--update-goldens` elsewhere.
- Per-task gate: `dart format --set-exit-if-changed lib test`, `flutter analyze`, `flutter test --exclude-tags golden <touched test files>`.
- Branch: `ccr-98684bf9-8obmh2`. One commit per task.
- D1 owner ruling: row padding is `EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: AppSpacing.grouped)`.

## Review Focus

- **Disabled tray under a disabled row (E1):** a Study options tray while "Use app defaults" is on must not take a tap, and TalkBack must read it as disabled. It dims like `MxStepper`, which dims inside a dimmed `MxSettingsRow`. Pinned in Task 1 and Task 11.
- **Large text on the new block buttons (D5):** at text scale 2.0 the three stacked unset-state buttons must not overflow. Pinned in Task 10 at `textScale: 2`.
- **Reorder drag with cards (D2):** the drag handle still starts a drag, and each item's key stays on the item's root widget after the `MxCard` wrap. Pinned by the existing `deck_reorder_test.dart`, which must stay green.
- **Loading → data transition in the picker sheets (A5):** the title must not jump position when data arrives. Both forms share one `_PickerHead`. Pinned in Task 4.
- **Grade row inside `StudyCtaRowWidget` (C3):** its single-child `Center` must not shrink the four-grade row. Pinned in Task 12 by a width assertion.

---

### Task 0: Baseline — the gate and the golden renderer

**Files:** none changed.

- [ ] **Step 1: Confirm a clean tree on the branch**

Run: `git status --short && git rev-parse --abbrev-ref HEAD`
Expected: no changes; `ccr-98684bf9-8obmh2`.

- [ ] **Step 2: Validate that this container renders goldens the way CI does**

Run: `TZ=UTC flutter test --tags golden`
Expected: `All tests passed!` If anything fails, this container is not a valid renderer. Use the Docker recipe in the header of `golden.Dockerfile` for Task 14 instead. Record which renderer Task 14 will use in the commit message of Task 14.

- [ ] **Step 3: Record the non-golden baseline**

Run: `flutter analyze && flutter test --exclude-tags golden`
Expected: no issues; all pass. If anything fails here, stop and report: it is not this plan's regression.

---

### Task 1: `MxSegmentedTray` disabled state (E1, shared)

**Files:**
- Modify: `lib/shared/widgets/mx_segmented_tray.dart`
- Test: `test/shared/widgets/mx_segmented_tray_test.dart`

**Interfaces:**
- Produces: `MxSegmentedTray.onSelected` is now `ValueChanged<T>?`. Null means disabled: no tap, `Semantics(enabled: false)`, the whole tray under `Opacity(AppOpacity.disabled)`.

- [ ] **Step 1: Write the failing test** (append to `main()`; add imports `package:memox/core/theme/foundations/app_opacity.dart` if missing)

```dart
  testWidgets('a null onSelected dims the tray and disables every option', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpMx(
      tester,
      const MxSegmentedTray<int>(
        segments: [
          MxSegment(value: 0, label: 'Created'),
          MxSegment(value: 1, label: 'Random'),
        ],
        selected: 0,
        onSelected: null,
      ),
    );

    final opacity = tester.widget<Opacity>(
      find.descendant(
        of: find.byType(MxSegmentedTray<int>),
        matching: find.byType(Opacity),
      ).first,
    );
    expect(opacity.opacity, AppOpacity.disabled);
    expect(
      tester.getSemantics(find.text('Random')),
      containsSemantics(hasEnabledState: true, isEnabled: false),
    );
    handle.dispose();
  });
```

- [ ] **Step 2: Run it and confirm it fails**

Run: `flutter test test/shared/widgets/mx_segmented_tray_test.dart`
Expected: compile error, because `onSelected: null` is not allowed for `ValueChanged<int>`.

- [ ] **Step 3: Implement**

In `MxSegmentedTray`:

```dart
  /// Null disables the tray: no option takes a tap, and it dims like a
  /// disabled MxStepper (ruling M3-E1).
  final ValueChanged<T>? onSelected;

  @override
  Widget build(BuildContext context) {
    final tray = LayoutBuilder(
      builder: (context, constraints) =>
          _naturalWidth(context) > constraints.maxWidth
          ? _stacked(context)
          : _inline(context),
    );
    if (onSelected != null) return tray;
    return Opacity(opacity: AppOpacity.disabled, child: tray);
  }

  VoidCallback? _select(T value) {
    final onSelected = this.onSelected;
    if (onSelected == null) return null;
    return () => onSelected(value);
  }
```

Replace both `onTap: () => onSelected(segment.value),` with `onTap: _select(segment.value),`. In `_Segment`, make `final VoidCallback? onTap;` and add `enabled: onTap != null,` to its `Semantics(...)`. Import `app_opacity.dart`.

- [ ] **Step 4: Run the tray tests**

Run: `flutter test test/shared/widgets/mx_segmented_tray_test.dart`
Expected: all pass, the existing tests included.

- [ ] **Step 5: Commit**

```bash
git add lib/shared/widgets/mx_segmented_tray.dart test/shared/widgets/mx_segmented_tray_test.dart
git commit -m "feat(shared): MxSegmentedTray disabled state for read-only choices"
```

---

### Task 2: `MxEmptyState` third action (D5, shared)

**Files:**
- Modify: `lib/shared/widgets/mx_empty_state.dart`
- Test: `test/shared/widgets/mx_empty_state_test.dart`

**Interfaces:**
- Produces: `MxEmptyState({..., String? tertiaryActionLabel, VoidCallback? onTertiaryAction})`. The two come together (assert). It draws an outline, block `MxButton` `AppSpacing.control` under the secondary action (or under the primary when there is no secondary), above the footnote.

- [ ] **Step 1: Write the failing test**

```dart
  testWidgets('a third action is an outline block button, 8 under the second', (
    tester,
  ) async {
    var taps = 0;
    await pumpMx(
      tester,
      MxEmptyState(
        icon: AppIcons.folder,
        title: 'Empty deck',
        actionLabel: 'New card',
        onAction: () {},
        secondaryActionLabel: 'New sub-deck',
        onSecondaryAction: () {},
        tertiaryActionLabel: 'Import cards',
        onTertiaryAction: () => taps++,
      ),
    );
    final buttons = tester.widgetList<MxButton>(find.byType(MxButton)).toList();

    expect(buttons.map((b) => b.tone), [
      MxButtonTone.primary,
      MxButtonTone.secondary,
      MxButtonTone.outline,
    ]);
    expect(buttons.every((b) => b.isBlock), isTrue);
    expect(
      tester.getTopLeft(find.text('Import cards')).dy -
          tester.getBottomLeft(find.widgetWithText(MxButton, 'New sub-deck')).dy,
      greaterThanOrEqualTo(8),
    );
    await tester.tap(find.text('Import cards'));
    expect(taps, 1);
  });

  test('a tertiary label without its callback is a programming error', () {
    expect(
      () => MxEmptyState(
        icon: AppIcons.inbox,
        title: 'x',
        tertiaryActionLabel: 'Import',
      ),
      throwsAssertionError,
    );
  });
```

- [ ] **Step 2: Run it and confirm it fails**

Run: `flutter test test/shared/widgets/mx_empty_state_test.dart`
Expected: compile error, because `tertiaryActionLabel` is not defined.

- [ ] **Step 3: Implement**

Constructor: add `this.tertiaryActionLabel, this.onTertiaryAction,` and a third assert:

```dart
       assert(
         (tertiaryActionLabel == null) == (onTertiaryAction == null),
         'tertiaryActionLabel and onTertiaryAction come together',
       );
```

Fields:

```dart
  /// A third, quietest action (outline), as the unset deck's "Import cards".
  final String? tertiaryActionLabel;
  final VoidCallback? onTertiaryAction;
```

In `build`, after the secondary block and before the footnote:

```dart
              if ((tertiaryActionLabel, onTertiaryAction) case (
                final label?,
                final onPressed?,
              )) ...[
                const SizedBox(height: AppSpacing.control),
                MxButton(
                  label: label,
                  tone: MxButtonTone.outline,
                  onPressed: onPressed,
                  isBlock: true,
                ),
              ],
```

- [ ] **Step 4: Run the tests**

Run: `flutter test test/shared/widgets/mx_empty_state_test.dart`
Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git add lib/shared/widgets/mx_empty_state.dart test/shared/widgets/mx_empty_state_test.dart
git commit -m "feat(shared): MxEmptyState third (outline) action slot"
```

---

### Task 3: `MxErrorState` action icon (D6, shared)

**Files:**
- Modify: `lib/shared/widgets/mx_error_state.dart`
- Test: `test/shared/widgets/mx_error_state_test.dart`

**Interfaces:**
- Produces: `MxErrorState({..., IconData actionIcon = AppIcons.retry})`, the icon of the `retryLabel`/`onRetry` button.

- [ ] **Step 1: Write the failing test**

```dart
  testWidgets('the action can carry another icon, as Close does', (
    tester,
  ) async {
    await pumpMx(
      tester,
      MxErrorState(
        title: _title,
        body: _body,
        retryLabel: 'Close',
        onRetry: () {},
        actionIcon: AppIcons.close,
      ),
    );

    expect(tester.widget<MxButton>(find.byType(MxButton)).icon, AppIcons.close);
    expect(find.byIcon(AppIcons.retry), findsNothing);
  });
```

- [ ] **Step 2: Run it and confirm it fails**

Run: `flutter test test/shared/widgets/mx_error_state_test.dart`
Expected: compile error, because `actionIcon` is not defined.

- [ ] **Step 3: Implement**

Add `this.actionIcon = AppIcons.retry,` to the constructor and a field:

```dart
  /// The action's glyph: Retry by default; Close where nothing can be
  /// retried (study Guess, BR-STUDY-040).
  final IconData actionIcon;
```

In the button, change `icon: AppIcons.retry,` to `icon: actionIcon,`. Update the class doc's last sentence to: "Without [onRetry] it is the "not found" form; [actionIcon] swaps Retry's glyph when the action is not a retry."

- [ ] **Step 4: Run the tests**

Run: `flutter test test/shared/widgets/mx_error_state_test.dart`
Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git add lib/shared/widgets/mx_error_state.dart test/shared/widgets/mx_error_state_test.dart
git commit -m "feat(shared): MxErrorState configurable action icon"
```

---

### Task 4: Deck picker loading form, adopted by the three picker sheets (A5)

**Files:**
- Modify: `lib/shared/widgets/mx_deck_picker_sheet.dart`
- Modify: `lib/features/card/presentation/widgets/overlays/card_move_sheet_widget.dart` (loading branch)
- Modify: `lib/features/deck/presentation/widgets/overlays/deck_move_sheet_widget.dart` (loading branch)
- Modify: `lib/features/trash/presentation/widgets/overlays/trash_restore_sheet_widget.dart` (loading branch)
- Test: `test/shared/widgets/mx_deck_picker_sheet_test.dart`

**Interfaces:**
- Produces: `class MxDeckPickerLoadingSheet extends StatelessWidget` with `({Key? key, required String title, String? rule, required String semanticLabel, int rows = 3})`. The private `_PickerHead(title:, rule:)` is shared with `MxDeckPickerSheet`.

- [ ] **Step 1: Write the failing test**

```dart
  testWidgets('loading keeps the head where the loaded sheet draws it', (
    tester,
  ) async {
    await pumpMx(
      tester,
      const MxDeckPickerLoadingSheet(
        title: 'Move to deck',
        semanticLabel: 'Loading',
      ),
    );
    final sheet = tester.getTopLeft(find.byType(MxBottomSheet));

    expect(find.byType(MxSkeletonList), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Move to deck')) - sheet,
      const Offset(20, 20),
    );
  });
```

(Import `package:memox/shared/widgets/mx_skeleton.dart`.)

- [ ] **Step 2: Run it and confirm it fails**

Run: `flutter test test/shared/widgets/mx_deck_picker_sheet_test.dart`
Expected: compile error, because `MxDeckPickerLoadingSheet` is not defined.

- [ ] **Step 3: Implement**

Extract the header into a private widget and reuse it:

```dart
class _PickerHead extends StatelessWidget {
  const _PickerHead({required this.title, this.rule});

  final String title;
  final String? rule;

  /// Ruling O11: the title → rule gap is UNSPECIFIED.
  static const double _ruleGap = 4;

  @override
  Widget build(BuildContext context) {
    final styles = context.textStyles;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.card,
        AppSpacing.micro,
        AppSpacing.card,
        AppSpacing.grouped,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: _ruleGap,
        children: [
          Text(title, style: styles.compactTitle),
          if (rule case final text?) Text(text, style: styles.noteText),
        ],
      ),
    );
  }
}

/// MxDeckPickerSheet while its candidates load: the same head over a
/// skeleton, so the title does not appear late (ruling M3-A5). The rule is
/// optional because some rules depend on the loaded targets.
class MxDeckPickerLoadingSheet extends StatelessWidget {
  const MxDeckPickerLoadingSheet({
    super.key,
    required this.title,
    this.rule,
    required this.semanticLabel,
    this.rows = _defaultRows,
  });

  final String title;
  final String? rule;

  /// What is loading, in the caller's copy.
  final String semanticLabel;
  final int rows;

  static const int _defaultRows = 3;

  @override
  Widget build(BuildContext context) => MxBottomSheet(
    header: _PickerHead(title: title, rule: rule),
    child: MxSkeletonList(semanticLabel: semanticLabel, rows: rows),
  );
}
```

In `MxDeckPickerSheet.build`, replace the `header: Padding(...)` block with `header: _PickerHead(title: title, rule: rule),`. Delete its `_ruleGap` and `styles` if they become unused. Import `mx_skeleton.dart`.

In each of the three sheets, replace the `_ => MxBottomSheet(child: Column(children: [MxSkeletonList(...)]))` branch:
- card move:
  ```dart
  _ => MxDeckPickerLoadingSheet(
    title: l10n.cardMoveTitle,
    rule: l10n.cardMoveRule,
    semanticLabel: l10n.commonLoading,
    rows: _skeletonRows,
  ),
  ```
- deck move: the same, with `l10n.deckMoveTitle` and `l10n.deckMoveRule`.
- Trash restore: `title: _title(l10n)`, no `rule` (its rule depends on the targets), `semanticLabel: l10n.commonLoading`, `rows: _skeletonRows`.

Remove any import that becomes unused (`mx_skeleton.dart` and possibly `mx_bottom_sheet.dart` in the feature files; keep `mx_bottom_sheet.dart` where the error branch still uses it).

- [ ] **Step 4: Run the tests**

Run: `flutter test test/shared/widgets/mx_deck_picker_sheet_test.dart test/features/card test/features/deck test/features/trash --exclude-tags golden`
Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git add lib/shared/widgets/mx_deck_picker_sheet.dart lib/features/card/presentation/widgets/overlays/card_move_sheet_widget.dart lib/features/deck/presentation/widgets/overlays/deck_move_sheet_widget.dart lib/features/trash/presentation/widgets/overlays/trash_restore_sheet_widget.dart test/shared/widgets/mx_deck_picker_sheet_test.dart
git commit -m "fix(ui): picker sheets keep their title while loading"
```

---

### Task 5: Bottom-sheet family — flag sheet header, deck sort/filter sheet (A1–A4)

**Files:**
- Modify: `lib/features/card/presentation/widgets/overlays/card_flag_sheet_widget.dart`
- Modify: `lib/features/deck/presentation/widgets/overlays/deck_level_query_sheets_widget.dart`
- Test: create `test/features/card/presentation/card_flag_sheet_test.dart`, create `test/features/deck/presentation/deck_sort_filter_sheet_test.dart`

- [ ] **Step 1: Write the failing tests**

`card_flag_sheet_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/features/card/presentation/widgets/overlays/card_flag_sheet_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_bottom_sheet.dart';

final _en = lookupAppLocalizations(const Locale('en'));

void main() {
  testWidgets('the flag sheet has the shared title header (M3-A1)', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: CardFlagSheetWidget()),
      ),
    );

    expect(
      tester.widget<MxBottomSheet>(find.byType(MxBottomSheet)).header,
      isNotNull,
    );
    expect(find.text(_en.cardFlag), findsOneWidget);
  });
}
```

`deck_sort_filter_sheet_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/deck/presentation/widgets/overlays/deck_level_query_sheets_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_bottom_sheet.dart';
import 'package:memox/shared/widgets/mx_list_section_header.dart';
import 'package:memox/shared/widgets/mx_settings_row.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';

final _en = lookupAppLocalizations(const Locale('en'));

void main() {
  testWidgets('sort/filter sheet uses the shared sheet parts (M3-A2..A4)', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: buildLightTheme(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: DeckSortFilterSheetWidget(parentId: null),
          ),
        ),
      ),
    );
    final header =
        tester.widget<MxBottomSheet>(find.byType(MxBottomSheet)).header!
            as Padding;

    expect(
      (header.padding as EdgeInsets).bottom,
      AppSpacing.grouped,
    );
    expect(
      find.widgetWithText(MxListSectionHeader, _en.deckSortByHeader),
      findsOneWidget,
    );
    expect(find.byType(MxSheetActions), findsOneWidget);
    expect(
      find.widgetWithText(MxSettingsRow, _en.deckFilterDueOnlyTitle),
      findsOneWidget,
    );
  });
}
```

If `deckLevelQueryProvider` needs an override to build in isolation, copy the override from `test/features/deck/presentation/deck_level_screen_test.dart` rather than inventing one.

- [ ] **Step 2: Run them and confirm they fail**

Run: `flutter test test/features/card/presentation/card_flag_sheet_test.dart test/features/deck/presentation/deck_sort_filter_sheet_test.dart`
Expected: FAIL. The header is null, the bottom padding is 8, and no `MxListSectionHeader`, `MxSheetActions` or `MxSettingsRow` is found.

- [ ] **Step 3: Implement**

Flag sheet: add a header to `MxBottomSheet`, and add imports for `theme_context.dart` and `app_spacing.dart` if they are missing:

```dart
    return MxBottomSheet(
      header: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.card,
          AppSpacing.micro,
          AppSpacing.card,
          AppSpacing.grouped,
        ),
        child: Text(l10n.cardFlag, style: context.textStyles.compactTitle),
      ),
      child: /* unchanged */,
    );
```

Deck sort/filter sheet:
1. Header padding bottom: `AppSpacing.control` → `AppSpacing.grouped`.
2. Footer:
   ```dart
   footer: MxSheetActions.custom(
     isInSheet: true,
     children: [
       Expanded(
         child: MxButton(
           label: l10n.commonDone,
           isBlock: true,
           onPressed: () => Navigator.of(context).pop(),
         ),
       ),
     ],
   ),
   ```
3. The "Sort by" overline, in the export sheet's form:
   ```dart
   Padding(
     padding:
         const EdgeInsets.only(top: AppSpacing.micro) +
         const EdgeInsets.symmetric(horizontal: AppSpacing.control),
     child: MxListSectionHeader(label: l10n.deckSortByHeader),
   ),
   ```
4. Replace the whole due-only `Padding(... Row(...))` with:
   ```dart
   MxSettingsRow(
     label: l10n.deckFilterDueOnlyTitle,
     subtitle: l10n.deckFilterDueOnlyBody,
     trailing: MxToggle(
       isOn: query.filter == DeckLevelFilter.due,
       semanticLabel: l10n.deckFilterDueOnlyTitle,
       onChanged: (isOn) => _query(ref)
           .show(isOn ? DeckLevelFilter.due : DeckLevelFilter.all),
     ),
   ),
   ```
   Add imports for `mx_list_section_header.dart`, `mx_settings_row.dart` and `mx_sheet_actions.dart`. Drop `styles` if it becomes unused.

- [ ] **Step 4: Run the tests**

Run: `flutter test test/features/card/presentation/card_flag_sheet_test.dart test/features/deck/presentation/deck_sort_filter_sheet_test.dart test/features/deck test/features/card --exclude-tags golden`
Expected: all pass. If an existing deck-level test finds the due-only row by the old `Row` structure, update its finder to `find.widgetWithText(MxSettingsRow, _en.deckFilterDueOnlyTitle)`.

- [ ] **Step 5: Commit**

```bash
git add lib/features/card/presentation/widgets/overlays/card_flag_sheet_widget.dart lib/features/deck/presentation/widgets/overlays/deck_level_query_sheets_widget.dart test/features/card/presentation/card_flag_sheet_test.dart test/features/deck/presentation/deck_sort_filter_sheet_test.dart
git commit -m "fix(ui): align flag and deck sort/filter sheets with the shared sheet parts"
```

---

### Task 6: Dialog family — width, reset loading, settings reset actions (B1–B3)

**Files:**
- Modify: `lib/features/card/presentation/widgets/overlays/card_discard_dialog_widget.dart`
- Modify: `lib/features/deck/presentation/widgets/overlays/deck_discard_dialog_widget.dart`
- Modify: `lib/features/study/presentation/widgets/overlays/study_exit_dialog_widget.dart`
- Modify: `lib/features/settings/presentation/widgets/overlays/settings_reset_dialog_widget.dart`
- Modify: `lib/features/deck/presentation/widgets/overlays/deck_reset_dialog_widget.dart`
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb` (remove `resetRunning` and `@resetRunning`)
- Test: `test/features/deck/presentation/deck_reset_dialog_test.dart`, `test/features/settings/presentation/settings_screen_test.dart`

- [ ] **Step 1: Change the tests first**

In `deck_reset_dialog_test.dart`, in `'while the reset runs the dialog says so and Cancel waits'`, replace `expect(find.text(_en.resetRunning), findsOneWidget);` with:

```dart
    expect(find.byType(MxSpinner), findsOneWidget);
    expect(
      tester.widget<MxSheetActions>(find.byType(MxSheetActions)).onCancel,
      isNull,
    );
```

(Import `mx_spinner.dart` and `mx_sheet_actions.dart`.) Rename the test to `'while the reset runs the confirm spins and Cancel is off'`.

In `settings_screen_test.dart`, in the test that opens the reset dialog (it finds `_en.settingsResetConfirm`), add after the dialog opens:

```dart
    expect(
      tester.widget<MxSheetActions>(find.byType(MxSheetActions)).confirmLabel,
      _en.settingsResetConfirm,
    );
```

- [ ] **Step 2: Run them and confirm they fail**

Run: `flutter test test/features/deck/presentation/deck_reset_dialog_test.dart test/features/settings/presentation/settings_screen_test.dart`
Expected: FAIL. There is no spinner and `onCancel` is non-null. `confirmLabel` is null (`.custom`).

- [ ] **Step 3: Implement**

- B1: delete the `width: MxDialogWidth.medium,` line in the four dialogs.
- B2, in `deck_reset_dialog_widget.dart`:
  ```dart
        actions: MxSheetActions(
          cancelLabel: l10n.commonCancel,
          onCancel: _isResetting ? null : () => Navigator.of(context).pop(),
          confirmLabel: l10n.resetConfirm(_nextCycle(view)),
          confirmIcon: AppIcons.resetProgress,
          isConfirmLoading: _isResetting,
          onConfirm: summary != null && !_isResetting
              ? () => unawaited(_reset(view, summary))
              : null,
        ),
  ```
  Then remove `resetRunning` and `@resetRunning` from `app_en.arb`, and `resetRunning` from `app_vi.arb`. Run `flutter gen-l10n`.
- B3, in `settings_reset_dialog_widget.dart`: delete `_cancelShare`/`_confirmShare` and their comment, and replace `actions:` with:
  ```dart
          actions: MxSheetActions(
            cancelLabel: l10n.commonCancel,
            onCancel: _isResetting ? null : () => Navigator.of(context).pop(),
            confirmLabel: l10n.settingsResetConfirm,
            onConfirm: () => unawaited(_reset()),
            isConfirmLoading: _isResetting,
          ),
  ```
  Import `dart:async` if `unawaited` is missing. Remove the `mx_action_pair.dart` and `mx_button.dart` imports and the stale comment `// The pair of MxSheetActions, with Cancel off while it runs.`

- [ ] **Step 4: Verify**

Run: `grep -rn "MxDialogWidth.medium\|resetRunning" lib test --include=*.dart --include=*.arb | grep -v generated`
Expected: no output.

Run: `flutter test test/features/deck test/features/settings test/features/card test/features/study --exclude-tags golden`
Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git add lib/features lib/l10n test/features/deck/presentation/deck_reset_dialog_test.dart test/features/settings/presentation/settings_screen_test.dart
git commit -m "fix(ui): one confirm-dialog width and MxSheetActions loading everywhere"
```

---

### Task 7: Button roles — export Close, import banner action (C1, C2)

**Files:**
- Modify: `lib/features/transfer/presentation/widgets/overlays/card_export_sheet_widget.dart` (`_Actions`, `problem.isFinal` branch)
- Modify: `lib/features/transfer/presentation/widgets/sections/import_source_section_widget.dart` (warning banner action)
- Test: `test/features/transfer/presentation/card_export_sheet_test.dart`, `test/features/transfer/presentation/card_import_screen_test.dart` (or the import test that reaches the file warning; find it with `grep -rln "MxBannerTone.warning\|importReadWarning" test/features/transfer`)

- [ ] **Step 1: Write the failing assertions**

In `card_export_sheet_test.dart` `'an empty deck opens on nothing to export (E5)'`, append:

```dart
    expect(
      tester.widget<MxButton>(_button(_en.exportClose)).tone,
      MxButtonTone.primary,
    );
```

In the import test that shows the file warning banner with "Choose another", append:

```dart
    final choose = tester.widget<MxButton>(
      find.widgetWithText(MxButton, _en.importChooseAnother),
    );
    expect((choose.tone, choose.size), (MxButtonTone.primary, MxButtonSize.compact));
```

If no test reaches that banner, add one to the import test file, modelled on the existing warning-state test in that file (same seed and pump), with only the assertion above.

- [ ] **Step 2: Run them and confirm they fail**

Run: `flutter test test/features/transfer --exclude-tags golden`
Expected: FAIL, because the tones are outline and outline/small.

- [ ] **Step 3: Implement**

- Export `_Actions`: delete `tone: MxButtonTone.outline,` from the `exportClose` button.
- Import banner: delete `tone: MxButtonTone.outline,` and change `size: MxButtonSize.small,` to `size: MxButtonSize.compact,`.

- [ ] **Step 4: Run the tests**

Run: `flutter test test/features/transfer --exclude-tags golden`
Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git add lib/features/transfer test/features/transfer
git commit -m "fix(ui): terminal Close and banner actions use the app-wide button roles"
```

---

### Task 8: Rows — entity row padding, reorder rows as cards (D1, D2)

**Files:**
- Modify: `lib/features/card/presentation/widgets/items/card_row_widget.dart`
- Modify: `lib/features/trash/presentation/widgets/items/trash_entry_row_widget.dart`
- Modify: `lib/features/deck/presentation/widgets/items/deck_reorder_row_widget.dart`
- Modify: `lib/features/deck/presentation/widgets/sections/deck_reorder_list_widget.dart`
- Test: `test/features/card/presentation/card_row_test.dart`, `test/features/deck/presentation/deck_reorder_test.dart`

**Interfaces:**
- `DeckReorderRowWidget` loses `hasDivider`: `({Key? key, required DeckTile tile, required int index})`.

- [ ] **Step 1: Write the failing tests**

In `card_row_test.dart`, add, reusing that file's pump helper and fixture:

```dart
  // M3-D1: a card row's content starts 16 in, like every MxListRow.
  expect(
    tester.getTopLeft(find.text(/* the row's front text in this test */)).dx -
        tester.getTopLeft(find.byType(CardRowWidget)).dx,
    greaterThanOrEqualTo(AppSpacing.gutter),
  );
```

Put it in the first existing test that renders a single row, and use that test's front text literal.

In `deck_reorder_test.dart`, in the first test that enters reorder mode, add:

```dart
    expect(
      find.descendant(
        of: find.byType(DeckReorderRowWidget).first,
        matching: find.byType(MxCard),
      ),
      findsOneWidget,
    );
```

(Import `mx_card.dart`.)

- [ ] **Step 2: Run them and confirm they fail**

Run: `flutter test test/features/card/presentation/card_row_test.dart test/features/deck/presentation/deck_reorder_test.dart`
Expected: FAIL. The horizontal inset is 12, and the reorder row has no `MxCard`.

- [ ] **Step 3: Implement**

D1, in both row widgets: delete `static const double _rowPadding = 12;` and change the padding to:

```dart
padding: const EdgeInsets.symmetric(
  horizontal: AppSpacing.gutter,
  vertical: AppSpacing.grouped,
),
```

Import `app_spacing.dart` if it is missing.

D2, in `DeckReorderRowWidget`: delete `hasDivider` (field, constructor and doc), wrap the row, and update the class doc to "A deck in reorder mode, in the browse row's shape: one MxCard per deck (handoff 01). Its drag handle takes the chevron's place (spec §6.1)."

```dart
  @override
  Widget build(BuildContext context) => MxCard(
    isFullBleed: true,
    child: MxListRow(
      title: tile.name,
      leading: const MxIconTile(
        icon: AppIcons.library,
        size: MxIconTileSize.large,
      ),
      meta: DeckWorkloadLineWidget(
        overdueCount: tile.overdueCount,
        todayCount: tile.dueTodayCount,
        newCount: tile.newCount,
        cardCount: tile.cardCount,
      ),
      trailing: ReorderableDragStartListener(
        index: index,
        child: const SizedBox.square(
          dimension: AppSize.touchTarget,
          child: Icon(AppIcons.dragHandle),
        ),
      ),
      hasDivider: false,
    ),
  );
```

In `DeckReorderListWidget.build`, keep the key on the item root:

```dart
    itemBuilder: (context, index) => Padding(
      key: ValueKey(_order[index].id),
      padding: EdgeInsets.only(
        bottom: index < _order.length - 1 ? AppSpacing.control : 0,
      ),
      child: DeckReorderRowWidget(tile: _order[index], index: index),
    ),
```

- [ ] **Step 4: Run the tests**

Run: `flutter test test/features/card test/features/trash test/features/deck --exclude-tags golden`
Expected: all pass. If a test found `DeckReorderRowWidget` by its old key, move the finder to the item `Padding` via `find.byKey(ValueKey(id))`.

- [ ] **Step 5: Commit**

```bash
git add lib/features/card/presentation/widgets/items/card_row_widget.dart lib/features/trash/presentation/widgets/items/trash_entry_row_widget.dart lib/features/deck/presentation/widgets test/features/card/presentation/card_row_test.dart test/features/deck/presentation/deck_reorder_test.dart
git commit -m "fix(ui): entity rows share the 16dp edge; reorder keeps the card shape"
```

---

### Task 9: Screen layout — Progress gap, Language/Theme notes, Theme hint role (D3, D4, G1)

**Files:**
- Modify: `lib/features/progress/presentation/screens/progress_screen.dart`
- Modify: `lib/features/settings/presentation/screens/language_screen.dart`
- Modify: `lib/features/settings/presentation/screens/theme_screen.dart`
- Modify: `lib/features/settings/presentation/widgets/items/theme_choice_card_widget.dart`
- Test: `test/features/settings/presentation/language_screen_test.dart`, `test/features/progress/presentation/progress_screen_test.dart`

- [ ] **Step 1: Write the failing tests**

In `language_screen_test.dart`, in the first test that shows the loaded rows:

```dart
    expect(find.byType(MxSection), findsOneWidget);
    expect(find.widgetWithText(MxNote, _en.settingsLanguageNote), findsOneWidget);
```

In `progress_screen_test.dart`, in the first loaded-overview test:

```dart
    // M3-D3: every section gap on the overview is AppSpacing.gutter.
    expect(
      tester.getTopLeft(find.byType(ProgressStreakWidget)).dy -
          tester.getBottomLeft(find.byType(ProgressTodayWidget)).dy,
      AppSpacing.gutter,
    );
```

(Import the two progress widgets and `app_spacing.dart`, `mx_section.dart`, `mx_note.dart` as needed.)

- [ ] **Step 2: Run them and confirm they fail**

Run: `flutter test test/features/settings/presentation/language_screen_test.dart test/features/progress/presentation/progress_screen_test.dart`
Expected: FAIL. There is no `MxSection`/`MxNote`, and the gap is 12.

- [ ] **Step 3: Implement**

- D3, in `progress_screen.dart` `_loaded`: change the `SizedBox(height: AppSpacing.grouped)` between Today and Streak to `AppSpacing.gutter`.
- D4, in the Language `AsyncData` branch:
  ```dart
          AsyncData(:final value) => MxScreenScroll(
            children: [
              const SizedBox(height: AppSpacing.control),
              MxSection(
                note: l10n.settingsLanguageNote,
                children: _rows(l10n, value.language),
              ),
            ],
          ),
  ```
  In `_rows`, set `hasDivider: false` on all three `MxOptionRow`s, because MxSection draws the dividers. Remove the unused `mx_card.dart` import.
- D4, in Theme: replace `const SizedBox(height: AppSpacing.gutter), Text(l10n.settingsAppliesAtOnce, ...)` with the MxSection note form:
  ```dart
              Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: AppSpacing.micro,
                  end: AppSpacing.micro,
                  top: AppSpacing.control,
                ),
                child: MxNote(text: l10n.settingsAppliesAtOnce),
              ),
  ```
  Import `mx_note.dart`.
- G1, in `theme_choice_card_widget.dart`: change both `styles.rowSubtitle` to `styles.rowDescription` (the `minWidth` measurement and the hint `Text`).

- [ ] **Step 4: Run the tests**

Run: `flutter test test/features/settings test/features/progress --exclude-tags golden`
Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git add lib/features/progress lib/features/settings test/features/settings/presentation/language_screen_test.dart test/features/progress/presentation/progress_screen_test.dart
git commit -m "fix(ui): section gap, MxSection notes and option-hint role on Progress, Language, Theme"
```

---

### Task 10: Empty/error adopters — deck unset state, Guess blocked (D5, D6)

**Files:**
- Modify: `lib/features/deck/presentation/widgets/sections/deck_unset_state_widget.dart`
- Modify: `lib/features/study/presentation/widgets/sections/study_guess_widget.dart` (`isBlocked` branch)
- Test: `test/features/deck/presentation/open_deck_screen_test.dart`, `test/features/study/presentation/study_guess_test.dart`

**Interfaces:**
- Consumes: `MxEmptyState.tertiaryActionLabel`/`onTertiaryAction` (Task 2) and `MxErrorState.actionIcon` (Task 3).

- [ ] **Step 1: Write the failing tests**

In `open_deck_screen_test.dart`, in the test that shows the unset state with both actions:

```dart
    expect(find.byType(OverflowBar), findsNothing);
    final buttons = tester
        .widgetList<MxButton>(
          find.descendant(
            of: find.byType(MxEmptyState),
            matching: find.byType(MxButton),
          ),
        )
        .toList();
    expect(buttons.every((b) => b.isBlock), isTrue);
    expect(buttons.first.label, _en.deckNewCard);
```

Add a copy of the same test pumped at `textScale: 2` (use the harness's `textScale` parameter) that asserts `tester.takeException()` is null.

In `study_guess_test.dart`, in the blocked-question test, after `expect(find.text(_en.studyGuessBlockedTitle), findsOneWidget);`:

```dart
      expect(
        find.descendant(
          of: find.byType(MxErrorState),
          matching: find.widgetWithText(MxButton, _en.studySessionClose),
        ),
        findsOneWidget,
      );
```

- [ ] **Step 2: Run them and confirm they fail**

Run: `flutter test test/features/deck/presentation/open_deck_screen_test.dart test/features/study/presentation/study_guess_test.dart`
Expected: FAIL. The OverflowBar is present, and Close sits outside `MxErrorState`.

- [ ] **Step 3: Implement**

Deck unset `build`:

```dart
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final onAddCard = this.onAddCard;
    final onCreateSubDeck = this.onCreateSubDeck;
    final isOpen = onAddCard != null && onCreateSubDeck != null;
    // The first way in leads; a sub-deck is second only when a card also
    // fits (ruling P4a-L9).
    final (String? leadLabel, VoidCallback? onLead) = switch (onAddCard) {
      final onAdd? => (l10n.deckNewCard, onAdd),
      null => (
        onCreateSubDeck == null ? null : l10n.deckNewSubDeck,
        onCreateSubDeck,
      ),
    };
    return MxEmptyState(
      icon: AppIcons.folder,
      title: onAddCard == null ? l10n.deckRootEmptyTitle : l10n.deckUnsetTitle,
      body: switch ((onAddCard, onCreateSubDeck)) {
        (null, _) => l10n.deckRootEmptyBody,
        (_, null) => l10n.deckUnsetDeepestBody,
        _ => l10n.deckUnsetBody,
      },
      actionLabel: leadLabel,
      onAction: onLead,
      secondaryActionLabel: isOpen ? l10n.deckNewSubDeck : null,
      onSecondaryAction: isOpen ? onCreateSubDeck : null,
      tertiaryActionLabel: onImportCards == null ? null : l10n.deckUnsetImport,
      onTertiaryAction: onImportCards,
      footnote: isOpen ? l10n.deckUnsetNote : null,
    );
  }
```

Update the class doc: "…what it can take next, as the empty state's block actions, and while both fit, the note on what the first one decides (ruling P4a-L9)." Remove the `mx_button.dart`, `mx_note.dart` and `app_spacing.dart` imports if they are unused.

Guess blocked branch:

```dart
    if (question.isBlocked) {
      // Close ends the session: nothing here can be retried (BR-STUDY-040).
      return MxScreenScroll(
        children: [
          MxErrorState(
            title: l10n.studyGuessBlockedTitle,
            body: l10n.studyGuessBlockedBody,
            icon: AppIcons.close,
            retryLabel: l10n.studySessionClose,
            onRetry: widget.onClose,
            actionIcon: AppIcons.close,
          ),
        ],
      );
    }
```

Import `mx_screen_scroll.dart`. If `widget.onClose` is nullable, keep the assert contract (label and callback together) by passing `retryLabel: widget.onClose == null ? null : l10n.studySessionClose`.

- [ ] **Step 4: Run the tests**

Run: `flutter test test/features/deck test/features/study test/app/library_routes_test.dart --exclude-tags golden`
Expected: all pass. The blocked test's `find.byIcon(AppIcons.retry)` still finds nothing.

- [ ] **Step 5: Commit**

```bash
git add lib/features/deck/presentation/widgets/sections/deck_unset_state_widget.dart lib/features/study/presentation/widgets/sections/study_guess_widget.dart test/features/deck/presentation/open_deck_screen_test.dart test/features/study/presentation/study_guess_test.dart
git commit -m "fix(ui): unset deck and blocked Guess use the empty/error state action slots"
```

---

### Task 11: Study options — segmented tray and row icons (E1, E2)

**Files:**
- Modify: `lib/features/settings/presentation/widgets/sections/study_options_form_widget.dart`
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb` (remove `studyOptionsCreationOrder`, `studyOptionsCreationOrderHint`, `studyOptionsRandomHint` if unreferenced)
- Test: `test/features/settings/presentation/study_options_screen_test.dart`

**Interfaces:**
- Consumes: `MxSegmentedTray.onSelected` nullable (Task 1).

- [ ] **Step 1: Change the test first**

In `'turning app defaults off, stepping and saving…'`, replace `await tester.tap(find.text(_en.studyOptionsRandomHint));` with `await tester.tap(find.text(_en.settingsOrderRandom));`. Add a new test after it, in the same `libraryTest` style:

```dart
  libraryTest('while app defaults are on the order tray is read-only (E1)', (
    tester,
    env,
  ) async {
    final ids = await _seed(env);
    await pumpLibraryScreen(tester, env, _screen(ids.subId));

    final tray = tester.widget<MxSegmentedTray<NewCardOrder>>(
      find.byType(MxSegmentedTray<NewCardOrder>),
    );
    expect(tray.onSelected, isNull);
    expect(find.byType(MxOptionRow), findsNothing);
  });
```

(Import `mx_segmented_tray.dart` and `mx_option_row.dart`.)

- [ ] **Step 2: Run it and confirm it fails**

Run: `flutter test test/features/settings/presentation/study_options_screen_test.dart`
Expected: FAIL, because there is no tray and `settingsOrderRandom` is not on screen.

- [ ] **Step 3: Implement**

In `StudyOptionsFormWidget.build`:
- "Use app defaults" row: add `icon: AppIcons.studyOptions,`.
- Card-limit row: add `icon: AppIcons.library,` (the same as Settings).
- Replace the `MxSettingsRow(label: l10n.settingsNewCardOrder, ...)` header and the `for` loop of `MxOptionRow`s with:
  ```dart
            MxSettingsRow(
              label: l10n.settingsNewCardOrder,
              subtitle: l10n.settingsNewCardOrderHint,
              icon: AppIcons.shuffle,
              isEnabled: !form.isUsingAppDefaults,
              wideControl: MxSegmentedTray<NewCardOrder>(
                segments: [
                  MxSegment(
                    value: NewCardOrder.created,
                    label: l10n.settingsOrderCreated,
                  ),
                  MxSegment(
                    value: NewCardOrder.random,
                    label: l10n.settingsOrderRandom,
                  ),
                ],
                selected: options.newCardOrder,
                onSelected: isEditable
                    ? (order) => _controller(ref).chooseNewCardOrder(order)
                    : null,
              ),
            ),
  ```
- Update the class doc: "Screen 15's options: Use app defaults, then the card limit and the new-card order, drawn as Settings draws them (M3-E1), read-only while the deck follows Settings (A1)."
- Swap the `mx_option_row.dart` import for `mx_segmented_tray.dart`.
- Run `grep -rn "studyOptionsCreationOrder\b\|studyOptionsCreationOrderHint\|studyOptionsRandomHint" lib test --include=*.dart | grep -v generated`. Remove every key with no hit from both ARB files (with its `@` entry in `app_en.arb`), then run `flutter gen-l10n`.

- [ ] **Step 4: Run the tests**

Run: `flutter test test/features/settings test/l10n --exclude-tags golden`
Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git add lib/features/settings/presentation/widgets/sections/study_options_form_widget.dart lib/l10n test/features/settings/presentation/study_options_screen_test.dart
git commit -m "fix(ui): Study options draws new-card order and icons as Settings does"
```

---

### Task 12: Study session — Match wrong icon, Recall track, Browse label, Self-assess CTA (F1, F2, F3, C3)

**Files:**
- Modify: `lib/features/study/presentation/widgets/sections/study_match_widget.dart` (`_Tile.build`)
- Modify: `lib/features/study/presentation/widgets/support/recall_countdown_bar_widget.dart`
- Modify: `lib/features/study/presentation/widgets/sections/study_browse_widget.dart` (`_Half.build`)
- Modify: `lib/features/study/presentation/widgets/sections/study_self_assess_widget.dart`
- Test: `study_match_test.dart`, `study_support_widgets_test.dart`, `study_browse_test.dart`, `study_self_assess_test.dart` (all in `test/features/study/presentation/`)

- [ ] **Step 1: Write the failing tests**

Match, in `'a wrong pair flashes wrong…'`, after the two `wrong` tone expectations:

```dart
    expect(
      find.descendant(
        of: find.byType(StudyChoiceWidget),
        matching: find.byIcon(AppIcons.close),
      ),
      findsNWidgets(2),
    );
```

Recall, in the first `RecallCountdownBarWidget` test:

```dart
    expect(
      tester.getSize(find.byType(FractionallySizedBox)).height,
      4,
    );
```

Browse, in its first test after `pumpAndSettle`:

```dart
    // M3-F3: the face label sits in flow above the content, never over it.
    expect(
      find.descendant(
        of: find.byType(StudyBrowseWidget),
        matching: find.byType(Positioned),
      ),
      findsNothing,
    );
```

Self-assess, in the test that reveals the answer (it calls `_reveal`), after revealing:

```dart
    final grades = find.byType(StudyGradeRowWidget);
    expect(
      find.ancestor(of: grades, matching: find.byType(StudyCtaRowWidget)),
      findsOneWidget,
    );
    expect(
      tester.getSize(grades).width,
      tester.getSize(find.byType(StudyCtaRowWidget)).width - AppSpacing.gutter * 2,
    );
```

Import any missing widget or token.

- [ ] **Step 2: Run them and confirm they fail**

Run: `flutter test test/features/study/presentation/study_match_test.dart test/features/study/presentation/study_support_widgets_test.dart test/features/study/presentation/study_browse_test.dart test/features/study/presentation/study_self_assess_test.dart`
Expected: FAIL. There is no ✕, the track is 6, a `Positioned` is present, and there is no `StudyCtaRowWidget`.

- [ ] **Step 3: Implement**

F1, in Match `_Tile.build`, replace `if (tile.isMatched) IconTheme(... const Icon(AppIcons.check))` with:

```dart
            if (tone == StudyChoiceTone.right ||
                tone == StudyChoiceTone.wrong)
              IconTheme(
                data: IconThemeData(color: ink, size: AppIconSize.inline),
                child: Icon(
                  tone == StudyChoiceTone.right
                      ? AppIcons.check
                      : AppIcons.close,
                ),
              ),
```

F2: `static const double _trackHeight = 4;` Add a doc line above it: "The app's thin track (MxLinearProgress, MxStudyTopBar), M3's 4dp (ruling M3-F2)."

F3, in Browse `_Half.build`:

```dart
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.card,
            AppSpacing.gutter,
            AppSpacing.card,
            0,
          ),
          child: Text(
            label.toUpperCase(),
            semanticsLabel: label,
            style: styles.overline,
          ),
        ),
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.gutter),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: AppSpacing.control,
                children: [
                  main,
                  if (detail != null)
                    Text(
                      detail,
                      textAlign: TextAlign.center,
                      style: styles.studyDetail,
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
```

C3, in Self-assess, replace the `Padding(... child: _isRevealed ? … : Center(MxButton…))` with:

```dart
        StudyCtaRowWidget(
          children: [
            if (_isRevealed)
              StudyGradeRowWidget(
                intervals: widget.intervals,
                isBusy: widget.isBusy,
                onGrade: widget.onGrade,
              )
            else
              MxButton(
                label: l10n.studySelfAssessShowAnswer,
                size: MxButtonSize.study,
                onPressed: _reveal,
              ),
          ],
        ),
```

Import `study_cta_row_widget.dart`. Do not change `StudyGradeRowWidget`.

- [ ] **Step 4: Run the tests**

Run: `flutter test test/features/study --exclude-tags golden`
Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git add lib/features/study test/features/study
git commit -m "fix(ui): study modes share icon, track, label and CTA conventions"
```

---

### Task 13: Record the rulings in the screen handoff

**Files:**
- Modify: `docs/shared/ui/screen-handoff/01-deck-list.md` (reorder rows: one `MxCard` per deck, 8 apart; sort/filter sheet: due-only is an `MxSettingsRow` + `MxToggle`, footer `MxSheetActions`)
- Modify: `docs/shared/ui/screen-handoff/02-review-algorithm.md` line 51 (buttons: "Cancel" · "Reset and start cycle {n+1}"; the confirm spins while it runs, and there is no "Resetting…" label)
- Modify: `docs/shared/ui/screen-handoff/15-study-options.md` line 30 (new-card order is an `MxSettingsRow` with `MxSegmentedTray`, as screen 23; rows carry icons)
- Modify: `docs/shared/ui/screen-handoff/19-study-recall.md` line 19 (track 4dp, M3)
- Modify: `docs/shared/ui/screen-handoff/26-language.md` line 20 (`MxSection` + `MxOptionRow` × 3, note as `MxNote`)

- [ ] **Step 1: Edit each line** to state the built behaviour. In each file's deviation table, add a row "M3 consistency review 2026-09-28 (spec `2026-09-28-ui-consistency-m3-review.md`, item X)" wherever the change departs from the kit.

- [ ] **Step 2: Check the docs tooling**

Run: `python3 tools/docs/check.py`
Expected: exit 0.

- [ ] **Step 3: Commit**

```bash
git add docs/shared/ui/screen-handoff
git commit -m "docs(ui): record the M3 consistency rulings in the screen handoff"
```

---

### Task 14: Regenerate goldens and run the full gate

**Files:** `test/**/goldens/*.png` (regenerated only).

- [ ] **Step 1: Regenerate goldens in the validated renderer**

If Task 0 validated this container, run:
`TZ=UTC flutter test --tags golden --update-goldens`

Otherwise, run the Docker recipe in the `golden.Dockerfile` header against this checkout.

- [ ] **Step 2: Review every changed picture**

Run: `git status --short -- 'test/**/goldens/*.png'`
Expected: only goldens of screens this plan touched. These are screens 01, 02, 06, 07, 11, 12, 15, 16, 16a, 17, 19, 22, 23, 25 and 26, the shared widget galleries for the empty state, error state, tray and picker, and the flag/move/restore sheets. Open each one. An unexpected screen means a regression: stop and investigate it with `superpowers:systematic-debugging`.

- [ ] **Step 3: Full gate**

Run:

```bash
dart format --set-exit-if-changed lib test
flutter analyze
python3 .claude/skills/flutter-workflow/scripts/check_generated.py
bash .claude/skills/flutter-workflow/scripts/dod_check.sh
TZ=UTC flutter test --tags golden
```

Expected: every command exits 0.

- [ ] **Step 4: Commit**

```bash
git add test
git commit -m "test(golden): regenerate after the M3 consistency fixes (renderer: <container|docker>)"
```

- [ ] **Step 5: Push**

Run: `git push -u origin ccr-98684bf9-8obmh2`

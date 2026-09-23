# Flutter UI Base — Phase 5 (Surfaces, Rows, Status and Metadata) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the thirteen widgets of handoff groups D and E: Card, IconTile, ListRow, SettingsRow, ActionSheetCommandRow, Note, ListSectionHeader, Section, Badge, StatusBadge, TagChip, WorkloadBreakdownLine and MasteryDonut. Each gets widget tests and light/dark goldens, and joins the debug gallery. EmptyState gains its footnote.

**Architecture:**
- Same shape as phases 2 and 4: `lib/shared/widgets/mx_<name>.dart`. Theme is read only through the `context.*` accessors and the `App*` tokens. Component type treatments go into `MxTextStyles`.
- `MxCard` is a `Material`, not a `DecoratedBox`, so a row's ripple paints on the card instead of under its fill.
- The three tappable rows share one `MxRowInk` (`lib/shared/widgets/mx_row_ink.dart`). It owns the platform ripple, the 2px primary focus ring and the global 0.38 disabled dim, as `mxButtonStyle` does for buttons.
- `MxSection` composes `MxListSectionHeader`, `MxCard` and `MxNote`. The Settings and Reminder screens then build from one unit.
- OptionRow's text styles become the shared row styles (`rowTitle`, `rowDescription`), because ActionSheetCommandRow and SettingsRow state the same treatments.

**Tech Stack:** Flutter 3.47.5, Material 3, `intl` (already a dependency), `flutter_test`.

**Spec:** [`docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md`](../specs/2026-09-23-flutter-ui-base-design.md), §5, §8 and the §9 debt register.
- Contracts: `docs/shared/ui/design-handoff/widgets/{card,icon-tile,list-row,settings-row,action-sheet-command-row,note,list-section-header,section,badge,status-badge,tag-chip,workload-breakdown-line,mastery-donut}.md`.
- Phases 1–4 are merged (#19–#22).

## Global Constraints

- UI only: no `lib/features/` and no backend source.
- The guard rules active on `lib/shared/` apply unchanged:
  - No hex values and no `Colors.*`.
  - No digit literals in `EdgeInsets`, `SizedBox`, `spacing:`, `BorderRadius.circular`, `strokeWidth:` or `BorderSide(width:)`.
  - No `TextStyle(`, no `texts|textStyles.x.copyWith(`, no `styleFrom`.
  - No `Text('…letters…')` literals, and no `label|title|tooltip|semanticLabel: '…'` literals.
  - Booleans read as predicates.
  - A source file stays under 400 lines.
- Component-specific numbers are named `static const` in the widget.
- Every interactive row meets the 48 minimum (`androidTapTargetGuideline`) and is labelled (`labeledTapTargetGuideline`).
- A control inside a row keeps its own semantics node and its own tap.
- A widget holds no copy. Labels, reasons, notes and term builders come from the caller.
- Disabled means the whole row at 0.38 with no tap (the global rule).
- Heights around text are minimums, and text scale is never clamped (spec §5).
- Goldens go into two new files: `test/shared/widgets/surface_widgets_golden_test.dart` for group D, and `test/shared/widgets/status_widgets_golden_test.dart` for group E and Note.
  - Each file stays under 400 lines.
  - Goldens use `expectThemedGoldens`, are generated on Windows at 3x, and are opened and checked against the contract.
- The gate, run before every commit:
  - `dart format` produces no changes.
  - `flutter analyze` is clean.
  - The guard `memox-v8` reports **0 errors and 0 warnings**. Read its `Total:` line; a warning fails the gate too.
- The end-of-phase gate adds:
  - `flutter test`.
  - `check_architecture.py`.
  - The CI tooling tests.
  - `tools/docs/check.py` with 0 errors.
- Commits use scope `ui` or `theme` and end with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- Replies to the user are in Vietnamese.

## Rulings made while planning (carried into spec §9 by Task 8)

- **S1:** Badge offers no `streak` tone. The theme binding marks `streak` FOUNDATION_DEFINED_UNUSED / PRESERVE_ONLY, and spec §4.2 keeps `MxSemanticColors` at nine fields. A screen that paints streak adds it.
- **S2:** The contract does not name a colour for the Badge `neutral` tone. It paints `onSurfaceVariant`, as EmptyState's neutral tone does.
- **S3:** A tonal warning Badge reads in `warningInk`. The kit scopes warning text this way, because the amber fails as 12px text on a light surface; this extends row 20. A solid Badge's label is `onPrimary` for every tone, as written.
- **S4:** Pill and count text uses the FilterChip count's 0.1 label tracking instead of the caption role's 1.2, extending row 26. This covers Badge, StatusBadge, TagChip, WorkloadBreakdownLine and the MasteryDonut label.
- **S5:** 12px text whose contract states only size and colour keeps the caption role, extending row 24. This covers the ListRow sub, the ActionSheetCommandRow sub, the SettingsRow sub and the Note.
- **S6:** StatusBadge's name comes from the caller (required `label`). ADR-011 lets `shared/` import only `core/`, so the status → ARB mapping is a feature `support/` concern. The bare dot announces the same label.
- **S7:** Two ActionSheetCommandRow values are UNSPECIFIED in the contract:
  - Its glyph is 16, the step of the nearest tile (IconTile small, 28).
  - Its label → sub gap is 2, the ListRow gap.
- **S8:** Section owns what sits around its rows:
  - It draws the ghost dividers between its rows, so a row inside a Section carries no divider of its own.
  - It renders its note as an `MxNote`, 8 below the card and inset 4.
- **S9:** Section keeps its contract's 16 gap below the block. Spec §5 gives outer spacing to the caller, but the widget spec wins for its own geometry.
- **S10:** MasteryDonut:
  - Its track is `surfaceContainer`, as its contract states, not MasteryRamp's progress-track.
  - At 0% the label takes `statusLearning`, the band 0 falls in.
  - The label is the locale's percentage (`intl`), and it scales down to stay inside the ring.
- **S11:** The 22 and 18 heights of Badge, StatusBadge and TagChip are minimums that text scaling grows.
- **S12:** WorkloadBreakdownLine:
  - It paints no top margin. The row that stacks it (MxListRow `meta`) owns the 2 gap.
  - The caller passes a builder for each term and the all-zero fallback sentence.
  - The suffix follows the terms after a space.
- **S13:** ListRow, SettingsRow and ActionSheetCommandRow share `MxRowInk`. Its focus ring is a 2px primary foreground border (row 13).
- **S14:** MxCard is a `Material` that always clips (`Clip.antiAlias`) and fills its column's width.
- **S15:** Glyph mapping: info → `info_outline`, folder → `folder_outlined`, pencil → `edit_outlined`, bell → `notifications_none`.
- **S16:** IconTile's `seed` is the one `Color` parameter among the shared widgets. It is per-deck data that the contract passes per instance (COMPONENT_INPUT). ListRow takes a `leading` widget and forwards nothing.
- **S17:** SettingsRow's wide control keeps its own width, start-aligned under the label, because Stepper and SegmentedTray are intrinsic-width.
- **S18:** Badge's leading glyph is 12, below the 16 icon floor, as its contract states.
- **S19:** EmptyState gains `footnote`, an `MxNote` 20 below the action. This resolves the footnote half of row 16.

## Review Focus

1. **Ripples on rows inside a card.**
   - Expected: a tap on a row inside `MxCard` or `MxSection` shows its ripple on the card surface, not hidden under an opaque fill.
   - Pinned in Task 2 (the nearest `Material` above the row is the card's).
2. **A long title at 2x text.**
   - Expected: a ListRow stays one line with an ellipsis, and every row keeps one height.
   - Expected: a SettingsRow wraps its label without squeezing its trailing control.
   - Pinned in Tasks 3 and 4.
3. **A row that holds a control.**
   - Expected: the overflow button or toggle keeps its own semantics node, and its tap does not fire the row.
   - Pinned in Task 3.
4. **WorkloadBreakdownLine with zero terms.**
   - Expected: no dangling separator, a fixed order, the fallback when all counts are zero, and an assertion on negative counts.
   - Pinned in Task 7.
5. **MasteryDonut at the edges.**
   - Expected: 0 paints the track only, 1 paints the full ring, and NaN or out-of-range values assert.
   - Expected: the label and the arc always share one colour.
   - Pinned in Task 7.

---

## File Structure

```
lib/core/theme/
  mx_text_styles.dart          modify: rowTitle/rowDescription (renamed), listRowTitle,
                                       rowSubtitle, settingsLabel, commandLabel, overline,
                                       badgeLabel, tagLabel, noteText, workloadText,
                                       workloadTerm, donutLabel
  app_decorations.dart         modify: heroCard
  foundations/app_icons.dart   modify: info, folder, edit, reminder
lib/shared/widgets/
  mx_option_row.dart           modify: renamed styles
  mx_empty_state.dart          modify: footnote
  mx_card.dart                 create
  mx_icon_tile.dart            create
  mx_row_ink.dart              create
  mx_list_row.dart             create
  mx_settings_row.dart         create
  mx_action_sheet_command_row.dart  create
  mx_note.dart                 create
  mx_list_section_header.dart  create
  mx_section.dart              create
  mx_badge.dart                create
  mx_status_badge.dart         create
  mx_tag_chip.dart             create
  mx_workload_breakdown_line.dart   create
  mx_mastery_donut.dart        create
lib/app/gallery/
  gallery_surfaces_section.dart     create (group D)
  gallery_status_section.dart       create (group E)
  gallery_screen.dart               modify
test/core/theme/{mx_text_styles_test,app_decorations_test}.dart   modify
test/shared/widgets/mx_<name>_test.dart                          create, one per widget
test/shared/widgets/mx_empty_state_test.dart                     modify
test/shared/widgets/{surface,status}_widgets_golden_test.dart    create
test/app/gallery_test.dart                                       modify
docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md      modify (§9 rows 28–42)
```

---

### Task 1: Theme additions

**Files:**
- Modify: `lib/core/theme/mx_text_styles.dart`, `lib/core/theme/app_decorations.dart`, `lib/core/theme/foundations/app_icons.dart`, `lib/shared/widgets/mx_option_row.dart`
- Test: `test/core/theme/mx_text_styles_test.dart`, `test/core/theme/app_decorations_test.dart`

**Interfaces:**
- Produces on `MxTextStyles`:
  - Getters: `rowTitle`, `rowDescription`, `listRowTitle`, `rowSubtitle`, `settingsLabel`, `overline`, `tagLabel`, `noteText`, `workloadText`.
  - Methods: `commandLabel({required bool isDestructive})`, `badgeLabel(Color ink)`, `workloadTerm(Color ink)`, `donutLabel(Color ink)`.
  - `optionTitle` and `optionDescription` are removed.
- Produces `AppDecorations.heroCard(ColorScheme, MxDerivedColors) → BoxDecoration`.
- Produces `AppIcons.info`, `AppIcons.folder`, `AppIcons.edit` and `AppIcons.reminder`.

- [ ] **Step 1: Write the failing tests**

In `test/core/theme/mx_text_styles_test.dart`, replace the test `'option row: title 14/600/-0.1, description 12 at 1.45'` with:

```dart
  test('row styles: title 14/600/-0.1, list title at 1.35, sub-lines 12', () {
    expectStyle(
      styles.rowTitle,
      size: 14,
      weight: FontWeight.w600,
      tracking: -0.1,
      color: scheme.onSurface,
    );
    expectStyle(
      styles.listRowTitle,
      size: 14,
      weight: FontWeight.w600,
      tracking: -0.1,
    );
    expect(styles.listRowTitle.height, 1.35);
    expectStyle(
      styles.rowDescription,
      size: 12,
      weight: FontWeight.w600,
      color: scheme.onSurfaceVariant,
    );
    expect(styles.rowDescription.height, 1.45);
    expectStyle(
      styles.rowSubtitle,
      size: 12,
      weight: FontWeight.w600,
      color: scheme.onSurfaceVariant,
    );
  });

  test('settings label 16/600/-0.1; a destructive command label is error', () {
    expectStyle(
      styles.settingsLabel,
      size: 16,
      weight: FontWeight.w600,
      tracking: -0.1,
      color: scheme.onSurface,
    );
    expect(styles.commandLabel(isDestructive: false).color, scheme.onSurface);
    expectStyle(
      styles.commandLabel(isDestructive: true),
      size: 14,
      weight: FontWeight.w600,
      color: scheme.error,
    );
  });

  test('overline 12/700 at 0.6, tabular, onSurfaceVariant', () {
    expectStyle(
      styles.overline,
      size: 12,
      weight: FontWeight.w700,
      tracking: 0.6,
      color: scheme.onSurfaceVariant,
    );
    expect(
      styles.overline.fontFeatures,
      contains(const FontFeature.tabularFigures()),
    );
  });

  test('pills: badge 12/700 tabular and tag 12/600, line-height 1, 0.1', () {
    final badge = styles.badgeLabel(scheme.primary);
    expectStyle(
      badge,
      size: 12,
      weight: FontWeight.w700,
      tracking: 0.1,
      color: scheme.primary,
    );
    expect(badge.height, 1);
    expect(badge.fontFeatures, contains(const FontFeature.tabularFigures()));
    expectStyle(
      styles.tagLabel,
      size: 12,
      weight: FontWeight.w600,
      tracking: 0.1,
      color: scheme.onSurfaceVariant,
    );
    expect(styles.tagLabel.height, 1);
  });

  test('note 12 at 1.5; workload 12/400 with 600 terms; donut 9/700', () {
    expectStyle(
      styles.noteText,
      size: 12,
      weight: FontWeight.w600,
      color: scheme.onSurfaceVariant,
    );
    expect(styles.noteText.height, 1.5);
    expectStyle(
      styles.workloadText,
      size: 12,
      weight: FontWeight.w400,
      tracking: 0.1,
      color: scheme.onSurfaceVariant,
    );
    expect(styles.workloadText.height, 1.5);
    expect(
      styles.workloadText.fontFeatures,
      contains(const FontFeature.tabularFigures()),
    );
    expectStyle(
      styles.workloadTerm(scheme.primary),
      size: 12,
      weight: FontWeight.w600,
      color: scheme.primary,
    );
    expectStyle(
      styles.donutLabel(scheme.primary),
      size: 9,
      weight: FontWeight.w700,
      color: scheme.primary,
    );
  });
```

Append to `test/core/theme/app_decorations_test.dart`, inside `main`:

```dart
  test('hero: surface-hero fill with the ghost edge in both themes', () {
    for (final (scheme, semantic) in [
      (AppColorSchemes.light, MxSemanticColors.light),
      (AppColorSchemes.dark, MxSemanticColors.dark),
    ]) {
      final derived = MxDerivedColors.resolve(scheme, semantic);
      final hero = AppDecorations.heroCard(scheme, derived);

      expect(hero.color, derived.surfaceHero);
      expect(hero.border, Border.all(color: derived.ghostBorder));
      expect(hero.borderRadius, BorderRadius.circular(20));
      expect(hero.boxShadow, AppShadows.whisper(scheme));
    }
  });
```

- [ ] **Step 2: Run them to verify they fail**

Run: `flutter test test/core/theme/mx_text_styles_test.dart test/core/theme/app_decorations_test.dart`
Expected: FAIL to compile, because `rowTitle`, `heroCard` and the other new members are not defined.

- [ ] **Step 3: Implement**

In `lib/core/theme/mx_text_styles.dart`, make four changes.

First, replace the two option constants with:

```dart
  static const double _rowTitleTracking = -0.1;
  static const double _rowDescriptionHeight = 1.45;
  static const double _listRowTitleHeight = 1.35;
  static const double _overlineTracking = 0.6;
  static const double _pillHeight = 1;
  static const double _noteHeight = 1.5;
  static const double _workloadHeight = 1.5;
  static const double _donutLabelSize = 9;
```

Second, replace the `optionTitle` and `optionDescription` getters with:

```dart
  /// Row title (OptionRow, ActionSheetCommandRow): 14/600, -0.1.
  TextStyle get rowTitle => AppTypography.withWeight(
    _texts.bodyMedium!,
    FontWeight.w600,
  ).copyWith(letterSpacing: _rowTitleTracking, color: _scheme.onSurface);

  /// Row description (OptionRow, SettingsRow sub): the caption role at
  /// line-height 1.45 (I5, S5).
  TextStyle get rowDescription => _texts.labelSmall!.copyWith(
    height: _rowDescriptionHeight,
    color: _scheme.onSurfaceVariant,
  );
```

Third, add after `rowDescription`:

```dart
  /// ListRow title: the row title at line-height 1.35, so every row in a list
  /// is one height.
  TextStyle get listRowTitle => rowTitle.copyWith(height: _listRowTitleHeight);

  /// ListRow and ActionSheetCommandRow sub-line: the caption role in
  /// onSurfaceVariant (S5).
  TextStyle get rowSubtitle => footerCaption;

  /// SettingsRow label: 16/600, -0.1.
  TextStyle get settingsLabel => AppTypography.withWeight(
    _texts.bodyLarge!,
    FontWeight.w600,
  ).copyWith(letterSpacing: _rowTitleTracking, color: _scheme.onSurface);

  /// ActionSheetCommandRow verb: the row title, error when destructive.
  TextStyle commandLabel({required bool isDestructive}) => rowTitle.copyWith(
    color: isDestructive ? _scheme.error : _scheme.onSurface,
  );

  /// Overline (Section, ListSectionHeader): 12/700, 0.6 tracking,
  /// onSurfaceVariant. Tabular, so a trailing static count lines up. The
  /// widget upper-cases the text.
  TextStyle get overline => AppTypography.withWeight(
    _texts.labelSmall!,
    FontWeight.w700,
  ).copyWith(
    letterSpacing: _overlineTracking,
    fontFeatures: _tabular,
    color: _scheme.onSurfaceVariant,
  );

  /// Badge and StatusBadge label: 12/700 tabular at line-height 1, with the
  /// label's 0.1 tracking (S4).
  TextStyle badgeLabel(Color ink) =>
      chipCount(ink).copyWith(height: _pillHeight);

  /// TagChip label: 12/600 at line-height 1, 0.1 tracking (S4).
  TextStyle get tagLabel => _texts.labelSmall!.copyWith(
    height: _pillHeight,
    letterSpacing: _labelTracking,
    color: _scheme.onSurfaceVariant,
  );

  /// Note text: the caption role at line-height 1.5 (S5).
  TextStyle get noteText => _texts.labelSmall!.copyWith(
    height: _noteHeight,
    color: _scheme.onSurfaceVariant,
  );

  /// WorkloadBreakdownLine connectives and fallback: 12/400 tabular, 0.1
  /// tracking (S4), line-height 1.5 for the 18 band.
  TextStyle get workloadText => AppTypography.withWeight(
    _texts.labelSmall!,
    FontWeight.w400,
  ).copyWith(
    height: _workloadHeight,
    letterSpacing: _labelTracking,
    fontFeatures: _tabular,
    color: _scheme.onSurfaceVariant,
  );

  /// WorkloadBreakdownLine term: the connective style at 600 in its colour.
  TextStyle workloadTerm(Color ink) => AppTypography.withWeight(
    workloadText,
    FontWeight.w600,
  ).copyWith(color: ink);

  /// MasteryDonut label: 9/700 at line-height 1, 0.1 tracking (S4), in the
  /// arc colour. Below the 12 floor as the contract states (row 8).
  TextStyle donutLabel(Color ink) => AppTypography.withWeight(
    _texts.labelSmall!,
    FontWeight.w700,
  ).copyWith(
    fontSize: _donutLabelSize,
    height: _pillHeight,
    letterSpacing: _labelTracking,
    color: ink,
  );
```

Fourth, in `lib/shared/widgets/mx_option_row.dart`, replace `styles.optionTitle` with `styles.rowTitle` and `styles.optionDescription` with `styles.rowDescription`.

In `lib/core/theme/app_decorations.dart`, add after `raisedCard`:

```dart
  /// The tinted hero Card: the surface-hero fill, with the ghost edge in both
  /// themes, because a borderless hero dissolves into the light page.
  static BoxDecoration heroCard(
    ColorScheme scheme,
    MxDerivedColors derived,
  ) => raisedCard(scheme, derived).copyWith(
    color: derived.surfaceHero,
    border: Border.all(color: derived.ghostBorder, width: AppStroke.hairline),
  );
```

In `lib/core/theme/foundations/app_icons.dart`, add after the `remove` line:

```dart
  static const IconData info = Icons.info_outline; // info
  static const IconData folder = Icons.folder_outlined; // folder
  static const IconData edit = Icons.edit_outlined; // pencil
  static const IconData reminder = Icons.notifications_none; // bell
```

- [ ] **Step 4: Run them to verify they pass**

Run: `flutter test test/core/theme test/shared/widgets/mx_option_row_test.dart`
Expected: PASS.

- [ ] **Step 5: Gate and commit**

```bash
dart format lib test
flutter analyze
python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
git add lib/core/theme lib/shared/widgets/mx_option_row.dart test/core/theme
git commit -m "feat(theme): phase 5 row, pill and overline styles; hero card; icons

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

Expected:
- Analyze is clean.
- The guard reports `Errors: 0 | Warnings: 0`.

---

### Task 2: MxCard and MxIconTile

**Files:**
- Create: `lib/shared/widgets/mx_card.dart`, `lib/shared/widgets/mx_icon_tile.dart`, `test/shared/widgets/surface_widgets_golden_test.dart`
- Test: `test/shared/widgets/mx_card_test.dart`, `test/shared/widgets/mx_icon_tile_test.dart`

**Interfaces:**
- Consumes: `AppDecorations.raisedCard`/`heroCard`, `AppIcons.folder`/`reminder`/`library`.
- Produces:
  - `MxCard({required Widget child, bool isFullBleed = false, bool isHero = false})`
  - `enum MxIconTileSize { small, medium, large }`
  - `MxIconTile({IconData? icon, Widget? child, MxIconTileSize size = MxIconTileSize.small, Color? seed})`, with exactly one of `icon` and `child`.

- [ ] **Step 1: Write the failing tests**

`test/shared/widgets/mx_card_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/foundations/app_shadows.dart';
import 'package:memox/core/theme/mx_derived_colors.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
import 'package:memox/shared/widgets/mx_card.dart';

import '../../support/widget_harness.dart';

const _bodyKey = ValueKey('card-body');

Material _surface(WidgetTester tester) => tester.widget<Material>(
  find
      .descendant(of: find.byType(MxCard), matching: find.byType(Material))
      .first,
);

RoundedRectangleBorder _shape(WidgetTester tester) =>
    _surface(tester).shape! as RoundedRectangleBorder;

List<BoxShadow>? _shadow(WidgetTester tester) =>
    (tester
                .widget<DecoratedBox>(
                  find
                      .descendant(
                        of: find.byType(MxCard),
                        matching: find.byType(DecoratedBox),
                      )
                      .first,
                )
                .decoration
            as BoxDecoration)
        .boxShadow;

void main() {
  testWidgets('light: raised fill, radius 20, 20 padding, whisper, no edge', (
    tester,
  ) async {
    final scheme = AppColorSchemes.light;
    await pumpMx(
      tester,
      const MxCard(child: SizedBox(key: _bodyKey, height: 40)),
    );

    expect(_surface(tester).color, scheme.surfaceContainerLowest);
    expect(_shape(tester).borderRadius, BorderRadius.circular(20));
    expect(_shape(tester).side, BorderSide.none);
    expect(_shadow(tester), AppShadows.whisper(scheme));
    expect(
      tester.getTopLeft(find.byKey(_bodyKey)) -
          tester.getTopLeft(find.byType(MxCard)),
      const Offset(20, 20),
    );
    expect(tester.getSize(find.byType(MxCard)).width, 360);
  });

  testWidgets('dark: a 1px ghost edge and no shadow', (tester) async {
    final scheme = AppColorSchemes.dark;
    final derived = MxDerivedColors.resolve(scheme, MxSemanticColors.dark);
    await pumpMx(
      tester,
      const MxCard(child: SizedBox(height: 40)),
      brightness: Brightness.dark,
    );

    expect(_shape(tester).side, BorderSide(color: derived.ghostBorder));
    expect(_shadow(tester), isEmpty);
  });

  testWidgets('hero: surface-hero fill keeps the ghost edge in light', (
    tester,
  ) async {
    final scheme = AppColorSchemes.light;
    final derived = MxDerivedColors.resolve(scheme, MxSemanticColors.light);
    await pumpMx(
      tester,
      const MxCard(isHero: true, child: SizedBox(height: 40)),
    );

    expect(_surface(tester).color, derived.surfaceHero);
    expect(_shape(tester).side, BorderSide(color: derived.ghostBorder));
  });

  testWidgets('full bleed: no padding, clipped, the row ripple on the card', (
    tester,
  ) async {
    await pumpMx(
      tester,
      MxCard(
        isFullBleed: true,
        child: InkWell(
          key: _bodyKey,
          onTap: () {},
          child: const SizedBox(height: 48),
        ),
      ),
    );

    expect(
      tester.getTopLeft(find.byKey(_bodyKey)),
      tester.getTopLeft(find.byType(MxCard)),
    );
    expect(_surface(tester).clipBehavior, Clip.antiAlias);
    // Review Focus 1: the nearest Material above the row is the card's, so
    // the ripple paints on the card instead of under its fill.
    expect(
      tester.widget<Material>(
        find
            .ancestor(of: find.byKey(_bodyKey), matching: find.byType(Material))
            .first,
      ),
      same(_surface(tester)),
    );
  });
}
```

`test/shared/widgets/mx_icon_tile_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';

import '../../support/widget_harness.dart';

const _childKey = ValueKey('tile-child');
const _seed = Color(0xFF0E9F6E);

BoxDecoration _tile(WidgetTester tester) =>
    tester
            .widget<DecoratedBox>(
              find.descendant(
                of: find.byType(MxIconTile),
                matching: find.byType(DecoratedBox),
              ),
            )
            .decoration
        as BoxDecoration;

void main() {
  testWidgets('three steps: 28/8/16, 36/12/20, 44/12/20', (tester) async {
    for (final (size, box, radius, glyph) in [
      (MxIconTileSize.small, 28.0, 8.0, 16.0),
      (MxIconTileSize.medium, 36.0, 12.0, 20.0),
      (MxIconTileSize.large, 44.0, 12.0, 20.0),
    ]) {
      await pumpMx(tester, MxIconTile(icon: AppIcons.folder, size: size));

      expect(tester.getSize(find.byType(MxIconTile)), Size.square(box));
      expect(_tile(tester).borderRadius, BorderRadius.circular(radius));
      expect(tester.widget<Icon>(find.byType(Icon)).size, glyph);
    }
  });

  testWidgets('default: primary at 10% light and 16% dark, primary glyph', (
    tester,
  ) async {
    final light = AppColorSchemes.light.primary;
    await pumpMx(tester, const MxIconTile(icon: AppIcons.folder));
    expect(_tile(tester).color, light.withValues(alpha: 0.10));
    expect(tester.widget<Icon>(find.byType(Icon)).color, light);

    await pumpMx(
      tester,
      const MxIconTile(icon: AppIcons.folder),
      brightness: Brightness.dark,
    );
    expect(
      _tile(tester).color,
      AppColorSchemes.dark.primary.withValues(alpha: 0.16),
    );
  });

  testWidgets('seeded: the seed at 12% with a seed glyph', (tester) async {
    await pumpMx(tester, const MxIconTile(icon: AppIcons.folder, seed: _seed));

    expect(_tile(tester).color, _seed.withValues(alpha: 0.12));
    expect(tester.widget<Icon>(find.byType(Icon)).color, _seed);
  });

  testWidgets('a child replaces the glyph; the tile never shrinks', (
    tester,
  ) async {
    await pumpMx(
      tester,
      Row(
        children: [
          const MxIconTile(child: SizedBox(key: _childKey)),
          Expanded(child: Text(List.filled(60, 'word').join(' '))),
        ],
      ),
    );

    expect(find.byKey(_childKey), findsOneWidget);
    expect(find.byType(Icon), findsNothing);
    expect(tester.getSize(find.byType(MxIconTile)), const Size.square(28));
  });

  test('an icon or a child, not both', () {
    expect(
      () => MxIconTile(icon: AppIcons.folder, child: const SizedBox()),
      throwsAssertionError,
    );
  });
}
```

`test/shared/widgets/surface_widgets_golden_test.dart`:

```dart
@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';

import '../../support/golden_harness.dart';

void main() {
  testWidgets('MxCard and MxIconTile', (tester) async {
    await expectThemedGoldens(
      tester,
      'mx_card_icon_tile',
      const Column(
        spacing: 16,
        children: [
          MxCard(child: SizedBox(height: 56)),
          MxCard(isHero: true, child: SizedBox(height: 56)),
          Row(
            spacing: 12,
            children: [
              MxIconTile(icon: AppIcons.library),
              MxIconTile(
                icon: AppIcons.reminder,
                size: MxIconTileSize.medium,
              ),
              MxIconTile(icon: AppIcons.library, size: MxIconTileSize.large),
              MxIconTile(icon: AppIcons.folder, seed: Color(0xFF0E9F6E)),
            ],
          ),
        ],
      ),
    );
  });
}
```

- [ ] **Step 2: Run them to verify they fail**

Run: `flutter test test/shared/widgets/mx_card_test.dart test/shared/widgets/mx_icon_tile_test.dart`
Expected: FAIL to compile, because `mx_card.dart` and `mx_icon_tile.dart` do not exist.

- [ ] **Step 3: Implement**

`lib/shared/widgets/mx_card.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/app_decorations.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';

/// The base surface. Light lifts it with the whisper shadow; dark draws the
/// hairline ghost edge instead. It is a Material, so the ripple of a row
/// inside paints on the card instead of under its fill (ruling S14).
class MxCard extends StatelessWidget {
  const MxCard({
    super.key,
    required this.child,
    this.isFullBleed = false,
    this.isHero = false,
  });

  final Widget child;

  /// No padding, for rows that run edge to edge. The card clips them to its
  /// radius, so their dividers meet the corners.
  final bool isFullBleed;

  /// The surface-hero tint, with the ghost edge in both themes.
  final bool isHero;

  @override
  Widget build(BuildContext context) {
    final surface = isHero
        ? AppDecorations.heroCard(context.colors, context.derivedColors)
        : AppDecorations.raisedCard(context.colors, context.derivedColors);
    final radius = surface.borderRadius!;
    final edge = surface.border as Border?;
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: surface.boxShadow,
        ),
        child: Material(
          color: surface.color,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: edge?.top ?? BorderSide.none,
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: isFullBleed
                ? EdgeInsets.zero
                : const EdgeInsets.all(AppSpacing.card),
            child: child,
          ),
        ),
      ),
    );
  }
}
```

`lib/shared/widgets/mx_icon_tile.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/theme_context.dart';

/// The size steps, each with one role: small leads content rows, medium
/// leads settings rows, large leads deck rows.
enum MxIconTileSize { small, medium, large }

/// The tinted square that leads a row. It never shrinks; the text beside it
/// gives up space first.
class MxIconTile extends StatelessWidget {
  const MxIconTile({
    super.key,
    this.icon,
    this.child,
    this.size = MxIconTileSize.small,
    this.seed,
  }) : assert((icon == null) != (child == null), 'an icon or a child');

  final IconData? icon;

  /// Replaces the glyph: a letter, a count, a donut.
  final Widget? child;
  final MxIconTileSize size;

  /// A per-deck colour from the caller's data (ruling S16). Null tints with
  /// primary.
  final Color? seed;

  static const double _smallBox = 28;
  static const double _mediumBox = 36;
  static const double _largeBox = 44;
  static const double _primaryTintLight = 0.10;
  static const double _primaryTintDark = 0.16;
  static const double _seedTint = 0.12;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final ink = seed ?? colors.primary;
    final tint = switch ((seed, colors.brightness)) {
      (_?, _) => _seedTint,
      (null, Brightness.light) => _primaryTintLight,
      (null, Brightness.dark) => _primaryTintDark,
    };
    final (box, radius, glyph) = switch (size) {
      MxIconTileSize.small => (_smallBox, AppRadius.sm, AppIconSize.inline),
      MxIconTileSize.medium => (_mediumBox, AppRadius.md, AppIconSize.compact),
      MxIconTileSize.large => (_largeBox, AppRadius.md, AppIconSize.compact),
    };
    return SizedBox.square(
      dimension: box,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: ink.withValues(alpha: tint),
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Center(child: child ?? Icon(icon, size: glyph, color: ink)),
      ),
    );
  }
}
```

- [ ] **Step 4: Run them to verify they pass**

Run: `flutter test test/shared/widgets/mx_card_test.dart test/shared/widgets/mx_icon_tile_test.dart`
Expected: PASS, 4 + 5 tests.

- [ ] **Step 5: Golden, gate, commit**

```bash
flutter test --update-goldens --tags golden test/shared/widgets/surface_widgets_golden_test.dart
flutter test --tags golden test/shared/widgets/surface_widgets_golden_test.dart
dart format lib test
flutter analyze
python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
git add lib/shared/widgets test/shared/widgets
git commit -m "feat(ui): MxCard, MxIconTile

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

Open `mx_card_icon_tile_light.png` and `_dark.png` and check them against the contract:
- In light, the plain card has a faint shadow and no edge.
- In dark, the plain card has a hairline edge and no shadow.
- The hero card is tinted and has a hairline edge in both themes.
- The tiles are 28, 36 and 44, and the seeded tile is green.

---

### Task 3: MxRowInk and MxListRow

**Files:**
- Create: `lib/shared/widgets/mx_row_ink.dart`, `lib/shared/widgets/mx_list_row.dart`
- Modify: `test/shared/widgets/surface_widgets_golden_test.dart`
- Test: `test/shared/widgets/mx_row_ink_test.dart`, `test/shared/widgets/mx_list_row_test.dart`

**Interfaces:**
- Consumes: `context.textStyles.listRowTitle`/`rowSubtitle`, `MxIconTile`, `MxIconButton(icon:, semanticLabel:, onPressed:)`.
- Produces:
  - `MxRowInk({required VoidCallback? onTap, required Widget child, bool isEnabled = true})`
  - `MxListRow({required String title, String? subtitle, Widget? meta, Widget? leading, Widget? trailing, bool hasChevron = false, VoidCallback? onTap, bool isEnabled = true, bool isBusy = false, bool hasDivider = true})`

- [ ] **Step 1: Write the failing tests**

`test/shared/widgets/mx_row_ink_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/shared/widgets/mx_row_ink.dart';

import '../../support/widget_harness.dart';

void main() {
  testWidgets('static: no ripple and nothing to focus', (tester) async {
    await pumpMx(
      tester,
      const MxRowInk(onTap: null, child: SizedBox(width: 200, height: 48)),
    );

    expect(find.byType(InkWell), findsNothing);
  });

  testWidgets('tappable: fires, and focus draws the 2px primary ring', (
    tester,
  ) async {
    var taps = 0;
    await pumpMx(
      tester,
      MxRowInk(
        onTap: () => taps++,
        child: const SizedBox(width: 200, height: 48),
      ),
    );
    await tester.tap(find.byType(MxRowInk));
    expect(taps, 1);

    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(
      () => FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    final ring =
        tester
                .widget<DecoratedBox>(
                  find.descendant(
                    of: find.byType(MxRowInk),
                    matching: find.byType(DecoratedBox),
                  ),
                )
                .decoration
            as BoxDecoration;

    expect(
      ring.border,
      Border.all(color: AppColorSchemes.light.primary, width: 2),
    );
  });

  testWidgets('disabled: 0.38, no tap, a disabled button', (tester) async {
    final handle = tester.ensureSemantics();
    var taps = 0;
    await pumpMx(
      tester,
      MxRowInk(
        onTap: () => taps++,
        isEnabled: false,
        child: const Text('Move here'),
      ),
    );
    await tester.tap(find.byType(MxRowInk), warnIfMissed: false);

    expect(taps, 0);
    expect(
      tester
          .widget<Opacity>(
            find.descendant(
              of: find.byType(MxRowInk),
              matching: find.byType(Opacity),
            ),
          )
          .opacity,
      0.38,
    );
    expect(
      tester.getSemantics(find.text('Move here')),
      isSemantics(
        label: 'Move here',
        isButton: true,
        hasEnabledState: true,
        isEnabled: false,
      ),
    );
    handle.dispose();
  });
}
```

`test/shared/widgets/mx_list_row_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';

import '../../support/widget_harness.dart';

const _first = ValueKey('row-1');
const _second = ValueKey('row-2');

Widget _width(Widget child) => SizedBox(width: 360, child: child);

void main() {
  final scheme = AppColorSchemes.light;

  testWidgets('one-line title and sub; 16 inset; 48 floor', (tester) async {
    await pumpMx(
      tester,
      _width(
        const MxListRow(
          title: 'Kanji N5',
          subtitle: '42 cards',
          leading: MxIconTile(icon: AppIcons.library),
        ),
      ),
    );
    final title = tester.widget<Text>(find.text('Kanji N5'));
    final sub = tester.widget<Text>(find.text('42 cards'));

    expect((title.maxLines, title.overflow), (1, TextOverflow.ellipsis));
    expect((sub.maxLines, sub.overflow), (1, TextOverflow.ellipsis));
    expect(title.style!.fontSize, 14);
    expect(sub.style!.color, scheme.onSurfaceVariant);
    expect(
      tester.getTopLeft(find.byType(MxIconTile)).dx -
          tester.getTopLeft(find.byType(MxListRow)).dx,
      16,
    );
    expect(
      tester.getTopLeft(find.text('42 cards')).dy -
          tester.getBottomLeft(find.text('Kanji N5')).dy,
      2,
    );
    expect(
      tester.getSize(find.byType(MxListRow)).height,
      greaterThanOrEqualTo(48),
    );
  });

  testWidgets('a long title stays one line at 2x; rows keep one height', (
    tester,
  ) async {
    await pumpMx(
      tester,
      _width(
        Column(
          children: [
            MxListRow(
              key: _first,
              title: List.filled(12, 'Từ vựng tiếng Nhật').join(' '),
              subtitle: '42 cards',
            ),
            const MxListRow(key: _second, title: 'Kana', subtitle: '46 cards'),
          ],
        ),
      ),
      textScale: 2,
    );

    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byKey(_first)).height,
      tester.getSize(find.byKey(_second)).height,
    );
  });

  testWidgets('a trailing control keeps its own node and tap (RF3)', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    var rowTaps = 0;
    var menuTaps = 0;
    await pumpMx(
      tester,
      _width(
        MxListRow(
          title: 'Kanji N5',
          subtitle: '42 cards',
          onTap: () => rowTaps++,
          trailing: MxIconButton(
            icon: AppIcons.more,
            semanticLabel: 'Deck actions',
            onPressed: () => menuTaps++,
          ),
        ),
      ),
    );
    await tester.tap(find.byTooltip('Deck actions'));
    expect((rowTaps, menuTaps), (0, 1));
    await tester.tap(find.text('Kanji N5'));
    expect(rowTaps, 1);

    final row = tester.getSemantics(find.text('Kanji N5'));
    expect(row, isSemantics(label: 'Kanji N5\n42 cards', isButton: true));
    expect(tester.getSemantics(find.byTooltip('Deck actions')).id,
        isNot(row.id));
    handle.dispose();
    await expectAccessibleTargets(tester);
  });

  testWidgets('chevron and busy spinner fill the trailing slot', (
    tester,
  ) async {
    await pumpMx(
      tester,
      _width(MxListRow(title: 'Kanji N5', hasChevron: true, onTap: () {})),
    );
    expect(
      tester.widget<Icon>(find.byIcon(AppIcons.chevronRight)).color,
      scheme.onSurfaceVariant,
    );

    await pumpMx(
      tester,
      _width(
        MxListRow(
          title: 'Kanji N5',
          hasChevron: true,
          isBusy: true,
          onTap: () {},
        ),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byIcon(AppIcons.chevronRight), findsNothing);
  });

  testWidgets('divider unless last; disabled dims and ignores taps', (
    tester,
  ) async {
    BoxBorder? edge() =>
        (tester
                    .widget<DecoratedBox>(
                      find
                          .descendant(
                            of: find.byType(MxListRow),
                            matching: find.byType(DecoratedBox),
                          )
                          .first,
                    )
                    .decoration
                as BoxDecoration)
            .border;

    await pumpMx(tester, _width(const MxListRow(title: 'Kana')));
    expect(edge(), isNotNull);
    await pumpMx(
      tester,
      _width(const MxListRow(title: 'Kana', hasDivider: false)),
    );
    expect(edge(), isNull);

    var taps = 0;
    await pumpMx(
      tester,
      _width(
        MxListRow(
          title: 'Grammar',
          subtitle: 'Cannot hold another deck',
          isEnabled: false,
          onTap: () => taps++,
        ),
      ),
    );
    await tester.tap(find.text('Grammar'), warnIfMissed: false);
    expect(taps, 0);
    expect(
      tester
          .widget<Opacity>(
            find.ancestor(
              of: find.text('Grammar'),
              matching: find.byType(Opacity),
            ),
          )
          .opacity,
      0.38,
    );
  });

  test('subtitle or meta, trailing or chevron', () {
    expect(
      () => MxListRow(title: 'a', subtitle: 'b', meta: const SizedBox()),
      throwsAssertionError,
    );
    expect(
      () => MxListRow(
        title: 'a',
        trailing: const SizedBox(),
        hasChevron: true,
      ),
      throwsAssertionError,
    );
  });
}
```

Before the closing `}` of `test/shared/widgets/surface_widgets_golden_test.dart`, append the test below. Add imports for `mx_icon_button.dart` and `mx_list_row.dart`.

```dart
  testWidgets('MxListRow states in a full-bleed card', (tester) async {
    await expectThemedGoldens(
      tester,
      'mx_list_row',
      MxCard(
        isFullBleed: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MxListRow(
              title: 'Kanji N5',
              subtitle: '42 cards · 12 due',
              leading: const MxIconTile(icon: AppIcons.library),
              hasChevron: true,
              onTap: () {},
            ),
            MxListRow(
              title: 'A deck name long enough to be cut with an ellipsis',
              subtitle: 'Nested three levels deep under Japanese',
              leading: const MxIconTile(
                icon: AppIcons.folder,
                seed: Color(0xFF0E9F6E),
              ),
              trailing: MxIconButton(
                icon: AppIcons.more,
                semanticLabel: 'Deck actions',
                onPressed: () {},
              ),
              onTap: () {},
            ),
            MxListRow(
              title: 'Importing',
              subtitle: '120 of 300 cards',
              leading: const MxIconTile(icon: AppIcons.library),
              isBusy: true,
              onTap: () {},
            ),
            MxListRow(
              title: 'Grammar',
              subtitle: 'Cannot hold another deck',
              leading: const MxIconTile(icon: AppIcons.folder),
              isEnabled: false,
              onTap: () {},
              hasDivider: false,
            ),
          ],
        ),
      ),
    );
  });
```

- [ ] **Step 2: Run them to verify they fail**

Run: `flutter test test/shared/widgets/mx_row_ink_test.dart test/shared/widgets/mx_list_row_test.dart`
Expected: FAIL to compile, because the widget files do not exist.

- [ ] **Step 3: Implement**

`lib/shared/widgets/mx_row_ink.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/theme_context.dart';

/// What the tappable rows share (spec §4.5, ruling S13):
/// - the platform ripple across the whole row;
/// - a 2px primary ring when focused;
/// - the global 0.38 dim when disabled.
///
/// A row without [onTap] is static: no ripple, and not focusable. A control
/// inside the row keeps its own semantics node and its own tap.
class MxRowInk extends StatefulWidget {
  const MxRowInk({
    super.key,
    required this.onTap,
    required this.child,
    this.isEnabled = true,
  });

  final VoidCallback? onTap;
  final Widget child;
  final bool isEnabled;

  @override
  State<MxRowInk> createState() => _MxRowInkState();
}

class _MxRowInkState extends State<MxRowInk> {
  var _hasFocus = false;

  @override
  void didUpdateWidget(MxRowInk oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A row that stops being tappable drops out of focus without a callback.
    if (widget.onTap == null || !widget.isEnabled) _hasFocus = false;
  }

  @override
  Widget build(BuildContext context) {
    final onTap = widget.onTap;
    if (!widget.isEnabled) {
      return Opacity(
        opacity: AppOpacity.disabled,
        child: onTap == null
            ? widget.child
            : Semantics(
                container: true,
                button: true,
                enabled: false,
                child: widget.child,
              ),
      );
    }
    if (onTap == null) return widget.child;
    return Semantics(
      container: true,
      button: true,
      child: InkWell(
        onTap: onTap,
        onFocusChange: (hasFocus) => setState(() => _hasFocus = hasFocus),
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            border: _hasFocus
                ? Border.all(
                    color: context.colors.primary,
                    width: AppStroke.focus,
                  )
                : null,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
```

`lib/shared/widgets/mx_list_row.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_row_ink.dart';

/// A content row: decks, search results, tags, move targets and cards. The
/// title and the sub are one line each with an ellipsis, so every row in a
/// list is one height. It is not a SettingsRow: this is a piece of content.
class MxListRow extends StatelessWidget {
  const MxListRow({
    super.key,
    required this.title,
    this.subtitle,
    this.meta,
    this.leading,
    this.trailing,
    this.hasChevron = false,
    this.onTap,
    this.isEnabled = true,
    this.isBusy = false,
    this.hasDivider = true,
  }) : assert(subtitle == null || meta == null, 'a subtitle or meta'),
       assert(trailing == null || !hasChevron, 'a trailing or the chevron');

  final String title;

  /// The one-line metadata. For a disabled move target, it is the reason
  /// the row cannot take the payload.
  final String? subtitle;

  /// A widget in the sub-line position (MxWorkloadBreakdownLine, tag chips).
  /// The row keeps the 2 gap above it (ruling S12).
  final Widget? meta;

  /// Usually an MxIconTile at the small step; any widget may replace it.
  final Widget? leading;

  /// An overflow button or another control. It keeps its own tap and node.
  final Widget? trailing;

  /// The navigation affordance.
  final bool hasChevron;
  final VoidCallback? onTap;
  final bool isEnabled;

  /// A spinner takes the trailing slot while the row's action runs.
  final bool isBusy;

  /// The ghost rule under the row. The caller turns it off on the last row
  /// and inside an MxSection, which draws its own.
  final bool hasDivider;

  static const double _subtitleGap = 2;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final styles = context.textStyles;
    final end = switch ((isBusy, hasChevron)) {
      (true, _) => SizedBox.square(
        dimension: AppIconSize.inline,
        child: CircularProgressIndicator(
          strokeWidth: AppStroke.indicator,
          color: colors.primary,
        ),
      ),
      (false, true) => Icon(
        AppIcons.chevronRight,
        size: AppIconSize.compact,
        color: colors.onSurfaceVariant,
      ),
      (false, false) => trailing,
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        border: hasDivider
            ? Border(
                bottom: BorderSide(
                  color: context.derivedColors.ghostBorder,
                  width: AppStroke.hairline,
                ),
              )
            : null,
      ),
      child: MxRowInk(
        onTap: onTap,
        isEnabled: isEnabled,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSize.listRowMin),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.gutter,
              vertical: AppSpacing.grouped,
            ),
            child: Row(
              spacing: AppSpacing.grouped,
              children: [
                ?leading,
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                        style: styles.listRowTitle,
                      ),
                      if (subtitle case final text?) ...[
                        const SizedBox(height: _subtitleGap),
                        Text(
                          text,
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                          style: styles.rowSubtitle,
                        ),
                      ],
                      if (meta case final slot?) ...[
                        const SizedBox(height: _subtitleGap),
                        slot,
                      ],
                    ],
                  ),
                ),
                ?end,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run them to verify they pass**

Run: `flutter test test/shared/widgets/mx_row_ink_test.dart test/shared/widgets/mx_list_row_test.dart`
Expected: PASS, 3 + 6 tests.

The merged row label is expected to read `'Kanji N5\n42 cards'`. If Flutter joins the merged labels differently, assert the label it actually produces: it must contain both lines and no trailing-button text. Record that as a test-only ruling.

- [ ] **Step 5: Golden, gate, commit**

Run the same commands as Task 2 Step 5 for `surface_widgets_golden_test.dart`. Commit message: `feat(ui): MxRowInk, MxListRow`.

Check the golden:
- The rows are one height.
- The long name is cut with an ellipsis.
- The busy row shows a spinner in place of the trailing control.
- The disabled row is dimmed, and the last row has no rule.

---

### Task 4: MxSettingsRow and MxActionSheetCommandRow

**Files:**
- Create: `lib/shared/widgets/mx_settings_row.dart`, `lib/shared/widgets/mx_action_sheet_command_row.dart`
- Modify: `test/shared/widgets/surface_widgets_golden_test.dart`
- Test: `test/shared/widgets/mx_settings_row_test.dart`, `test/shared/widgets/mx_action_sheet_command_row_test.dart`

**Interfaces:**
- Consumes: `MxRowInk`, `MxIconTile(size: MxIconTileSize.medium)`, `settingsLabel`, `rowDescription`, `commandLabel`, `rowSubtitle`, `derivedColors.dangerSoft`, `MxToggle(isOn:, onChanged:, semanticLabel:)`.
- Produces:
  - `MxSettingsRow({required String label, String? subtitle, IconData? icon, Widget? trailing, Widget? wideControl, VoidCallback? onTap, bool isEnabled = true})`
  - `MxActionSheetCommandRow({required IconData icon, required String label, required VoidCallback onTap, String? subtitle, bool isDestructive = false, bool hasChevron = false})`

- [ ] **Step 1: Write the failing tests**

`test/shared/widgets/mx_settings_row_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';
import 'package:memox/shared/widgets/mx_settings_row.dart';
import 'package:memox/shared/widgets/mx_toggle.dart';

import '../../support/widget_harness.dart';

const _controlKey = ValueKey('wide-control');

Widget _width(Widget child) => SizedBox(width: 360, child: child);

MxToggle _toggle() =>
    MxToggle(isOn: true, onChanged: (_) {}, semanticLabel: 'Daily reminder');

void main() {
  testWidgets('a 36 tile centred in the 40 column; label 16; sub 4 below', (
    tester,
  ) async {
    await pumpMx(
      tester,
      _width(
        const MxSettingsRow(
          label: 'Daily reminder',
          subtitle: 'One nudge a day',
          icon: AppIcons.reminder,
        ),
      ),
    );
    final row = tester.getTopLeft(find.byType(MxSettingsRow));

    expect(tester.getSize(find.byType(MxIconTile)), const Size.square(36));
    expect(tester.getTopLeft(find.byType(MxIconTile)).dx - row.dx, 18);
    expect(tester.getTopLeft(find.text('Daily reminder')).dx - row.dx, 72);
    expect(
      tester.widget<Text>(find.text('Daily reminder')).style!.fontSize,
      16,
    );
    expect(
      tester.getTopLeft(find.text('One nudge a day')).dy -
          tester.getBottomLeft(find.text('Daily reminder')).dy,
      4,
    );
    expect(
      tester.getSize(find.byType(MxSettingsRow)).height,
      greaterThanOrEqualTo(48),
    );
  });

  testWidgets('the chevron shows only on a row that navigates', (
    tester,
  ) async {
    await pumpMx(
      tester,
      _width(MxSettingsRow(label: 'Language', onTap: () {})),
    );
    expect(find.byIcon(AppIcons.chevronRight), findsOneWidget);

    await pumpMx(
      tester,
      _width(
        MxSettingsRow(label: 'Daily reminder', trailing: _toggle()),
      ),
    );
    expect(find.byIcon(AppIcons.chevronRight), findsNothing);

    await pumpMx(tester, _width(const MxSettingsRow(label: 'Version')));
    expect(find.byIcon(AppIcons.chevronRight), findsNothing);
    expect(find.byType(InkWell), findsNothing);
  });

  testWidgets('a long label wraps; the trailing control keeps its size', (
    tester,
  ) async {
    await pumpMx(
      tester,
      _width(MxSettingsRow(label: 'Reminder', trailing: _toggle())),
    );
    final toggle = tester.getSize(find.byType(MxToggle));
    final oneLine = tester.getSize(find.text('Reminder')).height;

    final long = List.filled(8, 'Nhắc học hằng ngày').join(' ');
    await pumpMx(
      tester,
      _width(MxSettingsRow(label: long, trailing: _toggle())),
      textScale: 2,
    );

    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(MxToggle)), toggle);
    expect(tester.getSize(find.text(long)).height, greaterThan(oneLine * 2));
  });

  testWidgets('a wide control drops onto its own line, 12 below', (
    tester,
  ) async {
    await pumpMx(
      tester,
      _width(
        const MxSettingsRow(
          label: 'Cards per session',
          icon: AppIcons.library,
          wideControl: SizedBox(key: _controlKey, width: 120, height: 36),
        ),
      ),
    );

    expect(
      tester.getTopLeft(find.byKey(_controlKey)).dy -
          tester.getBottomLeft(find.text('Cards per session')).dy,
      12,
    );
    expect(
      tester.getTopLeft(find.byKey(_controlKey)).dx,
      tester.getTopLeft(find.text('Cards per session')).dx,
    );
  });

  testWidgets('dimmed at 0.38 while unavailable', (tester) async {
    var taps = 0;
    await pumpMx(
      tester,
      _width(
        MxSettingsRow(
          label: 'Language',
          isEnabled: false,
          onTap: () => taps++,
        ),
      ),
    );
    await tester.tap(find.text('Language'), warnIfMissed: false);

    expect(taps, 0);
    expect(
      tester
          .widget<Opacity>(
            find.ancestor(
              of: find.text('Language'),
              matching: find.byType(Opacity),
            ),
          )
          .opacity,
      0.38,
    );
  });
}
```

`test/shared/widgets/mx_action_sheet_command_row_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/mx_derived_colors.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
import 'package:memox/shared/widgets/mx_action_sheet_command_row.dart';

import '../../support/widget_harness.dart';

const _tileKey = ValueKey('mx-command-tile');

Widget _width(Widget child) => SizedBox(width: 344, child: child);

BoxDecoration _tile(WidgetTester tester) =>
    tester.widget<DecoratedBox>(find.byKey(_tileKey)).decoration
        as BoxDecoration;

void main() {
  final scheme = AppColorSchemes.light;

  testWidgets('a 30 tile at primary 8%, 16 glyph, 14/600 verb; 48 target', (
    tester,
  ) async {
    await pumpMx(
      tester,
      _width(
        MxActionSheetCommandRow(
          icon: AppIcons.edit,
          label: 'Rename',
          subtitle: 'Change the deck name',
          onTap: () {},
        ),
      ),
    );
    final row = tester.getTopLeft(find.byType(MxActionSheetCommandRow));

    expect(tester.getSize(find.byKey(_tileKey)), const Size.square(30));
    expect(tester.getTopLeft(find.byKey(_tileKey)).dx - row.dx, 9);
    expect(_tile(tester).color, scheme.primary.withValues(alpha: 0.08));
    expect(_tile(tester).borderRadius, BorderRadius.circular(8));
    final glyph = tester.widget<Icon>(find.byIcon(AppIcons.edit));
    expect((glyph.size, glyph.color), (16, scheme.primary));
    expect(tester.widget<Text>(find.text('Rename')).style!.fontSize, 14);
    expect(tester.getTopLeft(find.text('Rename')).dx - row.dx, 52);
    await expectAccessibleTargets(tester);
  });

  testWidgets('destructive: danger-soft tile, error glyph and verb', (
    tester,
  ) async {
    final derived = MxDerivedColors.resolve(scheme, MxSemanticColors.light);
    await pumpMx(
      tester,
      _width(
        MxActionSheetCommandRow(
          icon: AppIcons.delete,
          label: 'Delete',
          isDestructive: true,
          onTap: () {},
        ),
      ),
    );

    expect(_tile(tester).color, derived.dangerSoft);
    expect(
      tester.widget<Icon>(find.byIcon(AppIcons.delete)).color,
      scheme.error,
    );
    expect(tester.widget<Text>(find.text('Delete')).style!.color, scheme.error);
  });

  testWidgets('chevron only when it opens a surface; one tap, one call', (
    tester,
  ) async {
    var taps = 0;
    await pumpMx(
      tester,
      _width(
        MxActionSheetCommandRow(
          icon: AppIcons.folder,
          label: 'Move',
          hasChevron: true,
          onTap: () => taps++,
        ),
      ),
    );
    expect(find.byIcon(AppIcons.chevronRight), findsOneWidget);
    await tester.tap(find.text('Move'));
    expect(taps, 1);

    await pumpMx(
      tester,
      _width(
        MxActionSheetCommandRow(
          icon: AppIcons.folder,
          label: 'Move',
          onTap: () {},
        ),
      ),
    );
    expect(find.byIcon(AppIcons.chevronRight), findsNothing);
  });

  testWidgets('announced as one button', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpMx(
      tester,
      _width(
        MxActionSheetCommandRow(
          icon: AppIcons.edit,
          label: 'Rename',
          subtitle: 'Change the deck name',
          onTap: () {},
        ),
      ),
    );

    expect(
      tester.getSemantics(find.text('Rename')),
      isSemantics(label: 'Rename\nChange the deck name', isButton: true),
    );
    handle.dispose();
  });
}
```

Before the closing `}` of `surface_widgets_golden_test.dart`, append the test below. Add imports for `mx_settings_row.dart`, `mx_action_sheet_command_row.dart`, `mx_toggle.dart` and `mx_stepper.dart`.

```dart
  testWidgets('MxSettingsRow and MxActionSheetCommandRow', (tester) async {
    await expectThemedGoldens(
      tester,
      'mx_settings_command_rows',
      Column(
        spacing: 16,
        children: [
          MxCard(
            isFullBleed: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MxSettingsRow(
                  label: 'Daily reminder',
                  subtitle: 'One nudge at the time you choose',
                  icon: AppIcons.reminder,
                  trailing: MxToggle(
                    isOn: true,
                    onChanged: (_) {},
                    semanticLabel: 'Daily reminder',
                  ),
                ),
                MxSettingsRow(
                  label: 'Language',
                  icon: AppIcons.library,
                  onTap: () {},
                ),
                MxSettingsRow(
                  label: 'Cards per session',
                  icon: AppIcons.library,
                  wideControl: MxStepper(
                    value: 20,
                    decrementLabel: 'Fewer',
                    incrementLabel: 'More',
                    onDecrement: () {},
                    onIncrement: () {},
                  ),
                ),
                const MxSettingsRow(
                  label: 'Unavailable while notifications are off',
                  icon: AppIcons.reminder,
                  isEnabled: false,
                ),
              ],
            ),
          ),
          MxCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MxActionSheetCommandRow(
                  icon: AppIcons.edit,
                  label: 'Rename',
                  subtitle: 'Change the deck name',
                  onTap: () {},
                ),
                MxActionSheetCommandRow(
                  icon: AppIcons.folder,
                  label: 'Move',
                  hasChevron: true,
                  onTap: () {},
                ),
                MxActionSheetCommandRow(
                  icon: AppIcons.delete,
                  label: 'Delete',
                  subtitle: 'Recoverable for 30 days',
                  isDestructive: true,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  });
```

- [ ] **Step 2: Run them to verify they fail**

Run: `flutter test test/shared/widgets/mx_settings_row_test.dart test/shared/widgets/mx_action_sheet_command_row_test.dart`
Expected: FAIL to compile, because the widget files do not exist.

- [ ] **Step 3: Implement**

`lib/shared/widgets/mx_settings_row.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';
import 'package:memox/shared/widgets/mx_row_ink.dart';

/// A setting: a bigger label, a roomier lead column, and a trailing slot for
/// a control. The chevron shows only when the row navigates and holds no
/// control, so a row with a toggle never implies a destination. Inside an
/// MxSection, the section draws the dividers.
class MxSettingsRow extends StatelessWidget {
  const MxSettingsRow({
    super.key,
    required this.label,
    this.subtitle,
    this.icon,
    this.trailing,
    this.wideControl,
    this.onTap,
    this.isEnabled = true,
  }) : assert(trailing == null || wideControl == null, 'one control slot');

  final String label;
  final String? subtitle;

  /// Drawn as an MxIconTile at the medium step, centred in the 40 lead column.
  final IconData? icon;

  /// A toggle, a time button or a value.
  final Widget? trailing;

  /// A stepper or a segmented tray, on its own line under the label. It
  /// keeps its own width (ruling S17).
  final Widget? wideControl;

  /// Navigates. The row then shows the chevron, unless it holds a control.
  final VoidCallback? onTap;

  /// False dims the row while the setting is unavailable.
  final bool isEnabled;

  static const double _leadColumn = 40;
  static const double _subtitleGap = 4;

  @override
  Widget build(BuildContext context) {
    final styles = context.textStyles;
    final isNavigable =
        onTap != null && trailing == null && wideControl == null;
    return MxRowInk(
      onTap: onTap,
      isEnabled: isEnabled,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSize.listRowMin),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.gutter,
            vertical: AppSpacing.grouped,
          ),
          child: Row(
            spacing: AppSpacing.gutter,
            children: [
              if (icon case final glyph?)
                SizedBox(
                  width: _leadColumn,
                  child: Center(
                    heightFactor: 1,
                    child: MxIconTile(
                      icon: glyph,
                      size: MxIconTileSize.medium,
                    ),
                  ),
                ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: styles.settingsLabel),
                    if (subtitle case final text?) ...[
                      const SizedBox(height: _subtitleGap),
                      Text(text, style: styles.rowDescription),
                    ],
                    if (wideControl case final control?) ...[
                      const SizedBox(height: AppSpacing.grouped),
                      control,
                    ],
                  ],
                ),
              ),
              ?trailing,
              if (isNavigable)
                Icon(
                  AppIcons.chevronRight,
                  size: AppIconSize.compact,
                  color: context.colors.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
```

`lib/shared/widgets/mx_action_sheet_command_row.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_row_ink.dart';

/// One command in a bottom-sheet action list: a 30 tile in a 32 lead column
/// and a 14/600 verb. It is neither a SettingsRow nor a ListRow. The sheet
/// supplies the outer gutter.
class MxActionSheetCommandRow extends StatelessWidget {
  const MxActionSheetCommandRow({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.isDestructive = false,
    this.hasChevron = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? subtitle;

  /// The error tile, glyph and verb: named in colour and in words.
  final bool isDestructive;

  /// The command opens a further surface.
  final bool hasChevron;

  static const double _leadColumn = 32;
  static const double _tileSize = 30;
  static const double _tileTint = 0.08;

  /// Ruling S7: UNSPECIFIED; the ListRow gap.
  static const double _subtitleGap = 2;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final styles = context.textStyles;
    final ink = isDestructive ? colors.error : colors.primary;
    return MxRowInk(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSize.touchTarget),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.control,
            vertical: AppSpacing.grouped,
          ),
          child: Row(
            spacing: AppSpacing.grouped,
            children: [
              SizedBox(
                width: _leadColumn,
                child: Center(
                  heightFactor: 1,
                  child: SizedBox.square(
                    dimension: _tileSize,
                    child: DecoratedBox(
                      key: const ValueKey('mx-command-tile'),
                      decoration: BoxDecoration(
                        color: isDestructive
                            ? context.derivedColors.dangerSoft
                            : colors.primary.withValues(alpha: _tileTint),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      // Ruling S7: the glyph size is UNSPECIFIED; the small
                      // IconTile step.
                      child: Center(
                        child: Icon(
                          icon,
                          size: AppIconSize.inline,
                          color: ink,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: styles.commandLabel(isDestructive: isDestructive),
                    ),
                    if (subtitle case final text?) ...[
                      const SizedBox(height: _subtitleGap),
                      Text(
                        text,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                        style: styles.rowSubtitle,
                      ),
                    ],
                  ],
                ),
              ),
              if (hasChevron)
                Icon(
                  AppIcons.chevronRight,
                  size: AppIconSize.compact,
                  color: colors.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run them to verify they pass**

Run: `flutter test test/shared/widgets/mx_settings_row_test.dart test/shared/widgets/mx_action_sheet_command_row_test.dart`
Expected: PASS, 5 + 4 tests.

- [ ] **Step 5: Golden, gate, commit**

Run the same commands as Task 2 Step 5. Commit message: `feat(ui): MxSettingsRow, MxActionSheetCommandRow`.

Check the golden:
- The toggle row has no chevron.
- Language has a chevron.
- The stepper sits on its own line under "Cards per session".
- The disabled row is dimmed.
- The command tiles are small tinted squares, and Delete is red in its tile, glyph and verb.

---

### Task 5: MxNote, MxListSectionHeader, MxSection and the EmptyState footnote

**Files:**
- Create: `lib/shared/widgets/mx_note.dart`, `lib/shared/widgets/mx_list_section_header.dart`, `lib/shared/widgets/mx_section.dart`
- Modify: `lib/shared/widgets/mx_empty_state.dart`, `test/shared/widgets/mx_empty_state_test.dart`, `test/shared/widgets/surface_widgets_golden_test.dart`
- Test: `test/shared/widgets/mx_note_test.dart`, `test/shared/widgets/mx_list_section_header_test.dart`, `test/shared/widgets/mx_section_test.dart`

**Interfaces:**
- Consumes: `MxCard(isFullBleed: true)`, `noteText`, `overline`, `AppIcons.info`, `derivedColors.ghostBorder`.
- Produces:
  - `MxNote({required String text, IconData icon = AppIcons.info})`
  - `MxListSectionHeader({required String label, Widget? trailing, bool isAfterFilterBand = false})`
  - `MxSection({String? title, required List<Widget> children, String? note})`
  - `MxEmptyState(..., String? footnote)`

- [ ] **Step 1: Write the failing tests**

`test/shared/widgets/mx_note_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/mx_derived_colors.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
import 'package:memox/shared/widgets/mx_note.dart';

import '../../support/widget_harness.dart';

const _rule = 'Changes apply to future sessions.';

void main() {
  final scheme = AppColorSchemes.light;

  testWidgets('muted fill, ghost hairline, radius 12, padding 10 12', (
    tester,
  ) async {
    final derived = MxDerivedColors.resolve(scheme, MxSemanticColors.light);
    await pumpMx(tester, const SizedBox(width: 328, child: MxNote(text: _rule)));
    final box =
        tester
                .widget<DecoratedBox>(
                  find.descendant(
                    of: find.byType(MxNote),
                    matching: find.byType(DecoratedBox),
                  ),
                )
                .decoration
            as BoxDecoration;
    final note = tester.getTopLeft(find.byType(MxNote));

    expect(box.color, scheme.surfaceContainerLow);
    expect(box.border, Border.all(color: derived.ghostBorder));
    expect(box.borderRadius, BorderRadius.circular(12));
    expect(tester.getTopLeft(find.byType(Icon)).dx - note.dx, 13);
    expect(tester.getTopLeft(find.text(_rule)) - note, const Offset(37, 11));
    expect(tester.widget<Icon>(find.byType(Icon)).size, 16);
    expect(
      tester.widget<Text>(find.text(_rule)).style!.color,
      scheme.onSurfaceVariant,
    );
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets('the glyph centres on the first line at ${scale}x', (
      tester,
    ) async {
      final long = List.filled(12, _rule).join(' ');
      await pumpMx(
        tester,
        SizedBox(width: 328, child: MxNote(text: long)),
        textScale: scale,
      );
      final firstLine = 12 * scale * 1.5;

      expect(
        tester.getCenter(find.byType(Icon)).dy,
        tester.getTopLeft(find.text(long)).dy + firstLine / 2,
      );
    });
  }
}
```

`test/shared/widgets/mx_list_section_header_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/shared/widgets/mx_list_section_header.dart';

import '../../support/widget_harness.dart';

const _countKey = ValueKey('count');

Widget _width(Widget child) => SizedBox(width: 360, child: child);

void main() {
  testWidgets('an uppercase 12/700 overline that reads the original label', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpMx(tester, _width(const MxListSectionHeader(label: 'Hôm nay')));
    final text = tester.widget<Text>(find.text('HÔM NAY'));

    expect(text.style!.fontSize, 12);
    expect(text.style!.fontWeight, FontWeight.w700);
    expect(
      tester.getSemantics(find.text('HÔM NAY')),
      isSemantics(label: 'Hôm nay'),
    );
    handle.dispose();
  });

  testWidgets('padding 0 4 8, or 2 4 8 after a filter band', (tester) async {
    await pumpMx(tester, _width(const MxListSectionHeader(label: 'Decks')));
    final header = tester.getTopLeft(find.byType(MxListSectionHeader));
    final label = tester.getRect(find.text('DECKS'));
    expect(label.topLeft - header, const Offset(4, 0));
    expect(
      tester.getSize(find.byType(MxListSectionHeader)).height,
      label.height + 8,
    );

    await pumpMx(
      tester,
      _width(
        const MxListSectionHeader(label: 'Decks', isAfterFilterBand: true),
      ),
    );
    expect(
      tester.getTopLeft(find.text('DECKS')) -
          tester.getTopLeft(find.byType(MxListSectionHeader)),
      const Offset(4, 2),
    );
  });

  testWidgets('the trailing affordance sits 8 after the label, 4 inset', (
    tester,
  ) async {
    await pumpMx(
      tester,
      _width(
        MxListSectionHeader(
          label: 'Decks',
          trailing: Text(12.toString(), key: _countKey),
        ),
      ),
    );

    expect(
      tester.getTopLeft(find.byKey(_countKey)).dx -
          tester.getTopRight(find.text('DECKS')).dx,
      8,
    );
    expect(tester.getTopRight(find.byKey(_countKey)).dx, 356);
  });
}
```

`test/shared/widgets/mx_section_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/mx_derived_colors.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_list_section_header.dart';
import 'package:memox/shared/widgets/mx_note.dart';
import 'package:memox/shared/widgets/mx_section.dart';

import '../../support/widget_harness.dart';

List<Widget> _rows(int count) => [
  for (var i = 0; i < count; i++)
    SizedBox(key: ValueKey('row-$i'), height: 48),
];

Widget _width(Widget child) => SizedBox(width: 360, child: child);

void main() {
  testWidgets('an overline over a full-bleed card, and 16 below', (
    tester,
  ) async {
    await pumpMx(
      tester,
      _width(MxSection(title: 'Reminders', children: _rows(1))),
    );

    expect(find.byType(MxListSectionHeader), findsOneWidget);
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('row-0'))),
      tester.getTopLeft(find.byType(MxCard)),
    );
    expect(
      tester.getBottomLeft(find.byType(MxSection)).dy -
          tester.getBottomLeft(find.byType(MxCard)).dy,
      16,
    );
  });

  testWidgets('untitled: the card only, still 16 below', (tester) async {
    await pumpMx(tester, _width(MxSection(children: _rows(1))));

    expect(find.byType(MxListSectionHeader), findsNothing);
    expect(
      tester.getTopLeft(find.byType(MxCard)),
      tester.getTopLeft(find.byType(MxSection)),
    );
    expect(
      tester.getBottomLeft(find.byType(MxSection)).dy -
          tester.getBottomLeft(find.byType(MxCard)).dy,
      16,
    );
  });

  testWidgets('ghost dividers between rows, none after the last', (
    tester,
  ) async {
    final ghost = MxDerivedColors.resolve(
      AppColorSchemes.light,
      MxSemanticColors.light,
    ).ghostBorder;
    await pumpMx(tester, _width(MxSection(children: _rows(3))));
    final dividers = tester
        .widgetList<ColoredBox>(
          find.descendant(
            of: find.byType(MxCard),
            matching: find.byType(ColoredBox),
          ),
        )
        .where((box) => box.color == ghost);

    expect(dividers, hasLength(2));
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('row-1'))).dy -
          tester.getBottomLeft(find.byKey(const ValueKey('row-0'))).dy,
      1,
    );
  });

  testWidgets('a note sits 8 below the card, inset 4', (tester) async {
    await pumpMx(
      tester,
      _width(
        MxSection(
          note: 'Changes apply to future sessions.',
          children: _rows(1),
        ),
      ),
    );

    expect(
      tester.getTopLeft(find.byType(MxNote)) -
          tester.getBottomLeft(find.byType(MxCard)),
      const Offset(4, 8),
    );
  });
}
```

Append to `test/shared/widgets/mx_empty_state_test.dart`, inside `main`. Add any of these imports that are missing: `mx_note.dart`, `mx_button.dart`, `app_icons.dart`.

```dart
  testWidgets('a footnote sits 20 below the action as a note', (tester) async {
    await pumpMx(
      tester,
      MxEmptyState(
        icon: AppIcons.inbox,
        title: 'Trash is empty',
        actionLabel: 'Back to library',
        onAction: () {},
        footnote: 'Deleted items stay here for 30 days.',
      ),
    );

    expect(
      tester.getTopLeft(find.byType(MxNote)).dy -
          tester.getBottomLeft(find.byType(MxButton)).dy,
      20,
    );
  });
```

Before the closing `}` of `surface_widgets_golden_test.dart`, append the test below. Add imports for `mx_section.dart`, `mx_list_section_header.dart`, `mx_note.dart` and `mx_chip_trigger.dart`.

```dart
  testWidgets('MxSection, MxListSectionHeader and MxNote', (tester) async {
    await expectThemedGoldens(
      tester,
      'mx_section_header_note',
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MxListSectionHeader(
            label: 'Decks',
            trailing: MxChipTrigger(
              label: 'Sort: Due',
              icon: AppIcons.sort,
              onPressed: () {},
            ),
          ),
          MxSection(
            title: 'Reminders',
            note: 'Changes apply to future sessions.',
            children: [
              MxSettingsRow(
                label: 'Daily reminder',
                icon: AppIcons.reminder,
                trailing: MxToggle(
                  isOn: true,
                  onChanged: (_) {},
                  semanticLabel: 'Daily reminder',
                ),
              ),
              MxSettingsRow(
                label: 'Reminder time',
                icon: AppIcons.reminder,
                onTap: () {},
              ),
            ],
          ),
          const MxSection(
            children: [
              MxSettingsRow(label: 'Untitled group', icon: AppIcons.library),
            ],
          ),
          const MxNote(
            text:
                'Deleted decks stay recoverable for 30 days, then they are '
                'removed for good together with their cards.',
          ),
        ],
      ),
    );
  });
```

- [ ] **Step 2: Run them to verify they fail**

Run: `flutter test test/shared/widgets/mx_note_test.dart test/shared/widgets/mx_list_section_header_test.dart test/shared/widgets/mx_section_test.dart test/shared/widgets/mx_empty_state_test.dart`
Expected: FAIL to compile, because the new widget files and `footnote` do not exist.

- [ ] **Step 3: Implement**

`lib/shared/widgets/mx_note.dart`:

```dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/theme_context.dart';

/// One calm line stating a product rule. Info tone only: never a warning,
/// never an action.
class MxNote extends StatelessWidget {
  const MxNote({super.key, required this.text, this.icon = AppIcons.info});

  final String text;

  /// The info glyph, or a clock or shield where the rule is about time or
  /// safety.
  final IconData icon;

  static const double _verticalPadding = 10;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final style = context.textStyles.noteText;
    // The glyph centres on the first line at any text scale.
    final firstLine =
        MediaQuery.textScalerOf(context).scale(style.fontSize!) *
        style.height!;
    final glyphInset = math.max(0.0, (firstLine - AppIconSize.inline) / 2);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: context.derivedColors.ghostBorder,
          width: AppStroke.hairline,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.grouped,
          vertical: _verticalPadding,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.control,
          children: [
            Padding(
              padding: EdgeInsets.only(top: glyphInset),
              child: Icon(
                icon,
                size: AppIconSize.inline,
                color: colors.onSurfaceVariant,
              ),
            ),
            Expanded(child: Text(text, style: style)),
          ],
        ),
      ),
    );
  }
}
```

The test offsets include the 1px border. The note's origin is at 0: the glyph is at 1 + 12 = 13, and the text is at (13 + 16 + 8, 1 + 10) = (37, 11).

`lib/shared/widgets/mx_list_section_header.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';

/// The overline that introduces a list, with one optional trailing
/// affordance (a ChipTrigger, a Badge, a Button or a plain count). The
/// trailing widget owns its own colours.
class MxListSectionHeader extends StatelessWidget {
  const MxListSectionHeader({
    super.key,
    required this.label,
    this.trailing,
    this.isAfterFilterBand = false,
  });

  final String label;
  final Widget? trailing;

  /// 2 above instead of 0, where the header follows a filter band.
  final bool isAfterFilterBand;

  static const double _afterFilterBandTop = 2;
  static const _padding = EdgeInsetsDirectional.only(
    start: AppSpacing.micro,
    end: AppSpacing.micro,
    bottom: AppSpacing.control,
  );
  static const _afterFilterBandPadding = EdgeInsetsDirectional.fromSTEB(
    AppSpacing.micro,
    _afterFilterBandTop,
    AppSpacing.micro,
    AppSpacing.control,
  );

  @override
  Widget build(BuildContext context) => Padding(
    padding: isAfterFilterBand ? _afterFilterBandPadding : _padding,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      spacing: AppSpacing.control,
      children: [
        Expanded(
          child: Text(
            label.toUpperCase(),
            semanticsLabel: label,
            style: context.textStyles.overline,
          ),
        ),
        ?trailing,
      ],
    ),
  );
}
```

`lib/shared/widgets/mx_section.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_list_section_header.dart';
import 'package:memox/shared/widgets/mx_note.dart';

/// The structural unit of Settings and Reminder: an overline, a card that
/// holds a group of rows, and an optional note under it. It keeps its own 16
/// below the block (ruling S9).
class MxSection extends StatelessWidget {
  const MxSection({super.key, this.title, required this.children, this.note});

  final String? title;

  /// The rows. The section draws the ghost dividers between them (ruling
  /// S8), so a row here carries none of its own.
  final List<Widget> children;

  /// A product rule under the card, drawn as an MxNote.
  final String? note;

  @override
  Widget build(BuildContext context) {
    final divider = SizedBox(
      height: AppStroke.hairline,
      child: ColoredBox(color: context.derivedColors.ghostBorder),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.gutter),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title case final text?) MxListSectionHeader(label: text),
          MxCard(
            isFullBleed: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (index, row) in children.indexed) ...[
                  if (index > 0) divider,
                  row,
                ],
              ],
            ),
          ),
          if (note case final text?)
            Padding(
              padding: const EdgeInsetsDirectional.only(
                start: AppSpacing.micro,
                end: AppSpacing.micro,
                top: AppSpacing.control,
              ),
              child: MxNote(text: text),
            ),
        ],
      ),
    );
  }
}
```

In `lib/shared/widgets/mx_empty_state.dart`:
- Add `this.footnote,` to the constructor after `this.onAction,`.
- Add the field after `onAction`:

```dart
  /// A product rule under the action, drawn as an MxNote (ruling S19).
  final String? footnote;
```

- Add `import 'package:memox/shared/widgets/mx_note.dart';`.
- Append after the action block, inside the `Column` children:

```dart
              if (footnote case final rule?) ...[
                const SizedBox(height: AppSpacing.card),
                MxNote(text: rule),
              ],
```

- [ ] **Step 4: Run them to verify they pass**

Run: `flutter test test/shared/widgets/mx_note_test.dart test/shared/widgets/mx_list_section_header_test.dart test/shared/widgets/mx_section_test.dart test/shared/widgets/mx_empty_state_test.dart`
Expected: PASS.

- [ ] **Step 5: Golden, gate, commit**

Run the same commands as Task 2 Step 5. Also run `flutter test --tags golden test/shared/widgets/shared_widgets_golden_test.dart`: the EmptyState goldens must not change. Commit message: `feat(ui): MxNote, MxListSectionHeader, MxSection; EmptyState footnote`.

Check the golden:
- The overlines are uppercase and muted.
- Section rows meet the card's corners, with hairlines between them.
- The note sits under the Reminders card.
- The untitled section has no overline.
- The long note wraps, with the glyph on its first line.

---

### Task 6: MxBadge, MxStatusBadge and MxTagChip

**Files:**
- Create: `lib/shared/widgets/mx_badge.dart`, `lib/shared/widgets/mx_status_badge.dart`, `lib/shared/widgets/mx_tag_chip.dart`, `test/shared/widgets/status_widgets_golden_test.dart`
- Test: `test/shared/widgets/mx_badge_test.dart`, `test/shared/widgets/mx_status_badge_test.dart`, `test/shared/widgets/mx_tag_chip_test.dart`

**Interfaces:**
- Consumes: `badgeLabel(Color)`, `tagLabel`, `semanticColors.{mastery,warning,statusNew,statusLearning,statusReviewing,statusMastered}`, `derivedColors.warningInk`.
- Produces:
  - `enum MxBadgeTone { primary, mastery, warning, danger, neutral }`
  - `MxBadge({required String label, MxBadgeTone tone = MxBadgeTone.primary, bool isSolid = false, IconData? icon})`
  - `enum MxCardStatus { newCard, learning, reviewing, mastered }`
  - `MxStatusBadge({required MxCardStatus status, required String label, bool isDot = false})`
  - `MxTagChip({required String label, bool isDense = false})`

- [ ] **Step 1: Write the failing tests**

`test/shared/widgets/mx_badge_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/mx_derived_colors.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
import 'package:memox/shared/widgets/mx_badge.dart';

import '../../support/widget_harness.dart';

BoxDecoration _pill(WidgetTester tester) =>
    tester
            .widget<DecoratedBox>(
              find.descendant(
                of: find.byType(MxBadge),
                matching: find.byType(DecoratedBox),
              ),
            )
            .decoration
        as BoxDecoration;

Color? _ink(WidgetTester tester, String label) =>
    tester.widget<Text>(find.text(label)).style!.color;

void main() {
  final scheme = AppColorSchemes.light;
  final semantic = MxSemanticColors.light;
  final derived = MxDerivedColors.resolve(scheme, semantic);

  testWidgets('tonal: tone @12% under a tone label; a 22 pill, 8 inset', (
    tester,
  ) async {
    await pumpMx(tester, const MxBadge(label: '23 due'));

    expect(_pill(tester).color, scheme.primary.withValues(alpha: 0.12));
    expect(_pill(tester).borderRadius, BorderRadius.circular(999));
    expect(_ink(tester, '23 due'), scheme.primary);
    expect(tester.getSize(find.byType(MxBadge)).height, 22);
    expect(
      tester.getTopLeft(find.text('23 due')).dx -
          tester.getTopLeft(find.byType(MxBadge)).dx,
      8,
    );
  });

  testWidgets('solid: tone fill under an onPrimary label', (tester) async {
    await pumpMx(tester, const MxBadge(label: '23 due', isSolid: true));

    expect(_pill(tester).color, scheme.primary);
    expect(_ink(tester, '23 due'), scheme.onPrimary);
  });

  testWidgets('each tone; a tonal warning reads in warning-ink (S3)', (
    tester,
  ) async {
    for (final (tone, fill, ink) in [
      (MxBadgeTone.mastery, semantic.mastery, semantic.mastery),
      (MxBadgeTone.danger, scheme.error, scheme.error),
      (
        MxBadgeTone.neutral,
        scheme.onSurfaceVariant,
        scheme.onSurfaceVariant,
      ),
      (MxBadgeTone.warning, semantic.warning, derived.warningInk),
    ]) {
      await pumpMx(tester, MxBadge(label: '4 due', tone: tone));

      expect(_pill(tester).color, fill.withValues(alpha: 0.12));
      expect(_ink(tester, '4 due'), ink);
    }
  });

  testWidgets('a 12 glyph 4 before the label; the pill grows, never clips', (
    tester,
  ) async {
    await pumpMx(
      tester,
      const MxBadge(label: '12 ready', icon: AppIcons.check),
    );
    final glyph = tester.getRect(find.byIcon(AppIcons.check));
    expect(glyph.size, const Size.square(12));
    expect(glyph.left - tester.getTopLeft(find.byType(MxBadge)).dx, 8);
    expect(tester.getTopLeft(find.text('12 ready')).dx - glyph.right, 4);

    await pumpMx(tester, const MxBadge(label: '1 due'));
    final short = tester.getSize(find.byType(MxBadge)).width;
    await pumpMx(tester, const MxBadge(label: '12345 due'), textScale: 2);
    expect(tester.getSize(find.byType(MxBadge)).width, greaterThan(short));
    expect(tester.getSize(find.byType(MxBadge)).height, greaterThan(22));
    expect(tester.takeException(), isNull);
  });
}
```

`test/shared/widgets/mx_status_badge_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
import 'package:memox/shared/widgets/mx_status_badge.dart';

import '../../support/widget_harness.dart';

const _dotKey = ValueKey('mx-status-dot');

Color? _fill(WidgetTester tester, Finder finder) =>
    (tester.widget<DecoratedBox>(finder).decoration as BoxDecoration).color;

void main() {
  final semantic = MxSemanticColors.light;

  testWidgets('the status fixes the dot, label and 12% fill', (tester) async {
    for (final (status, color) in [
      (MxCardStatus.newCard, semantic.statusNew),
      (MxCardStatus.learning, semantic.statusLearning),
      (MxCardStatus.reviewing, semantic.statusReviewing),
      (MxCardStatus.mastered, semantic.statusMastered),
    ]) {
      await pumpMx(tester, MxStatusBadge(status: status, label: 'State'));
      final pill = find
          .descendant(
            of: find.byType(MxStatusBadge),
            matching: find.byType(DecoratedBox),
          )
          .first;

      expect(_fill(tester, pill), color.withValues(alpha: 0.12));
      expect(_fill(tester, find.byKey(_dotKey)), color);
      expect(tester.widget<Text>(find.text('State')).style!.color, color);
    }
  });

  testWidgets('pill: 22 tall, 6 before the 6 dot, 4 gap, 8 after', (
    tester,
  ) async {
    await pumpMx(
      tester,
      const MxStatusBadge(status: MxCardStatus.learning, label: 'Learning'),
    );
    final badge = tester.getRect(find.byType(MxStatusBadge));
    final dot = tester.getRect(find.byKey(_dotKey));
    final label = tester.getRect(find.text('Learning'));

    expect(badge.height, 22);
    expect(dot.size, const Size.square(6));
    expect(dot.left - badge.left, 6);
    expect(label.left - dot.right, 4);
    expect(badge.right - label.right, 8);
  });

  testWidgets('dot only: an 8 circle announced by its label', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpMx(
      tester,
      const MxStatusBadge(
        status: MxCardStatus.mastered,
        label: 'Mastered',
        isDot: true,
      ),
    );

    expect(tester.getSize(find.byKey(_dotKey)), const Size.square(8));
    expect(find.text('Mastered'), findsNothing);
    expect(find.bySemanticsLabel('Mastered'), findsOneWidget);
    handle.dispose();
  });
}
```

`test/shared/widgets/mx_tag_chip_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/shared/widgets/mx_tag_chip.dart';

import '../../support/widget_harness.dart';

void main() {
  final scheme = AppColorSchemes.light;

  testWidgets('22 default, 18 dense; surfaceContainer, muted label', (
    tester,
  ) async {
    await pumpMx(tester, const MxTagChip(label: 'verbs'));
    final box =
        tester
                .widget<DecoratedBox>(
                  find.descendant(
                    of: find.byType(MxTagChip),
                    matching: find.byType(DecoratedBox),
                  ),
                )
                .decoration
            as BoxDecoration;

    expect(tester.getSize(find.byType(MxTagChip)).height, 22);
    expect(box.color, scheme.surfaceContainer);
    expect(box.borderRadius, BorderRadius.circular(999));
    expect(
      tester.widget<Text>(find.text('verbs')).style!.color,
      scheme.onSurfaceVariant,
    );
    expect(
      tester.getTopLeft(find.text('verbs')).dx -
          tester.getTopLeft(find.byType(MxTagChip)).dx,
      8,
    );

    await pumpMx(tester, const MxTagChip(label: 'verbs', isDense: true));
    expect(tester.getSize(find.byType(MxTagChip)).height, 18);
  });

  testWidgets('a long tag stops at 140 with an ellipsis', (tester) async {
    const long = 'a tag long enough to push the row past its width';
    await pumpMx(tester, const MxTagChip(label: long));

    expect(tester.getSize(find.byType(MxTagChip)).width, 140);
    expect(
      tester.widget<Text>(find.text(long)).overflow,
      TextOverflow.ellipsis,
    );

    await pumpMx(tester, const MxTagChip(label: 'N5'));
    expect(tester.getSize(find.byType(MxTagChip)).width, lessThan(140));
  });
}
```

`test/shared/widgets/status_widgets_golden_test.dart`:

```dart
@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/shared/widgets/mx_badge.dart';
import 'package:memox/shared/widgets/mx_status_badge.dart';
import 'package:memox/shared/widgets/mx_tag_chip.dart';

import '../../support/golden_harness.dart';

void main() {
  testWidgets('MxBadge, MxStatusBadge and MxTagChip', (tester) async {
    await expectThemedGoldens(
      tester,
      'mx_badges_tags',
      const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 16,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              MxBadge(label: '23 due'),
              MxBadge(label: '4 mastered', tone: MxBadgeTone.mastery),
              MxBadge(label: '2 late', tone: MxBadgeTone.warning),
              MxBadge(label: '1 failed', tone: MxBadgeTone.danger),
              MxBadge(label: '128 cards', tone: MxBadgeTone.neutral),
              MxBadge(label: '23 due', isSolid: true),
              MxBadge(
                label: '12 ready',
                tone: MxBadgeTone.mastery,
                icon: AppIcons.check,
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              MxStatusBadge(status: MxCardStatus.newCard, label: 'New'),
              MxStatusBadge(status: MxCardStatus.learning, label: 'Learning'),
              MxStatusBadge(
                status: MxCardStatus.reviewing,
                label: 'Reviewing',
              ),
              MxStatusBadge(status: MxCardStatus.mastered, label: 'Mastered'),
              MxStatusBadge(
                status: MxCardStatus.learning,
                label: 'Learning',
                isDot: true,
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              MxTagChip(label: 'verbs'),
              MxTagChip(label: 'N5', isDense: true),
              MxTagChip(label: 'a tag long enough to reach the maximum'),
            ],
          ),
        ],
      ),
    );
  });
}
```

- [ ] **Step 2: Run them to verify they fail**

Run: `flutter test test/shared/widgets/mx_badge_test.dart test/shared/widgets/mx_status_badge_test.dart test/shared/widgets/mx_tag_chip_test.dart`
Expected: FAIL to compile, because the widget files do not exist.

- [ ] **Step 3: Implement**

`lib/shared/widgets/mx_badge.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';

/// The tone a count carries. There is no streak tone (ruling S1).
enum MxBadgeTone { primary, mastery, warning, danger, neutral }

/// A count pill. The unit belongs inside the label ("23 due"), so the digits
/// stay tabular and the space is part of the text. Omitting a zero count is
/// the caller's call.
class MxBadge extends StatelessWidget {
  const MxBadge({
    super.key,
    required this.label,
    this.tone = MxBadgeTone.primary,
    this.isSolid = false,
    this.icon,
  });

  final String label;
  final MxBadgeTone tone;

  /// Emphasis inside a tinted or hero surface.
  final bool isSolid;

  /// A 12 glyph before the label, for a counted status (ruling S18).
  final IconData? icon;

  /// A minimum: text scaling grows the pill (ruling S11).
  static const double _height = 22;
  static const double _glyphSize = 12;
  static const double _tint = 0.12;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final toneColor = switch (tone) {
      MxBadgeTone.primary => colors.primary,
      MxBadgeTone.mastery => context.semanticColors.mastery,
      MxBadgeTone.warning => context.semanticColors.warning,
      MxBadgeTone.danger => colors.error,
      // Ruling S2: the contract names no neutral colour.
      MxBadgeTone.neutral => colors.onSurfaceVariant,
    };
    // Ruling S3: tonal warning text reads in warning-ink, because the amber
    // fails as 12px text on a light surface.
    final ink = switch ((isSolid, tone)) {
      (true, _) => colors.onPrimary,
      (false, MxBadgeTone.warning) => context.derivedColors.warningInk,
      (false, _) => toneColor,
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isSolid ? toneColor : toneColor.withValues(alpha: _tint),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: _height),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.control),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: AppSpacing.micro,
            children: [
              if (icon case final glyph?)
                Icon(glyph, size: _glyphSize, color: ink),
              Text(
                label,
                maxLines: 1,
                softWrap: false,
                style: context.textStyles.badgeLabel(ink),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

`lib/shared/widgets/mx_status_badge.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';

/// The card lifecycle, in order.
enum MxCardStatus { newCard, learning, reviewing, mastered }

/// Names a card's lifecycle state; a Badge counts things. The status fixes
/// the colour. The caller passes the localized name (ruling S6), which the
/// bare dot uses as its semantics label.
class MxStatusBadge extends StatelessWidget {
  const MxStatusBadge({
    super.key,
    required this.status,
    required this.label,
    this.isDot = false,
  });

  final MxCardStatus status;
  final String label;

  /// The bare 8 indicator for dense card rows.
  final bool isDot;

  /// A minimum: text scaling grows the pill (ruling S11).
  static const double _height = 22;
  static const double _pillDot = 6;
  static const double _bareDot = 8;

  /// The dot sits closer to the start edge than the label to the end edge.
  static const double _startPadding = 6;
  static const double _tint = 0.12;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final color = switch (status) {
      MxCardStatus.newCard => semantic.statusNew,
      MxCardStatus.learning => semantic.statusLearning,
      MxCardStatus.reviewing => semantic.statusReviewing,
      MxCardStatus.mastered => semantic.statusMastered,
    };
    if (isDot) {
      return Semantics(
        container: true,
        label: label,
        child: _Dot(color: color, size: _bareDot),
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: _tint),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: _height),
        child: Padding(
          padding: const EdgeInsetsDirectional.only(
            start: _startPadding,
            end: AppSpacing.control,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: AppSpacing.micro,
            children: [
              _Dot(color: color, size: _pillDot),
              Text(
                label,
                maxLines: 1,
                softWrap: false,
                style: context.textStyles.badgeLabel(color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: DecoratedBox(
      key: const ValueKey('mx-status-dot'),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    ),
  );
}
```

`lib/shared/widgets/mx_tag_chip.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';

/// A tag as read-only metadata, in two densities: 22 on its own line, 18
/// inside a packed 12px metadata line. The removable chip in the card editor
/// is a different, interactive control.
class MxTagChip extends StatelessWidget {
  const MxTagChip({super.key, required this.label, this.isDense = false});

  final String label;
  final bool isDense;

  /// Minimums: text scaling grows the chip (ruling S11).
  static const double _height = 22;
  static const double _denseHeight = 18;

  /// A long tag must not push the row.
  static const double _maxWidth = 140;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: BoxConstraints(
      minHeight: isDense ? _denseHeight : _height,
      maxWidth: _maxWidth,
    ),
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.control),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: context.textStyles.tagLabel,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
```

- [ ] **Step 4: Run them to verify they pass**

Run: `flutter test test/shared/widgets/mx_badge_test.dart test/shared/widgets/mx_status_badge_test.dart test/shared/widgets/mx_tag_chip_test.dart`
Expected: PASS, 4 + 3 + 2 tests.

- [ ] **Step 5: Golden, gate, commit**

```bash
flutter test --update-goldens --tags golden test/shared/widgets/status_widgets_golden_test.dart
flutter test --tags golden test/shared/widgets/status_widgets_golden_test.dart
dart format lib test
flutter analyze
python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
git add lib/shared/widgets test/shared/widgets
git commit -m "feat(ui): MxBadge, MxStatusBadge, MxTagChip

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

Check the golden:
- The tonal pills are pale with coloured text.
- The solid pill is filled.
- The warning text is dark amber in light.
- The status pills have a dot before the name.
- The bare dot is 8 wide.
- The long tag ends in an ellipsis at 140.

---

### Task 7: MxWorkloadBreakdownLine and MxMasteryDonut

**Files:**
- Create: `lib/shared/widgets/mx_workload_breakdown_line.dart`, `lib/shared/widgets/mx_mastery_donut.dart`
- Modify: `test/shared/widgets/status_widgets_golden_test.dart`
- Test: `test/shared/widgets/mx_workload_breakdown_line_test.dart`, `test/shared/widgets/mx_mastery_donut_test.dart`

**Interfaces:**
- Consumes: `workloadText`, `workloadTerm(Color)`, `donutLabel(Color)`, `MasteryRamp.fill`, `derivedColors.warningInk`, `semanticColors.statusNew`, `package:intl` `NumberFormat.percentPattern`.
- Produces:
  - `MxWorkloadBreakdownLine({required int overdueCount, required int todayCount, required int newCount, required String Function(int) overdueLabel, required String Function(int) todayLabel, required String Function(int) newLabel, required String fallback, String? suffix})`
  - `MxMasteryDonut({required double fraction})`

- [ ] **Step 1: Write the failing tests**

`test/shared/widgets/mx_workload_breakdown_line_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/mx_derived_colors.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
import 'package:memox/shared/widgets/mx_workload_breakdown_line.dart';

import '../../support/widget_harness.dart';

MxWorkloadBreakdownLine _line({
  int overdue = 3,
  int today = 5,
  int fresh = 2,
  String? suffix,
}) => MxWorkloadBreakdownLine(
  overdueCount: overdue,
  todayCount: today,
  newCount: fresh,
  overdueLabel: (n) => '$n overdue',
  todayLabel: (n) => '$n today',
  newLabel: (n) => '$n new',
  fallback: 'Nothing due',
  suffix: suffix,
);

TextSpan _root(WidgetTester tester) =>
    tester
            .widget<Text>(
              find.descendant(
                of: find.byType(MxWorkloadBreakdownLine),
                matching: find.byType(Text),
              ),
            )
            .textSpan!
        as TextSpan;

String _plain(WidgetTester tester) => _root(tester).toPlainText();

TextStyle? _termStyle(WidgetTester tester, String term) => _root(tester)
    .children!
    .whereType<TextSpan>()
    .firstWhere((span) => span.text == term)
    .style;

void main() {
  final scheme = AppColorSchemes.light;
  final semantic = MxSemanticColors.light;
  final derived = MxDerivedColors.resolve(scheme, semantic);

  testWidgets('all three terms in order, each in its colour, at 600', (
    tester,
  ) async {
    await pumpMx(tester, _line());

    expect(_plain(tester), '3 overdue · 5 today · 2 new');
    expect(_termStyle(tester, '3 overdue')!.color, derived.warningInk);
    expect(_termStyle(tester, '5 today')!.color, scheme.primary);
    expect(_termStyle(tester, '2 new')!.color, semantic.statusNew);
    expect(_termStyle(tester, '2 new')!.fontWeight, FontWeight.w600);
    expect(_root(tester).style!.fontWeight, FontWeight.w400);
    expect(_root(tester).style!.color, scheme.onSurfaceVariant);
  });

  testWidgets('a zero term drops with its separator (RF4)', (tester) async {
    for (final (overdue, today, fresh, expected) in [
      (0, 5, 2, '5 today · 2 new'),
      (3, 0, 2, '3 overdue · 2 new'),
      (3, 5, 0, '3 overdue · 5 today'),
      (0, 0, 2, '2 new'),
    ]) {
      await pumpMx(tester, _line(overdue: overdue, today: today, fresh: fresh));

      expect(_plain(tester), expected);
    }
  });

  testWidgets('nothing due is the fallback; a suffix follows the terms', (
    tester,
  ) async {
    await pumpMx(tester, _line(overdue: 0, today: 0, fresh: 0));
    expect(_plain(tester), 'Nothing due');

    await pumpMx(tester, _line(suffix: 'across 4 decks'));
    expect(_plain(tester), '3 overdue · 5 today · 2 new across 4 decks');
  });

  testWidgets('one 18 line with an ellipsis', (tester) async {
    await pumpMx(tester, SizedBox(width: 120, child: _line()));
    final text = tester.widget<Text>(
      find.descendant(
        of: find.byType(MxWorkloadBreakdownLine),
        matching: find.byType(Text),
      ),
    );

    expect((text.maxLines, text.overflow), (1, TextOverflow.ellipsis));
    expect(tester.getSize(find.byType(MxWorkloadBreakdownLine)).height, 18);
  });

  test('a negative count asserts', () {
    expect(() => _line(overdue: -1), throwsAssertionError);
  });
}
```

`test/shared/widgets/mx_mastery_donut_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
import 'package:memox/shared/widgets/mx_mastery_donut.dart';

import '../../support/widget_harness.dart';

RenderObject _ring(WidgetTester tester) => tester.renderObject(
  find
      .descendant(
        of: find.byType(MxMasteryDonut),
        matching: find.byType(CustomPaint),
      )
      .first,
);

void main() {
  final scheme = AppColorSchemes.light;
  final semantic = MxSemanticColors.light;

  testWidgets('56 box; the label is the percentage in the ramp colour', (
    tester,
  ) async {
    for (final (fraction, text, color) in [
      (0.2, '20%', semantic.statusLearning),
      (0.42, '42%', semantic.statusReviewing),
      (0.9, '90%', semantic.statusMastered),
    ]) {
      await pumpMx(tester, MxMasteryDonut(fraction: fraction));

      expect(tester.getSize(find.byType(MxMasteryDonut)), const Size.square(56));
      expect(tester.widget<Text>(find.text(text)).style!.color, color);
      expect(
        _ring(tester),
        paints
          ..circle(color: scheme.surfaceContainer, style: PaintingStyle.stroke)
          ..arc(color: color, strokeCap: StrokeCap.round),
      );
    }
  });

  testWidgets('0%: the track only; the label in the lowest band (RF5)', (
    tester,
  ) async {
    await pumpMx(tester, const MxMasteryDonut(fraction: 0));

    expect(
      tester.widget<Text>(find.text('0%')).style!.color,
      semantic.statusLearning,
    );
    expect(_ring(tester), paints..circle(color: scheme.surfaceContainer));
    expect(_ring(tester), isNot(paints..arc()));
  });

  testWidgets('100%: the full ring at the top colour', (tester) async {
    await pumpMx(tester, const MxMasteryDonut(fraction: 1));

    expect(
      tester.widget<Text>(find.text('100%')).style!.color,
      semantic.statusMastered,
    );
    expect(_ring(tester), paints..arc(color: semantic.statusMastered));
  });

  testWidgets('at 2x the label stays inside the ring', (tester) async {
    await pumpMx(tester, const MxMasteryDonut(fraction: 1), textScale: 2);

    expect(tester.takeException(), isNull);
    expect(tester.getRect(find.text('100%')).width, lessThanOrEqualTo(44));
  });

  test('out of range or NaN asserts (RF5)', () {
    expect(() => MxMasteryDonut(fraction: 1.2), throwsAssertionError);
    expect(() => MxMasteryDonut(fraction: -0.1), throwsAssertionError);
    expect(() => MxMasteryDonut(fraction: double.nan), throwsAssertionError);
  });
}
```

Before the closing `}` of `status_widgets_golden_test.dart`, append the test below. Add imports for `mx_workload_breakdown_line.dart` and `mx_mastery_donut.dart`.

```dart
  testWidgets('MxWorkloadBreakdownLine and MxMasteryDonut', (tester) async {
    String overdue(int n) => '$n overdue';
    String today(int n) => '$n today';
    String fresh(int n) => '$n new';
    await expectThemedGoldens(
      tester,
      'mx_workload_donut',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 16,
        children: [
          MxWorkloadBreakdownLine(
            overdueCount: 3,
            todayCount: 12,
            newCount: 5,
            overdueLabel: overdue,
            todayLabel: today,
            newLabel: fresh,
            fallback: 'Nothing due',
            suffix: 'across 4 decks',
          ),
          MxWorkloadBreakdownLine(
            overdueCount: 0,
            todayCount: 4,
            newCount: 0,
            overdueLabel: overdue,
            todayLabel: today,
            newLabel: fresh,
            fallback: 'Nothing due',
          ),
          MxWorkloadBreakdownLine(
            overdueCount: 0,
            todayCount: 0,
            newCount: 0,
            overdueLabel: overdue,
            todayLabel: today,
            newLabel: fresh,
            fallback: '42 cards · nothing due',
          ),
          const Row(
            spacing: 16,
            children: [
              MxMasteryDonut(fraction: 0),
              MxMasteryDonut(fraction: 0.2),
              MxMasteryDonut(fraction: 0.5),
              MxMasteryDonut(fraction: 1),
            ],
          ),
        ],
      ),
    );
  });
```

- [ ] **Step 2: Run them to verify they fail**

Run: `flutter test test/shared/widgets/mx_workload_breakdown_line_test.dart test/shared/widgets/mx_mastery_donut_test.dart`
Expected: FAIL to compile, because the widget files do not exist.

- [ ] **Step 3: Implement**

`lib/shared/widgets/mx_workload_breakdown_line.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/theme_context.dart';

/// The "N overdue · N today · N new" statement, with one colour for each
/// term across the whole product.
/// - A term at zero drops out together with its separator.
/// - The order is urgency first, and it never changes.
/// - When nothing is due, [fallback] is the whole line.
///
/// It paints no top margin: the row that stacks it owns the 2 gap (S12).
class MxWorkloadBreakdownLine extends StatelessWidget {
  const MxWorkloadBreakdownLine({
    super.key,
    required this.overdueCount,
    required this.todayCount,
    required this.newCount,
    required this.overdueLabel,
    required this.todayLabel,
    required this.newLabel,
    required this.fallback,
    this.suffix,
  }) : assert(
         overdueCount >= 0 && todayCount >= 0 && newCount >= 0,
         'counts are never negative',
       );

  final int overdueCount;
  final int todayCount;
  final int newCount;

  /// Builds a term from its count, typically a plural ARB message.
  final String Function(int count) overdueLabel;
  final String Function(int count) todayLabel;
  final String Function(int count) newLabel;

  /// The calm line when all three counts are zero: "12 cards · nothing due",
  /// "Nothing due" or "No cards yet". The caller knows which one applies.
  final String fallback;

  /// A trailing clause ("across 4 decks"), after a space.
  final String? suffix;

  static const String _separator = ' · ';
  static const String _space = ' ';

  @override
  Widget build(BuildContext context) {
    final styles = context.textStyles;
    final terms = [
      (overdueCount, overdueLabel, context.derivedColors.warningInk),
      (todayCount, todayLabel, context.colors.primary),
      (newCount, newLabel, context.semanticColors.statusNew),
    ].where((term) => term.$1 > 0).toList();
    return Text.rich(
      TextSpan(
        style: styles.workloadText,
        children: [
          for (final (index, (count, label, ink)) in terms.indexed) ...[
            if (index > 0) const TextSpan(text: _separator),
            TextSpan(text: label(count), style: styles.workloadTerm(ink)),
          ],
          if (terms.isEmpty) TextSpan(text: fallback),
          if (suffix case final clause?) ...[
            const TextSpan(text: _space),
            TextSpan(text: clause),
          ],
        ],
      ),
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.ellipsis,
    );
  }
}
```

The suffix test expects `'… 2 new across 4 decks'`: one space span, then the clause.

`lib/shared/widgets/mx_mastery_donut.dart`:

```dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:memox/core/theme/mastery_ramp.dart';
import 'package:memox/core/theme/theme_context.dart';

/// The circular mastery indicator. The ring fills clockwise from twelve
/// o'clock in the MasteryRamp colour, and the percentage uses the same
/// colour, so the number and the ring never disagree.
class MxMasteryDonut extends StatelessWidget {
  const MxMasteryDonut({super.key, required this.fraction})
    : assert(fraction >= 0 && fraction <= 1, 'fraction is within [0, 1]');

  final double fraction;

  static const double _box = 56;

  /// The kit's geometry: r 17 and stroke 3 on a 40 viewBox, scaled to the
  /// box.
  static const double _viewBox = 40;
  static const double _viewRadius = 17;
  static const double _viewStroke = 3;
  static const double _scale = _box / _viewBox;

  /// The clear space inside the stroke, where the label scales down to fit
  /// (ruling S10).
  static const double _innerDiameter =
      (_viewRadius * 2 - _viewStroke) * _scale;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    // Ruling S10: 0% falls in the lowest band, so its label takes that colour.
    final ink = MasteryRamp.fill(semantic, fraction) ?? semantic.statusLearning;
    final percent = NumberFormat.percentPattern(
      Localizations.localeOf(context).toString(),
    ).format(fraction);
    return SizedBox.square(
      dimension: _box,
      child: CustomPaint(
        painter: _DonutPainter(
          fraction: fraction,
          arc: ink,
          // Ruling S10: the contract's track, not the ramp's progress-track.
          track: context.colors.surfaceContainer,
        ),
        child: Center(
          child: SizedBox.square(
            dimension: _innerDiameter,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(percent, style: context.textStyles.donutLabel(ink)),
            ),
          ),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({
    required this.fraction,
    required this.arc,
    required this.track,
  });

  final double fraction;
  final Color arc;
  final Color track;

  static const double _fullTurn = 2 * math.pi;
  static const double _twelveOClock = -math.pi / 2;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    const radius = MxMasteryDonut._viewRadius * MxMasteryDonut._scale;
    canvas.drawCircle(center, radius, _stroke(track));
    if (fraction == 0) return;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      _twelveOClock,
      _fullTurn * fraction,
      false,
      _stroke(arc),
    );
  }

  Paint _stroke(Color color) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = MxMasteryDonut._viewStroke * MxMasteryDonut._scale
    ..strokeCap = StrokeCap.round;

  @override
  bool shouldRepaint(_DonutPainter oldDelegate) =>
      oldDelegate.fraction != fraction ||
      oldDelegate.arc != arc ||
      oldDelegate.track != track;
}
```

- [ ] **Step 4: Run them to verify they pass**

Run: `flutter test test/shared/widgets/mx_workload_breakdown_line_test.dart test/shared/widgets/mx_mastery_donut_test.dart`
Expected: PASS, 5 + 5 tests.

- [ ] **Step 5: Golden, gate, commit**

Run the same commands as Task 6 Step 5. Commit message: `feat(ui): MxWorkloadBreakdownLine, MxMasteryDonut`.

Check the golden:
- The overdue term is dark amber, the today term indigo, and the new term blue-grey.
- The all-zero line is the calm fallback.
- The donuts show an empty ring at 0%, then amber, indigo and green.
- The 100% donut is a full green ring.
- Each label has its arc's colour.

---

### Task 8: Gallery, spec, gate, hand back

**Files:**
- Create: `lib/app/gallery/gallery_surfaces_section.dart`, `lib/app/gallery/gallery_status_section.dart`
- Modify: `lib/app/gallery/gallery_screen.dart`, `test/app/gallery_test.dart`, `docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md`

- [ ] **Step 1: Write the failing gallery test**

In `test/app/gallery_test.dart`, under "every built group is present", add these titles after `'C · Inputs & selection'`:
- `'D · Surfaces, rows & content'`
- `'E · Status & metadata'`

Run: `flutter test test/app/gallery_test.dart`
Expected: FAIL, because 'D · Surfaces, rows & content' is not found.

- [ ] **Step 2: Create groups D and E**

`lib/app/gallery/gallery_surfaces_section.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/app/gallery/gallery_section.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_action_sheet_command_row.dart';
import 'package:memox/shared/widgets/mx_badge.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_chip_trigger.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';
import 'package:memox/shared/widgets/mx_list_section_header.dart';
import 'package:memox/shared/widgets/mx_section.dart';
import 'package:memox/shared/widgets/mx_settings_row.dart';
import 'package:memox/shared/widgets/mx_stepper.dart';
import 'package:memox/shared/widgets/mx_toggle.dart';

/// Group D: the surfaces and the rows that fill them, live where they have
/// state.
class GallerySurfacesSection extends StatefulWidget {
  const GallerySurfacesSection({super.key});

  @override
  State<GallerySurfacesSection> createState() => _GallerySurfacesSectionState();
}

class _GallerySurfacesSectionState extends State<GallerySurfacesSection> {
  static const int _minCards = 1;
  static const int _maxCards = 200;

  var _isReminderOn = true;
  var _cards = 20;

  @override
  Widget build(BuildContext context) => GallerySection(
    title: 'D · Surfaces, rows & content',
    children: [
      const MxCard(
        isHero: true,
        child: MxListSectionHeader(
          label: 'Hero card',
          trailing: MxBadge(label: '23 due', isSolid: true),
        ),
      ),
      Row(
        spacing: AppSpacing.grouped,
        children: [
          const MxIconTile(icon: AppIcons.library),
          const MxIconTile(
            icon: AppIcons.reminder,
            size: MxIconTileSize.medium,
          ),
          const MxIconTile(
            icon: AppIcons.library,
            size: MxIconTileSize.large,
          ),
          MxIconTile(
            icon: AppIcons.folder,
            seed: context.semanticColors.mastery,
          ),
        ],
      ),
      MxListSectionHeader(
        label: 'Decks',
        trailing: MxChipTrigger(
          label: 'Sort: Due',
          icon: AppIcons.sort,
          onPressed: () {},
        ),
      ),
      MxCard(
        isFullBleed: true,
        child: Column(
          children: [
            MxListRow(
              title: 'Kanji N5',
              subtitle: '42 cards · 12 due',
              leading: const MxIconTile(icon: AppIcons.library),
              hasChevron: true,
              onTap: () {},
            ),
            MxListRow(
              title: 'A deck name long enough to be cut with an ellipsis',
              subtitle: 'Nested three levels deep',
              leading: const MxIconTile(icon: AppIcons.folder),
              trailing: MxIconButton(
                icon: AppIcons.more,
                semanticLabel: 'Deck actions',
                onPressed: () {},
              ),
              onTap: () {},
            ),
            MxListRow(
              title: 'Importing',
              subtitle: '120 of 300 cards',
              leading: const MxIconTile(icon: AppIcons.library),
              isBusy: true,
              onTap: () {},
            ),
            MxListRow(
              title: 'Grammar',
              subtitle: 'Cannot hold another deck',
              leading: const MxIconTile(icon: AppIcons.folder),
              isEnabled: false,
              onTap: () {},
              hasDivider: false,
            ),
          ],
        ),
      ),
      MxSection(
        title: 'Reminders',
        note: 'Changes apply to future sessions.',
        children: [
          MxSettingsRow(
            label: 'Daily reminder',
            subtitle: 'One nudge at the time you choose',
            icon: AppIcons.reminder,
            trailing: MxToggle(
              isOn: _isReminderOn,
              onChanged: (value) => setState(() => _isReminderOn = value),
              semanticLabel: 'Daily reminder',
            ),
          ),
          MxSettingsRow(
            label: 'Cards per session',
            icon: AppIcons.library,
            wideControl: MxStepper(
              value: _cards,
              decrementLabel: 'Fewer cards',
              incrementLabel: 'More cards',
              onDecrement: _cards > _minCards
                  ? () => setState(() => _cards--)
                  : null,
              onIncrement: _cards < _maxCards
                  ? () => setState(() => _cards++)
                  : null,
            ),
          ),
          MxSettingsRow(
            label: 'Language',
            icon: AppIcons.settings,
            onTap: () {},
          ),
          const MxSettingsRow(
            label: 'Unavailable while notifications are off',
            icon: AppIcons.reminder,
            isEnabled: false,
          ),
        ],
      ),
      MxCard(
        child: Column(
          children: [
            MxActionSheetCommandRow(
              icon: AppIcons.edit,
              label: 'Rename',
              subtitle: 'Change the deck name',
              onTap: () {},
            ),
            MxActionSheetCommandRow(
              icon: AppIcons.folder,
              label: 'Move',
              hasChevron: true,
              onTap: () {},
            ),
            MxActionSheetCommandRow(
              icon: AppIcons.delete,
              label: 'Delete',
              subtitle: 'Recoverable for 30 days',
              isDestructive: true,
              onTap: () {},
            ),
          ],
        ),
      ),
    ],
  );
}
```

`lib/app/gallery/gallery_status_section.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/app/gallery/gallery_section.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/shared/widgets/mx_badge.dart';
import 'package:memox/shared/widgets/mx_mastery_donut.dart';
import 'package:memox/shared/widgets/mx_note.dart';
import 'package:memox/shared/widgets/mx_status_badge.dart';
import 'package:memox/shared/widgets/mx_tag_chip.dart';
import 'package:memox/shared/widgets/mx_workload_breakdown_line.dart';

/// Group E: counts, lifecycle, tags, rules and the workload and mastery
/// indicators.
class GalleryStatusSection extends StatelessWidget {
  const GalleryStatusSection({super.key});

  static String _overdue(int count) => '$count overdue';
  static String _today(int count) => '$count today';
  static String _fresh(int count) => '$count new';

  @override
  Widget build(BuildContext context) => const GallerySection(
    title: 'E · Status & metadata',
    children: [
      Wrap(
        spacing: AppSpacing.control,
        runSpacing: AppSpacing.control,
        children: [
          MxBadge(label: '23 due'),
          MxBadge(label: '4 mastered', tone: MxBadgeTone.mastery),
          MxBadge(label: '2 late', tone: MxBadgeTone.warning),
          MxBadge(label: '1 failed', tone: MxBadgeTone.danger),
          MxBadge(label: '128 cards', tone: MxBadgeTone.neutral),
          MxBadge(label: '23 due', isSolid: true),
          MxBadge(
            label: '12 ready',
            tone: MxBadgeTone.mastery,
            icon: AppIcons.check,
          ),
        ],
      ),
      Wrap(
        spacing: AppSpacing.control,
        runSpacing: AppSpacing.control,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          MxStatusBadge(status: MxCardStatus.newCard, label: 'New'),
          MxStatusBadge(status: MxCardStatus.learning, label: 'Learning'),
          MxStatusBadge(status: MxCardStatus.reviewing, label: 'Reviewing'),
          MxStatusBadge(status: MxCardStatus.mastered, label: 'Mastered'),
          MxStatusBadge(
            status: MxCardStatus.learning,
            label: 'Learning',
            isDot: true,
          ),
        ],
      ),
      Wrap(
        spacing: AppSpacing.control,
        runSpacing: AppSpacing.control,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          MxTagChip(label: 'verbs'),
          MxTagChip(label: 'N5', isDense: true),
          MxTagChip(label: 'a tag long enough to reach the maximum'),
        ],
      ),
      MxNote(text: 'Deleted decks stay recoverable for 30 days.'),
      MxWorkloadBreakdownLine(
        overdueCount: 3,
        todayCount: 12,
        newCount: 5,
        overdueLabel: _overdue,
        todayLabel: _today,
        newLabel: _fresh,
        fallback: 'Nothing due',
        suffix: 'across 4 decks',
      ),
      MxWorkloadBreakdownLine(
        overdueCount: 0,
        todayCount: 0,
        newCount: 0,
        overdueLabel: _overdue,
        todayLabel: _today,
        newLabel: _fresh,
        fallback: '42 cards · nothing due',
      ),
      Row(
        spacing: AppSpacing.gutter,
        children: [
          MxMasteryDonut(fraction: 0),
          MxMasteryDonut(fraction: 0.2),
          MxMasteryDonut(fraction: 0.5),
          MxMasteryDonut(fraction: 1),
        ],
      ),
    ],
  );
}
```

In `gallery_screen.dart`:
- Import both files.
- Add `GallerySurfacesSection(),` and `GalleryStatusSection(),` right after `GalleryInputsSection(),`.

Run: `flutter test test/app/gallery_test.dart`
Expected: PASS, 5 tests, including the 2x text render with no exception.

- [ ] **Step 3: Check the app goldens**

```bash
flutter test --tags golden test/app/app_golden_test.dart
```

Expected: PASS. Groups D and E sit below the first screen of the gallery, so the gallery golden should not change.

If `app_gallery_*` changes anyway:
1. Regenerate it with `--update-goldens`.
2. Open it and confirm that only the part below group C differs.
3. Record a ruling.

The Library golden must not change.

- [ ] **Step 4: Record the rulings in spec §9**

Append after row 27:

```markdown
| 28 | Badge offers no `streak` tone: its colour is PRESERVE_ONLY with no V3 call site, and §4.2 keeps the extension at nine fields | phase 5 plan S1 |
| 29 | Badge's `neutral` tone, whose colour the contract does not name, paints `onSurfaceVariant`, as EmptyState's neutral tone does | phase 5 plan S2 |
| 30 | A tonal warning Badge reads in `warningInk` (extends row 20); a solid Badge's label is `onPrimary` for every tone as written, so a solid warning badge is white on amber | phase 5 plan S3 |
| 31 | Pill and count text (Badge, StatusBadge, TagChip, WorkloadBreakdownLine, MasteryDonut label) takes the 0.1 label tracking (extends row 26) | phase 5 plan S4 |
| 32 | 12px text whose contract states only size and colour (the ListRow, ActionSheetCommandRow and SettingsRow sub-lines, Note) keeps the caption role (extends row 24) | phase 5 plan S5 |
| 33 | StatusBadge's four names come from the caller, since `shared/` cannot import `l10n/`; the bare dot announces the same name | phase 5 plan S6 |
| 34 | ActionSheetCommandRow's glyph (16) and label→sub gap (2) are UNSPECIFIED and use the small IconTile step and the ListRow gap | phase 5 plan S7 |
| 35 | Section draws the ghost dividers between its rows, renders its note as MxNote, and keeps its 16 bottom gap although §5 gives outer spacing to the caller | phase 5 plan S8, S9 |
| 36 | MasteryDonut's track is `surfaceContainer` as its contract states, not MasteryRamp's progress-track; at 0% the label takes the lowest band colour; the label scales down to stay inside the ring | phase 5 plan S10 |
| 37 | Badge, StatusBadge and TagChip heights (22, 18) are minimums that text scaling grows | phase 5 plan S11 |
| 38 | WorkloadBreakdownLine paints no top margin; the row that stacks it owns the 2 gap. The suffix follows the terms after a space | phase 5 plan S12 |
| 39 | IconTile's `seed` is the one `Color` parameter among the shared widgets: per-deck data the contract passes per instance | phase 5 plan S16 |
| 40 | SettingsRow's wide control keeps its own width, start-aligned under the label, since Stepper and SegmentedTray are intrinsic-width | phase 5 plan S17 |
| 41 | Badge's leading glyph is 12, below the 16 icon floor, as its contract states | phase 5 plan S18 |
| 42 | Row 16's footnote half is resolved: EmptyState's `footnote` renders an MxNote 20 below the action | phase 5 plan S19 |
```

- [ ] **Step 5: Gate, scope, commit, hand back**

```bash
dart format lib test
flutter analyze
flutter test
python .claude/skills/flutter-architecture/scripts/check_architecture.py
python -m unittest discover -s .claude/skills/flutter-workflow/scripts/tests -p "test_*.py"
python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
python tools/docs/check.py
git add lib/app test/app docs/superpowers
git commit -m "feat(app): phase 5 widgets in the gallery; record phase 5 rulings

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
git diff --name-only origin/master...HEAD
```

Expected:
- Every gate command exits 0.
- The guard reports 0 errors and 0 warnings.
- The diff lists only `lib/core/theme/`, `lib/shared/widgets/`, `lib/app/gallery/`, `test/` and `docs/superpowers/`.

Report to the user in Vietnamese:
- Counts and results.
- Every execution ruling.
- The new goldens, sent with SendUserFile.

Then ask through AskUserQuestion whether to open the PR, merge it, and continue to phase 6.

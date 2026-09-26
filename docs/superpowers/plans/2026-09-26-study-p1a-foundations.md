# Study P1a — foundations (FE-A6) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give phase P1 of the study flow what its screens need and nothing yet provides: the summary hero's `success`/`danger`/`caution` tones, the shared `MxStatTile`, the Study Entry's overdue count and resumable session, and the summary's answered and turn counts.

**Architecture:** Theme first, then the shared widgets on it (`flutter-theme-design`: token → ThemeData/extension → Mx widget → tests), then two read-model extensions in the study data layer, each proven by a repository test over an in-memory database. No screen is built here; P1b builds screens 14, 16 and 21 on these.

**Tech Stack:** Flutter 3.47.5, Drift, Riverpod 3 (untouched here), `flutter_test` goldens on Linux.

**Spec:** [docs/superpowers/specs/2026-09-26-study-ui-design.md](../specs/2026-09-26-study-ui-design.md) — D11 (summary counts), D14 (tones), D15 (entry read model), D17 (`MxStatTile`), D18 (nothing answered).

## Global Constraints

- `success` is `#2BA88B` light / `#6FE0BD` dark (V3 foundations, `docs/shared/ui/design-handoff/01-foundations.md:75`); `success-soft` is `success` at 10 % light / 18 % dark (`02-theme-binding.md:298`).
- Green means success or mastery, never tertiary; `mastery` keeps its own field and values.
- A glyph on a soft tint reads at ≥ 3:1 against its ground; text reads at ≥ 4.5:1 (PRODUCT.md, WCAG 2.2 AA). Where the kit's hue fails, the ink is pulled toward `onSurface` as the status inks are (`MxDerivedColors._ink`), and the deviation is recorded.
- Feature code never passes a `Color`, `TextStyle`, radius, border or padding to a shared widget (`flutter-theme-design` §0).
- No magic numbers in `lib/`: every ratio is a named constant.
- `study` imports only `study_mode`, `srs`, `settings`, `card` (`test/architecture/boundary_rules.dart`).
- Goldens are written on Linux; run the untouched golden suite first (it must pass) before `--update-goldens`.
- After an ARB change run `flutter gen-l10n`; after a `@riverpod`/Drift change run `dart run build_runner build --delete-conflicting-outputs`.

## Review Focus

1. A session answered only in Browse (no graded turn) must count 0 answered and 0 turns, so the summary shows no stats (D18) — pinned in Task 5.
2. A card due earlier today is due but not overdue; one due yesterday is both — pinned in Task 4 at the local-day boundary.
3. A session resumable on another deck of the tree must not appear on this deck's entry — pinned in Task 4 (existing test, carried over).
4. The success ink and the caution/danger glyph inks must pass contrast in dark as well as light — pinned in Tasks 1 and 2 for both brightnesses.
5. `MxStatTile` must stay one TalkBack node reading label and value, and must not clip at text scale 2 — pinned in Task 3.

---

## File map

| File | Action | Responsibility |
|---|---|---|
| `lib/core/theme/mx_semantic_colors.dart` | modify | `success` field |
| `lib/core/theme/mx_derived_colors.dart` | modify | `successSoft`, `successBorder`, `successInk` |
| `lib/core/theme/app_decorations.dart` | modify | `successCard`, `dangerCard` |
| `lib/core/theme/mx_text_styles.dart` | modify | `statValue`, `statLabel` |
| `lib/shared/widgets/mx_icon_tile.dart` | modify | tones `success`, `caution`, `danger` |
| `lib/shared/widgets/mx_card.dart` | modify | `isSuccess`, `isDanger` |
| `lib/shared/widgets/mx_stat_tile.dart` | create | the stat tile |
| `lib/app/gallery/gallery_surfaces_section.dart`, `lib/app/gallery/gallery_status_section.dart` | modify | show the new tones and the stat tile |
| `lib/l10n/app_en.arb`, `app_vi.arb` | modify | gallery labels only |
| `lib/features/study/domain/models/study_entry_model.dart` | modify | `overdueCardCount`, `resumable` |
| `lib/features/study/domain/models/study_session_view_model.dart` | modify | `answeredCardCount`, `turnCount` |
| `lib/features/study/data/datasources/resumable_session_data_source.dart` | create | the resumable session for Study Home and Study Entry |
| `lib/features/study/data/datasources/study_view_dao.dart`, `study_session_dao.dart` | modify | queries |
| `lib/features/study/data/mappers/study_home_mapper.dart`, `study_session_view_mapper.dart` | modify | mapping |
| `lib/features/study/data/repositories/study_entry_repository_impl.dart`, `study_home_repository_impl.dart`, `study_session_view_repository_impl.dart` | modify | wiring |
| tests under `test/core/theme/`, `test/shared/widgets/`, `test/features/study/data/` | create/modify | proofs |

---

### Task 1: The `success` semantic and its derivations

**Files:**
- Modify: `lib/core/theme/mx_semantic_colors.dart`, `lib/core/theme/mx_derived_colors.dart`
- Test: `test/core/theme/mx_semantic_colors_test.dart`, `test/core/theme/mx_derived_colors_test.dart`

**Interfaces:**
- Produces: `MxSemanticColors.success`; `MxDerivedColors.successSoft`, `.successBorder`, `.successInk`.

- [ ] **Step 1: Failing tests**

In `mx_semantic_colors_test.dart` add to `_expected`:

```dart
  'success': ((c) => c.success, 0xFF2BA88B, 0xFF6FE0BD),
```

and change the header comment to "The ten BIND_NOW …". In `mx_derived_colors_test.dart` add (follow the file's existing helpers for resolving both themes; a contrast helper exists in `test/support/color_matchers.dart` — use it, or the `_ratio` function of `test/shared/widgets/mx_outcome_tile_test.dart`):

```dart
  for (final brightness in Brightness.values) {
    test('success soft is success at 10 % light / 18 % dark, and success ink '
        'reads 4.5:1 on the surface and on its soft tint '
        '(${brightness.name})', () {
      final scheme = brightness == Brightness.light
          ? AppColorSchemes.light
          : AppColorSchemes.dark;
      final semantic = brightness == Brightness.light
          ? MxSemanticColors.light
          : MxSemanticColors.dark;
      final derived = MxDerivedColors.resolve(scheme, semantic);

      expect(
        derived.successSoft.a,
        closeTo(brightness == Brightness.light ? 0.10 : 0.18, 0.001),
      );
      expect(derived.successSoft.withValues(alpha: 1), semantic.success);
      final soft = Color.alphaBlend(derived.successSoft, scheme.surface);
      expect(contrastRatio(derived.successInk, scheme.surface),
          greaterThanOrEqualTo(4.5));
      expect(contrastRatio(derived.successInk, soft),
          greaterThanOrEqualTo(4.5));
    });
  }
```

(`contrastRatio` is the name to use if `color_matchers.dart` has it; otherwise define `_ratio` in the test as `mx_outcome_tile_test.dart` does.)

- [ ] **Step 2: Run to see them fail**

Run: `flutter test test/core/theme/mx_semantic_colors_test.dart test/core/theme/mx_derived_colors_test.dart`
Expected: FAIL — `success`, `successSoft`, `successInk` are not defined.

- [ ] **Step 3: Implement**

`MxSemanticColors`: add `required this.success` to the constructor, `success: Color(0xFF2BA88B)` to `light`, `success: Color(0xFF6FE0BD)` to `dark`, the field

```dart
  /// Success green: a finished session (FE-A6 spec D14). Its own role,
  /// never [mastery], though both read as progress.
  final Color success;
```

and the field in `copyWith` and `lerp`. Update the class doc: `success` moves from PRESERVE_ONLY to bound ("PRESERVE_ONLY semantics (streak, mastery-fixed…)").

`MxDerivedColors`: add the three fields to the private constructor and to `resolve`:

```dart
      successSoft: semantic.success.withValues(
        alpha: isDark ? _successSoftDark : _successSoftLight,
      ),
      successBorder: semantic.success.withValues(
        alpha: isDark ? _successBorderDark : _successBorderLight,
      ),
      // Success TEXT and glyphs: the kit's green fails 4.5:1 on light
      // surfaces, so it is pulled toward onSurface as the status inks are.
      successInk: _ink(
        semantic.success,
        scheme,
        isDark ? _successInkDark : _successInkLight,
      ),
```

with the constants

```dart
  static const double _successSoftLight = 0.10;
  static const double _successSoftDark = 0.18;
  static const double _successBorderLight = 0.26;
  static const double _successBorderDark = 0.32;
  static const double _successInkLight = 0.40;
  static const double _successInkDark = 0;
```

and the documented fields:

```dart
  /// Success tint (V3 success-soft).
  final Color successSoft;

  /// Success card edge, at the warning border's ratios.
  final Color successBorder;

  /// Success TEXT and glyphs, never the success fill.
  final Color successInk;
```

- [ ] **Step 4: Run and tune**

Run the Step 2 command. Expected: PASS. If the 4.5:1 check fails for a brightness, raise that brightness's `_successInk…` constant in steps of 0.05 until it passes, and keep the smallest passing value.

- [ ] **Step 5: Commit**

```bash
git add lib/core/theme test/core/theme
git commit -m "feat(theme): the success semantic and its soft, border and ink (FE-A6 D14)"
```

---

### Task 2: New tones on `MxIconTile` and `MxCard`

**Files:**
- Modify: `lib/shared/widgets/mx_icon_tile.dart`, `lib/shared/widgets/mx_card.dart`, `lib/core/theme/app_decorations.dart`, `lib/app/gallery/gallery_surfaces_section.dart`, `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb`
- Test: `test/shared/widgets/mx_icon_tile_test.dart`, `test/shared/widgets/mx_card_test.dart`, `test/core/theme/app_decorations_test.dart`, `test/shared/widgets/surface_widgets_golden_test.dart`

**Interfaces:**
- Consumes: Task 1.
- Produces: `MxIconTileTone.success`, `.caution`, `.danger`; `MxCard(isSuccess: true)`, `MxCard(isDanger: true)`; `AppDecorations.successCard(scheme, derived)`, `AppDecorations.dangerCard(scheme, derived)`.

- [ ] **Step 1: Failing tests**

`mx_icon_tile_test.dart` — add:

```dart
  for (final brightness in Brightness.values) {
    for (final tone in [
      MxIconTileTone.success,
      MxIconTileTone.caution,
      MxIconTileTone.danger,
    ]) {
      testWidgets('${tone.name}, ${brightness.name}: a soft tint, and the '
          'glyph reads 3:1 on it over the surface', (tester) async {
        await pumpMx(
          tester,
          MxIconTile(icon: AppIcons.check, tone: tone),
          brightness: brightness,
        );
        final scheme = brightness == Brightness.light
            ? AppColorSchemes.light
            : AppColorSchemes.dark;
        final fill = _tile(tester).color!;
        final glyph = tester.widget<Icon>(find.byIcon(AppIcons.check)).color!;

        expect(fill.a, lessThan(1), reason: 'a soft tint, not a solid fill');
        expect(
          _ratio(glyph, Color.alphaBlend(fill, scheme.surface)),
          greaterThanOrEqualTo(3),
        );
      });
    }
  }
```

(`_tile` is the file's existing finder of the tile's `BoxDecoration`; add a `_ratio` helper as in `mx_outcome_tile_test.dart` if the file has none.)

`mx_card_test.dart` — add:

```dart
  testWidgets('a success card and a danger card take their decoration', (
    tester,
  ) async {
    await pumpMx(
      tester,
      const Column(
        children: [
          MxCard(isSuccess: true, child: Text('ok')),
          MxCard(isDanger: true, child: Text('error')),
        ],
      ),
    );
    final colors = tester
        .widgetList<Material>(
          find.descendant(of: find.byType(MxCard), matching: find.byType(Material)),
        )
        .map((material) => material.color)
        .toList();
    final scheme = AppColorSchemes.light;
    final derived = MxDerivedColors.resolve(scheme, MxSemanticColors.light);

    expect(colors, [
      AppDecorations.successCard(scheme, derived).color,
      AppDecorations.dangerCard(scheme, derived).color,
    ]);
  });

  test('a card takes one tone at most', () {
    expect(
      () => MxCard(isHero: true, isSuccess: true, child: const SizedBox()),
      throwsAssertionError,
    );
    expect(
      () => MxCard(isWarning: true, isDanger: true, child: const SizedBox()),
      throwsAssertionError,
    );
  });
```

`app_decorations_test.dart` — add, mirroring its `warningCard` test:

```dart
  test('the success and danger cards blend their soft tint over the raised '
      'fill and take their border', () {
    final scheme = AppColorSchemes.light;
    final derived = MxDerivedColors.resolve(scheme, MxSemanticColors.light);
    final raised = AppDecorations.raisedCard(scheme, derived).color!;

    final success = AppDecorations.successCard(scheme, derived);
    final danger = AppDecorations.dangerCard(scheme, derived);

    expect(success.color, Color.alphaBlend(derived.successSoft, raised));
    expect((success.border! as Border).top.color, derived.successBorder);
    expect(danger.color, Color.alphaBlend(derived.dangerSoft, raised));
    expect((danger.border! as Border).top.color, derived.dangerBorder);
  });
```

- [ ] **Step 2: Run to see them fail**

Run: `flutter test test/shared/widgets/mx_icon_tile_test.dart test/shared/widgets/mx_card_test.dart test/core/theme/app_decorations_test.dart`
Expected: FAIL — unknown tones, parameters and methods.

- [ ] **Step 3: Implement**

`app_decorations.dart`, next to `warningCard`:

```dart
  /// The success Card: the success-soft ground over the raised fill, edged
  /// with the success border, for a finished session (FE-A6 D14).
  static BoxDecoration successCard(
    ColorScheme scheme,
    MxDerivedColors derived,
  ) {
    final raised = raisedCard(scheme, derived);
    return raised.copyWith(
      color: Color.alphaBlend(derived.successSoft, raised.color!),
      border: Border.all(
        color: derived.successBorder,
        width: AppStroke.hairline,
      ),
    );
  }

  /// The danger Card: the danger-soft ground over the raised fill, edged
  /// with the destructive border, for a session stopped by an error.
  static BoxDecoration dangerCard(
    ColorScheme scheme,
    MxDerivedColors derived,
  ) {
    final raised = raisedCard(scheme, derived);
    return raised.copyWith(
      color: Color.alphaBlend(derived.dangerSoft, raised.color!),
      border: Border.all(
        color: derived.dangerBorder,
        width: AppStroke.hairline,
      ),
    );
  }
```

`mx_card.dart`: add `this.isSuccess = false, this.isDanger = false` with docs ("The success Card (a finished session)." / "The danger Card (a session stopped by an error)."), replace the assert with

```dart
  }) : assert(
         [isHero, isWarning, isSuccess, isDanger].where((tone) => tone).length <=
             1,
         'one tone at most',
       );
```

(an assert in a const constructor cannot call `where`; if the analyzer rejects it, write it as `(isHero ? 1 : 0) + (isWarning ? 1 : 0) + (isSuccess ? 1 : 0) + (isDanger ? 1 : 0) <= 1`), and the surface switch:

```dart
    final surface = switch ((isHero, isWarning, isSuccess, isDanger)) {
      (true, _, _, _) => AppDecorations.heroCard(
        context.colors,
        context.derivedColors,
      ),
      (_, true, _, _) => AppDecorations.warningCard(
        context.colors,
        context.derivedColors,
      ),
      (_, _, true, _) => AppDecorations.successCard(
        context.colors,
        context.derivedColors,
      ),
      (_, _, _, true) => AppDecorations.dangerCard(
        context.colors,
        context.derivedColors,
      ),
      _ => AppDecorations.raisedCard(context.colors, context.derivedColors),
    };
```

`mx_icon_tile.dart`: extend the enum with docs

```dart
/// [success], [caution] and [danger] are soft tints with a legible glyph:
/// the session summary's outcomes (FE-A6 D14).
enum MxIconTileTone { tinted, primary, warning, success, caution, danger }
```

and the `(fill, ink)` switch:

```dart
      MxIconTileTone.success => (
        context.derivedColors.successSoft,
        context.derivedColors.successInk,
      ),
      MxIconTileTone.caution => (
        context.derivedColors.warningSoft,
        context.derivedColors.warningInk,
      ),
      MxIconTileTone.danger => (
        context.derivedColors.dangerSoft,
        context.colors.error,
      ),
```

- [ ] **Step 4: Gallery and golden**

In `gallery_surfaces_section.dart` add, after the warning card, `MxCard(isSuccess: true, child: MxListSectionHeader(label: context.l10n.gallerySuccessCard))` and `MxCard(isDanger: true, child: MxListSectionHeader(label: context.l10n.galleryDangerCard))`, and to the icon-tile row three medium tiles `MxIconTile(icon: AppIcons.check, size: MxIconTileSize.medium, tone: MxIconTileTone.success)`, `…(icon: AppIcons.resetProgress, …, tone: MxIconTileTone.caution)`, `…(icon: AppIcons.alert, …, tone: MxIconTileTone.danger)`. Add the ARB keys `gallerySuccessCard` ("Success card" / "Thẻ thành công") and `galleryDangerCard` ("Danger card" / "Thẻ lỗi") next to `galleryWarningCard`, with `@` descriptions like its own, then `flutter gen-l10n`.

In `surface_widgets_golden_test.dart`, extend the `mx_card_icon_tile` scene: after `MxCard(isHero: true, …)` add `MxCard(isSuccess: true, child: SizedBox(height: 56))` and `MxCard(isDanger: true, child: SizedBox(height: 56))`, and a second `Row` of the three new tones (`AppIcons.check` success, `AppIcons.resetProgress` caution, `AppIcons.alert` danger, all `size: MxIconTileSize.large`).

- [ ] **Step 5: Run, write the golden, commit**

Run: `flutter test test/shared/widgets/mx_icon_tile_test.dart test/shared/widgets/mx_card_test.dart test/core/theme test/app/gallery_test.dart`
Expected: PASS. If a glyph misses 3:1 in a theme, raise that tone's ink the way Task 1 tunes `successInk` (a derived ink, never a colour in the widget).
Then (Linux only, after the untouched golden suite passed once in this session): `TZ=UTC flutter test --tags golden --update-goldens test/shared/widgets/surface_widgets_golden_test.dart` and open `test/shared/widgets/goldens/mx_card_icon_tile_{light,dark}.png`; only that golden changes (`git status`).

```bash
git add lib/core/theme lib/shared/widgets lib/app/gallery lib/l10n test/core/theme test/shared/widgets
git commit -m "feat(ui): success, caution and danger tones on MxIconTile and MxCard (FE-A6 D14)"
```

---

### Task 3: `MxStatTile`

**Files:**
- Create: `lib/shared/widgets/mx_stat_tile.dart`
- Modify: `lib/core/theme/mx_text_styles.dart`, `lib/app/gallery/gallery_status_section.dart`, `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb`
- Test: `test/shared/widgets/mx_stat_tile_test.dart`, `test/core/theme/mx_text_styles_test.dart`, `test/shared/widgets/status_widgets_golden_test.dart`

**Interfaces:**
- Produces:
  - `enum MxStatTileEmphasis { primary, plain, muted }`
  - `enum MxStatTileLayout { boxed, inline }`
  - `MxStatTile({required String value, required String label, MxStatTileEmphasis emphasis = MxStatTileEmphasis.plain, MxStatTileLayout layout = MxStatTileLayout.inline})`
  - `MxTextStyles.statValue(Color ink)`, `MxTextStyles.statLabel`

- [ ] **Step 1: Failing tests**

`test/shared/widgets/mx_stat_tile_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/shared/widgets/mx_stat_tile.dart';

import '../../support/widget_harness.dart';

void main() {
  testWidgets('one node reads the label, then the value', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpMx(tester, const MxStatTile(value: '12', label: 'Due'));

    expect(
      tester.getSemantics(find.byType(MxStatTile)),
      matchesSemantics(label: 'Due', value: '12'),
    );
    handle.dispose();
  });

  testWidgets('primary takes the primary ink, muted the variant ink, plain '
      'the surface ink', (tester) async {
    await pumpMx(
      tester,
      const Column(
        children: [
          MxStatTile(value: '1', label: 'a', emphasis: MxStatTileEmphasis.primary),
          MxStatTile(value: '2', label: 'b'),
          MxStatTile(value: '3', label: 'c', emphasis: MxStatTileEmphasis.muted),
        ],
      ),
    );
    Color? ink(String value) => tester.widget<Text>(find.text(value)).style?.color;
    const scheme = AppColorSchemes.light;

    expect(ink('1'), scheme.primary);
    expect(ink('2'), scheme.onSurface);
    expect(ink('3'), scheme.onSurfaceVariant);
  });

  testWidgets('the label is upper-cased and the value never clips at text '
      'scale 2', (tester) async {
    await pumpMx(
      tester,
      const SizedBox(
        width: 120,
        child: MxStatTile(
          value: '3 / 23',
          label: 'Wrong',
          layout: MxStatTileLayout.boxed,
        ),
      ),
      textScale: 2,
    );

    expect(find.text('WRONG'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
```

`mx_text_styles_test.dart` — add (follow its existing way of building an `MxTextStyles`):

```dart
  test('statValue is tabular in the ink given; statLabel is the overline',
      () {
    final styles = _styles(); // the file's existing factory for light
    final value = styles.statValue(const Color(0xFF123456));

    expect(value.color, const Color(0xFF123456));
    expect(value.fontFeatures, contains(const FontFeature.tabularFigures()));
    expect(styles.statLabel, styles.overline);
  });
```

- [ ] **Step 2: Run to see them fail**

Run: `flutter test test/shared/widgets/mx_stat_tile_test.dart test/core/theme/mx_text_styles_test.dart`
Expected: FAIL — `mx_stat_tile.dart` and `statValue` do not exist.

- [ ] **Step 3: Implement**

`mx_text_styles.dart`, near `overline`:

```dart
  /// A stat's figure (StatTile): the headline role at 700, tabular, tight
  /// line box, in the ink the tile's emphasis picks.
  TextStyle statValue(Color ink) =>
      AppTypography.withWeight(_texts.headlineSmall!, FontWeight.w700)
          .copyWith(
            height: _statValueHeight,
            fontFeatures: _tabular,
            color: ink,
          );

  /// A stat's label: the overline. The widget upper-cases it.
  TextStyle get statLabel => overline;
```

with `static const double _statValueHeight = 1.1;` among the constants.

`lib/shared/widgets/mx_stat_tile.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';

/// How a stat's figure is inked: [primary] draws the eye to what the
/// screen offers, [plain] states a fact, [muted] a figure nothing acts on.
enum MxStatTileEmphasis { primary, plain, muted }

/// [boxed]: left-aligned on its own surface, as the Study Entry hero draws
/// New and Due. [inline]: centred with no surface, as the session summary
/// hero draws its three stats.
enum MxStatTileLayout { boxed, inline }

/// A figure over its label (FE-A6 D17): screens 14 and 21. One semantics
/// node reads the label, then the value.
class MxStatTile extends StatelessWidget {
  const MxStatTile({
    super.key,
    required this.value,
    required this.label,
    this.emphasis = MxStatTileEmphasis.plain,
    this.layout = MxStatTileLayout.inline,
  });

  /// Already formatted by the caller: "12", "3 / 23".
  final String value;
  final String label;
  final MxStatTileEmphasis emphasis;
  final MxStatTileLayout layout;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final styles = context.textStyles;
    final ink = switch (emphasis) {
      MxStatTileEmphasis.primary => colors.primary,
      MxStatTileEmphasis.plain => colors.onSurface,
      MxStatTileEmphasis.muted => colors.onSurfaceVariant,
    };
    final isBoxed = layout == MxStatTileLayout.boxed;
    final figure = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: isBoxed
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      spacing: AppSpacing.micro,
      children: [
        Text(value, style: styles.statValue(ink)),
        Text(label.toUpperCase(), style: styles.statLabel),
      ],
    );
    final body = isBoxed
        ? DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.grouped),
              child: SizedBox(width: double.infinity, child: figure),
            ),
          )
        : figure;
    return Semantics(
      container: true,
      label: label,
      value: value,
      excludeSemantics: true,
      child: body,
    );
  }
}
```

- [ ] **Step 4: Gallery and golden**

In `gallery_status_section.dart` add a `Row` of two boxed tiles (`MxStatTile(value: '0', label: context.l10n.galleryNew, layout: MxStatTileLayout.boxed)`, `MxStatTile(value: '12', label: context.l10n.galleryDue, emphasis: MxStatTileEmphasis.primary, layout: MxStatTileLayout.boxed)`, each in `Expanded`) and a `Row` of three inline tiles (`'20'`/`galleryReviewed`, `'20'`/`galleryAnswered`, `'3 / 23'`/`galleryWrong`, each `Expanded`). Add whichever of `galleryDue`, `galleryReviewed`, `galleryAnswered`, `galleryWrong` is missing (`grep -n '"gallery\(Due\|Reviewed\|Answered\|Wrong\)"' lib/l10n/app_en.arb`) to both ARB files ("Due"/"Đến hạn", "Reviewed"/"Đã ôn", "Answered"/"Đã trả lời", "Wrong"/"Sai"), then `flutter gen-l10n`.

In `status_widgets_golden_test.dart` add a test `'MxStatTile'` with `expectThemedGoldens(tester, 'mx_stat_tile', …)` over the same two rows, using literal labels (`'New'`, `'Due'`, `'Reviewed'`, `'Answered'`, `'Wrong'`) as the file's other scenes do.

- [ ] **Step 5: Run, write the golden, commit**

Run: `flutter test test/shared/widgets/mx_stat_tile_test.dart test/core/theme/mx_text_styles_test.dart test/app/gallery_test.dart`
Expected: PASS.
Then: `TZ=UTC flutter test --tags golden --update-goldens test/shared/widgets/status_widgets_golden_test.dart`; open `mx_stat_tile_{light,dark}.png` next to `docs/shared/ui/screen-handoff/img/14-study-entry/eightBox-light.png` (hero tiles) and `img/21-session-summary/loaded-light.png` (hero stats); `git status` shows only the two new PNGs.

```bash
git add lib/shared/widgets/mx_stat_tile.dart lib/core/theme lib/app/gallery lib/l10n test/shared/widgets test/core/theme
git commit -m "feat(ui): MxStatTile, a figure over its label (FE-A6 D17)"
```

---

### Task 4: The Study Entry's overdue count and resumable session

**Files:**
- Create: `lib/features/study/data/datasources/resumable_session_data_source.dart`
- Modify: `lib/features/study/domain/models/study_entry_model.dart`, `lib/features/study/data/datasources/study_session_dao.dart`, `lib/features/study/data/datasources/study_view_dao.dart`, `lib/features/study/data/mappers/study_home_mapper.dart`, `lib/features/study/data/repositories/study_entry_repository_impl.dart`, `lib/features/study/data/repositories/study_home_repository_impl.dart`
- Test: `test/features/study/data/watch_entry_test.dart`, `test/features/study/data/session_endings_test.dart:371`

**Interfaces:**
- Consumes: `ResumableSession` (`study_home_model.dart`), `RoundProgress`, `startOfLocalDay` (already imported by the entry repository).
- Produces: `StudyEntry.overdueCardCount` (`int`), `StudyEntry.resumable` (`ResumableSession?`, replacing `resumableSessionId`); `ResumableSessionDataSource(StudyViewDao views, StudyQueueDao queue).read({String? deckId, required DateTime startOfToday}) → Future<ResumableSession?>`; `StudyViewDao.resumableSessionRow({String? deckId, required DateTime startOfToday})`.

- [ ] **Step 1: Failing tests**

In `watch_entry_test.dart`, replace every `.resumableSessionId` expectation: `expect((await entryOf(leaf.id)).resumableSessionId, id)` becomes

```dart
    final resumable = (await entryOf(leaf.id)).resumable!;
    expect(resumable.sessionId, id);
    expect(resumable.deckName, 'Lesson');
    expect(resumable.kind, SessionKind.learning);
    expect(resumable.mode, StudyMode.browse);
    expect(
      (resumable.progress!.completed, resumable.progress!.total),
      (0, 2),
    );
```

and every `….resumableSessionId, isNull` becomes `….resumable, isNull`. Do the same at `session_endings_test.dart:371` (`entry!.resumable`). Add the import of `session_kind_model.dart`. Then add:

```dart
  test('the entry counts the due cards that fell due before today as '
      'overdue: a card due earlier today is due, not overdue '
      '(FE-A6 D15, the BR-STUDY-068 boundary)', () async {
    final root = await decks.root('Korean');
    final leaf = await decks.sub(root.id, 'Lesson');
    await learned(leaf.id, 'yesterday', DateTime(2026, 9, 23, 20));
    await learned(leaf.id, 'early', DateTime(2026, 9, 24, 7));
    await learned(leaf.id, 'later', DateTime(2026, 9, 24, 18));

    final entry = await entryOf(leaf.id);

    expect((entry.dueCardCount, entry.overdueCardCount), (2, 1));
  });
```

- [ ] **Step 2: Run to see them fail**

Run: `flutter test test/features/study/data/watch_entry_test.dart test/features/study/data/session_endings_test.dart`
Expected: FAIL — `resumable` and `overdueCardCount` are not defined.

- [ ] **Step 3: The model**

In `study_entry_model.dart`: import `study_home_model.dart`; replace `required this.resumableSessionId` / `final String? resumableSessionId;` with

```dart
    required this.overdueCardCount,
    required this.resumable,
```

```dart
  /// The due cards whose due day is before today, the boundary the Library
  /// hero counts with (BR-STUDY-068); a part of [dueCardCount] (FE-A6 D15).
  final int overdueCardCount;

  /// This deck's open session, when Continue can take it up (BR-STUDY-075),
  /// with what the resume banner says of it (FE-A6 D15).
  final ResumableSession? resumable;
```

- [ ] **Step 4: The data layer**

`study_session_dao.dart`: `SubtreeCounts` gains `int overdueCount`; `subtreeCounts(String deckId, DateTime now)` becomes `subtreeCounts(String deckId, DateTime now, {required DateTime startOfToday})`, with the select line

```dart
          ' COUNT(CASE WHEN cs.learned_at IS NOT NULL AND cs.due_at < ?'
          '  THEN 1 END) AS overdue_count,'
```

after `due_count`, the variable `Variable<DateTime>(startOfToday)` in the matching place, and `overdueCount: row.read<int>('overdue_count')` in the record. Update every caller (`grep -rn "subtreeCounts(" lib test`).

`study_view_dao.dart`: delete `resumableSessionId`; give `resumableSessionRow` an optional deck:

```dart
  /// The newest open session Continue can take up (BR-STUDY-075): of
  /// [deckId] when given, of any deck otherwise (the Study tab's Resume
  /// card); null when none may be taken up.
  Future<ResumableRow?> resumableSessionRow({
    String? deckId,
    required DateTime startOfToday,
  }) async {
    final byDeck = deckId == null ? '' : ' AND s.deck_id = ?';
    final row = await _db
        .customSelect(
          'SELECT s.*, d.name AS deck_name$_resumable$byDeck$_newestFirst',
          variables: [
            Variable<DateTime>(startOfToday),
            if (deckId != null) Variable<String>(deckId),
          ],
          readsFrom: {_db.studySession, _db.deck, _db.studyQueueItems},
        )
        .getSingleOrNull();
    if (row == null) return null;
    return (
      session: _db.studySession.map(row.data),
      deckName: row.read<String>('deck_name'),
    );
  }
```

(check that `_resumable` already joins `deck d`, as the current `resumableSessionRow` reads `d.name`).

`resumable_session_data_source.dart`:

```dart
import 'package:memox/features/study/data/datasources/study_queue_dao.dart';
import 'package:memox/features/study/data/datasources/study_view_dao.dart';
import 'package:memox/features/study/data/mappers/study_home_mapper.dart';
import 'package:memox/features/study/domain/models/study_home_model.dart';

/// The session Continue can take up, with the round it serves, read as the
/// session screen counts it (spec D3): the Study tab's Resume card and the
/// Study Entry's resume banner share it (FE-A6 D15).
final class ResumableSessionDataSource {
  const ResumableSessionDataSource(this._views, this._queue);

  final StudyViewDao _views;
  final StudyQueueDao _queue;

  /// Of [deckId] when given, of any deck otherwise.
  Future<ResumableSession?> read({
    String? deckId,
    required DateTime startOfToday,
  }) async {
    final row = await _views.resumableSessionRow(
      deckId: deckId,
      startOfToday: startOfToday,
    );
    if (row == null) return null;
    final session = row.session;
    final head = await _queue.headRow(
      session.id,
      session.currentMode,
      session.cursor,
    );
    final round = head == null
        ? null
        : await _views.roundCounts(session.id, head.mode, head.round);
    return resumableSessionOf(row, round);
  }
}
```

`study_home_mapper.dart`: rename `_resumableOf` to the public `resumableSessionOf(ResumableRow row, RoundCounts? round)` (same body), and make `studyHomeOf` take `ResumableSession? resumable` instead of the row and round (`resumable: resumable`).

`study_home_repository_impl.dart`: build `_resumable = ResumableSessionDataSource(_views, _queue)` next to the DAOs; in `_snapshot` replace the resumable read and `_roundOf` with `resumable: await _resumable.read(startOfToday: startOfToday)`; delete `_roundOf`.

`study_entry_repository_impl.dart`: build the same data source; in `_entryOf`:

```dart
    final startOfToday = startOfLocalDay(now);
    final counts = await _dao.subtreeCounts(
      deckId,
      now,
      startOfToday: startOfToday,
    );
    return StudyEntry(
      schedulerType: type,
      cardLimit: options.cardLimit,
      newCardCount: counts.newCount,
      dueCardCount: counts.dueCount,
      overdueCardCount: counts.overdueCount,
      nextDueAt: counts.nextDueAt,
      reviewModes: reviewModeOptions(
        type,
        due,
        distinctMeaningCount: await _meaningsOf(root, due),
      ),
      resumable: await _resumable.read(
        deckId: deckId,
        startOfToday: startOfToday,
      ),
    );
```

- [ ] **Step 5: Run the study data tests**

Run: `dart run build_runner build --delete-conflicting-outputs && flutter test test/features/study`
Expected: PASS, including the Study Home tests unchanged (the shared reader returns what `_roundOf` did).

- [ ] **Step 6: Analyze, check the boundaries, commit**

Run: `flutter analyze && bash .claude/skills/flutter-architecture/scripts/check_architecture.sh`
Expected: clean.

```bash
git add lib/features/study test/features/study
git commit -m "feat(study): the entry reads its overdue count and resumable session (FE-A6 D15)"
```

---

### Task 5: The summary's answered cards and turns

**Files:**
- Modify: `lib/features/study/domain/models/study_session_view_model.dart`, `lib/features/study/data/datasources/study_view_dao.dart`, `lib/features/study/data/mappers/study_session_view_mapper.dart`
- Test: `test/features/study/data/watch_session_test.dart`

**Interfaces:**
- Produces: `SessionSummary.answeredCardCount` (`int`), `SessionSummary.turnCount` (`int`), `SessionSummary.hasAnswers` (`bool`, `turnCount > 0`).

**Ruling carried by this task:** a turn is a graded answer, a `review_log` row of the session; a Browse advance is not a turn (it writes no log, BR-MODE-006). Answered cards are the distinct cards with a turn. So a session left during Browse has `hasAnswers == false` and D18 applies.

- [ ] **Step 1: Failing tests**

In `watch_session_test.dart`, extend the two summary tests' records:

```dart
      expect(
        (
          summary.cardCount,
          summary.learnedCardCount,
          summary.wrongTurnCount,
          summary.answeredCardCount,
          summary.turnCount,
        ),
        (2, 2, 1, 2, 3),
      );
```

(learning: c1 again then good, c2 good — 3 self-assess turns on 2 cards) and `(2, null, 1, 2, 3)` for the review (one wrong recall, then two right). Add:

```dart
  test('a session left in Browse has answered nothing: no turn is counted '
      'for an advance (FE-A6 D18, BR-MODE-006)', () async {
    final (_, leaf) = await tree(SchedulerType.sm2);
    for (final id in ['c1', 'c2']) {
      await insertCard(db, id: id, deckId: leaf.id);
    }
    final id = await learning(leaf);
    await answer(id, const AdvanceAnswer());
    expect(
      await sessions.abandonSession(sessionId: id),
      isA<Ok<void, StudyRejection>>(),
    );

    final summary = (await viewOf(id)).summary!;

    expect(
      (summary.answeredCardCount, summary.turnCount, summary.hasAnswers),
      (0, 0, false),
    );
  });
```

(use the file's existing `tree`, `learning`, `answer`, `viewOf` helpers and its `sessions` repository; if `abandonSession` lives on a differently named field, use that).

- [ ] **Step 2: Run to see them fail**

Run: `flutter test test/features/study/data/watch_session_test.dart`
Expected: FAIL — the new fields are not defined.

- [ ] **Step 3: Implement**

`SessionSummary`: add `required this.answeredCardCount, required this.turnCount` and

```dart
  /// The distinct cards with a graded turn; a Browse advance is no turn
  /// (BR-MODE-006; FE-A6 D11).
  final int answeredCardCount;

  /// The session's graded turns, its `review_log` rows (FE-A6 D11).
  final int turnCount;

  /// Nothing was answered: the summary shows no stats (FE-A6 D18).
  bool get hasAnswers => turnCount > 0;
```

`study_view_dao.dart`: `SummaryCounts` gains `int answeredCount, int turnCount`; `summaryCounts` adds to its select

```dart
          ' (SELECT COUNT(DISTINCT card_id) FROM review_log'
          '  WHERE session_id = ?) AS answered_count,'
          ' (SELECT COUNT(*) FROM review_log WHERE session_id = ?)'
          '  AS turn_count,'
```

before the `wrong_count` subquery, the two `Variable<String>(sessionId)` in the matching places, and `answeredCount: row.read<int>('answered_count'), turnCount: row.read<int>('turn_count')` in the record.

`study_session_view_mapper.dart`: pass `answeredCardCount: counts.answeredCount, turnCount: counts.turnCount` to `SessionSummary`.

- [ ] **Step 4: Run and commit**

Run: `flutter test test/features/study`
Expected: PASS.

```bash
git add lib/features/study test/features/study
git commit -m "feat(study): the summary counts answered cards and turns (FE-A6 D11, D18)"
```

---

### Task 6: Records

**Files:**
- Modify: `docs/wbs_FE.md` (FE-A6 row: evidence "P1a: a link to `superpowers/plans/2026-09-26-study-p1a-foundations.md`", status `đang làm`), `docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md` §9 (a row: "Success and caution/danger glyph inks are pulled toward `onSurface` for 3:1 and 4.5:1; the kit's pure hues fail on their soft tints | FE-A6 D14"), `docs/features/study/README.md` or `data.md` if either documents `StudyEntry`/`SessionSummary` fields (`grep -rn "resumableSessionId\|wrongTurnCount" docs`), `docs/_generated/` (regenerated).

- [ ] **Step 1: Edit, regenerate, check**

Run: `python3 tools/docs/generate.py && python3 tools/docs/check.py`
Expected: `PASS — 0 error(s)`, warnings not above 57.

- [ ] **Step 2: Gate and commit**

Run: `bash .claude/skills/flutter-workflow/scripts/dod_check.sh` and `TZ=UTC flutter test --tags golden`
Expected: `✓ mechanical gates passed`; all goldens pass.

```bash
git add docs
git commit -m "docs(study): P1a records — WBS, UI-base §9 ink deviation (FE-A6)"
```

# One primary for both themes, and a primary ink — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the dark primary the brand indigo `#5265F5` with white ink. Every
primary-coloured text, icon, focus ring and off-fill spinner moves to a new
`primaryInk`, which reads at ≥ 4.5:1 on every ground in both themes.

**Architecture:**
- `primaryInk` is one derivation in `MxDerivedColors`: `Color.lerp(primary, onSurface,
  t)`, with t 0.45 in dark and 0.15 in light.
- A static `MxDerivedColors.primaryInkOf(ColorScheme)` is the single source. The
  `primaryInk` field, `MxTextStyles` and `AppComponentThemes` all call it.
- Widgets swap `colors.primary` for `context.derivedColors.primaryInk` where the colour
  is ink, and keep `primary` where it is a fill, edge, indicator or tint.

**Tech Stack:** Flutter 3.47.5, Dart 3.13, flutter_test.

**Spec:** `docs/superpowers/specs/2026-09-27-shared-primary-and-primary-ink-design.md`

## Global Constraints

- Dark `primary` is `AppColorSchemes.seed` (`0xFF5265F5`). Dark `onPrimary` is
  `0xFFFFFFFF`.
- `primaryInk` = `Color.lerp(scheme.primary, scheme.onSurface, t)`: t `0.45` in dark,
  `0.15` in light. It must be ≥ 4.5:1 on every `surface*` ground of its theme, and on
  primary at 8–20 % over those grounds.
- Unchanged:
  - light `inversePrimary` `0xFF8B9AFF`, and dark `inversePrimary` = seed;
  - `statusReviewing`;
  - `primaryContainer` / `onPrimaryContainer`.
- **Ink** (text, icon, focus ring, spinner off a fill) → `primaryInk`. **Fill, edge,
  indicator, tint** → `primary`.
- No literal colours in widgets. New numbers are named `static const`.
- Goldens are rewritten only in the Linux container, after the unmodified master is
  shown green here.

## Review Focus

1. **A solid `MxBadge` in a non-primary tone** would get white ink on mint or amber.
   Task 3 asserts that solid means primary tone.
2. **Focus on a `surfaceContainer` ground.** The ring must be `primaryInk`, which reaches
   ≥ 4.5:1 there, not `primary`, which reaches 2.90:1. Task 2 tests the component
   themes' focus colour.
3. **`MxStudyTopBar` with a caller accent.** An explicit accent (a mode colour) must
   still ink its own badge text, not `primaryInk`. Task 3 tests both paths.
4. **Light mode text that was primary** moves to a darker indigo. It must still be
   the indigo family, not `onSurface`. Task 1 tests that `primaryInk` light differs
   from both primary and `onSurface`.
5. **A spinner on a primary fill** keeps `onPrimary`, now white. Task 3 tests both
   spinner paths.

---

### Task 1: The tokens — dark primary, `onPrimary`, `primaryInk`

**Files:**
- Modify: `lib/core/theme/app_color_schemes.dart:60-61` (dark `primary`, `onPrimary`)
- Modify: `lib/core/theme/mx_derived_colors.dart` (field, constructor, `resolve`,
  constants, `primaryInkOf`)
- Test: `test/core/theme/app_color_schemes_test.dart`,
  `test/core/theme/mx_derived_colors_test.dart`, `test/core/theme/mx_semantic_colors_test.dart`
  (unchanged, but it must still pass)

**Interfaces:**
- Produces:
  - `static Color MxDerivedColors.primaryInkOf(ColorScheme scheme)`;
  - `final Color MxDerivedColors.primaryInk`, reached through
    `context.derivedColors.primaryInk`.

- [ ] **Step 1: Write the failing tests**

`app_color_schemes_test.dart`: in `_v3Roles`, change the dark halves of two entries:

```dart
  'primary': (0xFF5265F5, 0xFF5265F5),
  'onPrimary': (0xFFFFFFFF, 0xFFFFFFFF),
```

Leave `'inversePrimary': (0xFF8B9AFF, 0xFF5265F5)` as it is (D4). Update the comment above
`_v3Roles` to say the dark primary pair follows spec 2026-09-27 D1, not the kit.

`mx_derived_colors_test.dart`:
- Replace the dark expectations of the two primary-derived tests:

```dart
  test('surfaceHero blends over surfaceBright in light, surface in dark', () {
    // Light: #5265F5 at 5% over #FFFFFF. Dark: #5265F5 at 12% over #0A0E27.
    expect(light.surfaceHero, isColorCloseTo(0xFFF6F7FE));
    expect(dark.surfaceHero, isColorCloseTo(0xFF131840));
  });
```

```dart
  test('ghostBorder is primary at 14% light, 16% dark', () {
    expect(light.ghostBorder, isColorCloseTo(0x245265F5));
    expect(dark.ghostBorder, isColorCloseTo(0x295265F5));
  });
```

- Add, using the file's existing `_ratio` helper:

```dart
  group('primaryInk (spec 2026-09-27 D2)', () {
    for (final (name, scheme, derived) in [
      ('light', AppColorSchemes.light, light),
      ('dark', AppColorSchemes.dark, dark),
    ]) {
      final grounds = [
        scheme.surface,
        scheme.surfaceBright,
        scheme.surfaceContainerLowest,
        scheme.surfaceContainerLow,
        scheme.surfaceContainer,
        scheme.surfaceContainerHigh,
      ];
      test('$name: 4.5:1 on every ground and on primary tints over it', () {
        for (final ground in grounds) {
          expect(_ratio(derived.primaryInk, ground), greaterThanOrEqualTo(4.5));
          for (final alpha in [0.08, 0.10, 0.12, 0.16, 0.20]) {
            final tint = Color.alphaBlend(
              scheme.primary.withValues(alpha: alpha),
              ground,
            );
            expect(_ratio(derived.primaryInk, tint), greaterThanOrEqualTo(4.5));
          }
        }
      });
      test('$name: an indigo between primary and onSurface', () {
        expect(derived.primaryInk, isNot(scheme.primary));
        expect(derived.primaryInk, isNot(scheme.onSurface));
        expect(derived.primaryInk, MxDerivedColors.primaryInkOf(scheme));
      });
    }
  });
```

- [ ] **Step 2: Run them to verify they fail**

Run: `flutter test test/core/theme/app_color_schemes_test.dart test/core/theme/mx_derived_colors_test.dart`
Expected: the scheme test fails on dark primary (`8B9AFF`); the derived test fails to
compile because `primaryInk` and `primaryInkOf` do not exist.

- [ ] **Step 3: Implement**

`app_color_schemes.dart`, in `dark`:

```dart
        // The brand indigo in both themes (spec 2026-09-27 D1; kit: #8B9AFF).
        // Primary text and icons read in MxDerivedColors.primaryInk instead.
        primary: seed,
        onPrimary: const Color(0xFFFFFFFF),
```

`mx_derived_colors.dart`:
- add `required this.primaryInk,` to the private constructor;
- in `resolve`, add `primaryInk: primaryInkOf(scheme),`;
- add the constants beside the other ink mixes:

```dart
  static const double _primaryInkLight = 0.15;
  static const double _primaryInkDark = 0.45;
```

- add the static and the field:

```dart
  /// Primary as TEXT, icon, focus ring or off-fill spinner: primary pulled
  /// toward onSurface until it reads at 4.5:1 on every ground and primary
  /// tint (spec 2026-09-27 D2). Fills, edges and tints keep primary. The
  /// one source for MxTextStyles and the component themes too.
  static Color primaryInkOf(ColorScheme scheme) => _ink(
    scheme.primary,
    scheme,
    scheme.brightness == Brightness.dark ? _primaryInkDark : _primaryInkLight,
  );
```

```dart
  /// Primary text, icons and focus rings, never a fill.
  final Color primaryInk;
```

If the 4.5 test fails for a ground at these mixes, raise that theme's mix in 0.05
steps until it passes. Ledger it as a ruling with the value.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/core/theme`
Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git add lib/core/theme/app_color_schemes.dart lib/core/theme/mx_derived_colors.dart test/core/theme
git commit -m "feat(theme): dark primary is the brand indigo; primaryInk for text"
```

---

### Task 2: Text styles and component themes ink in `primaryInk`

**Files:**
- Modify: `lib/core/theme/mx_text_styles.dart` (`navLabel`, `disclosureLabel`,
  `rowTitleMatch`, `requiredMarker`, `removableTagLabel`)
- Modify: `lib/core/theme/app_component_themes.dart:51,71,120,132,157` (the focused
  field edge, focus colours, and the outlined and text button inks)
- Test: `test/core/theme/mx_text_styles_test.dart`,
  `test/core/theme/app_component_themes_test.dart`

**Interfaces:**
- Consumes: `MxDerivedColors.primaryInkOf(ColorScheme)` (Task 1).

- [ ] **Step 1: Write the failing tests**

`mx_text_styles_test.dart` (the file's `styles` and `scheme` are the light pair):

```dart
  test('primary-coloured styles ink in primaryInk (spec 2026-09-27 D2)', () {
    final ink = MxDerivedColors.primaryInkOf(scheme);
    expect(styles.navLabel(isSelected: true).color, ink);
    expect(styles.disclosureLabel.color, ink);
    expect(styles.rowTitleMatch.color, ink);
    expect(styles.requiredMarker.color, ink);
    expect(styles.removableTagLabel.color, ink);
  });
```

If the file is at or near the guard's 400-line limit, put this test in a new
`test/core/theme/mx_text_styles_ink_test.dart` with the same setup as the first lines
of `mx_text_styles_test.dart`.

`app_component_themes_test.dart`: add a test that, for both themes, the outlined and
text button `foregroundColor` resolves to `MxDerivedColors.primaryInkOf(scheme)`, and
that the input decoration's focused border colour is the same. Follow the file's
existing way of building the themes and resolving `WidgetStateProperty` values.

- [ ] **Step 2: Run them to verify they fail**

Run: `flutter test test/core/theme/mx_text_styles_test.dart test/core/theme/app_component_themes_test.dart`
Expected: FAIL, because the styles and themes still use `scheme.primary`.

- [ ] **Step 3: Implement**

`mx_text_styles.dart`: add `import 'package:memox/core/theme/mx_derived_colors.dart';`,
add a getter `Color get _primaryInk => MxDerivedColors.primaryInkOf(_scheme);`, and
replace `_scheme.primary` with `_primaryInk` in the five styles. Update each doc
comment from "primary" to "primaryInk".

`app_component_themes.dart`: add the same import. At lines 51, 71, 120, 132 and 157,
replace `scheme.primary` with `MxDerivedColors.primaryInkOf(scheme)`. Keep line 105,
the elevated button fill, on `scheme.primary` with `scheme.onPrimary`.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/core/theme --exclude-tags golden`
Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git add lib/core/theme test/core/theme
git commit -m "feat(theme): text styles and component themes ink in primaryInk"
```

---

### Task 3: Shared widgets ink in `primaryInk`; solid badge is primary only

**Files (modify):**
- `lib/shared/widgets/mx_button.dart`: the outline tone ink, line 167, and
  `focusColor`, line 100.
- Focus colours: `mx_chip_trigger.dart:36`, `mx_filter_chip.dart:59`,
  `mx_stepper.dart:123`, `mx_toggle.dart:60`; the focus border in `mx_row_ink.dart:67`.
- `mx_action_sheet_command_row.dart:50`: the non-destructive ink. The tile tint on
  line 75 stays `primary`.
- `mx_bottom_nav.dart:150`, the selected icon. The label already comes from `navLabel`
  (Task 2); the pill tint stays `primary`.
- `mx_badge.dart`: the tinted primary ink, plus the solid-tone assert.
- `mx_workload_breakdown_line.dart:51`: the "today" term.
- `mx_search_field.dart:137`: the focused icon.
- `mx_empty_state.dart`: the primary tone's glyph. Its tint stays `primary`.
- `mx_stat_tile.dart:37`: the primary emphasis.
- `mx_spinner.dart:66`: the off-fill arc.
- `mx_icon_tile.dart`: the tinted tone's glyph when no seed is given.
- `mx_study_top_bar.dart`: the badge text when there is no accent.

**Tests:** `test/shared/widgets/` — `mx_button_test.dart`, `mx_bottom_nav_test.dart`,
`mx_badge_test.dart`, `mx_action_sheet_command_row_test.dart`,
`mx_study_top_bar_test.dart`, `mx_spinner_test.dart`, `mx_search_field_test.dart`, plus
any existing assertion that pinned `scheme.primary` for an ink.

**Interfaces:**
- Consumes: `context.derivedColors.primaryInk` (Task 1).

- [ ] **Step 1: Write the failing tests**

In each file, next to the existing tone and ink tests, and with `context`/`scheme` as
each file already builds them:

```dart
  // mx_bottom_nav_test.dart — replace the selected-destination colour checks:
  final ink = MxDerivedColors.primaryInkOf(scheme);
  expect(tester.widget<Icon>(find.byIcon(AppIcons.studySelected)).color, ink);
  expect(tester.widget<Text>(find.text('Study')).style!.color, ink);
```

```dart
  // mx_button_test.dart
  testWidgets('outline ink is primaryInk; the primary fill keeps primary', (
    tester,
  ) async {
    await pumpMx(
      tester,
      Column(
        children: [
          MxButton(
            label: 'Outline',
            tone: MxButtonTone.outline,
            onPressed: () {},
          ),
          MxButton(label: 'Fill', onPressed: () {}),
        ],
      ),
    );
    final ink = MxDerivedColors.primaryInkOf(scheme);
    final outline = tester.widget<Text>(find.text('Outline'));
    expect(DefaultTextStyle.of(tester.element(find.text('Outline'))).style.color ??
        outline.style?.color, ink);
    final fill = tester.widget<Material>(
      find.descendant(
        of: find.widgetWithText(MxButton, 'Fill'),
        matching: find.byType(Material),
      ).first,
    );
    expect(fill.color, scheme.primary);
  });
```

```dart
  // mx_badge_test.dart
  testWidgets('a tinted primary badge inks in primaryInk over a primary tint', (
    tester,
  ) async {
    await pumpMx(tester, const MxBadge(label: '23 due'));
    final text = tester.widget<Text>(find.text('23 due'));
    expect(text.style!.color, MxDerivedColors.primaryInkOf(scheme));
  });

  test('a solid badge is primary only (spec 2026-09-27 D5)', () {
    expect(
      () => MxBadge(label: 'x', tone: MxBadgeTone.mastery, isSolid: true),
      throwsAssertionError,
    );
  });
```

```dart
  // mx_study_top_bar_test.dart
  // Without an accent the badge text is primaryInk; with an accent it is the
  // accent. Pump the bar as the file's existing tests do, once with no accent
  // and once with `accent: const Color(0xFF00AA55)`, and read the badge Text's
  // style colour.
```

```dart
  // mx_spinner_test.dart
  // isOnFill: true paints onPrimary (white in dark), false paints primaryInk.
  // Read `_RingPainter.color` the way the file's existing tests read it.
```

```dart
  // mx_search_field_test.dart
  // After focusing the field, the leading search Icon's colour is primaryInk.
```

```dart
  // mx_action_sheet_command_row_test.dart
  // A non-destructive row's label Text colour and Icon colour are primaryInk;
  // the tile's tint is still primary at the file's _tileTint.
```

- [ ] **Step 2: Run them to verify they fail**

Run: `flutter test test/shared/widgets --exclude-tags golden`
Expected: the new assertions fail, because the widgets still use `colors.primary`.

- [ ] **Step 3: Implement**

In every file listed above, replace `colors.primary` or `context.colors.primary` with
`context.derivedColors.primaryInk` at the named ink lines only. For the non-obvious
ones:

- **`mx_badge.dart`:**
  - constructor assert:
    `assert(!isSolid || tone == MxBadgeTone.primary, 'a solid badge is primary: only onPrimary is guaranteed on its fill')`;
  - the ink switch becomes
    `(false, MxBadgeTone.primary) => context.derivedColors.primaryInk,` before
    `(false, _) => toneColor,`.
- **`mx_empty_state.dart`:** `_Tile` gets a second colour, `ink`, for the glyph. The
  tint keeps `color`. `build` passes
  `ink: tone == MxEmptyStateTone.primary ? context.derivedColors.primaryInk : toneColor`.
- **`mx_icon_tile.dart`:** the tinted pair becomes
  `(tinted.withValues(alpha: tint), seed ?? context.derivedColors.primaryInk)`.
- **`mx_study_top_bar.dart`:** keep `accentColor` for the badge tint and the progress
  fill. Add `final accentInk = accent ?? context.derivedColors.primaryInk;` and use it
  in `styles.studyBadge(accentInk)`.
- **`mx_spinner.dart`:**
  `color: widget.isOnFill ? colors.onPrimary : context.derivedColors.primaryInk`.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/shared test/core --exclude-tags golden`
Expected: all pass. An old test that pinned `scheme.primary` for an ink is updated in
this task to `primaryInk`. A test that pinned a fill stays.

- [ ] **Step 5: Commit**

```bash
git add lib/shared test/shared
git commit -m "feat(ui): shared widgets ink in primaryInk; a solid badge is primary only"
```

---

### Task 4: Feature call sites

**Files:**
- Modify: `lib/features/card/presentation/widgets/items/card_add_details_widget.dart:27`
  (the glyph `IconThemeData` colour)
- Modify: `lib/features/card/presentation/widgets/items/card_removable_tag_chip_widget.dart:55`
  (the glyph; line 43, the tint, stays)
- Test: the card editor tests that already pump these widgets (find them with
  `grep -rln "CardAddDetailsWidget\|CardRemovableTagChipWidget" test`)

**Interfaces:**
- Consumes: `context.derivedColors.primaryInk`.

- [ ] **Step 1: Write the failing test**

In the test file that pumps `CardAddDetailsWidget`, assert that the add-details glyph
(`Icon` inside it) has colour `MxDerivedColors.primaryInkOf(scheme)`. In the one that
pumps `CardRemovableTagChipWidget`, assert the same for its remove glyph.

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test <those files>`
Expected: FAIL (the glyphs are `primary`).

- [ ] **Step 3: Implement**

Replace `colors.primary` with `context.derivedColors.primaryInk` at the two lines.

- [ ] **Step 4: Run to verify it passes**

Run: `flutter test test/features/card --exclude-tags golden`
Expected: all pass.

- [ ] **Step 5: Sweep, then commit**

Run: `grep -rn "colors\.primary\b\|scheme\.primary\b" lib --include=*.dart`

Classify every remaining hit by the spec's rule: text, icon or focus → `primaryInk`;
fill, edge, indicator or tint → `primary`. Fix any ink left on `primary`, with a test
if it is a shared widget. Then:

```bash
git add lib/features test/features
git commit -m "feat(card): add-details and tag-chip glyphs ink in primaryInk"
```

---

### Task 5: Register, skill note, goldens, gate

**Files:**
- Modify: `docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md` (§9, after the
  last row)
- Modify: `.claude/skills/flutter-design-system/SKILL.md` (one short rule)
- Modify: goldens under `test/**/goldens/`

- [ ] **Step 1: Register rows.** Read the last row number N in §9 and add:

```markdown
| N+1 | Dark `primary` is the brand indigo `#5265F5`, as in light, with white `onPrimary` (kit: `#8B9AFF` with `#11173A`) | owner 2026-09-27, spec shared-primary D1 |
| N+2 | `primaryInk` (primary pulled toward onSurface: dark 0.45, light 0.15) inks primary text, icons, focus rings and off-fill spinners; the kit inks them in primary, which fails 4.5:1 | owner 2026-09-27, D2 |
| N+3 | Dark `primary-soft`, `primary-border` and `surface-hero` follow the new primary (the kit mixes `#8B9AFF`); a solid `MxBadge` is primary only | owner 2026-09-27, D1, D5 |
```

- [ ] **Step 2: Skill note.** In `flutter-design-system/SKILL.md`, where colour roles
  are described, add one line: "Primary as text, icon or focus ring is
  `context.derivedColors.primaryInk`; `colors.primary` is for fills, edges, indicators
  and tints (spec 2026-09-27)."

- [ ] **Step 3: Prove the container.** In a scratch worktree of `origin/master`:

```bash
export FLUTTER_ROOT=/root/.flutter-sdk/3.47.5/flutter
flutter pub get && flutter gen-l10n && dart run build_runner build --delete-conflicting-outputs
bash .claude/skills/flutter-workflow/scripts/prepare_test_fonts.sh
TZ=UTC flutter test --tags golden
```

Expected: `All tests passed!`. Otherwise stop and report.

- [ ] **Step 4: Regenerate and check.** On the branch:

```bash
TZ=UTC flutter test --tags golden --update-goldens
```

Then build a pixel-diff table for every changed PNG against `HEAD`. Open old/new pairs
by eye for at least:
- dark: card list, trash selection, session summary, library, study entry, search, a
  dialog, a bottom sheet;
- light: card list, search (the `rowTitleMatch`).

Expected, and nothing else:
- dark fills are the deeper indigo with white ink;
- primary text and icons are a lighter indigo in dark and a slightly deeper one in
  light.

- [ ] **Step 5: Verify and gate**

```bash
TZ=UTC flutter test --tags golden
bash .claude/skills/flutter-workflow/scripts/dod_check.sh
```

Expected: `All tests passed!` and `✓ mechanical gates passed`.

- [ ] **Step 6: Commit**

```bash
git add docs .claude/skills/flutter-design-system/SKILL.md test
git commit -m "test(ui): goldens for the shared primary and primaryInk; register rows"
```

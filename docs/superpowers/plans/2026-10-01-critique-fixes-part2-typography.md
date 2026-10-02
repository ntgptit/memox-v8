# Critique 2026-09-30 part 2: label roles Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Split the one all-caps overline into three roles (section label, eyebrow, field label) and stop upper-casing user data.

**Architecture:** Two new styles (`eyebrow`, `fieldLabel`) and a re-sized `requiredMarker` in `MxTextStyles`; each call site switches to the role the spec names. A study-feature helper upper-cases the app's words around a deck name. Search drops its results header.

**Tech Stack:** Flutter 3.47.5, flutter_test, ARB l10n (`flutter gen-l10n`), goldens in the Linux container.

**Spec:** `docs/superpowers/specs/2026-10-01-critique-fixes-part2-typography-design.md` (owner rulings P1–P4).

## Global Constraints

- Section label: `overline`, 13/700, 0.6 tracking, tabular, onSurface, upper-cased; only above a list or settings group (P1).
- Eyebrow: 12/600, 0.8 tracking, tabular, onSurfaceVariant; the app's words upper-cased, user data as typed (P2).
- Field label: 14/600, onSurface, sentence case; "Required" is `rowDescription` in primary ink (P3).
- Never upper-case user data; search shows no "Results for" header (P4).
- `semanticsLabel` keeps the plain sentence wherever the visible text is upper-cased.
- A removed ARB key goes from both `app_en.arb` and `app_vi.arb`; a new key lists placeholders before its description; run `flutter gen-l10n` after ARB edits.
- No layout change beyond line heights; commits in English with the two attribution lines.

## Review Focus

1. A deck name with Vietnamese diacritics or mixed case ("Nhà hàng", "TOPIK I") must appear exactly as typed in the summary and the context line, in both locales: Task 4 tests "Nhà hàng" and "TOPIK I" in en and vi.
2. A deck name containing a placeholder-like sequence must not break the helper: Task 4's helper uses a private-use code point and a test with a name containing "·".
3. The screen reader must hear the plain sentence for every eyebrow (no letter-by-letter caps): Tasks 3–5 keep `semanticsLabel`, and Task 4 asserts the summary's semantics label.
4. The Required caption must stay legible beside a 14/600 label at large text: Task 6 pins `requiredMarker` to `rowDescription`'s size.
5. Search with only cards or only decks must still show its group headers: Task 7 asserts "CARDS" with no decks.

---

### Task 1: The styles

**Files:**
- Modify: `lib/core/theme/mx_text_styles.dart:287-320` (overline doc, `compactOverline`, `statLabel`, `requiredMarker`; add `eyebrow`, `fieldLabel`)
- Modify: `test/core/theme/mx_text_styles_test.dart:252-253,425-432`
- Create: `test/core/theme/mx_text_styles_label_test.dart`
- Modify: `DESIGN.md` (Typography: the Section Label line, line 276; the all-caps Don't, line 380)

**Interfaces:**
- Produces: `TextStyle get eyebrow`, `TextStyle get fieldLabel` on `MxTextStyles`; `requiredMarker` = `rowDescription.copyWith(color: primaryInk)`; `statLabel` = `eyebrow`. `compactOverline` is deleted in Task 5 (its callers move there), not here.

- [ ] **Step 1: Write the failing test** — `test/core/theme/mx_text_styles_label_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/mx_derived_colors.dart';
import 'package:memox/core/theme/mx_text_styles.dart';

// The three label roles (critique 2026-09-30 part 2, P1–P3).
void main() {
  final theme = buildLightTheme();
  final scheme = AppColorSchemes.light;
  final styles = MxTextStyles(theme.textTheme, scheme);

  test('eyebrow: 12/600 at 0.8, tabular, onSurfaceVariant (P2)', () {
    final eyebrow = styles.eyebrow;
    expect(eyebrow.fontSize, 12);
    expect(eyebrow.fontWeight, FontWeight.w600);
    expect(eyebrow.letterSpacing, 0.8);
    expect(eyebrow.color, scheme.onSurfaceVariant);
    expect(eyebrow.fontFeatures, contains(const FontFeature.tabularFigures()));
  });

  test('field label: 14/600 onSurface (P3)', () {
    expect(styles.fieldLabel.fontSize, 14);
    expect(styles.fieldLabel.fontWeight, FontWeight.w600);
    expect(styles.fieldLabel.color, scheme.onSurface);
  });

  test('Required is the optional caption in primary ink (P3)', () {
    expect(styles.requiredMarker.fontSize, styles.rowDescription.fontSize);
    expect(styles.requiredMarker.fontWeight, styles.rowDescription.fontWeight);
    expect(styles.requiredMarker.color, MxDerivedColors.primaryInkOf(scheme));
  });

  test('a stat label is the eyebrow (P1)', () {
    expect(styles.statLabel, styles.eyebrow);
  });
}
```

In `mx_text_styles_test.dart`, change the statValue test's last line to drop the `statLabel` expectation (the new file owns it) and rename it `'statValue is tabular in the ink given (FE-A6 D17)'`.

- [ ] **Step 2: Run** `flutter test test/core/theme/mx_text_styles_label_test.dart` — Expected: FAIL to compile (`eyebrow`, `fieldLabel` undefined).

- [ ] **Step 3: Implement** in `mx_text_styles.dart`:
  - add constants `static const double _eyebrowSize = 12;`, `static const double _eyebrowTracking = 0.8;`, `static const double _fieldLabelSize = 14;` beside `_overlineSize`;
  - change the overline doc's first line to `/// Section label: the overline that introduces a list or settings group, and nothing else (critique 2026-09-30 part 2, P1): 13/700, ...`;
  - add after `compactOverline`:

```dart
  /// Eyebrow: the context line above a big title or number (critique
  /// 2026-09-30 part 2, P2). The caller upper-cases the app's own words,
  /// never user data.
  TextStyle get eyebrow =>
      AppTypography.withWeight(_texts.labelSmall!, FontWeight.w600).copyWith(
        fontSize: _eyebrowSize,
        letterSpacing: _eyebrowTracking,
        fontFeatures: _tabular,
        color: _scheme.onSurfaceVariant,
      );

  /// Field label: names an input or a read-only field, in sentence case
  /// (critique 2026-09-30 part 2, P3).
  TextStyle get fieldLabel =>
      AppTypography.withWeight(_texts.labelLarge!, FontWeight.w600).copyWith(
        fontSize: _fieldLabelSize,
        color: _scheme.onSurface,
      );
```

  - `statLabel` doc `/// A stat's label: the eyebrow. The widget upper-cases it.` and body `=> eyebrow;`
  - `requiredMarker` doc `/// A field's "Required" caption: the optional caption's size in primary ink (critique 2026-09-30 part 2, P3).` and body `=> rowDescription.copyWith(color: _primaryInk);`
  - `DESIGN.md` line 276 becomes three lines:
    - `- **Section Label** (700, 13px, 0.6px, tabular, upper-cased by the widget): the overline that introduces a list or settings group, and nothing else.`
    - `- **Eyebrow** (600, 12px, 0.8px, tabular, \`on-surface-variant\`): the context line above a big title or number; the app's own words upper-cased, user data as typed (critique 2026-09-30 part 2).`
    - `- **Field Label** (600, 14px, \`on-surface\`, sentence case): names an input or a read-only field; "Required" is the optional caption's size in primary ink.`
  - `DESIGN.md` line 380: `- **Don't** introduce an all-caps overline above headings as decoration; the section label introduces a list or settings group, the eyebrow is the one context line above a title or number, and user data is never upper-cased.`

- [ ] **Step 4: Run** `flutter test test/core/theme/` — Expected: PASS (`mx_text_styles_ink_test` still pins `requiredMarker.color`).

- [ ] **Step 5: Commit** `feat(theme): eyebrow and field label styles (part 2 P1-P3)`.

### Task 2: Shared widgets — `MxDotOverline` and `MxStatTile`

**Files:**
- Modify: `lib/shared/widgets/mx_dot_overline.dart:35`, `lib/shared/widgets/mx_stat_tile.dart:58` (already `statLabel`, so only the test changes for the stat tile)
- Test: `test/shared/widgets/mx_dot_overline_test.dart`, `test/shared/widgets/mx_stat_tile_test.dart`

**Interfaces:** Consumes `eyebrow`, `statLabel` (Task 1).

- [ ] **Step 1: Write the failing tests.** Append to `mx_dot_overline_test.dart` inside `main()` (import `package:memox/core/theme/theme_context.dart` if missing):

```dart
  testWidgets('the label is an eyebrow (critique 2026-09-30 part 2, P2)', (
    tester,
  ) async {
    await pumpMx(tester, const MxDotOverline(label: 'Continue studying'));
    final label = find.text('CONTINUE STUDYING');
    expect(
      tester.widget<Text>(label).style,
      tester.element(label).textStyles.eyebrow,
    );
  });
```

Append to `mx_stat_tile_test.dart`:

```dart
  testWidgets('the label is an eyebrow (critique 2026-09-30 part 2, P1)', (
    tester,
  ) async {
    await pumpMx(tester, const MxStatTile(value: '3', label: 'Wrong turns'));
    final label = find.text('WRONG TURNS');
    expect(
      tester.widget<Text>(label).style,
      tester.element(label).textStyles.eyebrow,
    );
  });
```

(If `MxDotOverline`/`MxStatTile` take other required arguments, pass the ones the file's first test passes.)

- [ ] **Step 2: Run** both files — Expected: the dot-overline test FAILS (overline); the stat-tile test PASSES already through Task 1's `statLabel`, which pins it.

- [ ] **Step 3: Implement** `mx_dot_overline.dart`: `style: context.textStyles.eyebrow,` and its doc `/// ... an eyebrow (critique 2026-09-30 part 2).`

- [ ] **Step 4: Run** `flutter test test/shared/widgets/` — Expected: PASS.

- [ ] **Step 5: Commit** `feat(shared): dot overline and stat label are eyebrows (part 2)`.

### Task 3: Study eyebrows (13, 14, 16–20)

**Files:**
- Modify: `lib/features/study/presentation/widgets/sections/study_home_workload_widget.dart:45-57` (icon ink and text style)
- Modify: `.../sections/study_entry_hero_widget.dart:46`, `.../support/study_face_card_widget.dart:45`, `.../sections/study_browse_widget.dart:268`, `.../support/session_context_line_widget.dart:26`
- Test: `test/features/study/presentation/study_home_screen_test.dart`, `study_entry_screen_test.dart`, `study_support_widgets_test.dart`

**Interfaces:** Consumes `eyebrow`.

- [ ] **Step 1: Write the failing tests.** Add a test to each file, arranged exactly as the named existing test, then:
  - `study_home_screen_test.dart`, after the arrange of `'loaded: the Resume card, the workload hero …'`:

```dart
    final waiting = find.text('WAITING FOR YOU');
    expect(
      tester.widget<Text>(waiting).style,
      tester.element(waiting).textStyles.eyebrow,
    );
    // The glyph follows the eyebrow, not the Required ink (part 2, P2).
    final glyph = find.byIcon(AppIcons.dueNow);
    expect(
      IconTheme.of(tester.element(glyph)).color,
      tester.element(glyph).colors.onSurfaceVariant,
    );
```

  - `study_entry_screen_test.dart`, in a test that shows the SM-2 hero: `final overline = find.text('SM-2'); expect(tester.widget<Text>(overline).style, tester.element(overline).textStyles.eyebrow);`
  - `study_support_widgets_test.dart`: pump `SessionContextLineWidget(text: 'x · Review')` and the face card as the file's existing face-card test does; assert the context line's `Text` and the face label (`'TERM'`) use `textStyles.eyebrow`.

- [ ] **Step 2: Run** the three files — Expected: the new tests FAIL (overline / requiredMarker).

- [ ] **Step 3: Implement:** in each listed widget replace `styles.overline` / `context.textStyles.overline` with `.eyebrow`; in the workload widget replace `style: styles.requiredMarker` with `style: styles.eyebrow` and set the glyph's `IconThemeData(color: context.colors.onSurfaceVariant, ...)` (drop the now-unused `ink` local if nothing else reads it). Keep every `toUpperCase()` and `semanticsLabel` as they are.

- [ ] **Step 4: Run** `flutter test --exclude-tags golden test/features/study/` — Expected: PASS.

- [ ] **Step 5: Commit** `feat(study): eyebrows on study home, entry and session (part 2)`.

### Task 4: User data keeps its case (21, 16–20)

**Files:**
- Create: `lib/features/study/presentation/states/upper_around_name_state.dart`
- Modify: `lib/features/study/presentation/states/session_context_state.dart`, `.../widgets/support/session_context_line_widget.dart`, `.../widgets/sections/session_summary_hero_widget.dart:34-63`
- Test: `test/features/study/presentation/upper_around_name_test.dart` (create), `session_summary_test.dart`

**Interfaces:**
- Produces: `String upperAroundName(String Function(String name) build, String name)` — builds the string with a private-use placeholder for the name, upper-cases it, then puts the name back.
- Produces: `String sessionContextOf(...)` unchanged (plain sentence, for semantics) plus `String sessionContextShownOf(AppLocalizations l10n, StudySessionView view)` (the visible, upper-cased-around-name form).

- [ ] **Step 1: Write the failing tests** — `test/features/study/presentation/upper_around_name_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/presentation/states/upper_around_name_state.dart';

void main() {
  test('upper-cases the app words and keeps the name as typed (part 2, P4)',
      () {
    expect(
      upperAroundName((name) => 'Review session · $name', 'Nhà hàng'),
      'REVIEW SESSION · Nhà hàng',
    );
    expect(
      upperAroundName((name) => '$name · review · round 1', 'TOPIK I · từ'),
      'TOPIK I · từ · REVIEW · ROUND 1',
    );
    expect(
      upperAroundName((name) => 'Phiên ôn tập · $name', 'nhà hàng'),
      'PHIÊN ÔN TẬP · nhà hàng',
    );
  });
}
```

In `session_summary_test.dart`, in the review-finished test (deck name per its fixture), assert the overline shows `'REVIEW SESSION · <deck as typed>'` with `find.text`, its style is `textStyles.eyebrow`, and `tester.getSemantics(find.text(...)).label` equals the plain `'Review session · <deck>'`.

- [ ] **Step 2: Run** both — Expected: FAIL (file missing; summary still upper-cases the deck).

- [ ] **Step 3: Implement** `upper_around_name_state.dart`:

```dart
/// A private-use code point no deck name contains: the template is
/// upper-cased with it in the name's place, then the name goes back as
/// typed (critique 2026-09-30 part 2, P4: never upper-case user data).
const String _namePlaceholder = '\u{F8FF}';

String upperAroundName(String Function(String name) build, String name) =>
    build(_namePlaceholder).toUpperCase().replaceAll(_namePlaceholder, name);
```

- `session_context_state.dart`: extract the body into `String _contextOf(AppLocalizations l10n, StudySessionView view, String deckName)`; `sessionContextOf` calls it with `view.deckName`; add `String sessionContextShownOf(AppLocalizations l10n, StudySessionView view) => upperAroundName((name) => _contextOf(l10n, view, name), view.deckName);`.
- `SessionContextLineWidget` takes `required this.text, required this.shown`: shows `shown`, `semanticsLabel: text`, no `toUpperCase()`; the session screen passes `text: sessionContextOf(l10n, view), shown: sessionContextShownOf(l10n, view)`.
- `session_summary_hero_widget.dart`: `final kind = view.kind == SessionKind.learning ? l10n.summaryKindLearning : l10n.summaryKindReview;` then `final overline = l10n.summaryOverline(kind, view.deckName);` (semantics) and `final shown = upperAroundName((name) => l10n.summaryOverline(kind, name), view.deckName);`; the `Text` shows `shown` with `semanticsLabel: overline`, `style: styles.eyebrow`.

- [ ] **Step 4: Run** `flutter test --exclude-tags golden test/features/study/` — Expected: PASS. Fix any test that expected the upper-cased deck name by changing it to the as-typed name (ledger each as a ruling).

- [ ] **Step 5: Commit** `fix(study): deck names keep their case in eyebrows (part 2 P4)`.

### Task 5: Eyebrows elsewhere (01, 07, 10, 22) and `compactOverline` goes

**Files:**
- Modify: `lib/features/card/presentation/widgets/sections/card_schedule_widget.dart:43`, `lib/features/progress/presentation/widgets/sections/progress_today_widget.dart:45`, `.../progress_streak_widget.dart:42,143`, `lib/features/deck/presentation/widgets/sections/deck_summary_card_widget.dart:61`, `lib/features/card/presentation/widgets/sections/card_deck_summary_widget.dart:64`
- Modify: `lib/core/theme/mx_text_styles.dart` (delete `compactOverline` and `_compactOverlineSize`), `test/core/theme/mx_text_styles_test.dart:252-253`
- Test: `test/features/card/presentation/card_detail_blocks_test.dart`, `test/features/progress/presentation/progress_screen_test.dart`, `test/features/card/presentation/card_deck_summary_test.dart`, `test/features/deck/presentation/open_deck_screen_test.dart`

- [ ] **Step 1: Write the failing tests:** next to each existing `find.text(X.toUpperCase())` expectation for these labels (card_detail_blocks_test lines 124 and 154: `cardScheduleBox(3, 8)`, `cardScheduleSm2`; progress_screen_test lines 74 and 107: `progressToday`, `progressStreakCurrent`; card_deck_summary_test line 54: `cardDeckProgress('SM-2')`; open_deck_screen_test line 378: `overline`), add:

```dart
    final label = find.text(/* the same upper-cased string */);
    expect(
      tester.widget<Text>(label).style,
      tester.element(label).textStyles.eyebrow,
    );
```

- [ ] **Step 2: Run** those four files — Expected: FAIL (overline / compactOverline).
- [ ] **Step 3: Implement:** replace `styles.overline`, `context.textStyles.overline` and `styles.compactOverline` with `.eyebrow` at the listed lines; delete `compactOverline` and `_compactOverlineSize` from `MxTextStyles` and the `compactOverline` line from `mx_text_styles_test.dart`.
- [ ] **Step 4: Run** `flutter analyze lib test` and `flutter test --exclude-tags golden test/features/card test/features/progress test/features/deck test/core/theme` — Expected: no issues; PASS.
- [ ] **Step 5: Commit** `feat: eyebrows on schedule, progress and deck summaries (part 2)`.

### Task 6: Field labels (03, 05, 08/09, 10)

**Files:**
- Modify: `lib/features/card/presentation/widgets/sections/card_field_widget.dart:113`, `.../card_tag_editor_widget.dart:116-120`, `.../card_detail_content_widget.dart:110-113`, `lib/features/tags/presentation/widgets/overlays/tag_rename_dialog_widget.dart:153-156`, `lib/features/starter_decks/presentation/widgets/overlays/starter_algorithm_sheet_widget.dart:100-103`
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb` (`starterSheetOverline` → `starterSheetAlgorithmLabel` "Review algorithm" / "Thuật toán ôn tập"; add `starterSheetRequired` "Required" / "Bắt buộc")
- Test: `test/features/card/presentation/card_editor_blocks_test.dart`, `card_detail_blocks_test.dart:65,96-97`, `test/features/tags/presentation/tags_screen_test.dart`, `test/features/starter_decks/presentation/starter_library_screen_test.dart`

- [ ] **Step 1: Write the failing tests:**
  - `card_editor_blocks_test.dart`: in the test that renders the front field, `final label = find.text(_en.cardFieldFront); expect(tester.widget<Text>(label).style, tester.element(label).textStyles.fieldLabel); final req = find.text(_en.cardRequiredLegend); expect(tester.widget<Text>(req).style, tester.element(req).textStyles.requiredMarker);` and for Tags `find.text(_en.cardTags)` with `fieldLabel`. (Use the label key the field actually receives if it is not `cardFieldFront`; read it from `card_field_widget`'s caller.)
  - `card_detail_blocks_test.dart`: change lines 65, 96, 97 from `cardFieldExample.toUpperCase()` / `cardFieldHint.toUpperCase()` to the plain keys, and assert the example label's style is `fieldLabel`.
  - `tags_screen_test.dart`: in the rename dialog test, `find.text(_en.tagsNewName)` uses `fieldLabel` (and `'NEW NAME'` finds nothing).
  - `starter_library_screen_test.dart`: in the algorithm sheet test, `find.text(_en.starterSheetAlgorithmLabel)` uses `fieldLabel` and `find.text(_en.starterSheetRequired)` uses `requiredMarker`.
- [ ] **Step 2: Run** — Expected: FAIL (labels upper-cased; `starterSheetAlgorithmLabel` undefined).
- [ ] **Step 3: Implement:** at each site drop `toUpperCase()` and use `styles.fieldLabel` (keep any `semanticsLabel`/`ExcludeSemantics` as is). The starter sheet becomes `Wrap(spacing: AppSpacing.micro, crossAxisAlignment: WrapCrossAlignment.center, children: [Text(l10n.starterSheetAlgorithmLabel, style: styles.fieldLabel), Text(l10n.starterSheetRequired, style: styles.requiredMarker)])`. ARB: rename the key in both files (description unchanged), add `starterSheetRequired` with description `"Screen 03 algorithm sheet: the Required caption after the label."`; run `flutter gen-l10n`.
- [ ] **Step 4: Run** `flutter test --exclude-tags golden test/features/card test/features/tags test/features/starter_decks` — Expected: PASS.
- [ ] **Step 5: Commit** `feat: field labels in sentence case (part 2 P3)`.

### Task 7: Search drops the results header (04)

**Files:**
- Modify: `lib/features/search/presentation/widgets/sections/search_results_widget.dart:45`, `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb` (delete `searchResultsFor` and its `@` entry)
- Test: `test/features/search/presentation/library_search_screen_test.dart:146-152`

- [ ] **Step 1: Write the failing test:** replace the `searchResultsFor` expectation at line 148 with:

```dart
    // The field shows the term; no header repeats it (part 2, P4).
    expect(find.textContaining('“'), findsNothing);
    expect(find.textContaining('RESULTS'), findsNothing);
```

and keep the DECKS/CARDS expectations; the test at line 169 (cards only) keeps `findsOneWidget` for CARDS.
- [ ] **Step 2: Run** — Expected: FAIL (header still shown).
- [ ] **Step 3: Implement:** delete the `MxListSectionHeader(label: l10n.searchResultsFor(results.term)),` line; delete the key from both ARBs; `flutter gen-l10n`.
- [ ] **Step 4: Run** `flutter test --exclude-tags golden test/features/search` — Expected: PASS.
- [ ] **Step 5: Commit** `fix(search): no header repeats the query (part 2 P4)`.

### Task 8: Records, goldens and the gate

**Files:** detail files 01, 03, 04, 05, 07, 08, 09, 10, 13, 14, 16, 16a, 17, 18, 19, 20, 21, 22 (one Rulings line each); `docs/wbs_FE.md` (row FE-D13 after FE-D12); goldens.

- [ ] **Step 1:** Add to each detail file's Rulings: `- **Critique 2026-09-30 part 2 (spec \`2026-10-01-critique-fixes-part2-typography-design.md\`):** <the role change on this screen>.` — one concrete sentence per screen naming the label and its new role (e.g. 04: "no header repeats the query; Decks and Cards stay section labels").
- [ ] **Step 2:** WBS row: `| FE-D13 | Critique 2026-09-30 phần 2: ba vai nhãn (section label, eyebrow 12/600 muted, field label 14/600 viết thường), "Required" là caption, tên deck giữ nguyên chữ ở summary và context line, Search bỏ tiêu đề kết quả | đang làm | FE-D12 | S | [spec](superpowers/specs/2026-10-01-critique-fixes-part2-typography-design.md) và [plan](superpowers/plans/2026-10-01-critique-fixes-part2-typography.md) | — |`; then `python3 tools/docs/generate.py && python3 tools/docs/check.py` — Expected: `PASS — 0 error(s)`.
- [ ] **Step 3:** `TZ=UTC flutter test --tags golden --update-goldens`, then `TZ=UTC flutter test --tags golden` — Expected: all pass.
- [ ] **Step 4:** `bash .claude/skills/flutter-workflow/scripts/dod_check.sh` — Expected: mechanical gates passed.
- [ ] **Step 5: Commit** `test(goldens): regenerate for part 2 label roles`.
